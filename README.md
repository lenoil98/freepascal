Free Pascal Compiler - an open source Object Pascal compiler. This is an unofficial repository for porting FPC to FreeBSD PowerPC and is for convenience use only.
This is a work-in-progress (WIP).  The code currently supports creation of cross compilers for FreeBSD/PowerPC, 32-bit and 64-bit on a host but can not create a working freepascal compiler. 

TODO:

  - Startup code must be adapted. Twice. 
    - linking without libc (prt0)
    - linking with libc (cprt0)
  - Validate signals
