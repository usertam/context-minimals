
--===========================================================================--
--                              Glagolica                                    --
--===========================================================================--

local translit = thirddata.translit

-------------------------------------------
-- Lowercase Glagolitic Transliteration  --
-------------------------------------------

if not translit.done_glagolica then
    translit.ocs_gla_low = translit.make_add_dict{
    ["ⰰ"] = "a",  -- GLAGOLITIC SMALL LETTER AZU
    ["ⰱ"] = "b",  -- GLAGOLITIC SMALL LETTER BUKY
    ["ⰲ"] = "v",  -- GLAGOLITIC SMALL LETTER VEDE
    ["ⰳ"] = "g",  -- GLAGOLITIC SMALL LETTER GLAGOLI
    ["ⰴ"] = "d",  -- GLAGOLITIC SMALL LETTER DOBRO
    ["ⰵ"] = "e",  -- GLAGOLITIC SMALL LETTER YESTU
    ["ⰶ"] = "ž",  -- GLAGOLITIC SMALL LETTER ZHIVETE
    ["ⰷ"] = "ʒ",  -- GLAGOLITIC SMALL LETTER DZELO
    ["ⰸ"] = "z",  -- GLAGOLITIC SMALL LETTER ZEMLJA
    ["ⰹ"] = "i",  -- GLAGOLITIC SMALL LETTER IZHE
    ["ⰺ"] = "i",  -- GLAGOLITIC SMALL LETTER INITIAL IZHE
    ["ⰻ"] = "i",  -- GLAGOLITIC SMALL LETTER I
    ["ⰼ"] = "g’", -- GLAGOLITIC SMALL LETTER DJERVI
    ["ⰽ"] = "k",  -- GLAGOLITIC SMALL LETTER KAKO
    ["ⰾ"] = "l",  -- GLAGOLITIC SMALL LETTER LJUDIJE
    ["ⰿ"] = "m",  -- GLAGOLITIC SMALL LETTER MYSLITE
    ["ⱀ"] = "n",  -- GLAGOLITIC SMALL LETTER NASHI
    ["ⱁ"] = "o",  -- GLAGOLITIC SMALL LETTER ONU
    ["ⱂ"] = "p",  -- GLAGOLITIC SMALL LETTER POKOJI
    ["ⱃ"] = "r",  -- GLAGOLITIC SMALL LETTER RITSI
    ["ⱄ"] = "s",  -- GLAGOLITIC SMALL LETTER SLOVO
    ["ⱅ"] = "t",  -- GLAGOLITIC SMALL LETTER TVRIDO
    ["ⱆ"] = "u",  -- GLAGOLITIC SMALL LETTER UKU
    ["ⱇ"] = "f",  -- GLAGOLITIC SMALL LETTER FRITU
    ["ⱈ"] = "x",  -- GLAGOLITIC SMALL LETTER HERU
    ["ⱉ"] = "o",  -- GLAGOLITIC SMALL LETTER OTU
    ["ⱊ"] = "?",  -- GLAGOLITIC SMALL LETTER PE
    ["ⱋ"] = "št", -- GLAGOLITIC SMALL LETTER SHTA
    ["ⱌ"] = "c",  -- GLAGOLITIC SMALL LETTER TSI
    ["ⱍ"] = "č",  -- GLAGOLITIC SMALL LETTER CHRIVI
    ["ⱎ"] = "š",  -- GLAGOLITIC SMALL LETTER SHA
    ["ⱏ"] = "ъ",  -- GLAGOLITIC SMALL LETTER YERU
    ["ⱐ"] = "ь",  -- GLAGOLITIC SMALL LETTER YERI
    ["ⱑ"] = "ě",  -- GLAGOLITIC SMALL LETTER YATI
    ["ⱒ"] = "x",  -- GLAGOLITIC SMALL LETTER SPIDERY HA
    ["ⱓ"] = "ju", -- GLAGOLITIC SMALL LETTER YU
    ["ⱔ"] = "ę",  -- GLAGOLITIC SMALL LETTER SMALL YUS
    ["ⱕ"] = "y̨",  -- GLAGOLITIC SMALL LETTER SMALL YUS WITH TAIL 
    ["ⱖ"] = "??", -- GLAGOLITIC SMALL LETTER YO
    ["ⱗ"] = "ję", -- GLAGOLITIC SMALL LETTER IOTATED SMALL YU
    ["ⱘ"] = "ǫ",  -- GLAGOLITIC SMALL LETTER BIG YUS
    ["ⱙ"] = "jǫ", -- GLAGOLITIC SMALL LETTER IOTATED BIG YUS
    ["ⱚ"] = "th", -- GLAGOLITIC SMALL LETTER FITA
    ["ⱛ"] = "ü",  -- GLAGOLITIC SMALL LETTER IZHITSA
    ["ⱜ"] = "??", -- GLAGOLITIC SMALL LETTER SHTAPIC
    ["ⱝ"] = "??", -- GLAGOLITIC SMALL LETTER TROKUTASTI A
    ["ⱞ"] = "m",  -- GLAGOLITIC SMALL LETTER LATINATE MYSLITE
    }

    translit.tables["Glagolica transliteration for OCS lowercase"] = translit.ocs_gla_low

    ------------------------------------------------
    -- Uppercase (?!) Glagolitic Transliteration  --
    ------------------------------------------------

    translit.ocs_gla_upp = translit.make_add_dict{
    ["Ⰰ"] = "A",  -- GLAGOLITIC CAPITAL LETTER AZU
    ["Ⰱ"] = "B",  -- GLAGOLITIC CAPITAL LETTER BUKY
    ["Ⰲ"] = "V",  -- GLAGOLITIC CAPITAL LETTER VEDE
    ["Ⰳ"] = "G",  -- GLAGOLITIC CAPITAL LETTER GLAGOLI
    ["Ⰴ"] = "D",  -- GLAGOLITIC CAPITAL LETTER DOBRO
    ["Ⰵ"] = "E",  -- GLAGOLITIC CAPITAL LETTER YESTU
    ["Ⰶ"] = "Ž",  -- GLAGOLITIC CAPITAL LETTER ZHIVETE
    ["Ⰷ"] = "Ʒ",  -- GLAGOLITIC CAPITAL LETTER DZELO
    ["Ⰸ"] = "Z",  -- GLAGOLITIC CAPITAL LETTER ZEMLJA
    ["Ⰹ"] = "I",  -- GLAGOLITIC CAPITAL LETTER IZHE
    ["Ⰺ"] = "I",  -- GLAGOLITIC CAPITAL LETTER INITIAL IZHE
    ["Ⰻ"] = "I",  -- GLAGOLITIC CAPITAL LETTER I
    ["Ⰼ"] = "G’", -- GLAGOLITIC CAPITAL LETTER DJERVI
    ["Ⰽ"] = "K",  -- GLAGOLITIC CAPITAL LETTER KAKO
    ["Ⰾ"] = "L",  -- GLAGOLITIC CAPITAL LETTER LJUDIJE
    ["Ⰿ"] = "M",  -- GLAGOLITIC CAPITAL LETTER MYSLITE
    ["Ⱀ"] = "N",  -- GLAGOLITIC CAPITAL LETTER NASHI
    ["Ⱁ"] = "O",  -- GLAGOLITIC CAPITAL LETTER ONU
    ["Ⱂ"] = "P",  -- GLAGOLITIC CAPITAL LETTER POKOJI
    ["Ⱃ"] = "R",  -- GLAGOLITIC CAPITAL LETTER RITSI
    ["Ⱄ"] = "S",  -- GLAGOLITIC CAPITAL LETTER SLOVO
    ["Ⱅ"] = "T",  -- GLAGOLITIC CAPITAL LETTER TVRIDO
    ["Ⱆ"] = "U",  -- GLAGOLITIC CAPITAL LETTER UKU
    ["Ⱇ"] = "F",  -- GLAGOLITIC CAPITAL LETTER FRITU
    ["Ⱈ"] = "X",  -- GLAGOLITIC CAPITAL LETTER HERU
    ["Ⱉ"] = "O",  -- GLAGOLITIC CAPITAL LETTER OTU
    ["Ⱊ"] = "?",  -- GLAGOLITIC CAPITAL LETTER PE
    ["Ⱋ"] = "Št", -- GLAGOLITIC CAPITAL LETTER SHTA
    ["Ⱌ"] = "C",  -- GLAGOLITIC CAPITAL LETTER TSI
    ["Ⱍ"] = "Č",  -- GLAGOLITIC CAPITAL LETTER CHRIVI
    ["Ⱎ"] = "Š",  -- GLAGOLITIC CAPITAL LETTER SHA
    ["Ⱏ"] = "Ъ",  -- GLAGOLITIC CAPITAL LETTER YERU
    ["Ⱐ"] = "Ь",  -- GLAGOLITIC CAPITAL LETTER YERI
    ["Ⱑ"] = "Ě",  -- GLAGOLITIC CAPITAL LETTER YATI
    ["Ⱒ"] = "X",  -- GLAGOLITIC CAPITAL LETTER SPIDERY HA
    ["Ⱓ"] = "Ju", -- GLAGOLITIC CAPITAL LETTER YU
    ["Ⱔ"] = "Ę",  -- GLAGOLITIC CAPITAL LETTER SMALL YUS
    ["Ⱕ"] = "Y̨",  -- GLAGOLITIC CAPITAL LETTER SMALL YUS WITH TAIL
    ["Ⱖ"] = "??", -- GLAGOLITIC CAPITAL LETTER YO
    ["Ⱗ"] = "Ję", -- GLAGOLITIC CAPITAL LETTER IOTATED SMALL YUS
    ["Ⱘ"] = "Ǫ",  -- GLAGOLITIC CAPITAL LETTER BIG YUS
    ["Ⱙ"] = "Jǫ", -- GLAGOLITIC CAPITAL LETTER IOTATED BIG YUS
    ["Ⱚ"] = "Th", -- GLAGOLITIC CAPITAL LETTER FITA
    ["Ⱛ"] = "Ü",  -- GLAGOLITIC CAPITAL LETTER IZHITSA
    ["Ⱜ"] = "??", -- GLAGOLITIC CAPITAL LETTER SHTAPIC
    ["Ⱝ"] = "??", -- GLAGOLITIC CAPITAL LETTER TROKUTASTI A
    ["Ⱞ"] = "M",  -- GLAGOLITIC CAPITAL LETTER LATINATE MYSLIT
    }

    translit.tables["Glagolica transliteration for OCS uppercase"] = translit.ocs_gla_upp

    translit.done_glagolica = true
end

--===========================================================================--
--                              End Of Tables                                --
--===========================================================================--


