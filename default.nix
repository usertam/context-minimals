{ stdenvNoCC
, inputs
, src
, runCommand
, luametatex
, luatex
, makeWrapper
, xorg
, fonts
, fpath ? []
, fcache ? []
}:

stdenvNoCC.mkDerivation {
  inherit src;
  pname = "context-minimals";
  version = builtins.readFile (runCommand "version" {} ''
    grep 'newcontextversion' ${inputs.context}/tex/context/base/mkxl/cont-new.mkxl \
      | cut -d{ -f2 | cut -d} -f1 | tr -d "\n" > $out
  '');

  buildInputs = [ luametatex luatex ] ++ fonts;
  nativeBuildInputs = [ makeWrapper ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    # install context source to $out/tex/texmf-context
    mkdir -p $out/tex/texmf-context
    cp -a ${inputs.context}/{colors,context,doc,fonts,metapost,tex,web2c} $out/tex/texmf-context

    # for scripts in source, avoid copying the stubs
    mkdir -p $out/tex/texmf-context/scripts/context
    cp -a ${inputs.context}/scripts/context/{lua,perl,ruby} $out/tex/texmf-context/scripts/context

    # make writable for patch temporary file
    chmod +w $out/tex/texmf-context/scripts/context/lua \
      $out/tex/texmf-context/tex/context/base/mkiv \
      $out/tex/texmf-context/tex/context/base/mkxl \
      $out/tex/texmf-context/tex/generic/context/luatex

    # apply patches
    for PATCH in $src/patches/*.patch; do
      patch -Np1 -d $out/tex/texmf-context -i $PATCH
    done

    # patch done, make read-only
    chmod -w $out/tex/texmf-context/scripts/context/lua \
      $out/tex/texmf-context/tex/context/base/mkiv \
      $out/tex/texmf-context/tex/context/base/mkxl \
      $out/tex/texmf-context/tex/generic/context/luatex

    # install modules to populate $out/modules
    cp -a ${inputs.modules} $out/modules

    # populate $out/tex/texmf
    mkdir -p $out/tex/texmf/web2c
    ln -s $out/tex/texmf-context/web2c/context.cnf $out/tex/texmf/web2c/texmf.cnf
    ln -s $out/tex/texmf-context/web2c/contextcnf.lua $out/tex/texmf/web2c/texmfcnf.lua

    # install luametatex and luatex to $out/tex/texmf-system/bin
    install -Dm755 -t $out/tex/texmf-system/bin ${luametatex}/bin/luametatex ${luatex}/bin/luatex

    # populate $out/tex/texmf-system/bin
    ln -s $out/tex/{texmf-context/scripts/context/lua,texmf-system/bin}/context.lua
    ln -s $out/tex/{texmf-context/scripts/context/lua,texmf-system/bin}/mtxrun.lua
    ln -s $out/tex/texmf-system/bin/{luametatex,mtxrun}
    ln -s $out/tex/texmf-system/bin/{luametatex,context}

    # populate $out/tex/texmf-modules
    mkdir -p $out/tex/texmf-modules
    for DIR in $out/modules/*; do
      ${xorg.lndir}/bin/lndir -silent $DIR $out/tex/texmf-modules
    done
    find -L $out/tex/texmf-modules -maxdepth 1 -type f -delete

    # wrap $out/tex/texmf-system/bin/<exe> -> $out/bin/<exe>
    for FILE in $(find $out/tex/texmf-system/bin -type f -executable -follow); do
      makeWrapper $FILE $out/bin/''${FILE##*/}
    done
  '';

  fixupPhase = ''
    runHook preFixup

    # generate file databases
    $out/tex/texmf-system/bin/mtxrun --generate
    $out/tex/texmf-system/bin/luatex --luaonly $out/tex/texmf-system/bin/mtxrun.lua --generate

    # generate font databases
    export OSFONTDIR=${builtins.concatStringsSep ":" ((map (f: f + "/share/fonts") fonts) ++ fpath)}
    $out/tex/texmf-system/bin/mtxrun --script font --reload

    '' + builtins.concatStringsSep "\n" (map (font: ''
    # generate font cache payload
    cat <<'EOF' > "${font}.tex"
    \definefontfamily[main][serif][${font}]
    \setupbodyfont[main]
    \starttext
    Normal {\bf Bold} {\it Italic} {\sl Slanted} {\bi Bold Italic} {\bs Bold Slanted} {\sc Small Capitals}
    \stoptext
    EOF

    # build font cache by forcing cache misses
    $out/bin/context "${font}.tex"

    '') fcache) + ''
    # delete the formats from forcing cache misses, keep cache deterministic
    find $out/tex/texmf-cache -name 'formats' -type d -exec rm -rf {} +

    runHook postFixup
  '';
}
