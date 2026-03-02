/* @(#)trap.s	5.4 SID */

#ifdef ROBIN
#include "./rtrap.s"
#else
#if defined(SCHROEDER) || defined(KICKER)
#include "./strap.s"
#else

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
 *			ps		psh by hardware/moved by sw
 *			aa			"
 *			ir			"
 *			sr		pushed by hardware/software
 *	hi mem		pc		pushed by hardware
 *
 *	bus error and address error traps push some extra words on
 *	the stack (ir-instruction register, aa-access address,
 *	ps-processor state).
 *
 *	for all traps that go to the c routine trap.c the stack
 *	is made to look the same--all the entries shown above
 *	and all entries are 'longs'. this is the only way
 *	calling a 'c' routine can work.
 *
 *	traps (e.g. devices,clk) that do not go to 'trap.c'
 *	leave the ps-aa-ir and usp-flag info off the stack.
 *	they must still however pad the sr to a long.
 *
 *  probably can just save d0,d1 and a0,a1 for the device (and
 *  maybe other) int service routines--this will be much faster   JK
 *
 */

	.data
	.even
.globl _runrun
.globl _berrflg
_berrflg: .long	0

#define SROFF 70

	.text
.globl _trap
.globl t_berr
t_berr:
	tstl	_berrflg		| see if we expected this
	jeq	ber1		|   if not go call trap
	addql	#8,sp		| pop bus err words
	movl	_berrflg,sp@(2)	| set up to goto handler
	clrl	_berrflg		| cover tracks
	movb	#BUSERRRESET,P_RESET	| tidy up
	movb	#MEMERRRESET,P_RESET	| ditto
	rte			| return to error handler
ber1:
	/* kludge 68000 stack to look like 68010 stack so
	 * p15/p20/p35/p60 all have common stacks
	 */
	lea	sp@(-10),sp	| grow stack
	movw	sp@(18),sp@(2)	| position SR	
	clrw	sp@		| clear SR high
	movl	sp@(20),sp@(4)	| position PC

	moveml	#0xfffe,sp@-	| save regs
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#BUSERR,sp@-	| push exception type
	jsr	_trap		| call trap routine
berrret:
	movw	sp@(SROFF),d0	| sr
	andw	#0x2000,d0	| were we in sys mode?
	jne	brtn3		| yes, just return
	tstb	_runrun		| any reason to resched?
	jeq	brtn2		| if not return to user
	movl	#RESCHED,sp@	| re-enter trap for reschedule
	andw	#~0x700,sr	| enable ints
	jsr	_trap
brtn2:
	addql	#4,sp		| pop dev word
	movl	sp@+,a0
	movl	a0,usp		| set users stack pointer
	jra	brtn4
brtn3:
	addql	#8,sp		| pop flag, usp
brtn4:
	moveml	sp@+,#0x7fff	| restore all regs
	movw	sp@(2),sp@(18)	| return sr
	movl	sp@(4),sp@(20)	| return pc (maybe updated)
	lea	sp@(18),sp	| pop down to sr low
	rte

.globl t_aerr
t_aerr:
	tstl	_berrflg		| see if we expected this
	jeq	aer1		| if not continue
	addql	#8,sp		| pop off addr err junk
	movl	_berrflg,sp@(2)	| return to err handler
	clrl	_berrflg	| cover tracks
	rte
aer1:
	/* kludge 68000 stack to look like 68010 stack so
	 * p15/p20/p35/p60 all have common stacks
	 */
	lea	sp@(-10),sp	| grow stack
	movw	sp@(18),sp@(2)	| position SR	
	clrw	sp@		| clear SR high
	movl	sp@(20),sp@(4)	| position PC

	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#ADDERR,sp@-	| push flag
	jsr	_trap
	jra	berrret

.globl _sysdebug
.globl t_ill
t_ill:
	clrw	sp@-		| clear sr hi
	moveml	#0xfffe,sp@-	| push all regs
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#ILLINST,sp@-
	movw	sp@(SROFF),d0	| old sr
	andw	#0x2000,d0	| were we in sys mode?
	beq	notdebug
	jsr	_sysdebug	| yes -sysdebug bkpt
	jra	trapret
notdebug:
	jsr	_trap		| no-trap user
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
	addql	#2,sp		| throw away sr high
	rte

.globl t_zdiv
t_zdiv:
	clrw	sp@-		| clear sr hi
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#ZERODIV,sp@-
	jsr	_trap
	jra	trapret

.globl t_chk
t_chk:
	clrw	sp@-		| clear sr hi
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#CHKINST,sp@-
	jsr	_trap
	jra	trapret
	
.globl t_trapv
t_trapv:
	clrw	sp@-		| clear sr hi
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#TRAPVINST,sp@-
	jsr	_trap
	jra	trapret

.globl t_priv
t_priv:
	clrw	sp@-		| clear sr hi
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
	clrw	sp@-		| clear sr hi
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#TRACETRAP,sp@-
	tstl	_dbgsscnt	| is this sysdebug doing the single step ?
	beq	notsys
	jsr	_sysdebug	| yes - sysdebug single step (not rumba)
	jra	trapret
notsys:
	jsr	_trap
	jra	trapret

.globl t_1010
t_1010:
	clrw	sp@-		| clear sr hi
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#T1010,sp@-
	jsr	_trap
	jra	trapret

.globl t_1111
t_1111:
	clrw	sp@-		| clear sr hi
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
	clrw	sp@-		| clear sr hi
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#T1111,sp@-
	jra	trapret


.globl t_res
t_res:
	clrw	sp@-		| clear sr hi
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#TRESERVED,sp@-
	jsr	_trap
	jra	trapret

.globl t_uninit
t_uninit:
	clrw	sp@-		| clear sr hi
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#TUNINIT,sp@-
	jsr	_trap
	jra	trapret

.globl t_spur
t_spur:
	clrw	sp@-		| clear sr hi
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#SPURIOUS,sp@-
	jsr	_trap
	jra	trapret

.globl i_sc
i_sc:
	clrw	sp@-		| clear sr hi
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#SYSCALL,sp@-
	jsr	_trap
	jra	trapret

.globl u_bkpt
u_bkpt:
	subql	#2,sp@(2)	| reset pc to re-execute inst
	clrw	sp@-		| clear sr hi
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
	clrw	sp@-		| clear sr hi
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#IBAD,sp@-
	jsr	_trap
	jra	trapret

.globl t_bad
t_bad:
	clrw	sp@-		| clear sr hi
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#TBAD,sp@-
	jsr	_trap
	jra	trapret

.globl u_res
u_res:
	clrw	sp@-		| clear sr hi
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#URESERVED,sp@-
	jsr	_trap
	jra	trapret

.globl i_bepci
.globl _usint
i_bepci:
	clrw	sp@-		| clear hi sr
	moveml	#0xfffe,sp@-
	movl	#1,sp@-		| 'dev' word
	jsr	_usint
	addql	#4,sp		| pop dev word
	moveml	sp@+,#0x7fff	| restore regs
	addql	#2,sp		| pop sr hi half
	rte

.globl i_aepci
.globl _usint
i_aepci:
	clrw	sp@-		| clear hi sr
	moveml	#0xfffe,sp@-
	clrl	sp@-		| 'dev' parameter
	jsr	_usint
	addql	#4,sp		| pop dev word
	moveml	sp@+,#0x7fff	| restore regs
	addql	#2,sp		| pop sr hi
	rte

.globl _clock
.globl i_clk
i_clk:
	clrw	sp@-
	moveml	#0xfffe,sp@-
	movl	usp,a0
	movl	a0,sp@-
	subql	#4,sp		| fake dev
	movb	CALREGC,d0	| reset int-let clk continue
	jsr	_clock
	jra	trapret

.globl i_dmerr
i_dmerr:
	clrw	sp@-
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#DMERR,sp@-
	jsr	_trap

	movw	sp@(SROFF),d0	| sr
	andw	#0x2000,d0	| were we in sys mode?
	jne	rtn3b		| yes, just return
	tstb	_runrun		| any reason to resched?
	jeq	rtn2b		| if not return to user
	movl	#RESCHED,sp@	| re-enter trap for reschedule
	andw	#~0x700,sr	| enable ints
	jsr	_trap
rtn2b:
	addql	#4,sp		| pop dev word
	movl	sp@+,a0
	movl	a0,usp		| set users stack pointer
	jra	rtn4b
rtn3b:
	addql	#8,sp		| pop flag, usp
rtn4b:
	moveml	sp@+,#0x7fff	| restore all regs
	addql	#2,sp		| throw away sr high
	movb	#MEMERRRESET,P_RESET	| enable errs to CPU
	rte

.globl i_pwr
i_pwr:
	clrw	sp@-		| clear sr hi
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movb	P_STATUS,d0
	andb	#M_SWITCH,d0	| see if int switch
	beq	pfail
	movl	#ISWITCH,sp@-	| sysdebug interrupt
	jsr	_sysdebug
	jra	trapret
pfail:
	movl	#PWR,sp@-
	jsr	_trap
	jra	trapret

.globl _debug
_debug:
	movw	sr,sp@-		| build fake int stk
	clrw	sp@-		| fake high word of sr
	moveml	#0xfffe,sp@-	| save all regs
	movl	usp,a0
	movl	a0,sp@-
	movl	#DBG,sp@-
	jsr	_sysdebug
	addql	#8,sp		| pop DBG and usp
	moveml	sp@+,#0x7fff	| restore regs
	addql	#4,sp		| pop (fake)(sr)
	rts
#endif
