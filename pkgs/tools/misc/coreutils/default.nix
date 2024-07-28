{ lib
, stdenv
, fetchurl
, autoreconfHook
, buildPackages
, libiconv
, perl
, texinfo
, xz
, binlore
, coreutils
, gmpSupport ? true, gmp
, aclSupport ? stdenv.isLinux, acl
, attrSupport ? stdenv.isLinux, attr
, selinuxSupport ? false, libselinux, libsepol
# No openssl in default version, so openssl-induced rebuilds aren't too big.
# It makes *sum functions significantly faster.
, minimal ? true
, withOpenssl ? !minimal, openssl
, withPrefix ? false
, singleBinary ? "symlinks" # you can also pass "shebangs" or false
}:

# Note: this package is used for bootstrapping fetchurl, and thus cannot use
# fetchpatch! All mutable patches (generated by GitHub or cgit) that are needed
# here should be included directly in Nixpkgs as files.

assert aclSupport -> acl != null;
assert selinuxSupport -> libselinux != null && libsepol != null;

let
  inherit (lib) concatStringsSep isString optional optionalAttrs optionals optionalString;
  isCross = (stdenv.hostPlatform != stdenv.buildPlatform);
in
stdenv.mkDerivation rec {
  pname = "coreutils" + (optionalString (!minimal) "-full");
  version = "9.5";

  src = fetchurl {
    url = "mirror://gnu/coreutils/coreutils-${version}.tar.xz";
    hash = "sha256-zTKO3qyS9qZl3p8yPJO3Eq8YWLwuDYjz9xAEaUcKG4o=";
  };

  patches = [
    # https://lists.gnu.org/archive/html/bug-coreutils/2024-05/msg00037.html
    # This is not precisely the patch provided - this is a diff of the Makefile.in
    # after the patch was applied and autoreconf was run, since adding autoreconf
    # here causes infinite recursion.
    ./fix-mix-flags-deps-libintl.patch
  ] ++ lib.optionals stdenv.hostPlatform.isMusl [
    # https://lists.gnu.org/archive/html/bug-coreutils/2024-03/msg00089.html
    ./fix-test-failure-musl.patch
  ];

  postPatch = ''
    # The test tends to fail on btrfs, f2fs and maybe other unusual filesystems.
    sed '2i echo Skipping dd sparse test && exit 77' -i ./tests/dd/sparse.sh
    sed '2i echo Skipping du threshold test && exit 77' -i ./tests/du/threshold.sh
    sed '2i echo Skipping cp reflink-auto test && exit 77' -i ./tests/cp/reflink-auto.sh
    sed '2i echo Skipping cp sparse test && exit 77' -i ./tests/cp/sparse.sh
    sed '2i echo Skipping env test && exit 77' -i ./tests/env/env.sh
    sed '2i echo Skipping rm deep-2 test && exit 77' -i ./tests/rm/deep-2.sh
    sed '2i echo Skipping du long-from-unreadable test && exit 77' -i ./tests/du/long-from-unreadable.sh

    # The test tends to fail on cephfs
    sed '2i echo Skipping df total-verify test && exit 77' -i ./tests/df/total-verify.sh

    # Some target platforms, especially when building inside a container have
    # issues with the inotify test.
    sed '2i echo Skipping tail inotify dir recreate test && exit 77' -i ./tests/tail/inotify-dir-recreate.sh

    # sandbox does not allow setgid
    sed '2i echo Skipping chmod setgid test && exit 77' -i ./tests/chmod/setgid.sh
    substituteInPlace ./tests/install/install-C.sh \
      --replace 'mode3=2755' 'mode3=1755'

    # Fails on systems with a rootfs. Looks like a bug in the test, see
    # https://lists.gnu.org/archive/html/bug-coreutils/2019-12/msg00000.html
    sed '2i print "Skipping df skip-rootfs test"; exit 77' -i ./tests/df/skip-rootfs.sh

    # these tests fail in the unprivileged nix sandbox (without nix-daemon) as we break posix assumptions
    for f in ./tests/chgrp/{basic.sh,recurse.sh,default-no-deref.sh,no-x.sh,posix-H.sh}; do
      sed '2i echo Skipping chgrp && exit 77' -i "$f"
    done
    for f in gnulib-tests/{test-chown.c,test-fchownat.c,test-lchown.c}; do
      echo "int main() { return 77; }" > "$f"
    done

    # We don't have localtime in the sandbox
    for f in gnulib-tests/{test-localtime_r.c,test-localtime_r-mt.c}; do
      echo "int main() { return 77; }" > "$f"
    done

    # intermittent failures on builders, unknown reason
    sed '2i echo Skipping du basic test && exit 77' -i ./tests/du/basic.sh
  '' + (optionalString (stdenv.hostPlatform.libc == "musl") (concatStringsSep "\n" [
    ''
      echo "int main() { return 77; }" > gnulib-tests/test-parse-datetime.c
      echo "int main() { return 77; }" > gnulib-tests/test-getlogin.c
    ''
  ])) + (optionalString stdenv.isAarch64 ''
    # Sometimes fails: https://github.com/NixOS/nixpkgs/pull/143097#issuecomment-954462584
    sed '2i echo Skipping cut huge range test && exit 77' -i ./tests/cut/cut-huge-range.sh
  '');

  outputs = [ "out" "info" ];
  separateDebugInfo = true;

  nativeBuildInputs = [
    perl
    xz.bin
  ]
  ++ optionals stdenv.hostPlatform.isCygwin [
    # due to patch
    autoreconfHook
    texinfo
  ];

  buildInputs = [ ]
    ++ optional aclSupport acl
    ++ optional attrSupport attr
    ++ optional gmpSupport gmp
    ++ optional withOpenssl openssl
    ++ optionals selinuxSupport [ libselinux libsepol ]
    # TODO(@Ericson2314): Investigate whether Darwin could benefit too
    ++ optional (isCross && stdenv.hostPlatform.libc != "glibc") libiconv;

  hardeningDisable = [ "trivialautovarinit" ];

  configureFlags = [ "--with-packager=https://nixos.org" ]
    ++ optional (singleBinary != false)
      ("--enable-single-binary" + optionalString (isString singleBinary) "=${singleBinary}")
    ++ optional withOpenssl "--with-openssl"
    ++ optional stdenv.hostPlatform.isSunOS "ac_cv_func_inotify_init=no"
    ++ optional withPrefix "--program-prefix=g"
    # the shipped configure script doesn't enable nls, but using autoreconfHook
    # does so which breaks the build
    ++ optional stdenv.isDarwin "--disable-nls"
    ++ optionals (isCross && stdenv.hostPlatform.libc == "glibc") [
      # TODO(19b98110126fde7cbb1127af7e3fe1568eacad3d): Needed for fstatfs() I
      # don't know why it is not properly detected cross building with glibc.
      "fu_cv_sys_stat_statfs2_bsize=yes"
    ]
    # /proc/uptime is available on Linux and produces accurate results even if
    # the boot time is set to the epoch because the system has no RTC. We
    # explicitly enable it for cases where it can't be detected automatically,
    # such as when cross-compiling.
    ++ optional stdenv.hostPlatform.isLinux "gl_cv_have_proc_uptime=yes";

  # The tests are known broken on Cygwin
  # (http://article.gmane.org/gmane.comp.gnu.core-utils.bugs/19025),
  # Darwin (http://article.gmane.org/gmane.comp.gnu.core-utils.bugs/19351),
  # and {Open,Free}BSD.
  # With non-standard storeDir: https://github.com/NixOS/nix/issues/512
  doCheck = (!isCross)
    && (stdenv.hostPlatform.libc == "glibc" || stdenv.hostPlatform.libc == "musl")
    && !stdenv.isAarch32;

  # Prevents attempts of running 'help2man' on cross-built binaries.
  PERL = if isCross then "missing" else null;

  enableParallelBuilding = true;

  NIX_LDFLAGS = optionalString selinuxSupport "-lsepol";
  FORCE_UNSAFE_CONFIGURE = optionalString stdenv.hostPlatform.isSunOS "1";
  env.NIX_CFLAGS_COMPILE = toString ([]
    # Work around a bogus warning in conjunction with musl.
    ++ optional stdenv.hostPlatform.isMusl "-Wno-error"
    ++ optional stdenv.hostPlatform.isAndroid "-D__USE_FORTIFY_LEVEL=0");

  # Works around a bug with 8.26:
  # Makefile:3440: *** Recursive variable 'INSTALL' references itself (eventually).  Stop.
  preInstall = optionalString isCross ''
    sed -i Makefile -e 's|^INSTALL =.*|INSTALL = ${buildPackages.coreutils}/bin/install -c|'
  '';

  postInstall = optionalString (isCross && !minimal) ''
    rm $out/share/man/man1/*
    cp ${buildPackages.coreutils-full}/share/man/man1/* $out/share/man/man1
  ''
  # du: 8.7 M locale + 0.4 M man pages
  + optionalString minimal ''
    rm -r "$out/share"
  '';

  passthru = {} // optionalAttrs (singleBinary != false) {
    # everything in the single binary gets the same verdict, so we
    # override _that case_ with verdicts from separate binaries.
    #
    # binlore only spots exec in runcon on some platforms (i.e., not
    # darwin; see comment on inverse case below)
    binlore.out = binlore.synthesize coreutils ''
      execer can bin/{chroot,env,install,nice,nohup,runcon,sort,split,stdbuf,timeout}
      execer cannot bin/{[,b2sum,base32,base64,basename,basenc,cat,chcon,chgrp,chmod,chown,cksum,comm,cp,csplit,cut,date,dd,df,dir,dircolors,dirname,du,echo,expand,expr,factor,false,fmt,fold,groups,head,hostid,id,join,kill,link,ln,logname,ls,md5sum,mkdir,mkfifo,mknod,mktemp,mv,nl,nproc,numfmt,od,paste,pathchk,pinky,pr,printenv,printf,ptx,pwd,readlink,realpath,rm,rmdir,seq,sha1sum,sha224sum,sha256sum,sha384sum,sha512sum,shred,shuf,sleep,stat,stty,sum,sync,tac,tail,tee,test,touch,tr,true,truncate,tsort,tty,uname,unexpand,uniq,unlink,uptime,users,vdir,wc,who,whoami,yes}
    '';
  } // optionalAttrs (singleBinary == false) {
    # binlore only spots exec in runcon on some platforms (i.e., not
    # darwin; I have a note that the behavior may need selinux?).
    # hard-set it so people working on macOS don't miss cases of
    # runcon until ofBorg fails.
    binlore.out = binlore.synthesize coreutils ''
      execer can bin/runcon
    '';
  };

  meta = with lib; {
    homepage = "https://www.gnu.org/software/coreutils/";
    description = "GNU Core Utilities";
    longDescription = ''
      The GNU Core Utilities are the basic file, shell and text manipulation
      utilities of the GNU operating system. These are the core utilities which
      are expected to exist on every operating system.
    '';
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ das_j ];
    platforms = with platforms; unix ++ windows;
    priority = 10;
  };
}
