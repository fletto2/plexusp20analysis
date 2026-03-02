/* SID @(#)start.s	5.4 */
#ifdef robin
#include "rstart.s"
#else

#include "sys/param.h"
#include "sys/mc146818.h"
#include "sys/mtpr.h"
#include "sys/usart.h"
#include "sys/page.h"
#include "sys/psl.h"

/*
 * initial code branched to by boot to bring up unix
 */

#ifdef SYS3
	_u = LA_UBLK
	.globl	_u
#endif
#if defined(SCHROEDER) || defined(KICKER)
	.data
	.even
	.globl	_isfpu
_isfpu:	.word	0
	.globl	initfp
initfp:	.word	0
	.globl	_ufpstk
#endif

	.text
.globl	_berrflg
.globl _start
.globl start
.globl _main
#ifdef SYS3
.globl _rsavadd
.globl _getpadd
#else
.globl _rsavaddr
.globl _getpaddr
#endif

/*
 * at this point logical and physical memory looks like:
 *
 *			LOG		   PHYS
 *		-----------------------------------------
 *		| 0				 m+1	|
 *		| 1		text		 m+2	|
 *		|...				 ...	|
 *		| A				  q	|
 *		|---------------------------------------|
 *		| A+1				  0	|
 *		| A+2 		data		  1	|
 *		| ...				  2	|
 *		|				  ...	|
 *		| B				  n	|
 *		|---------------------------------------|
 *		| B+1 				  n+1	|
 *		| B+2		bss		  n+2	|
 *		| ...				  ...	|
 *		|  C				   m	|
 *		|---------------------------------------|
 *		| C+1					|
 *		|					|
 *		| ...		INVALID			|
 *		|					|
 *		| max-3					|
 *		|---------------------------------------|
 *		| max-2 boot tmp pg 0-mapped to scr ram |
 *		|---------------------------------------|
 *		| max-1		INVALID			|
 *		|---------------------------------------|
 *		| max	 	stack		  q+1	|
 *		|					|
 *		|---------------------------------------| <- sp
 *
 * on the stack at the stack pointer is (are) the argument(s)
 * passed from boot to the loaded program. currently this
 * is a single arg whose value is q+2, i.e. the physical
 * page number of the next available page.
 */

/* throughout d2 contains next available page */

_start:
start:
#if defined(SCHROEDER) || defined(KICKER)

	movl	#0,d0		/* set vector base register to 0 */
	movec	d0,vbr

#endif
	movl	sp@+,d2		/* save next pg (from boot) */

	movl	SMHI-4,CMHI-4	/* setup cdma map for i/o pg  */
	movl	#NBPC-1,d0	/* dbf loop count */
	movl	#LA_SYSIO,a0
.L1:	clrb	a0@+		/* clear i/o pg */
	dbf	d0,.L1

	movl	d2,d0		/* next pg will be UBLK */
	addql	#USIZE,d2	/* bump to next avail pg */
	movl	d0,SMHI-16	/* map ublk pg for system */
	movl	#USIZE*NBPC-1,d0	/* dbf loop count */
#ifdef SYS3
	movl	#_u,a0
#else
	lea	_u,a0
#endif
.L2:	clrb	a0@+		/* clear UBLK */
	dbf	d0,.L2

#ifdef SYS3
	movl	#_u,a0
#else
	lea	_u,a0		/* start of ublk */
#endif
	movl	a0,d0
	addl	#USIZE*NBPC,d0 
	movl	d0,sp		/* set system stk ptr */
	movl	#0,a6		/* init sys frame ptr */
	movb	P_USA+P_USCMD,d0
	andb	#~B_TXRDY,d0		| turn off xmitter
	movb	d0,P_USA+P_USCMD

	movb	P_USB+P_USCMD,d0
	andb	#~B_TXRDY,d0		| turn off xmitter
	movb	d0,P_USB+P_USCMD
	movb	CALREGB,d0		/* get mode bits */
	movb	#B_CPIE+B_CAIE+B_CUIE,d1/* int bits */
	notb	d1
	andb	d1,d0
	movb	d0,CALREGB		/* disable ints but keep running */
	movb	CALREGC,d0		/* reset/turn off clk */

	/*
	 * size memory
	 */
#ifdef KICKER
	movl	#kbuserr,d0
	movl	d0,_berrflg
#endif
	movl	d2,d0		/* next avail page */
	lsrl	#6,d0		/* bank # */
#if defined(SCHROEDER) || defined(KICKER)
	movl	#18,d4		/* shift count to get number of bytes */
#else
	movl	#10,d4
#endif
	jmp	.L11
.L10:
	addql	#1,d0		/* next bank */
.L11:
	movl	d0,d3		/* bank # */
	cmpl	#MAXBANK,d3	/* past max bank? */
	beq	.L98		/* branch if yes */
	lsll	d4,d3		/* to address latch */
#if defined(SCHROEDER) || defined(KICKER)
	movl	#RLATCH + P_PHYSMEMC,a0	/* to generate mem board latch addr */
#else
	movl	#RLATCH,a0	/* to generate mem board latch addr */
#endif
	addl	d3,a0		/* generate full latch addr */
	movw	a0@,d5		/* read latch */
	andl	#B_0EXIST,d5	/* if exists bit low, mem bank is there */
	beq	.L10		/* loop until non existent bank found */
.L98:				/* now d0 points to non existant bank */
	lsll	#6,d0		/* bank -> page */
	subql	#1,d0		/* highest page */

	pea	star3
	movl	d0,sp@-	
	movl	d2,sp@-
#if defined(SCHROEDER) || defined(KICKER)
/* set up DFC and SFC for moves */
	movl	#1,d0
	movec	d0,sfc
	movec	d0,dfc
#endif
	/* mlsetup(nextpage, lastpage, startpc) */
	jsr	_mlsetup
	addql	#8,sp
	/* switch to proc 0 */
#ifdef SYS3
	jsr	_rsavadd
#else
	jsr	_rsavaddr
#endif
	movl	d0,sp@-		/* push &u.u_rsav for resume */
#ifdef SYS3
	jsr	_getpadd
#else
	jsr	_getpaddr
#endif
	movl	d0,sp@-		/* push p.p_addr for resume */
	jsr	_resume
	/* no return */

star3:
	/* main returns pc for new process */
	andw	#~PSR_I,sr	/* enable ints */
#if defined(SCHROEDER) || defined(KICKER)
	addqw	#1,initfp	| indicate initial access to float point unit
	movl	_ufpstk,a0
	.word	0xf350		| frestore a0@ to reset chip
	.word	0xf310		| fsave	a0@ test if chip is there
	tstl	a0@
	beq	.L97
	addqw	#1,_isfpu
.L97:	clrw	initfp		| clear initial state
#endif
.L99:	jsr	_main
	tstl	d0
	bne	star5		/* branch for system */
#ifdef SYS3
	movl	#0x7ff000,a0	/* user stack top */
#else
	movl	#USRSTACK,a0	/* user stack top */
#endif
	movl	a0,usp		/* set user sp */
#if defined(SCHROEDER) || defined(KICKER)
	clrw	sp@-		/* exception format */
#endif
	clrl	sp@-		/* user pc */
	clrw	sp@-		/* user sr */
	rte			/* go to user */

star5:
#if defined(SCHROEDER) || defined(KICKER)
	clrw	sp@-		/* exception format */
#endif
	movl	d0,a0
	pea	star6		/* pc */
	movw	#PSR_S,sp@-	/* kernel mode */
	rte

star6:
	jsr	a0@

#endif
#ifdef KICKER
kbuserr:
	bra	.L98		| Exit as if done
#endif
