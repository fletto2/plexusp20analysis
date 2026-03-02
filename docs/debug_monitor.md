# Plexus P/20 Debug Monitor (U17 ROM)

## Overview

The U17 ROM (32KB at 0x800000) contains the DMA processor's self-test diagnostics and an interactive debug monitor. After power-on self-test completes (or fails), the debug monitor can be entered to inspect and manipulate hardware, memory, SCSI devices, and inter-processor communication.

The debug monitor is built around a command dispatcher at **0x8025B4** (`debug_command_dispatcher`) which decodes a single-character command and up to four numeric arguments, then routes to the appropriate handler via a jump table at **0x80261E**.

## Debug Monitor Architecture

### Entry Points

The debug monitor can be entered from several paths:

1. **Self-test failure**: After POST fails, control reaches the monitor via `0x801816`
2. **Debug input loop**: The interactive loop at `0x8072D2` (`debug_monitor_input_loop`) reads serial console input and dispatches commands
3. **Direct call**: Other ROM code can call `0x8025B4` directly with arguments on the stack

### Input Processing (`debug_monitor_input_loop`, 0x8072D2)

The interactive loop:
1. Prints a prompt string
2. Sets debug-mode flag at `0xC0082E = 1`
3. Reads characters from serial port (SCC channel, port IDs 0x42 and 0x43)
4. Remaps `_` (0x5F) to DEL (0x7F) for backspace handling
5. Handles `~` (0x7E) as a reset/escape — restarts the monitor loop
6. Passes input to `0x807882` for command parsing and hex argument collection
7. Calls `0x8025B4` with parsed command character and arguments

### Argument Parsing (`parse_hex_digit_sequence`, 0x8012CC)

Hex arguments are parsed from the console input buffer at `0xC006E2`. The parser:
- Reads ASCII hex digits (0-9, A-F, a-f)
- Accumulates into a 32-bit integer
- Returns the parsed value in `%d0`

### Command Dispatcher (`debug_command_dispatcher`, 0x8025B4)

**Stack frame**: 76 bytes local, saves D2-D7/A2-A5

**Arguments** (passed on stack):
| Offset | Register | Description |
|--------|----------|-------------|
| fp+8   | D7       | First argument (address or data value) |
| fp+12  | D4       | Second argument (count or offset) |
| fp+16  | —        | Third argument (used by `$` and `%` commands) |
| fp+20  | D5       | Command character (ASCII value) |
| fp+24  | D6       | Fourth argument (data value) |

**Key registers set up by dispatcher**:
| Register | Value |
|----------|-------|
| A5       | Pointer to SCSI control block (`0xC00836` area, from `0x80353C`) |
| A3       | Pointer to SCSI CDB area (from `0x803540`) |
| A2       | Pointer to ROM data table (from `0x803544`) |
| D3       | `(D4 + 1) >> 1` — half-count, rounded up |

**Result**: Stored in `%d2`, also written to `0xC00860` (global result variable), returned in `%d0`.

### Jump Table (0x80261E)

The dispatcher subtracts 0x21 (`!`) from the command character and indexes into a table of 87 word-sized PC-relative offsets. Characters outside 0x21-0x77 go to the default handler.

## Command Reference

### Memory Inspection Commands

#### `d` — Dump memory (words) — 0x802818
**Syntax**: `d <address> [<count>]`

Displays memory contents as 16-bit words with ASCII representation. This is the primary memory dump command.

**Operation**:
1. If count (D4) is 0, enters continuous mode with interactive navigation
2. Aligns address to word boundary (`D7 &= 0xFFFFFFFE`)
3. For each group of 8 words (16 bytes):
   - Prints address and 8 hex words: `%8x = %4x ? ...`
   - Prints ASCII representation (non-printable chars shown as `.`)
4. Interactive features at each line:
   - `q` — quit dump
   - `^` — go back one line
   - Any other key — continue
   - Hex input at `?` prompt replaces the displayed value (write-back)
5. Reads words using `0x80598E` (word read with bus error protection)
6. Writes modified values using `0x8059DC` (word write)

**Format strings**:
```
"%8x =  %4x  ? "     (address = value prompt)
"%4x "                (hex word)
"     "               (separator)
"    /* "              (ASCII section start)
" */\n"               (ASCII section end)
```

#### `I` — Dump memory (bytes) — 0x802816
**Syntax**: `I <address> [<count>]`

Same as `d` but reads and displays individual bytes instead of words. Uses `0x805A20` (byte read) and `0x805A6E` (byte write) instead of word-oriented functions.

**Note**: The `I` command shares its entry point (0x802816) with setup code that also loads D3 from D4 before falling through to the `d` handler at 0x802818, distinguishing itself by checking `D5 == 100` ('d') vs `D5 == 73` ('I').

#### `!` — Read word from address — 0x802FF6
**Syntax**: `! <address>`

Reads a 16-bit word from the address in D7 and stores it in the result variable at `0xC00860`.

**Operation**:
```
result = *(uint16_t *)D7;
0xC00860 = result;
```

#### `"` — Read byte from address — 0x803006
**Syntax**: `" <address>`

Reads a single byte from the address in D7 and stores it in the result variable at `0xC00860`.

**Operation**:
```
result = *(uint8_t *)D7;
0xC00860 = result;
```

---

### Memory Test Commands

#### `b` — Memory compare (block test) — 0x80272A
**Syntax**: `b <start_addr> <length> <fill_value>`

Performs a dual-processor memory test on the address range `[D7, D7+D4)` using fill value D6.

**Operation**:
1. Calls `dual_processor_memory_test` (0x803E9E) with args: start=D7, end=D7+D4, fill=D6, mode=2
2. If test fails, prints error message at 0x807AF1
3. Stores result (0=pass, non-zero=fail) at `0xC00860`

**Format string**: `"%8x = %4x,\t%8x = %4x\n"` (shows mismatch address and values)

#### `T` — Memory test (single pattern) — 0x802F04
**Syntax**: `T <start_addr> <length> <fill_value>`

Like `b` but uses mode=1 for the memory test (DMA-only, no Job processor involvement).

**Operation**:
1. Calls `dual_processor_memory_test` (0x803E9E) with args: start=D7, end=D7+D4, fill=D6, mode=1
2. Prints error on failure
3. Stores result at `0xC00860`

#### `c` — Memory compare (word scan) — 0x80275A
**Syntax**: `c <start_addr> [<count>] <expected_value>`

Scans memory word-by-word starting at D7, comparing each word against D6. Reports mismatches.

**Operation**:
1. If count (D3) is 0, defaults to 1
2. For each word in range:
   - Reads word at current address via `0x80598E`
   - Compares against expected value D6
   - If mismatch: prints `"%8x = %4x,\t%8x = %4x\n"` showing address, actual, expected
   - Calls `wait_for_scsi_operation_completion` (0x805930) after each mismatch
   - Sets D2=1 (error flag)
3. Advances by 2 bytes per iteration

**Variants**: Commands `c`, `f`, and `i` share the same handler at 0x80275A but behave differently:

#### `f` — Memory fill and verify — 0x80275A
**Syntax**: `f <start_addr> [<count>] <fill_value>`

Same handler as `c`, but when D5='f' (0x66), uses D6 as both the fill value and the expected compare value. Does NOT write — only reads and compares. (The name is misleading; it's really a verify-against-constant operation.)

#### `i` — Memory compare (report matches) — 0x80275A
**Syntax**: `i <start_addr> [<count>] <search_value>`

When D5='i' (0x69), reports addresses where the value EQUALS D6 (the inverse of `c`):
- Prints `"%8x = %4x  instead of %x\n"` for each mismatch
- Prints `"%8x = %4x\n"` for each match against D6

---

### Memory Write Commands

#### `O` — Write bytes to memory — 0x802EB0
**Syntax**: `O <start_addr> <count> <value>`

Writes byte D6 to successive memory locations starting at D7, for D4 iterations.

**Operation**:
1. If count is 0, defaults to 1
2. For each iteration:
   - Calls `0x804FF6` (poll SCSI/system state)
   - Writes byte D6 to address D7 via `0x805A6E` (byte write)
   - Increments D7

#### `M` — Write words to memory — 0x802E98
**Syntax**: `M <start_addr> <count> <value>`

Writes word pattern to memory using `scsi_verify_drive_presence` (0x801590) — this appears to set up a SCSI-like write to the specified memory range.

**Operation**:
1. If count is 0, defaults to 1
2. Calls `0x801590` with args: start=D7, count=D4, value=D6

#### `W` — Write words to memory (fill) — 0x802F36
**Syntax**: `W <start_addr> <count> <value>`

Fills memory with word or longword values.

**Operation**:
- If D6 != 0: calls `0x800D50` (longword-aligned memcpy) with D7=dest, D4=count
- If D6 == 0: calls `0x800D7A` (word fill) with D7=dest, D4=count

---

### Processor Control Commands

#### `a` — Set interrupt mask / run test — 0x802714
**Syntax**: `a [<addr>] [<count>] [<value>]`

Multi-purpose command based on argument combinations:
- If D7 != 0: behaves like memory init with `set_boot_device_flag_and_clear_string` (0x805714) or `clear_boot_flag_based_on_test` (0x80575A)
- If D4 != 0: calls `initialize_shared_memory_and_boot_control` (0x805656) or `disable_processor_serial_interrupts` (0x8058F4)
- If both D7 and D4 are 0: calls `set_sr_interrupt_mask` (0x800610) with value D6-1

#### `S` — Jump to address — 0x802ED6
**Syntax**: `S <address>`

Prints "jumping to %x" and then calls the specified address as a subroutine.

**Operation**:
1. Prints: `"\njumping to %x\n"` with D7
2. Calls `jsr (D7)` — jumps to the address in D7
3. If the called code returns: stores return value at `0xC00860`
4. If return is non-zero, prints error message

**Warning**: This directly executes code at the given address. Use with care.

#### `v` — Set serial port mode — 0x802D64
**Syntax**: `v [<flag>] [<value>]`

Configures serial port operating parameters.

**Operation**:
1. Stores D6 to `0xC007F2` (serial mode variable)
2. If D7 == 0: calls `debug_monitor_input_loop` (0x8072D2) with arg=2
3. If D7 != 0: calls `debug_monitor_input_loop` with arg=1

---

### SCSI Commands

#### `%` — SCSI control — 0x803016
**Syntax**: `% <sub_cmd> [<args...>]`

The `%` command is the gateway to low-level SCSI operations. It has its own sub-command dispatch based on the command character in D5.

**Initialization** (common to all `%` sub-commands):
1. Clears SCSI state: `0xC0083A = 0`, `0xC0080A = 0`, `0xC008A6 = 0`
2. Copies SCSI target address from `0xC00854` to CDB area (A3+2)
3. Checks if sub-command is `C`, `b`, or `c` — if so, skips SCSI ID setup
4. Otherwise: sets SCSI target ID from `0xC0080E`, configures command byte, LUN, sector count

**Sub-commands**:

| Sub-cmd | Code | Address | Description |
|---------|------|---------|-------------|
| `%C`    | 0x43 | 0x8032DA | Configure SCSI controller parameters |
| `%R`    | 0x52 | 0x803354 | SCSI Read — reads sectors from disk |
| `%O`    | 0x4F | 0x803348 | SCSI Output — send data to SCSI device |
| `%W`    | 0x57 | 0x803412 | SCSI Write — writes sectors to disk |
| `%f`    | 0x66 | 0x803174 | SCSI Format/Verify — formats or verifies disk blocks |

**`%f` (Format/Verify)** — 0x803174:
1. Calls `confirm_or_abort` (0x80397C) — prompts "are you sure?"
2. Sets SCSI opcode to 0x04 (FORMAT UNIT)
3. Configures LUN/sector from D6/D7
4. Calls `scsi_command_execute` (0x80621A)

**`%R` (Read)** — 0x803354:
1. Sets SCSI opcode to 0x08 (READ)
2. Configures block address and transfer length
3. Calls `scsi_command_execute` (0x80621A)
4. Stores result in D2

**`%W` (Write)** — 0x803412:
1. Calls `confirm_or_abort` (0x80397C)
2. Sets SCSI opcode to 0x0A (WRITE)
3. Configures block address and transfer length
4. Calls `scsi_command_execute` (0x80621A)

**Additional `%` sub-commands** (within the nested switch at 0x803094):
- Block address auto-increment logic
- Verify after write operations
- SCSI MODE SELECT (opcode 0x15) and MODE SENSE (opcode 0x1A)
- SCSI INQUIRY (opcode 0x12)

#### `$` — SCSI special operation — (pre-dispatch at 0x8025F4)

The `$` character (0x24) is intercepted before the main jump table. When D5 is `$`, it combines with the `%` handler to execute SCSI operations with special parameters from the third stack argument (fp+16).

#### `L` — SCSI block verify (IPC) — 0x802E4A
**Syntax**: `L <start_block> <count> <fill_value>`

Performs SCSI block verification with inter-processor coordination.

**Operation**:
1. Calls `read_dma_int_status` (0x800F06) to check DMA processor state
2. If DMA interrupt active: sets `0xC0082A = 1` (DMA-side flag)
3. If not: sets `0xC00826 = 1` (Job-side flag)
4. Clears `0xC00832`
5. Calls `memory_test_pattern` (0x8039CA) with args: start=D7, end=D7+D4, fill=D6
6. If errors found, prints error message at 0x807B98
7. Stores result at `0xC00860`

#### `q` — SCSI self-test — 0x802C4C
**Syntax**: `q`

Runs the SCSI subsystem self-test.

**Operation**:
1. Calls `selftest_scsi_devices` (0x806CD8)
2. Prints result message at 0x807B7C
3. Returns to command loop

---

### Inter-Processor Communication (IPC) Commands

#### `B` — Boot/IPC to Job processor — 0x802D82
**Syntax**: `B <address> [<count>]`

Initiates communication with the Job processor and optionally boots it.

**Operation**:
1. Calls `read_dma_int_status` (0x800F06)
2. If DMA interrupt active:
   - Calls `scsi_command_with_timeout` (0x8054FA) with args: D7, D4, 0x42, 0
3. If D4 == 0 (no count — boot mode):
   - Sets `Boot.JOB` bit (0x0100) in control register `0xE00016`
   - Calls `selftest_memory_bus_arbitration` (0x80139A) with arg=0
   - Scales result and calls `configure_dma_transfer` (0x805B9E)
4. Clears `0xC0064C`
5. Clears processor control register `0xE00018` (releases Job processor)
6. Calls `0x803548` with arg=1 (delay/sync)
7. Clears `0xC00644`
8. Reads ROM function table pointer from `0x8003F8`
9. If D7 != 0: verifies ROM checksum via `verify_rom_checksum` (0x8038D4)
10. Calls boot function with args from `0xC006D6`
11. Calls `boot_processor_switch_or_reset` (0x80536C) with arg=0

This is the mechanism for loading and starting the Job processor — it's how the DMA processor hands off to the boot loader or Unix kernel.

#### `C` — Configure IPC channel — 0x802BD8 (via jump table entry 0x802E26)
**Syntax**: `C <flag> <value>` or `C 0 <value>`

Stores configuration values for inter-processor communication.

**Operation**:
- If D7 != 0: stores D4 to `0xC00802` (IPC command register)
- If D7 == 0: stores D6 to `0xC006DE` (IPC data register)

Note: The jump table entry for `C` (0x43) at 0x802E26 falls through to 0x802E32 which is the `E` handler, but the `C` entry is at the distinct address 0x802BD8 (verified from ROM_debug.md).

#### `E` — Execute IPC command — 0x802E32
**Syntax**: `E <start_addr> <count> <fill_value>`

Fills memory via the IPC subsystem, likely writing to Job processor memory space.

**Operation**:
1. If D4 == 0, defaults to 1
2. Calls `configure_dma_transfer` (0x805B9E) with args: start=D7, count=D4, fill=D6
3. Returns to command loop

---

### Display / Information Commands

#### `V` — Print version — 0x802F5A
**Syntax**: `V`

Prints the ROM version string.

**Operation**:
1. Loads string pointer from `0x800400` (ROM version string area)
2. Prints: `"\nVERSION = %s\n\n"` with the version string

The version string at 0x800400 contains: `" RD-32 06/04/85"` — indicating this ROM was built June 4, 1985 for the RD-32 (Robin Debug) version 32.

#### `X` — Print CSRs (Control/Status Registers) — 0x802F72
**Syntax**: `X`

Displays the contents of all hardware control and status registers.

**Operation**:
1. Calls `0x801246` which reads and prints all registers at 0xE00000-0xE0001A

This provides a complete snapshot of the hardware state including:
- System status (parity, bus errors, processor enable bits)
- Control register (Boot.DMA, Boot.JOB, DIS.MAP, DIAG bits)
- Processor status (EN.JOB, INT.JOB, INT.DMA)
- Serial port status (RI, TCE, RCE, DSR)

#### `h` — Print interrupt vector table — 0x802BF0
**Syntax**: `h`

Displays the contents of all 16 entries in the interrupt handler function table.

**Operation**:
1. Iterates D4 from 0 to 15
2. For each entry: reads the function pointer from table at `0x800F50 + D4*4`
3. Prints: `"%4x - %s\n"` with the index and function pointer

This shows the installed interrupt/exception handler addresses.

#### `e` — List SCSI descriptors — 0x802A4E
**Syntax**: `e [<count>] [<index>]`

Lists or manipulates SCSI block transfer descriptors stored in a table in memory.

**Operation**:
- If D4 == 0x0C: calls `scsi_verify_blocks` (0x8037E2) — verifies all descriptors
- If D7 == 0 (list mode):
  - Iterates through descriptor table at A2+652
  - Prints each entry: `"%6x   %s\n"` with descriptor value and description
  - Count limited by word at A2+650
- If D4 == 0x0D (manage mode):
  - If D7 == 0xFE: reinitializes all 25 descriptor slots
  - Otherwise: inserts/removes descriptors from the table (linked list operations)
  - Reads user input for new descriptor data via `process_escape_sequence` (0x8077B6)

**Descriptor table**: Located at A2+652 (offset from ROM data pointer), with up to 25 entries of 26 bytes each. The count is stored as a word at A2+650.

---

### Hardware Test Commands

#### `t` — Run hardware test — 0x802C6C
**Syntax**: `t [<test_num>]`

Runs a specific hardware diagnostic test or all tests.

**Operation**:
1. If D6 > 15: error (invalid test number)
2. If D6 == 0: runs ALL tests (D4=15, loops from test 0 to 14)
3. If D6 != 0: runs single test (D4=1, D5=D6-1)
4. For each test:
   - Prints test number and name: `"%4x - %s\n"` from function table at 0x800F14
   - Calls `0x804FF6` (poll system state)
   - Calls `read_dma_int_status` (0x800F06)
   - Compares result against expected at `0xC00648`
   - If match: calls `0x800EC0` (additional setup)
   - Calls test function via indirect jump through table at `0x800F14 + D5*4`
   - On failure (non-zero return): prints `" FAILED (%x)\n"` with error code
   - On success: prints `" PASSED\n"`

**Test function table** at 0x800F14: Contains 16 function pointers for individual hardware tests (memory, SCSI, serial ports, bus arbitration, etc.)

#### `Z` — Reset/reinitialize system — 0x802F7C
**Syntax**: `Z [<count>] [<value>]`

Performs a controlled system reset with optional configuration.

**Operation**:
1. Calls `confirm_or_abort` (0x80397C) — prompts user for confirmation
2. Copies 100 bytes (0x64) from ROM address `0xD0001C` to memory via `write_words_with_rounding` (0x800D22)
3. If D4 != 0: modifies configuration word at offset 36 in the copied data
4. Modifies configuration word at offset 20 with optional D6 value
5. Calls `checksum_rom_block` (0x803934) to recompute checksum
6. Returns to command loop

This appears to reset the system configuration stored in the clock/calendar NVRAM area (0xD0001C is in the NVRAM space).

---

### Serial Port / Console Commands

#### `g` — Store to IPC command register — 0x802BD8
**Syntax**: `g <flag> <value>`

Same handler as `C` — stores values to IPC registers.

- If D7 != 0: `0xC00802 = D4`
- If D7 == 0: `0xC006DE = D6`

#### `s` — Set SCSI timeout — 0x802C62
**Syntax**: `s <value>`

Sets the SCSI operation timeout value.

**Operation**: `0xC006BA = D6`

#### `o` — Set output channel — 0x802C2E
**Syntax**: `o <value>`

Selects the output channel for diagnostic messages.

**Operation**:
1. Calls `read_dma_int_status` (0x800F06)
2. If DMA interrupt active: `0xC006C2 = D6`
3. If not active: `0xC006BE = D6`

#### `w` — Write to memory (word pairs) — 0x802D18
**Syntax**: `w <start_addr> [<count>] [<value>]`

Writes word values to memory, with bus error protection.

**Operation**:
1. Aligns address to word boundary
2. If count is 0, defaults to 1
3. Calls `read_dma_int_status` (0x800F06) to determine processor
4. For each iteration:
   - If DMA processor: calls `0x800D22` (word write) with args: addr=D7, count=D4, value=D6
   - If Job processor: read-modify-write loop using `0x8059DC` and `0x805A6E`
   - Calls `0x804FF6` (poll) between iterations
   - Advances D7 by 2

---

## Shared Memory Variables

The debug monitor uses several shared memory locations for state:

| Address | Size | Name | Description |
|---------|------|------|-------------|
| 0xC006BA | 4 | scsi_timeout | SCSI operation timeout value |
| 0xC006BE | 4 | output_channel_job | Output channel (Job processor side) |
| 0xC006C2 | 4 | output_channel_dma | Output channel (DMA processor side) |
| 0xC006D6 | 4 | ipc_data | IPC data register |
| 0xC006DE | 4 | ipc_data_alt | IPC data register (alternate) |
| 0xC006E2 | var | input_buffer | Console input buffer |
| 0xC007F2 | 4 | serial_mode | Serial port operating mode |
| 0xC00802 | 4 | ipc_command | IPC command register |
| 0xC0080A | 4 | scsi_state_a | SCSI state variable A |
| 0xC0080E | 4 | scsi_target_id | Current SCSI target ID |
| 0xC0082A | 4 | dma_ipc_flag | DMA-side IPC flag |
| 0xC00826 | 4 | job_ipc_flag | Job-side IPC flag |
| 0xC0082E | 4 | debug_mode | Debug mode active flag |
| 0xC00832 | 4 | ipc_sync | IPC synchronization variable |
| 0xC00836 | 4 | scsi_indirect | SCSI indirect mode flag |
| 0xC0083A | 4 | scsi_state_b | SCSI state variable B |
| 0xC00854 | 4 | scsi_target_addr | SCSI target address (physical) |
| 0xC00858 | 4 | scsi_param | SCSI parameter storage |
| 0xC00860 | 4 | result | Global result/return value |
| 0xC008A6 | 4 | scsi_state_c | SCSI state variable C |
| 0xC008F4 | 4 | scsi_fallback | SCSI fallback address |

## Complete Command Summary

### Quick Reference Table

| Cmd | Handler | Category | Description |
|-----|---------|----------|-------------|
| `!` | 0x802FF6 | Memory | Read word at address → result |
| `"` | 0x803006 | Memory | Read byte at address → result |
| `%` | 0x803016 | SCSI | SCSI operations (sub-commands: C, R, W, O, f) |
| `$` | (pre-dispatch) | SCSI | SCSI special operation |
| `B` | 0x802D82 | IPC | Boot/start Job processor |
| `C` | 0x802E26 | IPC | Configure IPC channel (also `g`) |
| `E` | 0x802E32 | IPC | Execute IPC memory fill |
| `I` | 0x802816 | Memory | Dump memory (byte-oriented) |
| `L` | 0x802E4A | SCSI | SCSI block verify with IPC |
| `M` | 0x802E98 | Memory | Write words to memory (SCSI-style) |
| `O` | 0x802EB0 | Memory | Write bytes to memory |
| `S` | 0x802ED6 | Control | Jump to address (call subroutine) |
| `T` | 0x802F04 | Test | Memory test (single pattern) |
| `V` | 0x802F5A | Info | Print ROM version string |
| `W` | 0x802F36 | Memory | Fill memory with word pattern |
| `X` | 0x802F72 | Info | Print all CSR register values |
| `Z` | 0x802F7C | Control | Reset/reinitialize system (NVRAM) |
| `a` | 0x802714 | Control | Set interrupt mask / processor control |
| `b` | 0x80272A | Test | Memory block test (dual processor) |
| `c` | 0x80275A | Test | Memory compare (word scan) |
| `d` | 0x802818 | Memory | Dump memory (word-oriented, interactive) |
| `e` | 0x802A4E | SCSI | List/manage SCSI descriptors |
| `f` | 0x80275A | Test | Memory fill-verify |
| `g` | 0x802BD8 | IPC | Store to IPC registers (same as `C`) |
| `h` | 0x802BF0 | Info | Print interrupt vector table |
| `i` | 0x80275A | Test | Memory compare (report matches) |
| `m` | 0x802C1C | Memory | Memory copy (memcpy) |
| `o` | 0x802C2E | Config | Set output channel |
| `q` | 0x802C4C | Test | SCSI self-test |
| `s` | 0x802C62 | Config | Set SCSI timeout |
| `t` | 0x802C6C | Test | Run hardware diagnostic test |
| `v` | 0x802D64 | Config | Set serial port mode |
| `w` | 0x802D18 | Memory | Write words (bus-error protected) |

### Commands by Category

**Memory Inspection**: `!`, `"`, `d`, `I`
**Memory Write**: `m`, `M`, `O`, `W`, `w`
**Memory Test**: `b`, `c`, `f`, `i`, `T`
**SCSI Operations**: `%`, `$`, `e`, `L`, `q`
**Inter-Processor**: `B`, `C` (`g`), `E`
**System Control**: `S`, `Z`, `a`
**Information**: `V`, `X`, `h`
**Configuration**: `o`, `s`, `v`, `t`

## Hardware Test Table (0x800F14)

The `t` command can run individual tests by number. The test function pointers are stored in a table at `0x800F14`, with 16 entries (4 bytes each):

| Test # | Purpose (inferred) |
|--------|--------------------|
| 0 | Memory bus test |
| 1 | Memory pattern test |
| 2 | Memory parity test |
| 3 | Bus arbitration test |
| 4 | Interrupt controller test |
| 5 | Timer/clock test |
| 6 | Serial port A test |
| 7 | Serial port B test |
| 8 | SCSI controller init |
| 9 | SCSI bus test |
| 10 | SCSI device presence |
| 11 | SCSI read/write test |
| 12 | DMA controller test |
| 13 | Job processor communication |
| 14 | System integration test |
| 15 | (reserved/unused) |

## ROM Version and Build Info

The version string at **0x800400** reads: `" RD-32 06/04/85"`

- **RD**: Robin Debug (Robin was the Plexus internal project name)
- **32**: Version/revision number
- **06/04/85**: Build date — June 4, 1985

## Error Handling

The default handler (0x8026CC) is reached for any unrecognized command character. It:
1. Sets D2 = 0xE0 (error code 224)
2. Stores 0xE0 to `0xC00860`
3. Prints `" ????\n"` (the string at 0x807BBE)
4. Returns via common exit

All command handlers return through the common exit at **0x80270E** → **0x80350C**:
```asm
80270e: movel %d2,%d0
80350c: movel %d2,0xc00860    ; store result
        moveml %fp@(-72),...   ; restore registers
        unlk %fp
        rts
```
