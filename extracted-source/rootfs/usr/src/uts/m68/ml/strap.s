/* @(#)strap.s	5.6 SID */

#include "sys/trap.h"
#include "sys/mtpr.h"

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
 *			unused		"
 *			ssw			"
 *			unused			"
 *			unused			"
 *			aa			"
 *			unused			"
 *			unused			"
 *			unused			"
 *			unused			"
 *			unused			"
 *			many more internal registers
 *
 *	bus error and address error traps push some extra words on
 *	the stack (ssw-special status word aa-access address).
 *
 *	for all traps that go to the c routine trap.c the stack
 *	is made to look the same.
 *
 *
 *  probably can just save d0,d1 and a0,a1 for the device (and
 *  maybe other) int service routines--this will be much faster   JK
 *
 */

#define SROFF 70

	.data
	.even
.globl _runrun
.globl _berrflg
.globl initfp
_berrflg: .long	0
.globl	_berrtemp
_berrtemp:
	.word	0

	.text
.globl _trap
.globl t_berr
t_berr:
|	jsr		__oldmaskfixup
	tstl	_berrflg		| see if we expected this
	jeq	ber1			|   if not go call trap
	andw    #0xf000,sp@(6)          | throw away vector offset
	cmpw    #0xa000,sp@(6)          | is it short stack frame?
	jne     longf                   | if not, process as long
	movw    sp@,sp@(24)             | keep status register
	addl    #24,sp                  | pop stack
	jra     bercont                 |
longf:                                  |long stack frame
	movw    sp@,sp@(84)             | keep status register
	addl    #84,sp                  | pop stack
bercont:
	clrw    sp@(6)                  | clear new vector offset
	movl	_berrflg,sp@(2)		| set up to goto handler
	clrl	_berrflg		| cover tracks
	clrb	P_RSTERROR	| reset the hardware error latches
.L100:
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

rtn2:	addql	#4,sp		| pop dev word
	movl	sp@+,a0
	movl	a0,usp		| set users stack pointer
	jra	rtn4
rtn3:
	addql	#8,sp		| pop flag, usp
rtn4:
	moveml	sp@+,#0x7fff	| restore all regs
	addql	#2,sp		| discard sr hi fake part
	clrb	P_RSTERROR
	rte

.globl t_aerr
t_aerr:
|	jsr	__oldmaskfixup
	tstl	_berrflg		| see if we expected this
	jeq	aer1		| if not continue
	movl	_berrflg,sp@(2)	| return to err handler
	clrl	_berrflg	| cover tracks
	orw	#0x3000,sp@(10)	| software rerun
	rte
aer1:
	clrw	sp@-		| stretch sr to long
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#ADDERR,sp@-	| push flag
	jsr	_trap
	jra	trapret

.globl i_dmerr
i_dmerr:
	clrw	sp@-
	movl	a0,sp@-
	movl	a1,sp@-
	movl	d0,sp@-
	movl	d1,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	jsr	_memerr		| Go do the memerr stuff
	tstl	d0		| Check for uncorrectable stuff
	bne	dmerr_ok
	movl	sp@+,a0		| Only do this when no memory errs occurred.
	movl	a0,usp		| Restore USP
	movl	sp@+,d1
	movl	sp@+,d0
	movl	sp@+,a1
	movl	sp@+,a0
	addql	#2,sp		| discard sr hi fake part
	rte			| return
dmerr_ok:
	movl	sp@+,a0
	movl	a0,usp		| Restore USP
	movl	sp@+,d1
	movl	sp@+,d0
	movl	sp@+,a1
	movl	sp@+,a0
	addql	#2,sp		| discard sr hi fake part
	clrb	P_RSTERROR	| Else reset ERROR REGISTER
	rte			

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
/* !! seems that it should be 70
	movw	sp@(60+20),d0	| old sr
*/
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
	andw	#0x3fff,sp@	| trace off
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
	tstw	initfp		| error due to float point initialization?
	beq	.T11		| handle regularly if not
	clrb	P_RSTERROR	| this means board does not have float point
	clrw	sp@(6)		| chip, so ignore error
	addql	#2,sp@(2)	| increment stack pc to skip fsave in start.s
	rte			| return to start.s

.T11:	clrw	sp@-		| stretch sr to long
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movl	#T1111,sp@-
	tstw	initfp
	jsr	_trap
	jra	trapret


#ifdef SCHROEDER
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
#endif


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
	clrw	sp@-		| stretch sr to long
	moveml	#0xfffe,sp@-
	movl	usp,a0
	movl	a0,sp@-
	subql	#4,sp		| fake dev
	movb	CALREGC,d0	| reset interrupt
	jsr	_clock
	jra	trapret


.globl i_pwr
i_pwr:
	clrw	sp@-		| stretch sr to long
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	movb	P_STATUS,d0
	andb	#M_SWITCH,d0	| see if int switch
	beq	pfail
	movl	#ISWITCH,sp@-	| sysdebug interrupt
	jsr	_sysdebug
	clrb	P_RSTSWITCH	| switch interrupt reset
	jra	trapret
pfail:
	movl	#PWR,sp@-
	jsr	_trap
	jra	trapret

.globl	i_diag
i_diag:
	clrb	P_RSTSWITCH	| tell the dump hardware I heard it
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
	movw	sr,sp@-		| build fake int stk
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
	addql	#4,sp		| discard sr 
	rts

