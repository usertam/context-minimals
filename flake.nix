{
  inputs = {
    context.flake = false;
    context.url = "github:contextgarden/context";
    context-fonts.flake = false;
    context-fonts.url = "github:contextgarden/context-distribution-fonts";
    context-modules.flake = false;
    context-modules.url = "github:usertam/context-minimals/mirror/modules";
    luatex.flake = false;
    luatex.url = "github:TeX-Live/luatex";
    nixpkgs.url = "flake:nixpkgs/nixpkgs-unstable";
    systems.flake = false;
    systems.url = "flake:systems";
  };

  nixConfig.extra-substituters = "https://context-minimals.cachix.org";
  nixConfig.extra-trusted-public-keys = "context-minimals.cachix.org-1:pYxyH24J/A04fznRlYbTTjWrn9EsfUQvccGMjfXMdj0=";

  outputs = { self, ... }@inputs:
    let
      forAllSystems = nixpkgs-lib.attrsets.genAttrs systems;
      nixpkgs-lib = inputs.nixpkgs.lib;
      systems = import inputs.systems;
    in {
      packages = forAllSystems (system:
        let
          packages' = self.packages.${system};
          pkgs = inputs.nixpkgs.legacyPackages.${system};
        in {
          luametatex = pkgs.callPackage ./pkgs/luametatex {
            src = inputs.context + /source/luametatex;
          };
          luatex = pkgs.callPackage ./pkgs/luatex {
            src = inputs.luatex;
          };
          context-minimals = pkgs.callPackage ./pkgs/context-minimals {
            inherit (inputs) context context-fonts context-modules;
            inherit (packages') luametatex luatex;
          };
          default = packages'.context-minimals;
        });

      apps = forAllSystems (system:
        let
          apps' = self.apps.${system};
          mkApp = bin: {
            type = "app";
            program = "${packages'.default}/bin/${bin}";
          };
          packages' = self.packages.${system};
        in {
          context = mkApp "context";
          luametatex = mkApp "luametatex";
          luatex = mkApp "luatex";
          mtxrun = mkApp "mtxrun";
          default = apps'.context;
        });

      lib = import ./modules/lib {
        inherit (inputs) nixpkgs;
        inherit forAllSystems nixpkgs-lib;
        contextPackages = self.packages;
      };
    };
}
