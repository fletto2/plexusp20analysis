/* SID @(#)low.s	1.7 */

#ifdef robin
#include "rlow.s"
#else

#include "sys/param.h"
#include "sys/trap.h"

	.text
.globl t_berr
.globl u_res
.globl start
.globl t_aerr
.globl t_ill
.globl t_zdiv
.globl t_chk
.globl t_trapv
.globl t_priv
.globl t_trace
.globl t_1010
.globl t_1111
.globl t_res
.globl t_uninit
.globl t_spur
.globl i_bad
.globl i_sc
.globl t_fp
.globl t_bad
.globl u_bkpt
.globl	i_mb0
.globl	i_mb1
.globl	i_mb2
.globl	i_mb3
.globl	i_mb4
.globl	i_mb5
.globl	i_mb6
.globl	i_mb7
.globl	i_bepci
.globl	i_aepci
.globl	i_clk
.globl	i_dmerr
.globl	i_pwr
.globl	_runrun
.globl	_trap

/*
 * instead of the usual 'reset' vector that should be at loc
 * 0 we put the starting address of the kernel here. this
 * works because when 'reset' is hit we are forced into
 * boot mode addressing to the reset vector is always fetched
 * from PROM
 */
	.text
	jmp	start
	.word	0x4afc			/* illegal inst */

	.long	t_berr		/* 2  bus error vector */
	.long	t_aerr		/* 3  address error vector */
	.long	t_ill		/* 4  illegal inst vector */
	.long	t_zdiv		/* 5  zero divide vector */
	.long	t_chk		/* 6  chk inst vector */
	.long	t_trapv		/* 7  trapv inst vector */
	.long	t_priv		/* 8  priv violation vector */
	.long	t_trace		/* 9  trace vector */

	.long	t_1010		/* 10  1010 inst vector */
	.long	t_1111		/* 11  1111 inst vector */

	.long	t_res		/* 12  reserved vector */
	.long	t_res		/* 13  reserved vector */
	.long	t_res		/* 14  reserved vector */

	.long	t_uninit	/* 15  uninitialized int vector */

	.long	t_res		/* 16  reserved vector */
	.long	t_res		/* 17  reserved vector */
	.long	t_res		/* 18  reserved vector */
	.long	t_res		/* 19  reserved vector */
	.long	t_res		/* 20  reserved vector */
	.long	t_res		/* 21  reserved vector */
	.long	t_res		/* 22  reserved vector */
	.long	t_res		/* 23  reserved vector */

	.long	t_spur		/* 24  spurious int vector */
	.long	i_bad		/* 25  level 1 int */
	.long	i_bad		/* 26  level 2 int */
	.long	i_bad		/* 27  level 3 int */
	.long	i_bad		/* 28  level 4 int */
	.long	i_bad		/* 29  level 5 int */
	.long	i_bad		/* 30  level 6 int */
	.long	i_bad		/* 31  level 7 int */

	.long	i_sc		/* 32  trap #0 syscall */
	.long	t_bad		/* 33  trap #1 */
	.long	u_bkpt		/* 34  trap #2 is user bpkt */
	.long	t_bad		/* 35  trap #3 */
	.long	t_bad		/* 36  trap #4 */
	.long	t_bad		/* 37  trap #5 */
	.long	t_bad		/* 38  trap #6 */
	.long	t_bad		/* 39  trap #7 */
	.long	t_bad		/* 40  trap #8 */
	.long	t_bad		/* 41  trap #9 */
	.long	t_bad		/* 42  trap #10 */
	.long	t_bad		/* 43  trap #11 */
	.long	t_bad		/* 44  trap #12 */
	.long	t_bad		/* 45  trap #13 */
	.long	t_bad		/* 46  trap #14 */
	.long	t_fp		/* 47  trap #15 is floating point trap to sky */

	.long	t_res		/* 48  reserved */
	.long	t_res		/*     reserved */
	.long	t_res		/*     reserved */
	.long	t_res		/*     reserved */
	.long	t_res		/*     reserved */
	.long	t_res		/*     reserved */
	.long	t_res		/*     reserved */
	.long	t_res		/*     reserved */
	.long	t_res		/*     reserved */
	.long	t_res		/*     reserved */
	.long	t_res		/*     reserved */
	.long	t_res		/*     reserved */
	.long	t_res		/*     reserved */
	.long	t_res		/*     reserved */
	.long	t_res		/*     reserved */
	.long	t_res		/* 63  reserved */

	.long	u_res		/* 64  user int vector */
	.long	u_res		/*     user int vector */
	.long	i_mb7		/* 66  multibus int 7  */
	.long	i_mb6		/* 67  multibus int 6 */
	.long	i_mb5		/* 68  multibus int 5 */
	.long	i_mb4		/* 69  multibus int 4 */
	.long	i_mb3		/* 70  multibus int 3 */
	.long	i_mb2		/* 71  multibus int 2 */
	.long	i_mb1		/* 72  multibus int 1 */
	.long	i_mb0		/* 73  multibus int 0 */
	.long	i_bepci		/* 74  epci b int */
	.long	i_aepci		/* 75  epci a int */
	.long	i_bad		/* 76  unused */
	.long	i_clk		/* 77  clock int */
	.long	i_dmerr		/* 78  dma/memory err int */
	.long	i_pwr		/* 79  pwr fail/int switch int */

	.long	u_res		/* 80  user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/* 90  user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/* 100 user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/* 110 user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/* 120 user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/* 130 user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/* 140 user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/* 150 user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/* 160 user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/* 170 user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/* 180 user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/* 190 user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/* 200 user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/* 210 user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/* 220 user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/* 230 user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/* 240 user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/* 250 user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/*     user int vector */
	.long	u_res		/* 255 user int vector */

#ifdef NOS
.globl _etintr
#else
.globl _siint4
#endif
.globl i_mb0
i_mb0:
	clrw	sp@-		| clear sr hi
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	subql	#4,sp		| fake dev
#ifdef NOS
	jsr	_etintr		| call ether int routine
#else
	jsr	_siint4		| icp int routine
#endif
	jra	trapret

.globl i_mb1
.globl _rmintr
i_mb1:
	clrw	sp@-
	moveml	#0xfffe,sp@-	| save regs
	movl	usp,a0
	movl	a0,sp@-
	subql	#4,sp		| fake dev
	jsr	_rmintr		| call tape int routine
	jra	trapret

.globl i_mb2
.globl _siint1
i_mb2:
	clrw	sp@-		| fake sr hi
	moveml	#0xfffe,sp@-	| save regs
	movl	usp,a0
	movl	a0,sp@-
	subql	#4,sp		| fake dev
	jsr	_siint1		| icp int routine
	jra	trapret

.globl i_mb3
.globl _siint0
i_mb3:
	clrw	sp@-		| fake sr hi
	moveml	#0xfffe,sp@-	| save regs
	movl	usp,a0
	movl	a0,sp@-
	subql	#4,sp		| fake usp, dev
	jsr	_siint0		| icp int routine
	jra	trapret

.globl i_mb4
.globl _siint2
i_mb4:
	clrw	sp@-		| fake sr hi
	moveml	#0xfffe,sp@-	| save regs
	movl	usp,a0
	movl	a0,sp@-
	subql	#4,sp		| fake usp, dev
	jsr	_siint2		| icp int routine
	jra	trapret

.globl i_mb5
i_mb5:
	clrw	sp@-		| fake sr hi
	moveml	#0xfffe,sp@-	| save regs
	movl	usp,a0
	movl	a0,sp@-
	subql	#4,sp		| fake usp,dev
	jsr	_xyintr		/* xylogics interrupt; JF */
	jra	trapret

.globl i_mb6
.globl _siint3
i_mb6:
	clrw	sp@-		| fake sr hi
	moveml	#0xfffe,sp@-	| save regs
	movl	usp,a0
	movl	a0,sp@-
	subql	#4,sp		| fake usp, dev
	jsr	_siint3		| icp int routine
	jra	trapret


#ifndef PIRATE
/*
 *
 * these defs must match those in pd.c and pt.c!!!
 *
 *		find a better way to do this for long term JK
 */
#define DISKBIT 1
#define TAPEBIT 2
#define IMBIT 4
#endif

.globl i_mb7
.globl _pdintr
#ifndef PIRATE
.globl _ptintr
.globl _imintr
.globl _imscint
#endif
i_mb7:
	clrw	sp@-		| fake sr hi
	moveml	#0xfffe,sp@-	| save regs
	movl	usp,a0
	movl	a0,sp@-
	clrl	sp@-		| fake dev
#ifndef PIRATE
	movl	_imscint,d0
	andl	#DISKBIT,d0	| expecting disk int?
	jeq	imb7a		| branch if not
	jsr	_pdintr		| else call disk int routine
imb7a:
	movl	_imscint,d0
	andl	#TAPEBIT,d0	| expecting tape int?
	jeq	imb7b
	jsr	_ptintr		| else call tape int routine
imb7b:	
	movl	_imscint,d0
	andl	#IMBIT,d0
	jeq	trapret
	jsr	_imintr		| service download int
#else
	jsr	_pdintr		| pdintr calls ptintr or imintr if necessary
#endif

#define SROFF 70
	.globl	_runrun
	.globl	_trap
trapret:
	movw	sp@(SROFF),d0	| sr
	andw	#0x2000,d0	| were we in sys mode?
	jne	rtn3		| yes, just return
	tstl	_runrun		| any reason to resched?
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
	addql	#2,sp		| pop off sr high
	rte
#endif
