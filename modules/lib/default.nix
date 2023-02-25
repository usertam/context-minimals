{ nixpkgs
, ctxpkgs
, forAllSystems
}:

{
  mkCompilation =
    { src
    , nativeBuildInputs ? []
    , preUnpack         ? ""
    , postUnpack        ? ""
    , doc               ? "main"
    , suffices          ? [ ".tex" ".bib" ".pdf" ]
    , fonts             ? []
    , fpath             ? []
    , fcache            ? []
    }:
    forAllSystems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        ctx = ctxpkgs.${system}.default.override {
          inherit fpath fcache;
          fonts = map (a: pkgs.${a}) fonts;
        };
      in {
        default = pkgs.runCommand doc {
          inherit preUnpack postUnpack;
          src = if suffices != null
            then nixpkgs.lib.sourceFilesBySuffices src suffices
            else src;
          nativeBuildInputs = [ ctx pkgs.qpdf ]
            ++ map (a: pkgs.${a}) nativeBuildInputs;
        } ''
          unpackPhase && cd $sourceRoot
          context --randomseed=0 --nodates --trailerid=false ${doc}
          qpdf --deterministic-id --linearize \
            --newline-before-endstream --replace-input ${doc}.pdf
          install -Dm444 -t $out ${doc}.pdf
        '';
      });

  mkCompilationApps =
    { doc ?     "main"
    , fonts ?   []
    , fpath ?   []
    , fcache ?  []
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
