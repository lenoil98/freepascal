Free Pascal Compiler - an open source Object Pascal compiler. This is an unofficial repository for porting FPC to FreeBSD PowerPC and is for convenience use only.
This is a work-in-progress (WIP).  The code currently supports creation of cross compilers for FreeBSD/PowerPC, 32-bit and 64-bit on a host but can not create a working freepascal compiler. 

TODO:

  - Startup code must be adapted. 
    - linking without libc (rtl/freebsd/powerpc64/prt0.as)
    - linking with libc (rtl/freebsd/powerpc64/cprt0.as)
  - Validate signals (rtl/freebsd/signals.inc)
  
Instructions for building cross-compiler and compiler:

On the host machine

1. Check out FPC from Github:

   $ git clone https://github.com/lenoil98/freepascal.git

2. Install the gcc cross toolchain for the powerpc architecture:

3. Enter FPC source directory and build the cross-compiler:

   $ gmake crossall crossinstall CPU_TARGET=powerpc64 CROSSOPT="-CaSYSV" OS_TARGET=freebsd FPC=/usr/local/lib/fpc/3.0.4/ppcx64 BINUTILSPREFIX=powerpc64-unknown-freebsd12.1- INSTALL_PREFIX=/root/fpc-powerpc64

4. Build the native compiler:

   $ gmake compiler CPU_TARGET=powerpc64 CROSSOPT="-CaSYSV -Cp970 -gw3" OS_TARGET=freebsd FPC=/root/fpc-powerpc64/lib/fpc/3.2.0/ppcrossppc64 BINUTILSPREFIX=powerpc64-unknown-freebsd11.2- INSTALL_PREFIX=/root/fpc-powerpc64

Note: The options for CROSSOPT can be obtained by running "ppcrossppc64" after the initial build without parameters:

   ~/freepascal# ./compiler/ppcrossppc64 -ic # (Returns list of supported CPU instruction sets)
	970
   ~/freepascal# ./compiler/ppcrossppc64 -if # (Returns list of supported FPU instruction sets)
	NONE
	SOFT
	STANDARD
   ~/freepascal# ./compiler/ppcrossppc64 -ia # (Returns list of supported ABI targets)
	DEFAULT
	SYSV
	AIX
	DARWIN
   ~/freepascal#

5. Copy target compiler into directory of cross-compiler:

   $ cp -av compiler/ppcppc64 /root/fpc-powerpc64/lib/fpc/3.2.0/

7. Tar the target compiler up to transport it to the target machine:

   $ tar czf fpc-powerpc64.tgz /root/fpc-powerpc64

On the target machine

1. Check out FPC from Github:

   $ git clone https://github.com/lenoil98/freepascal.git

2. Untar cross-compiled target compiler:

   $ tar xf fpc-powerpc64.tgz

3. Build FPC with the bootstrapped FPC:

   $ make FPC=/path/to/ppcbinary FPCDIR=/path/to/fpc/root OVERRIDEVERSIONCHECK=1 all

FPC usually being /usr/local/lib/fpc/x.y.z/ppc$CPU and FPCDIR /usr/local/lib/fpc/x.y.z/ when the tarball generated on the bootstrapping host was extracted into /usr/local.


