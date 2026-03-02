# Plexus P/20 Boot Loader (U15 ROM)

## Overview

The Plexus P/20 boot loader resides in the U15 ROM pair (32KB, mapped at `0x808000`). It runs on the DMA processor (Motorola 68010) and provides:

- Hardware initialization and SCSI controller setup
- An interactive boot menu with the `PLEXUS PRIMARY BOOT REV 1.2` banner
- Command parsing for device specifiers (`sc()`, `mt()`, `pt()`, `fp()`) and short code aliases
- SCSI disk, tape, and floppy device drivers
- A read-only System V (s5fs) filesystem implementation (see `docs/filesystem.md`)
- An `a.out` executable loader that transfers control to the Job processor
- Disk-to-tape and tape-to-disk copy utilities
- An ICP (Inter-processor Communication Protocol) remote kernel for the Job processor

The boot loader's design closely follows the earlier Z8000-based Plexus boot loader (source in `Src/Sys3_v1.1/stand/z8000/boot.c`), adapted for the 68010 architecture. The ROM is dated to approximately the same era as U17 ("RD-32 06/04/85").

## Boot Sequence

### 1. Entry from U17 Self-Test

After U17 completes self-tests, it transfers control to U15. The U15 entry point is at **0x808560** (`boot_loader_init`):

```
0x808560: Set SSP to 0xC03FF4 (top of shared RAM stack area)
           Set VBR to 0x808000 (U15 exception vector table)
           Call boot_initialize_system (0x809696)
           Call boot_menu_init (0x80950e)
           STOP #0x2700 (halt, wait for interrupt)
```

The `STOP` instruction halts the DMA processor with interrupts masked at level 7, waiting for an interrupt from the self-test completion or a serial port event to wake it.

### 2. System Initialization (`boot_initialize_system`, 0x809696)

This function prepares all hardware and data structures for booting:

1. **Copy boot sectors** — calls `0x80BB74` to copy 1024 bytes from `0xC00000` to `0xC00400` and snapshot 15 words of I/O registers from `0xE00000` to `0xC00672`
2. **Halt Job processor** — writes `0` to `0xE00018` (KILL.JOB), holding it in reset
3. **Check warm boot** — reads magic value at `0xC00274`; if not `0x04D2` (1234), this is a cold boot: set bit 5 at `0xE0000E` and store the magic value
4. **Hardware reset** — calls `0x8087FE` (`hardware_reset_and_init`) to clear all error flags, configure serial ports, and reset interrupt controllers
5. **Clear shared memory** — zero two regions:
   - `0xC00000`–`0xC00400` (1KB system variables)
   - `0xC03800`–`0xC03E00` (1.5KB device tables)
6. **Initialize pointer tables** — store hardcoded pointers into shared RAM:
   - `0xC03804` = `0xC00000` (system data base)
   - `0xC03808` = `0xC0001A` (secondary data area)
   - Other system pointers
7. **Initialize SCSI target parameters** — calls `0x80888E` which populates a device configuration table for up to 8 SCSI targets, reading configuration from the clock calendar RAM at `0xD0001C`
8. **Set flags** — writes `0xFF` to `0xC0380D` (SCSI command ready flag), clears `0xC0026C` and `0xC03B24`
9. **Save boot magic** — stores `0x04D2` back to `0xC00274` for warm boot detection

### 3. Boot Menu Loop (`boot_menu_loop`, 0x80B37C)

The main boot menu displays the banner and prompt, then reads and dispatches commands:

```
PLEXUS PRIMARY BOOT REV 1.2
:
```

**Algorithm**:
1. Print banner string at `0x80C2C0` (`"\nPLEXUS PRIMARY BOOT REV 1.2\n: "`)
2. Check auto-boot flag: if the configuration switch at `0xE000xx` has bit 3 clear, and this is the first or second attempt, auto-boot with the default command (empty line = `sc(0,0)/unix`)
3. If not auto-booting, call `read_and_process_console_input` (0x80A236) to read a line into buffer at `0xC03ABC`
4. Call `parse_boot_command` (0x80904C) with the input string
5. If parsing succeeds, dispatch to the appropriate boot function
6. On error, print error message and loop back to the prompt

### 4. Auto-Boot

If the hardware configuration switch has bit 3 clear (`AUTOBOOT` condition), the boot loader will:
- On the first attempt: immediately try the default boot command
- On the second attempt: wait 30 seconds (`spin(30*60)`) before retrying
- After two failed attempts: fall through to the interactive prompt

The auto-boot string is `"AUTO BOOT\n"` at `0x80C2E2`, printed before the automatic boot attempt.

## Command Parser (`parse_boot_command`, 0x80904C)

The 500-byte command parser handles these input formats:

### Input Formats

| Format | Example | Meaning |
|--------|---------|---------|
| Empty | *(just Enter)* | Default: `sc(0,0)/unix` |
| `!` prefix | `!sc(0,0)/unix` | Enable verbose debug output |
| `/path` | `/unix`, `/stand/ccal` | Load from default disk (`sc(0,0)`) |
| `dev(params)` | `sc(0,0)` | Boot from device (tape/raw) |
| `dev(params)/path` | `sc(0,0)/unix` | Load file from device filesystem |
| Short code | `unix`, `help` | Alias (see table below) |

### Parsing Algorithm

1. Skip leading spaces
2. Check for `!` prefix → set verbose flag at `0xC03A9C`
3. Check for `/` prefix → save path pointer, use default device `sc(0,0)`
4. Search the command table at `0x809308` for a matching device/alias name using `strncmp_or_nullterm_match` (0x808DC2), which treats `(` as a string terminator so `"sc"` matches `"sc(0,0)"`
5. Extract parameters between `(` and `)`:
   - First number = controller/unit (stored in `0xC03A7C`)
   - After `,` = partition/file number (stored in `0xC03A80`)
6. Compute SCSI device index and store in `0xC03A30`
7. If a path follows `)`, enter filesystem mode:
   - Set bit 3 of `0xC03A20` (filesystem mode flag)
   - Call `parse_path_components` (0x808A9A) to resolve the path
   - Call `read_inode` (0x8089DE) to load the file's inode
8. Dispatch to the appropriate handler via the command table

### String Match Function (`strncmp_or_nullterm_match`, 0x808DC2)

Compares up to 14 characters (DIRSIZ) with a special rule: if the entry string contains `(` and the search string has a null terminator at the same position, it's considered a match. This allows short code names like `"sc"` to match the entry `"sc(0,0)"` in the command table.

This is identical to the `match()` function in the Z8000 boot source:

```c
match(s1, s2) {
    cc = 14;
    while (cc--) {
        if ((*s1=='(') && !(*s2)) return(1);
        if (*s1 != *s2) return(0);
        if (*s1++ && *s2++) continue;
        else return(1);
    }
    return(1);
}
```

## Command Table (0x809308)

The command table is an array of 16-byte entries at `0x809308`. Each entry contains four longword pointers:

```
Offset  Field          Description
+0      name_ptr       Pointer to device/command name string
+4      init_fn        Initialization function (called via 0x8092AC)
+8      boot_fn        Boot/execute function (called via 0x8092CC)
+12     scsi_fn        SCSI operation function (called via 0x8092E6)
```

Three dispatcher functions use different offsets into each entry:

| Dispatcher | Address | Offset | Purpose |
|-----------|---------|--------|---------|
| `call_boot_menu_function` | 0x8092AC | +4 | Device initialization |
| `dispatch_boot_command` | 0x8092CC | +8 | Boot/load operation |
| `dispatch_scsi_command` | 0x8092E6 | +12 | SCSI-level operation |

### Decoded Table Entries

| Index | Name | Init (0x8092AC) | Boot (0x8092CC) | SCSI (0x8092E6) |
|-------|------|-----------------|-----------------|-----------------|
| 0 | `sc` (disk) | `boot_scsi_read_boot_block` (0x80AD7E) | `boot_load_unix_kernel` (0x80ADE0) | `null_handler` (0x809300) |
| 1 | `mt`/`pt` (tape) | `boot_tape_init` (0x80B3AE) | `boot_cleanup_or_shutdown` (0x80B2F6) | `boot_menu_loop` (0x80B37C) |
| 2 | `fp` (floppy) | `boot_floppy_init` (0x80B63E) | `scsi_wait_busy` (0x80B57A) | `boot_handle_scsi_error` (0x80B61C) |
| 3 | *(alt floppy)* | `boot_floppy_init` (0x80B63E) | `scsi_wait_busy` (0x80B57A) | `boot_handle_scsi_error` (0x80B61C) |
| 4 | `dtot` | `disk_to_tape` (0x80B82C) | `null_handler` (0x809300) | `null_handler` (0x809300) |
| 5 | `ttod` | `tape_to_disk` (0x80B8DC) | `null_handler` (0x809300) | `null_handler` (0x809300) |
| 6 | *(unknown)* | `boot_read_disk_block` (0x80B43C) | `null_handler` (0x809300) | `null_handler` (0x809300) |

The `null_handler` at `0x809300` is a stub that immediately returns (link/unlk/rts).

## Short Code Aliases

The ROM contains a table of short code names that map to tape file positions. When the user types a short code at the `:` prompt, it is expanded to the corresponding `pt(,N)` command:

| Short Code | Tape Command | File Position | Description |
|-----------|-------------|--------------|-------------|
| `?` | `pt(,)` | 0 | Help / first file on tape |
| `help` | `pt(,)` | 0 | Help (same as `?`) |
| `unix` | `pt(,2)` | 2 | Unix kernel |
| `sys5` | `pt(,2)` | 2 | Unix kernel (alias for `unix`) |
| `format` | `pt(,3)` | 3 | Disk format utility |
| `mkfs` | `pt(,4)` | 4 | Make filesystem |
| `restor` | `pt(,5)` | 5 | Restore from backup |
| `fsck` | `pt(,6)` | 6 | Filesystem check |
| `dd` | `pt(,7)` | 7 | Block copy utility |
| `fbackup` | `pt(,8)` | 8 | File backup |
| `od` | `pt(,9)` | 9 | Octal dump |
| `ccal` | `pt(,10)` | 10 | Clock calendar configuration |
| `fsdb` | `pt(,12)` | 12 | Filesystem debugger |
| `du` | `pt(,13)` | 13 | Disk usage |
| `ls` | `pt(,14)` | 14 | List directory |
| `cat` | `pt(,15)` | 15 | Concatenate files |

**Note**: Tape positions 1 and 11 are unused on the P/20 install tapes. The earlier Z8000-based Plexus used `mt()` instead of `pt()`, and had `boot` at position 1, `dconfig` at 10, `sash` at 11, and `diag` at 19. The P/20 ROM uses `pt()` but both `mt()` and `pt()` are accepted and behave identically.

The string table for these aliases is located at `0x80C204`–`0x80C2BF`:

```
0x80C204: "pt(,)"       (for ? and help)
0x80C21A: "pt(,2)"      (for unix and sys5)
0x80C234: "pt(,3)"      (for format)
0x80C240: "pt(,4)"      (for mkfs)
0x80C24E: "pt(,5)"      (for restor)
0x80C25A: "pt(,6)"      (for fsck)
0x80C264: "pt(,7)"      (for dd)
0x80C273: "pt(,8)"      (for fbackup)
0x80C27D: "pt(,9)"      (for od)
0x80C289: "pt(,10)"     (for ccal)
0x80C296: "pt(,12)"     (for fsdb)
0x80C2A1: "pt(,13)"     (for du)
0x80C2AC: "pt(,14)"     (for ls)
0x80C2B8: "pt(,15)"     (for cat)
```

## SCSI Device Addressing

### Device Specifier Syntax

```
sc(N,S)       SCSI disk: N = (unit * 2) + LUN, S = partition (slice)
mt(D,F)       Magnetic tape: D = SCSI device, F = file mark number
pt(D,F)       Pertec tape: D = SCSI device, F = file mark number (same as mt)
fp(...)       Floppy disk: OMTI 5200 LUN 2
```

### SCSI Unit Encoding

The `N` parameter in `sc(N,S)` encodes both the SCSI physical unit and LUN:

```
N = (Physical_Unit * 2) + LUN
```

| N | Physical Unit | LUN | Device |
|---|--------------|-----|--------|
| 0 | 0 | 0 | First hard drive (OMTI 5200, default) |
| 1 | 0 | 1 | Second hard drive (OMTI 5200) |
| 2 | 1 | 0 | External SCSI device at ID 1 |
| 3 | 1 | 1 | External SCSI device at ID 1, LUN 1 |

The boot ROM extracts these values from `0xC03A7C`:
- **Target ID**: `0xC03A7C >> 1` (right shift by 1)
- **LUN**: `0xC03A7C & 1` (bit 0)

### Partition (Slice) Handling

The `S` parameter selects a disk partition. The partition table is read from the boot block (sector 0) of the disk. Slices are numbered from 0; the default is slice 0 if omitted.

The partition start offset (in physical 512-byte blocks) is stored in `0xC03A80`.

### SCSI Parameter Validation (`is_valid_scsi_lun_or_partition`, 0x809F5C)

Validates that:
- LUN is 0 or 1
- Partition number is between 2 and 32

## SCSI Driver Stack

The boot ROM implements a complete SCSI initiator driver for the OMTI 5200 controller. The driver operates through interrupt-driven I/O with the SCSI controller connected via hardware registers.

### Driver Architecture

```
                     parse_boot_command (0x80904C)
                            |
              +-------------+-------------+
              |             |             |
        boot_scsi_read  boot_tape_read  boot_floppy
        (disk path)     (tape path)     (floppy path)
              |             |             |
              v             v             v
         scsi_setup_command (0x80B052)
              |
              v
     scsi_select_device_and_configure (0x80AC2A)
              |
              v
     wait_for_scsi_ready_or_timeout (0x80AF7A)
              |
              v
     scsi_check_status_or_error (0x80B72C)
```

### Key SCSI Functions

#### `scsi_setup_command` (0x80B052, 156 bytes)

Constructs a SCSI Command Descriptor Block (CDB) in the shared memory area. Takes 6 stack arguments:

1. Target ID
2. SCSI command opcode
3. LUN
4. Block address (shifted left by 1 for sector addressing)
5. Transfer count
6. Zero (reserved)

Writes the CDB to the device control block at `0xC03814 + (target_id * 60)`.

#### `scsi_select_device_and_configure` (0x80AC2A, 338 bytes)

Selects a SCSI target device on the bus:

1. Check if the SCSI bus is free (read `0xC039FC`)
2. Disable interrupts via `0x80851A`
3. Look up control register bits from table at `0x8089B2 + (target_id * 2)`
4. For OMTI targets (ID 0 or 1), conditionally clear bit 12 in control register mirror `0xC03B68`
5. Write selection pattern to hardware: `(1 << target_id) | 0x08` to `0xA70000`
6. Update control register at `0xE0000E`
7. Wait for target to respond (poll bit 1 of `0xE0000E`, timeout ~100,000 iterations)
8. Restore interrupts

#### `boot_scsi_read_boot_block` (0x80AD7E, 96 bytes)

Reads the first block from a SCSI disk to obtain the boot block (sector 0):

1. Call `check_scsi_device_free` (0x80B01E) with string "DISK"
2. Set up SCSI READ command: opcode 8, block address from `0xC03A8C` (shifted left by 1), 2 sectors
3. Extract target ID and LUN from `0xC03A7C`
4. Call `scsi_setup_command` (0x80B052)
5. Call `scsi_execute_and_wait` (0x80AF7A)
6. Call `scsi_wait_completion` (0x80B0F0) with string "DISK"

#### `boot_scsi_read_sector` (0x80B9A6, 92 bytes)

Reads sectors from a SCSI disk for general-purpose block I/O:

- Takes sector count and command opcode as stack arguments
- Uses global state from `0xC03A7C` (unit/LUN) and `0xC03A8C` (block offset)
- Calls `scsi_setup_command` and `scsi_execute_and_wait`
- Prints "DISK" debug strings when verbose mode is active

#### `scsi_read_sector_with_timeout` (0x80B29C, 88 bytes)

Sends TEST UNIT READY commands to check device readiness:

1. Clear transfer size and DMA address globals
2. Build TEST UNIT READY CDB (opcode 1) via `scsi_setup_command`
3. Execute and wait via `0x80AF7A`
4. Check status bits 0-1 at `0xC03804 + 14`
5. Retry up to 32 times on error
6. Return when device is ready or timeout expires

#### `scsi_bus_reset_and_wait` (0x80AA36, 264 bytes)

Performs a SCSI bus reset for error recovery:

1. Read bus status from `0xA70002`
2. Verify only one bit is set (single device responding)
3. Count the bit position (device ID)
4. Assert reset via control register `0xE0000E`
5. Wait for bit 2 to clear (bus free), timeout 1000 iterations
6. Store identified device ID in `0xC039F4`

### SCSI Controller Registers

The SCSI controller interface uses these memory-mapped addresses:

| Address | Access | Description |
|---------|--------|-------------|
| `0xA70000` | Write | SCSI data bus output (selection pattern) |
| `0xA70002` | Read | SCSI bus status |
| `0xE0000E` | R/W | System control register (SCSI control bits, via mirror at `0xC03B68`) |
| `0xE0000F` | Read | Bit 7 = SCSI busy flag |
| `0xE00100` | Write | Reset DMA processor clock interrupt |
| `0xE000A0` | Write | Reset DMA processor software interrupt |

### Device Control Block Structure

Each SCSI target has a 60-byte control block at `0xC03814 + (target_id * 60)`:

```
Offset  Size  Field
+0      1     Device type
+1      1     Flags
+2      8     Configuration data (from OMTI/clock calendar)
+10     2     Status word
+12     8     Command data (2 longwords)
+20     8     Additional parameters
+28     4     Pointer to CDB buffer
+32     4     Control flags
+44     4     Pointer to SCSI CDB (set to 0xC03B6A)
+48     4     Active flag (1 = command pending)
```

### SCSI Target Parameter Initialization (0x80888E, 334 bytes)

Initializes SCSI parameters for up to 8 targets (IDs 0-7):

1. For each target ID 0-8:
   - Clear device type and flags
   - Read 50 words from clock calendar RAM at `0xD0001C` and compute checksum
   - If checksum equals 90 (`0x5A`), configuration is valid: read device type from `0xD0001E + (id * 2)`
   - For target ID 5, force device type to 0 (disabled)
   - Mask device type to 4 bits
   - Look up SCSI timing parameters from ROM table at `0x808930 + type`
   - Set CDB opcode bytes at offsets +10 (`0xC1`) and +12 (`0xC5`)
   - Look up additional parameters from `0x808920 + type`
   - Set transfer size byte at offset +22 (13 = 0x0D)

## Disk Boot Path

### Boot Block Validation (`boot_load_unix_kernel`, 0x80ADE0)

When booting from a SCSI disk:

1. **Wait for device ready** — send TEST UNIT READY up to 300 times with 1ms delay between retries
2. **Read sector 0** — call `scsi_read_sector_with_timeout` (0x80B29C)
3. **Read boot block** — call `boot_scsi_read_boot_block` (0x80AD7E)
4. **Validate boot block magic**:
   - Check word at boot block offset 26 for `0x7064` ("pd" = Plexus disk) or `0x7363` ("sc" = SCSI controller)
   - If neither: print `"BOOT: disk not formatted\n"` and call `fatal_error`
5. **Check controller type** at offset 400:
   - Value 1: valid OMTI 5200 controller
   - Value 0: valid (default controller)
   - Other: print `"BOOT: unknown controller. assuming default\n"` and skip geometry copy
6. **Copy disk geometry** from boot block offset 408 into the device table at `0xC03810 + (target_id * 6)`:
   - 4 bytes + 2 bytes of geometry data (heads, cylinders, sectors per track)
7. **Set up boot control block** at `0xC0380C` from boot block data
8. **Copy kernel parameter string** from boot block

### Loading the Unix Kernel (`load_and_execute_boot_image`, 0x8097AC)

This 706-byte function loads a Unix `a.out` executable and starts the Job processor:

#### a.out Header Reading

Two formats are supported:

| Magic | Format | Read Method |
|-------|--------|-------------|
| `0x0108` | Old-style OMAGIC | Read header word-by-word via `get_next_byte` |
| `0x0150` | New-style NMAGIC | Read header via block reads (`read_block`) |

**Header fields extracted**:
- Text segment size
- Data segment size
- BSS segment size
- Symbol table size (skipped)
- Entry point address

#### Loading Process

1. **Check initialization** — if flag at `0xC03B48` is zero, call `boot_setup_memory_params` (0x808E0E)
2. **Read a.out header** — detect magic number:
   - `0x0108`: read 8 words (16 bytes) via `read_big_endian_longword` (0x809D04)
   - `0x0150`: read via `read_block` (0x808F72)
   - Other: print `"Boot: BAD MAGIC 0x%x\n"` or `"invalid object file (0x%x)"` and abort
3. **Calculate pages** — compute 4KB pages for text and data+BSS segments:
   - `text_pages = (text_size + 4095) / 4096` → store at `0xC03B4C`
   - `data_pages = (data_size + bss_size + 4095) / 4096` → store at `0xC03B50`
4. **Load text+data** — read bytes sequentially via `get_next_byte` (0x808E56) into low memory
5. **Zero BSS** — clear `bss_size` bytes after loaded data
6. **Set up jump table** at address `0x00000000`:
   ```
   [0x0] = 0x77FFF4    (system data pointer / SSP for Job processor)
   [0x4] = boot_arg    (argument for loaded program)
   [0x8] = global      (from 0xC03AA0)
   ```
7. **Print verbose message** if debug flag at `0xC039FC` is set (format string at `0x80C335`: `"ts(%d) ds(%d) bs(%d)\n"`)
8. **Start Job processor**:
   - Write `0x4000` to `0xE00016` (set Boot.JOB bit — release Job processor from reset)
   - Write `0x0002` to `0xE00018` (set KILL.JOB — trigger soft reset)
   - Call `0x80851A` (configure Job processor state)
   - Transfer control to loaded program via pointer at `0xC00404`

## Tape Boot Path

### Tape Device Handling

When booting from tape (`mt()` or `pt()`):

1. The tape device is initialized via entry 1 in the command table (`boot_tape_init` at 0x80B3AE)
2. The file mark number from the `F` parameter determines which file on the tape to load
3. The tape controller seeks to the specified file mark
4. Data is loaded sequentially from the tape into memory

Tape boot uses the same `load_and_execute_boot_image` function as disk boot — the difference is in the underlying SCSI device driver (tape vs disk).

### Tape Error Messages

```
0x80C123: "unable to wake up tape controller"
0x80C145: "bad tape init"
0x80C153: "bad tape read"
0x80C161: "bad tape seek"
0x80C16F: "tape save error"
0x80C17F: "tape recall error"
0x80C1B6: "tape error %X, %X"
0x80C6D5: "TAPE"
```

## Floppy Boot Path

The floppy drive is connected to the OMTI 5200 as SCSI Unit 0, LUN 2. It uses entries 2-3 in the command table, sharing the same SCSI infrastructure but with floppy-specific initialization and error handling.

The floppy path supports formatting operations with the `"Format with interleave of %d\n"` prompt (0x80C667) and an interactive `"Insert disk and press <cr> : "` prompt (0x80C685).

## Disk Utility Commands

### `dtot` — Disk to Tape (0x80B82C)

Copies disk blocks to magnetic tape for backup:

1. Print `"dumping %d disk blocks to tape from block %d\n"`
2. Initialize both disk and tape devices
3. Loop reading 20 blocks at a time from disk via `boot_scsi_read_sector` (0x80B9A6)
4. Write each 20-block chunk to tape via `boot_loader_entry` (0x80B676)
5. Advance disk offset by 20 blocks each iteration
6. Set completion flag at `0xC03B8C` when done

Transfer parameters:
- Buffer at `0xC00400` (shared RAM)
- Transfer size 10240 bytes (10KB = 20 × 512-byte sectors)
- Reads SCSI command 8 (READ), writes SCSI command 10 (WRITE)

### `ttod` — Tape to Disk (0x80B8DC)

Copies tape data back to disk (restore from backup):

1. Print `"really rewrite disk ? "` and wait for confirmation
2. If user types `y` (0x79): proceed with copy
3. Print `"\n%d tape blocks to disk from block %d\n"`
4. Loop reading from tape and writing to disk in 20-block chunks
5. Same buffer and transfer parameters as `dtot`

The confirmation prompt is a safety check against accidental disk overwrites.

## ICP Remote Kernel

The U15 ROM contains an ICP (Inter-processor Communication Protocol) remote kernel that allows the Job processor to communicate with the DMA processor during boot. Evidence for this:

- String at `0x80F4C8`: `",JRemote Kernal : "` (note original spelling "Kernal")
- The `boot_processor_switch` function (0x809DC0) implements temporary Job-processor-mode execution
- The `boot_checksum_and_copy` function (0x809A70) copies a data structure from ROM at `0x80CC60` to shared RAM at `0xC00400`, padding to `0xC03C00`

### Processor Switch Mechanism (0x809DC0)

The DMA processor can temporarily run code as the Job processor:

1. Set bit 8 (`0x0100`) in `0xE00016` — enter Job processor boot mode
2. Save exception vectors from addresses `0x0` and `0x4`
3. Install new vectors (passed as function arguments)
4. Clear flag at `0xC03B58`
5. Set bit 14 (`0x4000`) in `0xE00016` — disable memory mapping
6. Set bit 1 (`0x0002`) in `0xE00018` — release Job processor
7. Poll `0xC03B58` until it becomes non-zero (Job processor signals completion)
8. Clear `0xE00018` — halt Job processor
9. Restore original exception vectors
10. Clear bit 8 in `0xE00016` — exit boot mode

### Boot Loader Main (ICP path, 0x80BA04)

A separate boot path exists for loading via the ICP protocol:

1. Clear `0xC03A80` and `0xC03A7C`
2. Initialize SCSI via `0x80B57A`
3. Loop calling `boot_setup_bootstrap_buffer` (0x80BB04) with incrementing 8KB addresses
4. Load system data to shared memory regions `0xC00000` and `0xC02000`
5. Enable memory mapping: set bit 8 (`0x0100`) in `0xE00016`
6. Load additional segments (0x800 and 0x2800 bytes)
7. Set completion flag at `0xC03B8C`
8. Print `"DONE       \n"` (0x80C789)

## Exception and Interrupt Handling

### Vector Table (0x808000)

The U15 ROM installs its own exception vector table at `0x808000` (set via VBR):

| Vector | Number | Handler | Purpose |
|--------|--------|---------|---------|
| Bus Error | 2 | 0x808400 | Full context save, calls `handle_bus_error_or_parity_error` (0x809ADE) |
| Address Error | 3 | 0x808400 | Same as bus error |
| Illegal Instruction | 4 | 0x808400 | Same as bus error |
| Zero Divide | 5 | 0x808400 | Same as bus error |
| CHK | 6 | 0x808400 | Same as bus error |
| TRAPV | 7 | 0x808400 | Same as bus error |
| Privilege Violation | 8 | 0x808400 | Same as bus error |
| Trace | 9 | 0x808400 | Same as bus error |
| Line 1010 | 10 | 0x808400 | Same as bus error |
| Line 1111 | 11 | 0x808400 | Same as bus error |
| SW Interrupt | — | 0x808478 | Write `%d0` to `0xE000A0` (clear SW interrupt), `rte` |
| Clock Interrupt | — | 0x808480 | Write 1 to `0xE00100` (clear clock interrupt), `rte` |
| SCSI/Serial IRQs | — | 0x80848A+ | Context save, call specific handler, restore, `rte` |

### Interrupt Service Routines

The vector table dispatches to these handlers for hardware interrupts:

| Handler | Address | Purpose |
|---------|---------|---------|
| `boot_checks_and_init` | 0x80A622 | SCSI data-out interrupt |
| `boot_checks_and_init` | 0x80A5A8 | SCSI data-in interrupt |
| `boot_phase2_checks` | 0x80A9BC | SCSI status interrupt |
| `scsi_init_or_reset_device` | 0x80A692 | SCSI command-out interrupt |
| `boot_init_scsi_drive` | 0x80A90E | SCSI message-in interrupt |
| `scsi_controller_init` | 0x80A7E2 | SCSI message-out interrupt |
| `scsi_init_device` | 0x80A3F8 | SCSI selection interrupt |
| `scsi_bus_reset_and_wait` | 0x80AA36 | SCSI reselection interrupt |
| `empty_stack_frame` | 0x80B016 | No-op handler (unused vectors) |

Each handler follows the same pattern:
```
moveml %d0-%fp,%sp@-     ; save all 16 registers
jsr handler_address       ; call specific handler
moveml %sp@+,%d0-%fp     ; restore all registers
rte                       ; return from exception
```

### Bus Error / Parity Error Handler (0x809ADE)

Distinguishes between parity errors (code `0x104`) and other bus errors:

- **Parity error**: Clear parity flag by writing to `0xE00160`, set flag at `0xC03B62`, return
- **Other bus errors**: Print diagnostic info (error code, faulting address, status) via `printf`, call `fatal_error` (0x809266) — does not return

### Bad Interrupt Handler (0x80BBBE)

Dumps hardware registers when an unexpected interrupt occurs:

```
"BOOT : Bad Interrupt : cmd %x dev %x\n"
"I_PERR1 0x%x I_PERR2 0x%x I_MBERR 0x%x\n"
"I_SC_C 0x%x 0x%x  I_SC_P 0x%x 0x%x I_SC_R 0x%x\n"
"I_ERR 0x%x I_MISC 0x%x I_KILL 0x%x I_TRCE 0x%x I_USER 0x%x\n"
```

After dumping all registers, enters an infinite loop (`bra.s *` at 0x80BC78).

## Error Handling

### Error Dispatch (`boot_error_handler`, 0x809266)

On any fatal error:
1. Print error message via `printf` (0x809F94) with format string `"Exit %d"` at `0x80C1DB`
2. Call `0x80928C` which prints the address and calls `0x808560` to restart the boot loader
3. Returns to the boot menu prompt

### Filesystem Errors

| Address | Message | Cause |
|---------|---------|-------|
| 0x80C058 | `invalid object file (0x%x)` | Bad a.out magic number |
| 0x80C077 | `%s: not found` | File not found in directory |
| 0x80C085 | `bad directory` | Inode is not a directory |
| 0x80C093 | `bad bn %D` | Block number out of range |
| 0x80C09D | `unknown device` | Unrecognized device specifier |
| 0x80C0AC | `bad offset or unit specification` | Invalid SCSI params |
| 0x80C1C8 | `file` | File not found (short form) |
| 0x80C2EF | `Boot: BAD MAGIC 0x%x` | Invalid a.out magic |
| 0x80C306 | `illegal system V a.out magic %o` | Wrong a.out type |
| 0x80C327 | `text protect` | Text segment protection error |

### SCSI/Disk Errors

| Address | Message | Cause |
|---------|---------|-------|
| 0x80C0CD | `unable to wake up disk controller` | OMTI 5200 not responding |
| 0x80C0EF | `bad disk init` | Controller initialization failed |
| 0x80C0FD | `bad disk read` | SCSI read error |
| 0x80C10B | `invalid disk init block` | Boot block validation failure |
| 0x80C1A4 | `disk error %X, %X` | SCSI error with status codes |
| 0x80C58F | `BOOT: disk not formatted` | No valid boot block |
| 0x80C5A9 | `BOOT: unknown controller. assuming default` | Unknown controller type |
| 0x80C5D5 | `BOOT: Phony scsi address %x` | Invalid SCSI address |
| 0x80C5F2 | `BOOT: SCSI device %d failed` | Device failure |
| 0x80C610 | `BOOT: %s: scdevice not free` | SCSI bus busy |
| 0x80C62D | `Scsi device %d command %x` | SCSI command trace |
| 0x80C648 | `Error Code %x %x %x %x` | Detailed error codes |
| 0x80C6DA | `Scsi command %x Error Code 0x%x` | Command failure |
| 0x80C6FB | `residue bytes %x %x %x` | Incomplete transfer |

### OMTI 5200 Controller Errors

| Address | Message | OMTI Error |
|---------|---------|------------|
| 0x80C886 | `No index signal` | Drive spindle not running |
| 0x80C896 | `No seek complete` | Head positioning failed |
| 0x80C8A7 | `Write fault` | Write head failure |
| 0x80C8B3 | `Drive not ready` | Drive not spun up |
| 0x80C8C3 | `Drive not selected` | Drive selection failed |
| 0x80C8D6 | `No track 00` | Cannot find track 0 |
| 0x80C8E2 | `Multiple Winchester drives selected` | Bus contention |
| 0x80C906 | `Media change` | Floppy disk changed |
| 0x80C913 | `Seek in progress` | Previous seek not complete |
| 0x80C924 | `ID read error (ECC) error in the ID field` | Header ECC error |
| 0x80C94E | `Uncorrectable data error during a read` | Data ECC failure |
| 0x80C975 | `ID address mark not found` | Missing sector header |
| 0x80C98F | `Data address not found` | Missing data area |
| 0x80C9A6 | `Record not found` | Sector not found |
| 0x80C9B7 | `Seek error` | Head positioning error |
| 0x80C9C2 | `Write protected` | Disk is write-protected |
| 0x80C9D2 | `Correctable data field error` | ECC-corrected read |
| 0x80C9EF | `Bad block found` | Defective sector |
| 0x80C9FF | `Format error` | Low-level format problem |
| 0x80CA0C | `Unable to read alternate track address` | Defect management error |
| 0x80CA33 | `Attempted to directly access an alternate track` | Bad track access |
| 0x80CA63 | `Sequence time out during disk to host transfer` | DMA timeout |
| 0x80CA92 | `Invalid command from host` | Bad SCSI command |
| 0x80CAAC | `Illegal disk address ( beyond maximum )` | Block out of range |

### SCSI Debug Strings (Verbose Mode)

When verbose mode is enabled (`!` prefix), these strings are printed as the boot loader enters each SCSI bus phase:

```
"BOOT: "                                    (0x80C48F)
"Enter arbit\n"                             (0x80C496)
"Enter select\n"                            (0x80C4A3)
"scsi busy not set by target\n"             (0x80C4B1)
"Enter scrwi\n"                             (0x80C4CE)
"Enter s_d_i_int\n"                         (0x80C4DB)
"Enter s_d_o_int\n"                         (0x80C4EC)
"Enter s_s_i_int\n"                         (0x80C4FD)
"Enter s_m_i_int\n"                         (0x80C50E)
"Enter s_m_o_int\n"                         (0x80C51F)
"Enter s_c_o_int\n"                         (0x80C530)
"Enter resel\n"                             (0x80C541)
"Boot: scsi abort\n"                        (0x80C54E)
"Enter saveptrs\n"                          (0x80C560)
"Enter loadptrs\n"                          (0x80C570)
```

The abbreviations correspond to SCSI bus phases:
- `arbit` = Arbitration
- `select` = Selection
- `scrwi` = SCSI read/write initiate
- `s_d_i_int` = SCSI Data-In interrupt
- `s_d_o_int` = SCSI Data-Out interrupt
- `s_s_i_int` = SCSI Status-In interrupt
- `s_m_i_int` = SCSI Message-In interrupt
- `s_m_o_int` = SCSI Message-Out interrupt
- `s_c_o_int` = SCSI Command-Out interrupt
- `resel` = Reselection
- `saveptrs` = Save Data Pointers
- `loadptrs` = Restore Data Pointers

## Shared Memory Variables

### Boot State Variables (0xC03A00 region)

| Address | Size | Name | Description |
|---------|------|------|-------------|
| 0xC03A08 | 4 | buffer_base | Base of indirect block buffer area |
| 0xC03A0C | 12 | ind_cache[3] | Cached indirect block addresses (3 levels) |
| 0xC03A20 | 1 | boot_flags | Bit 3: filesystem mode (vs raw device) |
| 0xC03A24 | ~64 | inode_buf | Working inode buffer |
| 0xC03A30 | 2 | device_index | Command table index for current device |
| 0xC03A32 | 2 | cur_ino | Current inode number |
| 0xC03A34 | 2 | di_mode | Current inode mode (cached) |
| 0xC03A3C | 4 | di_size | Current file size (cached) |
| 0xC03A40 | 52 | i_addr[13] | Unpacked block addresses (4 bytes each) |
| 0xC03A7C | 4 | scsi_unit | SCSI unit encoding: `(phys_unit << 1) | LUN` |
| 0xC03A80 | 4 | part_start | Partition start (512-byte physical blocks) |
| 0xC03A88 | 4 | file_offset | Current byte position in file |
| 0xC03A8C | 4 | disk_block | Current disk block to read |
| 0xC03A90 | 4 | buf_ptr | Current buffer pointer (DMA address) |
| 0xC03A94 | 4 | buf_remain | Bytes remaining in buffer |
| 0xC03A98 | 4 | buf_base | Base address of 1KB I/O buffer |
| 0xC03A9C | 4 | verbose_flag | Non-zero = verbose/debug output enabled |
| 0xC03AA0 | 4 | boot_global | Global value passed to loaded program at [0x8] |
| 0xC03AA4 | 4 | boot_block_ptr | Pointer to boot block data in buffer |
| 0xC03ABC | varies | input_buffer | Console input line buffer |

### System/Device State (0xC03800 region)

| Address | Size | Name | Description |
|---------|------|------|-------------|
| 0xC03804 | 4 | sys_data_base | System data area pointer (= 0xC00000) |
| 0xC03808 | 4 | secondary_data | Secondary data area pointer (= 0xC0001A) |
| 0xC0380C | varies | boot_control | Boot control block (from boot block data) |
| 0xC0380D | 1 | scsi_cmd_ready | 0xFF when SCSI commands are ready |
| 0xC03810 | varies | device_geometry | Disk geometry table (6 bytes per target) |
| 0xC03814 | 480 | scsi_dcb[8] | Device control blocks (8 × 60 bytes) |

### Miscellaneous State

| Address | Size | Name | Description |
|---------|------|------|-------------|
| 0xC00274 | 2 | boot_magic | Warm boot signature (0x04D2 = 1234) |
| 0xC039F4 | 4 | current_scsi_id | Current SCSI target being accessed |
| 0xC039F8 | 4 | prev_scsi_id | Previous SCSI target (-1 = none) |
| 0xC039FC | 4 | scsi_busy_flag | Non-zero = SCSI bus is busy |
| 0xC03B24 | 1 | init_flag | Cleared during initialization |
| 0xC03B40 | 4 | init_flag_copy | Copy of init_flag |
| 0xC03B44 | 4 | scsi_phase_count | SCSI bus phase counter |
| 0xC03B48 | 4 | stream_mode | 0 = buffered I/O, non-zero = direct memory read |
| 0xC03B4C | 4 | text_pages | Text segment pages (set by a.out loader) |
| 0xC03B50 | 4 | data_pages | Data+BSS segment pages |
| 0xC03B58 | 4 | ipc_done_flag | Set by Job processor to signal completion |
| 0xC03B60 | 4 | parity_test_flag | Non-zero during RAM parity testing |
| 0xC03B62 | 2 | parity_error | Set to 1 if parity error detected |
| 0xC03B64 | 4 | stream_ptr | Current byte pointer for stream reads |
| 0xC03B68 | 4 | ctrl_reg_mirror | Mirror of control register at 0xE0000E |
| 0xC03B6A | 1 | scsi_cdb_byte | SCSI command byte (e.g. 0x08 = READ) |
| 0xC03B6C | 4 | scsi_select_data | Data for SCSI selection phase |
| 0xC03B70 | 4 | scsi_status_reg | SCSI controller status readback |
| 0xC03B8C | 4 | completion_flag | Set to 1 when disk/tape operation completes |
| 0xC03B94 | 2 | running_checksum | Accumulated checksum for ICP protocol |
| 0xC03B98 | 4 | checksum_sentinel | -1 when checksum not initialized |

## RAM Size Detection (`detect_ram_size`, 0x809CA0)

The boot loader probes installed RAM by writing unique values to each 256KB block:

1. Set testing flag at `0xC03B60`
2. Starting at `0x800000` (below ROM), write each address to itself, stepping down by 256KB
3. Scan upward from `0x000000`, counting blocks where readback matches
4. If parity error flag `0xC03B62` becomes non-zero, stop early
5. Return count of valid 256KB blocks in `%d0`
6. Clear testing flag

Maximum detectable RAM: 8MB (32 × 256KB blocks from `0x000000` to `0x7FFFFF`).

## Printf Implementation (`printf_style_formatter`, 0x809F94)

The boot ROM includes a minimal `printf`-style formatter supporting:

| Format | Description |
|--------|-------------|
| `%d` | Signed decimal |
| `%x` | Hexadecimal (lowercase) |
| `%X` | Hexadecimal (uppercase) |
| `%o` | Octal |
| `%s` | String |
| `%D` | Long decimal (32-bit) |

Output is sent to the console serial port via `serial_send_break_or_loop` (0x80A0D6).

## Comparison with Z8000 Boot Loader

The P/20's 68010 boot loader is a direct descendant of the earlier Z8000-based Plexus boot loader (`Src/Sys3_v1.1/stand/z8000/boot.c`):

| Feature | Z8000 (boot.c) | P/20 (U15 ROM) |
|---------|----------------|-----------------|
| Banner | `"PLEXUS PRIMARY BOOT REV 1.0"` | `"PLEXUS PRIMARY BOOT REV 1.2"` |
| Tape prefix | `mt(,N)` | `pt(,N)` (also accepts `mt`) |
| Default boot | `sc(0,0)/unix` | `sc(0,0)/unix` |
| Match function | `match()` with `(` terminator | `strncmp_or_nullterm_match` (0x808DC2) |
| Max name length | 14 (DIRSIZ) | 14 (DIRSIZ) |
| a.out magic | 0407, 0411 (octal) | 0x0108, 0x0150 |
| Short codes | 18 entries (includes boot, v7, sys3, dconfig, sash, diag) | 16 entries (unix instead of v7/sys3, ccal instead of dconfig) |
| Tape position 1 | `boot` | unused |
| Tape position 11 | `sash` | unused |
| Verbose mode | Not in source | `!` prefix sets `0xC03A9C` |
| Filesystem | s5fs read-only | s5fs read-only (see docs/filesystem.md) |
| Disk utilities | Not in PROM | `dtot`, `ttod` built-in |
| Auto-boot | `AUTOBOOT` macro | Similar, 30-second timeout on retry |

## Complete Boot Flow: `sc(0,0)/unix`

1. User presses Enter (or system auto-boots)
2. Empty input defaults to `"sc(0,0)/unix"` via default string at `0x80C1D2`
3. `parse_boot_command` matches `"sc"` in command table (index 0)
4. Extracts: controller=0, unit=0, partition=0 → `0xC03A7C=0`, `0xC03A80=0`
5. Path `/unix` detected → set filesystem mode (bit 3 of `0xC03A20`)
6. `dispatch_boot_command` calls `boot_load_unix_kernel` (0x80ADE0):
   - Wait for OMTI 5200 ready (up to 300 retries)
   - Read boot block (sector 0), validate magic ("pd" or "sc")
   - Copy disk geometry to device table
7. `boot_initialize_scsi_or_filesystem` (0x80B6BC):
   - Read superblock (block 1) to get filesystem parameters
   - Set up filesystem I/O state
8. `parse_path_components` resolves `/unix`:
   - `read_inode(2)` — load root directory inode
   - `search_directory("unix")` — find `unix` entry in root directory
   - Returns inode number of `/unix`
9. `load_and_execute_boot_image` (0x8097AC):
   - Read a.out header (magic 0x0108 or 0x0150)
   - Calculate text/data/BSS pages
   - Load text+data segments byte-by-byte into low memory
   - Zero BSS
   - Set up jump table at address 0x0
   - Write Boot.JOB (0x4000) to 0xE00016
   - Write KILL.JOB (0x0002) to 0xE00018
   - Job processor starts executing Unix kernel
