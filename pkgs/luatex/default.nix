{ stdenv
, src
, pkg-config
, graphite2
, harfbuzz
, libpng
, zlib
, zziplib
}:

stdenv.mkDerivation (attrsFinal: {
  pname = "luatex";
  version = "1.23.3";

  inherit src;

  nativeBuildInputs = [
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
    "--enable-silent-rules"
    "--disable-all-pkgs"
    "--disable-native-texlive-build"
    "--enable-luatex"
    "--without-x"
  ] ++ map (lib: "--with-system-${lib}") [
    "graphite2"
    "harfbuzz"
    "libpng"
    "zlib"
    "zziplib"
  ];

  buildPhase = ''
    local flagsArray=(''${enableParallelBuilding:+-j''${NIX_BUILD_CORES}} SHELL=$SHELL $makeFlags "''${makeFlagsArray[@]}" $buildFlags "''${buildFlagsArray[@]}")
    make ''${flagsArray[@]}
    make ''${flagsArray[@]} -C libs/pplib
    make ''${flagsArray[@]} -C texk/web2c luatex
    unset flagsArray
  '';

  installPhase = ''
    install -Dm555 -t $out/bin texk/web2c/luatex
  '';

  passthru.computedVersion =
    let
      source = builtins.readFile (attrsFinal.src + "/texk/web2c/luatexdir/luatex.c");
      versionMatch = builtins.match ''.*[^a-z0-9_]luatex_version_string[ \t]*=[ \t]*"([^"]*)";.*'' source;
    in builtins.elemAt versionMatch 0;
})
