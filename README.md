# Plexus P/20 Analysis

AI-assisted reverse engineering analysis of the Plexus P/20 minicomputer's boot ROMs, UNIX operating system, and disk contents.

The original hardware, ROM dumps, disk images, and documentation come from [Adrian's Digital Basement](https://www.youtube.com/@AdrianDigitalBasement) — see Adrian's [Plexus P/20 repository](https://github.com/AkBKukU/Plexus-P20) for the source material.

Watch the Plexus P/20 video series:

- Part 1: [What is this rare multi-user UNIX workstation? (Plexus P/20)](https://youtu.be/iltZYXg5hZw)
- Part 2: [First power up of the Plexus P/20 dual processor UNIX system](https://youtu.be/lCPZAYvk940)
- Part 3: [Booting UNIX on the Plexus P/20 didn't go to plan](https://youtu.be/_IrxvDE6Fyo)
- Part 4: [We made some unbelievable discoveries about this Plexus P/20!](https://youtu.be/Ve1SuuRkx_o)
- Part 5: [The Plexus P/20 is now fully operational!](https://youtu.be/10b50ECWXLk)

## System Overview

- **CPU:** Motorola MC68000/68010, 10 MHz (dual-processor: DMA + Job)
- **RAM:** 2 MB
- **Bus:** Intel Multibus I
- **OS:** AT&T UNIX System V Release 2 (`UNIX/1.2: Sys5.2r8`)
- **Boot ROM:** 64KB across U15/U17, dated June 4, 1985
- **Disk:** OMTI 5200 SCSI-to-MFM, 10 heads x 753 cylinders x 17 spt
- **Kernel:** `/unix`, 180,208 bytes, dated Nov 27 1985

## Repository Contents

### Documentation (`docs/`)

| File | Description |
|------|-------------|
| `docs/boot_loader.md` | Complete U15 boot loader analysis — command parser, filesystem, a.out loader, SCSI driver |
| `docs/filesystem.md` | Detailed s5fs filesystem implementation from ROM disassembly |
| `docs/debug_monitor.md` | U17 debug monitor — all commands, memory layout, SCSI operations |
| `docs/disk_contents.md` | Complete catalog of all 4,584 files across rootfs and stocku partitions |
| `docs/registers.md` | Hardware register map — memory-mapped I/O addresses |
| `docs/ROM_boot_menu.md` | Boot ROM menu interface and commands |
| `docs/ROM_debug.md` | ROM debug monitor details |
| `docs/Jumper List Mainboard.md` | Mainboard jumper configuration reference |

### ROM Analysis

| File | Description |
|------|-------------|
| `ROM_analysis.md` | Function-by-function ROM analysis with full hardware context and cross-references |
| `U15_disasm.txt` | Raw MC68000 disassembly of U15 boot loader ROM |
| `U17_disasm.txt` | Raw MC68000 disassembly of U17 self-test/debug ROM |
### Tools

| File | Description |
|------|-------------|
| `identify_functions.py` | Parses m68k objdump output to identify function boundaries |
| `s5fs_tool.py` | Read/write tool for AT&T System V s5fs filesystem disk images — list, extract, cat, create, mkdir, rm |

### Extracted Source Code (`extracted-source/`)

All source code, shell scripts, headers, and configuration files extracted from the disk image, preserving original directory structure. 820 files total.

```
extracted-source/
  rootfs/              # Main filesystem (521 files)
    .profile, .cshrc, .login
    etc/               # Shell scripts & configs (passwd, rc, inittab, etc.)
    root/              # root home directory profiles
    usr/src/           # Kernel source, LP source, VPM source, build scripts
    usr/include/       # 293 C headers (full sys/ tree)
    usr/lib/           # acct/, cron/, sa/, spell/, uucp/ scripts
    usr/spool/         # lp/model/ printer scripts, cron/crontabs/
    usr/local/         # SCCS scripts, 20-20 CAD configs
  stocku/              # Recovery partition (299 files)
    etc/               # Shell scripts & configs
    usr/src/           # Kernel config source (conf.c, low.s, rlow.s)
    usr/include/       # 218 C headers
    usr/lib/           # acct/, ctrace/, printer models
```

Key files of interest:
- `extracted-source/rootfs/usr/src/:mkuts68` — Kernel build script (supports Lundell/P20, Robin/P35, Pirate, Schroeder variants)
- `extracted-source/stocku/usr/src/uts/m68/cf/conf.c` — Kernel device configuration
- `extracted-source/stocku/usr/src/uts/m68/cf/low.s` — MC68000 interrupt vectors (Lundell/P20)
- `extracted-source/stocku/usr/src/uts/m68/cf/rlow.s` — MC68010 interrupt vectors (Robin/P35)
- `extracted-source/rootfs/etc/passwd` — User accounts
- `extracted-source/rootfs/etc/rc` — System boot script

## Machine Variants

The kernel build system supports four Plexus models:
- **Lundell** (P/20) — MC68000, USART console, Multibus I/O
- **Robin** (P/35) — MC68010, SCSI, onboard serial ports
- **Pirate** — variant
- **Schroeder** — variant

## How the Analysis Was Done

1. ROM binaries were disassembled with `m68k-linux-gnu-objdump`
2. `identify_functions.py` parsed the disassembly to find function boundaries
3. Functions were sent to local LLMs with full hardware context for analysis
4. Results were compiled into the ROM analysis documents
5. Disk image contents were extracted and cataloged from the original tar archives
