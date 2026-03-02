#!/usr/bin/env python3
"""Parse m68k objdump output to identify function boundaries and extract strings."""

import re
import sys
import json
from collections import defaultdict

def parse_disassembly(filename):
    """Parse objdump output into a list of (address, raw_bytes, mnemonic, operands, full_line)."""
    instructions = []
    with open(filename) as f:
        for line in f:
            # Match lines like: "  800708:\t46fc 2700      \tmovel #9984,%sr"
            m = re.match(r'\s+([0-9a-f]+):\s+([0-9a-f ]+?)\s+\t(\S+)\s*(.*)', line)
            if m:
                addr = int(m.group(1), 16)
                raw = m.group(2).strip()
                mnemonic = m.group(3)
                operands = m.group(4).strip()
                instructions.append((addr, raw, mnemonic, operands, line.rstrip()))
            else:
                # Also match data lines like "  800000:\t00c0      \t.short 0x00c0"
                m2 = re.match(r'\s+([0-9a-f]+):\s+([0-9a-f ]+?)\s+\t(\.\w+)\s*(.*)', line)
                if m2:
                    addr = int(m2.group(1), 16)
                    raw = m2.group(2).strip()
                    mnemonic = m2.group(3)
                    operands = m2.group(4).strip()
                    instructions.append((addr, raw, mnemonic, operands, line.rstrip()))
    return instructions


def extract_strings_from_binary(bin_filename, base_addr):
    """Extract ASCII strings from the binary, returning {address: string}."""
    strings = {}
    with open(bin_filename, 'rb') as f:
        data = f.read()

    current_str = []
    start_offset = None
    for i, b in enumerate(data):
        if 0x20 <= b < 0x7f or b in (0x0a, 0x0d, 0x09):
            if not current_str:
                start_offset = i
            current_str.append(chr(b))
        else:
            if len(current_str) >= 4:
                s = ''.join(current_str)
                strings[base_addr + start_offset] = s
            current_str = []
            start_offset = None
    if len(current_str) >= 4:
        strings[base_addr + start_offset] = ''.join(current_str)
    return strings


def parse_vector_table(instructions, base_addr):
    """Parse the 68010 vector table (256 entries, 4 bytes each) to find entry points."""
    entry_points = set()
    # Vector table is at base_addr, 256 longwords (1024 bytes)
    # But we need to read longwords from the raw binary
    # The first two entries are SSP and PC (reset vector)
    # Let's extract from instruction data - vectors are stored as pairs of words
    i = 0
    vectors = {}
    while i < len(instructions) and instructions[i][0] < base_addr + 0x400:
        addr = instructions[i][0]
        if addr >= base_addr and (addr - base_addr) % 4 == 0:
            vec_num = (addr - base_addr) // 4
            # Read the longword: combine two consecutive words from raw bytes
            raw = instructions[i][1]
            # The raw bytes might span multiple display items
            # Better to read from binary directly
            pass
        i += 1
    return entry_points


def extract_vectors_from_binary(bin_filename, base_addr):
    """Read vector table longwords directly from binary."""
    vectors = {}
    with open(bin_filename, 'rb') as f:
        data = f.read()

    # 68010 vector table: 256 entries, 4 bytes each
    # Entry 0: Initial SSP, Entry 1: Initial PC (reset vector)
    # We'll read first 64 vectors (covers all standard ones)
    for i in range(64):
        offset = i * 4
        if offset + 4 <= len(data):
            val = int.from_bytes(data[offset:offset+4], 'big')
            if val != 0 and base_addr <= val < base_addr + len(data):
                vectors[i] = val
    return vectors


def find_function_boundaries(instructions, vectors, base_addr, end_addr):
    """Identify function entry points and boundaries."""
    entry_points = set()

    # Add vector table targets
    for vec_num, target in vectors.items():
        if vec_num >= 1:  # Skip SSP (vector 0)
            entry_points.add(target)

    # Find jsr/bsr targets
    for addr, raw, mnemonic, operands, line in instructions:
        if mnemonic in ('jsr', 'bsr', 'bsrs', 'bsrl', 'bsrw'):
            # Extract target address
            # Absolute: jsr 0x800abc
            m = re.search(r'(?:0x)?([0-9a-f]+)', operands)
            if m:
                target = int(m.group(1), 16)
                if base_addr <= target < end_addr:
                    entry_points.add(target)
        # Also jmp targets can be function entries
        elif mnemonic in ('jmp',):
            m = re.search(r'(?:0x)?([0-9a-f]+)', operands)
            if m:
                target = int(m.group(1), 16)
                if base_addr <= target < end_addr:
                    entry_points.add(target)
        # Branch targets (bra, beq, bne, etc.) to distant locations
        elif mnemonic.startswith('b') and mnemonic not in ('btst', 'bset', 'bclr', 'bchg', 'bfchg', 'bfclr', 'bfexts', 'bfextu', 'bfffo', 'bfins', 'bfset', 'bftst'):
            m = re.search(r'(?:0x)?([0-9a-f]+)\b', operands)
            if m:
                target = int(m.group(1), 16)
                # Only add as entry point if it's a forward reference far away
                # (likely a different function, not just a local branch)

    # Find rts/rte as function endings
    endings = set()
    for addr, raw, mnemonic, operands, line in instructions:
        if mnemonic in ('rts', 'rte'):
            endings.add(addr)

    return sorted(entry_points), sorted(endings)


def split_into_functions(instructions, entry_points, endings, base_addr, end_addr, strings):
    """Split disassembly into function chunks."""
    functions = []

    # Build address-to-instruction index
    addr_to_idx = {}
    for i, (addr, raw, mnemonic, operands, line) in enumerate(instructions):
        addr_to_idx[addr] = i

    # Sort entry points
    sorted_entries = sorted(entry_points)

    for i, start_addr in enumerate(sorted_entries):
        if start_addr not in addr_to_idx:
            continue

        # Function extends until next entry point or until we hit an rts/rte
        # followed by another function
        next_entry = sorted_entries[i + 1] if i + 1 < len(sorted_entries) else end_addr

        # Collect instructions for this function
        func_instructions = []
        start_idx = addr_to_idx[start_addr]
        last_rts_addr = None

        for j in range(start_idx, len(instructions)):
            addr, raw, mnemonic, operands, line = instructions[j]
            if addr >= next_entry:
                break
            func_instructions.append(instructions[j])
            if mnemonic in ('rts', 'rte'):
                last_rts_addr = addr

        if not func_instructions:
            continue

        func_end = func_instructions[-1][0]

        # Find associated strings
        func_strings = {}
        for str_addr, s in strings.items():
            if start_addr <= str_addr <= func_end + 0x40:
                func_strings[str_addr] = s
            # Also check if any instruction references a string address
        for addr, raw, mnemonic, operands, line in func_instructions:
            # Look for references to string addresses in operands
            for m in re.finditer(r'(?:0x)?([0-9a-f]{5,8})', operands):
                ref_addr = int(m.group(1), 16)
                if ref_addr in strings:
                    func_strings[ref_addr] = strings[ref_addr]

        # Build the disassembly text
        disasm_text = '\n'.join(inst[4] for inst in func_instructions)

        functions.append({
            'start_addr': f"0x{start_addr:06x}",
            'end_addr': f"0x{func_end:06x}",
            'size': func_end - start_addr,
            'instruction_count': len(func_instructions),
            'disassembly': disasm_text,
            'strings': func_strings,
            'has_rts': last_rts_addr is not None,
        })

    return functions


def process_rom(disasm_file, bin_file, base_addr, rom_name):
    """Process a single ROM file."""
    print(f"Processing {rom_name}...")
    end_addr = base_addr + 0x8000  # 32KB

    instructions = parse_disassembly(disasm_file)
    print(f"  Parsed {len(instructions)} instructions")

    strings = extract_strings_from_binary(bin_file, base_addr)
    print(f"  Found {len(strings)} strings")

    vectors = extract_vectors_from_binary(bin_file, base_addr)
    print(f"  Found {len(vectors)} vector table entries")
    for vec_num, target in sorted(vectors.items()):
        vec_names = {0: 'SSP', 1: 'Reset PC', 2: 'Bus Error', 3: 'Address Error',
                     4: 'Illegal Instruction', 5: 'Zero Divide', 6: 'CHK',
                     7: 'TRAPV', 8: 'Privilege Violation', 9: 'Trace',
                     10: 'Line 1010', 11: 'Line 1111',
                     24: 'Spurious Interrupt',
                     25: 'Autovector 1', 26: 'Autovector 2', 27: 'Autovector 3',
                     28: 'Autovector 4', 29: 'Autovector 5', 30: 'Autovector 6',
                     31: 'Autovector 7'}
        name = vec_names.get(vec_num, f'Vector {vec_num}')
        print(f"    {name}: 0x{target:06x}")

    entry_points, endings = find_function_boundaries(instructions, vectors, base_addr, end_addr)
    print(f"  Found {len(entry_points)} entry points, {len(endings)} rts/rte endings")

    functions = split_into_functions(instructions, entry_points, endings, base_addr, end_addr, strings)
    print(f"  Split into {len(functions)} functions")

    return {
        'rom_name': rom_name,
        'base_addr': f"0x{base_addr:06x}",
        'vectors': {str(k): f"0x{v:06x}" for k, v in vectors.items()},
        'strings': {f"0x{k:06x}": v for k, v in strings.items()},
        'functions': functions,
    }


def main():
    base_dir = '/home/fletto/ext/src/claude/plexus'

    u17_result = process_rom(
        f'{base_dir}/U17_disasm.txt',
        f'{base_dir}/ROMs/U17-MERGED.BIN',
        0x800000,
        'U17 (Self-test/Debug)'
    )

    u15_result = process_rom(
        f'{base_dir}/U15_disasm.txt',
        f'{base_dir}/ROMs/U15-MERGED.BIN',
        0x808000,
        'U15 (Boot Loader)'
    )

    # Save results
    output = {'u17': u17_result, 'u15': u15_result}
    output_file = f'{base_dir}/rom_functions.json'
    with open(output_file, 'w') as f:
        json.dump(output, f, indent=2)
    print(f"\nSaved function data to {output_file}")

    # Print summary
    for rom in [u17_result, u15_result]:
        print(f"\n{rom['rom_name']}:")
        print(f"  Functions: {len(rom['functions'])}")
        for func in rom['functions'][:5]:
            strs = list(func['strings'].values())[:2]
            str_info = f" -- strings: {strs}" if strs else ""
            print(f"  {func['start_addr']}: {func['instruction_count']} insns, {func['size']} bytes{str_info}")
        if len(rom['functions']) > 5:
            print(f"  ... and {len(rom['functions']) - 5} more")


if __name__ == '__main__':
    main()
