{ stdenvNoCC
, runCommand
, context
, context-fonts
, modules
, luametatex
, luatex
, makeWrapper
, fonts ? []
, fpath ? []
, fcache ? []
}:

let
ctx-base = stdenvNoCC.mkDerivation {
  pname = "context-minimals-base";
  version = "2023.03.06 23:15";

  srcs = [ context context-fonts modules ];
  buildInputs = [ luametatex luatex ];
  nativeBuildInputs = [ makeWrapper ];

  dontConfigure = true;
  dontBuild = true;
  dontInstall = true;

  unpackPhase = ''
    runHook preUnpack

    # unpack sources to `tex/texmf-context`
    mkdir -p $out/share/tex/texmf-context/scripts/context
    cp -a ${context}/{colors,fonts,metapost,tex}  $out/share/tex/texmf-context
    cp -a ${context}/scripts/context/lua          $out/share/tex/texmf-context/scripts/context

    # unpack configs to `tex/texmf/web2c`
    mkdir -p $out/share/tex/texmf/web2c
    cp -a ${context}/web2c/context.cnf    $out/share/tex/texmf/web2c/texmf.cnf
    cp -a ${context}/web2c/contextcnf.lua $out/share/tex/texmf/web2c/texmfcnf.lua

    # unpack binaries to `tex/texmf-context/bin`
    install -Dm755 -t $out/share/tex/texmf-context/bin ${luametatex}/bin/luametatex ${luatex}/bin/luatex

    # populate `tex/texmf-context/bin`
    ln -s ../scripts/context/lua/context.lua  $out/share/tex/texmf-context/bin/context.lua
    ln -s ../scripts/context/lua/mtxrun.lua   $out/share/tex/texmf-context/bin/mtxrun.lua
    ln -s luametatex                          $out/share/tex/texmf-context/bin/mtxrun
    ln -s luametatex                          $out/share/tex/texmf-context/bin/context

    # unpack fonts to `tex/texmf-fonts`
    cp -a ${context-fonts} $out/share/tex/texmf-fonts

    # unpack modules to `tex/texmf-modules`
    mkdir -p $out/share/tex/texmf-modules
    for MODULE in ${modules}/*; do
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

    # sources are located in `tex/texmf-context`
    cd $out/share/tex/texmf-context
  '';

  postPatch = ''
    # patch done, make read-only
    chmod -w $out/share/tex/texmf-context/scripts/context/lua \
      $out/share/tex/texmf-context/tex/context/base/mkiv \
      $out/share/tex/texmf-context/tex/context/base/mkxl \
      $out/share/tex/texmf-context/tex/generic/context/luatex
  '';
};

in
runCommand "context-minimals-${ctx-base.version}" {
  src = ctx-base;
  buildInputs = [ ctx-base ] ++ fonts;
  nativeBuildInputs = [ makeWrapper ];
} (''
  # symlink original sources
  mkdir -p $out/share/tex
  ln -t $out/share/tex -s $src/share/tex/*

  # wrap `tex/texmf-system/bin` -> `bin`
  for BIN in context mtxrun luametatex luatex; do
    makeWrapper $out/share/tex/texmf-context/bin/$BIN $out/bin/$BIN
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
  if [ -d $out/share/tex/texmf-cache ]; then
    find $out/share/tex/texmf-cache -name 'formats' -type d -exec rm -rf {} +
  fi
'')
