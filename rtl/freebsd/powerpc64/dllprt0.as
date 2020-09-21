/*
 * This file is part of the Free Pascal run time library.
 * Copyright (c) 2005 by Thomas Schatzl,
 * member of the Free Pascal development team.
 *
 * Startup code for shared libraries, PowerPC64 version.
 *
 * See the file COPYING.FPC, included in this distribution,
 * for details about the copyright.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 */

.macro LOAD_64BIT_VAL ra, value
    lis       \ra,\value@highest
    ori       \ra,\ra,\value@higher
    sldi      \ra,\ra,32
    oris      \ra,\ra,\value@h
    ori       \ra,\ra,\value@l
.endm

/* create function prolog for symbol "fn" */
.macro FUNCTION_PROLOG fn
    .section  ".text"
    .align    2
    .globl    \fn
    .section  ".opd", "aw"
    .align    3
\fn:
    .quad     .\fn, .TOC.@tocbase, 0
    .previous
    .size     \fn, 24
    .type     \fn, @function
    .globl    .\fn
.\fn:
.endm

/*
 * "ptrgl" glue code for calls via pointer. This function
 * sequence loads the data from the function descriptor
 * referenced by R11 into the CTR register (function address),
 * R2 (GOT/TOC pointer), and R11 (the outer frame pointer).
 *
 * On entry, R11 must be set to point to the function descriptor.
 *
 * See also the 64-bit PowerPC ABI specification for more
 * information, chapter 3.5.11 (in v1.7).
 */
.section ".text"
.align 3
.globl .ptrgl
.ptrgl:
    ld	    0, 0(11)
    std     2, 40(1)
    mtctr   0
    ld      2, 8(11)
    ld      11, 16(11)
    bctr
.long 0
.byte 0, 12, 128, 0, 0, 0, 0, 0
.type .ptrgl, @function
.size .ptrgl, . - .ptrgl

/*
 * Main program entry point label (function), called by the loader
 *
 * The document "64-bit PowerPC ELF Application Binary Interface Supplement 1.9"
 * pg. 24f specifies the register contents.
 */
FUNCTION_PROLOG FPC_SHARED_LIB_START
    mflr    0
    std     0, 16(1)        /* save LR */
    stdu    1, -144(1)      /* save back chain, make frame */

    /* store argument count (in r3)*/
    LOAD_64BIT_VAL 10, operatingsystem_parameter_argc
    stw     3, 0(10)
    /* store argument vector (in r4) */
    LOAD_64BIT_VAL 10, operatingsystem_parameter_argv
    std     4, 0(10)
    /* store environment pointer (in r5) */
    LOAD_64BIT_VAL 10, operatingsystem_parameter_envp
    std     5, 0(10)

    LOAD_64BIT_VAL 8, __stkptr
    std     1,0(8)

    /* call library initialization */
    bl      PASCALMAIN
    nop

    /* return to the caller */
    addi    1,1,144   /* restore stack */
    ld      0,16(1)   /* prepare for method return */
    mtlr    0
    blr
.long 0
.byte 0, 12, 64, 0, 0, 0, 0, 0

/* this routine is only called when the halt() routine of the RTL embedded in
   the shared library is called */
FUNCTION_PROLOG _haltproc
    /* exit_group call */
    LOAD_64BIT_VAL 3, operatingsystem_result
    lwz     3, 0(3)
    li      0, 234
    sc
    /* exit call */
    LOAD_64BIT_VAL 3, operatingsystem_result
    lwz     3, 0(3)
    li      0, 1
    sc
    /* we should not reach here. Crash horribly */
    trap
.long 0
.byte 0, 12, 64, 0, 0, 0, 0, 0

    /* Define a symbol for the first piece of initialized data.  */
    .section ".data"
    .globl  __data_start
__data_start:
data_start:

    .section ".bss"

    .type __stkptr, @object
    .size __stkptr, 8
    .global __stkptr
__stkptr:
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
