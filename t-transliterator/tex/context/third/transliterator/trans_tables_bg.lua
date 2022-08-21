--===========================================================================--
--                            Bulgarian                                      --
--===========================================================================--

local translit  = thirddata.translit
local pcache    = translit.parser_cache
local lpegmatch = lpeg.match

if not translit.done_bg then
    ---------------------------------------------------------------------------
    -- Uppercase Bulgarian -> „scientific“ transliteration                   --
    ---------------------------------------------------------------------------

    translit.bg_upp = translit.make_add_dict{
        ["А"] = "A",
        ["Б"] = "B",
        ["В"] = "V",
        ["Г"] = "G",
        ["Д"] = "D",
        ["Е"] = "E",
        ["Ж"] = "Ž",
        ["З"] = "Z",
        ["И"] = "I",
        ["Й"] = "J",
        ["К"] = "K",
        ["Л"] = "L",
        ["М"] = "M",
        ["Н"] = "N",
        ["О"] = "O",
        ["П"] = "P",
        ["Р"] = "R",
        ["С"] = "S",
        ["Т"] = "T",
        ["У"] = "U",
        ["Ф"] = "F",
        ["Х"] = "Ch",
        ["Ц"] = "C",
        ["Ч"] = "Č",
        ["Ш"] = "Š",
        ["Щ"] = "Št",
        ["Ъ"] = "Ă",
        ["Ь"] = "′",
        ["Ю"] = "Ju",
        ["Я"] = "Ja",
    }
    translit.tables["Bulgarian \\quotation{scientific} transliteration uppercase"] = translit.bg_upp

    ---------------------------------------------------------------------------
    -- Lowercase Bulgarian -> „scientific“ transliteration                   --
    ---------------------------------------------------------------------------
    translit.bg_low = translit.make_add_dict{
        ["а"] = "a",
        ["б"] = "b",
        ["в"] = "v",
        ["г"] = "g",
        ["д"] = "d",
        ["е"] = "e",
        ["ж"] = "ž",
        ["з"] = "z",
        ["и"] = "i",
        ["й"] = "j",
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
        ["ф"] = "f",
        ["х"] = "ch",
        ["ц"] = "c",
        ["ч"] = "č",
        ["ш"] = "š",
        ["щ"] = "št",
        ["ъ"] = "ă",
        ["ь"] = "′",
        ["ю"] = "ju",
        ["я"] = "ja",
    }

    translit.tables["Bulgarian \\quotation{scientific} transliteration lowercase"] = translit.bg_low

    translit.done_bg = true
end

local P, Cs    = lpeg.P, lpeg.Cs
local addrules = translit.addrules
local utfchar  = translit.utfchar

local function bulgarian (mode)
    local bulgarian_parser
    if mode == "de" then
        local bg = translit.bg_upp + translit.bg_low
        local p_bg = addrules(bg)
        bulgarian_parser = Cs((p_bg / bg + utfchar)^0)
    else
        return nil
    end
    return bulgarian_parser
end

translit.methods["bg_de"] = function (text)
    local p = pcache["bg_de"]
    if not p then
        p = bulgarian("de")
        pcache["bg_de"] = p
    end
    return p and lpegmatch(p, text) or ""
end

-- vim:ft=lua:sw=4:ts=4
