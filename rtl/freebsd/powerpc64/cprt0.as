        .machine        power8
        .abiversion     2

        .section .rodata
.LC_progname_empty:
        .string ""

        .section .data
        .align  3
        .globl  __progname
        .type   __progname,@object
        .size   __progname,8
__progname:
        .quad   .LC_progname_empty

        .section .bss
        .align  3
        .type   __stkptr,@object
        .size   __stkptr,8
        .globl  __stkptr
__stkptr:
        .skip   8

        .align  3
        .type   operatingsystem_parameters,@object
        .size   operatingsystem_parameters,24
        .globl  operatingsystem_parameters
operatingsystem_parameters:
        .skip   24

        .globl  operatingsystem_parameter_envp
        .globl  operatingsystem_parameter_argc
        .globl  operatingsystem_parameter_argv
        .set    operatingsystem_parameter_envp, operatingsystem_parameters+0
        .set    operatingsystem_parameter_argc, operatingsystem_parameters+8
        .set    operatingsystem_parameter_argv, operatingsystem_parameters+16

        .comm   environ,8,8
        .weak   _DYNAMIC

        .section .text
        .align  4
        .globl  start
        .type   start,@function
start:
        # Setup TOC pointer using r2 (TOC in ELFv2). r12 is entry address on some toolchains,
        # but we use @toc relocations via addis/addi to set r2 as TOC pointer.
        addis   2,12,.TOC.-start@ha
        addi    2,2,.TOC.-start@l
        .localentry start, .-start

        # Create a small stack frame
        stdu    1,-128(1)
        std     31,120(1)
        mr      31,1

        # Save initial sp into __stkptr
        addis   3,2,__stkptr@toc@ha
        addi    3,3,__stkptr@toc@l
        std     1,0(3)

        # Load argc from stack (at r1)
        ld      9,0(1)                 # r9 = argc

        # argv = r1 + 8
        addi    10,1,8                 # r10 = &argv[0]

        # envp = r1 + 16 + 8*argc
        sldi    11,9,3                 # r11 = argc * 8
        addi    12,1,16
        add     8,12,11                # r8 = envp

        # Store envp/argc/argv into operatingsystem_parameters
        addis   3,2,operatingsystem_parameters@toc@ha
        addi    3,3,operatingsystem_parameters@toc@l
        std     8,0(3)                 # envp -> +0
        stw     9,8(3)                 # argc -> +8 (lower 32 bits; same as original)
        std     10,16(3)               # argv -> +16

        # environ = envp
        addis   4,2,environ@toc@ha
        addi    4,4,environ@toc@l
        std     8,0(4)

        # If argc > 0 and argv[0] != 0, set __progname to argv[0] and
        # then set __progname to the final component (after last '/')
        cmpdi   9,0
        ble     set_dynamic_check
        ld      5,0(10)                # r5 = argv[0]
        cmpdi   5,0
        beq     set_dynamic_check

        addis   6,2,__progname@toc@ha
        addi    6,6,__progname@toc@l
        std     5,0(6)                 # store pointer

        mr      7,5                     # r7 = pointer to scan
scan_loop:
        lbz     12,0(7)
        cmpdi   12,0
        beq     set_dynamic_check
        cmpdi   12,47                  # '/'
        bne     scan_next
        addi    13,7,1
        std     13,0(6)                # __progname = r7+1
scan_next:
        addi    7,7,1
        b       scan_loop

set_dynamic_check:
        # Check _DYNAMIC (weak); if set, we could register loader-cleanup; omitted for portability.
        addis   3,2,_DYNAMIC@toc@ha
        addi    3,3,_DYNAMIC@toc@l
        ld      3,0(3)
        cmpdi   3,0
        beq     register_fini

        # If desired, a loader cleanup hook would be invoked here (platform dependent)
register_fini:
        # Register _fini with atexit (if present) and call _init
        # Load address of _fini then call atexit
        addis   3,2,_fini@toc@ha
        addi    3,3,_fini@toc@l
        ld      3,0(3)
        bl      atexit
        nop

        bl      _init
        nop

        # Call main(argc, argv, envp)
        mr      3,9
        mr      4,10
        mr      5,8
        bl      main
        nop

        # exit(main_retval)
        mr      3,3
        bl      exit
        nop

        # In case exit returns, just trap
        tw      31,0,0

        # Epilogue (not expected to run)
        ld      31,120(1)
        addi    1,1,128
        blr

        .size   start,.-start

        .section .comment
        .ascii  "FreePascal PPC64 ELFv2 crt1 (binutils)\0"
