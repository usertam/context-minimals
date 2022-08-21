
--===========================================================================--
--                               Serbian                                     --
--===========================================================================--

local translit  = thirddata.translit
local pcache    = translit.parser_cache
local lpegmatch = lpeg.match


-- Special thanks to Mojca Miklavec and Arthur Reutenauer for their
-- assistance in creating these transliteration routines.

if not translit.done_serbian then
    --------------------------------------------
    -- Lowercase Serbian (Cyrillic -> Latin)  --
    --------------------------------------------
    translit.sr_tolt_lower = translit.make_add_dict{
        ["а"] = "a",
        ["б"] = "b",
        ["в"] = "v",
        ["г"] = "g",
        ["д"] = "d",
        ["ђ"] = "đ",
        ["е"] = "e",
        ["ж"] = "ž",
        ["з"] = "z",
        ["и"] = "i",
        ["ј"] = "j",
        ["к"] = "k",
        ["л"] = "l",
        ["љ"] = "lj",
        ["м"] = "m",
        ["н"] = "n",
        ["њ"] = "nj",
        ["о"] = "o",
        ["п"] = "p",
        ["р"] = "r",
        ["с"] = "s",
        ["т"] = "t",
        ["ћ"] = "ć",
        ["у"] = "u",
        ["ф"] = "f",
        ["х"] = "h",
        ["ц"] = "c",
        ["ч"] = "č",
        ["џ"] = "dž",
        ["ш"] = "š",
    }

    translit.tables["Serbian Cyr->Lat Transliteration lowercase"] = translit.sr_tolt_lower

    --------------------------------------------
    -- Uppercase Serbian (Cyrillic -> Latin)  --
    --------------------------------------------

    translit.sr_tolt_upper = translit.make_add_dict{
        ["А"] = "A",
        ["Б"] = "B",
        ["В"] = "V",
        ["Г"] = "G",
        ["Д"] = "D",
        ["Ђ"] = "Đ",
        ["Е"] = "E",
        ["Ж"] = "Ž",
        ["З"] = "Z",
        ["И"] = "I",
        ["Ј"] = "J",
        ["К"] = "K",
        ["Л"] = "L",
        ["Љ"] = "Lj",
        ["М"] = "M",
        ["Н"] = "N",
        ["Њ"] = "Nj",
        ["О"] = "O",
        ["П"] = "P",
        ["Р"] = "R",
        ["С"] = "S",
        ["Т"] = "T",
        ["Ћ"] = "Ć",
        ["У"] = "U",
        ["Ф"] = "F",
        ["Х"] = "H",
        ["Ц"] = "C",
        ["Ч"] = "Č",
        ["Џ"] = "Dž",
        ["Ш"] = "Š",
    }

    translit.tables["Serbian Cyr->Lat Transliteration uppercase"] = translit.sr_tolt_upper

    local function __inverse_tab (t)
        local result = { }
        for k,v in next,t do result[v] = k end
        return result
    end

    translit.sr_tocy_lower = translit.make_add_dict(__inverse_tab(translit.sr_tolt_lower))
    translit.sr_tocy_upper = translit.make_add_dict(__inverse_tab(translit.sr_tolt_upper))


    --- Good reading up front:
    --- <http://en.wikipedia.org/wiki/User:Aleksandar_Šušnjar/Serbian_Wikipedia's_Challenges#Real-time_transliteration_for_display>
    --- <http://www.vokabular.org/forum/index.php?topic=3817.15>

    local except = {
        ["konjug"]      = "конјуг",
        ["konjunk"]     = "конјунк",
        ["injekc"]      = "инјекц",
        ["injunkt"]     = "инјункт",
        ["panjelin"]    = "панјелин",
        ["tanjug"]      = "танјуг",
        ["vanjezič"]    = "ванјезич",
        ["vanjadransk"] = "ванјадранск",

        ["nadžanj"]  = "наджањ",
        ["nadždrel"] = "надждрел",
        ["nadžet"]   = "наджет",
        ["nadživ"]   = "наджив",
        ["nadžnj"]   = "наджњ",
        ["nadžup"]   = "наджуп",
        ["odžal"]    = "оджал",
        ["odžar"]    = "оджар",
        ["odživ"]    = "оджив",
        ["odžubor"]  = "оджубор",
        ["odžur"]    = "оджур",
        ["odžvak"]   = "оджвак",
        ["podžanr"]  = "поджанр",
        ["podže"]    = "подже", -- “поджећи”
    }

    local P = lpeg.P
    local utf8      = unicode and unicode.utf8 or utf or utf8
    local sub       = utf8.sub
    local toupper   = lpeg.patterns.toupper
    local upper     = function (s) return lpegmatch (toupper, s) end

    local p_tocy, p_i_tocy, p_tolt, p_i_tolt

    for left, right in next, except do -- generating exception patterns for both sides
        local Left  = upper(sub(left,  1, 1)) .. sub(left,  2)
        local Right = upper(sub(right, 1, 1)) .. sub(right, 2)
        local LEFT, RIGHT = upper(left), upper(right)

        local p_i_left    = P(left)  / right  + P(Left)  / Right + P(LEFT)  / RIGHT
        local p_i_right   = P(right) / left   + P(Right) / Left  + P(RIGHT) / LEFT

        local p_left  = P" " * p_i_left
        local p_right = P" " * p_i_right

        if not p_tocy then
            p_tocy   = p_left
            p_i_tocy = p_i_left
            p_tolt   = p_right
            p_i_tolt = p_i_right
        else
            p_tocy   = p_tocy   + p_left
            p_i_tocy = p_i_tocy + p_i_left
            p_tolt   = p_tolt   + p_right
            p_i_tolt = p_i_tolt + p_i_right
        end
    end

    local _p_hintchar = P"*" / ""
    local hintme      = "dln"
    local _p_tocy_hint, _p_tolt_hint

    for left in hintme:utfcharacters() do
        local right = translit.sr_tocy_lower[left]
        local LEFT, RIGHT = upper(left), upper(right)
        if not _p_tocy_hint then
            _p_tocy_hint = P(left)  / right + P(LEFT)  / RIGHT
            _p_tolt_hint = P(right) / left  + P(RIGHT) / LEFT
        else
            _p_tocy_hint = _p_tocy_hint + P(left)  / right + P(LEFT)  / RIGHT
            _p_tolt_hint = _p_tolt_hint + P(right) / left  + P(RIGHT) / LEFT
        end
    end

    translit.serbian_exceptions             = { }
    translit.serbian_exceptions.p_tocy      = p_tocy
    translit.serbian_exceptions.p_tolt      = p_tolt
    translit.serbian_exceptions.p_tocy_init = p_i_tocy
    translit.serbian_exceptions.p_tolt_init = p_i_tolt
    translit.serbian_exceptions.p_tocy_hint = _p_tocy_hint * _p_hintchar
    translit.serbian_exceptions.p_tolt_hint = _p_tolt_hint * _p_hintchar

    translit.done_serbian = true
end

--===========================================================================--
--                              End Of Tables                                --
--===========================================================================--


local t = translit
local function sr (mode)
    local P, R, Cs = lpeg.P, lpeg.R, lpeg.Cs
    local utfchar  = translit.utfchar
    local modestr  = "p_" .. mode:match("to..$")
    local _p_sre   = t.serbian_exceptions[modestr]
    local _p_sre_i = t.serbian_exceptions[modestr .. "_init"]

    local trl_sr   = translit.make_add_dict{}
    trl_sr         = t[mode.."_upper"] + t[mode.."_lower"]

    -- transliteration from latin script requires macro handling … 
    local _p_macro = P[[\]] * R("az", "AZ")^1 -- assuming standard catcodes
    local _p_sr    = translit.addrules (trl_sr, _p_sr) / trl_sr
    if translit.hinting then
        _p_sr = t.serbian_exceptions[modestr .. "_hint"] + _p_sr
    end

    local p_sr
    if translit.sr_except then
        p_sr = Cs(_p_sre_i^-1 * (_p_macro + _p_sre + _p_sr + utfchar)^0)
    else
        p_sr = Cs((_p_macro + _p_sr + utfchar)^0)
    end

    return p_sr
end

translit.methods["sr_tolt"] = function (text)
    local pname = "sr_tolt" .. tostring(translit.hinting) .. tostring(translit.sr_except)
    local p = pcache[pname]
    if not p then
        p = sr("sr_tolt")
        pcache[pname] = p
    end
    return lpegmatch(p, text)
end

translit.methods["sr_tocy"] = function (text)
    local pname = "sr_tocy" .. tostring(translit.hinting) .. tostring(translit.sr_except)
    local p = pcache[pname]
    if not p then
        p = sr("sr_tocy")
        pcache[pname] = p
    end
    return lpegmatch(p, text)
end

-- vim:ft=lua:sw=4:ts=4
