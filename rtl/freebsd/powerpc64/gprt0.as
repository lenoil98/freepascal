        .file   "crt1_ppc64_elfv2.S"

        # ELFv2: no function descriptors, direct entry; r3=argc, r4=argv, r5=envp
        .abiversion 2

        # Optional ABI note (adjust or drop as needed)
        .section .note.ABI-tag,"a",@progbits
        .p2align 2
        .type   abitag, @object
        .size   abitag, 24
abitag:
        .long   8
        .long   4
        .long   1
        .string "FreeBSD"
        .long   900044

        .section .rodata
.LC0:
        .asciz  ""

        .globl  __progname
        .section .data
        .p2align 3
        .type   __progname, @object
        .size   __progname, 8
__progname:
        .quad   .LC0

        .comm   environ,8,8           # like on x86_64
        .weak   _DYNAMIC              # kept for parity with original

        # Optionally expose these like the original snippet did.
        .globl  operatingsystem_parameter_argc
        .globl  operatingsystem_parameter_argv
        .globl  operatingsystem_parameter_envp
        .p2align 3
operatingsystem_parameter_argc:
        .quad   0
operatingsystem_parameter_argv:
        .quad   0
operatingsystem_parameter_envp:
        .quad   0

        .text
        .p2align 2
        .globl  _start
        .type   _start, @function
_start:
        .cfi_startproc
        # Prologue (simple, we’re going to exit() so restoration is purely formal)
        mflr    0
        stdu    1, -32(1)             # create small frame
        std     0, 16(1)
        .cfi_def_cfa_offset 32
        .cfi_offset 65, 16

        # r3=argc, r4=argv, r5=envp (ELFv2 process entry convention)

        # Store argc
        lis     9, operatingsystem_parameter_argc@ha
        addi    9, 9, operatingsystem_parameter_argc@l
        std     3, 0(9)

        # Store argv
        lis     10, operatingsystem_parameter_argv@ha
        addi    10, 10, operatingsystem_parameter_argv@l
        std     4, 0(10)

        # Store envp
        lis     11, operatingsystem_parameter_envp@ha
        addi    11, 11, operatingsystem_parameter_envp@l
        std     5, 0(11)

        # environ = envp
        lis     12, environ@ha
        addi    12, 12, environ@l
        std     5, 0(12)

        # if (argc > 0 && argv[0] != NULL) { __progname = argv[0]; ... }
        cmpdi   3, 0
        ble     1f                      # if argc <= 0, skip

        ld      6, 0(4)                 # r6 = argv[0]
        cmpdi   6, 0
        beq     1f

        # __progname = argv[0]
        lis     7, __progname@ha
        addi    7, 7, __progname@l
        std     6, 0(7)

        # Scan to last '/' and keep pointer to char after it.
        # r8 = current pointer
        mr      8, 6

0:      lbz     9, 0(8)                 # load byte
        cmpdi   9, 0
        beq     1f                      # reached end -> done

        cmpdi   9, 47                   # '/'
        bne     2f
        # if '/', __progname = (r8 + 1)
        addi    10, 8, 1
        std     10, 0(7)

2:      addi    8, 8, 1                 # ++ptr
        b       0b

1:
        # Call main(argc, argv, envp)
        # r3,r4,r5 already set by entry, keep them.
        bl      main
        # return value in r3

        # exit(main_ret)
        mr      3, 3
        bl      exit

        # (no return)
        .cfi_endproc
        .size   _start, .-_start

        .ident  "GAS: ppc64 (ELFv2) crt1"
