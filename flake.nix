{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    context.url = "github:contextgarden/context/main";
    context.flake = false;
    luatex.url = "github:TeX-Live/luatex";
    luatex.flake = false;
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
      in rec {
        luatex = pkgs.callPackage ./pkgs/luatex/default.nix {
          src = inputs.luatex;
        };
        luametatex = pkgs.callPackage ./pkgs/luametatex/default.nix {
          src = "${inputs.context}/source/luametatex";
        };
        context-minimals = pkgs.callPackage ./default.nix {
          inherit inputs luametatex luatex;
          libfaketime = pkgs.libfaketime.overrideAttrs (final: prev: rec {
            version = "0.9.10";
            src = pkgs.fetchFromGitHub {
              owner = "wolfcw";
              repo = "libfaketime";
              rev = "v${version}";
              sha256 = "sha256-DYRuQmIhQu0CNEboBAtHOr/NnWxoXecuPMSR/UQ/VIQ=";
            };
            patches = [];
          });
          src = self;
          fonts = [ pkgs.lmodern pkgs.libertinus ];
        };
        default = context-minimals;
      });

      apps = forAllSystems (system: let
        mkApp = bin: {
          type = "app";
          program = "${self.packages.${system}.default}/bin/${bin}";
        };
      in {
        context = mkApp "context";
        luametatex = mkApp "luametatex";
        luatex = mkApp "luatex";
        mtxrun = mkApp "mtxrun";
        default = self.apps.${system}.context;
      });
    };
}
