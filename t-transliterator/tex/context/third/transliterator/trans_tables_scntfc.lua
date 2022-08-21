--===========================================================================--
--                      Other transliterations                               --
--===========================================================================--

local translit  = thirddata.translit
local pcache    = translit.parser_cache
local lpegmatch = lpeg.match

-- The following are needed because ISO 9 does not cover old Slavonic
-- characters that became obsolete before the advent of гражданский шрифт.

-- Please note that these mappings are not bijective so don't expect the result 
-- to be easily revertible (by machines).

-- Source p. 77 of
-- http://www.schaeken.nl/lu/research/online/publications/akslstud/as2_03_kapitel_c.pdf

if not translit.done_ocs then
    -----------------------------------------------------------------------
    -- Lowercase and uppercase letter Uk -- “scientific transliteration” --
    -----------------------------------------------------------------------

    translit.ocs_uk = translit.make_add_dict{
    ["oу"] = "u",
    ["оу"] = "u",
    ["Оу"] = "U",
    }
    -----------------------------------------------------------------------------
    -- Lowercase pre-Peter cyrillic characters -- “scientific transliteration” --
    -----------------------------------------------------------------------------

    translit.ocs_low = translit.make_add_dict{
    ["а"] = "a",
    ["б"] = "b",
    ["в"] = "v",
    ["г"] = "g",
    ["д"] = "d",
    ["є"] = "e",
    ["ж"] = "ž",
    ["ꙃ"] = "ʒ",  -- U+0292, alternative: ǳ U+01f3
    ["ѕ"] = "ʒ",
    ["ꙁ"] = "z",
    ["з"] = "z",
    ["и"] = "i",
    ["і"] = "i",
    ["ї"] = "i",
    ["ћ"] = "g’",
    ["к"] = "k",
    ["л"] = "l",
    ["м"] = "m",
    ["н"] = "n",
    ["о"] = "o",
    ["п"] = "p",
    ["р"] = "r",
    ["с"] = "s",
    ["т"] = "t",
    ["у"] = "u",
    ["ѹ"] = "u",
    ["ꙋ"] = "u",
    ["ф"] = "f",
    ["х"] = "x",
    ["ѡ"] = "o",  --"ō",
    ["ѿ"] = "ot", -- U+047f
    ["ѽ"] = "o!", -- U+047d
    ["ꙍ"] = "o!", -- U+064D
    ["ц"] = "c",
    ["ч"] = "č",
    ["ш"] = "š",
    ["щ"] = "št",
    ["ъ"] = "ъ",
    ["ы"] = "y",
    ["ꙑ"] = "y",  -- Old jery (U+a651) as used e.g. by the OCS Wikipedia.
    ["ь"] = "ь",
    ["ѣ"] = "ě",
    ["ю"] = "ju",
    ["ꙗ"] = "ja",
    ["ѥ"] = "je",
    ["ѧ"] = "ę",
    ["ѩ"] = "ję",
    ["ѫ"] = "ǫ",
    ["ѭ"] = "jǫ",
    ["ѯ"] = "ks",
    ["ѱ"] = "ps",
    ["ѳ"] = "th",
    ["ѵ"] = "ü",
    }

    translit.tables["OCS \\quotation{scientific} transliteration lowercase"] = translit.ocs_low

    -----------------------------------------------------------------------------
    -- Uppercase pre-Peter cyrillic characters -- “scientific transliteration” --
    -----------------------------------------------------------------------------

    translit.ocs_upp = translit.make_add_dict{
    ["А"] = "A",
    ["Б"] = "B",
    ["В"] = "V",
    ["Г"] = "G",
    ["Д"] = "D",
    ["Є"] = "E",
    ["Ж"] = "Ž",
    ["Ꙃ"] = "Ʒ",  -- U+01b7, alternative: ǲ U+01f2
    ["Ѕ"] = "Ʒ",
    ["Ꙁ"] = "Z",
    ["З"] = "Z",
    ["И"] = "I",
    ["І"] = "I",
    ["Ї"] = "I",
    ["Ћ"] = "G’",
    ["К"] = "K",
    ["Л"] = "L",
    ["М"] = "M",
    ["Н"] = "N",
    ["О"] = "O",
    ["П"] = "P",
    ["Р"] = "R",
    ["С"] = "S",
    ["Т"] = "T",
    ["У"] = "u",
    ["Ѹ"] = "U",
    --["ꙋ"] = "U",
    ["Ф"] = "F",
    ["Х"] = "X",
    ["Ѡ"] = "Ō",
    ["Ѿ"] = "Ot", -- U+047c
    ["Ѽ"] = "O!", -- U+047e
    ["Ꙍ"] = "O!", -- U+064C
    ["Ц"] = "C",
    ["Ч"] = "Č",
    ["Ш"] = "Š",
    ["Щ"] = "Št",
    ["Ъ"] = "Ŭ",
    ["Ы"] = "Y",
    ["Ꙑ"] = "Y",  -- U+a650
    ["Ь"] = "Ĭ",
    ["Ѣ"] = "Ě",
    ["Ю"] = "Ju",
    ["Ꙗ"] = "Ja",
    ["Ѥ"] = "Je",
    ["Ѧ"] = "Ę",
    ["Ѩ"] = "Ję",
    ["Ѫ"] = "Ǫ",
    ["Ѭ"] = "Jǫ",
    ["Ѯ"] = "Ks",
    ["Ѱ"] = "Ps",
    ["Ѳ"] = "Th",
    ["Ѵ"] = "Ü",
    }

    translit.tables["OCS \\quotation{scientific} transliteration uppercase"] = translit.ocs_upp

    -- Note on the additional tables: these cover characters that are not defined
    -- in ISO 9 but have a “scientific” transliteration.  You may use them as
    -- complementary mapping to ISO 9, trading off homogenity for completeness.

    ----------------------------------------------------------------------------------------
    -- Lowercase additional pre-Peter cyrillic characters -- “scientific transliteration” --
    ----------------------------------------------------------------------------------------

    translit.ocs_add_low = translit.make_add_dict{
    ["ѕ"] = "dz", -- Mapped to ẑ in ISO 9 (Macedonian …)
    ["ѯ"] = "ks",
    ["ѱ"] = "ps",
    ["ѡ"] = "ô",
    ["ѿ"] = "ot", -- U+047f
    ["ѫ"] = "ǫ",  -- Mapped to ǎ in ISO 9.
    ["ѧ"] = "ę",
    ["ѭ"] = "jǫ",
    ["ѩ"] = "ję",
    ["ѥ"] = "je",
    ["ѹ"] = "u",  -- Digraph uk.
    ["ꙋ"] = "u",  -- Monograph uk, U+a64b.  (No glyph yet in the "fixed" font in February 2010 …)
    ["ꙑ"] = "y",  -- U+a651
    }

    translit.tables["OCS \\quotation{scientific} transliteration additional lowercase"] = translit.ocs_add_low

    ----------------------------------------------------------------------------------------
    -- Uppercase additional pre-Peter cyrillic characters -- “scientific transliteration” --
    ----------------------------------------------------------------------------------------

    translit.ocs_add_upp = translit.make_add_dict{
    ["Ѕ"] = "Dz",
    ["Ѯ"] = "Ks",
    ["Ѱ"] = "Ps",
    ["Ѡ"] = "Ô",
    ["Ѿ"] = "ot",
    ["Ѫ"] = "Ǫ",
    ["Ѧ"] = "Ę",
    ["Ѭ"] = "Jǫ",
    ["Ѩ"] = "Ję",
    ["Ѥ"] = "Je",
    ["Ѹ"] = "U",  -- Digraph uk.
    --["Ꙋ"] = "U",  -- Monograph Uk, U+a64a.
    ["Ꙑ"] = "Y",  -- U+a650
    }

    translit.tables["OCS \\quotation{scientific} transliteration additional uppercase"] = translit.ocs_add_upp
    translit.done_ocs = true
end

--===========================================================================--
--                              End Of Tables                                --
--===========================================================================--

local function scientific (mode)
    local P, Cs = lpeg.P, lpeg.Cs
    local utfchar = translit.utfchar
    local addrules = translit.addrules

    local cyr = translit.make_add_dict{}
    local cyruk, p_cyruk, p_cyr, scientific_parser

    if mode == "iso9_ocs" or mode == "iso9_ocs_hack" then

        environment.loadluafile("trans_tables_iso9")
        cyr = translit.ocs_add_low
            + translit.ocs_add_upp
            + translit.ocs_low
            + translit.ru_upp
            + translit.ru_low
            + translit.ru_old_upp
            + translit.ru_old_low
            + translit.non_ru_upp
            + translit.non_ru_low
            + translit.ocs_upp

        if translit.deficient_font == "yes" then
            cyr = cyr + translit.ru_jer_hack
        end

        p_cyr = addrules(cyr, p_cyr)

        scientific_parser = Cs((p_cyr / cyr + utfchar)^0)

    elseif mode == ("ocs") then

        cyr = translit.ocs_low + translit.ocs_upp

        p_cyruk = addrules(translit.ocs_uk, cyruk)
        p_cyr   = addrules(cyr,             p_cyr)

        scientific_parser = Cs((p_cyruk / translit.ocs_uk
                              + p_cyr   / cyr
                              + utfchar)^0)

    elseif mode == ("ocs_gla") then
        environment.loadluafile( "trans_tables_glag")
        cyr = translit.ocs_gla_low + translit.ocs_gla_upp

        p_cyr = addrules(cyr, p_cyr)
        scientific_parser = Cs((p_cyr / cyr + utfchar)^0)
    end

    return scientific_parser
end


translit.methods["iso9_ocs"] = function (text)
    local pname = "iso9_ocs" .. translit.deficient_font
    local p     = pcache[pname]
    if not p then
        p = scientific("iso9_ocs")
        pcache[pname] = p
    end
    return lpegmatch(p, text)
end

translit.methods["ocs"] = function (text)
    local p = pcache["ocs"]
    if not p then
        p = scientific("ocs")
        pcache["ocs"] = p
    end
    return lpegmatch(p, text)
end

translit.methods["ocs_gla"] = function (text)
    local p = pcache["ocs_gla"]
    if not p then
        p = scientific("ocs_gla")
        pcache["ocs_gla"] = p
    end
    return lpegmatch(p, text)
end

-- vim:ft=lua:ts=4:sw=4
