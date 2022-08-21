#!/usr/bin/env texlua
--------------------------------------------------------------------------------
--         FILE:  transliterator.lua
--        USAGE:  to be called by t-transliterator.mkiv
--  DESCRIPTION:  basic lua environment for the Transliterator module
-- REQUIREMENTS:  latest ConTeXt MkIV
--       AUTHOR:  Philipp Gesang (Phg), <phg42.2a@gmail.com>
--      CREATED:  2010-12-23 22:12:31+0100
--------------------------------------------------------------------------------
--

thirddata               = thirddata or { }
thirddata.translit      = thirddata.translit or { }
local translit          = thirddata.translit
translit.tables         = translit.tables  or { }
translit.methods        = translit.methods or { }
translit.deficient_font = "no"
translit.parser_cache   = { }

local utf8     = unicode and unicode.utf8 or utf8
local utf8byte = utf8.byte
local utf8len  = utf8.len

--------------------------------------------------------------------------------
-- Predefining vowel lists
--------------------------------------------------------------------------------
-- If you haven't heard of cyrillic scripts until now you might want to read
-- at least the first 15 pages of 
-- http://www.uni-giessen.de/partosch/eurotex99/berdnikov2.pdf
-- before you continue reading this file.
translit.ru_vowels = {"а", "е", "ё", "и", "й", "о", "у", "ы", "э", "ю", "я",
                      "А", "Е", "Ё", "И", "Й", "О", "У", "Ы", "Э", "Ю", "Я"}
translit.ru_consonants = {"б", "в", "г", "д", "ж", "з", "к", "л", "м", "н", 
                          "п", "р", "с", "т", "ф", "х", "ц", "ч", "ш", "щ",
                          "Б", "В", "Г", "Д", "Ж", "З", "К", "Л", "М", "Н", 
                          "П", "Р", "С", "Т", "Ф", "Х", "Ц", "Ч", "Ш", "Щ"}

-- Substitution tables are the very heart of the Transliterator.  Due to the
-- nature of languages and scripts exhaustive substitution is the simplest
-- method for transliterations and transcriptions unless they are one-to-one
-- mappings like those defined in ISO~9.
--
-- To achieve better reusability we split the tables into segments, the most
-- obvious being the \type{*_low} and \type{*_upp} variants for sets of lowercase
-- and uppercase characters.  Another set is constituted by e.~g. the
-- \type{ru_old*} tables that allow adding transcription of historical
-- characters if needed; by the way those are included in the default
-- transliteration mode \type{ru_old}.

-- Tables can be found in separate Lua files.
-- See {\tt
-- trans_tables_glag.lua
-- trans_tables_gr.lua
-- trans_tables_iso9.lua
-- trans_tables_scntfc.lua
-- and
-- trans_tables_trsc.lua.}

--------------------------------------------------------------------------------
-- Metatables allow for lazy concatenation.
--------------------------------------------------------------------------------

do
    -- This returns the Union of both key sets for the “+” operator.
    -- The values of the first table will be updated (read: overridden) by
    -- those given in the second.
    local Dict_add = {
        __add = function (dict_a, dict_b)
            assert (type(dict_a) == "table" and type(dict_b) == "table")
            local dict_result = setmetatable({}, Dict_add)

            for key, val in pairs(dict_a) do
                dict_result[key] = val
            end

            for key, val in pairs(dict_b) do
                dict_result[key] = val
            end
            return dict_result
        end
    }

    translit.make_add_dict = function (dict)
        return setmetatable(dict, Dict_add)
    end
end

--------------------------------------------------------------------------------
-- Auxiliary Functions
--------------------------------------------------------------------------------

-- Generate a rule pattern from hash table.
do
    local P, R, V = lpeg.P, lpeg.R, lpeg.V

    -- multi-char rules first
    translit.addrules = function (dict, rules)
        local by_length, occurring_lengths = { }, { }
        for chr, _ in next, dict do
            local l = utf8len(chr)
            if not by_length[l] then
                by_length[l] = { }
                occurring_lengths[#occurring_lengths+1] = l
            end
            by_length[l][#by_length[l]+1] = chr
        end
        table.sort(occurring_lengths)
        for i=#occurring_lengths, 1, -1 do
            local l = occurring_lengths[i]
            for _, chr in next, by_length[l] do
                rules = rules and rules + P(chr) or P(chr)
            end
        end
        return rules
    end

-- Modified version of Hans’s utf pattern (l-lpeg.lua).


    translit.utfchar = P{
        V"utf8one" + V"utf8two" + V"utf8three" + V"utf8four",

        utf8next  = R("\128\191"),
        utf8one   = R("\000\127"),
        utf8two   = R("\194\223") * V"utf8next",
        utf8three = R("\224\239") * V"utf8next" * V"utf8next",
        utf8four  = R("\240\244") * V"utf8next" * V"utf8next" * V"utf8next",
    }
end

-- We might want to have all the table data nicely formatted by \CONTEXT\ 
-- itself, here's how we'll do it.  \type{translit.show_tab(t)} handles a
-- single table \type{t}, builds a Natural TABLE out of its content and
-- hands it down to the machine for typesetting.  For debugging purposes it
-- does not only print the replacement pairs but shows their code points as
-- well.

-- handle the input chars and replacement values
local strempty = function (s) 
    if s == "" then return "nil"
    else 
        -- add the unicode positions of the replacements (can be more
        -- than one with composed diacritics
        local i = 1
        local r = ""
        repeat
            r = r .. utf8byte(s,i) .. " "
            i = i + 1
        until utf8byte(s,i) == nil
        return r
    end
end

function translit.show_tab (tab)
    -- Output a transliteration table, nicely formatted with natural tables.
    -- Lots of calls to context() but as it’s only a goodie this doesn’t
    -- really matter.
    local cnt = 0
    context.setupTABLE({"r"}, {"each"},     {style="\\tfx", align="center"})
    context.setupTABLE({"c"}, {"each"},     {frame="off"})
    context.setupTABLE({"r"}, {"each"},     {frame="off"})
    context.setupTABLE({"c"}, {"first"},    {style="italic"})
    context.setupTABLE({"r"}, {"first"},    {style="bold", topframe="on", bottomframe="on"})
    context.setupTABLE({"r"}, {"last"},     {style="bold", topframe="on", bottomframe="on"})
    context.bTABLE({split="yes", option="stretch"})
        context.bTABLEhead()
        context.bTR()
            context.bTH() context("number")         context.eTH()
            context.bTH() context("letters")        context.eTH()
            context.bTH() context("n")              context.eTH()
            context.bTH() context("replacement")    context.eTH()
            context.bTH() context("n")              context.eTH()
            context.bTH() context("bytes")          context.eTH()
            context.bTH() context("repl. bytes")    context.eTH()
        context.eTR()
        context.eTABLEhead()
        context.bTABLEbody()

        for key, val in next,tab do
            cnt = cnt + 1
            context.bTR()
            context.bTC() context(cnt)              context.eTC()
            context.bTC() context(key)              context.eTC()
            context.bTC() context(string.len(key))  context.eTC()
            context.bTC() context(val)              context.eTC()
            context.bTC() context(string.len(val))  context.eTC()
            context.bTC() context(strempty(key))    context.eTC()
            context.bTC() context(strempty(val))    context.eTC()
            context.eTR()
        end

        context.eTABLEbody()
        context.bTABLEfoot() context.bTR()
        context.bTC() context("number")       context.eTC()
        context.bTC() context("letters")      context.eTC()
        context.bTC() context("n")            context.eTC()
        context.bTC() context("replacement")  context.eTC()
        context.bTC() context("n")            context.eTC()
        context.bTC() context("bytes")        context.eTC()
        context.bTC() context("repl. bytes")  context.eTC()
        context.eTR()
        context.eTABLEfoot()
    context.eTABLE()
end

-- Having to pick out single tables for printing can be tedious, therefore we
-- let Lua do the job in our stead.  \type{translit.show_all_tabs()} calls
-- \type{translit.show_tab} on every table that is registered with
-- \type{translit.table} -- and uses its registered key as table heading.

function translit.show_all_tabs ()
    environment.loadluafile ("trans_tables_iso9")
    environment.loadluafile ("trans_tables_trsc")
    environment.loadluafile ("trans_tables_scntfc")
    environment.loadluafile ("trans_tables_sr")
    environment.loadluafile ("trans_tables_trsc")
    environment.loadluafile ("trans_tables_glag")
    environment.loadluafile ("trans_tables_gr")
    translit.gen_rules_en()
    translit.gen_rules_de()
    -- Output all translation tables that are registered within translit.tables.
    -- This will be quite unordered. 
    context.chapter("Transliterator Showing All Tables")
    for key, val in pairs(translit.tables) do
        context.section(key)
        translit.show_tab (val)
    end
end

-- for internal use only

translit.debug_count = 0

function translit.debug_next ()
    translit.debug_count = translit.debug_count + 1
    context("\\tfxx{\\bf translit debug msg. nr.~" .. translit.debug_count ..  "}")
end

--------------------------------------------------------------------------------
-- User-level Function
--------------------------------------------------------------------------------

-- \type{translit.transliterate(m, t)} constitutes the
-- metafunction that is called by the \type{\transliterate} command.
-- It loads the transliteration tables according to \type{method} and calls the
-- corresponding function.

-- Those supposedly are the most frequently used so it won’t hurt to preload
-- them.  The rest will be loaded on request.
environment.loadluafile ("trans_tables_iso9")

function translit.transliterate (method, text)
    local methods = translit.methods
    if not methods[method] then -- register tables and method
        if      method == "ru_transcript_de"     or
                method == "ru_transcript_de_exp" or -- experimental lpeg
                method == "ru_transcript_en"     or
                method == "ru_transcript_en_exp" or
                method == "ru_cz"                or
                method == "ocs_cz"               then
            environment.loadluafile ("trans_tables_trsc")
        elseif  method == "iso9_ocs"      or
                method == "iso9_ocs_hack" or
                method == "ocs"           or
                method == "ocs_gla"       then
            environment.loadluafile ("trans_tables_scntfc")
        elseif  method:match("^sr_") then
            environment.loadluafile ("trans_tables_sr")
        elseif  method:match("^bg_") then -- only bg_de for now
            environment.loadluafile ("trans_tables_bg")
        elseif  method == "gr"   or
                method == "gr_n" then
            environment.loadluafile ("trans_tables_gr")
        end
    end

    if translit.__script then
        return methods[method](text)
    end
    context ( methods[method](text) )
end

-- vim:sw=4:ts=4:expandtab:ft=lua
