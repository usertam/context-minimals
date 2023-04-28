{ stdenv
, src
, cmake
, ninja
}:

stdenv.mkDerivation {
  inherit src;
  pname = "luametatex";
  version = "2.10.09";

  nativeBuildInputs = [
    cmake
    ninja
  ];

  enableParallelBuilding = true;

  CFLAGS = "-Wno-builtin-macro-redefined -U__DATE__";

  installPhase = ''
    install -Dm555 -t $out/bin luametatex
  '';
}
