# Plexus P/20 Disk Image Contents

Complete catalog and analysis of the Plexus P/20 hard drive image (`plexus-sanitized.img.gz`), containing AT&T UNIX System V Release 2 ported to the Motorola 68000.

## 1. Overview

| Property | Value |
|----------|-------|
| System | Plexus P/20 |
| OS | AT&T UNIX System V Release 2 (`UNIX/1.2: Sys5.2r8`) |
| CPU | Motorola MC68000 |
| RAM | 2 MB (1,794,048 bytes available to UNIX) |
| Disk controller | OMTI 5200 SCSI-to-MFM interposer (SCSI ID 0) |
| Drive geometry | 10 heads, 753 cylinders, 17 sectors/track |
| Sector size | 512 bytes |
| Filesystem block size | 1024 bytes |
| Filesystem type | System V s5fs (1024-byte blocks, `s_magic` = 0xFD187E20, `s_type` unreliable — see below) |
| Kernel | `/unix`, 180,208 bytes, dated Nov 27 1985 |
| MOTD | `PLEXUS SYS5 R1.5A` |
| Timezone | PST8PDT (Pacific) |
| Key dates | Files dated 1984-1986; Q-Office registered Dec 6 1985 |

## 2. Boot Block (Sector 0)

The first 512-byte sector contains the OMTI 5200 interposer configuration and boot parameters. See [`disk/bootblock.md`](../disk/bootblock.md) for the full decoded structure.

| Field | Value |
|-------|-------|
| OMTI heads | 10 |
| OMTI cylinders | 753 |
| OMTI sectors/track | 17 |
| Filesystem block size | 1024 |
| Boot path | `/unix` |
| Root device | partition 1 |
| Swap start | block 58000 |
| Swap size | 8000 blocks |

The boot ROM contains a read-only s5fs implementation that resolves `/unix` through the directory tree, loads the a.out executable, and transfers control to the Job processor. See [`docs/filesystem.md`](filesystem.md) for the complete filesystem implementation analysis.

## 3. Partition Layout

All values in 512-byte physical blocks:

| Slice | Device | Start | Length | Mount | Filesystem | Files | Used Blocks | Free |
|-------|--------|-------|--------|-------|------------|-------|-------------|------|
| 0s0 | `/dev/dsk/0s0` | 0 | entire | *(whole disk)* | — | — | — | — |
| 0s1 | `/dev/dsk/0s1` | 0 | 66,000 | `/` (rootfs) | root vol 1 | 3,185 | 27,142 | 1,403 |
| 0s2 | `/dev/dsk/0s2` | 66,000 | 34,000 | `/user` | user vol 1 | 82 | 868 | 15,865 |
| 0s3 | `/dev/dsk/0s3` | 100,000 | entire | *(rest of disk)* | — | — | — | — |
| 0s4 | `/dev/dsk/0s4` | 100,000 | 45,000 | `/stocku` | stocku vol 1 | 1,970 | 16,792 | 5,355 |
| swap | — | 58,000 | 8,000 | *(swap)* | — | — | — | — |

The swap region overlaps the end of the rootfs partition (blocks 58,000-66,000). It was apparently never used on this system, and the original `/user` partition data at block 60,000 was preserved, which is how technical documentation about the system was recovered.

The `/user` partition (0s2) was sanitized (PII removed) and is nearly empty (82 files, 868 blocks used).

**`s_type` field note:** The kernel is compiled with `FsTYPE==2` (1024-byte blocks hardcoded), so the superblock `s_type` field is never checked at runtime. The rootfs and `/user` have `s_type=1` despite using 1024-byte blocks — their `mkfs` did not set this field correctly. The `/stocku` partition has the correct `s_type=2`. Always use `s_magic` (0xFD187E20) for validation and assume 1024-byte blocks.

## 4. Rootfs (/) — The Running System

**2,852 files** extracted from the rootfs partition. This is the live, customized system as it was running on the actual Plexus P/20.

### 4.1. Kernel (`/unix`)

- **Size:** 180,208 bytes
- **Date:** Nov 27, 1985
- **Format:** Motorola 68000 a.out (magic 0x0108 or 0x0150)
- **Identifies as:** `UNIX/1.2: Sys5.2r8`
- **Memory:** 2 MB physical, 1,794,048 available
- **Root device:** `makedev(0,1)` — block device 0 (OMTI disk), partition 1
- **Swap:** block 58,000, 8,000 blocks (but apparently unused)

### 4.2. `/bin/` — Essential System Commands (90 files)

**File management:** `cat`, `cp`, `ln`, `ls`, `ll`, `lx`, `mkdir`, `mv`, `rm`, `rmdir`, `chmod`, `chgrp`, `chown`, `find`, `cmp`, `diff`, `du`, `df`, `touch`, `file`

**Text processing:** `ed`, `red`, `sed`, `grep`, `sort`, `wc`, `pr`, `echo`, `tail`, `tee`, `od`, `dump`

**Process management:** `kill`, `ps`, `nice`, `nohup`, `sleep`, `time`, `who`, `tty`, `mesg`

**User management:** `login`, `newgrp`, `passwd`, `su`, `write`

**Shell and scripting:** `sh`, `rsh`, `env`, `expr`, `basename`, `dirname`, `line`, `true`, `false`, `date`, `uname`

**Development tools:** `ar`, `as`, `cc`, `bigcc`, `ld`, `nm`, `size`, `strip`, `make`, `lorder`, `adb`, `bs`

**System administration:** `cpio`, `dd`, `sum`, `sync`, `stty_old`, `telinit`, `df`

**IPC:** `ipcrm`, `ipcs`

**Encryption:** `crypt`

**Mail:** `mail`, `rmail`

**Architecture test stubs:** `m68`, `n16`, `ns32000`, `pdp11`, `u370`, `u3b`, `u3b5`, `vax`, `z8000` — shell scripts that return true/false based on the current architecture. `m68` returns true on this system.

**LP printing:** `lpwb`

**Accounting:** `acctcom`

### 4.3. `/etc/` — System Configuration

#### 4.3.1. Boot and Init

**`/etc/inittab`** — System initialization table:
```
is:s:initdefault:                          # Default: single-user
bl::bootwait:/etc/bcheckrc                 # Filesystem check on boot
bc::bootwait:/etc/brc                      # Remove stale mnttab
rc::wait:/etc/rc                           # Run commands
pf::powerfail:/etc/powerfail               # Power fail handler
co::respawn:/etc/getty console console     # Console (always active)
01:2:respawn:/etc/getty /dev/tty1 9600     # Serial port 1 (run level 2)
02:2:respawn:/etc/getty /dev/tty2 9600     # Serial port 2 (run level 2)
03:2:off:/etc/getty /dev/tty3 9600         # Ports 3-7 disabled
04:2:off:/etc/getty /dev/tty4 1200
05-07:2:off:/etc/getty /dev/ttyN 9600
```

**`/etc/inittab.mstr`** — Master inittab template (all 7 ttys enabled at 9600 baud). The `ttyconf` script generates `inittab` from this template.

**`/etc/bcheckrc`** — Boot check script: prompts for date confirmation, optionally runs `fsck`.

**`/etc/brc`** — Boot run command: removes stale `/etc/mnttab`.

**`/etc/rc`** — Run command script:
- **Run level S/1:** Unmounts `/user`
- **Run level 2:** Mounts `/dev/dsk/0s2` on `/user`, cleans `/tmp`, starts cron, downloads ICP firmware (`/etc/dnld -dr -L -f /usr/lib/dnld/rker -o /dev/rk -a c00400`), starts LP scheduler

**`/etc/powerfail`** — Power failure handler (minimal: echoes message, runs `uname`).

**`/etc/shutdown`** — Graceful shutdown: warns users via `wall`, kills processes, unmounts filesystems, syncs.

#### 4.3.2. User Accounts

**`/etc/passwd`** — 20 accounts:

| Username | UID | GID | Home | Shell | Notes |
|----------|-----|-----|------|-------|-------|
| `root` | 0 | 3 | `/` | `/bin/sh` | System administrator |
| `here` | 0 | 3 | `/root` | `/bin/sh` | Alternate root login |
| `csh` | 0 | 3 | `/` | `/usr/plx/csh` | Root with C shell |
| `off` | 0 | 3 | `/etc/gone` | `/bin/sh` | Auto-shutdown account (see below) |
| `daemon` | 1 | 12 | `/` | — | System daemon |
| `bin` | 2 | 2 | `/bin` | — | Binary owner |
| `sys` | 3 | 3 | `/usr/src` | — | System files owner |
| `adm` | 4 | 4 | `/usr/adm` | — | Accounting |
| `uucp` | 5 | 1 | `/usr/lib/uucp` | — | UUCP admin |
| `nuucp` | 6 | 1 | `/usr/spool/uucppublic` | `uucico` | UUCP incoming |
| `sync` | 20 | 1 | `/` | `/bin/sync` | Sync-and-exit |
| `lp` | 71 | 2 | `/usr/spool/lp` | — | Line printer |
| `woody` | 112 | 100 | `/user/woody` | `/usr/plx/csh` | User account |
| `work` | 112 | 100 | `/user/work` | `/usr/plx/csh` | Shared UID with woody |
| `ed` | 113 | 110 | `/user/ed` | `/usr/plx/csh` | User account |
| `lac` | 114 | 110 | `/user/lac` | `/usr/plx/csh` | User account |
| `guest` | 115 | 110 | `/user/guest` | `/usr/plx/csh` | Guest (no password) |
| `jan` | 116 | 100 | `/user/jan` | `/usr/plx/csh` | User account |
| `colleen` | 117 | 100 | `/user/colleen` | `/usr/plx/csh` | No password |
| `bob` | 118 | 100 | `/user/bob` | `/usr/plx/csh` | No password |
| `jim` | 120 | 100 | `/user/jim` | `/usr/plx/csh` | User account |

The `off` account has home `/etc/gone` whose `.profile` does `cd /; shutdown 0` — logging in as `off` immediately shuts down the system.

All regular users default to `/usr/plx/csh` (BSD C shell), not `/bin/sh`.

**`/etc/group`** — 9 groups:

| Group | GID | Members |
|-------|-----|---------|
| root | 0 | root |
| other | 1 | — |
| bin | 2 | root, bin, daemon |
| sys | 3 | root, bin, sys, adm |
| adm | 4 | root, adm, daemon |
| mail | 6 | root |
| rje | 8 | rje, shqer |
| daemon | 12 | root, daemon |

#### 4.3.3. Terminal Configuration

**`/etc/gettydefs`** — Terminal line speed definitions:

| Label | Speed | Notes |
|-------|-------|-------|
| `console` | 9600 | Console login prompt |
| `9600` | 9600 | Standard terminal |
| `1200` | 1200 | Modem speed |
| `300` | 300 | Low-speed modem |
| `4800` | 4800 | — |
| `38400` | 38400 | High-speed |
| `lp` | 9600 | Line printer port (IXOFF flow control) |
| `1234` | 300 | 7-bit, CLOCAL |

**`/etc/termcap`** — 33 KB terminal capabilities database.

#### 4.3.4. Filesystem and Devices

**`/etc/checklist`** — Filesystems to check on boot:
```
/dev/rdsk/0s2
/dev/dsk/0s1
```

**`/etc/TIMEZONE`** — `TZ=PST8PDT`

**`/etc/motd`** — `PLEXUS SYS5 R1.5A`

**`/etc/master`** — Device driver master table. Defines all supported device drivers with major numbers, flags, and handler function prefixes. Key entries:

| Device | Type | Major | Handler | Description |
|--------|------|-------|---------|-------------|
| con | char | 0 | con | Console |
| tty | char | 2 | sy | Controlling terminal |
| memory | char | 3 | mm | Physical memory access |
| disk | block | 0 (blk), 4 (chr) | gd | Generic disk (OMTI/SCSI) |
| vpm | char | 15 | vpm | Virtual Protocol Machine |
| trace | char | 16 | tr | Protocol trace |
| csi | char | 17 | csi | Communications subsystem |
| prf | char | 25 | prf | Kernel profiler |
| st | char | 30 | st | Serial/tty (ICP) |
| stc | char | 35 | stc | Serial control |
| fault | char | 13 | xx | Fault handler |

Also defines tunable parameters: NBUF, NINODE (200), NFILE (175), NMOUNT (13), NPROC (100 max, limit 255), NTEXT (40), NCLIST (20), MAXUP (25), NHBUF (64), and IPC tunables (messages, semaphores, shared memory).

#### 4.3.5. Other /etc Files

| File | Purpose |
|------|---------|
| `acpconf` | ACP (Auxiliary Communications Processor) device configuration script |
| `checkall` | Parallel filesystem check script |
| `cshprofile` | C shell login profile (shows motd, checks mail) |
| `errstop` | Stops the error logging daemon |
| `filesave` | Disk-to-disk backup script using `volcopy` |
| `tapesave` | Filesystem-to-tape backup script |
| `ttyconf` | ICP/ACP tty device node and inittab generator |
| `vpmstart` | VPM firmware download script (`dnld -d -f "$filen" -o "$1" -a 4000`) |
| `vpmstarta` | Duplicate of vpmstart |
| `vpmsnap` | VPM state snapshot utility (binary) |
| `vpmtrace` | VPM protocol trace utility (binary) |
| `printcap` | Printer capability definitions (lp, vp, qp, pp) |
| `magic` | File type identification magic numbers |
| `mvdir` | Directory rename script using link/unlink |
| `ioctl.syscon` | Saved console terminal settings |
| `gone/.profile` | Auto-shutdown profile for the `off` account |

**Binary utilities in `/etc/`:** `ccal`, `chroot`, `clri`, `crash`, `cron`, `dcopy`, `devnm`, `dfsck`, `dmkset`, `dnld`, `dump`, `eccdaemon`, `errdead`, `fbkup`, `ff`, `finc`, `format`, `frec`, `fsck`, `fsck1b`, `fscv`, `fsdb`, `fsdb1b`, `fuser`, `getty`, `grpck`, `icpdmp`, `acpdmp`, `init`, `killall`, `labelit`, `link`, `mirutil`, `mkfs`, `mknod`, `mount`, `ncheck`, `openup`, `prfdc`, `prfld`, `prfpr`, `prfsnap`, `prfstat`, `pwck`, `restor`, `setmnt`, `umount`, `unlink`, `volcopy`, `wall`, `whodo`

### 4.4. `/lib/` — Compiler Toolchain (37 files)

**C compiler passes:**

| File | Purpose |
|------|---------|
| `cpp` | C preprocessor |
| `ccom` | C compiler (code generator) |
| `c2` | Optimizer |
| `bigcpp` | Large-model preprocessor |
| `bigccom` | Large-model compiler |
| `nccom` | New C compiler |
| `occom` | Old C compiler |

**Cross-compiler passes (Z8000 target):**

| File | Purpose |
|------|---------|
| `zcpp` | Z8000 cross-preprocessor |
| `zccom` | Z8000 cross-compiler |
| `zc2` | Z8000 cross-optimizer |
| `zcrt0.o` | Z8000 C runtime startup |

**Cross-compiler passes (other targets):**

| File | Purpose |
|------|---------|
| `tcpp` | Target cross-preprocessor |
| `tccom` | Target cross-compiler |
| `tc2` | Target cross-optimizer |

**C runtime objects:**

| File | Purpose |
|------|---------|
| `crt0.o` | Standard C runtime startup |
| `crt2.o` | Alternate model startup |
| `crt3.o` | Alternate model startup |
| `crtj.o` | Job processor model |
| `crtr.o` | Relocatable model |
| `crts.o` | Shared library model |
| `mcrt0.o` | Profiling runtime startup |

**Libraries:**

| Library | Purpose |
|---------|---------|
| `libc.a` | Standard C library |
| `libc.a.sav` | Backup of libc |
| `libm.a` | Math library |
| `libPW.a` | Programmer's Workbench library |
| `libld.a` | Link editor library |
| `libg.a` | Debug library |
| `libzc.a` | Z8000 cross C library |
| `libzm.a` | Z8000 cross math library |
| `libtc.a`, `libtg.a`, `libtm.a` | Target cross-libraries |
| `libp/libc.a` | Profiling C library |
| `libp/libm.a` | Profiling math library |
| `libp/libmalloc.a` | Profiling malloc library |

**Protocol objects:** `cslapb.o`, `cslapb.kms` (LAPB protocol), `dial.o` (dialer)

### 4.5. `/stand/` — Standalone Boot Utilities (13 files)

These are standalone programs that run without the UNIX kernel, loaded directly by the boot ROM for system recovery:

| File | Purpose |
|------|---------|
| `cat` | Display files |
| `ccal` | Checksum calculator |
| `dd` | Disk copy |
| `du` | Disk usage |
| `fbkup` | Full backup |
| `format` | Low-level disk format |
| `fsck` | Filesystem check |
| `fsdb` | Filesystem debugger |
| `help` | Help text |
| `ls` | List files |
| `mkfs` | Create filesystem |
| `od` | Octal dump |
| `restor` | Restore from backup |

### 4.6. `/dev/` — Device Nodes

Device node directories preserved in the archive (actual mknod entries not preserved by tar):

| Path | Purpose |
|------|---------|
| `/dev/dsk/` | Block disk devices (`0s0`-`0s4`) |
| `/dev/rdsk/` | Raw (character) disk devices |
| `/dev/rmt/` | Raw magnetic tape |
| `/dev/od/` | Optical disk (block) |
| `/dev/rod/` | Raw optical disk |
| `/dev/ram/` | RAM disk (block) |
| `/dev/rram/` | Raw RAM disk |
| `/dev/rfp/` | Raw floppy |
| `/dev/rft/` | Raw formatted tape |
| `/dev/rpt/` | Raw Pertec tape |
| `/dev/crm/` | Character raw memory |
| `/dev/rrm/` | Raw removable media |

Key device major/minor numbers (from `/etc/master` and `conf.c`):

| Device | Major (blk) | Major (chr) | Description |
|--------|-------------|-------------|-------------|
| disk (dk/gd) | 0 | 3 | OMTI/SCSI generic disk |
| tape (mt/rm) | 5 | 8 | Magnetic tape |
| console (con) | — | 0 | USART console |
| memory (mm) | — | 2 | `/dev/mem`, `/dev/kmem`, `/dev/null` |
| tty (sy) | — | 13 | Controlling terminal |
| ICP (ic) | — | 14 | ICP board control |
| serial (sp) | — | 15 | ICP serial ports |
| parallel (pp) | — | 16 | ICP parallel ports |
| VPM (vpm) | — | 18 | Virtual Protocol Machine |
| trace (tr) | — | 19 | Protocol tracing |
| error log (err) | — | 20 | Error logging |
| profiler (prf) | — | 21 | Kernel profiler |
| floppy (fp) | 8 (Robin) | 26 | Floppy disk |
| tape (6,0) | — | 6 | `/dev/tape` → `/dev/rmt/0m` |
| floppy (26,0) | — | 26 | `/dev/floppy` → `/dev/0m` |

### 4.7. `/usr/bin/` — Extended Commands (168 files)

**Text processing:** `awk`, `cut`, `paste`, `join`, `comm`, `uniq`, `tr`, `nl`, `newform`, `csplit`, `split`, `col`, `sdiff`, `bdiff`, `diff3`, `diffmk`, `dircmp`, `pg`

**Document formatting:** `nroff`, `troff`, `otroff`, `sroff`, `tbl`, `eqn`, `neqn`, `pic`, `mm`, `mmt`, `mvt`, `checkmm`, `mmlint`, `macref`, `ptx`, `deroff`, `hyphen`, `osdd`

**Printer output filters:** `300` (DASI 300), `4014` (Tektronix), `450` (DASI 450), `daps` (Autologic APS-5), `di10` (Diablo), `dx9700` (Xerox 9700), `hp` (HP), `s2020` (Savin), `graph`, `spline`, `tplot`

**Source Code Control (SCCS):** `admin`, `cdc`, `comb`, `delta`, `get`, `prs`, `rmdel`, `sact`, `sccsdiff`, `unget`, `val`, `what`

**C development:** `cb` (beautifier), `cflow`, `ctrace`, `cxref`, `lint`, `regcmp`, `lex`, `yacc`, `m4`

**Programming languages:** `bc`, `dc`, `efl` (Extended Fortran), `ratfor`, `sno` (SNOBOL)

**Communication:** `cu`, `ct`, `uucp`, `uux`, `uulog`, `uuname`, `uupick`, `uustat`, `uuto`, `net`, `vpmc` (VPM compiler), `vtcmp`

**Q-Office suite (36 binaries):** `Q1`, `QTinit`, `Qconv`, `Qcrypt`, `Qdbreorg`, `Qdglos`, `Qdraw`, `Qfixfmt`, `Qfortune`, `Qglos`, `Qhy`, `Qimagen`, `Qindex`, `Qinstall`, `Qmaild`, `Qmailx`, `Qmath`, `Qmenu`, `Qndxgen`, `Qoffice`, `Qone`, `Qplock`, `Qprint`, `Qproto`, `Qrec`, `Qsched1`, `Qsetup`, `Qspell`, `Qspool`, `Qtkcomp`, `Qtkinit`, `Qtodif`, `Qwang`

**Z8000 cross-tools:** `zar`, `zas`, `zcc`, `zld`, `znm`, `zsize`, `zstrip` — complete cross-development toolchain for the Z8000 processor (used in ICP boards)

**Other utilities:** `at`, `batch`, `banner`, `cal`, `calendar`, `cancel`, `crontab`, `enable`, `disable`, `errpt`, `ex`, `vi`, `view`, `vedit`, `edit`, `factor`, `fgrep`, `egrep`, `fsplit`, `gath`, `getopt`, `hpio`, `id`, `logname`, `lp`, `lpforms`, `lphold`, `lprun`, `lpstat`, `mailx`, `man`, `news`, `pack`, `pcat`, `unpack`, `prof`, `sadp`, `sag`, `sar`, `shl` (shell layers), `spell`, `tabs`, `tar`, `tar.wb`, `tic`, `timex`, `tput`, `xargs`

### 4.8. `/usr/lib/` — Libraries and Support (1,115 files)

#### Accounting (`acct/`, 30 files)
Complete System V accounting suite: `acctcms`, `acctcon1`, `acctcon2`, `acctdisk`, `acctdusg`, `acctmerg`, `accton`, `acctprc1`, `acctprc2`, `acctwtmp`, `chargefee`, `ckpacct`, `diskusg`, `dodisk`, `fwtmp`, `holidays`, `lastlogin`, `monacct`, `nulladm`, `prctmp`, `prdaily`, `prtacct`, `ptecms.awk`, `ptelus.awk`, `remove`, `runacct`, `shutacct`, `startup`, `turnacct`, `wtmpfix`

#### Cron (`cron/`)
`at.allow`, `at.deny`, `cron.allow`, `cron.deny`, `queuedefs`, `log`, `.proto`

#### ICP/ACP Firmware Downloads (`dnld/`)

Z8000 binary firmware images loaded into ICP/ACP boards at boot time (via `sadnld` or the `rc` scripts). The ACP firmware identifies as `ACP5 R1.5A`; the ICP firmware prints "Plexus ICP Software Initialization Complete." on successful load.

| File | Size | Date | Purpose |
|------|------|------|---------|
| `icp` | — | 10/21/86 | ICP firmware (primary) |
| `icp.new` | — | 07/24/85 | Updated ICP firmware |
| `icp.old` | — | 07/18/85 | Previous ICP firmware |
| `acp` | 45.3 KB | 10/21/86 | ACP firmware (`@(#) ACP5 R1.5A`) |
| `acp5.syms` | — | — | ACP symbol table |
| `rker` | 10.3 KB | 09/06/85 | RKer protocol firmware (loaded on boot via `rc`) |
| `rker_old` | — | — | Previous RKer firmware |
| `imsc` | 42.4 KB | 06/28/85 | IMSC firmware |

#### LP Scheduler
`accept`, `lpadmin`, `lpd`, `lpdfilter`, `lpfx`, `lpmove`, `lpsched`, `lpshut`, `reject`, `topq`

#### Libraries
| Library | Purpose |
|---------|---------|
| `lib2.a`, `lib2A.a` | Additional system libraries |
| `lib3.a` | Extended library |
| `lib300.a`, `lib300s.a` | DASI 300 terminal |
| `lib4014.a` | Tektronix 4014 |
| `lib450.a` | DASI 450 terminal |
| `libF77.a`, `libI77.a` | Fortran 77 runtime |
| `libcurses.a`, `libcurses3.a` | Curses screen library |
| `libg.a` | Debug |
| `libl.a` | Lex library |
| `libmalloc.a` | Malloc library |
| `libplot.a` | Plot library |
| `libtermlib.a` | Terminal library |
| `libvt0.a` | VT library |
| `liby.a` | Yacc library |
| `libDate.a` | Date handling |
| `libr.a` | Robin (P/35) machine-variant library (`ROBIN*.o` members) |
| `libs.a` | Schroeder machine-variant library (`SCH*.o` members) |
| `libj.a` | Schroeder sub-variant library (`SCH*.o` members) |
| `libx.a` | P/60 variant library (`P60*.o` members — undocumented variant) |

#### Font Data (`font/`)
- `devaps/` — Autologic APS-5 typesetter fonts (55 files, 27 typefaces)
- `devX97.tim10p/`, `devX97.tim12p/` — Xerox 9700 Times Roman fonts (10pt and 12pt)
- Classic `ft*` nroff fonts (28 files)

#### Nroff/Troff Macros (`macros/`, `tmac/`)
- `mmn`, `mmt` — Memorandum Macros (nroff/troff)
- `an` — Manual page macros
- `tmac.an`, `tmac.m`, `tmac.s`, `tmac.v`, `tmac.org`, `tmac.osd`, `tmac.ptx`
- `sroff.mm`, `sroff.addrs`, `sroff.m.rp` — Simple roff macros

#### SCCS Help (`help/`, 15 files)
Online help files for SCCS commands.

#### Spell Checking (`spell/`)
`compress`, `hashcheck`, `hashmake`, `hlista`, `hlistb`, `hstop`, `spellin`, `spellprog`, `spellhist`

#### Terminfo Database (`terminfo/`, 722 entries)
Compiled terminal descriptions for hundreds of terminals including: HP 2621/2622/2623/2626/2640/2644/2645/2648, VT100/VT125/VT132/VT50/VT52, TeleVideo 912/920/925/950, Concept 100/108, ADM 1/2/3/5/21/31/36/42, Wyse 75/100, Ann Arbor Ambassador, Tektronix 4012-4114, IBM 3101, and many more.

#### UUCP (`uucp/`)
| File | Content |
|------|---------|
| `L-devices` | `ACU modem /usr/plx/mdial 300` and `1200` — modem dialer |
| `L.sys` | Example entry only (408-111-1111) |
| `L-dialcodes` | Dial code abbreviations |
| `L.cmds` | Permitted remote commands |
| `USERFILE` | UUCP access control |
| `uucico` | UUCP communication daemon |
| `uuxqt` | UUCP execution daemon |
| `uuclean` | UUCP spool cleanup |

#### Usenet News (`news/`, 30+ files)
Complete Usenet B-News 2.x installation with SCCS version tags from the binaries:

| Binary | SCCS Version | Date | Purpose |
|--------|-------------|------|---------|
| `inews` | `inews.c v2.44` | 09/03/84 | Inject news articles |
| `expire` | `expire.c v2.32` | 09/12/84 | Expire old articles |
| `recmail` | `recmail.c v1.9` | 09/17/84 | Receive mail as news |
| `sendnews` | `sendnews.c v2.9` | 09/17/84 | Send news to peers |
| `compress` | `compress.c v1.6` | 09/12/84 | Compress batched news |
| `caesar` | `caesar.c v1.5` | 08/14/84 | ROT-13 decoder |
| `batch` | — | 06/24/85 | Batch news for UUCP |

Also includes: `recnews`, `sendbatch`, `uurec`, `vnews.help`, and `rn/` newsreader support files. Configuration: `active` (newsgroup list, last updated 06/26/85), `sys`, `distributions`, `aliases`, `history`.

#### NOS / Networking (`nos/`)
`D-hosts`, `vtconf` — PlexusNet virtual terminal configuration.

#### VPM (`vpm/`)
`pass0`, `pass1`, `pass1a`, `pass2`, `pl`, `vratfor` — VPM compiler passes and ratfor translator.

#### Mail (`mailx/`)
`mailx.help`, `mailx.rc`, `plxmail`, `plxmap`, `oplxmap`, `rmmail`

#### System Activity (`sa/`)
`sa1`, `sa2`, `sadc` — System activity data collection.

### 4.9. `/usr/plx/` — Plexus-Specific Tools (43 files)

These are Plexus additions to the standard System V distribution, a mix of BSD ports, AT&T Writer's Workbench components, and Plexus-proprietary utilities.

**BSD-derived utilities:** Ported from 4.1 BSD with original SCCS version tags preserved:
- `more` (`@(#)more.c 4.1`, Berkeley 10/16/80) — page-at-a-time file viewer
- `ctags` (`@(#)ctags.c 4.3`, Berkeley 11/24/80) — C function tag indexer
- `csh` — C shell
- `head`, `strings`, `printenv`, `script`, `tset` — standard BSD utilities
- `mkstr`, `xstr` — string extraction tools for C programs

**File utilities:** `bar` (Berkeley archive), `bls` (Berkeley ls with `-F` flags), `bbanner` (big banner)

**Optical disk tools:** `odconf`, `odcreate`, `odctl`, `oddf`, `oddiag`, `odls`, `odrepair`, `odstat` — complete optical disk management suite supporting optical cartridge media with media side detection, formatting, and repair

**Tape utilities:** `copytape`, `dumpdir`, `tape`

**Communication:** `dial`, `mdial` (modem dialer, used by UUCP), `uuencode`, `uudecode`

**Writer's Workbench:** `diction`, `explain`, `style`, `style1`, `style2`, `style3` — AT&T Writer's Workbench text analysis pipeline. The `style` command runs text through `deroff` then a three-stage pipeline (`style1` → `style2` → `style3`) computing readability indices (Kincaid, Flesch, Coleman-Liau), sentence statistics, and vocabulary analysis. `diction` flags problematic phrases; `explain` provides alternatives.

**Assembly:** `las`, `mas` — alternate/variant MC68000 assemblers

**Other:** `clear` (clear screen), `dprog`, `mconv`, `ramdisk` (RAM disk management), `sadnld` (firmware download), `wbs` (wide block structure directory listing)

### 4.10. `/usr/qlib/` — Q-Office Plus Suite (349 files)

Q-Office Plus is a comprehensive integrated office suite bundled with the Plexus. Copyright (c) 1983, 1984, 1985 (vendor name not embedded in binaries). Registered as serial # "demo" on CPU # 3000, December 6, 1985.

The suite consists of independently versioned modules, mostly at v1.92–1.94 (mid-1985). Developer initials in binaries (`lrl`, `tjf`, `dpf`, `MH`) suggest a small team. The `Qspell` module uses the Proximity v5.3 spell-checking engine (USA version).

#### Modules

| Module | Binary | Version | Date | Description |
|--------|--------|---------|------|-------------|
| Main Menu | `Qoffice` | — | — | Application launcher (QOFFICE PLUS) |
| Word Processing | `Qone` | 1.9u | 07/13/84 | Full-featured WP with formatting, spell check, mail merge |
| Spreadsheet | `Qmath` | 1.94 | 07/01/85 | Arithmetic/spreadsheet with formulas, memory, print |
| Calendar | `Qsched1` | — | — | Appointment scheduling, alarms, holidays |
| Mail | `Qmailx` | 1.92 | 03/25/85 | Electronic mail with folders and aliases |
| Mail Daemon | `Qmaild` | 1.92a | 05/15/85 | Mail delivery daemon |
| Database | `Qdbreorg` | 1.92 | — | Database reorganization |
| Records | `Qrec` | 1.92 | — | Record management with indexing |
| Drawing | `Qdraw` | 1.94 | 06/27/85 | Character-mode drawing tool |
| Printing | `Qprint` | 1.94 | 06/28/85 | Print management with 40+ printer drivers |
| Spooling | `Qspool` | 1.94 | 06/27/85 | Print job spooling |
| Indexing | `Qindex` | 1.92 | 01/01/85 | Index and report generation |
| Index Gen | `Qndxgen` | — | — | Index file generator |
| Forms | `Qproto` | 1.9a | 04/19/84 | Forms design and entry |
| Glossary | `Qglos`, `Qdglos` | — | — | Text glossary/abbreviation expansion |
| Spelling | `Qspell` | 1.94 | 07/02/85 | Spell checker (Proximity v5.3 engine) |
| Hyphenation | `Qhy` | 1.7c | 03/15/84 | Hyphenation engine |
| Terminal Cfg | `Qtkcomp` | 1.94 | 06/27/85 | Terminal capability compiler |
| Conversion | `Qconv` | — | — | File format transfer/conversion |
| Encryption | `Qcrypt` | — | — | File encryption |

#### Support Files

**`/usr/qlib/files/`** (148 files):
- Printer drivers (`.pc` files) for 40+ printers: HP LaserJet, NEC Spinwriter, Epson FX-80, Imagen, Fujitsu, Diablo 630, Centronics, Printronix, Minolta, Qume Sprint
- Terminal key compilations (`.tkc` files) for 30+ terminals: VT100, VT200, VT220, Wyse 50/75/85/100, TeleVideo 925/970, ADM-12, Freedom 200, Sun, Tektronix 4105
- Language files (`*.eng`) for all modules
- Configuration: `Qmail.cfg`, hyphenation dictionary (`english.hy`)

**`/usr/qlib/help/`** (177 files): Online help covering all modules — word processing (60+ help files), mail (40+), calendar, spreadsheet, forms, drawing.

**`/usr/qlib/menus/`** (76 files): Menu definitions for the hierarchical menu system.

**`/usr/qlib/demo/`** (49 files): Sample documents, databases, form letters, spreadsheets, mail merge examples.

**`/usr/qlib/install/`** (86 files): Terminal keyboard/translation file pairs, printer configs, platform-specific `mconfig` variants (BSD, System III, System V, V7, Xenix).

### 4.11. `/usr/local/` — Locally Installed Software

#### 20/20 Spreadsheet (Access Technology, Inc.)

`/usr/local/20-20/` — A full-featured spreadsheet and graphics application by Access Technology, Inc. of South Natick, Massachusetts. Copyright 1984, 1985.

| File | Size | Description |
|------|------|-------------|
| `2020V13` | 366,202 | Main executable (version 1.3, MC68000 COFF) |
| `s2020` | 629 | Shell wrapper script (sets SuTERM, SuTFIL, SuMEMR, etc.) |
| `scto2020` | 21,862 | SuperCalc-to-20/20 format converter |
| `tfil` | 66,553 | Terminal definition database |
| `hfil` | 128,000 | Online help text |
| `hfilidx` | 2,007 | Help file index |
| `setport` | 188 | Plotter port configuration script |
| `release.txt` | 41,680 | Technical release notes |
| `tutor/` | ~30 files | Interactive tutorial (`.tmf` model files, `.tut` tutorial scripts) |

The release notes are titled "TECHNICAL NOTES FOR 20/20 ON THE PLEXUS P-35 COMPUTER" and document Version 1.1 features including HP 7475A 6-pen and 7550A 8-pen plotter support, DEC VT125/VT240 terminal graphics output via LA-50/LA-100 printers, and model sizes up to 200,000 bytes. The `s2020` wrapper defaults to `SuMEMR=100000` (100K model limit) on this P/20 system. The binary contains a demo mode with output limits of 10 columns × 25 rows, suggesting this may be an evaluation copy.

#### SCCS Front-End Scripts

`/usr/local/sccs/` — A wrapper layer around the standard SCCS commands providing multi-user administrative workflows. Includes `admins`, `deltas`, `gets` (compiled binaries), shell scripts for directory management (`chkdir`, `initdir`, `lsdir`, `crsrcdir`), and a `cheat.sheet` quick-reference. All files dated March 19, 1985.

### 4.12. `/usr/include/` — Header Files (203 files)

#### Standard C Headers
`a.out.h`, `ar.h`, `assert.h`, `ctype.h`, `curses.h`, `errno.h`, `fcntl.h`, `grp.h`, `math.h`, `memory.h`, `malloc.h`, `nan.h`, `nlist.h`, `pwd.h`, `regexp.h`, `search.h`, `setjmp.h`, `sgtty.h`, `signal.h`, `stdio.h`, `string.h`, `time.h`, `utmp.h`, `values.h`, `varargs.h`

#### COFF Object Format
`aouthdr.h`, `filehdr.h`, `linenum.h`, `reloc.h`, `scnhdr.h`, `storclass.h`, `syms.h`, `ldfcn.h`

#### System Headers (`sys/`, 103 files)
Core kernel: `param.h`, `types.h`, `sysmacros.h`, `systm.h`, `proc.h`, `user.h`, `inode.h`, `file.h`, `buf.h`, `conf.h`, `dir.h`, `filsys.h`, `ino.h`, `mount.h`, `signal.h`, `stat.h`, `termio.h`, `tty.h`, `var.h`, `map.h`, `seg.h`, `page.h`, `reg.h`, `trap.h`, `errno.h`

IPC: `ipc.h`, `msg.h`, `sem.h`, `shm.h`

Plexus-specific: `plexus.h`, `plxmap.h`, `plxparam.h`, `m68.h`, `io.h`, `iopage.h`, `peri.h`, `disk.h`, `gdisk.h`, `sc.h`, `od.h`, `ramdsk.h`, `mi.h`, `ecc.h`, `mc146818.h` (RTC), `clock.h`

Networking: `vp.h`, `vpm.h`, `vpmd.h`, `vpmt.h`, `vpr.h`, `remote.h`, `nc.h`, `nsc.h`, `nscdev.h`, `x25*.h` (6 files), `bx25*.h` (10 files), `pcl.h`, `lapbtr.h`, `hdlcsys.h`

Serial/terminal: `cons.h`, `usart.h`, `sio68564.h`, `st.h`, `stermio.h`, `ttold.h`, `sxt.h`, `crtctl.h`, `scropts.h`

Miscellaneous: `acct.h`, `callo.h`, `elog.h`, `erec.h`, `err.h`, `init.h`, `iobuf.h`, `ioctl.h`, `lock.h`, `lprio.h`, `pcb.h`, `psl.h`, `text.h`, `times.h`, `trace.h`, `utsname.h`, `sysinfo.h`, `space.h`, `stack.h`

#### ICP Headers (`icp/`, 28 files)
`icp.h`, `iconf.h`, `iparam.h`, `iuser.h`, `itty.h`, `ifile.h`, `idir.h`, `ittold.h`, `iioctl.h`, `icallo.h`, `icpinfo.h`, `ivpr.h`, `proc.h`, `sio.h`, `sioc.h`, `sioccomm.h`, `sioccsv.h`, `siocprom.h`, `siocunix.h`, `opdef.h`, `dma.h`, `ctc.h`, `pio.h`, `pbsioc.h`, `atoetbl.h`, `etoatbl.h`, `crctab.h`, `hdlcicp.h`

#### Networking Headers
- `ether/` (10 files): Ethernet driver — `buffers.h`, `command.h`, `etconf.h`, `ex.h`, `maps.h`, `misc.h`, `reg.h`, `sizes.h`, `state.h`, `status.h`
- `ncf/` (7 files): Network Control Facility — `attch.h`, `buffers.h`, `misc.h`, `msgs.h`, `sizes.h`, `states.h`, `test.h`
- `pdlc/` (5 files): Protocol Data Link Control — `buffers.h`, `cb.h`, `frames.h`, `misc.h`, `sizes.h`
- `pnet/` (6 files): PlexusNet — `dfsdfs.h`, `dfsmisc.h`, `dfsstat.h`, `dfswe.h`, `rmntab.h`, `vt.h`
- `3270/` (6 files): IBM 3270 emulation — `bisync.h`, `f3270.h`, `initdev.h`, `scrstrc`, `sdefines`, `structs`

#### ACP Headers (`acp/`, 30+ files)
Complete ACP subsystem headers including `acp/sys/` kernel-like headers for the ACP processor.

### 4.13. `/usr/games/` — Games (63 files)

| Game | Description |
|------|-------------|
| `arithmetic` | Math drill |
| `back`, `backgammon` | Backgammon |
| `bj` | Blackjack |
| `craps` | Craps dice game |
| `cribbage` | Cribbage card game |
| `fish` | Go Fish |
| `fortune` | Random fortune cookies (data: `lib/fortunes.dat`) |
| `hangman` | Hangman word game |
| `mastermind` | Code-breaking game |
| `maze` | Random maze generator |
| `moo` | Number guessing (Bulls & Cows) |
| `number` | Number name generator |
| `psych` | Eliza-style chatbot |
| `quiz` | Quiz game with 30 topic databases |
| `random` | Random number generator |
| `reversi` | Reversi/Othello |
| `robots` | Dodge the robots (data: `lib/robots_hof`) |
| `trk` | Star Trek game |
| `ttt` | Tic-tac-toe |
| `wump` | Hunt the Wumpus |

Quiz topics include: `africa`, `america`, `asia`, `europe`, `babies`, `bard` (Shakespeare), `chinese`, `collectives`, `editor`, `elements`, `greeklang`, `inca`, `latin`, `locomotive`, `midearth` (Tolkien), `morse`, `murders`, `poetry`, `pres` (US presidents), `province`, `state`, `trek`, `ucc`.

### 4.14. `/usr/spool/` — Spool Directories (39 files)

#### Cron (`cron/crontabs/`)
All four crontabs (`root`, `adm`, `sys`, `uucp`) contain only comment headers — no active cron jobs configured.

#### LP Printing (`lp/`)

**Configured printers:**

| Printer | Member | Interface |
|---------|--------|-----------|
| `noisy` | — | Custom |
| `ours` | — | Custom |
| `raw` | — | Raw passthrough |
| `stark` | — | Custom |

**Printer models (12):** `1640`, `dumb`, `dumber`, `dumber.raw`, `f450`, `fuji-320`, `fuji-320p`, `hp`, `interface`, `lprmodel`, `ph.daps`, `pprx`, `prx`, `stark`

The `dumb` model script prints a banner page with the user's name and request ID, sends form feeds between copies, and prints separator bars.

#### UUCP (`uucp/`)
`LOGFILE`, `LOGDEL`, `Log-WEEK` — UUCP log files.

### 4.15. Root Directory Files

| File | Content |
|------|---------|
| `.profile` | Root's Bourne shell profile (see below) |
| `.cshrc` | Root's C shell configuration (see below) |
| `.login` | C shell login actions |
| `.logout` | `sync; sync` |
| `unix` | The kernel binary |
| `Qglos.eng` | Q-Office registration log |
| `mdisk` | `mount /dev/dsk/0s2 /user` |
| `udisk` | `umount /dev/dsk/0s2` |

### 4.16. Shell Profiles

#### Root `.profile` (Bourne shell)
```sh
stty erase '^h' kill '^x' echoe
PATH=.:/usr/plx:/bin:/usr/bin:/etc
TZ=PST8PDT
TERM=vt100
EXINIT='set ai nows redraw sm'
export PATH TZ TERM EXINIT
sync
if [ -f /up ] ; then
    rm /up; sync; sleep 5; banner NOW; sync
else
    echo up > /up; sync; init 2
fi
```

The profile uses a clever `/up` flag file mechanism: on first login after boot (single-user mode), it creates `/up` and runs `init 2` to enter multi-user mode. The `shutdown` script removes `/up`, so on the next single-user boot, it goes through multi-user init again. If `/up` exists (meaning we're already in multi-user and got back to single user for shutdown), it removes the flag and displays `NOW` in banner text, signaling the operator it's safe to power off.

#### Root `.cshrc` (C shell)
```csh
set history=200
set prompt = 'Rootcsh > '
set noclobber
set mail=/usr/mail/root
stty erase '^H' kill '^X' ixon ixany echoe -brkint
alias c 'clear'
alias bye 'logout'
alias w '/bin/find ~ -name \!* -print'
alias me 'ps -fu csh'
alias l 'bls -F'
alias q 'Qoffice'
alias h 'history'
alias f 'grep \!* *'
alias sp 'echo \!* | spell'
alias p  '/usr/plx/wbs < \!* &'
set path = ( . /user/woody/bin /usr/plx /bin /usr/bin /v7/bin /v7/usr/bin
             /usr/games /usr/local/sccs /etc /usr/lib/spell )
setenv TZ PST8PDT
setenv TERM vt100
setenv EXINIT 'set ai nowrapscan redraw'
```

Notable: PATH includes `/user/woody/bin` and `/v7/bin` (Version 7 UNIX compatibility), suggesting there may have been a V7 compatibility tree at some point. The `q` alias launches Q-Office. `bls` is Plexus's BSD-style `ls`.

#### Root `.login`
```csh
date
setenv MENUDIR /usr/qlib/menus:/usr/qlib/files:/usr/qlib/help:/usr/bin
set path=(. /usr/bin $path)
```

#### `/etc/profile` (system-wide Bourne shell)
```sh
trap "" 1 2 3
. /etc/TIMEZONE
export LOGNAME
# Shows motd, checks mail, shows news
```

#### `/etc/cshprofile` (system-wide C shell)
```csh
setenv LOGNAME "$LOGNAME"
cat /etc/motd
if { mail -e } then; echo "you have mail"; endif
if ( $LOGNAME != root ) then; news -n; endif
```

## 5. Stocku (Recovery Partition)

**1,732 files** on the stocku partition (`/dev/dsk/0s4`). This is an untouched factory copy of UNIX, used for recovery.

### 5.1. How Stocku Differs from Rootfs

The stocku partition is a clean factory image. Key differences:

**Files only in rootfs (customized system):**
- User dotfiles (`.cshrc`, `.login`, `.logout`, `.profile`)
- Customized configs (`etc/acpconf`, `etc/gettydefs.old`, `etc/inittab.mstr`, `etc/printcap`, `etc/ttyconf`)
- Backup passwd files (`etc/opasswd`, `etc/passwd.bak`, `etc/passwd.old`)
- Extra binaries (`bin/bigcc`, `bin/ll`, `bin/lpwb`, `bin/lx`, `bin/stty_old`)
- Extra compiler variants (`lib/bigccom`, `lib/bigcpp`, `lib/nccom`, `lib/occom`, `lib/tc*`)
- Cross-target CRT files (`lib/crt3.o`, `lib/crtj.o`, `lib/crtr.o`, `lib/crts.o`)
- User data (`Qglos.eng`, `mdisk`, `udisk`)
- Accounting data (`usr/adm/acct/`)
- Usenet news system (`usr/lib/news/`)

**Files only in stocku:**
- `bin/STTY` (instead of `bin/stty_old`)
- `bin/stty` (rootfs has `stty_old`)
- Release tools: `tmp/release/cpio`, `tmp/release/fixup`, `tmp/release/init`, `tmp/release/sh`
- **Kernel source tree** (`usr/src/`)

### 5.2. Kernel Source Tree

The stocku partition contains a partial kernel source tree at `/usr/src/uts/` — enough to reconfigure and relink the kernel, but not the full OS source code (which was proprietary AT&T code).

#### Source Directory Structure

```
usr/src/
├── :mkuts68              # Master kernel build script
├── :mkuts68r             # Copy of build script
├── uts/
│   ├── uts68.mk          # Top-level stub makefile
│   └── m68/
│       ├── m68.mk        # Subsystem coordination makefile
│       ├── locore.o      # Pre-compiled assembly runtime
│       ├── lib1 - lib7   # Pre-compiled kernel object archives
│       └── cf/
│           ├── cf.mk     # Kernel link-edit makefile
│           ├── conf.c    # Device switch tables and tunables
│           ├── low.s     # MC68000 vector table (Lundell/P/20)
│           ├── rlow.s    # MC68010 vector table (Robin/P/35)
│           ├── name.c    # utsname structure
│           └── linesw.c  # Line discipline switch table
└── cmd/
    └── vpm/
        ├── proto0.s      # VPM protocol wrapper
        ├── sas_define    # VPM stack size (256 bytes)
        ├── scriptb.mk68 # BSC VPM firmware build
        └── scripth.mk68 # HDLC VPM firmware build
```

#### `conf.c` — Kernel Configuration

Defines the block device switch table (`bdevsw[]`) and character device switch table (`cdevsw[]`):

**Block devices:**

| Index | Driver | Device |
|-------|--------|--------|
| 0 | dk | Generic disk (OMTI/SCSI) |
| 1 | mt | Magnetic tape |
| 2 | pd | Parallel disk (Lundell only) |
| 5 | rm | Removable media |
| 6 | xy | Xylogics disk (Lundell only) |
| 7 | sc | SCSI disk (Robin only) |
| 8 | fp | Floppy (Robin only) |

**Character devices (29 total):**

| Index | Driver | Device |
|-------|--------|--------|
| 0 | us/co | Console (USART on Lundell, direct-line on Robin) |
| 2 | mm | Memory (`/dev/mem`, `/dev/kmem`, `/dev/null`) |
| 3 | dk | Disk (character interface) |
| 4 | mt | Tape (character interface) |
| 5 | pd | Parallel disk |
| 6 | pt/tp | Pertec tape (Lundell) / SCSI tape (Robin) |
| 8 | rm | Removable media |
| 9 | xy | Xylogics disk |
| 13 | sy | Controlling terminal (`/dev/tty`) |
| 14 | ic | ICP board control |
| 15 | sp/dl | ICP serial ports (Lundell) / Direct-line serial (Robin) |
| 16 | pp | ICP parallel ports |
| 17 | ncf | Network Control Facility (NOS only) |
| 18 | vpm | Virtual Protocol Machine |
| 19 | tr | Protocol trace |
| 20 | err | Error logging |
| 21 | prf | Kernel profiler |
| 22 | vtty | Virtual terminal (NOS only) |
| 23 | im | IMSC download (Lundell only) |
| 24 | hdlc | HDLC protocol |
| 25 | ft | File transfer |
| 26 | fp | Floppy (Robin only) |
| 27 | rk | RKer (Robin only) |
| 28 | crm | Caching removable media |

Uses `#ifdef` conditionals for four machine variants:
- **Lundell** (P/20): default — USART console, parallel disk, Pertec tape, Xylogics, IMSC
- **Robin** (P/35): `#ifdef robin` — SCSI disk/tape/floppy, direct-line console
- **NOS**: `#ifdef NOS` — adds Ethernet, NCF, virtual terminal
- Combinations possible (e.g., Robin with NOS)

Key tunables defined in `conf.c`:

| Parameter | Value | Description |
|-----------|-------|-------------|
| NBUF | 0 | Auto (10% of physical memory) |
| NINODE | 200 | In-core inodes |
| NFILE | 175 | Open file table entries |
| NMOUNT | 13 | Mount table entries |
| NPROC | 100 | Max processes (hard limit 255) |
| NTEXT | 40 | Shared text segments |
| NCLIST | 20/80 | Character list buffers (80 for NOS/Robin) |
| MAXUP | 25 | Max processes per user |
| NHBUF | 64 | Hash buckets (power of 2) |
| Root device | makedev(0,1) | Disk 0, partition 1 |
| Swap | block 36000, 4000 blocks | Different from running system (58000/8000) |

#### `low.s` — MC68000 Exception Vector Table (Lundell)

The 68000 exception vectors starting at address 0:

| Vector | Handler | Description |
|--------|---------|-------------|
| 0 | `start` | Reset (jumps to kernel entry) |
| 2 | `t_berr` | Bus error |
| 3 | `t_aerr` | Address error |
| 4 | `t_ill` | Illegal instruction |
| 5 | `t_zdiv` | Divide by zero |
| 8 | `t_priv` | Privilege violation |
| 9 | `t_trace` | Trace |
| 24 | `t_spur` | Spurious interrupt |
| 32 | `i_sc` | TRAP #0 — system call entry |
| 34 | `u_bkpt` | TRAP #2 — user breakpoint |
| 47 | `t_fp` | TRAP #15 — Sky floating point |

Hardware interrupt dispatch (Multibus slots):

| Vector | Multibus | Handler | Device |
|--------|----------|---------|--------|
| 73 | MB0 | `_siint4` / `_etintr` | ICP serial slot 4 / Ethernet (NOS) |
| 72 | MB1 | `_rmintr` | Tape controller |
| 71 | MB2 | `_siint1` | ICP serial slot 1 |
| 70 | MB3 | `_siint0` | ICP serial slot 0 |
| 69 | MB4 | `_siint2` | ICP serial slot 2 |
| 68 | MB5 | `_xyintr` | Xylogics disk controller |
| 67 | MB6 | `_siint3` | ICP serial slot 3 |
| 66 | MB7 | `_pdintr`/`_ptintr`/`_imintr` | Parallel disk/tape/IMSC (shared) |
| 77 | — | `_i_clk` | Clock |
| 78 | — | `_i_dmerr` | DMA/memory error |
| 79 | — | `_i_pwr` | Power fail |

The Multibus 7 interrupt is shared between the parallel disk controller (`_pdintr`), Pertec tape (`_ptintr`), and IMSC download (`_imintr`), distinguished by the `_imscint` flags word.

The `trapret` return-from-interrupt code checks whether to return to user mode, and if so, checks `_runrun` to decide whether to reschedule.

#### `rlow.s` — MC68010 Exception Vector Table (Robin)

Similar to `low.s` but for the Robin (P/35) with MC68010:
- Uses Vector Base Register (`vbraddr` label) — the 68010 can relocate the vector table
- Vector 14 is `t_format` (68010 format error, not present on 68000)
- Has SCSI interrupt vectors (0x60-0x6F) for the onboard SCSI controller
- Has USART interrupt vectors (0x88-0x9C) for 6 onboard serial ports (p0-p5)
- Includes DMA/Job processor interrupt vectors
- Memory parity error handler (`i_memerr` → `_parerr`)

#### `linesw.c` — Line Discipline Switch

Two line disciplines:
- **0:** Standard tty (`ttopen`, `ttclose`, `ttread`, `ttwrite`, `ttin`, `ttout`)
- **1:** Virtual terminal (`ttopen`, `nulldev`, `vttread`, `vttwrite`)

Optional terminal emulation via `termsw[]`:
- Slot 0: plain tty
- Slot 1: VT100 emulation (if `VT_VT100` defined)
- Slot 2: HP45 emulation (if `VT_HP45` defined)

#### `:mkuts68` — Kernel Build Script

The master build script supports four Plexus machine variants:

| Machine | Flag | Version prefix | Uname -v |
|---------|------|----------------|----------|
| Lundell (P/20) | `-DLUNDELL` (default) | `m` | `m*` |
| Robin (P/35) | `-DROBIN -Drobin` | `r` | `r*` |
| Pirate | `-DPIRATE` | `p` | `p*` |
| Schroeder | `-DSCHROEDER` | `s` | `s*` |

Usage: `:mkuts68 -u users -m machine -n -c -r release -v version -t rootfs -i includefs`

The script auto-detects the current machine type from `uname -v` and supports user counts of 8, 16, 24, 32, or 64. The `-n` flag enables NOS (PlexusNet networking), `-c` enables ICP communications build.

The actual OS source code (scheduler, filesystem, memory management, device drivers) is shipped only as precompiled `.o` files in `lib1` through `lib7`, consistent with AT&T's proprietary System V source licensing. Only the configuration and link-edit source is provided.

### 5.3. VPM/ICP Protocol Sources

The VPM (Virtual Protocol Machine) firmware build pipeline:

1. **`vpmc`** compiles VPM script (`vpmscript.r`) to intermediate code
2. ICP opcode definitions (`/usr/include/icp/opdef.h`) are prepended
3. **`zcpp`** (Z8000 C preprocessor) preprocesses the combined source
4. **`vratfor`** converts ratfor-like syntax to Z8000 assembly
5. Assembly is placed into the ICP kernel source tree
6. The ICP operating system (a Z8000 RTOS) is built with `make`
7. **`zar`** extracts objects from the VPM library archive
8. **`zld`** links 35+ object files into the downloadable `vpm0` firmware

Two protocol variants are built:
- **BSC** (Binary Synchronous Communication) — `scriptb.mk68`
- **HDLC** (High-Level Data Link Control) — `scripth.mk68`

The ICP boards use Zilog Z8000 processors with their own mini-OS containing: scheduler (`sched.o`), sleep/wakeup (`slp.o`), traps (`trap.o`), DMA (`dma.o`), CTC timer (`ctc.o`), serial I/O (`tty.o`, `tt0.o`, `dh.o`), mailbox interface (`mb.o`), and the VPM interpreter (`interp.o`, `fetch.o`, `get.o`, `put.o`, `rcv.o`, `xmt.o`).

## 6. Device Drivers and Hardware

### 6.1. Plexus P/20 Hardware Architecture

The P/20 is built around the Motorola MC68000 CPU with a Multibus I backplane:

| Component | Description |
|-----------|-------------|
| CPU | Motorola MC68000, 10 MHz |
| Bus | Intel Multibus I |
| RAM | 2 MB (0x200000 bytes) |
| Boot ROM | Mapped at 0x808000 |
| Console | On-board USART (EPCI) |
| Disk | OMTI 5200 SCSI-to-MFM interposer (SCSI ID 0) |
| Tape | Archive QIC SCSI tape (SCSI ID 7) |
| Floppy | Shugart-style 80-track DD (720K) via OMTI (SCSI LUN 1) |
| Serial I/O | ICP (Intelligent Communications Processor) — Multibus card |
| SCSI host | On-board (SCSI ID 3) |

### 6.2. ICP/ACP Serial I/O

The ICP (Intelligent Communications Processor) is a Z8000-based Multibus card that handles serial communications. Each ICP provides 8 serial ports. Up to 5 I/O cards (ICPs and/or ACPs) can be installed.

- **ICP:** 8 ports per card (major 14=control, 15=tty, 16=parallel)
- **ACP:** 16 ports per card (major 30=control, 31=tty, 32=parallel)
- Device naming: `/dev/ic0`, `/dev/tty0`-`/dev/tty7` for ICP 0; `/dev/ac1`, `/dev/tty8`-`/dev/tty23` for ACP 1

Firmware is downloaded to ICP boards at boot time via `/etc/dnld`:
```sh
# From /etc/rc:
/etc/dnld -dr -L -f /usr/lib/dnld/rker -o /dev/rk -a c00400
```

### 6.3. Multibus Interrupt Mapping (Lundell/P/20)

| Multibus Line | Vector | Device | Priority |
|---------------|--------|--------|----------|
| MB0 | 73 | ICP slot 4 / Ethernet | Lowest |
| MB1 | 72 | Tape controller (rm) | |
| MB2 | 71 | ICP slot 1 | |
| MB3 | 70 | ICP slot 0 | |
| MB4 | 69 | ICP slot 2 | |
| MB5 | 68 | Xylogics disk | |
| MB6 | 67 | ICP slot 3 | |
| MB7 | 66 | Parallel disk/tape/IMSC | Highest |

## 7. Networking and Communication

### 7.1. UUCP

The system has UUCP configured with modem support:
- **L-devices:** Two ACU (Automatic Calling Unit) entries using `/usr/plx/mdial` at 300 and 1200 baud
- **L.sys:** Only an example entry (not a real connection)
- Spool: `/usr/spool/uucp/` with LOGFILE, LOGDEL, Log-WEEK

### 7.2. VPM (Virtual Protocol Machine)

VPM is Plexus's protocol engine running on the ICP Z8000 coprocessor. It supports:
- **BSC** (Binary Synchronous Communication) — IBM mainframe connectivity
- **HDLC** (High-Level Data Link Control) — X.25 and other protocols

User-space tools: `vpmc` (compiler), `vtcmp` (compare), `/etc/vpmstart`, `/etc/vpmsnap`, `/etc/vpmtrace`

### 7.3. PlexusNet / NOS

When compiled with `-DNOS`, the kernel includes:
- **Ethernet driver** (`etopen/etclose/etread/etwrite`)
- **NCF** (Network Control Facility) — `ncfopen/ncfclose/ncfread/ncfwrite/ncfioctl`
- **Virtual TTY** — `vttyopen/vttyclose/vttyread/vttywrite/vttyioctl`
- **DFS** (Distributed File System) — PlexusNet's remote filesystem

Configuration files: `/usr/lib/nos/D-hosts`, `/usr/lib/nos/vtconf`

### 7.4. X.25 / HDLC

Extensive X.25 networking support visible in headers (`sys/x25*.h`, `sys/bx25*.h`) and the `bx25s`/`bx25nc` drivers in the master device table. The LAPB protocol support is compiled as `cslapb.o` in `/lib/`.

### 7.5. Usenet News

Complete B-News installation with rn newsreader support in `/usr/lib/news/`. Includes `inews`, `expire`, `recnews`, `sendbatch`, `uurec`, and the `rn/` reader configuration.

## 8. Development Environment

### 8.1. C Compiler — AT&T PCC (Portable C Compiler)

The C compiler is the **AT&T Portable C Compiler (PCC)**, the standard compiler distributed with UNIX System V. Version strings extracted from the binaries:

| Binary | Location | Size | Version String |
|--------|----------|------|----------------|
| `cc` | `/bin/cc` | 24,584 | `@(#) C rel 6.0` |
| `ccom` | `/lib/ccom` | 141,142 | `PCC/PCCrx UNIX 6.X` / `UNIX 6.0` |
| `cpp` | `/lib/cpp` | 35,278 | `@(#)C rel 6.0` |
| `c2` | `/lib/c2` | 41,648 | *(no version string)* |
| `lint1` | `/usr/lib/lint1` | 116,925 | `PCC/PCCrx UNIX 6.X` |

The "PCCrx" designation likely indicates the MC68000 register-model backend variant of PCC. The `UNIX 6.X` / `UNIX 6.0` identifier refers to the AT&T compiler release number (not the UNIX version — the OS is System V Release 2).

The compiler toolchain follows the standard System V compilation pipeline:

```
source.c → cpp (preprocessor) → ccom (compiler) → as (assembler) → ld (linker)
                                    ↓
                                c2 (optimizer, optional)
```

The `cc` driver also references `/usr/Xinclude` as an include path, profiling variants (`mcrt0.o`, `fcrt0.o`, `fmcrt0.o`), and profiling libraries (`/lib/libp/`).

The rootfs also has variant compiler binaries not on stocku: `/bin/bigcc` (large-model C compiler), `/lib/bigccom`, `/lib/bigcpp` (large-model compiler/preprocessor), `/lib/nccom` (variant), `/lib/occom` (old compiler, saved copy).

### 8.2. MC68000 Assembler and Linker

| Binary | Location | Size | SCCS Dates | Notes |
|--------|----------|------|------------|-------|
| `as` | `/bin/as` | 94,822 | 1982-01 to 1983-08 | Recognizes MC68010 instructions |
| `ld` | `/bin/ld` | 96,562 | 1982-01 to 1983-10 | Identifies as `MC 68000` |

The assembler source files (from SCCS IDs): `pass0.c`, `instab.c`, `pass1.c`, `code.c`, `expand1.c`, `errors.c`, `pass2.c`, `codeout.c`, `getstab.c`, `obj.c`, `symlist.c`. It is a two-pass assembler with 68010 instruction awareness (emits warnings for 68010-only instructions when targeting 68000).

The linker source files: `ld00.c`, `ld01.c`, `ld1.c`, `ld2.c`, `expr0.c`, `expr1.c`, `globs.c`, `lists.c`, `util.c`, `alloc.c`, `dump.c`, `maps.c`, `output.c`, `slotvec.c`, `syms.c`, `instr.c`, `version.c`, plus `ld.lex` and `ld.yac` (the linker uses lex/yacc for script parsing).

### 8.3. Native Toolchain (Complete)

| Tool | Location | Size | Purpose |
|------|----------|------|---------|
| `cc` | `/bin/cc` | 24,584 | C compiler driver (PCC rel 6.0) |
| `ccom` | `/lib/ccom` | 141,142 | C compiler proper (PCC/PCCrx) |
| `cpp` | `/lib/cpp` | 35,278 | C preprocessor |
| `c2` | `/lib/c2` | 41,648 | Peephole optimizer |
| `as` | `/bin/as` | 94,822 | MC68000/68010 assembler |
| `ld` | `/bin/ld` | 96,562 | Link editor |
| `ar` | `/bin/ar` | 34,118 | Archive manager |
| `nm` | `/bin/nm` | 35,120 | Symbol table lister |
| `size` | `/bin/size` | 24,310 | Section size reporter |
| `strip` | `/bin/strip` | 52,970 | Strip symbols |
| `make` | `/bin/make` | 83,372 | Build automation |
| `adb` | `/bin/adb` | 69,391 | Assembler-level debugger |

### 8.4. C Runtime and Libraries

#### Architecture Test Commands

The system uses shell script architecture test commands for portable makefiles:
- `/bin/m68` → `/bin/true` (this IS an MC68000 system)
- `/bin/z8000`, `/bin/vax`, `/bin/pdp11`, `/bin/u370`, `/bin/u3b`, `/bin/u3b5`, `/bin/n16`, `/bin/ns32000` → `/bin/false` (all other architectures)

#### CRT (C Runtime Startup) Variants

| File | Size | Purpose |
|------|------|---------|
| `crt0.o` | 480 | Standard startup (Lundell/P20) |
| `crt2.o` | 5,865 | Profiling startup |
| `crt3.o` | 7,259 | Variant startup |
| `crtj.o` | 7,123 | Schroeder "J" variant startup |
| `crtr.o` | 5,865 | Robin (P/35) variant startup |
| `crts.o` | 7,123 | Schroeder variant startup |

The variant CRTs correspond to the machine variants in the kernel build system (`:mkuts68`).

#### Machine-Variant Libraries

The system ships per-variant C libraries, each ~200 KB, containing the standard `libc.a` objects plus machine-specific I/O and initialization routines:

| Library | Size | Variant | Machine-Specific Objects |
|---------|------|---------|--------------------------|
| `/lib/libc.a` | 173,414 | Lundell (P/20) | *(standard, no prefix)* |
| `/usr/lib/libr.a` | 198,788 | Robin (P/35) | `ROBINfp.o`, `ROBINinit.o`, `ROBINpt.o`, `ROBINrm.o`, `ROBINsc.o`, `ROBINtty.o` |
| `/usr/lib/libs.a` | 199,914 | Schroeder | `SCHdk.o`, `SCHinit.o`, `SCHmapdata.o`, `SCHmt.o`, `SCHpd.o`, `SCHpt.o`, `SCHrm.o`, `SCHtty.o`, `SCHxy.o` |
| `/usr/lib/libj.a` | 202,380 | Schroeder (sub-variant) | `SCHdk.o`, `SCHinit.o`, `SCHmapdata.o`, `SCHmt.o`, `SCHpd.o`, `SCHpt.o`, `SCHrm.o`, `SCHtty.o`, `SCHxy.o` |
| `/usr/lib/libx.a` | 199,784 | P/60(?) | `P60dk.o`, `P60init.o`, `P60mapdata.o`, `P60mt.o`, `P60pd.o`, `P60pt.o`, `P60rm.o`, `P60tty.o`, `P60xy.o` |
| `/lib/libtc.a` | 169,964 | Unknown variant | *(no machine-specific prefix)* |

The `libx.a` library reveals a previously undocumented machine variant with `P60` prefixed objects. The "P60" might refer to a Plexus P/60 model not mentioned in other documentation.

All variant libraries share common objects (`Aconf.o`, `Ainit.o`, `Akmem.o`, `SYS.o`) plus the full standard C library (`a64l.o`, `abort.o`, `abs.o`, etc.).

#### Standard Libraries

| Library | Location | Size | Purpose |
|---------|----------|------|---------|
| `libc.a` | `/lib/libc.a` | 173,414 | Standard C library |
| `libm.a` | `/lib/libm.a` | 47,648 | Math library |
| `libld.a` | `/lib/libld.a` | 20,508 | Loader access library |
| `libg.a` | `/lib/libg.a` | 542 | Debug library (stub) |
| `libcurses.a` | `/usr/lib/libcurses.a` | 163,284 | Curses screen library |
| `libcurses3.a` | `/usr/lib/libcurses3.a` | 45,428 | Curses v3 library |
| `libl.a` | `/usr/lib/libl.a` | 4,352 | Lex library |
| `liby.a` | `/usr/lib/liby.a` | 988 | Yacc library |
| `libmalloc.a` | `/usr/lib/libmalloc.a` | 8,576 | Malloc library |
| `libplot.a` | `/usr/lib/libplot.a` | 9,176 | Plot library |
| `libtermlib.a` | `/usr/lib/libtermlib.a` | 5,410 | Terminal library |
| `libvt0.a` | `/usr/lib/libvt0.a` | 9,872 | VT terminal library |

Profiling variants (`/lib/libp/`): `libc.a` (188,880), `libm.a` (49,376), `libmalloc.a` (8,846).

### 8.5. Z8000 Cross-Development Toolchain (for ICP)

A complete cross-compilation toolchain for the Zilog Z8000 processor, used to build firmware for the ICP (Intelligent Communications Processor) boards:

| Binary | Location | Size | Version String |
|--------|----------|------|----------------|
| `zcc` | `/usr/bin/zcc` | 17,162 | `@(#)cc.c 1.6`, `C rel 2.3; UTS rel 1.3` |
| `zccom` | `/lib/zccom` | 130,423 | `PCC/3.0r1` |
| `zas` | `/usr/bin/zas` | 83,020 | SCCS 1.3 (1982-1983) |
| `zld` | `/usr/bin/zld` | 18,416 | — |
| `zar` | `/usr/bin/zar` | 17,162 | — |
| `znm` | `/usr/bin/znm` | 11,757 | — |
| `libzc.a` | `/lib/libzc.a` | 75,908 | Z8000 C library |
| `libzm.a` | `/lib/libzm.a` | 27,148 | Z8000 math library |

The Z8000 compiler is an older version of PCC (3.0r1) compared to the native MC68000 compiler (6.0). The `zcc` driver identifies itself as `C rel 2.3; UTS rel 1.3` — "UTS" here likely refers to the Plexus Unix Tool Set release, not Amdahl UTS.

### 8.6. Other Languages

| Language | Tool | Location | Notes |
|----------|------|----------|-------|
| Fortran 77 | `f77pass1`, `f77pass2` | `/usr/lib/` | **0 bytes** — stub files, compiler not installed |
| SNOBOL | `sno` | `/usr/bin/sno` | 17,332 bytes — pattern matching language |
| Ratfor | `ratfor` | `/usr/bin/ratfor` | 29,736 bytes — Rational Fortran preprocessor |
| EFL | `efl` | `/usr/bin/efl` | Extended Fortran Language preprocessor |
| Lex | `lex` | `/usr/bin/lex` | 51,148 bytes — lexical analyzer generator |
| Yacc | `yacc` | `/usr/bin/yacc` | 47,364 bytes — parser generator |
| BC/DC | `bc`, `dc` | `/usr/bin/` | Arbitrary precision calculator |
| BS | `bs` | `/bin/bs` | 54,920 bytes — Basic-like interpreter |
| M4 | `m4` | `/usr/bin/m4` | 34,712 bytes — macro processor |

### 8.7. Development Analysis Tools

| Tool | Location | Size | Purpose |
|------|----------|------|---------|
| `cb` | `/usr/bin/cb` | 29,398 | C beautifier (source formatter) |
| `cflow` | `/usr/bin/cflow` | 1,444 | Call graph analyzer |
| `ctrace` | `/usr/bin/ctrace` | 59,680 | C program execution tracer |
| `cxref` | `/usr/bin/cxref` | 44,618 | Cross-reference generator |
| `lint` | `/usr/bin/lint` | 3,296 | C program checker (PCC/PCCrx) |
| `lint1` | `/usr/lib/lint1` | 116,925 | Lint first pass |
| `lint2` | `/usr/lib/lint2` | 45,245 | Lint second pass |
| `prof` | `/usr/bin/prof` | — | Execution profiler |
| `regcmp` | `/usr/bin/regcmp` | — | Regex compiler |
| SCCS | `/usr/bin/` | — | Source Code Control System (12 commands) |

### 8.8. Document Processing

Complete `troff`/`nroff` document formatting suite:

| Tool | Location | Size | Purpose |
|------|----------|------|---------|
| `troff` | `/usr/bin/troff` | 67,762 | Typesetter formatter |
| `nroff` | `/usr/bin/nroff` | 93,338 | Terminal formatter |
| `eqn` | `/usr/bin/eqn` | 52,414 | Equation formatter |
| `tbl` | `/usr/bin/tbl` | 53,918 | Table formatter |
| `pic` | `/usr/bin/pic` | 106,394 | Picture language processor |

## 9. System Administration

### 9.1. Boot Sequence

1. **Power on** → Boot ROM loads from PROM at 0x808000
2. **Boot ROM** displays `PLEXUS PRIMARY BOOT REV 1.2`, prompts `: `
3. **Path resolution** — ROM's s5fs implementation finds `/unix` on rootfs
4. **Kernel load** — 180,208 bytes loaded into memory, Job processor started
5. **Kernel init** — Displays `UNIX/1.2: Sys5.2r8`, memory info
6. **`/etc/init`** starts, reads `/etc/inittab`
7. **Single-user** — `bcheckrc` checks date and filesystems, `brc` cleans mnttab
8. **Root `.profile`** runs — creates `/up` flag, runs `init 2` for multi-user
9. **Run level 2** — `rc` mounts `/user`, downloads ICP firmware, starts cron and LP scheduler, spawns `getty` on tty1 and tty2
10. **Login** — `getty` → `login` → shell (csh for regular users)

### 9.2. Cron

Cron daemon started by `/etc/rc`. All crontab files (`root`, `adm`, `sys`, `uucp`) are empty (comment-only) — no scheduled jobs configured.

### 9.3. Accounting

Process accounting infrastructure is installed but commented out in `/etc/rc`:
```sh
# /bin/su - adm -c /usr/lib/acct/startup
# echo process accounting started
```

The complete `acct/` suite (30 programs) is present, and historical accounting data exists in `/usr/adm/acct/`.

### 9.4. Error Logging

Error logging daemon (`/usr/lib/errdemon`) is also commented out in `/etc/rc`. The `errstop` script, `errdead` utility, and `errpt` reporting tool are all present.

### 9.5. System Activity

`sar`, `sadp`, `sag`, `timex` for performance monitoring. System activity data collection (`/usr/lib/sa/sadc`) is commented out in `/etc/rc`.

### 9.6. Backup

| Method | Tool | Description |
|--------|------|-------------|
| Disk-to-disk | `/etc/filesave` | Uses `volcopy` to copy partitions between drives |
| Disk-to-tape | `/etc/tapesave` | Uses `volcopy` to copy a filesystem to tape |
| Full backup | `/etc/fbkup` or `/stand/fbkup` | Full filesystem backup |
| Restore | `/etc/restor` or `/stand/restor` | Restore from backup |
| Standalone | `/stand/*` | Boot ROM can load standalone utilities for recovery |

### 9.7. Printer Administration

LP scheduler: `/usr/lib/lpsched`, `/usr/lib/lpshut`
Configuration: `/usr/lib/lpadmin`, `accept`, `reject`, `lpmove`
Status: `/usr/bin/lpstat`, `/usr/bin/enable`, `/usr/bin/disable`

Four printers configured: `noisy`, `ours`, `raw`, `stark`. Twelve printer model scripts available.

## 10. File Statistics

### 10.1. Rootfs

| Category | Files |
|----------|-------|
| `/bin/` | 90 |
| `/etc/` (all files) | 90 |
| `/lib/` | 37 |
| `/stand/` | 13 |
| `/usr/bin/` | 168 |
| `/usr/lib/` (including terminfo) | 1,115 |
| `/usr/plx/` | 43 |
| `/usr/qlib/` | 349 |
| `/usr/include/` | 203 |
| `/usr/games/` | 63 |
| `/usr/spool/` | 39 |
| Root directory files | 10 |
| Other | ~632 |
| **Total** | **2,852** |

### 10.2. Stocku

| Category | Files |
|----------|-------|
| Total files | 1,732 |
| Kernel source (usr/src/) | ~15 source files + precompiled libs |
| Unique to stocku | Release tools, kernel source tree |

### 10.3. Key Dates

| Date | Significance |
|------|-------------|
| 1984 | Earliest file dates (some printer models) |
| Apr-May 1986 | Most `/etc/` scripts (`@(#)` SID dates) |
| Aug 29, 1986 | Profile scripts (`profile.sh 5.3`, `cshprofil.sh 5.3`) |
| Nov 27, 1985 | Kernel binary (`/unix`) |
| Dec 6, 1985 | Q-Office registration |
| Jul 30, 1985 | Shutdown script |

## 11. Cross-References

- **Boot ROM filesystem implementation:** [`docs/filesystem.md`](filesystem.md)
- **Boot block structure:** [`disk/bootblock.md`](../disk/bootblock.md)
- **Disk overview and partition table:** [`disk/readme.md`](../disk/readme.md)
- **Boot ROM debug monitor:** [`docs/debug_monitor.md`](debug_monitor.md)
- **Boot menu:** [`docs/ROM_boot_menu.md`](ROM_boot_menu.md)
- **Hardware registers:** [`docs/registers.md`](registers.md)
