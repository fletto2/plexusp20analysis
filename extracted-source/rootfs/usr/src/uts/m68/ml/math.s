/* SID @(#)math.s	5.2 */

/* signed long division: quotient = dividend / divisor */

	.globl	ldiv
	.text

ldiv:	link	a6,#0
	moveml	#0x3C00,sp@-	|need d2,d3,d4,d5 registers
	movl	#1,d5		|sign of result
	movl	a6@(8),d0	|dividend
	jge	ldiv1
	negl	d0
	negl	d5
ldiv1:	movl	d0,d3		|save positive dividend
	movl	a6@(12),d1	|divisor
	jge	ldiv2
	negl	d1
	negl	d5
ldiv2:	movl	d1,d4		|save positive divisor

	cmpl	#0x10000,d1	|divisor >= 2 ** 16?
	jge	ldiv3		|yes, divisor must be < 2 ** 16
	clrw	d0		|divide dividend
	swap	d0		|  by 2 ** 16
	divu	d1,d0		|get the high order bits of quotient
	movw	d0,d2		|save quotient high
	movw	d3,d0		|dividend low + remainder * (2**16)
	divu	d1,d0		|get quotient low
	swap	d0		|temporarily save quotient low in high
	movw	d2,d0		|restore quotient high to low part of register
	swap	d0		|put things right
	jra	ldiv5		|return

ldiv3:	asrl	#1,d0		|shift dividend
	asrl	#1,d1		|shift divisor
	andl	#0x7FFFFFFF,d0	|insure positive
	andl	#0x7FFFFFFF,d0	|  sign bit
	cmpl	#0x10000,d1	|divisor < 2 ** 16?
	jge	ldiv3		|no, continue shift
	divu	d1,d0		|yes, divide, remainder is garbage
	andl	#0xFFFF,d0	|get rid of remainder
	movl	d0,d2		|save quotient
	movl	d0,sp@-		|call ulmul with quotient
	movl	d4,sp@-		|  and saved divisor on stack
	jsr	ulmul		|  as arguments
	addql	#8,sp		|restore sp
	cmpl	d0,d3		|original dividend >= lmul result?
	jge	ldiv4		|yes, quotient should be correct
	subql	#1,d2		|no, fix up quotient

ldiv4:	movl	d2,d0		|move quotient to d0
ldiv5:	tstl	d5		|sign of result
	jge	ldiv6
	negl	d0
ldiv6:	moveml	sp@+,#0x3C	|restore registers
	unlk	a6
	rts

/* unsigned long multiply: c = a * b */

	.globl	ulmul
	.text

ulmul:	link	a6,#0
	moveml	#0x3000,sp@-	|save d2,d3
	movl	a6@(8),d2	|d2 = a
	movl	a6@(12),d3	|d3 = b

	clrl	d0
	movw	d2,d0		|d0 = alo, unsigned
	mulu	d3,d0		|d0 = blo*alo, unsigned
	movw	d2,d1		|d1 = alo
	swap	d2		|swap alo-ahi
	mulu	d3,d2		|d2 = blo*ahi, unsigned
	swap	d3		|swap blo-bhi
	mulu	d3,d1		|d1 = bhi*alo, unsigned
	addl	d2,d1		|d1 = (ahi*blo + alo*bhi)
	swap	d1		|d1 =
	clrw	d1		|   (ahi*blo + alo*bhi)*(2**16)
	addl	d1,d0		|d0 = alo*blo + (ahi*blo + alo*bhi)*(2**16)

	moveml	sp@+,#0xC	|restore d2,d3
	unlk	a6
	rts

/* signed long multiply: c = a * b */

	.globl	lmul
	.text

lmul:	link	a6,#0
	moveml	#0x3800,sp@-	|save d2,d3,d4
	movl	#1,d4		|sign of result
	movl	a6@(8),d2	|d2 = a
	bge	lmul1
	negl	d2
	negl	d4
lmul1:	movl	a6@(12),d3	|d3 = b
	bge	lmul2
	negl	d3
	negl	d4

lmul2:	clrl	d0
	movw	d2,d0		|d0 = alo, unsigned
	mulu	d3,d0		|d0 = blo*alo, unsigned
	movw	d2,d1		|d1 = alo
	swap	d2		|swap alo-ahi
	mulu	d3,d2		|d2 = blo*ahi, unsigned
	swap	d3		|swap blo-bhi
	mulu	d3,d1		|d1 = bhi*alo, unsigned
	addl	d2,d1		|d1 = (ahi*blo + alo*bhi)
	swap	d1		|d1 =
	clrw	d1		|   (ahi*blo + alo*bhi)*(2**16)
	addl	d1,d0		|d0 = alo*blo + (ahi*blo + alo*bhi)*(2**16)
	tstl	d4		|sign of result
	bge	lmul3
	negl	d0

lmul3:	moveml	sp@+,#0x1C	|restore d2,d3,d4
	unlk	a6
	rts

/* signed long remainder: a = a % b */

	.globl	lrem
	.text

lrem:	link	a6,#0
	moveml	#0x3800,sp@-	|need d2,d3,d4 registers
	movl	#1,d4		|sign of result
	movl	a6@(8),d0	|dividend
	bge	lrem1
	negl	d0
	negl	d4
lrem1:	movl	d0,d2		|save positive dividend
	movl	a6@(12),d1	|divisor
	bge	lrem2
	negl	d1

lrem2:	cmpl	#0x10000,d1	|divisor < 2 ** 16?
	bge	lrem3		|no, divisor must be < 2 ** 16
	clrw	d0		|d0 =
	swap	d0		|   dividend high
	divu	d1,d0		|yes, divide
	movw	d2,d0		|d0 = remainder high + quotient low
	divu	d1,d0		|divide
	clrw	d0		|d0 = 
	swap	d0		|   remainder
	bra	lrem6		|return

lrem3:	movl	d1,d3		|save divisor
lrem4:	asrl	#1,d0		|shift dividend
	asrl	#1,d1		|shift divisor
	andl	#0x7FFFFFFF,d0	|assure positive
	andl	#0x7FFFFFFF,d1	|  sign bit
	cmpl	#0x10000,d1	|divisor < 2 ** 16?
	bge	lrem4		|no, continue shift
	divu	d1,d0		|yes, divide
	andl	#0xFFFF,d0	|erase remainder
	movl	d0,sp@-		|call ulmul with quotient
	movl	d3,sp@-		|  and saved divisor on stack
	jsr	ulmul		|  as arguments
	addql	#8,sp		|restore sp
	cmpl	d0,d2		|original dividend >= lmul result?
	jge	lrem5		|yes, quotient should be correct
	subl	d3,d0		|no, fixup 
lrem5:	subl	d2,d0		|calculate
	negl	d0		|  remainder

lrem6:	tstl	d4		|sign of result
	bge	lrem7
	negl	d0
lrem7:	moveml	sp@+,#0x1C	|restore registers
	unlk	a6
	rts

/* unsigned long division: dividend = dividend / divisor */

	.globl	uldiv
	.text

uldiv:	link	a6,#0
	moveml	#0x3800,sp@-	|need d2,d3,d4 registers
	movl	a6@(8),d0	|dividend
	movl	d0,d3		|save dividend
	movl	a6@(12),d1	|divisor
	movl	d1,d4		|save divisor

	cmpl	#0x10000,d1	|divisor >= 2 ** 16?
	jge	uld1		|yes, divisor must be < 2 ** 16
	swap	d0		|divide dividend
	andl	#0xFFFF,d0	|  by 2 ** 16
	divu	d1,d0		|get the high order bits of quotient
	movw	d0,d2		|save quotient high
	movw	d3,d0		|dividend low + remainder * (2**16)
	divu	d1,d0		|get quotient low
	swap	d0		|temporarily save quotient low in high
	movw	d2,d0		|restore quotient high to low part of register
	swap	d0		|put things right
	jra	uld3		|return

uld1:	asrl	#1,d0		|shift dividend
	asrl	#1,d1		|shift divisor
	andl	#0x7FFFFFFF,d0	|assure positive
	andl	#0x7FFFFFFF,d1	|  sign bit
	cmpl	#0x10000,d1	|divisor < 2 ** 16?
	jge	uld1		|no, continue shift
	divu	d1,d0		|yes, divide, remainder is garbage
	andl	#0xFFFF,d0	|get rid of remainder
	movl	d0,d2		|save quotient
	movl	d0,sp@-		|call ulmul with quotient
	movl	d4,sp@-		|  and saved divisor on stack
	jsr	ulmul		|  as arguments
	addql	#8,sp		|restore sp
	cmpl	d0,d3		|original dividend >= lmul result?
	jge	uld2		|yes, quotient should be correct
	subql	#1,d2		|no, fix up quotient
uld2:	movl	d2,d0		|move quotient to d0

uld3:	moveml	sp@+,#0x1C	|restore registers
	unlk	a6
	rts

/* unsigned long remainder: a = a % b */

	.globl	ulrem
	.text

ulrem:	link	a6,#0
	moveml	#0x3000,sp@-	|need d2,d3 registers
	movl	a6@(8),d0	|dividend
	movl	d0,d2		|save dividend
	movl	a6@(12),d1	|divisor

	cmpl	#0x10000,d1	|divisor < 2 ** 16?
	bge	ulr1		|no, divisor must be < 2 ** 16
	clrw	d0		|d0 =
	swap	d0		|   dividend high
	divu	d1,d0		|yes, divide
	movw	d2,d0		|d0 = remainder high + quotient low
	divu	d1,d0		|divide
	clrw	d0		|d0 = 
	swap	d0		|   remainder
	bra	ulr4		|return

ulr1:	movl	d1,d3		|save divisor
ulr2:	asrl	#1,d0		|shift dividend
	asrl	#1,d1		|shift divisor
	andl	#0x7FFFFFFF,d0	|assure positive
	andl	#0x7FFFFFFF,d1	|  sign bit
	cmpl	#0x10000,d1	|divisor < 2 ** 16?
	bge	ulr2		|no, continue shift
	divu	d1,d0		|yes, divide
	andl	#0xFFFF,d0	|erase remainder
	movl	d0,sp@-		|call ulmul with quotient
	movl	d3,sp@-		|  and saved divisor on stack
	jsr	ulmul		|  as arguments
	addql	#8,sp		|restore sp
	cmpl	d0,d2		|original dividend >= lmul result?
	jge	ulr3		|yes, quotient should be correct
	subl	d3,d0		|no, fixup 
ulr3:	subl	d2,d0		|calculate
	negl	d0		|  remainder

ulr4:	moveml	sp@+,#0xC	|restore registers
	unlk	a6
	rts


	.text
/*
 * now does unsigned compares like z8000 version
 */
.globl _min
_min:
	movl	sp@(8),d0
	cmpl	sp@(4),d0
	bcs	.L1
	movl	sp@(4),d0
.L1:
	rts
/*
 * now does unsigned compares like z8000 version
 */
.globl _max
_max:
	movl	sp@(4),d0
	cmpl	sp@(8),d0
	jls	.L3
	jra	.L2
.L3:
	movl	sp@(8),d0
.L2:
	rts

/* the following is the math library for the greenhills compiler */
.text

POSDIV:
	cmpl	#0xffff,d2
	bhis	LONGDIV
	movw	d1,a1
	clrw	d1
	swap	d1
	divu	d2,d1
	movl	d1,d0
	swap	d1
	movw	a1,d0
	divu	d2,d0
	movw	d0,d1
	clrw	d0
	swap	d0
	rts

LONGDIV:
	movl	d1,d0
	clrw	d0
	swap	d0
	swap	d1
	clrw	d1
	movl	d2,a1
	moveq	#0xf,d2

LABEL1:
	addl	d1,d1
	addxl	d0,d0
	cmpl	d0,a1
	bhis	LDEX
	subl	a1,d0
	addqw	#1,d1

LDEX:
	dbf	d2,LABEL1
	rts

	.globl	lmult
lmult:

	.globl	ulmult
ulmult:
	movl	d2,sp@-
	movl	d0,d2
	mulu	d1,d2
	movl	d2,a0
	movl	d0,d2
	swap	d2
	mulu	d1,d2
	swap	d1
	mulu	d1,d0
	addl	d2,d0
	swap	d0
	clrw	d0
	addl	d0,a0
	movl	a0,d0
	movl	sp@+,d2
	rts

	.globl	ulmodt
ulmodt:
	movl	d2,sp@-
	movl	d1,d2
	movl	d0,d1
	jsr	POSDIV
	movl	sp@+,d2
	rts

	.globl	uldivt
uldivt:
	movl	d2,sp@-
	movl	d1,d2
	movl	d0,d1
	jsr	POSDIV
	movl	d1,d0
	movl	sp@+,d2
	rts

	.globl	lmodt
lmodt:
	movl	d2,sp@-
	movl	d1,d2
	bges	lremt1
	negl	d2

lremt1:
	movl	d0,d1
	moveq	#0x0,d0
	tstl	d1
	bges	lremt2
	negl	d1
	notl	d0

lremt2:
	movl	d0,a0
	jsr	POSDIV
	movw	a0,d2
	beqs	lremDONE
	negl	d0

lremDONE:
	movl	sp@+,d2
	rts

	.globl	ldivt
ldivt:
	movl	d2,sp@-
	movl	d0,a0
	moveq	#0x0,d0
	movl	d1,d2
	bges	ldivt1
	negl	d2
	notl	d0

ldivt1:
	movl	a0,d1
	bges	ldivt2
	negl	d1
	notl	d0

ldivt2:
	movl	d0,a0
	jsr	POSDIV
	movl	a0,d2
	beqs	ldivRET
	negl	d1

ldivRET:
	movl	d1,d0
	movl	sp@+,d2
	rts
