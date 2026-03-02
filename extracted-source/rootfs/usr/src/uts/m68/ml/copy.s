/* SID @(#)copy.s	5.6 */
#ifdef robin
#include "rcopy.s"
#else
#include "sys/param.h"
#include "sys/psl.h"
#include "sys/mtpr.h"
#include "sys/page.h"

#ifdef MONITOR
	.data
	.globl	_copy_statistics
_copy_statistics:
seg_calls:	.long	0
clr_calls:	.long	0
in_calls:	.long	0
out_calls:	.long	0
in_1_4:		.long	0
in_5_49:	.long	0
in_50_511:	.long	0
in_512:		.long	0
in_513_inf:	.long	0
in_odd:		.long	0
in_bswap:	.long	0
out_1_4:	.long	0
out_5_49:	.long	0
out_50_511:	.long	0
out_512:	.long	0
out_513_inf:	.long	0
out_odd:	.long	0
out_bswap:	.long	0
#endif

/* defines for moveml register moves */
REGS	=	0x7cfe	/* register bit mask for d1-d7 and a2-a6 with incrementing addresses */
BREGS	=	48	/* bytes per register move */

	.text
/*
 * copyseg( phys-pg-1 , phys-pg-2 )
 *
 * copies physical page 1 to physical page 2
 */
.globl _copypte
.globl _copyvad
.globl _copyseg
_copyseg:
	link	a6,#-BREGS

#ifdef MONITOR
	addql	#1,seg_calls
#endif

	movw	sr,d1		| save int state
	orw	#PSR_I,sr	| ints off
	movl	a6@(8),d0	| src ppn
	orl	#PG_NOEX+PG_NOWR,d0
	movl	_copypte,a0
	movl	d0,a0@+		| map in src pg

	movl	a6@(12),d0	| dest ppn
	orl	#PG_NOEX,d0
	movl	d0,a0@		| map in dest pg

	movl	_copyvad,a0	| src log addr
	movl	a0,a1
	addl	#NBPC,a1	| dest addr

	/* copy as many bytes as possible with moveml */
	moveml	#REGS,sp@	| save current register contents
	movl	#(NBPC/BREGS)-1,d0	| moveml loop count
.L1:
	moveml	a0@+,#REGS	| load all avaliable registers
	moveml	#REGS,a1@	| store at new location
	addw	#BREGS,a1	| no destination auto increment on moveml
	dbf	d0,.L1		| and loop till pg done	

	/* complete copy using movl */
	movl	#(NBPC-((NBPC/BREGS)*BREGS))/4-1,d0
.L11:
	movl	a0@+,a1@+
	dbf	d0,.L11

	moveml	sp@,#REGS	| restore registers

	movw	d1,sr		| restor int level
	unlk	a6
	rts


/*
 * clearseg(phys-pg)
 *
 * this routine sets physical-page to all zeros
 */
.globl _clearseg
_clearseg:

	link	a6,#-BREGS

#ifdef MONITOR
	addql	#1,clr_calls
#endif

	movw	sr,d1
	orw	#PSR_I,sr	| ints off

	movl	a6@(8),d0	| ppn
	andl	#PG_PFNUM,d0	/* just ppn */
	orl	#PG_NOEX,d0
	movl	_copypte,a0
	movl	d0,a0@

	movl	_copyvad,a0

	/* clear as many bytes as possible with moveml */
	moveml	#REGS,sp@	| save current register contents
	lea	0:w,a2
	movl	a2,a3		| clear registers
	movl	a2,a4		| clear registers
	movl	a2,a5		| clear registers
	movl	a2,a6		| clear registers
	movl	a2,d1		| clear registers
	movl	a2,d2		| clear registers
	movl	a2,d3		| clear registers
	movl	a2,d4		| clear registers
	movl	a2,d5		| clear registers
	movl	a2,d6		| clear registers
	movl	a2,d7		| clear registers

	/* main loop */
	movl	#(NBPC/BREGS)-1,d0	| moveml loop count
.L2:
	moveml	#REGS,a0@	| store at new location
	addw	#BREGS,a0	| no destination auto increment on moveml
	dbf	d0,.L2		| and loop till pg done	

	/* complete using movl */
	movl	#(NBPC-((NBPC/BREGS)*BREGS))/4-1,d0
.L22:
	movl	a2,a0@+
	dbf	d0,.L22

	moveml	sp@,#REGS	| restore registers

	movw	d1,sr		| restor int level
	unlk	a6
	rts

/*
 * this routine initializes in core map tables fast
 */
.globl _clearmap
_clearmap:
#define NUMTOMOV (NBPC+NBPC)
	link	a6,#-BREGS

	movl	a6@(8),d0	| address
	movl	d0,a0

	/* set as many bytes as possible with moveml */
	moveml	#REGS,sp@	| save current register contents
	movl	#PG_PFNUM+PG_NORD+PG_NOWR+PG_NOEX,d0
	movl	d0,a2
	movl	a2,a3		| setup registers
	movl	a2,a4		| setup registers
	movl	a2,a5		| setup registers
	movl	a2,a6		| setup registers
	movl	a2,d1		| setup registers
	movl	a2,d2		| setup registers
	movl	a2,d3		| setup registers
	movl	a2,d4		| setup registers
	movl	a2,d5		| setup registers
	movl	a2,d6		| setup registers
	movl	a2,d7		| setup registers

	/* main loop */
	movl	#(NUMTOMOV/BREGS)-1,d0	| moveml loop count
.L99:
	moveml	#REGS,a0@	| store at new location
	addw	#BREGS,a0	| no destination auto increment on moveml
	dbf	d0,.L99		| and loop till pg done	

	/* complete using movl */
	movl	#(NUMTOMOV-((NUMTOMOV/BREGS)*BREGS))/4-1,d0
.L98:
	movl	a2,a0@+
	dbf	d0,.L98

	moveml	sp@,#REGS	| restore registers

	unlk	a6
	rts

/*
 * bcopy(src,dest,bytes)
 *
 * copies bytes from src to dest 
 *   copies logical to logical--caller must map if needed
 */

/* copy words */
.globl _wcopy
_wcopy:
	link	a6,#0
	movl	a6@(8),a0	| src byte addr
	movl	a6@(12),a1	| dest byte addr
#if !defined(SCHROEDER) && !defined(KICKER)
	movl	a0,d0
	orl	a6@(12),d0
	andl	#0x1,d0
	beq	.L136
	movl	a6@(16),d0
	lsll	#1,d0
	bra	.Lbcpy2
.L136:
#endif
	movl	a6@(16),d0	| word cnt
	lsrl	#1,d0
	jeq	.L135		| none to move...
	subql	#1,d0		| adj for dbcc loop
.L138:
	movl	a0@+,a1@+	| move a long
	dbf	d0,.L138	| loop till done

/* now move left over stuff */
.L135:
	movl	a6@(16),d0	| word cnt
	btst	#1,d0
	beq	.L137
	movw	a0@+,a1@+
.L137:
	unlk	a6
	rts

/* copy longs */
.globl _lcopy
_lcopy:
	link	a6,#0
	movl	a6@(8),a0	| src byte addr
	movl	a6@(12),a1	| dest byte addr
#if !defined(SCHROEDER) && !defined(KICKER)
	movl	a0,d0
	orl	a6@(12),d0
	andl	#0x1,d0
	beq	.L134
	movl	a6@(16),d0
	lsll	#2,d0
	bra	.Lbcpy2
.L134:
#endif
	movl	a6@(16),d0	| long cnt
	jeq	.L5
	subql	#1,d0		| adj for dbcc loop
.L139:
	movl	a0@+,a1@+	| move a long
	dbf	d0,.L139	| loop till done
	unlk	a6
	rts

/* copy bytes */
.globl _bcopy
_bcopy:
	link	a6,#0

	movl	a6@(8),a0	| src byte addr
	movl	a6@(12),a1	| dest byte addr

#if !defined(SCHROEDER) && !defined(KICKER)
	movl	a0,d0
	orl	a6@(12),d0
	andl	#0x1,d0
	bne	.Lbcopy
#endif
	movl	a6@(16),d0	| byte cnt
	jeq	.L5		| none to move...

	lsrl	#2,d0
	subql	#1,d0		| adj for dbcc loop
.L133:
	movl	a0@+,a1@+	| move a long
	dbf	d0,.L133		| loop till done

/* now move left over stuff */
	movl	a6@(16),d0	| byte cnt
	btst	#1,d0
	beq	.L132
	movw	a0@+,a1@+
.L132:
	btst	#0,d0
	beq	.L131
	movb	a0@+,a1@+
.L131:
	unlk	a6
	rts

/* last ditch byte by byte copy */
.Lbcopy:
	movl	a6@(16),d0	| byte cnt
.Lbcpy2:
	jeq	.L5
	subql	#1,d0		| adj for dbcc loop

/* do not change the instructions in the following loop */
.L4:
	movb	a0@+,a1@+	| move a byte
	dbf	d0,.L4		| loop till done
.L5:
	unlk	a6
	rts


/*
 * copyin(usr_src_addr,sys_dest_addr,bytecnt)
 * copyout(sys_src_addr,usr_dest_addr,bytecnt)
 *
 */
#ifdef SYS3
.globl _copyipt
.globl _copyiva
#else
.globl _copyipte
.globl _copyivad
#endif
.globl _berrflg
.globl _copyin
_copyin:
	link	a6,#-BREGS

#ifdef MONITOR
	addql	#1,in_calls
	movl	a6@(16),d0
	ble	IM9
	cmpl	#4,d0
	bgt	IM6
	addql	#1,in_1_4
	bra	IM9
IM6:
	cmpl	#49,d0
	bgt	IM1
	addql	#1,in_5_49
	bra	IM9
IM1:
	cmpl	#511,d0
	bgt	IM2
	addql	#1,in_50_511
	bra	IM9
IM2:
	cmpl	#512,d0
	bne	IM3
	addql	#1,in_512
	bra	IM9
IM3:
	addql	#1,in_513_inf
IM9:
	movl	a6@(8),d0
	movl	a6@(12),d1
	addl	d0,d1
	btst	#0,d1
	beq	IM4
	addql	#1,in_bswap
IM4:
	orl	a6@(12),d0
	btst	#0,d0
	beq	IM5
	addql	#1,in_odd
IM5:
#endif

.L6:
	/* load the map for the copy */
	movl	a6@(8),d0	| usr src addr
	movl	#BPCSHIFT,d1	| page shift factor
	lsrl	d1,d0		| -> page number
	cmpl	#MAXMEM-1,d0	| if user addr too high give err now
	jgt	_coperr		| too bad if addr too high
	lsll	#2,d0		| -> map table offset
	movl	#UMLO,a0	| base user page map
	addl	d0,a0		| offset into user page map
#ifdef SYS3
	movl	_copyipt,a1
#else
	movl	_copyipte,a1
#endif
	movl	a0@,d0		| move page entry into d0
	andl	#PG_MAPID,d0	| and to get at id
	movl	#PG_IDSHIFT,d1	| load shift count
	lsrl	d1,d0		| shift to get at id
#ifndef KICKER
	cmpb	P_RMAPID,d0	| compare with current id
#else
	movw	P_RMAPID,d1	| get current id
	andw	#M_RMAPID,d1	| mask off junk
	cmpw	d1,d0		| compare
#endif
	beq	.L62
	movl	#PG_INV,a1@+
	movl	a0@+,d0
	bra	.L63
.L62:
	movl	a0@+,a1@+	| map user page 
.L63:
	movl	a0@,d0		| move page entry into d0
	andl	#PG_MAPID,d0	| and to get at id
	movl	#PG_IDSHIFT,d1	| load shift count
	lsrl	d1,d0		| shift to get at id
#ifndef KICKER
	cmpb	P_RMAPID,d0	| compare with current id
#else
	movw	P_RMAPID,d1	| get current id
	andw	#M_RMAPID,d1	| mask off junk
	cmpw	d1,d0		| compare
#endif
	beq	.L60
	movl	#PG_INV,a1@
	bra	.L61
.L60:
	movl	a0@,a1@		| map next for page overflow 
.L61:

	/* get source address in a0 and destination address in a1 */
	movl	a6@(8),d0	| usr src addr 
	andl	#NBPC-1,d0	| offset into page
#ifdef SYS3
	movl	_copyiva,a0	| log addr of sys temp area
#else
	movl	_copyivad,a0	| log addr of sys temp area
#endif
	addl	d0,a0		| mapped src addr - DONT HURT D0 til after alingment check
	movl	a6@(12),a1	| sys dest addr
	movl	#_coperr,_berrflg | in case of trap

	/* check for  both addresses being word aligned (almost always is) */
	movl	a1,d1
	orw	d1,d0		| d0 has low 12 bits of source already
	btst	#0,d0
	beq	CI1		| jmp if both addresses word aligned

	/* use movb to copy at most one page - this is mandatory if the
	addresses do not have the same word alignment. If both addresses
	were odd they could be aligned but this is so rare that checking
	for this case would take more time than it would save */

	movl	#NBPC,d1	| maximum amount to copy now - one page
	addl	d1,a6@(12)	| bump dest addr for next
	addl	d1,a6@(8)	| bump source for next
	movl	a6@(16),d0	| # bytes
	cmpl	d1,d0
	ble	.L7		| br if moving .le. 1 page
	movl	d1,d0		| > 1 pg. only move 1 now
.L7:
	subl	d0,a6@(16)	| adj byte count

#if defined(SCHROEDER) || defined(KICKER)

	btst	#0,d0
	beq	.L831
	movb	a0@+,a1@+
	subql	#1,d0
	jeq	.L835		| none to move...
.L831:
	btst	#1,d0
	beq	.L832
	movw	a0@+,a1@+
	subql	#2,d0
	jeq	.L835		| none to move...
.L832:
	btst	#2,d0
	beq	.L837
	movl	a0@+,a1@+
	subql	#4,d0
	jeq	.L835		| none to move...
.L837:
	btst	#3,d0
	beq	.L838
	movl	a0@+,a1@+
	movl	a0@+,a1@+
	subql	#8,d0
	jeq	.L835		| none to move...
.L838:
	btst	#4,d0
	beq	.L839
	movl	a0@+,a1@+
	movl	a0@+,a1@+
	movl	a0@+,a1@+
	movl	a0@+,a1@+
	subl	#16,d0
	jeq	.L835		| none to move...
.L839:
	lsrl	#5,d0
	subql	#1,d0		| adj for dbcc loop
.L833:
	movl	a0@+,a1@+	| move a long
	movl	a0@+,a1@+	| move a long
	movl	a0@+,a1@+	| move a long
	movl	a0@+,a1@+	| move a long
	movl	a0@+,a1@+	| move a long
	movl	a0@+,a1@+	| move a long
	movl	a0@+,a1@+	| move a long
	movl	a0@+,a1@+	| move a long
	dbf	d0,.L833		| loop till done

#else

	subql	#1,d0		| for dbcc loop
.L8:
	movb	a0@+,a1@+	| move a byte
	dbf	d0,.L8		| loop till done
	clrl	_berrflg

#endif

.L835:
	tstl	a6@(16)		| any more bytes to move?
	bgt	.L6		| br if yes
	unlk	a6
	clrl	d0		| good return
	rts

	/* check for the most common case : copying < 150 bytes and go straight
	to the movl loop to avoid excessive overhead checking */
CI1:
	movl	a6@(16),d0	| fetch byte count
	cmpl	#BREGS*3+2,d0	| require moveml loop to cycle 3 times 
	blt	CI2		| jmp if moveml would be inefficient

	/* check for more than a page which will require multiple mappings */
	cmpl	#NBPC,d0
	ble	CI3		| jmp if no remapping will be required

	/* do as many moveml's as possible within one page */
	moveml	#REGS,sp@	| save current register contents
	movl	#_rrcoperr,_berrflg | in case of trap
	movl	#(NBPC/BREGS)-1,d0	| moveml loop count
CI11:
	moveml	a0@+,#REGS	| load all avaliable registers
	moveml	#REGS,a1@	| store at new location
	addw	#BREGS,a1	| no destination auto increment on moveml
	dbf	d0,CI11		| and loop till pg done	
	moveml	sp@,#REGS	| restore registers

	/* adjust pointers and start all over */
	clrl	_berrflg	| clear trap flag
	movl	#(NBPC/BREGS)*BREGS,d0	| number of bytes actually copied
	addl	d0,a6@(8)	| bump source
	addl	d0,a6@(12)	| bump dest
	subl	d0,a6@(16)	| dec count
	bra	.L6		| start over at the top

	/* do as many moveml's as possible without overflowing */
	/* note that memory to register moveml does one extra word read so
	it is necessary to stop one word early to avoid unnecessary trap */
CI3:
	subw	#BREGS+1,d0	| adjust cnt to terminate in time
				| d0 is <= NBPC so subw will work like subl
	moveml	#REGS,sp@	| save current register contents
	movl	#_rrcoperr,_berrflg | in case of trap
CI10:
	moveml	a0@+,#REGS	| load all avaliable registers
	moveml	#REGS,a1@	| store at new location
	addw	#BREGS,a1	| no destination auto increment on moveml
	subw	#BREGS,d0	| decrement count
	bgt	CI10		| jmp if more to do
	moveml	sp@,#REGS	| restore registers
	addw	#BREGS+1,d0	| correct the count to real remaining

	/* split count into a long count in d0 and a byte count in d1 */
CI2:
	movl	d0,d1
	andw	#3,d1		| extract odd number of bytes to copy
	asrl	#2,d0		| divide by 4 to get long count

	/* use movl to copy as much as possible */
	bra	CI5		| enter at bottom of loop for case of 0
CI4:
	movl	a0@+,a1@+
CI5:	dbf	d0,CI4

	/* use movb to copy remaining bytes */
	bra	CI7		| enter at bottom of loop for case of 0
CI6:
	movb	a0@+,a1@+
CI7:	dbf	d1,CI6

	/* copy has completed successfully so return */
	clrl	_berrflg
	unlk	a6
	clrl	d0
	rts

.globl _coperr
.globl _rrcoperr
_rrcoperr:
	moveml	sp@,#REGS	| resore registers if moveml loop in progress
_coperr:
	unlk	a6
	movl	#-1,d0		| err return
	rts


#ifdef SYS3
.globl _copyopt
.globl _copyova
#else
.globl _copyopte
.globl _copyovad
#endif
.globl _copyout
_copyout:
	link	a6,#-BREGS

#ifdef MONITOR
	addql	#1,out_calls
	movl	a6@(16),d0
	ble	OM9
	cmpl	#4,d0
	bgt	OM6
	addql	#1,out_1_4
	bra	OM9
OM6:
	cmpl	#49,d0
	bgt	OM1
	addql	#1,out_5_49
	bra	OM9
OM1:
	cmpl	#511,d0
	bgt	OM2
	addql	#1,out_50_511
	bra	OM9
OM2:
	cmpl	#512,d0
	bne	OM3
	addql	#1,out_512
	bra	OM9
OM3:
	addql	#1,out_513_inf
OM9:
	movl	a6@(8),d0
	movl	a6@(12),d1
	addl	d0,d1
	btst	#0,d1
	beq	OM4
	addql	#1,out_bswap
OM4:
	orl	a6@(12),d0
	btst	#0,d0
	beq	OM5
	addql	#1,out_odd
OM5:
#endif
.L66:
	/* load the map for the copy */
	movl	a6@(12),d0	| usr dest addr
	movl	#BPCSHIFT,d1	| page shift factor
	lsrl	d1,d0		| -> page number
	cmpl	#MAXMEM-1,d0	| if user addr too high give err now
	jgt	_coperr		| too bad if addr too high
	lsll	#2,d0		| -> map table offset
	movl	#UMLO,a0	| base user page map
	addl	d0,a0		| offset into user page map
#ifdef SYS3
	movl	_copyopt,a1
#else
	movl	_copyopte,a1
#endif
	movl	a0@,d0		| move page entry into d0
	andl	#PG_MAPID,d0	| and to get at id
	movl	#PG_IDSHIFT,d1	| load shift count
	lsrl	d1,d0		| shift to get at id
#ifndef KICKER
	cmpb	P_RMAPID,d0	| compare with current id
#else
	movw	P_RMAPID,d1	| get current id
	andw	#M_RMAPID,d1	| mask off junk
	cmpw	d1,d0		| compare
#endif
	beq	.L82
	movl	#PG_INV,a1@+
	movl	a0@+,d0
	bra	.L83
.L82:
	movl	a0@+,a1@+	| map user page 
.L83:
	movl	a0@,d0		| move page entry into d0
	andl	#PG_MAPID,d0	| and to get at id
	movl	#PG_IDSHIFT,d1	| load shift count
	lsrl	d1,d0		| shift to get at id
#ifndef KICKER
	cmpb	P_RMAPID,d0	| compare with current id
#else
	movw	P_RMAPID,d1	| get current id
	andw	#M_RMAPID,d1	| mask off junk
	cmpw	d1,d0		| compare
#endif
	beq	.L80
	movl	#PG_INV,a1@
	bra	.L81
.L80:
	movl	a0@,a1@		| map next for page overflow 
.L81:

	/* get source address in a1 and destination address in a0 */
	movl	a6@(12),d0	| usr dest addr 
	andl	#NBPC-1,d0	| offset into page
#ifdef SYS3
	movl	_copyova,a0	| log addr of sys temp area
#else
	movl	_copyovad,a0	| log addr of sys temp area
#endif
	addl	d0,a0		| mapped dest addr - DONT HURT D0 til after alingment check
	movl	a6@(8),a1	| sys src addr
	movl	#_coperr,_berrflg | in case of trap

	/* check for  both addresses being word aligned (almost always is) */
	movl	a1,d1
	orw	d1,d0		| d0 has low 12 bits of destination already
	btst	#0,d0
	beq	CO1		| jmp if both addresses word aligned

	/* use movb to copy at most one page - this is mandatory if the
	addresses do not have the same word alignment. If both addresses
	were odd they could be aligned but this is so rare that checking
	for this case would take more time than it would save */

	movl	#NBPC,d1	| maximum amount to copy now - one page
	addl	d1,a6@(12)	| bump usr dest addr for next
	addl	d1,a6@(8)	| bump source for next
	movl	a6@(16),d0	| # bytes
	cmpl	d1,d0
	ble	.L77		| br if moving .le. 1 page
	movl	d1,d0		| > 1 pg. only move 1 now
.L77:
	subl	d0,a6@(16)	| adj byte count
	subql	#1,d0		| for dbcc loop
.L88:
	movb	a1@+,a0@+	| move a byte
	dbf	d0,.L88		| loop till done
	clrl	_berrflg
	tstl	a6@(16)		| any more bytes to move?
	bgt	.L66		| br if yes

	unlk	a6
	clrl	d0		| good return
	rts

	/* check for the most common case : copying < 150 bytes and go straight
	to the movl loop to avoid excessive overhead checking */
CO1:
	movl	a6@(16),d0	| fetch byte count
	cmpl	#BREGS*3+2,d0	| require moveml loop to cycle 3 times 
	blt	CO2		| jmp if moveml would be inefficient

	/* check for more than a page which will require multiple mappings */
	cmpl	#NBPC,d0
	ble	CO3		| jmp if no remapping will be required

	/* do as many moveml's as possible within one page */
	moveml	#REGS,sp@	| save current register contents
	movl	#_rrcoperr,_berrflg | in case of trap
	movl	#(NBPC/BREGS)-1,d0	| moveml loop count
CO11:
	moveml	a1@+,#REGS	| load all avaliable registers
	moveml	#REGS,a0@	| store at new location
	addw	#BREGS,a0	| no destination auto increment on moveml
	dbf	d0,CO11		| and loop till pg done	
	moveml	sp@,#REGS	| restore registers

	/* adjust pointers and start all over */
	clrl	_berrflg	| clear trap flag
	movl	#(NBPC/BREGS)*BREGS,d0	| number of bytes actually copied
	addl	d0,a6@(8)	| bump source
	addl	d0,a6@(12)	| bump dest
	subl	d0,a6@(16)	| dec count
	bra	.L66		| start over at the top

	/* do as many moveml's as possible without overflowing */
	/* note that memory to register moveml does one extra word read so
	it is necessary to stop one word early to avoid unnecessary trap */
CO3:
	subw	#BREGS+1,d0	| adjust cnt to terminate in time
				| d0 is <= NBPC so subw will work like subl
	moveml	#REGS,sp@	| save current register contents
	movl	#_rrcoperr,_berrflg | in case of trap
CO10:
	moveml	a1@+,#REGS	| load all avaliable registers
	moveml	#REGS,a0@	| store at new location
	addw	#BREGS,a0	| no destination auto increment on moveml
	subw	#BREGS,d0	| decrement count
	bgt	CO10		| jmp if more to do
	moveml	sp@,#REGS	| restore registers
	addw	#BREGS+1,d0	| correct the count to real remaining

	/* split count into a long count in d0 and a byte count in d1 */
CO2:
	movl	d0,d1
	andw	#3,d1		| extract odd number of bytes to copy
	asrl	#2,d0		| divide by 4 to get long count

	/* use movl to copy as much as possible */
	bra	CO5		| enter at bottom of loop for case of 0
CO4:
	movl	a1@+,a0@+
CO5:	dbf	d0,CO4

	/* use movb to copy remaining bytes */
	bra	CO7		| enter at bottom of loop for case of 0
CO6:
	movb	a1@+,a0@+
CO7:	dbf	d1,CO6

	/* copy has completed successfully so return */
	clrl	_berrflg
	unlk	a6
	clrl	d0
	rts
#endif



/* ml utility to zero some memory */
.globl _bzero
_bzero:
	link	a6,#0
	movl	a6@(8),a0	| src byte addr

/* watch for odd addresses if not 68020 */
#if !defined(SCHROEDER) && !defined(KICKER)
	movl	a0,d0
	andl	#1,d0
	bne	.Lbzero
#endif
	movl	a6@(12),d0	| byte cnt

/* start by doing all the longs */
	lsrl	#2,d0
	beq	.L234		| none to move...
	subql	#1,d0		| adj for dbcc loop
.L233:
	movl	#0,a0@+
	dbf	d0,.L233		| loop till done

/* now do the left over bytes */
.L234:
	movl	a6@(12),d0	| byte cnt
	btst	#1,d0
	beq	.L232
	movw	#0,a0@+
.L232:
	btst	#0,d0
	beq	.L231
	movb	#0,a0@+
.L231:
	unlk	a6
	rts

/* do it byte at a time for lesser cpu's */
.Lbzero:
	movl	a6@(12),d0	| byte cnt
	beq	.L105
	subql	#1,d0		| adj for dbcc loop

/* do not change the instructions in the following loop */
.L104:
	movb	#0,a0@+
	dbf	d0,.L104		| loop till done
.L105:
	unlk	a6
	rts
