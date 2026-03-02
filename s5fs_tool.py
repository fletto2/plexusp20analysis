#!/usr/bin/env python3
#
# s5fs_tool.py - Read/write tool for AT&T System V s5fs filesystem disk images
#
# Designed for the Plexus P/20 minicomputer (MC68000, big-endian, 1024-byte
# blocks), but should work with any s5fs image using FsTYPE=2.
#
# No external dependencies -- uses only Python 3 standard library.
#
# ============================================================================
#
# s5fs (System V filesystem) is the native filesystem of AT&T UNIX System V
# Release 2 on Motorola 68000 processors. This tool can list, extract, and
# inspect files within s5fs disk images, and optionally modify them.
#
# --------------------------------------------------------------------------
# USAGE
# --------------------------------------------------------------------------
#
# Read operations (image opened read-only):
#
#   python3 s5fs_tool.py <image> --info
#       Show partition table from boot block (Plexus format).
#
#   python3 s5fs_tool.py <image> -p1 --dump-super
#       Dump superblock metadata (sizes, free counts, volume name, dates).
#
#   python3 s5fs_tool.py <image> -p1 --dump-inode N
#       Dump raw inode fields for inode number N.
#
#   python3 s5fs_tool.py <image> -p1 -l
#       List all files and directories with mode, uid/gid, size, dates.
#
#   python3 s5fs_tool.py <image> -p1 --cat /etc/passwd
#       Print a file's contents to stdout.
#
#   python3 s5fs_tool.py <image> -p1 -o /tmp/extract
#       Extract all files preserving directory structure.
#
# Write operations (image opened read-write):
#
#   python3 s5fs_tool.py <image> -p1 --create /path/on/vol local_file
#       Write a local file into the filesystem image.
#
#   python3 s5fs_tool.py <image> -p1 --mkdir /path/on/vol
#       Create a directory in the filesystem image.
#
#   python3 s5fs_tool.py <image> -p1 --rm /path/on/vol
#       Remove a file from the filesystem image.
#
# Safety flags (combine with any write operation):
#
#   --backup    Create a .bak copy of the image before any modification.
#   --dry-run   Show what would be changed without actually writing.
#
# Partition selection:
#
#   -p N, --partition N   Select partition N from the Plexus partition table.
#   --offset BYTES        Manual byte offset to the start of the filesystem.
#
# ============================================================================

import argparse
import gzip
import os
import shutil
import stat as stat_module
import struct
import sys
import time

# ---------------------------------------------------------------------------
# Constants from sys/param.h, sys/filsys.h, sys/ino.h, sys/dir.h, sys/stat.h
# ---------------------------------------------------------------------------

BSIZE      = 1024       # Filesystem block size (FsTYPE=2)
SUPERB     = 1          # Superblock is at logical block 1
ROOTINO    = 2          # Root directory inode number
DIRSIZ     = 14         # Max filename length
INOPB      = 16         # Inodes per block
INOSHIFT   = 4          # LOG2(INOPB)
NINDIR     = 256        # Indirect block entries (BSIZE / 4)
NSHIFT     = 8          # LOG2(NINDIR)
NMASK      = 0xFF       # NINDIR - 1
NICFREE    = 50         # Free block list entries in superblock
NICINOD    = 100        # Free inode list entries in superblock
FsMAGIC    = 0xFD187E20 # s5fs magic number
SECTOR     = 512        # Physical sector size

# Inode size on disk
INODE_SIZE = 64

# File type bits from sys/stat.h
S_IFMT  = 0o170000
S_IFDIR = 0o040000
S_IFCHR = 0o020000
S_IFBLK = 0o060000
S_IFREG = 0o100000
S_IFIFO = 0o010000
S_ISUID = 0o4000
S_ISGID = 0o2000
S_ISVTX = 0o1000

# Number of block addresses per inode
NADDR = 13
# Number of direct block addresses
NDIRECT = 10

# Boot block / partition table constants (Plexus-specific)
BOOTBLOCK_PD_MAGIC_OFFSET = 0x1A
BOOTBLOCK_PD_MAGIC = 0x7064        # "pd" in ASCII
BOOTBLOCK_PARTTABLE_OFFSET = 0x90
BOOTBLOCK_MAX_SLICES = 32

# Boot block field offsets
BB_OMTI_NHEADS     = 0x03
BB_OMTI_NCYLS      = 0x04  # 2 bytes
BB_OMTI_SPT        = 0x08
BB_FSBSIZE         = 0x18  # 2 bytes
BB_ID              = 0x1A  # 2 bytes
BB_INITSIZE        = 0x1C  # 2 bytes
BB_BOOTNAME        = 0x20  # 16 bytes
BB_NODENAME        = 0x30  # 16 bytes
BB_NSWAP           = 0x80  # 2 bytes
BB_SWPLO           = 0x84  # 2 bytes
BB_ROOTDEV         = 0x86  # 2 bytes
BB_PIPEDEV         = 0x88  # 2 bytes
BB_DUMPDEV         = 0x8A  # 2 bytes
BB_SWAPDEV         = 0x8C  # 2 bytes


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def mode_string(mode):
    """Convert a Unix mode word to a drwxrwxrwx string."""
    ftype = mode & S_IFMT
    c = {
        S_IFDIR: 'd', S_IFCHR: 'c', S_IFBLK: 'b',
        S_IFREG: '-', S_IFIFO: 'p',
    }.get(ftype, '?')

    def rwx(m, shift, sbit, schar):
        r = 'r' if m & (0o400 >> shift) else '-'
        w = 'w' if m & (0o200 >> shift) else '-'
        if m & sbit:
            x = schar if m & (0o100 >> shift) else schar.upper()
        else:
            x = 'x' if m & (0o100 >> shift) else '-'
        return r + w + x

    return (c
            + rwx(mode, 0, S_ISUID, 's')
            + rwx(mode, 3, S_ISGID, 's')
            + rwx(mode, 6, S_ISVTX, 't'))


def format_time(t):
    """Format a Unix timestamp for display."""
    if t == 0:
        return '                '
    try:
        return time.strftime('%Y-%m-%d %H:%M', time.gmtime(t))
    except (OSError, OverflowError, ValueError):
        return f'  ({t:#010x})  '


def unpack_addrs(di_addr_40):
    """Unpack 13 three-byte disk addresses from di_addr[40] into a list of ints."""
    addrs = []
    for i in range(NADDR):
        b = di_addr_40[i * 3 : i * 3 + 3]
        addrs.append(int.from_bytes(b'\x00' + b, 'big'))
    return addrs


def cstring(data, maxlen=None):
    """Extract a null-terminated C string from bytes."""
    if maxlen is not None:
        data = data[:maxlen]
    end = data.find(b'\x00')
    if end >= 0:
        data = data[:end]
    return data.decode('ascii', errors='replace')


# ---------------------------------------------------------------------------
# S5Inode - Parsed on-disk inode
# ---------------------------------------------------------------------------

class S5Inode:
    """Parsed inode from the on-disk dinode structure (64 bytes)."""

    __slots__ = ('ino', 'mode', 'nlink', 'uid', 'gid', 'size',
                 'addrs', 'atime', 'mtime', 'ctime')

    def __init__(self):
        self.ino = 0
        self.mode = 0
        self.nlink = 0
        self.uid = 0
        self.gid = 0
        self.size = 0
        self.addrs = [0] * NADDR
        self.atime = 0
        self.mtime = 0
        self.ctime = 0

    @classmethod
    def parse(cls, data, ino_num):
        """Parse a 64-byte on-disk dinode into an S5Inode."""
        if len(data) < INODE_SIZE:
            raise ValueError(f'inode data too short: {len(data)} < {INODE_SIZE}')
        inode = cls()
        inode.ino = ino_num
        # struct dinode layout (MC68000, big-endian):
        #   +0  ushort di_mode
        #   +2  short  di_nlink
        #   +4  ushort di_uid
        #   +6  ushort di_gid
        #   +8  long   di_size  (off_t)
        #  +12  char   di_addr[40]
        #  +52  long   di_atime
        #  +56  long   di_mtime
        #  +60  long   di_ctime
        (inode.mode, inode.nlink, inode.uid, inode.gid, inode.size) = \
            struct.unpack('>HhHHi', data[0:12])
        inode.addrs = unpack_addrs(data[12:52])
        (inode.atime, inode.mtime, inode.ctime) = \
            struct.unpack('>III', data[52:64])
        return inode

    @property
    def is_dir(self):
        return (self.mode & S_IFMT) == S_IFDIR

    @property
    def is_regular(self):
        return (self.mode & S_IFMT) == S_IFREG

    @property
    def is_chardev(self):
        return (self.mode & S_IFMT) == S_IFCHR

    @property
    def is_blockdev(self):
        return (self.mode & S_IFMT) == S_IFBLK

    @property
    def is_fifo(self):
        return (self.mode & S_IFMT) == S_IFIFO

    @property
    def is_special(self):
        return self.is_chardev or self.is_blockdev

    @property
    def mode_str(self):
        return mode_string(self.mode)

    @property
    def type_char(self):
        ftype = self.mode & S_IFMT
        return {
            S_IFDIR: 'd', S_IFCHR: 'c', S_IFBLK: 'b',
            S_IFREG: '-', S_IFIFO: 'p',
        }.get(ftype, '?')

    @property
    def devno(self):
        """For special files, the device number is encoded in addrs[0]."""
        if self.is_special:
            return self.addrs[0]
        return None

    def dump(self, file=sys.stdout):
        """Print human-readable inode fields."""
        print(f'Inode {self.ino}:', file=file)
        print(f'  mode:  {self.mode:#06o}  {self.mode_str}', file=file)
        print(f'  nlink: {self.nlink}', file=file)
        print(f'  uid:   {self.uid}', file=file)
        print(f'  gid:   {self.gid}', file=file)
        print(f'  size:  {self.size}', file=file)
        if self.is_special:
            maj = (self.devno >> 8) & 0xFF
            minor = self.devno & 0xFF
            print(f'  rdev:  {maj},{minor}  (0x{self.devno:04x})', file=file)
        else:
            for i, a in enumerate(self.addrs):
                tag = '(direct)' if i < NDIRECT else \
                      ['(single indirect)', '(double indirect)',
                       '(triple indirect)'][i - NDIRECT]
                if a != 0 or i < NDIRECT:
                    print(f'  addr[{i:2d}]: {a:8d}  (0x{a:06x})  {tag}', file=file)
        print(f'  atime: {format_time(self.atime)}  ({self.atime})', file=file)
        print(f'  mtime: {format_time(self.mtime)}  ({self.mtime})', file=file)
        print(f'  ctime: {format_time(self.ctime)}  ({self.ctime})', file=file)


# ---------------------------------------------------------------------------
# S5Superblock - Parsed superblock
# ---------------------------------------------------------------------------

class S5Superblock:
    """Parsed s5fs superblock (struct filsys)."""

    __slots__ = ('s_isize', 's_fsize', 's_nfree', 's_free', 's_ninode',
                 's_inode', 's_flock', 's_ilock', 's_fmod', 's_ronly',
                 's_time', 's_dinfo', 's_tfree', 's_tinode',
                 's_fname', 's_fpack', 's_magic', 's_type')

    @classmethod
    def parse(cls, data):
        """Parse a 512-byte superblock."""
        sb = cls()
        off = 0
        sb.s_isize = struct.unpack_from('>H', data, off)[0]; off += 2
        sb.s_fsize = struct.unpack_from('>i', data, off)[0]; off += 4
        sb.s_nfree = struct.unpack_from('>h', data, off)[0]; off += 2
        sb.s_free = list(struct.unpack_from(f'>{NICFREE}i', data, off))
        off += NICFREE * 4
        sb.s_ninode = struct.unpack_from('>h', data, off)[0]; off += 2
        sb.s_inode = list(struct.unpack_from(f'>{NICINOD}H', data, off))
        off += NICINOD * 2
        sb.s_flock, sb.s_ilock, sb.s_fmod, sb.s_ronly = \
            struct.unpack_from('>BBBB', data, off); off += 4
        sb.s_time = struct.unpack_from('>I', data, off)[0]; off += 4
        sb.s_dinfo = list(struct.unpack_from('>4h', data, off)); off += 8
        sb.s_tfree = struct.unpack_from('>i', data, off)[0]; off += 4
        sb.s_tinode = struct.unpack_from('>H', data, off)[0]; off += 2
        sb.s_fname = cstring(data[off:off+6], 6); off += 6
        sb.s_fpack = cstring(data[off:off+6], 6); off += 6
        off += 13 * 4  # s_fill[13]
        sb.s_magic = struct.unpack_from('>I', data, off)[0]; off += 4
        sb.s_type = struct.unpack_from('>i', data, off)[0]; off += 4
        return sb

    @property
    def valid(self):
        return self.s_magic == FsMAGIC

    def dump(self, file=sys.stdout):
        """Print human-readable superblock fields."""
        print('Superblock:', file=file)
        magic_ok = 'OK' if self.s_magic == FsMAGIC else 'BAD'
        print(f'  s_magic:  0x{self.s_magic:08X}  ({magic_ok})', file=file)
        type_str = {1: '512-byte', 2: '1024-byte'}.get(self.s_type, 'unknown')
        note = '  (tool always uses 1024-byte)' if self.s_type != 2 else ''
        print(f'  s_type:   {self.s_type}  ({type_str} blocks){note}', file=file)
        print(f'  s_isize:  {self.s_isize} blocks  '
              f'({(self.s_isize - 2) * INOPB} max inodes)', file=file)
        fsize_kb = self.s_fsize * BSIZE // 1024
        print(f'  s_fsize:  {self.s_fsize} blocks  '
              f'({fsize_kb} KB / {fsize_kb // 1024} MB)', file=file)
        print(f'  s_tfree:  {self.s_tfree} blocks free', file=file)
        print(f'  s_tinode: {self.s_tinode} inodes free', file=file)
        print(f'  s_nfree:  {self.s_nfree} (free list cache entries)', file=file)
        print(f'  s_ninode: {self.s_ninode} (free inode cache entries)', file=file)
        print(f'  s_fname:  "{self.s_fname}"', file=file)
        print(f'  s_fpack:  "{self.s_fpack}"', file=file)
        print(f'  s_time:   {format_time(self.s_time)}  ({self.s_time})', file=file)
        print(f'  s_fmod:   {self.s_fmod}', file=file)
        print(f'  s_ronly:  {self.s_ronly}', file=file)


# ---------------------------------------------------------------------------
# Partition table parsing (Plexus-specific boot block format)
# ---------------------------------------------------------------------------

class Partition:
    """A single partition entry from the Plexus boot block."""

    __slots__ = ('index', 'start_sector', 'length_sectors')

    def __init__(self, index, start, length):
        self.index = index
        self.start_sector = start
        self.length_sectors = length

    @property
    def start_bytes(self):
        return self.start_sector * SECTOR

    @property
    def length_bytes(self):
        return self.length_sectors * SECTOR

    def __repr__(self):
        return (f'Partition(index={self.index}, start={self.start_sector}, '
                f'length={self.length_sectors})')


def parse_partition_table(f):
    """Parse the Plexus boot block partition table.

    Returns (partitions, boot_info) where boot_info is a dict of
    boot block fields and partitions is a list of Partition objects.
    """
    f.seek(0)
    sector0 = f.read(SECTOR)
    if len(sector0) < SECTOR:
        raise ValueError('image too small for boot block')

    # Check "pd" magic
    magic = struct.unpack_from('>H', sector0, BOOTBLOCK_PD_MAGIC_OFFSET)[0]
    if magic != BOOTBLOCK_PD_MAGIC:
        raise ValueError(
            f'no Plexus "pd" magic at offset 0x{BOOTBLOCK_PD_MAGIC_OFFSET:X}: '
            f'got 0x{magic:04X}, expected 0x{BOOTBLOCK_PD_MAGIC:04X}')

    # Parse boot block fields
    info = {}
    info['nheads'] = sector0[BB_OMTI_NHEADS]
    info['ncyls'] = struct.unpack_from('>H', sector0, BB_OMTI_NCYLS)[0]
    info['spt'] = sector0[BB_OMTI_SPT]
    info['fsbsize'] = struct.unpack_from('>H', sector0, BB_FSBSIZE)[0]
    info['bootname'] = cstring(sector0[BB_BOOTNAME:BB_BOOTNAME + 16])
    info['nodename'] = cstring(sector0[BB_NODENAME:BB_NODENAME + 16])
    info['nswap'] = struct.unpack_from('>H', sector0, BB_NSWAP)[0]
    info['swplo'] = struct.unpack_from('>H', sector0, BB_SWPLO)[0]
    info['rootdev'] = struct.unpack_from('>H', sector0, BB_ROOTDEV)[0]
    info['pipedev'] = struct.unpack_from('>H', sector0, BB_PIPEDEV)[0]
    info['dumpdev'] = struct.unpack_from('>H', sector0, BB_DUMPDEV)[0]
    info['swapdev'] = struct.unpack_from('>H', sector0, BB_SWAPDEV)[0]

    # Parse partition entries (32 pairs of 4-byte start, length)
    partitions = []
    off = BOOTBLOCK_PARTTABLE_OFFSET
    for i in range(BOOTBLOCK_MAX_SLICES):
        start, length = struct.unpack_from('>II', sector0, off)
        off += 8
        if off > SECTOR:
            break
        if start == 0 and length == 0:
            continue
        partitions.append(Partition(i, start, length))

    return partitions, info


def print_partition_table(partitions, info, file=sys.stdout):
    """Display boot block info and partition table."""
    print('Boot Block Info:', file=file)
    print(f'  Drive geometry: {info["nheads"]} heads, '
          f'{info["ncyls"]} cylinders, {info["spt"]} sectors/track', file=file)
    total_sect = info['nheads'] * info['ncyls'] * info['spt']
    print(f'  Total capacity: {total_sect} sectors '
          f'({total_sect * SECTOR // 1024 // 1024} MB)', file=file)
    print(f'  Filesystem block size: {info["fsbsize"]}', file=file)
    print(f'  Boot: {info["bootname"]}', file=file)
    if info['nodename']:
        print(f'  Node: {info["nodename"]}', file=file)
    print(f'  Swap: start={info["swplo"]}, size={info["nswap"]} '
          f'({info["nswap"] * SECTOR // 1024} KB)', file=file)
    print(f'  rootdev={info["rootdev"]}, pipedev={info["pipedev"]}, '
          f'dumpdev={info["dumpdev"]}, swapdev={info["swapdev"]}', file=file)

    # Known mount points
    mounts = {1: '/ (rootfs)', 2: '/user', 4: '/stocku'}

    print(file=file)
    print('Partition Table:', file=file)
    print(f'  {"Slice":>5}  {"Start":>10}  {"Length":>10}  '
          f'{"Start MB":>10}  {"Size MB":>10}  Mount', file=file)
    print(f'  {"-----":>5}  {"----------":>10}  {"----------":>10}  '
          f'{"----------":>10}  {"----------":>10}  -----', file=file)
    for p in partitions:
        start_mb = p.start_bytes / (1024 * 1024)
        size_mb = p.length_bytes / (1024 * 1024)
        mount = mounts.get(p.index, '')
        print(f'  {p.index:5d}  {p.start_sector:10d}  {p.length_sectors:10d}  '
              f'{start_mb:10.1f}  {size_mb:10.1f}  {mount}', file=file)


# ---------------------------------------------------------------------------
# S5Volume - Main filesystem class
# ---------------------------------------------------------------------------

class S5Volume:
    """Main class for s5fs filesystem operations."""

    def __init__(self, f, base_offset=0):
        """Open an s5fs volume.

        Args:
            f: Open file handle (binary mode).
            base_offset: Byte offset to the start of this filesystem partition.
        """
        self.f = f
        self.base = base_offset
        self._writable = hasattr(f, 'writable') and f.writable()
        self._dry_run = False

        # Read and validate superblock
        sb_data = self.read_block(SUPERB)
        self.sb = S5Superblock.parse(sb_data[:SECTOR])
        if not self.sb.valid:
            raise ValueError(
                f'invalid superblock: magic=0x{self.sb.s_magic:08X} '
                f'type={self.sb.s_type}')

        # Cache for indirect blocks (block_number -> data)
        self._indirect_cache = {}

    # ----- Block I/O -----

    def read_block(self, blkno):
        """Read a 1024-byte filesystem block."""
        self.f.seek(self.base + blkno * BSIZE)
        data = self.f.read(BSIZE)
        if len(data) < BSIZE:
            data += b'\x00' * (BSIZE - len(data))
        return data

    def write_block(self, blkno, data):
        """Write a 1024-byte filesystem block."""
        if not self._writable:
            raise IOError('image not opened for writing')
        if self._dry_run:
            print(f'  [dry-run] would write block {blkno}')
            return
        if len(data) != BSIZE:
            raise ValueError(f'block data must be {BSIZE} bytes, got {len(data)}')
        self.f.seek(self.base + blkno * BSIZE)
        self.f.write(data)

    # ----- Inode operations -----

    def _inode_location(self, ino):
        """Return (block_number, offset_in_block) for an inode number."""
        # itod: block = (ino + 2*INOPB - 1) >> INOSHIFT
        blk = (ino + 2 * INOPB - 1) >> INOSHIFT
        # itoo: offset = ((ino - 1) % INOPB) * INODE_SIZE
        off = ((ino - 1) % INOPB) * INODE_SIZE
        return blk, off

    def read_inode(self, ino):
        """Read and parse an on-disk inode by number."""
        blk, off = self._inode_location(ino)
        data = self.read_block(blk)
        return S5Inode.parse(data[off:off + INODE_SIZE], ino)

    def write_inode(self, ino, inode):
        """Write an inode back to disk."""
        blk, off = self._inode_location(ino)
        data = bytearray(self.read_block(blk))
        # Pack the inode back
        struct.pack_into('>HhHHi', data, off,
                         inode.mode, inode.nlink, inode.uid, inode.gid, inode.size)
        # Pack addresses back to 3-byte format
        for i in range(NADDR):
            addr_bytes = inode.addrs[i].to_bytes(4, 'big')
            data[off + 12 + i * 3 : off + 12 + i * 3 + 3] = addr_bytes[1:4]
        struct.pack_into('>III', data, off + 52,
                         inode.atime, inode.mtime, inode.ctime)
        self.write_block(blk, bytes(data))

    # ----- Block address mapping -----

    def get_file_block(self, inode, logical_blk):
        """Map a logical file block number to a physical disk block number.

        Returns the physical block number, or 0 for a hole (sparse file).
        """
        if logical_blk < 0:
            raise ValueError(f'negative block number: {logical_blk}')

        # Direct blocks (0-9)
        if logical_blk < NDIRECT:
            return inode.addrs[logical_blk]

        # Indirect blocks
        logical_blk -= NDIRECT

        # Determine indirection level:
        #   level 1 (single indirect): 0..255
        #   level 2 (double indirect): 256..65791
        #   level 3 (triple indirect): 65792..16843007
        for level in range(1, 4):
            span = NINDIR ** level
            if logical_blk < span:
                break
            logical_blk -= span
        else:
            raise ValueError('block number too large')

        # Start with the appropriate address from the inode
        # addrs[10] = single indirect, addrs[11] = double, addrs[12] = triple
        blkno = inode.addrs[NDIRECT + level - 1]
        if blkno == 0:
            return 0

        # Traverse indirect block chain
        for i in range(level, 0, -1):
            if blkno not in self._indirect_cache:
                self._indirect_cache[blkno] = self.read_block(blkno)
            ind_data = self._indirect_cache[blkno]

            # Extract index for this level
            shift = (i - 1) * NSHIFT
            idx = (logical_blk >> shift) & NMASK

            blkno = struct.unpack_from('>I', ind_data, idx * 4)[0]
            if blkno == 0:
                return 0

        return blkno

    def get_all_blocks(self, inode):
        """Return a list of all physical block numbers for a file."""
        if inode.size == 0:
            return []
        nblocks = (inode.size + BSIZE - 1) // BSIZE
        blocks = []
        for i in range(nblocks):
            blocks.append(self.get_file_block(inode, i))
        return blocks

    # ----- File I/O -----

    def read_file(self, ino_or_inode):
        """Read the entire contents of a file. Returns bytes."""
        if isinstance(ino_or_inode, int):
            inode = self.read_inode(ino_or_inode)
        else:
            inode = ino_or_inode

        if inode.size == 0:
            return b''

        result = bytearray()
        remaining = inode.size
        logical_blk = 0
        while remaining > 0:
            phys = self.get_file_block(inode, logical_blk)
            if phys == 0:
                # Sparse file hole
                chunk = min(BSIZE, remaining)
                result.extend(b'\x00' * chunk)
            else:
                data = self.read_block(phys)
                chunk = min(BSIZE, remaining)
                result.extend(data[:chunk])
            remaining -= chunk
            logical_blk += 1
        return bytes(result)

    # ----- Directory operations -----

    def list_dir(self, ino_or_inode):
        """List directory entries. Returns list of (ino, name) tuples."""
        if isinstance(ino_or_inode, int):
            inode = self.read_inode(ino_or_inode)
        else:
            inode = ino_or_inode

        if not inode.is_dir:
            raise ValueError(f'inode {inode.ino} is not a directory')

        entries = []
        data = self.read_file(inode)
        nentries = len(data) // 16
        for i in range(nentries):
            off = i * 16
            d_ino = struct.unpack_from('>H', data, off)[0]
            if d_ino == 0:
                continue  # deleted entry
            d_name = cstring(data[off + 2 : off + 16], DIRSIZ)
            entries.append((d_ino, d_name))
        return entries

    def resolve_path(self, path):
        """Resolve a Unix pathname to an inode number."""
        path = path.strip()
        if not path or path == '/':
            return ROOTINO

        # Start from root
        ino = ROOTINO
        parts = [p for p in path.split('/') if p]
        for i, component in enumerate(parts):
            inode = self.read_inode(ino)
            if not inode.is_dir:
                raise FileNotFoundError(
                    f'not a directory: /{"/".join(parts[:i])}')
            found = False
            for d_ino, d_name in self.list_dir(inode):
                if d_name == component:
                    ino = d_ino
                    found = True
                    break
            if not found:
                raise FileNotFoundError(f'not found: {path}')
        return ino

    # ----- High-level operations -----

    def walk(self, ino=ROOTINO, path='/'):
        """Recursively walk the filesystem tree.

        Yields (path, inode, entries) for directories and (path, inode, None)
        for non-directory files.
        """
        inode = self.read_inode(ino)
        if inode.is_dir:
            entries = self.list_dir(inode)
            yield (path, inode, entries)
            for d_ino, d_name in entries:
                if d_name in ('.', '..'):
                    continue
                child_path = path.rstrip('/') + '/' + d_name
                yield from self.walk(d_ino, child_path)
        else:
            yield (path, inode, None)

    def list_all(self, file=sys.stdout):
        """List all files in ls -l format."""
        for path, inode, entries in self.walk():
            if entries is not None:
                # Directory
                self._print_entry(path, inode, file=file)
            else:
                # File or special
                self._print_entry(path, inode, file=file)

    def _print_entry(self, path, inode, file=sys.stdout):
        """Print one ls -l style line."""
        if inode.is_special:
            maj = (inode.devno >> 8) & 0xFF
            minor = inode.devno & 0xFF
            size_str = f'{maj:3d},{minor:3d}'
        else:
            size_str = f'{inode.size:7d}'
        print(f'{inode.ino:5d} {inode.mode_str} {inode.nlink:3d} '
              f'{inode.uid:5d} {inode.gid:5d} {size_str} '
              f'{format_time(inode.mtime)} {path}', file=file)

    def extract_all(self, output_dir):
        """Extract all files to a local directory."""
        os.makedirs(output_dir, exist_ok=True)
        count = 0
        errors = 0
        for path, inode, entries in self.walk():
            local_path = os.path.join(output_dir, path.lstrip('/'))
            if inode.is_dir:
                os.makedirs(local_path, exist_ok=True)
            elif inode.is_regular:
                os.makedirs(os.path.dirname(local_path), exist_ok=True)
                try:
                    data = self.read_file(inode)
                    with open(local_path, 'wb') as out:
                        out.write(data)
                    count += 1
                except Exception as e:
                    print(f'ERROR extracting {path}: {e}', file=sys.stderr)
                    errors += 1
            elif inode.is_special:
                # Record special files as metadata
                os.makedirs(os.path.dirname(local_path), exist_ok=True)
                devno = inode.devno or 0
                maj = (devno >> 8) & 0xFF
                minor = devno & 0xFF
                dtype = 'c' if inode.is_chardev else 'b'
                # Write a placeholder noting the device
                with open(local_path + '.dev', 'w') as out:
                    out.write(f'{dtype} {maj} {minor}\n')
            elif inode.is_fifo:
                os.makedirs(os.path.dirname(local_path), exist_ok=True)
                with open(local_path + '.fifo', 'w') as out:
                    out.write('fifo\n')
            else:
                print(f'SKIP {path}: unknown type 0o{inode.mode & S_IFMT:06o}',
                      file=sys.stderr)

        print(f'Extracted {count} files to {output_dir}', file=sys.stderr)
        if errors:
            print(f'{errors} errors', file=sys.stderr)

    def cat(self, path):
        """Return the contents of a file by path."""
        ino = self.resolve_path(path)
        inode = self.read_inode(ino)
        if inode.is_dir:
            raise IsADirectoryError(f'{path} is a directory')
        return self.read_file(inode)

    # ----- Write operations -----

    def _write_superblock(self):
        """Write the superblock back to disk."""
        data = bytearray(self.read_block(SUPERB))
        off = 0
        struct.pack_into('>H', data, off, self.sb.s_isize); off += 2
        struct.pack_into('>i', data, off, self.sb.s_fsize); off += 4
        struct.pack_into('>h', data, off, self.sb.s_nfree); off += 2
        for i, blk in enumerate(self.sb.s_free):
            struct.pack_into('>i', data, off + i * 4, blk)
        off += NICFREE * 4
        struct.pack_into('>h', data, off, self.sb.s_ninode); off += 2
        for i, ino in enumerate(self.sb.s_inode):
            struct.pack_into('>H', data, off + i * 2, ino)
        off += NICINOD * 2
        struct.pack_into('>BBBB', data, off,
                         self.sb.s_flock, self.sb.s_ilock,
                         self.sb.s_fmod, self.sb.s_ronly); off += 4
        struct.pack_into('>I', data, off, self.sb.s_time); off += 4
        for i, d in enumerate(self.sb.s_dinfo):
            struct.pack_into('>h', data, off + i * 2, d)
        off += 8
        struct.pack_into('>i', data, off, self.sb.s_tfree); off += 4
        struct.pack_into('>H', data, off, self.sb.s_tinode); off += 2
        data[off:off+6] = self.sb.s_fname.encode('ascii').ljust(6, b'\x00')[:6]
        off += 6
        data[off:off+6] = self.sb.s_fpack.encode('ascii').ljust(6, b'\x00')[:6]
        off += 6
        # s_fill stays as-is
        off += 13 * 4
        struct.pack_into('>I', data, off, self.sb.s_magic); off += 4
        struct.pack_into('>i', data, off, self.sb.s_type)
        self.write_block(SUPERB, bytes(data))

    def alloc_block(self):
        """Allocate a free block from the free list. Returns block number."""
        if self.sb.s_nfree <= 0:
            raise RuntimeError('no free blocks')

        self.sb.s_nfree -= 1
        blkno = self.sb.s_free[self.sb.s_nfree]
        self.sb.s_free[self.sb.s_nfree] = 0

        if blkno == 0:
            raise RuntimeError('no free blocks')

        if self.sb.s_nfree == 0:
            # The allocated block contains the next batch of the free list
            data = self.read_block(blkno)
            self.sb.s_nfree = struct.unpack_from('>i', data, 0)[0]
            for i in range(NICFREE):
                self.sb.s_free[i] = struct.unpack_from('>i', data, 4 + i * 4)[0]

        self.sb.s_tfree -= 1
        return blkno

    def free_block(self, blkno):
        """Return a block to the free list."""
        if self.sb.s_nfree >= NICFREE:
            # Write current free list into the block being freed
            data = bytearray(BSIZE)
            struct.pack_into('>i', data, 0, self.sb.s_nfree)
            for i in range(NICFREE):
                struct.pack_into('>i', data, 4 + i * 4, self.sb.s_free[i])
            self.write_block(blkno, bytes(data))
            self.sb.s_nfree = 0

        self.sb.s_free[self.sb.s_nfree] = blkno
        self.sb.s_nfree += 1
        self.sb.s_tfree += 1

    def alloc_inode(self):
        """Allocate a free inode. Returns inode number."""
        if self.sb.s_ninode <= 0:
            # Scan inode list for free inodes
            self._refill_free_inodes()
            if self.sb.s_ninode <= 0:
                raise RuntimeError('no free inodes')

        self.sb.s_ninode -= 1
        ino = self.sb.s_inode[self.sb.s_ninode]
        self.sb.s_inode[self.sb.s_ninode] = 0
        self.sb.s_tinode -= 1
        return ino

    def _refill_free_inodes(self):
        """Scan the inode list to refill the superblock free inode cache."""
        max_ino = (self.sb.s_isize - 2) * INOPB
        count = 0
        for ino in range(ROOTINO, max_ino + 1):
            if count >= NICINOD:
                break
            inode = self.read_inode(ino)
            if inode.mode == 0:
                self.sb.s_inode[count] = ino
                count += 1
        self.sb.s_ninode = count

    def free_inode(self, ino):
        """Return an inode to the free list."""
        # Zero the inode on disk
        inode = S5Inode()
        inode.ino = ino
        self.write_inode(ino, inode)
        # Add to superblock cache if room
        if self.sb.s_ninode < NICINOD:
            self.sb.s_inode[self.sb.s_ninode] = ino
            self.sb.s_ninode += 1
        self.sb.s_tinode += 1

    def _add_block_to_file(self, inode, logical_blk, phys_blk):
        """Set a logical block mapping in an inode (direct blocks only for now)."""
        if logical_blk < NDIRECT:
            inode.addrs[logical_blk] = phys_blk
        elif logical_blk < NDIRECT + NINDIR:
            # Single indirect
            idx = logical_blk - NDIRECT
            if inode.addrs[NDIRECT] == 0:
                ind_blk = self.alloc_block()
                self.write_block(ind_blk, b'\x00' * BSIZE)
                inode.addrs[NDIRECT] = ind_blk
            ind_data = bytearray(self.read_block(inode.addrs[NDIRECT]))
            struct.pack_into('>I', ind_data, idx * 4, phys_blk)
            self.write_block(inode.addrs[NDIRECT], bytes(ind_data))
        else:
            raise NotImplementedError(
                'writing files larger than single-indirect not implemented')

    def create_file(self, vol_path, local_file):
        """Create a file in the filesystem from a local file."""
        with open(local_file, 'rb') as lf:
            file_data = lf.read()

        # Resolve parent directory
        parts = [p for p in vol_path.strip('/').split('/') if p]
        if not parts:
            raise ValueError('invalid path')
        filename = parts[-1]
        if len(filename) > DIRSIZ:
            raise ValueError(f'filename too long (max {DIRSIZ}): {filename}')
        parent_path = '/' + '/'.join(parts[:-1]) if len(parts) > 1 else '/'
        parent_ino = self.resolve_path(parent_path)
        parent_inode = self.read_inode(parent_ino)
        if not parent_inode.is_dir:
            raise ValueError(f'{parent_path} is not a directory')

        # Check file doesn't already exist
        for d_ino, d_name in self.list_dir(parent_inode):
            if d_name == filename:
                raise FileExistsError(f'{vol_path} already exists')

        # Allocate inode
        new_ino = self.alloc_inode()
        new_inode = S5Inode()
        new_inode.ino = new_ino
        new_inode.mode = S_IFREG | 0o644
        new_inode.nlink = 1
        new_inode.uid = 0
        new_inode.gid = 0
        new_inode.size = len(file_data)
        now = int(time.time())
        new_inode.atime = now
        new_inode.mtime = now
        new_inode.ctime = now

        # Write data blocks
        nblocks = (len(file_data) + BSIZE - 1) // BSIZE if file_data else 0
        for i in range(nblocks):
            blk = self.alloc_block()
            chunk = file_data[i * BSIZE : (i + 1) * BSIZE]
            if len(chunk) < BSIZE:
                chunk = chunk + b'\x00' * (BSIZE - len(chunk))
            self.write_block(blk, chunk)
            self._add_block_to_file(new_inode, i, blk)

        self.write_inode(new_ino, new_inode)

        # Add directory entry
        self._add_dir_entry(parent_ino, new_ino, filename)

        # Write updated superblock
        self._write_superblock()

        if self._dry_run:
            print(f'  [dry-run] would create {vol_path} '
                  f'({len(file_data)} bytes, inode {new_ino})')
        else:
            print(f'Created {vol_path} ({len(file_data)} bytes, inode {new_ino})',
                  file=sys.stderr)

    def mkdir(self, vol_path):
        """Create a directory in the filesystem."""
        parts = [p for p in vol_path.strip('/').split('/') if p]
        if not parts:
            raise ValueError('invalid path')
        dirname = parts[-1]
        if len(dirname) > DIRSIZ:
            raise ValueError(f'directory name too long (max {DIRSIZ}): {dirname}')
        parent_path = '/' + '/'.join(parts[:-1]) if len(parts) > 1 else '/'
        parent_ino = self.resolve_path(parent_path)
        parent_inode = self.read_inode(parent_ino)
        if not parent_inode.is_dir:
            raise ValueError(f'{parent_path} is not a directory')

        # Check doesn't exist
        for d_ino, d_name in self.list_dir(parent_inode):
            if d_name == dirname:
                raise FileExistsError(f'{vol_path} already exists')

        # Allocate inode and a data block for . and ..
        new_ino = self.alloc_inode()
        data_blk = self.alloc_block()

        new_inode = S5Inode()
        new_inode.ino = new_ino
        new_inode.mode = S_IFDIR | 0o755
        new_inode.nlink = 2  # . and parent's entry
        new_inode.uid = 0
        new_inode.gid = 0
        now = int(time.time())
        new_inode.atime = now
        new_inode.mtime = now
        new_inode.ctime = now

        # Build directory block with . and ..
        dir_data = bytearray(BSIZE)
        struct.pack_into('>H', dir_data, 0, new_ino)
        dir_data[2:2+len(b'.')] = b'.'
        struct.pack_into('>H', dir_data, 16, parent_ino)
        dir_data[18:18+len(b'..')] = b'..'
        new_inode.size = 32  # 2 entries
        new_inode.addrs[0] = data_blk

        self.write_block(data_blk, bytes(dir_data))
        self.write_inode(new_ino, new_inode)

        # Add entry in parent
        self._add_dir_entry(parent_ino, new_ino, dirname)

        # Increment parent nlink (for ..)
        parent_inode = self.read_inode(parent_ino)
        parent_inode.nlink += 1
        self.write_inode(parent_ino, parent_inode)

        self._write_superblock()

        if self._dry_run:
            print(f'  [dry-run] would mkdir {vol_path} (inode {new_ino})')
        else:
            print(f'Created directory {vol_path} (inode {new_ino})',
                  file=sys.stderr)

    def rm(self, vol_path):
        """Remove a file from the filesystem."""
        parts = [p for p in vol_path.strip('/').split('/') if p]
        if not parts:
            raise ValueError('cannot remove root')
        filename = parts[-1]
        parent_path = '/' + '/'.join(parts[:-1]) if len(parts) > 1 else '/'
        parent_ino = self.resolve_path(parent_path)

        # Find the file
        target_ino = None
        for d_ino, d_name in self.list_dir(parent_ino):
            if d_name == filename:
                target_ino = d_ino
                break
        if target_ino is None:
            raise FileNotFoundError(f'{vol_path} not found')

        target_inode = self.read_inode(target_ino)
        if target_inode.is_dir:
            # Check empty (only . and ..)
            entries = self.list_dir(target_inode)
            real_entries = [e for e in entries if e[1] not in ('.', '..')]
            if real_entries:
                raise OSError(f'directory not empty: {vol_path}')

        # Free all data blocks
        if not target_inode.is_special:
            for blkno in self.get_all_blocks(target_inode):
                if blkno != 0:
                    self.free_block(blkno)
            # Free indirect blocks too
            for i in range(NDIRECT, NADDR):
                if target_inode.addrs[i] != 0:
                    self._free_indirect_blocks(target_inode.addrs[i],
                                                i - NDIRECT + 1)

        # Free the inode
        self.free_inode(target_ino)

        # Remove directory entry
        self._remove_dir_entry(parent_ino, filename)

        # If removing a directory, decrement parent nlink
        if target_inode.is_dir:
            parent_inode = self.read_inode(parent_ino)
            parent_inode.nlink -= 1
            self.write_inode(parent_ino, parent_inode)

        self._write_superblock()

        if self._dry_run:
            print(f'  [dry-run] would remove {vol_path}')
        else:
            print(f'Removed {vol_path}', file=sys.stderr)

    def _free_indirect_blocks(self, blkno, level):
        """Recursively free indirect blocks."""
        if blkno == 0 or level <= 0:
            return
        if level > 1:
            data = self.read_block(blkno)
            for i in range(NINDIR):
                child = struct.unpack_from('>I', data, i * 4)[0]
                if child != 0:
                    self._free_indirect_blocks(child, level - 1)
        self.free_block(blkno)

    def _add_dir_entry(self, parent_ino, child_ino, name):
        """Add a directory entry to a directory."""
        parent_inode = self.read_inode(parent_ino)
        dir_data = bytearray(self.read_file(parent_inode))

        # Look for a free slot (d_ino == 0)
        nentries = len(dir_data) // 16
        slot = None
        for i in range(nentries):
            d_ino = struct.unpack_from('>H', dir_data, i * 16)[0]
            if d_ino == 0:
                slot = i
                break

        if slot is not None:
            off = slot * 16
            struct.pack_into('>H', dir_data, off, child_ino)
            name_bytes = name.encode('ascii')[:DIRSIZ].ljust(DIRSIZ, b'\x00')
            dir_data[off + 2 : off + 16] = name_bytes
        else:
            # Append new entry
            entry = struct.pack('>H', child_ino) + \
                    name.encode('ascii')[:DIRSIZ].ljust(DIRSIZ, b'\x00')
            dir_data.extend(entry)
            parent_inode.size = len(dir_data)

        # Write back directory data blocks
        nblocks = (len(dir_data) + BSIZE - 1) // BSIZE
        for i in range(nblocks):
            phys = self.get_file_block(parent_inode, i)
            if phys == 0:
                phys = self.alloc_block()
                self._add_block_to_file(parent_inode, i, phys)
            chunk = dir_data[i * BSIZE : (i + 1) * BSIZE]
            if len(chunk) < BSIZE:
                chunk = chunk + b'\x00' * (BSIZE - len(chunk))
            self.write_block(phys, bytes(chunk))

        parent_inode.size = len(dir_data)
        self.write_inode(parent_ino, parent_inode)

    def _remove_dir_entry(self, parent_ino, name):
        """Remove a directory entry by name (sets d_ino to 0)."""
        parent_inode = self.read_inode(parent_ino)
        dir_data = bytearray(self.read_file(parent_inode))

        nentries = len(dir_data) // 16
        for i in range(nentries):
            off = i * 16
            d_ino = struct.unpack_from('>H', dir_data, off)[0]
            if d_ino == 0:
                continue
            d_name = cstring(dir_data[off + 2 : off + 16], DIRSIZ)
            if d_name == name:
                # Zero out the inode number
                struct.pack_into('>H', dir_data, off, 0)
                # Write back the affected block
                blk_idx = (off // BSIZE)
                blk_off = blk_idx * BSIZE
                phys = self.get_file_block(parent_inode, blk_idx)
                chunk = dir_data[blk_off : blk_off + BSIZE]
                if len(chunk) < BSIZE:
                    chunk = chunk + b'\x00' * (BSIZE - len(chunk))
                self.write_block(phys, bytes(chunk))
                return
        raise FileNotFoundError(f'{name} not found in directory')


# ---------------------------------------------------------------------------
# Image file handling (supports .gz)
# ---------------------------------------------------------------------------

class GzipWrapper:
    """Read-only wrapper around a gzip file that supports seeking."""

    def __init__(self, path):
        self._path = path
        # Decompress entirely into memory for seekable access
        with gzip.open(path, 'rb') as gz:
            self._data = gz.read()
        self._pos = 0

    def seek(self, offset, whence=0):
        if whence == 0:
            self._pos = offset
        elif whence == 1:
            self._pos += offset
        elif whence == 2:
            self._pos = len(self._data) + offset
        self._pos = max(0, min(self._pos, len(self._data)))

    def tell(self):
        return self._pos

    def read(self, n=-1):
        if n < 0:
            result = self._data[self._pos:]
            self._pos = len(self._data)
        else:
            result = self._data[self._pos:self._pos + n]
            self._pos += len(result)
        return result

    def writable(self):
        return False

    def close(self):
        self._data = None

    def __enter__(self):
        return self

    def __exit__(self, *args):
        self.close()


def open_image(path, writable=False):
    """Open a disk image file, handling .gz transparently."""
    if path.endswith('.gz'):
        if writable:
            raise ValueError('cannot write to .gz images directly; '
                             'decompress first')
        return GzipWrapper(path)
    mode = 'r+b' if writable else 'rb'
    return open(path, mode)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description='s5fs filesystem tool for Plexus P/20 disk images',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''\
examples:
  %(prog)s disk.img --info
  %(prog)s disk.img -p1 --dump-super
  %(prog)s disk.img -p1 -l
  %(prog)s disk.img -p1 --cat /etc/passwd
  %(prog)s disk.img -p1 -o /tmp/rootfs
  %(prog)s disk.img -p1 --dump-inode 2
''')

    parser.add_argument('image', help='disk image file (.img or .img.gz)')

    # Partition selection
    pgroup = parser.add_mutually_exclusive_group()
    pgroup.add_argument('-p', '--partition', type=int, metavar='N',
                        help='select partition N from the partition table')
    pgroup.add_argument('--offset', type=lambda x: int(x, 0), metavar='BYTES',
                        help='manual byte offset to filesystem start')

    # Read operations
    parser.add_argument('--info', action='store_true',
                        help='show partition table from boot block')
    parser.add_argument('--dump-super', action='store_true',
                        help='dump superblock metadata')
    parser.add_argument('--dump-inode', type=int, metavar='N',
                        help='dump inode N')
    parser.add_argument('-l', '--list', action='store_true',
                        help='list all files and directories')
    parser.add_argument('--cat', metavar='PATH',
                        help='print file contents to stdout')
    parser.add_argument('-o', '--output', metavar='DIR',
                        help='extract all files to directory')

    # Write operations
    parser.add_argument('--create', nargs=2, metavar=('VOL_PATH', 'LOCAL_FILE'),
                        help='write a local file into the image')
    parser.add_argument('--mkdir', metavar='VOL_PATH',
                        help='create a directory')
    parser.add_argument('--rm', metavar='VOL_PATH',
                        help='remove a file or empty directory')

    # Safety
    parser.add_argument('--backup', action='store_true',
                        help='create .bak before writing')
    parser.add_argument('--dry-run', action='store_true',
                        help='show what would change without writing')

    args = parser.parse_args()

    # Determine if we need write access
    need_write = args.create or args.mkdir or args.rm
    if need_write and args.dry_run:
        need_write = False  # dry-run doesn't actually write

    # --info doesn't need a partition
    if args.info:
        with open_image(args.image) as f:
            partitions, info = parse_partition_table(f)
            print_partition_table(partitions, info)
        if not any([args.dump_super, args.dump_inode is not None,
                    args.list, args.cat, args.output,
                    args.create, args.mkdir, args.rm]):
            return

    # Determine partition offset
    if args.partition is not None or args.offset is not None:
        pass  # will be resolved below
    elif not args.info:
        # Need a partition for non-info operations
        if any([args.dump_super, args.dump_inode is not None,
                args.list, args.cat, args.output,
                args.create, args.mkdir, args.rm]):
            parser.error('specify -p/--partition or --offset to select a filesystem')

    # Backup if needed
    if need_write and args.backup and not args.image.endswith('.gz'):
        bak = args.image + '.bak'
        if not os.path.exists(bak):
            shutil.copy2(args.image, bak)
            print(f'Backup: {bak}', file=sys.stderr)

    # Open image
    with open_image(args.image, writable=need_write) as f:
        # Resolve partition offset
        base_offset = 0
        if args.offset is not None:
            base_offset = args.offset
        elif args.partition is not None:
            partitions, _ = parse_partition_table(f)
            found = None
            for p in partitions:
                if p.index == args.partition:
                    found = p
                    break
            if found is None:
                avail = [str(p.index) for p in partitions]
                parser.error(
                    f'partition {args.partition} not found; '
                    f'available: {", ".join(avail)}')
            base_offset = found.start_bytes
            print(f'Partition {args.partition}: offset {base_offset} bytes '
                  f'({found.length_sectors} sectors, '
                  f'{found.length_bytes // 1024 // 1024} MB)',
                  file=sys.stderr)

        # Now dispatch operations that need a filesystem
        if not any([args.dump_super, args.dump_inode is not None,
                    args.list, args.cat, args.output,
                    args.create, args.mkdir, args.rm]):
            return

        vol = S5Volume(f, base_offset)
        if args.dry_run:
            vol._dry_run = True

        if args.dump_super:
            vol.sb.dump()

        if args.dump_inode is not None:
            inode = vol.read_inode(args.dump_inode)
            inode.dump()

        if args.list:
            vol.list_all()

        if args.cat:
            data = vol.cat(args.cat)
            sys.stdout.buffer.write(data)

        if args.output:
            vol.extract_all(args.output)

        if args.create:
            vol_path, local_file = args.create
            vol.create_file(vol_path, local_file)

        if args.mkdir:
            vol.mkdir(args.mkdir)

        if args.rm:
            vol.rm(args.rm)


if __name__ == '__main__':
    try:
        main()
    except (FileNotFoundError, IsADirectoryError, FileExistsError,
            ValueError, OSError) as e:
        print(f'error: {e}', file=sys.stderr)
        sys.exit(1)
    except KeyboardInterrupt:
        sys.exit(130)
