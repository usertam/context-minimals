# context-minimals
A reproducible ConTeXt LMTX distribution. Mirrors updated daily.

## Run me with Nix!
This will execute `context` by default.
```sh
nix run github:usertam/context-minimals
```

## Put me in a shell
In a shell, `context`, `luametatex`, `luatex` and `mtxrun` will be made available.
```sh
nix shell github:usertam/context-minimals
```

## Make local cache
When sometimes the global cache is not enough.
```sh
nix run github:usertam/context-minimals#mtxrun -- --generate
nix run github:usertam/context-minimals#mtxrun -- --script font --reload    # font cache
```
