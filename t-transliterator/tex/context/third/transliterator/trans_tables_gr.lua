--===========================================================================--
--                              Greek                                        --
--===========================================================================--

local translit  = thirddata.translit
local pcache    = translit.parser_cache
local lpegmatch = lpeg.match

-- Note that the Greek transliteration mapping isn't bijective so transliterated
-- texts won't be reversible.  (Shouldn't be impossible to make one up using
-- diacritics on latin characters to represent all possible combinations of
-- Greek breathings + accents.) 

-- Good reading on composed / precombined unicode:
--  http://www.tlg.uci.edu/~opoudjis/unicode/unicode_gaps.html#precomposed

-------------------------------------------------
-- Lowercase Greek Initial Position Diphthongs --
-------------------------------------------------

if not translit.done_greek then
    translit.gr_di_in_low = translit.make_add_dict{
    [" αὑ"] = " hau",
    [" αὕ"] = " hau",
    [" αὓ"] = " hau",
    [" αὗ"] = " hau",
    [" εὑ"] = " heu",
    [" εὕ"] = " heu",
    [" εὓ"] = " heu",
    [" εὗ"] = " heu",
    [" ηὑ"] = " hēu",
    [" ηὕ"] = " hēu",
    [" ηὓ"] = " hēu",
    [" ηὗ"] = " hēu",
    [" οὑ"] = " hu",
    [" οὕ"] = " hu",
    [" οὓ"] = " hu",
    [" οὗ"] = " hu",
    [" ωὑ"] = " hōu",
    [" ωὕ"] = " hōu",
    [" ωὓ"] = " hōu",
    [" ωὗ"] = " hōu"
    }

    translit.tables["Greek transliteration initial breathing diphthongs lowercase"] = translit.gr_di_in_low

    -------------------------------------------------
    -- Uppercase Greek Initial Position Diphthongs --
    -------------------------------------------------

    translit.gr_di_in_upp = translit.make_add_dict{
    [" Αὑ"] = " Hau",
    [" Αὕ"] = " Hau",
    [" Αὓ"] = " Hau",
    [" Αὗ"] = " Hau",
    [" Εὑ"] = " Heu",
    [" Εὕ"] = " Heu",
    [" Εὓ"] = " Heu",
    [" Εὗ"] = " Heu",
    [" Ηὑ"] = " Hēu",
    [" Ηὕ"] = " Hēu",
    [" Ηὓ"] = " Hēu",
    [" Ηὗ"] = " Hēu",
    [" Οὑ"] = " Hu",
    [" Οὕ"] = " Hu",
    [" Οὓ"] = " Hu",
    [" Οὗ"] = " Hu",
    [" Ωὑ"] = " Hōu",
    [" Ωὕ"] = " Hōu",
    [" Ωὓ"] = " Hōu",
    [" Ωὗ"] = " Hōu"
    }

    translit.tables["Greek transliteration initial breathing diphthongs uppercase"] = translit.gr_di_in_upp

    ---------------------------------------
    -- Lowercase Greek Initial Position  --
    ---------------------------------------

    translit.gr_in_low = translit.make_add_dict{
    [" ἁ"] = " ha",
    [" ἅ"] = " ha",
    [" ἃ"] = " ha",
    [" ἇ"] = " ha",
    [" ᾁ"] = " ha",
    [" ᾅ"] = " ha",
    [" ᾃ"] = " ha",
    [" ᾇ"] = " ha",
    [" ἑ"] = " he",
    [" ἕ"] = " he",
    [" ἓ"] = " he",
    [" ἡ"] = " hē",
    [" ἥ"] = " hē",
    [" ἣ"] = " hē",
    [" ἧ"] = " hē",
    [" ᾑ"] = " hē",
    [" ᾕ"] = " hē",
    [" ᾓ"] = " hē",
    [" ᾗ"] = " hē",
    [" ἱ"] = " hi",
    [" ἵ"] = " hi",
    [" ἳ"] = " hi",
    [" ἷ"] = " hi",
    [" ὁ"] = " ho",
    [" ὅ"] = " ho",
    [" ὃ"] = " ho",
    [" ὑ"] = " hy",
    [" ὕ"] = " hy",
    [" ὓ"] = " hy",
    [" ὗ"] = " hy",
    [" ὡ"] = " hō",
    [" ὥ"] = " hō",
    [" ὣ"] = " hō",
    [" ὧ"] = " hō",
    [" ᾡ"] = " hō",
    [" ᾥ"] = " hō",
    [" ᾣ"] = " hō",
    [" ᾧ"] = " hō",
    }

    translit.tables["Greek transliteration initial breathing lowercase"] = translit.gr_in_low

    ---------------------------------------
    -- Uppercase Greek Initial Position  --
    ---------------------------------------

    translit.gr_in_upp = translit.make_add_dict{
    [" Ἁ"] = " Ha",
    [" Ἅ"] = " Ha",
    [" Ἃ"] = " Ha",
    [" Ἇ"] = " Ha",
    [" ᾉ"] = " Ha",
    [" ᾍ"] = " Ha",
    [" ᾋ"] = " Ha",
    [" ᾏ"] = " Ha",
    [" Ἑ"] = " He",
    [" Ἕ"] = " He",
    [" Ἓ"] = " He",
    [" Ἡ"] = " Hē",
    [" Ἥ"] = " Hē",
    [" Ἣ"] = " Hē",
    [" Ἧ"] = " Hē",
    [" ᾙ"] = " Hē",
    [" ᾝ"] = " Hē",
    [" ᾛ"] = " Hē",
    [" ᾟ"] = " Hē",
    [" Ἱ"] = " Hi",
    [" Ἵ"] = " Hi",
    [" Ἳ"] = " Hi",
    [" Ἷ"] = " Hi",
    [" Ὁ"] = " Ho",
    [" Ὅ"] = " Ho",
    [" Ὃ"] = " Ho",
    [" Ὑ"] = " Hy",
    [" Ὕ"] = " Hy",
    [" Ὓ"] = " Hy",
    [" Ὗ"] = " Hy",
    [" Ὡ"] = " Hō",
    [" Ὥ"] = " Hō",
    [" Ὣ"] = " Hō",
    [" Ὧ"] = " Hō",
    [" ᾩ"] = " Hō",
    [" ᾭ"] = " Hō",
    [" ᾫ"] = " Hō",
    [" ᾯ"] = " Hō",
    }

    translit.tables["Greek transliteration initial breathing uppercase"] = translit.gr_in_upp

    ---------------------------------
    -- Lowercase Greek Diphthongs  --
    ---------------------------------

    translit.gr_di_low = translit.make_add_dict{
    ["αυ"] = "au",
    ["αύ"] = "au",
    ["αὺ"] = "au",
    ["αῦ"] = "au",
    ["αὐ"] = "au",
    ["αὔ"] = "au",
    ["αὒ"] = "au",
    ["αὖ"] = "au",
    ["αὑ"] = "au",
    ["αὕ"] = "au",
    ["αὓ"] = "au",
    ["αὗ"] = "au",
    ["ευ"] = "eu",
    ["εύ"] = "eu",
    ["εὺ"] = "eu",
    ["εῦ"] = "eu",
    ["εὐ"] = "eu",
    ["εὔ"] = "eu",
    ["εὒ"] = "eu",
    ["εὖ"] = "eu",
    ["εὑ"] = "eu",
    ["εὕ"] = "eu",
    ["εὓ"] = "eu",
    ["εὗ"] = "eu",
    ["ηυ"] = "ēu",
    ["ηύ"] = "ēu",
    ["ηὺ"] = "ēu",
    ["ηῦ"] = "ēu",
    ["ηὐ"] = "ēu",
    ["ηὔ"] = "ēu",
    ["ηὒ"] = "ēu",
    ["ηὖ"] = "ēu",
    ["ηὑ"] = "ēu",
    ["ηὕ"] = "ēu",
    ["ηὓ"] = "ēu",
    ["ηὗ"] = "ēu",
    ["ου"] = "u",
    ["ου"] = "u",
    ["ου"] = "u",
    ["ού"] = "u",
    ["οὺ"] = "u",
    ["οῦ"] = "u",
    ["οὐ"] = "u",
    ["οὔ"] = "u",
    ["οὒ"] = "u",
    ["οὖ"] = "u",
    ["οὑ"] = "u",
    ["οὕ"] = "u",
    ["οὓ"] = "u",
    ["οὗ"] = "u",
    ["ωυ"] = "ōu",
    ["ωύ"] = "ōu",
    ["ωὺ"] = "ōu",
    ["ωῦ"] = "ōu",
    ["ωὐ"] = "ōu",
    ["ωὔ"] = "ōu",
    ["ωὒ"] = "ōu",
    ["ωὖ"] = "ōu",
    ["ωὑ"] = "ōu",
    ["ωὕ"] = "ōu",
    ["ωὓ"] = "ōu",
    ["ωὗ"] = "ōu",
    ["ῤῥ"] = "rrh",
    }

    translit.tables["Greek transliteration diphthongs lowercase"] = translit.gr_in_low

    ---------------------------------
    -- Uppercase Greek Diphthongs  --
    ---------------------------------

    translit.gr_di_upp = translit.make_add_dict{
    ["Αυ"] = "Au",
    ["Αύ"] = "Au",
    ["Αὺ"] = "Au",
    ["Αῦ"] = "Au",
    ["Αὐ"] = "Au",
    ["Αὔ"] = "Au",
    ["Αὒ"] = "Au",
    ["Αὖ"] = "Au",
    ["Αὑ"] = "Au",
    ["Αὕ"] = "Au",
    ["Αὓ"] = "Au",
    ["Αὗ"] = "Au",
    ["Ευ"] = "Eu",
    ["Εύ"] = "Eu",
    ["Εὺ"] = "Eu",
    ["Εῦ"] = "Eu",
    ["Εὐ"] = "Eu",
    ["Εὔ"] = "Eu",
    ["Εὒ"] = "Eu",
    ["Εὖ"] = "Eu",
    ["Εὑ"] = "Eu",
    ["Εὕ"] = "Eu",
    ["Εὓ"] = "Eu",
    ["Εὗ"] = "Eu",
    ["Ηυ"] = "Ēu",
    ["Ηύ"] = "Ēu",
    ["Ηὺ"] = "Ēu",
    ["Ηῦ"] = "Ēu",
    ["Ηὐ"] = "Ēu",
    ["Ηὔ"] = "Ēu",
    ["Ηὒ"] = "Ēu",
    ["Ηὖ"] = "Ēu",
    ["Ηὑ"] = "Ēu",
    ["Ηὕ"] = "Ēu",
    ["Ηὓ"] = "Ēu",
    ["Ηὗ"] = "Ēu",
    ["Ου"] = "U",
    ["Ου"] = "U",
    ["Ου"] = "U",
    ["Ού"] = "U",
    ["Οὺ"] = "U",
    ["Οῦ"] = "U",
    ["Οὐ"] = "U",
    ["Οὔ"] = "U",
    ["Οὒ"] = "U",
    ["Οὖ"] = "U",
    ["Οὑ"] = "U",
    ["Οὕ"] = "U",
    ["Οὓ"] = "U",
    ["Οὗ"] = "U",
    ["Ωυ"] = "Ōu",
    ["Ωύ"] = "Ōu",
    ["Ωὺ"] = "Ōu",
    ["Ωῦ"] = "Ōu",
    ["Ωὐ"] = "Ōu",
    ["Ωὔ"] = "Ōu",
    ["Ωὒ"] = "Ōu",
    ["Ωὖ"] = "Ōu",
    ["Ωὑ"] = "Ōu",
    ["Ωὕ"] = "Ōu",
    ["Ωὓ"] = "Ōu",
    ["Ωὗ"] = "Ōu",
    }

    translit.tables["Greek transliteration diphthongs uppercase"] = translit.gr_in_upp

    -- The following will be used in an option that ensures transcription of
    -- nasalization, e.g. Ἁγχίσης -> “Anchises” (instead of “Agchises”)
    translit.gr_nrule = translit.make_add_dict{
    ["γγ"] = "ng",
    ["γκ"] = "nk",
    ["γξ"] = "nx",
    ["γχ"] = "nch",
    }

    translit.tables["Greek transliteration optional nasalization"] = translit.gr_nrule


    --------------------------------------
    -- Lowercase Greek Transliteration  --
    --------------------------------------

    translit.gr_low = translit.make_add_dict{
    ["α"] = "a",
    ["ά"] = "a",
    ["ὰ"] = "a",
    ["ᾶ"] = "a",
    ["ᾳ"] = "a",
    ["ἀ"] = "a",
    ["ἁ"] = "a",
    ["ἄ"] = "a",
    ["ἂ"] = "a",
    ["ἆ"] = "a",
    ["ἁ"] = "a",
    ["ἅ"] = "a",
    ["ἃ"] = "a",
    ["ἇ"] = "a",
    ["ᾁ"] = "a",
    ["ᾴ"] = "a",
    ["ᾲ"] = "a",
    ["ᾷ"] = "a",
    ["ᾄ"] = "a",
    ["ᾂ"] = "a",
    ["ᾅ"] = "a",
    ["ᾃ"] = "a",
    ["ᾆ"] = "a",
    ["ᾇ"] = "a",
    ["β"] = "b",
    ["γ"] = "g",
    ["δ"] = "d",
    ["ε"] = "e",
    ["έ"] = "e",
    ["ὲ"] = "e",
    ["ἐ"] = "e",
    ["ἔ"] = "e",
    ["ἒ"] = "e",
    ["ἑ"] = "e",
    ["ἕ"] = "e",
    ["ἓ"] = "e",
    ["ζ"] = "z",
    ["η"] = "ē",
    ["η"] = "ē",
    ["ή"] = "ē",
    ["ὴ"] = "ē",
    ["ῆ"] = "ē",
    ["ῃ"] = "ē",
    ["ἠ"] = "ē",
    ["ἤ"] = "ē",
    ["ἢ"] = "ē",
    ["ἦ"] = "ē",
    ["ᾐ"] = "ē",
    ["ἡ"] = "ē",
    ["ἥ"] = "ē",
    ["ἣ"] = "ē",
    ["ἧ"] = "ē",
    ["ᾑ"] = "ē",
    ["ῄ"] = "ē",
    ["ῂ"] = "ē",
    ["ῇ"] = "ē",
    ["ᾔ"] = "ē",
    ["ᾒ"] = "ē",
    ["ᾕ"] = "ē",
    ["ᾓ"] = "ē",
    ["ᾖ"] = "ē",
    ["ᾗ"] = "ē",
    ["θ"] = "th",
    ["ι"] = "i",
    ["ί"] = "i",
    ["ὶ"] = "i",
    ["ῖ"] = "i",
    ["ἰ"] = "i",
    ["ἴ"] = "i",
    ["ἲ"] = "i",
    ["ἶ"] = "i",
    ["ἱ"] = "i",
    ["ἵ"] = "i",
    ["ἳ"] = "i",
    ["ἷ"] = "i",
    ["ϊ"] = "i",
    ["ΐ"] = "i",
    ["ῒ"] = "i",
    ["ῗ"] = "i",
    ["κ"] = "k",
    ["λ"] = "l",
    ["μ"] = "m",
    ["ν"] = "n",
    ["ξ"] = "x",
    ["ο"] = "o",
    ["ό"] = "o",
    ["ὸ"] = "o",
    ["ὀ"] = "o",
    ["ὄ"] = "o",
    ["ὂ"] = "o",
    ["ὁ"] = "o",
    ["ὅ"] = "o",
    ["ὃ"] = "o",
    ["π"] = "p",
    ["ρ"] = "r",
    ["ῤ"] = "r",
    ["ῥ"] = "rh",
    ["σ"] = "s",
    ["ς"] = "s",
    ["τ"] = "t",
    ["υ"] = "y",
    ["ύ"] = "y",
    ["ὺ"] = "y",
    ["ῦ"] = "y",
    ["ὐ"] = "y",
    ["ὔ"] = "y",
    ["ὒ"] = "y",
    ["ὖ"] = "y",
    ["ὑ"] = "y",
    ["ὕ"] = "y",
    ["ὓ"] = "y",
    ["ὗ"] = "y",
    ["ϋ"] = "y",
    ["ΰ"] = "y",
    ["ῢ"] = "y",
    ["ῧ"] = "y",
    ["φ"] = "ph",
    ["χ"] = "ch",
    ["ψ"] = "ps",
    ["ω"] = "ō",
    ["ώ"] = "ō",
    ["ὼ"] = "ō",
    ["ῶ"] = "ō",
    ["ῳ"] = "ō",
    ["ὠ"] = "ō",
    ["ὤ"] = "ō",
    ["ὢ"] = "ō",
    ["ὦ"] = "ō",
    ["ᾠ"] = "ō",
    ["ὡ"] = "ō",
    ["ὥ"] = "ō",
    ["ὣ"] = "ō",
    ["ὧ"] = "ō",
    ["ᾡ"] = "ō",
    ["ῴ"] = "ō",
    ["ῲ"] = "ō",
    ["ῷ"] = "ō",
    ["ᾤ"] = "ō",
    ["ᾢ"] = "ō",
    ["ᾥ"] = "ō",
    ["ᾣ"] = "ō",
    ["ᾦ"] = "ō",
    ["ᾧ"] = "ō",
    }

    translit.tables["Greek transliteration lowercase"] = translit.gr_low

    --------------------------------------
    -- Uppercase Greek Transliteration  --
    --------------------------------------

    translit.gr_upp = translit.make_add_dict{
    ["Α"] = "A",
    ["Ά"] = "A",
    ["Ὰ"] = "A",
    --["ᾶ"] = "A",
    ["ᾼ"] = "A",
    ["Ἀ"] = "A",
    ["Ἁ"] = "A",
    ["Ἄ"] = "A",
    ["Ἂ"] = "A",
    ["Ἆ"] = "A",
    ["Ἁ"] = "A",
    ["Ἅ"] = "A",
    ["Ἃ"] = "A",
    ["Ἇ"] = "A",
    ["ᾉ"] = "A",
    --["ᾴ"] = "A", -- I’d be very happy if anybody could explain to me
    --["ᾲ"] = "A", -- why there's Ά, ᾌ and ᾼ but no “A + iota subscript
    --["ᾷ"] = "A", -- + acute” …, same for Η, Υ and Ω + diacritica.
    ["ᾌ"] = "A",
    ["ᾊ"] = "A",
    ["ᾍ"] = "A",
    ["ᾋ"] = "A",
    ["ᾎ"] = "A",
    ["ᾏ"] = "A",
    ["Β"] = "B",
    ["Γ"] = "G",
    ["Δ"] = "D",
    ["Ε"] = "E",
    ["Έ"] = "E",
    ["Ὲ"] = "E",
    ["Ἐ"] = "E",
    ["Ἔ"] = "E",
    ["Ἒ"] = "E",
    ["Ἑ"] = "E",
    ["Ἕ"] = "E",
    ["Ἓ"] = "E",
    ["Ζ"] = "Z",
    ["Η"] = "Ē",
    ["Η"] = "Ē",
    ["Ή"] = "Ē",
    ["Ὴ"] = "Ē",
    --["ῆ"] = "Ē",
    ["ῌ"] = "Ē",
    ["Ἠ"] = "Ē",
    ["Ἤ"] = "Ē",
    ["Ἢ"] = "Ē",
    ["Ἦ"] = "Ē",
    ["ᾘ"] = "Ē",
    ["Ἡ"] = "Ē",
    ["Ἥ"] = "Ē",
    ["Ἣ"] = "Ē",
    ["Ἧ"] = "Ē",
    ["ᾙ"] = "Ē",
    --["ῄ"] = "Ē",
    --["ῂ"] = "Ē",
    --["ῇ"] = "Ē",
    ["ᾜ"] = "Ē",
    ["ᾚ"] = "Ē",
    ["ᾝ"] = "Ē",
    ["ᾛ"] = "Ē",
    ["ᾞ"] = "Ē",
    ["ᾟ"] = "Ē",
    ["Θ"] = "Th",
    ["Ι"] = "I",
    ["Ί"] = "I",
    ["Ὶ"] = "I",
    --["ῖ"] = "I",
    ["Ἰ"] = "I",
    ["Ἴ"] = "I",
    ["Ἲ"] = "I",
    ["Ἶ"] = "I",
    ["Ἱ"] = "I",
    ["Ἵ"] = "I",
    ["Ἳ"] = "I",
    ["Ἷ"] = "I",
    ["Ϊ"] = "I",
    --["ΐ"] = "I",
    --["ῒ"] = "I",
    --["ῗ"] = "I",
    ["Κ"] = "K",
    ["Λ"] = "L",
    ["Μ"] = "M",
    ["Ν"] = "N",
    ["Ξ"] = "X",
    ["Ο"] = "O",
    ["Ό"] = "O",
    ["Ὸ"] = "O",
    ["Ὀ"] = "O",
    ["Ὄ"] = "O",
    ["Ὂ"] = "O",
    ["Ὁ"] = "O",
    ["Ὅ"] = "O",
    ["Ὃ"] = "O",
    ["Π"] = "P",
    ["Ρ"] = "R",
    --["ῤ"] = "R",
    ["Ῥ"] = "Rh",
    ["Σ"] = "S",
    ["Σ"] = "S",
    ["Τ"] = "T",
    ["Υ"] = "Y",
    ["Ύ"] = "Y",
    ["Ὺ"] = "Y",
    --["ῦ"] = "Y",
    --["ὐ"] = "Y",
    --["ὔ"] = "Y",
    --["ὒ"] = "Y",
    --["ὖ"] = "Y",
    ["Ὑ"] = "Y",
    ["Ὕ"] = "Y",
    ["Ὓ"] = "Y",
    ["Ὗ"] = "Y",
    ["Ϋ"] = "Y",
    --["ΰ"] = "Y",
    --["ῢ"] = "Y",
    --["ῧ"] = "Y",
    ["Φ"] = "Ph",
    ["Χ"] = "Ch",
    ["Ψ"] = "Ps",
    ["Ω"] = "Ō",
    ["Ώ"] = "Ō",
    ["Ὼ"] = "Ō",
    --["ῶ"] = "Ō",
    ["ῼ"] = "Ō",
    ["Ὠ"] = "Ō",
    ["Ὤ"] = "Ō",
    ["Ὢ"] = "Ō",
    ["Ὦ"] = "Ō",
    ["ᾨ"] = "Ō",
    ["Ὡ"] = "Ō",
    ["Ὥ"] = "Ō",
    ["Ὣ"] = "Ō",
    ["Ὧ"] = "Ō",
    ["ᾩ"] = "Ō",
    --["ῴ"] = "Ō",
    --["ῲ"] = "Ō",
    --["ῷ"] = "Ō",
    ["ᾬ"] = "Ō",
    ["ᾪ"] = "Ō",
    ["ᾭ"] = "Ō",
    ["ᾫ"] = "Ō",
    ["ᾮ"] = "Ō",
    ["ᾯ"] = "Ō",
    }

    translit.tables["Greek transliteration uppercase"] = translit.gr_upp

    ------------
    -- Varia  --
    ------------

    translit.gr_other = translit.make_add_dict{
    ["ϝ"] = "w",
    ["Ϝ"] = "W",
    ["ϙ"] = "q",
    ["Ϙ"] = "Q",
    ["ϡ"] = "ss",
    ["Ϡ"] = "Ss",
    }

    translit.tables["Greek transliteration archaic characters"] = translit.gr_other

    translit.done_greek = true
end

--===========================================================================--
--                              End Of Tables                                --
--===========================================================================--

local function greek (mode, text)
    local P, V, Cs = lpeg.P, lpeg.V, lpeg.Cs
    local addrules = translit.addrules
    local utfchar = translit.utfchar

    if mode == "gr" or mode == "gr_n" then

        local gr_di_in, gr_in, gr_di, gr = translit.make_add_dict{}, translit.make_add_dict{}, translit.make_add_dict{}, translit.make_add_dict{}
        gr_di_in = gr_di_in + translit.gr_di_in_low + translit.gr_di_in_upp
        gr_in    = gr_in    + translit.gr_in_low    + translit.gr_in_upp
        gr_di    = gr_di    + translit.gr_di_low    + translit.gr_di_upp
        gr       = gr       + translit.gr_low       + translit.gr_upp       + translit.gr_other

        if mode == "gr_n" then gr_di = gr_di + translit.gr_nrule end

        local p_di_in, p_in, p_di, p

        p_di_in = addrules( gr_di_in, p_di_in )
        p_in    = addrules( gr_in,    p_in    )
        p_di    = addrules( gr_di,    p_di    )
        p       = addrules( gr,       p       )

        local g = P{ -- 2959 rules
            Cs((V"init_diph"
              + V"init"
              + V"diph"
              + V"other"
              + utfchar
            )^0),

            init_diph = Cs(p_di_in / gr_di_in  ),
            init      = Cs(p_in    / gr_in     ),
            diph      = Cs(p_di    / gr_di     ),
            other     = Cs(p       / gr        ),
        }

        return g
    end
end

translit.methods["gr"] = function (text)
    p = pcache["gr"]
    if not p then
        p = greek("gr")
        pcache["gr"] = p
    end
    return lpegmatch(p, text)
end

translit.methods["gr_n"] = function (text)
    p = pcache["gr_n"]
    if not p then
        p = greek("gr_n")
        pcache["gr_n"] = p
    end
    return lpegmatch(p, text)
end

-- vim:ft=lua:sw=4:ts=4
