/* SID @(#)mtpr.h	1.7 */
/* @(#)mtpr.h	6.1 */
/*
 *	VAX processor register numbers
 */

#ifdef vax
#define KSP 0		/* kernal stack pointer */
#define ESP 1		/* exec stack pointer */
#define SSP 2		/* supervisor stack pointer */
#define USP 3		/* user stack pointer */
#define ISP 4		/* interrupt stack pointer */
#define P0BR 8		/* p0 base register */
#define P0LR 9		/* p0 length register */
#define P1BR 10		/* p1 base register */
#define P1LR 11		/* p1 length register */
#define SBR 12		/* system segment base register */
#define SLR 13		/* system segment length register */
#define PCBB 16		/* process control block base */
#define SCBB 17		/* system control block base */
#define IPL 18		/* interrupt priority level */
#define ASTLVL 19	/* async. system trap level */
#define SIRR 20		/* software interrupt request */
#define SISR 21		/* software interrupt summary */
#define ICCS 24		/* interval clock control */
#define NICR 25		/* next interval count */
#define ICR 26		/* interval count */
#define TODR 27		/* time of year (day) */
#define RXCS 32		/* console receiver control and status */
#define RXDB 33		/* console receiver data buffer */
#define TXCS 34		/* console transmitter control and status */
#define TXDB 35		/* console transmitter data buffer */
#define MAPEN 56	/* memory management enable */
#define TBIA 57		/* translation buffer invalidate all */
#define TBIS 58		/* translation buffer invalidate single */
#define PMR 61		/* performance monitor enable */
#define SID 62		/* system identification */
/*
 *	VAX-11/780 specific registers
 */
#define ACCS 40		/* accelerator control and status */
#define ACCR 41		/* accelerator maintenance */
#define WCSA 44		/* WCS address */
#define WCSD 45		/* WCS data */
#define SBIFS 48	/* SBI fault and status */
#define SBIS 49		/* SBI silo */
#define SBISC 50	/* SBI silo comparator */
#define SBIMT 51	/* SBI maintenance */
#define SBIER 52	/* SBI error register */
#define SBITA 53	/* SBI timeout address */
#define SBIQC 54	/* SBI quadword clear */
#define MBRK 60		/* micro-program breakpoint */
/*
 *	VAX-11/750 specific registers
 */
#define CSRS 28		/* console storage receive status */
#define CSRD 29		/* console storage receive data */
#define CSTS 30		/* console storage transmit status */
#define CSTD 31		/* console storage transmit data */
#define TBDR 36		/* translation buffer disable register */
#define CADR 37		/* cache disable register */
#define MCESR 38	/* machine check error summary register */
#define CAER 39		/* cache error */
#define IORR 55		/* i/o reset register */
#define TB 59		/* translation buffer */
#endif

#ifdef m68
/* cpu control registers */
#ifndef robin
#define	P_CONTROL	0xaf0001
#define B_MBUNLOCK	0x1		/* 0 -> lock MB busy */
#define B_SBE		0x2		/* 0 -> disable sbe ints */

#define	P_LEDS		0xaf0003

#define P_RESET		0xaf0005
#define BOOTRESET	1
#define MEMERRRESET	2
#define BUSERRRESET	3
#define MBRESET		4
#define DEBUGRESET	5

#define	P_MAPID		0xaf0007

/* cpu status registers */

#define	P_STATUS	0xaf0001
#define M_SWITCH	0x2		/* int switch active */
#define B_DMABUSERR	0x8
#define B_MBLOCK	0x10
#define B_BUSERR	0x20
#define B_MEMERR	0x40
#define B_MBINIT	0x80

#define	P_SWITCHES	0xaf0003
#define M_BAUDRATE	0x07		/* console baud rate */
#define M_AUTOBOOT	0x08		/* autoboot switch */
#define M_CHARIO	0x30		/* console port control */
#define B_USNORM	0x00		/* normal port control */
#define B_USAPORT	0x10		/* console port A */
#define B_USBPORT	0x20		/* console port B */
#define B_USABPORT	0x30		/* console port both A and B */
#define M_STATRAM	0x40		/* static ram used at boot */
#define M_DIAGMODE	0x80		/* diagnostic startup mode */

#define	P_BUSERR	0xaf0005
#define MBTO		1
#define MMTO		2
#define MA23		4
#define MMUE		8
#define MACC		16
#define MZOI		32		/* zone of impropriety */

#define P_DMAERR	0xaf0007

#define	P_MREGERR	0xaf0009
#define B_SBEENABLED	0x2

#define	P_MADDERR	0xaf000b

#define P_RMAPID	0xaf000d

/* 2661 EPCI addresses */

#define P_USA	0xa80000		/* port A */
#define P_USB	0xa90000		/* port B */

#define P_USCTL		0x5
#define P_USCMD		0x7
#define P_USSTAT	0x3
#define P_USDATA	0x1

/* define memory board latch and register addresses */

#define DIAGLO	0xad0002	/* low edc diagnostic latch (bits 0-15) */
#define DIAGHI	0xad0080	/* high edc diagnostic latch (bits 16-31) */
#define ENBSBE	0xad0100	/* enable single bit error detection */
#define DSBSBE	0xad0180	/* disable single bit error detection */
#define RLATCH	0xad0202	/* read error status latch */
#define RSTERR	0xad0280	/* reset error flipflop */

/* define edc diagnostic latch values */

#define CODE01		0x0200	/* corresponds to DIAGLO */
#define CODE23		0x0300  /* corresponds to DIAGHI */
#define CORRECT		0x2000	/* turn on error correction */
#define PASSTHRU	0x4000	/* turn on pass thru mode (overrides others) */

#define	EDCNORM		0x0000	/* normal operation */
#define DIAGGEN		0x0800	/* diagnostic generate mode */
#define DIAGDET		0x1000	/* diagnostic detect/correct mode */
#define EDCINIT		0x1800	/* initialize memory to zero */

/* define RLATCH values */

#define M_SYNDROME	0x7f	/* mask for syndrome code */
#define B_0SBE		0x80	/* single bit err (active low) */
#define B_0DBE		0x100	/* double bit err */
#define M_BANK		0x600	/* ad18 and ad19 */
#define B_0EXIST	0x8000	/* this 256kb bank exists */


/* Motorola Real-Time Clock plus RAM chip - MC146818 */

#define	CALSECS		0xae0001
#define CALSECALARM	0xae0003
#define CALMINS		0xae0005
#define CALMINALARM	0xae0007
#define CALHRS		0xae0009
#define CALHRALARM	0xae000b
#define CALDAY		0xae000d
#define CALDATE		0xae000f
#define CALMONTH	0xae0011
#define CALYEAR		0xae0013

#define CALREGA		0xae0015	/* REGA: r/w register */
#define CALREGB		0xae0017	/* REGB: r/w register */
#define CALREGC		0xae0019	/* REGC: read only register */
#define CALREGD		0xae001b	/* REGD: read only register */

#define DISKLED		0x80
#define TAPELED		0x40
#define USERLED		0x20
#define CLKLED		0x10
#define SWAPLED		0x8

#else
	/* output register addresses for the robin */

# define O_RSEL 0xE00000	/* reset selection , see below */
# define O_SC_C 0xE00006	/* scsi byte count */
# define O_SC_P	0xE0000A	/* scsi pointer register */
# define O_SC_R	0xE0000E	/* scsi register */
# define O_LEDS	0xE00010	/* led register */
# define O_MISC 0xE00016	/* misc. functions */
# define O_KILL 0xE00018	/* kill job / dma cpu */
# define O_TRCE	0xE0001A	/* rce/ tce for usarts */
# define O_INTE	0xE0001C	/* interupt register */
# define O_MAPID 0xe0001E	/* user id register */

	/* defines for O_RSEL  reset register */

#define	R_MULTERR	0xe00020  /* reset multibus interface error flag */
#define	R_SCSI_PFLG	0xe00040  /* reset scsi parity error flag */
#define	R_JOBINT	0xe00060  /* reset job processor software int */
#define	S_JOBINT	0xe00080  /* set job processor software int */
#define	R_DMAINT	0xe000a0  /* reset dma processor software int */
#define	S_DMAINT	0xe000c0  /* set dma processor int */
#define	R_CINTJ		0xe000e0  /* reset job clock interrupt */
#define R_CINTD		0xe00100  /* reset dma clock int */
#define	R_JBERR		0xe00120  /* reset job bus error flag */
#define	R_DBERR		0xe00140  /* reset dma bus error flag */
#define	R_MPERR		0xe00160  /* reset memory parity err flag SET ON RESET*/
#define	R_SWINT		0xe00180  /* reset switch interrupt */
#define	R_SCSIBERR	0xe001a0  /* reset scsi bus error flag */

	/* input register addresses for the robin */

# define I_PERR1 0xE00000	/* parity error latch */
# define I_PERR2 0xE00002	/* parity error latch */
# define I_MBERR 0xE00004	/* latches address on multibus error */
# define I_SC_C 0xE00006	/* scsi byte count */
# define I_SC_P	0xE0000A	/* scsi pointer register */
# define I_SC_R	0xE0000E	/* scsi register */
# define I_LEDS	0xE00010	/* led register */
# define I_USRT 0xE00012	/* usart register */
# define I_ERR	0xE00014	/* misc functoins */
# define I_MISC 0xE00016	/* misc. functions */
# define I_KILL 0xE00018	/* kill job / dma cpu */
# define I_TRCE	0xE0001A	/* rce/ tce for usarts */
# define I_INTE	0xE0001C	/* interupt register */
# define I_USER 0xE0001E	/* user number */

	/* bits in I_ERR */

# define B_MBTO	0x20

	/* scsi bits in register O_SC_R */

# define IOPTR  0x8000
# define MSGPTR 0x4000
# define CDPTR  0x2000
# define S_DRAM 0x1000
# define SC_RST 0x0800
# define SC_SEL	0x0400
# define SC_BSY	0x0200
# define ARBIT	0x0100
# define SCSIREQ 0x080
# define SCSIMSG 0x040
# define SCSIRST 0x020
# define SCSIIO	0x0010
# define SCSICD	0x0008
# define SCSIATN 0x004
# define SCSIACK 0x002
# define AUTO	0x0001


	/* scsi data buffers */

# define SCDBUF0 0xA70000
# define SCDBUF1 0xA70001
# define SCDBUF2 0xA70002
# define SCDBUF3 0xA70003
# define MY_ID	0x08


	/* defines for inter processor communication */

# define DZERO 0x8000
# define JZERO 0x4000
# define MAPENBL 0x0100
# define STARTJOB 0x0002
# define KILLJOB 0x0000
# define KILLDMA 0x0001

	/* defines for which cpu handles the int . A 1 in a bit says
	   the job cpu gets it */

# define CENJOB	0x04		/* Ints to clock are seperately enalbled */
# define CENDMA	0x08

	/* defines for miscellaneous register */

#define	B_UINTEN	0x1	/* enable ups interrupt */
#define	B_TINTEN	0x2	/* enable temperature interrupt */
#define B_CINTJEN	0x4	/* enable job's clock interrupt */
#define B_CINTDEN	0x8	/* enable dma's clock interrupt */
#define B_RESMB		0x10	/* reset multibus ACTIVE LOW */
#define B_HOLDMBUS	0x20	/* hold multibus */
#define B_DIAGUART	0x40	/* disable output to ttys */
#define	B_TBUSY		0x80	/* READ only */
#define B_ENMAP		0x100	/* enable mapping (active low) */
#define B_DISMAP	0x100	/* disables map (active hi ) */
#define	B_DIAGMB	0x200	/* put multibus into diagnostic mode */
#define B_DIAGPESC	0x400	/* force parity scsi parity error */
#define	B_DIAGPH	0x800	/* force parity error low byte */
#define B_DIAGPL	0x1000	/* force parity error hi byte */
#define B_SCSIDL	0x2000	/* enable diag latch (ACTIVE LOW) */
#define B_BOOTJOB	0x4000	/* force job's A23 high (ACTIVE LOW ) */
#define B_BOOTDMA	0x8000	/* force dma's A23 high (ACTIVE LOW ) */

/* non kill bits in I_KILL */

#define	B_INTDMA 0x4		/* dma processor interrupt */
#define B_INTJOB 0x8		/* job processor interrupt */
#define B_JOBP	0x80		/* on if we are the job processor */


/* locations of the various interrupt vectors */

#define I_MBUS_INT	0xf00003
#define I_SCSI_INT	0xf00009
#define I_PANIC_INT	0xf0000f

/*  68564 usart adresses */

#define P_U0	0xa00021		/* port 0 */
#define P_U1	0xa00001		/* port 1 */
#define P_U2	0xa10021		/* port 2 */
#define P_U3	0xa10001		/* port 3 */
#define P_U4	0xa20021		/* port 4 */
#define P_U5	0xa20001		/* port 5 */
#define P_U6	0xa30001		/* port 6 */
#define P_U7	0xa30021		/* port 7 */

/* Motorola Real-Time Clock plus RAM chip - MC146818 */

#define	CALSECS		0xd00001
#define CALSECALARM	0xd00003
#define CALMINS		0xd00005
#define CALMINALARM	0xd00007
#define CALHRS		0xd00009
#define CALHRALARM	0xd0000b
#define CALDAY		0xd0000d
#define CALDATE		0xd0000f
#define CALMONTH	0xd00011
#define CALYEAR		0xd00013

#define CALREGA		0xd00015	/* REGA: r/w register */
#define CALREGB		0xd00017	/* REGB: r/w register */
#define CALREGC		0xd00019	/* REGC: read only register */
#define CALREGD		0xd0001b	/* REGD: read only register */

#define DISKLED		0x4
#define TAPELED		0x4
#define USERLED		0x2
#define CLKLED		0x2
#define SWAPLED		0x8
#define DMALED		0x1

#endif

#define LA_UBLK		0x77c000	/* user blk page address */
#define LA_SYSIO	0x7ff000	/* i/o page address */
#define MAXBANK		64		/* max # of 256Kb banks of ram */

/* pseudo hardware regions for use by expand() and callers */
#define TREGION		0
#define DREGION		1
#define SREGION		2
#endif
