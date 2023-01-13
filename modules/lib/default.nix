{ nixpkgs
, ctxpkgs
, forAllSystems
}:

{
  mkCompilation =
    { src
    , doc ? "main"
    , preUnpack ? ""
    , postUnpack ? ""
    , fonts ? []
    , fpath ? []
    , fcache ? []
    }:
    forAllSystems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        ctx = ctxpkgs.${system}.default.override {
          inherit fpath fcache;
          fonts = map (a: pkgs.${a}) fonts;
        };
      in {
        default = pkgs.runCommand "main" {
          inherit src preUnpack postUnpack;
          nativeBuildInputs = [ ctx pkgs.qpdf ];
        } ''
          unpackPhase && cd $sourceRoot
          context --randomseed=0 --nodates --trailerid=false ${doc}
          qpdf --deterministic-id --linearize \
            --newline-before-endstream --replace-input ${doc}.pdf
          install -Dm444 -t $out ${doc}.pdf
        '';
      });

  mkCompilationApps =
    { doc ? "main"
    , fonts ? []
    , fpath ? []
    , fcache ? []
    }:
    forAllSystems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        ctx = ctxpkgs.${system}.default.override {
          inherit fpath fcache;
          fonts = map (a: pkgs.${a}) fonts;
        };
        sh = cmd: {
          type = "app";
          program = toString (pkgs.writeShellScript "app.sh" cmd);
        };
      in {
        default = sh ''
          ${ctx}/bin/context \
            --randomseed=0 --nodates --trailerid=false \
            --synctex ${doc} || exit $?
          rm -f ${doc}.{log,syncctx,tua,tuc}
        '';
        clean = sh ''
          rm -f ${doc}.{log,syncctx,tua,tuc,pdf,synctex}
        '';
      });
}
