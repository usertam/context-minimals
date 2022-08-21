#!/usr/bin/env texlua
--------------------------------------------------------------------------------
--         FILE:  rst_parser.lua
--        USAGE:  refer to doc/documentation.rst
--  DESCRIPTION:  https://bitbucket.org/phg/context-rst/overview
--       AUTHOR:  Philipp Gesang (Phg), <phg42.2a@gmail.com>
--      VERSION:  0.6c
--      CHANGED:  2014-03-02 19:20:17+0100
--------------------------------------------------------------------------------
--

local usage_info = [[
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                           rstConTeXt
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Functionality has been moved, the reST converter can now be
accessed via mtxrun:

    $mtxrun --script rst

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
]]

local main = function ()
    io.write("\n"..usage_info.."\n")
    return -1
end

thirddata             = thirddata or { }
thirddata.rst         = { }
thirddata.rst_helpers = { rst_debug = false }

if context then
    if environment.argument "debug" == true then
        thirddata.rst_helpers.rst_debug = true
    end
elseif not scripts then
    return main()
end

environment.loadluafile"rst_helpers"
environment.loadluafile"rst_directives"
environment.loadluafile"rst_setups"
environment.loadluafile"rst_context"

local rst                   = thirddata.rst
local helpers               = thirddata.rst_helpers
local optional_setups       = thirddata.rst_setups

rst.strip_BOM               = true
rst.expandtab               = true
rst.shiftwidth              = 4
rst.crlf                    = true

local utf                   = unicode.utf8

local ioopen                = io.open
local iowrite               = io.write
local select                = select
local stringfind            = string.find
local stringformat          = string.format
local stringgsub            = string.gsub
local stringlen             = string.len
local stringmatch           = string.match
local stringstrip           = string.strip
local stringsub             = string.sub
local tableconcat           = table.concat
local utflen                = utf.len

local context               = context

local warn
do
    local ndebug = 0
    warn = function(str, ...)
        if not helpers.rst_debug then return false end
        ndebug = ndebug + 1
        local slen = #str + 3
        --str = "*["..str.."]"
        str = stringformat("*[%4d][%s]", ndebug, str)
        for i=1, select ("#", ...) do
            local current = select (i, ...)
            if 80 - i * 8 - slen < 0 then
                local indent = ""
                for i=1, slen do
                    indent = indent .. " "
                end
                str = str .. "\n" .. indent
            end
            str = str .. stringformat(" |%6s", stringstrip(tostring(current)))
        end
        iowrite(str .. " |\n")
        return 0
    end
end

local C,   Cb, Cc, Cg,
      Cmt, Cp, Cs, Ct
    = lpeg.C,   lpeg.Cb, lpeg.Cc, lpeg.Cg,
      lpeg.Cmt, lpeg.Cp, lpeg.Cs, lpeg.Ct

local P, R, S, V, lpegmatch
    = lpeg.P, lpeg.R, lpeg.S, lpeg.V, lpeg.match

local utf = unicode.utf8

local state          = {}
thirddata.rst.state  = state

state.depth          = 0
state.bullets        = {}  -- mapping bullet forms to depth
state.bullets.max    = 0
state.lastbullet     = ""
state.lastbullets    = {}
state.roman_cache    = {}  -- storing roman numerals that were already converted
state.currentindent  = ""  -- used in definition lists and elsewhere
state.previousindent = ""  -- for literal blocks included in paragraphs to restore the paragraph indent
state.currentwidth   = 0   -- table layout
state.currentlayout  = {}  -- table layout
state.previousadorn  = nil -- section underlining and overlining

state.footnotes            = {}
state.footnotes.autonumber = 0
state.footnotes.numbered   = {}
state.footnotes.labeled    = {}
state.footnotes.autolabel  = {}
state.footnotes.symbol     = {}

state.addme                = {}

local valid_adornment
do
    --[[--

        valid_adornment -- This subpattern tests if the string consists
        entirely of one repeated adornment char.

    --]]--
    local first_adornment    = ""
    local adornment_char     = S[[!"#$%&'()*+,-./:;<=>?@[]^_`{|}~]] + P[[\\]]
    local check_first        = Cmt(adornment_char, function(_,_, first)
                                       first_adornment = first
                                       return true
                                   end)
    local check_other        = Cmt(adornment_char, function(_,_, char)
                                       return char == first_adornment
                                   end)
    valid_adornment          = check_first * check_other^1 * -P(1)
end

local enclosed_mapping = {
    ["'"] = "'",
    ['"'] = '"',
    ["("] = ")",
    ["["] = "]",
    ["{"] = "}",
    ["<"] = ">",
}

local utfchar = P{ -- from l-lpeg.lua, modified to use as grammar
    [1] = "utfchar",
    utf8byte      = R("\128\191"),
    utf8one       = R("\000\127"),
    utf8two       = R("\194\223") * V"utf8byte",
    utf8three     = R("\224\239") * V"utf8byte" * V"utf8byte",
    utf8four      = R("\240\244") * V"utf8byte" * V"utf8byte" * V"utf8byte",
    utfchar       = V"utf8one" + V"utf8two" + V"utf8three" + V"utf8four",
}



local rst_parser = P {
    [1] = V"document",

    document = V"blank_line"^0 * Cs(V"block"^1),

--------------------------------------------------------------------------------
-- Blocks
--------------------------------------------------------------------------------

    block = V"explicit_markup"
          + Cs(V"section")     / rst.escape
          + V"target_block"
          + V"literal_block"
          + Cs(V"list")        / rst.escape
          + Cs(V"line_block")  / rst.escape
          + Cs(V"table_block") / rst.escape
          + V"transition"    --/ rst.escape
          + V"comment_block"
          + Cs(V"block_quote") / rst.escape
          + Cs(V"paragraph")   / rst.escape
          ,

--------------------------------------------------------------------------------
-- Explicit markup block
--------------------------------------------------------------------------------

    explicit_markup_start = V"double_dot" * V"whitespace",

    explicit_markup = V"footnote_block"
                    + V"directive_block"
                    + V"substitution_definition"
                    ,

    explicit_markup_block = V"explicit_markup"^1
                          ,

--------------------------------------------------------------------------------
-- Directives block
--------------------------------------------------------------------------------

    directive_block = V"directive"
                    --* (V"blank_line"^-1 * V"directive")^0
                    * V"end_block"
                    ,

    directive = V"explicit_markup_start"
              * C(((V"escaped_colon" + (1 - V"colon" - V"eol"))
                 - V"substitution_text")^1) --> directive name
              * V"double_colon"
              * Ct(V"directive_block_multi" + V"directive_block_single") --> content
              / rst.directive
              ,

    directive_block_multi = Cg((1 - V"eol")^0, "name") -- name
                          * V"eol"
                          * V"blank_line"^0 -- how many empty lines are permitted?
                          * V"directive_indented_lines"
                          ,

    directive_block_single = V"whitespace"^1 * Ct(C((1 - V"eol")^1)) * V"eol",

--------------------------------------------------------------------------------
-- Substitution definition block
--------------------------------------------------------------------------------

    substitution_definition = V"explicit_markup_start"
                            * V"substitution_text"
                            * V"whitespace"^1
                            * C((1 - V"colon" - V"space" - V"eol")^1) -- directive
                            * V"double_colon"
                            * Ct(V"data_directive_block")
                            * V"end_block"^-1
                            / rst.substitution_definition
                            ,

    substitution_text = V"bar"
                      * C((1 - V"bar" - V"eol")^1)
                      * V"bar"
                      ,

    data_directive_block = V"data_directive_block_multi"
                         + V"data_directive_block_single"
                         ,
    data_directive_block_single = Ct(C((1 - V"eol")^0)) * V"eol",

    data_directive_block_multi  = Cg((1 - V"eol")^0, "first") * V"eol"
                                * V"directive_indented_lines"
                                ,

    directive_indented_lines = Ct(V"directive_indented_first"
                                * V"directive_indented_other"^0)
                             * (V"blank_line"^1 * Ct(V"directive_indented_other"^1))^0
                             ,


    directive_indented_first = Cmt(V"space"^1, function(s,i,indent)
                                    warn("sub-i", #indent, i)
                                    state.currentindent = indent
                                    return true
                                end)
                             * C((1 - V"eol")^1) * V"eol"
                             ,

    directive_indented_other = Cmt(V"space"^1, function(s,i,indent)
                                    warn("sub-m",
                                      #state.currentindent <= #indent,
                                      #indent,
                                      #state.currentindent,
                                      i)
                                    return #state.currentindent <= #indent
                                end)
                             * C((1 - V"eol")^1) * V"eol"
                             ,


--------------------------------------------------------------------------------
-- Explicit markup footnote block
--------------------------------------------------------------------------------

    footnote_block = V"footnote"^1 * V"end_block",

    footnote = V"explicit_markup_start"
             * (V"footnote_marker" + V"citation_reference_label")
             * C(V"footnote_content")
             * (V"blank_line" - V"end_block")^-1
             / rst.footnote
             ,

    footnote_marker = V"lsquare" * C(V"footnote_label") * V"rsquare" * V"whitespace"^0
                    ,

    citation_reference_label = V"lsquare" * C(V"letter" * (1 - V"rsquare")^1) * V"rsquare" * V"whitespace"^0,

    footnote_label = V"digit"^1
                   + (V"gartenzaun" * V"letter"^1)
                   + V"gartenzaun"
                   + V"asterisk"
                   ,

    footnote_content = V"footnote_long" -- single line
                     + V"footnote_simple"
                     ,

    footnote_simple = (1 - V"eol")^1 * V"eol"
                    ,

    footnote_long = (1 - V"eol")^1 * V"eol"
                  * V"footnote_body"
                  ,

    footnote_body = V"fn_body_first"
                  * (V"fn_body_other" + V"fn_body_other_block")^0
                  ,

    fn_body_first = Cmt(V"space"^1, function(s, i, indent)
                        warn("fn-in", true, #indent)
                        state.currentindent = indent
                        return true
                    end)
                  * (1 - V"eol")^1 * V"eol"
                  ,

    fn_matchindent = Cmt(V"space"^1, function(s, i, indent)
                        local tc = state.currentindent
                        warn("fn-ma", tc == indent, #tc, #indent, i)
                        return tc == indent
                    end)
                   ,

    fn_body_other = V"fn_body_other_regular"
                  * (V"blank_line" * V"fn_body_other_regular")^0
                  ,

    fn_body_other_regular = V"fn_matchindent"
                          * (1 - V"eol")^1 * V"eol"
                          ,

    -- TODO find a way to get those to work in footnotes!
    fn_body_other_block = V"line_block"
                        + V"table_block"
                        + V"transition"
                        + V"block_quote"
                        + V"list"
                        ,

--------------------------------------------------------------------------------
-- Table block
--------------------------------------------------------------------------------

    table_block = V"simple_table"
                + V"grid_table"
                ,

--------------------------------------------------------------------------------
-- Simple tables
--------------------------------------------------------------------------------

    simple_table = Ct(V"st_first_row"
                    * V"st_other_rows")
                 * V"end_block"
                 / function (tab)
                     return rst.simple_table(helpers.table.simple(tab))
                 end
                 ,

    st_first_row = V"st_setindent"
                 * C(V"st_setlayout")
                 * V"space"^0
                 * V"eol"
                 ,

    st_setindent = Cmt(V"space"^0, function(s, i, indent)
                        warn("sta-i", "true",  #indent, "set", i)
                        state.currentindent = indent
                        return true
                    end)
                 ,

    st_matchindent = Cmt(V"space"^0, function(s, i, indent)
                          warn("sta-m", state.currentindent == indent, #indent, #state.currentindent, i)
                          return state.currentindent == indent
                      end)
                   ,

    st_setlayout = Cmt((V"equals"^1) * (V"spaces" * V"equals"^1)^1, function(s, i, layout)
                        local tc = state.currentlayout
                        warn("sta-l", #layout, "set", "", i)
                        tc.raw = layout
                        tc.bounds = helpers.get_st_boundaries(layout)
                        return true
                    end)
                 ,

    st_other_rows = (V"st_content"^1 * V"st_separator")^1,

    st_content = V"blank_line"^-1
               * C(V"st_matchlayout"),

    st_matchlayout = -#V"st_separator" * Cmt((1 - V"eol")^1, function (s, i, content)
                        -- Don't check for matching indent but if the rest is
                        -- fine then the line should be sane. This allows
                        -- cells starting with spaces.
                        content = stringsub (content, #state.currentindent)
                        local tcb = state.currentlayout.bounds
                        local n = 1
                        local spaces_only = P" "^1
                        while n < #tcb.slices do
                            local from = tcb.slices[n]  .stop
                            local to   = tcb.slices[n+1].start
                            local between = lpegmatch (spaces_only, content, from)
                            if not between then -- Cell spanning more than one row.
                                -- pass
                                warn("sta-c", "span", from, to, i)
                            elseif not (between >= to) then
                                warn("sta-c", "false", from, to, i)
                                return false
                            end
                            n = n + 1
                        end
                        warn("sta-c", "true", #tcb.slices, "", i)
                        return true
                     end)
                     * V"eol"
                   ,

    st_separator = V"st_matchindent"
                 * C(V"st_normal_sep" + V"st_colspan_sep")
                 * V"eol"
                 ,

    st_normal_sep = Cmt((V"equals"^1) * (V"spaces" * V"equals"^1)^1, function(s, i, layout)
                        warn("sta-s", state.currentlayout.raw == layout, #layout, #state.currentlayout.raw, i)
                        return state.currentlayout.raw == layout
                    end)
                  ,

    st_colspan_sep = Cmt(V"dash"^1 * (V"spaces" * V"dash"^1)^0, function(s, i, layout)
                         local tcb = state.currentlayout.bounds
                         local this = helpers.get_st_boundaries (layout)
                         local start_valid = false
                         for start, _ in next, this.starts do
                             if tcb.starts[start] then
                                 start_valid = true
                                 local stop_valid = false
                                 for stop, _ in next, this.stops do
                                     if tcb.stops[stop] then -- bingo
                                         stop_valid = true
                                     end
                                 end
                                 if not stop_valid then
                                     warn("sta-x", stop_valid, #layout, #state.currentlayout.raw, i)
                                     return false
                                 end
                             end
                         end
                         warn("sta-x", start_valid, #layout, #state.currentlayout.raw, i)
                         return start_valid
                     end)
                   ,


--------------------------------------------------------------------------------
-- Grid tables
--------------------------------------------------------------------------------

    grid_table = Ct(V"gt_first_row"
                  * V"gt_other_rows")
               * V"blank_line"^1
               / function(tab)
                   return rst.grid_table(helpers.table.create(tab))
               end
               ,

    gt_first_row = V"gt_setindent"
                 * C(V"gt_sethorizontal")
                 * V"eol"
                 ,

    gt_setindent = Cmt(V"space"^0, function(s, i, indent)
                        warn("tab-i", true, #indent, "set", i)
                        state.currentindent = indent
                        return true
                    end)
                 ,

    gt_layoutmarkers = V"table_intersection" + V"table_hline" + V"table_header_hline",

    gt_sethorizontal = Cmt(V"gt_layoutmarkers"^3, function (s, i, width)
                             warn("tab-h", "width", "true", #width, "set", i)
                             state.currentwidth = #width
                             return true
                         end)
                     ,

    gt_other_rows = V"gt_head"^-1
                  * V"gt_body"
                  ,

    gt_matchindent = Cmt(V"space"^0, function (s, i, this)
        local matchme = state.currentindent
        warn("tab-m", "indent", #this == #matchme, #this, #matchme, i)
        return #this == #matchme
    end)
    ,


    gt_cell = (V"gt_content_cell" + V"gt_line_cell")
    * (V"table_intersection" + V"table_vline")
    ,

    gt_content_cell = ((1 - V"table_vline" - V"table_intersection" - V"eol")^1),

    gt_line_cell = V"table_hline"^1,

    gt_contentrow = V"gt_matchindent"
                   * C((V"table_intersection" + V"table_vline")
                     * V"gt_cell"^1)
                   * V"whitespace"^-1 * V"eol"
                  ,

    gt_body = ((V"gt_contentrow" - V"gt_bodysep")^1 * V"gt_bodysep")^1,

    gt_bodysep = V"gt_matchindent"
               * C(Cmt(V"table_intersection"
                     * (V"table_hline"^1 * V"table_intersection")^1, function(s, i, separator)
                          local matchme = state.currentwidth
                          warn("tab-m", "body", #separator == matchme, #separator, matchme, i)
                          return #separator == matchme
                      end))
               * V"whitespace"^-1 * V"eol"
               ,

    gt_head = V"gt_contentrow"^1
            * V"gt_headsep"
            ,

    gt_headsep = V"gt_matchindent"
               * C(Cmt(V"table_intersection"
                    * (V"table_header_hline"^1 * V"table_intersection")^1, function(s, i, separator)
                          local matchme = state.currentwidth
                          warn("tab-s", "head", #separator == matchme, #separator, matchme, i)
                          return #separator == matchme
                      end))
               * V"whitespace"^-1 * V"eol"
               ,


--------------------------------------------------------------------------------
-- Block quotes
--------------------------------------------------------------------------------

    block_quote = Ct(Cs(V"block_quote_first"
                   * V"block_quote_other"^0
                   * (V"blank_line" * V"block_quote_other"^1)^0)
                   * (V"blank_line"
                   *  Cs(V"block_quote_attri"))^-1)
                * V"end_block"
                / rst.block_quote
                ,

    block_quote_first = Cmt(V"space"^1, function (s, i, indent)
                             warn("bkq-i", #indent, "", indent, "", i)
                             state.currentindent = indent
                             return true
                         end) / ""
                      * -V"attrib_dash"
                      * (1 - V"eol")^1
                      * V"eol"
                      ,

    block_quote_other = Cmt(V"space"^1, function (s, i, indent)
                            warn("bkq-m", #indent, #state.currentindent,
                                           indent,  state.currentindent, i)
                            return state.currentindent == indent
                        end) / ""
                      * -V"attrib_dash"
                      * (1 - V"eol")^1
                      * V"eol"
                      ,

    block_quote_attri = V"block_quote_attri_first"
                      * V"block_quote_attri_other"^0,

    block_quote_attri_first = Cmt(V"space"^1 * V"attrib_dash" * V"space", function (s, i, indent)
                                   local t = state
                                   warn("bqa-i", utflen(indent), #t.currentindent,
                                                 indent,         t.currentindent, i)
                                   local ret = stringmatch (indent, " *") == t.currentindent
                                   t.currentindent = ret and indent or t.currentindent
                                   return ret
                               end) / ""
                            * (1 - V"eol")^1
                            * V"eol"
                            ,

    block_quote_attri_other = Cmt(V"space"^1, function (s, i, indent)
                                  warn("bqa-m", #indent, utflen(state.currentindent),
                                                 indent,  state.currentindent, i)
                                  return utflen(state.currentindent) == #indent
                              end) / ""
                            * (1 - V"eol")^1
                            * V"eol"
                            ,

--------------------------------------------------------------------------------
-- Line blocks
--------------------------------------------------------------------------------

    line_block = Cs(V"line_block_first"
                  * (V"line_block_other"
                   + V"line_block_empty")^1)
               --* V"blank_line"
               * V"end_block"
               / rst.line_block
               ,

    line_block_marker = V"space"^0 * V"bar" * V"space",

    line_block_empty_marker = V"space"^0 * V"bar" * V"space"^0 * V"eol",


    line_block_first = Cmt(V"line_block_marker", function(s, i, marker)
                            warn("lbk-i", #marker, "", marker, "", i)
                            state.currentindent = marker
                            return true
                        end) / ""
                     * V"line_block_line"
                     ,

    line_block_empty = Cmt(V"line_block_empty_marker", function(s, i, marker)
                            warn("lbk-e", #marker, #state.currentindent, marker, state.currentindent, i)
                            marker = stringgsub (marker, "|.*", "| ")
                            return state.currentindent == marker
                        end) / ""
                     / rst.line_block_empty
                     ,

    line_block_other = Cmt(V"line_block_marker", function(s, i, marker)
                            warn("lbk-m", #marker, #state.currentindent, marker, state.currentindent, i)
                            return state.currentindent == marker
                        end) / ""
                     * V"line_block_line"
                     ,

    line_block_line = Cs((1 - V"eol")^1
                       * V"line_block_cont"^0
                       * V"eol")
                    / rst.line_block_line
                    ,

    line_block_cont = (V"eol" - V"line_block_marker")
                    * Cmt(V"space"^1, function(s, i, spaces)
                            warn("lbk-c", #spaces, #state.currentindent, spaces, state.currentindent, i)
                            return #spaces >= #state.currentindent
                        end) / ""
                    * (1 - V"eol")^1
                    ,

--------------------------------------------------------------------------------
-- Literal blocks
--------------------------------------------------------------------------------

    literal_block = V"literal_block_marker"
                    * Cs(V"literal_block_lines")
                    * V"end_block"
                    / rst.literal_block,

    literal_block_marker = V"double_colon" * V"whitespace"^0 * V"eol" * V"blank_line",

    literal_block_lines = V"unquoted_literal_block_lines"
                        + V"quoted_literal_block_lines"
                        ,

    unquoted_literal_block_lines = V"literal_block_first"
                                 * (V"blank_line"^-1 * V"literal_block_other")^0
                                 ,

    quoted_literal_block_lines =  V"quoted_literal_block_first"
                               * V"quoted_literal_block_other"^0 -- no blank lines allowed
                               ,

    literal_block_first = Cmt(V"space"^1, function (s, i, indent)
                        warn("lbk-f", #indent, "", "", i)
                        if not indent or
                            indent == "" then
                            return false
                        end
                        if state.currentindent and #state.currentindent < #indent then
                            state.currentindent = state.currentindent .. " "
                            return true
                        else
                            state.currentindent = " "
                            return true
                        end
                    end)
                   * V"rest_of_line"
                   * V"eol",

    literal_block_other = Cmt(V"space"^1, function (s, i, indent)
                        warn("lbk-m",
                             #indent,
                             #state.currentindent,
                             #indent >= #state.currentindent,
                             i)
                        return #indent >= #state.currentindent
                    end)
                   * V"rest_of_line"
                   * V"eol"
                   ,

    quoted_literal_block_first = Cmt(V"adornment_char", function (s, i, indent)
                        warn("qlb-f", #indent, indent, "", i)
                        if not indent    or
                            indent == "" then
                            return false
                        end
                        state.currentindent = indent
                        return true
                    end)
                   * V"rest_of_line"
                   * V"eol"
                   ,

    quoted_literal_block_other = Cmt(V"adornment_char", function (s, i, indent)
                        warn("qlb-m",
                             #indent,
                             #state.currentindent,
                             #indent >= #state.currentindent,
                             i)
                        return #indent >= #state.currentindent
                    end)
                   * V"rest_of_line"
                   * V"eol",

--------------------------------------------------------------------------------
-- Lists
--------------------------------------------------------------------------------

    list = (V"option_list"
          + V"bullet_list"
          + V"definition_list"
          + V"field_list")
         - V"explicit_markup_start"
         ,

--------------------------------------------------------------------------------
-- Option lists
--------------------------------------------------------------------------------

    option_list = Cs((V"option_list_item"
                   * V"blank_line"^-1)^1)
                /rst.option_list,

    option_list_item = Ct(C(V"option_group")
                        * Cs(V"option_description"))
                     / rst.option_item,

    option_description = V"option_desc_next"
                       + V"option_desc_more"
                       + V"option_desc_single",

    option_desc_single = V"space"^2
                       --* V"rest_of_line"
                       * (1 - V"eol")^1
                       * V"eol",

    option_desc_more = V"space"^2
                     * (1 - V"eol")^1
                     * V"eol"
                     * V"indented_lines"
                     * (V"blank_line" * V"indented_lines")^0,

    option_desc_next = V"eol"
                     * V"indented_lines"
                     * (V"blank_line" * V"indented_lines")^0,

    option_group = V"option"
                 * (V"comma" * V"space" * V"option")^0,

    option = (V"option_posixlong"
            + V"option_posixshort"
            + V"option_dos_vms")
            * V"option_arg"^-1,

    option_arg = (V"equals" + V"space")
               * ((V"letter" * (V"letter" + V"digit")^1)
                + (V"angle_left" * (1 - V"angle_right")^1 * V"angle_right")),

    option_posixshort = V"dash" * (V"letter" + V"digit"),

    option_posixlong = V"double_dash"
                     * V"letter"
                     * (V"letter" + V"digit" + V"dash")^1,

    option_dos_vms = V"slash"
                   * V"letter"^1,

--------------------------------------------------------------------------------
-- Field lists (for bibliographies etc.)
--------------------------------------------------------------------------------

    field_list = Cs(V"field"
                  * (V"blank_line"^-1 * V"field")^0)
               * V"end_block"
               / rst.field_list,

    field = Ct(V"field_marker"
             * V"whitespace"
             * V"field_body")
          / rst.field,

    field_marker = V"colon"
                 * C(V"field_name")
                 * V"colon",

    field_name = (V"escaped_colon" + (1 - V"colon"))^1,

    field_body = V"field_single" + V"field_multi",

    field_single = C((1 -V"eol")^1) * V"eol",

    field_multi = C((1 - V"eol")^0 * V"eol"
                  * V"indented_lines"^-1),

--------------------------------------------------------------------------------
-- Definition lists
--------------------------------------------------------------------------------

    definition_list = Ct((V"definition_item" - V"comment")
                      * (V"blank_line" * V"definition_item")^0)
                    * V"end_block"
                    / rst.deflist
                    ,

    definition_item = Ct(C(V"definition_term")
                       * V"definition_classifiers"
                       * V"eol"
                       * Ct(V"definition_def"))
                    ,

    definition_term = #(1 - V"space" - V"field_marker")
                    * (1 - V"eol" - V"definition_classifier_separator")^1
                    ,

    definition_classifier_separator = V"space" * V"colon" * V"space",

    definition_classifiers = V"definition_classifier"^0,

    definition_classifier = V"definition_classifier_separator"
                          * C((1 - V"eol" - V"definition_classifier_separator")^1)
                          ,

    definition_def = C(V"definition_firstpar") * C(V"definition_par")^0
                   ,

    definition_indent = Cmt(V"space"^1, function(s, i, indent)
                            warn("def-i", #indent, #state.currentindent, indent == state.currentindent, i)
                            state.currentindent = indent
                            return true
                        end),

    definition_firstpar = V"definition_parinit"
                        * (V"definition_parline" - V"blank_line")^0
                        ,

    definition_par = V"blank_line"
                   * (V"definition_parline" - V"blank_line")^1
                   ,

    definition_parinit = V"definition_indent"
                       * (1 - V"eol")^1
                       * V"eol"
                       ,

    definition_parline = V"definition_match"
                       * (1 - V"eol")^1
                       * V"eol"
                       ,

    definition_match = Cmt(V"space"^1, function (s, i, this)
                            warn("def-m", #this, #state.currentindent, this == state.currentindent, i)
                            return this == state.currentindent
                        end),

--------------------------------------------------------------------------------
-- Bullet lists and enumerations
--------------------------------------------------------------------------------

    -- the next rule handles enumerations as well
    bullet_list = V"bullet_init"
                * (V"blank_line"^-1 * (V"bullet_list" + V"bullet_continue"))^0
                * V"bullet_stop"
                * Cmt(Cc(nil), function (s, i)
                    local depth = state.depth
                    warn("close", depth)
                    state.bullets[depth] = nil -- “pop”
                    depth = depth - 1
                    state.lastbullet = state.lastbullets[depth]
                    state.depth = depth
                    return true
                end)
                ,

    bullet_stop = V"end_block" / rst.stopitemize,

    bullet_init = Ct(C(V"bullet_first") * V"bullet_itemrest")
                / rst.bullet_item
                ,

    bullet_first = #Cmt(V"bullet_indent", function (s, i, bullet)
                        local depth      = state.depth
                        local bullets    = state.bullets
                        local oldbullet  = state.bullets[depth]
                        local n_spaces   = lpegmatch(P" "^0, bullet)
                        warn("first",
                            depth,
                            (depth == 0 and n_spaces >= 1) or (depth >  0 and n_spaces >  1),
                            bullet,
                            oldbullet,
                            helpers.list.conversion(bullet))

                        if depth == 0 and n_spaces >= 1 then -- first level
                            depth = 1             -- “push”
                            bullets[1] = bullet
                            state.lastbullet = bullet
                            bullets.max = bullets.max < depth and depth or bullets.max
                            state.depth = depth
                            return true
                        elseif depth > 0 and n_spaces > 1 then    -- sublist (of sublist)^0
                            if n_spaces >= utflen(oldbullet) then
                                state.lastbullets[depth] = state.lastbullet
                                depth = depth + 1
                                bullets[depth] = bullet
                                state.lastbullet = bullet
                                bullets.max = bullets.max < depth and depth or bullets.max
                                state.depth = depth
                                return true
                            end
                        end
                        return false
                    end)
                    * V"bullet_indent"
                    / rst.startitemize
                    ,

    bullet_indent = V"space"^0 * V"bullet_expr" * V"space"^1,

    bullet_cont  = Cmt(V"bullet_indent", function (s, i, bullet)
                        local conversion    = helpers.list.conversion
                        local depth         = state.depth
                        local bullets       = state.bullets
                        local lastbullets   = state.lastbullets
                        warn("conti",
                                depth,
                                bullet == bullets[depth],
                                bullet,
                                bullets[depth],
                                lastbullets[depth],
                                conversion(state.lastbullet),
                                conversion(bullet)
                                )

                        if utflen(bullets[depth]) ~= utflen(bullet) then
                            return false
                        elseif not conversion(bullet) and bullets[depth] == bullet then
                            return true
                        elseif conversion(state.lastbullet) == conversion(bullet) then -- same type
                            local autoconv  = conversion(bullet) == "auto"
                            local greater   = helpers.list.greater  (bullet, state.lastbullet)
                            state.lastbullet = bullet
                            return autoconv or successor or greater
                        end
                    end)
                 ,

    bullet_continue = Ct(C(V"bullet_cont") * V"bullet_itemrest")
                    /rst.bullet_item
                    ,

    bullet_itemrest = C(V"bullet_rest"                               -- first line
                       * ((V"bullet_match" * V"bullet_rest")^0        -- any successive lines
                        * (V"blank_line"
                         * (V"bullet_match" * (V"bullet_rest" - V"bullet_indent"))^1)^0))
                    ,
                         --                                     ^^^^^^^^^^^^^
                         --                                     otherwise matches bullet_first

    bullet_rest = (1 - V"eol")^1 * V"eol",  -- rest of one line

    bullet_next  = V"space"^1
                 ,

    bullet_match = Cmt(V"bullet_next", function (s, i, this)
                         local t = state
                         warn("match",
                                t.depth,
                                stringlen(this) == utflen(t.bullets[t.depth]),
                                utflen(t.bullets[t.depth]), stringlen(this) )
                         return stringlen(this) == utflen(t.bullets[t.depth])
                     end)
                 ,

    bullet_expr = V"bullet_char"
                + (P"(" * V"number_char" * P")")        --- surrounded by parentheses
                +        (V"number_char" * P")")        --- suffixed with right parenthesis
                + (V"number_char" * V"dot") * #V"space" --- suffixed with period
                --[[--
                    below rule is invalid according to the spec:
                    http://docutils.sourceforge.net/docs/ref/rst/restructuredtext.html#enumerated-lists
                --]]--
                --+ (V"number_char" * #V"space")
                ,

    number_char = V"roman_numeral"
                + V"Roman_numeral"
                + P"#"
                + V"digit"^1
                + R"AZ"
                + R"az"
                ,

--------------------------------------------------------------------------------
-- Transitions
--------------------------------------------------------------------------------

    transition_line = C(V"adornment_char"^4),

    transition = V"transition_line" * V"eol"
               * V"end_block"
               / rst.transition
               ,

--------------------------------------------------------------------------------
-- Sectioning
--------------------------------------------------------------------------------

    section_adorn = V"adornment_char"^1,

    section = ((V"section_text" * V"section_once")
             + (V"section_before" * V"section_text" * V"section_after"))
            / rst.section
            * (V"end_block" + V"blank_line")
            ,

    -- The whitespace handling after the overline is necessary because headings
    -- without overline aren't allowed to be indented.
    section_before = C(Cmt(V"section_adorn", function(s,i, adorn)
                          local adorn_matched = lpegmatch (valid_adornment, adorn)
                          state.previousadorn = adorn
                          warn ("sec-f", adorn_matched,
                                stringsub (adorn, 1,2) .. "...", "", i)
                          if adorn_matched then
                              return true
                          end
                          return false
                      end))
                   * V"whitespace"^0
                   * V"eol"
                   * V"whitespace"^0
                   ,

    section_text = C((1 - V"space" - V"eol") * (1 - V"eol")^1) * V"eol",

    section_after = C(Cmt(V"section_adorn", function(s,i, adorn)
                         local tests = false
                         if lpegmatch (valid_adornment, adorn) then
                           tests = true
                         end
                         if state.previousadorn then
                             tests = tests and adorn == state.previousadorn
                         end
                         warn ("sec-a", tests, stringsub (adorn, 1,2) .. "…", "", i)
                         state.previousadorn = nil
                         return tests
                     end))
                    * V"whitespace"^0
                    ,

    section_once = C(Cmt(V"section_adorn", function(s,i, adorn)
                         local tests = false
                         if lpegmatch (valid_adornment, adorn) then
                           tests = true
                         end
                         warn ("sec-o", tests, stringsub (adorn, 1,2) .. "…", "", i)
                         state.previousadorn = nil
                         return tests
                     end))
                    * V"whitespace"^0
                    ,

--------------------------------------------------------------------------------
-- Target Blocks
--------------------------------------------------------------------------------

    tname_normal = C((V"escaped_colon" + 1 - V"colon")^1)
                 * V"colon",

    tname_bareia = C(V"bareia"
                    * (1 - V"eol" - V"bareia")^1
                    * V"bareia")
                 * V"colon",

    target_name = V"double_dot"
                * V"space"
                * V"underscore"
                * (V"tname_bareia" + V"tname_normal"),

    target_firstindent = V"eol" * Cg(V"space"^1, "indent"),

    target_nextindent  = V"eol" * C(V"space"^1),

    target_indentmatch = Cmt(V"target_nextindent" -- I ♡ LPEG!
                           * Cb("indent"), function (s, i, a, b)
                                return a == b
                            end),

    target_link  = ( V"space"^0 * V"target_firstindent"
                 * Ct(C(1 - V"whitespace" - V"eol")^1
                    * (V"target_indentmatch"
                     * C(1 - V"whitespace" - V"eol")^1)^0)
                 * V"eol" * #(1 - V"whitespace" - "eol")) / rst.joinindented
                 + C((1 - V"eol")^1) * V"eol" * #(V"double_dot" + V"double_underscore" + V"eol")
                 + (1 - V"end_block")^0 * Cc(""),

    target       = Ct((V"target_name" * (V"space"^0 * V"eol" * V"target_name")^0)
                 * V"space"^0
                 * V"target_link")
                 / rst.target,

    anonymous_prefix = (V"double_dot" * V"space" * V"double_underscore" * V"colon")
                     + (V"double_underscore")
                     ,

    anonymous_target = V"anonymous_prefix"
                     * V"space"^0
                     * Ct(Cc"" * V"target_link")
                     / rst.target
                     ,

    target_block = (V"anonymous_target" + V"target")^1
                 * V"end_block",

--------------------------------------------------------------------------------
-- Paragraphs * Inline Markup
--------------------------------------------------------------------------------

    paragraph = Ct(V"par_first"
                 * V"par_other"^0) / rst.paragraph
              * V"end_block"
              * V"reset_depth"
              ,

    par_first = V"par_setindent"
              * C((1 - V"literal_block_shorthand" - V"eol")^1)
              * (V"included_literal_block" + V"eol")
              ,

    par_other = V"par_matchindent"
              * C((1 - V"literal_block_shorthand" - V"eol")^1)
              * (V"included_literal_block" + V"eol")
              ,

    par_setindent = Cmt(V"space"^0, function (s, i, indent)
                        warn("par-i", #indent, "", "", i)
                        state.previousindent = state.currentindent
                        state.currentindent = indent
                        return true
                    end),

    par_matchindent = Cmt(V"space"^0, function (s, i, indent)
                          warn("par-m", state.currentindent == indent, #indent, #state.currentindent, i)
                          return state.currentindent == indent
                      end),

    included_literal_block = V"literal_block_shorthand"
                           * V"literal_block_markerless"
                           * Cmt(Cp(), function (s, i, _)
                                  warn("par-s", "", #state.previousindent, #state.currentindent, i)
                                  state.currentindent = state.previousindent
                                  return true
                              end)
                           ,

    literal_block_shorthand = Cs((V"colon" * V"space" * V"double_colon"
                                + V"double_colon")
                             * V"whitespace"^0
                             * V"eol"
                             * V"blank_line")
                             -- The \unskip is necessary because the lines of a
                             -- paragraph get concatenated from a table with a
                             -- space as separator. And the literal block is
                             -- treated as one such line, hence it would be
                             -- preceded by a space. As the ":" character
                             -- always  follows a non-space this should be a
                             -- safe, albeit unpleasant, hack. If you don't
                             -- agree then file a bug report and I'll look into
                             -- it.
                             / "\\\\unskip:"
                            ,

    literal_block_markerless = Cs(V"literal_block_lines")
                             * V"blank_line"
                             / rst.included_literal_block
                             ,

    -- This is needed because lpeg.Cmt() patterns are evaluated even
    -- if they are part of a larger pattern that doesn’t match. The
    -- result is that they confuse the nesting.
    -- Resetting the current nesting depth at every end of block
    -- should be safe because this pattern always matches last.
    reset_depth = Cmt(Cc("nothing") / "", function (s,i, something)
                        state.depth = 0
                        warn("reset", "", state.depth, #state.currentindent, i)
                        return true
                    end)
                ,

--------------------------------------------------------------------------------
-- Comments
--------------------------------------------------------------------------------

    comment_block = V"comment"
                  * V"end_block"^-1
                  ,

    comment = V"double_dot" / ""
            * (V"block_comment" + V"line_comment")
            ,

    block_comment = V"whitespace"^0
                  * Cs((1 - V"eol")^0 * V"eol"
                     * V"indented_lines")
                  / rst.block_comment,

    line_comment = V"whitespace"^1
                 * C((1 - V"eol")^0 * V"eol")
                 / rst.line_comment
                 ,

--------------------------------------------------------------------------------
-- Generic indented block
--------------------------------------------------------------------------------

    indented_lines = V"indented_first"
                   * (V"indented_other"^0
                    * (V"blank_line" * V"indented_other"^1)^0)
                   ,

    indented_first = Cmt(V"space"^1, function (s, i, indent)
                        warn("idt-f", indent, i)
                        state.currentindent = indent
                        return true
                    end) / ""
                   * (1 - V"eol")^1
                   * V"eol"
                   ,

    indented_other = Cmt(V"space"^1, function (s, i, indent)
                        warn("idt-m", #indent, #state.currentindent, #indent == #state.currentindent, i)
                        return indent == state.currentindent
                    end) / ""
                   * (1 - V"eol")^1
                   * V"eol"
                   ,

--------------------------------------------------------------------------------
-- Urls
--------------------------------------------------------------------------------
    uri             = V"url_protocol" * V"url_domain" * (V"slash" * V"url_path")^0,

    url_protocol    = (P"http" + P"ftp" + P"shttp" + P"sftp") * P"://",
    url_domain_char = 1 - V"dot" - V"spacing" - V"eol" - V"punctuation",
    url_domain      = V"url_domain_char"^1 * (V"dot" * V"url_domain_char"^1)^0,
    url_path_char   = R("az", "AZ", "09") + S"-_.!~*'()",
    url_path        = V"slash" * (V"url_path_char"^1 * V"slash"^-1)^1,

--------------------------------------------------------------------------------
-- Terminal Symbols and Low-Level Elements
--------------------------------------------------------------------------------

    asterisk          = P"*",
    backslash         = P"\\",
    bar               = P"|",
    bareia            = P"`",
    slash             = P"/",
    solidus           = P"⁄",
    equals            = P"=",

    --- Punctuation
    -- Some of the following are used for markup as well as for punctuation.

    apostrophe        = P"’" + P"'",
    comma             = P",",
    colon             = P":",
    dot               = P".",
    interpunct        = P"·",
    semicolon         = P";",
    underscore        = P"_",
    dash              = P"-",
    emdash            = P"—",
    hyphen            = P"‐",
    questionmark      = P"?",
    exclamationmark   = P"!",
    interrobang       = P"‽",
    lsquare           = P"[",
    rsquare           = P"]",
    ellipsis          = P"…" + P"...",
    guillemets        = P"«" + P"»",
    quotationmarks    = P"‘" + P"’" + P"“" + P"”",

    period            = V"dot",
    double_dot        = V"dot" * V"dot",
    double_colon      = V"colon" * V"colon",
    escaped_colon     = V"backslash" * V"colon",
    double_underscore = V"underscore" * V"underscore",
    double_dash       = V"dash" * V"dash",
    triple_dash       = V"double_dash" * V"dash",
    attrib_dash       = V"triple_dash" + V"double_dash" + V"emdash", -- begins quote attribution blocks
    dashes            = V"dash" + P"‒" + P"–" + V"emdash" + P"―",



    punctuation = V"apostrophe"
                + V"colon"
                + V"comma"
                + V"dashes"
                + V"dot"
                + V"ellipsis"
                + V"exclamationmark"
                + V"guillemets"
                + V"hyphen"
                + V"interpunct"
                + V"interrobang"
                + V"questionmark"
                + V"quotationmarks"
                + V"semicolon"
                + V"slash"
                + V"solidus"
                + V"underscore"
                ,

    -- End punctuation

    letter       = R"az" + R"AZ",
    digit        = R"09",

    space        = P" ",
    spaces       = V"space"^1,
    whitespace   = (P" " + Cs(P"\t") / "        " + Cs(S"\v") / " "),
    spacing      = V"whitespace"^1,
    blank_line   = V"whitespace"^0 * V"eol",

    rest_of_line = (1 - V"eol")^1,

    eol          = S"\r\n",
    eof          = V"eol"^0 * -P(1),

    end_block    = V"blank_line"^1 * V"eof"^-1
                 + V"eof"
                 ,

    -- diverse markup character sets
    adornment_char     = S[[!"#$%&'()*+,-./:;<=>?@[]^_`{|}~]] + P[[\\]], -- headings
    bullet_char        = S"*+-" + P"•" + P"‣" + P"⁃",                    -- bullet lists

    roman_numeral      = S"ivxlcdm"^1,
    Roman_numeral      = S"IVXLCDM"^1,

    angle_left         = P"<",
    angle_right        = P">",
    gartenzaun         = P"#",

    table_intersection = P"+",
    table_hline        = V"dash",
    table_vline        = V"bar",
    table_header_hline = P"=",
}

--- 225 rules at 2014-02-28 with lpeg 0.12 and Luatex 0.78.3
--lpeg.print(rst_parser)
--lpeg.ptree(rst_parser)
--os.exit()

local file_helpers = { }

function file_helpers.strip_BOM (raw)
    if stringmatch (raw, "^\239\187\191") then
        return stringsub (raw, 4)
    end
    return raw
end

--- Tab expansion: feature request by Philipp A.
do
    local shiftwidth = rst.shiftwidth
    local stringrep  = string.rep
    local position   = 1

    local reset_position     = function ()  position = 1 return "\n" end
    local increment_position = function (c) position = position + 1 return c end
    local expand_tab         = function ()
        local expand = (shiftwidth - position) % shiftwidth + 1
        position     = position + expand
        return stringrep(" ", expand)
    end

    local tab      = S"\t\v" / expand_tab
    local utfchar  = utfchar / increment_position
    local eol      = P"\n"   / reset_position
    local p_expand = Cs((tab + eol + utfchar)^1)

    function file_helpers.expandtab (raw)
        position = 1
        return lpegmatch (p_expand, raw)
    end
end

--- Spotted by Philipp A.
function file_helpers.insert_blank (raw)
    if not stringfind (raw, "\n%s$") then
        return raw .. "\n\n"
    end
    return raw
end

function file_helpers.crlf (raw)
    if stringfind (raw, "\r\n") then
        return stringgsub (raw, "\r\n", "\n")
    end
    return raw
end

local function load_file (name)
    f = assert(ioopen(name, "r"), "Not a file!")
    if not f then return 1 end
    local tmp = f:read("*all")
    f:close()

    local fh = file_helpers
    if thirddata.rst.strip_BOM then
        tmp = fh.strip_BOM(tmp)
    end
    if thirddata.rst.crlf then
        tmp = fh.crlf(tmp)
    end
    if thirddata.rst.expandtab then
        tmp = fh.expandtab(tmp)
    end
    return fh.insert_blank(tmp)
end

local function save_file (name, data)
    f = assert(ioopen(name, "w"), "Could not open file "..name.." for writing! Check its permissions")
    if not f then return 1 end
    f:write(data)
    f:close()
    return 0
end

local function get_setups (inline)
    local optional_setups = optional_setups
    local setups = ""
    if not inline then
        setups = setups .. [[
%+-------------------------------------------------------------+%
%|                           Setups                            |%
%+-------------------------------------------------------------+%
% General                                                       %
%---------------------------------------------------------------%

]]
    end

    setups = setups .. [[
\setupcolors[state=start]
%% Interaction is supposed to be handled manually.
%%\setupinteraction[state=start,focus=standard,color=darkgreen,contrastcolor=darkgreen]
\setupbodyfontenvironment [default]  [em=italic]
\sethyphenatedurlnormal{:=?&}
\sethyphenatedurlbefore{?&}
\sethyphenatedurlafter {:=/-}

\doifundefined{startparagraph}{% -->mkii
  \enableregime[utf]
  \let\startparagraph\relax
  \let\stopparagraph\endgraf
}

]]
    for item, _ in next, state.addme do
        local f = optional_setups[item]
        setups = f and setups .. f() or setups
    end
    if not inline then
        setups = setups .. [[


%+-------------------------------------------------------------+%
%|                            Main                             |%
%+-------------------------------------------------------------+%

\starttext
]]
    end
    return setups
end

function thirddata.rst.standalone (infile, outfile)
    local testdata = load_file(infile)
    if testdata == 1 then return 1 end

    local processeddata = lpegmatch (rst_parser, testdata)
    local setups = get_setups(false)

    processeddata = setups .. processeddata .. [[

\stoptext

%+-------------------------------------------------------------+%
%|                       End of Document                       |%
%+-------------------------------------------------------------+%

% vim:ft=context:tw=65:shiftwidth=2:tabstop=2:set expandtab
]]

    if processeddata then
        save_file(outfile, processeddata)
    else
        return 1
    end
    return 0
end

local p_strip_comments
do
    local Cs, P = lpeg.Cs, lpeg.P
    local percent = P"%"
    local eol     = P"\n"
    local comment = percent * (1 - eol)^0 * eol / "\n"
    p_strip_comments = Cs((comment + 1)^0)
end


local tempfile_count = { } --- map category -> count

local get_tmpfile = function (category)
    local cnt = tempfile_count[category]
    if not cnt then
        cnt = 0
    end
    cnt = cnt + 1
    tempfile_count[category] = cnt
    local filename = stringformat ("%s_rst-%s-%d",
                                   tex.jobname, category, cnt)
    return luatex.registertempfile (filename,
                                    true,
                                    (helpers.rst_debug == true)) --- for debugging generated code
end


function thirddata.rst.do_rst_file(fname)
    local raw_data   = load_file(fname)
    local processed  = lpegmatch (rst_parser, raw_data)
    local setups     = get_setups(false)
    local tmp_file   = get_tmpfile "temporary"
    if processed then
        processed = lpegmatch (p_strip_comments, setups..processed.."\n\\stoptext\n")
        save_file(tmp_file, processed)
        context.input("./"..tmp_file)
    end
end

local rst_inclusions = { }
local rst_incsetups  = { }
function thirddata.rst.do_rst_inclusion (iname, fname)
    local raw_data   = load_file(fname)
    local processed  = lpegmatch (rst_parser, raw_data)
    local setups     = get_setups(true)
    local tmp_file   = get_tmpfile "setup"

    if processed then
        processed = lpegmatch (p_strip_comments, processed)
        save_file(tmp_file, processed)
        rst_inclusions[iname] = tmp_file
        rst_incsetups[#rst_incsetups +1] = setups
    end
end

function thirddata.rst.do_rst_setups ()
    local out = tableconcat(rst_incsetups)
    --context(out) --- why doesn’t this work?
    local tmp_file = get_tmpfile "setup"
    save_file(tmp_file, out)
    context.input(tmp_file)
end

function thirddata.rst.get_rst_inclusion (iname)
    if rst_inclusions[iname] then
        context.input(rst_inclusions[iname])
    else
        context(stringformat([[{\bf File for inclusion “%s” not found.}\par ]], iname))
    end
end

function thirddata.rst.do_rst_snippet(txt)
    local processed  = lpegmatch (rst_parser, txt)
    local setups     = get_setups(true)
    local tmp_file   = get_tmpfile "snippet"
    if processed then
        warn("·cs·", txt)
        processed = lpegmatch (p_strip_comments, setups..processed)
        save_file(tmp_file, processed)
        context.input("./" .. tmp_file)
    else
        warn("·cs·", txt)
        context.par()
        context("{\\bf context-rst could not process snippet.\\par}")
        context.type(txt)
        context.par()
    end
end

--- vim:tw=79:et:sw=4:ts=8:sts=4
