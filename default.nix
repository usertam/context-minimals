{ lib
, stdenv
, pname
, inputs
, version
, src
, libfaketime
, makeWrapper
, xorg
, fonts
, fpath ? lib.makeSearchPath "share/fonts" fonts
}:

stdenv.mkDerivation {
  inherit pname version src;
  buildInputs = fonts;
  nativeBuildInputs = [ makeWrapper ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    # install context to $out/tex/texmf-context
    mkdir -p $out/tex/texmf-context
    cp -a ${inputs.context}/{colors,context,doc,fonts,metapost,scripts,tex,web2c} $out/tex/texmf-context

    # make writable for patch temporary file
    chmod +w $out/tex/texmf-context/scripts/context/lua \
      $out/tex/texmf-context/scripts/context/stubs/mswin \
      $out/tex/texmf-context/scripts/context/stubs/unix \
      $out/tex/texmf-context/scripts/context/stubs/win64 \
      $out/tex/texmf-context/tex/context/base/mkiv \
      $out/tex/texmf-context/tex/context/base/mkxl \
      $out/tex/texmf-context/tex/generic/context/luatex

    # apply patches
    patch -Np1 -d $out/tex/texmf-context -i ${./0001-remove-modification-detections.patch}

    # patch done, make read-only
    chmod -w $out/tex/texmf-context/scripts/context/lua \
      $out/tex/texmf-context/scripts/context/stubs/mswin \
      $out/tex/texmf-context/scripts/context/stubs/unix \
      $out/tex/texmf-context/scripts/context/stubs/win64 \
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
    install -Dm755 -t $out/tex/texmf-system/bin ${inputs.binaries}/${stdenv.hostPlatform.system}/{luametatex,luatex}

    '' + lib.optionalString stdenv.isLinux ''
    patchelf \
      --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      --set-rpath "${ lib.makeLibraryPath [ stdenv.cc.libc ] }" \
      $out/tex/texmf-system/bin/{luametatex,luatex}

    '' + ''
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

    # make cache deterministic
    export LD_PRELOAD=${libfaketime}/lib/libfaketime.so.1
    export FAKETIME="1970-01-01 00:00:00"

    # generate file databases
    $out/tex/texmf-system/bin/mtxrun --generate
    $out/tex/texmf-system/bin/luatex --luaonly $out/tex/texmf-system/bin/mtxrun.lua --generate

    # generate necessary font cache
    export OSFONTDIR=${fpath}
    $out/tex/texmf-system/bin/mtxrun --script font --reload

    runHook postFixup
  '';
}
