{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    context.url = "github:contextgarden/context";
    context.flake = false;
    context-fonts.url = "github:contextgarden/context-distribution-fonts";
    context-fonts.flake = false;
    luatex.url = "github:TeX-Live/luatex";
    luatex.flake = false;
    modules.url = "github:usertam/context-minimals/mirror/modules";
    modules.flake = false;
  };

  outputs = { self, ... }@inputs: let
      forAllSystems = with inputs.nixpkgs.lib; genAttrs platforms.unix;
    in {
      packages = forAllSystems (system: let
        pkgs = inputs.nixpkgs.legacyPackages.${system};
      in rec {
        luametatex = pkgs.callPackage ./pkgs/luametatex {
          src = "${inputs.context}/source/luametatex";
        };
        luatex = pkgs.callPackage ./pkgs/luatex {
          src = inputs.luatex;
        };
        context-minimals = pkgs.callPackage self {
          inherit (inputs) context context-fonts modules;
          inherit luametatex luatex;
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
