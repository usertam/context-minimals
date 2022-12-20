{ stdenv
, src
, runCommand
, cmake
, ninja
}:

stdenv.mkDerivation {
  inherit src;
  pname = "luametatex";
  version = builtins.readFile (runCommand "version" {} ''
    grep 'luametatex_version_string' ${src}/source/luametatex.h \
      | cut -d\" -f2 | tr -d "\n" > $out
  '');

  nativeBuildInputs = [
    cmake
    ninja
  ];

  enableParallelBuilding = true;

  configurePhase = ''
    cmake -G Ninja .
  '';

  installPhase = ''
    install -Dm555 -t $out/bin luametatex
  '';
}
