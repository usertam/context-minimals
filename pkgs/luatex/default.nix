{ lib
, stdenv
, src
, runCommand
, pkg-config
, cairo
, gmp
, graphite2
, harfbuzz
, libpng
, mpfr
, pixman
, zlib
, zziplib
}:

stdenv.mkDerivation rec {
  inherit src;
  pname = "luatex";
  version = builtins.readFile (runCommand "version" {} ''
    grep 'luatex_version_string' ${src}/source/texk/web2c/luatexdir/luatex.c \
      | cut -d\" -f2 | tr -d "\n" > $out
  '');

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    cairo
    gmp
    graphite2
    harfbuzz
    libpng
    mpfr
    pixman
    zlib
    zziplib
  ];

  ldLibraryPath = lib.makeLibraryPath buildInputs;

  enableParallelBuilding = true;

  preConfigure = ''
    export BUILD=$PWD/build
    mkdir -p $BUILD && cd $BUILD
  '';

  configureScript = "${src}/source/configure";
  configureFlags = [
    "--enable-compiler-warnings=yes"
    "--enable-silent-rules"
    "--disable-all-pkgs"
    "--disable-shared"
    "--disable-ptex"
    "--disable-largefile"
    "--disable-xetex"
    "--disable-ipc"
    "--disable-dump-share"
    "--disable-native-texlive-build"
    "--enable-coremp"
    "--enable-web2c"
    "--enable-luatex"
    "--enable-luajittex=no"
    "--enable-mfluajit=no"
    "--enable-luahbtex=no"
    "--enable-luajithbtex=no"
    "--enable-mfluajit=no"
    "--without-mf-x-toolkit"
    "--without-x"
  ] ++ map (what: "--with-system-${what}") [
    "cairo"
    "gmp"
    "graphite2"
    "harfbuzz"
    "libpng"
    "mpfr"
    "pixman"
    "zlib"
    "zziplib"
  ] ++ map (what: "--without-system-${what}") [
    "kpathsea"
    "ptexenc"
    "teckit"
    "xpdf"
  ];

  postConfigure = toString (map (dir: ''
    mkdir -p $BUILD/${dir} && cd $BUILD/${dir}
    local flagsArray=($configureFlags "''${configureFlagsArray[@]}")
    ${src}/source/${dir}/configure ''${flagsArray[@]}
    unset flagsArray
    cd $BUILD
  '') [
    "texk/kpathsea"
    "texk/web2c"
  ]);

  buildPhase = ''
    local flagsArray=(''${enableParallelBuilding:+-j''${NIX_BUILD_CORES}} SHELL=$SHELL $makeFlags "''${makeFlagsArray[@]}" $buildFlags "''${buildFlagsArray[@]}")
    make ''${flagsArray[@]} -C libs
    make ''${flagsArray[@]} -C utils
    make ''${flagsArray[@]} -C texk/kpathsea
    make ''${flagsArray[@]} -C texk/web2c luatex
    unset flagsArray
  '';

  installPhase = ''
    install -Dm555 -t $out/bin texk/web2c/luatex
  '';
}
