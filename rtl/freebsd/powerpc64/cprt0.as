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
        .globl  _start
        .type   _start,@function
_start:
        # Establish TOC (ELFv2): r12 holds entry address on entry
        addis   2,12,.TOC.-_start@ha
        addi    2,2,.TOC.-_start@l
        .localentry _start, .-_start

        # Standard PPC64 prologue (small frame; we don’t need much)
        stdu    1,-128(1)              # create frame, save back chain
        std     31,120(1)              # callee-saved as scratch
        mr      31,1

        # Save initial SP as __stkptr (optional, mirroring original file)
        addis   3,2,__stkptr@toc@ha
        addi    3,3,__stkptr@toc@l
        std     1,0(3)

        # Load argc (64-bit word at [r1])
        ld      9,0(1)                 # r9 = argc

        # argv = r1 + 8
        addi    10,1,8                 # r10 = &argv[0]

        # envp = r1 + 16 + 8*argc
        sldi    11,9,3                 # r11 = argc * 8
        addi    12,1,16
        add     8,12,11                # r8 = envp

        # Store into operatingsystem_parameters.{envp,argc,argv}
        addis   3,2,operatingsystem_parameters@toc@ha
        addi    3,3,operatingsystem_parameters@toc@l
        # envp at +0
        std     8,0(3)
        # argc (store 32-bit into 8-byte slot, like original x86_64 code did)
        stw     9,8(3)
        # argv at +16
        std     10,16(3)

        # environ = envp
        addis   4,2,environ@toc@ha
        addi    4,4,environ@toc@l
        std     8,0(4)

        # Derive __progname from argv[0] if (argc > 0 && argv[0] != NULL)
        cmpdi   9,0
        ble     1f                      # if argc <= 0, skip
        ld      5,0(10)                 # r5 = argv[0]
        cmpdi   5,0
        beq     1f

        # __progname = argv[0]
        addis   6,2,__progname@toc@ha
        addi    6,6,__progname@toc@l
        std     5,0(6)

        # Scan for last '/' to set __progname past it
        mr      7,5                     # r7 = scan pointer
0:      lbz     12,0(7)                 # load byte
        cmpdi   12,0
        beq     1f                      # end of string
        cmpdi   12,47                   # '/'
        bne     2f
        addi    13,7,1                  # one past '/'
        std     13,0(6)                 # __progname = r7+1
2:      addi    7,7,1
        b       0b
1:
        # if (_DYNAMIC) atexit(/*no loader cleanup available here*/)
        # We keep the check (harmless) and simply proceed to TLS/init/atexit.
        addis   3,2,_DYNAMIC@toc@ha
        addi    3,3,_DYNAMIC@toc@l
        ld      3,0(3)                  # r3 = &_DYNAMIC or 0
        cmpdi   3,0
        beq     3f

        # Dynamically linked: no loader-provided cleanup in this ABI path.
        # Fall through to registering _fini and doing _init like the static path.

3:
        # Register _fini with atexit
        addis   3,2,_fini@toc@ha
        addi    3,3,_fini@toc@l         # r3 = &_fini
        ld      3,0(3)
        bl      atexit
        nop

        # Call _init
        bl      _init
        nop

        # Call main(argc, argv, envp)
        mr      3,9                     # r3 = argc
        mr      4,10                    # r4 = argv
        mr      5,8                     # r5 = envp
        bl      main
        nop

        # exit(main_retval)
        mr      3,3
        bl      exit
        nop

        # Should not return; just in case, trap.
        tw      31,0,0

        # Epilogue (not reached)
        ld      31,120(1)
        addi    1,1,128
        blr

        .size   _start,.-_start

        # Optional identity string (mirroring original style)
        .section .comment
        .ascii  "FreePascal PPC64 ELFv2 crt1 (binutils)\0"
