#!/usr/bin/env texlua
--------------------------------------------------------------------------------
--         FILE:  mtx-rst.lua
--        USAGE:  mtxrun --script rst --if=input.rst --of=output.tex 
--  DESCRIPTION:  context script interface for the reStructuredText module
-- REQUIREMENTS:  latest ConTeXt MkIV
--       AUTHOR:  Philipp Gesang (Phg), <megas.kapaneus@gmail.com>
--      CHANGED:  2013-03-27 00:25:32+0100
--------------------------------------------------------------------------------
--

scripts     = scripts or { }
scripts.rst = { }

environment.loadluafile("rst_parser")

local ea = environment.argument

local helpinfo = [[
===============================================================
    The reStructuredText module, command line interface.
    © 2010--2013 Philipp Gesang. License: 2-clause BSD.
    Home: <https://bitbucket.org/phg/context-rst/>
===============================================================

USAGE:

    mtxrun --script rst --if=input.rst --of=output.tex

Mandatory arguments:

    “infile.rst” is your input file containing reST markup.
    “outfile.tex” is the target file that the TeX-code will be
                  written to.

Optional arguments:
    --et=bool   “expandtab”, should tab chars (“\t”, “\v”) be
                converted to spaces?
    --sw=int    “shiftwidth”, tab stop modulo factor.

===============================================================
]]

local application = logs.application {
    name     = "mtx-rst",
    banner   = "The reStructuredText module for ConTeXt, hg-rev 125+",
    helpinfo = helpinfo,
}

scripts.rst.input  = ea("if")
scripts.rst.output = ea("of")

if scripts.rst.input and scripts.rst.output then
    local expandtab  = ea("et") == "true" and true
    local shiftwidth = ea("sw")
    local debug      = ea("debug") == "true"
    if expandtab  then thirddata.rst.expandtab  = true end
    if shiftwdith then thirddata.rst.shiftwidth = tonumber(shiftwidth) end
    if debug      then thirddata.rst_helpers.rst_debug = debug end
    thirddata.rst.standalone(scripts.rst.input, scripts.rst.output)
else
    application.help()
end

