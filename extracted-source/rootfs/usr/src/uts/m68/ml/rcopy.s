/* SID @(#)rcopy.s	5.1 */ 
#include "sys/param.h"
#include "sys/psl.h"
#include "sys/page.h"

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
	link	a6,#0

	movw	sr,d1		| save int state
	orw	#PSR_I,sr	| ints off
	movl	a6@(8),d0	| src ppn
	orl	#PG_NOEX+PG_NOWR,d0
	movl	_copypte,a0
	movl	d0,a0@+		| map in src pg

	movl	a6@(12),d0	| dest ppn
	orl	#PG_NOEX,d0
	movl	d0,a0@		| map in dest pg

	movl	#NBPC,d0	| byte/pg
	asrl	#2,d0		| longs/pg
	subql	#1,d0		| adj for dbcc loop

	movl	_copyvad,a0	| src log addr
	movl	a0,a1
	addl	#NBPC,a1	| dest addr

/*
 * the following two word loop is special cased in the 
 * 68000 hardware and is FAST. do not change it
 */
.L1:
	movl	a0@+,a1@+	| move a long word
	dbf	d0,.L1		| and loop till pg done	

	movw	d1,sr		| restor int level
	unlk	a6
	rts


/*
 * clearseg(phys-pg)
 *
 * this routine sets physical-page to all zeros
 */
#ifdef SYS3
.globl _clearse
_clearse:
#else
.globl _clearseg
_clearseg:
#endif

	link	a6,#0

	movw	sr,d1
	orw	#PSR_I,sr	| ints off

	movl	a6@(8),d0	| ppn
	andl	#PG_PFNUM,d0	/* just ppn */
	orl	#PG_NOEX,d0
	movl	_copypte,a0
	movl	d0,a0@

	movl	#NBPC,d0	| bytes/pg
	asrl	#2,d0		| longs/pg
	subql	#1,d0		| adj for dbcc loop

	movl	_copyvad,a0

/*
 * do not change the following two instructions
 */
.L2:
	clrl	a0@+		| zero out this long word
	dbf	d0,.L2		| and loop till done

	movw	d1,sr		| restore int level
	unlk	a6
	rts

/*
 * bcopy(src,dest,bytes)
 *
 * copies bytes from src to dest 
 *   copies logical to logical--caller must map if needed
 */
.globl _bcopy
_bcopy:
	link	a6,#0

	movl	a6@(8),a0	| src byte addr
	movl	a6@(12),a1	| dest byte addr
	movl	a6@(16),d0	| byte cnt
	tstl	d0		| moving zero today?
	jeq	.L5		| none to move...
	subql	#1,d0		| adj for dbcc loop

/* do not change the instructions in the following loop */
.L4:
	movb	a0@+,a1@+	| move a byte
	dbf	d0,.L4		| loop till done
.L5:
	unlk	a6
	rts

/*
 * wcopy(src,dest,words)
 *
 * copies words from src to dest 
 *   copies logical to logical--caller must map if needed
 */
.globl _wcopy
_wcopy:
	link	a6,#0

	movl	a6@(8),a0	| src word addr
	movl	a6@(12),a1	| dest word addr
	movl	a6@(16),d0	| word cnt
	tstl	d0		| moving zero today?
	jeq	.L55		| none to move...
	subql	#1,d0		| adj for dbcc loop

/* do not change the instructions in the following loop */
.L44:
	movw	a0@+,a1@+	| move a word
	dbf	d0,.L44		| loop till done
.L55:
	unlk	a6
	rts

/*
 * lcopy(src,dest,longs)
 *
 * copies longs from src to dest 
 *   copies logical to logical--caller must map if needed
 */
.globl _lcopy
_lcopy:
	link	a6,#0

	movl	a6@(8),a0	| src long addr
	movl	a6@(12),a1	| dest long addr
	movl	a6@(16),d0	| long cnt
	tstl	d0		| moving zero today?
	jeq	.L555		| none to move...
	subql	#1,d0		| adj for dbcc loop

/* do not change the instructions in the following loop */
.L444:
	movl	a0@+,a1@+	| move a long
	dbf	d0,.L444		| loop till done
.L555:
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
	link	a6,#0
.L6:
	movl	a6@(8),d0	| usr src addr
	movl	#BPCSHIFT,d1	| page shift factor
	lsrl	d1,d0		| -> page number
/* if user page out of range give error */
	cmpl	#MAXMEM-1,d0
	jgt	_coperr		| if u addr too hi give err
	lsll	#2,d0		| -> map table offset
	movl	#UMLO,a0	| base user page map
	addl	d0,a0		| offset into user page map
#ifdef SYS3
	movl	_copyipt,a1
#else
	movl	_copyipte,a1
#endif
	movl	a0@+,a1@+	| map user page 
	movl	a0@,a1@		| map next for page overflow 
	movl	#NBPC,d1
	movl	a6@(8),d0	| usr src addr 
	andl	#NBPC-1,d0	| offset into page
	addl	d1,a6@(8)	| bump usr src addr for next
#ifdef SYS3
	movl	_copyiva,a0	| log addr of sys temp area
#else
	movl	_copyivad,a0	| log addr of sys temp area
#endif
	addl	d0,a0		| mapped src addr
	movl	a6@(12),a1	| sys dest addr
	addl	d1,a6@(12)	| bump for next
	movl	a6@(16),d0	| # bytes
	cmpl	d1,d0
	ble	.L7		| br if moving .le. 1 page
	movl	d1,d0		| > 1 pg. only move 1 now
.L7:
	subl	d0,a6@(16)	| adjust byte count
	subql	#1,d0		| for dbcc loop
	movl	#_coperr,_berrflg | in case of trap
	tstb	a0@		| test the range of the move
	tstl	_berrflg
	beq	_coperr
	clrb	a1@		| possible 68010 bug ??
	tstl	_berrflg
	beq	_coperr
	tstb	a0@(0,d0:w)
	tstl	_berrflg
	beq	_coperr
	clrb	a1@(0,d0:w)
	tstl	_berrflg
	beq	_coperr
.L8:
	movb	a0@+,a1@+	| move a byte
	dbf	d0,.L8		| loop till done
	clrl	_berrflg
	tstl	a6@(16)		| any more bytes to move?
	bgt	.L6		| br if yes

	unlk	a6
	clrl	d0		| good return
	rts

.globl _coperr
_coperr:
	unlk	a6
	moveq	#-1,d0		| err return
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
	link	a6,#0
.L66:
	movl	a6@(12),d0	| usr dest addr
	movl	#BPCSHIFT,d1	| page shift factor
	lsrl	d1,d0		| -> page number
/* if user addr too high give err now */
	cmpl	#MAXMEM-1,d0
	jgt	_coperr		| too bad if addr too high
	lsll	#2,d0		| -> map table offset
	movl	#UMLO,a0	| base user page map
	addl	d0,a0		| offset into user page map
#ifdef SYS3
	movl	_copyopt,a1
#else
	movl	_copyopte,a1
#endif
	movl	a0@+,a1@+	| map user page 
	movl	a0@,a1@		| map next for page overflow 

	movl	#NBPC,d1
	movl	a6@(12),d0	| usr dest addr 
	andl	#NBPC-1,d0	| offset into page
	addl	d1,a6@(12)	| bump usr dest addr for next
#ifdef SYS3
	movl	_copyova,a0	| log addr of sys temp area
#else
	movl	_copyovad,a0	| log addr of sys temp area
#endif
	addl	d0,a0		| mapped dest addr
	movl	a6@(8),a1	| sys src addr
	addl	d1,a6@(8)	| bump for next
	movl	a6@(16),d0	| # bytes
	cmpl	d1,d0
	ble	.L77		| br if moving .le. 1 page
	movl	d1,d0		| > 1 pg. only move 1 now
.L77:
	subl	d0,a6@(16)	| adj byte count
	subql	#1,d0		| for dbcc loop
	movl	#_coperr,_berrflg | in case of trap
	clrb	a0@		| test the range of the move
	tstl	_berrflg
	beq	_coperr
	tstb	a1@		| possible 68010 bug ??
	tstl	_berrflg
	beq	_coperr
	clrb	a0@(0,d0:w)
	tstl	_berrflg
	beq	_coperr
	tstb	a1@(0,d0:w)
	tstl	_berrflg
	beq	_coperr
.L88:
	movb	a1@+,a0@+	| move a byte
	dbf	d0,.L88		| loop till done
	clrl	_berrflg
	tstl	a6@(16)		| any more bytes to move?
	bgt	.L66		| br if yes

	unlk	a6
	clrl	d0		| good return
	rts

	.globl	_flip
_flip:
	movl	sp@(4),a0	| addr
	movl	sp@(8),d0	| count in bytes
	movl	#_fliperr,_berrflg | in case of trap
	tstb	a0@
	tstl	_berrflg
	beq	_fliperr
	tstb	a0@(0,d0:l)
	tstl	_berrflg
	beq	_fliperr
	asrl	#2,d0		| convert to long
	subql	#1,d0		| adjust for dbcc
.L123:
	notl	a0@+
	dbf	d0,.L123
	clrl	_berrflg
	moveq	#0,d0
	rts
_fliperr:
	moveq	#-1,d0
	rts

.globl	_clearmap
_clearmap:
	link	a6,#0
	movl	a6@(8),a0
	movl	#(PG_PFNUM+PG_NORD+PG_NOWR+PG_NOEX),d0
	movl	#((NBPC+NBPC)/4)-1,d1

.L99:	movl	d0,a0@+
	dbf	d1,.L99
	unlk	a6
	rts



