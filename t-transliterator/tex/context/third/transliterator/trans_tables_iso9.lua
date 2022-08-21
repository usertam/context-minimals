--===========================================================================--
--           ISO 9.1995(E) standardized transliteration for cyrillic         --
--===========================================================================--

local translit  = thirddata.translit
local pcache    = translit.parser_cache
local lpegmatch = lpeg.match

if not translit.done_iso9 then
    -----------------------------------------
    -- Lowercase russian cyrillic alphabet --
    -----------------------------------------
    translit.ru_low = translit.make_add_dict({
    ["а"] = "a", -- U+0430 -> U+0061
    ["б"] = "b", -- U+0431 -> U+0062
    ["в"] = "v", -- U+0432 -> U+0076
    ["г"] = "g", -- U+0433 -> U+0067
    ["д"] = "d", -- U+0434 -> U+0064
    ["е"] = "e", -- U+0435 -> U+0065
    ["ё"] = "ë", -- U+0451 -> U+00eb
    ["ж"] = "ž", -- U+0436 -> U+017e
    ["з"] = "z", -- U+0437 -> U+007a
    ["и"] = "i", -- U+0438 -> U+0069
    ["й"] = "j", -- U+0439 -> U+006a
    ["к"] = "k", -- U+043a -> U+006b
    ["л"] = "l", -- U+043b -> U+006c
    ["м"] = "m", -- U+043c -> U+006d
    ["н"] = "n", -- U+043d -> U+006e
    ["о"] = "o", -- U+043e -> U+006f
    ["п"] = "p", -- U+043f -> U+0070
    ["р"] = "r", -- U+0440 -> U+0072
    ["с"] = "s", -- U+0441 -> U+0073
    ["т"] = "t", -- U+0442 -> U+0074
    ["у"] = "u", -- U+0443 -> U+0075
    ["ф"] = "f", -- U+0444 -> U+0066
    ["х"] = "h", -- U+0445 -> U+0068
    ["ц"] = "c", -- U+0446 -> U+0063
    ["ч"] = "č", -- U+0447 -> U+010d
    ["ш"] = "š", -- U+0448 -> U+0161
    ["щ"] = "ŝ", -- U+0449 -> U+015d
    ["ъ"] = "ʺ", -- U+044a -> U+02ba <- That's somewhat ambiguous as 0x2ba is
    ["ы"] = "y", -- U+044b -> U+0079    used for uppercase, too.
    ["ь"] = "ʹ", -- U+044c -> U+02b9 <- Same here with 0x2b9.
    ["э"] = "è", -- U+044d -> U+00e8
    ["ю"] = "û", -- U+044e -> U+00fb
    ["я"] = "â"  -- U+044f -> U+00e2
    })

    translit.tables["russian lowercase ISO~9"] = translit.ru_low

    -----------------------------------------
    -- Uppercase russian cyrillic alphabet --
    -----------------------------------------

    translit.ru_upp = translit.make_add_dict({
    ["А"] = "A", -- U+0410 -> U+0041
    ["Б"] = "B", -- U+0411 -> U+0042
    ["В"] = "V", -- U+0412 -> U+0056
    ["Г"] = "G", -- U+0413 -> U+0047
    ["Д"] = "D", -- U+0414 -> U+0044
    ["Е"] = "E", -- U+0415 -> U+0045
    ["Ё"] = "Ë", -- U+0401 -> U+00cb
    ["Ж"] = "Ž", -- U+0416 -> U+017d
    ["З"] = "Z", -- U+0417 -> U+005a
    ["И"] = "I", -- U+0418 -> U+0049
    ["Й"] = "J", -- U+0419 -> U+004a
    ["К"] = "K", -- U+041a -> U+004b
    ["Л"] = "L", -- U+041b -> U+004c
    ["М"] = "M", -- U+041c -> U+004d
    ["Н"] = "N", -- U+041d -> U+004e
    ["О"] = "O", -- U+041e -> U+004f
    ["П"] = "P", -- U+041f -> U+0050
    ["Р"] = "R", -- U+0420 -> U+0052
    ["С"] = "S", -- U+0421 -> U+0053
    ["Т"] = "T", -- U+0422 -> U+0054
    ["У"] = "U", -- U+0423 -> U+0055
    ["Ф"] = "F", -- U+0424 -> U+0046
    ["Х"] = "H", -- U+0425 -> U+0048
    ["Ц"] = "C", -- U+0426 -> U+0043
    ["Ч"] = "Č", -- U+0427 -> U+010c
    ["Ш"] = "Š", -- U+0428 -> U+0160
    ["Щ"] = "Ŝ", -- U+0429 -> U+015c
    ["Ъ"] = "ʺ", -- U+042a -> U+02ba
    ["Ы"] = "Y", -- U+042b -> U+0059
    ["Ь"] = "ʹ", -- U+042c -> U+02b9
    ["Э"] = "È", -- U+042d -> U+00c8
    ["Ю"] = "Û", -- U+042e -> U+00db
    ["Я"] = "Â"  -- U+042f -> U+00c2
    })

    translit.tables["russian uppercase ISO~9"] = translit.ru_upp

    ----------------------------------------------------------
    -- Lowercase pre-1918 russian cyrillic additional chars --
    ----------------------------------------------------------
    -- cf. http://www.russportal.ru/index.php?id=oldorth.decret1917

    translit.ru_old_low = translit.make_add_dict{
    ["ѣ"] = "ě", -- U+048d -> U+011b -- 2-byte
    ["і"] = "ì", -- U+0456 -> U+00ec -- 2-byte
    ["ѳ"] = "f", -- U+0473 -> U+0066 -- 2-byte
    ["ѵ"] = "ỳ", -- U+0475 -> U+1ef3 -- 3-byte
    }

    translit.tables["russian pre-1918 lowercase ISO~9 2 byte"] = translit.ru_old_low

    translit.ru_old_upp = translit.make_add_dict{
    ["Ѣ"] = "Ě", -- U+048c -> U+011a -- 2-byte
    ["І"] = "Ì", -- U+0406 -> U+00cc -- 2-byte
    ["Ѳ"] = "F", -- U+0424 -> U+0046 -- 2-byte
    ["Ѵ"] = "Ỳ", -- U+0474 -> U+1ef2 -- 3-byte
    }

    translit.ru_jer_hack = translit.make_add_dict{
    ["ь"] = "’",
    ["Ь"] = "’",
    ["ъ"] = "”",
    ["Ъ"] = "”",
    }

    translit.tables["russian magkij / tverdyj znak hack"] = translit.ru_jer_hack

    translit.tables["russian pre-1918 uppercase ISO~9 2 byte"] = translit.ru_old_upp

    ---------------------------------------------------------
    -- Lowercase characters from other cyrillic alphabets  --
    ---------------------------------------------------------

    translit.non_ru_low = translit.make_add_dict{
    ["ӑ"] = "ă", -- U+04d1 -> U+0103
    ["ӓ"] = "ä", -- U+04d3 -> U+00e4
    ["ә"] = "a̋", -- u+04d9 -> U+0061+030b
    ["ґ"] = "g̀", -- u+0491 -> U+0067+0300
    ["ҕ"] = "ğ", -- U+0495 -> U+011f
    ["ғ"] = "ġ", -- U+0493 -> U+0121
    ["ђ"] = "đ", -- U+0452 -> U+0111
    ["ѓ"] = "ǵ", -- U+0453 -> U+01f5
    ["ӗ"] = "ĕ", -- U+04d7 -> U+0115
    ["є"] = "ê", -- U+0454 -> U+00ea
    ["ҽ"] = "c̆", -- U+04bd -> U+0063+0306
    ["ҿ"] = "ç̆", -- U+04bf -> U+00e7+0306
    ["ӂ"] = "z̆", -- U+04c2 -> U+007a+0306
    ["ӝ"] = "z̄", -- U+04dd -> U+007a+0304
    ["җ"] = "ž̧", -- U+0497 -> U+017e+0327
    ["ӟ"] = "z̈", -- U+04df -> U+007a+0308
    ["ѕ"] = "ẑ", -- U+0455 -> U+1e91          -- Mapped to dz in old cyrillic non-ISO.
    ["ӡ"] = "ź", -- U+04e1 -> U+017a
    ["ӥ"] = "î", -- U+04e5 -> U+00ee
    ["і"] = "ì", -- U+0456 -> U+00ec
    ["ї"] = "ï", -- U+0457 -> U+00ef
    ["ј"] = "ǰ", -- U+0458 -> U+01f0
    ["қ"] = "ķ", -- U+049b -> U+0137
    ["ҟ"] = "k̄", -- U+049f -> U+006b+0304
    ["љ"] = "l̂", -- U+0459 -> U+006c+0302
    ["њ"] = "n̂", -- U+045a -> U+006e+0302
    ["ҥ"] = "ṅ", -- U+04a5 -> U+1e45
    ["ң"] = "ṇ", -- U+04a3 -> U+1e47
    ["ӧ"] = "ö", -- U+04e7 -> U+00f6
    ["ө"] = "ô", -- U+04e9 -> U+00f4
    ["ҧ"] = "ṕ", -- U+04a7 -> U+1e55
    ["ҫ"] = "ç", -- U+04ab -> U+00e7
    ["ҭ"] = "ţ", -- U+04ad -> U+0163
    ["ћ"] = "ć", -- U+045b -> U+0107
    ["ќ"] = "ḱ", -- U+045c -> U+1e31
    ["у́"] = "ú", -- U+0443+ -> U+00fA
    ["ў"] = "ŭ", -- U+045e -> U+016d
    ["ӱ"] = "ü", -- U+04f1 -> U+00fc
    ["ӳ"] = "ű", -- U+04f3 -> U+0171
    ["ү"] = "ù", -- U+04af -> U+00f9
    ["ҳ"] = "ḩ", -- U+04b3 -> U+1e29
    ["һ"] = "ḥ", -- U+04bb -> U+1e25
    ["ҵ"] = "c̄", -- U+04b5 -> U+0063+0304
    ["ӵ"] = "c̈", -- U+04f5 -> U+0063+0308
    ["ҷ"] = "ç", -- U+04cc -> U+00e7
    ["џ"] = "d̂", -- U+045f -> U+0064+0302
    ["ӹ"] = "ÿ", -- U+04f9 -> U+00ff
    ["ѣ"] = "ě", -- U+048d -> U+011b
    ["ѫ"] = "ǎ", -- U+046b -> U+01ce      -- Mapped to ǫ in non-ISO old cyrillic.
    ["ѳ"] = "f̀", -- U+0473 -> U+0066+0300 -- This is mapped to ‘f’ in ru_old.
    ["ѵ"] = "ỳ", -- U+0475 -> U+1ef3
    ["ҩ"] = "ò", -- U+04a9 -> U+00f2
    ["Ӏ"] = "‡"  -- U+04cf -> U+2021
    }

    translit.tables["cyrillic other lowercase ISO~9"] = translit.non_ru_low

    ---------------------------------------------------------
    -- Uppercase characters from other cyrillic alphabets  --
    ---------------------------------------------------------

    translit.non_ru_upp = translit.make_add_dict{
    ["Ӑ"] = "Ă", -- U+04d0 -> U+0102
    ["Ӓ"] = "Ä", -- U+04d2 -> U+00c4
    ["Ә"] = "A̋", -- U+04d8 -> U+0041+030b
    ["Ґ"] = "G̀", -- U+0490 -> U+0047+0300
    ["Ҕ"] = "Ğ", -- U+0494 -> U+011e
    ["Ғ"] = "Ġ", -- U+0492 -> U+0120
    ["Ђ"] = "Đ", -- U+0402 -> U+0110
    ["Ѓ"] = "Ǵ", -- U+0403 -> U+01f4
    ["Ӗ"] = "Ĕ", -- U+04d6 -> U+0114
    ["Є"] = "Ê", -- U+0404 -> U+00ca
    ["Ҽ"] = "C̆", -- U+04bc -> U+0043+0306
    ["Ҿ"] = "Ç̆", -- U+04be -> U+00c7+0306
    ["Ӂ"] = "Z̆", -- U+04c1 -> U+005a+0306
    ["Ӝ"] = "Z̄", -- U+04dc -> U+005a+0304
    ["Җ"] = "Ž̦", -- U+0496 -> U+017d+0326
    ["Ӟ"] = "Z̈", -- U+04de -> U+005a+0308
    ["Ѕ"] = "Ẑ", -- U+0405 -> U+1e90
    ["Ӡ"] = "Ź", -- U+04e0 -> U+0179
    ["Ӥ"] = "Î", -- U+04e4 -> U+00ce
    ["І"] = "Ì", -- U+0406 -> U+00cc
    ["Ї"] = "Ï", -- U+0407 -> U+00cf
    ["Ј"] = "J̌", -- U+0408 -> U+004a+030c
    ["Қ"] = "Ķ", -- U+049a -> U+0136
    ["Ҟ"] = "K̄", -- U+049e -> U+004b+0304
    ["Љ"] = "L̂", -- U+0409 -> U+004c+0302
    ["Њ"] = "N̂", -- U+040a -> U+004e+0302
    ["Ҥ"] = "Ṅ", -- U+04a4 -> U+1e44
    ["Ң"] = "Ṇ", -- U+04a2 -> U+1e46
    ["Ӧ"] = "Ö", -- U+04e6 -> U+00d6
    ["Ө"] = "Ô", -- U+04e8 -> U+00d4
    ["Ҧ"] = "Ṕ", -- U+04a6 -> U+1e54
    ["Ҫ"] = "Ç", -- U+04aa -> U+00c7
    ["Ҭ"] = "Ţ", -- U+04ac -> U+0162
    ["Ћ"] = "Ć", -- U+040b -> U+0106
    ["Ќ"] = "Ḱ", -- U+040c -> U+1e30
    ["У́"] = "Ú", -- U+0423 -> U+00da
    ["Ў"] = "Ŭ", -- U+040e -> U+016c
    ["Ӱ"] = "Ü", -- U+04f0 -> U+00dc
    ["Ӳ"] = "Ű", -- U+04f2 -> U+0170
    ["Ү"] = "Ù", -- U+04ae -> U+00d9
    ["Ҳ"] = "Ḩ", -- U+04b2 -> U+1e28
    ["Һ"] = "Ḥ", -- U+04ba -> U+1e24
    ["Ҵ"] = "C̄", -- U+04b4 -> U+0043+0304
    ["Ӵ"] = "C̈", -- U+04f4 -> U+0043+0308
    ["Ҷ"] = "Ç", -- U+04cb -> U+00c7
    ["Џ"] = "D̂", -- U+040f -> U+0044+0302
    ["Ӹ"] = "Ÿ", -- U+04f8 -> U+0178
    ["Ѣ"] = "Ě", -- U+048c -> U+011a
    ["Ѫ"] = "Ǎ", -- U+046a -> U+01cd
    ["Ѳ"] = "F̀", -- U+0472 -> U+0046+0300
    ["Ѵ"] = "Ỳ", -- U+0474 -> U+1ef2
    ["Ҩ"] = "Ò", -- U+04a8 -> U+00d2
    ["’"] = "‵", -- U+2035 -> U+2019
    ["Ӏ"] = "‡"  -- U+04c0 -> U+2021
    }

    translit.tables["cyrillic other uppercase ISO~9"] = translit.non_ru_upp

    translit.done_iso9 = true
end

--===========================================================================--
--                              End Of Tables                                --
--===========================================================================--

local function iso9 (mode)
    local P, R, S, V, Cs = lpeg.P, lpeg.R, lpeg.S, lpeg.V, lpeg.Cs
    local addrules = translit.addrules
    local utfchar = translit.utfchar

    local iso9 = translit.make_add_dict{}
    iso9 = translit.ru_upp + translit.ru_low

    if mode == "ru_old" or mode == "all" then

        iso9 = iso9 + translit.ru_old_upp + translit.ru_old_low

        if mode == "all" then
            iso9 = iso9
                 + translit.non_ru_upp
                 + translit.non_ru_low
        end
        if translit.deficient_font == "yes" then
            iso9 = iso9
                + translit.ru_old_upp
                + translit.ru_old_low
                + translit.ru_jer_hack
        end
    end

    local p_iso9 = addrules (iso9, p_iso9)
    local iso9_parser = Cs((p_iso9 / iso9 + utfchar)^0)

    return iso9_parser
end

translit.methods["all"] = function (text)
    local pname = "all" .. translit.deficient_font
    local p = pcache[pname]
    if not p then
        p = iso9("all")
        pcache[pname] = p
    end
    return lpegmatch(p, text)
end

translit.methods["ru"] = translit.methods["all"]

translit.methods["ru_old"] = function (text)
    local pname = "ru_old" .. translit.deficient_font
    local p = pcache[pname]
    if not p then
        p = iso9("all")
        pcache[pname] = p
    end
    return lpegmatch(p, text)
end

-- vim:ft=lua:sw=4:ts=4
