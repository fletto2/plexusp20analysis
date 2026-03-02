/* SID @(#)end.s	5.1 */

#include "sys/mtpr.h"

#ifndef SYS3
	_u = LA_UBLK
	.globl _u
#endif

	.text

.globl _icode
_icode:
	tstl	sp@(-4)		/* probe for stack growth */
	movl	#_initp-_icode,d0 | arg list ptr
	movl	d0,sp@-
	movl	#_init-_icode,d0	| path ptr
	movl	d0,sp@-
	clrl	sp@-		| dummy sys call rtn addr
	movw	#11,d0		| exec call
	trap	#0		| system call
.L1:
	jra	.L1		| fatal err

_init:
#ifdef SYS3
	.asciz	'/etc/init'
#else
	.byte	'/,'e,'t,'c,'/,'i,'n,'i,'t,0
#endif

	.even
_initp:
	.long	_init - _icode	| arg0 is "/etc/init"
	.long	0		| term arg list

_endicode:
.globl _szicode
_szicode: .long _endicode - _icode
