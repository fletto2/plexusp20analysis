/* @(#)sky.s	5.2 SID */
#ifdef KICKER
| kicker does not support sky board
#else

#include "sys/sky.h"
#include "sys/param.h"
#include "sys/sysmacros.h"
#include "sys/mtpr.h"
#include "sys/psl.h"
#include "sys/page.h"
#include "sys/signal.h"
|	Driver to the Sky floating point board
	.globl	sky_hwfp
	.globl	_mblock
#ifdef SYS3
	.globl	_mbunloc
#else
	.globl	_mbunlock
#endif
	.globl	_printf
	.globl	_hardsky
	.globl	_sigproc
	.text
sky_hwfp:
|	Operands are as follows
|	d2	Hi - size of result in longwords
|		Lo - size of operands in longwords
|	d3	Lo - opcode
|	d4-d7 operands , specified by d2(Lo)
|
|	uses a1 as ptr to comreg & dt1reg
|	uses d4 as counter for time out for hung board
|
|	result returned in d0 and d1 after going thru d4, d5
|
	cmpw	#0x1000,d3	| Smallest SKY instruction
	jlt	illegal
	cmpw	#0x1062,d3	| Largest sky instruction
	jgt	illegal
	movw	sr,d0		| disable interrupts
	orw	#PSR_I,d0
	movw	d0,sr
	jsr	_mblock
	lea	comreg,a1	| command
	movw	d3,a1@
	addql	#4,a1		| dt1reg address
	movl	d4,a1@
	cmpw	#1,d2
	jeq	over		| do i have a single long word operand
	movl	d5,a1@
	cmpw	#2,d2
	jeq	over		| do i have two long words
	movl	d6,a1@		| must be four
	movl	d7,a1@
over:
|	poll board
	moveq	#100,d4
	moveq	#-1,d0
	swap	d2		| find length of result
notready:
	tstw	stcreg
	dblt	d4,notready
	cmpw	d0,d4		| Timeout ?
	jeq	ffperr
	cmpw	#0x105c,d3
	jgt	cmpop		| Compare instruction result is 1 word
	movl	a1@,d4		| First long word of result 
	cmpw	#1,d2
	jeq	complete
	movl	a1@,d5		| Second Long word in result 
complete:
#ifdef SYS3
	jsr	_mbunloc
#else
	jsr	_mbunlock
#endif
	movw	sr,d2		| enable interrupts
	andw	#~PSR_I,d2
	movw	d2,sr
	movl	d4,d0
	movl	d5,d1
illegal:			| return without doing anything
	rts
cmpop:				| compare operation movw on word only
	moveq	#0,d4
	movw	a1@,d4
	jmp	complete
ffperr:
	movw	stcreg,d4
	subql	#2,a1		| reset board phase 2 sequence from sky manual
	movw	#0x0080,a1@
	subql	#2,a1
	movw	#0x1000,a1@
	movw	#0x1001,a1@
	movw	#0x1001,a1@+
	movw	#0x0040,a1@
#ifdef SYS3
	jsr	_mbunloc
#else
	jsr	_mbunlock
#endif
	movw	sr,d2		| enable interrupts
	andw	#~PSR_I,d2
	movw	d2,sr
	swap	d3
	andl	#0xffff0000,d3
	andl	#0xffff,d4
	orl	d3,d4		| opcode in Hi word. Status in Lo word.
	movl	d4,sp@-
	movl	#Errmsg,sp@-
	jsr	_printf
	addql	#8,sp
	movl	#SIGFPE,sp@-
	jsr	_sigproc	| let the world know
	addql	#4,sp
	rts
	.data
Errmsg:
	.byte	70,108,111,97,116,105,110,103
	.byte	32,112,111,105,110,116,32,98
	.byte	111,97,114,100,32,116,105,109
	.byte	101,111,117,116,32,115,114,32
	.byte	61,32,37,120,10,0
#endif
