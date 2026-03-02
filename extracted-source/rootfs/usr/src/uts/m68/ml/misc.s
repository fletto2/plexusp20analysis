/* @(#)misc.s	5.6 SID */

#include "sys/psl.h"
#include "sys/page.h"
#include "sys/mtpr.h"

	.text
.globl _spl0
.globl _spl1
.globl _spl2
.globl _spl3
.globl _spl4
.globl _spl5
.globl _spl6
.globl _spl7
.globl _splhi
.globl _splx

_splhi:
_spl7:
_spl6:
_spl5:
_spl4:
_spl3:
_spl2:
_spl1:
	clrl	d0
	movw	sr,d0		| return current to caller
	movw	d0,d1
	orw	#PSR_I,d1	| disable (set to level 7)
	movw	d1,sr
	rts

.globl	_spl0on			| BF 02nov84
_spl0:
	clrl	d0
	movw	sr,d0		| pass back old in d0
	movw	sr,d1
	andw	#~PSR_I,d1	| int lev 0
	movw	d1,sr
_spl0on:
	rts	
	|movw	d1,sp@-		| for rte
	|rte

.globl	_splxon			| BF 02nov84
_splx:
	movl	sp@(4),d0	| int setting from caller
	andw	#PSR_I,d0	| just int bits
	movw	sr,d1		| current int state
	andw	#~PSR_I,d1
	orw	d1,d0		| insert callers setting
	movw	d0,sr
_splxon:
	rts
	|movw	d0,sp@-		| for rte
	|rte


.globl _waitloc
.globl _idle
_idle:
	movw	sr,d0		/* save current state	 */
#ifdef SYS3
	stop
	PSR_S
#else
	stop	#PSR_S		/* system mode with ints on */
#endif
wloc:
	nop
	nop
	movw	d0,sr
	rts
	.data
_waitloc: 
	.long	wloc

	.text


#ifdef SYS3
.globl _out_mul
_out_mul:
#else
.globl _out_multibus
_out_multibus:
#endif
	movw	sr,d0		| current int state
	movl	d0,sp@-		| save it
	orw	#PSR_I,sr	| diable ints
#ifdef LUNDELL
	jsr	mblock		| lock bus
#endif
	movl	sp@(8),d0	| port
	addl	#MBILO,d0	| bump into MB addr space
	movl	d0,a0
	movl	sp@(12),d0	| byte to pump out
	movb	d0,a0@		| poke poke
	nop			| must be here to work with 68000
	nop			| JF
#ifdef LUNDELL
	jsr	mbunlock	| unlock bus
#endif
	movl	sp@+,d0		| get old int state
	movw	d0,sr		| restore state
	rts

#ifdef SYS3
.globl _in_mult
_in_mult:
#else
.globl _in_multibus
_in_multibus:
#endif
	movw	sr,d0		| current int state
	movl	d0,sp@-		| save it
	orw	#PSR_I,sr	| diable ints
#ifdef LUNDELL
	jsr	mblock		| lock bus
#endif
	movl	sp@(8),d0	| port
	addl	#MBILO,d0	| make mb addr
	movl	d0,a0
	clrl	d0		| clr high part
	movb	a0@,d0		| read port
	movl	d0,sp@-		| save over mbunlock call
#ifdef LUNDELL
	jsr	mbunlock	| unlock bus
#endif
	movl	sp@+,d0		| retrieve data
	movl	sp@+,d1		| get old int state
	movw	d1,sr		| restore state
	rts			| return w/byte in d0

/* 
 * these two local routines are used by out_multibus and
 * in_multibus to lock the bus around reads and writes
 */
.globl	_mblock
_mblock:
mblock:
#ifndef KICKER
#ifndef robin
	movb	P_CONTROL,d0
#ifdef SCHROEDER
	orb	#B_MBUNLOCK,d0
#else
	andb	#~B_MBUNLOCK,d0
#endif
	movl	#100000,d1	/* deadman timer value */
	movb	d0,P_CONTROL	| initiate MB lock
mblk1:
	subql	#1,d1		/* count down timer */
	beq	crater		/* timeout - panic */
	movb	P_STATUS,d0
	andb	#B_MBLOCK,d0	| test for MB locked
	beq	mblk1		| loop until lock is set
#endif
#endif /* KICKER */
	rts

.globl _panic
#ifdef SYS3
.globl	_mbunloc
_mbunloc:
#else
.globl	_mbunlock
_mbunlock:
#endif
mbunlock:
#ifndef KICKER
#ifndef robin
	movb	P_CONTROL,d0
#ifdef SCHROEDER
	andb	#~B_MBUNLOCK,d0
#else
	orb	#B_MBUNLOCK,d0	| set unlock 
#endif
	movb	d0,P_CONTROL	| unlock it
#endif
#endif /* KICKER */
	rts

crater:
	jsr	mbunlock
	movl	#msg,sp@-
	jsr	_panic
msg:
#ifdef SYS3
	.asciz	'mb acquisition timeout'
#else
	.byte	'm,'b,' ,'a,'c,'q,'u,'i,'s,'i,'t,'i,'o,'n
	.byte	' ,'t,'i,'m,'e,'o,'u,'t,012 ,0
#endif

/*
 * Code follows which is used to move, swap or compliment data
 */
#ifdef KICKER
/*
	This assembly language code uses movep instructions to do
	byte swaps of data and commands.
*/

/*
 *	mv_spec(src, dest, cnt, flag)
 *	Move 'cnt' bytes from 'src' to 'dest'.
 *	During the move the following options can be enabled in 'flag':
 *		0 - Move only.
 *		1 - Swap during move.
 *		2 - Compliment during move. (one's compliment)
 *		3 - Swap and compliment during move.
 */
	.text
.globl	_mv_spec
_mv_spec:
	moveml	#0xffff,sp@-	| Push caller regs
	movl	sp@(4),a0	| a0 = src
	movl	sp@(8),a1	| a1 = dest
	movl	sp@(12),d7	| d7 = cnt
	movl	sp@(16),d6	| d6 = flag
	lsrl	#1,d7		| Divide by 2 since we copy words at a time
	tstl	d6		| Check the flag
	bne	mvspec		| Not a normal MOVE
mvnorm:
	movw	a0@,d0
	movw	d0,a1@
	addl	#2,a0
	addl	#2,a1
	dbne	d7,mvnorm	|loop until done
mvexit:
	moveml	sp@+,#0xffff	| Restore caller regs.
	rts
mvspec:
	cmpl	#1,d6		| Swap only?
	beq	mv_swap		| if yes, swap the data.
	cmpl	#2,d6		| Compliment only?
	beq	mv_comp		| go do it.
mv_all:				| Swap and compliment.
	/* swap, compliment and move cnt bytes */
	movepw	a0@(0),d0
	movepw	a0@(1),d1
	notw	d0		| compliment the data
	notw	d1		| compliment the data
	movepw	d0,a1@(1)
	movepw	d1,a1@(0)
	addl	#2,a0		| Next Src.
	addl	#2,a1		| Next Dest.
	dbne	d7,mv_all	| Continue until we've zeroed out
	bra	mvexit		| Exit move routine

mv_comp:
	movw	a0@,d0
	notw	d0		| Compliment the data
	movw	d0,a1@
	addl	#2,a0
	addl	#2,a1
	dbne	d7,mv_comp	|loop until done
	bra	mvexit		| exit

mv_swap:
	/* swap and move cnt bytes */
	movepw	a0@(0),d0
	movepw	a0@(1),d1
	movepw	d0,a1@(1)
	movepw	d1,a1@(0)
	addl	#2,a0		| Next Src.
	addl	#2,a1		| Next Dest.
	dbne	d7,mv_swap	| Continue until we've zeroed out
	bra	mvexit		| Exit move routine
#endif /* KICKER */
