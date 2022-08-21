{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    context.url = "github:contextgarden/context-mirror/beta";
    context.flake = false;
    binaries.url = "github:usertam/context-minimals/mirror/binaries";
    binaries.flake = false;
    modules.url = "github:usertam/context-minimals/mirror/modules";
    modules.flake = false;
  };

  outputs = { self, ... }@inputs:
    let
      supportedSystems = [
        "aarch64-linux"
        "aarch64-darwin"
        "i686-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      forAllSystems = inputs.nixpkgs.lib.genAttrs supportedSystems;
    in {
      packages = forAllSystems (system: let
        pkgs = inputs.nixpkgs.legacyPackages.${system};
      in {
        default = pkgs.stdenv.mkDerivation {
          pname = "context-minimals";
          version = "2022.08.05 17:16";
          src = self;
          nativeBuildInputs = [ pkgs.makeWrapper ];
          dontConfigure = true;
          dontBuild = true;
          installPhase = let
            libPath = pkgs.lib.makeLibraryPath [ pkgs.glibc ];
          in ''
            # install context to $out/tex/texmf-context
            mkdir -p $out/tex/texmf-context
            cp -a ${inputs.context}/{colors,context,doc,fonts,metapost,scripts,tex,web2c} $out/tex/texmf-context

            # install modules to populate $out/modules
            cp -a ${inputs.modules} $out/modules

            # populate $out/tex/texmf
            mkdir -p $out/tex/texmf/web2c
            ln -s $out/tex/texmf-context/web2c/context.cnf $out/tex/texmf/web2c/texmf.cnf
            ln -s $out/tex/texmf-context/web2c/contextcnf.lua $out/tex/texmf/web2c/texmfcnf.lua

            # install luametatex and luatex to $out/tex/texmf-system/bin
            install -Dm755 -t $out/tex/texmf-system/bin ${inputs.binaries}/${system}/{luametatex,luatex}
            patchelf \
              --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
              --set-rpath "${libPath}" \
              $out/tex/texmf-system/bin/{luametatex,luatex}

            # populate $out/tex/texmf-system/bin
            ln -s $out/tex/{texmf-context/scripts/context/lua,texmf-system/bin}/context.lua
            ln -s $out/tex/{texmf-context/scripts/context/lua,texmf-system/bin}/mtxrun.lua
            ln -s $out/tex/texmf-system/bin/{luametatex,mtxrun}
            ln -s $out/tex/texmf-system/bin/{luametatex,context}

            # populate $out/tex/texmf-modules
            mkdir -p $out/tex/texmf-modules
            for DIR in $out/modules/*; do
              ${pkgs.xorg.lndir}/bin/lndir -silent $DIR $out/tex/texmf-modules
            done
            rm -f $out/tex/texmf-modules/{LICENSE,README.md,VERSION}

            # wrap $out/tex/texmf-system/bin/<exe> -> $out/bin/<exe>
            for FILE in $(find $out/tex/texmf-system/bin -type f -executable -follow); do
              makeWrapper $FILE $out/bin/''${FILE##*/}
            done
          '';
          fixupPhase = ''
            # make cache deterministic
            export LD_PRELOAD=${pkgs.libfaketime}/lib/libfaketime.so.1
            export FAKETIME="1970-01-01 00:00:00"

            # generate file databases
            $out/bin/mtxrun --generate
            $out/bin/luatex --luaonly $out/tex/texmf-system/bin/mtxrun.lua --generate

            # generate necessary font cache
            export OSFONTDIR=${pkgs.lmodern}/share/fonts:${pkgs.libertinus}/share/fonts:${pkgs.source-han-serif}/share/fonts:$OSFONTDIR
            $out/bin/mtxrun --script font --reload
          '';
        };
      });

      apps = forAllSystems (system: {
        context = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/context";
        };
        luametatex = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/luametatex";
        };
        luatex = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/luatex";
        };
        mtxrun = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/mtxrun";
        };
        default = self.apps.${system}.context;
      });
    };
}
