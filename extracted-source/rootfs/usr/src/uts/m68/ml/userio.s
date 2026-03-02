/* SID @(#)userio.s	5.4 */
#ifdef robin
#include "ruserio.s"
#else

#include "sys/param.h"
#include "sys/psl.h"
#include "sys/page.h"
#include "sys/mtpr.h"

	.data
.globl _berrflg
	.text

.globl _fuibyte
.globl _fubyte
.globl	_fubpte
.globl	_fubvad
_fuibyte:
_fubyte:
	link	a6,#0

#if defined(SCHROEDER) || defined(KICKER)
/* we rather assume that SFC and DFC have been set up for moves */
	movl	a6@(8),a0	| addr
	clrl	d0		| prepare for byte
	movl	#uerr,_berrflg	| handle bus err
	movesb	a0@,d0		| get the byte
	jra	uexit		| common exit
#endif
	movl	a6@(8),d0	| addr
	movl	#BPCSHIFT,d1
	lsrl	d1,d0		| page offset
	cmpl	#MAXMEM-1,d0| page out of range?
	jgt	uerr		| branch if yes
	lsll	#2,d0		| map offset
	addl	#UMLO,d0	| map slot addr
	movl	d0,a0
	movl	a0@,d0		| user map word
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
	bne	uerr
	movl	a0@,d0
	andl	#~PG_NORD,d0	| ensure readable
	orl	#PG_NOEX+PG_NOWR,d0
	movl	_fubpte,a0
	movl	d0,a0@		| map in user page
	movl	a6@(8),d0	| addr again
	andl	#NBPC-1,d0	| byte within pg
	addl	_fubvad,d0	| new log addr
	movl	d0,a0
	clrl	d0		| prepare for byte
	movl	#uerr,_berrflg	| handle bus err
	movb	a0@,d0		| get the byte
	jra	uexit		| common exit

.globl _fuiword
.globl _fuword
.globl	_fuwpte
.globl	_fuwvad
_fuiword:
_fuword:
	link	a6,#0
#if defined(SCHROEDER) || defined(KICKER)
/* we rather assume that SFC and DFC have been set up for moves */
	movl	a6@(8),a0	| addr
	movl	#uerr,_berrflg	| handle bus err
	movesl	a0@,d0		| get the byte
	jra	uexit		| common exit
#endif
	movl	_fuwpte,a0
	addl	#4,a0
	movl	#PG_NORD+PG_NOWR+PG_NOEX,a0@
	movl	a6@(8),d0	| addr
	movl	#BPCSHIFT,d1
	lsrl	d1,d0		| page offset
	cmpl	#MAXMEM-1,d0| page out of range?
	jgt	uerr		| branch if yes
	lsll	#2,d0		| map offset
	addl	#UMLO,d0	| map slot addr
	movl	d0,a0
	movl	a0@,d0		| user map word
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
	bne	uerr
	movl	a0@,d0
	andl	#~PG_NORD,d0	| ensure readable
	orl	#PG_NOEX+PG_NOWR,d0
	movl	_fuwpte,a0
	movl	d0,a0@		| map in user page

	movl	a6@(8),d0	| addr
	andl	#NBPC-1,d0	| byte offset
	cmpl	#NBPC-1-4,d0	| test for pg overflow
	ble	fuw1		| branch if no overflow

	movl	a6@(8),d0	| addr
	movl	#BPCSHIFT,d1
	lsrl	d1,d0		| page offset
	addql	#1,d0
	cmpl	#MAXMEM-1,d0| page out of range?
	jgt	fuw1		| branch if yes
	lsll	#2,d0		| map offset
	addl	#UMLO,d0	| map slot addr
	movl	d0,a0
	movl	a0@,d0		| user map word
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
	bne	uerr
	movl	a0@,d0
	andl	#~PG_NORD,d0	| ensure readable
	orl	#PG_NOEX+PG_NOWR,d0
	movl	_fuwpte,a0
	addl	#4,a0
	movl	d0,a0@		/* map in user page */
fuw1:
	movl	a6@(8),d0	| addr again
	andl	#NBPC-1,d0	| byte within pg
	addl	_fuwvad,d0	| new log addr
	movl	d0,a0
	clrl	d0		| prepare for err
	movl	#uerr,_berrflg	| handle bus err
	movl	a0@,d0		| get the word
	jra	uexit


.globl _suiword
.globl _suword
.globl	_suwpte
.globl	_suwvad
_suiword:
_suword:
	link	a6,#0
#if defined(SCHROEDER) || defined(KICKER)
/* we rather assume that SFC and DFC have been set up for moves */
	movl	a6@(8),a0	| addr
	movl	a6@(12),d0	| word to store
	movl	#uerr,_berrflg	| handle bus err
	movesl	d0,a0@		| store the byte
	clrl	d0
	jra	uexit		| common exit
#endif
	movl	_suwpte,a0
	addl	#4,a0
	movl	#PG_NORD+PG_NOWR+PG_NOEX,a0@
	movl	a6@(8),d0	| addr
	movl	#BPCSHIFT,d1
	lsrl	d1,d0		| page offset
	cmpl	#MAXMEM-1,d0| page out of range?
	jgt	uerr		| branch if yes
	lsll	#2,d0		| map offset
	addl	#UMLO,d0	| map slot addr
	movl	d0,a0
	movl	a0@,d0		| user map word
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
	bne	uerr
	movl	a0@,d0
	andl	#~PG_NORD+PG_NOWR,d0 | must be read/writable
	orl	#PG_NOEX,d0
	movl	_suwpte,a0
	movl	d0,a0@		/* map in user pg */

	movl	a6@(8),d0	| addr
	andl	#NBPC-1,d0	| offset
	cmpl	#NBPC-1-4,d0	| test for pg overflow
	ble	suw1		| branch if no overflow

	movl	a6@(8),d0	| addr
	movl	#BPCSHIFT,d1
	lsrl	d1,d0		| page offset
	addql	#1,d0
	cmpl	#MAXMEM-1,d0| page out of range?
	jgt	suw1		| branch if yes
	lsll	#2,d0		| map offset
	addl	#UMLO,d0	| map slot addr
	movl	d0,a0
	movl	a0@,d0		| user map word
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
	bne	uerr
	movl	a0@,d0
	andl	#~PG_NORD+PG_NOWR,d0 | must be read/writable
	orl	#PG_NOEX,d0
	movl	_suwpte,a0
	addl	#4,a0
	movl	d0,a0@
suw1:
	movl	a6@(8),d0	| addr again
	andl	#NBPC-1,d0	| byte within pg
	addl	_suwvad,d0	| new log addr
	movl	d0,a0
	movl	a6@(12),d1	| word to store
	movl	#uerr,_berrflg	| handle bus err
	movl	d1,a0@		| store the word
	clrl	d0
	jra	uexit

.globl _suibyte
.globl _subyte
.globl	_subpte
.globl	_subvad
_suibyte:
_subyte:
	link	a6,#0
#if defined(SCHROEDER) || defined(KICKER)
/* we rather assume that SFC and DFC have been set up for moves */
	movl	a6@(8),a0	| addr
	movl	a6@(12),d0	| word to store
	movl	#uerr,_berrflg	| handle bus err
	movesb	d0,a0@		| store the byte
	clrl	d0
	jra	uexit		| common exit
#endif
	movl	a6@(8),d0	| addr
	movl	#BPCSHIFT,d1
	lsrl	d1,d0		| page offset
	cmpl	#MAXMEM-1,d0| page out of range?
	jgt	uerr		| branch if yes
	lsll	#2,d0		| map offset
	addl	#UMLO,d0	| map slot addr
	movl	d0,a0
	movl	a0@,d0		| user map word
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
	bne	uerr
	movl	a0@,d0
	andl	#~PG_NORD+PG_NOWR,d0 | must be read/writable
	orl	#PG_NOEX,d0
	movl	_subpte,a0
	movl	d0,a0@		/* map in user page */
	movl	a6@(8),d0	| addr again
	andl	#NBPC-1,d0	| byte within pg
	addl	_subvad,d0	| new log addr
	movl	d0,a0
	movl	a6@(12),d1	| word to store
	movl	#uerr,_berrflg	| handle bus err
	movb	d1,a0@		| store the byte
	clrl	d0		| no error
uexit:
	clrl	_berrflg
	unlk	a6
	rts
/*
 * control comes here when we get an access error during
 *  one of the user fu/su operations. we simply abort the
 *  move operation and return a -1 error indication to the
 *  caller
 */
uerr:
	movl	#-1,d0
	unlk	a6
	rts

.globl _fushort
.globl fushort
.globl	_fuspte
.globl	_fusvad
fushort:
_fushort:
	link	a6,#0
#if defined(SCHROEDER) || defined(KICKER)
/* we rather assume that SFC and DFC have been set up for moves */
	movl	a6@(8),a0	| addr
	clrl	d0		| prepare for byte
	movl	#uerr,_berrflg	| handle bus err
	movesw	a0@,d0		| get the short
	jra	uexit		| common exit
#endif

	movl	a6@(8),d0	| addr
	movl	#BPCSHIFT,d1
	lsrl	d1,d0		| page offset
	cmpl	#MAXMEM-1,d0| page out of range?
	jgt	uerr		| branch if yes
	lsll	#2,d0		| map offset
	addl	#UMLO,d0	| map slot addr
	movl	d0,a0
	movl	a0@,d0		| user map word
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
	bne	uerr
	movl	a0@,d0
	andl	#~PG_NORD,d0	| ensure readable
	orl	#PG_NOEX+PG_NOWR,d0
	movl	_fuspte,a0
	movl	d0,a0@		/* map in user page */
	movl	a6@(8),d0	| addr again
	andl	#NBPC-1,d0	| byte within pg
	addl	_fusvad,d0	| new log addr
	movl	d0,a0
	clrl	d0		| prepare for err
	movl	#uerr,_berrflg	| handle bus err
	movw	a0@,d0		| get the word
	jra	uexit

.globl sushort
.globl _sushort
.globl	_suspte
.globl	_susvad
sushort:
_sushort:
	link	a6,#0
#if defined(SCHROEDER) || defined(KICKER)
/* we rather assume that SFC and DFC have been set up for moves */
	movl	a6@(8),a0	| addr
	movl	a6@(12),d0	| word to store
	movl	#uerr,_berrflg	| handle bus err
	movesw	d0,a0@		| store the word
	clrl	d0
	jra	uexit		| common exit
#endif

	movl	a6@(8),d0	| addr
	movl	#BPCSHIFT,d1
	lsrl	d1,d0		| page offset
	cmpl	#MAXMEM-1,d0| page out of range?
	jgt	uerr		| branch if yes
	lsll	#2,d0		| map offset
	addl	#UMLO,d0	| map slot addr
	movl	d0,a0
	movl	a0@,d0		| user map word
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
	bne	uerr
	movl	a0@,d0
	andl	#~PG_NORD+PG_NOWR,d0 | must be read/writable
	orl	#PG_NOEX,d0
	movl	_suspte,a0
	movl	d0,a0@		/* map in user page */
	movl	a6@(8),d0	| addr again
	andl	#NBPC-1,d0	| byte within pg
	addl	_susvad,d0	| new log addr
	movl	d0,a0
	movl	a6@(12),d1	| word to store
	movl	#uerr,_berrflg	| handle bus err
	movw	d1,a0@		| store the word
	clrl	d0		| indicate no error
	jra	uexit

#endif
