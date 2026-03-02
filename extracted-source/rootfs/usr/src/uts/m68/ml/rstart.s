/* SID @(#)rstart.s	5.1 */

#include "sys/param.h"
#include "sys/mc146818.h"
#include "sys/mtpr.h"
#include "sys/usart.h"
#include "sys/page.h"
#include "sys/psl.h"

/*
 * initial code branched to by boot to bring up unix on robin
 */

#ifdef SYS3
	_u = LA_UBLK
	.globl	_u
#endif
	.text
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
 *		| max-1		       			|
 *		|---------------------------------------|
 *		| max	 	stack		  q+1	|
 *		|					|
 *		|---------------------------------------| <- sp
 *
 * on the stack at the stack pointer are the arguments
 * passed from boot to the loaded program. currently these are
 * 	1. the physical page number of the next available page.
 *	2. size of the memory in 256*K banks
 */

/* throughout d2 contains next available page */

_start:
start:
	moveq	#1,d0		/* set up for user date access */
	.word	0x4e7b		/* movec	d0,sfc*/
	.word	0x0
	.word	0x4e7b		/* movec	d0,dfc*/
	.word	0x1
	movl	sp@+,d2		/* save next pg (from boot) */
	movl	sp@,d3		/* memsize in 256K banks */

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
	movl	#_u,sp
#else
	lea	_u,sp		/* start of ublk */
#endif
	lea	sp@(USIZE*NBPC),sp /* set system stk ptr */
	lea	0:w,a6		/* init sys frame ptr */

	/*
	 * In register d3 is memory size.
	 * passed in by boot as an argument.
	 */
	moveq	#2,d0		/* assume worst case */
	cmpl	#32,d3		/* if greater than 8 Mb must be bad */
	bgt	out
	movl	d3,d0		/* memsize is set to what boot passed us */
out:
	lsll	#6,d0		/* bank -> page */
	subql	#1,d0		/* highest page */

	pea	star3
	movl	d0,sp@-	
	movl	d2,sp@-
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
	jsr	_main
	tstl	d0
	bne	star5		/* branch for system */
#ifdef SYS3
	movl	#0x7ff000,a0	/* user stack top */
#else
	movl	#USRSTACK,a0	/* user stack top */
#endif
	movl	a0,usp		/* set user sp */
	clrw	sp@-		/* set format code for 68010 */
	clrl	sp@-		/* user pc */
	clrw	sp@-		/* user sr */
	rte			/* go to user */

star5:
	movl	d0,a0
	clrw	sp@-		/* set format code for 68010 */
	pea	star6		/* pc */
	movw	#PSR_S,sp@-	/* kernel mode */
	rte

star6:
	jsr	a0@

