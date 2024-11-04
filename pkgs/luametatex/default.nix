{ stdenv
, src
, cmake
, ninja
}:

stdenv.mkDerivation (attrsFinal: {
  pname = "luametatex";
  version = "2.11.06";

  inherit src;

  nativeBuildInputs = [
    cmake
    ninja
  ];

  enableParallelBuilding = true;

  CFLAGS = "-Wno-builtin-macro-redefined -U__DATE__";

  installPhase = ''
    install -Dm555 -t $out/bin luametatex
  '';

  passthru.computedVersion =
    let
      source = builtins.readFile (attrsFinal.src + "/source/luametatex.h");
      versionMatch = builtins.match ''.*[^a-z0-9_]luametatex_version_string[ \t]+"([^"]*)".*'' source;
    in builtins.elemAt versionMatch 0;
})
