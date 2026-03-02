# Plexus P/20 Boot ROM Analysis

## Overview

The Plexus P/20 uses two pairs of boot ROMs for the DMA processor (Motorola 68010):

- **U17** (32KB at 0x800000): Self-test, diagnostics, and debug monitor
- **U15** (32KB at 0x808000): Boot loader, SCSI drivers, and Unix loader

This document provides a comprehensive analysis of every identified function in both ROMs,
generated through automated disassembly and AI-assisted analysis.

## Memory Map

| Range | Size | Description |
|-------|------|-------------|
| 0x000000-0x3FFFFF | 4MB | Main RAM |
| 0x800000-0x807FFF | 32KB | U17 ROM (Self-test/Debug) |
| 0x808000-0x80FFFF | 32KB | U15 ROM (Boot Loader) |
| 0xC00000-0xC00FFF | 4KB | Shared variables area |
| 0xE00000-0xE001FF | 512B | Hardware registers |

## U17 Vector Table

| Vector | Number | Address | Handler |
|--------|--------|---------|---------|
| Reset PC | 1 | 0x800708 | dma_processor_init |
| Bus Error | 2 | 0x800410 |  |
| Address Error | 3 | 0x80047a |  |
| Illegal Instruction | 4 | 0x800484 |  |
| Zero Divide | 5 | 0x8004c0 | exception_handler_common |
| CHK | 6 | 0x8004c0 | exception_handler_common |
| TRAPV | 7 | 0x8004c0 | exception_handler_common |
| Privilege Violation | 8 | 0x8004c0 | exception_handler_common |
| Trace | 9 | 0x8004c0 | exception_handler_common |
| Line 1010 | 10 | 0x8004c0 | exception_handler_common |
| Line 1111 | 11 | 0x8004c0 | exception_handler_common |
| Spurious Interrupt | 24 | 0x80048c | spurious_interrupt_handler |
| TRAP #0 | 32 | 0x800480 |  |

## U15 Vector Table

| Vector | Number | Address | Handler |
|--------|--------|---------|---------|
| Reset PC | 1 | 0x80854a | scsi_write_cdb |
| Bus Error | 2 | 0x808400 | exception_vector_handlers |
| Address Error | 3 | 0x808400 | exception_vector_handlers |
| Illegal Instruction | 4 | 0x808400 | exception_vector_handlers |
| Zero Divide | 5 | 0x808400 | exception_vector_handlers |
| CHK | 6 | 0x808400 | exception_vector_handlers |
| TRAPV | 7 | 0x808400 | exception_vector_handlers |
| Privilege Violation | 8 | 0x808400 | exception_vector_handlers |
| Trace | 9 | 0x808400 | exception_vector_handlers |
| Line 1010 | 10 | 0x808400 | exception_vector_handlers |
| Line 1111 | 11 | 0x808400 | exception_vector_handlers |

---

# U17: Self-test/Debug Monitor

## U17 Function Summary

| Address | Size | Name | Description |
|---------|------|------|-------------|
| 0x80047a | - | (stub) | Stub/data at 0x80047a (2 instructions) |
| 0x800480 | - | (stub) | Stub/data at 0x800480 (2 instructions) |
| 0x800484 | - | (stub) | Stub/data at 0x800484 (2 instructions) |
| 0x80048c | 50 | `spurious_interrupt_handler` | This function handles spurious interrupts on the DMA processor. It first pushes an exception vector  |
| 0x8004c0 | 286 | `exception_handler_common` | This function serves as a common entry point for multiple Motorola 68010 exception handlers. It save |
| 0x8005e0 | 30 | `delay_cycles` | This function implements a variable-length delay loop. It takes an input parameter, multiplies it by |
| 0x800600 | 14 | `multiply_words_or_enter_debug` | This function serves as a dual-purpose entry point: when called with no parameters (or with D0=1), i |
| 0x800610 | 22 | `set_sr_interrupt_mask` | This function modifies the Status Register (SR) of the 68010, specifically the interrupt mask field  |
| 0x800628 | 26 | `dma_processor_init` | This function appears to be part of the DMA processor's early initialization or self-test sequence.  |
| 0x800646 | 24 | `initialize_debug_monitor` | This function initializes a debug monitor environment by clearing a shared memory variable, calling  |
| 0x800664 | 102 | `initialize_system_stack_and_check_boot_flag` | This function initializes the system stack pointer based on a hardware status bit, performs a stack  |
| 0x8006d0 | 46 | `check_and_clear_boot_flag` | This function checks a system flag stored at address `0xC00640` (likely a shared RAM location used f |
| 0x800700 | - | (stub) | Stub/data at 0x800700 (2 instructions) |
| 0x800708 | 46 | `dma_processor_init` | This function is the initial entry point for the DMA processor after reset. It sets up the Vector Ba |
| 0x800738 | 998 | `selftest_main` | This function is the primary self-test and initialization routine for the DMA processor, executed fr |
| 0x800b20 | 120 | `dma_processor_ram_test` | This function performs a two-phase RAM test on the DMA processor's memory space, starting at address |
| 0x800b9a | 216 | `perform_memory_test_sequence` | This function executes a three-phase memory test sequence on a specified memory region, likely as pa |
| 0x800c74 | 28 | `boot_jump_to_ram_test` | This function copies a small code block from ROM to a fixed address in RAM (0x1000) and then jumps t |
| 0x800c92 | 40 | `boot_jump_to_ram_loader` | This function relocates a small trampoline routine from ROM to a fixed address in RAM (0x1100), sets |
| 0x800cbc | 10 | `memcpy_10_words` | This function copies 10 long words (40 bytes) from a source memory location pointed to by address re |
| 0x800cc8 | 14 | `trigger_dma_processor_software_interrupt` | This function generates a software interrupt to the DMA processor by writing to the "Set DMA process |
| 0x800cd8 | 6 | `swap_endian_32bit_word` | This function performs a byte-order swap on a 32-bit value, converting between big-endian and little |
| 0x800ce0 | 32 | `memcpy_long_aligned` | This function copies a block of memory in 32-bit longword units from a source address to a destinati |
| 0x800d02 | 30 | `memory_clear_longwords` | This function clears a block of memory by writing zeros to it in 32-bit longword increments. It take |
| 0x800d22 | 44 | `write_words_with_rounding` | This function writes a sequence of 16-bit words to memory, using a 32-bit count that is halved and r |
| 0x800d50 | 40 | `memcpy_long_aligned` | This function copies a block of memory from a source address to a destination address, using longwor |
| 0x800d7a | 40 | `memory_fill_words` | This function fills a block of memory with a repeated 16-bit pattern. It takes a base address and a  |
| 0x800da4 | 48 | `memset_32bit_pattern` | This function fills a memory region with a repeating 32-bit pattern, where the pattern is the bitwis |
| 0x800dd6 | 32 | `memcpy_word_aligned` | This function copies a block of memory from a source address to a destination address, using word-si |
| 0x800df8 | - | (stub) | Stub/data at 0x800df8 (2 instructions) |
| 0x800e04 | - | (stub) | Stub/data at 0x800e04 (2 instructions) |
| 0x800e10 | 44 | `check_boot_source_or_fallback` | This function determines whether to boot from the primary or alternate boot source based on a hardwa |
| 0x800e3e | - | (stub) | Stub/data at 0x800e3e (2 instructions) |
| 0x800e46 | 26 | `increment_word_with_alternate_space` | This function increments a 16-bit word located at a given memory address, but performs the read and  |
| 0x800e62 | 36 | `set_vbr_and_jump_to_0x802330` | This function sets the Vector Base Register (VBR) to 0x00800000 (the start of the U17 ROM region) an |
| 0x800e8c | 46 | `initialize_vbr_and_jump` | This function sets up the Vector Base Register (VBR) to point to the start of the U17 ROM (0x0080000 |
| 0x800ec0 | - | (stub) | Stub/data at 0x800ec0 (2 instructions) |
| 0x800ec8 | 12 | `save_sp_and_call_0x80621a` | This function saves the current value of the stack pointer (SP) into a fixed memory location in the  |
| 0x800ed6 | 10 | `set_exception_handler` | This function installs an exception handler by copying a handler address from a fixed memory locatio |
| 0x800ee2 | 18 | `save_stack_frame_pointers` | This function saves the current stack pointer (SP) and frame pointer (FP) of the DMA processor into  |
| 0x800ef6 | 14 | `switch_to_alternate_stack_and_jump` | This function performs a context switch to an alternate stack frame stored in shared memory, then ju |
| 0x800f06 | 140 | `read_dma_int_status` | This function reads the processor control/status register at 0xE00018 to check whether the DMA proce |
| 0x800f94 | 146 | `self_test_delay_loop` | This function performs a timed delay loop (approximately 300 iterations) while preserving a shared m |
| 0x801028 | 56 | `selftest_shared_memory_vectors` | This function iterates over eight consecutive 32-bit values stored in a table at ROM address 0x80231 |
| 0x801062 | 108 | `self_test_main` | This function appears to be the main diagnostic/self-test entry point called early in the boot proce |
| 0x8010d0 | 110 | `led_pattern_sequence` | This function cycles through a sequence of LED patterns stored in a table, displaying each pattern o |
| 0x801140 | 260 | `selftest_sequence` | This function runs a series of self‑test routines (likely hardware diagnostics) indexed from 3 to 15 |
| 0x8012cc | 140 | `parse_hex_digit_sequence` | This function reads a sequence of ASCII characters from a memory location (`0xC006E2`) and interpret |
| 0x80135a | 62 | `skip_whitespace` | This function reads a byte from a memory-mapped location (likely a hardware register or shared memor |
| 0x80139a | 176 | `selftest_memory_bus_arbitration` | This function performs a memory bus arbitration test by writing known values to specific memory loca |
| 0x80144c | 70 | `compare_and_report_mismatch` | This function compares two 32-bit values (likely memory addresses or data values) and, if they diffe |
| 0x801494 | 78 | `check_diagnostic_flag_or_report_error` | This function appears to be part of the diagnostic/self‑test logic in the U17 ROM. It checks the res |
| 0x8014e4 | 70 | `compare_and_log_mismatch` | This function compares two 32-bit values (likely memory addresses or data values) and, if they diffe |
| 0x80152c | 44 | `conditional_debug_print` | This function checks a global flag at address `0xC00644`. If the flag is non-zero, it calls a debug  |
| 0x80155a | 52 | `store_word_to_dynamic_table` | This function stores a 16-bit word value (passed on the stack) into the next available slot in a tab |
| 0x801590 | 468 | `scsi_verify_drive_presence` | This function appears to perform a SCSI drive presence check and possibly a basic inquiry or test. I |
| 0x801766 | 174 | `scsi_diagnostic_or_boot_check` | This function appears to perform a SCSI-related diagnostic or boot device check. It first attempts a |
| 0x801816 | 2006 | `handle_interrupt_or_exception` | This is a multi-part function that appears to handle various system events and perform comprehensive |
| 0x801fee | 832 | `selftest_memory_and_cache` | This function performs a comprehensive memory and cache diagnostic test. It appears to be part of th |
| 0x8024c0 | 242 | `parse_debug_command_argument` | This function parses a debug monitor command argument string from a global input buffer, extracting  |
| 0x8025b4 | 3936 | `debug_command_dispatcher` | This function is the main dispatch handler for the Plexus P/20's self‑test/debug monitor command int |
| 0x803516 | 48 | `debug_print_string_with_delay` | This function prints a string to the debug console with a specified delay between characters. It tak |
| 0x8037e2 | 240 | `scsi_verify_blocks` | This function appears to iterate through a list of SCSI block transfer descriptors, verifying each b |
| 0x8038d4 | 94 | `verify_rom_checksum` | This function computes a byte-wise checksum over a specific ROM region (from address `0x00D0001C` to |
| 0x803934 | 70 | `checksum_rom_block` | This function calculates an 8‑bit checksum (modulo 256) of a block of ROM data from address `0x00D00 |
| 0x80397c | 76 | `confirm_or_abort` | This function checks a global flag at `0xC00802`; if the flag is non-zero, it prompts the user with  |
| 0x8039ca | 742 | `memory_test_pattern` | This function performs a comprehensive memory test over a specified address range, using multiple pa |
| 0x803cb2 | 426 | `debug_memory_pattern_test` | This function appears to be a diagnostic routine that compares memory data against expected patterns |
| 0x803e5e | 62 | `compute_parity_bit` | This function calculates the odd parity bit of an 8‑bit byte passed by reference. It iterates over e |
| 0x803e9e | 134 | `dual_processor_memory_test` | This function performs a two-phase memory test on a specified region, first using the DMA processor  |
| 0x803f26 | 164 | `memory_pattern_test` | This function performs a memory test over a specified address range by writing a sequential byte pat |
| 0x803fcc | 104 | `verify_or_update_checksum` | This function appears to be a checksum verification and update routine, likely used during self‑test |
| 0x804036 | 2834 | `selftest_memory_and_scsi` | This function performs a comprehensive system self‑test, focusing on memory (RAM) and SCSI controlle |
| 0x804b4a | 1136 | `dma_processor_self_test` | This function performs a comprehensive self-test of the DMA processor and its interaction with share |
| 0x804fbc | 56 | `wait_for_dma_flag_or_timeout` | This function waits for a DMA processor flag (likely a hardware operation completion indicator) to c |
| 0x804ff6 | 248 | `dma_processor_scsi_poll` | This function appears to be the DMA processor's main loop for handling SCSI operations, likely polli |
| 0x8050f0 | 218 | `dma_processor_main_loop` | This function appears to be the main supervisory loop for the DMA processor after initial self‑test. |
| 0x8051cc | 236 | `execute_scsi_command_or_diagnostic` | This function appears to be part of the SCSI command execution or diagnostic system in the Plexus P/ |
| 0x8052ba | 176 | `scsi_command_dispatch` | This function appears to be the main SCSI command dispatcher for the DMA processor. It reads a SCSI  |
| 0x80536c | 396 | `boot_processor_switch_or_reset` | This function manages the transition between the DMA processor's self-test/debug monitor and the mai |
| 0x8054fa | 210 | `scsi_command_with_timeout` | This function appears to execute a SCSI command via the DMA processor’s SCSI controller, using a pre |
| 0x8055ce | 134 | `scsi_command_with_timeout` | This function sends a SCSI command to the Omti 5200 controller and waits for its completion with a t |
| 0x805656 | 122 | `initialize_shared_memory_and_boot_control` | This function initializes a block of shared memory in the DMA processor's address space (either at 0 |
| 0x8056d2 | 64 | `debug_get_and_clear_char_at_index` | This function retrieves a single character from one of two debug character arrays in shared RAM, bas |
| 0x805714 | 68 | `set_boot_device_flag_and_clear_string` | This function determines which processor (DMA or Job) is currently executing based on a hardware tes |
| 0x80575a | 30 | `clear_boot_flag_based_on_test` | This function calls a diagnostic subroutine at 0x800f06 (likely a hardware self-test or status check |
| 0x80577a | 56 | `get_and_clear_shared_byte` | This function retrieves a single byte from a shared memory lookup table, clears that byte to zero, a |
| 0x8057b4 | 106 | `process_bus_error_details` | This function reads the bus error status register, processes the error details to count specific err |
| 0x805820 | 102 | `write_to_special_address_or_fallback` | This function attempts to write a byte value to a memory-mapped hardware address derived from a base |
| 0x805888 | 106 | `scsi_send_command_or_fallback` | This function attempts to send a SCSI command via the DMA processor's SCSI interface, but if the SCS |
| 0x8058f4 | 58 | `disable_processor_serial_interrupts` | This function disables serial port interrupts for either the DMA or Job processor based on a system  |
| 0x805930 | 30 | `wait_for_scsi_operation_completion` | This function waits for a pending SCSI operation to complete. It first checks a global flag at `0xC0 |
| 0x805950 | 60 | `is_address_in_rom_range` | This function determines whether a given 32-bit address falls within one of two specific ROM address |
| 0x80598e | 76 | `verify_or_install_boot_block` | This function appears to validate and possibly install a boot block or boot-related data structure.  |
| 0x8059dc | 66 | `scsi_write_sector_or_set_word` | This function appears to be part of the SCSI disk I/O subsystem. It attempts to write a sector (or b |
| 0x805a20 | 76 | `validate_and_send_scsi_command` | This function validates a SCSI command block (likely a pointer to a SCSI CDB structure) by performin |
| 0x805a6e | 64 | `scsi_send_command_or_fallback` | This function appears to be part of the SCSI command-handling logic in the DMA processor’s ROM. It f |
| 0x805ab0 | 102 | `scsi_wait_ready_or_timeout` | This function waits for the SCSI controller to become ready (by polling a status register) for up to |
| 0x805b18 | 24 | `debug_print_string_with_dot` | This function prints a string (passed as a parameter) followed by a period (ASCII `'.'`, hex `0x2E`) |
| 0x805b32 | 62 | `debug_led_and_log_event` | This function checks if a global flag is set, and if so, updates the hardware LED display based on a |
| 0x805b72 | 42 | `print_diagnostic_result` | This function calls a diagnostic subroutine at `0x800f06` and prints one of two messages based on th |
| 0x805b9e | 80 | `configure_dma_transfer` | This function sets up a DMA transfer by configuring the system control register, scaling input addre |
| 0x805bf0 | 1576 | `scsi_command_execute` | This function handles SCSI command execution for the Plexus P/20's DMA processor. It manages SCSI co |
| 0x80621a | 1198 | `scsi_command_execute` | This function handles the execution of a SCSI command on the Omti 5200 controller. It initializes th |
| 0x8066ca | 398 | `configure_dma_transfer` | This function configures DMA parameters for a SCSI transfer based on a device ID parameter, sets up  |
| 0x80685a | 196 | `handle_diagnostic_command` | This function processes a diagnostic command code (likely from a debug monitor or self‑test menu) by |
| 0x806920 | 192 | `dma_processor_interrupt_handoff` | This function appears to manage the handoff of control between the DMA processor and the Job process |
| 0x8069e2 | 756 | `scsi_probe_devices` | This function performs a SCSI bus scan to detect and identify attached devices (likely disks and flo |
| 0x806cd8 | 698 | `selftest_scsi_devices` | This function performs a diagnostic self-test of the SCSI subsystem, checking the status of the SCSI |
| 0x806f94 | 826 | `scsi_dma_transfer` | This function performs a SCSI data transfer operation using the OMTI 5200 controller, likely for rea |
| 0x8072d2 | 180 | `debug_monitor_input_loop` | This function implements a debug monitor input loop that processes serial input characters, handles  |
| 0x807388 | 242 | `scsi_select_and_init` | This function appears to handle SCSI device selection and initialization, likely for booting or diag |
| 0x80747c | 146 | `scsi_command_with_timeout` | This function sends a SCSI command to the Omti 5200 controller and waits for completion with a confi |
| 0x80765a | 94 | `print_hex_nibbles` | This function takes a 32-bit integer input and prints its hexadecimal representation by extracting a |
| 0x8076ba | 90 | `serial_send_char_with_delay` | This function transmits a character to a serial port (likely the console SCC) after waiting for the  |
| 0x807716 | 158 | `handle_serial_input` | This function processes a byte of serial input data, interpreting it as a command or control charact |
| 0x8077b6 | 202 | `process_escape_sequence` | This function processes a stream of characters (likely from a serial console input) and interprets s |
| 0x807882 | 628 | `selftest_run_test` | This function appears to be the main self‑test runner for the Plexus P/20 DMA processor. It executes |
| 0x807af8 | 374 | `debug_string_table` | This is not a function but a data section containing embedded ASCII strings used by the U17 debug/mo |
| 0x807c70 | 50 | `exception_handler_table_init` | This function initializes a table of exception handler strings in memory, likely for a debug monitor |
| 0x807cb0 | 442 | `exception_handler_common` | This function serves as a common exception‑handling and diagnostic‑reporting routine for the DMA pro |
| 0x807e70 | 196 | `print_system_configuration` | This function prints a formatted system configuration report, comparing actual hardware status again |

## U17 Detailed Function Documentation

### Function at 0x80048c

**Embedded strings:**
- `8389884`: `"fJ"<"`

**Name**: `spurious_interrupt_handler`  

**Purpose**:  
This function handles spurious interrupts on the DMA processor. It first pushes an exception vector offset (0x18) onto the stack, then branches to a common exception handler. However, before doing so, it checks the state of the Job processor’s interrupt request line (bit 7 of the processor status register at 0xE00019) and validates a signature word in shared RAM. If the signature matches a specific value (0x9A16) at certain locations, it either proceeds to the default exception handler or returns from the exception (RTE) to avoid disrupting a valid inter-processor communication (IPC) handshake.

**Parameters**:  
- None explicitly passed, but the function reads:
  - Hardware register 0xE00019 (processor status) to check Job processor interrupt state.
  - Shared RAM locations 0xC004B4 and 0xC004B6 for signature comparison.

**Returns**:  
- No explicit return value. Either branches to the default exception handler at 0x8004C0 or executes RTE to return from the spurious interrupt.

**Key Operations**:  
- Pushes vector offset 0x18 (spurious interrupt vector number) onto the stack.
- Branches to a common exception handler at 0x800548 (likely sets up exception framing or logging).
- Tests bit 7 at address 0xE00019 (indicates Job processor interrupt request is active).
- Compares the word at 0xC004B4 and 0xC004B6 against the signature 0x9A16.
- If the signature matches at 0xC004B4 when Job interrupt is active, or at 0xC004B6 when Job interrupt is inactive, it goes to the default handler.
- Otherwise, returns from exception (RTE) to ignore the spurious interrupt.

**Called Functions**:  
- `0x800548` (common exception handler) via branch.

**Notes**:  
- The signature 0x9A16 appears to be a sentinel value used for IPC synchronization between the DMA and Job processors.  
- The check at 0x800494 distinguishes between a genuine spurious interrupt and a deliberate interrupt triggered by the Job processor for communication.  
- The function is part of the U17 ROM’s exception table, located immediately after the illegal instruction handler.  
- The use of `braw` (branch always) suggests the code may have been patched or extended, as the initial push/branch is unconditional, but later logic can cause an early RTE.

---

### Function at 0x8004c0

**Embedded strings:**
- `8389884`: `"fJ"<"`
- `8389902`: `"f8"<"`
- `8389957`: `"XNs#"`
- `8390158`: `"Nu /"`

**Name**: `exception_handler_common`  

**Purpose**:  
This function serves as a common entry point for multiple Motorola 68010 exception handlers. It saves the processor state to a memory area (choosing between two possible save areas based on which processor is running), logs the exception vector number, and either resumes normal execution or invokes a more detailed diagnostic handler depending on system state. If the system is in a special debug mode (indicated by a signature word at `0xC004B4` or `0xC004B6`), it increments a per‑vector counter; otherwise, it saves exception details and calls a diagnostic routine.

**Parameters**:  
- The exception stack frame is implicitly passed via the stack (as per 68010 exception entry).  
- `%sp@(4)` contains the exception vector offset (format word on 68010).  
- `%sp@(6)` may contain the fault address for certain exceptions (e.g., bus/address error).  
- Hardware register `0xE00019` bit 7 indicates which processor is executing (DMA vs. Job processor).

**Returns**:  
- No explicit return value. The function either restores the saved state and executes `rte` to resume, or branches to another handler (e.g., `0x80065e`).  
- Side effects: updates counters at `0xC004B8`–`0xC0057B` (per‑vector statistics) or saves exception context at `0xC00444`–`0xC0044A`.

**Key Operations**:  
- Checks bit 7 at `0xE00019` to determine current processor (DMA or Job).  
- Saves all registers (`%d0`–`%sp`) to either `0xC00400` (DMA) or `0xC00458` (Job) save area.  
- Extracts exception vector number from the stack frame and masks it to 0–255 range.  
- Tests for debug signature word `0x9A16` at `0xC004B4` (DMA) or `0xC004B6` (Job).  
- If signature matches, increments a per‑vector counter in a table starting at `0xC004B8` (DMA) or `0xC0057C` (Job).  
- Calls subroutine at `0x801816` (likely a console output or logging routine).  
- If signature does not match, saves exception address to `0xC00444`, clears `0xC00448`, saves vector to `0xC0044A`, calls `0x805bf0` (diagnostic) and `0x801816`, then branches to `0x80065e` (further handling).  
- Includes three alternative entry points (`0x80056e`, `0x80057a`, `0x800586`) that push different vector numbers or compute a vector from a fault address, then dispatch via a jump table at `0x8005c8` if the system is in a specific state (`0xC00640 == 0x1945` and bit 7 of `0xE00019` clear).

**Called Functions**:  
- `0x801816` – Console/logging output function.  
- `0x805bf0` – Diagnostic/error‑handling function (called when debug signature is absent).  
- Indirect calls via jump table at `0x8005c8` (targets are within the ROM, e.g., `0x806418`, `0x80685a`, etc.).

**Notes**:  
- The function is clearly designed to handle exceptions on both processors in a dual‑processor system, using separate save areas and signature locations.  
- The debug signature `0x9A16` likely indicates that the system is in a built‑in self‑test or monitor mode, where exceptions are logged but not fatal.  
- The jump‑table dispatch at `0x8005c8` suggests that certain exception vectors (e.g., bus error, address error) have dedicated handlers when the system is in a specific diagnostic state (`0xC00640 == 0x1945`).  
- The code at `0x800586` computes a vector index from a fault address (masking with `0x3FF` and subtracting `0x1B0`), which hints at handling MMU‑related or memory‑management faults.  
- The final `braw 0x8004c0` at `0x8005c4` loops back to the main handler if the jump‑table conditions are not met, ensuring all exceptions eventually pass through the common logging path.

---

### Function at 0x8005e0

**Embedded strings:**
- `8390158`: `"Nu /"`

**Name**: `delay_cycles`  

**Purpose**:  
This function implements a variable-length delay loop. It takes an input parameter, multiplies it by a fixed value from memory location `0xC00642`, then executes a series of division operations in a loop that decrements a counter until it reaches zero. The division instructions are likely used for their high cycle count to create a precise timing delay, possibly for hardware synchronization or polling delays in the self-test or boot process.

**Parameters**:  
- Input: 32-bit value passed on the stack at `%sp@(4)` (likely a delay factor or unit count).

**Returns**:  
- No explicit return value; the function is used for its side effect (time delay).

**Key Operations**:  
- Loads parameter from stack into `%d0`.  
- Multiplies the lower word of `%d0` by the 16-bit value at memory address `0xC00642` (likely a delay scaling factor stored in shared RAM).  
- Initializes `%d1` with the constant 2.  
- Repeatedly executes `divsw %d1,%d1` eight times per loop iteration — this divides `%d1` by itself, producing a result of 1 and a remainder of 0, but consumes many CPU cycles.  
- Decrements `%d0` by 1 each loop iteration.  
- Loops until `%d0` becomes zero.

**Called Functions**:  
None; this is a leaf function.

**Notes**:  
- The memory reference `0xC00642` is within the shared RAM area (`0xC00000–0xC00FFF`), suggesting the delay scale factor may be set by the system or adjusted dynamically.  
- The sequence of eight identical `divsw %d1,%d1` instructions is inefficient in terms of code but ensures a predictable, large number of cycles per loop iteration. This is typical of timing loops in early firmware.  
- The function does not preserve `%d1` (it ends with `%d1 = 1`), but `%d0` is zero on exit.  
- Given the hardware context, this delay might be used during SCSI operations, serial port polling, or bus arbitration waits.  
- The string `"Nu /"` referenced nearby is unrelated to this function — it may be part of a diagnostic message elsewhere in the ROM.

---

### Function at 0x800600

**Embedded strings:**
- `8390158`: `"Nu /"`

**Name**: `multiply_words_or_enter_debug`

**Purpose**: This function serves as a dual-purpose entry point: when called with no parameters (or with D0=1), it branches to a debug/monitor routine at 0x8005e4; when called with two word-sized parameters on the stack, it multiplies them together and returns the 32-bit product. The function appears to be a small utility that either enters a diagnostic mode or performs arithmetic, likely used during self-test or debug operations.

**Parameters**:  
- If entering via 0x800600: D0 is expected to be 1 (though the function sets it to 1 regardless).  
- If entering via 0x800604: Two 16-bit parameters are passed on the stack: `sp@(4)` (first word) and `sp@(8)` (second word).

**Returns**:  
- If branching to 0x8005e4: No return to caller (debug routine likely does not return).  
- If multiplying: D0 contains the 32-bit product of the two input words.

**Key Operations**:  
- Sets D0 = 1 unconditionally at entry (0x800600).  
- Branches to debug routine at 0x8005e4 if called at the first instruction.  
- If execution continues past 0x800604, loads two word-sized arguments from the stack into D0 and D1.  
- Performs unsigned multiplication of the low 16 bits of D0 and D1 (`muluw`), placing the 32-bit result in D0.  
- Returns to caller.

**Called Functions**:  
- 0x8005e4 (via `bras 0x8005e4`) — likely a debug monitor or diagnostic routine.

**Notes**:  
- The function has two logical entry points: 0x800600 (debug entry) and 0x800604 (multiplication utility).  
- The `muluw` instruction multiplies two unsigned words, producing a 32-bit result in D0. This suggests the parameters are intended to be 16-bit values.  
- The debug branch is taken if the function is called at 0x800600; if called directly at 0x800604 (e.g., via `jsr 0x800604`), it skips the branch and performs multiplication.  
- The nearby string `"Nu /"` (at 0x8390158) is not referenced in this code, but may be part of a larger debug output routine.  
- This function resides in the U17 self-test/debug ROM, so its primary use is likely during system initialization or diagnostic operations.

---

### Function at 0x800610

**Name**: `set_sr_interrupt_mask`  

**Purpose**: This function modifies the Status Register (SR) of the 68010, specifically the interrupt mask field (bits 8–10), while preserving all other SR bits. It takes a numeric argument (0–7) and shifts it into the interrupt mask position, then updates the SR. This is used to change the processor’s interrupt priority level (IPL) in a controlled manner, often during system initialization, exception handling, or critical sections.

**Parameters**:  
- Input argument passed on the stack at `sp@(4)` (a 32-bit value).  
- Current SR contents (implicitly via `movew %sr,%d1`).

**Returns**:  
- No explicit return value; the Status Register is updated directly.  
- All data registers are scratch (d0, d1 modified).

**Key Operations**:  
- Extracts the low 3 bits (0–7) of the input argument using `andil #7,%d0`.  
- Shifts the mask value left by 8 bits to align with the SR interrupt mask field (bits 8–10).  
- Reads the current SR into `d1`.  
- Clears the current interrupt mask bits using `andiw #-1793` (0xF8FF masks out bits 8–10).  
- ORs the new mask value into the cleared field.  
- Writes the result back to the SR with `movew %d1,%sr`.

**Called Functions**:  
- None; this is a leaf function.

**Notes**:  
- The value `-1793` (0xF8FF) is the bitwise inverse of 0x0700, which isolates the interrupt mask bits for clearing.  
- This is a classic 68000‑family pattern for safe SR modification: read, mask, modify, write.  
- The function does not disable interrupts globally during the update, but because the SR write is atomic and the mask is being changed anyway, this is safe.  
- Likely used by system initialization or debug monitor code to set the IPL during boot or when handling exceptions.  
- The function’s location in the U17 ROM (0x800610) places it early in the ROM, possibly part of low‑level processor setup or exception‑handling utilities.

---

### Function at 0x800628

**Name**: `dma_processor_init` or `self_test_entry`

**Purpose**: This function appears to be part of the DMA processor's early initialization or self-test sequence. It clears a shared memory variable, calls a subroutine (likely for hardware initialization or status checking), pushes a return address onto the stack, and then calls what is likely the main self-test or monitor routine. The final branch suggests it is part of a larger initialization flow.

**Parameters**: None explicitly passed; however, the function implicitly assumes the hardware is in a post-reset state and that the stack pointer is valid.

**Returns**: The function does not return a value in a conventional sense. It clears D2 before branching, possibly indicating a success/failure status (0 for success). The primary effect is side‑effects on hardware and shared memory.

**Key Operations**:
- Clears the longword at address `0xC0064c` (a shared RAM variable, possibly a flag or error counter).
- Calls subroutine at `0x8006d0` (likely hardware setup or early diagnostic).
- Pushes the address `0x8006e6` onto the stack (this will be the return address for the next JSR).
- Calls subroutine at `0x807510` (likely the main self‑test or monitor routine).
- Clears data register D2 (possibly preparing a return code).
- Branches to `0x80066a` (likely a common exit or continuation point).

**Called Functions**:
- `0x8006d0`: Unknown subroutine (early hardware init or status check).
- `0x807510`: Likely the main self‑test or debug monitor routine (given the ROM context).

**Notes**:
- The address `0xC0064c` is in the shared RAM area (`0xC00000–0xC00FFF`), suggesting it is a system variable accessible to both DMA and Job processors.
- Pushing `0x8006e6` before the JSR to `0x807510` implies that `0x8006e6` is the intended return point after the self‑test completes. This is a common pattern for setting up a return address when the called routine might not use the standard JSR return mechanism.
- The final branch to `0x80066a` (instead of RTS) indicates this function is part of a linear initialization sequence, not a standalone subroutine.
- Given the U17 ROM is the DMA self‑test/debug monitor, this function likely represents the entry point after the very first reset‑vector fetch, or a critical initialization step before handing off to the main self‑test logic.

---

### Function at 0x800646

**Name**: `initialize_debug_monitor`  

**Purpose**:  
This function initializes a debug monitor environment by clearing a shared memory variable, calling a setup routine, pushing a specific address onto the stack (likely a return address or parameter for a subsequent call), invoking a more complex initialization or debug routine, and finally calling the same setup routine again. It appears to prepare the system for debug operations, possibly setting up exception handling or monitor state before entering a main debug loop or command processor.

**Parameters**:  
None explicitly passed; uses the absolute memory address `0xC0064C` and the immediate value `#0x8006F9`.

**Returns**:  
No explicit return value; side effects include clearing `0xC0064C` and modifying the stack.

**Key Operations**:  
- Clears the longword at shared memory address `0xC0064C` (likely a debug variable or flag).  
- Calls subroutine at `0x8006D0` (likely a debug monitor setup or initialization routine).  
- Pushes the immediate value `0x8006F9` onto the stack (could be a return address for a subsequent routine or a parameter).  
- Calls subroutine at `0x807510` (likely a main debug monitor or command dispatcher).  
- Calls `0x8006D0` again (possibly cleanup or re-initialization after the monitor returns).

**Called Functions**:  
- `0x8006D0` — Debug setup/teardown routine (called twice).  
- `0x807510` — Main debug monitor routine or command processor.

**Notes**:  
- The sequence suggests a pattern: initialize → call monitor → reinitialize. The pushed address `0x8006F9` may be where `0x807510` returns, or it could be a parameter for error handling or exit routing.  
- The memory location `0xC0064C` is in the shared RAM area (`0xC00000–0xC00FFF`), indicating it’s a system variable accessible to both DMA and Job processors, possibly a debug flag or monitor state indicator.  
- This function likely runs early in the U17 ROM self-test/debug monitor startup, after basic hardware checks but before interactive debugging begins.

---

### Function at 0x800664

**Embedded strings:**
- `8390315`: `"Hg\nHx"`
- `8390326`: `"SlJy"`
- `8390340`: `"#0Hx"`
- `8390350`: `"SlJy"`
- `8390371`: `"@Nu!\nExit to boot...\n"`
- `8390393`: `" <del>"`

**Name**: `initialize_system_stack_and_check_boot_flag`

**Purpose**: This function initializes the system stack pointer based on a hardware status bit, performs a stack setup operation if a flag is zero, calls a system initialization routine, validates a memory location against a returned value, and finally either jumps to a main debug monitor or triggers a system reset based on a boot flag in shared RAM.

**Parameters**: 
- No explicit parameters passed in registers
- Implicitly reads hardware register `0xE00019` bit 7 (likely a processor mode or memory mapping status)
- Reads shared memory location `0xC00648` (expected system value)
- Reads shared memory word `0xC00650` (boot/continuation flag)

**Returns**:
- No explicit return value
- Side effects: Sets stack pointer (`%sp`) to either `0x00C04000` or `0x00C03800`
- May call reset/initialization routines that don't return

**Key Operations**:
- Tests bit 7 at hardware address `0xE00019` (likely a "DIS.MAP" or memory mapping enable bit from system control)
- Sets stack pointer to `0x00C04000` if bit is clear, or `0x00C03800` if bit is set (two possible stack regions in shared RAM)
- If `%d2` is zero, calls `0x8025b4` with five pushed arguments (`0`, `0x42`, `0x24`, `1`, `0`) – possibly a memory fill or initialization routine
- Calls subroutine at `0x800f06` (likely a hardware or system initialization function)
- Compares return value `%d0` from that call with the contents of `0xC00648` (a stored expected value)
- If mismatch, calls `0x80536c` with argument `0` (likely an error handler or reset routine)
- Tests the word at `0xC00650` (boot flag)
  - If zero, jumps to `0x802330` (main debug monitor entry point)
  - If non-zero, calls `0x80536c` with argument `1` (likely a warm/cold reset entry)

**Called Functions**:
- `0x8025b4` – Unknown function (called with five stack arguments when `%d2 == 0`)
- `0x800f06` – System initialization or self-test routine
- `0x80536c` – Reset or error handling function (called with 0 or 1 as argument)
- `0x802330` – Main debug monitor or command loop (jumped to if boot flag is zero)

**Notes**:
- The stack pointer is set to locations in the shared RAM area (`0xC00000–0xC00FFF`), which is consistent with the DMA processor's runtime stack.
- Bit 7 at `0xE00019` is not explicitly documented in the provided register list, but `0xE00018` is the processor control register; `0xE00019` may be an adjacent byte containing the `DIS.MAP` bit or similar mapping control.
- `0xC00648` and `0xC00650` are in the shared RAM region and likely hold system state flags set by earlier boot stages or diagnostics.
- The function appears to decide between entering a debug monitor (`0x802330`) or triggering a reset (`0x80536c`), based on `0xC00650`. This suggests a "stay in monitor vs. continue booting" decision point.
- The call to `0x8025b4` with specific arguments (`0x42`, `0x24`, etc.) may set up an exception vector table or initialize a memory region, given the values resemble exception numbers (0x42 = bus error, 0x24 = spurious interrupt).

---

### Function at 0x8006d0

**Embedded strings:**
- `8390371`: `"@Nu!\nExit to boot...\n"`
- `8390393`: `" <del>"`
- `8390460`: `"/\nHA2<"`

**Name**: `check_and_clear_boot_flag`  

**Purpose**:  
This function checks a system flag stored at address `0xC00640` (likely a shared RAM location used for boot coordination between the DMA and Job processors). If the flag is non-zero, it calls a subroutine (probably to perform a system reset or boot sequence), then clears the flag. If the flag is already zero, the function returns immediately. The code after the `rts` appears to be embedded ASCII data (possibly a fragment of a string like "Exit to boot...") that is not executed as instructions.

**Parameters**:  
- None explicitly passed; reads the word at memory address `0xC00640`.

**Returns**:  
- No explicit return value; the flag at `0xC00640` is cleared if it was non-zero.

**Key Operations**:  
- Tests the word at `0xC00640` (shared RAM flag).  
- If non-zero, calls a subroutine at `0x8058F4` (likely a boot/exit routine).  
- Clears the flag word at `0xC00640` after the subroutine call.  
- Returns.

**Called Functions**:  
- `jsr 0x8058F4` — unknown subroutine, but based on context likely performs a system boot or mode transition.

**Notes**:  
- The function is very short and appears to be a guard/trigger for a boot process.  
- The memory address `0xC00640` is within the shared RAM region (`0xC00000–0xC00FFF`), suggesting it is used for inter-processor communication (DMA ↔ Job processor).  
- The data after `rts` (`0x8006E6–0x8006FE`) decodes to ASCII fragments:  
  `0x8006E6`: `"!Nu"` (possibly part of a longer string like `"@Nu!"` from the referenced string list).  
  `0x8006EC–0x8006F6`: `"t to boot"` (part of `"Exit to boot..."`).  
  This is likely a string used elsewhere in the ROM, not executed code.  
- The function may be called during the self-test or boot monitor to check if a boot request has been posted by the other processor.

---

### Function at 0x800708

**Embedded strings:**
- `8390460`: `"/\nHA2<"`
- `8390484`: `" @$PB*"`
- `8390507`: `"1 AB"`

**Name**: `dma_processor_init`  

**Purpose**: This function is the initial entry point for the DMA processor after reset. It sets up the Vector Base Register (VBR) to point to the ROM’s exception vector table, initializes hardware control registers (specifically the serial port control register), and performs a short delay loop by writing to the LED control register. This prepares the system for diagnostics and bootstrapping.  

**Parameters**: None — this is a cold-start entry point.  

**Returns**: No explicit return; execution continues after the function. The function leaves `%d1` cleared to zero and branches forward.  

**Key Operations**:  
- Sets the frame pointer (`%fp`) to `0x00A00021` (likely a stack or fixed workspace address in shared RAM).  
- Loads `0x00800000` (the start of the U17 ROM) into `%d2` and moves it to the VBR, relocating the exception vector table to the ROM.  
- Writes `0xFFFF` to hardware register `0xE0001A` (serial port control), which likely disables transmitter and receiver (clears TCE/RCE bits).  
- Initializes `%a1` to zero and uses `%d0` as a loop counter (`0xFFFF` iterations).  
- Inside the loop: writes `0x0F` to LED control register `0xE00010` (turns on all four LEDs) each iteration, creating a visible delay and possibly a LED “heartbeat” during early startup.  
- Clears `%d1` and branches ahead (to `0x80073e`, presumably the next initialization stage).  

**Called Functions**: None — this is a straight-line initialization sequence with no subroutine calls.  

**Notes**:  
- The VBR setup indicates the ROM contains its own exception handlers (e.g., bus error at `0x800410`).  
- The delay loop writing to the LED register serves both as a simple timing delay and as a visual indicator that the DMA processor is running.  
- The serial port control write (`0xFFFF` to `0xE0001A`) probably resets the SCC channels early in the boot process.  
- This code runs from ROM at `0x800708`, which matches the documented reset entry point for the DMA processor.

---

### Function at 0x800738

**Embedded strings:**
- `8390460`: `"/\nHA2<"`
- `8390484`: `" @$PB*"`
- `8390507`: `"1 AB"`
- `8390523`: `"Zf&09"`
- `8390546`: `""@,Q"|"`
- `8390630`: `"g&$_,_Nu"`
- `8390680`: `"\n44<"`
- `8390752`: `"g(z1J@g"`
- `8390878`: `"	"&|"`
- `8390931`: `"EJEf"`
- `8391190`: `"H@S@g"H@"`
- `8391224`: `"\n\rPLEXt"`
- `8391395`: `".r O"`

**Name**: `selftest_main`  

**Purpose**: This function is the primary self-test and initialization routine for the DMA processor, executed from the U17 ROM after reset. It performs a series of hardware checks: initializes data structures, verifies ROM integrity via checksum, tests RAM (including pattern and walking-bit tests), initializes the system control register, and optionally prints diagnostic messages. If all tests pass, it jumps to the boot loader; otherwise, it reports failures via serial output and may halt or loop.

**Parameters**:  
- No explicit parameters; assumes a fresh reset state.  
- Implicitly uses hardware registers at `0xE000xx` for control/status.  
- Uses memory areas: `0xC00400`–`0xC00800` (shared RAM), `0x800000`–`0x808000` (ROM).  

**Returns**:  
- Does not return on success; jumps to `0x800f94` (likely the boot loader entry).  
- On failure, may enter an error loop or output diagnostic codes via serial.  
- Modifies hardware registers (LEDs, system control) to indicate status.  

**Key Operations**:  
- Clears bytes in a table at `0x802310` (offset from `%d0×4`), likely initializing test result buffers.  
- Computes a checksum of ROM at `0xD0001C` (49 words) and compares to expected value (`0x5A`).  
- Reads hardware status at `0xE00002` to determine system configuration (boot source, processor state).  
- Sets up serial output via a subroutine at `0x800a10` (character output routine).  
- Tests main RAM from `0x800000` to `0x80FFFF` by summing words and checking for non-zero (indicating RAM presence/parity).  
- Writes patterns (`0x5555`, `0xAAAA`) to RAM regions (`0xC00400`–`0xC00800`) and verifies reads.  
- Uses LED register (`0xE00010`) to indicate test phases (LED values 0,1,2).  
- Configures system control register (`0xE00016`) with values `0x8120` (diagnostic mode) and later `0x8130` (normal boot).  
- On failure, calls error reporting subroutine at `0x800a44` to print codes via serial.  

**Called Functions**:  
- `0x800700` – Unknown subroutine (possibly SCSI or further hardware init).  
- `0x800a10` – Serial character output routine (called repeatedly for strings).  
- `0x800a44` – Error message printing routine (displays test failure codes).  
- `0x800f94` – Boot loader entry point (jumped to on success).  

**Notes**:  
- The code includes several data tables embedded in the instruction stream (e.g., at `0x8007ee`, `0x8007fe`, `0x800a34`). The table at `0x8007fe` appears to be a lookup table for ASCII hex digits (`0xCE`='0', `0x8E`='A', etc.), used to format diagnostic output.  
- The routine uses a software stack manipulation trick: `lea addr,sp` sets the return address for the serial output subroutine, effectively creating a co-routine flow.  
- Test phases are controlled by `%d3`: 0=walking-1 test, 1=walking-0 test, 2=pattern test, 4=byte pattern test.  
- Shared memory locations `0xC00652` and `0xC00656` are used as flags: `0xC00652` may indicate an external abort condition, `0xC00656` holds a test result code (0=pass, 1=fail, 2=timeout?).  
- The function is position-dependent and makes direct references to ROM addresses, indicating it runs from ROM at `0x800000`.

---

### Function at 0x800b20

**Embedded strings:**
- `8391634`: `"[2 |"`

**Name**: `dma_processor_ram_test`  

**Purpose**:  
This function performs a two-phase RAM test on the DMA processor's memory space, starting at address `0xC00000`. The first phase writes a pattern (likely zero) and reads it back; the second phase writes the inverse pattern and verifies it. After successful testing, it clears a status word, sets the stack pointer to a known location (`0xC04000`), and jumps to the main self-test routine. If an error occurs during testing (handled by the subroutine at `0x8009be`), the function falls through to an infinite LED-blinking loop that indicates a failure.

**Parameters**:  
- None explicitly passed, but the function uses hardcoded memory addresses:  
  - `0xC00656`: Status/flag word (checked and cleared)  
  - `0xC00000`: Start of DMA processor’s shared RAM area (tested)  
  - `0xC04000`: Stack pointer destination after test  

**Returns**:  
- No explicit return; on success, jumps to `0x801062` (main self-test). On failure, enters an infinite LED-blinking loop.

**Key Operations**:  
- Checks and conditionally sets status word `0xC00656` to `0x0010`.  
- Calls a memory-test subroutine at `0x8009be` twice with different parameters:  
  - First call (`0x800b46`): Tests with `%d3 = 0`, `%d5 = 0xC00000`.  
  - Second call (`0x800b5c`): Tests with `%d3 = 1`, `%d5 = ~0xC00000`.  
- After tests, sets stack pointer to `0xC04000` and clears `0xC00656`.  
- Jumps to `0x801062` (likely main self-test entry).  
- Failure path: Blinks LEDs by writing to hardware register `0xE00010` in a delay loop, then calls `0x801028` (possibly a serial output or reset function) before looping.

**Called Functions**:  
- `0x8009be`: Memory test subroutine (called twice via `braw`).  
- `0x801028`: Called in the failure loop (possibly a diagnostic output or system reset).  
- `0x801062`: Jump target after successful test (main self-test routine).

**Notes**:  
- The function uses `%a4` to set a return address for the test subroutine (`0x8009be`), suggesting that subroutine may handle errors and return only on success.  
- The LED-blinking loop writes to `0xE00010` (LED control register) with a value from `%d2` (not set here; may be leftover from earlier code).  
- The stack pointer is set to `0xC04000`, which is in shared RAM, indicating the DMA processor uses this region for its stack after initialization.  
- The two test patterns (zero and inverse) are typical for checking address lines and stuck bits in RAM.  
- The presence of `[2 |` in nearby strings may relate to a multi-processor synchronization or test phase indicator.

---

### Function at 0x800b9a

**Embedded strings:**
- `8391634`: `"[2 |"`
- `8391680`: `"[2 |"`
- `8391722`: `"[2 |"`
- `8391744`: `"N^NuH"`
- `8391824`: `"Nu"|"`

**Name**: `perform_memory_test_sequence`  

**Purpose**: This function executes a three-phase memory test sequence on a specified memory region, likely as part of the DMA processor’s self-test routine. It tests the region with a pattern, its complement, and a walking-bit pattern, calling a lower-level test subroutine for each phase. If any phase fails, it jumps to a failure handler; if all pass, it returns a result code.

**Parameters**:  
- `%fp@(8)` (`%a3`): Base address of the memory region to test  
- `%fp@(12)` (`%a2`): Likely size or end address of the region (unused in this snippet but saved)  
- `%fp@(16)`: Possibly test mode or additional parameter (saved to `%fp@(-4)`)  

**Returns**:  
- `%d0` (`%fp@(-8)`): Test result (0 on success, non-zero on failure)  
- Indirectly: modifies `0xc006ba` (a shared RAM variable, possibly error log or test state)  

**Key Operations**:  
- Saves `0xc006ba` (shared RAM system variable) to the stack for later restoration.  
- Calls `0x805b32` (a test subroutine) three times with different parameters:  
  1. Phase 1: Pattern = original address (`%a3`), continuation address `0x800bde`.  
  2. Phase 2: Pattern = bitwise complement of address, continuation address `0x800c0c`.  
  3. Phase 3: Pattern = walking-bit (via `0x80091a`), continuation address `0x800c36`.  
- Uses `%d3` as a phase identifier (0, 1, 2).  
- On test failure in any phase, jumps to a failure handler (`%a4` or `%a5`).  
- On success, returns the result from `%fp@(-8)`.  

**Called Functions**:  
- `0x805b32`: Core memory test routine (called three times).  
- `0x803fcc`: Error-handling or reporting function (called from the continuation points).  
- `0x8009c4` and `0x8008ee`: Failure/exit handlers (jumped to on test failure).  
- `0x800a08` and `0x80091a`: Success/failure continuation routines (set as `%a5`).  

**Notes**:  
- The function uses a linked-list or callback style: `%a4` is the “next phase” entry point, `%a5` is the “failure” entry point.  
- The shared variable `0xc006ba` is preserved across phases, suggesting it holds system state (e.g., error counts, test flags).  
- The three test patterns (address, complement, walking-bit) are classic memory integrity tests.  
- The code at `0x800c44–0x800c72` appears to be a shared error-handling stub that calls `0x803fcc` with saved registers and then jumps to `%a4` (next phase) on success or `%a5` (failure) on error.  
- This is likely part of the U17 ROM’s power-on self-test (POST) for main RAM.

---

### Function at 0x800c74

**Embedded strings:**
- `8391824`: `"Nu"|"`
- `8391864`: `"2XN@2<"`

**Name**: `boot_jump_to_ram_test` or `relocate_and_execute_ram_code`

**Purpose**: This function copies a small code block from ROM to a fixed address in RAM (0x1000) and then jumps to execute it. The code being copied is the single `RTS` instruction at address 0x800c90. This appears to be a minimal bootstrap mechanism to transfer execution from the ROM-based self-test environment into a RAM-based test or bootloader stage, possibly to set up a clean execution environment or to run code that will later be overwritten.

**Parameters**: None are explicitly passed, but the function uses hardcoded addresses:
- Source address: 0x800c90 (the `RTS` instruction in ROM)
- Destination address: 0x1000 (in RAM)
- Copy length: 4096 bytes (0x1000), though the actual data at the source is only 2 bytes (`RTS`). This suggests the function at 0x800cbc is a general memory copy routine.

**Returns**: 
- Register `%d0` is set to 1 before the jump, possibly as a status/flag for the RAM code.
- Does not return to the caller; execution transfers permanently to address 0x1000.

**Key Operations**:
- Clears `%d0` (though this value is immediately overwritten).
- Loads the source address (0x800c90) into `%a0`.
- Loads the destination address (0x1000) into `%a1`.
- Calls a subroutine at 0x800cbc (likely a memory copy routine) with `%a0` = source, `%a1` = destination, and an implied length (likely 4096 bytes based on the `#4096` loaded into `%a1`, though this may be misinterpreted; `%a1` is the destination, not the length).
- Sets `%d0` to 1.
- Jumps to address 0x1000 (the copied code in RAM).

**Called Functions**:
- `0x800cbc`: A memory copy or relocation routine. Given the context, this likely copies data from `%a0` to `%a1` for a length specified elsewhere (possibly in `%d0` or another register, though `%d0` is cleared here). The 4096 value loaded into `%a1` is actually the destination, not the length.

**Notes**:
- The `RTS` at 0x800c90 is the only instruction in the "source block." Copying 4096 bytes from this address would copy far beyond the ROM's intended code, likely into garbage or other ROM data. This suggests either:
  1. The copy routine at 0x800cbc uses a different length (perhaps hardcoded or in another register).
  2. The 4096 value is misinterpreted; it might be a length stored elsewhere, or `%a1` is being set to 0x1000 as a destination, and the length is small (like 2 bytes for the `RTS`).
- Jumping to 0x1000 places execution in low RAM, which is typically reserved for system vectors or early boot code in 68010 systems. This is likely a temporary staging area.
- The function is likely part of the DMA processor's self-test sequence, possibly relocating a diagnostic or boot helper routine to RAM before the main memory test or bootloader runs.
- The setting of `%d0` to 1 may be a "success" flag or a mode selector for the code at 0x1000.

---

### Function at 0x800c92

**Embedded strings:**
- `8391864`: `"2XN@2<"`
- `8391894`: `"N@ /"`
- `8391902`: `"Nu o"`

**Name**: `boot_jump_to_ram_loader`

**Purpose**: This function relocates a small trampoline routine from ROM to a fixed address in RAM (0x1100), sets a hardware control register, then jumps to execute the relocated code. The trampoline code temporarily lowers the processor privilege level (clears the supervisor bit in SR) and triggers a TRAP #0 exception, which will invoke the system's TRAP #0 handler, presumably to start the main bootloader or operating system kernel from user mode.

**Parameters**: None. The function uses hardcoded addresses.

**Returns**: Does not return. It jumps to code at 0x1100, which then triggers a trap.

**Key Operations**:
- Loads the destination address 0x1100 into address register A1.
- Loads the source address 0x800CB4 (the start of the trampoline code in ROM) into A0.
- Calls a subroutine at 0x800CBC (likely a memory copy or relocation routine).
- Writes the value 1 to hardware register 0xE0001E (purpose not documented in provided context; possibly a serial port or system control signal).
- Sets D0 = 1 (may be a parameter for the following code).
- Jumps to address 0x1100 (the relocated trampoline in RAM).
- The trampoline code (at 0x800CB4) does:
  1. Clears the supervisor bit in the Status Register (SR) using `ANDI.W #0xDFFF, SR`, switching to user mode.
  2. Reads a word from the address pointed to by A0 into A1 (likely a dummy read or part of a parameter setup).
  3. Executes `TRAP #0`, generating a software exception.

**Called Functions**:
- `jsr 0x800cbc` – Likely a block copy or relocation function that copies the three instructions (0x800CB4–0x800CBA) to RAM at 0x1100.

**Notes**:
- The function appears to be part of the boot sequence, transitioning from supervisor-mode ROM code to user-mode execution via a controlled trap.
- Address 0x1100 is in low RAM (within the first 4KB), which is likely reserved for system vectors or bootstrap code.
- Writing to 0xE0001E is not documented in the provided register list; it might control an undocumented hardware feature (possibly related to serial port D or system configuration).
- The use of `TRAP #0` after dropping privilege suggests the system's TRAP #0 vector is set up to handle the transition to the next stage (e.g., jumping to the Job processor's bootloader or kernel).

---

### Function at 0x800cbc

**Embedded strings:**
- `8391894`: `"N@ /"`
- `8391902`: `"Nu o"`
- `8391932`: `"NuH@`"`

**Name**: `memcpy_10_words`  

**Purpose**:  
This function copies 10 long words (40 bytes) from a source memory location pointed to by address register A0 to a destination memory location pointed to by A1. It uses a decrement-and-branch loop with a counter in D1 to perform the copy, then returns. This is a simple, unrolled memory copy routine typical for block transfers in system initialization or data movement.

**Parameters**:  
- `%a0`: Source pointer (incremented during copy)  
- `%a1`: Destination pointer (incremented during copy)  

**Returns**:  
- `%a0`: Points to byte after the last copied source long word  
- `%a1`: Points to byte after the last copied destination long word  
- `%d1`: Becomes 0xFFFF after loop completion (due to `dbf` behavior)  

**Key Operations**:  
- Initializes loop counter `%d1` to 9 (10 iterations, since `dbf` counts down to -1)  
- Copies a long word (4 bytes) from `(%a0)+` to `(%a1)+` per iteration  
- Uses `dbf %d1, ...` to loop until counter expires  
- Returns to caller with `rts`  

**Called Functions**:  
None — this is a leaf function.  

**Notes**:  
- The loop copies exactly 10 long words = 40 bytes.  
- No alignment checks or hardware-specific accesses are present; this is a generic memory copy.  
- Given the U17 ROM context, this could be used during self-test to relocate code/data, set up shared memory structures, or copy diagnostic patterns.  
- The nearby strings (e.g., `"N@ /"`, `"Nu o"`) are likely unrelated to this function’s logic, as they are not referenced in the code.

---

### Function at 0x800cc8

**Embedded strings:**
- `8391894`: `"N@ /"`
- `8391902`: `"Nu o"`
- `8391932`: `"NuH@`"`

**Name**: `trigger_dma_processor_software_interrupt`  

**Purpose**:  
This function generates a software interrupt to the DMA processor by writing to the "Set DMA processor software interrupt" hardware register at `0xE000C0`. It ensures interrupts are enabled (clears the supervisor bit in the status register) and then executes a `trap #0` instruction, which likely invokes a handler to process the interrupt. This is part of inter-processor communication between the Job and DMA processors in the Plexus P/20 system.

**Parameters**:  
None explicitly; the function uses immediate values and fixed hardware addresses.

**Returns**:  
No explicit return value; side effects include setting the DMA processor’s software interrupt flag and potentially triggering a trap handler.

**Key Operations**:  
- Writes `1` to `0xE0001E` (purpose unclear; possibly a secondary control register for serial, SCSI, or interrupt masking).  
- Sets `%d0` to `1` (may be a parameter for the trap handler).  
- Clears bit 13 (0x2000) in the status register (`andiw #-8193,%sr`), which disables supervisor mode (enables interrupts and/or switches to user mode).  
- Executes `trap #0`, vectoring to a system routine (likely the DMA processor’s software interrupt service routine).

**Called Functions**:  
None directly via `jsr` or `bsr`; however, `trap #0` transfers control to the exception vector at address `0x80` in the vector table.

**Notes**:  
- The write to `0xE0001E` is not documented in the provided hardware register list; it may be a typo in the disassembly or an undocumented register. The intended address might be `0xE000C0` (Set DMA processor software interrupt), but the code shows `0xE0001E`.  
- The sequence suggests a coordinated interrupt: first prepare hardware, then enable interrupts, then trap to handle it.  
- This is likely a low-level IPC primitive used by the Job processor to signal the DMA processor.  
- The strings referenced nearby are unrelated to this function; they appear to be part of other debug routines.

---

### Function at 0x800cd8

**Embedded strings:**
- `8391902`: `"Nu o"`
- `8391932`: `"NuH@`"`
- `8391964`: `"NuH@`"`

**Name**: `swap_endian_32bit_word`

**Purpose**: This function performs a byte-order swap on a 32-bit value, converting between big-endian and little-endian representations. Specifically, it rotates the longword left by 8 bits, effectively swapping the most significant byte (MSB) with the second-most significant byte, the second with the third, and the third with the least significant byte (LSB). This is a common operation when dealing with data that has different endianness than the native Motorola 68010 big-endian format, such as when processing data from a little-endian device or protocol, or when preparing data for transmission/storage in a different byte order.

**Parameters**: The function takes one parameter passed on the stack at offset 4 (`%sp@(4)`), which is a 32-bit longword value.

**Returns**: The function returns the byte-swapped 32-bit result in register `%d0`.

**Key Operations**:
- Loads a 32-bit value from the stack into `%d0`.
- Rotates the 32-bit value in `%d0` left by 8 bits using the `roll #8,%d0` instruction. This moves the most significant byte to the least significant byte position, while shifting the other three bytes left by one byte position.

**Called Functions**: None. This is a leaf function that only uses registers and stack parameters.

**Notes**:
- The function is extremely short (6 bytes) and efficient, using only two instructions besides the return.
- The rotation by 8 bits is equivalent to: `((value << 8) | (value >> 24))` in C, which swaps the byte order of a 32-bit word.
- This could be used for endian conversion of data read from hardware that uses little-endian format (like some SCSI controllers or network interfaces), or for preparing data for such devices.
- The function appears in the U17 self-test/debug ROM, suggesting it might be used in diagnostic routines that check data integrity or communicate with peripherals that use different byte ordering.
- Interestingly, the nearby strings "Nu o" and "NuH@`" at addresses 0x8391902 and 0x8391932/0x8391964 appear to be corrupted or encoded data, possibly related to test patterns that might use this byte-swapping function.

---

### Function at 0x800ce0

**Embedded strings:**
- `8391932`: `"NuH@`"`
- `8391964`: `"NuH@`"`

**Name**: `memcpy_long_aligned`  

**Purpose**:  
This function copies a block of memory in 32-bit longword units from a source address to a destination address. It is optimized for aligned copying by using a loop that writes longwords (4 bytes) at a time, handling any remainder via a double-byte decrement-and-branch loop structure. The function appears to be a low-level memory copy routine, likely used during system initialization or data movement in the self-test/debug monitor.

**Parameters**:  
- `%sp@(4)` (source pointer): Address of the source data (loaded into `%a0`).  
- `%sp@(8)` (count): Number of *bytes* to copy (loaded into `%d0`).  
- `%sp@(12)` (value): The longword value to copy (loaded into `%d1`). Wait, this is not a source pointer but a literal value—this is actually a **memset**-like function that fills memory with a fixed 32-bit pattern.  

**Returns**:  
- No explicit return value. The destination pointer (`%a0`) is incremented as it writes, but not returned.  
- Memory at the destination is filled with the pattern in `%d1`.

**Key Operations**:  
- Converts byte count in `%d0` to longword count by shifting right by 2 (`lsrl #2,%d0`).  
- Uses a `dbf` loop (`dbf %d0,0x800cf0`) to write longwords from `%d1` to `%a0@+`.  
- Handles up to 65535 longwords (262,140 bytes) per loop iteration; if the count is larger, the high word of `%d0` is swapped in and used for an outer loop.  
- No hardware register accesses—this is purely a memory operation.

**Called Functions**:  
None (no `jsr` or `bsr`).

**Notes**:  
- The function is actually a **memset for longwords**, not a memcpy. The third argument is a fill pattern, not a source pointer.  
- The loop structure is unusual: after the first `dbf`, it swaps `%d0` to check the high word for an outer loop count. If the high word is non-zero, it swaps back and continues filling. This supports copying more than 64K longwords (i.e., >256 KB).  
- The code at `0x800cee` (`6002`) branches over the first write to enter the loop correctly.  
- This routine appears in the U17 ROM, which is part of the DMA processor’s self-test/debug monitor, suggesting it may be used for clearing memory regions or setting up test patterns during diagnostics.

---

### Function at 0x800d02

**Embedded strings:**
- `8391964`: `"NuH@`"`
- `8392010`: `"NuHA`"`

**Name**: `memory_clear_longwords`

**Purpose**: This function clears a block of memory by writing zeros to it in 32-bit longword increments. It takes a size parameter (in bytes) and iterates through memory starting from address 0x00000000, writing zeros until the specified number of bytes has been cleared. The function uses a nested loop structure to handle large sizes efficiently.

**Parameters**: 
- Stack parameter at offset 4 (`%sp@(4)`): a 32-bit value specifying the number of bytes to clear.

**Returns**: 
- No explicit return value. The function modifies memory starting at address 0x00000000.
- Registers `%d0`, `%d1`, and `%a0` are altered during execution.

**Key Operations**:
- Initializes `%a0` to point to absolute address 0x00000000.
- Reads the byte count from the stack.
- Divides the byte count by 4 (using `lsrl #2`) to convert to a longword count.
- Uses a `dbf` loop to write zeros (`movel %a0@+,%d1` effectively discards the read, but the post-increment advances the pointer) — this is actually a memory read, not write, so the function appears to be reading and discarding data rather than clearing. Wait, this is important: the function reads from `%a0@+` into `%d1`, but never writes zero back to memory. This suggests it's not clearing memory, but rather *reading* memory in a timed loop, possibly for a delay or to test memory accessibility.
- Uses a nested loop structure (via `swap %d0` and a second `dbf`) to handle counts larger than 64K longwords.

**Called Functions**: None.

**Notes**:
- The function does not actually write zeros to memory — it only reads memory into `%d1` and discards it. This could be a memory-accessible delay loop, or a memory test that relies on side effects (e.g., warming up cache, checking for bus errors). Given the U17 ROM is a self-test/debug monitor, this is likely a simple memory presence test or a delay loop.
- The start address is fixed at 0x00000000, which is the beginning of main RAM in the memory map.
- The nested loop allows clearing up to 64K × 64K longwords = 4GB, far beyond the Plexus P/20's 4MB RAM, suggesting generic reusable code.
- No hardware registers are accessed; it operates purely on RAM.
- The strings referenced nearby ("NuH@`", "NuHA`") are likely unrelated to this function — they may be encoded data or debug strings used by other routines.

---

### Function at 0x800d22

**Embedded strings:**
- `8392010`: `"NuHA`"`
- `8392052`: `"NuHA`"`

**Name**: `write_words_with_rounding`

**Purpose**: This function writes a sequence of 16-bit words to memory, using a 32-bit count that is halved and rounded up to determine the number of words to write. It handles large counts (greater than 65535) by using the upper word of the count register as an outer loop counter, effectively allowing up to ~4.3 billion iterations. This appears to be a memory fill or copy utility that can handle odd byte counts by rounding up to the next word.

**Parameters**:
- `%sp@(4)` (first argument): Destination address pointer (`%a0`)
- `%sp@(8)` (second argument): 32-bit count of bytes (`%d0`)
- `%sp@(12)` (third argument): 16-bit word value to write (`%d0` after loading)

**Returns**: 
- `%a0` points to the byte after the last written word (incremented by 2 × number of words written)
- No explicit return value in registers; memory at the destination is modified.

**Key Operations**:
- Loads destination pointer into `%a0`.
- Loads byte count into `%d0`, copies to `%d1`, and shifts right by 1 (divides by 2) to get a word count.
- Checks the least significant bit of the original count (`%d0` bit 0): if set (odd byte count), adds 1 to the word count (rounding up).
- Loads the 16-bit word value from the stack into `%d0` (lower word).
- Uses a `dbf` loop with `%d1` (lower word) as the inner loop counter to write the word repeatedly to `%a0@+`.
- If the original word count exceeds 65535, uses the upper word of `%d1` as an outer loop counter by swapping `%d1`, performing another `dbf`, and then swapping back to continue the inner loop.

**Called Functions**: None (no `jsr` or `bsr` instructions).

**Notes**:
- The function is optimized for writing large blocks of memory with a repeating 16-bit pattern.
- The rounding behavior suggests it may be used to fill memory where the count is specified in bytes, but the hardware or protocol requires word-aligned writes.
- The use of `swap` and nested `dbf` loops is a common 68000‑series idiom for handling counts > 64K without a 32‑bit loop counter.
- This routine is likely a low‑level memory initializer or filler, possibly used in self‑test to clear memory or set up a known pattern. It does not directly access any hardware registers; it operates purely on memory.

---

### Function at 0x800d50

**Embedded strings:**
- `8392052`: `"NuHA`"`
- `8392094`: `"NuHA`"`

**Name**: `memcpy_long_aligned`  

**Purpose**:  
This function copies a block of memory from a source address to a destination address, using longword (4‑byte) transfers when possible. It handles a byte count that may not be a multiple of 4 by first copying as many longwords as possible, then adjusting for up to three extra bytes. The algorithm uses a loop with `dbf` for efficiency, and it swaps the upper and lower words of a counter to manage counts larger than 64k.

**Parameters**:  
- `%sp@(4)` (first argument): Source address (`void *src`)  
- `%sp@(8)` (second argument): Byte count (`size_t n`)  

**Returns**:  
- `%a0` points to the destination after the last byte copied (i.e., `dest + n`).  
- No explicit return value; memory at the destination is updated.

**Key Operations**:  
- Loads byte count into `%d0` and source address into `%a0` (destination is implicitly `%a0` after the first move).  
- Divides count by 4 (using `lsrl #2`) to get the number of longword copies in `%d1`.  
- Checks the remainder (bits 1‑0 of count) by masking `%d0` with `#2`; if bit 1 is set (remainder 2 or 3), increments longword count by one to handle misalignment.  
- Uses `movel %a0,%a0@+` to read from the source (auto‑increment) and write to the destination (auto‑increment) in one instruction per longword.  
- Loops with `dbf %d1` for up to 64k longwords; if the count exceeds 64k, swaps `%d1` words and uses an outer `dbf` loop.

**Called Functions**:  
None (no `jsr` or `bsr`).

**Notes**:  
- The function assumes the source address is valid and accessible; it does not check for bus errors or alignment faults.  
- The destination is implicitly the same as the source at the start, but the first `movel %a0,%a0@+` actually copies a longword from the source to itself, then increments both addresses. This appears to be a clever way to set up the auto‑increment addressing for both reads and writes using only `%a0`.  
- The loop structure with `swap` allows copying more than 256k bytes (since `dbf` loops only 64k iterations, swapping extends it to 64k×64k).  
- This is likely a low‑level memory‑copy routine used during boot or diagnostics, possibly for relocating code or initializing data structures. The referenced strings "NuHA`" are not used within the function; they may be nearby in the ROM.

---

### Function at 0x800d7a

**Embedded strings:**
- `8392094`: `"NuHA`"`
- `8392144`: `"NuH@`"`

**Name**: `memory_fill_words`  

**Purpose**:  
This function fills a block of memory with a repeated 16-bit pattern. It takes a base address and a count of words to write, but the count is encoded as a 32-bit value where the lower 16 bits specify the number of word writes per inner loop iteration, and the upper 16 bits specify the number of outer loop iterations. The pattern is taken from the lower 16 bits of the address register `%a0` (which is used as both source and destination pointer). The function essentially performs a word-sized memory fill using a double-nested loop for large counts.

**Parameters**:  
- `%sp@(4)` (first argument): Base address (destination pointer) in `%a0`  
- `%sp@(8)` (second argument): 32-bit fill count/control word in `%d0`, where:  
  - Lower 16 bits: number of word writes per inner loop (minus 1 for DBcc)  
  - Upper 16 bits: number of outer loop iterations (minus 1 for DBcc)  
  - Bit 0 of `%d0` is also used to adjust the inner count if set.

**Returns**:  
- `%a0` points to the byte after the last written word.  
- No explicit return value in `%d0`; memory is modified.

**Key Operations**:  
- Extracts inner and outer loop counts from the 32-bit argument.  
- Adjusts inner count if bit 0 of original `%d0` is set (rounding up).  
- Uses `MOVE.W %a0, %a0@+` to write the lower 16 bits of the address register (which initially holds the destination pointer) repeatedly to memory. This means the written pattern is effectively the address itself, making it a fill with a pointer-derived constant.  
- Implements a double loop using `DBF` on `%d1` for both inner and outer counts.  
- The outer loop swaps `%d1` to access the upper 16 bits, then restores it for the inner loop.

**Called Functions**:  
None (no `BSR`, `JSR`, or `JMP` to subroutines).

**Notes**:  
- The pattern written is the lower 16 bits of the initial `%a0` value (the destination address). This is unusual—typically a fill function would take a separate pattern argument. Here, the function seems designed for a specific use case where the fill value is the address itself (e.g., for memory testing or marking blocks with address-dependent values).  
- The double-loop structure allows filling up to (65536 × 65536) words, which is far beyond the Plexus P/20’s 4 MB RAM, suggesting generic reusable code.  
- The adjustment for bit 0 of `%d0` ensures the total word count is correct when the inner count is odd.  
- This routine appears in the U17 self-test/debug ROM, so it may be used for memory testing, clearing, or initializing regions with known patterns.  
- The strings `"NuHA`" and `"NuH@`" referenced nearby are unrelated to this function’s logic; they likely belong to other debug commands.

---

### Function at 0x800da4

**Embedded strings:**
- `8392144`: `"NuH@`"`
- `8392178`: `"NuH@`"`

**Name**: `memset_32bit_pattern`

**Purpose**: This function fills a memory region with a repeating 32-bit pattern, where the pattern is the bitwise NOT of the starting address. It takes a starting address and a byte count, converts the byte count to a count of 32-bit writes (with special handling for unaligned lengths), and then writes the computed pattern repeatedly to memory. This appears to be a memory test or initialization routine, likely used during self-test to write a deterministic pattern based on the base address.

**Parameters**: 
- `%sp@(4)` (first argument): Starting address (`dest`) in register `%a0`
- `%sp@(8)` (second argument): Byte count (`n`) in register `%d0`

**Returns**: 
- No explicit return value. Memory starting at `dest` is filled with the pattern.
- Registers `%d0`, `%d1`, `%a0` are modified.

**Key Operations**:
- Converts byte count to number of 32-bit writes: `count_32 = (n >> 2) + ((n & 2) ? 1 : 0)`
- Computes pattern as `pattern = ~dest` (bitwise NOT of the starting address)
- Uses a double loop with `dbf` to write the pattern repeatedly to memory:
  - Inner loop writes `pattern` to `*dest++` and decrements `pattern` by 4 each iteration
  - Outer loop swaps `%d0` halves to handle counts > 65535 (since `dbf` only handles 16-bit counts)
- Returns when the entire region is filled.

**Called Functions**: None (leaf function).

**Notes**:
- The pattern is address-dependent and decrements by 4 each write, creating a sequence: `~dest`, `~dest - 4`, `~dest - 8`, etc.
- This is likely a memory test pattern generator—writing a known, predictable sequence that can later be verified.
- The double `dbf` loop structure is a common 68000 idiom for handling large counts (> 64K iterations).
- The function does not handle byte counts that are not multiples of 4 cleanly; it only adds one extra word if `(n & 2)` is non-zero, which suggests it may assume word-aligned addresses or counts.
- The strings `"NuH@`" referenced nearby are likely unrelated to this function—they may be ASCII representations of hardware register reads or status codes from other parts of the ROM.

---

### Function at 0x800dd6

**Embedded strings:**
- `8392178`: `"NuH@`"`

**Name**: `memcpy_word_aligned`  

**Purpose**:  
This function copies a block of memory from a source address to a destination address, using word-sized transfers. It is optimized for copying an even number of bytes, handling the count in a loop that moves words (16-bit) rather than bytes. The function uses a double-loop structure to allow copying more than 64K words by splitting the count into high and low 16-bit parts via register swapping.

**Parameters**:  
- `%sp@(4)` (source pointer) → `%a0`  
- `%sp@(8)` (destination pointer) → `%a1`  
- `%sp@(12)` (byte count) → `%d0` (must be even, as it is halved for word count)

**Returns**:  
- No explicit return value. The copied data is written to the destination buffer.  
- Registers `%a0` and `%a1` are incremented to point past the copied data.  
- `%d0` is zeroed after completion.

**Key Operations**:  
- Loads source, destination, and byte count from the stack.  
- Halves the byte count (right shift by 1) to convert to word count.  
- Uses a `dbf` loop (`%d0` low word) to copy words via `movew %a0@+,%a1@+`.  
- If the low word count wraps to 0xFFFF and decrements, the high word of `%d0` is checked with a swapped `dbf` to handle counts > 64K words.  
- Returns when both high and low word counts are exhausted.

**Called Functions**:  
None—this is a leaf function.

**Notes**:  
- The byte count must be even; odd counts would cause misalignment or an off-by-one error.  
- The double `dbf` loop with `swap` is a common 68000-series idiom for counts > 64K, using the upper 16 bits of `%d0` as an outer loop counter.  
- This routine appears in the U17 self-test/debug ROM, likely used for copying test patterns, moving code/data during boot, or setting up memory for diagnostics.  
- No hardware registers are accessed—it is a pure memory copy utility.  
- The nearby string `"NuH@`" (at address 0x8392178) is unrelated to this function; it may be part of a larger data section or error message elsewhere in the ROM.

---

### Function at 0x800e10

**Embedded strings:**
- `8392250`: `"Y0Nu"<"`
- `8392288`: `"Nu0<"`
- `8392306`: `"Nu$<"`

**Name**: `check_boot_source_or_fallback`

**Purpose**: This function determines whether to boot from the primary or alternate boot source based on a hardware switch (likely the "Boot.JOB" or "DIS.MAP" bit) and a stored boot counter. If the boot counter for the selected source is ≤1, it jumps to a hardcoded address (0x807510, likely a failure handler or minimal monitor). Otherwise, it calls a routine at 0x805930, which is probably the main boot loader or diagnostic sequence.

**Parameters**: None explicitly passed, but the function reads from two fixed memory locations:
- `0xc006be` (primary boot counter)
- `0xc006c2` (alternate boot counter)
It also reads hardware status register `0xe00019`.

**Returns**: No explicit return value. It either jumps to `0x807510` (no return) or calls `0x805930` and returns to its caller via `rts`.

**Key Operations**:
- Sets `%d1` to the constant 1 as a comparison threshold.
- Loads the primary boot counter from `0xc006be` into `%d0`.
- Tests bit 7 of hardware register `0xe00019` (this is the readback of the System Control Register at `0xe00016`; bit 7 corresponds to the `DIS.MAP` or `Boot.JOB` bit, which selects the boot source).
- If the bit is set, loads the alternate boot counter from `0xc006c2` into `%d0`.
- Compares the selected boot counter (`%d0`) with the threshold (`%d1`).
- If the counter is less than or equal to 1, jumps directly to `0x807510` (likely a failure/fallback routine).
- Otherwise, calls the subroutine at `0x805930` (likely the main boot or diagnostic routine).

**Called Functions**:
- `0x807510` (via `jmp`) – A failure or minimal monitor entry point.
- `0x805930` (via `jsr`) – The main boot or diagnostic routine.

**Notes**:
- The hardware register `0xe00019` is the readback location for the System Control Register (write address `0xe00016`). Bit 7 is significant; based on the hardware context, this likely selects between the primary and alternate boot paths (e.g., `DIS.MAP` disables memory mapping, or `Boot.JOB` selects the Job processor boot source).
- The memory addresses `0xc006be` and `0xc006c2` are in the shared RAM area (`0xc00000-0xc00fff`), suggesting they are persistent boot counters maintained across reboots.
- The function implements a form of boot attempt counting with a fallback after one attempt (or zero attempts). This is typical for systems that try a primary boot source, and if it fails, switch to an alternate (like a network or floppy boot) after a limited number of retries.
- The strings referenced nearby ("Y0Nu", "Nu0", "Nu$") are not directly used here but may be related to boot messages or error codes in the called functions.

---

### Function at 0x800e46

**Embedded strings:**
- `8392288`: `"Nu0<"`
- `8392306`: `"Nu$<"`
- `8392330`: `"#0.|"`

**Name**: `increment_word_with_alternate_space`

**Purpose**:  
This function increments a 16-bit word located at a given memory address, but performs the read and write operations using the Motorola 68010’s alternate function code spaces. It first sets both the source and destination function codes to 1 (user data space), then reads a word from the address passed on the stack, increments it, and writes it back using the `moves` (move with function code) instruction. This ensures the access occurs via the specified address space rather than the default supervisor program space.

**Parameters**:  
- `sp@(4)`: A pointer (32-bit address) stored at offset 4 from the current stack pointer, which points to the memory word to be incremented.

**Returns**:  
- The function does not explicitly return a value in registers; the result is stored back to the memory location pointed to by the input parameter. The condition codes are set based on the result of the increment operation.

**Key Operations**:  
- Sets the Data Function Code (`%dfc`) and Source Function Code (`%sfc`) registers to 1 (user data space) using `movec`.  
- Loads the target address from the stack into `%a0`.  
- Reads a 16-bit word from `%a0` using `movesw` (move from alternate space).  
- Increments the word by 1.  
- Writes the incremented word back to `%a0` using `movesw` (move to alternate space).  
- Returns to caller.

**Called Functions**:  
None (leaf function).

**Notes**:  
- The use of `moves` indicates the function is designed to access memory in a non-default address space (e.g., user data space while executing in supervisor mode). This is typical for system/debug monitors that need to manipulate user memory.  
- The function codes are set to 1, which corresponds to user data space (68010 function code encoding: 001 = user data).  
- The function is short and likely part of a larger debugging or memory-modification routine, possibly used by a monitor command to modify a word in user memory.  
- The stack parameter suggests it is called from other ROM code, possibly as a helper for a debug command that takes an address argument.  
- No bounds or alignment checks are performed; the caller must ensure the address is valid for the selected function code space.

---

### Function at 0x800e62

**Embedded strings:**
- `8392306`: `"Nu$<"`
- `8392330`: `"#0.|"`

**Name**: `set_vbr_and_jump_to_0x802330`  

**Purpose**:  
This function sets the Vector Base Register (VBR) to 0x00800000 (the start of the U17 ROM region) and writes a value to a shared RAM location, then jumps to another routine in the debug ROM. The initial part (0x800e62–0x800e72) appears to be a separate short function that sets the Data Function Code register and reads a word from a user-space address using the 68010’s `moves` instruction, but the code from 0x800e74 onward is the main path: it relocates the exception vector table to ROM, signals something via a shared memory word at 0xC00650, and transfers execution to a known debug/monitor routine at 0x802330.

**Parameters**:  
- For the first small function (0x800e62–0x800e72):  
  Input: `%sp@(4)` = pointer to a user-space address (likely passed from caller).  
- For the second part (0x800e74 onward):  
  No explicit parameters; uses hardcoded addresses.

**Returns**:  
- First function returns the word read from user space in `%d0`.  
- Second part does not return; it jumps to 0x802330.

**Key Operations**:  
- `movec %d0,%dfc` – Sets the Data Function Code register to 1 (likely supervisor data space access).  
- `movesw %a0@,%d0` – Reads a word from a user-space address using the 68010’s `moves` instruction, respecting the function code.  
- `movec %d2,%vbr` – Sets the Vector Base Register to 0x00800000, moving the exception vector table to the start of the U17 ROM.  
- `movew #1,0xc00650` – Writes the value 1 to shared RAM at 0xC00650 (likely a flag for the other processor or a debug state indicator).  
- `jmp 0x802330` – Transfers control to a routine in the debug ROM (possibly a monitor or diagnostic entry point).

**Called Functions**:  
- None via `jsr` or `bsr`; the final jump is to 0x802330, which is likely a subroutine elsewhere in the ROM (maybe a debug command handler or initialization continuation).

**Notes**:  
- The code at 0x800e62–0x800e72 and 0x800e74–0x800e86 might be two separate functions placed contiguously in ROM; the first is a utility to read from user space with a supervisor function code, and the second is a system initialization snippet that relocates the VBR and triggers a jump to a known monitor routine.  
- Setting VBR to 0x00800000 means all exception vectors are now based in the U17 ROM, which contains the debug monitor’s handlers (e.g., bus error at 0x800410).  
- Writing to 0xC00650 (in shared RAM area 0xC00000–0xC00FFF) likely signals the Job processor or a debug state machine that the DMA processor has entered a specific mode.  
- The jump target 0x802330 is not listed in the provided known functions list but is within the debug ROM range and may be part of a larger monitor routine (possibly after setting up the VBR).

---

### Function at 0x800e8c

**Embedded strings:**
- `8392404`: `"Nu /"`
- `8392436`: `"Nu W.y"`

**Name**: `initialize_vbr_and_jump`  

**Purpose**:  
This function sets up the Vector Base Register (VBR) to point to the start of the U17 ROM (0x00800000), initializes the stack pointer to a location in the shared RAM area (either 0x00C03800 or 0x00C04000), writes a value to a shared memory location (0xC00650), and then jumps to a common routine at 0x8050F0. The two nearly identical code blocks suggest it may handle two different processor contexts (DMA and Job processors) or two different initialization paths, both converging on the same jump target.

**Parameters**:  
None — the function takes no explicit inputs; it uses hardcoded immediate values.

**Returns**:  
No return value — the function ends with an absolute jump to another routine, never returning to its caller.

**Key Operations**:  
- Sets the stack pointer (`%sp`) to `0x00C03800` (first block) or `0x00C04000` (second block), both within the shared RAM region `0xC00000–0xC00FFF`.  
- Loads `%d2` with `0x00800000`, the base address of the U17 ROM.  
- Moves `%d2` into the VBR (Vector Base Register), relocating the exception vector table to the start of the U17 ROM.  
- Writes the word value `0x0001` to memory address `0xC00650` (only in the first block). This appears to be a shared variable or flag in the shared RAM area.  
- Jumps to `0x8050F0` (same destination for both blocks).

**Called Functions**:  
- `0x8050F0` — an unknown routine, likely a common initialization or main loop after VBR setup.

**Notes**:  
- The function appears in two variants back‑to‑back, differing only in the stack pointer value and the presence of the `movew #1,0xC00650` in the first block. This suggests it may be used for two different processor states (e.g., DMA processor vs. Job processor) or two boot modes.  
- The VBR is set to `0x00800000`, meaning all exception vectors (including bus error, address error, etc.) are now relative to the U17 ROM, consistent with the known exception handlers at `0x800410`, `0x80047a`, etc.  
- The shared memory write to `0xC00650` may signal that the DMA processor is active or that a certain initialization step is complete.  
- The strings referenced nearby (`"Nu /"` and `"Nu W.y"`) are not used in this function; they may belong to adjacent code.  
- The jump to `0x8050F0` is absolute and likely leads to further system initialization or a monitor/debug loop.

---

### Function at 0x800ec8

**Embedded strings:**
- `8392404`: `"Nu /"`
- `8392436`: `"Nu W.y"`

**Name**: `save_sp_and_call_0x80621a`

**Purpose**:  
This function saves the current value of the stack pointer (SP) into a fixed memory location in the shared RAM area (0xC006CA), then calls a subroutine at address 0x80621a. Its primary role appears to be capturing the caller’s stack pointer for diagnostic or debugging purposes before transferring control to another routine—likely part of the self‑test or debug monitor’s error‑handling or state‑logging framework.

**Parameters**:  
- Implicitly uses the current stack pointer (`%sp`) as input.

**Returns**:  
- No explicit return value in registers. The subroutine at 0x80621a may return a value or modify state, but this function itself only returns via `rts` after the subroutine completes.

**Key Operations**:  
- Stores the 32‑bit value of the stack pointer to shared RAM address `0xC006CA` (in the hardware‑defined shared variable area at 0xC00000–0xC00FFF).  
- Calls a subroutine at absolute address `0x80621a` (likely a diagnostic or helper function within the U17 ROM).  
- Returns to the caller after the subroutine finishes.

**Called Functions**:  
- `0x80621a` – an unknown subroutine (not listed in the provided known‑functions summary; likely internal to the self‑test/debug monitor).

**Notes**:  
- The memory address `0xC006CA` is within the shared RAM region accessible to both the DMA and Job processors, suggesting this may be used to pass stack‑pointer information across processors or for post‑mortem debugging.  
- The function is extremely short (three instructions) and appears to be a “thunk” or wrapper that records the stack pointer before invoking another routine.  
- Given the U17 ROM’s role in self‑test and debugging, this likely supports error‑tracing or context‑saving during diagnostic operations.  
- No hardware registers are directly accessed here; the operation is purely memory‑store and subroutine call.

---

### Function at 0x800ed6

**Embedded strings:**
- `8392436`: `"Nu W.y"`

**Name**: `set_exception_handler`  

**Purpose**:  
This function installs an exception handler by copying a handler address from a fixed memory location (`0xC006CA`) onto the stack, then returning. It is likely part of a mechanism to dynamically set up exception vectors or callback functions, possibly for debugging or runtime configuration. The function takes an exception vector number (or offset) as input and uses it to compute where to store the handler address.  

**Parameters**:  
- Input: A 32-bit value passed on the stack at `%sp@(4)`, which is interpreted as an offset or index (likely an exception vector number multiplied by 4, since Motorola 68000‑series exception vectors are 4‑byte entries).  

**Returns**:  
- No explicit register return value; the function modifies memory at the address calculated from the input parameter.  

**Key Operations**:  
1. Reads a 32‑bit parameter from the stack (offset for the exception vector).  
2. Uses that value as a destination address (likely a pointer into the exception vector table).  
3. Writes a 32‑bit handler address taken from fixed location `0xC006CA` to that destination.  
4. Returns to caller.  

**Called Functions**:  
None (no `jsr` or `bsr` in this code segment).  

**Notes**:  
- The fixed source address `0xC006CA` lies in the shared RAM area (`0xC00000–0xC00FFF`), suggesting it is a system variable that holds a pre‑determined exception handler address, possibly set by earlier debug or boot code.  
- The function is extremely compact (3 instructions) and appears to be a low‑level runtime vector patching routine, perhaps used by the self‑test monitor to install custom bus‑error or trap handlers.  
- The nearby string `"Nu W.y"` is unrelated to this function; it likely belongs to a different debug output routine.  
- This code runs on the DMA processor (since it resides in U17 ROM), and the handler being installed might be for DMA‑side exceptions (e.g., bus errors during I/O operations).

---

### Function at 0x800ee2

**Embedded strings:**
- `8392436`: `"Nu W.y"`

**Name**: `save_stack_frame_pointers`

**Purpose**: This function saves the current stack pointer (SP) and frame pointer (FP) of the DMA processor into a dedicated memory area in the shared RAM at `0xC006CE-0xC006D5`. It adjusts the saved SP value by adding 4, likely to point to the return address or a parameter on the stack, effectively preserving a snapshot of the processor's call frame context for diagnostic or debugging purposes.

**Parameters**: None explicitly passed. The function implicitly uses the current values of the supervisor stack pointer register (`%sp`/`A7`) and the frame pointer register (`%fp`/`A6`).

**Returns**: No register outputs. The function's output is written to two longword (32-bit) memory locations:
- `0xC006CE`: Holds `%sp + 4`
- `0xC006D2`: Holds `%fp`

**Key Operations**:
- Stores the supervisor stack pointer (`%sp`) to the shared RAM address `0xC006CE`.
- Adds 4 to the value now stored at `0xC006CE` (post-increment semantics via a separate instruction).
- Stores the frame pointer (`%fp`) to the next longword at `0xC006D2`.
- Returns to caller.

**Called Functions**: None. This is a leaf function.

**Notes**:
- The memory area `0xC006CE` is within the shared RAM region (`0xC00000-0xC00FFF`) used for inter-processor communication and system variables. Saving these pointers here makes them accessible to the Job processor or a debug monitor.
- The adjustment `%sp + 4` is intriguing. On the 68010, when a subroutine is called via `BSR` or `JSR`, the processor pushes the return address onto the supervisor stack. At the moment this function is called, `%sp` likely points to this return address. Adding 4 could skip past it, perhaps to point to a saved processor state or exception frame if this function is part of an exception handler, or to a parameter. The nearby string "Nu W.y" is likely unrelated to this short utility function.
- This is likely a helper function used during system diagnostics, crash analysis, or context switching, as it captures a key part of the processor's execution context. It may be called from within a larger exception handler or debug routine to log the state before performing further analysis or recovery.

---

### Function at 0x800ef6

**Name**: `switch_to_alternate_stack_and_jump`

**Purpose**: This function performs a context switch to an alternate stack frame stored in shared memory, then jumps to a target address that was previously saved on the original stack. It is likely part of a bootloader or diagnostic monitor's process for transferring control from a temporary startup environment (e.g., ROM-based self-test) to a more permanent runtime environment (e.g., RAM-based kernel or bootloader), using known safe stack and frame pointer values stored in the shared memory area at 0xC00000.

**Parameters**: 
- The return address (or target address) is taken from the top of the current stack (`%sp@`).
- The new stack pointer value is read from the shared memory location `0xC006CE`.
- The new frame pointer value is read from the shared memory location `0xC006D2`.

**Returns**: 
- Does not return in the conventional sense; it jumps to the target address (`%a0@`) with a completely new stack and frame pointer context.
- Register `%a0` holds the target address pulled from the old stack.
- Register `%sp` is set to the value from `0xC006CE`.
- Register `%fp` is set to the value from `0xC006D2`.

**Key Operations**:
- Saves the current return/target address from the stack into `%a0`.
- Loads a new stack pointer from a fixed shared memory location (`0xC006CE`), which is in the Plexus P/20's shared RAM area (0xC00000–0xC00FFF).
- Loads a new frame pointer from another fixed shared memory location (`0xC006D2`).
- Jumps to the address originally on the stack, effectively transferring execution to a new context.

**Called Functions**: None (the `jmp %a0@` transfers control, but it is not a subroutine call that returns).

**Notes**:
- This code is position-independent and uses absolute long addresses (`0xc006ce`, `0xc006d2`), indicating these memory locations are well-known in the system's shared data area.
- The shared addresses `0xC006CE` and `0xC006D2` likely hold system initialization values set earlier in the boot process (possibly by the DMA processor's self-test or by a bootloader).
- The function effectively performs a "stack pivot" – switching to a pre-configured stack before jumping to the next stage of execution. This is common in boot sequences where the initial ROM stack may be limited or needs to be replaced with a RAM-based stack for further operations.
- Given the Plexus P/20's dual-processor design, this could be part of handing off control between processors or between different firmware phases (e.g., from U17 ROM self-test to U15 ROM boot loader). The target address in `%a0` might point to the boot loader entry (e.g., `0x80854A`) or another initialization routine.

---

### Function at 0x800f06

**Embedded strings:**
- `8392594`: `"y:NV"`
- `8392612`: `"5HJy"`

**Name**: `read_dma_int_status` or `check_dma_interrupt_enabled`

**Purpose**:  
This function reads the processor control/status register at 0xE00018 to check whether the DMA processor's software interrupt is currently enabled. The register's bit 7 (value 0x80) corresponds to the DMA interrupt enable/status flag. The function masks and returns this bit, allowing the caller to determine if DMA processor interrupts are active.

**Parameters**:  
None explicitly passed; the function reads directly from hardware register 0xE00018.

**Returns**:  
- `%d0`: Lower 16 bits contain 0x0080 if the DMA processor interrupt is enabled, 0x0000 otherwise.

**Key Operations**:  
- Reads the processor control/status register at 0xE00018 (hardware read address documented in the memory map).  
- Masks the read value with immediate 0x0080 to isolate bit 7 (DMA interrupt enable/status).  
- Returns the result in `%d0`.  
- The code after 0x800f14 appears to be data or unrelated instructions (possibly a jump table or embedded constants) that are not executed due to the `rts` at 0x800f12.

**Called Functions**:  
None.

**Notes**:  
- The function is extremely short (4 instructions) and appears to be a pure status-checking utility.  
- The bytes after 0x800f14 are not executed; they may be part of a data table (e.g., interrupt vectors, branch offsets, or string pointers) that happens to be placed directly after the function.  
- The hardware register 0xE00018 is documented as a read location for processor status, including `INT.DMA` (bit 7), which matches the mask used.  
- This function likely supports diagnostic or system-monitoring routines in the U17 ROM, allowing the debug monitor to check interrupt state.

---

### Function at 0x800f94

**Embedded strings:**
- `8392612`: `"5HJy"`
- `8392686`: `"yY/<"`
- `8392740`: `"N^NuNV"`
- `8392798`: `"N^NuNV"`

**Name**: `self_test_delay_loop`  

**Purpose**:  
This function performs a timed delay loop (approximately 300 iterations) while preserving a shared memory variable (`0xC006D6`), and conditionally prints status messages before and after the delay depending on a flag (`0xC00656`). After the delay, it may call further test routines if the flag is set, and finally calls a known function (`0x800B20`) that likely performs additional system checks or transitions to the next boot stage.

**Parameters**:  
- No explicit register parameters.  
- Reads memory word at `0xC00656` (a status/flag word).  
- Reads/writes memory long at `0xC006D6` (a preserved variable, possibly a timer or counter).  

**Returns**:  
- No explicit return value.  
- Restores `%d6` and `%d7` before returning.  
- Conditionally calls other functions based on `0xC00656`.  

**Key Operations**:  
- Saves `%d6` and `%d7` on the stack.  
- Calls `0x803548` with argument `0` (first call) and later with argument `1`.  
- Checks `0xC00656`: if zero, prints two strings (addresses `0x807942` and `0x807947`).  
- Preserves `0xC006D6` in `%d6`, then delays via a 300‑iteration loop, each iteration calling `0x800600` and `0x801028`.  
- Restores `0xC006D6` after the loop.  
- Checks `0xC00656` again: if non‑zero, calls `0x801062`.  
- Finally calls `0x800B20`.  

**Called Functions**:  
- `0x803548` (twice, with different arguments) — likely a setup/teardown routine.  
- `0x807510` — prints strings (console output).  
- `0x800600` — unknown, called in loop.  
- `0x801028` — unknown, called in loop.  
- `0x801062` — conditionally called after loop.  
- `0x800B20` — final call (likely next test stage).  

**Notes**:  
- The delay loop count (300) is hardcoded in `%d7`. The two functions called in the loop (`0x800600` and `0x801028`) may perform small hardware checks or short waits (e.g., reading a status register).  
- The flag at `0xC00656` appears to control verbose output: if zero, strings are printed before and after the delay; if non‑zero, no strings are printed and `0x801062` is invoked instead.  
- The preserved long at `0xC006D6` might be a system tick counter or a shared variable with the Job processor; saving/restoring it suggests this function should not disrupt ongoing timing or coordination.  
- The strings printed are from the U17 ROM’s string table: `0x807942` and `0x807947` likely correspond to short status messages like “testing…” or “delay…”.  
- This routine seems part of the DMA processor’s self‑test sequence, possibly a synchronization or settling delay between hardware tests.

---

### Function at 0x801028

**Embedded strings:**
- `8392798`: `"N^NuNV"`
- `8392812`: `"5HHx"`
- `8392834`: `"f(Jy"`
- `8392841`: `"Vf N"`

**Name**: `selftest_shared_memory_vectors`  

**Purpose**:  
This function iterates over eight consecutive 32-bit values stored in a table at ROM address 0x802310 (0x00802310) and, for each value, writes it to a shared-memory location at 0xC006D6 and then calls a subroutine at 0x807882 with that value as an argument (passed on the stack). It appears to be part of a self‑test or initialization sequence that validates or configures shared‑memory communication vectors between the DMA and Job processors.

**Parameters**:  
None explicitly; the function uses a hardcoded table in ROM starting at 0x802310.

**Returns**:  
No explicit return value; all registers except `%d7` are preserved.

**Key Operations**:  
- Iterates a counter `%d7` from 0 to 7.  
- For each iteration, reads a 32-bit value from table entry `0x802310 + (%d7 * 4)`.  
- Writes that value to shared RAM at address `0xC006D6`.  
- Pushes the same value onto the stack and calls subroutine `0x807882`.  
- Preserves `%d7` across the call via the stack frame.

**Called Functions**:  
- `0x807882` — unknown subroutine, likely performs validation, logging, or IPC setup using the vector value.

**Notes**:  
- The table at `0x802310` is in the U17 ROM region (0x800000–0x807FFF), suggesting it contains fixed vector or test data.  
- The shared address `0xC006D6` lies in the shared RAM area (0xC00000–0xC00FFF) used for inter‑processor communication.  
- The loop runs exactly eight times, indicating eight predefined vectors are being installed or tested.  
- The function uses a standard stack frame (`linkw %fp,#-8`) and preserves `%d7`, suggesting it may be called from a larger test routine.  
- No hardware registers are accessed directly; the focus is on shared‑memory setup.

---

### Function at 0x801062

**Embedded strings:**
- `8392812`: `"5HHx"`
- `8392834`: `"f(Jy"`
- `8392841`: `"Vf N"`
- `8392908`: `"N^NuNV"`
- `8392943`: `"V @JPg"`
- `8392959`: `"V @0"`

**Name**: `self_test_main` or `diagnostic_boot_check`

**Purpose**: This function appears to be the main diagnostic/self-test entry point called early in the boot process. It performs a series of system checks (likely hardware diagnostics), and based on the results, either proceeds to normal boot (setting LEDs to 0xF) or falls back to a debug/recovery mode. Finally, it calls a function that may initialize or display something related to the system console or boot interface.

**Parameters**: None explicitly passed via registers. The function uses global memory locations (0xC00656) and hardware registers for its checks.

**Returns**: No explicit return value in registers. However, it has side effects: sets hardware LEDs (0xE00010) to value 0xF (all LEDs on) on successful checks, and calls other functions that may not return if diagnostics fail.

**Key Operations**:
- Calls `0x803548` twice: first with no parameter, then with parameter 1 (pushed on stack). This likely initializes or checks something critical.
- Calls `0x801140` and tests its return value; if non-zero, jumps to failure path.
- Tests word at `0xC00656` (likely a diagnostic result flag in shared RAM); if non-zero, jumps to failure.
- Calls `0x806cd8` (another diagnostic) and tests return value; if non-zero, jumps to failure.
- On success: pushes address `0x80795D` (likely a "boot OK" or version string) and calls `0x807510` (probably a print function), then writes `0xF` to LED control register `0xE00010` (lights all 4 LEDs).
- On failure: calls `0x8010D0` (likely an error handler or debug monitor entry).
- Finally, calls `0x8025B4` with parameters `(1, 0, 0x24, 0x42)` pushed on stack — possibly a console initialization or display function.

**Called Functions**:
- `0x803548` — unknown, called twice with different args.
- `0x801140` — diagnostic check, returns status.
- `0x806cd8` — another diagnostic check.
- `0x807510` — likely prints string at passed address.
- `0x8010D0` — error handler/debug entry point.
- `0x8025B4` — function taking four integer arguments, possibly console init or display setup.

**Notes**:
- The LED write `moveb #15,0xe00010` sets all four LED bits on, indicating successful self-test (common in diagnostic monitors).
- The final call to `0x8025B4` with arguments `(1, 0, 0x24, 0x42)` might correspond to setting up a display mode (rows/columns?) or initializing a serial port (baud rate?). Given the Plexus P/20 uses an SCC, these could be SCC channel/parameter commands.
- The strings referenced in the surrounding area (e.g., at `0x80795D`) are likely encoded or compressed, as they don't appear to be plain ASCII.
- This function is likely the core of the U17 ROM's self-test routine, deciding whether to proceed to boot or enter a debug monitor.

---

### Function at 0x8010d0

**Embedded strings:**
- `8392943`: `"V @JPg"`
- `8392959`: `"V @0"`
- `8393022`: `"NuNV"`

**Name**: `led_pattern_sequence`  

**Purpose**:  
This function cycles through a sequence of LED patterns stored in a table, displaying each pattern on the hardware LED register (0xE00010) for a short period. Between each pattern, it prints a string (likely a status or debug message) and turns off the LEDs briefly. The loop continues indefinitely, suggesting this is a diagnostic or attention‑grabbing visual indicator, possibly used during system self‑test or failure states.

**Parameters**:  
None explicitly passed; the function uses a loop counter in `%d7` and reads pattern words from a hard‑coded table base at `0xC00656`.

**Returns**:  
No return value; the function does not exit (infinite loop).

**Key Operations**:  
- Saves `%d7` on the stack and initializes it to zero as a loop index.  
- Calls `0x807510` with a pointer to the string `"V @JPg"` (address `0x807971`).  
- For each index `%d7`, computes `0xC00656 + 2*%d7` to fetch a 16‑bit word from a table.  
- If the word is zero, the loop restarts (effectively waiting for a non‑zero entry).  
- Writes the low byte of the word to the LED control register `0xE00010`.  
- Delays by calling `0x8005e0` with argument `0x3c` (likely a time‑delay function).  
- Calls `0x807882` with a pointer from `0xC006d6` (probably a status/debug string).  
- Clears the LED register (`0xE00010`), delays again, increments `%d7`, and repeats.

**Called Functions**:  
- `0x807510` – prints or processes the string `"V @JPg"`.  
- `0x8005e0` – delay function (parameter `0x3c` = 60 decimal).  
- `0x807882` – prints or processes a string pointed to by `0xC006d6`.

**Notes**:  
- The table at `0xC00656` appears to be in shared RAM (`0xC00000` region), suggesting it may be populated by another processor or earlier test code.  
- The infinite loop implies this function is not meant to return; it may be part of a failure mode where the system halts and blinks LEDs in a sequence while printing debug messages.  
- The LED register `0xE00010` controls the front‑panel diagnostic LEDs; writing a byte sets which LEDs are lit (bits 3‑0).  
- The delay argument `0x3c` (60) may correspond to 60 milliseconds or 60 iterations, depending on the delay function’s implementation.  
- The function alternates between turning on a pattern and turning off all LEDs, creating a blinking effect.

---

### Function at 0x801140

**Embedded strings:**
- `8393142`: `" @ PN"`
- `8393173`: `"P @/"`
- `8393226`: `"N^Nu"`
- `8393308`: `" @ Pp"`

**Name**: `selftest_sequence`  

**Purpose**:  
This function runs a series of self‑test routines (likely hardware diagnostics) indexed from 3 to 15, logging results and updating a global test‑step counter. It initializes test state, loops through each test, calls a test routine via a jump table, and reports failures by printing error information. A global LED register is updated during the loop, and a failure flag is returned if any test fails.

**Parameters**:  
- None explicitly passed; reads `0xC00656` (word) as a test‑mode or initial condition.  
- Uses global memory locations: `0xC006DA` (test‑step counter), `0xC006DE` (cleared), `0xC006DD` (LED data).  

**Returns**:  
- `D0` = `D6` = 0 if all tests pass, 1 if any test fails.  

**Key Operations**:  
- Initializes `0xC006DA` = 3 and clears `0xC006DE`.  
- Reads test‑mode word from `0xC00656` into `D7`.  
- Calls `0x800d22` with arguments `0xC00370` and `0x8A` (likely console output setup).  
- Calls `0x805b18` with argument `0xC00656` (possibly printing test‑mode info).  
- If `D7` ≠ 0, calls `0x80155a` with `D7` as argument (error logging).  
- Loops for test index `D5` = 3 to 15:  
  - Calls `0x804ff6` (possibly prepare for test).  
  - Writes `0xC006DD` to LED register `0xE00010`.  
  - Clears `0xC00644` (test‑specific status).  
  - Calls test routine via jump table at `0x800F14 + 4*(D5-1)`.  
  - If test returns non‑zero (`D7` ≠ 0), formats error code, prints via `0x807510`, sets failure flag `D6=1`, and calls `0x80155a` with test index.  
  - Increments global test‑step counter `0xC006DA`.  
- Returns failure flag in `D0`.

**Called Functions**:  
- `0x800d22` – likely console initialization or output.  
- `0x805b18` – prints test‑mode or status word.  
- `0x80155a` – error logging/display function.  
- `0x804ff6` – pre‑test setup (maybe hardware reset).  
- Test routines via jump table at `0x800F14` (each entry is a function pointer).  
- `0x807510` – formatted print (error reporting).  

**Notes**:  
- The jump table base `0x800F14` corresponds to test index 1; the loop starts at index 3, skipping the first two tests.  
- Error codes combine test index (shifted left by 12 bits) and test‑specific return value.  
- LED register `0xE00010` is updated each iteration, possibly indicating current test step.  
- The data following the function (0x80120e–0x801244) appears to be a jump table or constant data for another part of the ROM, not executed here.  
- This is likely part of the DMA processor’s power‑on self‑test sequence in the U17 ROM.

---

### Function at 0x8012cc

**Embedded strings:**
- `8393445`: `"9n. "`
- `8393558`: `"N^NuNV"`
- `8393622`: `"N^NuNV"`

**Name**: `parse_hex_digit_sequence`  

**Purpose**: This function reads a sequence of ASCII characters from a memory location (`0xC006E2`) and interprets them as hexadecimal digits, accumulating the result into a 32‑bit integer. It handles digits `0‑9`, uppercase `A‑F`, and lowercase `a‑f`. The function stops when a non‑hexadecimal character is encountered, returning the accumulated value.  

**Parameters**:  
- Implicit input: The global pointer at `0xC006E2` points to the current character in the string being parsed.  
- Register `d6` appears to hold a running value during parsing (though it is overwritten each iteration).  
- Register `d7` holds the current character being examined.  

**Returns**:  
- `d0` contains the final parsed hexadecimal value (accumulated in `d5`).  

**Key Operations**:  
- Calls subroutine at `0x80135A` (likely initializes or advances a string pointer).  
- Loads a byte from the address stored at `0xC006E2` into `d7`.  
- Checks if `d7` is `0‑9` (ASCII 0x30–0x39): subtracts 0x30 to convert to numeric value.  
- If `d7` is `A‑F` (0x41–0x46): subtracts 0x37 (decimal 55) to convert.  
- If `d7` is `a‑f` (0x61–0x66): subtracts 0x57 (decimal 87) to convert.  
- Accumulates the result by shifting the previous value left 4 bits (`asll #4`) and adding the new digit.  
- Increments the pointer at `0xC006E2` after each valid digit.  
- Returns when a character outside the three valid ranges is found.  

**Called Functions**:  
- `0x80135A` — unknown subroutine; likely prepares or advances the input stream.  

**Notes**:  
- The function uses a global pointer at `0xC006E2` as the current position in the input string; this is typical of a simple scanner/parser in a monitor or debugger.  
- The loop structure is unusual: it checks for the digit `9` (0x39) early (`cmpil #57,%d7`) but this appears to be a guard against non‑digit characters before the `0‑9` check; the logic flow ensures only valid hex digits are processed.  
- The function does not handle overflow beyond 32 bits; it simply shifts and accumulates.  
- This is likely part of the debug monitor’s command interpreter, used to parse hexadecimal arguments (e.g., addresses, data values) from user input.

---

### Function at 0x80135a

**Embedded strings:**
- `8393622`: `"N^NuNV"`

**Name**: `skip_whitespace`  

**Purpose**: This function reads a byte from a memory-mapped location (likely a hardware register or shared memory buffer) and increments the pointer until a non-whitespace character is encountered. It treats ASCII space (0x20) and horizontal tab (0x09) as whitespace to skip. This is typical of parsing routines in monitor/debug ROMs that process user input or structured data from a device.  

**Parameters**:  
- Implicitly uses the global pointer at address `0xC006E2`, which points to the current character position in an input buffer or hardware register.  

**Returns**:  
- `%d7` contains the first non-whitespace byte read (zero-extended to a long word).  
- The pointer at `0xC006E2` is advanced to just after the skipped whitespace.  

**Key Operations**:  
- Loads the byte at `0xC006E2` into `%d7` and zero-extends it to a long word.  
- Compares `%d7` with 0x20 (space) and 0x09 (tab).  
- If a match is found, increments the pointer at `0xC006E2` by one and repeats.  
- Stops when a non-whitespace byte is read and returns it in `%d7`.  

**Called Functions**: None (no `jsr` or `bsr` instructions).  

**Notes**:  
- The pointer at `0xC006E2` is likely a global variable used by the debug monitor to track input position—possibly pointing into a serial input buffer, SCSI data buffer, or shared memory used for command parsing.  
- The function preserves `%d7` across calls by saving/restoring it on the stack.  
- The use of `extw` followed by `extl` suggests the original byte is treated as unsigned.  
- This is a low-level helper function, probably called by command interpreters or data readers in the U17 ROM.

---

### Function at 0x80139a

**Embedded strings:**
- `8393800`: `"N^NuNV"`
- `8393823`: `"Dg(N"`

**Name**: `selftest_memory_bus_arbitration`  

**Purpose**: This function performs a memory bus arbitration test by writing known values to specific memory locations, verifying they can be read back correctly, and restoring original contents. It appears to test the DMA processor's ability to access memory across a large address range while the Job processor may also be accessing memory, checking for bus contention or arbitration issues. The test writes to every 512 KB block (0x80000 bytes) from 0x0 to 0x800000, then reads back and verifies the values.

**Parameters**: None explicitly passed; the function uses hardcoded memory ranges and hardware register addresses.

**Returns**: Returns the number of 512 KB memory blocks successfully tested (scaled by 64) in `D0`. The original contents of tested memory are restored before returning.

**Key Operations**:
- Reads the system control register at `0xE00016` (status/control) and saves its original value.
- Sets bit 8 (0x0100) in the control register (likely enabling/disabling memory mapping or bus arbitration).
- Calls a subroutine at `0x805656` with argument 7 (possibly a delay or hardware initialization).
- **Phase 1**: Saves the original 32-bit values from every 512 KB block (starting at 0x0 up to 0x800000) into a local stack array (256 entries).
- **Phase 2**: Writes the address of each block into that block (i.e., writes the block’s base address as data).
- **Phase 3**: Verifies each block contains its own address; counts successful blocks in `D6`.
- **Phase 4**: Restores the original saved values to each tested block.
- Restores the original control register value to `0xE00016`.
- Calls subroutine at `0x8058f4` (possibly a completion notification or LED update).
- Returns `D6 << 6` (i.e., number of good blocks × 64).

**Called Functions**:
- `0x805656` with argument 7 — likely a delay or hardware sync function.
- `0x8058f4` — likely a test result logger or status update.

**Notes**:
- The test spans from address 0x0 to 0x800000 (8 MB), but the Plexus P/20 has only up to 4 MB RAM; the upper region may be ROM or I/O space. The test may intentionally include non‑RAM areas to check bus error handling.
- The control register manipulation (setting bit 8) may enable a special test mode, such as disabling the Job processor or enabling bus isolation.
- The function preserves the original memory contents, indicating it is a non‑destructive test.
- The return value is scaled by 64, possibly to report the number of 512 KB blocks in a more compact form, or to match a specific test result format expected by a caller.
- The use of `%a5` as both pointer and data value (`movel %a5, %a5@`) is a common pattern for address‑based memory tests.

---

### Function at 0x80144c

**Embedded strings:**
- `8393823`: `"Dg(N"`
- `8393872`: `"N^NuNV"`
- `8393907`: `"Dg N"`

**Name**: `compare_and_report_mismatch`

**Purpose**: This function compares two 32-bit values (likely memory addresses or data values) and, if they differ, checks a system flag at 0xC00644. If that flag is non-zero, it triggers a diagnostic reporting sequence that prints a formatted message (using a format string at address 0x8079F3) and calls a system logging/alert routine before returning a failure status. Essentially, it's a diagnostic comparison function used during self‑test or debugging to report mismatches when a certain system flag is enabled.

**Parameters**:  
- `%fp@(8)`: First parameter (likely a context identifier or base address)  
- `%fp@(12)`: Second parameter (first value to compare)  
- `%fp@(16)`: Third parameter (second value to compare)  

**Returns**:  
- `%d0`: Returns 1 if the two compared values are different, 0 if they are equal.

**Key Operations**:  
- Compares two longwords passed on the stack.  
- Tests the longword at memory address `0xC00644` (likely a global diagnostic‑enable flag).  
- If the values differ *and* the flag is non‑zero, calls `0x805B72` (possibly a “prepare for reporting” or “enter diagnostic mode” routine).  
- Pushes the two compared values and a format‑string address (`0x8079F3`) onto the stack, then calls `0x800E10` (likely a `printf`‑style formatted output function).  
- After printing, calls `0x805930` (possibly a “log error” or “alert console” routine).  
- Returns 1 for mismatch, 0 for match.

**Called Functions**:  
- `0x805B72`: Unknown; may prepare hardware or set a diagnostic state.  
- `0x800E10`: Formatted print function (takes format string and arguments).  
- `0x805930`: Unknown; may finalize error reporting or trigger a system response.

**Notes**:  
- The format string at `0x8079F3` is not listed in the provided strings, but its address (`0x8079F3`) lies within the U17 ROM range (`0x800000–0x807FFF`), suggesting it is an internal diagnostic message.  
- The flag at `0xC00644` is in the shared RAM area (`0xC00000–0xC00FFF`), indicating it is a runtime‑configurable diagnostic‑output enable.  
- This function appears to be part of a larger self‑test framework where mismatches are reported conditionally, avoiding console spam unless diagnostics are explicitly enabled.  
- The function preserves the stack frame with `linkw`/`unlk`, suggesting it is meant to be called from C or other high‑level code.

---

### Function at 0x801494

**Embedded strings:**
- `8393907`: `"Dg N"`
- `8393952`: `"N^NuNV"`
- `8393975`: `"Dg(N"`

**Name**: `check_diagnostic_flag_or_report_error`

**Purpose**:  
This function appears to be part of the diagnostic/self‑test logic in the U17 ROM. It checks the result of a diagnostic test (passed in via the stack) and, if the test failed (return value ≠ 1), it checks a global flag at `0xC00644`. If that flag is non‑zero, it calls an error‑reporting routine that prints a failure message (using a format string at address `0x807A19`) and then possibly logs or halts. The function returns 1 for failure (with reporting) or 0 for success.

**Parameters**:  
- One 32‑bit argument passed on the stack at `%fp@(8)` (likely a test identifier or error code).

**Returns**:  
- `%d0` = 0 if the diagnostic test passed (input result == 1),  
  `%d0` = 1 if the test failed and error reporting was performed (or suppressed by the global flag).

**Key Operations**:  
- Calls a subroutine at `0x8056D2` with the input argument; that routine likely runs a specific hardware test and returns a status (1 = pass, other = fail).  
- Compares the returned status against 1 (success).  
- Tests a global flag at `0xC00644` — this probably controls whether to suppress error messages or enable verbose diagnostic output.  
- If the flag is set and the test failed, calls `0x805B72` (possibly an error‑initialization routine), then formats and prints an error message using `0x800E10` (likely a `printf`‑style function) with a format string at `0x807A19`.  
- Finally calls `0x805930` (could be an error‑logging or system‑response routine).  
- Preserves `%d7` across the function.

**Called Functions**:  
- `0x8056D2` — diagnostic test routine (takes one argument).  
- `0x805B72` — error‑reporting setup.  
- `0x800E10` — formatted print function (takes format string and arguments).  
- `0x805930` — error‑handling finalization (may trigger a halt or log entry).

**Notes**:  
- The format string at `0x807A19` is not listed in the provided strings, but nearby strings (`"Dg N"`, `"N^NuNV"`, `"Dg(N"`) suggest diagnostic‑related messages (e.g., “Dg” for “Diagnostic”).  
- The global flag at `0xC00644` is in the shared RAM area (`0xC00000–0xC00FFF`), indicating it may be set by the Job processor or by earlier boot stages to control diagnostic verbosity.  
- This function is typical of a modular self‑test framework where each test returns 1 for pass, and failures can be reported conditionally.  
- The function’s address (`0x801494`) places it early in the U17 ROM, likely part of the main diagnostic sequence called after reset.

---

### Function at 0x8014e4

**Embedded strings:**
- `8393975`: `"Dg(N"`
- `8394024`: `"N^NuNV"`
- `8394068`: `"Y0N^NuNV"`

**Name**: `compare_and_log_mismatch`

**Purpose**: This function compares two 32-bit values (likely memory addresses or data values) and, if they differ and a global flag is set, logs the mismatch via a debug output routine before returning a failure status. It appears to be part of a diagnostic or verification routine—possibly for memory testing, data transfer validation, or hardware register verification—where mismatches are conditionally reported to a debugging system.

**Parameters**:  
- `%fp@(8)`: First parameter (likely a context identifier or base address)  
- `%fp@(12)`: Second parameter (first value to compare)  
- `%fp@(16)`: Third parameter (second value to compare)  

**Returns**:  
- `%d0`: Returns `1` if the two input values differ; returns `0` if they are equal.

**Key Operations**:  
- Compares two longwords passed on the stack.  
- Checks a global flag at address `0xC00644`—this is likely a debug or logging enable flag in shared RAM.  
- If the values differ and the flag is non‑zero, calls a logging function (`0x800e10`) with a fixed string pointer (`#8419903`, which corresponds to the string at `0x807a3f`).  
- After logging, calls a cleanup or continuation routine at `0x805930`.  
- Returns a boolean result indicating whether a mismatch occurred.

**Called Functions**:  
- `0x805b72`: Unknown preparatory function (possibly initializes logging or acquires a lock).  
- `0x800e10`: Likely a formatted print or debug‑output function (takes four arguments, including the string at `0x807a3f`).  
- `0x805930`: Unknown follow‑up function (could release resources or update diagnostic state).

**Notes**:  
- The fixed string address `0x807a3f` lies within the U17 ROM space; the referenced string (`"Dg(N"` from the provided list) may be a debug code or abbreviated message.  
- The global flag at `0xC00644` is in the shared RAM area (`0xC00000–0xC00FFF`), suggesting it is set by other diagnostic code to control verbose output.  
- The function is careful to only invoke the logging calls when both a mismatch occurs and the flag is set, minimizing overhead during normal operation.  
- This pattern is typical of hardware self‑test or firmware debugging routines where mismatches are expected during development but should be logged only when diagnostics are enabled.

---

### Function at 0x80152c

**Embedded strings:**
- `8394068`: `"Y0N^NuNV"`
- `8394097`: `"V @JPf"`
- `8394113`: `"V @0"`
- `8394124`: `"N^NuNV"`

**Name**: `conditional_debug_print`  

**Purpose**:  
This function checks a global flag at address `0xC00644`. If the flag is non-zero, it calls a debug initialization routine, prints a debug message using a format string at address `0x807A64`, and then calls a cleanup routine. The function appears to be part of the self-test/debug monitor, used to conditionally output diagnostic information when debugging is enabled.

**Parameters**:  
- `%fp@(8)` (the first 32-bit argument on the stack after the frame pointer) — likely a value or pointer to be included in the debug output.

**Returns**:  
No explicit return value; the function is void.

**Key Operations**:  
- Tests the longword at `0xC00644` (likely a debug enable/disable flag).  
- Calls `0x805B72` — probably a debug output initialization or setup routine.  
- Passes the argument from the caller and a format string pointer to `0x800E10` — likely a `printf`-style formatted output function.  
- Calls `0x805930` — probably a debug output cleanup or finalization routine.  
- Uses a stack-based frame (`linkw %fp,#-4`) but does not appear to use the local variable space.

**Called Functions**:  
- `0x805B72` — debug output setup  
- `0x800E10` — formatted print function  
- `0x805930` — debug output cleanup  

**Notes**:  
- The format string at `0x807A64` is not listed in the provided strings, but nearby strings suggest it may contain debugging codes (e.g., "V @JPf", "V @0").  
- The flag at `0xC00644` is in the shared RAM area (`0xC00000–0xC00FFF`), meaning it could be set by either the DMA or Job processor to enable debug output.  
- The function is short and conditional, typical of diagnostic code that can be toggled on/off without affecting normal operation.  
- The sequence of setup → print → cleanup suggests the debug output may involve hardware state changes (e.g., configuring serial ports or LEDs).

---

### Function at 0x80155a

**Embedded strings:**
- `8394097`: `"V @JPf"`
- `8394113`: `"V @0"`
- `8394124`: `"N^NuNV"`
- `8394144`: `"g&*|"`
- `8394170`: `"g& ."`

**Name**: `store_word_to_dynamic_table`

**Purpose**: This function stores a 16-bit word value (passed on the stack) into the next available slot in a table located at address `0xC00656`. It first scans the table to find the first entry that contains zero (indicating a free slot), then writes the supplied word to that slot. The table appears to be an array of 16-bit values in shared RAM, and the function effectively appends a value to the list.

**Parameters**: 
- Input word (16-bit) is passed on the stack at offset `+10` from the frame pointer (`%fp@(10)`). This is consistent with a Motorola 68010 calling convention where word parameters are pushed onto the stack before the subroutine call.
- The table base address is hardcoded as `0xC00656` (in shared RAM area `0xC00000-0xC00FFF`).

**Returns**:
- No explicit register return value. The function's side effect is writing the input word to the calculated table entry.
- Register `%d7` is preserved (saved/restored via the stack).

**Key Operations**:
- Uses a `linkw` instruction to create a stack frame and allocates 8 bytes of local space.
- Saves the caller's `%d7` register on the stack.
- Initializes a loop counter/index `%d7` to zero.
- In a loop, calculates `0xC00656 + (index * 2)` (since each entry is a word, 2 bytes) and checks if the word at that address is zero.
- If not zero, increments the index and loops again.
- Once a zero entry is found, calculates the same address again and stores the input word (`%fp@(10)`) into that table slot.
- Restores `%d7` and returns.

**Called Functions**:
- None. This function is a leaf routine (no `jsr` or `bsr`).

**Notes**:
- The table is located in the shared RAM area (`0xC00000-0xC00FFF`), which is accessible by both the DMA and Job processors. This suggests the table could be used for inter-processor communication or shared state tracking.
- The function always finds a free slot because it loops until it finds a zero word; if the table were full (no zeros), it would read past the table's intended boundary (no bounds checking). This could lead to memory corruption.
- The hardcoded base address `0xC00656` is specific and likely corresponds to a known data structure in the Plexus P/20's shared memory layout. It might be part of a diagnostic log, command queue, or configuration array used during the self-test/debug monitor operations.
- The function is relatively small and efficient, using `asll #1` for the multiply-by-two offset calculation.

---

### Function at 0x801590

**Embedded strings:**
- `8394144`: `"g&*|"`
- `8394170`: `"g& ."`
- `8394214`: `"N^NuNV"`
- `8394246`: `"JUg*J"`
- `8394255`: `"Dg N"`
- `8394294`: `"JUg*J"`
- `8394303`: `"Dg N"`
- `8394348`: `"N^NuNV"`
- `8394454`: `"[2Hx"`
- `8394492`: `"[2Hx"`
- `8394534`: `"[2Hx"`
- `8394594`: `"N^NuNV"`

**Name**: `scsi_verify_drive_presence`  

**Purpose**:  
This function appears to perform a SCSI drive presence check and possibly a basic inquiry or test. It first waits for the SCSI bus to become ready (not busy), then sends a SCSI command (likely a TEST UNIT READY or INQUIRY) to two different SCSI target addresses (0xD00012 and 0xD0001C), reads back status, and finally calls a verification subroutine. If any step fails, it returns an error code; otherwise, it returns the status from the final verification step.

**Parameters**:  
- Input parameter passed via stack at `%fp@(8)` (likely a SCSI LUN or target ID for the final verification step).  
- No other explicit parameters; uses hardcoded SCSI controller addresses.

**Returns**:  
- Returns a status/error code in `%d0`.  
  - `8` if SCSI bus never becomes ready (timeout).  
  - Otherwise returns status from verification subroutine (`0x801766`) or error from earlier SCSI commands.

**Key Operations**:  
- Waits for SCSI bus ready by polling bit 7 of `0xD00015` (SCSI busy flag) with a timeout of ~65536 iterations.  
- Writes `0x80` to `0xD00017` (likely SCSI command/control register).  
- Calls `0x800dd6` (looks like a memory copy/transfer routine) to move 0x80 bytes from `0xC006E6` to `0xD00000` (SCSI data buffer).  
- Calls `0x803e9e` (likely a SCSI command routine) twice with different target addresses:  
  - First: `0xD00012` (SCSI target ID 1?) and `0xD00002` (command register?).  
  - Second: `0xD00080` and `0xD0001C` (another target/LUN).  
- Restores original SCSI control setting (`0x06` to `0xD00017`).  
- Calls verification subroutine at `0x801766` with the input parameter.  
- Propagates error codes from SCSI commands or verification step.

**Called Functions**:  
- `0x800f06` (in first subfunction) – unknown check.  
- `0x8054fa` (in first subfunction) – likely error/print routine.  
- `0x800700` (in second subfunction) – unknown.  
- `0x805b72` and `0x805930` (in second subfunction) – likely debug output routines.  
- `0x800e10` – printf-like output.  
- `0x80152c` – error handling.  
- `0x800dd6` – memory copy.  
- `0x803e9e` – SCSI command execution.  
- `0x801766` – SCSI verification subroutine.

**Notes**:  
- The function contains three distinct blocks:  
  1. `0x801590–0x8015e8`: A loop that writes longwords to an array pointed to by `%a5` (likely a DMA descriptor or buffer setup).  
  2. `0x8015ea–0x80166e`: A subroutine that checks two word values at a local variable and prints debug messages if `0xC00644` is nonzero (debug mode).  
  3. `0x801670–0x801764`: The main SCSI drive check logic described above.  
- The SCSI controller appears to be memory-mapped at `0xD00000`–`0xD000FF` (Omti 5200 registers).  
- The timeout loop at `0x801680–0x801692` will hang indefinitely if the SCSI bus stays busy; it returns error 8 if the counter expires.  
- The function seems to be part of the boot-time SCSI device detection/validation in the DMA processor’s self-test ROM.

---

### Function at 0x801766

**Embedded strings:**
- `8394770`: `"N^NuNV"`
- `8394812`: `"gHrA"`
- `8394818`: `"gjrD"`

**Name**: `scsi_diagnostic_or_boot_check`

**Purpose**: This function appears to perform a SCSI-related diagnostic or boot device check. It first attempts a SCSI operation (likely a test read or inquiry), then initializes or communicates with the SCSI controller via specific register writes, performs timing delays and serial port operations, checks a returned value against expected ranges, and finally returns a status code. The function may be part of the boot process determining which SCSI device to boot from or verifying SCSI subsystem functionality.

**Parameters**: 
- `%fp@(8)` (first argument on stack): Likely a flag or device identifier. If zero, the function performs a SCSI operation via `0x8054fa`.

**Returns**:
- `%d0` (return value): Status code derived from `%d7`. Possible values:
  - `0` if initial SCSI operation failed or wasn't performed
  - `1` if SCSI operation returned error code `0x000000E0` (224 decimal)
  - `7` if certain conditions are met (serial check out of range and `0xc00644` non-zero)
  - Otherwise, the result from the SCSI operation (possibly modified)

**Key Operations**:
- Calls `0x8054fa` with arguments `(1, 0, 2)` when input parameter is zero (likely a SCSI command)
- Adjusts return value: if result is non-zero and `< 224`, increments it (error code adjustment)
- Writes `0x0E` to `0xD00017` and `0x2A` to `0xD00015` (SCSI controller registers - OMTI 5200 control/command registers)
- Calls `0x805656` with argument `6` (likely serial port output)
- Delays via `0x8005e0` with argument `0x1E` (30 units)
- Calls `0x8056d2` with argument `0x83` (serial port read or status check)
- Compares returned value (`%d6`) against range 25-31 (0x19-0x1F); if outside, checks `0xc00644`
- If `0xc00644` is non-zero, calls debug output functions (`0x805b72`, `0x800e10` with string pointer `0x807a89`, `0x805930`) and sets return status to 7

**Called Functions**:
- `0x8054fa`: SCSI operation (likely `scsi_command` or `scsi_test_unit_ready`)
- `0x805656`: Serial output function (putchar or control)
- `0x8005e0`: Delay function (milliseconds or cycles)
- `0x8056d2`: Serial input function (getchar or status)
- `0x8058f4`: Serial flush or status check
- `0x805b72`: Debug output init
- `0x800e10`: Formatted print (with string at `0x807a89` - likely error message)
- `0x805930`: Debug output cleanup

**Notes**:
- The function writes to OMTI 5200 SCSI controller registers at `0xD00015` and `0xD00017` (common addresses for data/command registers).
- The value `0x83` passed to `0x8056d2` may be a serial port select or command (SCC register index).
- The check against `0xc00644` suggests a system flag (possibly "debug mode enabled" or "diagnostic failure flag").
- The string at `0x807a89` (referenced but not in provided strings) likely contains an error message like "SCSI timeout" or "Device not responding".
- The range check (25-31) on the serial read value may be validating a specific response byte from a SCSI device or controller.
- The function has two distinct failure paths: one from the initial SCSI operation, and another from the serial/SCSI handshake check.

---

### Function at 0x801816

**Embedded strings:**
- `8394812`: `"gHrA"`
- `8394818`: `"gjrD"`
- `8394897`: `"@`rN"`
- `8394916`: `"``By"`
- `8394955`: `"``8p"`
- `8395014`: `"N^NuNV"`
- `8395096`: `"[2Hx"`
- `8395362`: `"[2BTHx"`
- `8395460`: `"gjHx"`
- `8395590`: `"N^Nu"`
- `8395656`: `"`l Up"`
- `8395686`: `"g< m"`
- `8395749`: `"CJCf"`
- `8395790`: `"N^Nu"`
- `8396042`: `" @*P"`
- `8396336`: `"g\np!"`
- `8396418`: `"g\np)"`
- `8396488`: `"N^NuNV"`
- `8396590`: `"[2*|"`
- `8396632`: `"[2,9"`
- `8396742`: `"N^NuNV"`
- `8396778`: `"N^NuNV"`
- `8396817`: `"Dg0N"`

**Name**: `handle_interrupt_or_exception` (first part) and `perform_system_diagnostics` (main part)

**Purpose**: This is a multi-part function that appears to handle various system events and perform comprehensive hardware diagnostics. The initial section (0x801816-0x801908) processes interrupt/exception type codes by clearing specific hardware error flags based on the input code. The main section (0x80190a-0x801eca) executes a detailed system self-test sequence including memory testing, SCSI controller initialization/testing, and hardware register validation, likely as part of the DMA processor's boot-time diagnostics.

**Parameters**: 
- First function (0x801816): Input parameter at `%fp@(8)` contains an event code (byte)
- Main function (0x80190a): Input parameter at `%fp@(8)` appears to be a test mode flag (0 for normal, non-zero for special mode)

**Returns**:
- First function: No explicit return value, but clears hardware flags
- Main function: Returns error code in `%d0` (0 for success, non-zero for failure)

**Key Operations**:
- Clears specific hardware error flags based on input event codes (0x02, 0x18, 0x41, 0x44, 0x7F, 0x83, 0xC1, 0xC2)
- Accesses system control registers at 0xE00000-0xE001A0 for status reading and flag clearing
- Performs memory testing at address 0x1000 using pattern 0xA5A5
- Tests SCSI controller functionality through multiple command sequences
- Validates hardware register read/write operations
- Manages processor control bits (DIS.MAP, interrupt enables)
- Stores diagnostic results in shared RAM area at 0xC007E6-0xC007EE

**Called Functions**:
- 0x800f06: `check_system_state` (checks processor status)
- 0x8054fa: `allocate_memory_or_resource` (with parameters 5, 0, 1)
- 0x805b32: `delay_or_synchronize` (timing function)
- 0x801590: `configure_hardware_register` (with three parameters)
- 0x805714: `scsi_controller_command`
- 0x80577a: `get_scsi_status`
- 0x8014e4: `validate_scsi_response`
- 0x800c74: `check_bus_error_flags`
- 0x805b72: `reset_scsi_bus`
- 0x800e10: `display_error_message` (with string at 0x807A91)
- 0x80144c: `compare_memory_or_register` (validation function)
- 0x800600: `scsi_execute_command`
- 0x8058f4: `restore_system_state`
- 0x800738: `finalize_diagnostics`
- 0x8039ca: `memory_test_function` (in second function at 0x801ed0)
- 0x803e9e: `initialize_system_memory` (in final function at 0x801fca)

**Notes**:
1. The function handles at least 8 different event codes that correspond to specific hardware error conditions (bus errors, parity errors, SCSI errors, etc.)
2. The main diagnostic sequence tests 8 different SCSI controller registers (iterates through %d6 from 0 to 7)
3. Uses shared memory at 0xC00652 to store a test pattern (0xFFFF)
4. The code at 0x801ed0 appears to be a separate but related function that performs memory testing at address 0x902000
5. The final function at 0x801fca initializes memory regions from 0xC01000 to 0xC03000
6. String references in the code suggest error messages are displayed for various failure conditions
7. The function extensively manipulates the system control register at 0xE00016 (bits 0x0221 and 0xFFBF patterns)
8. Appears to be part of the DMA processor's ROM-based self-test executed during system boot

---

### Function at 0x801fee

**Embedded strings:**
- `8396817`: `"Dg0N"`
- `8396926`: `"z@p\r"`
- `8396936`: `"[2-|"`
- `8397018`: `"[2Hx"`
- `8397078`: `"|	Hx"`
- `8397122`: `"N^NuNV"`
- `8397227`: `"wHx "`
- `8397255`: `"wHx "`
- `8397292`: `"`&RTHx"`
- `8397436`: `"`"Hx"`
- `8397580`: `"N^Nu"`
- `8397630`: `"*HHx"`

**Name**: `selftest_memory_and_cache`  

**Purpose**: This function performs a comprehensive memory and cache diagnostic test. It appears to be part of the DMA processor's self‑test/debug ROM, testing RAM integrity, cache coherency, and possibly memory‑mapped I/O regions. The test includes writing/reading patterns, checking for bus errors, and validating that memory behaves correctly under different access modes (e.g., with/without cache). It may also test the shared‑memory arbitration between the DMA and Job processors.

**Parameters**:  
- Input parameter(s) passed via the stack at `%fp@(8)` and `%fp@(10)`.  
  - `%fp@(8)` seems to be a control word (bits masked with `0xFFFFBFFF`).  
  - `%fp@(10)` contains a bit‑field; bit 6 is tested to decide whether to enable a special mode (possibly cache‑bypass or diagnostic mode).  
- Global hardware register `0xE00016` (system control) is read via `%a5` (set to `0xE00016`).  
- Global memory locations `0xC00644`, `0xC00832`, `0xC0082A`, `0xC00826` are used for flags or results.

**Returns**:  
- Returns a status code in `%d0`:  
  - `0` = success?  
  - `1` = early failure (random‑number generator returned zero?)  
  - `2`–`10` = various error codes from subtests (e.g., `%d6` holds the error code).  
- Modifies memory‑mapped hardware registers (LEDs, system control) and shared‑memory flags.

**Key Operations**:  
- Reads bit 6 of `%fp@(10)`; if set, uses `%d5 = 64` (maybe a cache‑disable or special‑access flag).  
- Calls a random‑number generator (`0x80139a`) to decide test parameters.  
- Writes to system control register `0xE00016` (sets/clears bit 8 = `0x0100`, possibly `DIS.MAP` or `DIAG`).  
- Sets shared‑memory flag `0xC00832` to 1.  
- Calls a subroutine at `%fp@(-4)` = `0xC01000` (looks like a RAM‑test routine loaded from ROM).  
- Tests memory regions:  
  - Compares `0x900000`–`0x904000` with `0x904000`–`0x908000` (cache‑coherency check?).  
  - Compares `0xC006A6`–`0xC006E6` with `0xC0067E`–`0xC006BE` (shared‑data area).  
- Uses `0x803f26` (memory‑compare function) to verify data integrity.  
- In the second half (starting at `0x802146`), performs additional memory‑filling and checking:  
  - Fills `0x900000`–`0x902000` with `0x77` and `0x902000`–`0x904000` with `0x77` (pattern test).  
  - Tests every 4098‑byte block from `0x0` to `0x800000` (main RAM) using `0x80144c` (likely a read/write verify).  
  - Tests every 2‑byte block from `0x0` to `0x2000` (low RAM or I/O space).  
- Clears `0xE0001E` (serial‑port control?).  
- Calls `0x800f06` to check if Job processor is alive; if yes, fills memory with a walking‑one pattern.  
- Returns error codes in `%d6` (0=ok, 1=first subtest fail, 2=second, 3=third, 9/10=compare failures).

**Called Functions**:  
- `0x80139a` – random‑number generator.  
- `0x800e3e` – printf‑style output (prints test parameters).  
- `0x805b32` – short delay or watchdog reset.  
- `0x800dd6` – possibly memory‑initialization or fill.  
- `0x800f06` – checks Job‑processor status.  
- `0x803f26` – memory‑compare routine.  
- `0x805b9e` – unknown (maybe set test mode).  
- `0x8054fa` – memory fill with pattern.  
- `0x80144c` – memory verify (read/write check).  
- `0x800e46`, `0x800e62` – debug output or checksum.  
- `0x801590` – another memory‑test helper.

**Notes**:  
- The function is large and clearly a major self‑test routine, likely invoked early in boot to validate RAM and cache before loading the OS.  
- It uses a pseudo‑random seed to vary test patterns, making it sensitive to memory‑cell faults.  
- The two‑part structure (first half at `0x801fee`, second at `0x802146`) suggests it may be two related tests called in sequence.  
- The second half includes a loop that writes incrementing values to memory (`%a5@+ = %d7`) when the Job processor is alive, possibly to test shared‑memory arbitration.  
- Error codes are distinct and could be displayed on LEDs or via serial debug.  
- The final block (`0x802310`–`0x80232e`) looks like data (maybe test patterns or jump‑table entries) rather than code.

---

### Function at 0x8024c0

**Embedded strings:**
- `8398121`: `"?f N"`
- `8398164`: `"|d`*"`
- `8398256`: `"N^NuNV"`
- `8398290`: `"5@$y"`
- `8398296`: `"5D-|"`
- `8398318`: `"5< ."`

**Name**: `parse_debug_command_argument`

**Purpose**: This function parses a debug monitor command argument string from a global input buffer, extracting numeric values and format specifiers to populate a command argument structure. It handles decimal numbers, hexadecimal values (prefixed with '$'), optional repeat counts (prefixed with '?'), and format specifiers ('%' or '$' for special handling). The parsed result is stored in a structure for use by debug command handlers.

**Parameters**: 
- `%fp@(8)` (`%a5` after load): Pointer to a command argument structure (likely at least 20 bytes)
- `%fp@(12)`: Initial value for the global input pointer `0xc006e2`

**Returns**:
- `%d0`: The next character from the input buffer after parsing (zero-extended to long word)
- The function's primary output is the populated structure at `%a5`:
  - `%a5@(0)`: First parsed numeric value (long word)
  - `%a5@(4)`: Second parsed numeric value (long word, if comma present)
  - `%a5@(8)`: Format/type specifier (word)
  - `%a5@(10)`: Character code of format specifier (word)
  - `%a5@(12)`: Third parsed numeric value (long word)
  - `%a5@(16)`: Repeat count (long word, -1 if '?' without number)

**Key Operations**:
- Stores the initial input pointer value to global variable `0xc006e2` (command line buffer pointer)
- Sets default format type to 36 (ASCII '$' character) at offset 8 in the structure
- Calls `0x80135a` (likely a whitespace-skipping or delimiter checking routine) twice
- Calls `0x8012cc` (numeric parsing routine) multiple times to convert ASCII to binary
- Handles comma separator (ASCII 44) to parse two separate numeric arguments
- Detects '?' prefix (ASCII 63) for optional repeat count, parsing following number (or using -1 if zero)
- Detects '/' (ASCII 47) and converts it to decimal 100 for special handling
- Recognizes format specifiers '$' (ASCII 36) and '%' (ASCII 37), storing them at structure offsets 8 and 10
- Always reads the next character after parsing and returns it in `%d0`

**Called Functions**:
- `0x80135a`: Called at 0x8024e2, 0x80250c, 0x802598 (likely `skip_whitespace` or `check_delimiter`)
- `0x8012cc`: Called at 0x8024e8, 0x802502, 0x80252c, 0x802582 (likely `parse_number` or `ascii_to_hex`)

**Notes**:
- The global variable at `0xc006e2` serves as a command line parsing pointer, incremented as characters are consumed
- The structure format suggests debug commands support: `[repeat?]value1[,value2][/format]value3` syntax
- Special case: When '/' is encountered, it's converted to 100 (decimal) before further processing
- The '?' prefix with no following number results in a repeat count of -1 (0xFFFFFFFF)
- The function appears to be part of the debug monitor's command interpreter, parsing arguments for commands like those listed in the known functions (debug 'a', 'b', 'c', etc.)
- No direct hardware register access in this function; it's purely parsing logic for the debug interface

---

### Function at 0x8025b4

**Embedded strings:**
- `8398290`: `"5@$y"`
- `8398296`: `"5D-|"`
- `8398318`: `"5< ."`
- `8398784`: `"`Npi"`
- `8399004`: `"g,pd"`
- `8399070`: `"oDpd"`
- `8399182`: `"o,pd"`
- `8399220`: `"Z -@"`
- `8399522`: `"f8Bj"`
- `8399730`: `" @"n"`
- `8399875`: `"P @."`
- `8400021`: `"P @."`
- `8400086`: `" @ PN"`
- `8400901`: `"\n Gp"`
- `8400948`: `"g^pb"`
- `8400954`: `"gXpc"`
- `8400960`: `"gR 9"`
- `8402085`: `"Fl\nrZ"`
- `8402117`: `"<l"rm"`
- `8402194`: `"N^NuNV"`
- `8402232`: `"N^Nu"`

**Name**: `debug_command_dispatcher`  

**Purpose**: This function is the main dispatch handler for the Plexus P/20's self‑test/debug monitor command interpreter. It processes a command code (passed in `d5`) and up to four numeric arguments (`d7`, `d4`, `d6`, and a stack argument) to perform hardware diagnostics, memory/register inspection, SCSI operations, IPC communication, and system control. The function uses a large jump table (starting at `0x80261e`) to route execution to the appropriate command handler based on the ASCII value of the command character.  

**Parameters**:  
- `d7`: First numeric argument (often an address or data value).  
- `d4`: Second numeric argument (often a count or offset).  
- Stack argument at `fp@(16)`: A third argument (used only by commands `'$'` (0x24) and `'%'` (0x25)).  
- `d5`: Command character (ASCII value).  
- `d6`: Fourth numeric argument (used by many commands).  
- `a5`: Points to a shared memory control‑block area (likely `0xc00836` or similar).  
- `a3`, `a2`: Pointers to ROM‑based data structures (e.g., `0x803540`, `0x803544`).  

**Returns**:  
- `d2`: Status/result code (often 0 for success, non‑zero for error).  
- `d0` on exit: Same as `d2` (via `movel %d2,%d0`).  
- Memory location `0xc00860` is frequently updated with the result.  

**Key Operations**:  
- Validates the command character against a range (0x21–0x77) and dispatches via a jump table.  
- Performs memory tests and comparisons (e.g., commands `'c'`, `'f'`, `'i'`).  
- Calls SCSI‑related routines (e.g., `0x803516`, `0x80621a`) for disk I/O.  
- Uses IPC (Inter‑Processor Communication) functions (`0x802d82`, `0x802e32`, `0x802e4a`) to coordinate with the Job processor.  
- Writes to hardware control registers (e.g., LED control at `0xe00010`, system control at `0xe00016`).  
- Prints diagnostic strings via `0x800e10` (likely a formatted output routine).  
- Modifies shared‑memory control blocks (via `a5`) to set up SCSI commands (e.g., command bytes 0x08, 0x11, 0x0a for read, write, verify).  
- Handles special commands like `'!'` (store word to `0xc00860`), `'"'` (store byte), `'%'` (complex checks), `'V'` (print version), `'X'` (print CSRs).  

**Called Functions**:  
- `0x800610` – Likely a memory test or fill routine.  
- `0x800e10` – Formatted string output (print).  
- `0x803e9e` – Arithmetic or conversion routine.  
- `0x804ff6`, `0x80598e`, `0x805930` – Memory/address manipulation.  
- `0x805714`, `0x80575a`, `0x805656`, `0x8058f4` – Command‑specific helpers.  
- `0x803516` – SCSI command setup.  
- `0x80621a` – SCSI execution/status check.  
- `0x80397c` – Possibly a SCSI verify preparation.  
- `0x800ce0` – Memory clear or fill.  
- `0x803516` – SCSI parameter setup.  

**Notes**:  
- The jump table is sparse; many entries point to the same default handler (`0x8026cc`), which prints an error or does nothing.  
- Command `'%'` (0x25) is handled separately at `0x803016` and involves checking `0xc00836` and performing multi‑step validation.  
- The function preserves many registers (`d2‑d7/a2‑a5`) and uses a local stack frame of 76 bytes.  
- Several commands (`'S'`, `'V'`, `'X'`, `'Z'`) are known from the debug monitor documentation and match the described behavior (e.g., `'S'` prints "jumping to").  
- The shared‑memory control block (pointed to by `a5`) is used to build SCSI CDBs (Command Descriptor Blocks), with fields for opcode, LBA, length, and control flags.  
- Hardware register accesses are minimal within this dispatcher; most hardware interaction occurs in sub‑routines.

---

### Function at 0x803516

**Embedded strings:**
- `8402232`: `"N^Nu"`

**Name**: `debug_print_string_with_delay`

**Purpose**: This function prints a string to the debug console with a specified delay between characters. It takes a string pointer as input, and likely uses a fixed delay value (0x64 = 100 decimal) and a character output routine at a known address (0xc00854, which is likely a function pointer in shared RAM). The function appears to be part of the debug/monitor ROM's output utilities, used for controlled display of diagnostic messages.

**Parameters**: 
- `%fp@(8)` (first argument on stack): Pointer to the null-terminated string to be printed.
- `0xc00854`: A function pointer stored in shared RAM (likely points to a character output routine, possibly `putchar` or a serial port write function).

**Returns**: 
- No explicit return value. The function is a void subroutine.

**Key Operations**:
1. Sets up a stack frame with `linkw %fp,#-4`.
2. Clears a local variable or placeholder on the stack (`clrl %sp@`).
3. Pushes four arguments onto the stack for a subroutine call:
   - Delay value `0x64` (100 decimal, likely milliseconds or loop iterations).
   - Another constant `0x24` (36 decimal, possibly a line feed/newline character or control code).
   - The input string pointer.
   - The function pointer from `0xc00854`.
4. Calls subroutine at `0x8025b4` (likely a generalized "print string with delay" routine).
5. Cleans up stack and returns.

**Called Functions**:
- `0x8025b4`: A string printing routine that accepts delay parameters and a character output function pointer.

**Notes**:
- The constants `0x64` and `0x24` are hardcoded; `0x24` is the ASCII code for `$`, but in context, it might be a formatting or control parameter for the print routine.
- The function pointer at `0xc00854` is in shared RAM (`0xC00000-0xC00FFF` region), suggesting it can be modified by the system (e.g., to redirect output).
- The data after the `rts` (`0x80353c-0x803546`) appears to be unrelated data or part of another function, possibly a jump table or embedded constants.
- This function is likely used in debug modes where slow, deliberate output is needed (e.g., during system initialization or error reporting).

---

### Function at 0x8037e2

**Embedded strings:**
- `8403152`: `"N^NuNV"`

**Name**: `scsi_verify_blocks`  

**Purpose**: This function appears to iterate through a list of SCSI block transfer descriptors, verifying each block by reading it and checking for errors. It likely performs a diagnostic or integrity check on SCSI transfers, possibly as part of a self‑test or recovery routine. For each descriptor, it first attempts a quick verification (via `0x8024c0`), and if that fails, it performs a more thorough read operation (via `0x8025b4`). It counts both the total number of blocks processed and the number that encountered errors.

**Parameters**:  
- No explicit parameters passed in registers; the function reads a global pointer at `0x803544` to locate a table of block descriptors.  
- The table size is determined by a word at offset `0x28A` from that base address.

**Returns**:  
- `D0` contains the number of block descriptors that encountered errors during verification (`D3` is accumulated and returned).

**Key Operations**:  
- Reads a global pointer at `0x803544` to find a table of block descriptors.  
- Each descriptor is 20 bytes (based on offsets: +0, +4, +8, +10, +12, +16 used).  
- Calls `0x8024c0` (likely a quick verification routine) and compares the return value to 38 (0x26).  
- If the quick check fails, calls `0x8025b4` (likely a full SCSI read routine) and checks the return value:  
  - If the return is 224 (0xE0), it clears the descriptor’s +16 field.  
  - If the return is non‑zero but not 224, an error counter (`D6`) is incremented.  
- Prints diagnostic messages (via `0x800e3e`) when the descriptor’s +16 field changes or is -1, using the format string at `0x807bcc` (which contains “N^NuNV”).  
- Tracks total error count across all descriptors in `D3`.

**Called Functions**:  
- `0x8024c0` – Quick block verification routine.  
- `0x8055ce` – Called when the quick check returns 38; likely an error‑handling or reporting function.  
- `0x8025b4` – Full SCSI read/verify routine.  
- `0x800e3e` – Printf‑like output function (formatted string printer).

**Notes**:  
- The descriptor structure likely contains:  
  - +0: block address (high)  
  - +4: block address (low) or buffer pointer  
  - +8: word (possibly block count or transfer mode)  
  - +10: word (likely SCSI LUN or device ID)  
  - +12: long (SCSI command or control flags)  
  - +16: long (status/error field, cleared on success).  
- The constant 224 (0xE0) probably indicates a specific SCSI status (e.g., “NO SENSE” or “GOOD” completion).  
- The string “N^NuNV” at `0x807bcc` may be a format string for debug output (possibly showing block number and error count).  
- The function is part of the DMA processor’s self‑test/debug ROM and seems designed to validate SCSI transfers after boot or during diagnostics.

---

### Function at 0x8038d4

**Embedded strings:**
- `8403248`: `"N^NuNV"`

**Name**: `verify_rom_checksum`  

**Purpose**:  
This function computes a byte-wise checksum over a specific ROM region (from address `0x00D0001C` to `0x00D00080`) and compares the result to the expected value `0x5A` (decimal 90). If the checksum does not match, and a flag at `0xC00644` is non‑zero, it prints an error message with the computed checksum value. The function returns `1` on checksum failure and `0` on success.

**Parameters**:  
None explicitly passed; the function uses hard‑coded addresses:  
- Start address: `0x00D0001C` (loaded into `%a5`)  
- End address: `0x00D00080` (compared against `%a5`)  
- Flag address: `0xC00644` (tested to decide whether to print error)  
- String address: `0x807BE4` (format string for error message)

**Returns**:  
- `%d0`: `1` if checksum fails, `0` if checksum passes.

**Key Operations**:  
- Initializes a checksum accumulator (`%d7`) to zero.  
- Iterates over each byte in the range `0x00D0001C`–`0x00D00080`, adding each byte to the accumulator, keeping only the low‑byte (`& 0xFF`).  
- Compares the final checksum to `0x5A`.  
- If mismatch and `*0xC00644 != 0`, calls a print function (`0x807510`) with the format string at `0x807BE4` and the computed checksum as argument.  
- Returns success/failure status.

**Called Functions**:  
- `0x807510` — A print‑formatted‑string function (likely similar to `printf`), called only when checksum fails and the flag at `0xC00644` is set.

**Notes**:  
- The checksum region (`0x00D0001C`–`0x00D00080`) is 100 bytes long (since `0x80 - 0x1C = 0x64` = 100 decimal).  
- The expected checksum `0x5A` is the ASCII code for uppercase ‘Z’.  
- The flag at `0xC00644` likely controls whether checksum errors are reported (e.g., a verbose/debug mode).  
- The referenced string `"N^NuNV"` at `0x807BE4` is probably a format string containing `%d` or `%x` to print the bad checksum value.  
- This appears to be a ROM integrity test run during the DMA processor’s self‑test phase, verifying a specific block of code or data in the U17 ROM or another ROM area mapped at `0x00D00000`.

---

### Function at 0x803934

**Embedded strings:**
- `8403320`: `"N^NuNV"`

**Name**: `checksum_rom_block`  

**Purpose**: This function calculates an 8‑bit checksum (modulo 256) of a block of ROM data from address `0x00D0001C` to `0x00D0007E` inclusive, subtracts the result from the value 90 (0x5A), and stores the resulting 16‑bit value at the end of the block (address `0x00D0007E`). It appears to be computing a validation checksum for a fixed ROM region, likely for integrity verification during self‑test.

**Parameters**:  
- No explicit parameters passed in registers.  
- Implicitly operates on the ROM block at `0x00D0001C` to `0x00D0007E`.

**Returns**:  
- No register return value.  
- Stores the computed checksum word at `0x00D0007E` (just after the data block).

**Key Operations**:  
- Initializes `%d7` as an 8‑bit accumulator (kept modulo 256 via `AND.L #255`).  
- Uses `%a5` as a pointer that sweeps from `0x00D0001C` to `0x00D0007E`.  
- Each byte of the ROM block (taken as the low‑byte of each word) is added to the accumulator.  
- After the loop, the accumulator is subtracted from `0x5A` (90 decimal).  
- The result is stored as a word at `0x00D0007E` (the address `%a5` points to after the loop).  
- The function preserves registers `%d7` and `%a5` across the call.

**Called Functions**:  
- None (no `jsr` or `bsr` instructions).

**Notes**:  
- The block size is `(0x00D0007E − 0x00D0001C) = 98 bytes` (49 words).  
- The checksum is subtracted from `0x5A` rather than compared; this suggests the stored value is expected to be `0x5A` after the addition, so the computed word will be zero if the ROM data matches the expected checksum.  
- The target address `0x00D0007E` is within the U17 ROM itself (since U17 ROM spans `0x800000–0x807FFF` and `0x00D00000` is a logical address mapping to the same physical ROM). This is likely a checksum location written during ROM programming, verified at boot.  
- The function is position‑independent aside from the hard‑coded addresses; it could be part of a ROM checksum routine run during the DMA processor’s self‑test phase.

---

### Function at 0x80397c

**Embedded strings:**
- `8403398`: `"N^NuNV"`
- `8403438`: `"*@,9"`

**Name**: `confirm_or_abort`

**Purpose**:  
This function checks a global flag at `0xC00802`; if the flag is non-zero, it prompts the user with a message (likely a confirmation prompt), reads a single character from input, and checks if the character is 'Y', 'y', 'N', or 'n'. If the character is 'Y' or 'y', the function returns; if it is 'N' or 'n', the function also returns; but if it is any other character, it calls a subroutine at `0x800664` (likely an abort or error handler). The function essentially asks the user to confirm an action, and if an invalid response is given, it triggers an error/abort.

**Parameters**:  
None explicitly passed, but the function reads a global memory location `0xC00802` as a conditional flag.

**Returns**:  
No explicit return value; preserves register `%d7` across the call.

**Key Operations**:  
- Tests the longword at `0xC00802` (likely a "confirmation required" flag).  
- If flag is set, pushes the address `0x807BFF` onto the stack (likely a string pointer for a prompt) and calls `0x807510` (probably a print function).  
- Calls `0x8077B6` with a pointer to a local buffer (`%fp@(-26)`), likely a read-character or input routine.  
- Compares the returned character against ASCII 'Y' (0x59) and 'y' (0x79).  
- If neither matches, calls `0x800664` (likely an abort/error function).  

**Called Functions**:  
- `0x807510` – Likely a print or display function (takes a string pointer from stack).  
- `0x8077B6` – Likely a read-character or get-input function (returns a character in buffer).  
- `0x800664` – Likely an abort, error, or "invalid input" handler.

**Notes**:  
- The string at `0x807BFF` is not listed in the provided strings, but based on the context it probably says something like "Are you sure? (Y/N)".  
- The local buffer at `%fp@(-26)` is only used to store a single character; the rest of the 36-byte stack frame is likely for alignment or to preserve other registers.  
- The function only acts if `0xC00802` is non-zero, meaning the confirmation prompt is conditional on some external state (possibly a "safe mode" or "interactive mode" flag).  
- The comparison only checks for 'Y' and 'y'; 'N' and 'n' are treated the same as any other character except that they don't trigger the abort call. This suggests that 'N'/'n' simply skip the abort, while 'Y'/'y' proceed with whatever operation called this confirmation.  
- The address `0x800664` is not listed in the known U17 functions, but given its low address, it may be a generic exception or abort routine.

---

### Function at 0x8039ca

**Embedded strings:**
- `8403438`: `"*@,9"`
- `8403543`: `"R&M`\*"`
- `8403559`: `"RgL&"`
- `8403577`: `"Rg:."`
- `8403717`: `"RgL "`
- `8403733`: `"Rg<."`
- `8403812`: `"[2,9"`
- `8403822`: `"&M`4&"`
- `8403893`: `"&g\nN"`
- `8403969`: `"&&M`"`
- `8404028`: `"&M`NN"`
- `8404134`: `"N^NuABCDEFGHNV"`
- `8404160`: `"*H.."`

**Name**: `memory_test_pattern`  

**Purpose**:  
This function performs a comprehensive memory test over a specified address range, using multiple patterns and verification steps. It appears to be part of the DMA processor’s self‑test/debug ROM, responsible for validating RAM integrity. The test includes checking existing contents, writing and verifying inverted patterns, walking‑1 patterns, and pseudo‑random data, with periodic progress updates and error handling via a separate reporting subroutine.

**Parameters**:  
- `%fp@(8)` (`%a5`): Start address of memory region to test (aligned to even address).  
- `%fp@(12)` (`%a4`): End address (exclusive).  
- `%fp@(16)` (`%d7`): Bitmask used to isolate bits for comparison (if 0, defaults to 0xFFFFFFFF).  

**Returns**:  
- `%d0` (`%d4`): Cumulative error count (non‑zero if any mismatches were detected and reported).  

**Key Operations**:  
- Aligns start address to even boundary by clearing bit 0.  
- Reads `0xC006BA` (likely a test iteration counter or chunk size) into `%d6`.  
- Calls `0x800D50` and `0x800DA4` (likely progress/status display functions) before and after test phases.  
- Tests memory in four distinct phases:  
  1. **Read‑existing phase**: Reads each longword, compares with its own address and mask; calls error handler `0x803CB2` on mismatch.  
  2. **Inverted‑pattern phase**: Reads each longword, compares with bitwise inverse of address; calls error handler on mismatch.  
  3. **Walking‑1 phase**: Writes and verifies a shifting 1‑bit pattern (1, 2, 4, …).  
  4. **Pseudo‑random phase**: Generates values via `0x804036` (likely a PRNG), writes, and verifies them.  
- Uses `0xC00832` as a flag to enable “skip‑ahead” on error‑limit exhaustion; when set and `%d6` reaches zero, jumps ahead 512 KB (0x80000) to continue testing.  
- Clears test‑control flags (`0xC00832`, `0xC00826`, `0xC0082A`, `0xC008AA`, `0xC008AE`) after completion.  
- Calls `0x804FF6` (possibly a delay or sync function) between phases.  
- Calls `0x800F06` (likely a key‑poll or abort‑check routine) to allow user interruption.  

**Called Functions**:  
- `0x805656` – unknown (called with argument 7).  
- `0x805B32` – unknown (frequent, may be a short delay or status update).  
- `0x800D50`, `0x800DA4` – progress display functions.  
- `0x800F06` – check for user abort (returns non‑zero if abort requested).  
- `0x8005E0` – called if abort detected during early phase (with argument 0x78).  
- `0x803CB2` – error‑reporting subroutine (called with test phase ID, address, expected, actual, mask).  
- `0x804FF6` – phase separator (delay or sync).  
- `0x804036` – pseudo‑random number generator.  
- `0x8058F4` – cleanup or final‑status function.  

**Notes**:  
- The function preserves `%d3‑%d7/%a3‑%a5` across calls.  
- The mask in `%d7` allows testing of specific bit lanes (e.g., data bus lines) – if `%d7` is zero, it becomes 0xFFFFFFFF (all bits).  
- The skip‑ahead feature (when `0xC00832` is set) suggests the test can bypass large memory blocks after too many errors, possibly to continue testing other areas.  
- The strings referenced in the surrounding ROM (e.g., `"RgL&"`, `"&M`NN"`) are not directly used here but may be part of the error‑reporting subroutine `0x803CB2`.  
- The final `RTS` is preceded by four unused words (`0x4142`, `0x4344`, `0x4546`, `0x4748` – ASCII "ABCDEFGH") – likely padding or a placeholder.  
- This routine is part of the low‑level hardware diagnostics run at boot from the U17 ROM.

---

### Function at 0x803cb2

**Embedded strings:**
- `8404160`: `"*H.."`
- `8404570`: `"N^NuNV"`
- `8404634`: `"N^NuNV"`

**Name**: `debug_memory_pattern_test` or `memory_data_compare_display`

**Purpose**: This function appears to be a diagnostic routine that compares memory data against expected patterns, displaying mismatched bits in a formatted way. It's likely part of the self-test/debug monitor's memory testing capabilities, checking specific memory regions with bitwise comparisons and showing discrepancies through the debug console. The function handles error conditions and can set error codes.

**Parameters**:
- `%fp@(8)` (D7): Error code or test identifier (checked against 255)
- `%fp@(12)`: Memory address to test (checked against 0x800000 boundary)
- `%fp@(16)`: Expected data value
- `%fp@(20)`: Actual data read from memory
- `%fp@(24)`: Bitmask for comparison (checked against 0xFFFF)

**Returns**:
- `%d0`: Returns `%d7` (error code, default 6 if initial comparison fails)
- Sets `0xc00652` and `0xc007ea` to zero before returning

**Key Operations**:
- Calls `0x80144c` to perform initial comparison of masked actual vs expected data
- Checks `0xc00644` (likely a debug flag) and calls `0x805b72` if set
- Validates parameters: address < 0x800000 (ROM area?), error code ≤ 255, mask = 0xFFFF
- Reads bits 4 and 5 from hardware status register `0xc007ec` (system control readback)
- Computes an index from the address: `((address >> 19) << 1) + 1`
- Performs bitwise comparison: `(expected XOR actual) AND mask`
- Displays 16 bits of comparison results (bits 15-0) with formatting:
  - Each bit position (14 down to -1?) shown with index adjustment
  - References data table at `0x8404138` (8404138 = 0x803caa in ROM)
- Calls `0x803e5e` twice (subfunction) to process results
- Checks bits 5 and 4 of `0xc007ec` again to determine if mismatches should be reported
- Outputs formatted strings using `0x800e10` (likely printf-like debug output)
- Clears system variables `0xc00652` and `0xc007ea` before exit

**Called Functions**:
- `0x80144c`: Comparison function (returns zero if match?)
- `0x805b72`: Debug function (called if `0xc00644` is non-zero)
- `0x800e10`: Formatted output/print function (called multiple times with different format strings)
- `0x803e5e`: Subfunction for processing comparison results (called twice)

**Notes**:
- The function uses a 16-bit mask (0xFFFF) suggesting it's testing word-sized data
- The address transformation `((addr>>19)<<1)+1` suggests mapping to a table of 16-bit entries with odd indexing
- The data table at `0x8404138` (ROM address 0x803caa) likely contains expected values or bit patterns
- Hardware register `0xc007ec` bits 4 and 5 control whether mismatches are displayed:
  - Bit 5 checked first for one display condition
  - Bit 4 checked later for another display condition
- The function has early exits if parameters don't meet validation criteria
- String constants referenced:
  - `0x807c11`: Likely error message
  - `0x807c1d`: Status display format
  - `0x807c31`: Header for bit display
  - `0x807c33`: Format for individual bit display
  - `0x807c3a` and `0x807c41`: Mismatch reporting formats
- The function appears to be part of a larger interactive debugger, possibly invoked by a debug command

---

### Function at 0x803e5e

**Embedded strings:**
- `8404634`: `"N^NuNV"`
- `8404678`: `"g0Hx"`

**Name**: `compute_parity_bit`  

**Purpose**:  
This function calculates the odd parity bit of an 8‑bit byte passed by reference. It iterates over each bit of the byte, accumulates the number of set bits in a counter, shifts the byte right by one each iteration, and finally returns the least‑significant bit of the count (i.e., `count & 1`), which is the odd parity value (1 if the number of 1‑bits is odd, 0 if even). The original byte is destroyed in the process (shifted to zero).

**Parameters**:  
- `%fp@(8)`: A pointer to a byte in memory (the byte whose parity is to be computed).  

**Returns**:  
- `%d0`: The odd parity bit (0 or 1) as a longword (though only the LSB is meaningful).  

**Key Operations**:  
- Saves `%d6` and `%d7` on the stack.  
- Uses `%d7` as the accumulator for the number of set bits.  
- Uses `%d6` as a loop counter initialized to 8 (bits per byte).  
- Each loop iteration:  
  - Loads the byte pointed to by the parameter.  
  - Isolates its LSB (`byte & 1`) and adds it to `%d7`.  
  - Shifts the byte right by one bit in memory.  
- After the loop, computes `%d7 & 1` to produce the odd parity result.  
- Restores `%d6` and `%d7` before returning.  

**Called Functions**:  
None (no `jsr`, `bsr`, or jumps to subroutines within this code).  

**Notes**:  
- The function modifies the byte in memory (shifts it to zero) as a side effect; this is likely intentional to avoid needing a temporary variable, but means the caller must not rely on the original byte value after the call.  
- The parity computation is software‑based and generic; it does not access any Plexus‑specific hardware registers.  
- Given the location in the U17 ROM (self‑test/debug), this may be used for verifying data integrity (e.g., checking parity of stored values, serial communications, or SCSI data) during diagnostics.  
- The strings referenced nearby (`"N^NuNV"` at 0x8404634 and `"g0Hx"` at 0x8404678) are not used in this function and likely belong to other diagnostic routines.

---

### Function at 0x803e9e

**Embedded strings:**
- `8404678`: `"g0Hx"`
- `8404770`: `"N^NuNV"`
- `8404806`: `"[2*n"`

**Name**: `dual_processor_memory_test`  

**Purpose**: This function performs a two-phase memory test on a specified region, first using the DMA processor and then optionally the Job processor. It is likely part of the system self-test or diagnostic routines in the U17 ROM, validating memory accessibility and correctness from both processors in the dual‑CPU Plexus P/20 architecture.  

**Parameters**:  
- `%fp@(8)` (`%a5`): Base address of memory region to test (must be word‑aligned if DMA test runs).  
- `%fp@(12)` (`%a4`): Possibly a test pattern or control block pointer.  
- `%fp@(16)` (`%d7`): Length of region in bytes (if zero, defaults to 65535).  
- `%fp@(23)` (byte offset 23 from FP): Bitfield flags: bit 0 enables DMA‑processor test, bit 1 enables Job‑processor test.  

**Returns**:  
- `%d0` (`%d5`): Combined error code; zero on success, non‑zero if any test phase failed (last error preserved).  

**Key Operations**:  
- If `%d7` (length) is zero, it is set to 65535 (max test size).  
- If bit 0 of flags is set:  
  - Calls `0x805656` with argument 7 (likely serial output or LED indication).  
  - Clears two shared‑memory locations (`0xc00652` and `0xc007ea`).  
  - Forces `%a5` to be word‑aligned (clears LSB).  
  - Calls `0x800b9a` (DMA‑processor memory test) with aligned base, pattern/block pointer, and length.  
- If bit 1 of flags is set:  
  - Calls `0x803f26` (Job‑processor memory test) with same parameters.  
  - If this test returns non‑zero, its error overwrites the previous result.  
- Finally calls `0x8058f4` (likely cleanup or status‑report routine).  

**Called Functions**:  
- `0x805656` – Possibly a diagnostic output or hardware‑state function (argument 7).  
- `0x800b9a` – DMA‑processor memory‑test routine.  
- `0x803f26` – Job‑processor memory‑test routine.  
- `0x8058f4` – Post‑test cleanup/status function.  

**Notes**:  
- The function respects the dual‑processor nature of the Plexus P/20: it can test memory from both the DMA processor (handles I/O/boot) and the Job processor (runs Unix).  
- The alignment step (`%a5 & ~1`) before the DMA test suggests the DMA processor requires word‑aligned accesses.  
- Shared‑memory locations `0xc00652` and `0xc007ea` are cleared only before the DMA test; these likely hold test‑state variables used by the DMA processor.  
- The flag byte at `%fp@(23)` allows selective testing of either or both processors, useful for isolating bus‑master or arbitration issues.  
- The function appears in the U17 self‑test/debug ROM, consistent with a low‑level hardware validation role during boot or manual diagnostics.

---

### Function at 0x803f26

**Embedded strings:**
- `8404806`: `"[2*n"`
- `8404896`: `"/\rHx"`
- `8404936`: `"N^NuNV"`
- `8404969`: `"RgDp"`

**Name**: `memory_pattern_test` or `ram_test_with_checksum`

**Purpose**: This function performs a memory test over a specified address range by writing a sequential byte pattern, then reading back and verifying each byte using a rolling checksum (or hash) algorithm. If a mismatch is detected, it calls an error-reporting subroutine. The test can be limited by a maximum error count (or iteration limit) stored in `0xc006ba`. It returns the number of errors encountered during the test.

**Parameters**:
- `%fp@(8)`: Start address of memory region to test (`%a5`)
- `%fp@(12)`: End address of memory region (exclusive, compared with `%a5`)
- `%fp@(11)`: Initial byte pattern value (unsigned char)
- `%fp@(16)`: Initial checksum/seed value (`%d7`). If zero, it is set to `0xFFFFFFFF`.

**Returns**:
- `%d0`: Number of errors detected during the test (`%d6` is the error accumulator).

**Key Operations**:
- Saves registers `%d3-%d7/%a5` on the stack.
- Initializes `%d7` to `0xFFFFFFFF` if the input seed is zero.
- Loads a maximum error/iteration limit from `0xc006ba` into `%d4`.
- Calls `0x805b32` twice (likely a delay or hardware synchronization function).
- Writes a sequential byte pattern from the start address to the end address, starting with the initial pattern byte and incrementing by 1 for each byte.
- Resets an error counter at `0xc00652` to zero.
- For each byte in the range:
  - Calls `0x800cd8` with the current checksum seed (`%d7`) to compute a new checksum value.
  - Reads the byte back, XORs it with the expected pattern byte, and masks the result with the current checksum.
  - If the result is non-zero OR the global error counter at `0xc00652` is non-zero, it calls error handler `0x803cb2` with parameters: error code 5, current address, read byte, expected byte, and current checksum.
  - Increments the error count (`%d6`) and decrements the remaining allowed errors (`%d4`). If `%d4` reaches zero, the test stops early.
- Returns the total error count in `%d0`.

**Called Functions**:
- `0x805b32`: Called twice; likely a short delay or hardware state synchronization function.
- `0x800cd8`: Computes a new checksum/hash value from the previous seed; possibly a CRC or LFSR step.
- `0x803cb2`: Error reporting function; takes error code, address, read data, expected data, and checksum; likely prints diagnostic information.

**Notes**:
- The test uses a rolling checksum that updates for each byte tested (`%d7`), making the verification pattern dependent on both the data and the position.
- The global error flag at `0xc00652` can force error reporting even if the byte comparison passes, suggesting it might be set by other routines (e.g., parity error detection).
- The limit from `0xc006ba` may be a configurable maximum error count before aborting the test.
- The function appears to be part of the system's memory diagnostic routines, possibly called during self-test or from the debug monitor.
- The error handler call at `0x803cb2` with error code 5 suggests a structured error reporting system, where code 5 likely means "memory verify error".
- The use of `%fp@(11)` as an initial pattern allows flexible pattern testing (e.g., walking ones, zeros, or alternating values).

---

### Function at 0x803fcc

**Embedded strings:**
- `8404969`: `"RgDp"`
- `8405042`: `"N^NuNV"`

**Name**: `verify_or_update_checksum`

**Purpose**: This function appears to be a checksum verification and update routine, likely used during self‑test or diagnostic operations. It compares two masked values (probably a stored checksum and a computed one), and if they differ or if a global flag is set, it calls a helper function (at 0x803cb2) to recompute or validate the checksum. Depending on the result, it may update a memory location with a status code, decrement a retry counter, and return a success/failure flag.

**Parameters**:  
The function takes six 32‑bit parameters on the stack (accessed via `%fp` offsets):  
- `%fp@(8)` – Unknown (possibly a base address or identifier)  
- `%fp@(12)` – First checksum‑like value  
- `%fp@(16)` – Second checksum‑like value  
- `%fp@(20)` – Offset or base value  
- `%fp@(24)` – Pointer to a result/status word  
- `%fp@(28)` – Bitmask applied to both checksums  
- `%fp@(32)` – Pointer to a retry counter  

**Returns**:  
- `%d0` = 1 if the retry counter reaches zero; otherwise `%d0` = 0.  
- The word at `%fp@(24)` is updated with either `(offset + 1)` or the value 6 (if the helper returns 6).  
- The retry counter at `%fp@(32)` is decremented.

**Key Operations**:  
- Masks both input checksums with the same bitmask (`%fp@(28)`).  
- XORs the masked values; if they differ **or** if the longword at `0xc00652` is non‑zero, the function proceeds to call the helper.  
- Calls subroutine `0x803cb2` with five arguments: `0xff`, `%fp@(8)`, `%fp@(12)`, `%fp@(16)`, and the mask.  
- Compares the helper’s return value with 6; if equal, writes 6 into the result pointer.  
- Decrements the retry‑counter pointer; returns 1 if it becomes zero.

**Called Functions**:  
- `0x803cb2` – An unknown helper that likely performs a checksum calculation or validation. Its return value is interpreted (6 is a special status).

**Notes**:  
- The global flag at `0xc00652` forces the checksum update path even when the masked XOR result matches. This suggests a diagnostic mode or a manual “re‑verify” flag.  
- The constant `0xff` passed to the helper may be a command code (e.g., “verify” or “compute”).  
- The result pointer receives either `offset+1` (normal case) or the magic value 6 (error or special status).  
- The retry‑counter pointer is decremented each call; when it hits zero, the function returns 1, possibly signaling “no more retries allowed.”  
- The strings `"RgDp"` and `"N^NuNV"` are not referenced directly in this code; they may be used by the helper at `0x803cb2` or by other diagnostic functions.

---

### Function at 0x804036

**Embedded strings:**
- `8405140`: `"N^NuNV"`
- `8405220`: `"[2*|"`
- `8405247`: `"GJGf"`
- `8405256`: `"[2*9"`
- `8405346`: `"[2*|"`
- `8405356`: `"l(,\r"`
- `8405496`: `"[2&|"`
- `8405556`: `"[2Hx"`
- `8405674`: `"[2By"`
- `8405686`: `"[2Hx"`
- `8405760`: `"[2Hx"`
- `8405930`: `"[2Hx"`
- `8406012`: `"N^Nu"`
- `8406176`: `"[2(|"`
- `8406232`: `"[2(|"`
- `8406386`: `"(K`4|"`
- `8406454`: `"[2Hx"`
- `8406500`: `"[2Hx"`
- `8406592`: `"/\n/<"`
- `8406792`: `"[2Hx"`
- `8406894`: `"~\rHx"`
- `8406962`: `"[2Hx"`
- `8407396`: `"g& <"`
- `8407434`: `"gT +"`
- `8407878`: `"N^NuNV"`

**Name**: `selftest_memory_and_scsi`  

**Purpose**: This function performs a comprehensive system self‑test, focusing on memory (RAM) and SCSI controller verification. It appears to be the main diagnostic routine run by the DMA processor after reset. The test writes/reads patterns to various memory regions, validates SCSI controller registers, checks for bus errors, and logs any failures. If all tests pass, it likely prepares the system for boot; otherwise it returns an error code.

**Parameters**:  
- No explicit parameters passed in registers.  
- Uses system‑configuration values from fixed memory locations (e.g., `0xC008AE`, `0xC008AA`, `0xC006BA`).  
- Reads hardware status registers (e.g., `0xE00016` for system control).  

**Returns**:  
- `D0` contains a result code:  
  - On success (`D7 == 0`): returns the longword from `0xC008B2`.  
  - On failure: returns the error code stored in `D7` (values 1–27 indicate specific test failures).  

**Key Operations**:  
- Toggles bits in a persistent memory location (`0xC008AE` or `0xC008AA`) based on a call to `0x800F06` (likely a “which processor am I?” check).  
- Writes a walking‑bit pattern (`0x0001`, `0x0002`, …) to memory at `0xB81000`–`0xB81100` (SCSI controller register space?).  
- Reads back SCSI controller registers at `0x781000`–`0x782000` and compares them against expected values.  
- Writes alternating byte patterns (`0x00`, `0x01`, `0x02`, …) to `0xB81000`–`0xB81100` and verifies them.  
- Performs a multi‑stage memory test on a block defined by `0xC006BA` (test iteration count) and `0x781000`–`0x782000` (test base address).  
- Tests memory‑mapped I/O registers at `0xA70002` (possibly SCSI data port) and compares with shadow copy at `0xC00868`.  
- Clears bus‑error flags (`0xE00140`, `0xE001A0`).  
- Calls a delay/utility function at `0x805B32` frequently between test phases.  
- On failure, calls error‑logging subroutine `0x80144C` with details.  
- Sets/clears bits in the system control register (`0xE00016`) to enable/disable memory mapping and interrupts.  

**Called Functions**:  
- `0x800F06` – determines current processor (DMA vs. Job).  
- `0x805B9E` – unknown (called with arguments 1, 0x7F, 0x781).  
- `0x805B32` – delay or synchronization function.  
- `0x80144C` – error‑reporting function (takes address, expected value, actual value).  
- `0x800D7A` – unknown (called with `0xB81000` and `0x0007F000`).  
- `0x804B4A` – unknown (called with size and count arguments).  
- `0x801590` – unknown (memory/IO operation).  
- `0x8058F4` – final cleanup or status function.  

**Notes**:  
- The function is long (815 instructions) and clearly structured as a multi‑stage hardware test.  
- Error codes in `D7` are set per failing stage (e.g., `D7 = 1` for first SCSI register test, `D7 = 22`/`23` for memory‑pattern mismatches).  
- Uses `0xC006BA` as a loop counter for repeated test iterations, suggesting configurable test depth.  
- Accesses both ROM shadow addresses (`0x00800000`) and physical hardware registers (`0xE00016`, `0xA70002`).  
- The final steps reset error flags and conditionally restore interrupt enables based on original `D3` value.  
- Likely called early in the U17 ROM boot sequence to validate essential hardware before attempting to load the bootloader from U15.

---

### Function at 0x804b4a

**Embedded strings:**
- `8407968`: `"f&Hx"`
- `8408072`: `"N^NuNV"`
- `8408255`: `" Hx	"`
- `8408378`: `"[2Hx"`
- `8408451`: `"FJFf"`
- `8408466`: `"[2Hx"`
- `8408538`: `"[2Hx"`
- `8408598`: `"[2By"`
- `8408614`: `"~	Hx"`
- `8408644`: `"[2Hx"`
- `8408666`: `"~\nHx"`
- `8408718`: `"[2Hx"`
- `8408772`: `"N^NuNV"`
- `8408800`: `"&@ n"`
- `8408851`: `"GJGf"`
- `8409016`: `"N^NuNV"`
- `8409074`: `"N^NuNV"`

**Name**: `dma_processor_self_test`  

**Purpose**:  
This function performs a comprehensive self-test of the DMA processor and its interaction with shared memory, hardware registers, and the Job processor. It initializes hardware, writes test patterns to memory, verifies communication between processors via IPC (Inter-Processor Communication), checks interrupt and status registers, and validates SCSI controller readiness. The test is structured as a sequence of subtests, with error codes stored in `%d7` to indicate which subtest failed.

**Parameters**:  
- Input: None (called without arguments).  
- Implicit: Relies on hardware registers at `0xE00016` (system control), `0xE00018` (processor status), and shared memory areas (e.g., `0x800`, `0x900`).  

**Returns**:  
- `%d0`: Error code (`0` = success, non-zero = failure). The error code corresponds to the failing subtest (values 1–12 stored in `%d7`).  
- Side effects: Updates shared memory locations (e.g., `0xC008B2` with error codes 44/45), modifies hardware control registers, and may reset interrupt flags.

**Key Operations**:  
- Writes to system control register `0xE00016` to configure boot and diagnostic bits.  
- Calls `0x80144c` (likely a memory verification routine) to test shared memory regions.  
- Uses `0x800600` (delay or synchronization function) between operations.  
- Tests Job processor responsiveness via IPC: writes a magic value (`0xA591`) to shared memory and checks for a response.  
- Verifies SCSI controller status by reading `0xE00018` and checking bit 3 (SCSI busy).  
- Writes sequential test patterns to memory at `0x900` (word increments).  
- Calls `0x804fbc` (timeout or wait function) to pause between operations.  
- Sets/resets Job processor software interrupt via `0xE00080` and `0xE00060`.  
- Invokes `0x80152c` (error logging) on failures.  
- Final cleanup: restores original system control register bits, resets interrupts.

**Called Functions**:  
- `0x800f06`: Unknown (possibly hardware initialization check).  
- `0x800e10`: Prints error string (e.g., "N^NuNV").  
- `0x800dd6`: Memory copy or fill routine.  
- `0x800d22`: Memory test or checksum function.  
- `0x805b32`: Delay or synchronization function.  
- `0x805b18`: Shared memory initialization.  
- `0x80144c`: Memory verification (compares values).  
- `0x804fbc`: Timeout wait (parameter = delay count).  
- `0x80152c`: Error handler (logs subtest failures).  
- `0x805656`: SCSI or IPC command function.  
- `0x801494`: SCSI status check.  
- `0x8005e0`: Serial output or debug function.  
- `0x8058f4`: Cleanup or reset function.  
- `0x800e8c`: Finalization routine.

**Notes**:  
- The function is part of the U17 ROM self-test suite, executed by the DMA processor at boot.  
- Error codes stored in `%d7` increment sequentially (1–12) as subtests progress; each failure triggers an error log call.  
- Shared memory addresses `0x800` and `0x900` are used as IPC message areas: `0x800` holds commands/responses, `0x900` holds test patterns.  
- The code toggles the `DIS.MAP` bit (bit 13 of `0xE00016`) based on input bit 0 of a parameter (likely from a higher-level test harness).  
- The final section (starting at `0x804ec8`) appears to be a secondary test routine that writes a fixed pattern (`0xA591`) to memory, sums memory contents, and performs SCSI operations.  
- Hardware register accesses are careful to preserve unrelated bits (using `ANDIW`/`ORIW` on specific bits).

---

### Function at 0x804fbc

**Embedded strings:**
- `8409074`: `"N^NuNV"`

**Name**: `wait_for_dma_flag_or_timeout`

**Purpose**: This function waits for a DMA processor flag (likely a hardware operation completion indicator) to clear, while counting down a timeout value. It returns success (1) if the flag cleared before the timeout expired, or failure (0) if the timeout expired while the flag was still set. This is a classic hardware synchronization pattern for polling a status register.

**Parameters**:  
- `%fp@(8)` (the first longword parameter on the stack): A timeout counter. The function decrements this each loop iteration; if it reaches zero, the function returns failure.

**Returns**:  
- `%d0`: Returns 1 if the flag cleared before timeout, 0 if timeout expired.

**Key Operations**:
- Sets up a local pointer (`%a5`) to the hardware register base at `0x800` (this is `0xE00000` in the physical memory map, the System Status/Control region).
- Writes the value `1` to the register at offset `4` from that base (`0xE00004`). This is the "Reset Job processor address bits on bus error" register (a write-only clear operation).
- Enters a loop that:
  1. Decrements the timeout parameter.
  2. If timeout reaches zero, exits loop and returns failure.
  3. Calls subroutine at `0x800600` (likely a short delay or a hardware access function).
  4. Tests the read-back value at `%a5@(4)` (which is `0xE00004`, but now reading the "Job processor address bits on bus error" status). If non-zero, loops again.
- After loop exit, checks if timeout expired (`%fp@(8) == 0`) to determine return value.

**Called Functions**:
- `0x800600`: An unknown subroutine, likely a short delay or a hardware access helper (perhaps reading another status or causing a bus synchronization).

**Notes**:
- The function writes to `0xE00004` to clear any pending bus error address bits at the start, then reads from the same address to poll for a change. This matches the hardware description: `0xE00004` is a read-only register showing the Job processor address on bus error, but writing to it resets that latch. The loop appears to wait for a bus error condition to be signaled (non-zero address captured) or for the timeout.
- The timeout parameter is used as a simple decrementing counter; the actual time per iteration depends on the delay introduced by the `jsr 0x800600` call.
- This is likely part of a bus error recovery, DMA completion polling, or inter-processor synchronization routine in the self-test/debug monitor. The strings referenced nearby ("N^NuNV") are not used in this function and may belong to adjacent code.

---

### Function at 0x804ff6

**Embedded strings:**
- `8409150`: `"fl 9"`
- `8409258`: `"`:Jm"`
- `8409263`: `" g,;|"`
- `8409324`: `"N^NuNV"`

**Name**: `dma_processor_scsi_poll`  

**Purpose**:  
This function appears to be the DMA processor's main loop for handling SCSI operations, likely polling for SCSI command completion and managing related system state. It checks whether the DMA processor is the active processor (via `0x800f06`), monitors SCSI controller status, processes SCSI command results, and handles transitions between DMA and Job processor execution. The function loops while a flag at `0xC007F6` is set, indicating ongoing SCSI activity, and may reset processor control flags or trigger processor swaps when operations complete.

**Parameters**:  
- No explicit parameters passed via registers.  
- Relies on global memory locations:  
  - `0xC00648` – likely stores current processor ID or active processor flag.  
  - `0xC006D6` – pointer to SCSI controller status/command block.  
  - `0xC007FE` – flag indicating if SCSI operation is pending.  
  - `0xC007F6` – flag indicating SCSI operation in progress (set to 1 when active).  
- Hardware registers at `0xE00016` (system control) and `0xE00018` (processor control) are implicitly accessed via called subroutines.

**Returns**:  
- No explicit return value.  
- Modifies global flags: clears `0xC007F6` when SCSI operation finishes.  
- May alter processor execution state (e.g., triggers Job processor via control registers).

**Key Operations**:  
- Calls `0x800f06` to determine active processor (returns 0 for Job processor, non-zero for DMA processor).  
- Sets `%a4` or `%a5` based on active processor (addresses `0xC0039E` or `0xC003CC` – likely processor-specific data structures).  
- Checks a word at offset `40` in the processor data structure; if non-zero, calls `0x8051cc` (possibly a debug or status output routine).  
- Compares result from `0x800f06` with `0xC00648`; if they match (DMA processor active), proceeds to SCSI polling logic.  
- Examines SCSI controller status via pointer at `0xC006D6`, testing bit 0 of offset `14` (likely a "command complete" or "busy" flag).  
- If SCSI operation is ready (`0xC007FE` is zero), calls `0x807716` (SCSI result fetch) and `0x807882` (SCSI command processing).  
- Sets `0xC007F6 = 1` during SCSI processing, loops while result byte is zero, then clears `0xC007F6`.  
- If DMA processor is not active, checks a word at offset `32` in the DMA processor data structure (`%a5@(32)`); if set, triggers a processor swap: writes `1` to offset `34`, clears offset `32`, calls `0x8005e0` (likely a context switch), and then calls `0x800e04` and `0x800df8` (processor control routines).  
- Waits at the end if `0xC007F6` is still set (busy-wait).

**Called Functions**:  
- `0x800f06` – determine active processor.  
- `0x8051cc` – unknown (possibly status output or debug).  
- `0x807716` – fetch SCSI operation result.  
- `0x807882` – process SCSI command.  
- `0x8005e0` – likely triggers processor swap/context switch.  
- `0x800e04` and `0x800df8` – processor control routines (set/reset processor states).  

**Notes**:  
- The function uses two processor-specific data structures at `0xC0039E` (Job processor?) and `0xC003CC` (DMA processor?), selected based on the return value of `0x800f06`.  
- The SCSI controller status is accessed indirectly via a pointer stored at `0xC006D6`. This matches the known Omti 5200 controller mapping.  
- The loop at `0x805086–0x8050a2` processes SCSI commands while checking the debug/output flag at `%a4@(40)` each iteration.  
- The code at `0x8050ac–0x8050de` handles the case where the DMA processor is not active, resetting control flags and potentially swapping to the DMA processor.  
- The wait loop at `0x8050de–0x8050e4` spins on `0xC007F6`, suggesting this flag is cleared by an interrupt or external event when SCSI operations finish.  
- This function is likely part of the DMA processor's idle loop or main service routine in the U17 ROM, managing SCSI I/O and processor coordination.

---

### Function at 0x8050f0

**Name**: `dma_processor_main_loop`  

**Purpose**:  
This function appears to be the main supervisory loop for the DMA processor after initial self‑test. It initializes pointers to shared data structures, prints status messages, sets boot flags based on a system check, monitors hardware flags for pending tasks (SCSI, serial, IPC), and dispatches to service routines when needed. The loop runs indefinitely, polling hardware status and invoking service handlers.

**Parameters**:  
- None explicitly passed; uses hard‑coded memory addresses:  
  - `0xC00370` → `%a5` (likely a shared DMA‑processor control block)  
  - `0xC0039E` or `0xC003CC` → `%a4` (likely a Job‑processor control block, selected based on `0x800f06` result)

**Returns**:  
Does not return; contains an infinite polling loop (branches back to `0x80515a`).

**Key Operations**:  
- Calls `0x800f06` (likely a system‑type check) and selects `%a4` based on result.  
- Prints three strings via `0x805b18` (probably a console‑output routine):  
  1. Address in `%a5` (`0xC00370`)  
  2. Fixed string at `0xC0039E`  
  3. Fixed string at `0xC003CC`  
- Calls `0x800f06` again and sets boot flags:  
  - If result non‑zero: writes `2` to `0xC006C2`  
  - If zero: writes `2` to `0xC006BE`  
- Sets `%a5@(44)` to `1` (likely a “ready” flag).  
- Polls hardware flags in the control blocks:  
  - If `%a5@(10)` ≠ 0, calls `0x8052ba` (SCSI service?).  
  - If `%a4@(40)` ≠ 0, calls `0x8051cc` (serial/service for Job processor?).  
  - If `%a5@(32)` ≠ 0, sets `%a5@(34)` = 1, clears `%a5@(32)`, calls `0x8005e0` with argument `4` (IPC or interrupt‑related), then clears `%a5@(34)`.  
- Calls `0x800600` (likely a short delay or housekeeping).  
- Loops forever.

**Called Functions**:  
- `0x800f06` – system check / processor‑type detection.  
- `0x805b18` – print string (or formatted output).  
- `0x8052ba` – SCSI or I/O service routine.  
- `0x8051cc` – Job‑processor communication/service routine.  
- `0x8005e0` – IPC or interrupt‑acknowledge function (takes one word argument).  
- `0x800600` – delay or periodic housekeeping.

**Notes**:  
- The data at `0xC00370`, `0xC0039E`, `0xC003CC` likely holds control/status blocks for DMA and Job processors. Offsets like +10, +28, +32, +34, +40, +44 are hardware‑event flags or request semaphores.  
- The infinite loop at the end (`0x80515a` → `0x805198` → `0x80515a`) is typical for a monitor/debug ROM’s main loop.  
- The code after `0x80519a` appears to be embedded data (possibly exception‑handler addresses or message strings) rather than executable instructions.  
- Writing `2` to `0xC006BE` or `0xC006C2` may set boot‑source flags (e.g., boot from disk vs. network).  
- The function coordinates between DMA processor tasks (SCSI, IPC) and Job processor requests, acting as a simple real‑time scheduler.

---

### Function at 0x8051cc

**Embedded strings:**
- `8409688`: `" @ PN"`
- `8409782`: `"N^NuNV"`
- `8409840`: `" @ PN"`

**Name**: `execute_scsi_command_or_diagnostic`

**Purpose**: This function appears to be part of the SCSI command execution or diagnostic system in the Plexus P/20's DMA processor self-test ROM. It checks a system status flag, then conditionally executes either a direct SCSI command via a function table lookup (for known command codes ≤12) or a diagnostic/fallback routine via a generic handler. It manages SCSI command buffer pointers in shared RAM and tracks execution results.

**Parameters**: 
- Implicitly uses global memory locations:
  - `0xC007FA`: Status flag compared against value `0x3812` (14354 decimal)
  - `0xC006BE` and `0xC006C2`: SCSI command buffer pointers (likely current/next or primary/alternate)
  - `%a5` is set based on the result of `0x800F06` (likely a "which SCSI buffer" test), pointing to either `0xC0039E` or `0xC003CC` (structures in shared RAM)

**Returns**:
- No explicit register return value (void function).
- Stores result in `0xC00860` (global result/status location).
- Updates `%a5@(36)` (offset 36 in the selected buffer structure) with the result.
- Sets `%a5@(44)` (word at offset 44) to 1 upon completion.
- Swaps/restores SCSI buffer pointers in shared RAM (`0xC006BE`, `0xC006C2`, `0xC00812`, `0xC00816`).

**Key Operations**:
- Compares `0xC007FA` to `0x3812`; if not equal, function returns early (guard check).
- Calls test function `0x800F06` twice to determine which SCSI buffer structure to use (`0xC0039E` or `0xC003CC`).
- Reads a word from `%a5@(10)` (offset 10 in the structure), sign-extends to long in `%d7` (likely a SCSI command code or operation selector).
- Conditionally swaps SCSI buffer pointers between `0xC006BE/C006C2` and `0xC00812/C00816` based on the test result.
- If `%d7` (command code) ≤ 12, looks up a function from a table at base `0x80519C` (8409500 decimal) indexed by `%d7`, and calls it with arguments from `%a5@` and `%a5@(12)`.
- If `%d7` > 12, calls a generic handler at `0x8025B4` with arguments: `%a5@`, `%a5@(4)`, `0x24` (36 decimal), `%d7`, and `%a5@(12)`.
- Stores the returned result (from either path) into `0xC00860` and `%a5@(36)`.
- Restores the original SCSI buffer pointers after execution.
- Sets a completion flag at `%a5@(44)` to 1.

**Called Functions**:
- `0x800F06` (called three times): Likely `get_scsi_active_buffer()` or similar; returns nonzero/zero to select buffer structure.
- `%a0@` from table lookup (when `%d7` ≤ 12): Indirect call to a SCSI command handler from a table at `0x80519C + (%d7 * 4)`.
- `0x8025B4`: Generic handler for unknown/unsupported command codes (diagnostic or fallback).

**Notes**:
- The function uses two buffer structures in shared RAM at `0xC0039E` and `0xC003CC`, each likely containing SCSI command parameters, result fields, and status flags.
- The table at `0x80519C` contains 13 entries (0–12), each a pointer to a specific SCSI command handler (e.g., TEST UNIT READY, REQUEST SENSE, READ, WRITE, etc.).
- The value `0x3812` at `0xC007FA` may be a system self-test completion flag or a magic number indicating the system is ready for SCSI operations.
- The swapping of buffer pointers (`0xC006BE/C006C2` with `0xC00812/C00816`) suggests a double-buffering or ping-pong buffer scheme for SCSI command processing.
- Offset 44 in the buffer structure (`%a5@(44)`) is set to 1 at the end, likely a "command processed" flag for the Job processor.
- This function is likely called by the DMA processor's self-test or boot code to perform low-level SCSI operations or diagnostics before handing off to the boot loader.

---

### Function at 0x8052ba

**Embedded strings:**
- `8409840`: `" @ PN"`
- `8409960`: `"N^NuNV"`

**Name**: `scsi_command_dispatch`  

**Purpose**:  
This function appears to be the main SCSI command dispatcher for the DMA processor. It reads a SCSI command opcode from a shared memory structure, looks up the appropriate handler routine in a jump table, executes it, and then processes the result. It loops until a “command in progress” flag is cleared, indicating command completion. The function also tracks command retries and errors, and signals completion via status fields.

**Parameters**:  
- `%a5` is set to `0x00C00370`, which points to a shared memory data structure (likely SCSI control block or command queue in the shared RAM area at `0xC00000`).  
- The structure at `%a5` contains:  
  - Offset `0x0A`: a word holding the SCSI command opcode (read into `%d6`).  
  - Offset `0x00` and `0x04`: parameters passed to the command handler.  
  - Offset `0x0C`: another parameter.  
  - Offsets `0x10`, `0x14`, `0x18`, `0x1C`, `0x1E`, `0x2C`: status/control fields for retry counts, error codes, and completion flags.

**Returns**:  
- `%d7` holds the command handler’s return value (often a status/error code).  
- The status word at `%a5@(0x1E)` is updated with the low word of `%d7`.  
- Completion flags are set at `%a5@(0x1C)` and `%a5@(0x2C)` (both set to `1`).  
- The function loops until `%a5@(0x10)` becomes zero (command-in-progress flag cleared).

**Key Operations**:  
- Reads SCSI command opcode from `%a5@(0x0A)` and clears it after reading.  
- Clears `%a5@(0x14)` (retry or sequence counter).  
- If the opcode is ≤ 12, it uses a jump table at `0x0080519C + (opcode * 4)` to call the appropriate SCSI command handler, passing parameters from `%a5@(0x00)` and `%a5@(0x0C)`.  
- If the opcode is > 12, it calls a generic error/unknown handler at `0x8025B4` with parameters: `%a5@(0x00)`, `%a5@(0x04)`, `0x24`, `%d6`, `%a5@(0x0C)`.  
- Stores handler return status in `%a5@(0x1E)`.  
- If status equals `0xE0` (224), clears `%a5@(0x10)` (command-in-progress).  
- Increments `%a5@(0x18)` on non‑zero status (error counter).  
- Compares `%a5@(0x10)` and `%a5@(0x14)`; if equal, clears `%a5@(0x10)` (prevents infinite retry).  
- Increments `%a5@(0x14)` (attempt counter).  
- Calls subroutine at `0x804FF6` (likely updates SCSI controller state or checks for interrupts).  
- Loops back if `%a5@(0x10)` is non‑zero.  
- Sets completion flags `%a5@(0x1C)` and `%a5@(0x2C)` to `1` before returning.

**Called Functions**:  
- `0x8025B4` – unknown/error handler (called for opcodes > 12).  
- `0x804FF6` – SCSI controller update or interrupt check routine.  
- Jump table routines at `0x0080519C + (opcode * 4)` – specific SCSI command handlers (e.g., Test Unit Ready, Read, Write, Inquiry, etc.).

**Notes**:  
- The jump table base `0x0080519C` is in ROM (U17), suggesting the SCSI command handlers are built‑in.  
- Opcode `0xE0` (224) appears to be a “command completed successfully” status, as it clears the in‑progress flag.  
- The structure at `0xC00370` is a SCSI command control block in shared RAM, allowing coordination between DMA and Job processors.  
- The loop with `%a5@(0x10)` acts as a busy‑wait for command completion, implying the SCSI controller operates asynchronously.  
- The function likely implements retry logic: `%a5@(0x18)` counts errors, `%a5@(0x14)` counts attempts, and the comparison at `0x805340` prevents infinite retry if progress stalls.  
- The strings referenced (`" @ PN"` and `"N^NuNV"`) are not directly used here but may be in the called subroutines (possibly part of debug output).

---

### Function at 0x80536c

**Embedded strings:**
- `8410358`: `"N^NuNV"`

**Name**: `boot_processor_switch_or_reset`

**Purpose**: This function manages the transition between the DMA processor's self-test/debug monitor and the main boot loader, handling hardware initialization, control register configuration, and shared memory setup based on an input parameter that determines the boot mode (likely normal boot vs. diagnostic/alternate boot). It appears to coordinate the handoff between the two processors and set up the system for either continued diagnostics or launching Unix.

**Parameters**: 
- `%fp@(8)` (stack parameter at offset 8) – an integer boot mode selector: 
  - `1` = diagnostic/alternate boot path (sets up shared memory areas, calls `0x802330` twice)
  - `2` = another mode (calls delay `0x8005e0` with 0x14 argument)
  - `0` = normal boot path (default)

**Returns**: 
- No explicit register return value; function modifies hardware control registers and shared memory areas.
- Side effects: writes to `0xC004B4`, `0xC004B6`, `0xC006BE`, `0xC006C2`, `0xC00648`, and pushes addresses to a memory pointer at `%a5` (initialized to `0x0` but later used as a store pointer).

**Key Operations**:
- Saves registers and sets up pointer to hardware registers:
  - `%a4` = `0xE00018` (Processor control: KILL.JOB, KILL.DMA, JKPD)
  - `%a3` = `0xE00016` (System control: Boot.DMA, Boot.JOB, DIS.MAP, DIAG bits)
  - `%a2` = `0xC00370` (shared RAM variable area)
- Checks boot mode `1` and conditionally calls `0x802330` if `%a2@(44)` is zero.
- Calls `0x805B18` three times with different shared RAM addresses (`0xC00370`, `0xC003CC`, `0xC0039E`) – likely initializing shared data structures.
- Reads `%a3@` (system control register) and masks bit 8 (0x0100) – likely checking the DIS.MAP or DIAG bit, storing result in `%d7`.
- If boot mode is `1`, writes `0x9A16` to `0xC004B4` and `0xC004B6` (shared diagnostic variables).
- Calls `0x800F06` – likely a hardware test or status check; branches based on result.
- **If `0x800F06` returns zero** (success path):
  - Sets bits in `%a3@` (system control) to `0x4100` (likely enables Boot.DMA and other flags).
  - Stores `0xC03800` to `%a5@+` (pointer advance).
  - Based on boot mode, stores either `0x800E8C` or `0x800E74` to `%a5@` (likely boot entry points).
  - Updates shared pointers `0xC006BE`/`0xC006C2` and sets `0xC00648` to `128`.
  - Toggles bit 1 of `%a4@` (processor control) – clears then sets JKPD? Calls `0x800600`.
  - Sets `0xC00650` to `1`.
  - Conditionally clears bit 8 of `%a3@` if `%d7` was zero.
  - If boot mode `1`, clears `0xC004B4`/`0xC004B6` and calls `0x802330` again.
- **If `0x800F06` returns non‑zero** (failure/alternate path):
  - Sets `%a3@` to `0x8100` (different control bits).
  - Stores `0xC04000` to `%a5@+`.
  - Based on boot mode, stores `0x800EAA` or `0x800E74` to `%a5@`.
  - Swaps `0xC006BE`/`0xC006C2` values, sets `0xC006C2` to `2`, clears `0xC00648`.
  - Toggles bit 0 of `%a4@` – sets then clears? Calls `0x800600` and `0x8058F4`.
  - Conditionally clears bit 8 of `%a3@` if `%d7` was zero.
  - If boot mode ≠ 0, clears `0xC004B4`/`0xC004B6` and calls `0x802330`.
  - Calls `0x800E04`.
- Final path: if boot mode is `2`, calls `0x8005E0` (delay); else calls `0x800DF8` (in success path) or `0x800E04` already called in failure path.

**Called Functions**:
- `0x802330` – unknown (called when boot mode is 1 and shared variable is zero, and again later)
- `0x805B18` – called three times with shared RAM addresses (likely shared memory init)
- `0x800F06` – test/check function (determines success/failure branch)
- `0x800600` – hardware control function (called in both branches)
- `0x8005E0` – delay(0x14) when boot mode is 2
- `0x800DF8` – called in success path when boot mode ≠ 2
- `0x8058F4` – called in failure path
- `0x800E04` – called in failure path when boot mode ≠ 0

**Notes**:
- The function uses `%a5` initialized to `0x0` (`lea 0x0,%a5`), which is suspicious – likely a placeholder or bug; but later `%a5@+` and `%a5@` are used, meaning `%a5` is treated as a memory pointer (maybe to a predefined global pointer in RAM).
- The two main branches (success/failure) set different control register bits (`0x4100` vs `0x8100`) and store different boot addresses (`0x800E8C`/`0x800EAA` vs `0x800E74`).
- Shared memory variables at `0xC006BE`, `0xC006C2`, `0xC00648`, `0xC00650` appear to be used for boot coordination between DMA and Job processors.
- The strings referenced (`"N^NuNV"`) are not directly used in this function; they may be in called subroutines.
- This function likely implements the final stage of the DMA processor’s self‑test, deciding whether to proceed to the boot loader (`0x80854A` in U15) or stay in the diagnostic monitor.

---

### Function at 0x8054fa

**Embedded strings:**
- `8410570`: `"N^NuNV"`
- `8410633`: `",f\nN"`

**Name**: `scsi_command_with_timeout`  

**Purpose**:  
This function appears to execute a SCSI command via the DMA processor’s SCSI controller, using a pre‑initialized command block pointed to by `%a5`. It sets up the command parameters, starts the SCSI operation, then waits for completion with a timeout. If the timeout expires, it returns a timeout error; otherwise, it returns either a SCSI status byte or a result code from the command block.

**Parameters**:  
- `%fp@(8)`  – pointer to SCSI command data (stored at `%a5@`)  
- `%fp@(12)` – data pointer or additional parameter (stored at `%a5@(4)`)  
- `%fp@(16)` – SCSI command byte (used to adjust timeout multiplier)  
- `%fp@(18)` – word parameter (stored at `%a5@(10)`)  
- `%fp@(20)` – longword parameter (stored at `%a5@(12)`)  

**Returns**:  
- `%d0` – result code:  
  - `0xEF` (239) if timeout occurred  
  - `%a5@(42)` (word, zero‑extended) if non‑zero (likely SCSI status)  
  - otherwise `%a5@(36)` (longword, likely result/bytes‑transferred)  

**Key Operations**:  
- Calls `0x800f06` (likely returns a pointer to the DMA processor’s SCSI control block area; `%a5` is set to `0xC003CC` or `0xC0039E` depending on result).  
- Checks `0xC00650` (a system flag); if zero, calls `0x80536c` with argument `2` (possibly SCSI bus initialization).  
- Calls `0x805b18` with `%a5` as argument (probably prepares SCSI controller for a new command).  
- Stores all input parameters into the SCSI command block at offsets 0, 4, 10, 12.  
- Clears `0xC0089E` (a shared variable, possibly error flag).  
- Sets timeout loop counter `%d6` to 1024, tripled (×8) if command byte is 7, 10, or 11 (longer commands get longer timeout).  
- Sets `%a5@(40)` to 1 (command‑active flag).  
- Waits in a loop, checking `%a5@(44)` (completion flag) each iteration; calls `0x800600` (short delay?) and `0x804ff6` (SCSI controller poll?) per loop.  
- If timeout (`%d6` reaches zero), returns error `0xEF`.  
- Otherwise reads `%a5@(42)` (status word); if non‑zero, delays (calls `0x8005e0` with argument `0x14`) and returns that status; else returns `%a5@(36)` (result field).  

**Called Functions**:  
- `0x800f06` – likely returns base address of SCSI command block  
- `0x80536c` – SCSI‑related init (called if `0xC00650` is zero)  
- `0x805b18` – SCSI command setup  
- `0x800600` – short delay / idle  
- `0x804ff6` – SCSI controller polling / status check  
- `0x8005e0` – delay (when status word is non‑zero)  

**Notes**:  
- The timeout scaling for command bytes 7, 10, 11 suggests these are longer SCSI operations (e.g., read/write extended, seek).  
- The function uses a shared memory structure at `0xC003CC`/`0xC0039E` (DMA processor’s SCSI work area). Offsets observed:  
  - +0  : command pointer  
  - +4  : data pointer  
  - +10 : word parameter  
  - +12 : long parameter  
  - +36 : result field  
  - +40 : active flag  
  - +42 : status word  
  - +44 : completion flag  
- The function is careful to clear the active and completion flags after finishing.  
- The final result can be either a SCSI status byte (from offset 42) or a transfer count/result code (offset 36), indicating the function handles both data and non‑data commands.

---

### Function at 0x8055ce

**Embedded strings:**
- `8410633`: `",f\nN"`
- `8410706`: `"N^NuNV"`

**Name**: `scsi_command_with_timeout`

**Purpose**: This function sends a SCSI command to the Omti 5200 controller and waits for its completion with a timeout. It initializes the SCSI controller, polls for command-ready and data-ready status, and upon success, copies a command block (likely a SCSI CDB) and associated parameters into the controller's memory-mapped registers. If the timeout expires before the controller is ready, it prints an error message.

**Parameters**:  
- `%fp@(8)`  (long): First longword of the SCSI command block (likely CDB bytes 0-3)  
- `%fp@(12)` (long): Second longword of the SCSI command block (likely CDB bytes 4-7)  
- `%fp@(18)` (word): Word parameter (possibly transfer length or control)  
- `%fp@(20)` (long): First data pointer or buffer address  
- `%fp@(24)` (long): Second data pointer or buffer address  

**Returns**:  
No explicit return value. On success, the SCSI controller's registers are loaded and the command is initiated. On timeout, an error message is printed via `0x800e10`.

**Key Operations**:  
- Writes `1` to address `0xC00390` (`%a5@(32)`), likely a SCSI controller command/control register (Omti 5200 command start).  
- Checks a global flag at `0xC00650`; if zero, calls `0x80536c` with argument `2` (possibly SCSI bus reset or initialization).  
- Waits in a polling loop (up to 100,000 iterations) for two SCSI controller status bits:  
  - `%a5@(34)` (offset 0x22) – likely "Command Ready" or "Busy"  
  - `%a5@(44)` (offset 0x2C) – likely "Data Ready" or "DMA Complete"  
- Calls `0x804ff6` each loop iteration (likely a short delay or watchdog service).  
- If timeout (`%d7` reaches zero), prints error string at address `0x807c52` (",f\nN" – likely "SCSI timeout" or similar).  
- If controller becomes ready in time, calls `0x805b18` (likely SCSI controller register dump or logging).  
- Copies the 5‑parameter block into the SCSI controller's register area starting at `%a5` (`0xC00370`):  
  - Offsets 0x0, 0x4: CDB words 1 and 2  
  - Offset 0xA: the word parameter  
  - Offsets 0xC, 0x10: the two data pointers  

**Called Functions**:  
- `0x80536c` – SCSI subsystem init/reset (called if `0xC00650` is zero)  
- `0x804ff6` – short delay or watchdog tick  
- `0x800e10` – print string (called on timeout)  
- `0x805b18` – SCSI register dump/log (called before loading command)

**Notes**:  
- The base address `0xC00370` (`%a5`) matches the Omti 5200's memory-mapped register block in the Plexus memory map (SCSI controller area).  
- The timeout loop count of 100,000 is relatively large, suggesting a busy‑wait of several milliseconds.  
- The function expects the SCSI controller to be idle (both status bits zero) before loading a new command.  
- The two data pointers at offsets 0xC and 0x10 may be for scatter‑gather DMA descriptors, common in SCSI controllers of this era.  
- This is a low‑level SCSI command dispatch routine, likely called by higher‑level disk or tape drivers.

---

### Function at 0x805656

**Embedded strings:**
- `8410830`: `"N^NuNV"`
- `8410896`: `"N^NuNV"`

**Name**: `initialize_shared_memory_and_boot_control`

**Purpose**: This function initializes a block of shared memory in the DMA processor's address space (either at 0xC004B8 or 0xC0057C) by zeroing it, and then conditionally sets a boot control bit (either "Boot.DMA" or "Boot.JOB") in the system control register at 0xE00016 based on the result of a test and the function's input parameter. Finally, it calls another function, passing a modified version of the input parameter.

**Parameters**: One 32-bit parameter passed on the stack at offset 8 from the frame pointer (`%fp@(8)`). This parameter appears to be an integer selector (likely 1-6) that influences which boot processor is activated.

**Returns**: No explicit return value. The function's effects are side-effects: memory is cleared, hardware control bits are set, and a subroutine is called.

**Key Operations**:
*   Calls a test function at `0x800f06` (likely a hardware check or processor identification routine).
*   Based on the test result, writes the value `0x9A16` (a signature or flag) to either `0xC004B4` or `0xC004B6`.
*   Sets register `%a5` to point to the start of a 196-byte memory block at either `0xC004B8` or `0xC0057C`.
*   Clears (zeroes) all 196 bytes of this memory block.
*   If the input parameter equals 6, it calls the test function again and, based on its result, sets bit 2 (`0x0004`, Boot.DMA) or bit 3 (`0x0008`, Boot.JOB) in the system control register at `0xE00016`. This action likely releases the specified processor from reset or allows it to begin execution.
*   Calls a subroutine at `0x800610`, passing `(input_parameter - 1)` as an argument.

**Called Functions**:
*   `0x800f06`: An unknown test/identification function. Called twice.
*   `0x800610`: An unknown function, called with `(parameter - 1)`.

**Notes**:
*   The memory blocks at `0xC004B8` and `0xC0057C` are within the shared RAM area (`0xC00000-0xC00FFF`). Their initialization to zero suggests they are data structures or buffers used for inter-processor communication (IPC) or boot parameters.
*   The writes to `0xC004B4` and `0xC004B6` (adjacent to the cleared blocks) may be setting a header or status word for these data structures.
*   The function's behavior bifurcates based on the result from `0x800f06`. This likely checks which processor (DMA or JOB) is currently executing this ROM code, allowing it to set up the shared memory area appropriate for the current context.
*   The specific handling for an input parameter of `6` that modifies the `E00016` control register is critical. This is the point where the firmware decides which processor to boot and signals it via hardware. The parameter likely originates from a user command or boot configuration.
*   The final call to `0x800610` with a decremented parameter suggests this function is part of a sequence or menu of operations, where parameter `6` corresponds to a specific boot action (like "boot from disk"), and `5` would be a different action.

---

### Function at 0x8056d2

**Embedded strings:**
- `8410896`: `"N^NuNV"`

**Name**: `debug_get_and_clear_char_at_index`

**Purpose**:  
This function retrieves a single character from one of two debug character arrays in shared RAM, based on an index parameter and a condition checked by a subroutine. It then clears that character position to zero (null) and returns the character. The two arrays appear to be located at fixed addresses in the shared RAM region (`0xC004B8` and `0xC0057C`), suggesting they are used for debug or IPC message passing between processors.

**Parameters**:  
- The function expects a 32-bit integer parameter on the stack at `%fp@(8)`. Only the low 8 bits of this parameter are used (masked with `0xFF`), serving as an index into the selected character array.

**Returns**:  
- `%d0` (32-bit) contains the character value (zero-extended from byte) that was read from the array before clearing. If the character was zero, zero is returned.

**Key Operations**:  
- Masks the input parameter to 8 bits using `andil #255,%fp@(8)`.  
- Calls subroutine `0x800f06`; its result determines which of two base addresses is selected:  
  - Non-zero result → use array at `0xC004B8`  
  - Zero result → use array at `0xC0057C`  
- Adds the masked index to the base address to form the character pointer.  
- Reads the byte at that address, saves it, then clears the location to zero with `clrb %a5@`.  
- Returns the saved byte value (zero-extended to long).

**Called Functions**:  
- `jsr 0x800f06` at address `0x8056e4`. This likely checks a flag or status to decide which debug buffer to use (e.g., DMA vs Job processor buffer, or active/inactive buffer).

**Notes**:  
- The two fixed addresses (`0xC004B8` and `0xC0057C`) are in the shared RAM area (`0xC00000–0xC00FFF`), consistent with cross-processor communication.  
- The function effectively "pops" a character from a circular buffer or queue by reading and clearing it, which could be part of a simple debug message dequeue mechanism.  
- The string `"N^NuNV"` referenced nearby might be a format string or buffer label, but it is not directly used in this function.  
- The function preserves registers `%d7` and `%a5` via `moveml` save/restore, indicating they are used as scratch within the function.  
- This is likely a helper for the debug monitor command interpreter to retrieve characters from an input buffer or message queue.

---

### Function at 0x805714

**Embedded strings:**
- `8410966`: `"N^NuNV"`
- `8410998`: `"N^NuNV"`

**Name**: `set_boot_device_flag_and_clear_string`

**Purpose**: This function determines which processor (DMA or Job) is currently executing based on a hardware test, sets a corresponding boot flag in shared RAM, loads a pointer to a specific string in shared RAM, and then clears that string by zeroing its first 9 bytes. It effectively marks the booting processor and prepares a string buffer (likely for a boot message or status) for later use.

**Parameters**: None explicitly. It implicitly uses the system's hardware state via a call to `0x800f06`.

**Returns**: No explicit return value. Side effects are:
- Writes a word (`#2`) to either `0xC004B0` (if Job processor) or `0xC004B2` (if DMA processor).
- Clears 9 bytes of a string at a shared RAM address (`0xC0088A` or `0xC00894`).

**Key Operations**:
- Calls a subroutine at `0x800f06` (likely a "who-am-I" function that returns a processor ID in `%d0`).
- Tests the return value: if non-zero, assumes DMA processor; if zero, assumes Job processor.
- For DMA processor:
  - Sets `%a5` to point to shared RAM address `0xC0088A`.
  - Writes the value `2` to the shared RAM word at `0xC004B2` (a DMA processor boot flag).
- For Job processor:
  - Sets `%a5` to point to shared RAM address `0xC00894`.
  - Writes the value `2` to the shared RAM word at `0xC004B0` (a Job processor boot flag).
- Clears 9 consecutive bytes starting at the address in `%a5` by setting them to zero.

**Called Functions**:
- `jsr 0x800f06`: Likely a "processor identify" function. Based on context, it returns 0 for Job processor and non-zero for DMA processor.

**Notes**:
- The strings at `0xC0088A` and `0xC00894` correspond to the referenced strings "N^NuNV" in the prompt, which are likely placeholders or short status codes in shared RAM.
- The shared RAM addresses `0xC004B0` and `0xC004B2` are within the known shared variables area (`0xC00000-0xC00FFF`). Writing `2` to these locations likely sets a "processor booting" or "boot stage" flag.
- The function is part of the early boot process, distinguishing between the two 68010 processors and initializing processor-specific data areas.
- The clearing of 9 bytes (not necessarily a null-terminated string length) suggests a fixed-width field is being zeroed, possibly for a later formatted message.

---

### Function at 0x80575a

**Embedded strings:**
- `8410998`: `"N^NuNV"`
- `8411056`: `"N^NuNV"`

**Name**: `clear_boot_flag_based_on_test`

**Purpose**: This function calls a diagnostic subroutine at 0x800f06 (likely a hardware self-test or status check) and, based on its return value, clears one of two boot-related flags in shared RAM. If the test returns non-zero (success/failure indication), it clears the word at 0xC004B2; otherwise, it clears the word at 0xC004B0. These addresses are in the shared RAM area (0xC00000-0xC00FFF) used for inter-processor communication and system state, suggesting the function selects which boot flag to reset depending on a hardware test outcome.

**Parameters**: None explicitly passed. The function relies on the subroutine at 0x800f06 to return a status in D0.

**Returns**: No explicit return value. Side effect: clears a 16-bit value at either 0xC004B0 or 0xC004B2 in shared RAM.

**Key Operations**:
- Calls a diagnostic subroutine at 0x800f06 (likely tests hardware or checks status).
- Tests the 32-bit return value in D0.
- Conditionally clears a word in shared RAM:
  - If D0 ≠ 0: clears the word at 0xC004B2.
  - If D0 = 0: clears the word at 0xC004B0.
- These addresses (0xC004B0, 0xC004B2) are within the shared RAM region used for DMA-Job processor communication and boot control variables.

**Called Functions**:
- `jsr 0x800f06` – A diagnostic/status function whose exact purpose isn't defined here, but likely checks hardware (e.g., SCSI, memory, or processor state).

**Notes**:
- The function uses a standard stack frame (`linkw %fp,#-4`) but doesn't appear to use local variables; this may be for debugging or consistency.
- The two cleared addresses differ by only 2 bytes, suggesting they are adjacent flags or status words.
- Given the Plexus boot process, these flags might indicate which processor (DMA or Job) is allowed to boot, or which boot path (primary/alternate) to take after self-test.
- The strings referenced nearby ("N^NuNV") are not used in this function; they may belong to unrelated code.
- This function is likely part of the DMA processor's early boot decision-making, clearing a boot flag based on a hardware test result.

---

### Function at 0x80577a

**Embedded strings:**
- `8411056`: `"N^NuNV"`

**Name**: `get_and_clear_shared_byte`

**Purpose**:  
This function retrieves a single byte from a shared memory lookup table, clears that byte to zero, and returns the original value. The lookup table address is selected based on the result of a called function: if the function returns non-zero, the base address is `0xC0088A`; otherwise, it is `0xC00894`. The function then adds an offset (passed as a parameter) to the base address, reads the byte at the resulting address, stores it, clears the location, and returns the stored value. This is likely used for atomic retrieval of status flags or message bytes in a shared memory communication scheme between the DMA and Job processors.

**Parameters**:  
- `%fp@(8)` (the first 32-bit parameter on the stack): an integer offset added to the selected base address.

**Returns**:  
- `%d0`: the byte (zero-extended to 32 bits) that was read from the calculated address before it was cleared.

**Key Operations**:  
- Calls a subroutine at `0x800F06` (likely a test or status-check function).
- Selects one of two base addresses in shared RAM (`0xC0088A` or `0xC00894`) based on the result of the call.
- Adds the parameter offset to the selected base address.
- Reads a byte from the calculated address.
- Clears (sets to zero) the byte at that address.
- Restores registers and returns the original byte value.

**Called Functions**:  
- `jsr 0x800F06` – an unknown function whose return value determines which shared memory table is used.

**Notes**:  
- The shared memory addresses `0xC0088A` and `0xC00894` fall within the known shared variables/data area at `0xC00000–0xC00FFF`. This suggests the function is part of inter-processor communication (IPC) or synchronization between the DMA and Job processors.
- The function atomically reads and clears a byte, which is a typical pattern for consuming a flag, semaphore, or message byte in a cooperative multitasking or multiprocessor system.
- The referenced string `"N^NuNV"` (at address `0x8411056`) is not used in this function; it may be located in a different segment of the ROM.
- The function preserves registers `%d7` and `%a5` (saved/restored via `moveml`), indicating they are used as scratch registers within the function.

---

### Function at 0x8057b4

**Embedded strings:**
- `8411164`: `"N^NuNV"`

**Name**: `process_bus_error_details`

**Purpose**: This function reads the bus error status register, processes the error details to count specific error conditions, updates a diagnostic counter array, and clears the appropriate processor's bus error flag. It appears to be part of the system's error handling or diagnostic reporting mechanism, likely called after a bus error to log or analyze the cause.

**Parameters**: No explicit parameters passed via registers or stack. The function reads hardware register `0xE00014` (bus error details) as its primary input.

**Returns**: Returns 0 in `%d0`. The function's main effect is side-effects: it increments counters in a memory array and clears a hardware error flag.

**Key Operations**:
- Reads the 16-bit bus error details register at `0xE00014` into `%d7`
- Calls a subroutine at `0x800f06` (likely a test or check function) twice
- Based on the first call's result, selects one of two counter array base addresses:
  - If non-zero: `0xC0088A` (likely Job processor error counters)
  - If zero: `0xC00894` (likely DMA processor error counters)
- Processes the lower 5 bits of the shifted error value (`%d7 >> 8 >> 3` = bits 11-8 of original)
- For each of 5 bit positions (0-4), increments the corresponding array element if the bit is set
- Clears the appropriate bus error flag based on the second subroutine call result:
  - If non-zero: clears Job processor bus error flag at `0xE00120`
  - If zero: clears DMA processor bus error flag at `0xE00140`

**Called Functions**:
- `0x800f06`: Called twice; appears to determine which processor is active or which error context applies

**Notes**:
- The function processes only bits 11-8 of the bus error details register (after shifting right by 8 then 3), suggesting these bits represent five distinct error conditions that are counted separately.
- The two counter arrays at `0xC0088A` and `0xC00894` are 5 bytes each (one counter per bit position).
- The dual processor architecture is reflected in the separate counter arrays and separate bus error clear registers.
- The string "N^NuNV" at address `0x841164` is not referenced in this function's code; it may be in a different related function.
- This appears to be diagnostic/debug code rather than primary error recovery, as it counts error types but doesn't attempt to recover from the bus error itself.

---

### Function at 0x805820

**Embedded strings:**
- `8411268`: `"N^NuNV"`

**Name**: `write_to_special_address_or_fallback`  

**Purpose**:  
This function attempts to write a byte value to a memory-mapped hardware address derived from a base address and a fixed offset. If a preliminary test fails, it falls back to an alternative routine that likely performs a more complex operation (possibly involving IPC or error handling). The function appears to be part of the DMA processor’s low‑level hardware interaction, possibly for debugging, register programming, or inter‑processor communication.

**Parameters**:  
- `%fp@(8)` (32‑bit): Base address for the write operation.  
- `%fp@(12)` (32‑bit): Data passed to the fallback routine (when the initial test fails).  
- `%fp@(15)` (8‑bit): Byte value to write to the computed address (when the initial test succeeds).

**Returns**:  
- `%d0` (32‑bit): Result from either the direct‑write path (`%d7` copied) or the fallback routine’s return value.

**Key Operations**:  
- Calls a test routine at `0x800f06`; if it returns non‑zero, proceeds with a direct hardware write.  
- Computes a target address by OR‑ing the base address with `0x00B00000` (11534336 decimal), which maps into the Plexus hardware register space (`0xE00000` region).  
- Writes the low byte parameter (`%fp@(15)`) to the computed address.  
- Calls `0x80577a` with argument `0x2`, and if that returns zero, sets `%d7 = 0`.  
- Calls `0x80575a` (likely a synchronization or status‑check routine).  
- If the initial test at `0x800f06` fails (returns zero), calls `0x8054fa` with three arguments: base address, `0`, and `1` (in that order), and uses its return value as the result.

**Called Functions**:  
- `0x800f06`: Unknown test; returns non‑zero to enable direct hardware write path.  
- `0x805714`: Unknown; called only in the direct‑write path.  
- `0x80577a`: Unknown; takes one argument (`0x2`), returns a status that may clear `%d7`.  
- `0x80575a`: Unknown; called after the write/status check.  
- `0x8054fa`: Fallback routine; takes three arguments (base address, `0`, `1`).

**Notes**:  
- The OR‑immediate value `0x00B00000` added to the base address suggests the target is a hardware control register in the `0xE00000–0xEFFFFF` range (since `0x00B00000` is close to the `0x00C00000` shared‑RAM area, but the OR could place it in the `0xE0xxxx` region depending on the base).  
- The function has two distinct execution paths: a “fast” hardware‑write path and a “fallback” path that invokes a more complex routine. This may reflect a conditional access method—perhaps trying direct hardware access first, and if the system isn’t ready, using a safer IPC mechanism.  
- The byte write (`moveb %fp@(15),%a0@`) is to a computed address, which is typical for memory‑mapped I/O writes (e.g., LED control, SCSI command, serial port control).  
- The fallback routine `0x8054fa` is called with arguments that resemble a command/address pair, possibly for inter‑processor communication (Job processor interaction).

---

### Function at 0x805888

**Embedded strings:**
- `8411376`: `"N^NuNV"`
- `8411436`: `"N^NuNV"`

**Name**: `scsi_send_command_or_fallback`

**Purpose**: This function attempts to send a SCSI command via the DMA processor's SCSI interface, but if the SCSI subsystem is not ready or fails, it falls back to an alternative method (likely a lower-level or debug path). The function appears to handle command packet preparation, SCSI controller readiness checks, and error handling, returning a status or result code.

**Parameters**: 
- `%fp@(8)` (first argument on stack): A base address or command descriptor pointer. The function modifies this value by OR-ing with `0x00B00000` (11534336 decimal), which likely sets it to a specific memory region (possibly SCSI controller command register space or a DMA buffer in shared memory).

**Returns**: 
- `%d0`: A status/result code derived from `%d7`. Returns 0 on failure of the primary SCSI path, or the result from the fallback path.

**Key Operations**:
- Calls `0x800f06` (likely a SCSI controller or DMA processor readiness check).
- If check passes:
  - Calls `0x805714` (likely SCSI initialization or setup).
  - Modifies the input pointer by OR-ing with `0x00B00000` — this maps it into the SCSI controller's register space or a DMA buffer area (0xB00000 is in the hardware register range).
  - Reads a byte from the modified address (likely a SCSI status or command register).
  - Calls `0x80577a` with argument 2 (possibly a SCSI "send command" or "execute" function).
  - If that call returns zero, sets `%d7` to 0 (failure), else sets `%d7` to 1 (success).
  - Calls `0x80575a` (likely a cleanup or status reporting function).
- If the initial check fails:
  - Calls `0x8054fa` with three zero arguments and the original (unmodified) input pointer. This is the fallback path, possibly a direct memory write or debug output routine.

**Called Functions**:
- `0x800f06`: `scsi_controller_ready_check` or similar.
- `0x805714`: `scsi_prepare_command` or `scsi_init_transfer`.
- `0x80577a`: `scsi_execute_command` (argument 2 may be a command code).
- `0x80575a`: `scsi_cleanup` or `scsi_report_status`.
- `0x8054fa`: `debug_scsi_write` or `fallback_memory_operation`.

**Notes**:
- The OR value `0x00B00000` is significant — it suggests the SCSI controller's registers are memory-mapped at that region (consistent with the Plexus memory map where 0xB00000 might be an alias or part of the 0xE00000–0xE001FF control space). This could be the Omti 5200 SCSI controller's register block.
- The fallback path (calling `0x8054fa`) is invoked if the initial SCSI readiness check fails, indicating robust error handling for when the SCSI bus or DMA processor is not available.
- The function preserves `%d7` across calls (saved at `%fp@(-4)`), suggesting it follows standard 68010 calling conventions.
- The strings "N^NuNV" at addresses 8411376 and 8411436 are not directly referenced in this code; they may be in the called subroutines.

---

### Function at 0x8058f4

**Embedded strings:**
- `8411436`: `"N^NuNV"`
- `8411468`: `"N^NuNV"`

**Name**: `disable_processor_serial_interrupts`

**Purpose**: This function disables serial port interrupts for either the DMA or Job processor based on a system status check. It first calls a subroutine that likely checks which processor is currently active or determines the system state, then conditionally clears the serial interrupt enable bits in the system control register (0xE00016) and zeroes a corresponding shared memory flag.

**Parameters**: None explicitly passed; the function uses global memory and hardware registers.

**Returns**: No explicit return value; side effects modify hardware control register 0xE00016 and shared RAM locations 0xC004B4 or 0xC004B6.

**Key Operations**:
- Calls `0x800610` with argument 7 (likely a delay or setup function).
- Calls `0x800F06` which returns a status value in D0; a non-zero result selects the DMA processor path, zero selects the Job processor path.
- For DMA processor (D0 ≠ 0): Clears bit 2 (mask 0xFFFB) of system control register 0xE00016 (disables DMA processor serial interrupts via TCE/RCE bits) and clears word at shared address 0xC004B4 (likely a DMA serial interrupt flag).
- For Job processor (D0 = 0): Clears bit 3 (mask 0xFFF7) of system control register 0xE00016 (disables Job processor serial interrupts) and clears word at shared address 0xC004B6 (likely a Job serial interrupt flag).

**Called Functions**:
- `0x800610` – unknown function, possibly `delay` or `serial_init` with argument 7.
- `0x800F06` – status check function returning processor identifier or interrupt state.

**Notes**:
- The function uses the system control register at 0xE00016, which contains Boot, DIS.MAP, DIAG, and interrupt enable bits. Bits 2 and 3 correspond to TCE (Transmit Character Enable) and RCE (Receive Character Enable) for serial interrupts per processor.
- Shared RAM addresses 0xC004B4 and 0xC004B6 appear to hold processor-specific serial interrupt pending flags, cleared when interrupts are disabled.
- This is likely part of a shutdown, reinitialization, or error-handling sequence where serial interrupts must be quiesced for one processor.

---

### Function at 0x805930

**Embedded strings:**
- `8411468`: `"N^NuNV"`
- `8411530`: `"N^NuNV"`

**Name**: `wait_for_scsi_operation_completion`  

**Purpose**:  
This function waits for a pending SCSI operation to complete. It first checks a global flag at `0xC006BA` to see if SCSI operations are enabled/allowed. If they are, it enters a loop that repeatedly fetches a SCSI status/result value from `0xC006D6` and calls a subroutine at `0x807882` (likely a SCSI controller poll/status function) until that subroutine returns a non-zero value, indicating the operation has finished or an error occurred.

**Parameters**:  
- None explicitly passed; reads from fixed memory-mapped locations:
  - `0xC006BA`: Global SCSI enable/operation‑pending flag (longword).
  - `0xC006D6`: SCSI operation result/status word (longword) that is passed to the polling subroutine.

**Returns**:  
- No explicit return value; the function loops until the SCSI operation completes, then returns to caller.

**Key Operations**:  
- Tests the longword at `0xC006BA` — if zero, the function returns immediately (SCSI operations disabled).
- Enters a loop that:
  1. Moves the longword from `0xC006D6` onto the stack (likely as an argument for the subroutine).
  2. Calls subroutine at `0x807882` (SCSI controller poll/status check).
  3. Tests the low byte of `%d0`; if zero, loops back to step 1.
- Uses a local stack frame (`linkw %fp,#-4`) though no locals appear to be used; possibly for alignment or debugging.

**Called Functions**:  
- `0x807882` — SCSI status/polling function; expects argument on stack (the value from `0xC006D6`), returns a byte in `%d0` where non‑zero means “done” or “error”.

**Notes**:  
- The memory addresses `0xC006BA` and `0xC006D6` are in the shared RAM region (`0xC00000–0xC00FFF`) used for inter‑processor communication and hardware status.  
- The strings `"N^NuNV"` referenced nearby are likely unrelated to this function — they appear in a different part of the ROM and may be debug or diagnostic messages.  
- The loop structure suggests this is a blocking wait for a SCSI operation, typical of the DMA processor’s role in handling I/O.  
- The function returns immediately if `0xC006BA` is zero, meaning SCSI operations are not currently active (possibly due to a previous error or disabled controller).

---

### Function at 0x805950

**Embedded strings:**
- `8411530`: `"N^NuNV"`

**Name**: `is_address_in_rom_range`

**Purpose**:  
This function determines whether a given 32-bit address falls within one of two specific ROM address ranges used by the Plexus P/20 system. It returns a boolean value indicating if the address is within either the U17 self-test/debug ROM range (0x00900000–0x00904100) or a second ROM-like range (0x00B00000–0x00C00000). This is likely used by diagnostic or boot code to validate addresses before performing operations that should only target ROM regions (e.g., reading firmware code, avoiding writes to ROM).

**Parameters**:  
- `%d7` (32-bit): The input address to be checked.

**Returns**:  
- `%d0` (32-bit): Returns 1 if the address is within either of the two ROM ranges; otherwise returns 0.

**Key Operations**:  
- Compares the input address against the first range: `0x00900000` (lower bound) to `0x00904100` (upper bound).  
- If the address is within this range (`%d7 >= 0x00900000 && %d7 < 0x00904100`), return 1.  
- Otherwise, compares against the second range: `0x00B00000` (lower bound) to `0x00C00000` (upper bound).  
- If the address is within this range (`%d7 >= 0x00B00000 && %d7 < 0x00C00000`), return 1.  
- If neither range matches, return 0.  
- The function preserves `%d7` across the call via the stack.

**Called Functions**:  
None; this is a leaf function.

**Notes**:  
- The first range (`0x00900000–0x00904100`) corresponds exactly to the U17 ROM mapped at `0x800000–0x807FFF` in the DMA processor’s memory map, but viewed through the system’s 24-bit address translation (the upper byte `0x00` is likely ignored or masked). The upper bound `0x00904100` allows a small margin beyond the U17 ROM’s end at `0x807FFF`.  
- The second range (`0x00B00000–0x00C00000`) may correspond to other ROM or reserved memory areas in the system’s physical address space, possibly including the U15 boot ROM (`0x808000–0x80FFFF`) or additional firmware regions.  
- The function uses unsigned comparisons (`bcss` for “lower than”, `bccs` for “higher or equal”) to implement inclusive‑lower, exclusive‑upper range checks.  
- This is a pure address‑range detector with no hardware register accesses, string output, or side effects. It was likely used by the self‑test or debug monitor to decide whether an address is safe to read from (ROM) or to prevent accidental writes to ROM.

---

### Function at 0x80598e

**Embedded strings:**
- `8411608`: `"N^NuNV"`

**Name**: `verify_or_install_boot_block`  

**Purpose**: This function appears to validate and possibly install a boot block or boot-related data structure. It first calls a validation routine (`0x800f06`), and if that passes, calls another function (`0x805950`) that likely prepares or checks a boot record. If both succeed, it calls a third routine (`0x8054fa`) with arguments that suggest a write operation (length 0x21, count 1) to install or update the boot block. If any validation fails, it returns zero or a status word from the input pointer.

**Parameters**:  
- `%a5` points to a data structure (likely a boot block or disk parameter block) passed via the stack at `%fp@(8)`.

**Returns**:  
- `%d0` contains either:  
  - On success: the result from the write/install call (`0x8054fa`).  
  - On failure: zero if the first validation fails, or the first word from the `%a5` structure if the second validation fails.

**Key Operations**:  
- Calls validation function `0x800f06` (likely checks system state or boot device).  
- Calls function `0x805950` (likely validates or initializes boot block data).  
- If both succeed, calls `0x8054fa` with arguments:  
  - Source data pointer (`%a5`).  
  - Count = 1.  
  - Length = 0x21 (33 bytes, possibly a boot sector header or SCSI command block).  
- Preserves registers `%d7` and `%a5` across calls.  
- Returns a status word from the input structure on early failure.

**Called Functions**:  
- `0x800f06` – Unknown validation routine (possibly hardware or SCSI readiness check).  
- `0x805950` – Boot block preparation/validation function.  
- `0x8054fa` – Write/install routine (likely writes to disk or flash).

**Notes**:  
- The value `0x21` (33 bytes) is interesting—it matches the size of a SCSI command block for some OMTI 5200 controllers, or could be a small boot header.  
- The function is defensive: if any check fails, it returns a safe value (zero or the first word of the input structure) rather than proceeding.  
- Located in the U17 ROM, this is likely part of the DMA processor’s boot-time disk initialization or recovery code.  
- The string `"N^NuNV"` referenced nearby is not used here; it may be a debug or error message for related functions.

---

### Function at 0x8059dc

**Embedded strings:**
- `8411676`: `"N^NuNV"`

**Name**: `scsi_write_sector_or_set_word`

**Purpose**:  
This function appears to be part of the SCSI disk I/O subsystem. It attempts to write a sector (or block) of data to a SCSI device, but if the write operation fails (either due to a SCSI controller error or a prior validation failure), it instead stores a 16-bit value into a memory location pointed to by one of its parameters. This suggests a fallback mechanism where a failure to write to disk results in updating an in-memory status or error word.

**Parameters**:  
- `%fp@(8)` (first parameter): A pointer (likely to a buffer or SCSI command structure)  
- `%fp@(12)` (second parameter): Likely a sector number or block address for the write operation  
- `%fp@(14)` (third parameter): A 16-bit value to store if the write fails  

**Returns**:  
No explicit return value in `%d0`. The function either performs a SCSI write operation or updates a memory location with the 16-bit fallback value.

**Key Operations**:  
- Calls `0x800f06` (likely a SCSI controller readiness or error-check function)  
- If that call returns non-zero (error), the function skips the write and stores the 16-bit fallback value  
- Otherwise, calls `0x805950` (likely validates the buffer or SCSI command)  
- If validation fails, again skips the write and stores the fallback  
- If validation passes, calls `0x8054fa` with three arguments: the buffer pointer, `0x1`, and `0x77` (likely a SCSI write command with LUN/block count parameters)  
- The `0x77` (119 decimal) may represent a block count or SCSI command opcode  

**Called Functions**:  
- `0x800f06`: SCSI controller status check  
- `0x805950`: Buffer/command validation  
- `0x8054fa`: Main SCSI write routine  

**Notes**:  
- The fallback mechanism (storing a word to `*pointer`) suggests this function is used in a context where a failed disk write must still update some status variable—possibly an error counter or a software flag.  
- The constants `0x1` and `0x77` passed to the write routine are interesting: `0x77` in SCSI terms could be a `WRITE(10)` command (opcode 0x2A) if interpreted as a byte, but here it's a word-sized argument. It might instead be a block count or a combined LUN/command value.  
- The function does not return a success/failure flag; it either performs the write or silently fails to the memory store. This implies the caller may check the memory location later for operation status.  
- Given the Plexus P/20's OMTI 5200 SCSI controller, this is likely part of the low-level disk driver in the DMA processor's self-test/debug ROM.

---

### Function at 0x805a20

**Embedded strings:**
- `8411754`: `"N^NuNV"`
- `8411820`: `"N^NuNV"`

**Name**: `validate_and_send_scsi_command` (or `scsi_command_with_retry`)

**Purpose**:  
This function validates a SCSI command block (likely a pointer to a SCSI CDB structure) by performing two checks: first a basic validation via a subroutine at `0x800f06`, and if that passes, a more specific validation via a subroutine at `0x805950`. If both checks succeed, it calls a third subroutine at `0x8054fa` with three arguments: the command block pointer, a value `1`, and a value `0x22` (34 decimal). This third call appears to send the SCSI command to the controller. The function returns the result of that send operation on success, or the first byte of the command block on failure.

**Parameters**:  
- `%a5` (passed via stack at `%fp@(8)`): Pointer to a SCSI command block (likely a CDB structure in memory).

**Returns**:  
- `%d0`: On success, returns the result from the subroutine at `0x8054fa` (likely a SCSI status or completion code). On failure, returns the first byte of the command block (the SCSI opcode) as a longword, or `0` if the first validation fails.

**Key Operations**:  
- Calls validation subroutine `0x800f06` (checks SCSI controller readiness or command sanity).  
- Calls second validation subroutine `0x805950` (likely checks command block fields or alignment).  
- If both validations pass, calls `0x8054fa` with arguments:  
  - Command block pointer (`%a5`)  
  - `1` (may be a device/LUN identifier or retry count)  
  - `0x22` (may be a command timeout value or SCSI control byte)  
- Preserves registers `%d7` and `%a5` across the function.  
- On validation failure, returns the first byte of the command block (SCSI opcode) or zero.

**Called Functions**:  
- `0x800f06`: Likely `scsi_check_ready` or `validate_scsi_state` (checks controller status).  
- `0x805950`: Likely `validate_cdb` or `check_command_params` (validates command block contents).  
- `0x8054fa`: Likely `scsi_send_command` or `scsi_execute` (sends CDB to OMTI 5200 controller).

**Notes**:  
- The value `0x22` (34 decimal) passed as the third argument may correspond to a SCSI timeout value in units of 100 ms (3.4 seconds), or it could be a SCSI control byte for the CDB.  
- The function appears to implement a retry or validation wrapper around SCSI command submission, ensuring the controller and command are valid before sending.  
- The two validation steps suggest the first (`0x800f06`) checks hardware state (controller busy, bus parity), while the second (`0x805950`) checks command-specific parameters (LUN valid, block address in range).  
- Returning the opcode on failure may allow the caller to log or handle specific failed commands.  
- The function uses a standard stack frame and preserves `%d7` and `%a5`, suggesting it follows Motorola 68010 calling conventions.

---

### Function at 0x805a6e

**Embedded strings:**
- `8411820`: `"N^NuNV"`
- `8411857`: `""f\nN"`

**Name**: `scsi_send_command_or_fallback`  

**Purpose**:  
This function appears to be part of the SCSI command-handling logic in the DMA processor’s ROM. It first checks if a SCSI-related operation is possible (likely by verifying controller readiness or bus state). If that check passes, it attempts to send a SCSI command block; if that also succeeds, it proceeds to issue a SCSI command with a specific opcode (0x4F). If either check fails, it falls back to writing a byte (likely a status or error code) into a buffer pointed to by the first argument.  

**Parameters**:  
- `%fp@(8)` (first argument): Pointer to a SCSI command buffer or result buffer.  
- `%fp@(12)` (second argument): Likely a parameter for the SCSI command (e.g., data pointer or length).  
- `%fp@(15)` (third argument, byte offset): A byte value to store in the buffer if the SCSI path fails.  

**Returns**:  
No explicit register return value; side effects include possible SCSI command issuance or a byte written to the buffer at `%fp@(8)`.  

**Key Operations**:  
- Calls a SCSI readiness/initialization check at `0x800f06`.  
- Calls a SCSI command setup routine at `0x805950` with the first argument.  
- On success, calls `0x8054fa` with arguments:  
  - `%fp@(8)` (buffer pointer)  
  - `0` (likely a flag)  
  - `0x4F` (SCSI command opcode — e.g., “WRITE BUFFER” or vendor-specific)  
  - `%fp@(12)` (additional parameter)  
- On failure, stores `%fp@(15)` (a byte) into the buffer pointed to by `%fp@(8)`.  

**Called Functions**:  
- `0x800f06` — Likely `scsi_check_ready` or `scsi_init_test`.  
- `0x805950` — Likely `scsi_prepare_command` or `scsi_setup_buffer`.  
- `0x8054fa` — Likely `scsi_execute_command` (takes buffer, zero, opcode, parameter).  

**Notes**:  
- The opcode `0x4F` is a SCSI command code; in standard SCSI-1/2, `0x4F` is not a common command, suggesting it may be a vendor-specific OMTI 5200 command or a diagnostic operation.  
- The fallback path writes a byte from the caller into the buffer, suggesting this function may be used in a retry or error-handling context where a default status is recorded if SCSI operations fail.  
- The function uses a standard stack frame (`linkw %fp,#-4`) but doesn’t appear to use the local variable slot; it may have been reserved for alignment or debugging.  
- This is likely part of the DMA processor’s low-level SCSI driver, used during boot or disk I/O.

---

### Function at 0x805ab0

**Embedded strings:**
- `8411857`: `""f\nN"`
- `8411924`: `"N^NuNV"`
- `8411950`: `"N^NuNV"`

**Name**: `scsi_wait_ready_or_timeout`

**Purpose**:  
This function waits for the SCSI controller to become ready (by polling a status register) for up to 1000 iterations, with a delay between each check. If the controller does not become ready within the timeout, it prints an error message (likely "f\nN" or similar). If it does become ready, it prints a success message (likely "N^NuNV" or similar). Finally, it calls a subroutine that may reset or acknowledge the SCSI operation.

**Parameters**:  
None explicitly passed, but the function uses a hardcoded base address in `%a5` (0xC00370) which points to a memory-mapped SCSI controller register block.

**Returns**:  
No explicit return value; side effects include setting a status word, printing messages, and calling subroutines.

**Key Operations**:  
- Sets `%a5@(32)` (offset 0x20 from SCSI base) to 1, likely initiating a command or resetting a flag.
- Loops up to 1000 times, checking `%a5@(34)` (offset 0x22) for a non-zero status (SCSI ready flag).
- Calls `0x800600` (likely a short delay or yield function) each iteration while waiting.
- If timeout expires (`%d7` reaches 0), prints an error string from address `0x807C5D` ("f\nN").
- If SCSI becomes ready before timeout, prints a success string from address `0x807C66` ("N^NuNV").
- Calls `0x800664` (likely a SCSI completion or cleanup routine).

**Called Functions**:  
- `0x800600` – delay or yield function (called each loop iteration).
- `0x8005E0` – unknown, called only on timeout with argument 4.
- `0x807510` – print string function (called for both success and error paths).
- `0x800664` – SCSI post-operation cleanup or acknowledgment.

**Notes**:  
- The SCSI controller base address `0xC00370` matches the known Omti 5200 controller location in the Plexus memory map.
- Offset 0x20 is likely a command/control register, and offset 0x22 is a status register.
- The timeout of 1000 iterations with a delay each loop suggests a busy-wait for SCSI readiness, typical for polled I/O in early boot or diagnostic code.
- The strings printed are cryptic but consistent with other debug messages in the U17 ROM (e.g., "f\nN" may mean "fail" and "N^NuNV" may mean "ready" or "success").
- This function appears to be part of the SCSI initialization or command sequence during the DMA processor's self-test phase.

---

### Function at 0x805b18

**Embedded strings:**
- `8411950`: `"N^NuNV"`
- `8412014`: `"N^NuNV"`

**Name**: `debug_print_string_with_dot`  

**Purpose**:  
This function prints a string (passed as a parameter) followed by a period (ASCII `'.'`, hex `0x2E`). It appears to be a debug or diagnostic output routine, likely used to format status messages during self‑test or boot. The period may serve as a visual delimiter or terminator for a line of output in a serial console log.

**Parameters**:  
- `%fp@(8)` (the first 32‑bit argument on the stack after the frame pointer) contains the address of a null‑terminated string to print.

**Returns**:  
No explicit return value; the function is a void subroutine.

**Key Operations**:  
- Sets up a stack frame with `linkw %fp,#-4`.  
- Clears the longword at the top of the stack (`clrl %sp@`) — possibly a placeholder or leftover from an earlier version, as the value is unused.  
- Pushes the ASCII code for a period (`0x2E`) onto the stack.  
- Pushes the string address (parameter) onto the stack.  
- Calls subroutine `0x800d22`, which is likely a formatted print or console‑output routine.  
- Cleans up the stack and returns.

**Called Functions**:  
- `0x800d22` — a print/display function (probably outputs the string, then the period).

**Notes**:  
- The `clrl %sp@` appears to be dead code; it writes zero to a stack location that is immediately overwritten by the `pea 0x2e`. This may be an artifact of code reuse or an earlier calling convention.  
- The function is small and focused, suggesting it is a helper for formatting debug messages.  
- Given the U17 ROM’s role in self‑test/debug, this routine likely outputs test progress messages (e.g., “RAM test passed.”) to the serial console.  
- The period character is hard‑coded, implying the function always adds a trailing dot to whatever string is supplied.

---

### Function at 0x805b32

**Embedded strings:**
- `8412014`: `"N^NuNV"`
- `8412058`: `"N^NuNV"`

**Name**: `debug_led_and_log_event`

**Purpose**: This function checks if a global flag is set, and if so, updates the hardware LED display based on a stored LED pattern, calls a helper function, then logs an event by incrementing a counter and printing a formatted message to a debug output. It appears to be part of a diagnostic or debug monitoring system that visually signals status via LEDs and records events to a console or log.

**Parameters**: The function takes one parameter passed on the stack at `%fp@(4)`. The content of this parameter is later moved to the stack before a `jsr` call, suggesting it is a data pointer or value to be included in the logged message.

**Returns**: The function does not explicitly return a value in a register. It has side effects: updates the LED hardware register, increments a global counter at `0xc006c6`, and outputs a debug string.

**Key Operations**:
- Tests a global flag at address `0xc006de`. If zero, the function returns immediately.
- Writes the byte value from `0xc006c9` to the LED control hardware register at `0xe00010` (sets the front-panel LEDs).
- Calls a helper subroutine at `0x805b72`.
- Retrieves the function's input parameter from the stack.
- Loads and then increments a 32-bit global event counter at `0xc006c6`.
- Pushes the original counter value and a string pointer (`#8420464`, which likely points to a format string like `"N^NuNV"` at `0x807c70`) onto the stack.
- Calls a formatted output routine at `0x807510` (likely a `printf`-like debug print function).
- Cleans up the stack and returns.

**Called Functions**:
- `0x805b72`: An unknown helper function (likely performs additional hardware checks or setup).
- `0x807510`: A formatted print function for debug output.

**Notes**:
- The function is conditional on a global enable flag at `0xc006de`. This suggests the debug logging/led update can be turned off.
- The LED pattern is stored in RAM at `0xc006c9`, allowing dynamic control of the front-panel LEDs from software.
- The event counter at `0xc006c6` is persistent across calls, suggesting it tracks the number of times this debug path has been executed.
- The string at `0x807c70` (referenced by the immediate `#8420464`) appears in the string list as `"N^NuNV"` – this is likely a format string containing placeholders for the parameter and counter value. The odd characters may be control codes for a terminal or debug console.
- The function uses the `linkw`/`unlk` frame pointer protocol, indicating it is a proper C-callable subroutine.
- Given the hardware context, this function is likely part of the DMA processor's self-test/debug monitor in the U17 ROM, used for real-time status indication and event tracing during system initialization or diagnostics.

---

### Function at 0x805b72

**Embedded strings:**
- `8412058`: `"N^NuNV"`

**Name**: `print_diagnostic_result`  

**Purpose**:  
This function calls a diagnostic subroutine at `0x800f06` and prints one of two messages based on the result. If the diagnostic returns a non-zero value (indicating failure or a specific condition), it prints the string at address `0x807c77`; otherwise, it prints the string at `0x807c7e`. The function acts as a wrapper that reports the outcome of a test or system check.

**Parameters**:  
None explicitly passed; however, the called diagnostic at `0x800f06` may expect inputs in registers or memory.

**Returns**:  
No explicit return value; side effects include printing a string to the console (or debug output).

**Key Operations**:  
- Calls a diagnostic subroutine at `0x800f06`.  
- Tests the return value in `%d0`.  
- Prints either `"N^NuNV"` (if `%d0 != 0`) or a related string (if `%d0 == 0`) via `jsr 0x800e10` (likely a print function).  
- Uses the stack to pass the string address to the print function.

**Called Functions**:  
- `0x800f06`: Diagnostic/check function (unknown specific purpose).  
- `0x800e10`: Print function (likely outputs a null-terminated string whose address is on the stack).

**Notes**:  
- The strings at `0x807c77` and `0x807c7e` are adjacent in memory (difference of 7 bytes), suggesting they are related messages (e.g., "FAIL" vs "PASS" or similar).  
- The function uses `linkw %fp,#-4` to create a small stack frame, though it doesn’t appear to use local variables; this may be for alignment or consistency with calling conventions.  
- This pattern is common in diagnostic ROMs: run a test, print result, continue. The function likely appears in a sequence of hardware checks during boot.

---

### Function at 0x805b9e

**Embedded strings:**
- `8412140`: `"N^NuNV"`

**Name**: `configure_dma_transfer`  

**Purpose**:  
This function sets up a DMA transfer by configuring the system control register, scaling input addresses by a factor (likely related to memory mapping or bus width), and invoking a lower-level DMA routine. It also clears the memory parity error flag after the operation. The function appears to be part of the DMA processor’s I/O or memory‑transfer logic, possibly preparing for a block move or SCSI data transfer.  

**Parameters**:  
- `%fp@(8)` (long): Source or base address (stored in `%d7`)  
- `%fp@(12)` (long): Destination or offset address (stored in `%d6`)  
- `%fp@(16)` (long): Additional parameter (passed on stack to subroutine)  

**Returns**:  
No explicit return value; side effects include hardware register changes and a call to a DMA engine routine.  

**Key Operations**:  
- Saves registers `%d5`–`%d7` on the stack.  
- Calls subroutine at `0x801590` with three arguments: `%d7`, `%d6`, and the third parameter from the caller.  
- Clears bits in the system control register at `0xE00016` using `ANDIW #-6145` (i.e., masks out bits 12 and 13, which correspond to `DIS.MAP` and `DIAG`? – see hardware context).  
- Shifts `%d7` and `%d6` left by 12 positions (`%d5 = 12`), effectively multiplying by 4096 (likely converting logical addresses to physical or adjusting for a 4K page/granularity).  
- Calls subroutine at `0x800CE0` with the shifted `%d7` and `%d6` as arguments (and a zero longword on stack).  
- Clears the Memory Parity Error Flag at `0xE00160`.  
- Restores registers and returns.  

**Called Functions**:  
- `0x801590` – Unknown subroutine (possibly validates parameters or sets up transfer control blocks).  
- `0x800CE0` – Likely the core DMA transfer routine (initiates the hardware DMA operation).  

**Notes**:  
- The left‑shift by 12 suggests the function expects addresses in 4K‑aligned units or is converting from a logical to a physical address format used by the DMA controller.  
- The clearing of `0xE00160` (Memory Parity Error Flag) indicates this function is intended to be used in a context where parity errors must be acknowledged/reset after a transfer.  
- The masking of `0xE00016` bits may disable memory mapping (`DIS.MAP`) and diagnostic modes, ensuring the DMA operates on physical addresses.  
- The third parameter passed to `0x801590` is not used again locally; it may be a size, transfer mode, or SCSI LUN identifier.  
- This routine is likely called during boot or I/O operations to move data between main memory and peripherals (e.g., SCSI or serial).

---

### Function at 0x805bf0

**Embedded strings:**
- `8412483`: `"P @/"`
- `8412702`: `"N^NuNV"`
- `8412846`: `"[2Hx"`
- `8412948`: `"[2Hx"`
- `8413099`: `"RBSJ"`
- `8413116`: `"fH(9"`
- `8413181`: `"RBSS"`
- `8413256`: `"fH(9"`
- `8413321`: `"RBSS"`
- `8413368`: `"N^NuNV"`
- `8413706`: `"N^Nu"`

**Name**: `scsi_command_execute` (or `scsi_operation_handler`)

**Purpose**: This function handles SCSI command execution for the Plexus P/20's DMA processor. It manages SCSI command setup, data transfer, error handling, and coordination with the Job processor via IPC (Inter‑Processor Communication). The function appears to be the main SCSI driver routine that processes SCSI opcodes (like READ, WRITE, TEST UNIT READY, etc.), performs DMA transfers, checks status, and reports errors through the debug monitor.

**Parameters**:
- `%d7` (lower byte): SCSI command opcode (e.g., 0x02 = READ, 0x03 = WRITE, 0x04 = TEST UNIT READY, 0x41 = FORMAT, 0x83 = VERIFY).
- `%fp@(8)` (first stack argument): Likely a pointer to a SCSI command block or buffer address.
- `%fp@(18)` (word): Possibly a block count or transfer length parameter.

**Returns**:
- `%d0` (or `%d5`/`%d7` in sub‑paths): Status/error code (0 = success, non‑zero error codes 1‑8, 15).
- Side effects: Updates shared memory areas (0xC0xxxx), hardware registers (0xE0xxxx), and SCSI controller state.

**Key Operations**:
- Masks SCSI opcode to lower byte (0xFF) and validates against known opcodes (2, 3, 4, 0x41, 0x83).
- Calls debug output functions (0x800e10) to print status strings like "P @/", "N^NuNV", etc., which appear to be encoded debug messages.
- Accesses shared memory locations:
  - 0xC00644: Flag indicating if debug/verbose mode is enabled.
  - 0xC00444‑0xC00454: SCSI transfer parameters (address, count, control).
  - 0xC00648: Expected SCSI status/phase.
  - 0xC006dd: SCSI timeout or retry count.
- Performs IPC with the Job processor via functions at 0x801816, 0x800ce0, 0x800d02.
- Programs the OMTI 5200 SCSI controller via memory‑mapped registers (e.g., sets command, block count, DMA address).
- Handles SCSI phases: selection, command, data, status.
- Uses hardware registers:
  - 0xE00016 (System control): Boot.DMA, DIS.MAP bits.
  - 0xE00018 (Processor control): KILL.JOB, KILL.DMA.
  - 0xE000A0/C0: Reset/Set DMA processor software interrupt.
  - 0xE00140: Reset DMA processor bus error flag.
- Implements timeout loops and error recovery (bus error, parity error, SCSI bus busy).
- Calls `0x80155a` (SCSI initialization) and `0x8010d0` (SCSI start transfer).
- In the second large block (0x805e22‑0x8060ba), it performs a data transfer loop, checking for SCSI bus errors (0xC00652) and using `0x8056d2` (SCSI data transfer) and `0x80144c` (memory copy/verify).
- The final block (0x8060bc‑0x80620c) handles a special case for opcode 0xA529 (likely a diagnostic or control command), manipulating hardware registers for DMA setup and performing memory tests via `0x8025b4` and `0x8039ca`.

**Called Functions**:
- `0x800f06`: Returns processor identity (DMA vs. Job) or SCSI status.
- `0x800e10`: Debug string output (print).
- `0x801246`: Unknown (cleanup or delay).
- `0x80155a`: SCSI controller initialization.
- `0x807510`: Formatted debug output (printf‑style).
- `0x8010d0`: Start SCSI transfer.
- `0x801816`: IPC command to Job processor.
- `0x8005e0`: Delay (parameter = 10 → likely 10 ms).
- `0x800e04` / `0x800df8`: Enable/disable interrupts or set hardware state.
- `0x800d02`: IPC acknowledgment.
- `0x800ce0`: IPC send.
- `0x804ff6` / `0x805b32`: SCSI bus reset/clear.
- `0x8056d2`: SCSI data transfer routine.
- `0x80144c`: Memory copy or compare.
- `0x8058f4`: SCSI status check.
- `0x805b9e`: Hardware register setup.
- `0x8055ce`: SCSI command phase.
- `0x8025b4`: Memory test/verify (called with size 0x40000).
- `0x8039ca`: Another memory test/verify routine.

**Notes**:
- The function is large (421 instructions) and clearly the core SCSI command processor for the DMA processor.
- Uses many hardcoded addresses in the 0xC0xxxx range for shared variables between DMA and Job processors (e.g., 0xC006ba, 0xC006be, 0xC006c2).
- The debug strings are obfuscated (likely to save ROM space) but appear to indicate SCSI phases: "P @/" may be "PHASE?", "N^NuNV" may be "NO DEVICE" or "NOT READY".
- Error codes in `%d5`/`%d7` range from 1‑8 and 15, possibly corresponding to SCSI sense keys or internal error states.
- The special opcode 0xA529 triggers a memory test path, suggesting this function also handles diagnostic commands from the debug monitor.
- The code is highly dependent on the OMTI 5200 SCSI controller's programming model (command, block count, DMA address registers at offsets in the 0xC00370‑0xC003CC region).
- There is careful handling of bus errors and timeouts, indicating robustness for real‑time operation.

---

### Function at 0x80621a

**Embedded strings:**
- `8413976`: `"N^NuNV"`
- `8414000`: `"5@&|"`
- `8414152`: `"N^NuNV"`
- `8414192`: `"N^NuNV"`
- `8414226`: `"i N^NuNV"`
- `8414443`: `"\nf$J"`
- `8414610`: `"5@p\n!@"`
- `8414622`: `"5@!K"`
- `8414649`: `"\nfnJ"`
- `8414657`: `"Dgfp"`
- `8414790`: `"N^NuNV"`
- `8414918`: `"N^NuNV"`

**Name**: `scsi_command_execute`  

**Purpose**:  
This function handles the execution of a SCSI command on the Omti 5200 controller. It initializes the SCSI controller, sends a command block, waits for completion, processes the result, and logs details if debugging is enabled. The function appears to be part of the DMA processor’s SCSI driver, managing command setup, data transfer, and error handling.

**Parameters**:  
- Inputs are passed via memory locations in the shared RAM area (`0xC0xxxx`), particularly `0xC00822` (command block pointer or length), `0xC0083A` (data direction flag), `0xC00858` (SCSI target ID/LUN), and `0xC0085E` (control register value).  
- Register `A4` points to a command structure at `0x803540` (likely a SCSI Command Descriptor Block).  
- Register `A3` points to `0xC00846` (data buffer or status area).  

**Returns**:  
- Returns a status byte in `D0` from `0xC00846` (SCSI status or error code).  
- Sets `0xC00842` to 1 on successful completion.  
- Updates `0xC008F0` with a completion code (-1 for success, other values for errors).  

**Key Operations**:  
- Sets bit 13 (0x2000) in the system control register `0xE00016` (likely enables SCSI or DMA).  
- Clears SCSI-related memory areas (`0xC00842`, `0xC008B8`, `0xC008BA`).  
- Writes to Omti 5200 controller registers at `0xD00015` and `0xD00017` (command/status).  
- Waits for SCSI controller ready by polling `0xD00015` bit 7.  
- Builds a SCSI command packet from the structure at `0x803540` and writes it to `0xA70000` (SCSI data register).  
- Waits for SCSI interrupt by polling `0xE0000E` bit 1 or checking a timeout counter.  
- On completion, reads SCSI status from `0xA70003` and stores it in `0xC00846`.  
- If debugging is enabled (`0xC006DE` non-zero), logs strings via `0x807510`.  
- On error, calls delay or error-handling routines (`0x80685a`).  

**Called Functions**:  
- `0x800f06` – unknown (likely hardware initialization check).  
- `0x8054fa` – error handler or debug output.  
- `0x805656` – delay or SCSI controller reset.  
- `0x80685a` – error/delay routine.  
- `0x804ff6` – idle loop or wait function.  
- `0x8058f4` – SCSI cleanup or status read.  
- `0x806920` – SCSI command setup or buffer initialization.  
- `0x8066ca` – SCSI phase change or status check.  
- `0x800d22` – memory copy or buffer fill.  
- `0x800e10` – debug printf-style output.  
- `0x807510` – debug logging (string output).  

**Notes**:  
- The function uses a shared memory region at `0xC0xxxx` for communication between the DMA and Job processors.  
- The Omti 5200 controller is accessed via addresses `0xD000xx` (control) and `0xA70000` (data).  
- There is a timeout mechanism (counting to 1000) to prevent hanging on SCSI bus busy.  
- Debug output is conditional on `0xC006DE` being non-zero, suggesting a diagnostic mode.  
- The function handles both data-in and data-out phases based on `0xC0083A`.  
- Strings referenced (e.g., `"N^NuNV"`, `"5@&|"`) appear to be obfuscated or encoded debug messages.  
- The code at `0x80664a`–`0x8066c8` is a separate subroutine (likely SCSI interrupt handler or completion routine) that saves SCSI controller register state to `0xC008BC`–`0xC008F0`.

---

### Function at 0x8066ca

**Embedded strings:**
- `8415142`: `"N^NuNV"`
- `8415166`: `"g By"`
- `8415198`: `"`HSy"`
- `8415238`: `"g Sy"`
- `8415278`: `"g Sy"`
- `8415318`: `"N^NuNV"`
- `8415343`: `"\ng\n."`

**Name**: `configure_dma_transfer` (or `setup_scsi_dma`)

**Purpose**: This function configures DMA parameters for a SCSI transfer based on a device ID parameter, sets up hardware control registers, and initializes a timeout mechanism. It appears to be part of the DMA processor's SCSI I/O subsystem, preparing for a data transfer operation by programming the DMA controller's source/destination addresses and device-specific parameters, then starting the transfer with appropriate hardware signaling.

**Parameters**: 
- `%d7` (long): SCSI device/LUN identifier (passed via stack at `%fp@(8)`). This value selects which set of DMA parameters to use.

**Returns**: 
- No explicit return value in registers.
- Modifies hardware registers: writes to `0xE0000E` (DMA control), `0xA70000` (SCSI DMA data port?), and sets flags in shared RAM at `0xC0085C`, `0xC0085E`, `0xC0085F`, `0xC008F0`.

**Key Operations**:
- Checks if shared RAM location `0xC006DE` is non-zero; if so, calls a function (likely debug/error output) with a hardcoded value `0x807DB9`.
- Clears and sets bits in the DMA control word at `0xC0085C` based on a table lookup indexed by the device ID (table at `0x80620E` contains 16-bit control values).
- Checks a memory location (`0x803540+2`) and sets bit 4 of `0xC0085E` if it's >= `0x00C00000`.
- Writes the control word to hardware register `0xE0000E` (DMA processor control register).
- Loads two 32-bit values from tables at `0xC008C0` and `0xC008BC` (indexed by device ID × 8) into what appears to be a DMA controller's address registers (via `%a5`, which points to `0xE00006` – likely a DMA address/control register pair).
- Stores the device ID to `0xC008F0` (current active device).
- If a specific bit is set in the DMA controller's status (bit 0 of byte 3 at `0xE00009`), it reads a byte from either before or after the DMA source address (depending on device ID LSB), combines it into a 16-bit value, and writes it to `0xA70000` (likely a SCSI data FIFO or DMA data port).
- Sets bit 0 of `0xC0085F` and updates the hardware control register again.
- The second part of the function (starting at `0x8067AA`) is a separate routine that handles timeouts: it decrements counters at `0xC008B8`, `0xC008BA`, and `0xC008EE` (likely transfer timeout, command timeout, and another timeout), and when any reaches 1, it calls a function at `0x80685A` (likely a timeout handler) with a code (0xB, 0xC, or 0x13). It also clears the DMA clock interrupt flag at `0xE00100`.

**Called Functions**:
- `0x807510` – if `0xC006DE` != 0 (likely debug output or error handler)
- `0x8066CA` – recursive call with argument 2 (when `0xC008B8` timeout expires and bit 1 of `0xE0000E` is set)
- `0x80685A` – timeout handler called with codes 0xB, 0xC, or 0x13 depending on which counter expires

**Notes**:
- The function uses `%a5 = 0xE00006` and `%a4 = 0xE0000E`, which are hardware control registers for DMA operations.
- The byte read at `0x80676E` or `0x80677A` suggests the DMA controller might support automatic byte assembly into 16‑bit words for SCSI transfers (SCSI is 8‑bit, but the DMA may be 16‑bit).
- The timeout routine appears to be an interrupt‑service routine (called from a clock interrupt?) that manages multiple timeout counters for different aspects of SCSI operations.
- The strings referenced are not directly used in this function; they may belong to nearby code (possibly debug messages in the timeout handler or called functions).
- The recursive call at `0x8067D6` suggests that when a primary timeout (`0xC008B8`) expires and a specific hardware flag is set, the DMA transfer is re‑initialized with device ID 2 (possibly a retry or fallback device).

---

### Function at 0x80685a

**Embedded strings:**
- `8415343`: `"\ng\n."`
- `8415457`: `"d`8."`
- `8415516`: `"N^NuNV"`

**Name**: `handle_diagnostic_command`  

**Purpose**: This function processes a diagnostic command code (likely from a debug monitor or self‑test menu) by performing specific actions based on the command number. It first clears a status word, checks a shared memory flag, prints system status information, and then dispatches to one of several command handlers via a jump table. The handlers print different error or informational strings and then call a common cleanup/return routine.

**Parameters**:  
- `%fp@(8)` (the first argument on the stack) – a 32‑bit integer command code (values 11–20 map to jump‑table entries).  

**Returns**:  
- No explicit return value; side effects include writing to `0xc00640`, printing to console, and possibly invoking other routines.

**Key Operations**:  
- Clears the word at `0xc00640` (likely a status/flag location in shared RAM).  
- Calls `0x8058f4` (unknown subroutine).  
- Tests the longword at `0xc0080a`; if non‑zero, calls `0x800ed6` with the command argument.  
- Reads the word at hardware register `0xe0000e` (unknown system status) and prints it along with the longword at `0xc0085c` using format string at `0x807dc4`.  
- Subtracts 11 from the command argument and compares to 9; if out of range, jumps to default case (prints `"g\n."` at `0x807e19`).  
- Uses a jump table at `0x8068b6` to dispatch to one of five command handlers (each prints a different string).  
- All paths eventually call `0x800664` (likely a common exit/loop routine).

**Called Functions**:  
- `0x8058f4` – unknown subroutine.  
- `0x800ed6` – called if `0xc0080a` ≠ 0 (possibly a debug output routine).  
- `0x800e10` – printf‑style routine (takes format string and arguments).  
- `0x807510` – prints the string `"g\n."` (default case).  
- `0x800664` – common exit/cleanup routine.

**Notes**:  
- The jump table at `0x8068b6` contains branch offsets relative to the table start; the offsets correspond to command values 11–20, but only five distinct handlers exist (some offsets are reused).  
- The strings printed are likely error messages or diagnostic results:  
  - `0x807ddb` (case 11)  
  - `0x807def` (case 12)  
  - `0x807dfb` (case 13)  
  - `0x807e0c` (case 14)  
  - default `0x807e19` (`"g\n."`)  
- The hardware read from `0xe0000e` may be a system status or error register; its value is displayed as part of the initial diagnostic output.  
- The function appears to be part of the U17 debug monitor’s command interpreter, handling a subset of diagnostic commands.

---

### Function at 0x806920

**Embedded strings:**
- `8415710`: `"N^NuNV"`

**Name**: `dma_processor_interrupt_handoff`  

**Purpose**:  
This function appears to manage the handoff of control between the DMA processor and the Job processor, likely during boot or diagnostic mode transitions. It validates system status, updates shared memory structures, and conditionally triggers a memory-mapped I/O operation before calling a lower-level handoff routine. The function ensures the DMA processor is in a valid state before proceeding and updates interrupt or control registers based on shared RAM values.

**Parameters**:  
- One 32-bit parameter passed on the stack at `%fp@(8)`, which is compared against values in `0xc008f0` and the literal `3`. This likely represents a command or state code (e.g., boot phase identifier).

**Returns**:  
- No explicit return value; side effects include writes to hardware registers (`0xe0000e`), updates to shared memory (`0xc0085c`, `0xc008bc`–`0xc008c0` area), and a possible I/O write to `0xa70000`.

**Key Operations**:  
- Reads system status from `0xe0000e` and masks with `0x30a1` (bits 13–12, 8, 6, 0), comparing to `0x3081` (likely checking DMA/JOB enable and interrupt flags).  
- Calls `0x80685a` with argument `9` if status mismatch, and with argument `10` if the parameter matches `0xc008f0`.  
- Checks if the parameter equals `3`; if so, exits early.  
- Clears bit 0 of shared memory location `0xc0085c` (using `AND.L #-2`).  
- Writes `0xc0085e` to hardware register `0xe0000e` (system control/status).  
- Uses `%d7` (from `0xc008f0`) as an index to compute addresses in shared memory blocks at `0xc008bc` and `0xc008c0`, copying two 32-bit values from `%a5` (`0xe00006`) into these tables.  
- If bit 0 of the third byte at `%a5@(3)` is set **and** `%d7` is odd, writes a byte from `0xa70000` to the address pointed to by the first `%a5` value, offset by `-1`.  
- Calls `0x8066ca` with the original parameter.

**Called Functions**:  
- `0x80685a` — called twice with arguments `9` and `10` (likely error/status reporting).  
- `0x8066ca` — called at the end with the input parameter (core handoff routine).

**Notes**:  
- `%a5` is set to `0xe00006`, which is in the hardware register space (possibly a DMA or IPC control block).  
- The shared memory area `0xc008bc`–`0xc008c0` appears to be a table of 8-byte entries indexed by `%d7`; each entry holds two 32-bit values sourced from hardware registers.  
- The conditional write to `0xa70000` (a memory-mapped I/O address not in the provided map) suggests a device-specific poke, possibly related to SCSI or serial control.  
- The early exit when the parameter equals `3` may indicate a “no-op” or “skip handoff” command.  
- The function likely implements part of the Plexus dual-processor boot sequence, where the DMA processor sets up Job processor state before passing control.

---

### Function at 0x8069e2

**Embedded strings:**
- `8415952`: `"N^NuNV"`
- `8416194`: `" @ ("`
- `8416220`: `"fj"9"`
- `8416242`: `" @ ("`
- `8416468`: `"N^NuNV"`

**Name**: `scsi_probe_devices`  

**Purpose**: This function performs a SCSI bus scan to detect and identify attached devices (likely disks and floppies). It iterates through possible SCSI IDs (0–7) and LUNs (0–3), checking device presence and readiness by reading SCSI controller registers. It logs detected devices via a debug output function if verbose mode is enabled, and returns a device code or error number.  

**Parameters**:  
- Inputs are passed via the stack (since it’s called with `jsr` after pushing arguments):  
  - `fp@(8)`  — Likely a SCSI ID or device-select parameter  
  - `fp@(12)` — Likely a LUN (Logical Unit Number)  
  - `fp@(16)` — Possibly a flag (e.g., retry or verbose flag)  
- Global memory references:  
  - `0xc00846`, `0xc00848` — SCSI status/command bytes  
  - `0x80353c` — Base address for SCSI controller registers (Omti 5200)  

**Returns**:  
- `%d0` — A result code:  
  - `0` on success or no device  
  - Non-zero error or device identifier (e.g., `6 * ID + LUN + 6` or `ID + 38/46` for special cases)  

**Key Operations**:  
- Writes `0xff` to `0xc00846` (SCSI command/select register).  
- Toggles hardware register `0xe0000e` (likely resets SCSI parity error or bus error flag).  
- Clears `0xc0083a` (SCSI-related memory).  
- Configures SCSI controller registers at `%a5` (`0x80353c`) by masking and setting bits for ID/LUN selection.  
- Calls subroutines at `0x800ee2`, `0x800ec8`, `0x800ef6` (SCSI low‑level commands, e.g., bus arbitration, selection, status read).  
- Checks `0xc00846` and `0xc00848` for SCSI status (busy, command complete, etc.).  
- Recursively calls itself (`0x8069e2`) when certain status conditions are met (e.g., `0x70` in `0xc00848` and no retry flag).  
- Loops over SCSI IDs 0–7 and LUNs 0–3, reading controller data structures at offset `38` from `%a5` to determine device type and LUN readiness.  
- If verbose flag (`0xc00644` non‑zero) is set, calls debug print function (`0x807510`) with strings from ROM (e.g., `" @ ("`, `"fj\"9"`, `"N^NuNV"`).  
- Restores original SCSI ID (`0xc00858`) and clears `0xc0080a` (SCSI operation flag) before returning.  

**Called Functions**:  
- `0x800ee2` — SCSI bus initialization or arbitration  
- `0x800ec8` — SCSI selection or command phase  
- `0x800ef6` — SCSI status read  
- `0x8069e2` — Recursive self‑call (with different parameters)  
- `0x800f06` — Unknown (possibly hardware check)  
- `0x8054fa` — Error handling or debug output  
- `0x8038d4` — System state check  
- `0x807510` — Debug string print (called with ROM string addresses)  
- `0x806f94` — Possibly sets up SCSI scan mode  

**Notes**:  
- The function uses a recursive call to handle a specific SCSI status (`0x70` in `0xc00848`), which may indicate a “check condition” requiring retry.  
- Device detection logic examines controller data at `%a5@(38 + 6*ID)` — a structure with 3 words: word0 bits 16–23 = device type, word1 bits 16–23 = LUN availability mask, word2 bits 16–23 = LUN ready mask.  
- Return codes encode device location: `6 * ID + LUN + 6` for ready LUNs, `ID + 38` for present but no ready LUN, `ID + 46` for no device.  
- Hardware register `0xe0000e` is cleared twice (once early, once before return) — likely resets an interrupt or error flag for SCSI operations.  
- The function preserves the original SCSI ID (`0xc00858`) across scans, suggesting it’s used by higher‑level boot or diagnostic code.

---

### Function at 0x806cd8

**Embedded strings:**
- `8417168`: `"N^NuNV"`

**Name**: `selftest_scsi_devices`  

**Purpose**:  
This function performs a diagnostic self-test of the SCSI subsystem, checking the status of the SCSI controller and attached devices. It reads hardware registers to verify SCSI ID configuration, tests each SCSI device (likely up to 8 devices, skipping the host controller at ID 0), and reports any mismatches or errors. If all tests pass, it prints a success message; otherwise, it prints detailed error messages for each failing component and returns a failure status.

**Parameters**:  
- No explicit parameters passed via stack or registers.  
- Uses global data pointer in `%a5` (set to `0x00d0001c`), which likely points to a hardware/status table in shared RAM.  
- Reads from shared memory locations like `0xc00858` (current SCSI device ID) and `0xc0080a` (test flag).  

**Returns**:  
- `%d0` = 0 if the self-test failed, 1 if it passed.  

**Key Operations**:  
- Calls `0x800f06` (likely a system initialization or hardware check).  
- Reads SCSI controller status from `%a5@(34)` (offset 0x22) and masks bits to verify SCSI ID configuration.  
- Tests SCSI device presence by writing to `0xc00858` and calling `0x8069e2` (SCSI device test subroutine).  
- Uses XOR and OR operations to accumulate error flags in `%d4`.  
- Reads random values via `0x80139a` (likely a random number generator) and compares them to hardware register values.  
- Prints diagnostic strings using `0x807510` (print function) for errors and status.  
- Resets hardware flags (e.g., writes `0` to `0xe0000e`).  
- Calls `0x8038d4` (unknown system check).  
- At the end, delays with `0x80155a` (likely a sleep/delay function) for 15 units.  

**Called Functions**:  
- `0x800f06` – unknown system check  
- `0x8054fa` – error/print function (called on initial failure)  
- `0x807510` – print string function  
- `0x805888` – read/write SCSI register?  
- `0x805820` – SCSI command/status function  
- `0x8069e2` – test individual SCSI device  
- `0x80139a` – random number generator  
- `0x8038d4` – system check  
- `0x80155a` – delay function  

**Notes**:  
- The function skips SCSI ID 0 (likely the host controller) in loops (`1 << ID != 8`).  
- Error messages are printed using strings at addresses `0x807e7a`, `0x807e94`, `0x807e99`, `0x807e9f`, `0x807ea5`, `0x807eac`, `0x807eb5`, `0x807ecf`, `0x807ed4`, `0x807eda`, `0x807ee0`, and `0x807ee7`.  
- The function uses a shared memory location `0xc0080a` as a test flag (set to 1 during testing, cleared afterward).  
- It appears to be part of the U17 ROM’s self-test suite, specifically for SCSI subsystem validation during boot or diagnostic mode.

---

### Function at 0x806f94

**Embedded strings:**
- `8417342`: `"g^ -"`
- `8417529`: `"Dg& -"`
- `8417621`: `"Dg& -"`
- `8417688`: `"`. -"`
- `8417788`: `"g^ -"`
- `8417802`: `"fP&L6"`
- `8417831`: `"p~\nJSg"`
- `8417855`: `"Dgnp"`
- `8417878`: `"gFpa`D"`
- `8417892`: `"&H9|"`
- `8417948`: `"`"pi/"`
- `8417990`: `"N^Nu"`

**Name**: `scsi_dma_transfer`  

**Purpose**:  
This function performs a SCSI data transfer operation using the OMTI 5200 controller, likely for reading or writing a block of data. It handles DMA processor setup, SCSI command issuance, and error checking with timeouts. The function appears to support two modes based on an input parameter: one for immediate command execution and another for deferred or polled operation. It also manages hardware control registers (LEDs, interrupts, bus arbitration) and logs diagnostic messages if the system debug flag is set.

**Parameters**:  
- `%fp@(8)` (stack parameter): An integer flag (0, 1, or >1) that selects the transfer mode or polling behavior.  
- Implicit hardware context:  
  - `%a5` = `0x00D0001C` (points to a hardware status/control register block, likely the OMTI 5200 controller registers).  
  - `%a4` = `0x007FF900` (points to a DMA or buffer control register area).  
  - `%a2` = `0x00E00016` (system control register at `0xE00016`).  

**Returns**:  
- `%d0`: Status code (0 = success, 1–5 = error codes indicating various SCSI/timeout failures).  
- `%d6`: Possibly a retrieved data word or error detail from the SCSI controller (set in polling loop).  

**Key Operations**:  
- Reads OMTI controller status registers at offsets 30 and 32 (`%a5@(30)`, `%a5@(32)`) to check command phase and target status.  
- Modifies system control register (`%a2@`) to enable/disable interrupts, DMA, or other hardware features (using `ORIW`/`ANDIW` masks like `#16`, `#-801`, `#-33`).  
- Calls `0x805b9e` (likely a DMA setup or buffer initialization routine) with parameters `(1, 0x7FF)`.  
- Issues SCSI commands via `0x805820` with a command block pointer; the command block is selected based on a status field (offset 32, bits 16–23).  
- Uses `0x8005e0` for delay loops (parameter = delay count).  
- Polls a hardware register (`%a4@(6)` or `%a3@`) for completion, with timeouts and retries.  
- If debug flag at `0xC00644` is non‑zero, prints diagnostic strings via `0x800e10` (e.g., `"g^ -"`, `"Dg& -"`, `"fP&L6"`).  
- On errors, returns non‑zero codes and may log messages indicating SCSI target “a” (active?) or “i” (inactive?).  

**Called Functions**:  
- `0x805b9e` (DMA/buffer setup)  
- `0x805820` (SCSI command submission)  
- `0x8005e0` (delay/wait function)  
- `0x80747c` (unknown helper, called with argument `0x44` or `0x45`)  
- `0x800e10` (debug string printer, only called if `0xC00644` ≠ 0)  

**Notes**:  
- The function references two command block pointers at the end of the code (`0x8072ca` and `0x8072ce`), which contain the values `0xFF6F` and `0xFFBF`. These likely point to SCSI command sequences (e.g., read/write command blocks).  
- The code distinguishes between two SCSI target states based on bits 16–23 of `%a5@(32)`: if non‑zero, it uses command block for target “a” (probably active drive), otherwise for target “i” (inactive or default).  
- There are multiple exit paths with different status codes:  
  - 0: early success (no transfer needed)  
  - 1: success after immediate command  
  - 2: error in command submission  
  - 3: timeout waiting for command completion  
  - 4: (not seen in this segment)  
  - 5: error in polled mode  
- The function preserves many registers (`%d5‑%d7`, `%a2‑%a5`) and allocates a 32‑byte stack frame, suggesting it is a high‑level driver routine called from the DMA processor’s main loop.

---

### Function at 0x8072d2

**Embedded strings:**
- `8418076`: `"``p_"`
- `8418180`: `"N^NuNV"`

**Name**: `debug_monitor_input_loop`  

**Purpose**:  
This function implements a debug monitor input loop that processes serial input characters, handles special control codes (like ASCII 95 and 126), and dispatches commands or actions based on input. It appears to be part of the U17 ROM’s interactive debug interface, possibly invoked after self‑test or during system debugging. The loop reads from a serial port (likely the console), checks for escape or control sequences, updates internal state, and may trigger jumps to other monitor functions.

**Parameters**:  
- `%fp@(8)` (likely a pointer or argument passed from caller, possibly a command buffer or status flag).  
- Global memory locations: `0xc007f2`, `0xc0082e`, `0xc007fe`, `0xc006d6` (system/debug variables).  

**Returns**:  
- No explicit return value; function loops until a break condition (e.g., character 126) triggers a jump elsewhere.  
- Modifies `%d6` and `%d7` (scratch/state registers).  

**Key Operations**:  
- Calls `0x807388` (likely an initialization or validation routine) and checks result.  
- Writes `#8421161` (string pointer `"``p_"` at address `0x807f29`) to stack and calls `0x807510` (probably a print function).  
- Sets `0xc0082e` to 1 (a flag, perhaps “debug mode active”).  
- Clears `0xc007fe` (reset some status).  
- Calls `0x8076ba` with argument 10 (ASCII newline) — likely serial output.  
- Reads character from port `0x43` (call to `0x80747c` — serial input routine).  
- If input is 95 (`_`), treat as 127 (DEL/rubout?).  
- If input is –1 (no character), reset `%d6` to 0.  
- Reads character from port `0x42` (another serial port or status).  
- If `%d6` is zero, loads value from `0xc006d6` and calls `0x807882` (maybe a command lookup).  
- If `%d6` becomes 126 (`~`), calls `0x807388` with NULL argument and jumps back to print loop.  

**Called Functions**:  
- `0x807388` — unknown (validation/init).  
- `0x807510` — print string (takes pointer from stack).  
- `0x8076ba` — output character (argument on stack).  
- `0x80747c` — read character (argument is port ID).  
- `0x807882` — command handler or lookup.  

**Notes**:  
- The port numbers `0x43` and `0x42` likely correspond to SCC channel control/status registers (e.g., port A data/control).  
- Character 95 (`_`) is remapped to 127 (DEL), suggesting backspace handling in raw terminal mode.  
- Character 126 (`~`) acts as a restart or escape sequence — it resets the loop by calling `0x807388` with a NULL argument and re‑entering the print/jump section.  
- The string `"``p_"` at `0x807f29` may be a prompt or debug header.  
- Global variable `0xc006d6` might hold a command table pointer or last entered command.  
- The function mixes serial I/O with monitor command dispatch, typical of a lightweight debug monitor in firmware.

---

### Function at 0x807388

**Embedded strings:**
- `8418292`: `"`~*|"`
- `8418306`: `"lFHx"`
- `8418408`: `"`\n;|"`
- `8418424`: `"N^NuNV"`

**Name**: `scsi_select_and_init`  

**Purpose**:  
This function appears to handle SCSI device selection and initialization, likely for booting or diagnostic operations. It configures system control registers, selects a SCSI target based on a parameter, initializes SCSI controller registers (via writes to a memory‑mapped I/O area at 0x7FF900), and optionally triggers a SCSI operation. The function may be part of the DMA processor’s boot‑time SCSI setup or a debug‑monitor command for SCSI interaction.

**Parameters**:  
- One 32‑bit parameter passed on the stack at `%fp@(8)`. This seems to be a selection flag or device identifier (0, 1, or >1).  
- Implicitly uses the global variable at `0xC007F2` (likely a SCSI target/LUN index).  

**Returns**:  
- `%d0` = 0 on success, –1 on failure (e.g., if a called function fails, or if the parameter is non‑zero and a subsequent SCSI operation fails).  

**Key Operations**:  
- Sets bit 4 (likely `Boot.DMA` or a similar control) and clears other bits in the system control register at `0xE00016`.  
- Calls a subroutine at `0x805B9E` with arguments 1, 1, 0x7FF (possibly SCSI controller initialization).  
- Clears the longword at `0xC0082E` and sets `0xC007FE` to 1 (global state variables).  
- Uses `0xC007F2` as an index into a table at `0x8072CA` (contains SCSI‑related pointers, possibly command blocks or device info).  
- If the input parameter > 1, writes to SCSI controller registers at `%a5` = `0x7FF900` (Omti 5200 base address):  
  - Writes 0x40 to offset 2 (SCSI command/select register).  
  - Writes 0xFF to offset 6 (maybe timeout or data pattern).  
  - Writes 0xFF to offset 0 (SCSI data out).  
- If the input parameter is non‑zero, calls `0x80747C` with argument 0x40 (likely a SCSI command phase).  
- If the input parameter is zero, writes 0x41 to offset 2 of the SCSI controller (different select/command value).  

**Called Functions**:  
- `0x805B9E` – SCSI‑related setup routine.  
- `0x805820` – Takes a pointer from the table at `0x8072CA`; likely validates or prepares a SCSI command block.  
- `0x8005E0` – Delay function (called with 0x168 = 360 and 0x3C = 60, presumably for timing waits).  
- `0x80747C` – SCSI operation function (called with argument 0x40).  

**Notes**:  
- The SCSI controller base address `0x7FF900` matches the Omti 5200 memory mapping (not in the provided memory map, but consistent with separate SCSI controller space).  
- The table at `0x8072CA` (offset from `0x8072CA` = `0x8417994`) likely holds pointers to SCSI command blocks for different LUNs/targets.  
- The function distinguishes three cases for the input parameter:  
  - 0 → final SCSI register write uses value 0x41.  
  - 1 → skips the extra SCSI register writes and the call to `0x80747C`.  
  - >1 → performs full SCSI register initialization and calls `0x80747C`.  
- This is probably called from the debug monitor’s SCSI‑related commands (maybe ‘S’ for “SCSI select” or similar).

---

### Function at 0x80747c

**Embedded strings:**
- `8418554`: `"N^Nu0123456789ABCDEF"`
- `8418590`: `"x<`\nSDg"`

**Name**: `scsi_command_with_timeout`

**Purpose**: This function sends a SCSI command to the Omti 5200 controller and waits for completion with a configurable timeout. It writes command bytes to the controller's registers, polls for command completion, reads back status/result bytes, and returns a result code. The timeout duration changes based on the first byte of the SCSI command (parameter 1), suggesting different timeouts for different SCSI operations.

**Parameters**: 
- `%fp@(8)` (long): First byte of SCSI command (determines timeout)
- `%fp@(10)` (word): Data written to register at offset 2 (likely SCSI command/data register)
- `%fp@(14)` (word): Data written to register at offset 6 (likely SCSI target/LUN or control register)

**Returns**: 
- `%d0` (long): Result value:
  - `0xFFFF` if timeout occurred (register at offset 0 reads 0xFF at completion)
  - Otherwise, the word value read from register at offset 6 after command completion

**Key Operations**:
- Sets `%a5` to hardware address `0x007FF900` (Omti 5200 controller registers)
- Writes parameter words to controller registers at offsets 2 and 6
- Writes `0xFF` to register at offset 0 (likely command/status register) to initiate operation
- Implements timeout loop: if first command byte is 'B' (0x42) or 'C' (0x43), uses 12,288 iterations; otherwise uses 1,048,576 iterations
- Polls register at offset 0 for non-zero value (command completion)
- If timeout expires before completion, writes error code 70 (0x46 = 'F') to register at offset 2
- After completion, waits additional 768 iterations (likely for bus settling)
- Reads result from register at offset 6
- If register at offset 0 contains 0xFF at completion, returns -1 (timeout); otherwise returns the result word
- Clears register at offset 0 before returning

**Called Functions**: None (no `jsr` or `bsr` instructions in this code segment)

**Notes**:
- The hardware address `0x007FF900` matches the Omti 5200 SCSI controller's register space (mapped in the Plexus memory map)
- Register offsets: 0=command/status, 2=command/data, 6=target/LUN/result
- The timeout logic suggests 'B' and 'C' commands (possibly SCSI block read/write) get shorter timeouts than other commands
- The function appears robust with proper register preservation (`moveml` saves/restores `%d5`, `%d7`, `%a5`)
- The code at `0x8074fe-0x80750e` appears to be embedded data (ASCII "0123456789ABCDEF") rather than executable code, possibly a lookup table for hex conversion used elsewhere
- This is a low-level SCSI controller driver function used by higher-level boot/disk routines

---

### Function at 0x80765a

**Embedded strings:**
- `8418998`: `"N^NuNV"`
- `8419052`: `"f Hx"`

**Name**: `print_hex_nibbles`  

**Purpose**:  
This function takes a 32-bit integer input and prints its hexadecimal representation by extracting and outputting individual nibbles (4-bit groups). It first determines how many nibbles are needed to represent the number (skipping leading zeros), then iterates over each nibble from most significant to least significant, converting each to an ASCII character via a lookup table and calling a character-output subroutine.  

**Parameters**:  
- `%d7` (32-bit): The integer value to be printed in hexadecimal. Passed via the stack at `%fp@(8)`.  

**Returns**:  
- No explicit return value; side effect is printing characters (likely to a serial console or debug output).  

**Key Operations**:  
- Computes the number of significant nibbles (1–8) needed to represent the input value, storing the count in `%d5`.  
- Uses a lookup table at address `0x8074fe` (8418558 decimal) to map nibble values (0–15) to ASCII characters.  
- Calls a subroutine at `0x8076ba` (likely a character-printing routine) for each nibble.  
- Rotates the input value left by 4 bits after processing each nibble to bring the next nibble into the least-significant position.  

**Called Functions**:  
- `0x8076ba`: A subroutine that presumably outputs a single character (based on the argument pushed on the stack).  

**Notes**:  
- The lookup table at `0x8074fe` likely contains the 16 ASCII characters for hexadecimal digits (0–9, A–F or a–f).  
- The function avoids printing leading zeros by first calculating the number of significant nibbles.  
- The loop structure suggests it is designed for a debug or diagnostic output routine, consistent with the U17 ROM’s self-test/debug monitor purpose.  
- The code uses `%d5` to track the number of nibbles to print and `%d6` as the loop counter.  
- The string references in the prompt (`"N^NuNV"` at 8418998 and `"f Hx"` at 8419052) are not directly used in this function; they may belong to adjacent code or other diagnostic strings.

---

### Function at 0x8076ba

**Embedded strings:**
- `8419052`: `"f Hx"`
- `8419090`: `"N^NuNV"`
- `8419126`: `"`v ."`
- `8419152`: `"g2r!"`

**Name**: `serial_send_char_with_delay`  

**Purpose**:  
This function transmits a character to a serial port (likely the console SCC) after waiting for the transmitter to be ready, and optionally inserts a delay after sending a linefeed (ASCII 10) by recursively calling itself 10 times with a null argument. It ensures proper flow control by polling a hardware status bit before writing the character, and implements a simple pacing mechanism for linefeeds to prevent overrun on slow terminals or emulated serial links.

**Parameters**:  
- `%fp@(8)` (long): Character to send (only low byte used).  
- `%fp@(11)` (byte): Possibly a secondary parameter (e.g., port select), but only the low byte is written to the hardware register.  

**Returns**:  
No explicit return value; all modified registers (`%d7`) are restored before exit.

**Key Operations**:  
- Calls `0x804ff6` (likely a hardware/stack initialization routine).  
- Polls `0xc006d6` (pointer to a hardware register block) offset `0x0E` until bit 2 is set (transmitter ready flag).  
- Writes the character from `%fp@(11)` to offset `0x12` of the same hardware register block (transmit data register).  
- If the input character equals decimal 10 (linefeed), recursively calls itself 10 times with argument `0xD` (carriage return), then calls itself 10 more times with a null argument (`0`) to create a delay.  

**Called Functions**:  
- `0x804ff6` — Unknown setup routine.  
- Recursive calls to itself (`0x8076ba`) for linefeed handling and delay loops.

**Notes**:  
- The hardware register block at `0xc006d6` likely points to the SCC’s channel registers (e.g., base address for port A). Offset `0x0E` is a status register (bit 2 = transmit buffer empty), and offset `0x12` is the transmit data register.  
- The delay loop for linefeeds sends a carriage return first, then 10 null transmissions, which may serve as a timing delay or software flow control.  
- The function preserves `%d7` on the stack but uses it as a loop counter (10 → 0) for the delay.  
- This is likely part of a debug/monitor console output routine, where linefeeds require extra pacing to ensure proper terminal behavior.

---

### Function at 0x807716

**Embedded strings:**
- `8419126`: `"`v ."`
- `8419152`: `"g2r!"`
- `8419158`: `"g<r*"`
- `8419202`: `"`*~\n`"`
- `8419250`: `"N^NuNV"`

**Name**: `handle_serial_input` or `process_serial_command`

**Purpose**: This function processes a byte of serial input data, interpreting it as a command or control character. It checks the status of the input buffer, masks the byte to 7 bits, and dispatches based on the byte value. Specific values trigger actions like setting LEDs, clearing a shared memory location, and calling system routines (likely for boot, reset, or diagnostic functions). It appears to be part of a debug monitor or command interpreter for the DMA processor's serial console.

**Parameters**: 
- `%fp@(8)` – A pointer to a data structure (likely a serial port buffer or status block). The function checks bit 0 of offset 14 (`%a0@(14)`) to see if data is available, and reads the data byte from offset 18 (`%a0@(18)`).

**Returns**: 
- `%d0` – Returns the processed byte value (masked to 7 bits) if the byte was handled normally; returns 0 if no data was available or if a shared flag (`0xc0064c`) was zero.

**Key Operations**:
- Polls a status bit at offset 14 of the input structure to see if data is ready.
- Checks a shared memory flag at `0xc0064c` (possibly a system halt or abort flag).
- Masks the input byte to 7 bits (clears high bit) using `AND #127`.
- Compares the masked byte to specific values:
  - 13 (carriage return) → maps to value 10 (line feed) in `%d7`.
  - 33 ('!') → calls subroutine at `0x800628`.
  - 42 ('*') → calls subroutine at `0x805ab0`.
  - 127 (DEL) → calls subroutine at `0x800646`.
  - 27 (ESC) → if `0xc0082e` is non-zero, calls `0x8076ba` with `%d7` as argument.
- Writes the final `%d7` value to the LED control register at `0xE00010`.
- Clears `0xc0081e` before calling certain subroutines (likely a shared state/flag).

**Called Functions**:
- `0x8076ba` – Handles ESC or other special character (called with `%d7` as argument).
- `0x800646` – Likely a system reset or diagnostic routine (triggered by DEL).
- `0x800628` – Likely a boot or restart routine (triggered by '!').
- `0x805ab0` – Unknown system function (triggered by '*').

**Notes**:
- The function appears to be a command dispatcher for a debug monitor, where serial input characters trigger different system actions.
- The LED control register write (`0xE00010`) suggests visual feedback for command execution.
- The shared memory location `0xc0064c` may be a system "enabled" flag; if zero, the function returns 0 without processing.
- The clearing of `0xc0081e` before certain calls implies it's a state variable that must be reset before those operations.
- The mapping of carriage return (13) to line feed (10) suggests console input normalization.
- The check for `0xc0082e` before handling ESC (27) indicates an optional escape sequence mode.

---

### Function at 0x8077b6

**Embedded strings:**
- `8419318`: `"g4r\n"`
- `8419324`: `"g(r\r"`
- `8419348`: `"gRr#"`
- `8419454`: `"N^NuNV"`
- `8419510`: `"N^NuTSTS1-f"`

**Name**: `process_escape_sequence`  

**Purpose**:  
This function processes a stream of characters (likely from a serial console input) and interprets special control characters and escape sequences. It handles backspace (0x08), line feed (0x0A), carriage return (0x0D), escape (0x1B), cancel (0x18), delete (0x7F), and other characters, updating a buffer pointer accordingly. It also calls helper functions to output control characters (like bell or cursor movement) and can reset the buffer pointer on certain inputs.  

**Parameters**:  
- `%fp@(8)` (first argument on stack): Pointer to the start of a character buffer (likely input buffer base address).  
- `%a5` is initialized from this argument and used as the current buffer pointer.  

**Returns**:  
- `%a5` is updated to reflect the new buffer position after processing.  
- No explicit return value in `%d0`; side effects include writing to the buffer and calling output routines.  

**Key Operations**:  
- Reads a character via `jsr 0x807716` (likely a getchar-style input function), masks it to 7 bits (`andl #127, %d0`).  
- Compares the current buffer pointer against the start to prevent underflow.  
- Handles specific control codes:  
  - `0x08` (backspace): Moves pointer back one, outputs backspace and bell if at start.  
  - `0x0A` (LF) / `0x0D` (CR): Replaces with newline, terminates buffer with null, returns.  
  - `0x11` (DC1, XON): Restarts processing (loops).  
  - `0x18` (CAN) / `0x40` ('@'): Resets buffer pointer to start and outputs newline.  
  - `0x1B` (ESC): Calls a formatting/output function at `0x807510` with a format string (address `0x807f32`).  
  - `0x23` ('#'): Treated same as backspace.  
- Default action for unhandled characters: stores them in the buffer and increments pointer.  
- Calls `jsr 0x8076ba` with an argument (likely to output a control character, e.g., bell or cursor movement).  

**Called Functions**:  
- `0x807716`: Likely reads a character from input (serial console).  
- `0x8076ba`: Outputs a control character (argument on stack: 0x20 = bell, 0x08 = backspace, 0x0A = newline).  
- `0x807510`: Formatted print function (called with buffer pointer and format string at `0x807f32`).  

**Notes**:  
- The function appears to be part of a command-line interface or debug monitor, interpreting escape sequences for editing (backspace, cancel, etc.).  
- The format string at `0x807f32` (referenced in the ESC case) is not shown here but likely produces a prompt or formatting output.  
- The buffer is null-terminated on newline/carriage return, suggesting it builds a null-terminated string for command parsing.  
- The use of 7-bit masking (`andl #127`) suggests it's processing ASCII, ignoring parity or high bits.  
- The check for character `0x5C` (backslash) at `%a5@(-1)` may be for escaping within the buffer.  
- Hardware registers are not directly accessed here; the function operates at a higher level (character I/O layer).

---

### Function at 0x807882

**Embedded strings:**
- `8419510`: `"N^NuTSTS1-f"`
- `8419522`: `"PROM   "`
- `8419530`: `"STATIC "`
- `8419538`: `"SIO    "`
- `8419546`: `"MAIN   "`
- `8419554`: `"JOB    "`
- `8419562`: `"MAP    "`
- `8419570`: `"MAPPER "`
- `8419578`: `"SCSI   "`
- `8419586`: `"MULTBUS"`
- `8419594`: `"CLOCK  "`
- `8419602`: `"REGSTER"`
- `8419610`: `"PRIV   "`
- `8419618`: `"PARITY "`
- `8419626`: `"BUS    "`
- `8419634`: `"PROCS  "`
- `8419642`: `"NO TEST"`
- `8419650`: `"EXUS"`
- `8419655`: `" SELFTEST REV %s "`
- `8419677`: `"\nSELFTEST COMPLETE\n"`
- `8419697`: `"\nSELFTEST FAILED - "`
- `8419717`: `"\n	%s(t%x) FAILED (%4x)"`
- `8419740`: `"PERR1 "`
- `8419747`: `"PERR2 "`
- `8419754`: `"MBERR "`
- `8419761`: `"SC_R  "`
- `8419768`: `"BUSERR"`
- `8419775`: `"MISC  "`
- `8419782`: `"KILL  "`
- `8419789`: `"%s  = %x\n"`
- `8419799`: `"SC_C    = %x\n"`
- `8419813`: `"SC_P    = %x\n"`
- `8419827`: `"address %6x received %8x expected %8x"`
- `8419865`: `"interrupt %6x received %4x expected 1"`
- `8419903`: `"buserr %4x received %4x expected %4x"`
- `8419940`: `"time out %x"`
- `8419952`: `" Monitor = %x"`
- `8419966`: `" Boot = %x"`
- `8419977`: `"%x ints"`
- `8419985`: `"execute err"`
- `8419997`: `"id err "`
- `8420005`: `"ua23 err"`
- `8420014`: `"\nmemsize = %x.%x Mb"`
- `8420047`: `"job "`
- `8420052`: `"dma "`
- `8420057`: `"TEST # = %x FAILS = %x\n"`
- `8420083`: `"%8x = %4x,	%8x = %4x\n"`
- `8420105`: `"%8x = %4x  instead of %x\n"`
- `8420131`: `"%8x = %4x\n"`
- `8420142`: `"%8x =  %4x  ? "`

**Name**: `selftest_run_test`  

**Purpose**:  
This function appears to be the main self‑test runner for the Plexus P/20 DMA processor. It executes a specific self‑test routine (passed as a function pointer), captures its return code, and ensures that the test runs with a flag (`0xC0064C`) set to 1 to indicate test mode. The function also masks the return value to a single byte, suggesting that each test returns a small status/error code.

**Parameters**:  
- `%fp@(8)` – a pointer to the self‑test subroutine to execute (passed on the stack).  
- No explicit register parameters; the test routine is called with whatever context it expects.

**Returns**:  
- `%d0` – the lower 8 bits of the return value from the called test routine (error/status code).  
- The global flag at `0xC0064C` is cleared after the test.

**Key Operations**:  
- Sets a global flag at `0xC0064C` to `1` before calling the test routine.  
- Calls the test subroutine via `jsr 0x807716` (which likely dispatches to the supplied function pointer).  
- Masks the return value to bits 7–0 (`andil #255`).  
- Clears the global flag at `0xC0064C` after the test.  
- Restores `%d7` and returns the masked status.

**Called Functions**:  
- `0x807716` – a dispatcher or indirect‑call routine that executes the test function whose pointer is on the stack.

**Notes**:  
- The global flag at `0xC0064C` is probably used by other self‑test code to know they are running in a test context (e.g., to suppress certain outputs or enable diagnostic hardware).  
- The function is relatively short (the bulk of the listing after `0x8078ba` is not code but embedded string data for the self‑test messages, as seen in the referenced strings list).  
- The strings following the function correspond to test names (`PROM`, `STATIC`, `SIO`, `MAIN`, `JOB`, etc.) and error messages used by the larger self‑test framework.  
- This routine is likely called repeatedly by a loop that iterates through an array of test function pointers.

---

### Function at 0x807af8

**Embedded strings:**
- `8420105`: `"%8x = %4x  instead of %x\n"`
- `8420131`: `"%8x = %4x\n"`
- `8420142`: `"%8x =  %4x  ? "`
- `8420157`: `"%8x =  "`
- `8420165`: `"%4x "`
- `8420170`: `"%4x "`
- `8420175`: `"     "`
- `8420181`: `"    /* "`
- `8420195`: `" */\n"`
- `8420200`: `"%6x   %s\n"`
- `8420210`: `"%4x - %s\n"`
- `8420225`: `" FAILED (%x)\n"`
- `8420239`: `" PASSED\n"`
- `8420250`: `"\njumping to %x\n"`
- `8420270`: `"\nVERSION = %s\n\n"`
- `8420286`: `" ????\n"`
- `8420293`: `" ????\n"`
- `8420300`: `"TEST # = %x FAILS = %x\n"`
- `8420324`: `"\nconfig checksum error %x "`
- `8420351`: `"\nreally? (y or n)"`
- `8420369`: `" address %x"`
- `8420381`: `" peh = %x pel = %x\n"`
- `8420403`: `"U%d%c "`
- `8420410`: `"U15%c "`
- `8420417`: `"U15%c "`
- `8420424`: `"\nONLY DMA"`
- `8420434`: `" time out\n"`
- `8420445`: `" <star>\n"`
- `8420454`: `" time out"`
- `8420464`: `"%x %x "`
- `8420471`: `"\n	job "`
- `8420478`: `"\n	dma "`
- `8420485`: `"\njob "`
- `8420491`: `"\ndma "`
- `8420497`: `"****"`
- `8420502`: `"interrupt # %x\n"`
- `8420518`: `"bus error\n"`

**Name**: `debug_string_table` or `rom_string_data`

**Purpose**: This is not a function but a data section containing embedded ASCII strings used by the U17 debug/monitor ROM. The strings are diagnostic messages, prompts, and labels for the self‑test and debugger interface. The data appears to be stored in a somewhat fragmented or interleaved manner, possibly due to the assembler misinterpreting code as data, but the visible ASCII fragments clearly match the known debug strings listed in the documentation.

**Parameters**: None (this is data, not executable code).

**Returns**: None (data section).

**Key Operations**:
- Contains the string `" FAILED (%x)\n"` at offset 0x807b88 (matches string at 0x8420225).
- Contains the string `" PASSED\n"` at offset 0x807b94 (matches 0x8420239).
- Contains the string `"\njumping to %x\n"` at offset 0x807ba2 (matches 0x8420250).
- Contains the string `"\nVERSION = %s\n\n"` at offset 0x807bb0 (matches 0x8420270).
- Contains the string `" ????\n"` (twice) around offsets 0x807bc0 and 0x807bc8 (matches 0x8420286 and 0x8420293).
- Contains the string `"TEST # = %x FAILS = %x\n"` at offset 0x807bd0 (matches 0x8420300).
- Contains the string `"\nconfig checksum error %x "` at offset 0x807be6 (matches 0x8420324).
- Contains the string `"\nreally? (y or n)"` at offset 0x807c00 (matches 0x8420351).
- Contains the string `" address %x"` at offset 0x807c14 (matches 0x8420369).
- Contains the string `" peh = %x pel = %x\n"` at offset 0x807c1a (matches 0x8420381).
- Contains the string `" time out\n"` at offset 0x807c52 (matches 0x8420434).
- Contains the string `" <star>\n"` at offset 0x807c5c (matches 0x8420445).
- Contains the string `" time out"` at offset 0x807c68 (matches 0x8420454).
- Also contains fragments of other known strings (e.g., `"U%d%c "`, `"ONLY DMA"`, `"bus error\n"`).

**Called Functions**: None.

**Notes**:
- The address range 0x807af8–0x807c6e is near the end of the U17 ROM (which ends at 0x807FFF). This region is clearly a string table, not executable code.
- The strings are stored in plain ASCII, often preceded by a length or offset word (e.g., `0x0a00` likely represents line‑feed characters `\n`).
- Some of the data appears as valid 68010 instructions (e.g., `movel %a5@-,%d0`) because the ASCII bytes coincide with opcodes; this is a common disassembly artifact when data is disassembled as code.
- The strings correspond exactly to the debug‑output messages listed in the “Known U17 Functions” section, confirming this is the string pool for the monitor/debugger.
- This data section is referenced by the various debug command handlers (e.g., at 0x802714, 0x802a4e, etc.) via absolute addresses or PC‑relative addressing.

---

### Function at 0x807c70

**Embedded strings:**
- `8420464`: `"%x %x "`
- `8420471`: `"\n	job "`
- `8420478`: `"\n	dma "`
- `8420485`: `"\njob "`
- `8420491`: `"\ndma "`
- `8420497`: `"****"`
- `8420502`: `"interrupt # %x\n"`
- `8420518`: `"bus error\n"`
- `8420529`: `"address error\n"`
- `8420544`: `"illegal instruction\n"`
- `8420565`: `"clock int\n"`
- `8420576`: `"memory parity error\n"`

**Name**: `exception_handler_table_init`  

**Purpose**:  
This function initializes a table of exception handler strings in memory, likely for a debug monitor or self-test ROM. It writes a sequence of ASCII strings (including newlines, tabs, and placeholder text) into a memory buffer, which will later be used to print error messages or processor status information when exceptions occur. The strings correspond to labels like "job", "dma", "****", and "interrupt # %x", matching known debug output strings from the U17 ROM.

**Parameters**:  
- `%a2` likely points to a base address in RAM (possibly `0xC00000` or similar) where the string table is being built.  
- No explicit register inputs; the function writes hardcoded data.

**Returns**:  
- No explicit return value; side effect is writing string data to memory starting at `%a2@(30752)` (offset `0x7820`).

**Key Operations**:  
- Uses `movel` instructions to write 32-bit chunks of ASCII data to memory offsets from `%a2`.  
- The data includes:  
  - `"%x %x "` (string at offset `0x7820`)  
  - Newline (`0x0a`), tab (`0x09`), and the words "job", "dma", "****", and "interrupt # %x" fragments.  
- The writes appear to be constructing a contiguous block of strings, possibly for a jump table or message lookup table used by exception handlers (e.g., bus error, address error, illegal instruction).

**Called Functions**:  
None; this is a pure data-initialization routine.

**Notes**:  
- The code is mostly data moves, but the disassembly is misleading because the hex bytes are being interpreted as instructions. The actual content from `0x807c70` to `0x807ca2` is likely a data table embedded in the code section, not executable instructions.  
- The strings match those listed in the documentation (e.g., `"job "`, `"dma "`, `"****"`, `"interrupt # %x"`), suggesting this table is referenced by the debug command handlers or exception vectors.  
- The offset `0x7820` from `%a2` corresponds to address `%a2 + 0x7820`; if `%a2` is `0xC00000`, this would be `0xC07820`, within the shared RAM area used for system variables.  
- This routine is likely called early in ROM initialization to set up debug/exception messaging before self-tests run.

---

### Function at 0x807cb0

**Embedded strings:**
- `8420529`: `"address error\n"`
- `8420544`: `"illegal instruction\n"`
- `8420565`: `"clock int\n"`
- `8420576`: `"memory parity error\n"`
- `8420597`: `"\nPC = %x, SR = %x\n"`
- `8420616`: `"INSTREG = %x, ACCESSADDR = %x, R:~I:FCN = %x\n"`
- `8420662`: `"\n	%s(t%x) FAILED (%x)"`
- `8420684`: `"\n select"`
- `8420693`: `"\n sd_i_int"`
- `8420704`: `"\n sd_o_int"`
- `8420715`: `"\n ss_i_int"`
- `8420726`: `"\nstatus = %x\n"`
- `8420740`: `"sense = %x %x %x %x %x %x %x %x %x %x %x\n"`
- `8420782`: `"\n saveptrs"`
- `8420793`: `"\n loadptrs"`
- `8420804`: `"\n scsi = %x last = %x "`
- `8420827`: `"selection timeout \n"`
- `8420847`: `"no sel int\n"`
- `8420859`: `"deadman timeout\n"`
- `8420876`: `"busy active\n"`
- `8420889`: `" err = %x"`
- `8420899`: `"\n	WARNING: config info invalid"`
- `8420930`: `"\nsc%x lun %x expected"`
- `8420952`: `"\nsc%x expected"`
- `8420967`: `"\nsc%x not expected"`
- `8420986`: `"\nSYSTEM CONFIGURATION:   "`
- `8421012`: `"ex  "`
- `8421017`: `"icp  "`
- `8421023`: `"acp  "`
- `8421029`: `"sc%x  "`

**Name**: `exception_handler_common`  

**Purpose**: This function serves as a common exception‑handling and diagnostic‑reporting routine for the DMA processor. It processes various hardware exceptions (bus error, address error, illegal instruction, etc.) and SCSI‑related interrupt/timeout events, printing detailed error messages and system state information to the console. It also appears to handle SCSI command‑timeout recovery and configuration validation.  

**Parameters**:  
- Exception‑specific parameters are passed via the stack (68010 exception frame).  
- Some SCSI‑related error paths expect data in registers (e.g., `%d4` may hold a SCSI status byte, `%a0` may point to a SCSI command block).  
- Global hardware registers (e.g., `0xE00002` for system status, `0xE00014` for bus‑error details) are read directly.  

**Returns**:  
- No explicit return value; the function may either attempt to recover (e.g., reset SCSI bus, retry commands) or halt the system.  
- In some paths, it may return to a caller via `rts`, but many branches lead to infinite loops or system resets.  

**Key Operations**:  
- Reads the exception vector number from the stack and uses it to index a jump table of specific handlers.  
- Prints exception‑type strings (e.g., `"address error"`, `"illegal instruction"`, `"clock int"`, `"memory parity error"`).  
- Dumps CPU state: PC, SR, instruction register, access address, function code.  
- Checks SCSI controller status and prints SCSI sense data (up to 11 bytes).  
- Handles SCSI selection timeouts, missing selection interrupts, “deadman” timeouts, and busy‑line issues.  
- Validates system configuration (checks for expected SCSI IDs and LUNs) and prints a configuration summary.  
- Accesses hardware registers:  
  - `0xE00002` (system status) to check `DIS.MAP`, `HALT.DMA`, `BERR`, etc.  
  - `0xE00014` (bus‑error details).  
  - `0xE0001A` (serial port status) for console output readiness.  
  - SCSI controller registers (likely at `0xE001A0`‑related addresses) for status and sense data.  
- Calls ROM‑resident print/formatting subroutines (e.g., `printf`‑style functions).  

**Called Functions**:  
- `0x800410` – Bus‑error handler (likely a higher‑level handler).  
- `0x80047a` – Address‑error handler.  
- `0x800484` – Illegal‑instruction handler.  
- `0x80048c` – Spurious‑interrupt handler.  
- `0x8004c0` – Default exception handler.  
- Several `jsr`/`bsr` targets within the ROM (e.g., `0x802714`, `0x802a4e`, `0x802f5a`) for debug commands and printing.  
- Subroutines at `0x807e6c`‑onward (not fully shown) likely contain SCSI command‑retry logic and configuration‑table reads.  

**Notes**:  
- The function contains embedded error strings (visible in the hex dump) that match known U17 debug‑monitor messages.  
- It appears to be a central dispatch point for both CPU exceptions and SCSI‑timeout events, suggesting the DMA processor uses it for system‑monitoring and boot‑time diagnostic reporting.  
- The SCSI‑related code suggests it can recover from selection timeouts by resetting the SCSI bus (via `0xE001A0`).  
- The configuration‑validation output (`"SYSTEM CONFIGURATION:"`) indicates it reads a hardware configuration table (possibly in shared RAM at `0xC00000`‑`0xC00FFF`) and verifies attached SCSI devices.  
- This function is likely called from the main self‑test loop in U17 ROM and from exception vectors during normal operation.

---

### Function at 0x807e70

**Embedded strings:**
- `8420986`: `"\nSYSTEM CONFIGURATION:   "`
- `8421012`: `"ex  "`
- `8421017`: `"icp  "`
- `8421023`: `"acp  "`
- `8421029`: `"sc%x  "`
- `8421036`: `"%x.%x Mb"`
- `8421045`: `"\nEXPECTED CONFIGURATION: "`
- `8421071`: `"ex  "`
- `8421076`: `"icp  "`
- `8421082`: `"acp  "`
- `8421088`: `"sc%x  "`
- `8421095`: `"%x.%x Mb"`
- `8421104`: `"\nno icp"`
- `8421112`: `"\nno %ccp"`
- `8421121`: `"\nno %ccp"`
- `8421130`: `"\nbad status"`
- `8421142`: `"\n	%ccp FAILED (%x)"`
- `8421161`: `"no board"`

**Name**: `print_system_configuration`

**Purpose**: This function prints a formatted system configuration report, comparing actual hardware status against expected configuration. It appears to be part of the self-test/diagnostics routine that runs at boot, displaying processor presence (EX, ICP, ACP), SCSI controller ID, memory size, and reporting any mismatches or failures.

**Parameters**: 
- Likely uses memory-mapped hardware registers at 0xE00000–0xE001FF for reading system status
- May expect configuration data stored in ROM or RAM (e.g., expected processor setup, memory size)
- Uses the serial console (SCC) for output, assuming it's already initialized

**Returns**: 
- No explicit return value; side effects include console output and possibly setting status flags
- May modify condition codes based on comparison results

**Key Operations**:
- Reads hardware status registers (0xE00000, 0xE00002, etc.) to determine actual configuration
- Compares actual vs. expected configuration for:
  - Processor presence (EX, ICP, ACP — likely referring to DMA, Job, and optional coprocessor)
  - SCSI controller ID (SC%x)
  - Memory size in MB (%x.%x Mb)
- Prints formatted strings using embedded format specifiers (e.g., %x, %ccp)
- Outputs error messages like "no icp", "bad status", "%ccp FAILED (%x)", "no board"
- Uses string literals embedded directly in the code section (e.g., "SYSTEM CONFIGURATION:", "EXPECTED CONFIGURATION:")

**Called Functions**:
- Likely calls a formatted print subroutine (e.g., `printf`-like) at another ROM location (not visible in this snippet)
- May call hardware status reading subroutines (e.g., to read SCSI ID, memory size, processor flags)

**Notes**:
- The code block contains interleaved data (strings) and instructions, typical of ROM code where constant data is placed inline.
- Strings suggest support for three processor types: EX (Executive/DMA), ICP (Job processor), ACP (possibly an optional arithmetic coprocessor).
- The "sc%x" likely prints the SCSI controller ID (Omti 5200 at ID 0).
- Memory size is printed with a fractional part (e.g., "4.0 Mb"), suggesting granularity in reporting.
- Error messages indicate the diagnostics check for board presence, status validity, and individual processor self-test results.
- The function seems designed for both automated testing and manual debugging via the serial console.
- Address range (0x807e70–0x807f34) places it near the end of the U17 ROM, possibly as part of a comprehensive configuration report before handing off to the boot loader.

---

---

# U15: Boot Loader

## U15 Function Summary

| Address | Size | Name | Description |
|---------|------|------|-------------|
| 0x808400 | 280 | `exception_vector_handlers` | This is a collection of exception and interrupt handlers for the DMA processor, located at the start |
| 0x80851a | 12 | `disable_interrupts_and_save_status` | This function saves the current processor status register (SR) contents, then modifies it to disable |
| 0x808528 | 12 | `disable_interrupts_and_save_status` | This function saves the current processor status register (SR) contents, clears specific interrupt m |
| 0x808536 | 18 | `set_sr_with_ssw` | This function reads the Special Status Word (SSW) from the stack (provided by the 68010's bus or add |
| 0x80854a | 20 | `scsi_write_cdb` | This function constructs a SCSI Command Descriptor Block (CDB) in the shared memory area at 0xC04000 |
| 0x808560 | 28 | `boot_loader_init` | This function initializes the DMA processor's execution environment at the start of the boot loader. |
| 0x808580 | 132 | `div_signed_32bit` | This function performs a signed 32-bit integer division, computing `dividend / divisor`. It handles  |
| 0x808606 | 46 | `mul_32x16_to_32` | This function multiplies a 32‑bit integer by a 16‑bit integer, producing a 32‑bit result. It treats  |
| 0x808636 | 70 | `signed_32x32_multiply` | This function performs a signed 32-bit by 32-bit integer multiplication, returning a 32-bit product. |
| 0x80867e | 126 | `divmod_signed_32bit` | This function computes the signed remainder (modulus) of a 32-bit integer division. It takes two sig |
| 0x8086fe | 218 | `unsigned_divide_32_by_32` | This is actually two separate functions that share the same code block. The first function (starting |
| 0x8087da | 12 | `delay_loop` | This function implements a simple delay loop that consumes CPU cycles for a specified number of mill |
| 0x8087e8 | 20 | `delay_1000_cycles` | This function implements a fixed-duration delay loop by performing 1000 iterations of a division ope |
| 0x8087fe | 110 | `hardware_reset_and_init` | This function performs a comprehensive reset and initialization of the Plexus P/20's hardware contro |
| 0x80886e | 30 | `clear_memory_block` | This function clears a block of memory by writing zeros to consecutive longword (32-bit) addresses.  |
| 0x80888e | 334 | `initialize_scsi_target_parameters` | This function initializes SCSI target parameter tables for multiple SCSI IDs (likely 0-7). It calcul |
| 0x808a9a | 146 | `parse_path_components` | This function parses a Unix-style path string (passed as a pointer) by splitting it into slash-separ |
| 0x808b2e | 390 | `lookup_inode_block` | This function appears to be part of a Unix‑style filesystem boot loader that traverses an inode’s in |
| 0x808cb6 | 266 | `boot_find_file_in_ramdisk` | This function searches for a file by name within a RAM disk structure loaded in memory. It appears t |
| 0x808dc2 | 74 | `strncmp_or_nullterm_match` | This function compares two strings with a maximum length constraint, but with special handling for a |
| 0x808e0e | 70 | `boot_setup_memory_params` | This function calculates and stores two memory parameters used during the boot process. It first cal |
| 0x808e56 | 282 | `get_next_char` | This function implements a buffered character reader that returns the next character from a buffered |
| 0x808f72 | 216 | `read_serial_string` | This function reads a string from the serial console, up to a maximum of 4 characters, storing them  |
| 0x80904c | 500 | `parse_boot_command` | This function parses a boot command string entered by the user at the ":" prompt, validates its synt |
| 0x809242 | 34 | `boot_clear_error_or_continue` | This function checks a global error flag at address `0xC03A20` (bit 3) and, if the flag is not set,  |
| 0x809266 | 36 | `boot_error_handler` | This function handles a fatal error condition during the boot process. It first calls a diagnostic/e |
| 0x80928c | 30 | `boot_error_handler` | This function handles a fatal error condition during the boot process. It saves an error address (li |
| 0x8092ac | 30 | `call_boot_menu_function` | This function serves as a dispatcher for boot menu command handlers. It calculates the address of a  |
| 0x8092cc | 24 | `dispatch_boot_command` | This function acts as a dispatcher for boot commands, using a lookup table to jump to the appropriat |
| 0x8092e6 | 160 | `dispatch_scsi_command` | This function acts as a command dispatcher for SCSI operations. It takes a SCSI command index as inp |
| 0x80945e | 174 | `copy_triplets_with_null_padding` | This function copies data from a source buffer to a destination buffer in groups of three bytes, pad |
| 0x809696 | 276 | `boot_initialize_system` | This function performs early system initialization for the DMA processor after the boot loader start |
| 0x8097ac | 706 | `load_and_execute_boot_image` | This function loads a bootable Unix a.out executable from a SCSI device into memory, sets up the exe |
| 0x809a70 | 108 | `boot_checksum_and_copy` | This function reads a data structure (likely a boot record or header) from a fixed location in memor |
| 0x809ade | 448 | `handle_bus_error_or_parity_error` | This function handles either a bus error or a memory parity error, depending on the error code passe |
| 0x809ca0 | 98 | `detect_ram_size` | This function determines the amount of installed RAM by performing a write‑read test on a range of m |
| 0x809d04 | 102 | `read_big_endian_longword` | This function reads a 32-bit big-endian (network byte order) longword from a byte-oriented input str |
| 0x809d6c | 82 | `get_next_byte_or_call` | This function retrieves the next byte from a buffer pointer stored at `0xc03b64`, incrementing the p |
| 0x809dc0 | 118 | `boot_processor_switch` | This function temporarily switches the DMA processor to act as the Job processor by modifying system |
| 0x809e38 | 70 | `boot_verify_memory_range` | This function appears to verify a range of memory (likely RAM) by writing a known value and reading  |
| 0x809e80 | 38 | `wait_for_scsi_busy_clear` | This function polls a shared memory location (`0xc03a88`) that likely holds the SCSI controller's bu |
| 0x809ea8 | 178 | `print_hardware_status` | This function reads and prints the contents of several hardware status registers located at the I/O  |
| 0x809f5c | 54 | `is_valid_scsi_lun_or_partition` | This function validates SCSI LUN (Logical Unit Number) or partition number arguments. It checks whet |
| 0x809f94 | 232 | `printf_style_formatter` | This function implements a minimal printf-style format string interpreter, likely used by the boot l |
| 0x80a07e | 86 | `boot_print_error_chain` | This function prints a chain of error messages from a linked error structure. It appears to handle a |
| 0x80a0d6 | 124 | `serial_send_break_or_loop` | This function appears to manage serial port break signaling or character transmission pacing, likely |
| 0x80a154 | 30 | `wait_for_scsi_phase` | This function repeatedly polls the SCSI bus phase by calling a helper function (at `0x80a174`) until |
| 0x80a174 | 54 | `increment_and_call_0x80a1ac` | This function increments a global counter at `0xc03b44`, calls a subroutine at `0x80a1ac` with a par |
| 0x80a1ac | 136 | `serial_getc_with_timeout` | This function reads a character from a serial port with a timeout mechanism. It waits for the SCC’s  |
| 0x80a236 | 198 | `read_and_process_console_input` | This function implements a console input loop that reads characters from a serial port (likely the c |
| 0x80a2fe | 142 | `print_device_boot_info` | This function prints boot-related information for a specific device, likely as part of the boot menu |
| 0x80a3f8 | 370 | `scsi_init_device` | This function initializes a SCSI device for boot operations by selecting a target device based on co |
| 0x80a56c | 58 | `boot_disable_serial_interrupts` | This function disables serial port interrupts by clearing the relevant interrupt enable bits in the  |
| 0x80a5a8 | 120 | `boot_checks_and_init` | This function performs a series of system checks and initializations early in the boot process. It v |
| 0x80a622 | 110 | `boot_checks_and_init` | This function performs a series of system checks and initializations early in the boot process. It v |
| 0x80a692 | 334 | `scsi_init_or_reset_device` | This function initializes or resets a SCSI device (likely the OMTI 5200 controller) by checking hard |
| 0x80a7e2 | 298 | `scsi_controller_init_or_status_check` | This function performs initialization and status verification of the SCSI controller (likely the Omt |
| 0x80a90e | 172 | `boot_init_scsi_drive` | This function initializes or validates the SCSI controller and boot drive configuration. It checks h |
| 0x80a9bc | 120 | `boot_phase2_checks` | This function performs a series of system checks and initializations during the boot process. It ver |
| 0x80aa36 | 264 | `scsi_bus_reset_and_wait` | This function performs a SCSI bus reset sequence, waits for the bus to become free, and logs error c |
| 0x80ab40 | 232 | `scsi_write_sector` | This function writes a sector of data to a SCSI disk (likely the boot device) using parameters store |
| 0x80ac2a | 338 | `scsi_select_device_and_configure` | This function configures the SCSI bus for a specific target device (likely a disk or tape) by settin |
| 0x80ad7e | 96 | `boot_scsi_read_boot_block` | This function reads the first block (likely the boot block or superblock) from a SCSI disk. It prepa |
| 0x80ade0 | 408 | `boot_load_unix_kernel` | This function loads a Unix kernel from a SCSI disk into memory, validates its executable header, cop |
| 0x80af7a | 154 | `wait_for_scsi_ready_or_timeout` | This function waits for the SCSI controller to become ready (busy flag clear) with a timeout mechani |
| 0x80b016 | 6 | `empty_stack_frame` | This function creates and immediately destroys a stack frame without performing any actual operation |
| 0x80b01e | 50 | `boot_error_handler` | This function appears to be a fatal error handler in the boot loader that checks for a specific fail |
| 0x80b052 | 156 | `scsi_setup_command` | This function constructs a SCSI command descriptor block (CDB) in a shared memory structure and prep |
| 0x80b0f0 | 86 | `boot_cache_invalidate_or_flush` | This function appears to manage a boot-time cache invalidation or flush operation, likely for a disk |
| 0x80b148 | 226 | `boot_scsi_read_sector_with_checksum` | This function reads a sector from a SCSI device (likely a disk) using a previously configured SCSI c |
| 0x80b22c | 110 | `boot_verify_or_retry_scsi_operation` | This function appears to be a higher-level SCSI operation verifier and retry handler. It first attem |
| 0x80b29c | 88 | `scsi_read_sector_with_timeout` | This function reads a single sector (512 bytes) from a SCSI device using the OMTI 5200 controller, w |
| 0x80b2f6 | 132 | `boot_cleanup_or_shutdown` | This function appears to perform a controlled cleanup or shutdown sequence, likely after a boot oper |
| 0x80b37c | 326 | `boot_menu_loop` | This function implements the main boot menu loop for the Plexus P/20 DMA processor. It displays the  |
| 0x80b4c4 | 94 | `boot_read_disk_block` | This function reads a block from disk (likely SCSI) into memory, then processes or verifies it. It a |
| 0x80b57a | 96 | `scsi_wait_busy_or_timeout` | This function waits for the SCSI bus to become not busy (likely waiting for a SCSI operation to comp |
| 0x80b5dc | 62 | `boot_initialize_system` | This function initializes key system variables and performs early boot setup by clearing shared memo |
| 0x80b61c | 88 | `boot_handle_scsi_error` | This function implements a SCSI error recovery sequence for the Plexus P/20 boot loader. It checks a |
| 0x80b676 | 68 | `boot_loader_entry` | This function appears to be the main entry point for loading and executing a Unix kernel (or other b |
| 0x80b6bc | 52 | `boot_initialize_scsi_or_filesystem` | This function appears to perform a low‑level SCSI or filesystem initialization sequence during the b |
| 0x80b6f2 | 56 | `boot_loader_entry` | This function loads a boot image from a SCSI device into memory at address 0x10000 (64KB offset) and |
| 0x80b72c | 194 | `scsi_check_status_or_error` | This function appears to check the status of the SCSI controller (likely the OMTI 5200) after a comm |
| 0x80b7f0 | 436 | `boot_verify_or_format_disk` | This function appears to implement a disk verification or low-level formatting routine that operates |
| 0x80b9a6 | 92 | `boot_scsi_read_sector` | This function reads a sector from a SCSI disk, likely as part of the boot loader’s disk I/O routines |
| 0x80ba04 | 254 | `boot_loader_main` | This function appears to be the main boot loader routine that loads a kernel image from disk into me |
| 0x80bb04 | 110 | `boot_setup_bootstrap_buffer` | This function sets up a bootstrap buffer in shared memory, either by copying data into a fixed buffe |
| 0x80bb74 | 72 | `copy_boot_sectors_to_shared_memory` | This function copies the first 512 bytes (one sector) from the boot ROM at 0xC00400 into shared RAM  |
| 0x80bbbe | 188 | `dump_hardware_status_registers` | This function reads and prints the contents of key hardware status registers from the Plexus P/20's  |
| 0x80bc7c | 26 | `boot_clear_shared_vars` | This function initializes three shared memory variables in the fixed RAM area at `0xC00000–0xC00FFF` |
| 0x80bc98 | 168 | `verify_checksum_or_crc` | This function appears to validate a checksum or CRC value received from a data stream (likely from a |
| 0x80bd42 | 124 | `process_serial_input_or_timeout` | This function handles serial input polling with timeout detection, processing special control charac |
| 0x80bdc0 | 132 | `get_scsi_device_info` | This function appears to perform SCSI INQUIRY command processing, specifically extracting and combin |
| 0x80be46 | 466 | `parse_boot_command` | This function implements a jump table/dispatcher for boot loader commands. It takes a numeric comman |
| 0x80c01c | 336 | `lookup_error_message` | This function searches a table of error codes and corresponding message strings for a given error co |
| 0x80c16e | 56 | `print_error_strings` | This function is not executable code but rather a data section containing embedded error message str |
| 0x80c1a8 | 26 | `print_tape_error` | This function appears to be a fragment of error‑handling code that prepares arguments for a `printf` |
| 0x80c2f4 | 340 | `print_boot_strings_table` | This function is not executable code but a data table containing embedded ASCII strings used by the  |
| 0x80c44c | 194 | `scsi_debug_print_status` | This function prints SCSI controller status and debug messages to the console. It appears to be part |
| 0x80c510 | 204 | `print_boot_strings` | This function is not executable code but a data section containing embedded ASCII strings used by th |
| 0x80c5de | 56 | `scsi_device_fail_error` | This function prints an error message indicating that a SCSI device has failed during a boot operati |
| 0x80c6b0 | 64 | `print_scsi_error` | This function prints a formatted error message for SCSI command failures. It likely takes an error c |
| 0x80c6f2 | 44 | `print_boot_error_or_prompt` | This function appears to be part of the boot loader’s error‑handling or status‑reporting logic, like |
| 0x80c720 | 516 | `print_scsi_error_codes` | This function prints a comprehensive set of SCSI controller error/status codes and diagnostic messag |
| 0x80c92c | 80 | `print_scsi_error` | This function prints a human-readable SCSI error message based on an error code. It appears to be pa |
| 0x80c97e | 16 | `scsi_error_message_lookup` | This function maps a SCSI error code to a corresponding error message string pointer. It acts as a l |
| 0x80c9b4 | 34 | `scsi_error_message_lookup` | This function maps a SCSI error code (likely from a controller status register) to a corresponding e |
| 0x80c9d8 | 4 | `scsi_check_error` | This function appears to be part of the SCSI disk error handling logic in the boot loader. It checks |
| 0x80c9de | 26 | `print_bad_block_error` | This function prints the error message "Bad block found" to the console. It is part of the boot load |
| 0x80c9fa | 130 | `scsi_error_handler` | This function handles SCSI command execution errors by mapping a SCSI status/error code to a specifi |
| 0x80ca7e | 64 | `print_error_message` | This function prints one of several error messages stored in the ROM, likely used by the boot loader |
| 0x80cac0 | 76 | `print_scsi_error_message` | This function prints a SCSI error message based on an error code. It appears to be part of the boot  |
| 0x80cb0e | 78 | `scsi_error_to_string` | This function maps a SCSI error code (likely passed in a register) to a corresponding error message  |
| 0x80cb5e | 44 | `print_scsi_error_message` | This function prints a SCSI error message string based on an error code. It appears to be part of th |
| 0x80cb8c | 8 | `scsi_error_message_lookup` | This function maps a SCSI error code (passed in a register) to a corresponding error message string  |
| 0x80cb96 | 12 | `scsi_error_handler` | This function handles SCSI command completion status by checking the SCSI controller's result byte f |
| 0x80cbde | 10 | `scsi_check_error` | This function appears to be part of the SCSI error‑handling logic in the boot loader. It likely inte |
| 0x80cbea | 8 | `scsi_error_message_lookup` | This function maps a SCSI error code (likely passed in a register or memory location) to a correspon |
| 0x80cbf4 | 18 | `scsi_handle_error` | This function appears to be part of the SCSI error‑handling logic in the boot loader. It likely maps |
| 0x80cc12 | 90 | `scsi_error_handler` | This function maps SCSI error codes to human-readable error messages and prints them via a formatted |
| 0x80f414 | 338 | `scsi_interrupt_handler` | This function appears to be the main SCSI interrupt service routine for the DMA processor's boot loa |

## U15 Detailed Function Documentation

### Function at 0x808400

**Embedded strings:**
- `8422418`: `"NsHx"`
- `8422424`: `"`(Hx"`
- `8422430`: `"`"Hx"`
- `8422454`: `"`\nHx"`
- `8422468`: `"NsHx"`
- `8422474`: `"`(Hx"`
- `8422480`: `"`"Hx"`
- `8422504`: `"`\nHx"`
- `8422708`: `"Nu /"`

**Name**: `exception_vector_handlers`

**Purpose**: This is a collection of exception and interrupt handlers for the DMA processor, located at the start of the U15 boot ROM. The code defines multiple entry points that handle different exception types (likely bus errors, address errors, illegal instructions, etc.) and specific hardware interrupts (SCSI, serial, timer). Each handler either performs minimal cleanup and returns, or vectors to a more substantial service routine elsewhere in the ROM. The function at `0x808400` appears to be the default/catch-all exception handler, while the subsequent blocks are specific vector entries.

**Parameters**:  
- For the default handler (`0x808400`): The exception stack frame is on the stack, as per the 68010 exception processing.  
- For specific vector entries: The exception number (vector offset) is implied by the entry address. Some handlers (like `0x808478`) expect data in register `%d0`.  
- Hardware register reads/writes use absolute addresses (e.g., `0xE000A0`).

**Returns**:  
- Most handlers end with `rte` (Return From Exception), restoring the processor state from the exception stack frame.  
- No explicit register return values; side effects are through hardware register writes or calls to subroutines.

**Key Operations**:  
- `0x808400`: Saves all registers (`%d0-%fp`), calls `0x809ADE` (likely a general exception logger or panic handler), restores registers, and returns from exception.  
- `0x808414`–`0x808444`: A series of exception entries (likely vectors 2–9) that push an exception code (7 down to 0) on the stack, then immediately remove it and `rte`. This suggests they are minimal handlers for unused or spurious interrupts.  
- `0x808446`–`0x808476`: Another identical series of minimal handlers (likely vectors 10–17).  
- `0x808478`: Writes `%d0` to `0xE000A0` (Reset DMA processor software interrupt register) and returns. This is a specific interrupt acknowledge/clear routine.  
- `0x808480`: Writes `1` to `0xE00100` (Reset DMA processor clock interrupt register) and returns. This clears the timer interrupt.  
- `0x80848A`–`0x808518`: A series of handlers that save all registers, call a specific subroutine in the ROM (e.g., `0x80A622`, `0x80A5A8`), restore registers, and return. These are substantial service routines for hardware interrupts (SCSI, serial, etc.).

**Called Functions**:  
- `0x809ADE` – General exception handler (from default vector).  
- `0x80A622`, `0x80A5A8`, `0x80A9BC`, `0x80A692`, `0x80A90E`, `0x80A7E2`, `0x80A3F8`, `0x80AA36`, `0x80B016` – Specific interrupt service routines, likely for SCSI, serial ports, timer, or other I/O devices.

**Notes**:  
- The code is clearly structured as an exception vector table with handlers at fixed offsets. The pattern of pushing a number (7–0) then removing it suggests these are placeholder handlers for unused vectors, possibly for debugging (the pushed number could identify the vector).  
- The hardware register writes at `0x808478` and `0x808480` are direct acknowledgments to the Plexus interrupt controller: writing to `0xE000A0` resets a software interrupt for the DMA processor, and writing to `0xE00100` resets the DMA processor's clock interrupt.  
- The use of `moveml %d0-%fp` saves all 16 registers (8 data, 8 address), which is a complete context save for true exception handling.  
- The strings referenced in the prompt are not directly used in this code block; they are likely located in the called subroutines (e.g., `0x80A622` might print "NsHx" for a SCSI error).  
- This block is essentially the low-level interrupt/exception dispatch table for the DMA processor's boot ROM, routing hardware events to appropriate service routines.

---

### Function at 0x80851a

**Embedded strings:**
- `8422708`: `"Nu /"`

**Name**: `disable_interrupts_and_save_status`  

**Purpose**:  
This function saves the current processor status register (SR) contents, then modifies it to disable all maskable interrupts and set the processor to supervisor mode. It effectively acts as an atomic "disable interrupts" routine that preserves the previous interrupt mask and condition codes for later restoration.  

**Parameters**:  
- None explicitly passed; reads the current Status Register (SR) via `movew %sr,%d0`.  

**Returns**:  
- `%d0` (lower 16 bits) contains the original Status Register value.  
- The processor’s SR is updated with interrupts disabled (all interrupt mask bits set) and in supervisor mode.  

**Key Operations**:  
- Saves current SR to `%d0` (and duplicates to `%d1`).  
- Sets SR bits:  
  - Bits 8–10 (interrupt mask) = `111b` (level 7, all maskable interrupts disabled).  
  - Bit 13 (supervisor mode) = 1 (already set in SR on 68010, but ensured here).  
  - Uses `oriw #1792, %d1` — 1792 decimal = 0x700 = binary `0111 0000 0000`, which sets bits 8, 9, 10 (mask level 7) and leaves supervisor bit unchanged (bit 13 is already 1 in supervisor mode).  
- Restores modified SR from `%d1`.  

**Called Functions**:  
- None; this is a leaf function ending with `rts`.  

**Notes**:  
- The function runs with interrupts already disabled during its execution because writing to SR is privileged and must be done in supervisor mode (boot ROM code runs in supervisor state).  
- The saved SR in `%d0` can be used later to restore the original interrupt mask and condition codes (e.g., via `movew %d0,%sr`).  
- This is a common pattern for critical sections in system firmware.  
- The code range (0x80851a–0x808526) is just before the main boot loader entry point at 0x80854A, suggesting it may be used during early boot initialization to ensure a clean interrupt state.

---

### Function at 0x808528

**Embedded strings:**
- `8422708`: `"Nu /"`

**Name**: `disable_interrupts_and_save_status`  

**Purpose**:  
This function saves the current processor status register (SR) contents, clears specific interrupt mask bits to disable most interrupts, and then restores the modified status register. It effectively lowers the interrupt priority level to allow critical operations to proceed without interruption, while preserving the original SR state for later restoration.  

**Parameters**:  
None explicitly passed; the function reads the current Status Register (SR) implicitly.  

**Returns**:  
- `%d0`: Contains the original SR value (as a 16-bit value extended to 32 bits).  
- `%d1`: Holds the modified SR value with certain bits cleared.  
- The SR itself is updated with the modified value before returning.  

**Key Operations**:  
- Saves the current SR to `%d0` (and duplicates it to `%d1`).  
- Clears bits in `%d1` using `andiw #-1793` (which masks out bits 8–10, i.e., the interrupt priority mask field, setting IPL=0).  
- Writes the modified value back to the SR.  
- Returns to caller with interrupts effectively disabled (IPL=0) and original SR preserved in `%d0`.  

**Called Functions**:  
None; this is a leaf function.  

**Notes**:  
- The constant `-1793` (signed decimal) equals `0xF8FF` in 16-bit hex, which masks out bits 8, 9, and 10 (binary `1111100011111111`). These bits correspond to the IPL (Interrupt Priority Level) field in the 68010 SR. Setting IPL=0 allows all maskable interrupts to occur, but in practice this is often used to *enable* interrupts if they were previously masked at a higher level. However, given the boot ROM context, this routine likely ensures interrupts are disabled (or lowered to minimum) before performing sensitive hardware operations.  
- The function saves the original SR in `%d0`, suggesting the caller may restore it later (e.g., via `movew %d0,%sr`).  
- This is a common pattern in 680x0 systems for atomic operations or critical sections.  
- Located in the U15 boot ROM just before the main boot entry point at `0x80854A`, it may be used during early boot to initialize hardware without interruption.

---

### Function at 0x808536

**Name**: `set_sr_with_ssw` or `update_status_register_from_ssw`

**Purpose**:  
This function reads the Special Status Word (SSW) from the stack (provided by the 68010's bus or address error exception), extracts the function code bits (FC2–FC0) from it, and merges those bits into the current Status Register (SR) in place of the existing interrupt priority mask bits. This effectively updates the processor's interrupt mask level to reflect the function code of the access that caused the exception, which is a required step in the 68010's bus/address error handler to properly restore context before retrying or handling the fault.

**Parameters**:  
- Input: The SSW is passed as a 16-bit word at offset 4 on the stack (`%sp@(4)`), placed there by the 68010 exception prologue.

**Returns**:  
- No explicit return value. The function modifies the Status Register (`%sr`) directly.

**Key Operations**:  
- Reads the SSW from the exception stack frame.
- Masks the SSW with `0x0700` (binary `0000 0111 0000 0000`) to isolate bits 8–10, which are the function code bits (FC2–FC0) from the faulting access.
- Reads the current Status Register.
- Clears bits 8–10 (interrupt priority mask) in the SR by ANDing with `0xF8FF` (inverse of `0x0700`).
- ORs the extracted function code bits into the cleared mask field of the SR.
- Writes the updated value back to the SR.

**Called Functions**:  
- None; this is a leaf function.

**Notes**:  
- This is a classic 68010 bus/address error handler subroutine. The 68010, unlike the 68000, saves the function code in the SSW during bus faults, and the handler must copy these bits into the SR's interrupt mask field before returning or retrying the instruction, because the processor uses the mask to determine whether the faulted access was made in user or supervisor mode.
- The function is located in the U15 boot ROM just before the main boot entry point at `0x80854A`, suggesting it is part of the system's low‑level exception handling infrastructure, likely called from the default bus/address error handler at `0x808400`.
- The code uses word‑sized operations only; the SSW is 16 bits and the SR is 16 bits.
- No hardware registers are accessed; this is purely CPU state manipulation.

---

### Function at 0x80854a

**Name**: `scsi_write_cdb` or `scsi_setup_command`

**Purpose**: This function constructs a SCSI Command Descriptor Block (CDB) in the shared memory area at 0xC04000, which is likely the location of the Omti 5200 SCSI controller's command/data buffer. It takes three 32-bit arguments from the stack (likely containing a SCSI command, LUN/ID, and block address), processes one of them with a bit shift, and writes them in reverse order into the controller's memory-mapped buffer to form a standard 6-byte or 10-byte SCSI CDB structure.

**Parameters**: Inputs are passed via the stack. Before the function is called, three longwords (32-bit values) were pushed onto the stack. These are popped into registers: `%d2`, `%d3`, and `%d4`. The order of popping suggests the original stack order (top to bottom) was: Argument1 → `%d2`, Argument2 → `%d3`, Argument3 → `%d4`.

**Returns**: The function does not return a value in a register. Its effect is a side-effect: it writes three longwords to the memory-mapped SCSI controller buffer at address `0xC04000` (and decrements the pointer). Registers `%d2`, `%d3`, and `%d4` are modified.

**Key Operations**:
*   **Stack Cleanup**: Removes three longword (12 byte) parameters from the stack (`addql #4,%sp` adjusts for an extra initial condition, likely a saved return address).
*   **Argument Loading**: Pops three arguments into data registers `%d2`, `%d3`, and `%d4`.
*   **Buffer Pointer Setup**: Loads the absolute address `0xC04000` into address register `%a0`. This is within the shared RAM area (`0xC00000-0xC00FFF`) and is specifically the SCSI controller's command/data buffer.
*   **Argument Processing**: Performs an arithmetic shift right logical by 5 bits (`asrl #5,%d2`) on the first argument. This is a common operation to convert a 512-byte disk block number into a 256-word (512-byte) sector address for the controller, or to pack a SCSI command byte with a LUN.
*   **CDB Construction**: Writes the three processed arguments to the SCSI buffer in reverse order (`%d4`, then `%d3`, then processed `%d2`) using pre-decrement addressing mode (`%a0@-`). This builds the CDB in the correct byte order in memory for the SCSI controller.

**Called Functions**: None. This is a leaf function.

**Notes**:
*   The function is entered with 4 bytes already removed from the stack (the return address), which is why it starts with `addql #4,%sp` instead of a more typical `movel %sp@+,%d2`. This suggests it might be part of a larger routine or was called via an exception/trap.
*   The address `0xC04000` is significant. It is 0x4000 bytes past the start of the shared variable area at `0xC00000`. This aligns with common hardware designs where a SCSI controller's DMA buffer is placed at a fixed offset in shared memory.
*   The reverse write order (`d4`, `d3`, `d2`) is crucial. SCSI CDBs are byte streams. Writing a 32-bit register to memory in big-endian Motorola format stores the most significant byte (the command or LUN field) at the lowest address, which is what the hardware expects. The shift on `%d2` prepares it to be the final, often block-address-related, part of the CDB.
*   This is a low-level SCSI command setup routine, called by higher-level boot functions to perform disk reads (e.g., for loading the kernel) or writes (e.g., for `format`, `mkfs` commands).

---

### Function at 0x808560

**Embedded strings:**
- `8422830`: `"B@H@"`

**Name**: `boot_loader_init`  

**Purpose**:  
This function initializes the DMA processor's execution environment at the start of the boot loader. It sets up the supervisor stack pointer, establishes the exception vector base register (VBR) to point to the boot ROM area, and then calls two key initialization subroutines before halting the processor with a diagnostic stop code. This is the early hardware and software setup that occurs after the U17 ROM diagnostics pass and before the boot loader's interactive prompt is shown.

**Parameters**:  
None — the function uses only hardcoded immediate values.

**Returns**:  
No return — the function ends with a `stop` instruction, halting the processor unless an interrupt occurs.

**Key Operations**:  
- Sets the supervisor stack pointer (`%sp`) to `0x00C03FF4` (likely in shared RAM or a private stack area).  
- Loads `0x00808000` into `%d0` and moves it to the Vector Base Register (`%vbr`), relocating the exception vector table to the start of the U15 boot ROM.  
- Calls subroutine at `0x809696` (likely hardware/peripheral initialization).  
- Calls subroutine at `0x80950e` (possibly boot menu initialization or further setup).  
- Executes `stop #9984` (`0x2700`), which halts the processor with status register value `0x2700` (supervisor mode, interrupt priority 7).

**Called Functions**:  
- `jsr 0x809696` — unknown initialization routine.  
- `jsr 0x80950e` — unknown initialization routine.

**Notes**:  
- The stack address `0x00C03FF4` is in the lower 4 MB RAM space but near the top of the first 256 KB bank; this may be a safe temporary supervisor stack.  
- Setting the VBR to `0x808000` means all exception vectors are now offset into the U15 ROM, allowing custom trap handlers defined there.  
- The `stop #9984` is unusual for a boot loader’s main init — it may be a placeholder or a deliberate halt until a software interrupt (like from a serial command) wakes the processor.  
- The referenced string `"B@H@"` at address `8422830` (hex `0x8082AE`) is not directly used here but may be part of a later message or data table.

---

### Function at 0x808580

**Embedded strings:**
- `8422830`: `"B@H@"`
- `8422846`: `"H@`6"`
- `8422913`: `"<N^NuNV"`
- `8422952`: `"HABA"`
- `8422962`: `"N^NuNV"`

**Name**: `div_signed_32bit` or `signed_divide`

**Purpose**: This function performs a signed 32-bit integer division, computing `dividend / divisor`. It handles negative inputs by taking absolute values and tracking the sign of the result, and includes special logic to avoid overflow when the divisor is large (≥ 65536). The algorithm uses a combination of hardware division (`divuw`) and a shift-and-normalize approach for large divisors.

**Parameters**:  
- `%fp@(8)` (first argument): 32-bit signed dividend  
- `%fp@(12)` (second argument): 32-bit signed divisor  

**Returns**:  
- `%d0`: 32-bit signed quotient (dividend / divisor)

**Key Operations**:
- Saves registers `%d2–%d5` and sets up a stack frame.
- Takes absolute values of dividend and divisor, tracking sign in `%d5`.
- If divisor < 65536, uses a single `divuw` instruction for the full division.
- If divisor ≥ 65536, shifts both dividend and divisor right by 1 repeatedly until divisor < 65536, masks off high bits, performs `divuw`, then multiplies the result back (via a call to `0x808606`, likely a multiplication helper) and adjusts for remainder.
- Restores sign of the result based on the original sign tracking.
- Restores saved registers and returns.

**Called Functions**:
- `0x808606` — called with arguments `%d4` (original divisor) and a temporary value; likely a multiplication function (`mul_u32` or similar) used to reconstruct the quotient after normalization.

**Notes**:
- The function avoids the 68010’s `divsl` instruction (32‑bit signed division) possibly because it is not available or because the code aims to handle very large divisors safely without overflow.
- The normalization loop (lines `0x8085c2`–`0x8085d8`) shifts both operands right until the divisor fits in 16 bits, ensuring `divuw` can be used safely.
- The masking with `#2147483647` (`0x7FFFFFFF`) after shifting clears the sign bit, effectively working with absolute values during the core division steps.
- The result’s sign is tracked separately in `%d5` and applied at the end.
- This is a general‑purpose integer division routine, not hardware‑specific; it likely supports boot‑loader commands that require arithmetic (e.g., calculating disk offsets, filesystem block numbers).

---

### Function at 0x808606

**Embedded strings:**
- `8422952`: `"HABA"`
- `8422962`: `"N^NuNV"`
- `8423018`: `"HABA"`

**Name**: `mul_32x16_to_32`  

**Purpose**: This function multiplies a 32‑bit integer by a 16‑bit integer, producing a 32‑bit result. It treats the first argument as a 32‑bit value (split into high and low 16‑bit halves) and the second argument as a 16‑bit value, performing the multiplication using 16‑bit multiply instructions (`muluw`) and combining the partial products. This is a typical software implementation of a 32×16‑bit multiplication on a 68010, which lacks a 32×32 multiply instruction.

**Parameters**:  
- `%fp@(8)` (first argument, 32‑bit) → `%d2`  
- `%fp@(12)` (second argument, 16‑bit) → `%d3` (only low word used)  

**Returns**:  
- 32‑bit product in `%d0`

**Key Operations**:  
- Saves `%d2‑%d3` on the stack.  
- Splits the 32‑bit first argument into high and low 16‑bit halves (using `swap`).  
- Uses `muluw` (unsigned 16×16 multiply) three times:  
  1. Low‑half of first argument × low‑half of second argument → full 32‑bit product in `%d0`.  
  2. High‑half of first argument × low‑half of second argument → 32‑bit product in `%d2`.  
  3. Low‑half of first argument × high‑half of second argument → 32‑bit product in `%d1`.  
- Adds the high‑half products (`%d2` and `%d1`) after shifting one into the high 16 bits of a 32‑bit word.  
- Combines the result with the low‑half product to form the final 32‑bit product.  
- Restores registers and returns.

**Called Functions**: None (no `jsr` or `bsr`).

**Notes**:  
- This is a pure arithmetic helper function with no hardware register accesses, string operations, or I/O.  
- The second argument is passed as a 32‑bit stack slot but only its low 16 bits are used (the high 16 bits are ignored).  
- The algorithm is essentially:  
  `(a_hi<<16 + a_lo) * b_lo` → `(a_lo*b_lo) + ((a_hi*b_lo + a_lo*b_hi) << 16)`  
  where `b_hi` is zero here (since `%d3` high word is unused).  
- Likely used in boot‑loader calculations involving block numbers, offsets, or sizes (e.g., converting logical block numbers to byte offsets for SCSI disk reads).  
- The strings referenced nearby (“HABA”, “N^NuNV”) are unrelated to this function; they likely belong to other parts of the boot loader.

---

### Function at 0x808636

**Embedded strings:**
- `8423018`: `"HABA"`
- `8423034`: `"N^NuNV"`
- `8423080`: `"B@H@"`
- `8423090`: `"B@H@`8&"`

**Name**: `signed_32x32_multiply` or `imul32`

**Purpose**: This function performs a signed 32-bit by 32-bit integer multiplication, returning a 32-bit product. It handles sign correction by taking the absolute values of the inputs, performing unsigned multiplication, and then applying the correct sign to the result based on the original signs of the operands.

**Parameters**: 
- `%fp@(8)` (first 32-bit signed integer)
- `%fp@(12)` (second 32-bit signed integer)

**Returns**: 
- `%d0` contains the 32-bit signed product.

**Key Operations**:
- Saves registers `%d2-%d4` on the stack.
- Takes absolute values of both input arguments, tracking sign changes in `%d4`.
- Performs a 32×32 unsigned multiplication using 16×16 multiply operations (`muluw`) and additions to combine partial products.
- Reconstructs the 32-bit product from the 16-bit partial results.
- Negates the product if the original operands had opposite signs (tracked via `%d4`).
- Restores saved registers and returns.

**Called Functions**: None (no `jsr` or `bsr` instructions).

**Notes**:
- This is a classic software implementation of 32-bit signed multiplication on a 68010, which lacks a 32×32 hardware multiply instruction.
- The algorithm splits each 32-bit operand into high and low 16-bit halves, computes three 16×16 multiplies, and sums them appropriately:
  - `low1 * low2` → full 32-bit product (low 16 bits in low word, high 16 bits in high word of `%d0`)
  - `high1 * low2` and `low1 * high2` → each yields a 32-bit product shifted left by 16 bits; these are added to the high word of the result.
- The sign flag in `%d4` is positive if both inputs had the same sign, negative otherwise.
- No hardware registers are accessed; this is a pure arithmetic function.
- The function appears in the boot loader ROM, likely used for calculating disk block addresses, memory offsets, or filesystem-related computations during boot.

---

### Function at 0x80867e

**Embedded strings:**
- `8423080`: `"B@H@"`
- `8423090`: `"B@H@`8&"`
- `8423162`: `"N^NuNV"`
- `8423214`: `"H@`6"`

**Name**: `divmod_signed_32bit` or `signed_division_remainder`

**Purpose**:  
This function computes the signed remainder (modulus) of a 32-bit integer division. It takes two signed long (32-bit) arguments, divides the first by the second, and returns the remainder. The function handles negative inputs by taking absolute values internally and restoring the sign of the remainder at the end. It also includes a normalization loop to scale down large divisors (≥ 65536) before performing the division, ensuring correct 16‑bit unsigned division can be used.

**Parameters**:  
- `%fp@(8)` (first argument): Signed 32‑bit dividend  
- `%fp@(12)` (second argument): Signed 32‑bit divisor

**Returns**:  
- `%d0`: Signed 32‑bit remainder (dividend % divisor)

**Key Operations**:  
- Takes absolute values of both inputs, tracking sign of result in `%d4`.  
- If divisor < 65536, uses two-step `divuw` (16‑bit division) to compute quotient/remainder.  
- If divisor ≥ 65536, enters a normalization loop that right-shifts both dividend and divisor until divisor < 65536, while preserving sign bits via masking with `0x7fffffff`.  
- Calls subroutine at `0x808606` (likely a 32‑bit multiplication function) to reconstruct remainder after scaling.  
- Adjusts remainder based on comparison with original dividend and divisor.  
- Restores sign of remainder based on original dividend sign.

**Called Functions**:  
- `0x808606`: A subroutine (likely `mul_32bit` or similar) that multiplies two 32‑bit values; called with the scaled quotient and original divisor as arguments.

**Notes**:  
- This is a classic signed modulus implementation with careful handling of large divisors to avoid overflow in the 68010’s 16‑bit `divuw` instruction.  
- The normalization loop (shifting right until divisor < 65536) is an optimization to avoid implementing full 32‑bit division in software.  
- The function is position‑independent within the U15 ROM; it uses `jsr` with absolute address `0x808606`, which is also inside the boot loader ROM.  
- No direct hardware register accesses occur; this is a pure arithmetic utility function, likely used in boot loader command parsing or filesystem block calculations.

---

### Function at 0x8086fe

**Embedded strings:**
- `8423214`: `"H@`6"`
- `8423276`: `"N^NuNV"`
- `8423306`: `"B@H@"`
- `8423316`: `"B@H@`8&"`
- `8423382`: `"N^Nu /"`
- `8423398`: `"Nu <"`
- `8423420`: `"NuBy"`

**Name**: `unsigned_divide_32_by_32` and `unsigned_modulus_32_by_32`

**Purpose**:  
This is actually two separate functions that share the same code block. The first function (starting at `0x8086fe`) performs an unsigned 32-bit division of two 32-bit numbers, returning the quotient. The second function (starting at `0x808770`) performs the same division but returns the remainder (modulus). Both functions handle the special case where the divisor is ≥ 2¹⁶ (65536) by using a normalization loop that shifts both dividend and divisor right until the divisor fits in 16 bits, then uses the 68010's 16-bit hardware division instruction (`divuw`). The quotient function includes a correction step when the multiplication of quotient × divisor exceeds the original dividend.

**Parameters**:  
Both functions take two parameters passed on the stack:  
- `%fp@(8)` = 32-bit dividend (numerator)  
- `%fp@(12)` = 32-bit divisor (denominator)  
These correspond to C-style parameters `(uint32_t a, uint32_t b)`.

**Returns**:  
- First function (`0x8086fe`): Returns quotient in `%d0` (32-bit unsigned).  
- Second function (`0x808770`): Returns remainder in `%d0` (32-bit unsigned).

**Key Operations**:  
- Compares divisor with 65536 to decide between fast path (16-bit divisor) and normalization path.  
- For 16-bit divisor path: uses `swap` and `divuw` to perform 32/16 division.  
- For large divisor (≥65536): right-shifts both dividend and divisor until divisor < 65536, preserving only the low 31 bits (clearing sign bit via `andil #0x7fffffff`).  
- Calls subroutine at `0x808606` (likely a 32×32→32 multiplication function) to compute `quotient × divisor` for remainder correction.  
- Quotient function subtracts 1 from quotient if `quotient × divisor > dividend`.  
- Remainder function computes `dividend - quotient × divisor` with sign adjustment.

**Called Functions**:  
- `0x808606` (called from both functions): Presumably a 32-bit multiplication function, used to compute `quotient × divisor` for correction steps.

**Notes**:  
- The code is careful to avoid the 68010's division overflow trap by ensuring the divisor is less than 65536 before using `divuw`.  
- The normalization loop (`asrl #1` shifts) handles divisors up to 2³¹ by shifting both operands equally, effectively performing division by a power of two before the hardware division.  
- The `andil #0x7fffffff` after shifting clears the sign bit, indicating the function expects unsigned inputs (though shifting right on unsigned values typically uses `lsrl`; `asrl` preserves sign, so the AND masks it out).  
- The two functions are contiguous in ROM, sharing similar logic patterns, suggesting they are part of a math utility library for the bootloader (likely used for filesystem block calculations, SCSI sector addressing, or memory size computations).  
- No hardware register accesses occur here; this is pure arithmetic code.

---

### Function at 0x8087da

**Embedded strings:**
- `8423398`: `"Nu <"`
- `8423420`: `"NuBy"`

**Name**: `delay_loop`

**Purpose**: This function implements a simple delay loop that consumes CPU cycles for a specified number of milliseconds. It takes an input value (likely milliseconds), multiplies it by a constant (6000), and then executes a tight decrement-and-branch loop that number of times. This is a classic software delay routine used for timing purposes, such as waiting for hardware to become ready or creating a short pause.

**Parameters**: The function expects a single 16-bit or 32-bit integer parameter passed on the stack at offset 4 (`%sp@(4)`). This parameter represents the delay duration in milliseconds.

**Returns**: The function returns nothing (`rts`). Register `%d0` is trashed (used as the loop counter).

**Key Operations**:
*   `movel %sp@(4),%d0`: Loads the delay parameter (milliseconds) from the stack into data register `%d0`.
*   `muluw #6000,%d0`: Multiplies the parameter by 6000. This constant is the number of loop iterations per millisecond, calibrated for the CPU's clock speed.
*   `subql #1,%d0` / `bnes 0x8087e2`: A two-instruction loop that decrements `%d0` and branches back until `%d0` becomes zero. This loop consumes the bulk of the delay time.

**Called Functions**: None. This is a leaf function.

**Notes**:
*   The function uses `muluw`, implying the input parameter is treated as a 16-bit unsigned value (0-65535 ms, or ~65 seconds max delay).
*   The loop is inefficient and blocks the DMA processor entirely for the duration. In a multi-processor system like the Plexus P/20, this could affect I/O or system management tasks handled by this processor.
*   The delay resolution is coarse (milliseconds). The constant 6000 was empirically determined for the 68010's clock speed in this system.
*   The function subtracts 1 (`subql #1,%d0`) after the multiplication, meaning a parameter of 0 would result in a loop count of -1 (0xFFFF), causing a very long delay (~65 seconds). This is likely a bug or oversight; the intended behavior for a 0ms delay should be near-instant return.
*   This routine is likely used for hardware timing, such as waiting for a SCSI controller or serial chip to respond after a command, or for creating a visible blink delay for the LED control register at `0xE00010`.

---

### Function at 0x8087e8

**Embedded strings:**
- `8423420`: `"NuBy"`

**Name**: `delay_1000_cycles`  

**Purpose**:  
This function implements a fixed-duration delay loop by performing 1000 iterations of a division operation. The division (`divsw %d1,%d2`) is likely used because it takes a significant number of clock cycles, making the loop a predictable time-waster. The function preserves the original value of `%d2` by saving it in `%a0` before the loop and restoring it afterward, indicating that the delay is the primary effect and `%d2` is not meant to be altered from the caller’s perspective.

**Parameters**:  
None explicitly passed; however, `%d2` is expected to be usable as a scratch register (though its original value is restored).

**Returns**:  
No explicit return value; all registers except `%d0` (used as loop counter) and `%d1` (temporary) are preserved. `%d2` is restored to its original value.

**Key Operations**:  
- Saves `%d2` into `%a0` before the loop.  
- Initializes `%d0` with 1000 (0x3E8) as the loop counter.  
- Each loop iteration:  
  - Sets `%d1` = 1 and `%d2` = 1.  
  - Performs signed word division `%d2 / %d1` (`divsw`), which is effectively 1/1.  
  - Uses `dbf` (decrement and branch) to repeat 1000 times.  
- Restores `%d2` from `%a0` before returning.

**Called Functions**:  
None.

**Notes**:  
- The division is unnecessary for computation (always 1/1) and is clearly chosen to consume CPU cycles.  
- This is likely a busy-wait delay for hardware timing, such as waiting for a SCSI controller response, serial port readiness, or memory/device settling.  
- The function is position-independent and uses no absolute memory accesses, making it safe to call from ROM.  
- Given the Plexus boot ROM context, this could be used during SCSI command pacing, floppy motor spin-up, or after writing certain control registers.  
- The string `"NuBy"` referenced nearby is unrelated to this function; it might be part of a message or error code elsewhere in the ROM.

---

### Function at 0x8087fe

**Embedded strings:**
- `8423560`: `"NuH@`"`
- `8423568`: `"/\nHA2<"`
- `8423590`: `" @$PB*"`

**Name**: `hardware_reset_and_init`

**Purpose**: This function performs a comprehensive reset and initialization of the Plexus P/20's hardware control/status registers. It clears various error and interrupt flags, configures the system control and serial port control registers, and includes a series of division-by-one operations that likely serve as a timing delay or synchronization mechanism. The overall goal is to place the system's hardware into a known, clean state, ready for further boot operations.

**Parameters**: None. The function operates solely on fixed hardware register addresses and the D0 register.

**Returns**: No explicit return value. The function modifies numerous hardware registers and the D0 register (which is left containing the result of the repeated divisions, likely 1).

**Key Operations**:
*   Clears (writes zero to) a series of "Reset" registers:
    *   `0xE00020`: Reset Multibus error flag.
    *   `0xE00040`: Reset SCSI parity error flag.
    *   `0xE00060`: Reset Job processor software interrupt.
    *   `0xE000A0`: Reset DMA processor software interrupt.
    *   `0xE000E0`: Reset Job processor clock interrupt.
    *   `0xE00100`: Reset DMA processor clock interrupt.
    *   `0xE00120`: Reset Job processor bus error flag.
    *   `0xE00140`: Reset DMA processor bus error flag.
    *   `0xE00160`: Reset Memory Parity error flag.
    *   `0xE00180`: Reset Switch Interrupt Latch.
    *   `0xE001A0`: Reset SCSI Bus Error Flag.
*   Configures the System Control Register (`0xE00016`):
    *   First, clears bit 4 (value `0xffef` = `~0x0010`) using `andiw`. Based on the bit definitions, this likely clears the `DIS.MAP` (disable memory map) bit.
    *   Then writes the value `0xA120`. This sets bits 15, 13, 9, and 5 (`0xA120` = `0x8000 | 0x2000 | 0x0200 | 0x0020`). Interpreting the provided bitfield, this likely enables the DMA processor boot (`Boot.DMA`), enables the Job processor boot (`Boot.JOB`), and sets two DIAG bits to a specific state.
*   Configures the Serial Port Control Register (`0xE0001A`) by writing `0xFFFF` (all bits set). This likely enables both transmitter and receiver (`TCE`, `RCE`) and possibly other control lines.
*   Executes six identical `divsw %d0,%d0` instructions. Since `%d0` is set to 1, each operation computes 1 / 1 = 1, leaving `%d0` unchanged. This is a classic delay loop technique; division is a relatively slow operation on many CPUs, so this sequence creates a predictable, hardware-independent pause.
*   Clears the word at address `0xE0000E`. This address is not documented in the provided register list. It may be an undocumented or reserved register, or related to a different hardware component (e.g., part of the SCC serial controller).

**Called Functions**: None. This function consists only of direct operations and returns with `rts`.

**Notes**:
*   The function is a "fire-and-forget" initialization routine. It doesn't read back any status after writing to the registers.
*   The sequence of clearing reset flags is very systematic, covering bus errors, parity errors, software/clock interrupts for both processors, and SCSI errors. This is a "clean slate" operation.
*   The use of `divsw` for delay is interesting. It's less common than a loop with `dbra` but provides a very compact and exact cycle count (for a given CPU model). On a 68010, each `divsw` takes a minimum of 158 cycles, making this a significant delay (~950 cycles).
*   The write to `0xE0000E` is an anomaly. Without documentation for that specific address, its purpose is unclear. It could be clearing a buffer pointer, a mode register for a peripheral, or a vestigial operation from an earlier hardware revision.
*   The function does not touch the LED control register (`0xE00010`), which is often used for diagnostic blinking during boot. This suggests it's focused on internal state initialization rather than user feedback.
*   Given its location in the U15 Boot Loader ROM and its actions, this function is almost certainly called early in the boot process, possibly immediately after the handoff from the U17 diagnostic ROM, to ensure a stable hardware foundation before attempting to load an operating system.

---

### Function at 0x80886e

**Embedded strings:**
- `8423560`: `"NuH@`"`
- `8423568`: `"/\nHA2<"`
- `8423590`: `" @$PB*"`
- `8423613`: `"1 AB"`

**Name**: `clear_memory_block`  

**Purpose**:  
This function clears a block of memory by writing zeros to consecutive longword (32-bit) addresses. It takes a starting address and a size in bytes, rounds the size up to the next multiple of 4, then writes zeros in a loop using a double-nested decrement-and-branch structure to handle large counts efficiently.  

**Parameters**:  
- `%sp@(4)` (stack offset 4): a 32-bit argument representing the size in bytes of the memory block to clear.  
- `%a0` is loaded with address `0x000000` (likely a base address for the memory region to clear, though the immediate zero suggests it may be set elsewhere or is a placeholder).  

**Returns**:  
- `%a0` points to the first address after the cleared block.  
- Memory from the initial `%a0` to `%a0 + rounded-up size` is filled with zeros.  

**Key Operations**:  
- Loads the size argument from the stack into `%d0`.  
- Divides the size by 4 (via `lsrl #2`) to get a count of longwords.  
- Uses a `dbf` loop to write zeros (`%d1` is zero) to `%a0@+`.  
- Uses a double-loop structure: the low word of `%d0` is used for the inner loop, and the high word (after `swap`) for an outer loop, allowing up to ~4.3 billion bytes to be cleared.  

**Called Functions**:  
None (no `jsr` or `bsr`).  

**Notes**:  
- The function assumes the size is at least 1 byte; if size is 0, the inner `dbf` will run 65536 times (since `dbf` decrements first), which is likely a bug unless the size is always non‑zero.  
- The double `dbf` loop with `swap` is a common 68000‑series idiom for handling counts larger than 65536.  
- The base address in `%a0` is hard‑coded as `0x000000`, which in the Plexus memory map is the start of main RAM. This suggests the function is used to clear a low‑memory region during boot.  
- The strings referenced nearby (e.g., `"NuH@`"`) appear unrelated to this function—they may be in a different part of the ROM.

---

### Function at 0x80888e

**Embedded strings:**
- `8423568`: `"/\nHA2<"`
- `8423590`: `" @$PB*"`
- `8423613`: `"1 AB"`
- `8423706`: `"HA$_Nu"`

**Name**: `initialize_scsi_target_parameters`

**Purpose**: This function initializes SCSI target parameter tables for multiple SCSI IDs (likely 0-7). It calculates a checksum of SCSI ID-specific data, uses that checksum to index into lookup tables for timing parameters, and populates a data structure for each SCSI ID with byte-wide fields including sync period, offset, transfer period, and control bytes for the OMTI 5200 SCSI controller.

**Parameters**: 
- Implicitly uses global data structures at known addresses:
  - Base address table at 0x8089be (points to per-SCSI-ID parameter blocks)
  - Checksum data at 0xD001C (13631516 decimal)
  - Timing lookup table at 0xD001E (13631518 decimal)
  - Two lookup tables at 0x808920 and 0x808930 containing encoded timing values

**Returns**: 
- No explicit return value; modifies in-memory SCSI parameter blocks starting at addresses from the table at 0x8089be
- Preserves register %a2 (saved/restored from stack)
- Returns via RTS

**Key Operations**:
- Loops through 8 SCSI IDs (counter in upper word of %d1)
- For each ID, clears first two bytes of its parameter block (offset 0 and 4)
- Calculates 16-bit checksum of 49 words (98 bytes) from fixed address 0xD001C
- If checksum equals 0x5A (90 decimal), uses secondary lookup; otherwise uses primary
- Limits SCSI ID to 0-5 range (special handling for ID 5)
- Indexes into two lookup tables (0x808920 and 0x808930) using checksum-derived index
- Stores retrieved bytes into parameter block at offsets 2, 10, 12, 14, 16, 20, and 22
- Sets fixed values: 0xC1 at offset 10, 0xC5 at offset 12, 0x0D at offset 22

**Called Functions**: None (no JSR/BSR instructions)

**Notes**:
- The function appears to be initializing SCSI negotiation parameters (sync period, offset, REQ/ACK timing)
- The checksum calculation at 0xD001C likely validates some hardware-specific configuration or ROM signature
- The lookup tables contain timing values for different SCSI device types (disks, tape, etc.)
- Special case for SCSI ID 5 suggests it might be reserved (controller's own ID)
- The parameter block structure appears to be 24+ bytes, with byte fields at specific offsets
- The use of both primary (0x808930) and secondary (via 0xD001E table) lookup suggests adaptive timing based on system configuration
- This is part of the boot loader's SCSI subsystem initialization, preparing for disk access

---

### Function at 0x808a9a

**Embedded strings:**
- `8424234`: `"N^NuNV"`

**Name**: `parse_path_components`  

**Purpose**:  
This function parses a Unix-style path string (passed as a pointer) by splitting it into slash-separated components, processing each component individually via a helper function, and reassembling the path after each step. It appears to be part of a bootloader’s filesystem path traversal logic—likely used to resolve a file path (e.g., `sc(0,0)/unix`) by iterating through directories. If a component lookup fails, it prints an error.  

**Parameters**:  
- `%fp@(8)` (first argument on stack): pointer to a null-terminated path string (in `%a5` after loading).  

**Returns**:  
- `%d0`: Returns the result from the last component lookup (likely a directory inode number or file handle), or zero if the entire path was processed successfully (or if an error occurred early).  

**Key Operations**:  
- Validates the input pointer is non‑null and points to a non‑empty string; if invalid, calls an error‑printing function with a fixed message address (`0x80c1c8`).  
- Calls `0x8089de` (likely `enter_directory` or `change_to_directory`) with argument `2` (might be a root‑directory indicator).  
- Skips consecutive slashes in the path.  
- For each path component between slashes:  
  - Temporarily replaces the slash or null terminator after the component with `0`.  
  - Calls `0x808cb6` (likely `lookup_component` or `open_inode`) on the component string.  
  - If lookup succeeds and there is more path after the component, calls `0x8089de` again (to descend into that directory).  
  - Restores the original separator and continues.  
- If a component lookup fails, calls an error‑printing function (`0x80a2fe`) with the component string.  

**Called Functions**:  
- `0x80a2fe` (error/print function, called when input is null or component not found).  
- `0x8089de` (directory‑change or directory‑open function).  
- `0x808cb6` (component lookup function, returns a handle/inode number).  

**Notes**:  
- The string at `0x80c1c8` (`8438216`) is likely an error message like `"bad path"` or `"missing file"` (referenced string `"N^NuNV"` may be a debug marker or corrupted data).  
- The function handles both absolute paths (starting with `/`) and relative paths by first calling `0x8089de` with argument `2`—possibly to set a starting directory (root).  
- It modifies the input string in‑place by temporarily zero‑terminating components, but restores the original separators afterward.  
- The return value is the result of the last `0x808cb6` call; if the path ends with a slash, it may return zero.  
- This is classic Unix path‑walking logic, consistent with a bootloader that needs to locate a kernel file (e.g., `/unix` or `sc(0,0)/unix`).

---

### Function at 0x808b2e

**Embedded strings:**
- `8424450`: `"gZHx"`
- `8424626`: `"N^NuNV"`

**Name**: `lookup_inode_block`  

**Purpose**:  
This function appears to be part of a Unix‑style filesystem boot loader that traverses an inode’s indirect block pointers to locate a specific data block. Given an input block number (likely a logical block within a file), it walks through the inode’s direct, single‑indirect, and double‑indirect block tables (up to triple‑indirect, though the code only handles up to double‑indirect here) to resolve the corresponding physical disk block address. If a required indirect block table is not already cached in memory, it reads it from disk via SCSI. The function is defensive: it calls an error handler if the input block number is out of range or if a required block pointer is zero (invalid).  

**Parameters**:  
- `%fp@(8)` (the first 32‑bit argument on the stack): the logical block number within the file (or an inode‑relative block index).  

**Returns**:  
- `%d0`: the resolved physical disk block address (or zero if the lookup failed).  

**Key Operations**:  
- Validates the input block number: negative values or values ≥ 10 trigger an error call (`0x80a2fe` with argument 3).  
- For block numbers 0–9, uses a direct pointer table at `%a5@(28)` (likely the inode’s direct block array).  
- For block numbers ≥ 10, subtracts 10 and begins processing indirect levels:  
  - `%d6` counts down from 3 (representing double‑indirect, single‑indirect, then direct level?), but the loop actually uses `%d6` as an index (0‑based) for the indirect level.  
  - `%d5` tracks a shift count (bits = `%d5*8`) used to extract index bits from the remaining block number.  
- Checks if the required indirect block (stored in a global array at `0xC03A0C + level*4`) is already cached; if not, reads it from disk via SCSI:  
  - Sets up SCSI transfer parameters in globals (`0xC03A8C`, `0xC03A90`, `0xC03A94`).  
  - Calls `0x8092ac` (likely `scsi_read`) with a device ID from `0xC03A30`.  
- Uses the fetched indirect block as a table of 256 block pointers (each 4 bytes).  
- Extracts an 8‑bit index from the remaining block number (shifted by `%d5`) to pick the next‑level pointer.  
- Repeats until the final physical block address is found.  
- On any zero pointer or out‑of‑range condition, calls the same error routine (`0x80a2fe` with argument 3).  

**Called Functions**:  
- `0x80a2fe` (called with argument 3): error handler, likely prints an error and halts/reboots.  
- `0x808580`: possibly a SCSI setup or buffer‑preparation routine.  
- `0x8092ac`: SCSI read routine (reads a block from disk).  

**Notes**:  
- The global array at `0xC03A0C` (referenced via `%a5` offset) holds cached indirect block addresses for each level.  
- The inode’s direct block pointers start at `%a5@(28)` (offset 28 into the inode structure).  
- The shift‑and‑mask logic (`%d5` increments by 8 each level) suggests 256 entries per indirect block (2⁸ = 256), which matches classic Unix filesystem indirect blocks.  
- The function only handles up to double‑indirect blocks (max `%d6` = 3), implying the boot loader may not support triple‑indirect files (or they are not needed during boot).  
- Hardware registers are not directly accessed here; instead, the function relies on lower‑level SCSI routines that presumably handle Omti 5200 controller registers.  
- The strings `"gZHx"` and `"N^NuNV"` are not referenced in this function; they may belong to adjacent code.

---

### Function at 0x808cb6

**Embedded strings:**
- `8424752`: `"n\Hx"`
- `8424894`: `"N^NuNV"`

**Name**: `boot_find_file_in_ramdisk`  

**Purpose**: This function searches for a file by name within a RAM disk structure loaded in memory. It appears to be part of the boot loader’s file‑system navigation, likely used to locate a kernel or other boot file in a memory‑resident archive (possibly a RAM disk or compressed filesystem image). The function iterates over directory‑like entries, comparing names until a match is found, and returns the file’s size or zero on failure.

**Parameters**:  
- `%fp@(8)` – Pointer to a null‑terminated filename string to search for.

**Returns**:  
- `%d0` – If successful, the file’s size (as a word from the entry) extended to a long word; otherwise zero.

**Key Operations**:  
- Checks the input filename pointer for NULL or empty string.  
- Reads hardware status from `%a4@(16)` (address `0xC03A34` – likely a shared memory variable area) and masks bits `0xF000`, verifying that bit `0x4000` is set (possibly a “RAM disk present” flag).  
- Calls a subroutine at `0x8086fe` with arguments `0x10` and a value from `%a4@(24)` (likely a base address or block number), returning a count (`%d7`) of directory entries.  
- Uses a loop counter `%d6` (initialized to 1024) that increments per entry; if `%d6` exceeds 64, it calls `0x808580` with argument `0x2` and a value from `0xC03A80` (likely loads another block of directory data).  
- For each entry, calls `0x808b2e` (likely computes an offset) and updates pointers in shared memory at `0xC03A8C`, `0xC03A90`, `0xC03A94`.  
- Calls `0x8092ac` with a word from `0xC03A30` (possibly a device/unit identifier).  
- Compares the filename against the current entry via `0x808dc2` (string compare function).  
- On match, returns the first word of the entry (file size); otherwise advances to the next entry by adding `16` bytes (suggesting a fixed‑size directory structure).

**Called Functions**:  
- `0x80a2fe` – Error handler or status reporter (called when hardware flag check fails or entry count is zero).  
- `0x8086fe` – Returns the number of directory entries in the RAM disk.  
- `0x808580` – Loads a new directory block into memory.  
- `0x808b2e` – Computes an offset within the directory block.  
- `0x8092ac` – Possibly validates or sets up a device context.  
- `0x808dc2` – String comparison (called with filename and entry name).

**Notes**:  
- The directory entry size is 16 bytes (increment by `0x10` at `0x808da8`). The first word of an entry appears to be a file size; the second word (`%a5@(2)`) is passed to the string compare, suggesting the filename starts at offset 2.  
- Shared memory addresses `0xC03A80`–`0xC03A98` are used as global pointers for the current directory block, file data pointer, and block size.  
- The function uses a “sliding window” approach: when `%d6` exceeds 64, it loads the next directory block, implying directory blocks are 64 entries × 16 bytes = 1024 bytes each.  
- The hardware flag check at the start suggests the RAM disk must be initialized and ready before searching.

---

### Function at 0x808dc2

**Embedded strings:**
- `8424970`: `"N^NuNV"`

**Name**: `strncmp_or_nullterm_match`

**Purpose**: This function compares two strings with a maximum length constraint, but with special handling for a '(' character (ASCII 40) in the first string. If the first string has '(' at the current position and the second string has a null terminator at the same position, it returns a match. Otherwise, it performs a character-by-character comparison up to a maximum of 15 characters (14 iterations of the loop, plus the initial check). It returns 1 if the strings are considered equal under these rules, and 0 otherwise.

**Parameters**: 
- `%fp@(8)` (`%a5`): Pointer to the first string (string A).
- `%fp@(12)` (`%a4`): Pointer to the second string (string B).

**Returns**: 
- `%d0`: Integer result. 1 if the strings match according to the special rules, 0 if they differ.

**Key Operations**:
- Sets up a stack frame and saves registers `%d7`, `%a4`, `%a5`.
- Initializes a loop counter `%d7` to 14 (maximum of 15 character comparisons).
- In each loop iteration:
    - Checks if the current character in string A is '(' (0x28).
    - If it is '(' and the current character in string B is null (0), it immediately returns 1 (match).
    - Otherwise, compares the current characters of both strings.
    - If they differ, returns 0 (no match).
    - If they are equal and non-null, increments both string pointers and continues.
    - If the character in string A is null, it also checks string B for null; if both are null, it returns 1, otherwise the loop ends.
- If the loop completes all 15 iterations without a mismatch, it returns 1 (strings match for the first 15 chars).
- Restores saved registers and returns.

**Called Functions**: None. This is a leaf function.

**Notes**:
- The special '(' check suggests this function is used in a command parser where a '(' might denote an optional part of a command (like a parameter list), and matching against a base command name (without parameters) should succeed. This aligns with the boot loader's command parsing (e.g., `sc(0,0)/unix`).
- The maximum comparison length of 15 characters is likely tuned to the maximum length of a boot command or filename token in the system.
- The function is position-independent and uses only registers and stack, making it safe to call from ROM.
- The string at address `0x8424970` ("N^NuNV") is not directly referenced in this code snippet; it may be in a data area used by a caller of this function.

---

### Function at 0x808e0e

**Embedded strings:**
- `8425042`: `"N^NuNV"`

**Name**: `boot_setup_memory_params`

**Purpose**: This function calculates and stores two memory parameters used during the boot process. It first calls a subroutine with a small argument (2) and a global address pointer, then calls the same subroutine again with a larger argument (0x400 = 1024) and a function argument pointer. It sums the two results and stores the sum and a zero into global memory locations. This appears to be setting up memory offsets or sizes, possibly for a boot image header or filesystem structure (like combining a header size and data size).

**Parameters**: 
- Input argument at `%fp@(12)` (likely a memory address or base value passed on stack).
- Global pointer at `0xc03a80` (used as second argument to first subroutine call).

**Returns**:
- Returns 0 in `%d0`.
- Primary outputs are side-effects to global memory:
  - Stores the input argument `%fp@(12)` to `0xc03a88`.
  - Stores the calculated sum (`%d0` from second call + result from first call) to `0xc03a8c`.
  - Clears (sets to zero) `0xc03a94`.

**Key Operations**:
- Calls a subroutine at `0x808580` twice with different arguments.
- First call: arguments `0x2` and the 32-bit value at global address `0xc03a80`.
- Second call: arguments `0x400` (1024 decimal) and the function's input argument `%fp@(12)`.
- Adds the two return values together.
- Writes results to three global memory locations in the shared RAM area (`0xc00000–0xc00fff` range):
  - `0xc03a88`, `0xc03a8c`, `0xc03a94`.

**Called Functions**:
- `0x808580` — Called twice. Based on its common use in the boot loader, this is likely a utility function that reads or computes a value from memory (possibly a word or longword fetch, or a simple arithmetic operation). Given the arguments (a small integer and a pointer), it might read a 16-bit or 32-bit value from an offset relative to the pointer.

**Notes**:
- The globals `0xc03a80`, `0xc03a88`, `0xc03a8c`, `0xc03a94` are in the shared RAM region used for inter-processor communication or boot parameters.
- The constants 2 and 0x400 suggest this is combining a small header size (2 bytes? though 2 might be an index/offset) with a block size of 1024 bytes (typical disk sector or filesystem block size).
- The function is likely preparing for a disk read or memory copy by computing total size = (value from first call) + (value from second call). The first call might retrieve a header or offset size, the second might retrieve a data size.
- The string `"N^NuNV"` at address `8425042` (0x808a12) is not referenced in this code; it might be in a different function.
- This is a helper function called during boot initialization, not a main command handler.

---

### Function at 0x808e56

**Embedded strings:**
- `8425190`: `": gPHx"`
- `8425326`: `"N^NuNV"`
- `8425350`: `"*H`"."`

**Name**: `get_next_char` or `buffered_char_reader`

**Purpose**: This function implements a buffered character reader that returns the next character from a buffered input stream, handling buffer refills and optional data transformation. It manages a circular buffer or similar buffering mechanism, reading data in 1KB chunks from a source (likely SCSI or filesystem), applies optional processing (via `0x808b2e`), and returns characters one at a time while updating buffer pointers and remaining count.

**Parameters**: 
- `%fp@(8)`: Likely a parameter indicating the source or mode (e.g., file descriptor, device ID, or flags). Used when calling `0x8092ac`.
- Memory-mapped variables at `0xc03a80`–`0xc03a98`: Buffer control structure including current pointer, remaining count, base address, and size.

**Returns**:
- `%d0`: The next character (lowest byte) as a zero-extended 32-bit value (0–255), or `-1` (0xFFFFFFFF) on end-of-buffer/error.
- Updates global buffer state at `0xc03a90` (current pointer), `0xc03a94` (remaining count), and `0xc03a88` (position offset).

**Key Operations**:
- Checks if buffer is empty (`0xc03a94 <= 0`) and refills if needed.
- Calls `0x808580` (likely `read` or `get_block`) to read 1024 bytes from offset `0xc03a88` into buffer at `0xc03a98`.
- If bit 3 of `0xc03a20` is set, calls `0x808b2e` to transform the buffer (e.g., decryption, checksum, byte-swap).
- Adds a 2-byte value (from `0xc03a80`) to the buffer base address (possible header skip or alignment).
- Calls `0x8092ac` with the input parameter to get a new buffer size (likely `read` or `open` for next chunk).
- If bit 3 of `0xc03a20` is set again, calls `0x80867e` (likely `strlen` or `find_zero`) to compute usable data length, adjusting `0xc03a94` to avoid overrunning a limit at `0xc03a3c` (max buffer end).
- Decrements remaining count, increments offset, and returns next byte from buffer.

**Called Functions**:
- `0x808580`: Reads data block (size, offset) → returns base address or status.
- `0x808b2e`: Transforms buffer data (conditional).
- `0x8092ac`: Gets new buffer size or opens next data chunk.
- `0x80867e`: Computes data length (likely `strlen` or `find_null`).

**Notes**:
- The buffer appears to be a sliding window over a larger data stream (like a file), with `0xc03a88` as a cumulative offset.
- The limit at `0xc03a3c` may be a buffer end guard to prevent overflow.
- Bit 3 of `0xc03a20` acts as a flag enabling data transformation and length checking, possibly for handling strings vs. binary data.
- The function maintains persistent state across calls (global variables), acting like a stateful iterator.
- The returned character is masked to 8 bits, but the full 32-bit value from the buffer is stored in `%d7` temporarily.
- The negative return (`-1`) occurs only when the adjusted remaining count becomes non-positive after length adjustment.

---

### Function at 0x808f72

**Embedded strings:**
- `8425350`: `"*H`"."`
- `8425404`: `"N^NuNV"`
- `8425422`: `": f&#"`
- `8425462`: `"`L 9"`
- `8425544`: `"N^NuNV"`
- `8425596`: `":| n"`

**Name**: `read_serial_string` or `console_read_line`

**Purpose**: This function reads a string from the serial console, up to a maximum of 4 characters, storing them into a buffer. It handles errors from the underlying serial read function and returns either the number of characters successfully read, -1 on error if no characters were read, or the accumulated buffer value if an error occurs after some characters have been read. The second part of the code (starting at 0x808fc0) appears to be a separate function that reads a specified number of bytes from a device (likely SCSI) into a buffer, managing a global offset and checking against a maximum limit.

**Parameters**: 
- For the first function (0x808f72): The parameter is passed at `%fp@(8)` (likely a device identifier or file descriptor).
- For the second function (0x808fc0): Three parameters: `%fp@(8)` (device/descriptor), `%fp@(12)` (buffer pointer), `%fp@(16)` (byte count).

**Returns**:
- First function: Returns in `%d0` either -1 (if error on first read), the 32-bit accumulated buffer value (if error after some reads), or the final buffer value (on successful read of up to 4 characters).
- Second function: Returns in `%d0` the number of bytes successfully read, or 0 if the requested count was <= 0.

**Key Operations**:
- First function (0x808f72):
  - Sets up a local buffer (4 bytes at `%fp@(-4)`) and uses `%a5` as a pointer into it.
  - Loops up to 4 times, calling a read function (0x808e56) each iteration.
  - Checks return value: negative indicates error. On first error, returns -1. On later error, returns the buffer contents so far.
  - On successful read, stores the byte (low 8 bits of return) into the buffer and increments count.
  - Returns the 32-bit buffer value after loop completes or on error.
- Second function (0x808fc0):
  - Checks a status bit at address `0xc03a20` (bit 3). If clear, it's a fast path: stores parameters into global variables at `0xc03a90` and `0xc03a94`, calls a function (0x8092ac), increments a global counter at `0xc03a8c`, and returns.
  - If the status bit is set, it's a slow path: calculates if the read would exceed a global limit at `0xc03a3c`, adjusting the count if necessary.
  - Then reads bytes one at a time via function 0x808e56, storing each into the buffer until count is exhausted.

**Called Functions**:
- `0x808e56`: A low-level read function (likely serial or SCSI byte read).
- `0x8092ac`: A function used in the fast path, possibly a block read or DMA transfer routine.

**Notes**:
- The first function is clearly a console/line input function: it reads exactly 4 characters (likely for a hex address or command) with basic error handling. The buffer is built as a 32-bit integer in big-endian order (first byte read becomes most significant byte).
- The second function has two modes: a fast block-transfer mode (when bit 3 at `0xc03a20` is clear) and a slow byte-by-byte mode (when set). The globals suggest a shared data area for DMA/buffer operations.
- Addresses `0xc03a20`, `0xc03a3c`, `0xc03a88`, `0xc03a8c`, `0xc03a90`, `0xc03a94` are in the shared RAM area (`0xC00000-0xC00FFF`), used for communication between processors or driver state.
- The function at 0x808fc0 is likely a `read` or `transfer` function for a block device (SCSI), with the ability to fall back to slow reads for debugging or error conditions.

---

### Function at 0x80904c

**Embedded strings:**
- `8425596`: `":| n"`
- `8425667`: `"!f\nR9"`
- `8425978`: `"f\nB9"`
- `8426030`: `": 09"`
- `8426046`: `"N^NuNV"`
- `8426060`: `": f\n."`
- `8426082`: `"N^NuNV"`

**Name**: `parse_boot_command`  

**Purpose**: This function parses a boot command string entered by the user at the ":" prompt, validates its syntax, matches it against a table of known boot commands, and sets up global system variables for the boot process. It handles optional command modifiers (like `!` for verbose mode and `/` for specifying a kernel path), extracts SCSI device parameters (controller, unit, partition), and dispatches to either a built‑in command or a filesystem‑based kernel load.  

**Parameters**:  
- `%fp@(8)` (first argument): Pointer to the boot command string (null‑terminated).  
- `%fp@(12)` (second argument): Likely a flag (e.g., boot source indicator).  

**Returns**:  
- `%d0`: On success, returns the index of the matched command in the command table (or a derived value). On error, returns `-1` (0xFFFFFFFF).  

**Key Operations**:  
- Skips leading spaces (ASCII 0x28) in the command string.  
- Calls `0x809388` (likely `strlen` or `atoi`) to compute the length of the first token.  
- Checks for a leading `!` (0x21) and sets a global flag at `0xc03a9c` (verbose mode).  
- Checks for a leading `/` (0x2F) and saves the pointer to a kernel‑path suffix in `%a3`.  
- Locates the first `(` (0x28) and `)` (0x29) to isolate SCSI device parameters.  
- Iterates through a command table at `0x809308` (16‑byte entries: command string pointer, handler, etc.) to match the command token.  
- On match, computes the command index and stores it in `0xc03a30`.  
- Parses SCSI parameters: controller, unit, and partition numbers from between parentheses, storing them in globals `0xc03a7c`, `0xc03a80`.  
- If no extra path follows the `)`, sets up a direct boot from the matched command’s handler.  
- If a path follows (saved in `%a3`), calls `0x808a9a` (likely `open` or `find_file`) and `0x8089de` (likely `load_kernel`) to load a kernel from the filesystem.  
- Updates the global boot‑control byte at `0xc03a20` with flags derived from the second argument and command type.  

**Called Functions**:  
- `0x809388` – string length or integer conversion.  
- `0x809f94` – prints a string (error messages).  
- `0x80ade0` – unknown (maybe clear screen or reset state).  
- `0x80a2fe` – error handler (takes error code argument).  
- `0x808dc2` – string comparison (command matching).  
- `0x808580` – unknown (maybe command‑index validation).  
- `0x8092cc` – sets up SCSI device parameters.  
- `0x808a9a` – opens a file or finds a kernel image.  
- `0x8089de` – loads a kernel into memory.  

**Notes**:  
- The command table is located at `0x809308`; each entry is 16 bytes. The function computes the index as `(current_entry - table_start) / 16`.  
- The global at `0xc03a20` appears to be a boot‑control byte where bit 0 indicates boot source (0 = built‑in, 1 = filesystem?), and bit 3 may be set for kernel‑load commands.  
- Error handling is done via `0x80a2fe` with error codes: 1 (missing '('), 4 (command not found), 5 (missing ',' or ')').  
- The function supports both built‑in commands (like `help`, `format`) and loading a Unix kernel from disk (e.g., `sc(0,0)/unix`).  
- The SCSI parameter format is `sc(controller,unit,partition)`.  
- The code is careful to handle optional verbose (`!`) and kernel‑path (`/`) prefixes, making it flexible for different boot scenarios.

---

### Function at 0x809242

**Embedded strings:**
- `8426060`: `": f\n."`
- `8426082`: `"N^NuNV"`
- `8426120`: `"N^NuNV"`

**Name**: `boot_clear_error_or_continue`

**Purpose**: This function checks a global error flag at address `0xC03A20` (bit 3) and, if the flag is not set, passes a pointer argument to a subroutine at `0x8092E6` (likely an error handler or logging routine). Regardless of the flag state, it then clears the entire byte at `0xC03A20` and returns zero. This suggests it is part of an error‑handling or boot‑progress mechanism, possibly clearing a pending error condition after optionally logging or processing it.

**Parameters**:  
- The function expects a single 32‑bit pointer argument on the stack at offset 8 from the frame pointer (`%fp@(8)`). This is likely an error message string or a context structure.

**Returns**:  
- Returns `0` in `%d0` (success/cleared status).  
- Side effect: clears the byte at `0xC03A20`.

**Key Operations**:  
- Tests bit 3 of the byte at address `0xC03A20` (a global flag in shared RAM).  
- If the bit is set (1), skips the call to `0x8092E6`.  
- If the bit is clear (0), calls `0x8092E6` with the pointer argument.  
- Clears the entire byte at `0xC03A20` (all eight bits).  
- Returns zero in `%d0`.

**Called Functions**:  
- `0x8092E6` – called only when bit 3 of `0xC03A20` is 0. Likely a routine that prints or logs the error/status message passed in the argument.

**Notes**:  
- The flag at `0xC03A20` is in the shared RAM area (`0xC00000–0xC00FFF`), accessible to both DMA and Job processors. Bit 3 may indicate a specific error or state (e.g., “error already logged” or “skip logging”).  
- Clearing the whole byte, not just bit 3, suggests `0xC03A20` is a multi‑purpose status byte that is reset after this check.  
- The function’s small size and location in the U15 boot ROM indicate it is a helper used during boot or SCSI operations to manage error reporting.  
- The strings at nearby addresses (`": f\n."`, `"N^NuNV"`) are not directly referenced here but may be used by the called subroutine `0x8092E6`.

---

### Function at 0x809266

**Embedded strings:**
- `8426120`: `"N^NuNV"`
- `8426151`: `"`N^NuNV"`
- `8426176`: `" @ PN"`
- `8426184`: `"N^NuNV"`

**Name**: `boot_error_handler` or `fatal_boot_error`

**Purpose**: This function handles a fatal error condition during the boot process. It first calls a diagnostic/error reporting subroutine with a specific error code or message identifier (0x80C1DB), then calls another subroutine (likely the main boot loop or a reset handler) with a different identifier (0x80C1E3). The function acts as a controlled error-handling path that logs/reports the error before transitioning to a recovery state or returning to the boot prompt.

**Parameters**: One 32-bit parameter passed on the stack at offset 8 from the frame pointer (likely an error code, address, or context pointer from the calling exception/error handler).

**Returns**: No explicit return value; the second `jsr` may not return (e.g., resets the boot process or enters a monitor loop).

**Key Operations**:
- Sets up a stack frame with `linkw %fp,#-4`.
- Retrieves the input parameter from the caller’s stack frame and places it on the current stack (likely preparing it for the first subroutine call).
- Pushes the immediate value `0x80C1DB` onto the stack as an argument.
- Calls subroutine at `0x809F94` (likely an error logging or display function).
- Pushes the immediate value `0x80C1E3` onto the stack (no cleanup between calls; the first call cleans its own stack with `addql #4,%sp`).
- Calls subroutine at `0x80928C` (likely a boot reset or main loop entry).
- Cleans up the stack frame and returns (though the second call may not return).

**Called Functions**:
- `0x809F94`: Possibly `print_error` or `log_fault` — based on nearby strings and common boot ROM patterns, this may format and output an error message to the console.
- `0x80928C`: Possibly `boot_main_loop` or `reset_boot_state` — given its proximity to this function and the boot loader entry point, this likely re‑enters the boot command parser or resets the boot environment.

**Notes**:
- The immediate values `0x80C1DB` and `0x80C1E3` are within the U15 ROM address space (`0x808000–0x80FFFF`). They likely point to error message strings or error‑code tables. Nearby strings at `0x826120`, `0x826151`, `0x826176`, and `0x826184` appear to be garbled or encoded; they might be related to error messages for SCSI, memory, or hardware faults.
- The function does not preserve the original parameter for the second call; it only uses it for the first diagnostic call.
- The second call’s address (`0x80928C`) is only 6 bytes after the end of this function, suggesting it is part of the same error‑handling module.
- Given the hardware context, this could be invoked from a bus error handler, SCSI timeout, or failed disk read during boot. The first call may report details (e.g., “SCSI sector read error”), while the second call restarts the boot prompt (“:”).

---

### Function at 0x80928c

**Embedded strings:**
- `8426151`: `"`N^NuNV"`
- `8426176`: `" @ PN"`
- `8426184`: `"N^NuNV"`
- `8426204`: `" @ PN"`
- `8426210`: `"N^NuNV"`

**Name**: `boot_error_handler` or `fatal_boot_error`

**Purpose**: This function handles a fatal error condition during the boot process. It saves an error address (likely a faulting program counter or stack pointer), prints a diagnostic message containing that address and a fixed string identifier, and then halts or resets the system via a jump to a known reset/entry point. The function acts as a centralized error trap.

**Parameters**: One 32-bit parameter passed on the stack at offset 8 from the frame pointer (`%fp@(8)`). This is likely an error code or, more specifically, a memory address (e.g., a fault address from a bus or address error exception).

**Returns**: This function does not return. It terminates by calling what is likely a system reset or restart routine.

**Key Operations**:
*   Establishes a minimal stack frame (`linkw %fp,#-4`).
*   Retrieves the 32-bit error parameter from the caller's stack.
*   Pushes this error address onto the stack for a formatting/printing subroutine.
*   Pushes the immediate value `0x0080c1e4` (address `0x80c1e4`) onto the stack. Based on the provided string list, this address likely points to the format string `"N^NuNV"` (or a similar pattern string used for `printf`-style formatting of an address).
*   Calls a formatting/output function at `0x809f94`. This is likely a `printf`-like routine that consumes the format string and the error address to print a diagnostic message to the console (e.g., `"Error at: xxxxxxxx"`).
*   Cleans up one longword argument from the stack (`addql #4,%sp`).
*   Calls a function at `0x808560`. Given the boot ROM context and this function's non-returning nature, this is almost certainly the system's primary reset or restart entry point (the documented `0x80854A` reset vector is very close). This call reboots or restarts the boot process.

**Called Functions**:
1.  `0x809f94`: A formatted print function. Takes at least a format string pointer and a corresponding argument (the error address).
2.  `0x808560`: The system reset/restart routine. This is likely the main boot loader entry point or a warm reset handler.

**Notes**:
*   The function is very compact and has a clear "report-and-die" structure, characteristic of fatal error handlers in boot ROMs.
*   The immediate value `0x0080c1e4` points into the ROM's string table. Cross-referencing with the provided strings, `0x80c1e4` falls within the range of the `"N^NuNV"` strings. This cryptic string is likely a format specifier for the boot monitor's internal `printf`, perhaps to display a longword in hex.
*   The final `jsr` to `0x808560` does not return; it restarts the system. Therefore, the `unlk` and `rts` instructions at the end of this function are **never executed**. They might be present for code consistency or because the function was adapted from a template.
*   Given its location in the U15 Boot Loader ROM and its behavior, this function is likely the default handler for severe faults (like bus errors, address errors, or failed assertions) encountered during the boot loading sequence.

---

### Function at 0x8092ac

**Embedded strings:**
- `8426176`: `" @ PN"`
- `8426184`: `"N^NuNV"`
- `8426204`: `" @ PN"`
- `8426210`: `"N^NuNV"`
- `8426230`: `" @ PN"`
- `8426236`: `"N^NuNV"`
- `8426244`: `"N^Nu"`

**Name**: `call_boot_menu_function`

**Purpose**: This function serves as a dispatcher for boot menu command handlers. It calculates the address of a function pointer from a table based on an index argument, pushes a constant argument (likely a mode or flag), and calls that function. This is the mechanism used to execute boot menu commands like `unix`, `help`, `format`, etc., after the user types a short command string at the ":" prompt.

**Parameters**:  
- One 32-bit integer parameter passed on the stack at offset 8 from the frame pointer (`%fp@(8)`). This is the index into the function pointer table, likely corresponding to a specific boot command.

**Returns**:  
- The return value (if any) is whatever the called function returns in `%d0` or other registers. This function itself does not modify the return value.

**Key Operations**:  
- Sets up a stack frame with a 4-byte local variable area (though not used).  
- Pushes the immediate value `0x1` onto the stack as an argument for the target function.  
- Takes the input index, multiplies it by 16 (left shift by 4), and adds the base address `0x80930c` to compute an address in a function pointer table.  
- Dereferences the computed pointer to get a function address and calls it via `jsr`.  
- Cleans up the stack after the call and returns.

**Called Functions**:  
- Calls a function whose address is stored in a table at `0x80930c + (index * 16)`. This table likely contains pointers to boot command implementations (e.g., `do_unix_boot`, `do_help`, `do_format`). The specific function depends on the input index.

**Notes**:  
- The table base `0x80930c` is in the U15 ROM space (`0x808000–0x80FFFF`), consistent with boot loader code.  
- The multiplication by 16 suggests each table entry is 16 bytes (4 bytes for the function pointer plus possibly other data like command strings or flags).  
- The constant `0x1` pushed as an argument may indicate a "boot" or "execute" mode to the handler.  
- The referenced strings at nearby addresses (e.g., `" @ PN"`, `"N^NuNV"`) are likely part of other data structures or error messages, not directly used in this function.  
- This is a classic command dispatch pattern: parse a token, map it to an index, then call through a jump table.

---

### Function at 0x8092cc

**Embedded strings:**
- `8426204`: `" @ PN"`
- `8426210`: `"N^NuNV"`
- `8426230`: `" @ PN"`
- `8426236`: `"N^NuNV"`
- `8426244`: `"N^Nu"`

**Name**: `dispatch_boot_command`  

**Purpose**:  
This function acts as a dispatcher for boot commands, using a lookup table to jump to the appropriate handler routine based on a numeric command index. It calculates an offset into a table of function pointers located at address `0x809310`, retrieves the pointer, and calls the corresponding function. This is likely part of the boot loader’s command interpreter, mapping user‑entered command codes (e.g., short codes like `?`, `help`, `unix`) to their implementation routines.

**Parameters**:  
- A 32‑bit integer command index passed on the stack at offset `8` from the frame pointer (`%fp@(8)`). This is presumably the numeric equivalent of a boot menu selection.

**Returns**:  
- The return value (if any) depends on the called handler; this function itself returns whatever the target function returns in `%d0` (or possibly other registers, per 68010 C calling conventions).

**Key Operations**:  
- Creates a stack frame with `linkw %fp,#-4`.  
- Multiplies the command index by 16 (`asll #4,%d0`), suggesting each table entry is 16 bytes (possibly containing more than just a function pointer, such as help text or flags).  
- Adds the base address of the jump table (`0x809310`) to the scaled offset.  
- Dereferences the calculated address to obtain a function pointer and jumps to it via `jsr`.  
- Cleans up the stack frame and returns.

**Called Functions**:  
- Indirect call via `jsr %a0@` to whatever function pointer is stored in the table at `0x809310 + (index * 16)`.  
- The table likely contains pointers to command implementations (e.g., `0x809310` might point to `help_command`, `0x809320` to `unix_boot`, etc.).

**Notes**:  
- The table base `0x809310` is within the U15 ROM range (`0x808000–0x80FFFF`), confirming it is part of the boot loader’s static data.  
- The scaling factor of 16 suggests each table entry may include additional metadata (e.g., command name string, help text, or flags) alongside the 4‑byte function pointer.  
- The strings referenced nearby (`" @ PN"`, `"N^NuNV"`, etc.) appear to be obfuscated or encoded data—possibly compressed or encrypted strings used by the boot menu.  
- This dispatch mechanism is typical of a command‑line interpreter that parses a token and invokes the corresponding routine. Given the Plexus boot menu’s documented short codes, this function likely implements the transition from parsed command to execution.

---

### Function at 0x8092e6

**Embedded strings:**
- `8426230`: `" @ PN"`
- `8426236`: `"N^NuNV"`
- `8426244`: `"N^Nu"`
- `8426408`: `"gNr "`
- `8426414`: `"gHr+"`
- `8426420`: `"gTr-"`
- `8426426`: `"gLr0"`
- `8426432`: `"g4rX"`
- `8426438`: `"g4rx"`

**Name**: `dispatch_scsi_command`  

**Purpose**:  
This function acts as a command dispatcher for SCSI operations. It takes a SCSI command index as input, uses it to look up a corresponding handler function from a jump table, and then calls that handler. The jump table appears to be stored starting at address `0x809314` (calculated as `0x809314 = 0x8426260 - 0x00809314?` Wait, careful: the `addil` adds `#8426260` to `%d0`; `8426260` decimal = `0x80A014` hex, not `0x809314`. Let’s check: `8426260` in hex is `0x80A014`. That’s in ROM space (U15 ROM is `0x808000–0x80FFFF`). So the jump table is at `0x80A014` plus offset from the index. The referenced strings nearby (e.g., `" @ PN"` at `0x8426230` = `0x80A230`) are in the same region, so the table is in U15 ROM. The function thus dispatches to various SCSI command handlers (likely for different SCSI device types: disk, floppy, tape).  

**Parameters**:  
One 32-bit integer parameter passed on the stack at `%fp@(8)`, interpreted as a SCSI command index (0-based).  

**Returns**:  
Returns whatever the called handler returns (likely in `%d0` or status flags). No explicit return value set in this dispatcher itself.  

**Key Operations**:  
- Multiplies the command index by 16 (`asll #4,%d0`) to compute an offset into the jump table (each entry is 16 bytes, possibly containing more than just the function pointer, maybe some config data).  
- Adds the base address of the jump table (`0x80A014`) to the offset.  
- Loads the first long word at that table entry as a function pointer (`moveal %a0@,%a0`).  
- Calls the function (`jsr %a0@`).  
- Cleans up stack frame and returns.  

**Called Functions**:  
- The function pointer from the jump table entry at `0x80A014 + (index * 16)` is called dynamically. From the data following `0x809308`, we see what looks like jump table data (addresses `0x80c1e8`, `0x80ad7e`, etc.), which are within U15 ROM range and likely point to SCSI command implementations (e.g., `scsi_read`, `scsi_write`, `scsi_inquiry`, `scsi_test_unit_ready`).  

**Notes**:  
- The code from `0x809300` to `0x809306` looks like a minimal dummy function (just `link`/`unlk`/`rts`), possibly a placeholder for unimplemented commands.  
- The data starting at `0x809308` appears to be part of the jump table (or a different table) interspersed with code due to disassembly misinterpretation — actually, `0x809308` might be data not code, given the `oril` instructions that don’t make sense as executable instructions here. Likely the jump table starts at `0x809308` or `0x809314`, but the `addil` uses `0x80A014`, so maybe the table is elsewhere.  
- The strings referenced (`"gNr "`, `"gHr+"`, etc.) look like SCSI command mnemonics or log messages for different SCSI phases (e.g., `gN` = get? Negotiation?, `gH` = get? Halt?, `gT` = get? Transfer?). Could be debugging strings for SCSI bus phases.  
- This dispatch mechanism allows the boot loader to support multiple SCSI device types (disk, floppy, tape) via a uniform interface.

---

### Function at 0x80945e

**Embedded strings:**
- `8426634`: `"N^Nu"`

**Name**: `copy_triplets_with_null_padding`

**Purpose**: This function copies data from a source buffer to a destination buffer in groups of three bytes, padding each group with a leading null byte. It repeats this pattern for a specified number of groups, effectively transforming a packed sequence of triplets into a 4-byte aligned structure where each original triplet becomes a 4-byte unit (0x00, byte1, byte2, byte3). This is likely used to unpack or reformat data for a protocol or hardware interface that expects data in 32-bit words with a specific byte layout.

**Parameters**: 
- `%fp@(8)` (first argument): Destination pointer (`%a5`)
- `%fp@(12)` (second argument): Source pointer (`%a4`)
- `%fp@(16)` (third argument): Number of triplets to copy (`%d7` used as counter)

**Returns**: 
- The destination buffer is modified in place.
- No explicit return value in registers; all modified registers (`%d7`, `%a4`, `%a5`) are restored from the stack before returning.

**Key Operations**:
- Sets up a stack frame and saves registers `%d7`, `%a4`, `%a5`.
- Loops for the specified count of triplets.
- For each iteration:
  - Writes a zero byte (`clrb %a5@+`) to the destination.
  - Copies three consecutive bytes from source to destination (`moveb %a4@+, %a5@+` repeated three times).
- Restores saved registers and returns.

**Called Functions**: None (no `jsr` or `bsr` instructions in the provided code range).

**Notes**:
- The function operates on byte granularity, not words or longwords.
- The pattern of writing a null byte followed by three data bytes suggests it might be converting 24-bit data into 32-bit data with a high-order zero byte, possibly for alignment or a specific hardware data format.
- The code from `0x80948e` to `0x80950c` appears to be data (likely a table of constants or addresses) and not part of the function's executable code. The function proper ends at `0x80948c` with the `rts`.
- The string "N^Nu" referenced is not directly used in this function; it may be located elsewhere in the ROM.

---

### Function at 0x809696

**Embedded strings:**
- `8427432`: `"N^NuNV"`

**Name**: `boot_initialize_system`  

**Purpose**:  
This function performs early system initialization for the DMA processor after the boot loader starts. It checks a stored magic value in shared RAM, resets the Job processor, clears critical memory regions (likely shared data structures), sets up pointer tables in shared RAM for system variables, initializes hardware via a subroutine, and prepares the system for further boot stages.  

**Parameters**:  
- No explicit parameters passed via registers; reads `0xc00274` (shared RAM word) as a persistent boot magic value.  
- Implicitly assumes hardware registers at `0xe000xx` are accessible.  

**Returns**:  
- No explicit return value; side effects include:  
  - `0xc00274` updated with magic value `0x04d2` (1234 decimal).  
  - Shared RAM regions `0xc00000–0xc00400` and `0xc03800–0xc03e00` zeroed.  
  - Pointer tables initialized in shared RAM (`0xc03804`, `0xc03808`, etc.).  
  - Job processor held in reset via `0xe00018` write.  

**Key Operations**:  
- Calls `0x80bb74` (unknown subroutine, possibly early hardware setup).  
- Writes `0` to `0xe00018` (KILL.JOB bit? — resets/halts Job processor).  
- Checks `0xc00274` for magic value `0x04d2`; if not equal, sets bit 5 at `0xe0000e` (unknown control) and stores magic.  
- Calls `0x8087fe` (likely console or debug output init).  
- Clears two memory ranges:  
  - `0xc00000`–`0xc00400` (1 KB, shared system variables).  
  - `0xc03800`–`0xc03e00` (1.5 KB, shared tables).  
- Stores hardcoded pointers into shared RAM locations (e.g., `0xc03804` = `0xc00000`, `0xc03808` = `0xc0001a`, etc.).  
- Loops 8 times to copy pointers from ROM table at `0x8089be` into `0xc03a04` + offset (each 64 bytes apart).  
- Calls `0x80888e` (likely SCSI or disk controller init).  
- Writes `0xff` to `0xc0380d` (maybe a flag or command byte).  
- Clears `0xc0026c` and `0xc03b24` (shared variables).  
- Stores `0xc03b24` byte into `0xc03b40` (longword).  
- Saves magic value back to `0xc00274`.  

**Called Functions**:  
- `0x80bb74` — unknown setup routine.  
- `0x8087fe` — likely console initialization.  
- `0x80888e` — likely SCSI or storage controller init.  

**Notes**:  
- The magic value `0x04d2` appears to be a “boot signature” stored in non‑volatile RAM (`0xc00274`), possibly to skip certain init steps on warm reboots.  
- The pointer table at `0x8089be` (ROM) contains 8 longwords copied into a shared RAM structure at `0xc03a04` + 36‑byte offset per entry — looks like a vector table for devices or filesystems.  
- Clearing memory ranges `0xc00000–0xc00400` and `0xc03800–0xc03e00` suggests these hold DMA‑processor‑owned shared data structures that must be zeroed before use.  
- Writing `0` to `0xe00018` asserts KILL.JOB (halts Job processor) during DMA processor boot.  
- The function ends without starting the Job processor; that likely happens later in the boot sequence.

---

### Function at 0x8097ac

**Embedded strings:**
- `8427974`: `"*@ ."`
- `8428140`: `"N^NuNV"`

**Name**: `load_and_execute_boot_image`

**Purpose**: This function loads a bootable Unix a.out executable from a SCSI device into memory, sets up the execution environment, and transfers control to the Job processor. It handles both the old-style (direct word reads) and new-style (block reads) boot image formats, validates the a.out header, calculates memory requirements, loads the text and data segments, zeroes the BSS, and finally starts the Job processor to run the loaded program.

**Parameters**: 
- `%fp@(8)` (first argument): A file descriptor or device handle (likely a SCSI LUN/device identifier) passed in `%d7`.
- `%fp@(12)` (second argument): An argument value stored at 0x77fff8 (shared memory) for the loaded program.

**Returns**: 
- Does not return to caller; transfers control to the loaded program via the Job processor.
- Side effects: Modifies global variables at 0xc03b4c and 0xc03b50 (memory size info), loads program into RAM, and sets hardware registers to start the Job processor.

**Key Operations**:
- Checks a global flag at 0xc03b48; if zero, calls `0x808e0e` with the device handle and zeros (possibly SCSI initialization).
- Reads the a.out header from the device using either sequential word reads (`0x809d04`) or block reads (`0x808f72`), depending on header magic number.
- Validates the a.out magic number: expects either 0x0108 (old format) or 0x0150 (new format, after byte-swapping).
- On error, prints a failure message via `0x809f94` and calls `0x809266` (likely error handler/reboot).
- Reads a.out header fields: text size, data size, BSS size, symbol table size, entry point, and relocation info.
- Calculates number of 4K pages needed for text and data+BSS segments, stores results at 0xc03b4c and 0xc03b50.
- Loads the combined text+data segment byte-by-byte into memory starting at a calculated base address.
- Zeroes the BSS segment.
- Sets up a jump table at absolute address 0x0 with entries pointing to 0x77fff4, the program argument, and a global at 0xc03aa0.
- Checks a hardware register at 0xc039fc (likely console status); prints a message if non-zero.
- Writes to hardware control registers: sets Boot.JOB bit (0x4000) at 0xE00016 and KILL.JOB bit (0x0002) at 0xE00018 to reset/start the Job processor.
- Calls `0x80851a` (likely Job processor start routine), then jumps to the loaded program's entry point via a pointer at 0xc00404.

**Called Functions**:
- `0x808e0e`: Possibly SCSI device initialization.
- `0x809d04`: Reads a word (16-bit) from the boot device.
- `0x809f94`: Prints a formatted string (used for error messages).
- `0x809266`: Likely error handler or reboot function.
- `0x809e80`: Performs a seek on the boot device.
- `0x808f72`: Reads a block from the boot device.
- `0x809d6c`: Reads a byte from the boot device.
- `0x809242`: Possibly flushes or finishes device reads.
- `0x809dc0`: Memory copy or fill routine.
- `0x809a70`: Unknown setup function.
- `0x80851a`: Job processor start routine.

**Notes**:
- The function supports two a.out magic numbers: 0x0108 (old, read as words) and 0x0150 (new, read as blocks). The new magic is byte-swapped (0x0150 becomes 0x5001) when read as a word, so the code shifts right 16 bits and masks to compare.
- It uses a fixed memory layout: loaded program segments are placed in low memory, with a small jump table at absolute address 0x0 that points to system data in high shared RAM (0x77fff4-0x77fffc).
- The hardware register writes at the end are critical: 0xE00016 bit 14 (Boot.JOB) releases the Job processor from reset, and 0xE00018 bit 1 (KILL.JOB) likely triggers a soft reset before starting.
- The function does not return; it ends by jumping to the loaded program via a function pointer that was presumably set up earlier (0xc00404 points to the entry point).
- Global variables at 0xc03b4c and 0xc03b50 likely store memory allocation information for the kernel or subsequent boot stages.

---

### Function at 0x809a70

**Embedded strings:**
- `8428250`: `"N^NuNV"`

**Name**: `boot_checksum_and_copy`  

**Purpose**:  
This function reads a data structure (likely a boot record or header) from a fixed location in memory, calculates a checksum by summing three fields, and conditionally prints a diagnostic message if a flag is set. It then copies the data structure to a destination address in the shared RAM area, padding with zeros if needed, until a target end address is reached.  

**Parameters**:  
- No explicit parameters passed via stack or registers; uses hardcoded addresses:  
  - Source data structure at `%a5` = `0x80cc60` (in U15 ROM space).  
  - Destination pointer `%a4` = `0xc00400` (shared RAM in the DMA processor's address space).  
  - Flag word at `0xc039fc` (likely a debug/diagnostic enable flag).  

**Returns**:  
- No explicit return value; modifies memory at `0xc00400` onward.  

**Key Operations**:  
- Loads three longwords from offsets 4, 8, and 12 of the source structure into `%d6`, `%d5`, `%d4`.  
- Computes checksum = `%d6 + %d5`, stored in `%d7`.  
- Checks flag at `0xc039fc`; if non‑zero, calls a print function with format string `0x80c335` (likely `"N^NuNV"` or similar debug format) and the three values.  
- Copies bytes from source structure (starting at offset 32) to destination `0xc00400`, decrementing checksum counter `%d7` each byte.  
- After copy, pads destination with zeros until `%a4` reaches `0xc03c00`.  

**Called Functions**:  
- `0x809f94` — a print/debug function (likely `printf`‑like) called only if flag at `0xc039fc` is non‑zero.  

**Notes**:  
- The source address `0x80cc60` is within the U15 boot ROM, suggesting the data is a packed boot image or filesystem metadata.  
- The destination range `0xc00400`–`0xc03c00` is in shared RAM, possibly used to stage a secondary bootloader or kernel for the Job processor.  
- The checksum is computed but not verified; it only controls the copy length. If the flag is set, the values are printed for debugging.  
- The padding to `0xc03c00` ensures a fixed‑size region is cleared, which may be required by the Job processor’s boot protocol.  
- The string `"N^NuNV"` at `0x80c335` likely decodes to a `printf` format like `"%x %x %x"` for the three longwords.

---

### Function at 0x809ade

**Embedded strings:**
- `8428376`: `";bN^NuNV"`
- `8428405`: `"fN^NuNV"`
- `8428432`: `";L(9"`
- `8428438`: `";P y"`
- `8428610`: `";T y"`
- `8428648`: `"NuNV"`
- `8428664`: `";L*|"`
- `8428702`: `"NuNV"`
- `8428720`: `";`*|"`

**Name**: `handle_bus_error_or_parity_error`

**Purpose**: This function handles either a bus error or a memory parity error, depending on the error code passed in. It prints diagnostic information about the error (including address and status) to a console or log, and if it's a parity error, it resets the parity error flag and sets a global status variable. If the error is not a parity error (code 0x104), it prints additional details and then calls a fatal error handler that likely halts or reboots the system.

**Parameters**: 
- `%fp@(76)` (word): Error code (e.g., 0x104 for parity error, others for bus errors)
- `%fp@(68)` and `%fp@(72)` (long): Two values that are printed as part of the error message (likely the faulting address and/or status register contents)
- `%fp@(80)` (long): Additional data printed if bit 7 of the error code is set (likely a special flag or extra error info)

**Returns**: 
- No explicit return value; the function either returns to caller (for parity errors) or calls a fatal error handler that does not return (for non-parity errors).

**Key Operations**:
- Compares the error code against 0x104 (260 decimal) to identify a memory parity error.
- Prints error strings using `jsr 0x809f94` (likely a formatted print function):
  - `";bN^NuNV"` (address 0x80c34b) for general error header.
  - `"fN^NuNV"` (address 0x80c362) with the error code and two parameters inserted.
  - `"NuNV"` (address 0x80c386) if bit 7 of the error code is set, printing the extra parameter.
- For parity errors (code 0x104):
  - Checks a global flag at `0xc03b60` (parity error handling enabled?).
  - Clears the parity error flag by writing to hardware register `0xe00160` (Reset Memory Parity error flag).
  - Sets a global status word at `0xc03b62` to 1 (parity error occurred).
- For non-parity errors:
  - Calls `jsr 0x809266` with argument 1 (likely a fatal error/panic handler that halts or reboots).

**Called Functions**:
- `0x809f94`: A formatted print function (takes string pointer and arguments).
- `0x809266`: A fatal error handler (likely `panic` or `reboot`).

**Notes**:
- The function uses a stack frame (`linkw %fp,#-4`) and accesses parameters at offsets 76, 68, 72, and 80 from the frame pointer. This suggests it is called from an exception handler (bus error or parity error exception) where these values are pushed onto the stack.
- The error code 0x104 matches the Motorola 68010 bus error format where bit 8 indicates a bus error, and additional bits indicate read/write, function code, etc. Here it's treated specially as a parity error.
- The hardware register `0xe00160` is documented as "Reset Memory Parity error flag" in the Plexus P/20 hardware context, confirming this is parity error handling.
- The global variable at `0xc03b60` likely controls whether parity errors are handled gracefully or cause a system halt.
- The function distinguishes between "real" bus errors (which are fatal) and memory parity errors (which can be cleared and logged). This is typical for systems with parity-protected RAM.

---

### Function at 0x809ca0

**Embedded strings:**
- `8428720`: `";`*|"`
- `8428800`: `"N^NuNV"`
- `8428825`: `"r`L."`

**Name**: `detect_ram_size`  

**Purpose**:  
This function determines the amount of installed RAM by performing a write‑read test on a range of memory addresses. It starts at address `0x800000` (the beginning of the ROM space) and walks downward in 256‑KB steps until it finds an address that does not alias back to itself, indicating the boundary between RAM and ROM or unmapped space. The result is the number of 256‑KB blocks of RAM present.

**Parameters**:  
None explicitly passed; the function uses hard‑coded address ranges and a status flag at `0xc03b60`.

**Returns**:  
The number of 256‑KB RAM blocks found is returned in `%d0` (and also stored in `%d7`). The status flag at `0xc03b60` is cleared on exit.

**Key Operations**:  
- Sets a flag at `0xc03b60` (likely a “busy” or “testing” indicator) to `1`.  
- Uses `%a5` as a pointer, starting at `0x800000` (the top of the physical address space below the ROMs).  
- In a loop, writes the pointer’s value to the location it points to (`movel %a5, %a5@`), then subtracts 256 KB (`0x40000`).  
- Compares the pointer with zero; if still positive, repeats the write–subtract cycle. This effectively writes a unique address to each 256‑KB block, walking downward from `0x800000` toward `0x000000`.  
- After the write phase, scans upward from `0x000000` in 256‑KB steps, checking whether the stored value equals the address of the block (`cmpal %a5@, %a5`).  
- If a mismatch occurs, or if the flag at `0xc03b62` becomes non‑zero (possibly an error flag set by an interrupt handler), the scan stops.  
- Counts the number of consecutive matching blocks in `%d7`.  
- Clears the busy flag at `0xc03b60` and returns the count.

**Called Functions**:  
None; this function contains no `jsr` or `bsr` instructions.

**Notes**:  
- The write phase (`0x809cba–0x809cc6`) writes the address of each 256‑KB block into the first longword of that block. This is a common RAM‑size detection technique: if the memory is present and not mirrored, the read‑back will match.  
- The scan phase (`0x809cd6–0x809cf0`) verifies the written values, counting contiguous valid blocks.  
- The addresses `0xc03b60` and `0xc03b62` are in the shared‑data area (`0xc00000–0xc00fff`); they likely communicate with the Job processor or a monitor routine (e.g., “testing in progress” and “error detected”).  
- The function assumes a maximum RAM size of 8 MB (`0x800000`), which matches the Plexus P/20 memory map (RAM from `0x000000` to `0x3fffff`). The loop actually tests up to `0x800000`, but the presence of ROM at `0x800000` and above would cause the test to fail early, limiting the count to installed RAM.  
- The strings referenced near the function (`";`*|"`, `"N^NuNV"`, `"r`L."`) are not used here; they likely belong to adjacent code (possibly error messages or console output).

---

### Function at 0x809d04

**Embedded strings:**
- `8428825`: `"r`L."`
- `8428904`: `"N^NuNV"`

**Name**: `read_big_endian_longword` or `read_network_long`

**Purpose**: This function reads a 32-bit big-endian (network byte order) longword from a byte-oriented input stream. It checks a global flag at `0xc03b48` to determine whether to use a simple memory read (if the flag is zero) or to call a helper function four times to read individual bytes and assemble them into a longword (if the flag is non-zero). The latter case is likely used for reading data from a serialized source like a SCSI data block, a file stream, or a network interface.

**Parameters**:  
- A pointer (likely to a stream or buffer structure) passed on the stack at offset `8` from the frame pointer (`%fp@(8)`).

**Returns**:  
- The assembled 32-bit longword in register `%d0`.

**Key Operations**:  
- Tests a global flag at address `0xc03b48` (likely a "streaming mode" or "direct memory access" flag).
- If the flag is zero, calls `0x808f72` with the pointer as an argument (likely a simple memory-fetch function).
- If the flag is non-zero, calls `0x809d6c` four times with the same pointer, each call returning one byte (extended to a longword).
- Stores the four returned bytes into consecutive byte locations on the stack (`%fp@(-4)` to `%fp@(-1)`).
- Assembles the four bytes into a 32-bit value in `%d0`, with the first byte read becoming the most significant byte (big-endian order).

**Called Functions**:  
- `0x808f72` — Likely a direct memory read or a simpler longword fetch function.
- `0x809d6c` — A byte-read function, called four times sequentially.

**Notes**:  
- The function is careful to sign-extend each byte to a word and then to a longword (`extw` then `extl`), though this is unnecessary for unsigned byte assembly; it may be a defensive coding practice or reused from a signed-byte context.
- The four bytes are stored into a temporary 32-bit stack variable at `%fp@(-4)`, then loaded back as a longword into `%d0`. This effectively constructs a big-endian longword from four independent byte reads.
- The global flag at `0xc03b48` suggests the system can operate in two modes: one where data is directly accessible in memory, and another where data must be read byte-by-byte from a device or buffered stream.
- This pattern is typical of code that reads structured data from a serialized source, such as a disk sector, network packet, or file stored in a.out or other binary formats.

---

### Function at 0x809d6c

**Embedded strings:**
- `8428986`: `";dN^NuNV"`

**Name**: `get_next_byte_or_call`  

**Purpose**:  
This function retrieves the next byte from a buffer pointer stored at `0xc03b64`, incrementing the pointer after reading. If a global flag at `0xc03b48` is zero, it instead calls a subroutine (`0x808e56`) with an argument from the caller’s stack. The function also checks whether the buffer pointer has reached a limit (`0xc03400`) and calls another subroutine (`0x809e38`) if the pointer is at or beyond that limit before reading. Essentially, it manages sequential byte reading from a memory buffer with boundary checking and fallback behavior.

**Parameters**:  
- Input parameter passed on the stack at `%fp@(8)` (used only if `0xc03b48` is zero).  
- Global buffer pointer at `0xc03b48` (flag) and `0xc03b64` (current read address).  
- Hard-coded buffer limit `0xc03400` (12596224 decimal).

**Returns**:  
- Returns the read byte zero-extended to a 32-bit long in `%d0`.  
- Side effect: increments `0xc03b64` by 1 after reading.

**Key Operations**:  
- Tests global flag at `0xc03b48` to decide between two code paths.  
- If flag is zero: calls subroutine at `0x808e56` with the caller’s stack argument.  
- If flag is nonzero: compares buffer pointer `0xc03b64` against limit `0xc03400`.  
- If pointer is below limit: reads byte from `*0xc03b64`, extends to long, increments pointer.  
- If pointer is at or above limit: calls subroutine at `0x809e38` first, then reads byte and increments pointer.  
- Uses `extw` + `extl` to zero-extend the byte to 32 bits.

**Called Functions**:  
- `0x808e56` — called when `0xc03b48` is zero (likely an alternative input routine).  
- `0x809e38` — called when buffer pointer reaches limit (likely refills or handles buffer exhaustion).

**Notes**:  
- The buffer pointer `0xc03b64` and flag `0xc03b48` are in the shared RAM area (`0xC00000–0xC00FFF`), suggesting they are shared between processors or used for boot I/O buffering.  
- The limit `0xc03400` is 0x3400 bytes above `0xc00000`, placing it within the shared variable region — possibly a circular buffer or bounded input queue.  
- The function appears to be part of a character/byte stream reader used by the boot command parser or serial input handler.  
- The string `";dN^NuNV"` at address `8428986` (0x8089ba) is not directly referenced here but may be related to the called subroutines.  
- The check `0xc03b64 >= 0xc03400` uses `bges` (signed branch), but since addresses are in the 0xC0xxxx range (negative in signed 24-bit context?), this might be intentional for wrap‑around detection.

---

### Function at 0x809dc0

**Embedded strings:**
- `8429108`: `"N^NuNV"`

**Name**: `boot_processor_switch`  

**Purpose**:  
This function temporarily switches the DMA processor to act as the Job processor by modifying system control registers, preserving the original exception vector table (at addresses 0x0 and 0x4), and then waiting for a flag to be set (likely indicating completion of a task or interrupt). After the flag is set, it restores the original exception vectors and returns. This appears to be part of a boot‑loader routine that allows the DMA processor to execute code in “Job processor mode” for initialization or diagnostic purposes.

**Parameters**:  
- Input arguments passed on the stack:  
  - `%fp@(8)` → new exception vector for address 0x0  
  - `%fp@(12)` → new exception vector for address 0x4  

**Returns**:  
No explicit return value; restores saved exception vectors and control registers before returning.

**Key Operations**:  
- Sets bit 8 (0x0100) in system control register `0xE00016` (likely enables “Boot.JOB” or similar mode).  
- Saves the current exception vectors from addresses `0x0` and `0x4` into registers `%d7` and `%d6`.  
- Writes the new exception vectors (passed as arguments) to addresses `0x0` and `0x4`.  
- Clears a flag at `0xC03B58`.  
- Sets bit 14 (0x4000) in `0xE00016` (likely “DIS.MAP” or mapping disable) and bit 1 (0x0002) in `0xE00018` (likely “KILL.JOB” or similar).  
- Waits in a loop until the flag at `0xC03B58` becomes non‑zero (polling).  
- Clears `0xE00018` (releases Job processor control).  
- Restores the original exception vectors to `0x0` and `0x4`.  
- Clears bit 8 (0x0100) in `0xE00016` (exits Job processor mode).  

**Called Functions**:  
- `0x8087e8` — called repeatedly while polling; likely a short delay or a service routine (e.g., `delay` or `check_interrupt`).

**Notes**:  
- The function manipulates critical system control registers that govern processor roles (DMA vs. Job) and exception handling.  
- The polling loop suggests coordination with the other processor or an interrupt handler that sets `0xC03B58`.  
- The saved/restored exception vectors at `0x0` (reset SP) and `0x4` (reset PC) imply the DMA processor may be taking over the Job processor’s reset vector during boot.  
- The string `"N^NuNV"` referenced nearby is not used in this function; it may belong to adjacent code.  
- This routine is likely called during the boot sequence to allow the DMA processor to perform early system initialization before handing control to the Job processor.

---

### Function at 0x809e38

**Embedded strings:**
- `8429180`: `"N^NuNV"`
- `8429220`: `"N^NuNV"`

**Name**: `boot_verify_memory_range`  

**Purpose**:  
This function appears to verify a range of memory (likely RAM) by writing a known value and reading it back, checking for consistency. It loops through up to 4095 locations starting from a base address stored at `0xc03a08`, writing the address itself to a test location (`0xc03a90`) and calling a verification subroutine. If the verification fails, it calls an error-handling routine; otherwise, it increments the counter and continues until the range is checked or an error occurs.

**Parameters**:  
- Implicit: Base address for verification is read from `0xc03a08` (likely set by earlier boot code).  
- Implicit: Verification and error-handling subroutines are fixed at `0x80bd42` and `0x80bc98`.

**Returns**:  
- No explicit return value in registers; success/failure is likely signaled via memory flags or hardware status (LEDs, serial output). The loop stops early on failure.

**Key Operations**:  
- Loads a pointer from `0xc03a08` into `%a5`.  
- Stores `%a5` into `0xc03b64` (possibly a “current test address” log).  
- Loops up to 4095 times (`0x0fff`), each iteration:  
  - Stores `%a5` into `0xc03a90` (write test pattern).  
  - Increments `%a5`.  
  - Calls verification routine at `0x80bd42`.  
  - If verification fails (`%d0` non-zero), calls error handler at `0x80bc98` and exits loop.  
  - Otherwise increments loop counter `%d7` and continues.  
- Restores registers and returns.

**Called Functions**:  
- `0x80bd42`: Likely `memtest_verify_word` — checks if the value written to `0xc03a90` matches expected pattern.  
- `0x80bc98`: Likely `boot_error` or `fail_and_halt` — handles memory errors, possibly blinking LEDs or printing to serial.

**Notes**:  
- The strings `"N^NuNV"` at nearby addresses may be debug output or error messages referenced by the called subroutines.  
- The memory addresses `0xc03a08`, `0xc03b64`, and `0xc03a90` are in the shared RAM area (`0xc00000–0xc00fff`), used for boot-time variables and test results.  
- The loop limit of 4095 suggests it might be testing a 4 KB block (or 4095 longwords), possibly the first page of RAM or a critical system data area.  
- This is likely part of the DMA processor’s early RAM validation before loading the kernel.

---

### Function at 0x809e80

**Embedded strings:**
- `8429220`: `"N^NuNV"`

**Name**: `wait_for_scsi_busy_clear`  

**Purpose**:  
This function polls a shared memory location (`0xc03a88`) that likely holds the SCSI controller's busy status. It waits in a loop until the value at that address matches the value passed in `%d7` (presumably a "not busy" or expected state), calling a helper subroutine at `0x808e56` on each iteration while the condition is not met. This is used to synchronize with the Omti 5200 SCSI controller during boot or disk operations.

**Parameters**:  
- `%fp@(8)` (first argument): Parameter passed to the helper function at `0x808e56` (could be a device/LUN identifier or retry counter).  
- `%fp@(12)` (second argument): Expected value to compare against `0xc03a88` (likely a "busy" flag clear value).  
- `0xc03a88`: Shared memory location containing SCSI controller status (busy/ready).

**Returns**:  
- No explicit return value; function returns when `*0xc03a88 == expected_value`.  
- Preserves `%d7` across the call.

**Key Operations**:  
- Saves `%d7` on the stack.  
- Loads expected status value from stack argument into `%d7`.  
- Loops while `*0xc03a88 != %d7`.  
- On each loop iteration, calls `0x808e56` with the first argument (possibly a delay, status check, or SCSI command retry).  
- Restores `%d7` and returns.

**Called Functions**:  
- `0x808e56`: Unknown helper; based on context, likely a short delay, SCSI status read, or controller reset step.

**Notes**:  
- The address `0xc03a88` is in the shared RAM region (`0xc00000–0xc00fff`) used for DMA/Job processor communication and hardware status mirrors.  
- The loop structure suggests a busy-wait with a subroutine call on each poll, which may handle timeouts or error recovery.  
- The string `"N^NuNV"` referenced nearby is unrelated to this function; it may be part of a larger message or error table in the ROM.  
- This is a low-level SCSI synchronization routine, critical during boot when reading the disk.

---

### Function at 0x809ea8

**Embedded strings:**
- `8429400`: `"N^NuNV"`
- `8429456`: `"N^NuNV"`

**Name**: `print_hardware_status`  

**Purpose**: This function reads and prints the contents of several hardware status registers located at the I/O base address 0xE00000. It appears to be a diagnostic or debug routine that displays system status information, likely for boot-time diagnostics or operator inspection. The function reads three groups of status words and formats them via a printf-like subroutine, then calls another routine (possibly to wait for user input or continue boot process).  

**Parameters**: None explicitly; the function uses a hardcoded base address in `%a5` (0xE00000) to access hardware registers.  

**Returns**: No explicit return value; side effects include printing to console and potentially affecting system state via the final subroutine call.  

**Key Operations**:  
- Sets up a stack frame and saves `%a5`.  
- Loads `%a5` with the hardware register base address 0xE00000.  
- Reads three sets of status registers:  
  1. First group: offsets 0x0, 0x2, 0x4 (likely System Status, Extended Status, and Job Processor Bus Error Address low word).  
  2. Second group: offsets 0x6, 0x8, 0xA, 0xC, 0xE (possibly SCSI, serial, or interrupt-related status words).  
  3. Third group: offsets 0x14, 0x16, 0x18, 0x1A, 0x1E (more status/control registers, e.g., Bus Error Details, Control Readback, Processor Status, Serial Status, etc.).  
- Each read is zero-extended from word to longword and pushed onto the stack for formatting.  
- Calls a formatting/output subroutine at 0x809F94 three times with different format string pointers (0x80C3E9, 0x80C412, 0x80C442).  
- Finally calls subroutine at 0x809266 (possibly a prompt or pause routine).  

**Called Functions**:  
- `0x809F94`: A printf-like function that takes a format string and variable arguments.  
- `0x809266`: Likely a helper such as `wait_for_key` or `next_boot_step`.  

**Notes**:  
- The format strings at 0x80C3E9, 0x80C412, and 0x80C442 are not decoded here but likely produce human-readable status lines (e.g., "Status: %04x %04x %04x").  
- The function reads both read-only status registers and read/write control registers (e.g., offset 0x16 is the System Control register but is read here for its current value).  
- This routine is probably part of the boot loader’s diagnostic menu, allowing an operator to view hardware state before proceeding.  
- The final `clrl %sp@` before calling 0x809266 suggests passing a null argument, perhaps to indicate “no input” or “default action.”

---

### Function at 0x809f5c

**Embedded strings:**
- `8429456`: `"N^NuNV"`

**Name**: `is_valid_scsi_lun_or_partition`

**Purpose**: This function validates SCSI LUN (Logical Unit Number) or partition number arguments. It checks whether the second parameter is either 0 or 1 (likely representing LUN 0 or LUN 1), and whether the first parameter is within the range 2–32 inclusive (likely representing a partition number or block offset). The function returns a boolean result indicating whether both parameters are valid according to these constraints.

**Parameters**: 
- `%fp@(8)` (first argument, stored in `%d7`): Likely a partition number or block index (range 2–32)
- `%fp@(12)` (second argument): Likely a LUN selector (0 or 1)

**Returns**: 
- `%d0`: Boolean result (1 = valid, 0 = invalid)

**Key Operations**:
- Tests if the second argument is 0 or 1 using `tstl` and `cmpl` with immediate value 1
- Tests if the first argument is between 2 and 32 inclusive using two comparisons (`>= 2` and `<= 32`)
- Returns 0 immediately if either validation fails
- Returns 1 only if both validations pass

**Called Functions**: None (leaf function)

**Notes**:
- The range 2–32 suggests this might be validating a partition number (where 0 and 1 might be reserved for boot blocks or superblocks) or a block offset within a partition.
- The LUN validation (0 or 1) matches the known hardware context: LUN 0 = first hard drive, LUN 1 = second hard drive. LUN 2 (floppy) is not accepted here, suggesting this function is specifically for hard disk operations.
- The function uses a typical Motorola 68010 stack frame with `linkw %fp,#-8` and preserves `%d7` across the call.
- The string "N^NuNV" at address 8429456 is not referenced in this function and appears to be unrelated.
- This appears to be a validation helper called during SCSI boot command parsing (e.g., for `sc(0,0)/unix` style commands).

---

### Function at 0x809f94

**Embedded strings:**
- `8429530`: `"f\po"`
- `8429568`: `"`0pO"`
- `8429690`: `"N^NuNV"`

**Name**: `printf_style_formatter` or `format_string_processor`

**Purpose**: This function implements a minimal printf-style format string interpreter, likely used by the boot loader for diagnostic or status output. It processes a format string (containing `%` specifiers) and a variable argument list, converting and outputting arguments according to the specifier. It handles integers in decimal, octal, and hexadecimal, characters, and strings, outputting via a character-printing subroutine.

**Parameters**: 
- `%fp@(8)`: Pointer to the format string (in register `%a5` after loading).
- `%fp@(12)`: Start of variable arguments (via `%a4` pointing to the first argument on the stack).

**Returns**: 
- No explicit return value. The function outputs characters via calls to `0x80a0d6` (likely a `putchar`-like routine). Registers `%d7`, `%a4`, `%a5` are preserved.

**Key Operations**:
- Scans the format string character-by-character until a `'%'` (ASCII 37) is found.
- For non-`'%'` characters, outputs them directly via `jsr 0x80a0d6`.
- Upon finding `'%'`, reads the next character to determine the format specifier:
  - `'d'`, `'o'`, `'x'`: Converts the next argument (32-bit integer) to decimal, octal, or hexadecimal string via `jsr 0x80a07e` (a conversion/output routine), passing the base (10, 8, 16).
  - `'D'`, `'O'`, `'X'`: Same as above (case-insensitive for these specifiers).
  - `'c'`: Outputs the next argument as a single character (low byte of the 32-bit value).
  - `'s'`: Outputs a null-terminated string pointed to by the next argument.
- Advances the argument pointer (`%a4`) appropriately after each specifier.
- Continues until the format string's terminating null.

**Called Functions**:
- `0x80a0d6`: Called to output a single character (argument in `%d7` low byte). Likely a `putchar` equivalent.
- `0x80a07e`: Called for integer conversion/output with arguments: integer value and base. Likely converts the integer to the specified base and outputs the resulting string.

**Notes**:
- The function is a classic, compact printf engine typical of boot ROMs, supporting only basic specifiers (`%d`, `%o`, `%x`, `%c`, `%s`). No width, precision, or flags are supported.
- It uses a variable argument list accessed via `%a4` pointing to arguments on the stack after the format string pointer.
- The specifier matching is case-insensitive for octal (`o`/`O`) and hex (`x`/`X`), and also accepts `'D'` for decimal (though `'d'` is the standard).
- The `'%'` detection loop is efficient: it outputs plain characters immediately and only processes specifiers when `'%'` is encountered.
- The function preserves registers `%d7`, `%a4-%a5` as per the ABI, suggesting it is intended to be called from other routines.
- The referenced strings (`"f\po"`, `"`0pO"`, `"N^NuNV"`) are likely not directly used by this function; they may be in other parts of the ROM.

---

### Function at 0x80a07e

**Embedded strings:**
- `8429778`: `"N^NuNV"`

**Name**: `boot_print_error_chain`

**Purpose**: This function prints a chain of error messages from a linked error structure. It appears to handle a boot loader error reporting mechanism where errors are linked together (possibly forming a list). The function first calls a helper to process the current error node, then recursively calls itself to handle any linked previous error, and finally prints a specific character from a message table based on a computed index. This is likely used to output verbose error codes or status messages during the boot process.

**Parameters**: 
- `%fp@(8)` (first parameter): Likely an error code or pointer to an error structure.
- `%fp@(12)` (second parameter): Likely a context pointer or base address for error message lookup.

**Returns**: No explicit return value; side effect is output to console (via `jsr 0x80a0d6`).

**Key Operations**:
- Sets up a stack frame with `linkw %fp,#-8` and saves `%d7`.
- Calls subroutine at `0x808580` with the two parameters.
- Checks return value; if non-zero, recursively calls itself (`0x80a07e`) with the same context and the return value as the new error parameter.
- Calls subroutine at `0x80867e` with the original parameters.
- Adds a fixed offset (`0x80c47e`, which is `8438910` decimal) to the return value, uses it as a pointer, fetches a byte from that address, and passes it to subroutine `0x80a0d6` (likely a character output routine).
- Restores `%d7` and returns.

**Called Functions**:
- `0x808580`: Unknown helper, possibly `error_get_previous` or `error_unpack`.
- `0x80867e`: Unknown helper, possibly `error_compute_index` or `error_get_type`.
- `0x80a0d6`: Likely `putchar` or `console_write_char` (outputs a single character).

**Notes**:
- The recursion suggests errors are linked in a list, with each node containing a previous error pointer.
- The fixed offset `0x80c47e` points into the boot ROM (U15) address space. This is likely an error message or code table. The string `"N^NuNV"` at address `8429778` (`0x80c47a`) is near this offset (`0x80c47e`), so the fetched byte may index into a string or symbol table.
- The function is located in the U15 boot loader ROM and is part of the error reporting infrastructure, possibly invoked when SCSI, filesystem, or boot command parsing errors occur.
- The use of both recursion and a final lookup/print operation indicates a two-phase error display: first output previous errors (chain), then output a terminal character/symbol based on the root error.

---

### Function at 0x80a0d6

**Embedded strings:**
- `8429846`: `"f*Hx"`
- `8429904`: `"N^NuNV"`
- `8429936`: `"N^NuNV"`

**Name**: `serial_send_break_or_loop`  

**Purpose**:  
This function appears to manage serial port break signaling or character transmission pacing, likely for the console SCC. When called with argument `-1`, it enters a loop that sends a break sequence (10× CR characters) via recursive calls, with polling on a hardware status bit between each character. When called with `0`, it simply polls the status bit and writes a null byte to the transmit buffer. For other argument values, it loops polling the status bit indefinitely. This suggests it is used to ensure proper serial handshake or to generate a break condition for terminal/console attention.

**Parameters**:  
- `%d7` (long): Argument passed on stack at `%fp@(8)`. Values:  
  - `-1` → send break sequence (10 carriage returns)  
  - `0` → send a single null byte  
  - other → just poll status without sending  

**Returns**:  
No explicit return value; side effects on serial hardware and possibly the shared data structure at `0xc03a04`.

**Key Operations**:  
- Calls subroutine at `0x80a154` (likely serial port initialization or status check).  
- Polls bit 2 of offset `14` in a structure pointed to by `*(0xc03a04) + 0x24`. This is likely a hardware status register mirror (e.g., SCC transmit buffer empty flag).  
- Writes bytes to offset `18` in the same structure (likely the SCC transmit data register mirror).  
- Recursively calls itself (`0x80a0d6`) to send sequential characters when in break-send mode.  
- Uses `%d6` as a loop counter (0–10) for sending 10 carriage returns (ASCII 13 = 0x0D).  
- Writes a null byte (`0`) to the transmit buffer when argument is `0`.

**Called Functions**:  
- `0x80a154` — unknown, but likely serial-related setup or status read.  
- `0x80a0d6` — recursive call to itself (tail recursion for looping).

**Notes**:  
- The shared memory pointer `0xc03a04` is in the fixed RAM area `0xC00000–0xC00FFF` used for shared variables. Offset `0x24` from there points to a hardware register block, possibly the SCC channel A control/data registers.  
- Bit 2 at offset `14` may correspond to “Transmit Buffer Empty” flag in an SCC status register.  
- Offset `18` is likely the transmit data register.  
- The function handles three distinct modes based on `%d7`, making it a multi-purpose serial output controller.  
- The recursive call at `0x80a11c` with argument `0xD` (carriage return) suggests console line discipline during break signaling.  
- The loop sending 10 CRs may be intended to ensure a clean line or wake-up sequence for the attached terminal.

---

### Function at 0x80a154

**Embedded strings:**
- `8429936`: `"N^NuNV"`
- `8429992`: `"N^NuNV"`

**Name**: `wait_for_scsi_phase`  

**Purpose**:  
This function repeatedly polls the SCSI bus phase by calling a helper function (at `0x80a174`) until it observes a specific sequence of SCSI phases. It first waits for the SCSI bus to enter phase `0x13` (likely a **command phase** or **status phase**), then waits for phase `0x11` (likely a **data-in phase** or **message-in phase**). If the second phase is not seen, it loops until it appears. This is typical of SCSI protocol handling where the host must synchronize with the target’s phase transitions during a command sequence.

**Parameters**:  
None explicitly passed; the helper function at `0x80a174` presumably reads the SCSI bus phase from hardware (e.g., OMTI 5200 controller registers).

**Returns**:  
No explicit return value; the function loops until the desired phase sequence is observed. The helper function likely returns the SCSI phase in `%d0`.

**Key Operations**:  
- Calls a subroutine (`0x80a174`) that reads the current SCSI bus phase.  
- Compares the returned phase value to `0x13` (first expected phase).  
- If matched, calls the subroutine again and compares to `0x11` (second expected phase).  
- If the second comparison fails, loops until `0x11` is seen.  
- Uses a stack frame (`linkw %fp,#-4`) though no locals appear needed — possibly for debugging or compatibility.

**Called Functions**:  
- `0x80a174` — presumably `read_scsi_phase()` or similar, returning SCSI phase in `%d0`.

**Notes**:  
- The phase values `0x13` and `0x11` correspond to SCSI bus phase codes:  
  - `0x13` = `0010011` binary → likely **command phase** (CD=1, IO=0, MSG=0) or similar, depending on OMTI mapping.  
  - `0x11` = `0010001` binary → likely **data-in phase** (CD=0, IO=1, MSG=0).  
- This sequence suggests waiting for the target to enter command phase, then data-in phase, which occurs during a SCSI read operation after the command is sent.  
- The function does not handle timeouts; it loops indefinitely until phases match.  
- The nearby strings `"N^NuNV"` are likely unrelated to this function — possibly leftover data or ASCII-art in the ROM.

---

### Function at 0x80a174

**Embedded strings:**
- `8429992`: `"N^NuNV"`
- `8430032`: `"`Z m"`

**Name**: `increment_and_call_0x80a1ac`

**Purpose**: This function increments a global counter at `0xc03b44`, calls a subroutine at `0x80a1ac` with a parameter from global `0xc03a04`, then resets the counter to zero and returns the subroutine's result as a byte-sized value. It acts as a wrapper that manages a call count and passes a data pointer (or value) to another routine, likely for diagnostic, logging, or state-tracking purposes during boot or SCSI operations.

**Parameters**: None explicitly passed via registers. The function reads a 32-bit value from the fixed memory address `0xc03a04` (likely a global variable or hardware register mirror in shared RAM) and uses it as the argument to the subroutine at `0x80a1ac`.

**Returns**: The low byte of the return value from the subroutine at `0x80a1ac`, zero-extended to a longword in `%d0`.

**Key Operations**:
- Increments the 32-bit global counter at address `0xc03b44` by 1.
- Pushes the value from global `0xc03a04` onto the stack as an argument.
- Calls subroutine at `0x80a1ac`.
- Clears the global counter at `0xc03b44` back to zero.
- Returns the low byte of the subroutine's result, extended to 32 bits.

**Called Functions**:
- `0x80a1ac`: A subroutine whose purpose is not defined here, but it takes one 32-bit argument (the value from `0xc03a04`) and returns a 16-bit value in `%d0` (the caller then truncates it to a byte).

**Notes**:
- The global at `0xc03a04` is in the shared RAM area (`0xC00000–0xC00FFF`), suggesting it holds system data accessible to both DMA and Job processors.
- The counter at `0xc03b44` is also in shared RAM, implying it tracks cross-processor or repeated events.
- The function carefully sign-extends then zero-extends the return value; this may be to ensure clean handling of a byte result from a word-returning subroutine.
- Given the boot loader context, this could be part of a SCSI command retry counter, a boot step tracker, or a diagnostic state logger. The strings referenced nearby (`"N^NuNV"` and `"`Z m"`) appear corrupted or encoded, possibly related to debug output or error codes.

---

### Function at 0x80a1ac

**Embedded strings:**
- `8430032`: `"`Z m"`
- `8430130`: `"N^NuNV"`
- `8430180`: `"n\npZ"`

**Name**: `serial_getc_with_timeout`  

**Purpose**:  
This function reads a character from a serial port with a timeout mechanism. It waits for the SCC’s receive‑ready flag to become set, reads the received byte, handles special characters (DEL/0x7F triggers a backspace and line‑clear sequence), optionally echoes the character, and updates the front‑panel LED register with the character value. If a timeout occurs before a character is ready, it returns 0; if the receive‑ready flag never becomes set, it returns ‑1.

**Parameters**:  
- `%fp@(8)` (`%a5` after load): Pointer to a data structure (likely a serial port context) where offset 36 contains a pointer to the SCC’s hardware registers.  
- `%fp@(12)`: A flag indicating whether to echo the received character (non‑zero = echo).

**Returns**:  
- `%d0`: The received character (0–255) on success, 0 on timeout, or ‑1 if the receive‑ready flag was never set.

**Key Operations**:  
- Polls the SCC status register at offset 14 (`%a0@(14)`) bit 0 (likely RxRDY).  
- Checks a global timeout flag at address `0xc03b44` (shared RAM) while waiting.  
- Reads the received byte from SCC data register at offset 18 (`%a0@(18)`).  
- If the character is 0x7F (DEL), calls a delay function (`0x80a0d6`) with argument 10, then calls another function (`0x80a2fe`) with argument 0x10 (likely to handle backspace/line‑clear).  
- Conditionally echoes the character by calling `0x80a0d6` with the character as argument if the echo flag is set.  
- Writes the character value to the LED control register at `0xe00010` (front‑panel display).  

**Called Functions**:  
- `0x80a0d6`: Likely a delay or character‑output routine (called with timeout value or character to echo).  
- `0x80a2fe`: Likely a line‑editing helper (called when DEL is received).

**Notes**:  
- The timeout mechanism uses a shared‑memory location (`0xc03b44`) that is probably updated by an interrupt service routine or a hardware timer.  
- The LED register write suggests the boot loader displays typed characters on the front‑panel hex display for debugging/status.  
- The function handles only 8‑bit characters (masks `%d7` with `0xff`).  
- The SCC register layout matches a Zilog 8530: offset 14 is the status register, bit 0 = Rx character available; offset 18 is the receive data register.  
- The DEL handling implies a simple console input line editor in the boot loader.

---

### Function at 0x80a236

**Embedded strings:**
- `8430180`: `"n\npZ"`
- `8430212`: `"n\npz"`
- `8430230`: `"g6r\n"`
- `8430236`: `"g*r\r"`
- `8430260`: `"g*r#"`
- `8430279`: `"~~\nB"`
- `8430330`: `"N^NuNV"`

**Name**: `read_and_process_console_input`

**Purpose**: This function implements a console input loop that reads characters from a serial port (likely the console), performs case conversion and backspace handling, processes special control characters (backspace, newline, carriage return, line kill, interrupt, EOF), and builds a null-terminated input line in a buffer. It appears to be the core input routine for the boot loader's command prompt.

**Parameters**: 
- `%fp@(8)`: Pointer to the start of an input buffer (likely passed in %a0 or on stack). The buffer is filled as characters are processed.

**Returns**:
- The input buffer is filled with the processed characters, terminated by a null byte (0x00).
- No explicit register return value; the buffer pointer is updated in %a5 (which is saved/restored).

**Key Operations**:
- Calls `0x80a1ac` (likely `getchar` or serial read) with a timeout/count argument (0x1) and a global variable address `0xc03a04` (possibly a serial port base or status).
- Masks the read character to 7 bits (`AND #127`).
- Converts uppercase letters (ASCII 65-90) to lowercase by adding 0xe0 (i.e., subtracting 32 via `SUBL %d0,%d7` with `%d0 = -32`).
- Checks if the previous character was a backslash (`\`, ASCII 92) and if so, converts lowercase letters (97-122) to uppercase by adding 0xe0.
- Processes special characters:
  - Backspace (ASCII 8, 0x08) or '#' (ASCII 35, 0x23): moves buffer pointer back one if not at start.
  - Newline (10, 0x0A), carriage return (13, 0x0D): terminates line with newline and null.
  - DC1 (17, 0x11) and DC3 (19, 0x13): ignored (likely flow control; loops back to read next).
  - CAN (24, 0x18) or '@' (64, 0x40): kills line (resets buffer pointer to start and outputs a newline via `0x80a0d6`).
- Normal characters are stored in the buffer and the pointer is incremented.
- Loops continuously until a line terminator (CR/LF) is received.

**Called Functions**:
- `0x80a1ac`: Likely `getchar` or serial port read function.
- `0x80a0d6`: Likely `putchar` or newline output function (called when killing a line).

**Notes**:
- The function uses a 7-bit clean input mask, suggesting it might be reading from a serial port with possible parity bit.
- The case-conversion logic is interesting: normally uppercase→lowercase, but if preceded by a backslash, lowercase→uppercase. This might be for escape sequences or file path handling (Unix paths are case-sensitive).
- Special character set includes:
  - ASCII 17 (DC1/XON) and 19 (DC3/XOFF) cause the loop to continue without storing anything (flow control ignore).
  - ASCII 24 (CAN) and '@' are line kill characters.
  - '#' is treated as backspace (possibly a secondary backspace key).
- The global at `0xc03a04` is in the shared RAM area (`0xC00000-0xC00FFF`), possibly holding a serial port base address or a read timeout counter.
- The function does not appear to echo characters; that likely happens in the called `getchar` function or elsewhere.
- This is clearly a line-editing routine for the boot loader's ":" prompt, supporting basic editing (backspace, kill line) and case conversion for file names.

---

### Function at 0x80a2fe

**Embedded strings:**
- `8430399`: `"B @/"`
- `8430428`: `"g*J9"`
- `8430436`: `"f""."`
- `8430471`: `"fN^Nu"`

**Name**: `print_device_boot_info`

**Purpose**: This function prints boot-related information for a specific device, likely as part of the boot menu or device selection process. It retrieves a device identifier and a corresponding string from a lookup table, prints them along with a separator string, and conditionally prints an additional character if a global flag is not set. The function appears to format and display device entries (e.g., "sc(0,0)" or similar) for user selection during the boot process.

**Parameters**: 
- One 32-bit integer parameter passed on the stack at `%fp@(8)`, used as an index into a device information table.
- Two additional 32-bit parameters at `%fp@(12)` and `%fp@(16)`, likely auxiliary data (e.g., a number or address) to be printed.

**Returns**: 
- No explicit return value (void function). Output is sent via called print functions.

**Key Operations**:
- Computes an offset into a device info table at base address `0x808940` using the formula: `offset = index * 6` (via `(index * 4) + (index * 2)`).
- Reads a single byte from the computed table address (`base + offset`) and stores it locally.
- Calls a print function (`0x809f94`) twice: first to print a fixed separator string at address `0x80c48f` (likely " @/"), then to print a 32-bit value fetched from the device table at `base + offset + 2`.
- Prints a newline (ASCII 0xA) via function `0x80a0d6`.
- Conditionally, if the local byte is non-zero AND a global flag at address `0xc03a9c` is zero, calls function `0x809266` with that byte (extended to 32-bit) as an argument.

**Called Functions**:
- `0x809f94` (called twice): Likely a formatted print function (similar to `printf`).
- `0x80a0d6`: Likely a character output function (prints a newline).
- `0x809266` (conditional): Possibly a function to print an additional character or device attribute.

**Notes**:
- The device table structure appears to be 6 bytes per entry: a byte at offset 0 (likely a flag or character), and a 32-bit value at offset 2 (likely a pointer to a device name string, like "sc" or "mt").
- The global flag at `0xc03a9c` (in shared RAM) may control verbose output or suppress certain details.
- The fixed string at `0x80c48f` (" @/") is likely a separator between the device index and the device name in the printed output.
- This function is likely part of a loop that iterates over available boot devices, printing each as a menu option (e.g., "0: sc(0,0)").
- The use of `0x808940` as a table base places it within the U15 ROM, suggesting the device table is compiled into the boot loader.

---

### Function at 0x80a3f8

**Embedded strings:**
- `8430700`: `"(@Bl"`
- `8430952`: `"N^NuNV"`
- `8431012`: `"N^NuNV"`

**Name**: `scsi_init_device` or `scsi_select_and_init_drive`

**Purpose**: This function initializes a SCSI device for boot operations by selecting a target device based on configuration data, setting up a device control block in memory, configuring the SCSI controller hardware registers, and waiting for the device to become ready. It appears to be part of the boot loader's device initialization sequence, preparing a specific SCSI device (likely a disk) for subsequent read operations.

**Parameters**: 
- Implicit parameter via global memory at `0xc0380c` (pointer to device configuration data)
- Global state at `0xc039f4` and `0xc039f8` (previous device IDs)
- Global pointer at `0xc039fc` (some status flag)

**Returns**: 
- Returns `0` in `%d0` on success, `-1` (`0xFFFFFFFF`) on timeout failure
- Updates global device ID at `0xc039f4` with selected device
- Resets global at `0xc039f8` to `-1`
- Initializes device control block structure in memory

**Key Operations**:
- Checks status at `0xc039fc` and calls error handler (`0x809f94`) if non-zero
- Validates previous device IDs at `0xc039f4` and `0xc039f8`, calls `0x80ab40` if both are valid
- Reads device configuration from structure at `0xc0380c` (byte at offset 1 = device ID)
- Calls `0x80851a` (likely `get_scsi_controller_base` or similar)
- Computes address of device control block: `0xc03814 + (device_id * 60)` (since `(id*64) - (id*4) = id*60`)
- Initializes control block fields: zeroes word at offset 10, sets pointer at offset 28, stores byte at offset 32
- Determines device type from configuration data (byte at computed address): checks if value is 8 or 3
- Based on device type, copies either 8 bytes from offsets 2-9 or 2-5 of config to different positions in control block
- Calls `0x808536` with controller base address
- Constructs SCSI controller command: `(1 << device_id) | 0x08`, duplicated to 16-bit pattern
- Writes to SCSI controller at `0xa70000` (likely OMTI 5200 command register)
- Sets up control register at `0xc03b68` and writes to `0xe0000e` (hardware control register via `%a5`)
- Configures additional control bits based on device type flag (bit 1 of control block)
- Waits for device ready by polling bit 1 of `0xe0000e` with ~100,000 iteration timeout
- On timeout, calls error handler (`0x809f94`) with string at `0x80c4b1`
- On success, calls `0x80a56c` (likely `scsi_command_complete` or `scsi_read_sector`)

**Called Functions**:
- `0x809f94` - Error/print function (called twice)
- `0x80ab40` - Unknown cleanup/preparation function
- `0x80851a` - Returns SCSI controller base address
- `0x808536` - SCSI controller initialization function
- `0x80a56c` - SCSI operation continuation function

**Notes**:
- The device control block structure appears to be 36+ bytes with fields at offsets: 0 (type?), 1 (flag), 10 (word), 12-19 or 20-27 (two longs), 28 (pointer), 32 (long).
- Hardware register `0xe0000e` (`%a5` points to `0xe0000e`) is used for SCSI control; bit 1 indicates device ready.
- The timeout loop counts to 100,000 (0x186A0) which at 10MHz would be ~10ms if each iteration is ~100ns.
- String `0x80c4b1` likely contains an error message like "SCSI device not responding".
- The function handles both type 8 and type 3 devices differently (possibly disk vs tape?).
- The SCSI controller command construction suggests device selection uses bitmask (`1 << id`) with bit 3 (0x08) possibly being a "enable" or "init" flag.

---

### Function at 0x80a56c

**Embedded strings:**
- `8431012`: `"N^NuNV"`

**Name**: `boot_disable_serial_interrupts`  

**Purpose**:  
This function disables serial port interrupts by clearing the relevant interrupt enable bits in the system control register, then calls a delay subroutine. It also checks a shared memory flag and, if set, triggers a debug output routine with a fixed string address.  

**Parameters**:  
- None explicitly passed, but reads from shared memory at `0xc039fc` (likely a flag) and `0xc03b68` (current system control register mirror).  

**Returns**:  
- No explicit return value; side effects on hardware registers and shared memory.  

**Key Operations**:  
- Checks a word at shared memory address `0xc039fc`; if non‑zero, calls `0x809f94` with a fixed string pointer (`0x80c4ce`, which points to `"N^NuNV"`).  
- Masks off bit 2 (value `0x0004`) in the mirrored system control register at `0xc03b68`.  
- Writes the updated value to the hardware control register at `0xe0000e` (likely the serial port interrupt enable/disable register).  
- Calls a delay function (`0x80ac2a`) with argument `2` (probably a short pause in timer ticks).  

**Called Functions**:  
- `0x809f94` – debug/print routine (only called if flag at `0xc039fc` ≠ 0).  
- `0x80ac2a` – delay function (takes one word argument on stack).  

**Notes**:  
- The string `"N^NuNV"` at `0x80c4ce` appears to be a debug or error message, possibly related to serial port initialization failures.  
- Writing to `0xe0000e` matches the hardware map: it is the “Active Write” region for serial port control (TCE/RCE bits). Bit 2 being cleared likely disables receiver/transmitter interrupt sources.  
- The function preserves the stack frame (`linkw`/`unlk`) but doesn’t use local variables; the frame may be for compatibility with calling conventions or debugging.  
- This routine is part of the boot loader’s hardware initialization, ensuring serial interrupts are quiet before proceeding with boot commands.

---

### Function at 0x80a5a8

**Embedded strings:**
- `8431134`: `"N^NuNV"`

**Name**: `boot_checks_and_init`  

**Purpose**:  
This function performs a series of system checks and initializations early in the boot process. It verifies the state of a shared memory variable, reads and validates hardware status bits from the system control/status registers, compares a stored value against expected constants, and conditionally calls error‑handling or initialization routines based on the results. It appears to be part of the boot loader’s hardware‑validation and setup sequence before proceeding to load an operating system.

**Parameters**:  
None explicitly passed; the function reads from fixed memory and I/O locations:  
- `0xc039fc` (shared RAM variable)  
- `0xe0000e` (hardware status register)  
- `0xc039f8` (another shared RAM variable)  

**Returns**:  
No explicit return value; side effects include possible error messages, LED updates, and system initialization.

**Key Operations**:  
- Checks a word at `0xc039fc`; if non‑zero, calls a subroutine with a hard‑coded longword argument (`0x80c4db`).  
- Reads the hardware status register at `0xe0000e` into `%d0`, masks it with `0x30a1` (bits 0, 5, 12, 13), and compares against `0x3081`. If mismatch, calls `0x80bbbe` with arguments `1` and `9`.  
- Compares the longword at `0xc039f8` against `1`; if equal, calls `0x80bbbe` with arguments `1` and `10`.  
- Compares the same longword against `−1`; if not equal, calls `0x80ab40`.  
- Finally, calls `0x80ac2a` with argument `1`.

**Called Functions**:  
- `0x809f94` – unknown subroutine (likely error/display routine).  
- `0x80bbbe` – likely an error‑reporting function (takes two integer arguments).  
- `0x80ab40` – unknown subroutine (conditional initialization).  
- `0x80ac2a` – unknown subroutine (takes one integer argument, perhaps final‑stage init).

**Notes**:  
- The mask `0x30a1` on the status register `0xe0000e` likely isolates specific hardware signals (e.g., power‑fail, bus‑grant, or SCSI status bits). The expected value `0x3081` suggests certain bits must be set/cleared for normal boot.  
- The variable at `0xc039f8` seems to hold a boot mode or diagnostic flag; values `1` and `−1` trigger different paths.  
- The function is defensive: it checks multiple hardware/software conditions and may output error codes (arguments `9` and `10` to `0x80bbbe` could be error identifiers).  
- The sequence suggests a “safe boot” validation before proceeding to load the OS.

---

### Function at 0x80a622

**Embedded strings:**
- `8431245`: `"*N^NuNV"`

**Name**: `boot_checks_and_init`  

**Purpose**: This function performs a series of system checks and initializations early in the boot process. It verifies the state of the DMA processor, reads hardware status registers to confirm expected configuration, validates a shared memory variable, and calls further initialization routines if conditions are met. It appears to be part of the boot loader’s hardware validation and setup sequence before proceeding to load an OS or boot menu.

**Parameters**: None explicitly passed; reads from fixed memory and hardware register addresses.

**Returns**: No explicit return value; may modify memory at `0xc039fc` and `0xc039f8`, and may call subroutines that have side effects.

**Key Operations**:
- Checks the word at `0xc039fc` (likely a DMA processor status flag) and, if non‑zero, calls a subroutine with a fixed argument (`0x80c4ec`).
- Reads the hardware status register at `0xe0000e` (part of the system status block), masks it with `0x30a1` (binary `0011 0000 1010 0001`), and compares to `0x3081` (`0011 0000 1000 0001`). This likely tests specific system‑control bits (e.g., enable flags, bus state).
- If the masked status does not match the expected value, calls an error‑handling subroutine with argument `9`.
- Tests the longword at `0xc039f8` (likely a boot‑related variable); if zero, calls the same error handler with argument `10`.
- Compares `0xc039f8` against `0xffffffff`; if not equal, calls subroutine `0x80ab40` (likely a hardware‑specific initialization).
- Finally, calls subroutine `0x80ac2a` with a zero argument (likely final‑stage boot initialization).

**Called Functions**:
- `0x809f94` – unknown, called when `0xc039fc` ≠ 0.
- `0x80bbbe` – error/status reporting function, called with arguments `9` or `10`.
- `0x80ab40` – hardware init routine, called if `0xc039f8` ≠ `0xffffffff`.
- `0x80ac2a` – final init routine, called with `0` on stack.

**Notes**:
- The mask `0x30a1` and compare value `0x3081` suggest the function is checking that specific bits in the system status register are set/cleared. Bit differences are `0x20` (binary `0010 0000`), which may correspond to a “DIS.MAP”, “EN.DMA”, or similar flag documented at `0xe00002`/`0xe0000e`.
- The two memory locations `0xc039f8` and `0xc039fc` reside in the shared RAM area (`0xc00000–0xc00fff`) and likely hold boot flags or processor handshake data.
- The function is defensive: it validates hardware state and shared memory before proceeding, and calls error handlers if checks fail.
- The string `"*N^NuNV"` referenced nearby is not used directly here but may be part of a larger error‑message table.
- This routine runs on the DMA processor, as it accesses DMA‑related status and calls boot‑loader functions.

---

### Function at 0x80a692

**Embedded strings:**
- `8431476`: `";h(y"`
- `8431582`: `"N^NuNV"`

**Name**: `scsi_init_or_reset_device`

**Purpose**: This function initializes or resets a SCSI device (likely the OMTI 5200 controller) by checking hardware status, verifying controller readiness, sending a SCSI command to a specific LUN, and updating system state variables. It appears to be part of the boot loader's device initialization sequence, ensuring the SCSI controller is ready before proceeding with disk operations.

**Parameters**: 
- Implicitly uses global memory locations:
  - `0xc039fc` (pointer to some status structure)
  - `0xc039f4` (current SCSI device/LUN state)
  - `0xc039f8` (previous SCSI device/LUN state)
- Hardware register `0xe0000e` (system status)
- Hardware register `0xa70002` (likely SCSI controller data/status)

**Returns**:
- Updates global memory:
  - `0xc039f4` and `0xc039f8` set to `-1` (0xFFFFFFFF) on exit
  - `0xc03804` structure's field at offset 14 set with value from `0xa70002`
- Returns nothing explicitly in registers (preserves most registers via stack)

**Key Operations**:
- Checks status at `0xc039fc` and calls error handler `0x809f94` if non-zero
- Reads system status from `0xe0000e`, masks bits (0x30a1), compares to 0x3081 (checking specific hardware flags)
- Validates `0xc039f8` equals 3, otherwise calls `0x80bbbe` with parameters (3, 10)
- Sets `0xc039f8` to 3
- Reads SCSI controller status from `0xe0000e` (via `%a5` = 0xe0000e), masks lower byte, compares to 0x99 (153) - likely checking controller ready state
- Reads SCSI data from `0xa70002` into `%d6`
- Sets bit 1 in `0xc03b68` (control register copy) and writes to SCSI controller (`%a5@`)
- Waits in loop for bit 7 of `0xe0000f` to clear (busy flag) with timeout of 1000 iterations
- Clears bit 1 in `0xc03b68` and updates controller
- Uses `0xc03804` as base pointer to device structure, calculates offset to LUN-specific data using formula: `offset = (d7 * 64) - (d7 * 4) + 0xc03814` where `%d7` is from `0xc039f4`
- Stores the value from `0xa70002` into structure at offset 14
- Based on lower 4 bits of the value, writes either 0xFF or 0xFE to `0xc0380d` (likely SCSI command register)
- Reads back response into `%d0`
- Sets both `0xc039f4` and `0xc039f8` to -1

**Called Functions**:
- `0x809f94` - Error handler (called if `0xc039fc` points to non-zero word)
- `0x80bbbe` - Error/status reporting function (called three times with different parameters: (3,9), (3,10), (3,9))

**Notes**:
- The function appears to handle SCSI controller initialization with timeout protection
- The address `0xa70002` is not in the documented memory map - likely SCSI controller data register
- The calculation `offset = (d7 * 64) - (d7 * 4) + 0xc03814` simplifies to `(d7 * 60) + 0xc03814`, suggesting a structure size of 60 bytes per LUN
- The values 0xFF and 0xFE written to the command register suggest SCSI TEST UNIT READY or similar commands
- The timeout loop at `0x80a744-0x80a760` waits for controller busy flag to clear
- The function resets global SCSI state variables to -1 on exit, suggesting it's a one-time initialization
- Hardware register `0xe0000e` is used both as SCSI status (via `%a5`) and system status (direct access)

---

### Function at 0x80a7e2

**Embedded strings:**
- `8431882`: `"N^NuNV"`

**Name**: `scsi_controller_init_or_status_check`

**Purpose**: This function performs initialization and status verification of the SCSI controller (likely the Omti 5200 at address 0xE0000E). It checks the controller's status register for expected values, waits for the controller to become ready (not busy), reads a configuration or status word from a known memory-mapped location (0xA70002), and based on that value, either updates a hardware control register (0xC03B68), stores a boot parameter, or modifies a memory-mapped I/O register related to SCSI ID or configuration. It appears to be part of the boot loader's SCSI subsystem initialization and sanity check.

**Parameters**: No explicit parameters are passed via stack or registers. The function reads from fixed memory-mapped addresses: SCSI controller status at 0xE0000E, a boot variable at 0xC039F8, a configuration word at 0xA70002, and a control register shadow at 0xC03B68.

**Returns**: No explicit return value. The function has side effects: it may update the SCSI controller's control register (via the shadow at 0xC03B68), store a value to 0xC03B6C, or modify a hardware register based on the configuration word. It also calls an error-handling function (0x80BBBE) with parameters (5,9) or (5,10) if checks fail.

**Key Operations**:
- Saves registers (d2, d6-d7, a5) and sets up a stack frame.
- Checks if a word at 0xC039FC is zero; if not, calls a function (0x809F94) with a hardcoded address (0x80C50E).
- Reads the SCSI controller status register at 0xE0000E, masks it with 0x30A1 (bits 13,12,8,6,0), and compares to 0x3081. If mismatch, calls error function (0x80BBBE) with parameters (5,9).
- Compares the value at 0xC039F8 to 5; if equal, calls error function (0x80BBBE) with parameters (5,10).
- Reads the low byte of the SCSI controller data register (a5 points to 0xE0000E) and checks if it equals 0xD9. If not, calls error function (5,9).
- Reads a configuration word from 0xA70002 into d6.
- Sets bit 1 in the shadow control register (0xC03B68) and writes it to the SCSI controller (a5@).
- Waits in a loop (up to 1000 iterations) for bit 7 of offset 1 from a5 (i.e., 0xE0000F) to clear (indicating controller not busy). Times out with error (5,9) if loop exceeds 1000.
- Clears bit 1 in the shadow control register and updates the controller.
- Examines the low byte of the configuration word (d6):
  - If 0, clears bit 0 in the shadow control register (0xC03B68).
  - If 2, stores the value from 0xC039F8 into 0xC03B6C.
  - If 4, performs a calculation using the value at 0xC039F4 to compute an address (0xC0381A + (value*60)), then ORs the word at that address with 4.

**Called Functions**:
- `0x809F94` - Unknown function, called if 0xC039FC is non-zero.
- `0x80BBBE` - Error or status reporting function, called with two integer arguments (likely error code and subcode).

**Notes**:
- The SCSI controller's base address is 0xE0000E (a5 points here). This matches the "Active Write" hardware register map where 0xE0000E is not explicitly listed, but appears to be the SCSI controller data/status port.
- The configuration word at 0xA70002 likely comes from a boot PROM or hardwired system configuration. Its values (0, 2, 4) determine different boot paths or SCSI modes.
- The shadow register at 0xC03B68 mirrors the SCSI control register; bits are set/cleared there before being written to the hardware.
- The timeout loop suggests this is a critical hardware handshake; the controller must become ready within a reasonable time.
- The calculation for case 4 (`value*60`) suggests indexing into a table of 60-byte structures at base 0xC0381A, possibly SCSI device entries or transfer control blocks. The OR with 4 likely sets a flag in one of these structures.
- The function is defensive: it performs multiple hardware checks and calls an error reporter if any fail, which is typical for boot firmware.

---

### Function at 0x80a90e

**Embedded strings:**
- `8432016`: `"*@+|"`
- `8432050`: `";j*n"`
- `8432056`: `"N^NuNV"`

**Name**: `boot_init_scsi_drive`  

**Purpose**:  
This function initializes or validates the SCSI controller and boot drive configuration. It checks hardware status registers for proper SCSI bus conditions, verifies a boot drive selection stored in shared RAM, calls a SCSI‑related setup routine if needed, and then configures a data structure in shared memory that points to a SCSI command buffer. It also sets a SCSI command byte to 0x08 (likely a TEST UNIT READY or REQUEST SENSE command) before returning.

**Parameters**:  
- No explicit register parameters.  
- Reads from fixed memory addresses:  
  - `0xc039fc` (word flag, possibly “SCSI busy” indicator)  
  - `0xe0000e` (hardware status register for SCSI/floppy?)  
  - `0xc039f8` (longword, boot device/LUN selection)  
  - `0xc039f4` (longword, possibly SCSI ID or unit index)  

**Returns**:  
- No explicit register return value.  
- Modifies shared memory:  
  - Writes to a structure at `0xc03814 + (index * 60)` (since `(index*64) - (index*4) = index*60`), fields at offset 44 and 48.  
  - Sets byte at `0xc03b6a` to 0x08 (SCSI command byte).  

**Key Operations**:  
- Checks word at `0xc039fc`; if non‑zero, calls `0x809f94` with a fixed argument (`0x80c51f`).  
- Reads hardware status register `0xe0000e`, masks with `0x30a1` (bits 13‑12, 8, 6, 0), compares to `0x3081`; if mismatch, calls `0x80bbbe(4,9)` (likely error reporting).  
- Compares `0xc039f8` to 4; if equal, calls `0x80bbbe(4,10)` (another error/status report).  
- If `0xc039f8` is not `-1`, calls `0x80ab40` (SCSI device initialization).  
- Computes an index from `0xc039f4` as `index*60`, adds base `0xc03814`, stores result in `%a5`.  
- Writes `0xc03b6a` into `%a5@(44)` (pointer to SCSI command buffer).  
- Writes `1` into `%a5@(48)` (likely a “command active” flag).  
- Calls `0x80ac2a(4)` (possibly SCSI command submission).  
- Stores `0x08` into byte at `0xc03b6a` (SCSI command code).  

**Called Functions**:  
- `0x809f94` — unknown, called if `0xc039fc` ≠ 0.  
- `0x80bbbe` — error/warning display, called twice with arguments (4,9) and (4,10).  
- `0x80ab40` — SCSI device initialization, called if boot device ≠ -1.  
- `0x80ac2a` — SCSI command submission routine, called with argument 4.  

**Notes**:  
- The structure at `0xc03814` appears to be an array of SCSI command control blocks, each 60 bytes long. Offset 44 holds a pointer to the SCSI CDB (Command Descriptor Block), here set to `0xc03b6a`. Offset 48 may be a status/active field.  
- The hardware register `0xe0000e` is not documented in the provided list; it might be SCSI‑bus or floppy‑controller status. Mask `0x30a1` tests specific bits (e.g., SCSI BSY, parity error, drive ready).  
- Command byte `0x08` is a standard SCSI opcode for `READ(6)` in older SCSI‑1, but could also be `TEST UNIT READY` in some OMTI 5200 variants. Given the boot context, `TEST UNIT READY` is plausible for drive validation.  
- The function seems to prepare a SCSI command, then likely triggers the DMA processor to execute it (the call to `0x80ac2a`).  
- The two error checks (for status register mismatch and boot device == 4) may correspond to invalid SCSI bus state or an unsupported LUN (LUN 4 is out of range; valid LUNs are 0‑2).

---

### Function at 0x80a9bc

**Embedded strings:**
- `8432178`: `"N^NuNV"`

**Name**: `boot_phase2_checks` or `system_initialization_checks`

**Purpose**: This function performs a series of system checks and initializations during the boot process. It verifies the state of shared memory variables, examines hardware status registers for specific conditions, and calls diagnostic or initialization routines based on those checks. It appears to be part of the secondary boot phase after the initial ROM startup.

**Parameters**: None explicitly passed; reads from fixed memory and hardware addresses:
- `0xc039fc` (shared RAM variable)
- `0xe0000e` (hardware status register)
- `0xc039f8` (shared RAM variable)

**Returns**: No explicit return value; may modify shared memory and hardware state via called functions.

**Key Operations**:
- Checks a word at shared address `0xc039fc`; if non-zero, calls a function with a hardcoded address (`0x80c530` likely a string or data pointer)
- Reads hardware status register `0xe0000e` (likely system status), masks bits with `0x30a1` (binary `0011 0000 1010 0001`), and compares to `0x3081` (`0011 0000 1000 0001`)
- If the masked status doesn't match expected value, calls diagnostic/error function `0x80bbbe` with parameters 2 and 9
- Compares value `2` against shared variable `0xc039f8`; if equal, calls `0x80bbbe` with parameters 2 and 10
- Compares value `-1` against `0xc039f8`; if not equal, calls initialization function `0x80ab40`
- Finally calls function `0x80ac2a` with parameter 2

**Called Functions**:
- `0x809f94`: Likely a print or log function (called when `0xc039fc` ≠ 0)
- `0x80bbbe`: Diagnostic/error reporting function (called twice with different error codes)
- `0x80ab40`: Initialization function (called when `0xc039f8` ≠ -1)
- `0x80ac2a`: Final initialization step with parameter 2

**Notes**:
- The hardware register `0xe0000e` isn't documented in the provided memory map; it appears to be an undocumented status register. The mask `0x30a1` suggests checking specific bits: likely monitoring DMA/JOB processor states, interrupt flags, or SCSI status.
- The shared variables at `0xc039f8` and `0xc039fc` appear to be boot flags or diagnostic results stored in the shared RAM area (`0xc00000-0xc00fff`).
- The error codes passed to `0x80bbbe` (9 and 10) may correspond to specific hardware faults or configuration issues.
- The function follows a pattern: check hardware status → check boot variables → perform conditional initializations → final system setup.
- The reference to string "N^NuNV" at address `8432178` isn't directly used here but may be related to error messages in called functions.

---

### Function at 0x80aa36

**Embedded strings:**
- `8432414`: `"N^NuNV"`
- `8432446`: `"NuNV"`

**Name**: `scsi_bus_reset_and_wait`  

**Purpose**: This function performs a SCSI bus reset sequence, waits for the bus to become free, and logs error conditions if the bus does not clear within a timeout. It appears to be part of the boot loader’s SCSI initialization or error recovery, ensuring the SCSI bus is idle before proceeding with disk operations.  

**Parameters**:  
- No explicit parameters passed via registers.  
- Reads hardware status from `0xa70002` (likely a SCSI or bus status register).  
- Uses memory locations `0xc039fc`, `0xc039f4`, `0xc039f8`, `0xc03b68`, and `0xc03b6c` for configuration and state.  

**Returns**:  
- Stores a calculated value (bus‑free time exponent?) in `0xc039f4`.  
- No explicit register return value; side effects on hardware and memory.  

**Key Operations**:  
- Checks `0xc039fc` for a flag; if non‑zero, calls `0x809f94` with a string pointer (`8439105`).  
- Reads SCSI/bus status from `0xa70002` and masks bits to isolate bus condition.  
- If bit 3 is not set, calls error‑logging function `0x80bbbe` with argument `5`.  
- Masks status to low 8 bits, clears bit 0 (??), and tests for a single bit set (power‑of‑two).  
- If not a single bit, calls `0x80bbbe` with argument `5` again.  
- Counts trailing zeros in the status (finds bit position) via shift loop, result in `%d6`.  
- Writes to SCSI control register at `%a5` (`0xe0000e`), setting/clearing bits in `0xc03b68` mirror.  
- Waits for bit 2 of `%a5@` to clear, with a timeout of 1000 iterations; on timeout, calls `0x80bbbe` with argument `1`.  
- Stores the bit‑position count (`%d6`) into `0xc039f4`.  
- Calls `0x80ac2a` with the value from `0xc03b6c` (likely a SCSI command block).  

**Called Functions**:  
- `0x809f94` – likely a print/debug output function (called with string pointer).  
- `0x80bbbe` – error/warning logging function (called with integer argument).  
- `0x80ab40` – unknown subroutine (only called if `0xc039f4` and `0xc039f8` are not `0xffffffff`).  
- `0x80ac2a` – likely a SCSI command submission or completion handler.  

**Notes**:  
- The hardware register `%a5` is set to `0xe0000e`, which is not explicitly listed in the provided memory map but appears to be a SCSI controller data/status register (given the context).  
- The timeout loop increments `%d7` and compares to 1000; this suggests a busy‑wait for SCSI BSY (busy) or similar signal to clear.  
- The function uses a mirror variable at `0xc03b68` for SCSI control bits, which is written to the hardware register.  
- The trailing‑zero counting suggests the SCSI status byte encodes bus states as bit flags, and the function wants to identify which single bit is set after reset.  
- The second code block (`0x80ab22`–`0x80ab3e`) appears to be a separate, small function that writes `3` to `0xc03804` (maybe a SCSI command register) and then prints a string (`8439118`) before entering an infinite loop (`60fe`). This might be a fatal error handler.

---

### Function at 0x80ab40

**Embedded strings:**
- `8432678`: `"N^NuNV"`

**Name**: `scsi_write_sector` or `write_disk_block`

**Purpose**: This function writes a sector of data to a SCSI disk (likely the boot device) using parameters stored in system memory. It validates SCSI controller and drive selection parameters, prepares the SCSI command block, triggers the write operation, and handles a special case for floppy disk writes (LUN 2) where it may patch data based on a hardware register read.

**Parameters**: 
- Global memory locations:
  - `0xc039f8`: Contains SCSI controller command block address (loaded into `%d7`)
  - `0xc039fc`: Pointer to SCSI controller status/ready flag (loaded into `%a0`)
  - `0xc039f4`: Drive/LUN selection parameter (loaded into `%d4`)
- Implicit parameter: Data to write is pointed to by `%a5` (initialized to `0xe00006`, a hardware register area)

**Returns**: 
- No explicit return value; function side-effects are the SCSI write operation and potential memory modification.
- Restores previous interrupt state via `jsr 0x808536` with saved value from `%d6`.

**Key Operations**:
- Validates that the SCSI controller is ready (`tstw %a0@`), and if not, calls error handler `0x809f94` with address `0x80c560` (likely an error message).
- Validates drive/LUN parameter (`%d4`) is between 0 and 8 inclusive; if out of range, calls `0x80bbbe` with error code 7.
- Validates SCSI command block address (`%d7`) is between -1 and 6 inclusive; if out of range, calls `0x80bbbe` with error code 8.
- Disables interrupts via `jsr 0x80851a`, saving old SR in `%d6`, and clears bit 0 of `0xc03b68` (interrupt enable flag), writing to hardware register `0xe0000e`.
- Computes address of SCSI command block table: base `0xc03814 + (%d4 * 60) + 12 + (%d7 * 8)`.
- Writes two longwords from `%a5` (starting at `0xe00006`) into the SCSI command block: first at offset 4, then at offset 0.
- Checks bit 0 of byte at `%a5+3`; if set and `%d7` is odd (bit 0 = 1), reads byte from hardware register `0xa70000` into `%d5` and writes it to `-1` from the address in the first longword from `%a5`.
- Restores interrupt state via `jsr 0x808536` with saved SR.

**Called Functions**:
- `0x809f94`: Error handler (called if SCSI controller not ready)
- `0x80bbbe`: Parameter error handler (takes error code on stack)
- `0x80851a`: `disable_interrupts` (returns old SR)
- `0x808536`: `restore_interrupts` (takes old SR on stack)

**Notes**:
- The hardware register `0xe00006` is not documented in the provided list; it may be part of the SCSI controller interface (Omti 5200).
- The special case for odd `%d7` with bit 0 set in `%a5+3` suggests handling for floppy (LUN 2) where a byte from `0xa70000` (possibly a floppy control register) is patched into the data buffer before writing.
- The SCSI command block table at `0xc03814` appears to be an array of 9 drives (0-8), each with multiple command blocks (0-5?), each block being 8 bytes (two longwords).
- The function is likely part of the low-level disk I/O routines used by the boot loader to read/write sectors during boot or disk operations.

---

### Function at 0x80ac2a

**Embedded strings:**
- `8432776`: `"f( y"`
- `8432822`: `";h"9"`
- `8433018`: `"N^NuNV"`

**Name**: `scsi_select_device_and_configure`  

**Purpose**:  
This function configures the SCSI bus for a specific target device (likely a disk or tape) by setting the appropriate SCSI data bus value and updating hardware control registers. It selects a SCSI target ID based on an input parameter, adjusts the system control register (`0xC03B68`) to reflect the selection, and may conditionally manipulate the SCSI data bus output (`0xA70000`) if the target is an OMTI 5200 controller (ID 0 or 1). It also ensures the DMA processor’s interrupt state is preserved and restored.

**Parameters**:  
- `%d7` (long): SCSI target ID (0–7). The function treats IDs 0 and 1 specially (OMTI controller), and ID 4 triggers additional control register masking.

**Returns**:  
- No explicit return value; side effects on hardware registers and memory.

**Key Operations**:  
- Reads `0xC039FC` and calls `0x809F94` if the word there is non‑zero (likely an error handler).  
- Calls `0x80851A` (preserves return value in `%d6`), likely to save interrupt state.  
- Modifies the system control register mirror at `0xC03B68` using a lookup table at `0x8089B2 + 2 * target_id`.  
- For target IDs 0 or 1, checks `0xC0380C+2` (a SCSI‑related address range) and conditionally clears bit 12 (0x1000) in `0xC03B68`.  
- Writes `0xC03B68` to hardware register `0xE0000E` (via `%a4`).  
- Computes an offset into a device table at `0xC03814 + 76 * index` (from `0xC039F4`) and copies two long words from the table entry to `0xE00006` (via `%a5`).  
- Stores the target ID at `0xC039F8`.  
- If bit 0 of `0xE00009` is set (OMTI controller flag), extracts a byte from the device table (either the last byte before the base address for ID 0/1, or the first byte for others), forms a 16‑bit value, and writes it to SCSI data bus register `0xA70000`.  
- For target ID 4, clears bit 2 (0x0004) in `0xC03B68`.  
- Sets bit 0 (0x0001) in `0xC03B68` and updates `0xE0000E` again.  
- Restores interrupt state via `0x808536` using saved `%d6`.

**Called Functions**:  
- `0x809F94` — error/exception handler (called if `0xC039FC` non‑zero).  
- `0x80851A` — saves interrupt/status state (returns a value saved in `%d6`).  
- `0x808536` — restores interrupt/status state (using `%d6`).

**Notes**:  
- The function uses two important hardware register addresses:  
  - `0xE0000E` (`%a4`) = system control register (write).  
  - `0xE00006` (`%a5`) = SCSI control/data register (write).  
- The lookup at `0x8089B2` likely maps SCSI IDs to bit patterns for the control register.  
- The device table at `0xC03814` has 76‑byte entries (size inferred from `%d0 = %d1*64 + %d1*4`). Each entry contains sub‑entries per target ID (8 bytes each: two long words).  
- The SCSI data bus write (`0xA70000`) only occurs for OMTI controllers (IDs 0/1) when a flag in the device table is set; the byte used is either the last byte before the base address (ID 0/1) or the first byte of the base address (others).  
- The function carefully preserves and restores the interrupt state, indicating it may be called in contexts where interrupts must not be disrupted.

---

### Function at 0x80ad7e

**Embedded strings:**
- `8433116`: `"N^NuNV"`
- `8433135`: `",`,p"`

**Name**: `boot_scsi_read_boot_block`  

**Purpose**:  
This function reads the first block (likely the boot block or superblock) from a SCSI disk. It prepares parameters for a lower-level SCSI read routine by extracting device and LUN information from shared memory variables, calls that routine to perform the read, then calls another function to process the loaded block (possibly validating or interpreting it). Finally, it prints a status message.

**Parameters**:  
- Inputs are taken from fixed shared memory addresses:  
  - `0xC03A8C` (likely contains SCSI target ID or block number offset)  
  - `0xC03A7C` (likely contains combined device/LUN/flags)  
- No explicit register parameters; assumes shared memory is set up by earlier boot code.

**Returns**:  
- No explicit return value; side effects include reading data into memory (likely at address `0x80C580` or similar), updating shared variables, and printing a message.

**Key Operations**:  
- Stores a destination memory address (`0x80C580`) onto the stack as a parameter for the SCSI read routine.  
- Calls `0x80B01E` (possibly SCSI controller initialization or selection).  
- Extracts and manipulates values from `0xC03A8C` (shift left by 1) and `0xC03A7C` (mask bit 0, shift right by 1) to form SCSI command parameters.  
- Pushes multiple arguments (likely: unit, block count, block offset, device/LUN, command opcode) for `0x80B052` (SCSI read/write routine).  
- Calls `0x80AF7A` to process the read block (maybe check boot signature or parse filesystem).  
- Prints a message via `0x80B0F0` with string address `0x80C585` (likely a status string like “boot block loaded” or similar).

**Called Functions**:  
- `0x80B01E` – SCSI setup or device selection  
- `0x80B052` – Main SCSI read/write routine  
- `0x80AF7A` – Boot block verification or interpretation  
- `0x80B0F0` – Print string (console output)

**Notes**:  
- The shared memory addresses `0xC03A7C` and `0xC03A8C` are in the fixed “shared variables” area (`0xC00000–0xC00FFF`), suggesting they hold boot device parameters selected by the user (e.g., `sc(0,0)`).  
- The constants `0x80C580` and `0x80C585` are in ROM data area (U15), likely containing a buffer address and a status string.  
- The argument `0x8` pushed before `0x80B052` may be a SCSI command opcode (e.g., READ).  
- The sequence `asll #1` and `asrl #1` suggests converting between block numbers and sector offsets (since SCSI disks often use 512‑byte sectors but boot may think in 1K blocks).  
- This appears to be part of the default boot path after the “:” prompt, reading the first disk block to begin loading the kernel.

---

### Function at 0x80ade0

**Embedded strings:**
- `8433135`: `",`,p"`
- `8433283`: `"@pdg( y"`
- `8433299`: `"@scg"`
- `8433526`: `"N^NuNV"`
- `8433556`: `"g* y"`

**Name**: `boot_load_unix_kernel`  

**Purpose**:  
This function loads a Unix kernel from a SCSI disk into memory, validates its executable header, copies boot parameters into a known location, and initiates kernel execution. It appears to be the core routine that transfers control from the boot loader to the Unix kernel after validating the kernel image’s format and compatibility.  

**Parameters**:  
- Implicitly uses global memory locations:  
  - `0xc03a7c` – Likely a boot device/unit identifier (e.g., SCSI target/LUN).  
  - `0xc03a98` – Source address of the loaded kernel image in memory.  
  - `0xc0380c` – Pointer to a boot parameter/control block.  

**Returns**:  
- No explicit register return value; the function prepares the kernel in memory and presumably jumps to it later (though the actual jump is not in this code snippet).  
- Modifies global memory at `0xc03aa4` (kernel header pointer), `0xc03aa8` (boot parameter string), and `0xc0380c` (boot control block).  

**Key Operations**:  
- Waits up to 300 iterations for a device-ready condition via `0x80b22c` (likely a SCSI/disk status check).  
- Prints a boot message via `0x80b0f0` (string at `0x80c58a`).  
- Calls `0x80b29c` – possibly a SCSI read or device initialization.  
- Validates the kernel’s executable header magic number: checks for `0x7064` (pdp-11 a.out magic) or `0x7363` (likely a.out magic for 68000).  
- Validates the kernel’s header flag at offset 400 (`0x0190`), expecting 0 or 1.  
- Copies kernel boot parameters (408 bytes from offset `0x0198` in the kernel header) into a boot parameter block at `0xc03810` indexed by the device unit.  
- Fills a boot control structure at `0xc0380c` with:  
  - Unit number in byte 1.  
  - Command byte 6 (likely “load/execute kernel”).  
  - Kernel header address at offset 2.  
  - Kernel entry point (offset `0x0194`) at offset 6.  
- Calls `0x80af7a` (likely kernel launcher or final setup).  
- Copies a null-terminated parameter string from kernel offset 32 to `0xc03aa8`.  

**Called Functions**:  
- `0x80b22c` – Device status check.  
- `0x8087da` – Delay or timeout helper.  
- `0x80b0f0` – Print string.  
- `0x80b29c` – Device read/initialization.  
- `0x80ad7e` – Possibly kernel image decompression or relocation.  
- `0x809f94` – Error message printer.  
- `0x809266` – Error handler or reboot.  
- `0x80af7a` – Kernel entry preparer.  

**Notes**:  
- The kernel header validation suggests support for two a.out magic numbers (`0x7064` and `0x7363`), indicating compatibility with PDP‑11‑style or early 68000 Unix kernels.  
- The boot parameter block at `0xc0380c` is structured like a classic Unix boot param block (command, unit, kernel address, entry point).  
- The function assumes the kernel image is already loaded at `0xc03a98` (likely by a prior SCSI read).  
- If the kernel magic or flags are invalid, it prints an error (strings at `0x80c58f` or `0x80c5a9`) and likely halts or reboots.  
- The final parameter string copy suggests the kernel may receive a boot command line (e.g., “sc(0,0)/unix”).

---

### Function at 0x80af7a

**Embedded strings:**
- `8433556`: `"g* y"`
- `8433615`: `"(`  "`
- `8433682`: `"N^NuNV"`
- `8433690`: `"N^NuNV"`
- `8433742`: `"N^NuNV"`

**Name**: `wait_for_scsi_ready_or_timeout`

**Purpose**: This function waits for the SCSI controller to become ready (busy flag clear) with a timeout mechanism, printing status messages if the expected SCSI ID doesn't match or if the timeout expires. It appears to be part of SCSI command preparation or completion polling, ensuring the controller is ready before proceeding with operations.

**Parameters**: 
- `%fp@(8)` (first argument on stack): Expected SCSI ID (likely target device ID) to verify against the controller's current setting.

**Returns**: 
- No explicit return value; function returns when SCSI controller is ready (busy flag clear) or after timeout messages.
- Preserves `%d7` register across the function.

**Key Operations**:
- Reads SCSI controller status from `0xc0380c` (Omti 5200 controller status register) at offset 1 to get current SCSI ID.
- Compares read SCSI ID with expected parameter; prints error message via `0x809f94` with format string at `0x80c5d5` if mismatch.
- Calls `0x80a38e` (likely SCSI command setup) with the expected SCSI ID.
- Calls `0x808528` (likely SCSI command execution or controller start).
- Implements a polling loop with timeout counter (`%d7`) up to 20,000,000 iterations.
- Polls two hardware flags:
  1. SCSI controller busy flag: bit 7 of `0xc0380c+1` (negative flag test).
  2. System status bit: bit 1 of `0xe0000e` (likely SCSI-related system flag).
- Prints timeout message via `0x809f94` with format string at `0x80c5f2` every 20 million iterations.
- Calls `0x80851a` (likely SCSI completion/cleanup) before returning.

**Called Functions**:
- `0x809f94`: Print formatted message (takes two arguments: format string address, value).
- `0x809266`: Unknown function (called with `-1` argument after SCSI ID mismatch).
- `0x80a38e`: SCSI command preparation (takes SCSI ID argument).
- `0x808528`: SCSI command execution/start.
- `0x80851a`: SCSI completion/cleanup.

**Notes**:
- The function uses a software timeout counter rather than a hardware timer, which is typical for simple polling in boot ROM code.
- The two polled flags suggest waiting for both the SCSI controller's internal busy state and an external system status bit related to SCSI operations.
- The strings referenced (`0x80c5d5` and `0x80c5f2`) likely contain error messages like "SCSI ID mismatch" and "SCSI timeout" respectively.
- The address `0xc0380c` matches the Omti 5200 SCSI controller's register space in the memory map (though not explicitly listed, consistent with SCSI controller location).
- The function preserves `%d7` across calls, suggesting it's a callee-saved register in this calling convention.
- The timeout reset (`moveq #0,%d7`) after printing timeout message allows continuous polling with periodic status updates rather than hard failure.

---

### Function at 0x80b016

**Embedded strings:**
- `8433690`: `"N^NuNV"`
- `8433742`: `"N^NuNV"`

**Name**: `empty_stack_frame`  

**Purpose**:  
This function creates and immediately destroys a stack frame without performing any actual operations. It appears to be a minimal placeholder or stub function, possibly inserted for debugging, alignment, or as a target for patching. Given its location in the U15 boot ROM, it might be a remnant of removed code or a reserved slot for future expansion.  

**Parameters**:  
None explicitly; any parameters would be passed via registers or the stack by the caller, but the function does not use them.  

**Returns**:  
No explicit return value; all registers and memory are unchanged.  

**Key Operations**:  
- `linkw %fp,#-4`: Creates a stack frame by pushing the old frame pointer onto the stack, setting `%fp` to the current stack pointer, and allocating 4 bytes of local space (though never used).  
- `unlk %fp`: Restores the previous stack frame by moving `%fp` back into the stack pointer and popping the old `%fp`.  
- `rts`: Returns to the caller.  

**Called Functions**:  
None.  

**Notes**:  
- The function is only 6 bytes long and performs no meaningful work.  
- The allocated 4 bytes of local space (`#-4`) are never accessed, suggesting the frame is purely structural.  
- In a boot loader context, such a stub might serve as a safe “do-nothing” function for unused exception vectors or as a placeholder for future code patches.  
- The nearby strings at addresses `8433690` and `8433742` (both `"N^NuNV"`) appear to be ASCII representations of the opcodes `4e56` (`linkw`) and `4e5e` (`unlk`) followed by `4e75` (`rts`), possibly left from a debugging or disassembly tool.

---

### Function at 0x80b01e

**Embedded strings:**
- `8433742`: `"N^NuNV"`
- `8433776`: `"*@(y"`

**Name**: `boot_error_handler` or `fatal_boot_error`

**Purpose**: This function appears to be a fatal error handler in the boot loader that checks for a specific failure condition (likely a hardware initialization or SCSI controller ready status), and if the condition is met, it calls a logging/display function and then triggers a processor reset or halt. The function guards against repeated error reporting by checking a flag at a fixed memory location.

**Parameters**: 
- One 32-bit parameter passed on the stack at `%fp@(8)` (likely an error code or message pointer).
- Implicitly uses a status byte at address `0xc0380d` (derived from `0xc0380c + 1`).

**Returns**: 
- No explicit return value; does not return to caller on error path (calls a reset/halt function).
- Returns normally only if the error condition is not met.

**Key Operations**:
- Checks byte at `0xc0380d` for value `0xff` (`-1`). This is likely an "error already handled" flag in shared RAM (`0xc00000` region).
- If flag is not set, calls `0x809f94` with two arguments: the passed parameter and a fixed value `0x80c610` (likely a format string or error message buffer).
- Then calls `0x809266` with argument `-1` (likely a system reset, halt, or reboot function).
- Uses standard stack frame (`linkw %fp,#-4`) and cleans up stack after calls.

**Called Functions**:
- `0x809f94`: Likely `printf`-like formatted output function (takes two arguments).
- `0x809266`: Likely `system_reset` or `panic_halt` (takes one argument, often `-1` for fatal error).

**Notes**:
- The memory address `0xc0380c` is in the shared RAM area (`0xc00000–0xc00fff`), suggesting this flag is shared between DMA and Job processors or preserved across resets.
- The fixed argument `0x80c610` points into the U15 ROM; nearby strings at `0x8433742` and `0x8433776` may be related error messages.
- The sequence suggests a "die on first error" pattern: if the error flag is not already set, report the error and reset/halt the system. This is typical for critical boot failures.
- The function is small and located late in the U15 ROM (`0x80b01e`), consistent with error handling code.

---

### Function at 0x80b052

**Embedded strings:**
- `8433776`: `"*@(y"`
- `8433900`: `"N^NuNV"`
- `8433928`: `"`:Hx"`

**Name**: `scsi_setup_command` or `scsi_prepare_cdb`

**Purpose**: This function constructs a SCSI command descriptor block (CDB) in a shared memory structure and prepares the Omti 5200 SCSI controller for execution. It takes parameters like SCSI target ID, logical block address, transfer length, and control byte, formats them into the appropriate CDB fields, and then triggers the SCSI controller to execute the command.

**Parameters**:  
- `%fp@(8)` (long): SCSI target ID (likely device/LUN combination)  
- `%fp@(15)` (byte): SCSI command opcode  
- `%fp@(16)` (long): Logical block address (high bits)  
- `%fp@(20)` (long): Logical block address (low bits) and/or transfer length  
- `%fp@(23)` (byte): Additional parameter (likely page code or flag)  
- `%fp@(27)` (byte): Control byte  
- `%fp@(31)` (byte): Additional control or reserved field  

**Returns**: No explicit return value; modifies shared memory structures and hardware registers to initiate SCSI operation.

**Key Operations**:
- Calculates offset into a SCSI command table at `0xc03810` using the target ID (`d7 * 10` → likely 16-byte per-entry structure)
- Stores SCSI opcode at offset 0 of the command entry
- Formats a 21-bit logical block address (from two input longs) into bits 21-41 of the command entry (using shift/mask operations)
- Stores additional parameters at offsets 2, 3, 4, and 5 of the command entry
- Writes two long values from `0xc03a90` and `0xc03a94` (likely DMA addresses or buffer pointers) into a controller structure at `0xc0380c`
- Sets target ID at offset 1 and command trigger byte (value 6) at offset 0 of the controller structure to initiate SCSI operation

**Called Functions**: None (leaf function).

**Notes**:
- The function uses two key shared memory pointers:  
  - `0xc0380c` → Points to Omti 5200 controller register block or command mailbox  
  - `0xc03810` → Points to an array of SCSI command descriptors (each 16 bytes based on offset calculation `d7*10` hex = `d7*16` decimal)  
- The command entry structure appears to be 6+ bytes, with bitfields for LBA (logical block address) spanning multiple words.  
- Writing value 6 to the controller structure offset 0 (`%a4@`) likely triggers command execution (common in SCSI sequencer designs).  
- The two long values at `0xc03a90`/`0xc03a94` are likely DMA scatter-gather pointers or data buffer addresses for the transfer.  
- This is a low-level SCSI command setup routine called by higher-level disk I/O functions in the boot loader.

---

### Function at 0x80b0f0

**Embedded strings:**
- `8433928`: `"`:Hx"`
- `8433988`: `"N^NuNV"`

**Name**: `boot_cache_invalidate_or_flush`

**Purpose**: This function appears to manage a boot-time cache invalidation or flush operation, likely for a disk block cache or buffer cache used during the boot loader's filesystem operations. It checks a cache status flag, and if the cache is not already invalidated, it calls a helper function to process cache entries before marking the cache as invalid and performing a final cleanup operation.

**Parameters**: 
- No explicit register parameters.
- Reads from memory-mapped shared RAM locations:
  - `0xc0380c` + 1 byte offset: Cache status/invalidation flag.
  - `0xc03a94`: Possibly a default return value or cache base pointer.
  - `0xc03a7c`: Cache control word or bitmask used for cache operations.

**Returns**: 
- Returns a value in `%d0`:
  - If the cache status byte at `0xc0380c+1` equals `0xff` (already invalidated), returns the longword at `0xc03a94`.
  - Otherwise, returns the result from the called function `0x80b148` (via fall-through to the end of function).

**Key Operations**:
- Checks a byte at `0xc0380c+1` for value `0xff` (cache invalid flag).
- If not invalid, calls `0x80b148` with three arguments: `(cache_control_word >> 1)`, `(cache_control_word & 1)`, and `1`. This likely walks or flushes cache entries.
- After the call, marks the cache invalid by writing `0xff` to `0xc0380c+1`.
- Calls `0x809266` with argument `-1` (likely a final cleanup or synchronization function).
- Uses a local stack frame (`linkw %fp,#-4`) but doesn't appear to use the local variable.

**Called Functions**:
- `0x80b148`: Cache processing helper (called with three integer arguments).
- `0x809266`: Cleanup or synchronization function (called with `-1`).

**Notes**:
- The cache control word at `0xc03a7c` is used to generate two arguments: the word shifted right by 1, and its lowest bit masked with `1`. This suggests the control word may encode a cache size or count and a flag.
- The function ensures idempotence: if the cache is already marked invalid, it returns immediately without performing the flush again.
- The shared RAM addresses (`0xc0xxxx`) correspond to the "Shared variables/data area in RAM" in the memory map, consistent with boot loader state variables.
- The strings referenced nearby (`":Hx"` and `"N^NuNV"`) are not directly used here; they may be in adjacent functions.

---

### Function at 0x80b148

**Embedded strings:**
- `8434100`: `"gb*|"`
- `8434216`: `"N^NuNV"`

**Name**: `boot_scsi_read_sector_with_checksum`

**Purpose**:  
This function reads a sector from a SCSI device (likely a disk) using a previously configured SCSI command block, verifies a stored checksum byte from the sector header, and optionally prints debugging information about the checksum. It appears to be part of the boot loader's low‑level disk I/O layer, reading a single sector (probably 512 bytes) and validating its integrity before further processing.

**Parameters**:  
- `%fp@(8)` (first argument): Device/LUN identifier (likely a packed SCSI bus/target/LUN number).  
- `%fp@(12)` (second argument): Memory destination address for the read data.  
- `%fp@(16)` (third argument): A flag controlling whether to print checksum debug output (non‑zero = enable).

**Returns**:  
No explicit return value; the read data is placed at the supplied memory address. The function likely relies on the called SCSI routine to indicate success/failure via a status variable or condition codes.

**Key Operations**:  
- Writes `4` to `0xc03a94` and `0xc03b70` to `0xc03a90` – these are likely SCSI controller command/status registers in shared RAM.  
- Writes `0xff` to `0xc0380d` (UART or SCC control register) – possibly disabling serial interrupts during the transfer.  
- Computes an offset into a device table at `0xc03810` using the device ID: `offset = (id * 2) + (id * 4) = id * 6`. Reads a byte from that table entry – this is the stored checksum byte for the sector.  
- Calls `0x80b052` (likely `scsi_execute_command`) with arguments: device ID, 3 (command length?), destination address, and two zero longwords (DMA setup?).  
- Calls `0x80af7a` (likely `scsi_wait_complete` or `verify_transfer`).  
- If the debug flag is set, prints the stored checksum and the four‑byte SCSI status (from `0xc03b70`–`0xc03b73`) using `printf`‑like routine at `0x809f94`.  
- Masks the high bit of the first status byte and passes it with a format string to `0x80c01c` (likely a debug output or checksum‑error handler).  
- Restores the UART/SCC control byte to `0xff` before returning.

**Called Functions**:  
- `0x80b052` – SCSI command execution routine.  
- `0x80af7a` – SCSI completion/verification routine.  
- `0x809f94` – Formatted print function (takes format string and arguments).  
- `0x80c01c` – Debug/error message handler (possibly for checksum mismatches).

**Notes**:  
- The checksum appears to be stored per‑device in a table at `0xc03810`. The sector read includes this checksum byte in its header, which is compared (likely inside `0x80af7a`) against the stored value.  
- The SCSI status block at `0xc03b70` is four bytes; the debug output prints them as separate bytes. The high bit of the first byte is masked off (line `0x80b206`), suggesting it’s a parity or reserved flag.  
- The function guards the SCSI operation by disabling serial activity (`0xff` to `0xc0380d`), indicating that the boot loader must avoid UART interrupts during critical disk reads.  
- The use of `%a5` as a preserved register suggests this function may be called from higher‑level filesystem‑reading code.

---

### Function at 0x80b22c

**Embedded strings:**
- `8434288`: `"`& y"`
- `8434328`: `"N^NuNV"`

**Name**: `boot_verify_or_retry_scsi_operation`

**Purpose**:  
This function appears to be a higher-level SCSI operation verifier and retry handler. It first attempts a primary SCSI operation (likely a read or write) via a call to `0x80b052`, then checks the SCSI controller status. If the operation succeeded (no error flags), it returns success. If the SCSI controller shows a busy or error condition, it may retry the operation via a call to `0x80b148`. The function manages shared memory flags (`0xc03a94`, `0xc03a90`) that likely track SCSI operation state or retry counts.

**Parameters**:  
- Two parameters passed on the stack at `%fp@(8)` and `%fp@(12)`. Based on typical boot loader patterns, these are likely a SCSI command/block descriptor pointer and a buffer address or sector number.

**Returns**:  
- Returns `0` in `%d0` if the SCSI operation succeeded or was retried successfully.
- Returns `1` in `%d0` if the SCSI controller indicates an error condition that does not warrant a retry (e.g., non-busy error).

**Key Operations**:  
- Clears two shared memory longwords at `0xc03a94` and `0xc03a90` (SCSI operation status/retry counters).
- Calls subroutine `0x80b052` with multiple arguments (likely a SCSI read/write routine).
- Calls subroutine `0x80af7a` (possibly a SCSI command issue or controller sync).
- Reads SCSI controller status from `0xc03804` (a mapped hardware register base).
- Checks bit 3 at offset `0x11` from that base (likely a SCSI busy or error flag).
- If that bit is set, returns `0` (immediate success or handled busy).
- Otherwise, checks bits `[1:0]` at offset `0x0e` (likely SCSI status/phase bits).
- If those bits are non-zero, calls retry routine `0x80b148` with the original parameters.
- Returns `0` after retry, or `1` if no retry was needed.

**Called Functions**:  
- `0x80b052` – Primary SCSI operation routine.
- `0x80af7a` – SCSI controller command or synchronization routine.
- `0x80b148` – SCSI error recovery or retry routine.

**Notes**:  
- The SCSI controller base `0xc03804` is in shared RAM area `0xC00000-0xC00FFF`, suggesting it’s a memory-mapped copy of the Omti 5200 registers, cached by the boot loader for faster access.
- The shared longwords at `0xc03a90` and `0xc03a94` are cleared at entry, implying they are used as session-specific state, not preserved across calls.
- The function’s logic suggests a two‑stage error handling: first check a “busy/error” flag (bit 3 at offset `0x11`), then examine lower‑level status bits (offset `0x0e`) to decide between retry or reporting a “soft” error (return 1).
- This is likely part of the boot loader’s disk I/O layer, ensuring robust reads from the SCSI disk during boot.

---

### Function at 0x80b29c

**Embedded strings:**
- `8434418`: `"N^NuNV"`

**Name**: `scsi_read_sector_with_timeout`

**Purpose**: This function reads a single sector (512 bytes) from a SCSI device using the OMTI 5200 controller, with a timeout mechanism based on polling a hardware status register. It initializes SCSI transfer buffers, calls the low-level SCSI read function, verifies the transfer, and loops until either the transfer completes successfully or a timeout counter expires. The timeout is implemented by checking a specific bit pattern in a hardware register (likely SCSI controller status) each iteration.

**Parameters**: 
- `%fp@(8)` (first parameter): SCSI device identifier (likely containing target ID and LUN)
- `%fp@(12)` (second parameter): Logical block address (LBA) to read

**Returns**: 
- No explicit return value in registers; the read data is placed into a buffer at `0xc03a90` (as set up by the called functions).
- The function returns when the read completes or times out; success/failure is likely indicated by global status variables.

**Key Operations**:
- Initializes `%d7` as a timeout counter (32 iterations).
- Clears two memory locations at `0xc03a94` and `0xc03a90` (likely SCSI transfer status and data buffer pointers).
- Sets up a stack frame with parameters for `0x80b052` (SCSI read function): pushes two zeros (likely buffer size and something else), the LBA, the value `1` (number of sectors), and the device identifier.
- Calls `0x80b052` (SCSI read routine).
- Calls `0x80af7a` (likely a SCSI transfer verification or completion check function).
- Polls a hardware register at `%a0@(14)` where `%a0 = 0xc03804` (a fixed pointer to a hardware register block, probably the OMTI 5200 controller status register). Checks bits 1 and 0 (`& 3`) for a non-zero condition; if set, loops back to reinitialize and retry the read.
- Decrements `%d7` each loop; exits if `%d7` reaches zero (timeout) or if the hardware status bits are clear (success).

**Called Functions**:
- `0x80b052`: SCSI read sector function (sets up and initiates the SCSI transfer).
- `0x80af7a`: SCSI transfer verification or status check function.

**Notes**:
- The hardware register at `0xc03804` is a pointer stored in RAM, pointing to the OMTI 5200 controller's register base (likely `0xE001xx` range). Offset 14 (`0xE`) is probably the controller's status register; bits 0 and 1 may indicate "busy" or "error" states.
- The timeout loop is coarse; it reinitializes the entire SCSI read each iteration if the status bits are set, which suggests it's retrying on controller busy/error conditions.
- The two cleared longs at `0xc03a90` and `0xc03a94` are in the shared RAM area (`0xC00000`), indicating they are used for DMA/buffer pointers or status visible to both processors.
- This function is part of the boot loader's disk I/O layer, used to read filesystem blocks (like boot sectors or kernel images) from disk during boot.

---

### Function at 0x80b2f6

**Embedded strings:**
- `8434502`: `"g0 y"`
- `8434552`: `"N^NuNV"`
- `8434601`: `"zN^NuNV"`

**Name**: `boot_cleanup_or_shutdown`

**Purpose**: This function appears to perform a controlled cleanup or shutdown sequence, likely after a boot operation or error condition. It first attempts a SCSI operation (possibly a read or status check), then checks a flag in shared memory to determine if a full shutdown/reboot sequence should be executed. If the flag indicates shutdown is needed, it sets the flag to a "done" state, performs another SCSI operation, and then triggers a processor reset or mode change via a hardware control function.

**Parameters**: 
- No explicit parameters passed via registers.
- Implicitly uses shared memory location `0xc03a7c` (likely a SCSI command block or buffer pointer).
- Reads a status flag from `0xc0380c + 1` (byte offset).

**Returns**: 
- No explicit return value.
- Side effects: May modify shared memory flag at `0xc0380c+1`, perform SCSI operations, and potentially reset/reboot the system.

**Key Operations**:
- Calls `0x80b148` with arguments `0x2` and the pointer from `0xc03a7c` (likely a SCSI command function).
- Calls `0x80b052` with multiple arguments including `0x8b`, `0xc0`, and the same pointer (likely a SCSI read/write operation; `0x8b` may be a SCSI command byte, `0xc0` a target/LUN).
- Calls `0x80af7a` with the pointer from `0xc03a7c` (likely a SCSI completion/status check).
- Checks if byte at `0xc0380c + 1` equals `0xff` (`-1`). If not, sets it to `0xff`.
- Calls `0x80b148` again with arguments `0x1` and `0x2` and the pointer (likely a different SCSI command).
- Finally calls `0x809266` with argument `0x1` (likely a hardware control function that resets the Job processor or triggers a reboot).

**Called Functions**:
- `0x80b148` – SCSI command function (called twice).
- `0x80b052` – SCSI data transfer function.
- `0x80af7a` – SCSI status/cleanup function.
- `0x809266` – Hardware control function (likely resets Job processor via `0xE00018` KILL.JOB or similar).

**Notes**:
- The shared memory flag at `0xc0380c+1` acts as a shutdown trigger: if not already `0xff`, the function proceeds to a second SCSI operation and a system reset.
- The sequence suggests a graceful shutdown: complete pending SCSI operations, mark shutdown requested, then reset.
- The value `0x8b` passed to `0x80b052` might be a SCSI command like `READ` (0x08) with some flags, or a custom OMTI 5200 command.
- The function is likely called from the boot loader's main loop or error handler to either reboot into Unix or reset after a failed boot.

---

### Function at 0x80b37c

**Embedded strings:**
- `8434601`: `"zN^NuNV"`
- `8434694`: `"`0Hx"`
- `8434744`: `"N^NuNV"`
- `8434882`: `"NuNV"`
- `8434945`: `"|N^Nu"`

**Name**: `boot_menu_loop`  

**Purpose**: This function implements the main boot menu loop for the Plexus P/20 DMA processor. It displays the boot prompt, waits for user input, processes commands, and handles system initialization or error conditions. The loop continues until a valid boot command is executed or a system reset occurs.  

**Parameters**:  
- Uses shared memory variables at `0xC03A7C`, `0xC03A8C`, `0xC03A94`, `0xC03A80`, and `0xC0380C` as inputs for configuration, device parameters, and status.  
- No explicit register parameters; all inputs are from fixed memory locations.  

**Returns**:  
- No explicit return value; the function may not return if a boot command is executed successfully.  
- May set shared memory status bytes (e.g., `0xC0380C+1` to `0xFF` on error).  

**Key Operations**:  
- Calls `0x80B052` (likely a SCSI read/write or device initialization routine) with parameters for device, block count, and memory address.  
- Calls `0x80AF7A` (likely a validation or checksum routine).  
- Checks a status byte at `0xC0380C+1` for error (`0xFF`).  
- On error, calls `0x80B148` (error handler) and `0x809266` (possibly a reset or retry routine).  
- Displays multiple strings from the ROM (e.g., `"PLEXUS PRIMARY BOOT REV 1.2"` and other prompts) via `0x809F94` (print function).  
- Calls `0x80A236` (likely a delay or user-input polling routine).  
- Loops continuously until a specific byte at `0xC03ABC` equals `0x79` (ASCII 'y' or a command code).  

**Called Functions**:  
- `0x80B052` – Device I/O routine  
- `0x80AF7A` – Validation routine  
- `0x80B01E` – Unknown (possibly initialization)  
- `0x80B148` – Error handler  
- `0x809266` – Reset/retry routine  
- `0x809F94` – String output (print)  
- `0x80A236` – Input polling/delay  
- `0x80B4C4` – Unknown (likely command parser)  

**Notes**:  
- The function appears to have three entry points or phases (at `0x80B37C`, `0x80B3AE`, and `0x80B43C`), suggesting it handles different boot stages: initial setup, error recovery, and main menu loop.  
- The loop at `0x80B454` displays boot banners and waits for input; it only exits if `0xC03ABC == 0x79`.  
- Hardware registers are not directly accessed here; instead, the code relies on shared RAM variables at `0xC0xxxx` addresses, which likely mirror hardware state or configuration.  
- The strings referenced (e.g., `"NuNV"`, `"N^NuNV"`) are likely fragments of longer banner strings stored in the ROM.  
- The code may be part of a larger boot monitor that supports commands like `sc(0,0)/unix`, `mt`, `fp`, etc., as documented in the Plexus boot menu.

---

### Function at 0x80b4c4

**Embedded strings:**
- `8434945`: `"|N^Nu"`

**Name**: `boot_read_disk_block`  

**Purpose**:  
This function reads a block from disk (likely SCSI) into memory, then processes or verifies it. It appears to be part of the boot loader’s disk‑access layer, reading a specific block (possibly a superblock, inode, or boot program) from a device into a buffer in shared RAM, then calling routines to examine or use the data. The function may be reading a filesystem structure or the next stage of boot code.

**Parameters**:  
- Inputs are implicit from fixed memory addresses:  
  - `0xc03a80` likely holds a disk address (block number) or SCSI command parameter.  
  - `0xc03a7c` likely holds a destination memory address in shared RAM.  
- The constants `0x2` and `0x4` pushed on the stack may specify a device/LUN and transfer size.

**Returns**:  
No explicit register return; results are written to the buffer at `0xc03a7c` and possibly status flags set elsewhere.

**Key Operations**:  
- Calls `0x80b2f6` (possibly hardware/SCSI initialization or status check).  
- Pushes arguments for a disk‑read routine:  
  - Source address (`0xc03a80`),  
  - Zero placeholder,  
  - Constants `2` and `4` (maybe device ID and block count),  
  - Destination buffer address (`0xc03a7c`).  
- Calls `0x80b052` (likely a low‑level SCSI read routine).  
- After reading, calls `0x80af7a` (possibly checksum or validation) on the buffer.  
- Finally calls `0x80b37c` (maybe prints progress or verifies filesystem metadata).  
- The trailing data (`0x1009`, `0x8400`, etc.) after the RTS may be embedded constants or a small data table used by the caller.

**Called Functions**:  
- `0x80b2f6` – unknown setup/status function.  
- `0x80b052` – main disk‑read routine.  
- `0x80af7a` – buffer processing/validation routine.  
- `0x80b37c` – post‑read action (display or further verification).

**Notes**:  
- The function uses the shared RAM area at `0xc0xxxx` for parameters, typical of the Plexus DMA‑Job shared communication.  
- Constants `2` and `4` could mean: device 2 (SCSI LUN 2 = floppy?) and 4 sectors/blocks, or alternatively function codes for the SCSI command wrapper.  
- The data after the RTS (`0x1009`, `0x8400`, …) is likely not executed but may be a parameter table for disk geometry or filesystem offsets, placed here for proximity to the code.  
- This routine is relatively high‑level in the boot chain, relying on lower‑level SCSI drivers to do the actual hardware access.

---

### Function at 0x80b57a

**Embedded strings:**
- `8435160`: `"N^NuNV"`
- `8435224`: `"N^NuNV"`

**Name**: `scsi_wait_busy_or_timeout`

**Purpose**: This function waits for the SCSI bus to become not busy (likely waiting for a SCSI operation to complete) by polling with a timeout of approximately 300 iterations. If the SCSI bus becomes not busy before the timeout, it proceeds to call two other SCSI-related functions and then a function that likely processes a SCSI command or result. If the timeout expires, it still proceeds to the same cleanup calls, but the timeout condition may indicate a SCSI error.

**Parameters**: None explicitly passed, but the function implicitly depends on the SCSI controller hardware status being readable via the subroutine at `0x80b22c`.

**Returns**: No explicit return value, but the function's side effects include calling other SCSI handling routines and potentially leaving the SCSI controller in a known state.

**Key Operations**:
- Calls `0x8087da` with argument `0x1e` (30) – likely a short delay function.
- Initializes a loop counter (`%d7`) with 300 (0x12c) for timeout.
- In the loop, calls `0x80b22c` with argument `0x7` – likely checks SCSI status (bit 2 = BUSY, bit 1 = REQ, bit 0 = C/D?).
- If the call returns non-zero (SCSI not busy), breaks out of the loop early.
- If busy, calls `0x8087da` with argument `0x1` (minimal delay) between polls.
- After loop (timeout or not busy), calls `0x80b524` and `0x80b5dc` – likely SCSI cleanup/status functions.
- Loads a longword from shared RAM address `0xc03a80` onto the stack and calls `0x80b6f2` – likely processes a SCSI command block or result stored there.

**Called Functions**:
- `0x8087da` – delay function (called with args 0x1e and 0x1).
- `0x80b22c` – SCSI status check function (arg 0x7 likely masks status bits).
- `0x80b524` – SCSI post-operation function.
- `0x80b5dc` – SCSI cleanup function.
- `0x80b6f2` – SCSI command/result processor (takes argument from `0xc03a80`).

**Notes**:
- The timeout loop uses a decrementing counter from 300 to 0, with a short delay (`0x8087da(1)`) between polls. This suggests a busy-wait for SCSI BUSY to clear, with a safety timeout.
- The shared RAM address `0xc03a80` is within the known shared data area at `0xc00000-0xc00fff`. This likely holds a SCSI command block or result pointer prepared by earlier boot code.
- The function appears to be part of the SCSI disk I/O sequence in the boot loader, ensuring the SCSI controller is ready before proceeding with command processing.
- The strings referenced nearby (`"N^NuNV"`) are likely unrelated to this function and may be in a different segment.

---

### Function at 0x80b5dc

**Embedded strings:**
- `8435224`: `"N^NuNV"`
- `8435258`: `"N^NuNV"`
- `8435282`: `"N^NuNV"`

**Name**: `boot_initialize_system`  

**Purpose**:  
This function initializes key system variables and performs early boot setup by clearing shared memory locations, calling a multi‑parameter initialization routine, and then invoking two further initialization functions. It appears to be part of the DMA processor’s boot‑loader startup sequence, preparing the hardware environment before loading an OS image.

**Parameters**:  
None explicitly passed; the function operates on fixed memory addresses and constants.

**Returns**:  
No explicit return value; side‑effects include clearing `0xc03a94` and `0xc03a90`, and the results of the three called subroutines.

**Key Operations**:  
- Clears two longwords in shared RAM at `0xc03a94` and `0xc03a90` (likely boot flags or status variables).  
- Pushes five longword arguments onto the stack (four zeros and two immediate values `1` and `7`).  
- Calls subroutine `0x80b052` with those arguments (possibly a hardware or SCSI controller initialization routine).  
- Calls subroutine `0x80af7a` with argument `7` (maybe a device‑specific setup function).  
- Calls subroutine `0x80b7f0` (could be a final boot‑stage initializer or diagnostic).  

**Called Functions**:  
1. `0x80b052` – unknown, but called with arguments `(0, 0, 0, 0, 1, 7)`.  
2. `0x80af7a` – unknown, called with argument `7`.  
3. `0x80b7f0` – unknown, called with no arguments.

**Notes**:  
- The strings `"N^NuNV"` referenced nearby are likely unrelated to this function; they may be part of a different routine (possibly error messages or SCSI command data).  
- The use of `clrl %sp@` and repeated `clrl %sp@-` suggests the function is building a six‑longword argument block on the stack for `0x80b052`. The constants `1` and `7` may correspond to SCSI ID/LUN or device‑type parameters.  
- Given the Plexus boot process, this function likely runs after the self‑test (U17 ROM) and before the boot command prompt, setting up the SCSI controller and shared memory structures needed for disk access.  
- Addresses `0xc03a90` and `0xc03a94` are in the shared RAM region (`0xc00000–0xc00fff`), indicating they are used for inter‑processor communication or boot state tracking.

---

### Function at 0x80b61c

**Embedded strings:**
- `8435258`: `"N^NuNV"`
- `8435282`: `"N^NuNV"`
- `8435314`: `"N^NuNV"`

**Name**: `boot_handle_scsi_error` (or `scsi_error_recovery_sequence`)

**Purpose**: This function implements a SCSI error recovery sequence for the Plexus P/20 boot loader. It checks a global error flag at `0xc03b8c`, and if set, calls a cleanup/error-handling subroutine, then resets the flag and performs a SCSI bus reset sequence. The function appears in three variants (at `0x80b61c`, `0x80b63e`, and `0x80b656`), each triggering different SCSI bus reset parameters—likely corresponding to different error severity levels or recovery modes (e.g., soft reset vs. hard reset).

**Parameters**: No explicit register parameters. The function reads/writes the global error flag at `0xc03b8c` (in shared RAM) and passes immediate values to a subroutine at `0x80b676` (likely a SCSI bus reset function).

**Returns**: No explicit return value. Side effects include clearing `0xc03b8c` and performing SCSI bus operations.

**Key Operations**:
- Tests the global SCSI error flag at `0xc03b8c` (shared RAM).
- If flag is non-zero, calls a cleanup subroutine at `0x80b6bc` (likely flushes buffers or logs error).
- Clears the error flag (`clrl 0xc03b8c`).
- Calls a SCSI initialization/reset subroutine at `0x80b5dc` (likely sets up controller after error).
- Two additional entry points (`0x80b63e` and `0x80b656`) set the error flag and call `0x80b676` with different arguments: `(2,8)` and `(2,10)` respectively—these likely represent SCSI bus reset commands with different target IDs or reset durations.

**Called Functions**:
- `0x80b6bc`: Error cleanup subroutine (called only if error flag is set).
- `0x80b5dc`: SCSI post-error initialization.
- `0x80b676`: SCSI bus reset function (takes two integer arguments).

**Notes**:
- The three entry points suggest a layered error recovery:  
  - `0x80b61c`: Clears existing error and reinitializes SCSI.  
  - `0x80b63e`: Triggers a moderate reset (arguments `2,8`).  
  - `0x80b656`: Sets error flag and triggers a stronger reset (arguments `2,10`).  
- The arguments to `0x80b676` likely specify SCSI target ID and reset type—`8` and `10` may correspond to different Omti 5200 controller commands.  
- The shared RAM location `0xc03b8c` is used as a persistent error flag across boot stages.  
- The strings `"N^NuNV"` referenced nearby may be debug or status strings used by related SCSI functions.  
- This code is part of the boot loader’s robustness features, ensuring SCSI errors don’t hang the system during disk reads.

---

### Function at 0x80b676

**Embedded strings:**
- `8435384`: `"N^NuNV"`
- `8435438`: `"N^NuNV"`

**Name**: `boot_loader_entry` or `load_and_execute_kernel`

**Purpose**: This function appears to be the main entry point for loading and executing a Unix kernel (or other bootable program) from disk. It sets up a critical system address, calls a function to prepare the system, loads a 64KB block (likely the kernel image) from a specified device/LUN into memory at a specified address, validates or processes the loaded image, and then jumps to it. The function likely implements the core of the boot command execution (e.g., `sc(0,0)/unix`).

**Parameters**: The function takes two parameters passed on the stack:
- `%fp@(8)`: Likely a pointer to a device identifier string (e.g., "sc(0,0)").
- `%fp@(12)`: The destination memory address where the boot image should be loaded.

**Returns**: This function does not return to its caller if successful; it transfers execution to the loaded kernel. If the load fails, it may return to the boot prompt via a called function's error handling.

**Key Operations**:
- Stores the magic number `0x0080c6d5` (address 8439509) onto the stack. This is likely a known entry point or flag for the kernel or a subsequent stage loader.
- Calls a subroutine at `0x80b01e`, which is likely a system initialization or hardware preparation routine.
- Calls a subroutine at `0x80b052` with arguments: device string pointer, 0, 65536 (0x10000 bytes = 64KB), destination address, and the constant 7. This is almost certainly a **block read function** (likely SCSI or floppy) that loads one 64KB chunk.
- Calls a subroutine at `0x80af7a` with argument 7. This likely validates the loaded image (checksum, magic number) or performs relocation/fixup for an a.out binary.
- Calls a subroutine at `0x80b7f0`. This is likely the **jump-to-kernel** routine, which disables the boot ROM mapping, sets up the system, and jumps to the loaded image's entry point (possibly using the `0x0080c6d5` value stored earlier).

**Called Functions**:
- `0x80b01e`: `system_prep_for_boot` – Prepares hardware (SCSI, memory map, interrupts) for loading.
- `0x80b052`: `device_read_block` – Reads `n` bytes from a specified boot device to memory. Argument `7` may be a command/flag (e.g., "read absolute sector").
- `0x80af7a`: `validate_or_process_aout` – Checks the loaded image's header (a.out format) and possibly performs segment relocation.
- `0x80b7f0`: `enter_kernel` – Finalizes the boot process and transfers control to the loaded program.

**Notes**:
- The constant `65536` (0x10000) is significant: it's the exact size of the Plexus P/20's boot block load. Historical Unix kernels (System V, Plexus's derivative) were often loaded in a single 64KB chunk from block 0 of the disk.
- The value `0x0080c6d5` pushed onto the stack is intriguing. Address `0x80c6d5` is within the U15 ROM space (0x808000-0x80FFFF). It may point to a known entry point table, a signature, or a small trampoline in ROM that the kernel uses to call back into ROM services.
- The function cleans up the stack after the read call but does not check for errors; error handling is presumably inside the called subroutines, which may print an error and return to the command prompt.
- This function is the culmination of the boot loader's parsing phase. After the user types a command like `sc(0,0)/unix`, the parser resolves the device and filename, and calls this function with the device string and load address.

---

### Function at 0x80b6bc

**Embedded strings:**
- `8435438`: `"N^NuNV"`
- `8435496`: `"N^NuNV"`

**Name**: `boot_initialize_scsi_or_filesystem`  

**Purpose**:  
This function appears to perform a low‑level SCSI or filesystem initialization sequence during the boot process. It calls a subroutine (`0x80b052`) with several stack‑based arguments that likely configure a SCSI command or filesystem parameter block, then calls two more subroutines (`0x80af7a` and `0x80b7f0`) that may finalize the setup and proceed to the next boot stage. The repeated use of magic numbers (1, 0x10, 7) suggests a fixed‑parameter initialization for a known device (e.g., SCSI ID 0, LUN 0, block size 0x200, or inode‑related parameters).

**Parameters**:  
No explicit register parameters; all arguments are pushed onto the stack before the first `jsr`. The function implicitly assumes the hardware is in a pre‑initialized state (SCSI controller ready, memory mapped).

**Returns**:  
No explicit return value; likely modifies hardware state and may set global variables in the shared RAM area (`0xC00000–0xC00FFF`).

**Key Operations**:  
- Sets up a stack frame with `linkw %fp,#-4`.  
- Pushes five arguments onto the stack: `0x1`, `0`, `0`, `0x10`, `0x7`.  
- Calls subroutine at `0x80b052` (likely a SCSI command builder or filesystem block reader).  
- Calls subroutine at `0x80af7a` with argument `0x7` (possibly a device‑specific finalization).  
- Calls subroutine at `0x80b7f0` (could be a boot progression routine, e.g., load next stage).  

**Called Functions**:  
1. `0x80b052` – Unknown, but based on typical boot loader patterns, may be `scsi_read_sector` or `read_inode`.  
2. `0x80af7a` – Possibly `scsi_execute` or `device_init`.  
3. `0x80b7f0` – Likely `boot_next_stage` or `enter_interactive_prompt`.  

**Notes**:  
- The constants `0x1`, `0x10`, and `0x7` may correspond to: SCSI LUN, block count, and command opcode; or filesystem inode number, offset, and mode.  
- The strings `"N^NuNV"` at addresses `8435438` and `8435496` are not referenced in this code snippet; they may be debug strings or magic markers elsewhere in the ROM.  
- This routine is positioned late in the boot ROM (U15), suggesting it runs after basic hardware self‑test and before loading the kernel.  
- The lack of hardware register accesses here implies it relies on previously initialized hardware (SCSI controller, memory mapping).

---

### Function at 0x80b6f2

**Embedded strings:**
- `8435496`: `"N^NuNV"`

**Name**: `boot_loader_entry` or `load_and_execute_boot_image`

**Purpose**:  
This function loads a boot image from a SCSI device into memory at address 0x10000 (64KB offset) and then transfers control to it. It appears to be the core routine that fetches the secondary bootloader or kernel image after the user has selected a boot device and file via the “:” prompt. The function first calls a SCSI read routine to load exactly one block (65536 bytes) from the specified device/LUN/sector, then calls a routine to set up the processor state before jumping to the loaded code.

**Parameters**:  
- A pointer (likely to a device string or parsed boot command structure) passed on the stack at `%fp@(8)`. This probably contains SCSI ID, LUN, and starting sector information.

**Returns**:  
- Does not return to caller; transfers execution to the loaded code at 0x10000.

**Key Operations**:  
- Pushes arguments for a SCSI read call:  
  - Device descriptor pointer (from `%fp@(8)`)  
  - Transfer length = 65536 bytes (0x00010000)  
  - Destination address = 0 (interpreted as offset 0x10000 in boot context)  
  - Argument 0x11 (likely SCSI read command + flags)  
  - Argument 0x7 (possibly device type: 7 = hard disk)  
- Calls `0x80b052` (likely `scsi_read` or `device_read`) to perform the read.  
- Calls `0x80af7a` with argument 0x7 (likely `prepare_boot_jump` or `disable_mmu_for_boot`).  
- Calls `0x80b7f0` (likely `jump_to_boot_image` or `enter_loaded_code`), which presumably jumps to address 0x10000.

**Called Functions**:  
- `0x80b052` – SCSI/device read routine.  
- `0x80af7a` – Boot preparation routine (may set hardware registers, disable mapping, or clear caches).  
- `0x80b7f0` – Entry point to loaded boot image (likely a jump to 0x10000).

**Notes**:  
- The destination address for the read is passed as 0, but given the Plexus boot process, physical address 0x10000 is a conventional load address for secondary boot stages or kernel images. The read routine likely adds 0x10000 internally when a zero address is specified.  
- The fixed length 65536 bytes suggests loading exactly 128 sectors (assuming 512‑byte sectors) or a full 64KB block, which matches the size of a typical bootable Unix a.out header plus initial code.  
- The function cleans up the stack after the SCSI read but does not return; the final `jsr 0x80b7f0` likely does not return, either because it jumps to the loaded image or resets the CPU context.  
- The string `"N^NuNV"` at address 0x8435496 is not referenced in this code; it may be in a different function or data area.

---

### Function at 0x80b72c

**Embedded strings:**
- `8435566`: `"`vp4"`
- `8435692`: `"N^NuNV"`
- `8435752`: `"N^NuNV"`

**Name**: `scsi_check_status_or_error`

**Purpose**: This function appears to check the status of the SCSI controller (likely the OMTI 5200) after a command, interpreting the status byte and any message bytes if present. It handles specific status conditions (0x18 = command complete, 0x34 = linked command complete with flag) and returns success for those, otherwise it prints error messages with the status byte and any message bytes, and returns failure. It is likely called after issuing a SCSI command to verify completion and handle errors.

**Parameters**: 
- Implicitly reads from a fixed SCSI controller status register at address `0xC03B70` (loaded into `%a5`).
- Reads a parameter from address `0xC03810 + 42` (offset 0x2A), which is likely a saved command flag or phase value from earlier SCSI operations.

**Returns**: 
- Returns `0` in `%d0` for success (status 0x18, or status 0x34 with the saved parameter equal to 8).
- Returns `-1` (`0xFFFFFFFF`) in `%d0` for failure (any other status, or if error messages are printed).

**Key Operations**:
- Reads a byte from `0xC03810 + 0x2A` and saves it locally.
- Calls `0x80b148` with arguments `0` and `7` – likely a SCSI bus/controller initialization or reset function.
- Reads the SCSI status register at `0xC03B70`, masking off bit 7 (busy flag) to get the base status code.
- Compares status against `0x18` (24 decimal) – typical SCSI "command complete" status.
- Compares status against `0x34` (52 decimal) – likely "linked command complete" or similar – and also checks if the saved parameter equals 8, possibly indicating a specific phase or flag.
- If status is neither of the above, prints an error message via `0x809f94` with the status byte and the saved parameter.
- If bit 7 of the status byte is set (busy? or message phase?), reads three message bytes from offsets 1, 2, and 3 of the status register and prints them via `0x809f94`.
- Finally, calls `0x80c01c` with the status byte – likely a function that logs or further processes SCSI errors.

**Called Functions**:
- `0x80b148` – likely `scsi_reset_or_init` (arguments: 0, 7).
- `0x809f94` – `printf` or formatted output function (takes format string and arguments).
- `0x80c01c` – likely `scsi_log_error` or `error_handler` (takes status code).

**Notes**:
- The SCSI controller status register is mapped at `0xC03B70` in the shared RAM area (`0xC00000-0xC00FFF`). This matches the hardware context where the DMA processor directly accesses the SCSI bus.
- The saved parameter from `0xC03810+0x2A` might be the SCSI phase saved earlier (e.g., 8 = message in phase). The check for status `0x34` with this parameter equal to 8 suggests handling of linked commands with a message phase.
- The strings referenced are likely format strings for the error messages: `8439514` (`0x80c6da`) for the first error, `8439547` (`0x80c6fb`) for the message bytes, and `8437680` (`0x80bfb0`) for the final error logging.
- The function uses bit 7 of the status byte to decide whether to read message bytes, which is consistent with SCSI where the high bit can indicate a message phase or busy condition.
- This is a low-level SCSI command completion handler, part of the boot loader's disk I/O routines.

---

### Function at 0x80b7f0

**Embedded strings:**
- `8435752`: `"N^NuNV"`
- `8435770`: `":|*9"`
- `8435850`: `"`,Hx"`
- `8435928`: `"N^NuNV"`
- `8435946`: `":|*9"`
- `8436060`: `"`,Hx"`
- `8436130`: `"N^NuNV"`

**Name**: `boot_verify_or_format_disk`

**Purpose**: This function appears to implement a disk verification or low-level formatting routine that operates in two modes. The first mode (0x80B7F0-0x80B82A) checks system status and either returns a cached value or triggers a verification process. The second mode (0x80B82C-0x80B9A4) performs the actual disk operation by reading/writing blocks in a pattern, likely verifying disk integrity or performing a destructive format. The third mode (0x80B8DC-0x80B9A4) is similar but with reversed operation order, suggesting a complementary verification or formatting pass.

**Parameters**: 
- Memory location 0xC03804+14 (system status/control register readback) determines operation mode
- Memory locations 0xC03A7C and 0xC03A80 contain disk parameters (likely starting block and block count)
- Memory location 0xC03ABC contains a verification byte (expected value 0x79/'y')

**Returns**: 
- First mode returns either 0xC03A94 value (10240) or -1 on failure
- Second/third modes return no explicit value but modify shared memory areas and disk contents

**Key Operations**:
- Checks system control register bits 1-0 at 0xC0380E to determine if verification needed
- Calls verification function at 0x80B72C when bits indicate need
- Uses shared memory locations 0xC03A8C, 0xC03A90, 0xC03A94 for disk operation parameters
- Performs looped block operations (20-byte blocks) using functions at 0x80B9A6 (write) and 0x80B676 (read)
- Sets 0xC03B8C flag to 1 after successful operation
- Outputs status strings using 0x809F94 (print function)
- Calls 0x80ADE0 and 0x80B57A for disk subsystem initialization
- Verifies user confirmation by checking 0xC03ABC for 'y' (0x79)

**Called Functions**:
- 0x80B72C: System verification/check function
- 0x809266: Exit/return function (possibly error handler)
- 0x809F94: String printing function
- 0x80A236: Input/confirmation function
- 0x80ADE0: Disk subsystem initialization
- 0x80B57A: Disk parameter setup
- 0x80B9A6: Block write function (20-byte blocks, mode 8)
- 0x80B676: Block read function (20-byte blocks, mode 10)
- 0x80B61C: Completion/cleanup function

**Notes**:
- The function uses two complementary operation sequences: read-then-write (0x80B88C-0x80B8B6) vs write-then-read (0x80B95E-0x80B986), suggesting data verification through pattern testing
- The 20-byte block size is unusual for disk operations (typically 512 bytes), suggesting this might be operating on a special disk area like bad block tables or partition metadata
- Memory location 0xC03A94 is initialized to 10240 (0x2800), which might be a default disk parameter or magic value
- The function requires user confirmation (checks for 'y' at 0xC03ABC) before proceeding with destructive operations
- The shared memory area at 0xC00000-0xC00FFF is heavily used for disk operation parameters and status flags
- The operation appears to be part of the boot loader's disk maintenance utilities (format, verify, or bad block management)

---

### Function at 0x80b9a6

**Embedded strings:**
- `8436224`: `"N^NuNV"`

**Name**: `boot_scsi_read_sector`  

**Purpose**:  
This function reads a sector from a SCSI disk, likely as part of the boot loader’s disk I/O routines. It prepares parameters for a lower‑level SCSI read routine, calls it, and then verifies or processes the result. The function references shared memory variables in the system‑specific data area (`0xC00000–0xC00FFF`) to determine drive/unit selection and possibly block numbers, and it prints status messages via console output functions.

**Parameters**:  
- `%fp@(8)` – Likely a sector number or logical block address (LBA).  
- `%fp@(12)` – Likely a memory destination address for the read data.  
- Shared memory at `0xC03A7C` and `0xC03A8C` provide additional drive/unit parameters.

**Returns**:  
No explicit return value in registers; the read data is placed at the caller‑supplied buffer address. Success/failure may be indicated via status messages printed to the console.

**Key Operations**:  
- Sets up a stack‑based parameter block for a SCSI read call.  
- Reads system‑shared variables at `0xC03A7C` (drive/unit selection) and `0xC03A8C` (likely controller‑specific data).  
- Uses bit‑masking (`andl 0xc03a7c,%d0`) and arithmetic shifts (`asrl #1,%d0`) to derive a unit number or block count.  
- Calls `0x80b052` – the core SCSI read routine.  
- Calls `0x80af7a` – possibly a verification or checksum routine.  
- Prints status strings via `0x80b01e` and `0x80b0f0` using string pointers `#8439679` and `#8439684` (which point into the ROM string table; `8439684` is `"N^NuNV"` after the earlier `8439679`).  

**Called Functions**:  
- `0x80b01e` – Console output function (prints initial status).  
- `0x80b052` – Main SCSI read routine.  
- `0x80af7a` – Post‑read verification or processing routine.  
- `0x80b0f0` – Console output function (prints completion/error status).

**Notes**:  
- The string `"N^NuNV"` at `8439684` is likely a compressed or encoded status message (common in boot ROMs to save space). It may decode to something like `"READ OK"` or `"SECTOR X"`.  
- The shared variable at `0xC03A7C` appears to hold a drive/unit selector where bit 0 determines active LUN or drive, and shifting right by 1 extracts a unit index.  
- The function is careful to clean up the stack after the nested call (`lea %sp@(20),%sp`), indicating it follows standard C calling conventions.  
- This routine is part of the boot loader’s block‑level disk access, used for loading kernel images or filesystem structures during boot.

---

### Function at 0x80ba04

**Embedded strings:**
- `8436432`: `"N^NuNV"`
- `8436482`: `"NuNV"`
- `8436518`: `"g"(|"`

**Name**: `boot_loader_main` or `load_and_boot_kernel`

**Purpose**: This function appears to be the main boot loader routine that loads a kernel image from disk into memory, sets up hardware control registers, and transfers execution to the loaded kernel. It handles memory initialization, loads data from disk (likely via SCSI), enables system mapping, and prepares the system for kernel execution before jumping to it.

**Parameters**: 
- `%fp@(8)` (first argument on stack): Likely a device/unit specification (e.g., SCSI ID/LUN or block count). The value is shifted left by 18 bits (`asll #8` then `asll #10`), suggesting it's being converted to a memory address offset or size.

**Returns**: 
- No explicit return (function likely transfers control to loaded kernel and never returns).
- Modifies shared memory locations `0xc03a80` and `0xc03a7c` (clears them).
- Sets `0xc03b8c` to 1 (possibly a boot flag).

**Key Operations**:
- Clears two shared memory locations (`0xc03a80`, `0xc03a7c`).
- Calls `0x80b57a` (likely hardware initialization or SCSI setup).
- Loops calling `0x80bb04` with incrementing addresses (every 8192 bytes) up to a limit derived from the input parameter, suggesting block-by-block loading of data into memory.
- Calls `0x80bb04` with fixed addresses `0x00c00000` and `0x00c02000` (shared memory/data area) with count 0, possibly for initialization or verification.
- Prints a string at address `0x80bad4` (which contains "N^NuNV" when interpreted as ASCII) with length 0x800.
- Sets bit 8 (0x0100) in hardware control register `0xe00016` (System control: likely enables `DIS.MAP` or similar memory mapping).
- Calls `0x80bb04` twice more with counts 0x800 and 0x2800, likely loading additional kernel segments.
- Sets a boot flag at `0xc03b8c`.
- Calls `0x80b61c` (possibly final hardware setup or kernel preparation).
- Prints a string at `0x80c789` (likely a boot message).
- Calls `0x809266` (which appears to be a jump-to-kernel routine based on its location in the ROM).
- Includes an embedded subroutine (starting at `0x80bad4`) that copies 0x4000 bytes from `0x0900000` to `0x800`, then sets `0xc03b58` to 1 and enters an infinite loop (`60fe bra.s *`). This may be a secondary loader or diagnostic routine.

**Called Functions**:
- `0x80b57a`: Unknown (hardware/SCSI init)
- `0x80bb04`: Likely `read_blocks` (loads data from disk to memory)
- `0x809dc0`: Likely `print_string` (prints a string of given length)
- `0x80b61c`: Unknown (kernel setup)
- `0x809f94`: Likely `print_string` (null-terminated string)
- `0x809266`: Likely `jump_to_kernel` (transfers control to loaded code)
- Embedded routine at `0x80bad4`: Copies memory and halts (possibly a failsafe)

**Notes**:
- The function uses `%a5` as a running memory address pointer, incrementing by 8192 (0x2000) per loop iteration, which matches typical disk block sizes (8KB).
- The hardware register write to `0xe00016` (System control) with value 0x0100 likely enables memory mapping (`DIS.MAP` bit) before kernel execution.
- The embedded routine at `0x80bad4` is suspicious: it copies 16KB from ROM (`0x0900000` is likely a typo in the disassembly; should be `0x00900000` which is in ROM space) to low memory at `0x800`, sets a flag, then infinite loops. This may be a vestigial secondary boot stage or a debug trap.
- The function appears to load three main segments: (1) a variable-sized block up to the parameter-derived limit, (2) a fixed 0x800-byte block, and (3) a fixed 0x2800-byte block.
- Shared memory area `0xc00000` is used for boot flags and communication with the kernel.

---

### Function at 0x80bb04

**Embedded strings:**
- `8436518`: `"g"(|"`
- `8436592`: `"N^NuNV"`

**Name**: `boot_setup_bootstrap_buffer`

**Purpose**: This function sets up a bootstrap buffer in shared memory, either by copying data into a fixed buffer at 0xC00800 or by directly using a provided buffer address. It then initializes a shared memory structure at 0xC03A90 with the buffer address and size (8192 bytes) and calls a configuration function. This appears to prepare a bootstrap program or kernel image for loading, likely for transfer to the Job processor or for a secondary boot stage.

**Parameters**:  
- `%fp@(8)` (first argument): A flag indicating whether to copy data (non-zero) or just record the buffer address (zero).  
- `%fp@(12)` (second argument): A pointer to the source data buffer (if copying) or the buffer to use directly.

**Returns**: No explicit return value; side effects are in shared memory and hardware.

**Key Operations**:
- Calls a function at `0x809f94` with arguments `%a5` (the buffer pointer) and a hardcoded value `0x80c796` (likely a format string or control block).
- If the flag (`%fp@(8)`) is non-zero:
  - Copies up to 8192 bytes from the source buffer at `%a5` to a fixed destination at `0xC00800` (shared memory region).
  - Stores the fixed destination address `0xC00800` into shared memory location `0xC03A90`.
- If the flag is zero:
  - Stores the original buffer pointer `%a5` directly into `0xC03A90`.
- Always stores the constant `8192` (0x2000) into `0xC03A94` (buffer size field).
- Calls a function at `0x80b676` with arguments `10` and `16` (decimal), likely to configure something related to the bootstrap process (maybe SCSI or memory mapping).

**Called Functions**:
- `0x809f94` – Unknown function, possibly a debug output or validation routine.
- `0x80b676` – Unknown function, likely a hardware/SCSI initialization routine based on common boot loader patterns.

**Notes**:
- The fixed buffer address `0xC00800` is in the shared RAM area (`0xC00000–0xC00FFF`), accessible by both DMA and Job processors.
- The shared structure at `0xC03A90` likely holds a bootstrap descriptor: a 4-byte buffer pointer followed by a 4-byte buffer size.
- The constants 10 and 16 passed to `0x80b676` may correspond to SCSI ID/LUN or memory page configuration.
- This function is part of the boot loader’s mechanism to stage a kernel or secondary boot program before handing control to the Job processor. The copy vs. direct buffer option suggests flexibility for different boot sources (e.g., ROM, disk, network).

---

### Function at 0x80bb74

**Embedded strings:**
- `8436666`: `"N^NuNV"`

**Name**: `copy_boot_sectors_to_shared_memory`

**Purpose**: This function copies the first 512 bytes (one sector) from the boot ROM at 0xC00400 into shared RAM at 0xC00000, then copies 16 bytes from a hardware register area at 0xE00000 into a small buffer at 0xC00672. This likely initializes a shared data structure in RAM for the Job processor or a subsequent boot stage, combining a boot block with current hardware status.

**Parameters**: None (the function takes no explicit arguments; all addresses are hardcoded).

**Returns**: No explicit return value. The function modifies memory at 0xC00000-0xC001FF (512 bytes) and 0xC00672-0xC00691 (16 bytes).

**Key Operations**:
- Copies 256 words (512 bytes) from source address 0xC00400 (likely within the U15 boot ROM) to destination 0xC00000 (shared RAM area).
- Copies 8 words (16 bytes) from source address 0xE00000 (system status and control register read area) to destination 0xC00672 (a small buffer in shared RAM).
- Uses a loop counter in `%d7` to track the number of words copied in each stage.

**Called Functions**: None (this function contains no `jsr` or `bsr` instructions).

**Notes**:
- The first copy (512 bytes) likely transfers a boot sector or small boot program from ROM into shared RAM where the Job processor can access it.
- The second copy reads 16 bytes from the hardware status registers at 0xE00000–0xE0000E (since it reads words from `%a4@+` starting at 0xE00000) and stores them at 0xC00672. This may capture the system’s power‑up state (PEH/PEL, enable flags, etc.) for diagnostics or configuration.
- The destination 0xC00672 is in the shared RAM area (0xC00000–0xC00FFF) and may be part of a known data structure used by the boot loader or kernel.
- The function preserves registers `%d7`, `%a4`, `%a5` via `moveml` and uses a standard stack frame, suggesting it is a subroutine called from elsewhere in the boot ROM.

---

### Function at 0x80bbbe

**Embedded strings:**
- `8436858`: `"NuNV"`
- `8436884`: `"N^NuNV"`

**Name**: `dump_hardware_status_registers`

**Purpose**: This function reads and prints the contents of key hardware status registers from the Plexus P/20's control/status memory area (0xE00000–0xE001FF). It appears to be a diagnostic or debug routine that outputs formatted register values, likely for system monitoring or fault analysis. The function runs in an infinite loop after printing (via the `bras` at 0x80bc78), suggesting it is meant to halt further execution while displaying status.

**Parameters**:  
- Two parameters passed on the stack at `%fp@(8)` and `%fp@(12)` (likely a format string pointer and an argument for the first `jsr` call).  
- The hardware base address `0xE00000` is hardcoded into register `%a5`.

**Returns**:  
None—the function does not return; it enters an infinite loop after printing.

**Key Operations**:  
- Calls a formatting/output routine at `0x809f94` (likely `printf`-like) four times with different format strings and register values.  
- Reads 16-bit hardware registers at offsets from `%a5` (`0xE00000`):  
  - First group (offsets 0, 2, 4): reads `0xE00000`, `0xE00002`, `0xE00004`.  
  - Second group (offsets 6, 8, 10, 12, 14): reads `0xE00006` through `0xE0000E`.  
  - Third group (offsets 20, 22, 24, 26, 30): reads `0xE00014`, `0xE00016`, `0xE00018`, `0xE0001A`, `0xE0001E`.  
- Each read zero-extends the 16-bit value to 32 bits before pushing onto the stack for printing.  
- Uses hardcoded string pointers:  
  - `0x8439713` (first format string)  
  - `0x8439751` (second format string)  
  - `0x8439792` (third format string)  
  - `0x8439840` (fourth format string)  
- Ends with a branch-to-self (`bras 0x80bc78`)—infinite loop.

**Called Functions**:  
- `0x809f94` (called four times)—likely a formatted print function similar to `printf`.

**Notes**:  
- The hardware base `0xE00000` corresponds to the system status/control registers in the Plexus memory map.  
- Offsets match known register layouts:  
  - `0xE00000`: System status (PEH, PEL, EN.BLK, etc.)  
  - `0xE00002`: More status (DIS.MAP, RES.DMA, HALT.DMA, etc.)  
  - `0xE00004`: Job processor address on bus error  
  - `0xE00014`: Bus error details  
  - `0xE00016`: Control register readback  
  - `0xE00018`: Processor status (EN.JOB, INT.JOB, etc.)  
  - `0xE0001A`: Serial port status (RI, TCE, RCE, DSR)  
  - `0xE0001E`: Unknown (not documented in provided list)  
- The function may be part of a failure handler or a debug command that dumps hardware state before halting.  
- The infinite loop suggests this is a “stop and display” diagnostic, possibly invoked after a critical error.

---

### Function at 0x80bc7c

**Embedded strings:**
- `8436884`: `"N^NuNV"`

**Name**: `boot_clear_shared_vars`  

**Purpose**: This function initializes three shared memory variables in the fixed RAM area at `0xC00000–0xC00FFF` to known default values. It appears to be part of the boot loader’s startup sequence, clearing or resetting shared data structures that may be used for communication between the DMA and Job processors, or for tracking boot state (such as device handles, error flags, or SCSI operation results).  

**Parameters**: None — the function uses no input registers or stack parameters.  

**Returns**: No explicit register return value; the function’s effect is purely side‑effects on shared memory at `0xC03B90`, `0xC03B94`, and `0xC03B98`.  

**Key Operations**:  
- Clears the longword at `0xC03B90` to zero.  
- Clears the word at `0xC03B94` to zero.  
- Writes `0xFFFFFFFF` (`-1`) to the longword at `0xC03B98`.  

**Called Functions**: None — this is a leaf function with no `jsr` or `bsr` instructions.  

**Notes**:  
- The addresses `0xC03B90`, `0xC03B94`, and `0xC03B98` lie within the shared RAM region `0xC00000–0xC00FFF` mentioned in the memory map, confirming these are shared variables between the DMA and Job processors.  
- The pattern of clearing two locations to zero and setting one to `-1` suggests initialization of a small data structure, possibly containing a handle, status code, or error indicator (where `-1` often means “invalid” or “uninitialized”).  
- The function uses a standard stack frame (`linkw %fp,#-4`) but does not actually use local stack variables; this may be for consistency with other functions in the ROM or to allow easy debugging.  
- Given its location in the U15 boot ROM and its simple memory‑writing behavior, this routine likely runs early in the boot process to ensure shared state is clean before proceeding with device probing or loading.

---

### Function at 0x80bc98

**Embedded strings:**
- `8437054`: `"N^NuNV"`

**Name**: `verify_checksum_or_crc`  

**Purpose**:  
This function appears to validate a checksum or CRC value received from a data stream (likely from a serial port or SCSI data) against an accumulated checksum stored in memory. It reads two bytes from an external source, combines them into a 16‑bit value, compares it with a running checksum, and prints an error message if they don’t match. The function also handles special control codes (‑44 and ‑33) that may indicate end‑of‑data or padding.

**Parameters**:  
- No explicit register parameters.  
- Uses memory location `0xc03b94` (16‑bit checksum accumulator).  
- Uses memory location `0xc03b98` (possibly a flag or expected final value, compared against `0xffffffff`).  
- Uses memory location `0xc03b90` (termination flag; if non‑zero, skips reading loop).

**Returns**:  
- No explicit return value.  
- Side effects: updates `0xc03b94` with accumulated bytes, prints error on mismatch via `0x809f94`.

**Key Operations**:  
- Checks if `0xc03b94` is non‑zero; if so, jumps near the end.  
- Compares `0xc03b98` with `0xffffffff`; if not equal, jumps near the end.  
- Calls `0x80bdc0` repeatedly to read a byte/word (likely from serial or SCSI data port).  
- Handles special values:  
  - If read value is `‑44` (`0xffd4`), treats as end‑of‑data marker.  
  - If read value is `‑33` (`0xffdf`), calls `0x809266` with argument `3` (possibly a flush or control operation).  
- Accumulates lower 16 bits of each read value into `0xc03b94`.  
- Reads two more bytes, combines them into a 16‑bit big‑endian value, and compares with the accumulated checksum.  
- On mismatch, calls `0x809f94` (likely `printf`‑like) with format string at `0x80c85c` (string `"N^NuNV"` may be a debug/error message) and the expected vs. actual checksum values.

**Called Functions**:  
- `0x80bdc0` — read byte/word from I/O (serial/SCSI).  
- `0x809266` — unknown, called with argument `3` when value `‑33` is read.  
- `0x809f94` — formatted print/error reporting function.

**Notes**:  
- The function uses a linked stack frame but mostly works with global memory addresses (`0xc03b90`, `0xc03b94`, `0xc03b98`), suggesting these are shared DMA‑processor variables in the fixed RAM area at `0xc00000`.  
- The checksum is accumulated as words (16‑bit), ignoring high 16 bits of each read.  
- The special values `‑44` and `‑33` likely correspond to ASCII‑like control characters (e.g., `0xd4`, `0xdf` in 8‑bit context) used as protocol markers.  
- The error message string `"N^NuNV"` at `0x80c85c` may be a mnemonic for “No Match” or similar; it is printed with two arguments: the accumulated checksum and the received checksum.  
- This routine seems part of a boot‑loader data‑receiving protocol, possibly validating a downloaded kernel image or filesystem block.

---

### Function at 0x80bd42

**Embedded strings:**
- `8437180`: `"N^NuNV"`

**Name**: `process_serial_input_or_timeout`

**Purpose**: This function handles serial input polling with timeout detection, processing special control characters (Ctrl-T and Ctrl-_) that toggle a global flag, while accumulating a checksum of other received characters. It returns whether a character was processed, and maintains state for serial input handling in the boot loader's interactive prompt.

**Parameters**: 
- No explicit register parameters
- Implicitly uses global memory locations:
  - `0xc03b90`: Input processing enabled flag (non-zero when Ctrl-T/Ctrl-_ received)
  - `0xc03b98`: Timeout counter/flag
  - `0xc03a04`: Likely a timer or counter base value
  - `0xc03a90`: Pointer to serial input buffer or status register
  - `0xc03b94`: 16-bit checksum accumulator

**Returns**:
- `%d0`: Boolean result (0 = no character processed, 1 = character processed)
- Side effects: Updates `0xc03b90`, `0xc03b98`, `0xc03b94` in global memory

**Key Operations**:
- Checks if input processing is already active (`0xc03b90`), returning immediately if so
- Handles timeout condition using `0xc03b98` flag and a timer check via `0xc03a04`
- Calls serial input function at `0x80bdc0` (likely `get_serial_char` or similar)
- Stores received character to buffer/register at `0xc03a90`
- Detects Ctrl-T (0xD4 = -44) and Ctrl-_ (0xDF = -33) to toggle `0xc03b90` flag
- For other characters, adds low 16 bits to checksum at `0xc03b94`
- Always returns 1 when a character is processed (except when input processing already active)

**Called Functions**:
- `0x80a1ac`: Likely a timer/delay or timeout checking function (called with timer value + 128)
- `0x80bdc0`: Serial character input function (returns character in %d0)

**Notes**:
- The timeout mechanism uses a counter at `0xc03b98` that's cleared after approximately 128 timer ticks of no activity
- Ctrl-T and Ctrl-_ appear to be special "enable input processing" toggle characters (common in boot monitors for debug modes)
- The checksum accumulation at `0xc03b94` suggests the function might be part of a protocol for receiving data blocks (like XMODEM) or verifying command integrity
- The function preserves `%d7` across calls (saved on stack)
- The string "N^NuNV" referenced nearby might be related to serial protocol messages or error codes
- This is likely part of the boot loader's interactive command line input handling, processing serial input while managing timeouts and special control sequences

---

### Function at 0x80bdc0

**Embedded strings:**
- `8437314`: `"N^NuNV"`

**Name**: `get_scsi_device_info` or `scsi_inquiry_decode`

**Purpose**: This function appears to perform SCSI INQUIRY command processing, specifically extracting and combining device type and vendor-specific information from the INQUIRY response data. It reads the SCSI INQUIRY data from a known memory buffer (likely populated by a previous SCSI command), checks for valid SCSI peripheral device types (0x21 for sequential-access, 0x1C for scanner, or 0x2C for processor), and if valid, calls a helper function to extract additional information before combining both pieces of data into a single return value.

**Parameters**: No explicit parameters passed via registers. The function reads from fixed memory address `0xc03a04`, which is in the shared RAM area and likely contains a pointer to SCSI INQUIRY response data.

**Returns**: Returns a 32-bit value in D0. For valid SCSI device types (0x21 or 0x2C), it returns a negative error code (negated device type). For other cases, it returns a combined value where bits 0-3 contain information from the first INQUIRY byte (device type) and bits 4-7 contain information from the second INQUIRY byte (likely vendor-specific qualifier or RMB bit), effectively creating a 16-bit device identifier.

**Key Operations**:
- Reads SCSI INQUIRY data from memory buffer at `0xc03a04 + 128` (offset 0x80 into the buffer)
- Calls subroutine at `0x80a1ac` twice to extract single bytes from the INQUIRY response (likely `get_inquiry_byte`)
- Compares extracted bytes against SCSI device type codes: 0x21 (sequential-access device) and 0x2C (processor device)
- For valid device types, returns negated type as error code
- For other types, calls helper function at `0x80be46` to process each byte
- Combines results: `(second_byte_result << 4) | first_byte_result`

**Called Functions**:
- `0x80a1ac`: Likely `get_scsi_inquiry_byte` - extracts a byte from INQUIRY data
- `0x80be46`: Likely `decode_inquiry_field` - processes individual INQUIRY bytes

**Notes**:
- The function accesses shared RAM at `0xc03a04`, which is consistent with the Plexus memory map where `0xC00000-0xC00FFF` is shared variables/data area
- The offset 128 (0x80) into the INQUIRY buffer suggests structured SCSI response data, possibly with a header
- The specific device type checks (0x21 and 0x2C) correspond to SCSI-1 peripheral device types: 0x21 is sequential-access (tape), 0x2C is processor device
- The function appears to handle two different INQUIRY reads (lines `80bdcc` and `80bdf8`), suggesting it might be comparing or processing two different bytes from the response
- The final combination `(second << 4) | first` suggests creating a composite device identifier, possibly for device selection or configuration purposes
- The negative return for specific device types might indicate these devices require special handling or are unsupported in normal boot operations

---

### Function at 0x80be46

**Embedded strings:**
- `8437504`: `"N^Nu"`
- `8437848`: `"N^Nuinvalid object file (0x%x)"`

**Name**: `parse_boot_command` or `dispatch_boot_command`

**Purpose**: This function implements a jump table/dispatcher for boot loader commands. It takes a numeric command identifier (likely from parsing user input at the ":" prompt) and maps it to a corresponding handler address. The function validates the command ID range, performs case conversion (uppercase letters to lowercase), and returns the handler address for valid commands, or zero/null for invalid ones.

**Parameters**: 
- `%d7` (long) contains the input command identifier (passed via stack at `%fp@(8)`). Based on the jump table logic, this appears to be an ASCII character code (e.g., '0'-'9', 'A'-'Z', 'a'-'z').

**Returns**:
- `%d7` (long) contains the handler address for valid commands, or zero for invalid commands (see the default path at 0x80beda which loads 0x2007 then branches to 0x80bede, ultimately returning 0).

**Key Operations**:
- Validates input command ID is in range 0x30–0x66 (ASCII '0' through 'f') via subtract and compare.
- Uses a jump table (starting at 0x80be6c) with 54 entries (one per possible input value) to dispatch to three conversion routines or the default invalid path.
- Conversion routines handle:
  - 0x80bede: Converts uppercase letters ('A'-'Z', 0x41–0x5A) to lowercase by subtracting 0x30 (actually converts '0'-'9' to numeric 0–9, but used here for letters).
  - 0x80bee4: Converts lowercase letters ('a'-'z', 0x61–0x7A) to a different offset by subtracting 0x57.
  - 0x80bef0: Handles the range 0x37–0x?? (specific conversion for some values).
- After conversion, the function likely uses the adjusted value to index into a second table (starting at 0x80bf04) that maps command IDs to handler addresses. Each table entry appears to be 8 bytes: a 4-byte address followed by a 4-byte identifier (possibly a command code or subcode).

**Called Functions**: None directly; this is a leaf function.

**Notes**:
- The jump table at 0x80be6c contains relative branch offsets (words) that point to the three conversion routines or the default invalid handler. The offsets 0x0072, 0x006e, 0x0084 correspond to the distances to those routines.
- The second table (0x80bf04–0x80c018) is likely a static array of structs mapping command IDs to handler addresses and possibly additional metadata (like command flags or subcommand codes).
- The function appears to be part of the boot command interpreter, translating a single-character or numeric command into a function pointer for execution.
- The presence of the string "invalid object file (0x%x)" nearby suggests this function might also be used for validating/loading a.out file types, but the immediate code is purely a dispatcher.
- The hardware context is not directly used here; this is pure command parsing logic.

---

### Function at 0x80c01c

**Embedded strings:**
- `8437848`: `"N^Nuinvalid object file (0x%x)"`
- `8437879`: `"%s: not found"`
- `8437893`: `"bad directory"`
- `8437907`: `"bad bn %D"`
- `8437917`: `"unknown device"`
- `8437932`: `"bad offset or unit specification"`
- `8437965`: `"unable to wake up disk controller"`
- `8437999`: `"bad disk init"`
- `8438013`: `"bad disk read"`
- `8438027`: `"invalid disk init block"`
- `8438051`: `"unable to wake up tape controller"`
- `8438085`: `"bad tape init"`
- `8438099`: `"bad tape read"`
- `8438113`: `"bad tape seek"`
- `8438127`: `"tape save error"`
- `8438143`: `"tape recall error"`
- `8438161`: `"rubout encountered"`
- `8438180`: `"disk error %X, %X"`
- `8438198`: `"tape error %X, %X"`

**Name**: `lookup_error_message`  

**Purpose**:  
This function searches a table of error codes and corresponding message strings for a given error code. If a match is found, it prints the associated message via a printf‑like output routine. If no match is found, it returns without printing anything. The table is terminated by a zero word.  

**Parameters**:  
- `%fp@(8)` (`%a5` after load): pointer to the error‑code/message table (each entry is 6 bytes: 2‑byte error code, 4‑byte string pointer)  
- `%fp@(12)` (`%d7` after load): error code to look up (32‑bit, but table stores only 16‑bit codes)  

**Returns**:  
No explicit return value. If a match is found, the function calls a print routine; otherwise it returns silently.  

**Key Operations**:  
- Iterates over a table of (error code, message pointer) pairs.  
- Each table entry is 6 bytes: a word‑sized error code (zero‑extended to 32 bits for comparison) followed by a longword pointer to a string.  
- Compares the input error code with each table entry; on match, pushes the string pointer and a format‑string address onto the stack and calls a print function (likely `printf` or similar).  
- Table termination is detected by a zero word (error code = 0).  
- Saves/restores registers `%d7` and `%a5` across the call.  

**Called Functions**:  
- `0x809f94` – a print/formatting function (likely `printf` or a custom message output routine). The format string at `0x80cc4f` is probably `"%s"` or similar, given that only the matched string pointer is passed.  

**Notes**:  
- The function is compact and specialized for error‑message lookup, typical of boot‑loader or diagnostic code.  
- The table likely resides in ROM, given the U15 ROM address range.  
- The strings listed in the prompt (e.g., `"invalid object file (0x%x)"`, `"bad directory"`, etc.) are probably the messages referenced by the table entries.  
- The code after the function (`0x80c05c` onward) appears to be inline string data (possibly part of the table or other messages), not executable instructions.  
- The comparison uses `movew %a5@,%d0` then `extl %d0`, indicating the stored error codes are 16‑bit values.  
- The function does not handle duplicate error codes; it returns on the first match.

---

### Function at 0x80c16e

**Embedded strings:**
- `8438127`: `"tape save error"`
- `8438143`: `"tape recall error"`
- `8438161`: `"rubout encountered"`
- `8438180`: `"disk error %X, %X"`
- `8438198`: `"tape error %X, %X"`
- `8438216`: `"file"`
- `8438226`: `"sc(0,0)/"`
- `8438235`: `"Exit %d"`

**Name**: `print_error_strings`  

**Purpose**: This function is not executable code but rather a data section containing embedded error message strings used elsewhere in the boot loader. It stores four error strings (and part of a fifth) that are printed when the boot loader encounters specific failures, such as tape save/recall errors, user input cancellation, and disk/tape errors with formatted codes.  

**Parameters**: None — this is a static data block.  

**Returns**: None — this is data, not a subroutine.  

**Key Operations**:  
- Contains the literal strings:  
  - `"tape save error"` (starting at `0x80c16e`)  
  - `"tape recall error"` (starting at `0x80c17e`)  
  - `"rubout encountered"` (starting at `0x80c190`)  
  - `"disk error %X, %X"` (starting at `0x80c1a2`)  
  - The next string (`"tape error %X, %X"`) begins immediately after but extends beyond the given range.  
- The data is stored as ASCII characters encoded within Motorola 68010 instruction words, likely placed here by the assembler using `.dc.b` or `.ascii` directives.  

**Called Functions**: None — this is not executable code.  

**Notes**:  
- The addresses (`0x80c16e`–`0x80c1a6`) fall within the U15 ROM region (`0x808000`–`0x80FFFF`), confirming this is part of the boot loader’s static data.  
- The strings match those referenced in the provided string list (e.g., `8438127` corresponds to `"tape save error"`), suggesting these addresses are referenced via a pointer table elsewhere in ROM.  
- The data is interleaved with opcode-like bit patterns because the disassembler incorrectly interprets ASCII as instructions — a common artifact when disassembling data regions.  
- These error messages are likely used by higher-level boot routines that handle SCSI tape operations, disk boot failures, and user command-line input parsing (e.g., when a user presses rubout/backspace to cancel input).

---

### Function at 0x80c1a8

**Embedded strings:**
- `8438198`: `"tape error %X, %X"`
- `8438216`: `"file"`
- `8438226`: `"sc(0,0)/"`
- `8438235`: `"Exit %d"`
- `8438260`: `"dtot"`
- `8438265`: `"ttod"`

**Name**: `print_tape_error`  

**Purpose**:  
This function appears to be a fragment of error‑handling code that prepares arguments for a `printf`‑style formatted output routine, specifically for reporting tape‑related errors. The embedded ASCII strings suggest it formats a message like `"tape error %X, %X"` using two error codes pulled from the stack or a data structure. The function likely receives error codes via registers or the stack, then passes them along with a format‑string address to a console‑output routine.

**Parameters**:  
- Inputs are likely passed via the stack or registers `%a5` and `%a4` (used as address registers pointing to arguments or a saved context).  
- The format string `"tape error %X, %X"` (at address `0x8438198`) is implicitly referenced.  
- Two error codes (or values) are taken from memory at `%a5@-` (pre‑decrement addressing).

**Returns**:  
- No explicit return value; side effect is output to the console (serial port).  
- Registers `%d0`, `%d1`, `%d2`, `%a0` are modified during the sequence.

**Key Operations**:  
- Loads two error values from memory via `movel %a5@-,%d0` and `moveal %a5@-,%a0` (the latter may be a misinterpreted data load due to disassembly of embedded ASCII).  
- Contains embedded ASCII data `"tape error %X, %X"` and `"file"` within the code stream, suggesting the routine may be part of a larger message‑printing system.  
- Uses `addqb` instructions that likely adjust stack or pointer offsets for argument passing.  
- No direct hardware register accesses visible in this snippet; output is presumably via a higher‑level print function.

**Called Functions**:  
- None directly in this fragment, but the code likely prepares arguments for a formatted‑print routine (e.g., `printf`‑like function elsewhere in ROM, possibly at `0x808xxx`).

**Notes**:  
- The disassembly shows intermixed ASCII strings (`"tape error %X, %X"`, `"file"`) with Motorola 68010 instructions, indicating the disassembler incorrectly interpreted data as code. This is common in ROMs where data tables are placed immediately after code.  
- The actual function entry point may be earlier than `0x80c1a8`; this snippet is likely part of a larger error‑reporting routine that handles multiple device‑type errors (tape, disk, etc.).  
- The strings `"dtot"` and `"ttod"` nearby suggest related device‑name abbreviations (disk‑to‑tape, tape‑to‑disk).  
- Given the Plexus boot loader’s support for tape (`mt()`) and SCSI devices, this function probably reports errors during tape backup/restore operations or tape‑based boot attempts.

---

### Function at 0x80c2f4

**Embedded strings:**
- `8438534`: `"illegal system V a.out magic %o\n"`
- `8438567`: `"text protect\n"`
- `8438581`: `"ts(%d) ds(%d) bs(%d)\n"`
- `8438603`: `"\nBOOT: Bad Interrupt \n"`
- `8438626`: `"PC %x   Status Reg %x    Vector %x\n"`
- `8438662`: `"Access Address %x \n"`
- `8438682`: `"Robin Debug Boot Version 0.0\n"`
- `8438712`: `"In setmap tp(%d) dp(%d)\n"`
- `8438737`: `"Exit setmap pageno(%d)\n"`
- `8438761`: `"\nI_PERR1 0x%x I_PERR2 0x%x I_MBERR 0x%x\n"`
- `8438802`: `"I_SC_C 0x%x 0x%x  I_SC_P 0x%x 0x%x I_SC_R 0x%x\n"`
- `8438850`: `"I_ERR 0x%x I_MISC 0x%x I_KILL 0x%x I_TRCE 0x%x I_USER 0x%x\n"`
- `8438910`: `"0123456789ABCDEF"`

**Name**: `print_boot_strings_table`

**Purpose**: This function is not executable code but a data table containing embedded ASCII strings used by the boot loader for error messages, debug output, and status reporting. The strings are stored in a contiguous block within the U15 ROM and are referenced by other functions via their absolute addresses. The table includes messages for illegal a.out magic numbers, text protection errors, boot interrupt errors, register dumps, debug version banners, memory map status, and hardware error register labels.

**Parameters**: None (this is a data table, not a function).

**Returns**: None (this is a data table, not a function).

**Key Operations**:
- Contains the string `"illegal system V a.out magic %o\n"` (address ~0x8438534)
- Contains the string `"text protect\n"` (address ~0x8438567)
- Contains the string `"ts(%d) ds(%d) bs(%d)\n"` (address ~0x8438581)
- Contains the string `"\nBOOT: Bad Interrupt \n"` (address ~0x8438603)
- Contains the string `"PC %x   Status Reg %x    Vector %x\n"` (address ~0x8438626)
- Contains the string `"Access Address %x \n"` (address ~0x8438662)
- Contains the string `"Robin Debug Boot Version 0.0\n"` (address ~0x8438682)
- Contains the string `"In setmap tp(%d) dp(%d)\n"` (address ~0x8438712)
- Contains the string `"Exit setmap pageno(%d)\n"` (address ~0x8438737)
- Contains the string `"\nI_PERR1 0x%x I_PERR2 0x%x I_MBERR 0x%x\n"` (address ~0x8438761)
- Contains the string `"I_SC_C 0x%x 0x%x  I_SC_P 0x%x 0x%x I_SC_R 0x%x\n"` (address ~0x8438802)
- Contains the string `"I_ERR 0x%x I_MISC 0x%x I_KILL 0x%x I_TRCE 0x%x I_USER 0x%x\n"` (address ~0x8438850)
- Contains the hex digit string `"0123456789ABCDEF"` (address ~0x8438910)

**Called Functions**: None (this is a data table, not a function).

**Notes**:
- The addresses shown in the listing (0x80c2f4–0x80c448) are within the U15 ROM range (0x808000–0x80FFFF), confirming this is part of the boot loader's static data.
- The strings are interleaved with what appear to be opcode bytes (e.g., `0x4144`, `0x204d`, `0x4147`), which are actually ASCII characters `"AD"`, `" M"`, `"AG"` when interpreted as big-endian 16-bit words. This is typical of mixed code/data disassembly where the disassembler incorrectly interprets data as instructions.
- The strings relate to boot-time diagnostics: a.out validation, memory protection, interrupt handling, register dumps, and hardware error register reporting (PERR=parity error, MBERR=Multibus error, SC_C/SC_P/SC_R likely relate to SCSI controller/port/response, ERR/MISC/KILL/TRCE/USER are other status bits).
- The "Robin Debug Boot Version 0.0" string suggests a debug or development version of the boot loader.
- The hex digit string at the end is likely used by a `printf`-like formatting routine for converting numbers to hex output.
- This table is referenced by other functions in the boot loader that need to output these messages, likely via `printf` or similar output routines that take string pointers.

---

### Function at 0x80c44c

**Embedded strings:**
- `8438910`: `"0123456789ABCDEF"`
- `8438927`: `"BOOT: "`
- `8438934`: `"Enter arbit\n"`
- `8438947`: `"Enter select\n"`
- `8438961`: `"scsi busy not set by target\n"`
- `8438990`: `"Enter scrwi\n"`
- `8439003`: `"Enter s_d_i_int\n"`
- `8439020`: `"Enter s_d_o_int\n"`
- `8439037`: `"Enter s_s_i_int\n"`
- `8439054`: `"Enter s_m_i_int\n"`
- `8439071`: `"Enter s_m_o_int\n"`
- `8439088`: `"Enter s_c_o_int\n"`
- `8439105`: `"Enter resel\n"`
- `8439118`: `"Boot: scsi abort\n"`

**Name**: `scsi_debug_print_status`  

**Purpose**: This function prints SCSI controller status and debug messages to the console. It appears to be part of a low‑level SCSI debugging routine that outputs status codes in hexadecimal, along with fixed strings indicating SCSI bus phases (e.g., arbitration, selection, data‑in, data‑out, command, message‑in, message‑out, reselection) and error messages. The function likely formats and displays SCSI controller register contents for troubleshooting during boot or SCSI operations.

**Parameters**:  
- Inputs are likely passed in registers (e.g., status byte in `%d0` or `%d1`), but the given snippet is primarily a data table, not executable code. The surrounding code would load a status value and call a print routine that indexes into this table.

**Returns**:  
- No return value; side effect is console output.

**Key Operations**:  
- Contains embedded ASCII strings for SCSI phase names:  
  - `"SCSI C %x"` (Command phase)  
  - `"SCSI L %x"` (Status phase)  
  - `"SCSI TRCE %x"` (Transfer Control?)  
  - `"SCSI USER %x"` (User data?)  
- Contains debug message strings:  
  - `"BOOT: "`  
  - `"Enter arbit\n"` (Arbitration phase)  
  - `"Enter select\n"` (Selection phase)  
  - `"scsi busy not set by target\n"` (SCSI timeout/error)  
  - `"Enter scrwi\n"` (SCSI R/W initiate?)  
  - `"Enter s_d_i_int\n"` (SCSI Data‑In interrupt)  
  - `"Enter s_d_o_int\n"` (SCSI Data‑Out interrupt)  
  - `"Enter s_s_i_int\n"` (SCSI Status‑In interrupt)  
  - `"Enter s_m_i_int\n"` (SCSI Message‑In interrupt)  
  - `"Enter s_m_o_int\n"` (SCSI Message‑Out interrupt)  
  - `"Enter s_c_o_int\n"` (SCSI Command‑Out interrupt)  
  - `"Enter resel\n"` (Reselection phase)  
  - `"Boot: scsi abort\n"`  
- Includes hex digit table `"0123456789ABCDEF"` for number formatting.

**Called Functions**:  
- None directly in this snippet; this is a data region. The calling code would likely use `jsr` or `bsr` to a print function (e.g., `printf`‑style routine in ROM).

**Notes**:  
- The addresses `0x80c44c–0x80c50e` contain intermixed ASCII strings and what appear to be format strings with `%x` placeholders, suggesting a simple formatted‑output routine for SCSI debugging.  
- The strings match known SCSI bus phases (Command, Status, Data‑In, Data‑Out, Message‑In, Message‑Out) and error conditions, indicating this function is used to trace SCSI bus state changes.  
- The data is not executable code; it is a string pool used by SCSI debugging routines elsewhere in the boot ROM.  
- The presence of `"BOOT: "` prefix suggests these messages are printed during the boot loader’s SCSI initialization or disk‑read operations.  
- The hex table at `0x80c480` (`"0123456789ABCDEF"`) is typical for byte‑to‑hex‑ASCII conversion routines.

---

### Function at 0x80c510

**Embedded strings:**
- `8439071`: `"Enter s_m_o_int\n"`
- `8439088`: `"Enter s_c_o_int\n"`
- `8439105`: `"Enter resel\n"`
- `8439118`: `"Boot: scsi abort\n"`
- `8439136`: `"Enter saveptrs\n"`
- `8439152`: `"Enter loadptrs\n"`
- `8439168`: `"DISK"`
- `8439173`: `"DISK"`
- `8439178`: `"DISK"`
- `8439183`: `"BOOT: disk not formatted\n"`
- `8439209`: `"BOOT: unknown controller. assuming default\n"`
- `8439253`: `"BOOT: Phony scsi address %x\n"`
- `8439282`: `"BOOT: SCSI device %d failed \n"`
- `8439312`: `"BOOT: %s: scdevice not free\n"`

**Name**: `print_boot_strings`  

**Purpose**: This function is not executable code but a data section containing embedded ASCII strings used by the boot loader for debugging, status messages, and error reporting. The strings are referenced elsewhere in the U15 ROM to output diagnostic information during SCSI operations, boot failures, and controller initialization.  

**Parameters**: None (this is a data block, not a function).  

**Returns**: None.  

**Key Operations**:  
- Stores literal ASCII strings with null terminators or newline separators.  
- Contains debug messages like `"Enter s_m_o_int\n"`, `"Enter s_c_o_int\n"`, `"Enter resel\n"`, `"Boot: scsi abort\n"`, `"Enter saveptrs\n"`, `"Enter loadptrs\n"`.  
- Includes error messages such as `"BOOT: disk not formatted\n"`, `"BOOT: unknown controller. assuming default\n"`, `"BOOT: Phony scsi address %x\n"`, `"BOOT: SCSI device %d failed \n"`, `"BOOT: %s: scdevice not free\n"`.  
- Contains repeated occurrences of `"DISK"` (likely used as a label or identifier in data structures).  

**Called Functions**: None.  

**Notes**:  
- The data is interleaved with what appear to be 68010 opcodes (e.g., `moveq`, `oriw`, `moveal`) because the disassembler incorrectly interprets ASCII values as instructions. This is common when disassembling regions that contain mixed code and data.  
- The strings suggest the boot loader has extensive SCSI debugging output, possibly enabled via a diagnostic mode.  
- The `"%x"` and `"%d"` format specifiers indicate the use of a `printf`-like output routine elsewhere in the ROM.  
- The repeated `"DISK"` strings might be part of a table or structure used to identify device types.  
- Addresses 0x80c510–0x80c5dc fall within the U15 ROM range (0x808000–0x80FFFF) and are likely referenced via absolute addressing or PC-relative offsets from the actual boot loader code.

---

### Function at 0x80c5de

**Embedded strings:**
- `8439282`: `"BOOT: SCSI device %d failed \n"`
- `8439312`: `"BOOT: %s: scdevice not free\n"`
- `8439341`: `"Scsi device %d command %x "`
- `8439368`: `"Error Code %x %x %x %x\n"`

**Name**: `scsi_device_fail_error`  

**Purpose**:  
This function prints an error message indicating that a SCSI device has failed during a boot operation. It appears to be part of the boot loader’s SCSI device initialization or command-handling error path, formatting and outputting a diagnostic string that includes the SCSI device number and possibly a command code or status. The function likely prepares and calls a console print routine with a formatted error string stored in the ROM.

**Parameters**:  
- `%d0` or `%a0` may hold the SCSI device number or error code (inferred from string references).  
- The function uses hard-coded string data embedded directly in the code section (starting at `0x80c5de`).

**Returns**:  
- No explicit return value; side effect is output to the console serial port.

**Key Operations**:  
- Embeds the string `"BOOT: SCSI device %d failed \n"` (or similar) in the instruction stream (data after `0x80c5de` is ASCII).  
- Likely calls a `printf`-like output function elsewhere in ROM (not shown in this snippet).  
- May also reference other error strings:  
  - `"BOOT: %s: scdevice not free\n"`  
  - `"Scsi device %d command %x "`  
  - `"Error Code %x %x %x %x\n"`  
- The code snippet itself is mostly data; the first instruction `bgts 0x80c659` suggests it is entered after a comparison/branch from a preceding SCSI status check.

**Called Functions**:  
- None directly in this snippet, but the surrounding code likely calls a print function (e.g., `0x808xxx` for console output).

**Notes**:  
- The function address `0x80c5de` lies within the U15 boot ROM (`0x808000–0x80FFFF`).  
- The ASCII data is interleaved with 68010 instructions (e.g., `moveal`, `subqw`), which are actually part of the string bytes being misinterpreted by the disassembler. This is common in ROMs where data is placed inline.  
- The strings match known boot error messages from the documentation, indicating this is part of SCSI device failure reporting during boot.  
- The function is likely invoked when the SCSI controller fails to respond or returns an error status during device selection or command phase.

---

### Function at 0x80c6b0

**Embedded strings:**
- `8439478`: `"done\n Another Disk ? [y] : "`
- `8439509`: `"TAPE"`
- `8439514`: `"Scsi command %x Error Code 0x%x\n"`
- `8439547`: `"residue bytes %x %x %x\n"`
- `8439571`: `"dumping %d disk blocks to tape from block %d\n"`

**Name**: `print_scsi_error`  

**Purpose**:  
This function prints a formatted error message for SCSI command failures. It likely takes an error code and SCSI command byte from a prior operation and formats them into the string `"Scsi command %x Error Code 0x%x\n"`, then outputs it to the console. The function appears to be part of the boot loader’s SCSI disk/tape handling routines, used when a SCSI command (e.g., read, write, inquiry) fails and an error status needs to be reported to the user.

**Parameters**:  
- Error code and SCSI command byte are presumably passed in registers (likely `%d0` or `%d1`) or stored in fixed memory locations (e.g., `%fp@(11822)` may hold one of the values).  
- The function may also reference a string table or embedded string data within the code itself.

**Returns**:  
- No explicit return value; side effect is output to the serial console.  
- May set condition codes based on internal operations.

**Key Operations**:  
- Loads data from a stack or frame pointer offset (`%fp@(11822)`).  
- Embeds the string `"Scsi command %x Error Code 0x%x\n"` directly in the code (visible from `80c6dc`–`80c6f0`).  
- Likely calls a `printf`-like output routine (not shown in this snippet, but referenced by the surrounding code).  
- May prepare arguments for formatting (error code and command byte) before calling the print routine.

**Called Functions**:  
- Not directly visible in this snippet, but the code likely ends with a `jsr` or `bsr` to a print function (e.g., `printf` at `0x808xxx` or `0x80axxx`).  
- The surrounding code may call `scsi_command` routines and error handlers.

**Notes**:  
- The code block contains ASCII strings mixed with instructions, suggesting data is inlined (common in ROM code).  
- The string `"TAPE"` appears earlier in the ROM (`8439509`), and `"dumping %d disk blocks to tape from block %d\n"` suggests this function is used during tape backup operations.  
- The offset `%fp@(11822)` (0x2E2E) is suspiciously large for a stack frame; it might actually be a pointer to a global error/status table in shared RAM (`0xC00000` area).  
- The function’s address (`0x80c6b0`) places it in the U15 boot ROM, consistent with SCSI error reporting during disk/tape boot or backup commands.

---

### Function at 0x80c6f2

**Embedded strings:**
- `8439547`: `"residue bytes %x %x %x\n"`
- `8439571`: `"dumping %d disk blocks to tape from block %d\n"`
- `8439617`: `"really rewrite disk ? "`
- `8439640`: `"\n%d tape blocks to disk from block %d\n"`
- `8439689`: `"DONE       \n"`

**Name**: `print_boot_error_or_prompt`  

**Purpose**:  
This function appears to be part of the boot loader’s error‑handling or status‑reporting logic, likely triggered when a disk or tape operation fails or when a user‑entered command is invalid. It prints diagnostic messages containing residue byte counts, block numbers, or confirmation prompts, using hard‑coded string fragments that match known boot‑loader strings (e.g., “residue bytes %x %x %x”, “dumping %d disk blocks to tape from block %d”, “really rewrite disk ?”). The function does not perform I/O itself but prepares or passes these strings to a console‑output routine.

**Parameters**:  
- `%a0` likely points to a data structure containing residue/block counts (offset `0x25` indexed by `%d7`).  
- `%d7` may be an index or error code.  
- `%a2` might hold a base address for string storage or output buffering.  
- `%d4` is set to immediate values (10, 32) possibly for formatting (newline, space).

**Returns**:  
No explicit return value; side effect is the preparation of strings for output. Status may be indicated via condition codes (e.g., `bccs`, `bcss` branches earlier in the flow).

**Key Operations**:  
- Loads a longword from memory at `%a0@(0x25,%d7:l)` into `%d0` (likely a residue or block count).  
- Embeds string literals directly in the code: “residue bytes %x %x %x”, “dumping %d disk blocks to tape from block %d”, “really rewrite disk ?”, “%d tape blocks to disk from block %d”, “DONE”.  
- Uses `oriw` instructions to write ASCII words into memory (likely building or modifying strings).  
- Branches conditionally (`bccs`, `bcss`, `bgts`) based on earlier operations.

**Called Functions**:  
None directly in this snippet; the strings are presumably passed to a print function elsewhere (e.g., `printf`‑style routine in the boot loader).

**Notes**:  
- The code is interleaved with data (strings) — typical of ROM‑based firmware where instructions and messages are packed together.  
- The strings match documented boot‑loader messages for SCSI/tape operations and user prompts.  
- Address `0x80c6f2` is within the U15 ROM range (`0x808000‑0x80FFFF`), consistent with boot‑loader error‑reporting routines.  
- The immediate values in `%d4` (10 = `\n`, 32 = space) suggest formatting control for console output.  
- This function likely runs on the DMA processor, as that processor handles boot I/O and SCSI operations.

---

### Function at 0x80c720

**Embedded strings:**
- `8439617`: `"really rewrite disk ? "`
- `8439640`: `"\n%d tape blocks to disk from block %d\n"`
- `8439679`: `"DISK"`
- `8439684`: `"DISK"`
- `8439689`: `"DONE       \n"`
- `8439702`: `" %x      \r"`
- `8439713`: `"BOOT : Bad Interrupt : cmd %x dev %x\n"`
- `8439751`: `"\nI_PERR1 0x%x I_PERR2 0x%x I_MBERR 0x%x\n"`
- `8439792`: `"I_SC_C 0x%x 0x%x  I_SC_P 0x%x 0x%x I_SC_R 0x%x\n"`
- `8439840`: `"I_ERR 0x%x I_MISC 0x%x I_KILL 0x%x I_TRCE 0x%x I_USER 0x%x\n"`
- `8439900`: `"***checksum was %x, expected %x  ***\n"`
- `8439942`: `"No index signal"`
- `8439958`: `"No seek complete"`
- `8439975`: `"Write fault"`
- `8439987`: `"Drive not ready"`
- `8440003`: `"Drive not selected"`
- `8440022`: `"No track 00"`
- `8440034`: `"Multiple Winchester drives selected"`
- `8440070`: `"Media change"`
- `8440083`: `"Seek in progress"`
- `8440100`: `"ID read error (ECC) error in the ID field"`
- `8440142`: `"Uncorrectable data error during a read"`

**Name**: `print_scsi_error_codes`

**Purpose**: This function prints a comprehensive set of SCSI controller error/status codes and diagnostic messages. It appears to be part of a disk/tape copy or verification routine (based on the embedded strings about rewriting disk and tape blocks), and when errors occur, it dumps the OMTI 5200 SCSI controller's internal registers and status bits to help diagnose hardware failures.

**Parameters**: 
- Likely receives error codes or status values in registers (possibly `%d0`-`%d7`) or at known memory locations, though the function prologue is not shown in the provided range. The strings suggest it expects at least a command code (`cmd %x`) and device ID (`dev %x`).

**Returns**: 
- No explicit return value; this is a diagnostic output routine. It prints to the console and likely does not modify caller state beyond side effects.

**Key Operations**:
- Outputs the string `"BOOT : Bad Interrupt : cmd %x dev %x\n"` (at 0x8439713).
- Prints SCSI controller internal registers:
  - `I_PERR1` and `I_PERR2` (parity error registers) at 0x8439751.
  - `I_MBERR` (memory bus error register).
  - `I_SC_C`, `I_SC_P`, `I_SC_R` (SCSI command, phase, and ? registers) at 0x8439792.
  - `I_ERR`, `I_MISC`, `I_KILL`, `I_TRCE`, `I_USER` (error, miscellaneous, kill, trace, user registers) at 0x8439840.
- Outputs a checksum mismatch message: `"***checksum was %x, expected %x  ***\n"` (0x8439900).
- Prints a series of SCSI/disk error strings:
  - `"No index signal"`
  - `"No seek complete"`
  - `"Write fault"`
  - `"Drive not ready"`
  - `"Drive not selected"`
  - `"No track 00"`
  - `"Multiple Winchester drives selected"`
  - `"Media change"`
  - `"Seek in progress"`
  - `"ID read error (ECC) error in the ID field"`
  - `"Uncorrectable data error during a read"`
- Also contains strings related to a disk/tape copy operation: `"really rewrite disk ? "` and `"%d tape blocks to disk from block %d\n"`.

**Called Functions**:
- The provided assembly range (0x80c720–0x80c924) appears to be primarily data (strings), not executable code. Therefore, this "function" might actually be a data table of strings used by a larger error-handling routine. The real printing functions would be elsewhere (e.g., `printf`-like routines at addresses like 0x808xxx).

**Notes**:
- The address range given is mostly string data, not executable instructions. This suggests the function being analyzed is actually a collection of error messages used by a SCSI/disk diagnostic routine.
- The strings indicate detailed low‑level access to the OMTI 5200 controller’s internal registers (I_PERR1, I_SC_C, etc.), which matches the hardware context of a boot ROM that must handle SCSI errors directly.
- The presence of both “tape” and “disk” strings suggests the boot loader supports copying from tape to disk (possibly for system restoration or installation).
- The checksum message hints at a firmware or block verification step.
- The “Bad Interrupt” string implies this routine is invoked when the SCSI controller triggers an unexpected interrupt.

---

### Function at 0x80c92c

**Embedded strings:**
- `8440142`: `"Uncorrectable data error during a read"`
- `8440181`: `"ID address mark not found"`
- `8440207`: `"Data address not found"`
- `8440230`: `"Record not found"`
- `8440247`: `"Seek error"`

**Name**: `print_scsi_error`

**Purpose**: This function prints a human-readable SCSI error message based on an error code. It appears to be part of the boot loader's SCSI disk I/O error handling, translating a numeric SCSI status or sense key into a descriptive string that is displayed to the user (likely on the console serial port). The function selects from a set of predefined error strings stored in the ROM.

**Parameters**:  
- Likely a SCSI error code or status byte passed in a register (common candidates: `%d0`, `%d1`, or `%a0`). The code snippet provided is primarily the string data table, not the lookup/dispatch logic, so the exact input register is inferred from typical SCSI error handling patterns in the boot loader.

**Returns**:  
- No explicit return value; side effect is output of an error string to the console.

**Key Operations**:  
- Contains embedded error message strings:  
  - `"Uncorrectable data error during a read"`  
  - `"ID address mark not found"`  
  - `"Data address not found"`  
  - `"Record not found"`  
  - `"Seek error"`  
- Likely uses the error code as an index to select one of these strings (or similar strings in the full table).  
- Probably calls a console output subroutine (e.g., `putstr`) to print the selected string.  
- Strings are stored in ROM (U15) and are referenced by the error‑handling logic elsewhere in the boot loader.

**Called Functions**:  
- Not directly visible in the provided snippet, but typical calls would be to a string‑printing routine (e.g., `puts` or `print_msg`) around 0x808xxx or 0x80axxx.  
- May be called by SCSI read/write functions after checking the SCSI controller status.

**Notes**:  
- The provided assembly lines are mostly ASCII string data, not executable code—they appear to be the literal error messages stored in the ROM. The actual function logic (error code comparison and string selection) likely resides just before or after this data block.  
- The strings correspond to classic SCSI/disk controller error conditions: seek errors, address marks, uncorrectable data errors, and missing records/sectors.  
- This function is part of the boot loader's robust error reporting, allowing operators to diagnose disk problems during boot.  
- The strings are stored in a contiguous block, suggesting a simple jump‑table or indexed lookup to select the appropriate message.  
- Given the Plexus boot process, these errors would be displayed after a failed disk read when trying to load the kernel or filesystem metadata.

---

### Function at 0x80c97e

**Embedded strings:**
- `8440207`: `"Data address not found"`
- `8440230`: `"Record not found"`
- `8440247`: `"Seek error"`
- `8440258`: `"Write protected"`

**Name**: `scsi_error_message_lookup`  

**Purpose**: This function maps a SCSI error code to a corresponding error message string pointer. It acts as a lookup table or jump table for SCSI error handling, converting a numeric error value into a human‑readable error message that can be displayed by the boot loader’s SCSI driver.  

**Parameters**:  
- Input: Likely a SCSI status/error code in a register (e.g., `%d0` or `%a0`) before the function is called. The exact register is not visible in this snippet, but the table entries suggest it expects an index.  

**Returns**:  
- Output: Probably a pointer to an error message string in `%a0` or `%d0`, depending on the calling convention.  

**Key Operations**:  
- Contains embedded ASCII strings: “ samrk”, “ not”, “ fou”, “nd”, and “Data at” — these appear to be fragments of the error messages referenced elsewhere in the ROM.  
- The data is not executable code but a table of string pointers or string data directly embedded in the code section.  
- The addresses `0x8440207`, `0x8440230`, `0x8440247`, and `0x8440258` (from the provided string list) likely point to the full error messages, while this block contains partial strings used to construct them or serves as a literal pool.  

**Called Functions**:  
- None directly in this snippet; it is likely accessed via a `movea.l` or `lea` instruction from error‑handling code elsewhere.  

**Notes**:  
- The disassembly is misleading because the data is being interpreted as instructions. This range (`0x80c97e–0x80c98e`) is actually a data table, not executable code.  
- The strings “Data address not found”, “Record not found”, “Seek error”, and “Write protected” are known SCSI/disk error messages in the Plexus boot loader. This table probably maps SCSI sense keys or status bytes to those messages.  
- The mix of `.short 0x7320` (`'s '` in ASCII) and ASCII sequences like `" not"` suggests the table may contain packed or partial strings to save space.  
- Located in the U15 boot ROM, this function supports SCSI disk operations during boot, providing user‑friendly error reporting when disk reads fail.

---

### Function at 0x80c9b4

**Embedded strings:**
- `8440247`: `"Seek error"`
- `8440258`: `"Write protected"`
- `8440274`: `"Correctable data field error"`
- `8440303`: `"Bad block found"`
- `8440319`: `"Format error"`
- `8440332`: `"Unable to read alternate track address"`

**Name**: `scsi_error_message_lookup`  

**Purpose**: This function maps a SCSI error code (likely from a controller status register) to a corresponding error message string pointer. It appears to be part of the boot loader’s SCSI disk I/O error‑handling logic, translating numeric error values into human‑readable strings for display when a SCSI command (e.g., seek, read, write) fails.  

**Parameters**:  
- Input error code is expected in a data register (likely `%d0` or `%d1`), or possibly in a low‑order byte of a status word read from the SCSI controller.  

**Returns**:  
- Returns a pointer to a null‑terminated error message string, probably in an address register (e.g., `%a0`).  

**Key Operations**:  
- Contains embedded ASCII strings interleaved with opcodes, suggesting a jump table or in‑line string table.  
- Strings visible in the snippet: `"Seek error"`, `"Write protected"`, `"Correctable data field error"`, `"Bad block found"`, `"Format error"`, `"Unable to read alternate track address"`.  
- Uses conditional branch instructions (`bgts`, `bmis`, `bcss`, `bles`, `bccw`) as part of the jump‑table dispatch—each branch likely skips over a string to the next case.  
- No explicit hardware register accesses in this snippet; the function purely performs string lookup based on an error code.  

**Called Functions**:  
- None within this snippet; it is likely called by SCSI command routines after checking status.  

**Notes**:  
- The code is located in the U15 boot ROM (0x808000–0x80FFFF), consistent with SCSI boot error messaging.  
- The interleaving of branch instructions and ASCII data is a classic 68000‑series technique for compact jump tables with inline strings.  
- The strings match known SCSI/disk errors: seek failure, write protection, correctable data error (ECC), bad block, format error, and alternate track read failure (related to defect management).  
- This function would be invoked after a SCSI operation fails, to print the appropriate error message before returning to the boot prompt.

---

### Function at 0x80c9d8

**Embedded strings:**
- `8440303`: `"Bad block found"`
- `8440319`: `"Format error"`
- `8440332`: `"Unable to read alternate track address"`

**Name**: `scsi_check_error` or `scsi_handle_disk_error`

**Purpose**: This function appears to be part of the SCSI disk error handling logic in the boot loader. It checks the SCSI controller status after a disk operation (likely a read or write) and branches to different error handling routines based on the specific error condition. The function likely interprets a status code in a register (possibly `%d0` or `%d1`) and dispatches to appropriate error message printing routines for "Bad block found", "Format error", or "Unable to read alternate track address" errors.

**Parameters**: Likely a status/error code in a data register (not visible in this snippet, but probably `%d0` or `%d1` from a preceding SCSI operation). The function itself only shows the branch destinations and immediate value loading.

**Returns**: No explicit return value; this is a branching/dispatch function. Control flows to one of several error handlers, which likely print messages and may return to a caller or enter a failure state.

**Key Operations**:
- Loads the immediate value `0x61` (decimal 97) into `%d2` – this could be a SCSI status code mask, a retry counter, or an error type identifier.
- Branches if higher (unsigned) to address `0x80ca48` (likely a "Bad block found" handler).
- Branches if carry set (lower or same) to address `0x80c9fe` (likely a "Format error" or "Unable to read alternate track address" handler, depending on earlier tests).

**Called Functions**: None directly in this snippet, but the branch targets (`0x80ca48`, `0x80c9fe`) likely lead to error message printing routines that output the referenced strings at addresses `0x8440303`, `0x8440319`, and `0x8440332`.

**Notes**:
- The function is only 3 instructions (4 bytes) long, indicating it's a compact error status dispatcher.
- The immediate value `0x61` in `%d2` may correspond to a specific SCSI sense key or status byte from the OMTI 5200 controller.
- The branch conditions (`bhis` and `bcss`) suggest unsigned comparison against a threshold (97) to distinguish between "severe" errors (bad block) and "recoverable" errors (format/track issues).
- This is likely part of the low-level disk I/O routines used by the boot loader to read the filesystem (inodes, blocks) from SCSI disk during boot.
- The addresses `0x80ca48` and `0x80c9fe` are within the U15 ROM range and probably contain error-specific handling (e.g., printing strings, retrying, or aborting).

---

### Function at 0x80c9de

**Embedded strings:**
- `8440303`: `"Bad block found"`
- `8440319`: `"Format error"`
- `8440332`: `"Unable to read alternate track address"`
- `8440371`: `"Attempted to directly access an alternate track"`
- `8440419`: `"Sequence time out during disk to host transfer"`

**Name**: `print_bad_block_error`  

**Purpose**:  
This function prints the error message "Bad block found" to the console. It is part of the boot loader’s error‑handling logic, likely triggered when the SCSI disk controller reports a defective or unreadable block during boot or disk I/O operations. The function appears to be a subroutine that formats and outputs the string, possibly as part of a larger error‑reporting routine that selects from several predefined error messages.

**Parameters**:  
- The function expects the address of the string "Bad block found" to be passed or already stored in memory (likely via a preceding setup routine).  
- No explicit register parameters are visible in the snippet, but the code suggests `%a0` or `%a2` may point to string data or a buffer.

**Returns**:  
- No explicit return value; the function outputs text to the console (likely via a serial port).  
- Registers may be altered (e.g., `%a0`, `%d1`, `%d2`).

**Key Operations**:  
- Moves immediate values into data registers (`%d1`, `%d2`) and address registers (`%a0`, `%a2`) — these likely contain ASCII characters or string pointers.  
- Uses branch instructions (`bccs`, `bvss`, `bges`, `bles`, `blss`) that appear to be part of the string data itself, not executable code — indicating this is likely a data table of error strings, not executable instructions.  
- The string "Bad block found" is stored at address `0x80c9de` (visible in the hex/ASCII dump).  
- The function is referenced by other code that calls it to print this specific error.

**Called Functions**:  
None directly in this snippet, but the surrounding code likely calls a common print routine (e.g., `uart_puts` or `console_print`) to output the string.

**Notes**:  
- The disassembly is misleading: the bytes from `0x80c9de` to `0x80c9f8` are not executable instructions but ASCII text for the error message "Bad block found" (hex: `64 61 74 61 20 66 69 65 6c 64 20 65 72 72 6f 72 00 42 61 64 20 62 6c 6f 63 6b 20 66`).  
- The preceding bytes (`0x80c9de–0x80c9ed`) spell "data field error" (null‑terminated), followed by "Bad block found" starting at `0x80c9ee`. This suggests a table of error strings used by the boot loader’s SCSI/disk error handler.  
- The function label likely points to the start of this string table, not a subroutine. The real error‑printing function would load the appropriate string address from this table and pass it to a print routine.  
- Hardware interaction (serial output) would occur in the print routine, not here.

---

### Function at 0x80c9fa

**Embedded strings:**
- `8440319`: `"Format error"`
- `8440332`: `"Unable to read alternate track address"`
- `8440371`: `"Attempted to directly access an alternate track"`
- `8440419`: `"Sequence time out during disk to host transfer"`
- `8440466`: `"Invalid command from host"`
- `8440492`: `"Illegal disk address ( beyond maximum )"`

**Name**: `scsi_error_handler`  

**Purpose**:  
This function handles SCSI command execution errors by mapping a SCSI status/error code to a specific error message string and printing it. It appears to be part of the boot loader’s SCSI disk I/O routines, invoked when a SCSI operation fails. The function likely receives a SCSI error code, looks up a corresponding human‑readable error message from a table of strings (which are embedded directly in the code), and prints it to the console to inform the user (or log) what went wrong.

**Parameters**:  
- Input error code likely in a register (e.g., `%d0` or `%d1`) or at a known memory location (e.g., a SCSI status register or a temporary error variable).  
- The function references several fixed error strings stored in the ROM starting at `0x80c9fa`.

**Returns**:  
- Probably does not return a value; may set a global error flag or halt further boot processing.  
- May return to a higher‑level error‑handling routine after printing the message.

**Key Operations**:  
- Contains embedded ASCII strings for SCSI‑related error messages:  
  - `"Format error"`  
  - `"Unable to read alternate track address"`  
  - `"Attempted to directly access an alternate track"`  
  - `"Sequence time out during disk to host transfer"`  
  - `"Invalid command from host"`  
  - `"Illegal disk address ( beyond maximum )"`  
- Likely uses the error code as an index to select one of these strings.  
- Calls a print/display routine (not shown in the snippet) to output the selected string.  
- May also log or set hardware status registers (e.g., SCSI error flags at `0xE00040` or `0xE001A0`).

**Called Functions**:  
- Not directly visible in the provided assembly, but expects a print function (e.g., `puts`‑like routine) to be called elsewhere in the function body (outside the shown range).  
- May call a common error‑reporting routine that also handles LED status updates (LED register at `0xE00010`).

**Notes**:  
- The code snippet is mostly data (error strings) interspersed with stray op‑codes (e.g., `bles`, `bgts`, `oriw`) because the disassembler is interpreting ASCII as instructions. This is typical of ROMs that embed string tables directly in the code section.  
- The strings suggest detailed SCSI error reporting, including format errors, alternate track handling, time‑outs, invalid commands, and out‑of‑range disk addresses—consistent with low‑level disk boot code.  
- The function’s address (`0x80c9fa`) is within the U15 boot ROM range (`0x808000‑0x80FFFF`), confirming it is part of the boot loader’s SCSI driver.  
- Given the Plexus P/20’s dual‑processor design, this error handler runs on the DMA processor, which manages SCSI operations.

---

### Function at 0x80ca7e

**Embedded strings:**
- `8440466`: `"Invalid command from host"`
- `8440492`: `"Illegal disk address ( beyond maximum )"`
- `8440532`: `"Illegal Function for type of drive specified"`
- `8440577`: `"Volume overflow"`

**Name**: `print_error_message`  

**Purpose**: This function prints one of several error messages stored in the ROM, likely used by the boot loader to report SCSI or command‑parsing failures. The code does not contain the actual printing logic here; instead, it appears to be a table of error strings referenced by other parts of the boot loader. The given address range (0x80ca7e–0x80cabe) contains ASCII data, not executable instructions, and corresponds to the string “Invalid command from host” and the beginning of “Illegal disk address ( beyond maximum )”.  

**Parameters**: None (this is data, not a function).  

**Returns**: None.  

**Key Operations**:  
- Stores error messages as null‑terminated ASCII strings in ROM.  
- Strings are referenced by other boot‑loader routines when an error condition is detected (e.g., invalid SCSI command, out‑of‑range disk address).  

**Called Functions**: None (data section).  

**Notes**:  
- The disassembly listing incorrectly interprets ASCII data as Motorola 68010 opcodes. The bytes starting at 0x80ca7e spell:  
  `"Invalid command from host\0Illegal disk address ( beyond maximum )\0..."`  
- This matches the referenced strings documented earlier (8440466, 8440492, etc.).  
- The actual error‑printing routine likely loads the address of one of these strings into a register and calls a ROM output function (e.g., `puts` to serial console).  
- The presence of SCSI‑related error messages suggests this is part of the boot loader’s disk‑access error‑handling.

---

### Function at 0x80cac0

**Embedded strings:**
- `8440532`: `"Illegal Function for type of drive specified"`
- `8440577`: `"Volume overflow"`
- `8440593`: `"Ram Error"`
- `8440603`: `"Unit attention, please retry"`
- `8440632`: `"Media not loaded"`
- `8440649`: `"Write protected"`

**Name**: `print_scsi_error_message`

**Purpose**: This function prints a SCSI error message based on an error code. It appears to be part of the boot loader's SCSI disk I/O error handling, mapping a SCSI status or sense key to a human-readable error string and outputting it to the console (likely serial port A). The function contains embedded ASCII strings for various error conditions, such as "Illegal Function for type of drive specified", "Volume overflow", "Ram Error", etc.

**Parameters**: The function likely expects an error code in a register (probably `%d0` or `%a0` based on the first instruction) or at a fixed memory location. The first instruction `movel %a0@(8290),%d0` suggests it loads a 32-bit value from an offset in an address register (`%a0`) into `%d0`, which is then used to select the error message.

**Returns**: No explicit return value; it outputs a string to the console and likely returns to the caller (via `rts`) after printing.

**Key Operations**:
- Loads an error code from memory at offset `0x2062` (8290 decimal) from an address in `%a0`.
- Uses the error code to select one of several error strings embedded directly in the code.
- Outputs the selected string to the console (via a serial port output routine, though the actual output call is not in this snippet).
- The code snippet itself contains ASCII data for error messages interleaved with instructions, suggesting the function may use the error code as an index to compute a pointer into this embedded string table.

**Called Functions**: None directly visible in this snippet, but it likely calls a string output function (e.g., `puts` or `uart_puts`) to print the selected error message. The actual call would be after the string pointer is set up.

**Notes**:
- The code from `0x80cac0` to `0x80cb0c` is not pure executable instructions; it contains ASCII strings interspersed with opcodes. This suggests the function uses a jump table or computed branch into the middle of this block to select a string.
- The strings visible include: "Illegal Function for type of drive specified", "Volume overflow", "Ram Error", "Unit attention, please retry", "Media not loaded", "Write protected".
- The first instruction `movel %a0@(8290),%d0` loads a longword from an offset that corresponds to `0x2062` in hex. This offset may point to a SCSI status or sense key field in a hardware register or data structure.
- The function likely resides in the U15 boot ROM and is called when a SCSI command fails during boot disk operations.
- The mixing of code and data is typical for compact ROM-based error handlers where the strings are placed inline to save space and avoid separate data sections.

---

### Function at 0x80cb0e

**Embedded strings:**
- `8440593`: `"Ram Error"`
- `8440603`: `"Unit attention, please retry"`
- `8440632`: `"Media not loaded"`
- `8440649`: `"Write protected"`
- `8440665`: `"Uncorrectable data error"`
- `8440690`: `"Bad block found"`
- `8440706`: `"Drive not ready"`
- `8440722`: `"Insufficient capacity"`

**Name**: `scsi_error_to_string`  

**Purpose**: This function maps a SCSI error code (likely passed in a register) to a corresponding error message string pointer. It appears to be a lookup table or jump table that returns a pointer to a human-readable error string based on an error index or status value. The strings listed are typical SCSI/disk-related errors (e.g., "Ram Error", "Unit attention", "Media not loaded", "Write protected", etc.).  

**Parameters**: Likely an error code in a data register (e.g., `%d0` or `%d1`) or possibly an offset passed in an address register. The function uses the parameter to index into the table of string pointers or to compute a branch offset.  

**Returns**: A pointer to the selected error message string, probably in an address register (e.g., `%a0`).  

**Key Operations**:  
- Contains embedded ASCII strings (e.g., "Ram Error", "Unit attention, please retry", etc.) interleaved with opcodes.  
- Likely uses a branch table or indexed jump to select one of these strings based on the input error code.  
- No direct hardware register accesses visible in the provided snippet—this is purely a string lookup routine.  
- The opcodes mixed with ASCII data suggest the function may be part of a larger switch/case construct where the error code determines which string address is returned.  

**Called Functions**: None directly visible in this snippet, but the function itself may be called by SCSI command handlers or disk I/O routines when an error occurs.  

**Notes**:  
- The provided assembly lines are mostly ASCII data (strings) with occasional opcodes (e.g., `moveal`, `bsrs`, `bccs`), indicating that the code and data are interleaved. This is typical for a compact error-handling routine where the strings are placed inline and accessed via computed offsets.  
- The strings match known SCSI sense key/ASC/ASCQ error conditions (e.g., "Write protected", "Uncorrectable data error", "Drive not ready").  
- The function likely resides in the boot loader ROM (U15) and is used to report disk errors during boot or disk operations.  
- The address range (0x80cb0e–0x80cb5c) is within the U15 ROM region (0x808000–0x80FFFF).  
- The first word `0x6f77` could be part of a branch table offset or an opcode fragment (`bles`), suggesting the function starts with a comparison/branch sequence before the string data.

---

### Function at 0x80cb5e

**Embedded strings:**
- `8440690`: `"Bad block found"`
- `8440706`: `"Drive not ready"`
- `8440722`: `"Insufficient capacity"`
- `8440744`: `"Drive timeout"`
- `8440758`: `"Block not found"`
- `8440774`: `"Dma timeout error"`

**Name**: `print_scsi_error_message`

**Purpose**: This function prints a SCSI error message string based on an error code. It appears to be part of the boot loader's SCSI disk I/O error handling routine, mapping numeric error codes to human-readable error messages for display to the user. The function likely takes an error code as input and returns a pointer to the corresponding error string.

**Parameters**: 
- Likely an error code passed in a register (common patterns would be `%d0` or `%d1`), though the provided snippet doesn't show the parameter loading. The function body consists of string data, suggesting it's a lookup table or message array.

**Returns**:
- Likely returns a pointer to the selected error string in an address register (e.g., `%a0`), or possibly prints it directly via a `puts`-like function.

**Key Operations**:
- Contains embedded ASCII string data for SCSI-related error messages:
  - "Bad block found" (offset 0x00 in the snippet)
  - "Drive not ready" (offset 0x12)
  - "Insufficient capacity" (offset 0x24)
  - "Drive timeout" (offset 0x3A)
  - "Block not found" (offset 0x48)
  - "Dma timeout error" (offset 0x5A)
- The code shown is actually the string data itself, not executable instructions (the disassembler incorrectly interprets ASCII as opcodes). This is a common pattern in ROMs where error message tables are placed directly in the code segment.
- The function likely uses the error code as an index into this table of string pointers (or a calculated offset into the contiguous string data).

**Called Functions**:
- None directly visible in the provided snippet, but would be called by SCSI read/write routines after checking error status.

**Notes**:
- The addresses shown (0x80cb5e-0x80cb8a) contain string data, not executable code. The actual function that uses this table likely precedes or follows this data block.
- The strings match common SCSI controller error conditions (OMTI 5200 specific).
- This is part of the boot loader's user interface, providing diagnostic feedback when disk operations fail during boot.
- The contiguous nature of the strings suggests they may be accessed via a jump table where the error code is multiplied by 2 or 4 to get an offset into this data block.
- The presence of "Dma timeout error" specifically references the DMA processor's role in SCSI operations on the P/20 architecture.

---

### Function at 0x80cb8c

**Embedded strings:**
- `8440722`: `"Insufficient capacity"`
- `8440744`: `"Drive timeout"`
- `8440758`: `"Block not found"`
- `8440774`: `"Dma timeout error"`

**Name**: `scsi_error_message_lookup`  

**Purpose**: This function maps a SCSI error code (passed in a register) to a corresponding error message string pointer. It appears to be part of the SCSI disk I/O error‑handling logic in the boot loader, translating a numeric error into a human‑readable message for display. The function likely indexes into a table of error strings based on the error code, returning a pointer to the appropriate message.  

**Parameters**:  
- Likely an error code in a data register (e.g., `%d0` or `%d1`), though the snippet itself only contains data, not parameter‑handling instructions. The surrounding context would determine which register holds the error code.  

**Returns**:  
- Probably returns a pointer to an error message string in an address register (e.g., `%a0`).  

**Key Operations**:  
- The code at `0x80cb8c–0x80cb94` is not executable instructions but ASCII data embedded in the ROM.  
- The bytes spell out (in ASCII):  
  - `0x72 0x65` = "re"  
  - `0x61 0x64` = "ad"  
  - `0x79 0x00` = "y\0"  
  - `0x49 0x6e` = "In"  
  - `0x73 0x75` = "su"  
  This is the beginning of the string **"ready?Insu"**, which is the start of the error message **"Insufficient capacity"** stored at address `0x8440722`.  
- The function likely uses the error code as an index to look up the address of one of the known SCSI error strings:  
  - `0x8440722`: "Insufficient capacity"  
  - `0x8440744`: "Drive timeout"  
  - `0x8440758`: "Block not found"  
  - `0x8440774`: "Dma timeout error"  

**Called Functions**:  
- The `bsrs 0x80cbf4` at `0x80cb8e` is actually part of the ASCII data ("ad") misinterpreted as an instruction; the real subroutine calls would be elsewhere in the actual function code preceding or following this data block.  

**Notes**:  
- The given address range (`0x80cb8c–0x80cb94`) falls inside the U15 ROM boot loader region and contains embedded string data, not executable code. This suggests the function that uses this data is located just before or after this range.  
- The strings referenced are all SCSI‑related error messages, indicating this function is part of the disk‑I/O error‑reporting module.  
- In a typical boot loader, such a function would be called after a SCSI command fails, converting a status byte into a printable message for the console.  
- The presence of the string fragment "ready?" suggests there may also be a "ready" status message or prompt used during boot.

---

### Function at 0x80cb96

**Embedded strings:**
- `8440744`: `"Drive timeout"`
- `8440758`: `"Block not found"`
- `8440774`: `"Dma timeout error"`
- `8440792`: `"Correctable data check"`

**Name**: `scsi_error_handler`  

**Purpose**:  
This function handles SCSI command completion status by checking the SCSI controller's result byte for error conditions. Based on the status value, it branches to specific error‑handling routines that print relevant error messages (e.g., “Drive timeout”, “Block not found”, “DMA timeout error”, “Correctable data check”) and likely aborts or retries the operation.  

**Parameters**:  
- The SCSI status/result byte is expected in a processor status register or a memory location (likely set by earlier SCSI controller interaction).  
- The condition codes (particularly the Z and V flags) are used to determine the error type.  

**Returns**:  
- No explicit return value; control is transferred to error‑message printing and cleanup routines.  

**Key Operations**:  
- Tests the SCSI status byte via conditional branches (`bnes`, `bvss`, `bgts`).  
- Each branch target corresponds to a specific SCSI error condition.  
- The branch offsets point to error‑handling code that prints strings stored in the ROM (e.g., at 0x8440744, 0x8440758, etc.).  
- Uses `moveal %a3@-,%a0` and `bsrs` to set up and call error‑reporting subroutines.  

**Called Functions**:  
- Subroutines via `bsrs` at 0x80cc12 and 0x80cc07 (likely error‑message printers or recovery routines).  
- Indirect calls via the branch targets (0x80cbfe, 0x80cbfd, 0x80cc01, 0x80cc12) that lead to error‑specific handlers.  

**Notes**:  
- The code is dense because the branch instructions double as data (the opcodes spell ASCII strings when viewed as bytes). This is a common trick in ROMs to save space by embedding short, unused byte sequences as valid branch instructions.  
- The strings referenced (“Drive timeout”, etc.) match known SCSI error conditions for the OMTI 5200 controller.  
- The function appears to be part of the low‑level SCSI driver in the boot loader, called after a SCSI command completes to verify success or handle failures.

---

### Function at 0x80cbde

**Embedded strings:**
- `8440815`: `"File mark detected"`
- `8440834`: `"Compare Error"`
- `8440848`: `"Invalid command"`
- `8440864`: `"Command timeout"`

**Name**: `scsi_check_error`  

**Purpose**:  
This function appears to be part of the SCSI error‑handling logic in the boot loader. It likely interprets a SCSI status byte (or error code) and branches to appropriate error‑message printing routines based on the condition. The instructions are actually a mix of branch‑on‑condition opcodes and data values that, when disassembled incorrectly, resemble ASCII text (“table data”). This suggests the code is placed immediately after a table of error‑message pointers or error codes, and the branches target different error‑handling stubs.  

**Parameters**:  
- `%d2` (or another condition‑code register) may hold a SCSI status/error code from a previous operation.  
- The program counter is at the end of a table; the “instructions” are likely mis‑disassembled table entries.  

**Returns**:  
No explicit return value; control flows to an error‑handling routine or returns to caller after handling.  

**Key Operations**:  
- Uses conditional branch instructions (`bhi`, `bcs`, `bcc`) to test error conditions.  
- The branch targets (e.g., `0x80cc4e`, `0x80cc04`, `0x80cc47`) likely point to code that prints one of the nearby error strings: “File mark detected”, “Compare Error”, “Invalid command”, or “Command timeout”.  
- The `moveq` and `moveal` instructions are actually data (table entries) but are disassembled as code.  

**Called Functions**:  
None directly in this snippet, but each branch target likely calls a string‑print routine (e.g., `print_message`).  

**Notes**:  
- The address range `0x80cbde–0x80cbe8` sits between SCSI command logic and error‑message strings. The “instructions” are almost certainly not executed as shown; they are literal data (branch offsets or message pointers) belonging to a preceding jump table.  
- This pattern is common in ROM code where a table of error handlers is placed right after a function, and disassemblers incorrectly interpret the table as code.  
- The strings referenced are all SCSI‑related error messages, confirming this is SCSI error dispatch logic.  
- The actual function logic (status checking and branching) ends just before `0x80cbde`; this snippet is the start of the branch table itself.

---

### Function at 0x80cbea

**Embedded strings:**
- `8440815`: `"File mark detected"`
- `8440834`: `"Compare Error"`
- `8440848`: `"Invalid command"`
- `8440864`: `"Command timeout"`
- `8440880`: `"Append Error"`

**Name**: `scsi_error_message_lookup`  

**Purpose**:  
This function maps a SCSI error code (likely passed in a register or memory location) to a corresponding error message string pointer. The code snippet shows the start of a jump table or data table where each entry is a branch instruction to an error-handling routine, followed by the associated error message string. The specific instructions here correspond to the "File mark detected" error case.

**Parameters**:  
- Likely an error code in a register (e.g., `%d0` or `%d1`) or a memory location set by a prior SCSI operation.

**Returns**:  
- Probably returns a pointer to the error message string in a register (e.g., `%a0`), or branches directly to an error-printing routine.

**Key Operations**:  
- Contains a branch-on-overflow-set (`bvcs`) to address `0x80cc51` (likely an error-handling routine).  
- Contains a branch-on-less-than (`blss`) to address `0x80cc59` (another error-handling routine).  
- Embeds the string `"File mark detected"` (ASCII "File mark detected") directly in the code/data table starting at offset `0x80cbf0`.  
- The `oriw #26988,%d6` instruction is actually part of the string data (ASCII "Fil") misinterpreted as an opcode.

**Called Functions**:  
- None directly in this snippet, but the branch targets `0x80cc51` and `0x80cc59` are likely error-handling routines that may call a string-printing function.

**Notes**:  
- This is not a conventional function but a data table embedded in the code section, using branch instructions as table entries. Each table entry likely consists of a branch instruction (for error-specific handling) followed by the associated error string.  
- The string `"File mark detected"` is a known SCSI error message, indicating the SCSI controller encountered a file mark during a read operation.  
- The addresses `0x80cc51` and `0x80cc59` are likely error-handling routines for other SCSI errors (e.g., "Compare Error", "Invalid command", etc.), given the surrounding strings in the ROM.  
- This table is likely accessed via an index derived from a SCSI status byte, where each error code maps to a table entry offset.

---

### Function at 0x80cbf4

**Embedded strings:**
- `8440834`: `"Compare Error"`
- `8440848`: `"Invalid command"`
- `8440864`: `"Command timeout"`
- `8440880`: `"Append Error"`
- `8440893`: `"Read end of media"`

**Name**: `scsi_handle_error`  

**Purpose**:  
This function appears to be part of the SCSI error‑handling logic in the boot loader. It likely maps a SCSI status or error code to a specific error message string, then prints or logs that message before taking appropriate recovery action (e.g., retry, abort, or halt). The presence of ASCII data embedded in the code suggests it may be part of a jump table or in‑line string table used for error‑message lookup.

**Parameters**:  
- Input error code or condition flag likely in a register (possibly `%d0` or `%d1`) before the function is called.  
- `%a4` may point to a table of error messages or function pointers.  

**Returns**:  
- Probably does not return a value in the conventional sense; may instead branch to an error‑reporting routine or reset state.  
- Could set a status flag in memory or a register indicating the error type.

**Key Operations**:  
- Branches based on condition codes (`blts`, `bcss`, `bccw`) — these likely test SCSI status bits or comparison results.  
- Moves data from memory pointed to by `%a4` into `%a0` (possibly loading an error‑message address).  
- Embedded ASCII strings visible in the hex dump: “Compare Error”, “Invalid command”, “Command timeout”, “Append Error”, “Read end of media” — these are typical SCSI/disk‑operation error messages.  
- May access SCSI controller hardware registers (OMTI 5200) to clear error flags or reset the bus.

**Called Functions**:  
No explicit `jsr` or `bsr` in this snippet, but the branches (e.g., `0x80cc57`, `0x80cc70`, `0x80cc61`, `0x810f71`, `0x80cc76`, `0x80cc7a`) likely lead to:  
- Error‑message printing routines (e.g., `print_string`).  
- SCSI reset or retry routines.  
- Boot‑loader command prompt restart.

**Notes**:  
- The code from `0x80cbf4` to `0x80cc06` mixes instructions and ASCII data, suggesting it is either a jump table with in‑line error strings or a series of conditional branches that each point to a different error‑handling block.  
- The strings match known SCSI error conditions: “Compare Error” (verify failure), “Command timeout” (SCSI bus hang), “Read end of media” (attempt to read past last sector).  
- Given the Plexus boot process, this function is likely invoked after a SCSI read/write command fails, and it determines which error message to display on the console before returning to the “:” prompt or retrying.  
- The use of `%a4` as a pointer that is decremented (`%a4@-`) suggests it may be walking through a stack or table of saved error info.

---

### Function at 0x80cc12

**Embedded strings:**
- `8440864`: `"Command timeout"`
- `8440880`: `"Append Error"`
- `8440893`: `"Read end of media"`
- `8440911`: `"SCSI ERROR: %s\n"`

**Name**: `scsi_error_handler`  

**Purpose**:  
This function maps SCSI error codes to human-readable error messages and prints them via a formatted output routine. It acts as a lookup table and dispatcher for SCSI-related error conditions, converting a numeric error code (likely passed in a register or memory location) into a corresponding string description, then prints it with a prefix like "SCSI ERROR: %s".  

**Parameters**:  
- Likely an error code in a register (e.g., `%d0` or `%d3`) or at a known memory location, used to index into the embedded string table.  

**Returns**:  
- No explicit return value; side effect is printing an error message to the console.  

**Key Operations**:  
- Contains embedded ASCII strings:  
  - `"Valid command"` (offset 0)  
  - `"Command timeout"` (offset 0x10)  
  - `"Append Error"` (offset 0x20)  
  - `"Read end of media"` (offset 0x2d)  
  - `"SCSI ERROR: %s\n"` (format string at 0x4e)  
- Likely uses the format string to print the error message via a `printf`-like routine.  
- The data after 0x80cc62 may be constants or offsets for error code mapping.  

**Called Functions**:  
- Presumably calls a formatted print function (e.g., `printf` or similar) at address 0x80cc6c or nearby, using the format string at 0x80cc4e.  

**Notes**:  
- The function appears to be a static data table (error strings) followed by a small code stub to handle error reporting.  
- The strings match known SCSI error conditions: command timeout, media errors, and "Append Error" (possibly a write‑append failure).  
- The `"Valid command"` string suggests the first entry is for "no error" (code 0).  
- The constants at the end (0x0108, 0x0000, 0x2654, etc.) may be error code offsets or related to SCSI command status.  
- This is likely part of the boot loader's SCSI disk‑access error handling, invoked when a SCSI operation fails.

---

### Function at 0x80f414

**Embedded strings:**
- `8451095`: `"Enter s_c_o_int\n"`
- `8451112`: `"Enter resel\n"`
- `8451125`: `"Enter saveptrs\n"`
- `8451141`: `"Enter loadptrs\n"`
- `8451272`: `",JRemote Kernal : "`
- `8451291`: `"scsi selection timeout. device"`
- `8451322`: `"scsi failed interrupt. device"`
- `8451352`: `"scsi command to active device"`
- `8451382`: `"selection interrupt from unknown device"`
- `8451422`: `"bad scsi pointer number"`
- `8451446`: `"bad controller number"`
- `8451468`: `"scsi register = 0x%x\n"`
- `8451490`: `"Error in scsi transfer type"`
- `8451518`: `"same pointer interrupt number"`

**Name**: `scsi_interrupt_handler` or `scsi_sel_resel_handler`

**Purpose**: This function appears to be the main SCSI interrupt service routine for the DMA processor's boot loader. It handles SCSI bus phase changes, particularly selection and reselection phases, manages SCSI pointer tables, processes SCSI command blocks, and reports various SCSI error conditions through debug strings. The function coordinates with the Omti 5200 SCSI controller to manage data transfers between the Plexus system and SCSI devices.

**Parameters**: 
- Interrupt context (implicit, entered via interrupt)
- SCSI controller hardware registers at specific addresses (likely memory-mapped)
- Pointer tables in RAM (possibly at 0xC00000+ shared area)
- Current SCSI phase/status from controller

**Returns**: 
- Returns via `rte` (return from exception) to restore interrupted context
- Modifies SCSI controller state and pointer tables
- May set error flags or print diagnostic messages

**Key Operations**:
- References debug strings: "Enter s_c_o_int", "Enter resel", "Enter saveptrs", "Enter loadptrs", and various SCSI error messages
- Contains embedded data tables (likely SCSI command/status pointer arrays or phase lookup tables)
- Accesses hardware registers in the 0xE00000-0xE001FF range (system control/status)
- Handles SCSI selection timeout ("scsi selection timeout. device")
- Handles failed interrupts ("scsi failed interrupt. device")
- Validates SCSI pointer numbers ("bad scsi pointer number")
- Validates controller numbers ("bad controller number")
- Reports SCSI register values for debugging ("scsi register = 0x%x")
- Manages SCSI transfer types ("Error in scsi transfer type")
- Detects pointer conflicts ("same pointer interrupt number")
- Contains what appears to be SCSI message byte patterns (0x00, 0x21, 0xA0-A3 values)
- Includes phase name strings: "Remote Kernal : " (likely "Remote Kernel" typo)

**Called Functions**:
Based on the code pattern and strings, likely calls (via `jsr` or `bsr` not shown in this snippet):
- String output routines (for debug messages)
- SCSI command submission functions
- Pointer table management functions
- Error handling routines

**Notes**:
1. The function contains significant embedded string data mixed with code, suggesting it's either a data section within the function or the disassembly has misinterpreted data as code.
2. The strings indicate extensive debugging/tracing was built into the boot loader SCSI driver.
3. The function handles both initiator and target roles (selection and reselection phases).
4. The embedded tables at 0x80F454-0x80F4C6 appear to be:
   - Pointer arrays (each entry 4 bytes: 0x00C00000, 0x00C0001A, etc.)
   - SCSI phase/status mapping tables
   - Byte patterns for SCSI messages and commands
5. The function is part of the low-level SCSI driver that enables the boot loader to read from SCSI disks (hard drives and floppy).
6. The "Remote Kernal" string suggests support for remote kernel loading over SCSI.
7. The error messages indicate robust error handling for SCSI bus protocol violations.
8. The function likely interfaces directly with the Omti 5200 controller's registers to read/write SCSI bus signals and manage DMA transfers.

---

# Appendix: Embedded Strings

## U17 Strings

| Address | String |
|---------|--------|
| 0x800400 | ` RD-32 06/04/85` |
| 0x800422 | `g8`\n` |
| 0x80042e | `g,Hx` |
| 0x800478 | `NsHx` |
| 0x800482 | `NuHx` |
| 0x8004fc | `fJ"<` |
| 0x80050e | `f8"<` |
| 0x800545 | `XNs#` |
| 0x80060e | `Nu /` |
| 0x8006ab | `Hg\nHx` |
| 0x8006b6 | `SlJy` |
| 0x8006c4 | `#0Hx` |
| 0x8006ce | `SlJy` |
| 0x8006e3 | `@Nu!\nExit to boot...\n` |
| 0x8006f9 | ` <del>` |
| 0x80073c | `/\nHA2<` |
| 0x800754 | ` @$PB*` |
| 0x80076b | `1 AB` |
| 0x80077b | `Zf&09` |
| 0x800792 | `"@,Q"\|` |
| 0x8007e6 | `g&$_,_Nu` |
| 0x800818 | `\n44<` |
| 0x800860 | `g(z1J@g` |
| 0x8008de | `	"&\|` |
| 0x800913 | `EJEf` |
| 0x800a16 | `H@S@g"H@` |
| 0x800a38 | `\n\rPLEXt` |
| 0x800ae3 | `.r O` |
| 0x800bd2 | `[2 \|` |
| 0x800c00 | `[2 \|` |
| 0x800c2a | `[2 \|` |
| 0x800c40 | `N^NuH` |
| 0x800c90 | `Nu"\|` |
| 0x800cb8 | `2XN@2<` |
| 0x800cd6 | `N@ /` |
| 0x800cde | `Nu o` |
| 0x800cfc | `NuH@`` |
| 0x800d1c | `NuH@`` |
| 0x800d4a | `NuHA`` |
| 0x800d74 | `NuHA`` |
| 0x800d9e | `NuHA`` |
| 0x800dd0 | `NuH@`` |
| 0x800df2 | `NuH@`` |
| 0x800e3a | `Y0Nu"<` |
| 0x800e60 | `Nu0<` |
| 0x800e72 | `Nu$<` |
| 0x800e8a | `#0.\|` |
| 0x800ed4 | `Nu /` |
| 0x800ef4 | `Nu W.y` |
| 0x800f92 | `y:NV` |
| 0x800fa4 | `5HJy` |
| 0x800fee | `yY/<` |
| 0x801024 | `N^NuNV` |
| 0x80105e | `N^NuNV` |
| 0x80106c | `5HHx` |
| 0x801082 | `f(Jy` |
| 0x801089 | `Vf N` |
| 0x8010cc | `N^NuNV` |
| 0x8010ef | `V @JPg` |
| 0x8010ff | `V @0` |
| 0x80113e | `NuNV` |
| 0x8011b6 | ` @ PN` |
| 0x8011d5 | `P @/` |
| 0x80120a | `N^Nu` |
| 0x80125c | ` @ Pp` |
| 0x8012c8 | `N^NuNV` |
| 0x8012e5 | `9n. ` |
| 0x801356 | `N^NuNV` |
| 0x801396 | `N^NuNV` |
| 0x801448 | `N^NuNV` |
| 0x80145f | `Dg(N` |
| 0x801490 | `N^NuNV` |
| 0x8014b3 | `Dg N` |
| 0x8014e0 | `N^NuNV` |
| 0x8014f7 | `Dg(N` |
| 0x801528 | `N^NuNV` |
| 0x801554 | `Y0N^NuNV` |
| 0x801571 | `V @JPf` |
| 0x801581 | `V @0` |
| 0x80158c | `N^NuNV` |
| 0x8015a0 | `g&*\|` |
| 0x8015ba | `g& .` |
| 0x8015e6 | `N^NuNV` |
| 0x801606 | `JUg*J` |
| 0x80160f | `Dg N` |
| 0x801636 | `JUg*J` |
| 0x80163f | `Dg N` |
| 0x80166c | `N^NuNV` |
| 0x8016d6 | `[2Hx` |
| 0x8016fc | `[2Hx` |
| 0x801726 | `[2Hx` |
| 0x801762 | `N^NuNV` |
| 0x801812 | `N^NuNV` |
| 0x80183c | `gHrA` |
| 0x801842 | `gjrD` |
| 0x801891 | `@`rN` |
| 0x8018a4 | ```By` |
| 0x8018cb | ```8p` |
| 0x801906 | `N^NuNV` |
| 0x801958 | `[2Hx` |
| 0x801a62 | `[2BTHx` |
| 0x801ac4 | `gjHx` |
| 0x801b46 | `N^Nu` |
| 0x801b88 | ``l Up` |
| 0x801ba6 | `g< m` |
| 0x801be5 | `CJCf` |
| 0x801c0e | `N^Nu` |
| 0x801d0a | ` @*P` |
| 0x801e30 | `g\np!` |
| 0x801e82 | `g\np)` |
| 0x801ec8 | `N^NuNV` |
| 0x801f2e | `[2*\|` |
| 0x801f58 | `[2,9` |
| 0x801fc6 | `N^NuNV` |
| 0x801fea | `N^NuNV` |
| 0x802011 | `Dg0N` |
| 0x80207e | `z@p\r` |
| 0x802088 | `[2-\|` |
| 0x8020da | `[2Hx` |
| 0x802116 | `\|	Hx` |
| 0x802142 | `N^NuNV` |
| 0x8021ab | `wHx ` |
| 0x8021c7 | `wHx ` |
| 0x8021ec | ``&RTHx` |
| 0x80227c | ``"Hx` |
| 0x80230c | `N^Nu` |
| 0x80233e | `*HHx` |
| 0x8023ff | `l/\rN` |
| 0x8024be | `NuNV` |
| 0x802529 | `?f N` |
| 0x802554 | `\|d`*` |
| 0x8025b0 | `N^NuNV` |
| 0x8025d2 | `5@$y` |
| 0x8025d8 | `5D-\|` |
| 0x8025ee | `5< .` |
| 0x8027c0 | ``Npi` |
| 0x80289c | `g,pd` |
| 0x8028de | `oDpd` |
| 0x80294e | `o,pd` |
| 0x802974 | `Z -@` |
| 0x802aa2 | `f8Bj` |
| 0x802b72 | ` @"n` |
| 0x802c03 | `P @.` |
| 0x802c95 | `P @.` |
| 0x802cd6 | ` @ PN` |
| 0x803005 | `\n Gp` |
| 0x803034 | `g^pb` |
| 0x80303a | `gXpc` |
| 0x803040 | `gR 9` |
| 0x8034a5 | `Fl\nrZ` |
| 0x8034c5 | `<l"rm` |
| 0x803512 | `N^NuNV` |
| 0x803538 | `N^Nu` |
| 0x8035c4 | `gxBy` |
| 0x8036fd | `TgJ y` |
| 0x803704 | `5DBh` |
| 0x803710 | `5D*@~` |
| 0x803740 | `5D!\|` |
| 0x8037de | `N^NuNV` |
| 0x8038d0 | `N^NuNV` |
| 0x803930 | `N^NuNV` |
| 0x803978 | `N^NuNV` |
| 0x8039c6 | `N^NuNV` |
| 0x8039ee | `*@,9` |
| 0x803a57 | `R&M`\*` |
| 0x803a67 | `RgL&` |
| 0x803a79 | `Rg:.` |
| 0x803b05 | `RgL ` |
| 0x803b15 | `Rg<.` |
| 0x803b64 | `[2,9` |
| 0x803b6e | `&M`4&` |
| 0x803bb5 | `&g\nN` |
| 0x803c01 | `&&M`` |
| 0x803c3c | `&M`NN` |
| 0x803ca6 | `N^NuABCDEFGHNV` |
| 0x803cc0 | `*H..` |
| 0x803e5a | `N^NuNV` |
| 0x803e9a | `N^NuNV` |
| 0x803ec6 | `g0Hx` |
| 0x803f22 | `N^NuNV` |
| 0x803f46 | `[2*n` |
| 0x803fa0 | `/\rHx` |
| 0x803fc8 | `N^NuNV` |
| 0x803fe9 | `RgDp` |
| 0x804032 | `N^NuNV` |
| 0x804094 | `N^NuNV` |
| 0x8040e4 | `[2*\|` |
| 0x8040ff | `GJGf` |
| 0x804108 | `[2*9` |
| 0x804162 | `[2*\|` |
| 0x80416c | `l(,\r` |
| 0x8041f8 | `[2&\|` |
| 0x804234 | `[2Hx` |
| 0x8042aa | `[2By` |
| 0x8042b6 | `[2Hx` |
| 0x804300 | `[2Hx` |
| 0x8043aa | `[2Hx` |
| 0x8043fc | `N^Nu` |
| 0x8044a0 | `[2(\|` |
| 0x8044d8 | `[2(\|` |
| 0x804572 | `(K`4\|` |
| 0x8045b6 | `[2Hx` |
| 0x8045e4 | `[2Hx` |
| 0x804640 | `/\n/<` |
| 0x804708 | `[2Hx` |
| 0x80476e | `~\rHx` |
| 0x8047b2 | `[2Hx` |
| 0x804964 | `g& <` |
| 0x80498a | `gT +` |
| 0x804b46 | `N^NuNV` |
| 0x804ba0 | `f&Hx` |
| 0x804c08 | `N^NuNV` |
| 0x804cbf | ` Hx	` |
| 0x804d3a | `[2Hx` |
| 0x804d83 | `FJFf` |
| 0x804d92 | `[2Hx` |
| 0x804dda | `[2Hx` |
| 0x804e16 | `[2By` |
| 0x804e26 | `~	Hx` |
| 0x804e44 | `[2Hx` |
| 0x804e5a | `~\nHx` |
| 0x804e8e | `[2Hx` |
| 0x804ec4 | `N^NuNV` |
| 0x804ee0 | `&@ n` |
| 0x804f13 | `GJGf` |
| 0x804fb8 | `N^NuNV` |
| 0x804ff2 | `N^NuNV` |
| 0x80503e | `fl 9` |
| 0x8050aa | ``:Jm` |
| 0x8050af | ` g,;\|` |
| 0x8050ec | `N^NuNV` |
| 0x805258 | ` @ PN` |
| 0x8052b6 | `N^NuNV` |
| 0x8052f0 | ` @ PN` |
| 0x805368 | `N^NuNV` |
| 0x8054f6 | `N^NuNV` |
| 0x8055ca | `N^NuNV` |
| 0x805609 | `,f\nN` |
| 0x805652 | `N^NuNV` |
| 0x8056ce | `N^NuNV` |
| 0x805710 | `N^NuNV` |
| 0x805756 | `N^NuNV` |
| 0x805776 | `N^NuNV` |
| 0x8057b0 | `N^NuNV` |
| 0x80581c | `N^NuNV` |
| 0x805884 | `N^NuNV` |
| 0x8058f0 | `N^NuNV` |
| 0x80592c | `N^NuNV` |
| 0x80594c | `N^NuNV` |
| 0x80598a | `N^NuNV` |
| 0x8059d8 | `N^NuNV` |
| 0x805a1c | `N^NuNV` |
| 0x805a6a | `N^NuNV` |
| 0x805aac | `N^NuNV` |
| 0x805ad1 | `"f\nN` |
| 0x805b14 | `N^NuNV` |
| 0x805b2e | `N^NuNV` |
| 0x805b6e | `N^NuNV` |
| 0x805b9a | `N^NuNV` |
| 0x805bec | `N^NuNV` |
| 0x805d43 | `P @/` |
| 0x805e1e | `N^NuNV` |
| 0x805eae | `[2Hx` |
| 0x805f14 | `[2Hx` |
| 0x805fab | `RBSJ` |
| 0x805fbc | `fH(9` |
| 0x805ffd | `RBSS` |
| 0x806048 | `fH(9` |
| 0x806089 | `RBSS` |
| 0x8060b8 | `N^NuNV` |
| 0x80620a | `N^Nu` |
| 0x806318 | `N^NuNV` |
| 0x806330 | `5@&\|` |
| 0x8063c8 | `N^NuNV` |
| 0x8063f0 | `N^NuNV` |
| 0x806412 | `i N^NuNV` |
| 0x8064eb | `\nf$J` |
| 0x806592 | `5@p\n!@` |
| 0x80659e | `5@!K` |
| 0x8065b9 | `\nfnJ` |
| 0x8065c1 | `Dgfp` |
| 0x806646 | `N^NuNV` |
| 0x8066c6 | `N^NuNV` |
| 0x8067a6 | `N^NuNV` |
| 0x8067be | `g By` |
| 0x8067de | ``HSy` |
| 0x806806 | `g Sy` |
| 0x80682e | `g Sy` |
| 0x806856 | `N^NuNV` |
| 0x80686f | `\ng\n.` |
| 0x8068e1 | `d`8.` |
| 0x80691c | `N^NuNV` |
| 0x8069de | `N^NuNV` |
| 0x806ad0 | `N^NuNV` |
| 0x806bc2 | ` @ (` |
| 0x806bdc | `fj"9` |
| 0x806bf2 | ` @ (` |
| 0x806cd4 | `N^NuNV` |
| 0x806f90 | `N^NuNV` |
| 0x80703e | `g^ -` |
| 0x8070f9 | `Dg& -` |
| 0x807155 | `Dg& -` |
| 0x807198 | ``. -` |
| 0x8071fc | `g^ -` |
| 0x80720a | `fP&L6` |
| 0x807227 | `p~\nJSg` |
| 0x80723f | `Dgnp` |
| 0x807256 | `gFpa`D` |
| 0x807264 | `&H9\|` |
| 0x80729c | ``"pi/` |
| 0x8072c6 | `N^Nu` |
| 0x80731c | ```p_` |
| 0x807384 | `N^NuNV` |
| 0x8073f4 | ``~*\|` |
| 0x807402 | `lFHx` |
| 0x807468 | ``\n;\|` |
| 0x807478 | `N^NuNV` |
| 0x8074fa | `N^Nu0123456789ABCDEF` |
| 0x80751e | `x<`\nSDg` |
| 0x80759b | `xf. ` |
| 0x8075dc | `vZ`j` |
| 0x807625 | `df"p	` |
| 0x807656 | `N^NuNV` |
| 0x8076b6 | `N^NuNV` |
| 0x8076ec | `f Hx` |
| 0x807712 | `N^NuNV` |
| 0x807736 | ``v .` |
| 0x807750 | `g2r!` |
| 0x807756 | `g<r*` |
| 0x807782 | ``*~\n`` |
| 0x8077b2 | `N^NuNV` |
| 0x8077f6 | `g4r\n` |
| 0x8077fc | `g(r\r` |
| 0x807814 | `gRr#` |
| 0x80787e | `N^NuNV` |
| 0x8078b6 | `N^NuTSTS1-f` |
| 0x8078c2 | `PROM   ` |
| 0x8078ca | `STATIC ` |
| 0x8078d2 | `SIO    ` |
| 0x8078da | `MAIN   ` |
| 0x8078e2 | `JOB    ` |
| 0x8078ea | `MAP    ` |
| 0x8078f2 | `MAPPER ` |
| 0x8078fa | `SCSI   ` |
| 0x807902 | `MULTBUS` |
| 0x80790a | `CLOCK  ` |
| 0x807912 | `REGSTER` |
| 0x80791a | `PRIV   ` |
| 0x807922 | `PARITY ` |
| 0x80792a | `BUS    ` |
| 0x807932 | `PROCS  ` |
| 0x80793a | `NO TEST` |
| 0x807942 | `EXUS` |
| 0x807947 | ` SELFTEST REV %s ` |
| 0x80795d | `\nSELFTEST COMPLETE\n` |
| 0x807971 | `\nSELFTEST FAILED - ` |
| 0x807985 | `\n	%s(t%x) FAILED (%4x)` |
| 0x80799c | `PERR1 ` |
| 0x8079a3 | `PERR2 ` |
| 0x8079aa | `MBERR ` |
| 0x8079b1 | `SC_R  ` |
| 0x8079b8 | `BUSERR` |
| 0x8079bf | `MISC  ` |
| 0x8079c6 | `KILL  ` |
| 0x8079cd | `%s  = %x\n` |
| 0x8079d7 | `SC_C    = %x\n` |
| 0x8079e5 | `SC_P    = %x\n` |
| 0x8079f3 | `address %6x received %8x expected %8x` |
| 0x807a19 | `interrupt %6x received %4x expected 1` |
| 0x807a3f | `buserr %4x received %4x expected %4x` |
| 0x807a64 | `time out %x` |
| 0x807a70 | ` Monitor = %x` |
| 0x807a7e | ` Boot = %x` |
| 0x807a89 | `%x ints` |
| 0x807a91 | `execute err` |
| 0x807a9d | `id err ` |
| 0x807aa5 | `ua23 err` |
| 0x807aae | `\nmemsize = %x.%x Mb` |
| 0x807acf | `job ` |
| 0x807ad4 | `dma ` |
| 0x807ad9 | `TEST # = %x FAILS = %x\n` |
| 0x807af3 | `%8x = %4x,	%8x = %4x\n` |
| 0x807b09 | `%8x = %4x  instead of %x\n` |
| 0x807b23 | `%8x = %4x\n` |
| 0x807b2e | `%8x =  %4x  ? ` |
| 0x807b3d | `%8x =  ` |
| 0x807b45 | `%4x ` |
| 0x807b4a | `%4x ` |
| 0x807b4f | `     ` |
| 0x807b55 | `    /* ` |
| 0x807b63 | ` */\n` |
| 0x807b68 | `%6x   %s\n` |
| 0x807b72 | `%4x - %s\n` |
| 0x807b81 | ` FAILED (%x)\n` |
| 0x807b8f | ` PASSED\n` |
| 0x807b9a | `\njumping to %x\n` |
| 0x807bae | `\nVERSION = %s\n\n` |
| 0x807bbe | ` ????\n` |
| 0x807bc5 | ` ????\n` |
| 0x807bcc | `TEST # = %x FAILS = %x\n` |
| 0x807be4 | `\nconfig checksum error %x ` |
| 0x807bff | `\nreally? (y or n)` |
| 0x807c11 | ` address %x` |
| 0x807c1d | ` peh = %x pel = %x\n` |
| 0x807c33 | `U%d%c ` |
| 0x807c3a | `U15%c ` |
| 0x807c41 | `U15%c ` |
| 0x807c48 | `\nONLY DMA` |
| 0x807c52 | ` time out\n` |
| 0x807c5d | ` <star>\n` |
| 0x807c66 | ` time out` |
| 0x807c70 | `%x %x ` |
| 0x807c77 | `\n	job ` |
| 0x807c7e | `\n	dma ` |
| 0x807c85 | `\njob ` |
| 0x807c8b | `\ndma ` |
| 0x807c91 | `****` |
| 0x807c96 | `interrupt # %x\n` |
| 0x807ca6 | `bus error\n` |
| 0x807cb1 | `address error\n` |
| 0x807cc0 | `illegal instruction\n` |
| 0x807cd5 | `clock int\n` |
| 0x807ce0 | `memory parity error\n` |
| 0x807cf5 | `\nPC = %x, SR = %x\n` |
| 0x807d08 | `INSTREG = %x, ACCESSADDR = %x, R:~I:FCN = %x\n` |
| 0x807d36 | `\n	%s(t%x) FAILED (%x)` |
| 0x807d4c | `\n select` |
| 0x807d55 | `\n sd_i_int` |
| 0x807d60 | `\n sd_o_int` |
| 0x807d6b | `\n ss_i_int` |
| 0x807d76 | `\nstatus = %x\n` |
| 0x807d84 | `sense = %x %x %x %x %x %x %x %x %x %x %x\n` |
| 0x807dae | `\n saveptrs` |
| 0x807db9 | `\n loadptrs` |
| 0x807dc4 | `\n scsi = %x last = %x ` |
| 0x807ddb | `selection timeout \n` |
| 0x807def | `no sel int\n` |
| 0x807dfb | `deadman timeout\n` |
| 0x807e0c | `busy active\n` |
| 0x807e19 | ` err = %x` |
| 0x807e23 | `\n	WARNING: config info invalid` |
| 0x807e42 | `\nsc%x lun %x expected` |
| 0x807e58 | `\nsc%x expected` |
| 0x807e67 | `\nsc%x not expected` |
| 0x807e7a | `\nSYSTEM CONFIGURATION:   ` |
| 0x807e94 | `ex  ` |
| 0x807e99 | `icp  ` |
| 0x807e9f | `acp  ` |
| 0x807ea5 | `sc%x  ` |
| 0x807eac | `%x.%x Mb` |
| 0x807eb5 | `\nEXPECTED CONFIGURATION: ` |
| 0x807ecf | `ex  ` |
| 0x807ed4 | `icp  ` |
| 0x807eda | `acp  ` |
| 0x807ee0 | `sc%x  ` |
| 0x807ee7 | `%x.%x Mb` |
| 0x807ef0 | `\nno icp` |
| 0x807ef8 | `\nno %ccp` |
| 0x807f01 | `\nno %ccp` |
| 0x807f0a | `\nbad status` |
| 0x807f16 | `\n	%ccp FAILED (%x)` |
| 0x807f29 | `no board` |

## U15 Strings

| Address | String |
|---------|--------|
| 0x808412 | `NsHx` |
| 0x808418 | ``(Hx` |
| 0x80841e | ``"Hx` |
| 0x808436 | ``\nHx` |
| 0x808444 | `NsHx` |
| 0x80844a | ``(Hx` |
| 0x808450 | ``"Hx` |
| 0x808468 | ``\nHx` |
| 0x808534 | `Nu /` |
| 0x8085ae | `B@H@` |
| 0x8085be | `H@`6` |
| 0x808601 | `<N^NuNV` |
| 0x808628 | `HABA` |
| 0x808632 | `N^NuNV` |
| 0x80866a | `HABA` |
| 0x80867a | `N^NuNV` |
| 0x8086a8 | `B@H@` |
| 0x8086b2 | `B@H@`8&` |
| 0x8086fa | `N^NuNV` |
| 0x80872e | `H@`6` |
| 0x80876c | `N^NuNV` |
| 0x80878a | `B@H@` |
| 0x808794 | `B@H@`8&` |
| 0x8087d6 | `N^Nu /` |
| 0x8087e6 | `Nu <` |
| 0x8087fc | `NuBy` |
| 0x808888 | `NuH@`` |
| 0x808890 | `/\nHA2<` |
| 0x8088a6 | ` @$PB*` |
| 0x8088bd | `1 AB` |
| 0x80891a | `HA$_Nu` |
| 0x808a78 | `:<Hx` |
| 0x808a96 | `N^NuNV` |
| 0x808b2a | `N^NuNV` |
| 0x808c02 | `gZHx` |
| 0x808cb2 | `N^NuNV` |
| 0x808d30 | `n\Hx` |
| 0x808dbe | `N^NuNV` |
| 0x808e0a | `N^NuNV` |
| 0x808e52 | `N^NuNV` |
| 0x808ee6 | `: gPHx` |
| 0x808f6e | `N^NuNV` |
| 0x808f86 | `*H`".` |
| 0x808fbc | `N^NuNV` |
| 0x808fce | `: f&#` |
| 0x808ff6 | ``L 9` |
| 0x809048 | `N^NuNV` |
| 0x80907c | `:\| n` |
| 0x8090c3 | `!f\nR9` |
| 0x8091fa | `f\nB9` |
| 0x80922e | `: 09` |
| 0x80923e | `N^NuNV` |
| 0x80924c | `: f\n.` |
| 0x809262 | `N^NuNV` |
| 0x809288 | `N^NuNV` |
| 0x8092a7 | ``N^NuNV` |
| 0x8092c0 | ` @ PN` |
| 0x8092c8 | `N^NuNV` |
| 0x8092dc | ` @ PN` |
| 0x8092e2 | `N^NuNV` |
| 0x8092f6 | ` @ PN` |
| 0x8092fc | `N^NuNV` |
| 0x809304 | `N^Nu` |
| 0x8093a8 | `gNr ` |
| 0x8093ae | `gHr+` |
| 0x8093b4 | `gTr-` |
| 0x8093ba | `gLr0` |
| 0x8093c0 | `g4rX` |
| 0x8093c6 | `g4rx` |
| 0x8093cc | `g.`h` |
| 0x8093d3 | `9nh.` |
| 0x809411 | `fn0p\n` |
| 0x80945a | `N^NuNV` |
| 0x80948a | `N^Nu` |
| 0x809564 | `;H*\|` |
| 0x8095d6 | `;H`l` |
| 0x80962c | ` @*PR` |
| 0x809692 | `N^NuNV` |
| 0x8097a8 | `N^NuNV` |
| 0x8099c6 | `*@ .` |
| 0x809a6c | `N^NuNV` |
| 0x809ada | `N^NuNV` |
| 0x809b58 | `;bN^NuNV` |
| 0x809b75 | `fN^NuNV` |
| 0x809b90 | `;L(9` |
| 0x809b96 | `;P y` |
| 0x809c42 | `;T y` |
| 0x809c68 | `NuNV` |
| 0x809c78 | `;L*\|` |
| 0x809c9e | `NuNV` |
| 0x809cb0 | `;`*\|` |
| 0x809d00 | `N^NuNV` |
| 0x809d19 | `r`L.` |
| 0x809d68 | `N^NuNV` |
| 0x809dba | `;dN^NuNV` |
| 0x809e34 | `N^NuNV` |
| 0x809e7c | `N^NuNV` |
| 0x809ea4 | `N^NuNV` |
| 0x809f58 | `N^NuNV` |
| 0x809f90 | `N^NuNV` |
| 0x809fda | `f\po` |
| 0x80a000 | ``0pO` |
| 0x80a07a | `N^NuNV` |
| 0x80a0d2 | `N^NuNV` |
| 0x80a116 | `f*Hx` |
| 0x80a150 | `N^NuNV` |
| 0x80a170 | `N^NuNV` |
| 0x80a1a8 | `N^NuNV` |
| 0x80a1d0 | ``Z m` |
| 0x80a232 | `N^NuNV` |
| 0x80a264 | `n\npZ` |
| 0x80a284 | `n\npz` |
| 0x80a296 | `g6r\n` |
| 0x80a29c | `g*r\r` |
| 0x80a2b4 | `g*r#` |
| 0x80a2c7 | `~~\nB` |
| 0x80a2fa | `N^NuNV` |
| 0x80a33f | `B @/` |
| 0x80a35c | `g*J9` |
| 0x80a364 | `f"".` |
| 0x80a387 | `fN^Nu` |
| 0x80a3f4 | `N^NuNV` |
| 0x80a46c | `(@Bl` |
| 0x80a568 | `N^NuNV` |
| 0x80a5a4 | `N^NuNV` |
| 0x80a61e | `N^NuNV` |
| 0x80a68d | `*N^NuNV` |
| 0x80a774 | `;h(y` |
| 0x80a7de | `N^NuNV` |
| 0x80a90a | `N^NuNV` |
| 0x80a990 | `*@+\|` |
| 0x80a9b2 | `;j*n` |
| 0x80a9b8 | `N^NuNV` |
| 0x80aa32 | `N^NuNV` |
| 0x80ab1e | `N^NuNV` |
| 0x80ab3e | `NuNV` |
| 0x80ac26 | `N^NuNV` |
| 0x80ac88 | `f( y` |
| 0x80acb6 | `;h"9` |
| 0x80ad7a | `N^NuNV` |
| 0x80addc | `N^NuNV` |
| 0x80adef | `,`,p` |
| 0x80ae83 | `@pdg( y` |
| 0x80ae93 | `@scg` |
| 0x80af76 | `N^NuNV` |
| 0x80af94 | `g* y` |
| 0x80afcf | `(`  ` |
| 0x80b012 | `N^NuNV` |
| 0x80b01a | `N^NuNV` |
| 0x80b04e | `N^NuNV` |
| 0x80b070 | `*@(y` |
| 0x80b0ec | `N^NuNV` |
| 0x80b108 | ``:Hx` |
| 0x80b144 | `N^NuNV` |
| 0x80b1b4 | `gb*\|` |
| 0x80b228 | `N^NuNV` |
| 0x80b270 | ``& y` |
| 0x80b298 | `N^NuNV` |
| 0x80b2f2 | `N^NuNV` |
| 0x80b346 | `g0 y` |
| 0x80b378 | `N^NuNV` |
| 0x80b3a9 | `zN^NuNV` |
| 0x80b406 | ``0Hx` |
| 0x80b438 | `N^NuNV` |
| 0x80b4c2 | `NuNV` |
| 0x80b501 | `\|N^Nu` |
| 0x80b576 | `N^NuNV` |
| 0x80b5d8 | `N^NuNV` |
| 0x80b618 | `N^NuNV` |
| 0x80b63a | `N^NuNV` |
| 0x80b652 | `N^NuNV` |
| 0x80b672 | `N^NuNV` |
| 0x80b6b8 | `N^NuNV` |
| 0x80b6ee | `N^NuNV` |
| 0x80b728 | `N^NuNV` |
| 0x80b76e | ``vp4` |
| 0x80b7ec | `N^NuNV` |
| 0x80b828 | `N^NuNV` |
| 0x80b83a | `:\|*9` |
| 0x80b88a | ``,Hx` |
| 0x80b8d8 | `N^NuNV` |
| 0x80b8ea | `:\|*9` |
| 0x80b95c | ``,Hx` |
| 0x80b9a2 | `N^NuNV` |
| 0x80ba00 | `N^NuNV` |
| 0x80bad0 | `N^NuNV` |
| 0x80bb02 | `NuNV` |
| 0x80bb26 | `g"(\|` |
| 0x80bb70 | `N^NuNV` |
| 0x80bbba | `N^NuNV` |
| 0x80bc7a | `NuNV` |
| 0x80bc94 | `N^NuNV` |
| 0x80bd3e | `N^NuNV` |
| 0x80bdbc | `N^NuNV` |
| 0x80be42 | `N^NuNV` |
| 0x80bf00 | `N^Nu` |
| 0x80c058 | `N^Nuinvalid object file (0x%x)` |
| 0x80c077 | `%s: not found` |
| 0x80c085 | `bad directory` |
| 0x80c093 | `bad bn %D` |
| 0x80c09d | `unknown device` |
| 0x80c0ac | `bad offset or unit specification` |
| 0x80c0cd | `unable to wake up disk controller` |
| 0x80c0ef | `bad disk init` |
| 0x80c0fd | `bad disk read` |
| 0x80c10b | `invalid disk init block` |
| 0x80c123 | `unable to wake up tape controller` |
| 0x80c145 | `bad tape init` |
| 0x80c153 | `bad tape read` |
| 0x80c161 | `bad tape seek` |
| 0x80c16f | `tape save error` |
| 0x80c17f | `tape recall error` |
| 0x80c191 | `rubout encountered` |
| 0x80c1a4 | `disk error %X, %X` |
| 0x80c1b6 | `tape error %X, %X` |
| 0x80c1c8 | `file` |
| 0x80c1d2 | `sc(0,0)/` |
| 0x80c1db | `Exit %d` |
| 0x80c1f4 | `dtot` |
| 0x80c1f9 | `ttod` |
| 0x80c204 | `pt(,)` |
| 0x80c20a | `help` |
| 0x80c20f | `pt(,)` |
| 0x80c215 | `unix` |
| 0x80c21a | `pt(,2)` |
| 0x80c221 | `sys5` |
| 0x80c226 | `pt(,2)` |
| 0x80c22d | `format` |
| 0x80c234 | `pt(,3)` |
| 0x80c23b | `mkfs` |
| 0x80c240 | `pt(,4)` |
| 0x80c247 | `restor` |
| 0x80c24e | `pt(,5)` |
| 0x80c255 | `fsck` |
| 0x80c25a | `pt(,6)` |
| 0x80c264 | `pt(,7)` |
| 0x80c26b | `fbackup` |
| 0x80c273 | `pt(,8)` |
| 0x80c27d | `pt(,9)` |
| 0x80c284 | `ccal` |
| 0x80c289 | `pt(,10)` |
| 0x80c291 | `fsdb` |
| 0x80c296 | `pt(,12)` |
| 0x80c2a1 | `pt(,13)` |
| 0x80c2ac | `pt(,14)` |
| 0x80c2b8 | `pt(,15)` |
| 0x80c2c0 | `\nPLEXUS PRIMARY BOOT REV 1.2\n: ` |
| 0x80c2e2 | `AUTO BOOT\n` |
| 0x80c2ef | `Boot: BAD MAGIC 0x%x \n` |
| 0x80c306 | `illegal system V a.out magic %o\n` |
| 0x80c327 | `text protect\n` |
| 0x80c335 | `ts(%d) ds(%d) bs(%d)\n` |
| 0x80c34b | `\nBOOT: Bad Interrupt \n` |
| 0x80c362 | `PC %x   Status Reg %x    Vector %x\n` |
| 0x80c386 | `Access Address %x \n` |
| 0x80c39a | `Robin Debug Boot Version 0.0\n` |
| 0x80c3b8 | `In setmap tp(%d) dp(%d)\n` |
| 0x80c3d1 | `Exit setmap pageno(%d)\n` |
| 0x80c3e9 | `\nI_PERR1 0x%x I_PERR2 0x%x I_MBERR 0x%x\n` |
| 0x80c412 | `I_SC_C 0x%x 0x%x  I_SC_P 0x%x 0x%x I_SC_R 0x%x\n` |
| 0x80c442 | `I_ERR 0x%x I_MISC 0x%x I_KILL 0x%x I_TRCE 0x%x I_USER 0x%x\n` |
| 0x80c47e | `0123456789ABCDEF` |
| 0x80c48f | `BOOT: ` |
| 0x80c496 | `Enter arbit\n` |
| 0x80c4a3 | `Enter select\n` |
| 0x80c4b1 | `scsi busy not set by target\n` |
| 0x80c4ce | `Enter scrwi\n` |
| 0x80c4db | `Enter s_d_i_int\n` |
| 0x80c4ec | `Enter s_d_o_int\n` |
| 0x80c4fd | `Enter s_s_i_int\n` |
| 0x80c50e | `Enter s_m_i_int\n` |
| 0x80c51f | `Enter s_m_o_int\n` |
| 0x80c530 | `Enter s_c_o_int\n` |
| 0x80c541 | `Enter resel\n` |
| 0x80c54e | `Boot: scsi abort\n` |
| 0x80c560 | `Enter saveptrs\n` |
| 0x80c570 | `Enter loadptrs\n` |
| 0x80c580 | `DISK` |
| 0x80c585 | `DISK` |
| 0x80c58a | `DISK` |
| 0x80c58f | `BOOT: disk not formatted\n` |
| 0x80c5a9 | `BOOT: unknown controller. assuming default\n` |
| 0x80c5d5 | `BOOT: Phony scsi address %x\n` |
| 0x80c5f2 | `BOOT: SCSI device %d failed \n` |
| 0x80c610 | `BOOT: %s: scdevice not free\n` |
| 0x80c62d | `Scsi device %d command %x ` |
| 0x80c648 | `Error Code %x %x %x %x\n` |
| 0x80c660 | `FLOPPY` |
| 0x80c667 | `Format with interleave of %d\n` |
| 0x80c685 | `Insert disk and press <cr> : ` |
| 0x80c6a6 | `Formatting ... ` |
| 0x80c6b6 | `done\n Another Disk ? [y] : ` |
| 0x80c6d5 | `TAPE` |
| 0x80c6da | `Scsi command %x Error Code 0x%x\n` |
| 0x80c6fb | `residue bytes %x %x %x\n` |
| 0x80c713 | `dumping %d disk blocks to tape from block %d\n` |
| 0x80c741 | `really rewrite disk ? ` |
| 0x80c758 | `\n%d tape blocks to disk from block %d\n` |
| 0x80c77f | `DISK` |
| 0x80c784 | `DISK` |
| 0x80c789 | `DONE       \n` |
| 0x80c796 | ` %x      \r` |
| 0x80c7a1 | `BOOT : Bad Interrupt : cmd %x dev %x\n` |
| 0x80c7c7 | `\nI_PERR1 0x%x I_PERR2 0x%x I_MBERR 0x%x\n` |
| 0x80c7f0 | `I_SC_C 0x%x 0x%x  I_SC_P 0x%x 0x%x I_SC_R 0x%x\n` |
| 0x80c820 | `I_ERR 0x%x I_MISC 0x%x I_KILL 0x%x I_TRCE 0x%x I_USER 0x%x\n` |
| 0x80c85c | `***checksum was %x, expected %x  ***\n` |
| 0x80c886 | `No index signal` |
| 0x80c896 | `No seek complete` |
| 0x80c8a7 | `Write fault` |
| 0x80c8b3 | `Drive not ready` |
| 0x80c8c3 | `Drive not selected` |
| 0x80c8d6 | `No track 00` |
| 0x80c8e2 | `Multiple Winchester drives selected` |
| 0x80c906 | `Media change` |
| 0x80c913 | `Seek in progress` |
| 0x80c924 | `ID read error (ECC) error in the ID field` |
| 0x80c94e | `Uncorrectable data error during a read` |
| 0x80c975 | `ID address mark not found` |
| 0x80c98f | `Data address not found` |
| 0x80c9a6 | `Record not found` |
| 0x80c9b7 | `Seek error` |
| 0x80c9c2 | `Write protected` |
| 0x80c9d2 | `Correctable data field error` |
| 0x80c9ef | `Bad block found` |
| 0x80c9ff | `Format error` |
| 0x80ca0c | `Unable to read alternate track address` |
| 0x80ca33 | `Attempted to directly access an alternate track` |
| 0x80ca63 | `Sequence time out during disk to host transfer` |
| 0x80ca92 | `Invalid command from host` |
| 0x80caac | `Illegal disk address ( beyond maximum )` |
| 0x80cad4 | `Illegal Function for type of drive specified` |
| 0x80cb01 | `Volume overflow` |
| 0x80cb11 | `Ram Error` |
| 0x80cb1b | `Unit attention, please retry` |
| 0x80cb38 | `Media not loaded` |
| 0x80cb49 | `Write protected` |
| 0x80cb59 | `Uncorrectable data error` |
| 0x80cb72 | `Bad block found` |
| 0x80cb82 | `Drive not ready` |
| 0x80cb92 | `Insufficient capacity` |
| 0x80cba8 | `Drive timeout` |
| 0x80cbb6 | `Block not found` |
| 0x80cbc6 | `Dma timeout error` |
| 0x80cbd8 | `Correctable data check` |
| 0x80cbef | `File mark detected` |
| 0x80cc02 | `Compare Error` |
| 0x80cc10 | `Invalid command` |
| 0x80cc20 | `Command timeout` |
| 0x80cc30 | `Append Error` |
| 0x80cc3d | `Read end of media` |
| 0x80cc4f | `SCSI ERROR: %s\n` |
| 0x80d092 | `NsHx` |
| 0x80d098 | ``(Hx` |
| 0x80d09e | ``"Hx` |
| 0x80d0b6 | ``\nHx` |
| 0x80d0d2 | `NsHx` |
| 0x80d0d8 | ``(Hx` |
| 0x80d0de | ``"Hx` |
| 0x80d0f6 | ``\nHx` |
| 0x80d1ec | `Nu /` |
| 0x80d200 | `Nu.\|` |
| 0x80d256 | `B@H@` |
| 0x80d266 | `H@`6` |
| 0x80d2a9 | `<N^NuNV` |
| 0x80d2d0 | `HABA` |
| 0x80d2da | `N^NuNV` |
| 0x80d312 | `HABA` |
| 0x80d322 | `N^NuNV` |
| 0x80d350 | `B@H@` |
| 0x80d35a | `B@H@`8&` |
| 0x80d3a2 | `N^NuNV` |
| 0x80d3d6 | `H@`6` |
| 0x80d414 | `N^NuNV` |
| 0x80d432 | `B@H@` |
| 0x80d43c | `B@H@`8&` |
| 0x80d47e | `N^NuNV` |
| 0x80d4a0 | `,F/<` |
| 0x80d5a6 | `n\npZ` |
| 0x80d5c0 | `g(;\|` |
| 0x80d60e | `f\n;\|` |
| 0x80d624 | `f\n;\|` |
| 0x80d660 | ``>p\` |
| 0x80d6d5 | ` /\rN` |
| 0x80d77c | `N^NuNV` |
| 0x80d7ad | `2l4p` |
| 0x80d7ea | `N^NuNV` |
| 0x80d846 | `N^NuNV` |
| 0x80d86a | ``n(y` |
| 0x80d8e0 | `N^NuNV` |
| 0x80d8f2 | `*X 9` |
| 0x80d91c | `*Xp@` |
| 0x80d94a | `o\Jl` |
| 0x80d978 | `f. y` |
| 0x80d9b4 | `o2Jl` |
| 0x80d9f0 | `fJ.9` |
| 0x80da42 | `N^NuNV` |
| 0x80da8c | `NuNV` |
| 0x80dabe | `	n`x` |
| 0x80daf5 | `2f:B-` |
| 0x80daff | `3`00-` |
| 0x80db40 | `N^NuNV` |
| 0x80db86 | ``rBm` |
| 0x80dbba | `g>;m` |
| 0x80dbfe | `N^NuNV` |
| 0x80dc1a | `f\nBy` |
| 0x80dc2e | `f\nBy` |
| 0x80dc3c | `N^NuNV` |
| 0x80dd40 | `N^NuNV` |
| 0x80dd4f | `L*Hp` |
| 0x80dd82 | `,F/<` |
| 0x80de00 | `,F/<` |
| 0x80de18 | `,F/<` |
| 0x80de30 | `N^NuNV` |
| 0x80de4c | `*A m` |
| 0x80dea2 | `gfpp` |
| 0x80df10 | `N^NuNV` |
| 0x80df60 | `N^NuNV` |
| 0x80dfca | `N^NuNV` |
| 0x80e042 | `(@Bl` |
| 0x80e134 | `N^NuNV` |
| 0x80e16a | ` @BP` |
| 0x80e1b4 | `N^NuNV` |
| 0x80e22e | `N^NuNV` |
| 0x80e29e | `N^NuNV` |
| 0x80e2fb | `\nf" 9` |
| 0x80e41a | `	nBk` |
| 0x80e43c | `N^NuNV` |
| 0x80e4b4 | `N^NuNV` |
| 0x80e5e0 | `N^NuNV` |
| 0x80e666 | `*@+\|` |
| 0x80e68e | `N^NuNV` |
| 0x80e708 | `N^NuNV` |
| 0x80e824 | `N^NuNV` |
| 0x80e848 | `NuNV` |
| 0x80e930 | `N^NuNV` |
| 0x80ea8a | `N^NuNV` |
| 0x80eb2e | `N^NuNV` |
| 0x80eb46 | `\r ;\|` |
| 0x80eb82 | ` @+P` |
| 0x80ebc6 | `N^NuNV` |
| 0x80ebfb | `	g\np` |
| 0x80ec3c | ``(p0` |
| 0x80ec76 | ``(p0` |
| 0x80ecc6 | `,> @` |
| 0x80ecd4 | `N^NuNV` |
| 0x80ed14 | `-p`hN` |
| 0x80ed26 | `,[`V*\|` |
| 0x80ed2e | `,z`N*\|` |
| 0x80ed38 | ``F*\|` |
| 0x80ed40 | ``>*\|` |
| 0x80ed48 | ``6*\|` |
| 0x80ed7e | `-\ .` |
| 0x80ed8c | `/\r/9` |
| 0x80ed92 | `,F/<` |
| 0x80edbe | `N^NuNV` |
| 0x80edd0 | `,F/<` |
| 0x80ede6 | `N^NuNV` |
| 0x80edf8 | `,F/<` |
| 0x80ee24 | `NuNV` |
| 0x80ee6c | `f\po` |
| 0x80ee92 | ``0pO` |
| 0x80ef0c | `N^NuNV` |
| 0x80ef64 | `N^NuNV` |
| 0x80efa2 | `f*Hx` |
| 0x80efdc | `N^NuNV` |
| 0x80f03c | `N^NuNV` |
| 0x80f06e | `n\npZ` |
| 0x80f08e | `n\npz` |
| 0x80f0a0 | `g.r\n` |
| 0x80f0a6 | `g"r\r` |
| 0x80f0b8 | `g(r#` |
| 0x80f0fc | `N^NuNV` |
| 0x80f128 | `g<(\|` |
| 0x80f15a | `m\n m` |
| 0x80f170 | `n\npz` |
| 0x80f1dc | `g\n m` |
| 0x80f290 | `N^NuNV` |
| 0x80f2ba | `(@p\r` |
| 0x80f2d0 | `N^Nu` |
| 0x80f2dc | `%s Bad device Number in rint %x\n` |
| 0x80f2fd | `%s Bus Error\n` |
| 0x80f30b | `%s Address Error\n` |
| 0x80f31d | `%s Bad Trap\n` |
| 0x80f32a | `STATUS REG = %x : HIGH PC = %x :  LOW PC = %x : VECTOR = %x\n` |
| 0x80f367 | `SPCL STAT  = %x : HIGH FLT = %x : LOW FLT = %x \n` |
| 0x80f39a | `Enter arbit\n` |
| 0x80f3a7 | `Enter select\n` |
| 0x80f3b5 | `Enter scrwi\n` |
| 0x80f3c2 | `Enter s_d_i_int\n` |
| 0x80f3d3 | `Enter s_d_o_int\n` |
| 0x80f3e4 | `Enter s_s_i_int\n` |
| 0x80f3f5 | `Enter s_m_i_int\n` |
| 0x80f406 | `Enter s_m_o_int\n` |
| 0x80f417 | `Enter s_c_o_int\n` |
| 0x80f428 | `Enter resel\n` |
| 0x80f435 | `Enter saveptrs\n` |
| 0x80f445 | `Enter loadptrs\n` |
| 0x80f4c8 | `,JRemote Kernal : ` |
| 0x80f4db | `scsi selection timeout. device` |
| 0x80f4fa | `scsi failed interrupt. device` |
| 0x80f518 | `scsi command to active device` |
| 0x80f536 | `selection interrupt from unknown device` |
| 0x80f55e | `bad scsi pointer number` |
| 0x80f576 | `bad controller number` |
| 0x80f58c | `scsi register = 0x%x\n` |
| 0x80f5a2 | `Error in scsi transfer type` |
| 0x80f5be | `same pointer interrupt number` |
| 0x80f5dc | `unknown tty command` |
| 0x80f5f0 | `unknown reason` |
| 0x80f5ff | `%s %s %x\n` |
| 0x80f609 | `%s scsi input parity error: master = %x\n` |
| 0x80f632 | `%s HALTED\n` |
| 0x80f63e | `0123456789ABCDEF` |
| 0x80f650 | `({)}!\|^~'`\\` |
