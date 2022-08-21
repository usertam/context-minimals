--===================================================================--
--                 Legacy national transliterations                  --
--===================================================================--

local translit = thirddata.translit
local addrules = translit.addrules
local utfchar  = translit.utfchar

local lpegmatch = lpeg.match
local tablepack = table.pack -- lua 5.2 precaution

---------------------------------
-- German simple transcription --
---------------------------------
-- Reference:   „DUDEN. Rechtschreibung der deutschen Sprache“;
--              20. Aufl.,
--              Mannheim et. al. 1991.

if lpeg.version() == "0.9" and not translit.done_ru_trsc_de then

    --------------------------------------------------------
    -- Lowercase German simple transcription---first pass --
    --------------------------------------------------------

    translit.ru_trsc_low_first = translit.make_add_dict{
      [" е"] = " je",
      ["ъе"] = "je",
      ["ье"] = "je",
      [" ё"] = " jo",
      ["ъё"] = "jo",
      ["ьё"] = "jo",
      ["жё"] = "scho",
      ["чё"] = "tscho",
      ["шё"] = "scho",
      ["щё"] = "schtscho",
      ["ье"] = "je",
      ["ьи"] = "ji",
      ["ьо"] = "jo",
      ["ий"] = "i",
      ["ый"] = "y",
      ["кс"] = "x"
    }

    translit.tables["German transcription first pass lowercase"]
      = translit.ru_trsc_low_first

    --------------------------------------------------------
    -- Uppercase German simple transcription---first pass --
    --------------------------------------------------------

    translit.ru_trsc_upp_first = translit.make_add_dict{
      [" Е"] = " Je",
      ["Ъe"] = "Je",  -- Pedantic, isn't it?
      ["Ье"] = "Je",
      [" Ё"]  = "Jo",
      ["Ъё"] = "Jo",
      ["Ьё"] = "Jo",
      ["Жё"] = "Scho",
      ["Чё"] = "Tscho",
      ["Шё"] = "Scho",
      ["Щё"] = "Schtscho",
      ["Кс"] = "ks"
    }

    translit.tables["German transcription first pass uppercase"]
      = translit.ru_trsc_upp_first

    -------------------------------------------
    -- Lowercase German simple transcription --
    -------------------------------------------

    translit.ru_trsc_low = translit.make_add_dict{
      ["а"] = "a",
      ["б"] = "b",
      ["в"] = "w",
      ["г"] = "g",
      ["д"] = "d",
      ["е"] = "e",
      ["ё"] = "jo",
      ["ж"] = "sch",
      ["з"] = "s",
      ["и"] = "i",
      ["й"] = "i",
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
      ["ц"] = "z",
      ["ч"] = "tsch",
      ["ш"] = "sch",
      ["щ"] = "schtsch",
      ["ъ"] = "",
      ["ы"] = "y",
      ["ь"] = "",
      ["э"] = "e",
      ["ю"] = "ju",
      ["я"] = "ja" 
    }

    translit.tables["German transcription second pass lowercase"]
      = translit.ru_trsc_low

    -------------------------------------------
    -- Uppercase German simple transcription --
    -------------------------------------------

    translit.ru_trsc_upp = translit.make_add_dict{
      ["А"] = "A",
      ["Б"] = "B",
      ["В"] = "W",
      ["Г"] = "G",
      ["Д"] = "D",
      ["Е"] = "E",
      ["Ё"] = "Jo",
      ["Ж"] = "Sch",
      ["З"] = "S",
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
      ["Ц"] = "Z",
      ["Ч"] = "Tsch",
      ["Ш"] = "Sch",
      ["Щ"] = "Schtsch",
      ["Ъ"] = "",
      ["Ы"] = "Y",
      ["Ь"] = "",
      ["Э"] = "E",
      ["Ю"] = "Ju",
      ["Я"] = "Ja" 
    }

    translit.tables["German transcription second pass uppercase"]
      = translit.ru_trsc_upp

    translit.ru_trsc_iy = {"и", "ы", "И", "Ы"}

    function translit.gen_rules_de()
        -- The following are more interesting than the previous tables
        -- because they implement various rules.  For instance the
        -- table \type{translit.ru_trsc_irule} holds a substitution
        -- dictionary for all possible combinations (including nonsense
        -- galore) of a vowel preceding an “й” (Russian short i)
        -- preceding a consonant; here we access the sets of Russian
        -- vowels as well consonants that were defined earlier.

        -- The й-rule, VйC -> ViC
        translit.ru_trsc_irule = translit.make_add_dict{}
        for _, vow in ipairs(translit.ru_vowels) do
        for _, cons in ipairs(translit.ru_consonants) do
            local new_ante = vow .. "й" .. cons
            local new_post = vow .. "i" .. cons
            translit.ru_trsc_irule[new_ante] = new_post
        end
        end

        translit.tables["German transcription i-rule"]
          = translit.ru_trsc_irule

        -- The second й-rule, йV -> jV && [иы]йC -> [иы]jC
        translit.ru_trsc_jrule = {}
        for _, vow in ipairs(translit.ru_vowels) do
        local new_ante = "й" .. vow
        local new_post = "j" .. vow
        translit.ru_trsc_jrule[new_ante] = new_post
        end

        for _, cons in ipairs(translit.ru_consonants) do
        for _, iy in ipairs(translit.ru_trsc_iy) do
            local new_ante = iy .. "й" .. cons
            local new_post = iy .. "j" .. cons
            translit.ru_trsc_jrule[new_ante] = new_post
        end
        end

        translit.tables["German transcription j-rule"]
          = translit.ru_trsc_jrule

        -- The с-rule, VсV -> VssV
        translit.ru_trsc_srule = translit.make_add_dict{}
        for i, vow_1 in ipairs(translit.ru_vowels) do
        for j, vow_2 in ipairs(translit.ru_vowels) do
        local new_ante = vow_1 .. "с" .. vow_2
        local new_post = vow_1 .. "ss" .. vow_2
            translit.ru_trsc_srule[new_ante] = new_post
        end
        end

        translit.tables["German transcription s-rule"]
          = translit.ru_trsc_srule

        -- The sharp-s-rule, Vсх -> Vßх
        translit.ru_trsc_sharpsrule = translit.make_add_dict{}
        for i, vow in ipairs(translit.ru_vowels) do
        local new_ante = vow .. "сх"
        local new_post = vow .. "ßх"
        translit.ru_trsc_sharpsrule[new_ante] = new_post
        end

        translit.tables["German transcription sharp-s-rule"]
          = translit.ru_trsc_sharpsrule

        -- The е-rule, Vе -> Vje
        translit.ru_trsc_jerule = translit.make_add_dict{}
        for i, vow in ipairs(translit.ru_vowels) do
        local new_ante = vow .. "е"
        local new_post = vow .. "je"
        translit.ru_trsc_jerule[new_ante] = new_post
        end

        translit.tables["German transcription je-rule"]
          = translit.ru_trsc_jerule

        -- The ё-rule, Vё -> Vjo
        -- This should be redundant as [жцчшщ]ё -> o, else ё -> jo .
        -- Somebody should teach those DUDEN-guys parsimony.
        translit.ru_trsc_jorule = translit.make_add_dict{}
        for i, vow in ipairs(translit.ru_vowels) do
        local new_ante = vow .. "ё"
        local new_post = vow .. "jo"
        translit.ru_trsc_jorule[new_ante] = new_post
        end

        translit.tables["German transcription (redundant) jo-rule"]
          = translit.ru_trsc_jorule

    end

    translit.gen_rules_de()
    translit.done_ru_trsc_de = true
end

if lpeg.version() == "0.10" and not translit.done_ru_trsc_de then

    -- This is about *eight* times as fast as the old pattern. Just
    -- waiting for v0.10 to make it into luatex.

    local de_tables = { }

    --------------------------------------------------------
    -- Lowercase German simple transcription---first pass --
    --------------------------------------------------------

    de_tables[1] = { -- lowercase initial
        [" е"] = " je",  ["ъе"] = "je",       ["ье"] = "je",
        [" ё"] = " jo",  ["ъё"] = "jo",       ["ьё"] = "jo",
        ["жё"] = "scho", ["цё"] = "scho",     ["чё"] = "zo",
        ["шё"] = "scho", ["щё"] = "schtscho", ["ье"] = "je",
        ["ьи"] = "ji",   ["ьо"] = "jo",       ["ий"] = "i",
        ["ый"] = "y",    ["кс"] = "x" -- Extraordinarily stupid one.
    }
    translit.tables["German transcription first pass lowercase"]
      = de_tables[1]

    --------------------------------------------------------
    -- Uppercase German simple transcription---first pass --
    --------------------------------------------------------

    de_tables[2] = { -- uppercase initial
        [" Е"] = " Je",      ["Ъe"] = "Je",    ["Ье"] = "Je",
        [" Ё"]  = "Jo",      ["Ъё"] = "Jo",    ["Ьё"] = "Jo",
        ["Жё"] = "Scho",     ["Чё"] = "Tscho", ["Шё"] = "Scho",
        ["Щё"] = "Schtscho", ["Кс"] = "ks"
    }
    translit.tables["German transcription first pass uppercase"]
      = de_tables[2]

    -------------------------------------------
    -- Lowercase German simple transcription --
    -------------------------------------------

    de_tables[3] = { -- lowercase
        ["а"] = "a",    ["б"] = "b",   ["в"] = "w",  ["г"] = "g",
        ["д"] = "d",    ["е"] = "e",   ["ё"] = "jo", ["ж"] = "sch",
        ["з"] = "s",    ["и"] = "i",   ["й"] = "i",  ["к"] = "k",
        ["л"] = "l",    ["м"] = "m",   ["н"] = "n",  ["о"] = "o",
        ["п"] = "p",    ["р"] = "r",   ["с"] = "s",  ["т"] = "t",
        ["у"] = "u",    ["ф"] = "f",   ["х"] = "ch", ["ц"] = "z",
        ["ч"] = "tsch", ["ш"] = "sch", ["щ"] = "schtsch",
        ["ъ"] = "",     ["ы"] = "y",   ["ь"] = "",   ["э"] = "e",
        ["ю"] = "ju",   ["я"] = "ja" 
    }
    translit.tables["German transcription second pass lowercase"]
      = de_tables[3]

    -------------------------------------------
    -- Uppercase German simple transcription --
    -------------------------------------------

    de_tables[4] = { -- uppercase
        ["А"] = "A",    ["Б"] = "B",   ["В"] = "W",      ["Г"] = "G",
        ["Д"] = "D",    ["Е"] = "E",   ["Ё"] = "Jo",     ["Ж"] = "Sch",
        ["З"] = "S",    ["И"] = "I",   ["Й"] = "J",      ["К"] = "K",
        ["Л"] = "L",    ["М"] = "M",   ["Н"] = "N",      ["О"] = "O",
        ["П"] = "P",    ["Р"] = "R",   ["С"] = "S",      ["Т"] = "T",
        ["У"] = "U",    ["Ф"] = "F",   ["Х"] = "Ch",     ["Ц"] = "Z",
        ["Ч"] = "Tsch", ["Ш"] = "Sch", ["Щ"] = "Schtsch",["Ъ"] = "",
        ["Ы"] = "Y",    ["Ь"] = "",    ["Э"] = "E",      ["Ю"] = "Ju",
        ["Я"] = "Ja"
    }
    translit.tables["German transcription second pass uppercase"]
      = de_tables[4]

    local B, P, Cs = lpeg.B, lpeg.P, lpeg.Cs

    -- All chars are 2-byte.
    local Co = P{
       P"б" + "в" + "г" + "д" + "ж" + "з" + "к" + "л" + "м" + "н" +
        "п" + "р" + "с" + "т" + "ф" + "х" + "ц" + "ч" + "ш" + "щ" +
        "ъ" + "ь" +
        "Б" + "В" + "Г" + "Д" + "Ж" + "З" + "К" + "Л" + "М" + "Н" +
        "П" + "Р" + "С" + "Т" + "Ф" + "Х" + "Ц" + "Ч" + "Ш" + "Щ" +
        "Ъ" + "Ь"
    }

    local Vo = P{
       P"а" + "е" + "ё" + "и" + "й" + "о" + "у" + "ы" + "э" + "я" +
        "ю" + "А" + "Е" + "Ё" + "И" + "Й" + "О" + "У" + "Ы" + "Э" +
        "Я" + "Ю"
    }

    local iy = P"и" + P"ы" + P"И" + P"Ы"

    -------------------------------------------
    -- Pattern generation.
    -------------------------------------------

    local p_transcript

    for _, set in next, de_tables do
        for str, rep in next, set do
            if not p_transcript then -- it’ll be empty initially
                p_transcript = P(str) / rep
            else
                p_transcript = p_transcript + (P(str) / rep)
            end
        end
    end

    local irule  = B(Vo,2) * Cs(P"й") * #Co   / "i"
    local iyrule = B(iy,2) * Cs(P"й") * #Co   / "j"
    local jrule  =           Cs(P"й") * #Vo   / "j"
    local srule  = B(Vo,2) * Cs(P"с") * #Vo   / "ss"
    local ssrule = B(Vo,2) * Cs(P"с") * #P"х" / "ß"
    local jerule = B(Vo,2) * Cs(P"е")         / "je"
    local jorule = B(Vo,2) * Cs(P"ё")         / "jo"

    translit.future_ru_transcript_de
      = Cs((iyrule + jrule + irule
          + jerule + srule + ssrule
          + jorule + p_transcript + 1)^0
        )
end

if not translit.done_ru_trsc_en then

    ---------------------------------------------------------
    -- Lowercase English simple transcription---first pass --
    ---------------------------------------------------------

    translit.ru_trsc_en_low_first = translit.make_add_dict{
      [" е"] = " ye",
      ["ъе"] = "ye",
      ["ье"] = "ye",
      ["ье"] = "ye",
      ["ьи"] = "yi",
    }

    translit.tables["English transcription lowercase first pass"]
      = translit.ru_trsc_en_low_first

    ---------------------------------------------------------
    -- Uppercase English simple transcription---first pass --
    ---------------------------------------------------------

    translit.ru_trsc_en_upp_first = translit.make_add_dict{
      [" Е"] = " Ye",
      ["Ъe"] = "Ye",
      ["Ье"] = "Ye",
    }

    translit.tables["English transcription uppercase first pass"]
      = translit.ru_trsc_en_upp_first

    --------------------------------------------
    -- Lowercase English simple transcription --
    --------------------------------------------

    translit.ru_trsc_en_low = translit.make_add_dict{
      ["а"] = "a",
      ["б"] = "b",
      ["в"] = "v",
      ["г"] = "g",
      ["д"] = "d",
      ["е"] = "e",
      ["ё"] = "e",
      ["ж"] = "zh",
      ["з"] = "z",
      ["и"] = "i",
      ["й"] = "y",
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
      ["х"] = "kh",
      ["ц"] = "ts",
      ["ч"] = "ch",
      ["ш"] = "sh",
      ["щ"] = "shsh",
      ["ъ"] = "",
      ["ы"] = "y",
      ["ь"] = "",
      ["э"] = "e",
      ["ю"] = "yu",
      ["я"] = "ya"
    }

    translit.tables["English transcription lowercase second pass"]
      = translit.ru_trsc_en_low

    --------------------------------------------
    -- Uppercase English simple transcription --
    --------------------------------------------

    translit.ru_trsc_en_upp = translit.make_add_dict{
      ["А"] = "A",
      ["Б"] = "B",
      ["В"] = "V",
      ["Г"] = "G",
      ["Д"] = "D",
      ["Е"] = "E",
      ["Ё"] = "E",
      ["Ж"] = "Zh",
      ["З"] = "Z",
      ["И"] = "I",
      ["Й"] = "Y",
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
      ["Х"] = "Kh",
      ["Ц"] = "Ts",
      ["Ч"] = "Ch",
      ["Ш"] = "Sh",
      ["Щ"] = "Shsh",
      ["Ъ"] = "",
      ["Ы"] = "Y",
      ["Ь"] = "",
      ["Э"] = "E",
      ["Ю"] = "Yu",
      ["Я"] = "Ya"
    }

    translit.tables["English transcription uppercase second pass"]
      = translit.ru_trsc_en_upp

    function translit.gen_rules_en ()
        -- The english е-rule, Vе -> Vye
        translit.ru_trsc_en_jerule = translit.make_add_dict{}
        for i, vow in ipairs(translit.ru_vowels) do
            local new_ante = vow .. "е"
            local new_post = vow .. "ye"
            translit.ru_trsc_en_jerule[new_ante] = new_post
        end

        translit.tables["English transcription ye-rule"]
          = translit.ru_trsc_en_jerule
    end

    translit.gen_rules_en()
    translit.done_ru_trsc_en = true
end


if not translit.done_ru_trsc_cz then
    -----------------------------------
    -- Lowercase Czech transcription --
    -----------------------------------

    translit.ru_trsc_cz_low = translit.make_add_dict{
      ["а"] = "a",
      ["б"] = "b",
      ["в"] = "v",
      ["г"] = "g",
      ["д"] = "d",
      ["е"] = "e",
      ["ё"] = "ë",
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
      ["щ"] = "šč",
      ["ъ"] = "ъ",
      ["ы"] = "y",
      ["ь"] = "ь",
      ["э"] = "è",
      ["ю"] = "ju", -- Maybe we should do things like ню -> ňu and
      ["я"] = "ja", -- тя -> ťa, but that would complicate things a
    }               -- bit and linguists might not agree.

    translit.tables["Czech transcription lowercase"]
      = translit.ru_trsc_cz_low

    -----------------------------------
    -- Uppercase Czech transcription --
    -----------------------------------

    translit.ru_trsc_cz_upp = translit.make_add_dict{
      ["А"] = "A",
      ["Б"] = "B",
      ["В"] = "V",
      ["Г"] = "G",
      ["Д"] = "D",
      ["Е"] = "E",
      ["Ё"] = "Ë",
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
      ["Щ"] = "Šč",
      ["Ъ"] = "Ъ",
      ["Ы"] = "Y",
      ["Ь"] = "Ь",
      ["Э"] = "È",
      ["Ю"] = "Ju",
      ["Я"] = "Ja" 
    }

    translit.tables["Czech transcription uppercase"]
      = translit.ru_trsc_cz_upp

    ----------------------------------------------
    -- Lowercase Additional Czech Transcription --
    ----------------------------------------------

    translit.ru_trsc_cz_add_low = translit.make_add_dict{
    ["ѕ"] = "dz",
    ["з"] = "z",
    ["ꙁ"] = "z",
    ["і"] = "ï",
    ["ѹ"] = "u",
    ["ѡ"] = "ō",
    ["ѣ"] = "ě",
    ["ѥ"] = "je",
    ["ѧ"] = "ę",
    ["ѩ"] = "ję",
    ["ѫ"] = "ǫ",
    ["ѭ"] = "jǫ",
    ["ѯ"] = "ks",
    ["ѱ"] = "ps",
    ["ѳ"] = "th",
    ["ѵ"] = "ÿ",
    }

    translit.tables[
      "Czech transcription for OCS and pre-1918 lowercase"]
      = translit.ru_trsc_cz_add_low


    ----------------------------------------------
    -- Uppercase Additional Czech Transcription --
    ----------------------------------------------

    translit.ru_trsc_cz_add_upp = translit.make_add_dict{
    ["Ѕ"] = "Dz",
    ["З"] = "Z",
    ["Ꙁ"] = "Z",
    ["І"] = "Ï",
    ["Ѹ"] = "U",
    ["Ѡ"] = "Ō",
    ["Ѣ"] = "Ě",
    ["Ѥ"] = "Je",
    ["Ѧ"] = "Ę",
    ["Ѩ"] = "Ję",
    ["Ѫ"] = "Ǫ",
    ["Ѭ"] = "Jǫ",
    ["Ѯ"] = "Ks",
    ["Ѱ"] = "Ps",
    ["Ѳ"] = "Th",
    ["Ѵ"] = "Ÿ",
    }

    translit.tables[
      "Czech transcription for OCS and pre-1918 uppercase"]
      = translit.ru_trsc_cz_add_upp
    translit.done_ru_trsc_cz = true
end

--===================================================================--
--                           End Of Tables                           --
--===================================================================--

local function transcript (mode, text)
    local P, R, S, V, Cs = lpeg.P, lpeg.R, lpeg.S, lpeg.V, lpeg.Cs

    local trsc_parser, p_rules, capt, p_de

    local function tab_subst (s, ...)
        local sets = { ... }
        local p_tmp, tmp = nil, translit.make_add_dict{}
        for n=1, #sets do
            local set = sets[n]
            tmp = tmp + set
        end
        p_tmp = addrules(tmp, p_tmp)
        local fp = Cs((Cs(P(p_tmp) / tmp) + utfchar)^0)
        return lpegmatch(fp, s)
    end

    if mode == "ru_transcript_en" then

        text = tab_subst(text, translit.ru_trsc_en_jerule)
        text = tab_subst(text,
                  translit.ru_trsc_en_low_first,
                  translit.ru_trsc_en_upp_first)
        text = tab_subst(text,
                  translit.ru_trsc_en_low,
                  translit.ru_trsc_en_upp)

        return text

    elseif mode == "ru_transcript_en_exp" then

        local en_low_upp = translit.make_add_dict{}
        en_low_upp = translit.ru_trsc_en_low + translit.ru_trsc_en_upp

        local twochar
        local tworepl = translit.make_add_dict{}

        twochar = addrules( translit.ru_trsc_en_low_first, twochar)
        twochar = addrules( translit.ru_trsc_en_upp_first, twochar)

        tworepl = translit.ru_trsc_en_low_first
                + translit.ru_trsc_en_upp_first

        -- The е-rule, Vе -> Vye
        local function V_je (s)
            local ante = utf.sub(s, 1, 1)
            return en_low_upp[ante] .. "ye"
        end

        local jerule    = Cs((vow * "е")        / V_je)

        local dvoje     = Cs(twochar            / tworepl)
        local other     = Cs((utfchar)          / en_low_upp)

        local g = Cs((dvoje + jerule + other + utfchar)^0)

        text = g:match(text)

        return text

    elseif mode == "ru_cz" or mode ==  "ocs_cz" then
        text = tab_subst(text,
                         translit.ru_trsc_cz_low,
                         translit.ru_trsc_cz_upp)
        if mode == "ocs_cz" then
            text = tab_subst(text,
                      translit.ru_trsc_cz_add_low,
                      translit.ru_trsc_cz_add_upp)
        end
        return text
    end

    if mode == "ru_transcript_de_exp" then

        local vow, con, iy
        vow = addrules(translit.ru_vowels,     vow)
        con = addrules(translit.ru_consonants, con)
        iy  = addrules(translit.ru_trsc_iy,    iy )

        local de_low_upp = translit.make_add_dict{}
        de_low_upp = translit.ru_trsc_upp + translit.ru_trsc_low

        local twochar
        local tworepl = translit.make_add_dict{}

        twochar = addrules( translit.ru_trsc_low_first, twochar )
        twochar = addrules( translit.ru_trsc_upp_first, twochar )

        tworepl = translit.ru_trsc_low_first
                + translit.ru_trsc_upp_first

        -- The й-rule, VйC -> ViC
        local function V_i_C (s)
            local ante = utf.sub(s, 1, 1)
            local post = utf.sub(s, 3, 3)
            return de_low_upp[ante] .. "i" .. de_low_upp[post]
        end

        -- The second й-rule, йV -> jV && [иы]йC -> [иы]jC
        local function iy_j_C (s)
            local ante = utf.sub(s, 1, 1)
            local post = utf.sub(s, 3, 3)
            return de_low_upp[ante] .. "j" .. de_low_upp[post]
        end

        local function j_V (s)
            local post = utf.sub(s, 2, 2)
            return "j" .. de_low_upp[post]
        end

        -- The с-rule, VсV -> VssV
        local function V_ss_V (s)
            local ante = utf.sub(s, 1, 1)
            local post = utf.sub(s, 3, 3)
            return de_low_upp[ante] .. "ss" .. de_low_upp[post]
        end

        -- The sharp-s-rule, Vсх -> Vßх
        local function V_sz_ch (s)
            local ante = utf.sub(s, 1, 1)
            return de_low_upp[ante] .. "ßch"
        end

        -- The е-rule, Vе -> Vje
        local function V_je (s)
            local ante = utf.sub(s, 1, 1)
            return de_low_upp[ante] .. "je"
        end

        -- Reapplying V_je on its result + next char would make the
        -- following two rules obsolete.
        local function V_jeje (s)
            local ante = utf.sub(s, 1, 1)
            return de_low_upp[ante] .. "jeje"
        end

        local function V___je (s)
            local ante = utf.sub(s, 1, 1)
            return de_low_upp[ante] .. "jeje"
        end

        -- The ё-rule, Vё -> Vjo
        -- This should be redundant as [жцчшщ]ё -> o, else ё -> jo .
        -- Somebody should teach those DUDEN guys parsimony.
        local function V_jo (s)
            local ante = utf.sub(s, 1, 1)
            return de_low_upp[ante] .. "jo"
        end

        local iyrule    = Cs((iy * "й" * con)   / iy_j_C)
        local jrule     = Cs(("й" * vow)        / j_V)
        local irule     = Cs((vow * "й" * con)  / V_i_C)

        local ssrule    = Cs((vow * "с" * vow)  / V_ss_V)
        local szrule    = Cs((vow * "сх")       / V_sz_ch)

        --local _jrule    = Cs((vow * "ее")       / V___je)
        local jjrule    = Cs((vow * "ее")       / V_jeje)
        local jerule    = Cs((vow * "е")        / V_je)
        local jorule    = Cs((vow * "ё")        / V_jo)

        local dvoje     = Cs(twochar            / tworepl)
        local other     = Cs((utfchar)          / de_low_upp)

        local izhe      = iyrule + jrule + irule
        local slovo     = ssrule + szrule
        local jest      = jjrule + jerule + jorule

        local g = Cs((izhe + slovo + jest + dvoje + other + utfchar)^0)

        text = g:match(text)
        return text

    elseif mode == "ru_transcript_de" then

        if lpeg.version() == "0.9" then

            text = tab_subst(text, translit.ru_trsc_jrule)
            text = tab_subst(text, translit.ru_trsc_irule)
            text = tab_subst(text, translit.ru_trsc_jerule)
            text = tab_subst(text, translit.ru_trsc_srule)
            text = tab_subst(text, translit.ru_trsc_sharpsrule)
            text = tab_subst(text, translit.ru_trsc_jorule)
            text = tab_subst(text,
                      translit.ru_trsc_upp_first,
                      translit.ru_trsc_low_first)
            text = tab_subst(text,
                      translit.ru_trsc_upp,
                      translit.ru_trsc_low)

            return text
        elseif lpeg.version() == "0.10" then
            return translit.future_ru_transcript_de:match(text)
        end

    end

end

translit.methods ["ru_transcript_de"]
  = function (text) return transcript("ru_transcript_de"    , text) end
translit.methods ["ru_transcript_de_exp"]
  = function (text) return transcript("ru_transcript_de_exp", text) end
translit.methods ["ru_transcript_en"]
  = function (text) return transcript("ru_transcript_en"    , text) end
translit.methods ["ru_transcript_en_exp"]
  = function (text) return transcript("ru_transcript_en_exp", text) end
translit.methods ["ru_cz"]
  = function (text) return transcript("ru_cz"               , text) end
translit.methods ["ocs_cz"]
  = function (text) return transcript("ocs_cz"              , text) end

-- vim:sw=4:ts=4:expandtab:ft=lua
