{
  stdenv,
  src,
  autoreconfHook,
  pkg-config,
  graphite2,
  harfbuzz,
  libpng,
  zlib,
  zziplib,
}:

stdenv.mkDerivation (final: {
  pname = "luatex";
  version = "1.23.3";

  inherit src;

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
  ];

  buildInputs = [
    graphite2
    harfbuzz
    libpng
    zlib
    zziplib
  ];

  enableParallelBuilding = true;

  configureFlags = [
    "--enable-build-in-source-tree"
    # Enable dynamic linking with system libraries.
    "--disable-native-texlive-build"
    "--enable-shared"
    # Disable all except luatex.
    "--disable-all-pkgs"
    "--enable-luatex"
    "--without-system-kpathsea"
    "--without-x"
  ] ++ map (lib: "--with-system-${lib}") (map (x: x.pname) final.buildInputs);

  # Regenerate configure scripts for implicit luatex dependencies.
  postAutoreconf = ''
    autoreconf "''${flagsArray[@]}" \
      texk/web2c texk/kpathsea libs/lua53 libs/pplib
  '';

  # Ahead of the build phase, use make to configure all targets first.
  postConfigure = ''
    local flagsArray=(''${enableParallelBuilding:+-j''${NIX_BUILD_CORES}} SHELL="$SHELL")
    concatTo flagsArray makeFlags makeFlagsArray

    echoCmd 'post-configure flags' "''${flagsArray[@]}"
    make "''${flagsArray[@]}"

    unset flagsArray
  '';

  # Before building luatex itself, build dependency pplib first.
  preBuild = ''
    local flagsArray=(''${enableParallelBuilding:+-j''${NIX_BUILD_CORES}} SHELL="$SHELL")
    concatTo flagsArray makeFlags makeFlagsArray

    echoCmd 'pre-build flags' "''${flagsArray[@]}" '-C libs/pplib'
    make "''${flagsArray[@]}" -C libs/pplib

    unset flagsArray
  '';

  buildFlags = [
    "-C texk/web2c"
    "luatex"
  ];

  installFlags = [
    "-C texk/web2c"
    "lib_LTLIBRARIES="
    "bin_PROGRAMS=luatex"
  ];

  installTargets = [ "install-binPROGRAMS" ];

  # After installing luatex, install library kpathsea, lua53 and texmf.cnf.
  postInstall = ''
    local flagsArray=(''${enableParallelBuilding:+-j''${NIX_BUILD_CORES}} SHELL="$SHELL")
    concatTo flagsArray makeFlags makeFlagsArray

    # Don't create directories.
    substituteInPlace texk/kpathsea/Makefile \
      --replace-warn 'install-data-local: installdirs-am' 'install-data-local:'

    echoCmd 'post-install flags' "''${flagsArray[@]}" '-C texk/kpathsea install-libLTLIBRARIES install-data-local'
    make "''${flagsArray[@]}" -C texk/kpathsea install-libLTLIBRARIES install-data-local

    echoCmd 'post-install flags' "''${flagsArray[@]}" '-C libs/lua53 install-libLTLIBRARIES'
    make "''${flagsArray[@]}" -C libs/lua53 install-libLTLIBRARIES

    unset flagsArray
  '';

  passthru.computedVersion =
    let
      source = builtins.readFile (final.src + "/texk/web2c/luatexdir/luatex.c");
      versionMatch = builtins.match ''.*[^a-z0-9_]luatex_version_string[ \t]*=[ \t]*"([^"]*)";.*'' source;
    in
    builtins.elemAt versionMatch 0;
})
