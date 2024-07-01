# context-minimals
A reproducible ConTeXt LMTX distribution. Sources checked and updated weekly.

## Run me with Nix!
Common ad-hoc usages below.
```sh
# Run context by default, specify luametatex, luatex, mtxrun to run them.
nix run github:usertam/context-minimals
nix run github:usertam/context-minimals#mtxrun

# Get a shell with all the goodies.
nix shell github:usertam/context-minimals
```

## Dedicated cache
Builds of common platforms are cached at [context-minimals.cachix.org][6].
```sh
extra-substituters = https://context-minimals.cachix.org
extra-trusted-public-keys = context-minimals.cachix.org-1:pYxyH24J/A04fznRlYbTTjWrn9EsfUQvccGMjfXMdj0=
```

## Tex PDFs declaratively, with flakes
In `flake.nix`, use [`mkCompilation`][7] in `modules/lib/default.nix` to compile `main.tex`.
```nix
{
  inputs.context-minimals.url = "github:usertam/context-minimals";
  inputs.photo.url = "https://unsplash.com/photos/.../download";  # Include extra files, only available in `nix build`.
  inputs.photo.flake = false;

  outputs = { self, context-minimals, ... }@inputs: let
    fonts = [ "source-han-serif" ]; # Include a font defined in nixpkgs.
    fcache = [ "sourcehanserif" ];  # Force build caches of the font, useful for slow CJK fonts. This name should be recognized by ConTeXt.
  in {
    packages = context-minimals.lib.mkCompilation {
      inherit fonts fcache;
      src = self;
      nativeBuildInputs = [ "imagemagick" ];  # Include deps for `postUnpack`.
      postUnpack = "convert -quality 100% -despeckle ${inputs.photo} $sourceRoot/photo.jpeg";
    };
    apps = context-minimals.lib.mkCompilationApps {
      inherit fonts fcache;
    };
  };
}
```

## Remarks
By default, installing ConTeXt LMTX requires downloading a prebuilt [`mtxrun`][1] to bootstrap the installation. The installation script `mtx-install.lua` is then run, downloading and extracting archives in the process; after which the modules would need to be installed [separately][2]. While the defaults focus on the ease of maintenance (running `mtx-update`), the internals are harder to dissect.

The installation script is a lengthy [lua script][1], making the fetching and extracting steps unclear at first glance. The [two-part installation][2], platform-dependent [setups][3] and [install steps][4] also didn't make it easy to follow. Along with unpinned prebuilt [binaries][5], it was challenging to reproduce an installation that could be used out-of-the-box.

#### Solution
The project does not follow the installation script, but rather reconstructs the tex structure based on the sources and by looking at the artifact. The reworked steps are then trimmed down and implemented in `default.nix`, building binaries `luametatex` and `luatex` from source. Fonts and font caches are another can of worms, and need several patches to stay deterministic but functional.

Apart from the reproducibility of the ConTeXt installation, the deterministic compilation of PDFs is another goal of the project. ConTeXt does offer flags like `randomseed`, `nodates` and `trailerid` to disable non-deterministic PDF subtleties, but not well-documented. Therefore, functions like `lib.mkCompilation` are provided to offer "standard" ways to compile PDFs.

Note that non-determinism can still be introduced by macros like `\date`. For MetaPost, `randomseed := 0;` is still needed to make `uniformdeviate` deterministic.

[1]: https://distribution.contextgarden.net/setup/linux-64/bin
[2]: https://wiki.contextgarden.net/Modules#ConTeXt_LMTX
[3]: https://distribution.contextgarden.net/setup
[4]: https://wiki.contextgarden.net/Installing_ConTeXt_LMTX_on_MacOS
[5]: https://distribution.contextgarden.net/current/bin
[6]: https://context-minimals.cachix.org
[7]: https://github.com/usertam/context-minimals/blob/53f85e8ea12c5017b230eb3fc6dc38451e637541/modules/lib/default.nix#L7
