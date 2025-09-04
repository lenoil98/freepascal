        .section .note.tag,"a",@note
        .align  2
        .type    abitag,@object
        .size    abitag,48
abitag:
        .long   8
        .long   4
        .long   1
        .string "FreeBSD"
        .long   1400097
        .long   8
        .long   4
        .long   1
        .string "FreeBSD"
        .long   0

        .section .rodata
.LC0:
        .string ""

        .data
        .p2align 3
        .globl  __progname
        .type   __progname,@object
        .size   __progname,8
__progname:
        .quad   .LC0

        .bss
        .globl  __stkptr
        .type   __stkptr,@object
        .size   __stkptr,8
__stkptr:
        .skip   8

        .type   operatingsystem_parameters,@object
        .size   operatingsystem_parameters,24
        .globl  operatingsystem_parameters
operatingsystem_parameters:
        .skip   24
        .globl  operatingsystem_parameter_envp
        .globl  operatingsystem_parameter_argc
        .globl  operatingsystem_parameter_argv
        .set    operatingsystem_parameter_envp,operatingsystem_parameters+0
        .set    operatingsystem_parameter_argc,operatingsystem_parameters+8
        .set    operatingsystem_parameter_argv,operatingsystem_parameters+16

        .comm   environ,8,8
        .weak   _DYNAMIC

        .text
        .p2align 2
        .globl  _start
        .type   _start,@function
_start:
        # --- ELFv2 prologue: create small frame & establish TOC in r2 ---
        mflr    r0
        std     r0,16(r1)
        stdu    r1,-32(r1)

        bl      1f                  # get PC into LR
1:      mflr    r12                 # r12 = this function's address
        addis   r2,r12,.TOC.-1b@ha  # r2 = TOC base (high)
        addi    r2,r2,.TOC.-1b@l    # r2 = TOC base (low)
        .localentry _start, .-_start

        # Optionally record initial SP (to mirror your x86 global)
        addis   r11,r2,__stkptr@toc@ha
        addi    r11,r11,__stkptr@toc@l
        std     r1,0(r11)

        # --- Pull argc/argv/envp from initial stack layout ---
        ld      r3,0(r1)            # r3 = argc
        addi    r4,r1,8             # r4 = argv
        sldi    r0,r3,3             # r0 = argc * 8
        add     r5,r4,r0            # r5 = &argv[argc]
        addi    r5,r5,8             # r5 = envp

        # Store into your globals (TOC-relative)
        addis   r11,r2,operatingsystem_parameter_argc@toc@ha
        addi    r11,r11,operatingsystem_parameter_argc@toc@l
        std     r3,0(r11)

        addis   r11,r2,operatingsystem_parameter_argv@toc@ha
        addi    r11,r11,operatingsystem_parameter_argv@toc@l
        std     r4,0(r11)

        addis   r11,r2,operatingsystem_parameter_envp@toc@ha
        addi    r11,r11,operatingsystem_parameter_envp@toc@l
        std     r5,0(r11)

        # environ = envp
        addis   r11,r2,environ@toc@ha
        addi    r11,r11,environ@toc@l
        std     r5,0(r11)

        # __progname = argv[0] if argc>0 && argv[0]!=NULL
        cmpdi   r3,0
        ble     1f
        ld      r9,0(r4)            # r9 = argv[0]
        cmpdi   r9,0
        beq     1f
        addis   r11,r2,__progname@toc@ha
        addi    r11,r11,__progname@toc@l
        std     r9,0(r11)

        # Walk argv[0] to find last '/' and set __progname to basename
        mr      r10,r9
0:
        lbz     r6,0(r10)
        cmpdi   r6,0
        beq     1f
        cmpdi   r6,47               # '/'
        bne     2f
        addi    r7,r10,1
        addis   r11,r2,__progname@toc@ha
        addi    r11,r11,__progname@toc@l
        std     r7,0(r11)
2:
        addi    r10,r10,1
        b       0b

1:
        # Call main(argc, argv, envp)   (r3,r4,r5 already set)
        bl      main
        # exit(main_ret)
        mr      r3,r3
        bl      exit
        # no return

        .size   _start,.-_start
