/* @(#)cswitch.s	5.5 SID */
#include "sys/param.h"
#include "sys/psl.h"
#include "sys/page.h"
#include "sys/mtpr.h"

	.text
.globl _save
.globl _resume

/*
 * save(buf)
 *
 * buf is address of area to save d2-d7,a2-a7 and pc in
 * for resume call. pc is stashed in a1 for moveml 
 */
_save:
#if defined(SCHROEDER) || defined(KICKER)
	.data
	.even
	.globl	_ufpstk
	.text
	tstw	_isfpu		| float point processor on board?
	beq	.C01		| skip if not
	movl	_ufpstk,a0	|
	.word	0xf320		| fsave	-a0@ save float point internals
	tstb	a0@		| is it a null state save?
	beq	.C02		| skip register restore if so
	.word	0xf220		| fmovemx #0xff,-a0@ 
	.word	0xe0ff		| save float point data registers
	.word	0xf220		| fmoveml   FPCR/FPSR/FPIAR,-a0@
	.word	0xbc00		| 1011110000000000 
	movw	#0xffff,a0@-	| movw	#1,-a0@	mark stack as non-null
.C02:	movl	_ufpstk,a1	| save location of stack top
	movl	a0,a1@		| save current top value there
#endif
.C01:	movl	sp@(4),a0	| addr save area
	movl	sp@+,a1		| callers next pc
	/* if you change the following line you must change
	 * mlsetup() too
	 */
	moveml	#0xfefc,a0@	| save d2-d7, a1-a7
	clrl	d0		| return 0 to caller of save
	jmp	a1@

/*
 * resume(ublkpg,buf)
 *
 * ublkpg is new phys pg number of ublk area. buf is
 * address of area 'save' put registers and pc into
 *
 */
.globl	_lcopy
.globl	_loadmap
.globl	_procumap
_resume:
	orw	#PSR_I,sr	| ints off
	movl	sp@(4),d0	| ublk pg
	movl	sp@(8),a3	| addr save area
	andl	#PG_PFNUM,d0	| just phys pg
	orl	#PG_NOEX,d0
	movl	d0,LA_UBLK/NBPC*4+SMLO	| map new ublk pg
	movl	a3,a0
	/* if you change the following line you must change
	 * mlsetup() too
	 */
	moveml	a0@,#0xfefc	| restore d2-d7, a1-a7
	movl	a1,sp@-		| save ret addr around loadmap

	jsr	_loadmap
	
#if defined(SCHROEDER) || defined(KICKER)
	movl	a0,a1
	tstw	_isfpu		| float point processor on board?
	beq	.C03		| skip restore if not
	movl	_ufpstk,a0	| pointer to 
	movl	a0@,a0		| pointer to fp frame top
	tstb	a0@		| check if null (marked frame with a one if not)
	beq	.C04		| skip register restore if so
	addql	#2,a0		| pop frame mark if not null
	.word	0xf218		| fmoveml a0@+,FPCR/FPSR/FPIAR
	.word	0x9c00		|
	.word	0xf218		| fmovemx a0@+,FP0-FP7
	.word	0xd0ff		|
.C04:	.word	0xf358		| frestore a0@+ restore floating point internals
	movl	a1,a0
#endif

.C03:	movl	sp@+,a1		| recover ret addr

	movl	#1,d0		| return 1 to caller of resume
	andw	#~PSR_I,sr	| ints on
	jmp	a1@		| resume!


.globl _setjmp
.globl _longjmp

/*
 * setjmp(addr)
 *
 * place restart info (pc, a2-a7, d2-d7) into buf at addr
 *
 */
_setjmp:
	movl	sp@(4),a0	| buf addr
	movl	sp@+,a1		| pc to longjmp to
	moveml	#0xfefc,a0@	| save info
	clrl	d0		| return 0 to setjmp caller
	jmp	a1@


/*
 * longjmp(addr)
 *
 * restore regs and pc from addr and resume at place setjmp
 * happened
 */
_longjmp:
	orw	#PSR_I,sr	| ints off?..z8000 version does
	movl	sp@(4),a0	| save area addr
	moveml	a0@,#0xfefc	| restore regs and pc
	movl	#1,d0		| longjmp returns 1 to caller
	andw	#~PSR_I,sr	| ints on
	jmp	a1@		| longjmp!

