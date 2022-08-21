-- %D \module
-- %D   [     file=t-handlecsv-extra.lua,
-- %D      version=2019.05.27,
-- %D        title=HandleCSV extra,
-- %D     subtitle=CSV file analysis - extended functions and macros,
-- %D       author=Jaroslav Hajtmar,
-- %D         date=2019-05-27,
-- %D    copyright=Jaroslav Hajtmar,
-- %D      license=GNU General Public License]
--
-- %C Copyright (C) 2019  Jaroslav Hajtmar
-- %C
-- %C This program is free software: you can redistribute it and/or modify
-- %C it under the terms of the GNU General Public License as published by
-- %C the Free Software Foundation, either version 3 of the License, or
-- %C (at your option) any later version.
-- %C
-- %C This program is distributed in the hope that it will be useful,
-- %C but WITHOUT ANY WARRANTY; without even the implied warranty of
-- %C MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- %C GNU General Public License for more details.
-- %C
-- %C You should have received a copy of the GNU General Public License
-- %C along with this program.  If not, see <http://www.gnu.org/licenses/>.


thirddata = thirddata or { }

thirddata = thirddata or { }

thirddata.handlecsv = thirddata.handlecsv or { -- next global variables

}


-- Initialize global variables etc.


-- Utility and documentation function and macros



function thirddata.handlecsv.addleadingcharacters(character, tonumberortext, width)
-- Add leading characters to number to align with the width
   local strcharacter=tostring(character)
   local strnumberortext=tostring(tonumberortext)
   strnumberortext = string.rep(strcharacter, width-#strnumberortext)..strnumberortext
   return strnumberortext -- It returns a strange result unless the leading character is just one.
end

function thirddata.handlecsv.addleadingzeros(tonumberortext, width)
-- Add leading zeros to number to align with the width
   return thirddata.handlecsv.addleadingcharacters(0, tonumberortext, width)
end

function thirddata.handlecsv.addzeros(tonumber)
-- Add leading zeroes depending on the number of rows
    local width=string.len(tostring(thirddata.handlecsv.numrows()))
    return thirddata.handlecsv.addleadingzeros(tonumber, width)
end



-- function thirddata.handlecsv.cr_lines(s)
--    return s:gsub('\r\n?', '\n'):gmatch('(.-)\n')
-- end


function thirddata.handlecsv.file2Array(filename)
-- read CSV file into line array
local linesarray={}
 for line in io.lines (filename) do
  linesarray[#linesarray+1]=line
 end
return linesarray
end



function thirddata.handlecsv.writefileinreverseorder(inpfilename,outfilename)
-- write CSV file <inpfilename> into reverse order CSV file <outfilename>
 local tLines = thirddata.handlecsv.file2Array(inpfilename)
 local outfile = io.open(outfilename, "w")
 local ifrom=#tLines
 local ito=1
  if thirddata.handlecsv.gCSVHeader then  -- when CSV file is with header, then header line is first line
   outfile:write(tLines[1])
   outfile:write("\r\n")
   ito=2
  end
 for i = ifrom, ito, -1 do -- write rest of lines in reverse order
	outfile:write(tLines[i])
 	outfile:write("\r\n")
 end
outfile:flush()
outfile:close()
end



function thirddata.handlecsv.deletefile(filename)
-- remove file from disk
 os.remove(filename)
end


function thirddata.handlecsv.varreverseorder(csvfilename)
-- CSV file <csvfilename> is stored in variable array gTableRows['csvfilename'][row][column]
-- this function rearrange gTableRows into reverse order
local templine={}
for i = 1, math.floor(thirddata.handlecsv.gNumRows[csvfilename]/2) do
templine=thirddata.handlecsv.gTableRows[csvfilename][i]
thirddata.handlecsv.gTableRows[csvfilename][i]=thirddata.handlecsv.gTableRows[csvfilename][thirddata.handlecsv.gNumRows[csvfilename]-i+1]
thirddata.handlecsv.gTableRows[csvfilename][thirddata.handlecsv.gNumRows[csvfilename]-i+1]=templine
end
end





-- ConTeXt source:
local string2print=[[%

\def\addleading#1#2#3{\ctxlua{context(thirddata.handlecsv.addleadingcharacters('#1','#2','#3'))}}
\def\addzeros#1#2{\ctxlua{context(thirddata.handlecsv.addleadingzeros('#1','#2'))}}
\def\zeroed#1{\ctxlua{context(thirddata.handlecsv.addzeros('#1'))}}
% \def\zeroedlineno{\ctxlua{context(string.rep( "0",(tostring(thirddata.handlecsv.numrows())):len() - (tostring(thirddata.handlecsv.linepointer())):len()) .. thirddata.handlecsv.linepointer())}}% from Pablo
\def\zeroedlineno{\zeroed{\lineno}}% from Pablo (and simplified by him)
\def\writefileinreverseorderfromto#1#2{\ctxlua{thirddata.handlecsv.writefileinreverseorder('#1','#2')}}%
\def\writecurrfileinreverseorderto#1{\ctxlua{thirddata.handlecsv.writefileinreverseorder(thirddata.handlecsv.gCurrentlyProcessedCSVFile,'#1')}}%
\def\deletefile#1{\ctxlua{thirddata.handlecsv.deletefile('#1')}}%
\def\reverseorderof#1{\ctxlua{thirddata.handlecsv.varreverseorder('#1')}}
\def\reverseorder{\ctxlua{thirddata.handlecsv.varreverseorder(thirddata.handlecsv.gCurrentlyProcessedCSVFile)}}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Complete listing macros and commands that can be used (to keep track of all defined macros):
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% \addleading{}{}{}, \addzeros{}{}, \zeroed{}, \zeroedlineno (from Pablo)
% \writefileinreverseorderfromto{<inpfilename>}{<outfilename>} % create file <outfilename> in reverse order of file <inpfilename>
% \writecurrfileinreverseorderto{<outfilename>} % create file <outfilename> in reverse order
% \deletefile{<filename>} % close and delete file <filename>
% \reverseorderof{<csvfilename>} % reverse order of opened CSV file <csvfilename>
% \reverseorder % reverse order of currently processed CSV file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
]]

-- write definitions into ConTeXt:
thirddata.handlecsv.string2context(string2print)

