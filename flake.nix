{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
    context = { url = "github:contextgarden/context"; flake = false; };
    context-fonts = { url = "github:contextgarden/context-distribution-fonts"; flake = false; };
    context-modules = { url = "github:usertam/context-minimals/mirror/modules"; flake = false; };
    luatex = { url = "gitlab:texlive/luatex?host=gitlab.lisn.upsaclay.fr"; flake = false; };
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
            src = inputs.context + "/source/luametatex";
          };
          luatex = pkgs.callPackage ./pkgs/luatex {
            src = inputs.luatex + "/source";
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
