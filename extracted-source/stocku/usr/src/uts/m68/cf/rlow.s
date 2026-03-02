| 
| SID @(#)rlow.s	1.4
#include "sys/trap.h"

	.text
.globl t_berr
.globl u_res
.globl t_aerr
.globl t_ill
.globl t_zdiv
.globl t_chk
.globl t_trapv
.globl t_priv
.globl t_trace
.globl t_bad
.globl t_spur
.globl i_bad
.globl	i_mb0
.globl	i_mb1
.globl	i_mb2
.globl	i_mb3
.globl	i_mb4
.globl	i_mb5
.globl	i_mb6
.globl	i_mb7
.globl	i_clk
.globl	i_pwr
.globl	i_memerr
.globl	i_diag
.globl	i_ups
.globl	i_temp
.globl	i_mberr
.globl	t_format
.globl	start
.globl	i_dma
.globl	i_job

| scsi ints */
.globl	s_bad
.globl	s_sel
.globl	s_res
.globl	s_par
.globl	s_int0
.globl	s_int1
.globl	s_int2
.globl	s_int3
.globl	s_int4
.globl	s_int5
.globl	s_int6
.globl	s_int7

| usart ints */


.globl	p0tbe
.globl	p0esc
.globl	p0rca
.globl	p0src

.globl	p1tbe
.globl	p1esc
.globl	p1rca
.globl	p1src

.globl	p2tbe
.globl	p2esc
.globl	p2rca
.globl	p2src

.globl	p3tbe
.globl	p3esc
.globl	p3rca
.globl	p3src

.globl	p4tbe
.globl	p4esc
.globl	p4rca
.globl	p4src

.globl	p5tbe
.globl	p5esc
.globl	p5rca
.globl	p5src

.globl	t_1010
.globl	t_1111
.globl	t_fp
.globl	t_res
.globl	t_uninit
.globl	i_sc
.globl	u_bkpt

SLMHI = 0x780000
	.text
	.globl	vbraddr
vbraddr:			| to load vector base reg on init */
	.long	SLMHI-12	| ssp */
	.long	start		| pc */
	.long	t_berr		| 2  bus error vector */
	.long	t_aerr		| 3  address error vector */
	.long	t_ill		| 4  illegal inst vector */
	.long	t_zdiv		| 5  zero divide vector */
	.long	t_chk		| 6  chk inst vector */
	.long	t_trapv		| 7  trapv inst vector */
	.long	t_priv		| 8  priv violation vector */
	.long	t_trace		| 9  trace vector */

	.long	t_1010		| 10  1010 inst vector */
	.long	t_1111		| 11  1111 inst vector */

	.long	t_bad		| 12  reserved vector */
	.long	t_bad		| 13  reserved vector */
	.long	t_format	| 14  68010 format vector */

	.long	t_uninit	| 15  uninitialized int vector */

	.long	t_res		| 16  reserved vector */
	.long	t_res		| 17  reserved vector */
	.long	t_res		| 18  reserved vector */
	.long	t_res		| 19  reserved vector */
	.long	t_res		| 20  reserved vector */
	.long	t_res		| 21  reserved vector */
	.long	t_res		| 22  reserved vector */
	.long	t_res		| 23  reserved vector */

	.long	t_spur		| 24  spurious int vector */
	.long	i_bad		| 25  level 1 int */
	.long	i_bad		| 26  level 2 int */
	.long	i_bad		| 27  level 3 int */
	.long	i_bad		| 28  level 4 int */
	.long	i_bad		| 29  level 5 int */
	.long	i_bad		| 30  level 6 int */
	.long	i_bad		| 31  level 7 int */

	.long	i_sc		| 32  trap #0 syscall */
	.long	t_bad		| 33  trap #1 */
	.long	u_bkpt		| 34  trap #2 is user bpkt */
	.long	t_bad		| 35  trap #3 */
	.long	t_bad		| 36  trap #4 */
	.long	t_bad		| 37  trap #5 */
	.long	t_bad		| 38  trap #6 */
	.long	t_bad		| 39  trap #7 */
	.long	t_bad		| 40  trap #8 */
	.long	t_bad		| 41  trap #9 */
	.long	t_bad		| 42  trap #10 */
	.long	t_bad		| 43  trap #11 */
	.long	t_bad		| 44  trap #12 */
	.long	t_bad		| 45  trap #13 */
	.long	t_bad		| 46  trap #14 */
	.long	t_fp		| 47  trap #15 floating point trap to sky */

	.long	t_bad		| 48  reserved */
	.long	t_bad		|     reserved */
	.long	t_bad		|     reserved */
	.long	t_bad		|     reserved */
	.long	t_bad		|     reserved */
	.long	t_bad		|     reserved */
	.long	t_bad		|     reserved */
	.long	t_bad		|     reserved */
	.long	t_bad		|     reserved */
	.long	t_bad		|     reserved */
	.long	t_bad		|     reserved */
	.long	t_bad		|     reserved */
	.long	t_bad		|     reserved */
	.long	t_bad		|     reserved */
	.long	t_bad		|     reserved */
	.long	t_bad		| 63  reserved */

	.long	i_bad		| 0x40  spurious int vector */
	.long	i_memerr	|       memory int vector */
	.long	i_pwr		| 0x42  pwr fail */
	.long	i_pwr		| 0x43  */
	.long	i_diag		| 0x44  diag switch */
	.long	i_diag		| 0x45  */
	.long	i_diag		| 0x46  */
	.long	i_diag		| 0x47	 */
	.long	i_ups		| 0x48  universal power supply  */
	.long	i_ups		| 0x49  */
	.long	i_ups		| 0x4a  */
	.long	i_ups
	.long	i_ups
	.long	i_ups
	.long	i_ups
	.long	i_ups		| 0x4f  */

	.long	i_temp		| 0x50  over temp */
	.long	i_temp	
	.long	i_temp
	.long	i_temp
	.long	i_temp
	.long	i_temp
	.long	i_temp
	.long	i_temp
	.long	i_temp		| 0x58 */
	.long	i_temp
	.long	i_temp
	.long	i_temp
	.long	i_temp
	.long	i_temp
	.long	i_temp
	.long	i_temp		| 0x5f */
	.long	s_bad		| 0x60 scsi spurious vector */
	.long	s_sel		| 0x61 scsi selection vector */
	.long	s_res		| 0x62 scsi reslection vector */
	.long	s_bad		| 0x63 user int vector */
	.long	s_par		| 0x64 scsi parity  int vector */
	.long	s_par		| 0x65 user int vector */
	.long	s_par		| 0x66 user int vector */
	.long	s_bad		| 0x67 user int vector */
	.long	s_int7		| 0x68 scsi interrupt vectors */
	.long	s_int6		| 0x69 pointer int.  input */
	.long	s_int5		| 0x6A pointer int. command */
	.long	s_int4		|      user int vector */
	.long	s_int3		| 0x6C pointer int. message */
	.long	s_int2		|      user int vector */
	.long	s_int1		| 0x6E user int vector */
	.long	s_int0		|      user int vector */
	.long	i_mb0		| 0x70 multibus int vector */
	.long	i_mb1		|      multibus int vector */
	.long	i_mb2		|      multibus int vector */
	.long	i_mb3		|      multibus int vector */
	.long	i_mb4		|      multibus int vector */
	.long	i_mb5		|      multibus int vector */
	.long	i_mb6		|      multibus int vector */
	.long	i_mb7		| 0x77 multibus int vector */
	.long	u_res		| 0x78 user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	i_clk		| 0x7B clock int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	i_mberr		| 0x7F multi bus interface error vector */
	.long	u_res		| 0x80 old dma processor interrupt */
	.long	u_res		| 0x81 old job processor interrupt */
	.long	u_res		| 130  user int vector */
	.long	i_clk		| 0x83 clock int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	p1tbe		| 0x88 port transmit buffer empty vector */
	.long	p1esc		|      port external status change vector */
	.long	p1rca		|      port recieve char avail.  vector */
	.long	p1src		|      port special recieve cond. vector */
	.long	p0tbe		| 0x8C port transmit buffer empty vector */
	.long	p0esc		|      port external status change vector */
	.long	p0rca		|      port recieve char avail.  vector */
	.long	p0src		|      port special recieve cond. vector */
	.long	p3tbe		| 0x90 port transmit buffer empty vector */
	.long	p3esc		|      port external status change vector */
	.long	p3rca		|      port recieve char avail.  vector */
	.long	p3src		|      port special recieve cond. vector */
	.long	p2tbe		| 0x94 port transmit buffer empty vector */
	.long	p2esc		|      port external status change vector */
	.long	p2rca		|      port recieve char avail.  vector */
	.long	p2src		|      port special recieve cond. vector */
	.long	p5tbe		| 0x98 port transmit buffer empty vector */
	.long	p5esc		|      port external status change vector */
	.long	p5rca		|      port recieve char avail.  vector */
	.long	p5src		|      port special recieve cond. vector */
	.long	p4tbe		| 0x9c port transmit buffer empty vector */
	.long	p4esc		|      port external status change vector */
	.long	p4rca		|      port recieve char avail.  vector */
	.long	p4src		|      port special recieve cond. vector */
	.long	u_res		| 160  user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		| 170  user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		| 180  user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		| 190  user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	i_dma		| C1   dma -> job vector */
	.long	i_job		| C2   job -> dma vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		| 200  user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		| 210  user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		| 220  user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		| 230  user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		| 240  user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		| 250  user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		|      user int vector */
	.long	u_res		| 255  user int vector */

| Int's the job cpu should not see ( some are here temporarily )
i_memerr:
	.globl	_parerr
	clrw	sp@-		| clear sr hi
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	subql	#4,sp		| fake dev
	jsr	_parerr		| call parity int routine
	jra	trapret
i_ups:
i_temp:
t_format:
i_job:
s_bad:
s_sel:
s_res:
s_par:
s_int0:
s_int1:
s_int2:
s_int3:
s_int4:
s_int5:
s_int6:
s_int7:
p0tbe:
p0esc:
p0rca:
p0src:
p1tbe:
p1esc:
p1rca:
p1src:
p2tbe:
p2esc:
p2rca:
p2src:
p3tbe:
p3esc:
p3rca:
p3src:
p4tbe:
p4esc:
p4rca:
p4src:
p5tbe:
p5esc:
p5rca:
p5src:
	jmp	i_bad

	.globl i_mb0
i_mb0:
#ifdef NOS
	.globl _etintr
	clrw	sp@-		| clear sr hi
	moveml	#0xfffe,sp@-
	movl	usp,a0		| get user stk ptr
	movl	a0,sp@-		| save usp
	subql	#4,sp		| fake dev
	jsr	_etintr		| call ether int routine
	jra	trapret
#else
	jmp	i_bad
#endif

	.globl i_mb1
	.globl _rmintr
i_mb1:
	clrw	sp@-		| fake sr hi
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
	jmp	i_bad		/* unused interrupt */

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



	.globl i_mb7		| nothing exists on robin
i_mb7:
	jmp	i_bad


SROFF = 70
	.globl	_runrun
	.globl	_trap
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
	addql	#2,sp		| Discard fake word
	rte
