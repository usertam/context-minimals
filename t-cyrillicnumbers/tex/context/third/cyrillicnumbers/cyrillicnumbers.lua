#!/usr/bin/env texlua
--------------------------------------------------------------------------------
--         FILE:  cyrillicnumbers.lua
--        USAGE:  called by t-cyrillicnumbers.mkvi
--  DESCRIPTION:  part of the Cyrillic Numbers module for ConTeXt
-- REQUIREMENTS:  recent ConTeXt MkIV and LuaTeX
--       AUTHOR:  Philipp Gesang (phg), <phg42 dot 2a at gmail dot com>
--      VERSION:  hg tip
--      CHANGED:  2013-03-28 00:10:47+0100
--------------------------------------------------------------------------------
--

--[[ldx--
<p>read this first:</p>

<p>Жолобов, О. Ф.: <key>Числительные</key>. In: <key>Историческая
                   грамматика древнерусского языка</key>, vol. 4, Moskva
                   2006, pp. 58--63</p>

<p>Trunte, Nikolaos H.: <key>Altkirchenslavisch</key>. In:
                        <key>Словѣньскъи ѩꙁъікъ.  Ein praktisches Lehrbuch
                        des Kirchenslavischen in 30 Lektionen. Zugleich eine
                        Einführung in die slavische Philologie</key>, vol.
                        1, München ⁵2005, pp. 161ff.</p>

<p>or have a glance at these:</p>

<typing>
http://www.pravpiter.ru/zads/n018/ta013.htm
http://www.uni-giessen.de/partosch/eurotex99/berdnikov2.pdf
http://ru.wikipedia.org/wiki/Кириллическая_система_счисления
</typing>
--ldx]]--

local iowrite      = io.write
local mathceil     = math.ceil
local mathfloor    = math.floor
local stringformat = string.format
local tableconcat  = table.concat
local tableinsert  = table.insert
local tostring     = tostring
local type         = type
local utf8char     = unicode.utf8.char
local utf8len      = unicode.utf8.len


local cyrnum     = {
  placetitlo    = "font",
  prefer100k    = false,
  titlolocation = "final", -- above final digit
  titlospan     = 3,       -- only with mp
  drawdots      = true,
  debug         = false,
}

thirddata        = thirddata or { }
thirddata.cyrnum = cyrnum

local dbgpfx = "[cyrnum]"
local dbg = function (...)
  if cyrnum.debug then
    local args = {...}
    if type(args[1]) == "table" then args = args[1] end
    iowrite(dbgpfx)
    for i=1, #args do
      local this = args[i]
      local tthis = type(this)
      iowrite" "
      if tthis == "number" or tthis == "string" then
        iowrite(this)
      else
        iowrite(tostring(this))
      end
    end
    iowrite"\n"
  end
end

local cyrillic_numerals = {
  { "а", "в", "г", "д", "е", "ѕ", "з", "и", "ѳ", },
  { "і", "к", "л", "м", "н", "ѯ", "о", "п", "ч", },
  { "р", "с", "т", "у", "ф", "х", "ѱ", "ѡ", "ц", },
}
local cyrillic_1k    = "҂"
local cyrillic_100k  = utf8char(0x488) -- combining hundred thousands sign
local cyrillic_1m    = utf8char(0x489) -- combining million sign
local cyrillic_titlo = utf8char(0x483) -- combining titlo

--[[ldx--
<p>Some string synonyms for user convenience.</p>
--ldx]]--
cyrnum.yes_synonyms = {
  yes      = true,
  yeah     = true,
  ["true"] = true,
}

cyrnum.no_synonyms = {
  no        = true,
  nope      = true,
  ["false"] = true,
}

--[[ldx--
<p><type>m</type> for rounded down middle position, <type>l</type> for final
position. Will default to initial position otherwise.</p>
--ldx]]--
cyrnum.position_synonyms = {
  final     = "l",
  last      = "l",
  right     = "l",
  rightmost = "l",
  ["false"] = "l",
  middle    = "m",
  center    = "m",
  ["true"]  = "m",
}

--[[ldx--
<p>Digits above the thirds require special markers, some of which need to be
placed before, others after the determined character.</p>
--ldx]]--
local handle_plus1k = function (digit)
  local before, after
  if digit == 7 then
    after = cyrillic_1m
  elseif cyrnum.prefer100k and digit == 6 then
    after = cyrillic_100k
  elseif digit > 3 then -- insert thousand sign
    before = cyrillic_1k
  end
  return before, after
end

-- digit list = {
--  [1] = character to be printed
--  [2] = real digit of character
--  [3] = print this before character (e.g. thousand signs)
--  [4] = print this after character  (e.g. million signs)
-- }

--[[ldx--
<p>The base list of digits denotes empty (zero) digits with "false" values
instead of characters. The function <type>digits_only</type> will extract only
the nonempty digit values, returning a list.</p>
--ldx]]--
local digits_only = function (list)
  local result = { }
  for i=1, #list do
    local elm = list[i]
    if type(elm) == "string" then
      local before, after
      if i > 3 then
        before, after = handle_plus1k(i)
      end
      result[#result+1] = { elm, i, before, after } -- i contains the real digit
    end
  end
  return result
end

--[[ldx--
<p>The different ways for drawing the <italic>titlo</italic> are stored inside
a table. Basically, the options are to use the titlos symbol that is provided
by the font or to draw the titlo in <l n="metapost"/>.</p>
--ldx]]--
local lreverse = function(list)local r={}for i=#list,1,-1 do r[#r+1]=list[i]end return r end

local start_titlo, stop_titlo = [[\cyrnumdrawtitlo{]], "}"

local titlofuncs = {
  font = function (list)
    local result, titlopos = { }, #list
    if cyrnum.titlolocation == "l" then
      titlopos = 1
    elseif cyrnum.titlolocation == "m" then
      titlopos = mathceil(#list/2)
    end
    for i=#list, 1, -1 do
      local char, digit, before, after = list[i][1], list[i][2], list[i][3], list[i][4]
      if before then
        result[#result+1] = before
      end
      result[#result+1] = char
      if after then
        result[#result+1] = after
      end
      if i == titlopos then
        result[#result+1] = cyrillic_titlo
      end
    end
    return result
  end,
  mp = function (list)
    local result     = { }
    local titlospan  = cyrnum.titlospan
    local titlotype  = cyrnum.titlotype
    local titlostart = #list -- default to “all”
    if titlotype == true then -- number
      titlostart = (#list >= titlospan) and titlospan or #list
    end
    for i=#list, 1, -1 do
      local char, digit, before, after = list[i][1], list[i][2], list[i][3], list[i][4]
      --local char, digit, before, after = unpack(list[i])
      if i == titlostart then
        result[#result+1] = start_titlo
      end
      if before then
        result[#result+1] = before
      end
      result[#result+1] = char
      if after then
        result[#result+1] = after
      end
    end
    result[#result+1] = stop_titlo
    return result
  end,
  no = function (list)
    local result = { }
    for i=#list, 1, -1 do
      local char, digit, before, after = list[i][1], list[i][2], list[i][3], list[i][4]
      if before then
        result[#result+1] = before
      end
      result[#result+1] = char
      if after then
        result[#result+1] = after
      end
    end
    return result
  end,
}

--[[ldx--
<p>Concatenation of the digit list has to take into account different conditions: whether the user requests the dot markers to be added, whether a titlo is requested etc.</p>
--ldx]]--
local concat_cyrillic_nums = function (list)
  local result         = ""
  local digits         = digits_only(list) -- strip placeholders
  local nlist, ndigits = #list, #digits
  dbg(list)
  --dbg(digits)
  local titlo = titlofuncs[cyrnum.placetitlo]
  if titlo then
    result = tableconcat(titlo(digits))
    if cyrnum.drawdots then
      local sym = cyrnum.dotsymbol
      result = sym .. result .. sym
    end
  end
  dbg(result)
  return result
end

local do_tocyrillic do_tocyrillic = function (n, result)
  if n < 1000 then
    local mod100 = n % 100
    if #result == 0 and  mod100 > 10 and mod100 < 20 then
      result[#result+1] = "і"
      result[#result+1] = cyrillic_numerals[1][mod100%10]             or false
    else
      result[#result+1] = cyrillic_numerals[1][mathfloor(n%10)]       or false
      result[#result+1] = cyrillic_numerals[2][mathfloor((n%100)/10)] or false
    end
    result[#result+1] = cyrillic_numerals[3][mathfloor((n%1000)/100)] or false
  else
    result = do_tocyrillic(n%1000, result)
    result = do_tocyrillic(mathfloor(n/1000), result)
  end
  return result
end

local tocyrillic = function (n)
  local chars = do_tocyrillic(n, { })
  return concat_cyrillic_nums(chars)
end

local Tocyrillic = function (n)
  local chars = do_tocyrillic(n, { })
  return concat_cyrillic_nums(chars, true)
end

converters.tocyrillic       = tocyrillic
converters.cyrillicnumerals = tocyrillic
converters.Cyrillicnumerals = Tocyrillic

function commands.cyrillicnumerals (n) context(tocyrillic(n)) end
function commands.Cyrillicnumerals (n) context(Tocyrillic(n)) end

--- Fun ---------------------------------------------------------

local f_peano = [[suc(%s)]]
local do_topeano = function (n)
  n = tonumber(n) or 0
  if n == 0 then return "0" end
  local result = stringformat(f_peano, 0)
  if n == 1 then return result end
  for i=2, n do
    result = stringformat(f_peano, result)
  end
  return result
end

local s_churchp = [[λf.λx.\;]]
local s_church0 = [[x]]
local s_church1 = [[f\,x]]
local f_church  = [[f(%s)]]
local do_tochurch = function (n)
  if     n == 0 then return s_churchp .. s_church0
  elseif n == 1 then return s_churchp .. s_church1 end
  local result = stringformat(f_church, s_church1)
  for i=2, n do
    result = stringformat(f_church, result)
  end
  return s_churchp .. result
end

converters.topeano  = do_topeano
converters.tochurch = do_tochurch

commands.peanonumerals  = function (n) context(do_topeano(n))              end
commands.churchnumerals = function (n) context.mathematics(do_tochurch(n)) end

-- vim:ft=lua:ts=2:sw=2:expandtab:fo=croql
