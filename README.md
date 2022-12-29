# context-minimals
A reproducible ConTeXt LMTX distribution. Mirrors updated daily.

## Run me with Nix!
```sh
# run context by default; or luametatex, luatex, mtxrun by specifying them
nix run github:usertam/context-minimals
nix run github:usertam/context-minimals#mtxrun

# get a shell with all the goodies
nix shell github:usertam/context-minimals
```

## Make PDFs reproducible as well!
This fixes the random seed, disables timestamps and the PDF trailer ID.
```
nix shell github:usertam/context-minimals
context --randomseed=0 --nodates --trailerid=false main.tex
```

## Add fonts declaratively?
Specify or override the `fonts` attribute similar to [here][1].
```
ctx = context-minimals.packages.${system}.default.override {
  fonts = [ pkgs.source-sans-pro pkgs.source-serif-pro ];
};
```

##### More hacks if you need it
The `fpath` attribute adds additional paths to [`OSFONTDIR`][2], used when the font files are not placed under `$out/share/fonts`. The `fcache` attribute builds the font caches by forcing cache misses during `fixupPhase`. Used when ConTeXt is having a hard time chewing through CJK fonts cold-cached, i.e. getting stuck on `vorg | loading of table ... skipped`.
```
ctx = context-minimals.packages.${system}.default.override {
  fonts = [ pkgs.source-han-sans pkgs.source-han-serif ];
  fcache = [ "sourcehansans" "sourcehanserif" ];
};
```

OR, you can try doing it ad-hoc first. Try building with local cache, see if it works.
```sh
nix shell github:usertam/context-minimals
mtxrun --generate
mtxrun --script font --reload
context main.tex
```

[1]: https://github.com/usertam/context-minimals/blob/f32f9f4671a268f859c3a85d68897631b44f9937/flake.nix#L27
[2]: https://github.com/usertam/context-minimals/blob/f32f9f4671a268f859c3a85d68897631b44f9937/default.nix#L92
