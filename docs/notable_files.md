# Notable Files on the Plexus P/20

A curated guide to the most interesting and unusual files found on this 1985 Plexus P/20 running AT&T UNIX System V Release 2. Beyond the standard System V distribution, this disk reveals a working multi-user office system with commercial software, cross-development tools, networking, and clever sysadmin tricks.

## Commercial Software

### 20/20 Spreadsheet (Access Technology, Inc.)

`/usr/local/20-20/` — A full-featured spreadsheet and graphics application by Access Technology of South Natick, Massachusetts (1984-1985). Version 1.3, with plotter support for HP 7475A and 7550A pen plotters, and terminal graphics output on DEC VT125/VT240.

- `2020V13` (366 KB) — Main executable
- `scto2020` — SuperCalc-to-20/20 format converter
- `release.txt` — Technical notes titled "TECHNICAL NOTES FOR 20/20 ON THE PLEXUS P-35 COMPUTER", documenting model sizes up to 200,000 bytes
- `tutor/` — 30 interactive tutorial files
- The binary contains a demo mode (10 columns x 25 rows output limit), suggesting this may be an evaluation copy

### Q-Office Plus Suite

`/usr/qlib/` — 349 files comprising an integrated office suite. Copyright 1983-1985, registered as serial # "demo" on CPU # 3000, December 6, 1985. Developer initials in binaries (`lrl`, `tjf`, `dpf`, `MH`) suggest a small team.

Modules include word processing (`Qone`), spreadsheet (`Qmath`), calendar/scheduling (`Qsched1`), email (`Qmailx`/`Qmaild`), database (`Qdbreorg`/`Qrec`), drawing (`Qdraw`), spell checking via Proximity v5.3 engine (`Qspell`), and file encryption (`Qcrypt`). Comes with printer drivers for 40+ printers (HP LaserJet, Epson FX-80, NEC Spinwriter, Diablo 630, etc.) and terminal key mappings for 30+ terminals.

Root's `.cshrc` has `alias q 'Qoffice'` — Q-Office was one keystroke away.

## Z8000 Cross-Development Toolchain

`/usr/bin/zcc`, `zas`, `zld`, `zar`, `znm` + `/lib/zccom`, `zcpp`, `zc2` + `/lib/libzc.a`, `libzm.a`

A complete cross-compiler toolchain targeting the Zilog Z8000 processor, used to build firmware for the ICP (Intelligent Communications Processor) boards — the Multibus cards that provide serial I/O. The compiler is an older PCC variant (`PCC/3.0r1`) compared to the native MC68000 compiler (`PCC 6.0`).

The ICP boards run their own Z8000 RTOS with a scheduler, sleep/wakeup, DMA, timers, serial I/O, and a VPM (Virtual Protocol Machine) interpreter for protocol handling. The full build pipeline compiles VPM protocol scripts through ratfor, Z8000 assembly, and links 35+ object files into downloadable firmware.

## The "off" Account — Auto-Shutdown Login

`/etc/passwd` contains: `off:x:0:3::/etc/gone:/bin/sh`

The `off` account has home directory `/etc/gone`, whose `.profile` runs `cd /; shutdown 0`. Logging in as `off` immediately shuts down the system — an elegant trick for operators who need to power down without remembering shutdown commands.

## ICP/ACP Firmware

`/usr/lib/dnld/` — Binary firmware images downloaded to I/O coprocessor boards at boot:
- `icp`, `icp.new`, `icp.old` — Three generations of ICP firmware
- `acp` (45 KB) — ACP firmware identifying as `ACP5 R1.5A`
- `rker` (10 KB) — RKer protocol firmware, loaded on every boot via `/etc/rc`
- `imsc` (42 KB) — IMSC firmware

The boot script `/etc/rc` downloads firmware with: `/etc/dnld -dr -L -f /usr/lib/dnld/rker -o /dev/rk -a c00400`

## Undocumented Machine Variant: P/60

`/usr/lib/libx.a` contains objects prefixed `P60` (`P60dk.o`, `P60init.o`, `P60mapdata.o`, `P60mt.o`, `P60tty.o`, etc.). This reveals a previously undocumented Plexus model — possibly a "P/60" — not mentioned in any other documentation or the kernel build script. The library is 199 KB, roughly the same size as the Robin (P/35) and Schroeder variant libraries.

## Networking Stack

### PlexusNet / NOS

When compiled with `-DNOS`, the kernel gains Ethernet, a Network Control Facility, virtual terminals, and DFS (Distributed File System). Configuration in `/usr/lib/nos/`. Headers in `sys/x25*.h` and `sys/bx25*.h` reveal extensive X.25 packet-switching support.

### VPM Protocol Engine

`/usr/bin/vpmc` — A custom compiler for VPM (Virtual Protocol Machine) scripts. VPM runs on the ICP Z8000 coprocessors and supports BSC (IBM mainframe connectivity) and HDLC (X.25) protocols. The build pipeline goes: VPM script -> ratfor -> Z8000 assembly -> linked firmware.

### Usenet News (B-News 2.x)

`/usr/lib/news/` — Complete B-News installation from 1984-1985 with `inews` (v2.44), `expire` (v2.32), `sendnews`, `recmail`, `compress`, `caesar` (ROT-13 decoder), and `rn` newsreader support. Active newsgroup list last updated June 26, 1985.

## Standalone Boot Utilities

`/stand/` — 13 programs that run without the UNIX kernel, loaded directly by the boot ROM for system recovery: `cat`, `dd`, `du`, `fsck`, `fsdb` (filesystem debugger), `format` (low-level disk format), `mkfs`, `restor`, `ls`, `od`, and `help`.

## Root's Shell Configuration

Root's `.cshrc` reveals daily usage patterns:

```csh
set path = ( . /user/woody/bin /usr/plx /bin /usr/bin /v7/bin /v7/usr/bin
             /usr/games /usr/local/sccs /etc /usr/lib/spell )
```

- PATH includes `/user/woody/bin` — root borrows tools from user "woody"
- `/v7/bin` and `/v7/usr/bin` suggest a Version 7 UNIX compatibility tree existed at some point
- `/usr/games` is in root's PATH
- `alias q 'Qoffice'` — quick launch for Q-Office
- `alias w '/bin/find ~ -name \!* -print'` — find files by name
- `alias sp 'echo \!* | spell'` — quick spell-check from the command line

## The Kernel Build System

`/usr/src/:mkuts68` — The master kernel build script supports four machine variants (Lundell/P20, Robin/P35, Pirate, Schroeder) and user counts of 8, 16, 24, 32, or 64. It auto-detects the current machine from `uname -v`. The actual OS source (scheduler, filesystem, memory management, drivers) ships only as precompiled archives (`lib1`-`lib7`) — consistent with AT&T's proprietary source licensing. Only configuration and link-edit source is provided.

## Writer's Workbench

`/usr/plx/diction`, `explain`, `style`, `style1`, `style2`, `style3` — AT&T's Writer's Workbench text analysis suite. The `style` command computes readability indices (Kincaid, Flesch, Coleman-Liau), sentence statistics, and vocabulary analysis. `diction` flags problematic phrases; `explain` suggests alternatives.

## Games

`/usr/games/` — 20 games including `back` (backgammon), `bj` (blackjack), `craps`, `cribbage`, `fish`, `fortune`, `hangman`, `mastermind`, `maze`, `psych` (Eliza-style chatbot), `quiz` (with 30 topic databases including Tolkien's Middle-earth, Shakespeare, Morse code, and US presidents), `reversi`, `robots`, `trk` (Star Trek), and `wump` (Hunt the Wumpus).

## Optical Disk Support

`/usr/plx/odconf`, `odcreate`, `odctl`, `oddf`, `oddiag`, `odls`, `odrepair`, `odstat` — A complete optical disk management suite supporting cartridge media with side detection, formatting, and repair. Optical disk device nodes (`/dev/od/`, `/dev/rod/`) are present. This was cutting-edge storage technology for 1985.

## Printer Ecosystem

12 printer model scripts in `/usr/spool/lp/model/` supporting DASI 300/450, Fujitsu 320, HP, Printronix, and others. Q-Office adds another 40+ printer drivers. Four printers configured on this system: `noisy`, `ours`, `raw`, and `stark`.

## Key Dates

| Date | Event |
|------|-------|
| 1984 | Earliest file dates (printer models, some utilities) |
| June 4, 1985 | Boot ROM build date ("RD-32 06/04/85") |
| June 26, 1985 | Last Usenet newsgroup list update |
| November 27, 1985 | Kernel binary `/unix` compiled |
| December 6, 1985 | Q-Office registration |
| October 21, 1986 | Latest ICP/ACP firmware |
