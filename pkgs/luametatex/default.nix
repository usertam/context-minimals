{ stdenv
, src
, runCommand
, cmake
, ninja
}:

stdenv.mkDerivation {
  inherit src;
  pname = "luametatex";
  version = "2.10.05";

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
