/* SID @(#)rtrap.s	5.2 */

#include "sys/trap.h"
#include "sys/mtpr.h"
#include "sys/mc146818.h"

/*
 *
 * the format of the stack when we go to the c level 'trap'
 *	routine is:
 *
 *	lo mem		flag word	pushed by software
 *			USP			"
 *			d0			"
 *			d1			"
 *			d2			"
 *			d3			"
 *			d4			"
 *			d5			"
 *			d6			"
 *			d7			"
 *			a0			"
 *			a1			"
 *			a2			"
 *			a3			"
 *			a4			"
 *			a5			"
 *			a6			"
 *			sr		psh by hardware
 *			pc			"
 *			vector			"
 *			ssw			"
 *			aa			"
 *			unused			"
 *			unused			"
 *			unused			"
 *			unused			"
 *			unused			"
 *			iib			"
 *	hi mem		internal(16W)		"
 *
 *	bus error and address error traps push some extra words on
 *	the stack (ssw-special status word aa-access address
 *	iib-instruction input buffer  internal-16 words ).
 *
 *	for all traps that go to the c routine trap.c the stack
 *	is made to look the same.
 *
 *
 *  probably can just save d0,d1 and a0,a1 for the device (and
 *  maybe other) int service routines--this will be much faster   JK
 *
 */
SROFF = 70
	.data
	.even
.globl _runrun
.globl _berrflg
_berrflg: .long	0
.globl	_berrtemp
_berrtemp:
	.word	0
.globl	_ob1
.globl	_ob2
.globl	_ob3
_ob1:
	.long	0
_ob2:
	.long	0
_ob3:
	.long	0

	.text
.globl _trap
.globl t_berr
t_berr:
	tstl	_berrflg		| see if we expected this
	jeq	ber1			|   if not go call trap
	movl	_berrflg,sp@(2)		| set up to goto handler
	movl	_ob2,_ob3
	movl	_ob1,_ob2
	movl	_berrflg,_ob1
	clrl	_berrflg		| cover tracks
	orw	#0x8000,sp@(8)		| software rerun
	clrw	R_JBERR
	movw	I_ERR,_berrtemp
	andw	#0x40,_berrtemp
	beq	.L100
	clrw	R_DBERR
.L100:
	movw	sp@(8),_berrtemp	| debugging 
	rte				| return to error handler
ber1:
	clrw	sp@-		| stretch sr to long
	moveml	#0xfffe,sp@-	| save regs
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#BUSERR,sp@-	| push exception type
	jsr	_trap		| call trap routine
trapret:
	movw	sp@(SROFF),d0	| sr
	andw	#0x2000,d0	| were we in sys mode?
	jne	rtn3		| yes, just return
	tstb	_runrun		| any reason to resched?
	jeq	rtn2		| if not return to user
	movl	#RESCHED,sp@	| re-enter trap for reschedule
	andw	#~0x700,sr	| enable ints
	jsr	_trap
rtn2:
	addql	#4,sp		| pop dev word
	movl	sp@+,a0
	movl	a0,usp		| set users stack pointer
	jra	rtn4
rtn3:
	addql	#8,sp		| pop flag, usp
rtn4:
	moveml	sp@+,#0x7fff	| restore all regs
	addql	#2,sp		| discard sr hi fake part
	rte

.globl t_aerr
t_aerr:
	tstl	_berrflg		| see if we expected this
	jeq	aer1		| if not continue
	movl	_berrflg,sp@(2)	| return to err handler
	clrl	_berrflg	| cover tracks
	orw	#0x8000,sp@(8)	| software rerun
	rte
aer1:
	clrw	sp@-		| stretch sr to long
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#ADDERR,sp@-	| push flag
	jsr	_trap
	jra	trapret

#ifdef SYS3
.globl _sysdebu
#else
.globl _sysdebug
#endif
.globl t_ill
t_ill:
	clrw	sp@-		| stretch sr to long
	moveml	#0xfffe,sp@-	| push all regs
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#ILLINST,sp@-
	movw	sp@(SROFF),d0	| old sr
	andw	#0x2000,d0	| were we in sys mode?
	beq	notdebug
#ifdef SYS3
	jsr	_sysdebu	| yes-sysdebug bkpt
#else
	jsr	_sysdebug	| yes -sysdebug bkpt
#endif
	jra	trapret
notdebug:
	jsr	_trap		| no-trap user
	jra	trapret

.globl t_zdiv
t_zdiv:
	clrw	sp@-		| stretch sr to long
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#ZERODIV,sp@-
	jsr	_trap
	jra	trapret

.globl t_chk
t_chk:
	clrw	sp@-		| stretch sr to long
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#CHKINST,sp@-
	jsr	_trap
	jra	trapret
	
.globl t_trapv
t_trapv:
	clrw	sp@-		| stretch sr to long
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#TRAPVINST,sp@-
	jsr	_trap
	jra	trapret

.globl t_priv
t_priv:
	clrw	sp@-		| stretch sr to long
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#PRIVVIO,sp@-
	jsr	_trap
	jra	trapret

.globl t_trace
.globl _dbgsscnt
t_trace:
	andw	#0x7fff,sp@	| trace off
	clrw	sp@-		| stretch sr to long
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#TRACETRAP,sp@-
	tstl	_dbgsscnt	| is this sysdebug doing the single step ?
	beq	notsys
#ifdef SYS3
	jsr	_sysdebu	| yes - sys deb single step
#else
	jsr	_sysdebug	| yes - sys deb single step
#endif
	jra	trapret
notsys:
	jsr	_trap
	jra	trapret

.globl t_1010
t_1010:
	clrw	sp@-		| stretch sr to long
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#T1010,sp@-
	jsr	_trap
	jra	trapret

.globl t_1111
t_1111:
	clrw	sp@-		| stretch sr to long
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#T1111,sp@-
	jsr	_trap
	jra	trapret


.globl	sky_hwfp
.globl	_hardsky
.globl t_fp
t_fp:
	tstw	_hardsky
	jeq	t_bad
	jsr	sky_hwfp
	tstb	_runrun
	jne	norun
	rte
norun:
	clrw	sp@-		| stretch sr to long
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#T1111,sp@-
	jra	trapret


.globl t_res
t_res:
	clrw	sp@-		| stretch sr to long
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#TRESERVED,sp@-
	jsr	_trap
	jra	trapret

.globl t_uninit
t_uninit:
	clrw	sp@-		| stretch sr to long
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#TUNINIT,sp@-
	jsr	_trap
	jra	trapret

.globl t_spur
t_spur:
	clrw	sp@-		| stretch sr to long
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#SPURIOUS,sp@-
	jsr	_trap
	jra	trapret

.globl i_sc
i_sc:
	clrw	sp@-		| stretch sr to long
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#SYSCALL,sp@-
	jsr	_trap
	jra	trapret

.globl u_bkpt
u_bkpt:
	subql	#2,sp@(2)	| reset pc to re-execute inst
	clrw	sp@-		| stretch sr to long
	moveml	#0xfffe,sp@-	| save all regs
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#BKPT,sp@-	| flag as breakpoint
	movw	sp@(SROFF),d0	| old sr
	andw	#0x2000,d0	| were we in sys mode?
	beq	notsysbkpt
	jsr	_sysdebug	| yes remote debug bkpt
	jra	trapret
notsysbkpt:
	jsr	_trap
	jra	trapret

.globl i_bad
i_bad:
	clrw	sp@-		| stretch sr to long
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#IBAD,sp@-
	jsr	_trap
	jra	trapret

.globl t_bad
t_bad:
	clrw	sp@-		| stretch sr to long
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#TBAD,sp@-
	jsr	_trap
	jra	trapret

.globl u_res
u_res:
	clrw	sp@-		| stretch sr to long
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#URESERVED,sp@-
	jsr	_trap
	jra	trapret

.globl _clock
.globl i_clk
i_clk:
	clrw	sp@-		| stretch sr to long
	moveml	#0xfffe,sp@-
	movl	usp,a0
	movl	a0,sp@-
	subql	#4,sp		| fake dev
	clrw	R_CINTJ		| reset interrupt
	jsr	_clock
	jra	trapret


.globl i_pwr
i_pwr:
	clrw	sp@-		| stretch sr to long
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#PWR,sp@-
	jsr	_trap
	jra	trapret

.globl	i_diag
i_diag:
	clrw	R_SWINT
	clrw	sp@-		| stretch sr to long
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#ISWITCH,sp@-
#ifdef SYS3
	jsr	_sysdebu
#else
	jsr	_sysdebug
#endif
	jra	trapret

.globl _debug
_debug:
	clrw	sp@-		| stretch sr to long
	moveml	#0xfffe,sp@-	| save all regs
	movl	usp,a0
	movl	a0,sp@-
	movl	#DBG,sp@-
#ifdef SYS3
	jsr	_sysdebu
#else
	jsr	_sysdebug
#endif
	addql	#8,sp		| pop DBG and usp
	moveml	sp@+,#0x7fff	| restore regs
	addql	#2,sp		| discard sr hi fake part
	rts

.globl	i_dma
.globl	_dmaint
i_dma:
	clrw	sp@-		| stretch sr to long
	moveml	#0xfffe,sp@-	| save all regs
	movl	usp,a0
	movl	a0,sp@-
	subql	#4,sp		| fake dev
	jsr	_dmaint
	jra	trapret

.globl	i_mberr
i_mberr:
	clrw	sp@-		| stretch sr to long
	moveml	#0xfffe,sp@-	| save all regs
	movl	usp,a0
	movl	a0,sp@-
	movl	#MBERR,sp@-	
	jsr	_trap
	jra	trapret
