--
--------------------------------------------------------------------------------
--         FILE:  mtx-transliterate.lua
--        USAGE:  mtxrun --script transliterate [--mode=mode] --s="string"
--  DESCRIPTION:  context script interface for the Transliterator module
-- REQUIREMENTS:  latest ConTeXt MkIV
--       AUTHOR:  Philipp Gesang (Phg), <gesang@stud.uni-heidelberg.de>
--      CREATED:  2011-06-11T16:14:16+0200
--------------------------------------------------------------------------------
--

environment.loadluafile("transliterator")

local translit = thirddata.translit

translit.__script     = true
scripts               = scripts or { }
scripts.transliterate = { }
local ea              = environment.argument

local helpinfo = [[
===============================================================
    The Transliterator module, command line interface.
    © 2010--2011 Philipp Gesang. License: 2-clause BSD.
    Home: <https://bitbucket.org/phg/transliterator/>
===============================================================

USAGE:

    mtxrun --script transliterate [--mode=mode] --s="target"

    Where “target” is the target string to be transliterated.
    Optionally, a transliteration mode can be specified (see
    the respective descriptions in transliterator.pdf). The
    “mode” defaults to “ru_old”.

===============================================================
]]

local application = logs.application {
    name     = "mtx-transliterate",
    banner   = "The Transliterator for ConTeXt, hg-rev 38+",
    helpinfo = helpinfo,
}

scripts.transliterate.input = ea("s")
scripts.transliterate.out   = function (sin, sout)
    if ea("silent") then
        io.write(sout)
    else
        io.write(string.format("\n“%s” -> “%s”\n", sin, sout))
    end
end

if scripts.transliterate.input then
    local mode = ea("mode") or "ru_old"
    scripts.transliterate.out(
        scripts.transliterate.input,
        translit.transliterate(mode, ea("s"))
    )
else
    application.help()
end

