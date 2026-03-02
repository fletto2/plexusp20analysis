/* @(#)page.h	1.8 SID */
/* @(#)page.h	6.1 */
/*
 * VAX page table entry
 */

#ifdef m68
#ifndef robin
#define PG_PFNUM	0xfff		/* should include PG_RAM??? */
#define PG_RAM		0x8000
#define PG_MAPID	0xff0000
#define PG_PROT		0x38000000
#define PG_NOEX		0x08000000
#define PG_NOWR		0x10000000
#define PG_NORD		0x20000000
#define PG_MOD		0x40000000
#define PG_REF		0x80000000
#define PG_INV		0x38000000
#define ptomid(x)	((x) << 16)
#else
#define PG_PFNUM	0xfff
#define PG_RAM		0
#define PG_MAPID	0xff000000
#define PG_PROT		0xe000
#define PG_NOEX		0x2000
#define PG_NOWR		0x4000
#define PG_NORD		0x8000
#define PG_MOD		0x00010000
#define PG_REF		0x00020000
#define PG_INV		0xe000
#define ptomid(x)	((x) << 24)
#endif


#define	svtopte(X)	((int *)SMLO + btoc(X))

/*
 * address space definitions
 */
#define ULMLO		0x0		/* user log mem */
#define ULMHI		0x800000	/* user log mem */
#define UMLO		0x900000	/* user (page) map mem */
#define UMHI		0x902000	/* user (page) map mem */

#define SLMLO		0x0		/* sys log mem */
#define XLMLO		0x600000	/* sys log block mover mem */
#define XLMHI		0x700000	/* sys log block mover mem */
#define SLMHI		0x780000	/* sys log mem */
#define SLBLO		0x780000	/* sys log blk dma */
#define SLBHI		0x7c0000	/* sys log blk dma */
#define SLCLO		0x7c0000	/* sys log char dma */
#define SLCHI		0x800000	/* sys log char dma */

#define SMLO		0x902000	/* sys (page) map mem */
#define SMHI		0x903e00	/* sys (page) map mem */
#define BMLO		0x903e00	/* sys (page) map blk dma */
#define BMHI		0x903f00	/* sys (page) map blk dma */
#define CMLO		0x903f00	/* sys (page) map char dma */
#define CMHI		0x904000	/* sys (page) map char dma */
#define XMLO		0x903800	/* sys (page) map blk mover */
#define XMHI		0x903c00	/* sys (page) map blk mover */

#define PLMLO		0x800000	/* prom mem */
#define PLMHI		0x810000	/* prom mem */

#define CLMLO		0x980000	/* cache log mem */
#define CLMHI		0x981000	/* cache log mem */
#define CPMLO		0x9c0000	/* cache page/dirty */
#define CPMHI		0x9c1000	/* cache page/dirty */

#define MBILO		0xb00000	/* multibus i/o low */
#define MBIHI		0xb10000	/* multibus i/o hi */
#define MBMLO		0xb80000	/* multibus mem low */
#define MBMHI		0xc00000	/* multibus mem hi */
#ifdef robin
#define DLMLO		0xc00000	/* static memory lo */
#define DLMHI		0xc04000	/* static memory hi */
#ifndef BOOTSTART
#define BOOTSTART	0x808004	/* address of address of boot start */
#endif
#endif
/*	defines for siinit	*/
#define SMLOCLO	0x903fc0	/* first page for smalloc */
#define SMLOCPG 0xf		/* 15 pages for smalloc */
#endif

#ifdef vax
struct pt_entry {
	unsigned pg_pfnum:21,	/* Page frame number */
		pg_dec2:2,	/* Reserved for DEC */
		pg_type:2,	/* Type of page (user definable) */
		pg_dec1:1,	/* Reserved for DEC */
		pg_m:1,		/* Modified bit */
		pg_prot:4,	/* Protection */
		pg_v:1;		/* Valid */
};

#define	PG_PFNUM	0x1fffff
#define	PG_M	0x04000000
#define	PG_PROT	0x78000000
#define	PG_V	0x80000000
#define	PG_TYPE	0x01800000

#define	PG_NOACC	0
#define	PG_KR	0x18000000
#define	PG_KW	0x10000000
#define	PG_UW	0x20000000
#define	PG_URKW	0x60000000
#define	PG_URKR	0x78000000

/*	Definition of a virtual address.	*/
struct vaddress {
	unsigned v_byte:9,	/* Byte within the page */
		v_vpn:21,	/* Virtual page number */
		v_region:2;	/* Region of memory(system,user,data,stack) */
};

/*	Definition of a physical address.	*/
struct paddress {
	unsigned p_byte:9,	/* Byte within the page */
		p_pfn:21,	/* Page frame number */
		p_mbz:2;	/* Must be zero */
};
#define	SYSVA	0x80000000
#define	svtoc(X)	(((int)(X) >> 9) & PG_PFNUM)
#define	ctosv(X)	(((int)(X) << 9) + SYSVA)
#define	ctopv(X)	((int)(X) << 9)
#define	svtopte(X)	(sbrpte + svtoc(X))
extern int * sbrpte;
#endif
