{*
 * Free Pascal RTL startup for FreeBSD, PowerPC64 ELFv2
 *
 * Ported from the GNU libc variant used on Linux.
 * Differences:
 *  - No glibc __libc_start_main or csu hooks on FreeBSD.
 *  - ELFv2: no function descriptors; establish TOC from r12 at entry.
 *  - We call PASCALMAIN directly and then tail into _haltproc.
 *}

{$goto on}

{$ifndef _CALL_ELF or (_CALL_ELF = 1)}
{*
 * ELFv1 glue (kept for completeness, but FreeBSD/ppc64 defaults to ELFv2).
 * If you ever target ELFv1, you can enable this; otherwise it’s unused here.
 *}
procedure ptrgl; cdecl; public; assembler; nostackframe;
  asm
    ld      r0, 0(r11)
    std     r2, 40(r1)
    mtctr   r0
    ld      r2, 8(r11)
    ld      r11, 16(r11)
    bctr
  end;
{$endif _CALL_ELF}

{******************************************************************************
                          Process start/halt
 ******************************************************************************}

var
  __fpc_ret: pointer;

procedure save_argc_argv_envp_stkptr_fpcret(argc: longint; argv, envp: ppchar; stkptr: pointer);
begin
  operatingsystem_parameter_argc := argc;
  operatingsystem_parameter_argv := argv;
  operatingsystem_parameter_envp := envp;
  initialstkptr := stkptr;
  __fpc_ret := stkptr;
end;

procedure _haltproc(exitcode: longint); cdecl; forward;

{ The TOC anchor; provided by the linker/assembler. }
var
  TOCSTART: pointer; external name '.TOC.';

label
  __data_start,
  data_start;

{*
 * Free Pascal entry called from our _start (not from glibc).
 * ELFv2: r12 contains entry address on entry; use it to set r2 (TOC).
 *}
procedure main_stub(argc: longint; argv, envp: ppchar); cdecl; assembler; nostackframe;
  asm
{$if defined(_CALL_ELF) and (_CALL_ELF = 2)}
.L1:
    addis   r2, r12, (TOCSTART-.L1)@ha
    addi    r2, r2,  (TOCSTART-.L1)@l
    .localentry main_stub, . - main_stub
{$endif}
    mflr    r0
    std     r0, 16(r1)
    stdu    r1, -128(r1)

    mr      r6, r1
    bl      save_argc_argv_envp_stkptr_fpcret

    bl      PASCALMAIN
    nop

    b       _haltproc
    nop

.section ".data"
  .globl  __data_start
__data_start:
data_start:
.text
  end;

{*
 * Program entry point for FreeBSD/ppc64 (ELFv2).
 * No glibc __libc_start_main is used; we jump straight to main_stub.
 *}
procedure _start; cdecl; public; assembler; nostackframe;
  asm
{$if defined(_CALL_ELF) and (_CALL_ELF = 2)}
.Ls:
    addis   r2, r12, (TOCSTART-.Ls)@ha
    addi    r2, r2,  (TOCSTART-.Ls)@l
    .localentry _start, . - _start
{$endif}
    mr      r9, r1                 { save initial SP }

    { Set up an initial stack frame, and clear LR. }
    rldicr  r1, r1, 0, 59          { align r1 per ABI }
    li      r0, 0
    stdu    r1, -128(r1)
    mtlr    r0
    std     r0, 0(r1)

    { ELFv2 process entry already provides r3=argc, r4=argv, r5=envp. }
    bl      main_stub
    nop
  end;

{*
 * Called when the RTL performs halt(). Return via the initial stack,
 * passing exit code back to the kernel in r3 (as per ABI).
 *}
procedure _haltproc(exitcode: longint); cdecl; public;
var
  localret: pointer;
begin
  localret := __fpc_ret;
  { return via initial stack }
  asm
    lwa   r3, exitcode
    ld    r1, localret
    addi  r1, r1, 128
    ld    r0, 16(r1)
    mtlr  r0
    blr
  end;
end;

