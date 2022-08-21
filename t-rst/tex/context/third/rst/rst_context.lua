#!/usr/bin/env texlua
--------------------------------------------------------------------------------
--         FILE:  rst_context.lua
--        USAGE:  called by rst_parser.lua
--  DESCRIPTION:  Complement to the reStructuredText parser
--       AUTHOR:  Philipp Gesang (Phg), <phg42.2a@gmail.com>
--      CHANGED:  2013-03-26 22:46:17+0100
--------------------------------------------------------------------------------
--
--- TODO
---   Find an appropriate way to handle generic tables irrespective of the grid
---   settings. The problem is:
---   http://archive.contextgarden.net/message/20100912.112605.8a1aaf13.en.html
---   Seems we'll have to choose either the grid or split tables as default. Not
---   good.


local helpers           = helpers        or thirddata and thirddata.rst_helpers
local rst_directives    = rst_directives or thirddata and thirddata.rst_directives

local utf               = unicode.utf8
local utflen            = utf.len
local utflower          = utf.lower
local utfupper          = utf.upper
local iowrite           = io.write
local tableconcat       = table.concat

local stringgmatch      = string.gmatch
local stringgsub        = string.gsub
local stringmatch       = string.match
local stringsub         = string.sub
local stringformat      = string.format

local dbg_write = helpers.dbg_writef

local C,  Cb, Cc, Cg, Cmt, Cp,
      Cs, Ct, P,  R,  S,   V,  lpegmatch
      = lpeg.C,  lpeg.Cb, lpeg.Cc, lpeg.Cg, lpeg.Cmt, lpeg.Cp,
        lpeg.Cs, lpeg.Ct, lpeg.P,  lpeg.R,  lpeg.S,   lpeg.V,  lpeg.match

-- This one should ignore escaped spaces.
do
    local stripper = P{
        [1] = "stripper",
        stripper = V"space"^0 * C((V"space"^0 * (V"escaped" + V"nospace")^1)^0),
        space    = S(" \t\v\n"),
        nospace  = 1 - V"space",
        escaped  = P"\\" * V"space"
    }
    function string.strip(str)
        return lpegmatch(stripper, str) or ""
    end
end
local stringstrip  = string.strip

local err = function(str)
    if str then
        iowrite("\n*[rstctx] Error: " .. str .. "\n\n")
    end
end

local rst_context = thirddata.rst

rst_context.collected_adornments = {}
rst_context.last_section_level   = 0
rst_context.anonymous_targets    = 0
rst_context.anonymous_links      = {}

rst_context.collected_references = {}
rst_context.context_references   = {}
rst_context.structure_references = {}
rst_context.anonymous_set        = {}

rst_context.substitutions        = {}
rst_context.lastitemnumber       = 0  -- enumerations in RST allow arbitrary skips

rst_context.current_footnote_number   = 0
rst_context.current_symbolnote_number = 0

function rst_context.addsetups(item)
    local state = rst_context.state
    state.addme[item] = state.addme[item] or true
    return 0
end

function rst_context.footnote_reference (label)
    local tf = rst_context.state.footnotes
    if stringmatch(label, "^%d+$") then -- all digits
        local c = tonumber(label)
        return [[\\footnote{\\getbuffer[__footnote_number_]].. c .."]}"
    elseif label == "#" then --autonumber
        local rc = rst_context.current_footnote_number
        rc = rc + 1
        rst_context.current_footnote_number = rc
        return [[\\footnote{\\getbuffer[__footnote_number_]].. rc .."]}"
    elseif stringmatch(label, "^#.+$") then
        local thelabel = stringmatch(label, "^#(.+)$")
        return [[\\footnote{\\getbuffer[__footnote_label_]].. thelabel .."]}"
    elseif label == "*" then
        local rc = rst_context.current_symbolnote_number
        rc = rc + 1
        rst_context.current_symbolnote_number = rc
        return [[\\symbolnote{\\getbuffer[__footnote_symbol_]].. rc .."]}"
    else -- “citation reference” for now treating them like footnotes
        rst_context.addsetups("citations")
        return [[\\cite{]] .. label .. [[}]]
    end
end

do
    local w = S" \v\t\n" / "_"
    local wp = Cs((w + 1)^1)
    function rst_context.whitespace_to_underscore(str)
        return  str and lpegmatch(wp, str) or ""
    end
end

--- So we can use crefs[n][2] to refer to the place where the reference was
--- created.
local function get_context_reference (str)
    local crefs = rst_context.context_references
    local srefs = rst_context.structure_references
    srefs[str] = true
    refstring = "__target_" .. rst_context.whitespace_to_underscore(str)
    crefs[#crefs + 1] = { refstring, str }
    return refstring
end

function rst_context.emphasis (str)
    return [[{\\em ]] .. str .. [[}]]
end

function rst_context.strong_emphasis (str)
    return [[{\\sc ]] .. str .. [[}]]
end

function rst_context.literal (str)
    return [[\\type{]] .. str .. [[}]]
end

--- ROLES for interpreted text

rst_context.roles = {}
rst_context.roles.emphasis = rst_context.emphasis
rst_context.roles.strong_emphasis = rst_context.strong_emphasis
rst_context.roles.literal = rst_context.literal
rst_context.roles.bold = function(str)
    return [[{\\bold ]] .. str .. [[}]]
end
rst_context.roles.bf = rst_context.roles.bold

rst_context.roles.italic = function(str)
    return [[{\\italic ]] .. str .. [[}]]
end
rst_context.roles.it = rst_context.roles.italic

rst_context.roles.sans = function(str)
    return [[{\\ss ]] .. str .. [[}]]
end
rst_context.roles.sans_serif = rst_context.roles.sans
rst_context.roles.ss         = rst_context.roles.sans

rst_context.roles.uppercase = function(str)
    return utfupper(str)
end

rst_context.roles.lowercase = function(str)
    return utflower(str)
end

rst_context.roles.color = function(color, str)
    local p = helpers.patterns
    local definition = stringmatch(color, "^color_(.+)$")
    if stringmatch(definition, "^rgb_") then -- assume rgb
        local rgb = lpegmatch(p.rgbvalues, definition)
        definition = stringformat([[r=%s,g=%s,b=%s]], rgb[1], rgb[2], rgb[3])
    end
    return stringformat([[\\colored[%s]{%s}]], definition, str)
end

--------------------------------------------------------------------------------
--- Inofficial text roles for my private bib
--------------------------------------------------------------------------------

-- Afterthought:
-- Different citation commands are essentially typographical instructions:
-- they are concerned with the final representation of the data with respect to
-- a concrete implementation. Not the thing at all that would make reST
-- portable. But then its support for Python-style string escaping &c. ain’t at
-- all portable either. The problem is the same with XML written to be
-- processed with ConTeXt -- when processing the text directly in MkIV you’ll
-- always find yourself adding setups that allow fine-grained control of the
-- typeset output. At the same time those instructions directly contradict the
-- main reason for XML: to provide an application-independent data markup.
-- Typesetting XML (and now reST) with TeX, you will always end up writing TeX
-- code disguised in XML brackets. (Btw. the docutils reST specification has
-- the same kind of inclination to HTML -- some of its components don’t even
-- have a meaning save in HTML peculiarities.) If you strive to avoid this
-- *and* would like to have decent typesetting, you should use the
-- automatically generated TeX code as a starting point for the actual
-- typesetting job. Wish it was possible to have both -- the data in a
-- universal form and the output in the Optimal Typesetting System -- but
-- that’s a dream for now. If you really read these musings, then prove me
-- wrong if you can! Or go tell those digital publishers and their willing
-- subordinates, the authors, who think they can save a few pennys,
-- substituting the typesetter and editor by some fancy software. Keep in mind
-- that zapf.tex is not just random dummy text. </rant>

function rst_context.roles.ctsh(str) -- shorthand
    rst_context.addsetups("citator")
    return [[\\ctsh{]] .. str .. [[}]]
end

function rst_context.roles.ctas(str) -- short cite
    rst_context.addsetups("citator")
    return [[\\ctas{]] .. str .. [[}]]
end

function rst_context.roles.ctau(str) -- author only
    rst_context.addsetups("citator")
    return [[\\ctau{]] .. str .. [[}]]
end

function rst_context.roles.cttt(str) -- title only
    rst_context.addsetups("citator")
    return [[\\cttt{]] .. str .. [[}]]
end

function rst_context.roles.ctay(str) -- author year
    rst_context.addsetups("citator")
    return [[\\ctay{]] .. str .. [[}]]
end

function rst_context.roles.ctfu(str) -- full cite
    rst_context.addsetups("citator")
    return [[\\ctfu{]] .. str .. [[}]]
end

function rst_context.roles.nocite(str) -- nocite
    rst_context.addsetups("citator")
    return [[\\nocite[]] .. str .. [=[]]=]
end

--------------------------------------------------------------------------------
--- End citator roles
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--- Experimental roles.
--------------------------------------------------------------------------------

--- Feature request by Philipp A.
function rst_context.roles.math(str)
    return [[\\mathematics{]] .. str .. [[}]]
end

--------------------------------------------------------------------------------
--- End roles
--------------------------------------------------------------------------------

function rst_context.interpreted_text (...)
    local tab = { ... }
    local role, str
    role = stringmatch(tab[1], "^:(.*):$") or stringmatch(tab[3], "^:(.*):$")
    str  = tab[2]

    if not role then -- implicit role
        role = "emphasis"
    end

    if stringmatch(role, "^color_") then
        return rst_context.roles.color(role, str)
    end

    return rst_context.roles[role](str)
end

function rst_context.link_standalone (str)
    return "\n"
        .. [[\\goto{\\hyphenatedurl{]] .. str .. [[}}[url(]] .. str .. [=[)]]=]
end

function rst_context.reference (str)
    rst_context.addsetups("references")
    str = stringmatch(str, "^`?([^`]+)`?_$")
    return [[\\RSTchoosegoto{__target_]] .. rst_context.whitespace_to_underscore(str) .. "}{"
            .. str .. "}"
end

function rst_context.anon_reference (str)
    rst_context.addsetups("references")
    str = stringmatch(str, "^`?([^`]+)`?__$")
    rst_context.anonymous_links[#rst_context.anonymous_links+1] = str
    link = "__target_anon_" .. #rst_context.anonymous_links
    return stringformat([[\\RSTchoosegoto{%s}{%s}]], link, str)
end

local whitespace = S" \n\t\v"
local nowhitespace = 1 - whitespace
local removewhitespace = Cs((nowhitespace^1 + Cs(whitespace / ""))^0)

function rst_context.target (tab)
    rst_context.addsetups("references")
    --local tab = { ... }
    local  refs = rst_context.collected_references
    local arefs = rst_context.anonymous_set
    local target = tab[#tab] -- Ct + C could be clearer but who cares
    tab[#tab] = nil

    local function create_anonymous ()
        rst_context.anonymous_targets = rst_context.anonymous_targets + 1
        return { "anon_" .. rst_context.anonymous_targets, rst_context.anonymous_targets }
    end

    local insert = ""

    if target == "" then -- links here
        for _, id in next, tab do
            insert = insert .. "\n\\reference[__target_" .. id .. "]{}"
        end
    else
        for i=1,#tab do
            local id = tab[i]
            if id == "" then -- anonymous
                local anon = create_anonymous()
                id, arefs[anon[1]] = anon[1], anon[2]
            else
                local tmp = tab[i]
                tmp = stringgsub(tmp, "\\:",":")
                tmp = stringmatch(tmp, "`?([^`]+)`?")
                id = tmp
                --id = tab[i]:gsub("\\:",":"):match("`?([^`]+)`?") -- deescaping
            end
            if id then
                refs[id] = refs[id] or target
            end
        end
    end

    return insert
end

function rst_context.inline_internal_target (str)
    return "\\\\reference[__target_" .. rst_context.whitespace_to_underscore(str) .."]{}"
end

function rst_context.substitution_reference (str, underscores)
    local sub = ""
    rst_context.addsetups "substitutions"
    if underscores == "_" then -- normal reference
        sub = sub .. [[\\reference[__target_]] .. rst_context.whitespace_to_underscore(stringstrip(str)) .. "]{}"
    elseif underscores == "__" then -- normal reference
        rst_context.anonymous_targets = rst_context.anonymous_targets + 1
        sub = sub .. [[\\reference[__target_anon_]] .. rst_context.anonymous_targets .. "]{}"
    end
    return sub .. [[{\\RSTsubstitution]] .. stringgsub(str, "%s", "") .. "}"
end

do
    -- see catc-sym.tex
    local escape_me = {
        ["&"]   = [[\letterampersand ]],
        ["$"]   = [[\letterdollar ]],
        ["#"]   = [[\letterhash ]],
        ["^"]   = [[\letterhat ]],
        ["_"]   = [[\letterunderscore ]],
    }

    local chars
    for chr, repl in next, escape_me do
        chars = chars and chars + (P(chr) / repl) or P(chr) / repl
    end

    local p_escape = P{
        [1]      = Cs((V"skip"
                 --+ V"literal" -- achieved via gsub later
                 + chars
                 + 1)^1),
        skip1    = P"\\starttyping" * (1 - P"\\stoptyping")^1,
        balanced = P"{" * (V"balanced" + (1 - P"}"))^0 * P"}",
        skip2    = P"\\type" * V"balanced",
        skip3    = P"\\mathematics" * V"balanced",
        skip     = V"skip1" + V"skip2" + V"skip3",
        --literal  = Cs(P"\\" / "") * 1
    }

    function rst_context.escape (str)
        str = stringgsub(str, "\\(.)", "%1")
        return lpegmatch(p_escape, str)
    end
end

function rst_context.joinindented (tab)
    return tableconcat (tab, "")
end

local corresponding = {
    ['"'] = '"',
    ["'"] = "'",
    ["{"] = "}",
    ["("] = ")",
    ["["] = "]",
    ["<"] = ">",
}

local inline_parser = P{
    [1] = "block",

    block = Cs(V"inline_as_first"^-1 * (V"except" + V"inline_element" + V"normal_char")^0),

    inline_element = V"precede_inline"
                   * Cs(V"inline_do_elements")
                   * #V"succede_inline"
                   + V"footnote_reference"
                   ,

    -- Ugly but needed in case the first element of a paragraph is inline
    -- formatted.
    inline_as_first = V"inline_do_elements" * #V"succede_inline",

    except = P"\\starttyping" * (1 - P"\\stoptyping")^1 * P"\\stoptyping"
           + V"enclosed"
           ,

    inline_do_elements = V"strong_emphasis"
                       + V"substitution_reference"
                       + V"anon_reference"
                       + V"inline_literal"
                       + V"reference"
                       + V"emphasis"
                       + V"interpreted_text"
                       + V"inline_internal_target"
                       + V"link_standalone"
                       ,

    precede_inline = V"spacing"
                   + V"eol"
                   + -P(1)
                   + S[['"([{<-/:]]
                   + P"‘" + P"“" + P"’" + P"«" + P"¡" + P"¿"
                   + V"inline_delimiter"
                   + P"„", -- not in standard Murkin reST

    succede_inline = V"spacing"
                   + V"eol"
                   + S[['")]}>-/:.,;!?\]]
                   + P"’" + P"”" + P"»"
                   + V"inline_delimiter"
                   + -P(1)
                   + P"“" -- non-standard again but who cares
                   ,

    enclosed = V"precede_inline"^-1
             * Cg(V"quote_single" + V"quote_double" + V"leftpar", "lastgroup")
             * V"inline_delimiter"
             * Cmt(C(V"quote_single" + V"quote_double" + V"rightpar") * Cb("lastgroup"), function(s, i, char, oldchar)
                    return corresponding[oldchar] == char
                end)
             * V"succede_inline"^-1
             * -V"underscore"
             ,

    space = P" ",
    whitespace = (P" " + Cs(P"\t") / "        " + Cs(S"\v") / " "),
    spacing = V"whitespace"^1,

    eol = P"\n",
    --inline_delimiters = P"‐" + P"‑" + P"‒" + P"–" + V"emdash" + V"space",        -- inline markup
    inline_delimiter = P"‐" + P"‑" + P"‒" + P"–" + V"emdash" + V"space"
                     + V"bareia"
                     + V"asterisk"
                     + V"bar"
                     + V"lbrack" + V"rbrack"
                     ,        -- inline markup
    asterisk = P"*",
    quote_single = P"'",
    quote_double = P'"',
    double_asterisk = V"asterisk" * V"asterisk",
    bareia = P"`",
    backslash = P"\\",
    bar = P"|",
    double_bareia = V"bareia" * V"bareia",
    escaped_bareia = (Cs(V"backslash") / "" * V"bareia") + 1,
    colon = P":",
    escaped_colon = (Cs(V"backslash") / "" * V"colon") + 1,
    semicolon = P";",
    underscore = P"_",
    double_underscore = V"underscore" * V"underscore",
    dot = P".",
    interpunct = P"·",
    comma = P",",
    dash = P"-",
    emdash = P"—",
    ellipsis   = P"…" + P"...",
    exclamationmark = P"!",
    questionmark = P"?",
    interrobang = P"‽",
    double_dash = V"dash" * V"dash",
    triple_dash = V"double_dash" * V"dash",
    hyphen = P"‐",
    dashes = V"dash" + P"‒" + P"–" + V"emdash" + P"―",

    lparenthesis = P"(",
    rparenthesis = P")",
    lbrack  = P"[",
    rbrack  = P"]",
    lbrace  = P"{" / [[{\\letterleftbrace}]],
    rbrace  = P"}" / [[{\\letterrightbrace}]],
    less    = P"<",
    greater = P">",
    leftpar  = V"lparenthesis" + V"lbrack" + V"lbrace" + V"less",
    rightpar = V"rparenthesis" + V"rbrack" + V"rbrace" + V"greater",

    normal_char = V"lbrace" + V"rbrace" + V"lbrack" + V"rbrack" -- escape those if in input
                + 1
                ,

    --groupchars = S"()[]{}",
    groupchars = V"leftpar" + V"rightpar",
    apostrophe = P"’" + P"'",

    guillemets = P"«" + P"»",
    quotationmarks= P"‘" + P"’" + P"“" + P"”",
    solidus= P"⁄",
    slash = P"/",

    gartenzaun = P"#",
    digit  = R"09",
    letter = R"az" + R"AZ",

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

    emphasis        = (V"asterisk" - V"double_asterisk")
                    * Cs((V"normal_char" - V"spacing" - V"eol" - V"asterisk")
                       * ((V"normal_char" - (V"normal_char" * V"asterisk"))^0
                        * (V"normal_char" - V"spacing" - V"eol" - V"asterisk"))^-1)
                    * V"asterisk"
                    / rst_context.emphasis,

    strong_emphasis = V"double_asterisk"
                    * Cs((V"normal_char" - V"spacing" - V"eol" - V"asterisk")
                       * ((V"normal_char" - (V"normal_char" * V"double_asterisk"))^0
                        * (V"normal_char" - V"spacing" - V"eol" - V"asterisk"))^-1)
                    * V"double_asterisk"
                    / rst_context.strong_emphasis,

    inline_literal  = V"double_bareia"
                    * C ((V"escaped_bareia" - V"spacing" - V"eol" - V"bareia")
                       * ((V"escaped_bareia" - (V"normal_char" * V"double_bareia"))^0
                        * (V"escaped_bareia" - V"spacing" - V"eol" - V"bareia"))^-1)
                    * V"double_bareia"
                    / rst_context.literal,

    interpreted_single_char = (V"normal_char" - V"spacing" - V"eol" - V"bareia") * #V"bareia",
    interpreted_multi_char  = (V"normal_char" - V"spacing" - V"eol" - V"bareia") * (V"normal_char" - (1 * V"bareia"))^0 * (1 - V"spacing" - V"eol" - V"bareia"),

    interpreted_text = C(V"role_marker"^-1)
                     * (V"bareia" - V"double_bareia")
                     * C(V"interpreted_single_char" + V"interpreted_multi_char")
                     * V"bareia"
                     * C(V"role_marker"^-1)
                     / rst_context.interpreted_text,

    role_marker = V"colon" * (V"backslash" * V"colon" + V"letter" + V"digit" + V"dash" + V"underscore" + V"dot")^1 * V"colon",

    link_standalone = C(V"uri")
                    / rst_context.link_standalone,

    anon_reference = Cs(V"anon_phrase_reference" + V"anon_normal_reference")
              / rst_context.anon_reference,

    anon_normal_reference = C((1 - V"underscore" - V"spacing" - V"eol" - V"punctuation" - V"groupchars")^1) * V"double_underscore",

    anon_phrase_reference = (V"bareia" - V"double_bareia")
                          * C((1 - V"bareia")^1)
                          * V"bareia" * V"double_underscore"
                          ,

    reference = Cs(V"normal_reference" + V"phrase_reference")
              / rst_context.reference,

    normal_reference = (1 - V"underscore" - V"spacing" - V"eol" - V"punctuation" - V"groupchars")^1 * V"underscore",

    phrase_reference = (V"bareia" - V"double_bareia")
                     * C((1 - V"bareia")^1)
                     * V"bareia" * V"underscore"
                     ,

    footnote_reference = V"lbrack"
                       * Cs(V"footnote_label" + V"citation_reference_label")
                       * V"rbrack"
                       * V"underscore"
                       / rst_context.footnote_reference
                       ,

    footnote_label = V"digit"^1
                   + V"gartenzaun" * V"letter"^1
                   + V"gartenzaun"
                   + V"asterisk"
                   ,

    citation_reference_label = V"letter" * (1 - V"rbrack")^1,

    inline_internal_target = V"underscore"
                           * V"bareia"
                           * Cs((1 - V"bareia")^1)
                           * V"bareia"
                           / rst_context.inline_internal_target
                           ,

    substitution_reference = V"bar"
                           * C((1 - V"bar")^1)
                           * V"bar"
                           * C((V"double_underscore" + V"underscore")^-1)
                           / rst_context.substitution_reference
                           ,

--------------------------------------------------------------------------------
-- Urls
--------------------------------------------------------------------------------
    uri = V"url_protocol" * V"url_domain" * V"url_path_char"^0,

    url_protocol = (P"http" + P"ftp" + P"shttp" + P"sftp") * P"://",
    url_domain_char = 1 - V"dot" - V"spacing" - V"eol" - V"punctuation",
    url_domain = V"url_domain_char"^1 * (V"dot" * V"url_domain_char"^1)^0,
    url_path_char = R("az", "AZ", "09") + S[[-_.!~*'()/]],
}

rst_context.inline_parser = inline_parser

function rst_context.paragraph (data)
    local str
    if not data then
        return ""
    elseif type(data) == "table" then
--        str = #data > 1 and  helpers.string.wrapat(lpegmatch(inline_parser, tableconcat(data, " ")), 65) 
--                        or   inline_parser:match(data[1])
        if #data > 1 then
            str = helpers.string.wrapat(
                lpegmatch(inline_parser, tableconcat(data, " "))
                , 65)
        else
            str = lpegmatch(inline_parser, data[1])
        end
    else
        str = data
    end
    return stringformat([[

\\startparagraph
%s
\\stopparagraph
]], str)
end

local sectionlevels = {
    [1] = "chapter",
    [2] = "section",
    [3] = "subsection",
    [4] = "subsubsection",
    [5] = "subsubsubsection",
}

local function get_line_pattern (chr)
    return P(chr)^1 * (-P(1))
end

--[[--
        Quoth the spec:
            An underline-only adornment is distinct from an
            overline-and-underline adornment using the same character.

    We store the depths by hashing the adorn character and distinguish
    the overlined ones from only underlined ones by prefixing them with
    “O” and “U”, respectively.
--]]--

function rst_context.section (first, second, third)
    local section   = true
    local str       = ""
    local adornchar = nil
    local ulen      = utflen
    if third then --- overlined
        adornchar   = "O" .. stringsub(first, 1,1)
        section     = ulen(first) >= ulen(second)
        str         = stringstrip(second)
    else -- underline-only
        adornchar   = "U" .. stringsub(second, 1,1)
        section     = ulen(first) <= ulen(second)
        str         = stringstrip(first)
    end

    if section then -- determine level
        local level = rst_context.last_section_level
        local rca   = rst_context.collected_adornments
        if rca[adornchar] then
            level = rca[adornchar]
        else
            level = level + 1
            rca[adornchar] = level
            rst_context.last_section_level = level
        end

        local ref = get_context_reference (str)

        str = stringformat("\n\\\\%s[%s]{%s}\n",
                           sectionlevels[level],
                           ref,
                           str)
        return str or ""
    end
    return [[{\\bf fix your sectioning!}\\endgraf}]]
end

-- Prime time for the fancybreak module.
function rst_context.transition (str)
    rst_context.addsetups("breaks")
    --return "\\fancybreak\n"
    return "\\fancybreak{$* * *$}\n"
end

function rst_context.bullet_marker(str)
    return "marker"
end

-- This one should ignore escaped spaces.
do
    local stripper = P{
        [1] = "stripper",
        stripper = V"space"^0 * C((V"space"^0 * V"nospace"^1)^0),
        space    = S(" \t\v\n"),
        escaped  = P"\\" * V"space",
        nospace  = V"escaped" + (1 - V"space"),
    }
    function stringstrip(str)
        return lpegmatch(stripper, str) or ""
    end 
end

local enumeration_types = {
    ["*"] = "*", -- unordered bulleted
    ["+"] = "*",
    ["-"] = "*",
    ["•"] = "*",
    ["‣"] = "*",
    ["⁃"] = "*",

    ["#"] = "n", -- numbered lists and conversion
    ["A"] = "A",
    ["a"] = "a",
    ["I"] = "R",
    ["i"] = "r",
}

-- \setupitemize[left=(, right=), margin=4em, stopper=]

local stripme   = S"()."
local dontstrip = 1 - stripme
local itemstripper = stripme^0 * C(dontstrip^1) * stripme^0

local function parse_itemstring(str)
    local offset = nil
    local setup = ",fit][itemalign=flushright,"
    if stringmatch(str, "^%(") then
        setup = setup .. [[left=(,]]
    end
    if stringmatch(str, "%)$") then
        setup = setup .. [[right=)]]
    end
    if stringmatch(str, "%.$") then
        setup = setup .. [[stopper={.\\space}]]
    end
    local num = stringmatch(str, "^%d")
    if num then
        -- http://thread.gmane.org/gmane.comp.tex.context/61728/focus=61729
        setup = setup .. ",start=" .. num
        str = "n"
    end

    str = lpegmatch(itemstripper, str)
    str = enumeration_types[str] or str
    return { setup = setup, str = str }
end

function rst_context.startitemize(str)
    local setup = ""
    local result = ""
    str = stringstrip(str)

    local listtype = enumeration_types[str] or parse_itemstring(str)

    if type(listtype) == "table" then
        setup = listtype.setup
        listtype = listtype.str
    end

    result = [[
\\startitemize[]] .. listtype .. setup .. [[]
]] 
    return result
end

local item_stack = { }

function rst_context.stopitemize(str)
    item_stack[#item_stack] = nil
    return str .. [[
\\stopitemize
]]
end

function rst_context.bullet_item (tab)
    -- The capture of the first item has the \startitemize as 
    -- *second* element in the array.
    local content  = #tab == 2 and tab[2] or tab[3]
    local startstr = #tab == 3 and tab[2] or nil
    local itemtype = tab[1]
    local result = startstr or ""
    if startstr then
        item_stack[#item_stack + 1] = itemtype
    elseif next (item_stack) then
        local current_item = item_stack [#item_stack]
        if helpers.list.successor(itemtype, current_item) then
            -- just leave it alone
        elseif helpers.list.greater(itemtype, current_item) then
            local itemnum = tonumber(stringstrip(itemtype)) or helpers.list.get_decimal(itemtype)
            result = result .. stringformat([[
\\setnumber[itemgroup:itemize]{%s}
]], itemnum)
        end
        item_stack[#item_stack] = itemtype
    end

    return result .. [[

\\item ]] .. lpegmatch(inline_parser, content) .. [[

]]
end

--------------------------------------------------------------------------------
-- Definition lists 
--------------------------------------------------------------------------------
-- TODO define proper setups (probably bnf-like and some narrower for def-paragraphs)

function rst_context.deflist (list)
    rst_context.addsetups("deflist")

    local deflist = [[
\\startRSTdefinitionlist
]] 
    for nd=1, #list do
        local item = list[nd]
        local term = item[1]
        local nc = 2
        local tmp = [[

  \\RSTdeflistterm{]] .. stringstrip(term) .. "}"
        if #item > 2 then
            while nc < #item do
                tmp = tmp .. [[

  \\RSTdeflistclassifier{]] .. stringstrip(item[nc]) .. "}"
                nc = nc + 1
            end
        end
        tmp = tmp .. [[

  \\RSTdeflistdefinition{%
]]
        local final = item[#item]
        for np=1, #final do
            local par = final[np]
            tmp = tmp .. [[
    \\RSTdeflistparagraph{%
]] .. lpegmatch(inline_parser, par) .. "}\n"
        end
        tmp = tmp .. "  }"
        deflist = deflist .. tmp
    end
    return deflist .. [[

\\stopRSTdefinitionlist
]]
end

--------------------------------------------------------------------------------
-- Field lists
--------------------------------------------------------------------------------

-- TODO Do something useful with field lists. For now I'm not sure what as the
-- bibliography directives from the reST specification seem to make sense only
-- when using docinfo and, after all, we have .bib files that are portable.

function rst_context.field_list (str)
    rst_context.addsetups("fieldlist")
    return [[

\\startRSTfieldlist]] .. str .. [[\\eTABLEbody\\stopRSTfieldlist
]]
end

function rst_context.field_name (str)
    return [[\\fieldname{]] .. str .. [[}]]
end

function rst_context.field_body (str)
    return [[\\fieldbody{]] .. lpegmatch(inline_parser, str) .. [[}]]
end

function rst_context.field (tab)
    local name, body = tab[1], tab[2]
    return stringformat([[

    \\RSTfieldname{%s}
    \\RSTfieldbody{%s}
]], name, lpegmatch(inline_parser, body))
end

function rst_context.line_comment (str)
    return "% " .. str
end

function rst_context.block_comment (str)
    return stringformat([[

\iffalse %% start block comment
%s\fi %% stop block comment
]], str)
end

function rst_context.option_list (str)
    return [[
\\setupTABLE[c][first] [background=color, backgroundcolor=grey, style=\tt]
\\setupTABLE[c][each]  [frame=off]
\\setupTABLE[r][each]  [frame=off]
\\bTABLE[split=yes,option=stretch]
\\bTABLEhead
\\bTR
  \\bTH  Option \\eTH
  \\bTH  Description \\eTH
\\eTR
\\eTABLEhead
\\bTABLEbody
]] .. lpegmatch(inline_parser, str) .. [[

\\eTABLEbody
\\eTABLE
]]
end

function rst_context.option_item (tab)
    return stringformat([[\\bTR\\bTC %s \\eTC\\bTC %s \\eTC\\eTR
]], tab[1], tab[2])
end

function rst_context.test(str)
    return ":"
end

function rst_context.literal_block (str, included)
    local indent = P" "^1
    local stripme = #str
    for line in stringgmatch(str, "[^\n]+") do
        -- setting to the lowest indend of all lines
        local idt = lpegmatch(indent, line)
        if line and idt then
            stripme = idt < stripme and idt or stripme
        end
    end

    local strip = P{
        [1] = "strip",
        strip = Cs(V"line"^1),
        eol = P"\n",
        restofline = (1 - V"eol")^0,
        stop = Cs(V"eol" * P" "^0) * -P(1) / "", -- remove trailing blank lines
        line = Cs(V"restofline" * (V"stop" + V"eol")) / function (line)
            return #line > stripme and line:sub(stripme) or line
        end,
    }

    str = lpegmatch(strip, str)
    str = [[

\starttyping[lines=hyphenated]
]] .. str .. [[

\stoptyping
]]
    if included then -- escaping can ruin your day
        str = str:gsub("\\", "\\\\")
    end
    return str
end

function rst_context.included_literal_block (str)
    return rst_context.literal_block(str, true)
end

function rst_context.line_block (str)
    rst_context.addsetups("lines")
    return [[

\\startlines
]] .. lpegmatch(inline_parser, str) .. [[\\stoplines
]]
end

function rst_context.line_block_line(str)
    str = str:gsub("\n", " ")
    return str .. "\n"
end

function rst_context.line_block_empty()
    return "\n"
end

function rst_context.block_quote (tab)
    rst_context.addsetups("blockquote")
    local str = [[
\\startlinecorrection
\\blank[small]
\\startblockquote
]] .. lpegmatch(inline_parser, tab[1]) .. [[

\\stopblockquote
]]

    return tab[2] and str .. [[
\\blank[small]
\\startattribution
]] .. lpegmatch(inline_parser, tab[2]) .. [[
\\stopattribution
\\blank[small]
\\stoplinecorrection
]]  or str .. [[
\\blank[small]
\\stoplinecorrection
]] 
end

--function rst_context.table (str)
    --return [[
--\\startlinecorrection
--]] .. str .. [[

--\\stoplinecorrection
--]]
--end

function rst_context.grid_table (tab)
    local body = ""
    local nr = 1
    local head
    if tab.has_head then
        head = [[
\\setupTABLE[c][each]  [frame=off]
\\setupTABLE[r][each]  [frame=off]
%\\startlinecorrection
\\bTABLE[split=repeat,option=stretch]
\\bTABLEhead
]]
        while nr <= tab.head_end do
            local r = tab.rows[nr]
            local isempty = true
            for n=1, #r do
                local cell = r[n]
                if cell.variant == "normal" then
                    isempty = false
                    break
                end
            end

            if not isempty then
                local row = [[\\bTR]]
                for n=1, #r do
                    local c = r[n]
                    if not (c.parent or
                            c.variant == "separator") then
                        local celltext = lpegmatch(inline_parser, c.stripped)
                        if c.span.x or c.span.y then
                            local span_exp = "["
                            if c.span.x then
                                span_exp = span_exp .. "nc=" .. c.span.x .. ","
                            end
                            if c.span.y then
                                span_exp = span_exp .. "nr=" .. c.span.y
                            end
                            celltext  = span_exp .. "] " .. celltext

                        end

                        row = row .. "\n  " .. [[\\bTH ]] .. celltext .. [[\\eTH]]
                    end
                end
                head = head .. row .. "\n" .. [[\\eTR]] .. "\n"
            end
            nr = nr + 1
        end
        head = head .. [[
\\eTABLEhead
\\bTABLEbody
]] 
    else
        head = [[
\\setupTABLE[c][each]  [frame=off]
\\setupTABLE[r][each]  [frame=off]
%\\startlinecorrection
\\bTABLE[split=repeat,option=stretch]
\\bTABLEbody
]] 
    end
    while nr <= #tab.rows do
        local r = tab.rows[nr]
        local isempty = true
        for n=1, #r do
            local cell = r[n]
            if cell.variant == "normal" then
                isempty = false
                break
            end
        end

        if not isempty then
            local row = [[\\bTR]]
            for n=1, #r do
                local c = r[n]
                if not (c.parent or
                        c.variant == "separator") then
                    local celltext = lpegmatch(inline_parser, c.stripped)
                    if c.span.x or c.span.y then
                        local span_exp = "["
                        if c.span.x then
                            span_exp = span_exp .. "nc=" .. c.span.x .. ","
                        end
                        if c.span.y then
                            span_exp = span_exp .. "nr=" .. c.span.y
                        end
                        celltext  = span_exp .. "] " .. celltext

                    end

                    row = row .. "\n  " .. [[\\bTC ]] .. celltext .. [[\\eTC]]
                end
            end
            body = body .. row .. "\n" .. [[\\eTR]] .. "\n"
        end
        nr = nr + 1
    end
    local tail = [[
\\eTABLEbody
\\eTABLE
%\\stoplinecorrection
]]
    return head .. body .. tail
end


function rst_context.simple_table(tab)
    local head
    local nr = 1
    if tab.head_end then
        head = [[
\\setupTABLE[c][each]  [frame=off]
\\setupTABLE[r][each]  [frame=off]
%\\startlinecorrection
\\bTABLE[split=yes,option=stretch]
\\bTABLEhead
]]
        while nr <= tab.head_end do
            local row = tab[nr]
            if not row.ignore then
                dbg_write(">hr>" .. #row)
                head = head .. [[\\bTR]]
                for nc=1, #row do
                    local cell = row[nc]
                    dbg_write("%7s | ", cell.content)
                    local celltext = lpegmatch(inline_parser, cell.content)
                    if cell.span then
                        head = head .. stringformat([=[\\bTH[nc=%s]%s\\eTH]=], cell.span.x, celltext or "")
                    else
                        head = head .. [[\\bTH ]] .. celltext .. [[\\eTH]]
                    end
                end
                dbg_write("\n")
                head = head .. "\\\\eTR\n"
            end
            nr = nr + 1
        end

        head = head .. [[
\\eTABLEhead
\\bTABLEbody
]] 
    else
        head = [[
\\setupTABLE[c][each]  [frame=off]
\\setupTABLE[r][each]  [frame=off]
%\\startlinecorrection
\\bTABLE[split=yes,option=stretch]
\\bTABLEbody
]] 
    end
    local tail = [[
\\eTABLEbody
\\eTABLE
%\\stoplinecorrection
]]
    local body = ""
    while nr <= #tab do
        local row = tab[nr]
        if not row.ignore then
            dbg_write(">tr>" .. #row)
            body = body .. [[\\bTR]]
            for nc=1, #row do
                local cell = row[nc]
                dbg_write("%7s | ", cell.content)
                local celltext = lpegmatch(inline_parser, cell.content)
                if cell.span then
                    body = body .. stringformat([=[\\bTC[nc=%s]%s\\eTC]=], cell.span.x, celltext or "")
                else
                    body = body .. [[\\bTC ]] .. celltext .. [[\\eTC]]
                end
            end
            dbg_write("\n")
            body = body .. "\\\\eTR\n"
        end
        nr = nr + 1
    end
    return head .. body .. tail
end

function rst_context.footnote (label, content)
    local tf = rst_context.state.footnotes
    rst_context.addsetups("footnotes")
    if stringmatch(label, "^%d+$") then -- all digits
        tf.numbered[tonumber(label)] =
            rst_context.escape(lpegmatch(inline_parser, content))
    elseif label == "#" then --autonumber
        repeat -- until next unrequested number
            tf.autonumber = tf.autonumber + 1
        until tf.numbered[tf.autonumber] == nil
        tf.numbered[tf.autonumber] =
            rst_context.escape(lpegmatch(inline_parser, content))
    elseif stringmatch(label, "^#.+$") then
        local thelabel = stringmatch(label, "^#(.+)$")
        tf.autolabel[thelabel] =
            rst_context.escape(lpegmatch(inline_parser, content))
    elseif label == "*" then
        rst_context.addsetups("footnote_symbol")
        tf.symbol[#tf.symbol+1] =
            rst_context.escape(lpegmatch(inline_parser, content))
    else -- “citation reference” treated like ordinary footnote
        repeat -- until next unrequested number
            tf.autonumber = tf.autonumber + 1
        until tf.numbered[tf.autonumber] == nil
        tf.numbered[tf.autonumber] =
            rst_context.escape(lpegmatch(inline_parser, content))
    end
    return ""
end

--- hack to differentiate inline images
local special_substitutions = {
    image = "inline_image",
}

function rst_context.substitution_definition (subtext, directive, data)
    local special = special_substitutions[directive]
    if special then
        --- override; pass data directly
        directive = special
    else
        local tmp
        if data.first ~= "" then
            tmp = { data.first }
        else
            tmp = { }
        end
        data.first = nil
        for i=1, #data do -- paragraphs
            local current = tableconcat(data[i], "\n")
            --current = lpegmatch(inline_parser, current)
            --current = rst_context.escape(current)
            tmp[#tmp+1] = current
        end
        data = tableconcat(tmp, "\n\n")
        data = stringstrip(data)
    end
    subtext = stringgsub(subtext, "%s", "")
    rst_context.substitutions[subtext] = { directive = directive,
                                           data      = data }
    return ""
end

-- not to be confused with the directive definition table rst_directives
function rst_context.directive(directive, data)
    local fun = rst_directives[directive]
    if fun then
        rst_context.addsetups("directive")
        local result = ""
        result = fun(data)
        return result
    end
    return ""
end

-- vim:ft=lua:sw=4:ts=4:expandtab
