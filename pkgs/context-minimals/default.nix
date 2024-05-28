{ stdenv
, stdenvNoCC
, context
, context-fonts
, context-modules
, luametatex
, luatex
, makeWrapper
, fonts ? []
, fpath ? []
, fcache ? []
}:

let
ctx-base = stdenvNoCC.mkDerivation (attrsFinal: let
  inherit (attrsFinal.passthru) srcs';
in {
  pname = "context-minimals-base";
  version = "2024.05.27 18:05";

  passthru.srcs' = { inherit context context-fonts context-modules; };
  srcs = builtins.attrValues srcs';

  buildInputs = [ luametatex luatex ];
  nativeBuildInputs = [ makeWrapper ];

  dontConfigure = true;
  dontBuild = true;
  dontInstall = true;

  unpackPhase = ''
    runHook preUnpack

    # unpack sources to `tex/texmf-context`
    mkdir -p $out/share/tex/texmf-context/scripts/context
    cp -a ${srcs'.context}/{colors,fonts,metapost,tex}  $out/share/tex/texmf-context
    cp -a ${srcs'.context}/scripts/context/lua          $out/share/tex/texmf-context/scripts/context
    cp -a ${srcs'.context}/scripts/context/stubs        $out/share/tex/texmf-context/scripts/context

    # unpack configs to `tex/texmf/web2c`
    mkdir -p $out/share/tex/texmf/web2c
    cp -a ${srcs'.context}/web2c/context.cnf    $out/share/tex/texmf/web2c/texmf.cnf
    cp -a ${srcs'.context}/web2c/contextcnf.lua $out/share/tex/texmf/web2c/texmfcnf.lua

    # unpack binaries to `tex/texmf-context/bin`
    install -Dm755 -t $out/share/tex/texmf-context/bin ${luametatex}/bin/luametatex ${luatex}/bin/luatex

    # populate `tex/texmf-context/bin`
    ln -st $out/share/tex/texmf-context/bin ../scripts/context/lua/{context.lua,mtxrun.lua,mtx-context.{lua,xml}}
    ln -s luametatex $out/share/tex/texmf-context/bin/mtxrun
    ln -s luametatex $out/share/tex/texmf-context/bin/context

    # unpack fonts to `tex/texmf-fonts`
    cp -a ${srcs'.context-fonts} $out/share/tex/texmf-fonts

    # unpack modules to `tex/texmf-modules`
    mkdir -p $out/share/tex/texmf-modules
    for MODULE in ${srcs'.context-modules}/*; do
      cp -af --no-preserve=mode $MODULE/* $out/share/tex/texmf-modules
    done
    find -L $out/share/tex/texmf-modules -maxdepth 1 -type f -delete

    # wrap `tex/texmf-system/bin` -> `bin`
    for BIN in context mtxrun luametatex luatex; do
      makeWrapper $out/share/tex/texmf-context/bin/$BIN $out/bin/$BIN
    done

    runHook postUnpack
  '';

  patches = [
    ./patches/0001-remove-modification-detections.patch
    ./patches/0002-remove-timestamps-and-uuid-embedding-in-font-caches.patch
    ./patches/0003-stop-adding-prefixes-to-font-name.patch
    ./patches/0004-remove-placeholder-text-for-uuid.patch
  ];

  prePatch = ''
    # make writable for patch temporary file
    chmod +w $out/share/tex/texmf-context/scripts/context/lua \
      $out/share/tex/texmf-context/tex/context/base/mkiv \
      $out/share/tex/texmf-context/tex/context/base/mkxl \
      $out/share/tex/texmf-context/tex/generic/context/luatex
    # removed after patching
    chmod -R +w $out/share/tex/texmf-context/scripts/context/stubs

    # sources are located in `tex/texmf-context`
    cd $out/share/tex/texmf-context
  '';

  postPatch = ''
    rm -r $out/share/tex/texmf-context/scripts/context/stubs
    # patch done, make read-only
    chmod -w $out/share/tex/texmf-context/scripts/context/lua \
      $out/share/tex/texmf-context/tex/context/base/mkiv \
      $out/share/tex/texmf-context/tex/context/base/mkxl \
      $out/share/tex/texmf-context/tex/generic/context/luatex
  '';

  passthru.computedVersion =
    let
      source = builtins.readFile (srcs'.context + "/tex/context/base/mkxl/cont-new.mkxl");
      versionMatch = builtins.match ''.*\\newcontextversion\{([^{}]*)}.*'' source;
    in builtins.elemAt versionMatch 0;
});

in
stdenv.mkDerivation (attrsFinal: {
  pname = "context-minimals";
  inherit (attrsFinal.src) version;

  enableParallelBuilding = true;
  passAsFile = [ "buildCommand" ];

  src = ctx-base;

  buildInputs = [ attrsFinal.src ] ++ fonts;
  nativeBuildInputs = [ makeWrapper ];

  buildCommand = ''
    # symlink original sources
    mkdir -p $out/share/tex
    ln -t $out/share/tex -s $src/share/tex/*

    # set TEXMFCACHE to `tex/texmf-cache`
    export TEXMFCACHE=$out/share/tex/texmf-cache
    mkdir -p $TEXMFCACHE

    # wrap `tex/texmf-system/bin` -> `bin`
    for BIN in context mtxrun luametatex luatex; do
      makeWrapper $out/share/tex/texmf-context/bin/$BIN $out/bin/$BIN \
        --set TEXMFCACHE $TEXMFCACHE
    done

    # generate file databases
    $out/bin/mtxrun --verbose --generate
    $out/bin/luatex --luaonly $out/share/tex/texmf-context/bin/mtxrun.lua --verbose --generate

    # generate font databases
    export OSFONTDIR=${builtins.concatStringsSep ":" ((map (f: f + "/share/fonts") fonts) ++ fpath)}
    $out/bin/mtxrun --verbose --script font --reload

  '' + builtins.concatStringsSep "\n" (map (font: ''
    # build font cache by forcing cache misses
    cat <<'EOF' > "${font}.tex" && $out/bin/context "${font}.tex"
    \definedfont[name:${font}*default]
    Normal {\bf Bold} {\it Italic} {\sl Slanted} {\bi Bold Italic} {\bs Bold Slanted} {\sc Small Capitals}
    EOF
  '') fcache) + ''

    # delete the formats from forcing cache misses, keep cache deterministic
    find $out/share/tex/texmf-cache -name 'formats' -type d -exec rm -rf {} +
  '';
})
