-- %D \module
-- %D   [     file=t-handlecsv-tools.lua,
-- %D      version=2015.07.08,
-- %D        title=HandleCSV tools,
-- %D     subtitle=CSV file analysis,
-- %D       author=Jaroslav Hajtmar,
-- %D         date=\currentdate,
-- %D    copyright=Jaroslav Hajtmar,
-- %D      license=GNU General Public License]
-- 
-- %C Copyright (C) 2015  Jaroslav Hajtmar
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


-- use a feature that is part of the /texmf-dist/tex/context/base/util-prs.lua

thirddata = thirddata or { }

thirddata = thirddata or { }

thirddata.handlecsv = thirddata.handlecsv or { -- next global variables

}


-- Initialize global variables etc.


-- Utility and documentation function and macros

function thirddata.handlecsv.csvreport(anyfilename) -- Listing report informations about opening a CSV file
	local actualopenfile=thirddata.handlecsv.gCurrentlyProcessedCSVFile
	thirddata.handlecsv.opencsvfile(anyfilename)
 	local coldelim = thirddata.handlecsv.gUserCSVSeparator or ""
	local quot = thirddata.handlecsv.gUserCSVQuoter or ""
	local currcoldelim = thirddata.handlecsv.gCSVSeparator or ""
	local currquot = thirddata.handlecsv.gCSVQuoter or ""
	infomakra=[[\crlf ]]
	for i = 1, thirddata.handlecsv.gNumCols do 	-- for all fields in header
		local makroname=[[{\bf\backslash ]]..thirddata.handlecsv.tmn(thirddata.handlecsv.gColumnNames[i])..[[}]]
		  headercolnames = [[{\bf\backslash c]]..thirddata.handlecsv.ar2colnum(i)..[[}=]]..makroname..[[, ]]
			infomakra=infomakra..headercolnames -- list generating
	  end -- for i=1, #gCSV
		-- Kvůli nastavení na zač.
	infomakra=infomakra..'\\par'   -- infomakra=infomakra..'\par'  -- closing of opened group
local string2print=[[\title{Current CSV file report}
Input CSV file: {\bf ]]..'\\csvfilename'..[[} \crlf
Existing header of CSV file (ie first no data line) : {\tt ]]..tostring(thirddata.handlecsv.gCSVHeader)..[[}\crlf
Settings default CSV separator (see Lua variable {\tt gUserCSVSeparator}) :  ]]..coldelim..[[\crlf
Settings default CSV field "quoter" (see Lua variable {\tt gUserCSVQuoter}) :  ]]..quot..[[\crlf
Settings current CSV separator :  ]]..currcoldelim..[[\crlf
Settings current CSV field "quoter" :  ]]..currquot..[[\crlf
Current settings of delimiters and quoters:    {\tt ]]..currquot..[[field1]]..currquot..currcoldelim..currquot..[[field2]]..currquot..currcoldelim..currquot..[[field3]]..currquot..currcoldelim..[[ } ... etc.\crlf
Using hooks (default is off) : {\tt ]]..tostring(thirddata.handlecsv.gUseHooks)..[[}\crlf
Number of columns in a table:  {\bf]]..'\\numcols'..[[}\crlf
Number of rows in the table:  {\bf ]]..'\\numrows'..[[}\crlf
Macros supplying columns data in each row of table:  ]]..infomakra..[[
\crlf
Additional predefined macros: \crlf
{\bf\backslash csvfilename} -- name of open CSV file ({\bf]]..'\\csvfilename'..[[})\crlf
{\bf\backslash numcols} -- number of table columns ({\bf]]..'\\numcols'..[[})\crlf
{\bf\backslash numrows} -- number of table lines ({\bf]]..'\\numrows'..[[})\crlf
{\bf\backslash numline} -- number of the currently loaded row (for use in print reports) \crlf
{\bf\backslash lineno} -- serial number of the actual loaded line of CSV table \crlf
{\bf\backslash csvreport} -- prints the report on file open \crlf
{\bf\backslash printline} -- lists the current CSV row table in a condensed form \crlf
{\bf\backslash printall} -- CSV output table in a condensed form \crlf
{\bf\backslash setfiletoscan}\{{\it filename}\} -- setting of name of CSV file\crlf
{\bf\backslash opencsvfile}{\{\it filename}\} -- open CSV table\crlf
{\bf\backslash setheader} -- set a header flag\crlf
{\bf\backslash resetheader} -- unset a header flag\crlf
{\bf\backslash nextrow} -- next row of CSV table (with test of EOF)\crlf
{\bf\backslash setsep}{\{\it delimiter}\} -- set delimiter of columns\crlf
{\bf\backslash resetsep} -- unset to default values\crlf
{\bf\backslash setld}\{{\it delimiter}\} -- set left quoter\crlf
{\bf\backslash resetld} -- unset left quoter to default values\crlf
{\bf\backslash setrd}\{{\it delimiter}\} -- set right quoter\crlf
{\bf\backslash resetrd} -- unset right quoter to default values\crlf
{\bf\backslash blinehook} -- begin line hook macro (process before first column value of each row)\crlf
{\bf\backslash elinehook} -- end line hook macro (process after last column value of each row)\crlf
{\bf\backslash bfilehook} -- begin file hook macro (process before whole file processing)\crlf
{\bf\backslash efilehook} -- end file hook macro (process after whole file processing)\crlf
\vfill\break ]]
thirddata.handlecsv.string2context(string2print)
thirddata.handlecsv.opencsvfile(actualopenfile)
end -- thirddata.handlecsv.csvreport()

function thirddata.handlecsv.xprintline() -- lists the current CSV row table (needed to define macro \printline)
	for i=1,thirddata.handlecsv.gNumCols do
      context([[\csvcell]]..'['..i..','..thirddata.handlecsv.gCurrentLinePointer..']'..thirddata.handlecsv.gCSVSeparator..[[ ]])
   end
end


function thirddata.handlecsv.xprintall() -- lists all the csv table (necessary to define macros \printall)
--  http://www.pragma-ade.nl/general/manuals/hybrid.pdf
 thirddata.handlecsv.opencsvfile()
 local basespec = {
	framecolor = "blue",
	split="yes",
	align= "middle",
	style = "sans",
	offset="2pt",
	}
 context.bTABLE(basespec)
 		 for i=1, thirddata.handlecsv.gNumRows do
      	context.bTR()
		  for j=1,thirddata.handlecsv.gNumCols do
  			context.bTD()
        	context([[\csvcell]]..'['..j..','..i..']') -- Writing real values ...
        	-- context(thirddata.handlecsv.gTableRows[j][i]..' ') -- Writing real values ...
        	context.eTD()
		  end
			context.eTR()
		end -- of for
context.eTABLE()
end



-- ConTeXt source:
local string2print=[[%

% CSV file report. Syntax: \csvreport or \csvreport{filename}.
\def\csvreport{\dosingleempty\docsvreport}%
\def\docsvreport[#1]{\dosinglegroupempty\dodocsvreport}%
\def\dodocsvreport#1{\iffirstargument\ctxlua{thirddata.handlecsv.csvreport("#1")}\else\ctxlua{thirddata.handlecsv.csvreport()}\fi}%

%\def\xprintline{\ctxlua{context(thirddata.handlecsv.printline())}}


% Původní verze:
% \def\xprintall{\ctxlua{context(thirddata.handlecsv.xprintall())}}

\def\printline{\dorecurse{\numcols}{\csvcell[\recurselevel,\linepointer], }\crlf}


\def\printall{%
\setuppapersize[A3,landscape][A3,landscape]
\catcode`\#=12 %CSV file contains # characters (i.e. TeX problematic character)
\switchtobodyfont[10pt]
\setupTABLE[background=color,backgroundcolor=yellow]
\setupTABLE[row][first][background=color,backgroundcolor=lightgray]
\bTABLE[offset=2pt, split=yes]
 \dorecurse{\numexpr(\numrows+1)}
 {\bTR
   \dorecurse{\numcols}
	 {\bTD \csvcell[\currentTABLEcolumn,\currentTABLErow-1] \eTD}
 \eTR}
\eTABLE
}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Complete listing macros and commands that can be used (to keep track of all defined macros):
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% \csvreport,  \csvreport{<filename>}
% \printline
% \printall
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
]]

-- write definitions into ConTeXt:
thirddata.handlecsv.string2context(string2print)

