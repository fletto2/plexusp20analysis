# Plexus P/20 Boot ROM Filesystem Implementation

## Overview

The Plexus P/20 boot ROM (U15, mapped at 0x808000) contains a complete read-only implementation of the **AT&T System V Release 2 filesystem (s5fs)** with 1024-byte blocks. This allows the boot loader to navigate directory trees, resolve pathnames like `/unix`, and load executable files from the SCSI hard disk.

The filesystem code is compiled with `FsTYPE==2` (1024-byte block filesystem), matching the Plexus kernel headers in `sys/param.h`.

## Filesystem Type: System V (s5fs), 1024-byte blocks

Confirmed by the actual Plexus system headers (`usr/include/sys/param.h`, `sys/filsys.h`, `sys/ino.h`, `sys/dir.h`) and verified against the ROM disassembly:

| Parameter | Value | Source |
|-----------|-------|--------|
| Block size (BSIZE) | 1024 bytes | `param.h` FsTYPE==2; ROM constant at 0x808C34 |
| Inodes per block (INOPB) | 16 | `param.h` |
| Inode shift (INOSHIFT) | 4 | LOG2(INOPB) |
| NINDIR | 256 | BSIZE/sizeof(daddr_t) = 1024/4 |
| NSHIFT | 8 | LOG2(NINDIR); ROM shift at 0x808B88 |
| NMASK | 0377 (255) | NINDIR-1; ROM mask at 0x808C76 |
| DIRSIZ | 14 | `dir.h`; max filename length |
| Directory entry size | 16 bytes | 2-byte inode + 14-byte name |
| Root inode (ROOTINO) | 2 | `param.h`; ROM arg at 0x808AC4 |
| Superblock (SUPERB) | block 1 | `param.h` |
| Logical-to-physical | `b << 1` | FsLTOP macro; each fs block = 2 sectors |
| Disk sector size | 512 bytes | SCSI/OMTI 5200 standard |
| NADDR | 13 | 13 block addresses per inode |
| Block address size | 3 bytes (packed) | `di_addr[40]`; 13 addrs x 3 bytes = 39 |

## Disk Layout

```
Block 0:  Boot block (OMTI 5200 configuration + partition table)
Block 1:  Superblock (struct filsys)
Block 2 .. s_isize-1:  Inode list
Block s_isize .. s_fsize-1:  Data blocks
```

### Boot Block (Block 0, Sector 0)

The first sector contains the OMTI 5200 interposer configuration and partition table (see `disk/bootblock.md`):

```
Offset  Field              Value (this system)
0x00    OMTI drive params  10 heads, 753 cylinders, 17 spt
0x??    fsbsize            1024
0x??    bootname           "/unix"
0x??    nswap              8000 blocks
0x??    swplo              58000 (block offset)
0x??    rootdev            1
0x??    parttable          Partition start/length pairs
```

### Partition Table

```
Slice   Device          Start     Length    Mount Point
0       /dev/dsk/0s0        0   10000000   (whole disk - do not use)
1       /dev/dsk/0s1        0      66000   / (rootfs)
2       /dev/dsk/0s2    66000      34000   /user
3       /dev/dsk/0s3   100000   10000000   (rest of disk)
4       /dev/dsk/0s4   100000      45000   /stocku
Swap:   starts at block 58000, length 8000  (overlaps rootfs end)
```

All values are decimal, in 512-byte physical blocks. The ROM converts to filesystem blocks by shifting right 1 bit (i.e., dividing by 2, since each 1024-byte fs block = 2 sectors).

### Superblock (Block 1)

From `sys/filsys.h`:

```c
struct filsys {
    ushort  s_isize;        /* size in blocks of inode list */
    daddr_t s_fsize;        /* size in blocks of entire volume */
    short   s_nfree;        /* number of addresses in s_free */
    daddr_t s_free[NICFREE]; /* free block list (50 entries) */
    short   s_ninode;       /* number of inodes in s_inode */
    ino_t   s_inode[NICINOD]; /* free inode list (100 entries) */
    char    s_flock;        /* lock during free list manipulation */
    char    s_ilock;        /* lock during inode list manipulation */
    char    s_fmod;         /* super block modified flag */
    char    s_ronly;        /* mounted read-only flag */
    time_t  s_time;         /* last super block update */
    short   s_dinfo[4];     /* device information */
    daddr_t s_tfree;        /* total free blocks */
    ino_t   s_tinode;       /* total free inodes */
    char    s_fname[6];     /* file system name */
    char    s_fpack[6];     /* file system pack name */
    long    s_fill[13];     /* padding to 512 bytes */
    long    s_magic;        /* magic number: 0xFD187E20 */
    long    s_type;         /* type: 1 = 512-byte, 2 = 1024-byte blocks */
};
```

The boot ROM reads the superblock but only needs `s_isize` (to locate data blocks after the inode list) and `s_fsize` (for bounds checking).

**Note on `s_type`:** On this system, the kernel is compiled with `FsTYPE==2` (1024-byte blocks hardcoded), so the `s_type` field is never checked at runtime. In practice, the rootfs and `/user` partitions have `s_type=1` in their superblocks despite using 1024-byte blocks — the `mkfs` that created them apparently did not set this field correctly. The `/stocku` partition has the correct `s_type=2`. The `s_magic` field (0xFD187E20) is sufficient to identify a valid s5fs superblock.

### Observed Superblock Values

From the actual disk image (`plexus-sanitized.img`):

| Field | rootfs (0s1) | /user (0s2) | /stocku (0s4) |
|-------|-------------|-------------|---------------|
| s_isize | 455 | 267 | 353 |
| s_fsize | 29,000 | 17,000 | 22,500 |
| s_fname | "root" | "user" | "stocku" |
| s_fpack | "1" | "1" | "1" |
| s_tfree | 1,403 | 15,865 | 5,355 |
| s_tinode | 4,063 | 4,158 | 3,646 |
| s_magic | 0xFD187E20 | 0xFD187E20 | 0xFD187E20 |
| s_type | 1 | 1 | 2 |
| s_time | 1996-06-04 | 1996-06-04 | 1986-02-26 |

The `s_fsize` values are exactly half the corresponding partition lengths in 512-byte sectors (e.g., rootfs: 66,000 sectors / 2 = 33,000, minus 4,000 for swap = 29,000 fs blocks). Note that `s_time` shows the rootfs and `/user` were last modified in 1996, while `/stocku` was untouched since 1986 — consistent with `/stocku` being a factory recovery partition.

## On-Disk Inode Structure

From `sys/ino.h`:

```c
struct dinode {                 /* 64 bytes per inode */
    ushort  di_mode;     /* +0:  mode and type of file */
    short   di_nlink;    /* +2:  number of links */
    ushort  di_uid;      /* +4:  owner's user id */
    ushort  di_gid;      /* +6:  owner's group id */
    off_t   di_size;     /* +8:  number of bytes in file (4 bytes) */
    char    di_addr[40]; /* +12: disk block addresses (packed 3-byte) */
    time_t  di_atime;    /* +52: time last accessed */
    time_t  di_mtime;    /* +56: time last modified */
    time_t  di_ctime;    /* +60: time created */
};
```

### Block Address Packing

The 13 block addresses are stored in 40 bytes using 3-byte packed format:

```
di_addr[0..2]   = block address 0  (direct)
di_addr[3..5]   = block address 1  (direct)
...
di_addr[27..29] = block address 9  (direct)
di_addr[30..32] = block address 10 (single indirect)
di_addr[33..35] = block address 11 (double indirect)
di_addr[36..38] = block address 12 (triple indirect)
di_addr[39]     = unused
```

Each 3-byte address is unpacked to a 4-byte `daddr_t` by prepending a zero byte. This unpacking is performed by the function at **0x80945E** (`copy_3byte_to_4byte`), which copies 13 groups of 3 bytes, padding each with a leading null byte to form 13 longwords.

### Boot ROM Inode Buffer

The ROM unpacks the on-disk inode into a working structure at **0xC03A24** with the following layout:

```
Offset  Size  Field          Corresponds to
+0      2     di_mode        File type/permissions
+2      ...   (other fields)
+8      4     di_size        File size in bytes
+12     52    di_addr[13]    Block addresses (unpacked to 4 bytes each)
+16     2     i_mode copy    Cached at 0xC03A34
+24     4     di_size copy   Cached at 0xC03A3C
+28     52    i_addr[0..12]  13 x 4-byte block addresses (direct + indirect)
```

Key addresses:
- `0xC03A24`: Base of in-memory inode working area
- `0xC03A34`: Cached `di_mode` (checked for IFDIR = 0x4000)
- `0xC03A3C`: Cached `di_size`
- `0xC03A40`: Start of unpacked 4-byte block address array (13 entries)

## Directory Structure

From `sys/dir.h`:

```c
#define DIRSIZ  14

struct direct {
    ino_t   d_ino;          /* +0: inode number (2 bytes) */
    char    d_name[DIRSIZ]; /* +2: filename (14 bytes, null-padded) */
};
/* Total: 16 bytes per directory entry */
```

With 1024-byte blocks, each directory block holds **64 directory entries** (1024 / 16 = 64).

## Boot ROM Filesystem Functions

### Function Call Graph

```
boot_menu_loop (0x80B37C)
  └─ parse_boot_command (0x80904C)
       ├─ parse_path_components (0x808A9A)  ← resolves "/unix"
       │    ├─ read_inode (0x8089DE)         ← loads inode from disk
       │    │    ├─ div_signed_32bit (0x808580) ← inode-to-block math
       │    │    ├─ divmod (0x80867E)
       │    │    ├─ scsi_read_dispatch (0x8092AC)
       │    │    └─ copy_3byte_to_4byte (0x80945E) ← unpacks di_addr
       │    └─ search_directory (0x808CB6)   ← finds name in dir
       │         ├─ lookup_inode_block (0x808B2E) ← block mapping
       │         │    └─ scsi_read_dispatch (0x8092AC)
       │         ├─ strncmp_match (0x808DC2)
       │         └─ div_signed_32bit (0x808580)
       └─ load_and_execute_boot_image (0x8097AC)
            ├─ get_next_byte (0x808E56)     ← buffered read
            │    └─ lookup_inode_block (0x808B2E)
            ├─ read_block (0x808F72)        ← read full blocks
            └─ boot_scsi_read_sector (0x80B9A6)
```

### Detailed Function Documentation

#### `read_inode` — 0x8089DE (186 bytes)

**Purpose**: Reads an on-disk inode by number and populates the working inode buffer at 0xC03A24.

**Algorithm**:
1. Clear file position counter (`0xC03A88 = 0`)
2. Compute the physical block containing the inode:
   - `block = (inode_number + 31) / INOPB` → calls `div_signed_32bit(inode_num + 31, 16)`
   - This implements the standard `itod()` macro: `(unsigned)(x + 2*INOPB - 1) >> INOSHIFT`
   - Add partition start offset from `0xC03A80`
3. Set up SCSI read: block address → `0xC03A8C`, buffer → `0xC03A98`, size = 1024
4. Call `scsi_read_dispatch` (0x8092AC) with device ID from `0xC03A30`
5. Compute inode offset within the block:
   - `offset = (inode_num - 1) % INOPB` → calls `divmod(inode_num - 1, 16)`
   - `offset = offset * 64` (each dinode is 64 bytes) → `asl #6`
   - Add to buffer base to get pointer to the dinode
6. Cache the inode number at `0xC03A32`
7. Cache `di_mode` at `0xC03A34`
8. Cache `di_size` at `0xC03A3C`
9. Unpack block addresses: call `copy_3byte_to_4byte(0xC03A40, &dinode.di_addr, 13)` — copies 13 groups of 3 bytes from `di_addr[40]`, padding each to 4 bytes at `0xC03A40`

**Parameters**: Stack arg = inode number (long)

**Returns**: Nothing (populates globals)

---

#### `parse_path_components` — 0x808A9A (146 bytes)

**Purpose**: Resolves a Unix pathname to an inode number by walking the directory tree.

**Algorithm**:
1. Validate input pointer (error if NULL or empty string)
2. Call `read_inode(2)` — load root directory (inode 2, ROOTINO)
3. Loop over path components:
   a. Skip leading `/` characters
   b. Find end of component (next `/` or null terminator)
   c. Temporarily null-terminate the component
   d. Call `search_directory(component_name)` → returns inode number
   e. If not found → call error handler with "file" message
   f. If more path remains → call `read_inode(found_inode)` to descend
   g. Restore the `/` separator
   h. Repeat until end of path
4. Return the final inode number

**Parameters**: Stack arg = pointer to pathname string (e.g., "/unix")

**Returns**: `%d0` = inode number of the file (or 0 on failure)

**Example**: For path `/unix`:
1. Load root inode (inode 2)
2. Component = "unix"
3. Search root directory → finds inode N
4. Return N

For path `/stand/ccal`:
1. Load root inode (inode 2)
2. Component = "stand" → search root dir → inode M
3. Load inode M (the `/stand` directory)
4. Component = "ccal" → search `/stand` dir → inode K
5. Return K

---

#### `search_directory` — 0x808CB6 (266 bytes)

**Purpose**: Searches the current directory (whose inode is already loaded) for a filename, returning its inode number.

**Algorithm**:
1. Validate filename pointer
2. Check that current inode is a directory: `(di_mode & 0xF000) == IFDIR (0x4000)`
   - If not → error "bad directory"
3. Compute number of directory entries: `count = di_size / 16`
   - Calls `unsigned_divide(di_size, 16)` (0x8086FE)
4. Initialize entry counter `%d6 = 0` (counts within current block, mod 64)
5. For each directory entry (up to `count`):
   a. If `%d6 >= 64`: need next directory block
      - Compute block offset: `block_num = entry_index / (1024/16)` using `lookup_inode_block`
      - Read block from disk via SCSI
      - Reset `%d6 = 0`, set `%a5` to buffer base
   b. Compare filename: call `strncmp_match(%a5 + 2, search_name)`
      - Compares up to 14 characters (DIRSIZ)
      - Special handling: `(` character (0x28) in entry matches null terminator in search
   c. If match → return `d_ino` (the word at `%a5`, the first 2 bytes of the entry)
   d. Advance to next entry: `%a5 += 16`, `%d6 += 1`
6. If no match found → return 0

**Parameters**: Stack arg = pointer to filename to search for

**Returns**: `%d0` = inode number (d_ino) if found, 0 if not found

---

#### `lookup_inode_block` — 0x808B2E (390 bytes)

**Purpose**: Maps a logical file block number to a physical disk block address, traversing indirect blocks as needed.

**Algorithm**:
1. **Validate**: if block_num < 0 → error "bad bn"
2. **Direct blocks** (0-9):
   - If `block_num < 10`: return `inode_buffer[28 + block_num * 4]`
   - These are at `0xC03A24 + 28 + n*4` = `0xC03A40 + n*4`
3. **Indirect blocks** (10+):
   - Subtract 10 from block_num
   - Initialize: `level = 3` (max indirection), `shift = 0`, `entries_at_level = 1`
   - Loop (up to 3 levels):
     - `shift += 8` (each level indexes 256 entries = 2^8)
     - `entries_at_level <<= 8` (multiply by 256)
     - If `block_num < entries_at_level`: found the right level, break
     - `block_num -= entries_at_level`
     - `level -= 1`
   - If `level == 0` → error "bad bn" (block number too large)
4. **Traverse indirect blocks**:
   - Get initial pointer from `inode_buffer[28 + (13 - level) * 4]`
     - Level 3 → `inode_buffer[28 + 10*4]` = single indirect (addr 10)
     - Level 2 → `inode_buffer[28 + 11*4]` = double indirect (addr 11)
     - Level 1 → `inode_buffer[28 + 12*4]` = triple indirect (addr 12)
   - If pointer is 0 → error "bad bn"
   - For each indirection level remaining:
     - **Cache check**: compare block pointer against `0xC03A0C + level*4`
     - If not cached:
       - Compute physical address: `partition_start + block_pointer`
       - Read 1024-byte block from disk via SCSI
       - Update cache at `0xC03A0C + level*4`
     - Extract index: `index = (block_num >> shift) & 0xFF`
       - `shift -= 8` for next level
     - Follow pointer: `block_pointer = indirect_block[index]`
     - If pointer is 0 → error "bad bn"
   - `level += 1`, loop until all levels resolved
5. Return final physical block number

**Indirect block cache** at `0xC03A0C`:
```
0xC03A0C + 0:  Cached single-indirect block address
0xC03A0C + 4:  Cached double-indirect block address
0xC03A0C + 8:  Cached triple-indirect block address
```
The buffer for each level is at: `0xC03A08 (buffer_base) + level * 1024`

**Maximum file size** (with 1024-byte blocks):
- Direct: 10 blocks = 10 KB
- Single indirect: 256 blocks = 256 KB
- Double indirect: 256 * 256 = 65,536 blocks = 64 MB
- Triple indirect: 256^3 = 16,777,216 blocks = 16 GB (theoretical, unlikely supported)

---

#### `strncmp_match` — 0x808DC2 (74 bytes)

**Purpose**: Compares a filename from a directory entry against a search name, with special handling for the `(` character and a maximum length of 14 characters (DIRSIZ).

**Algorithm**:
1. Compare up to 14 bytes (DIRSIZ)
2. Special case: if entry char is `(` (0x28) and search char is null → match (this handles the case where directory entry names may be padded with `(` instead of null)
3. Normal case: compare byte by byte
4. Match if both strings end (null terminators or length exhausted)

---

#### `get_next_byte` — 0x808E56 (284 bytes)

**Purpose**: Buffered byte reader. Returns the next byte from the current file, automatically reading new blocks from disk as needed.

**Algorithm**:
1. Check remaining count at `0xC03A94`
2. If buffer exhausted (count <= 0):
   a. Compute next block: `file_offset / 1024` using `div_signed_32bit(0xC03A88, 0x400)`
   b. If filesystem mode (bit 3 of `0xC03A20` set):
      - Call `lookup_inode_block` to map logical → physical block
   c. Add partition offset
   d. Read 1024-byte block via SCSI into buffer at `0xC03A98`
   e. Reset count to bytes read, update buffer pointer
   f. If filesystem mode, compute actual remaining bytes (may be less than 1024 at end of file)
3. Decrement count, increment file position
4. Return next byte from buffer (masked to 0xFF)

**Returns**: `%d0` = next byte (0x00-0xFF), or -1 (0xFFFFFFFF) on EOF/error

---

#### `read_block` — 0x808F72 (128 bytes)

**Purpose**: Reads a full block (up to 1024 bytes) from the current file position into the caller's buffer.

**Algorithm**:
1. Clear accumulator
2. Loop calling `get_next_byte` up to 4 times (reads 4 bytes)
3. Accumulate bytes into a longword
4. Store longword to destination buffer
5. Repeat for entire block (256 longwords = 1024 bytes)
6. Return number of longwords read

---

#### `copy_3byte_to_4byte` — 0x80945E (48 bytes)

**Purpose**: Unpacks the 3-byte packed disk block addresses from the on-disk inode (`di_addr[40]`) into 4-byte longwords in the working inode buffer.

**Algorithm**:
1. For each of `count` groups (13 for a standard inode):
   a. Write 0x00 to destination (high byte = 0)
   b. Copy 3 bytes from source to destination
   c. Advance pointers
2. This converts the packed `di_addr` format to an array of `daddr_t` (4-byte block numbers)

**Parameters**: Stack args = destination pointer, source pointer, count (13)

---

#### `div_signed_32bit` — 0x808580 (134 bytes)

**Purpose**: 32-bit signed integer division. Used throughout filesystem code for block/inode calculations.

The 68010 lacks a 32-bit divide instruction (only 32/16 = 16-bit `divs`/`divu`), so this function implements extended-precision division using repeated shift-and-subtract.

---

#### `divmod_signed_32bit` — 0x80867E (128 bytes)

**Purpose**: 32-bit signed modulus. Returns remainder of division. Used for `inode % INOPB` calculations.

---

#### `scsi_read_dispatch` — 0x8092AC (30 bytes)

**Purpose**: Dispatcher that calls the appropriate SCSI device read function based on a device index.

Uses a jump table at `0x80A014` with 16-byte entries containing function pointers for different device types (disk, tape, floppy).

---

### `boot_scsi_read_boot_block` — 0x80AD7E (96 bytes)

**Purpose**: Reads the boot block (sector 0) from the SCSI disk to obtain the partition table and OMTI configuration.

---

### `load_and_execute_boot_image` — 0x8097AC (706 bytes)

**Purpose**: Loads a Unix `a.out` executable from the filesystem into memory and transfers control to the Job processor.

**a.out format support**:
- Magic 0x0108: Old-style format (read header word-by-word via `get_next_byte`)
- Magic 0x0150 (0x5001 byte-swapped): New-style format (read blocks via `read_block`)

**Loading process**:
1. Read a.out header (text size, data size, BSS size, symbol table size, entry point)
2. Calculate memory pages needed (4KB pages)
3. Load text+data segments byte-by-byte into low memory
4. Zero BSS segment
5. Set up jump table at address 0x0:
   - `[0x0]` → 0x77FFF4 (system data pointer)
   - `[0x4]` → boot argument
   - `[0x8]` → global from 0xC03AA0
6. Start Job processor: set `Boot.JOB` bit at 0xE00016, set `KILL.JOB` at 0xE00018
7. Transfer control to loaded program's entry point

## Shared Memory Variables (Filesystem State)

The boot ROM uses a block of shared RAM at 0xC03A00 for filesystem state:

| Address | Size | Name | Description |
|---------|------|------|-------------|
| 0xC03A08 | 4 | buffer_base | Base of indirect block buffer area |
| 0xC03A0C | 4 | ind_cache[0] | Cached block addr for indirection level 0 |
| 0xC03A10 | 4 | ind_cache[1] | Cached block addr for indirection level 1 |
| 0xC03A14 | 4 | ind_cache[2] | Cached block addr for indirection level 2 |
| 0xC03A20 | 1 | boot_flags | Bit 3: filesystem mode (vs raw device) |
| 0xC03A24 | ~64 | inode_buf | Working inode buffer |
| 0xC03A30 | 2 | device_index | SCSI device/command table index |
| 0xC03A32 | 2 | cur_ino | Current inode number |
| 0xC03A34 | 2 | di_mode | Current inode mode (cached) |
| 0xC03A3C | 4 | di_size | Current file size (cached) |
| 0xC03A40 | 52 | i_addr[13] | Unpacked block addresses (4 bytes each) |
| 0xC03A7C | 4 | scsi_unit | SCSI unit/LUN parameters |
| 0xC03A80 | 4 | part_start | Partition start (in physical blocks) |
| 0xC03A88 | 4 | file_offset | Current byte position in file |
| 0xC03A8C | 4 | disk_block | Current disk block to read |
| 0xC03A90 | 4 | buf_ptr | Current buffer pointer |
| 0xC03A94 | 4 | buf_remain | Bytes remaining in buffer |
| 0xC03A98 | 4 | buf_base | Base address of 1KB I/O buffer |
| 0xC03A9C | 4 | verbose_flag | Verbose/debug output flag |

## Boot Sequence: Loading `/unix`

Here is the complete sequence when the user types `/unix` (or just presses Enter for the default `sc(0,0)/unix`):

### 1. Command Parsing (`parse_boot_command`, 0x80904C)
```
Input: "sc(0,0)/unix" or just "" (empty = default)
→ Extract device: controller=0, unit=0, partition=0
→ Compute SCSI parameters:
    device_index → 0xC03A30
    scsi_unit → 0xC03A7C
    part_start = partition_table[0].start → 0xC03A80
→ Extract path: "/unix"
```

### 2. Initialize Disk (`boot_initialize_scsi_or_filesystem`, 0x80B6BC)
```
→ Send SCSI READ command to OMTI 5200 (ID 0)
→ Read boot block (sector 0) to get partition table
→ Read superblock (block 1) to get s_isize
→ Set boot_flags bit 3 (filesystem mode)
```

### 3. Path Resolution (`parse_path_components`, 0x808A9A)
```
Path: "/unix"

Step 1: read_inode(2)
  → Block = (2 + 31) / 16 = 2 (first inode block)
  → Read block 2 from partition start
  → Inode 2 offset in block = (2-1) % 16 = 1 → byte offset = 64
  → Unpack 13 block addresses from di_addr[40]
  → Cache di_mode (should be 0x4000 = IFDIR)
  → Cache di_size (root directory size)

Step 2: search_directory("unix")
  → Verify di_mode & 0xF000 == 0x4000 (is directory)
  → count = di_size / 16 (number of entries)
  → For each entry in root directory:
      Read block via lookup_inode_block if needed
      Compare d_name[14] against "unix"
      If match → return d_ino
  → Found: returns inode number of /unix
```

### 4. Load Executable (`load_and_execute_boot_image`, 0x8097AC)
```
read_inode(unix_inode)
  → Load inode for /unix
  → di_size = 180208 bytes (from the actual disk)

Read a.out header:
  → Magic: 0x0108 or 0x0150
  → Extract: text_size, data_size, bss_size, entry_point

Load text+data:
  → For each byte, call get_next_byte()
    → get_next_byte reads blocks via lookup_inode_block
    → Direct blocks 0-9 for first 10KB
    → Single-indirect block for 10KB-266KB
    → Most of /unix (180KB) fits in direct + single indirect

Zero BSS segment

Set up at address 0x0:
  → [0x0] = 0x77FFF4  (system data pointer)
  → [0x4] = boot arg
  → [0x8] = global

Start Job processor:
  → Write 0x4000 to 0xE00016 (Boot.JOB)
  → Write 0x0002 to 0xE00018 (KILL.JOB release)
  → Job processor starts executing loaded Unix kernel
```

## Error Messages

The filesystem code reports errors with these ROM strings:

| Address | String | Triggered by |
|---------|--------|--------------|
| 0x80C058 | `invalid object file (0x%x)` | Bad a.out magic number |
| 0x80C085 | `bad directory` | `search_directory`: inode is not IFDIR |
| 0x80C093 | `bad bn %D` | `lookup_inode_block`: block number out of range or null pointer |
| 0x80C0AC | `bad offset or unit specification` | Invalid SCSI device params |
| 0x80C0CD | `unable to wake up disk controller` | SCSI controller not responding |
| 0x80C0EF | `bad disk init` | OMTI 5200 initialization failure |
| 0x80C0FD | `bad disk read` | SCSI read error |
| 0x80C10B | `invalid disk init block` | Boot block validation failure |
| 0x80C1A4 | `disk error %X, %X` | SCSI error with status codes |
| 0x80C1C8 | `file` | File not found in directory |
| 0x80C2EF | `Boot: BAD MAGIC 0x%x` | Invalid a.out magic |
| 0x80C58F | `BOOT: disk not formatted` | No valid boot block |

## Comparison with Standard s5fs

The boot ROM's filesystem implementation is a faithful subset of the System V s5fs:

| Feature | Standard s5fs | Boot ROM |
|---------|--------------|----------|
| Block size | 512 or 1024 | 1024 only |
| Inode structure | Full dinode (64 bytes) | Full, 3-byte addrs unpacked to 4 |
| NADDR | 13 | 13 |
| Direct blocks | 10 | 10 |
| Single indirect | Yes | Yes |
| Double indirect | Yes | Yes |
| Triple indirect | Yes | Yes (code supports 3 levels) |
| Directory entries | 16 bytes (2+14) | 16 bytes (2+14) |
| DIRSIZ | 14 chars | 14 chars (match in strncmp_match) |
| Root inode | 2 | 2 |
| Superblock | Block 1 | Block 1 |
| Free list | Linked list in superblock | Not used (read-only) |
| File creation/write | Yes | No (read-only boot loader) |
| Symbolic links | No (s5fs doesn't have them) | N/A |
| Indirect block cache | Buffer cache | Simple 3-entry cache at 0xC03A0C |

The key simplification is that the boot ROM is **read-only** — it never modifies the filesystem. It only needs to:
1. Read inodes
2. Walk directory entries
3. Map logical blocks to physical blocks
4. Read file data sequentially

This makes the implementation much simpler than the full kernel filesystem driver, while remaining fully compatible with on-disk structures.

**Important caveat:** The `s_type` field in the superblock is unreliable on this system. The rootfs and `/user` partitions have `s_type=1` despite using 1024-byte blocks. Tools reading these filesystems should use the `s_magic` for validation and assume 1024-byte blocks (matching the `FsTYPE==2` build configuration), rather than relying on `s_type`.
