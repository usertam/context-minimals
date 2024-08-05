{ stdenv
, stdenvNoCC
, context
, context-fonts
, context-modules
, luametatex
, luatex
, makeWrapper
, poppler_utils
, fonts ? []
, fpath ? []
, fcache ? []
}:

let
ctx-base = stdenvNoCC.mkDerivation (attrsFinal: let
  inherit (attrsFinal.passthru) srcs';
in {
  pname = "context-minimals-base";
  version = "2024.07.31 18:56";

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

  src = ctx-base;

  buildInputs = [ attrsFinal.src ] ++ fonts;
  nativeBuildInputs = [ makeWrapper ];

  buildPhase = ''
    runHook preBuild

    # Symlink built base's /share/tex
    mkdir -p $out/share/tex
    ln -t $out/share/tex -s $src/share/tex/*

    # Wrap binaries in texmf-system to /bin
    for BIN in context mtxrun luametatex luatex; do
      makeWrapper $out/share/tex/texmf-context/bin/$BIN $out/bin/$BIN \
        --set TEXMFCACHE $TEXMFCACHE
    done

    # Set up texmf-cache
    export TEXMFCACHE=$out/share/tex/texmf-cache
    mkdir -p $TEXMFCACHE

    # Generate file databases
    $out/bin/mtxrun --generate
    $out/bin/luatex --luaonly $out/share/tex/texmf-context/bin/mtxrun.lua --generate

    # Generate font databases
    export OSFONTDIR=${builtins.concatStringsSep ":" ((map (f: f + "/share/fonts") fonts) ++ fpath)}
    $out/bin/mtxrun --script font --reload

  '' + builtins.concatStringsSep "\n" (map (font: ''
    (
      mkdir -p $TMPDIR/cache
      cd $TMPDIR/cache

      # Build font cache by forcing cache misses
      echo "Writing ${font}.tex..."
      cat <<'EOF' > "${font}.tex"
      \definedfont[name:${font}*default]
      Normal {\bf Bold} {\it Italic} {\sl Slanted} {\bi Bold Italic} {\bs Bold Slanted} {\sc Small Capitals}
      EOF
      echo "Compiling ${font}.tex..."
      $out/bin/context "${font}.tex"
    )
  '') fcache) + ''

    runHook postBuild

    # Delete formats from cache, keep it deterministic
    find $out/share/tex/texmf-cache -name 'formats' -type d -exec rm -rf {} +
  '';

  doCheck = true;
  nativeCheckInputs = [ poppler_utils ];

  checkPhase = ''
    runHook preCheck

    mkdir -p $TMPDIR/test-1
    cd $TMPDIR/test-1

    echo "Writing test-1.tex..."
    cat <<EOF > test-1.tex
    \starttext
    \input khatt-en
    \stoptext
    EOF
    echo "Compiling test-1.tex..."
    $out/bin/context test-1.tex 2>&1 | tail -10
    echo "Checking if result test-1.pdf exists..."
    if ! [ -f test-1.pdf ]; then
      echo "Fail: test-1.pdf not found."
      exit 1
    fi
    echo "Checking text in test-1.pdf..."
    if ! pdftotext test-1.pdf - | grep -q 'sharpen the edge of your pen'; then
      echo "Fail: test-1.pdf does not contain expected text."
      echo "  expected: sharpen the edge of your pen"
      echo "  got:"
      pdftotext test-1.pdf - | sed 's/^/    /g'
      exit 1
    fi
    echo "Pass: test-1.pdf."

    runHook postCheck

    # Delete formats from cache, keep it deterministic
    find $out/share/tex/texmf-cache -name 'formats' -type d -exec rm -rf {} +
  '';
})
