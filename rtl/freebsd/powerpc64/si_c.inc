{*
 * Startup code for programs linked with GNU libc, PowerPC64
 * version.
 *
 * Adapted from the glibc-sources (2.16) in the file
 *
 *     sysdeps/powerpc/powerpc64/elf/start.S
 *
 * Original header follows.
 *}

{* Startup code for programs linked with GNU libc.  PowerPC64 version.
   Copyright (C) 1998,1999,2000,2001,2002,2003,2009
   Free Software Foundation, Inc.
   This file is part of the GNU C Library.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   In addition to the permissions in the GNU Lesser General Public
   License, the Free Software Foundation gives you unlimited
   permission to link the compiled version of this file with other
   programs, and to distribute those programs without any restriction
   coming from the use of this file. (The GNU Lesser General Public
   License restrictions do apply in other respects; for example, they
   cover modification of the file, and distribution when not linked
   into another program.)

   Note that people who make modified versions of this file are not
   obligated to grant this special exception for their modified
   versions; it is their choice whether to do so. The GNU Lesser
   General Public License gives permission to release a modified
   version without this exception; this exception also makes it
   possible to release a modified version which carries forward this
   exception.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.
   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library; if not, see
   <http://www.gnu.org/licenses/>.  *}

{$goto on}

{$ifndef _CALL_ELF or (_CALL_ELF = 1)}
{*
 * "ptrgl" glue code for calls via pointer. This function
 * sequence loads the data from the function descriptor
 * referenced by R11 into the CTR register (function address),
 * R2 (GOT/TOC pointer), and R11 (the outer frame pointer).
 *
 * On entry, R11 must be set to point to the function descriptor.
 *
 * See also the 64-bit PowerPC ABI specification for more
 * information, chapter 3.5.11 (in v1.7).
 *}
procedure ptrgl;  cdecl; public; assembler; nostackframe;
  asm
    ld	  r0, 0(r11)
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

procedure __libc_csu_init; cdecl; external;
procedure __libc_csu_fini; cdecl; external;

procedure __libc_start_main(r3,r4,r5,r6,r7,r8,r9: pointer); cdecl; external;

var
  __fpc_ret: pointer;

procedure save_argc_argv_envp_stkptr_fpcret(argc: longint; argv, envp: ppchar; stkptr: pointer);
  begin
    operatingsystem_parameter_argc:=argc;
    operatingsystem_parameter_argv:=argv;
    operatingsystem_parameter_envp:=envp;
    initialstkptr:=stkptr;
    __fpc_ret:=stkptr;
  end;


procedure _haltproc(exitcode: longint); cdecl; forward;

var
  TOCSTART: pointer; external name '.TOC.';

label
  __data_start,
  data_start;

{*
 * This is our FreePascal main procedure which is called by
 * libc after initializing.
 *}
procedure main_stub(argc: longint; argv, envp: ppchar); cdecl; assembler; nostackframe;
  asm
{$if defined(_CALL_ELF) and (_CALL_ELF = 2)}
.L1:
    addis   r2,r12,(TOCSTART-.L1)@ha
    addi    r2,r2,(TOCSTART-.L1)@l
    .localentry main_stub, . - main_stub
{$endif}
    mflr    r0
    std     r0,16(r1)
    stdu    r1,-128(r1)

    mr      r6, r1
    bl      save_argc_argv_envp_stkptr_fpcret

    bl  PASCALMAIN
    nop

    b   _haltproc
    nop
.section ".data"
.globl  __data_start
__data_start:
data_start:
.text
  end;

const
  start_addresses: record
    sda_base: pointer;
    main: pointer;
    libc_csu_init: pointer;
    libc_csu_fini: pointer;
  end
  = (sda_base: nil; {* was _SDA_BASE_  but not in 64-bit ABI }
     main: @main_stub;
     libc_csu_init: @__libc_csu_init;
     libc_csu_fini: @__libc_csu_fini
    );


procedure call_libc_start_main(r3,r4,r5,r6,r7,r8,r9: pointer); cdecl;
  begin
    __libc_start_main(r3,r4,r5,r6,r7,@start_addresses,r9);
    asm
      { not reached }
      { trap }
      .long 0xffe00008
    end;
  end;

{*
 * the real entry point for the program
 *}
procedure _start; cdecl; public; assembler; nostackframe;
  asm
{$if defined(_CALL_ELF) and (_CALL_ELF = 2)}
.L1:
    addis   r2,r12,(TOCSTART-.L1)@ha
    addi    r2,r2,(TOCSTART-.L1)@l
    .localentry _start, . - _start
{$endif}
    mr  r9,r1                   { save the stack pointer }

    { Set up an initial stack frame, and clear the LR.  }
    rldicr  r1,r1,0,59
    li      r0,0
    stdu    r1,-128(r1)
    mtlr    r0
    std     r0,0(r1)

    bl call_libc_start_main
    nop
  end;


procedure _haltproc(exitcode: longint); cdecl; public;
  var
    localret: pointer;
  begin
    localret:=__fpc_ret;
    { return via initial stack }
    asm
      lwa  r3, exitcode
      ld   r1, localret
      addi r1, r1, 128
      ld   r0, 16(r1)
      mtlr r0
      blr
    end;
  end;

