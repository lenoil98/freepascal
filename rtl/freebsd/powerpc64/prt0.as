/*
   Start-up code for Free Pascal Compiler, not in a shared library,
   not linking with C library.

   Written by Edmund Grimley Evans in 2015 and released into the public domain.
*/

.macro LOAD_64BIT_VAL ra, value
    lis       \ra,\value@highest
    ori       \ra,\ra,\value@higher
    sldi      \ra,\ra,32
    oris      \ra,\ra,\value@h
    ori       \ra,\ra,\value@l
.endm

	.text
	.align 2

	.globl _dynamic_start
	.type  _dynamic_start,@function
_dynamic_start:
	lis		11, __dl_fini
	std      7,0(11)
	bl		_start

	.globl	_start
	.type	_start,@function
_start:
    mr     26,1            /* save stack pointer */
    /* Set up an initial stack frame, and clear the LR */
    clrrdi  1,1,5          /* align r1 */
    li      0,0
    stdu    1,-128(1)
    mtlr    0
    std     0,0(1)        /* r1 = pointer to NULL value */

    /* store argument count (= 0(r1) )*/
    ld      3,0(26)
    LOAD_64BIT_VAL 10,operatingsystem_parameter_argc
    stw     3,0(10)
    /* calculate argument vector address and store (= 8(r1) + 8 ) */
    addi    4,26,8
    LOAD_64BIT_VAL 10,operatingsystem_parameter_argv
    std     4,0(10)
    /* store environment pointer (= argv + (argc+1)* 8 ) */
    addi    5,3,1
    sldi    5,5,3
    add     5,4,5
    LOAD_64BIT_VAL 10, operatingsystem_parameter_envp
    std     5,0(10)

    LOAD_64BIT_VAL 8,__stkptr
    std     1,0(8)

    bl      PASCALMAIN
    nop

	.globl	_haltproc
	.type	_haltproc,@function
_haltproc:
    mflr  0
    std   0,16(1)
    stdu  1,-144(1)

    LOAD_64BIT_VAL 11,__dl_fini
    ld    11,0(11)
    cmpdi 11,0
    blr
.Lexit:
    LOAD_64BIT_VAL 3, operatingsystem_result
    lwz     3,0(3)
    /* exit call */
    li      0,1
    sc
    /* we should not reach here. Crash horribly */
    trap

	/* Define a symbol for the first piece of initialized data. */
	.data
	.align 3
    .section ".data"
	.globl __data_start
__data_start:
data_start:

    .section ".bss"

    .type __stkptr, @object
    .size __stkptr, 8
    .global __stkptr
__stkptr:
    .skip 8

    .type __dl_fini, @object
    .size __dl_fini, 8
    .global __dl_fini
__dl_fini:
    .skip 8

    .type operatingsystem_parameters, @object
    .size operatingsystem_parameters, 24
operatingsystem_parameters:
    .skip 3 * 8
    .global operatingsystem_parameter_argc
    .global operatingsystem_parameter_argv
    .global operatingsystem_parameter_envp
    .set operatingsystem_parameter_argc, operatingsystem_parameters+0
    .set operatingsystem_parameter_argv, operatingsystem_parameters+8
    .set operatingsystem_parameter_envp, operatingsystem_parameters+16

	.section .note.GNU-stack,"",%progbits
