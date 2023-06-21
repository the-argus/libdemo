{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  coreutils,
  llvmPackages,
  libxml2,
  zlib,
}:
stdenv.mkDerivation rec {
  pname = "zig";
  version = "0.11.0";

  src = fetchFromGitHub {
    owner = "ziglang";
    repo = pname;
    rev = "128fd7dd02ae112cba68d0ad6cc40dc1ce8c34b1";
    sha256 = "1ym6nkz2ahd65zxzxqs9jrncfqma57x7f22a0ls1s7nlaiq4blwy";
  };

  nativeBuildInputs = [
    cmake
    llvmPackages.llvm.dev
  ];

  buildInputs =
    [
      coreutils
      libxml2
      zlib
    ]
    ++ (with llvmPackages; [
      libclang
      lld
      llvm
    ]);

  preBuild = ''
    export HOME=$TMPDIR;
  '';

  postPatch = ''
    # Zig's build looks at /usr/bin/env to find dynamic linking info. This
    # doesn't work in Nix' sandbox. Use env from our coreutils instead.
    substituteInPlace lib/std/zig/system/NativeTargetInfo.zig --replace "/usr/bin/env" "${coreutils}/bin/env"
  '';

  cmakeFlags = [
    # file RPATH_CHANGE could not write new RPATH
    "-DCMAKE_SKIP_BUILD_RPATH=ON"

    # always link against static build of LLVM
    "-DZIG_STATIC_LLVM=ON"

    # ensure determinism in the compiler build
    "-DZIG_TARGET_MCPU=baseline"
  ];

  doCheck = false;

  installCheckPhase = ''
    $out/bin/zig test --cache-dir "$TMPDIR" -I $src/test $src/test/behavior.zig
  '';

  meta = with lib; {
    homepage = "https://ziglang.org/";
    description = "General-purpose programming language and toolchain for maintaining robust, optimal, and reusable software";
    license = licenses.mit;
    maintainers = with maintainers; [aiotter andrewrk AndersonTorres];
    platforms = platforms.unix;
  };
}
