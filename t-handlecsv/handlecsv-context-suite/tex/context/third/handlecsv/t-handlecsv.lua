-- %D \module
-- %D   [     file=t-handlecsv.lua,
-- %D      version=2019.03.30,
-- %D        title=HandleCSV module,
-- %D     subtitle=CSV file handling,
-- %D       author=Jaroslav Hajtmar,
-- %D         date=\currentdate,
-- %D    copyright=Jaroslav Hajtmar,
-- %D        email=hajtmar@gyza.cz,
-- %D      license=GNU General Public License]
--
-- %C Copyright (C) 2019 Jaroslav Hajtmar
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

thirddata.handlecsv = { -- Global variables
--	 gCSVSeparator
    gUserCSVSeparator=';',  -- the most widely used field separator in CSV tables
--  gCSVQuoter
    gUserCSVQuoter='"', --
--	 gCSVHeader
	gUserCSVHeader=false, -- CSV file is by default considered as a CSV file without the header (in header are treated as column names of macros
	gUserUseHooks=false, -- In default setting is not use "hooks" when process CSV file
    gUserColumnNumbering='XLS',  -- Something other than the XLS or undefined variable value (eg commenting that line) to set the Roman numbering ...
    gCurrentlyProcessedCSVFile=nil,
  	gMarkingEmptyLines=false,
    gUserMarkingEmptyLines=false, -- if true, then module mark empty rows in CSV file else module accept empty lines as regular lines
	gTableEmptyRows={}, -- array of indexes of empty lines of CSV table -> gTableEmptyRows['csvfilename'][1]= 3 etc
	gTableNotEmptyRows={}, -- array of indexes of nonempty lines of CSV table -> gTableNotEmptyRows['csvfilename'][1]= 3 etc
	gCSVHandleBuffer={}, -- temporary buffer
-- NEW variables
    gOpenFiles={}, -- array of all opened files
    gNumLine={}, -- global variable -      gNumLine['csvfilename.csv']=0
    gNumRows={}, -- global variable  - save number of rows of csv table: gNumRows['csvfilename']=0
	gNumEmptyRows={},  -- global variable  - save number of empty rows of csv table: gNumEmptyRows['csvfilename']=0
	gNumNotEmptyRows={},  -- global variable  - save number of empty rows of csv table: gNumNotEmptyRows['csvfilename']=0
    gNumCols={}, -- global variable  - save number of columns of csv table: gNumCols['csvfilename']=0
    gCurrentLinePointer={}, -- ie. CSV line number ie. number of the currently processed row: gCurrentLinePointer['csvfilename']=0
    gColumnNames={}, -- array with column names (readings from header of CSV file): gColumnNames['csvfilename']
    gColNames={}, -- associative array with column names for indexing use f.e. gColNames['csvfilename']['Firstname']=1, etc...
	gTableRows={}, -- array of contents of cells of CSV table -> gTableRows['csvfilename'][row][column]
	gTableRowsIndex={}, -- array of flags of lines of CSV table -> gTableEmptyRowsIndex['csvfilename'][i]= true or false
	gSavedLinePointerNo=1, -- global variable to keep the line number
}

local setmacro = interfaces.setmacro or ""

-- Initialize global variables etc.

--  Default value is saved  in glob. variable gUseHooks (default is FALSE)
if thirddata.handlecsv.gUseHooks == nil then thirddata.handlecsv.gUseHooks = thirddata.handlecsv.gUserUseHooks end
--  Default value is saved  in glob. variable gUserCSVHeader (default FALSE)
if thirddata.handlecsv.gCSVHeader == nil then thirddata.handlecsv.gCSVHeader = thirddata.handlecsv.gUserCSVHeader end
--  Default value is saved  in glob. variable gCSVSeparator (default COMMA)
if thirddata.handlecsv.gCSVSeparator == nil then thirddata.handlecsv.gCSVSeparator = thirddata.handlecsv.gUserCSVSeparator end
--  Default value is saved  in glob. variable gCSVSeparator (default ")
if thirddata.handlecsv.gCSVQuoter == nil then thirddata.handlecsv.gCSVQuoter = thirddata.handlecsv.gUserCSVQuoter end
--  Default value is saved  in glob. variable gMarkingEmptyLines (default is FALSE)
if thirddata.handlecsv.gMarkingEmptyLines==nil then thirddata.handlecsv.gMarkingEmptyLines = thirddata.handlecsv.gUserMarkingEmptyLines end


-- Tools block: Contain auxiliary functions and tools


function thirddata.handlecsv.texmacroisdefined(macroname) -- check whether macroname macro is defined  in ConTeXt
-- function is used to test whether the user has defined the macro \macroname. If not, it needs to define any default value
  return token.get_cmdname(token.create(macroname)) ~= "undefined_cs"
end

function thirddata.handlecsv.ParseCSVLine(line,sep)
-- tool function ParseCSVLine is defined for compatibility. Parsing string (or line).
	local mycsvsplitter = utilities.parsers.rfc4180splitter{
	    separator = sep,
	    quote = '"',
	    strict=true, -- add 15.2.2016
	}
	local list = mycsvsplitter(line) inspect(list)
	return list[1]
end


function thirddata.handlecsv.tmn(s) -- TeX Macro Name. Name of TeX macro should not contain forbidden characters
	if string.len(s) == 0 then s='nil' end -- When the parameter 's' does not contain any character that is not the separator character, it is necessary to create macro name
  maxmacrolength=50 -- if the first string in line longer "than is healthy, so about 50 characters is sufficient
  -- ATTENTION! In the case that 1st CSV table row header that is a different column for content, which coincides with the first 'maxmacrolength' characters, the names of macros in different columns are the same (ie, the macro will give the correct result for the column)
	diachar=  {"á","ä","č","ď","é","ě","í","ň","ó","ř","š","ť","ú","ů","ý","ž","Á","Ä","Č","Ď","É","Ě","Í","Ň","Ó","Ř","Š","Ť","Ú","Ů","Ý","Ž"}
	asciichar={"a","a","c","d","e","e","i","n","o","r","s","t","u","u","y","z","A","A","C","D","E","E","I","N","O","R","S","T","U","U","Y","Z"}
	for i=1, 32 do
		s=string.gsub(s, diachar[i], asciichar[i]) -- change diakritics chars
	end
	--s=string.gsub(s, "%d", "n") -- replace the numbers in name
	-- For 0-9 to replace the letter O or Roman numerals
	s=string.gsub(s, "0", "O") -- replace the numbers in name
	s=string.gsub(s, "1", "I") -- replace the numbers in name
	s=string.gsub(s, "2", "II") --
	s=string.gsub(s, "3", "III") --
	s=string.gsub(s, "4", "IV") --
	s=string.gsub(s, "5", "V") --
	s=string.gsub(s, "6", "VI") --
	s=string.gsub(s, "7", "VII") --
	s=string.gsub(s, "8", "VIII") --
	s=string.gsub(s, "9", "IX") --
	s=string.gsub(s, "%A", "x") -- Finally still removes all nealfabetic characters that were left there
  if string.len(s) > maxmacrolength+1 then s=string.sub(s, 1, maxmacrolength) end -- to limit the maximum length of a macro
return s
end


function thirddata.handlecsv.xls2ar(colname) -- convert Excel column name (like A, B, ... AA, AB, ...) into serial number of column (A->1, B->2, ...)
   -- No for more than 702 columns (ie last column parametr for this function is ZZ)
   -- for example Excel 2003 can handle only up to the column IV!
	local colnumber=0
	local colname=colname:upper()
	for i=1, string.len(colname) do
	 local onechar = string.sub(colname,i,i)
	 colnumber=26*colnumber + (string.byte(onechar) - string.byte('A') + 1)
	end
 return colnumber
end



function thirddata.handlecsv.ar2xls(arnum) -- convert number to Excel name column
   -- For more than 703 columns (ie column A to ZZ) should be a function to modify
   -- Excel 2003 can handle only up to the column IV!
	local part=math.floor(arnum/26)
   local remainder = math.mod(arnum,26)
   part = part   - (math.mod(arnum,26)==0 and 1 or 0)
	remainder = remainder + (math.mod(arnum,26)==0 and 26 or 0)
   local ctl =''
	 if arnum < 703 then
			 if part > 0 then
			   ctl=string.char(64+part)
			 end
			 ctl = ctl .. string.char(64+remainder)
 	 else
    ctl = 'overZZ'
	 end
 return ctl
end


function thirddata.handlecsv.ar2colnum(arnum) -- According to the settings glob. variable returns the column designation of TeX macros
	-- generated TeX macros referring to values in columns are numbered a`la EXCEL ie cA, cB, ..., cAA, etc
	-- or a`la roman number ie. cI, cII, cIII, cIV, ..., cXVIII, etc
	-- if it is "romannumbers" setting, then columns wil numbered by Romna else ala Excel
	if string.lower(thirddata.handlecsv.gUserColumnNumbering) == 'xls' then
		return thirddata.handlecsv.ar2xls(arnum) --  a la EXCEL
	else
      return string.upper(converters.romannumerals(arnum)) -- a la big ROMAN - convert Arabic numbers to big Roman. Used for "numbering" column in the TeX macros
   end
end

function thirddata.handlecsv.substitutecontentofcellof(csvfile,column,row,whattoreplace,substitution)
-- Substitute text in cell content of specified CSV file with other text
  local csvfile=thirddata.handlecsv.handlecsvfile(csvfile)
  local column=thirddata.handlecsv.gColNames[csvfile][column]
  local whattoreplace=tostring(whattoreplace)
  local substitution=tostring(substitution)
  return thirddata.handlecsv.getcellcontentof(csvfile,column,row):gsub(whattoreplace,substitution)
end

function thirddata.handlecsv.substitutecontentofcell(column,row,whattoreplace,substitution)
-- Substitute text in cell content of current CSV file with other text
  local csvfile=thirddata.handlecsv.getcurrentcsvfilename()
  local column=thirddata.handlecsv.gColNames[csvfile][column]
  return thirddata.handlecsv.substitutecontentofcellof(csvfile,column,row,whattoreplace,substitution)
end

function thirddata.handlecsv.substitutecontentofcellofcurrentrow(column,whattoreplace,substitution)
-- Substitute text in cell content of current row of current CSV file with other text
  local row=thirddata.handlecsv.linepointer()
  return thirddata.handlecsv.substitutecontentofcell(column,row,whattoreplace,substitution)
end

function thirddata.handlecsv.processinputvalue(inputparameter,replacingnumber)
-- when inputparameter is not correct, then return replacingnumber
local returnparameter=inputparameter
	if type(inputparameter)~= 'number' then
		returnparameter=replacingnumber
	end --
return returnparameter
end


-- Main functions and macros:

function thirddata.handlecsv.hookson()
 thirddata.handlecsv.gUseHooks=true
end

function thirddata.handlecsv.hooksoff()
 thirddata.handlecsv.gUseHooks=false
end

function thirddata.handlecsv.setfiletoscan(filetoscan)
   local inpcsvfile=thirddata.handlecsv.handlecsvfile(filetoscan)
 thirddata.handlecsv.gCurrentlyProcessedCSVFile=inpcsvfile
end


function thirddata.handlecsv.setheader()
 thirddata.handlecsv.gCSVHeader=true
 context([[\global\issetheadertrue%]])
 context([[\global\notsetheaderfalse%]])
end


function thirddata.handlecsv.unsetheader()
 thirddata.handlecsv.gCSVHeader=false
 context([[\global\issetheaderfalse%]])
 context([[\global\notsetheadertrue%]])
end

function thirddata.handlecsv.setsep(sep)
  thirddata.handlecsv.gCSVSeparator=sep
end

function thirddata.handlecsv.unsetsep()
  thirddata.handlecsv.gCSVSeparator=thirddata.handlecsv.gUserCSVSeparator
end

function thirddata.handlecsv.indexofnotemptyline(sernumline)
local csvfilename=thirddata.handlecsv.getcurrentcsvfilename()
	return thirddata.handlecsv.gTableNotEmptyRows[csvfilename][sernumline]
end

function thirddata.handlecsv.indexofemptyline(sernumline)
local csvfilename=thirddata.handlecsv.getcurrentcsvfilename()
	return thirddata.handlecsv.gTableEmptyRows[csvfilename][sernumline]
end

function thirddata.handlecsv.notmarkemptylines()
local csvfilename=thirddata.handlecsv.getcurrentcsvfilename()
   thirddata.handlecsv.gMarkingEmptyLines=false
   for row=1,thirddata.handlecsv.gNumRows[csvfilename] do
		thirddata.handlecsv.gTableNotEmptyRows[csvfilename][row]=row
     end
 	 thirddata.handlecsv.gTableEmptyRows[csvfilename]={}
 	 thirddata.handlecsv.gNumEmptyRows[csvfilename]=0
	 thirddata.handlecsv.gNumNotEmptyRows[csvfilename]=thirddata.handlecsv.gNumRows[csvfilename]
	 context([[\global\emptylinefalse%]])
	 context([[\global\notemptylinetrue%]])
	 context([[\global\emptylinesmarkingfalse%]])
	 context([[\global\emptylinesnotmarkingtrue%]])
end

function thirddata.handlecsv.markemptylines()
local csvfilename=thirddata.handlecsv.getcurrentcsvfilename()
 	thirddata.handlecsv.gTableEmptyRows[csvfilename]={}
 	thirddata.handlecsv.gTableNotEmptyRows[csvfilename]={}
	thirddata.handlecsv.gMarkingEmptyLines=true
 	 local counteremptylines=0
	 local counternotemptylines=0
	  for row=1,thirddata.handlecsv.gNumRows[csvfilename] do
			if thirddata.handlecsv.testemptyrow(row) then
				counteremptylines=counteremptylines+1
				thirddata.handlecsv.gTableEmptyRows[csvfilename][counteremptylines]=row
			else
				counternotemptylines=counternotemptylines+1
				thirddata.handlecsv.gTableNotEmptyRows[csvfilename][counternotemptylines]=row
			end
	  end -- for
	  thirddata.handlecsv.gNumEmptyRows[csvfilename]=counteremptylines
	  thirddata.handlecsv.gNumNotEmptyRows[csvfilename]=counternotemptylines
	  context([[\global\emptylinesmarkingtrue%]])
	  context([[\global\emptylinesnotmarkingfalse%]])
end


function thirddata.handlecsv.resetmarkemptylines()
-- do following lines only when file contain completely empty rows and is requiring testing empty lines
local csvfilename=thirddata.handlecsv.getcurrentcsvfilename()
	thirddata.handlecsv.gMarkingEmptyLines = thirddata.handlecsv.gUserMarkingEmptyLines
	 if thirddata.handlecsv.gMarkingEmptyLines then
	    thirddata.handlecsv.markemptylines()
	 else thirddata.handlecsv.notmarkemptylines()
	 end  -- if thirddata.handlecsv.gMarkingEmptyLines
end


function thirddata.handlecsv.testemptyrow(lineindex)
local csvfilename=thirddata.handlecsv.getcurrentcsvfilename()
local linecontent=""
local isemptyline=false
	for column=1,thirddata.handlecsv.gNumCols[csvfilename] do
		linecontent=linecontent..thirddata.handlecsv.gTableRows[csvfilename][lineindex][column]
	end
	if linecontent=="" or linecontent==nil then
		isemptyline=true
--		thirddata.handlecsv.gNumEmptyRows[csvfilename]=thirddata.handlecsv.gNumEmptyRows[csvfilename]+1
	end
	thirddata.handlecsv.gTableRowsIndex[csvfilename][lineindex]=isemptyline
 return isemptyline
end


function thirddata.handlecsv.emptylineevaluation(lineindex)
	if thirddata.handlecsv.gTableRowsIndex[thirddata.handlecsv.getcurrentcsvfilename()][lineindex] then
	  context([[\global\emptylinetrue%]])
	  context([[\global\notemptylinefalse%]])
	else
	 context([[\global\emptylinefalse%]])
	 context([[\global\notemptylinetrue%]])
	end
	return thirddata.handlecsv.gTableRowsIndex[thirddata.handlecsv.getcurrentcsvfilename()][lineindex]
end


function thirddata.handlecsv.removeemptylines()
-- This function remove empty rows only from field of variables thirddata.handlecsv.gTableRows!
-- The field is only re-indexed and function does not affect onto the physical input CSV file!
-- When the physical CSV file is reopened by using \open macro, the global field variable
-- thirddata.handlecsv.gTableRows[csvfile] is reset into original state!
	thirddata.handlecsv.markemptylines()
	local csvfilename=thirddata.handlecsv.getcurrentcsvfilename()

	for i=1,thirddata.handlecsv.gNumNotEmptyRows[csvfilename] do
		local indexofnotemptyrow=thirddata.handlecsv.gTableNotEmptyRows[csvfilename][i]
		-- i<--indexofnotemptyrow
		thirddata.handlecsv.gTableRows[csvfilename][i]=thirddata.handlecsv.gTableRows[csvfilename][indexofnotemptyrow]
	end

	for i=thirddata.handlecsv.gNumNotEmptyRows[csvfilename]+1,thirddata.handlecsv.gNumRows[csvfilename] do
		thirddata.handlecsv.gTableRows[csvfilename][i]=nil
	end

	thirddata.handlecsv.gNumRows[csvfilename]=thirddata.handlecsv.gNumNotEmptyRows[csvfilename]
	thirddata.handlecsv.markemptylines()
	thirddata.handlecsv.gTableEmptyRows[csvfilename]={}
	thirddata.handlecsv.gTableNotEmptyRows[csvfilename]={}
end


function thirddata.handlecsv.hooksevaluation()
	for i=1,#thirddata.handlecsv.gColumnNames[thirddata.handlecsv.getcurrentcsvfilename()] do
	 if not thirddata.handlecsv.texmacroisdefined('bch'..thirddata.handlecsv.gColumnNames[thirddata.handlecsv.getcurrentcsvfilename()][i]) then
	  context.setgvalue('bch'..thirddata.handlecsv.gColumnNames[thirddata.handlecsv.getcurrentcsvfilename()][i],'\\relax')
	 end
	 if not thirddata.handlecsv.texmacroisdefined('ech'..thirddata.handlecsv.gColumnNames[thirddata.handlecsv.getcurrentcsvfilename()][i]) then
	  context.setgvalue('ech'..thirddata.handlecsv.gColumnNames[thirddata.handlecsv.getcurrentcsvfilename()][i],'\\relax')
	 end
	end
end


function thirddata.handlecsv.setgetcurrentcsvfile(filename)
-- In the absence of the file name to use the global variable
	 thirddata.handlecsv.gCurrentlyProcessedCSVFile = (filename ~= nil) and filename or thirddata.handlecsv.gCurrentlyProcessedCSVFile
	 thirddata.handlecsv.gCurrentlyProcessedCSVFile = (thirddata.handlecsv.gCurrentlyProcessedCSVFile == nil) and filename or thirddata.handlecsv.gCurrentlyProcessedCSVFile
   local filename = filename ~= nil and filename or thirddata.handlecsv.gCurrentlyProcessedCSVFile
--   thirddata.handlecsv.gCurrentlyProcessedCSVFile = tostring(filename)
   return tostring(filename)
end

function thirddata.handlecsv.handlecsvfile(filename)
-- not used yet
local filename  =  tostring(filename)
  filename = string.gsub(filename, '"', '')
  filename = string.gsub(filename, "'", "")
if not (thirddata.handlecsv.isopenfile(filename)) then
 filename = (filename ~= nil) and filename or thirddata.handlecsv.gCurrentlyProcessedCSVFile
 filename = (thirddata.handlecsv.gCurrentlyProcessedCSVFile == nil) and filename or thirddata.handlecsv.gCurrentlyProcessedCSVFile
 filename = filename ~= nil and filename or thirddata.handlecsv.gCurrentlyProcessedCSVFile
 filename = filename ~= '' and filename or thirddata.handlecsv.gCurrentlyProcessedCSVFile
end
  return filename
end

function thirddata.handlecsv.getcurrentcsvfilename()
-- return current (actual) CSV file
   return tostring(thirddata.handlecsv.gCurrentlyProcessedCSVFile)
end


function thirddata.handlecsv.isopenfile(csvfilename)
-- testing of opening CSV files
  local retval=(thirddata.handlecsv.gOpenFiles[csvfilename] ~= nil)
   return retval
end

function thirddata.handlecsv.closecsvfile(csvfilename)
-- manual closing of CSV files
  thirddata.handlecsv.gOpenFiles[csvfilename] = nil
end


function thirddata.handlecsv.getnumberofopencsvfiles()
-- get the number of open files
local count = 0
for k, v in pairs(thirddata.handlecsv.gOpenFiles) do
     count = count + 1
end
  return count
end



function thirddata.handlecsv.setpointersofopeningcsvfile(inpcsvfile)
 thirddata.handlecsv.gCurrentLinePointer[inpcsvfile]=1
 thirddata.handlecsv.gNumLine[inpcsvfile]=1 -- set numline counter of file inpcsvfile
 thirddata.handlecsv.resetlinepointerof(inpcsvfile)	-- set pointer to begin table (first row)
 thirddata.handlecsv.setnumlineof(inpcsvfile,1)
 context([[\global\EOFfalse%]])
 context([[\global\notEOFtrue%]])
 thirddata.handlecsv.resetmarkemptylines()
end

function thirddata.handlecsv.opencsvfile(filetoscan)
-- Open CSV tabule, inicialize variables
	-- open the table and load it into the global variable thirddata.handlecsv.gTableRows[filetoscan]
	-- if the option thirddata.handlecsv.gCSVHeader==true is enabled, then into glob variable thirddata.handlecsv.gColumnNames[filetoscan]
	-- sets the column names from the title, if not then sets XLS notation, ie. cA, cB, cC, ...
	-- into global variables thirddata.handlecsv.gNumRows[filetoscan] and  thirddata.handlecsv.gNumCols[filetoscan] it saves the number of rows and columns of the table
	-- if the file header and the header line does not count the number of rows in the table
	-- Additionally, they can defined ConTeXt macros  \csvfilename, \numrows a \numcols

    local inpcsvfile=thirddata.handlecsv.setgetcurrentcsvfile(filetoscan) -- set filetoscan as current processed csv file

	if thirddata.handlecsv.isopenfile(inpcsvfile) then -- if file is open, then set needed pointers at first line of file only
	   thirddata.handlecsv.setpointersofopeningcsvfile(inpcsvfile)
	else -- if CSV file is not open, then open it and set all needed variables

		local inpcsvfile=thirddata.handlecsv.setgetcurrentcsvfile(inpcsvfile)
		thirddata.handlecsv.gOpenFiles[inpcsvfile]=inpcsvfile -- memory opening file
		thirddata.handlecsv.gColNames[inpcsvfile]={}
		thirddata.handlecsv.gColumnNames[inpcsvfile]={}
		thirddata.handlecsv.gTableRowsIndex[inpcsvfile]={}
		thirddata.handlecsv.gTableRows[inpcsvfile]={}
 		thirddata.handlecsv.gTableEmptyRows[inpcsvfile]={}
 		thirddata.handlecsv.gTableNotEmptyRows[inpcsvfile]={}


		local currentlyprocessedcsvfile = io.loaddata(inpcsvfile)
		local mycsvsplitter = utilities.parsers.rfc4180splitter{
			separator = thirddata.handlecsv.gCSVSeparator,
			quote = thirddata.handlecsv.gCSVQuoter,
			strict = true,
			}
		if thirddata.handlecsv.gCSVHeader then
		  thirddata.handlecsv.gTableRows[inpcsvfile], thirddata.handlecsv.gColumnNames[inpcsvfile] = mycsvsplitter(currentlyprocessedcsvfile,true)
		  inspect(thirddata.handlecsv.gTableRows[inpcsvfile])
		  inspect(thirddata.handlecsv.gColumnNames[inpcsvfile])
		else -- if thirddata.handlecsv.gCSVHeader
		  thirddata.handlecsv.gTableRows[inpcsvfile], thirddata.handlecsv.gColumnNames[inpcsvfile] = mycsvsplitter(currentlyprocessedcsvfile)
		  inspect(thirddata.handlecsv.gTableRows[inpcsvfile])
		  thirddata.handlecsv.gColumnNames[inpcsvfile]={}
		  -- ad now set column names for withoutheader situation:
			for i=1,#thirddata.handlecsv.gTableRows[inpcsvfile][1] do
			 -- OK, but not used: thirddata.handlecsv.gColumnNames[inpcsvfile][i]=thirddata.handlecsv.tmn(thirddata.handlecsv.gTableRows[inpcsvfile][1][i])
			 thirddata.handlecsv.gColumnNames[inpcsvfile][i]=tostring(thirddata.handlecsv.ar2xls(i)) -- set XLS notation (fill array with XLS names of columns like 'cA', 'cB', etc.)
			end -- for
		end -- if thirddata.handlecsv.gCSVHeader
			for i=1,#thirddata.handlecsv.gTableRows[inpcsvfile][1] do
			    thirddata.handlecsv.gColNames[inpcsvfile][tostring(thirddata.handlecsv.tmn(thirddata.handlecsv.gColumnNames[inpcsvfile][i]))] = i -- for indexing use (register names of macros ie 'Firstname' etc...)
				thirddata.handlecsv.gColNames[inpcsvfile][tostring(thirddata.handlecsv.gColumnNames[inpcsvfile][i])] = i -- for indexing use (register names of macros ie 'Firstname' etc...)
				thirddata.handlecsv.gColNames[inpcsvfile][tostring(thirddata.handlecsv.ar2xls(i))] = i -- for indexcolname macro (register names of macros ie 'A', 'B', etc...)
				thirddata.handlecsv.gColNames[inpcsvfile][tostring('c'..thirddata.handlecsv.ar2xls(i))] = i -- for indexcolname macro (register names of macros ie 'cA', 'cB', etc...)
				thirddata.handlecsv.gColNames[inpcsvfile][tostring(i)] = i -- for indexcolname macro (register names of macros ie 'cA', 'cB', etc...)
				thirddata.handlecsv.gColNames[inpcsvfile][i] = i -- for indexcolname macro (register names of macros ie 'cA', 'cB', etc...)
			end -- for
			local j=#thirddata.handlecsv.gTableRows[inpcsvfile][1]
			for i=1,#thirddata.handlecsv.gTableRows[inpcsvfile][1] do
			j=j+1
			thirddata.handlecsv.gColumnNames[inpcsvfile][j]=tostring('c'..thirddata.handlecsv.ar2xls(i)) -- set XLS notation (fill array with XLS names of columns like 'cA', 'cB', etc.)
			end -- for
			if thirddata.handlecsv.gCSVHeader then
				for i=1,#thirddata.handlecsv.gTableRows[inpcsvfile][1] do
				j=j+1
				thirddata.handlecsv.gColumnNames[inpcsvfile][j]=tostring(thirddata.handlecsv.ar2xls(i)) -- set XLS notation (fill array with XLS names of columns like 'cA', 'cB', etc.)
				end -- for
				for i=1,#thirddata.handlecsv.gTableRows[inpcsvfile][1] do
				j=j+1
				thirddata.handlecsv.gColumnNames[inpcsvfile][j]=tostring(thirddata.handlecsv.tmn(thirddata.handlecsv.gColumnNames[inpcsvfile][i])) -- maybe TeX incorect names of columns
				end -- for
			end -- if thirddata.handlecsv.gCSVHeader then

		thirddata.handlecsv.gNumRows[inpcsvfile]=#thirddata.handlecsv.gTableRows[inpcsvfile] -- Getting number of rows
		thirddata.handlecsv.gNumCols[inpcsvfile]=#thirddata.handlecsv.gTableRows[inpcsvfile][1] -- Getting number of columns
		thirddata.handlecsv.gNumEmptyRows[inpcsvfile]=0
		thirddata.handlecsv.gNumNotEmptyRows[inpcsvfile]=#thirddata.handlecsv.gTableRows[inpcsvfile]
		thirddata.handlecsv.setpointersofopeningcsvfile(inpcsvfile) 		-- set pointers

		if thirddata.handlecsv.gUseHooks then  thirddata.handlecsv.hooksevaluation() end

	end -- if thirddata.handlecsv.isopenfile(inpcsvfile) then
return
end -- of thirddata.handlecsv.opencsvfile(file)


function thirddata.handlecsv.readlineof(inpcsvfile,numberofline) --
-- Main function. Read data from specific line of specific file, parse them etc.
    local inpcsvfile=thirddata.handlecsv.handlecsvfile(inpcsvfile)
	local numberofline=numberofline
	local returnpar=false
	 if type(numberofline)~= 'number' then
	 	if numberofline==nil then
	 	 numberofline=thirddata.handlecsv.gCurrentLinePointer[inpcsvfile]
	 	 returnpar=true
	 	else numberofline = 0
		end -- if numberofline==nil
	 end --  if type(numberofline)
	 if (numberofline > 0 and numberofline <=thirddata.handlecsv.gNumRows[inpcsvfile]) then
	 	 thirddata.handlecsv.addtonumlineof(inpcsvfile,1)
	  	 thirddata.handlecsv.gCurrentLinePointer[inpcsvfile]=numberofline
		 returnpar=true
		 thirddata.handlecsv.assigncontentsof(inpcsvfile,thirddata.handlecsv.gTableRows[inpcsvfile][numberofline])
		 context([[\global\EOFfalse\global\notEOFtrue%]])
	 else
		 thirddata.handlecsv.assigncontentsof(inpcsvfile,'nil_line')
			if numberofline > thirddata.handlecsv.gNumRows[inpcsvfile] then
			   context([[\global\EOFtrue\global\notEOFfalse%]])
	   	end
	 end  -- if (numberofline > 0
--řešit	 	thirddata.handlecsv.emptylineevaluation(numberofline)
 return returnpar -- return true if numberofline is regular line, else return false
end -- function thirddata.handlecsv.readlineof(inpcsvfile,numberofline) --


function thirddata.handlecsv.readline(numberofline) --
-- Main function. Read data from specific line of specific file, parse them etc.
 local csvfile=thirddata.handlecsv.getcurrentcsvfilename()
  if type(numberofline) == 'number' then
	thirddata.handlecsv.readlineof(csvfile,numberofline) --
  else
   thirddata.handlecsv.readlineof(csvfile,thirddata.handlecsv.gCurrentLinePointer[csvfile]) --
  end
end


function thirddata.handlecsv.createxlscommandof(xlsname,csvfile)
local inpcsvfile=thirddata.handlecsv.handlecsvfile(csvfile)
local cxlsname=tostring('col'..xlsname)
local docxlsname=tostring('docol'..xlsname)
local xlsname=tostring(''..xlsname)

-- context([[\def\definice]]..xlsname..[[#1{\ctxlua{context(thirddata.handlecsv.getcellcontentof(']]..inpcsvfile..[[',']]..xlsname..[[','#1'))}}]])

		interfaces.definecommand (docxlsname, {
		    arguments = { { "option", "string" }  },
		    macro = function (opt_1)
		       if #opt_1>0 then
				context(thirddata.handlecsv.getcellcontentof(inpcsvfile,xlsname,tonumber(opt_1)))
				else
				context(thirddata.handlecsv.getcellcontentof(inpcsvfile,xlsname,thirddata.handlecsv.gCurrentLinePointer[inpcsvfile]))
				end
		    end
			})
		interfaces.definecommand(cxlsname, {
		    macro = function ()
		      context.dosingleempty()
		      context[docxlsname]()
		    end
			})
--		interfaces.definecommand ("column"..xlsname, {
--		    arguments = { { "option"}  },
--		    macro = function (opt_1)
--		    if opt_1~="" then
--			context(thirddata.handlecsv.getcellcontentof(inpcsvfile,xlsname,tonumber(opt_1)))
--			else
--			context(thirddata.handlecsv.getcellcontentof(inpcsvfile,xlsname,thirddata.handlecsv.gCurrentLinePointer[inpcsvfile]))
--			end
--		    end
--			})
end


function thirddata.handlecsv.createxlscommand(xlsname)
local inpcsvfile=thirddata.handlecsv.getcurrentcsvfilename()
thirddata.handlecsv.createxlscommandof(xlsname,inpcsvfile)
end


function thirddata.handlecsv.assigncontentsof(inpcsvfile,line) -- put data into columns macros
-- after read of line this function put content of columns into specific TeX macros...
--if tex.modes['XXL'] then context("XXL mode") else context("not XXL mode") end
	local inpcsvfile=thirddata.handlecsv.handlecsvfile(inpcsvfile)
	local cutoffinpcsvfile=thirddata.handlecsv.ParseCSVLine(inpcsvfile,".")[1] -- cut filename extension
 	for i=1,thirddata.handlecsv.gNumCols[inpcsvfile] do
 		content='nil' -- 1.10.2015
 		if line ~= 'nil_line' then content = line[i] end
		local puremacroname=thirddata.handlecsv.gColumnNames[inpcsvfile][i]
--		local macroname=cutoffinpcsvfile..thirddata.handlecsv.gColumnNames[inpcsvfile][i]
		local macroname=thirddata.handlecsv.gColumnNames[inpcsvfile][i]
--		context("macroname: "..macroname.."\\crlf")
		local purexlsname=thirddata.handlecsv.ar2colnum(i)
--		context("purexlsname: "..purexlsname.."\\crlf")
		local xlsname='c'..purexlsname
--		context("xlsname: "..xlsname.."\\crlf")
		local xlsfilename=thirddata.handlecsv.tmn(cutoffinpcsvfile)..'c'..purexlsname
--		context("xlsfilename: "..xlsfilename.."\\crlf")
		local hookxlsname='h'..xlsname
		local macroname=thirddata.handlecsv.tmn(macroname)
		local puremacroname=thirddata.handlecsv.tmn(puremacroname)
--		context("macroname: "..macroname.."\\crlf")
		local hookmacroname='h'..macroname
--		if content == ' ' then tex.print('space') end
--		if content == '' then tex.print('empty') content=[[\empty]] end
 	   context.setgvalue(xlsname, content) -- defining automatic TeX macros  \cA, \cB, atd. resp. \cI, \cII, ...  containing the contents of the line. Macros with names of the headers are updated automatically
 	   context.setgvalue(xlsfilename, content) -- defining automatic TeX macros  \filenamecA, \filenamecB, atd. resp. \cI, \cII, ...  containing the contents of the line. Macros with names of the headers are updated automatically
 	   -- was context.setgvalue(macroname,'\\'..xlsname) -- ie  for example \let\Name\cA
--		context.setgvalue(macroname,content) -- defining automatic TeX macros  \Name, \Date, etc. (names gets from header), containing the contents of the line. Macros with names of the headers are updated automatically
		context.setgvalue(puremacroname,content) -- defining automatic TeX macros  \Name, \Date, etc. (names gets from header), containing the contents of the line. Macros with names of the headers are updated automatically
	-- experimental version in next two lines:
	-- this define variants of macros \colA, \colA[8], ... and \colFirstname, \colFirstname[11] etc.
		thirddata.handlecsv.createxlscommandof(''..purexlsname,inpcsvfile) -- create macros \colA, \colB, etc. and their variants \colA[row], ...
--if tex.modes['XXX'] then
--context("XXX-"..macroname.."-XXX")
--end
		context.setgvalue('col'..macroname,'\\col'..purexlsname) -- and create fullname macros \colFirstname, \colFirstname[5], etc...
--		context.setgvalue(''..macroname,'\\col'..purexlsname) -- and create fullname macros \colFirstname, \colFirstname[5], etc...
--		context.setgvalue(''..macroname,'\\col'..purexlsname) -- and create fullname macros \colFirstname, \colFirstname[5], etc...
		--
			interfaces.definecommand ("column"..purexlsname, {
		    arguments = { { "string"}  },
		    macro = function (opt_1)
		    if opt_1~="" then
			context(thirddata.handlecsv.getcellcontentof(inpcsvfile,xlsname,tonumber(opt_1)))
			else
			context(thirddata.handlecsv.getcellcontentof(inpcsvfile,xlsname,thirddata.handlecsv.gCurrentLinePointer[inpcsvfile]))
			end
		    end
			})
		--
		-- and now create hooks macros:
	  	if thirddata.handlecsv.gUseHooks then
	  	 	 context.setgvalue(hookxlsname,'\\bch\\bch'..xlsname..'\\'..xlsname..'\\ech'..xlsname..'\\ech') -- defining automatic TeX macros \hcA, \hcB, atd. resp. \hcI, \hcII, ...  containing 'hooked' contents of the line. Macros with names of the headers are updated automatically)
	       context.setgvalue(hookmacroname,'\\bch\\bch'..macroname..'\\'..xlsname..'\\ech'..macroname..'\\ech ') -- defining automatic TeX macros \hName, \hDate, etc. (names gets from header), containing 'hooked' contents of the line. Macros with names of the headers are updated automatically)
	  	end
	end -- for i=1,
end -- function thirddata.handlecsv.assigncontentsof(inpcsvfile,line) -- put data into columns macros


function thirddata.handlecsv.assigncontents(line) -- put data into columns macros
thirddata.handlecsv.assigncontentsof(thirddata.handlecsv.getcurrentcsvfilename(),line)
end


function thirddata.handlecsv.getcellcontentof(csvfile,column,row)
-- Read data from specific cell of specific the csv table
	-- local returnparametr='nil'  -- 1.10.2015
	local csvfile=thirddata.handlecsv.handlecsvfile(csvfile)
	local returnparametr=''  -- 9.1.2016
	local column=column
	local row=row
	if type(column)=='string' then
		local testcolumn=thirddata.handlecsv.gColNames[csvfile][column]
		if testcolumn==nil then
		  column=thirddata.handlecsv.xls2ar(column)
		else
		   column=testcolumn
		end
	else
		testcolumn=tonumber(column)
		if testcolumn==nil then
		  column=0
		else
		   column=testcolumn
		end
	end
	if column<=0 then column=1 end
	if column>thirddata.handlecsv.gNumCols[csvfile] then column=thirddata.handlecsv.gNumCols[csvfile] end
	if type(row)=='string' then
		local testrow=tonumber(row)
		if testrow==nil then
		  row=0
		else
		   row=testrow
		end
	end
	if type(column)=='number' and type(row)=='number' then
		if row>0 and row <=thirddata.handlecsv.gNumRows[csvfile] and column>=0 and column<=thirddata.handlecsv.gNumCols[csvfile] then
	 		returnparametr=thirddata.handlecsv.gTableRows[csvfile][row][column]
		elseif row==0 then
	 		returnparametr=thirddata.handlecsv.gColumnNames[csvfile][column]
	 	end
	end
 return returnparametr
end


function thirddata.handlecsv.getcellcontent(column,row)
-- Read data from specific cell of current open csv table
 local csvfile=thirddata.handlecsv.getcurrentcsvfilename()
 local returnparametr=thirddata.handlecsv.getcellcontentof(csvfile,column,row)
 return returnparametr
end


function thirddata.handlecsv.nextlineof(csvfile)
-- Move line pointer to next line.
  local csvfile=thirddata.handlecsv.handlecsvfile(csvfile)
  if thirddata.handlecsv.gCurrentLinePointer[csvfile] > thirddata.handlecsv.gNumRows[csvfile] then
  	 thirddata.handlecsv.gCurrentLinePointer[csvfile]=thirddata.handlecsv.gNumRows[csvfile]
     context([[\global\EOFtrue%]])
     context([[\global\notEOFfalse%]])
  else
    thirddata.handlecsv.gCurrentLinePointer[csvfile]=thirddata.handlecsv.gCurrentLinePointer[csvfile]+1
     context([[\global\EOFfalse%]])
     context([[\global\notEOFtrue%]])
  end
end


function thirddata.handlecsv.nextline()
-- Move line pointer to next line.
 local csvfile=thirddata.handlecsv.getcurrentcsvfilename()
 thirddata.handlecsv.nextlineof(csvfile)
end


function thirddata.handlecsv.previouslineof(csvfile)
-- Move line pointer to previous line.
  local csvfile=thirddata.handlecsv.handlecsvfile(csvfile)
  if thirddata.handlecsv.gCurrentLinePointer[csvfile] < 2 then
  	 thirddata.handlecsv.gCurrentLinePointer[csvfile] = 1
  else
    thirddata.handlecsv.gCurrentLinePointer[csvfile]=thirddata.handlecsv.gCurrentLinePointer[csvfile] - 1
  end
     context([[\global\EOFfalse%]])
     context([[\global\notEOFtrue%]])
end


function thirddata.handlecsv.previousline()
-- Move line pointer to previous line.
 local csvfile=thirddata.handlecsv.getcurrentcsvfilename()
 thirddata.handlecsv.previouslineof(csvfile)
end


function thirddata.handlecsv.setlinepointerof(csvfile,numberofline)
  local csvfile=thirddata.handlecsv.handlecsvfile(csvfile)
  local numberofline = thirddata.handlecsv.processinputvalue(numberofline,thirddata.handlecsv.gCurrentLinePointer[csvfile])
   	if numberofline < 1 then numberofline = 1 end
   	if numberofline > thirddata.handlecsv.gNumRows[csvfile] then
  	 numberofline=thirddata.handlecsv.gNumRows[csvfile]
	end
  thirddata.handlecsv.gCurrentLinePointer[csvfile]=numberofline
  thirddata.handlecsv.readlineof(csvfile,numberofline)
end


function thirddata.handlecsv.setlinepointer(numberofline)
 local csvfile=thirddata.handlecsv.getcurrentcsvfilename()
 thirddata.handlecsv.setlinepointerof(csvfile,numberofline)
end


function thirddata.handlecsv.savelinepointer()
  local csvfile=thirddata.handlecsv.getcurrentcsvfilename()
  thirddata.handlecsv.gSavedLinePointerNo = thirddata.handlecsv.gCurrentLinePointer[csvfile]
end


function thirddata.handlecsv.setsavedlinepointer()
  thirddata.handlecsv.setlinepointer(thirddata.handlecsv.gSavedLinePointerNo)
end


function thirddata.handlecsv.resetlinepointerof(csvfile)
-- Take pointer to first row of table
 local csvfile=thirddata.handlecsv.handlecsvfile(csvfile)
  thirddata.handlecsv.setlinepointerof(csvfile,1)
end


function thirddata.handlecsv.resetlinepointer()
-- Take pointer to first row of table
 local csvfile=thirddata.handlecsv.getcurrentcsvfilename()
  thirddata.handlecsv.setlinepointerof(csvfile,1)
end


function thirddata.handlecsv.linepointerof(csvfile)
 local csvfile=thirddata.handlecsv.handlecsvfile(csvfile)
  return thirddata.handlecsv.gCurrentLinePointer[csvfile]
end


function thirddata.handlecsv.linepointer()
 local csvfile=thirddata.handlecsv.getcurrentcsvfilename()
 -- return thirddata.handlecsv.gCurrentLinePointer[csvfile] -- cause problem with decimal point for higher versions of Lua
 -- return math.tointeger(thirddata.handlecsv.gCurrentLinePointer[csvfile]) -- cause incompatibility for lower version of Lua
 return math.floor(tonumber(thirddata.handlecsv.gCurrentLinePointer[csvfile])) -- compatible with lower and higher versions of Lua
end


function thirddata.handlecsv.getcurrentlinepointer() -- for compatibility
  return thirddata.handlecsv.linepointer()
end


function thirddata.handlecsv.getlinepointer() -- for compatibility
  return thirddata.handlecsv.linepointer()
end


function thirddata.handlecsv.setnumlineof(csvfile,numline)
 local csvfile=thirddata.handlecsv.handlecsvfile(csvfile)
thirddata.handlecsv.gNumLine[csvfile]=numline
end


function thirddata.handlecsv.setnumline(numline)
 local csvfile=thirddata.handlecsv.getcurrentcsvfilename()
thirddata.handlecsv.setnumlineof(csvfile,numline)
end


function thirddata.handlecsv.resetnumlineof(csvfile)
local csvfile=thirddata.handlecsv.handlecsvfile(csvfile)
  thirddata.handlecsv.setnumlineof(csvfile,0)
end

function thirddata.handlecsv.resetnumline()
local csvfile=thirddata.handlecsv.getcurrentcsvfilename()
  thirddata.handlecsv.resetnumlineof(csvfile)
end

function thirddata.handlecsv.addtonumlineof(inpcsvfile,numline)
 local inpcsvfile=thirddata.handlecsv.handlecsvfile(inpcsvfile)
  thirddata.handlecsv.gNumLine[inpcsvfile]=thirddata.handlecsv.gNumLine[inpcsvfile]+numline
end


function thirddata.handlecsv.addtonumline(numline)
 local inpcsvfile=thirddata.handlecsv.getcurrentcsvfilename()
 thirddata.handlecsv.addtonumlineof(inpcsvfile,numline)
end

function thirddata.handlecsv.numlineof(csvfile)
local csvfile=thirddata.handlecsv.handlecsvfile(csvfile)
 return thirddata.handlecsv.gNumLine[csvfile]
end

function thirddata.handlecsv.numline()
local csvfile=thirddata.handlecsv.getcurrentcsvfilename()
 return thirddata.handlecsv.gNumLine[csvfile]
end


function thirddata.handlecsv.nextnumlineof(csvfile)
-- Move numline pointer to next number.
local csvfile=thirddata.handlecsv.handlecsvfile(csvfile)
  thirddata.handlecsv.gNumLine[csvfile]=thirddata.handlecsv.gNumLine[csvfile]+1
end


function thirddata.handlecsv.nextnumline()
-- Move numline pointer to next number.
local csvfile=thirddata.handlecsv.getcurrentcsvfilename()
  thirddata.handlecsv.gNumLine[csvfile]=thirddata.handlecsv.gNumLine[csvfile]+1
end


function thirddata.handlecsv.numrowsof(csvfile)
local csvfile=thirddata.handlecsv.handlecsvfile(csvfile)
--  context(thirddata.handlecsv.gNumRows[csvfile])
  return thirddata.handlecsv.gNumRows[csvfile]
end

function thirddata.handlecsv.numrows()
local csvfile=thirddata.handlecsv.getcurrentcsvfilename()
--  context(thirddata.handlecsv.gNumRows[csvfile])
   return thirddata.handlecsv.gNumRows[csvfile]
end


function thirddata.handlecsv.numemptyrows()
 return thirddata.handlecsv.gNumEmptyRows[thirddata.handlecsv.getcurrentcsvfilename()]
end


function thirddata.handlecsv.numnotemptyrows()
return thirddata.handlecsv.gNumRows[thirddata.handlecsv.getcurrentcsvfilename()]-thirddata.handlecsv.gNumEmptyRows[thirddata.handlecsv.getcurrentcsvfilename()]
end


function thirddata.handlecsv.numcolsof(csvfile)
local csvfile=thirddata.handlecsv.handlecsvfile(csvfile)
  context(thirddata.handlecsv.gNumCols[csvfile])
end

function thirddata.handlecsv.numcols()
local csvfile=thirddata.handlecsv.getcurrentcsvfilename()
  context(thirddata.handlecsv.gNumCols[csvfile])
-- thirddata.handlecsv.numcolsof(csvfile)
end


function thirddata.handlecsv.resethooks()
-- initialize ConTeXt hooks
 context([[%
 	\letvalue{blinehook}=\relax%
   \letvalue{elinehook}=\relax%
   \letvalue{bfilehook}=\relax%
   \letvalue{efilehook}=\relax%
   \letvalue{bch}=\relax%
   \letvalue{ech}=\relax%
	]])
end


function thirddata.handlecsv.string2context(str2ctx)
-- for safety writen
  local s=str2ctx
  s=string.gsub(s, "%%(.-)\n", "\n")  -- remove TeX comments from string. From % character to the end of line
  -- s=string.gsub(s, '\n', "")
  context(s)
  -- texsprint(s) -- for debugging ...
end


function thirddata.handlecsv.doloopfromto(from, to, action)
 context[[\opencsvfile]]
 context[[\edef\tempnumline{\numline}]] -- 23.6.2017
 context[[\resetnumline]] -- uncommented 23.6.2017
 if thirddata.handlecsv.gUseHooks then context[[\bfilehook]] end
 context[[\removeunwantedspaces]]
 local csvfile=thirddata.handlecsv.getcurrentcsvfilename()
 local gnumrows=thirddata.handlecsv.gNumRows[csvfile]+0
 local from=from+0
 local to=to+0
 local step=1
 local docycle=true
 if (from>gnumrows and to>gnumrows) then docycle=false end
 if docycle then
  if from>to then
  		step=-1
 		if from>gnumrows then from=gnumrows end
		if to<0 then to=0 end
  else -- if from<=to
 		if to>gnumrows then to=gnumrows end
 		if from<0 then from=1 end
  end
  for i=from, to, step do
  if thirddata.handlecsv.gUseHooks then context[[\blinehook]] end
   context([[\readline{]]..i..[[}]]) --
   context(action)
  if thirddata.handlecsv.gUseHooks then context[[\elinehook]] end
  end
 end -- docycle
-- context[[\removeunwantedspaces]]
if thirddata.handlecsv.gUseHooks then context[[\efilehook]] end
context[[\setnumline{\tempnumline}]]  -- 23.6.2017
end -- function thirddata.handlecsv.doloopfromto


function thirddata.handlecsv.doloopfornext(numberofrows, action)
 if thirddata.handlecsv.gUseHooks then context[[\bfilehook]] end
 context[[\removeunwantedspaces]]
 local csvfile=thirddata.handlecsv.getcurrentcsvfilename()
 local gnumrows=thirddata.handlecsv.gNumRows[csvfile]+0
 local from=thirddata.handlecsv.gCurrentLinePointer[csvfile]+0
 local to=thirddata.handlecsv.gCurrentLinePointer[csvfile]+numberofrows
 local step=1
 local docycle=true
  if from>to then
  		step=-1
 		if from>gnumrows then from=gnumrows end
		if to<0 then to=0 end
  else -- if from<=to
 		if to>gnumrows then to=gnumrows end
 		if from<0 then from=1 end
  end
  for i=from, to-step, step do
   if thirddata.handlecsv.gUseHooks then context[[\blinehook]] end
   context([[\readline{]]..i..[[}]]) -- context(thirddata.handlecsv.readline(i))
   context(action)
   if thirddata.handlecsv.gUseHooks then context[[\elinehook]] end
  end
  thirddata.handlecsv.addtonumline(-1)
context[[\removeunwantedspaces]]
if thirddata.handlecsv.gUseHooks then context[[\efilehook]] end
context[[\nextrow]]
end -- function thirddata.handlecsv.doloopfornext



-- ConTeXt source:
local string2print=[[%
% library newifs for testing during processing CSV table
\newif\ifissetheader%
\newif\ifnotsetheader%
\newif\ifEOF%
\newif\ifnotEOF%
\newif\ifemptyline%
\newif\ifnotemptyline%
\newif\ifemptylinesmarking% setting by macros \markemptylines and \notmarkemptylines
\newif\ifemptylinesnotmarking% setting by \markemptylines and \notmarkemptylines


% Macros defining above in source text:
\let\lineaction\empty% set user define macro into default value
\def\resethooks{\ctxlua{context(thirddata.handlecsv.resethooks())}}
\resethooks % -- DO IT NOW !!!
\def\hookson{\ctxlua{thirddata.handlecsv.hookson()}}
\let\usehooks\hookson % -- synonym only
\def\hooksoff{\ctxlua{thirddata.handlecsv.hooksoff()}}
\def\setheader{\ctxlua{thirddata.handlecsv.setheader()}}
\def\unsetheader{\ctxlua{thirddata.handlecsv.unsetheader()}}
\let\resetheader\unsetheader % -- for compatibility
\def\setsep#1{\ctxlua{thirddata.handlecsv.setsep('#1')}}
\def\unsetsep{\ctxlua{thirddata.handlecsv.unsetsep()}}
\let\resetsep\unsetsep % -- for compatibility
\def\setfiletoscan#1{\ctxlua{thirddata.handlecsv.setfiletoscan('#1');thirddata.handlecsv.opencsvfile()}}
\def\setcurrentcsvfile[#1]{\ctxlua{thirddata.handlecsv.setgetcurrentcsvfile('#1')}}


\def\numrows{\ctxlua{context(thirddata.handlecsv.numrows())}}
\def\numrowsof[#1]{\ctxlua{context(thirddata.handlecsv.numrowsof('#1'))}}
\def\numcols{\ctxlua{context(thirddata.handlecsv.gNumCols[thirddata.handlecsv.gCurrentlyProcessedCSVFile])}}
\def\numcolsof[#1]{\ctxlua{context(thirddata.handlecsv.gNumCols['#1'])}}
\def\currentcsvfile{\ctxlua{context(thirddata.handlecsv.getcurrentcsvfilename())}}
\let\csvfilename\currentcsvfile % for compatibility using


\def\numemptyrows{\ctxlua{context(thirddata.handlecsv.numemptyrows())}}
\def\numnotemptyrows{\ctxlua{context(thirddata.handlecsv.numnotemptyrows())}}


% usefull tool macros :

% Pass the contents of the macro into parameter
\def\thenumexpr#1{\the\numexpr(#1+0)}
% Add content (#2) into content of macro #1
\long\def\addto#1#2{\expandafter\def\expandafter#1\expandafter{#1#2}}
% Expanded version of previous macro
\long\def\eaddto#1#2{\edef#1{#1#2}}



% Get content of specific cell of CSV table. Calling: \csvcell[column number,row number] OR \csvcell['ColumnName',row number]
\def\getcsvcell[#1,#2]{\ctxlua{context(thirddata.handlecsv.getcellcontent(#1,#2))}}%
%%%%%\def\getcsvcell[#1,#2]{\if!#2!\ctxlua{context(thirddata.handlecsv.getcellcontent(#1,thirddata.handlecsv.gCurrentLinePointer[thirddata.handlecsv.getcurrentcsvfilename()]))}\else\ctxlua{context(thirddata.handlecsv.getcellcontent(#1,#2))}\fi}%

% Get content of specific cell of CSV table. Calling: \csvcell[column number,row number] OR \csvcell['ColumnName',row number]
\def\getcsvcellof[#1][#2,#3]{\ctxlua{context(thirddata.handlecsv.getcellcontentof("#1",#2,#3))}}%


% Get content of specific cell of CSV table. Calling: \csvcell[column number,row number or row number getting from macro] OR \csvcell['ColumnName',row number or row number getting from macro]
\def\csvcell[#1,#2]{\getcsvcell[#1,\the\numexpr(#2+0)]}%
%\def\csvcell\getcsvcell


% Get content of specific cell of current line of CSV table. Calling: \currentcell{column number} OR \currentcell{'ColumnName'}
\def\currentcsvcell#1{\getcsvcell[#1,\thenumexpr{\linepointer}]}%
\let\currcell\currentcsvcell

% Get content of specific cell of next line of CSV table. Calling: \nextcell{column number} OR \nextcell{'ColumnName'}
\def\nextcsvcell#1{\ifnum\linepointer<\numrows{\getcsvcell[#1,\thenumexpr{\linepointer+1}]}\fi}%
\let\nextcell\nextcsvcell

% Get content of specific cell of previous line of CSV table. Calling: \previouscell{column number} OR \previouscell{'ColumnName'}
\def\previouscsvcell#1{\ifnum\linepointer>1{\getcsvcell[#1,\thenumexpr{\linepointer-1}]}\fi}%
\let\prevcell\previouscsvcell


% Get column name of n-th column of CSV table. When is set header, then get headername else get XLSname
\def\colnameof[#1][#2]{\ctxlua{context(thirddata.handlecsv.gColumnNames['#1'][#2])}}%
\def\colname[#1]{\ctxlua{context(thirddata.handlecsv.gColumnNames[thirddata.handlecsv.getcurrentcsvfilename()][#1])}}%

% Get index (ie serrial number) of strings columns names (own name or XLS name)
\def\indexcolnameof[#1][#2]{\ctxlua{context(thirddata.handlecsv.gColNames['#1'][#2])}}%
\def\indexcolname[#1]{\ctxlua{context(thirddata.handlecsv.gColNames[thirddata.handlecsv.getcurrentcsvfilename()][#1])}}%

% Get (alternative) XLS column name (of n-th column)
\def\xlscolname[#1]{\ctxlua{context(thirddata.handlecsv.ar2colnum(#1))}}%

% Get (alternative) XLS column name (of n-th column)
\def\cxlscolname[#1]{\ctxlua{context('c'..thirddata.handlecsv.ar2colnum(#1))}}%

% Get column TeX name of n-th column of CSV table. When is set header, then get headername else get XLSname
\def\texcolname[#1]{\ctxlua{context(thirddata.handlecsv.tmn(thirddata.handlecsv.gColumnNames[thirddata.handlecsv.getcurrentcsvfilename()][#1]))}}%


% Get content of n-th column of current row
\def\columncontent[#1]{%
\getcsvcell[#1,\ctxlua{context(thirddata.handlecsv.linepointer())}] %
%\getcsvcell[#1,\linepointer]%
%\getcsvcell[#1,\ctxlua{context(thirddata.handlecsv.linepointer())}]%
%\ctxlua{context(tostring(thirddata.handlecsv.getcellcontent(#1,8)))}
}%

% Substitution of text #2 in cell content by text #3. Substitution is done in the current column of column #1 (number, XLS name or cX name)
\def\replacecontentin#1#2#3{\ctxlua{context(thirddata.handlecsv.substitutecontentofcellofcurrentrow('#1','#2','#3'))}}%

% Get number from XLS column name (ie n-th column)
\def\numberxlscolname[#1]{\ctxlua{context(thirddata.handlecsv.xls2ar(#1))}}%
%%%\def\columncontent[#1]{\ctxlua{context(thirddata.handlecsv.getcellcontent(#1,thirddata.handlecsv.linepointer()))}}
%%%\def\columncontent[#1]{\ctxlua{context(thirddata.handlecsv.getcellcontent(thirddata.handlecsv.gColNames[#1],thirddata.handlecsv.linepointer()))}}
\def\columncontentof[#1][#2]{\ctxlua{context(thirddata.handlecsv.getcellcontentof('#1',thirddata.handlecsv.gColNames['#1'][#2],thirddata.handlecsv.linepointerof('#1')))}}
\def\columncontent[#1]{\ctxlua{context(thirddata.handlecsv.getcellcontent(thirddata.handlecsv.gColNames[thirddata.handlecsv.getcurrentcsvfilename()][#1],thirddata.handlecsv.linepointerof(thirddata.handlecsv.getcurrentcsvfilename())))}}
\def\resetlinepointer{\ctxlua{context(thirddata.handlecsv.resetlinepointer())}}
\def\resetlinepointerof[#1]{\ctxlua{context(thirddata.handlecsv.resetlinepointerof('#1'))}}
\let\resetlineno\resetlinepointer
\let\resetsernumline\resetlinepointer
\def\setnumline#1{\ctxlua{thirddata.handlecsv.setnumline(#1)}}
\def\resetnumline{\ctxlua{context(thirddata.handlecsv.resetnumline())}}
\resetnumline % DO IT NOW
\def\linepointer{\ctxlua{context(thirddata.handlecsv.linepointer())}}
\def\linepointerof[#1]{\ctxlua{context(thirddata.handlecsv.linepointerof('#1'))}}
\let\lineno\linepointer
\let\sernumline\linepointer
\def\numline{\ctxlua{context(thirddata.handlecsv.numline())}}
\def\addtonumline#1{\ctxlua{thirddata.handlecsv.addtonumline(#1)}}
%\def\setlinepointer#1{\ctxlua{thirddata.handlecsv.setlinepointer(#1);thirddata.handlecsv.readline(#1)}}
\def\setlinepointerof[#1]#2{\ctxlua{thirddata.handlecsv.setlinepointerof('#1',#2)}}
\def\setlinepointer#1{\ctxlua{thirddata.handlecsv.setlinepointer(#1)}}
\def\savelinepointer{\ctxlua{thirddata.handlecsv.savelinepointer()}}
\let\savelineno\savelinepointer % synonym
\def\setsavedlinepointer{\ctxlua{thirddata.handlecsv.setsavedlinepointer()}}
\let\setsavedlineno\setsavedlinepointer % synonym
\def\indexofnotemptyline#1{\ctxlua{context(thirddata.handlecsv.indexofnotemptyline(#1))}}
\def\indexofemptyline#1{\ctxlua{context(thirddata.handlecsv.indexofemptyline(#1))}}
\def\notmarkemptylines{\ctxlua{thirddata.handlecsv.notmarkemptylines()}}
\def\markemptylines{\ctxlua{thirddata.handlecsv.markemptylines()}}
\def\resetmarkemptylines{\ctxlua{thirddata.handlecsv.resetmarkemptylines()}}%
\def\removeemptylines{\ctxlua{thirddata.handlecsv.removeemptylines()}}%
\def\nextlineof[#1]{\ctxlua{thirddata.handlecsv.nextlineof('#1')}} % -- macro for skip to next line. \nextlineof no read data from current line unlike \nextrow macro.
\def\nextline{\ctxlua{thirddata.handlecsv.nextline()}} % -- macro for skip to next line. \nextline no read data from current line unlike \nextrow macro.
\def\prevlineof[#1]{\ctxlua{thirddata.handlecsv.previouslineof('#1')}} % -- macro for skip to previous line. \prevlineof no read data from current line unlike \prevrowof macro.
\def\prevline{\ctxlua{thirddata.handlecsv.previousline()}} % -- macro for skip to previous line. \prevline no read data from current line unlike \prevrow macro.
\def\nextnumline{\ctxlua{thirddata.handlecsv.nextnumline()}} % -- macro for add  numline counter.
%\def\nextrow{\readline\nextline} % -- For compatibility
\def\nextrow{\nextline\readline} % -- For compatibility (changed 2015-09-22)
\def\nextrowof[#1]{\nextlineof[#1]\readlineof[#1]{\ctxlua{context(thirddata.handlecsv.linepointerof('#1'))}}} % -- For compatibility (changed 2015-09-22)
%\def\nextrowof[#1]{\nextlineof[#1]\readlineof[#1]{\ctxlua{context(thirddata.handlecsv.gCurrentLinePointer['#1'])}}} % -- For compatibility (changed 2015-09-22)
\def\prevrow{\prevline\readline}
\def\prevrowof[#1]{\prevlineof[#1]\readlineof[#1]{\ctxlua{context(thirddata.handlecsv.linepointerof('#1'))}}}
\def\exitlooptest{\ifEOF\exitloop\else\nextrow\fi}




% MAIN CONTEXT MACRO DEFINITIONS

% Open CSV file. Syntax: \opencsvfile or \opencsvfile{filename}.
\def\opencsvfile{%
    \dosingleempty\doopencsvfile%
}%

\def\doopencsvfile[#1]{%
	\dosinglegroupempty\dodoopencsvfile%
}%

\def\dodoopencsvfile#1{%
    \iffirstargument%
    \ctxlua{thirddata.handlecsv.opencsvfile("#1")}%
     \doifnot{\env{MainLinePointer}}{}{\setlinepointer{\env{MainLinePointer}}}% added by Pablo
   \else%
	 \ctxlua{thirddata.handlecsv.opencsvfile()}%
   \fi%
}%


% manual closing of CSV file
\def\closecsvfile#1{\ctxlua{thirddata.handlecsv.closecsvfile("#1")}}

% Read data from n-th line of CSV table. Calling without parameter read current line (pointered by global variable)
\def\readline{\dosingleempty\doreadline}%

\def\doreadline[#1]{\dosinglegroupempty\dodoreadline}%

% They must remain in such a compact form, otherwise it returns unwanted gaps !!!!
\def\dodoreadline#1{\iffirstargument\ctxlua{thirddata.handlecsv.readline(#1)}\else\ctxlua{thirddata.handlecsv.readline(thirddata.handlecsv.gCurrentLinePointer[thirddata.handlecsv.gCurrentlyProcessedCSVFile])}\fi}%


\def\readlineof[#1]#2{\ctxlua{thirddata.handlecsv.readlineof('#1',#2)}}

%\def\readline{\ctxlua{thirddata.handlecsv.readline(thirddata.handlecsv.gCurrentLinePointer[thirddata.handlecsv.gCurrentlyProcessedCSVFile])}}%


\def\readandprocessparameters#1#2#3#4{%
	\edef\firstparam{#1}%
	\edef\secondparam{#2}%
 	\edef\thirdparam{#3}%
 	\def\fourthparam{#4}%
 	\edef\paroperator{#2}%
 %  operator '==' is for strings comparing converted to 'eq' operator; a blank space before the percent sign is strictly required!!!
   \ctxlua{if '#2'=="==" and not(type(tonumber('#1'))=='number' and type(tonumber('#3'))=='number') then context('\\def\\paroperator{eq}') end}%
 %  operator '~=' is for strings comparing converted to 'neq' operator; a blank space before the percent sign is strictly required !!!
   \ctxlua{if '#2'=="~=" and not(type(tonumber('#1'))=='number' and type(tonumber('#3'))=='number') then context('\\def\\paroperator{neq}') end}%
}%

% MACROS FOR CYCLES PROCESSING. DO ACTIONS IN CYCLES


% In this function to remove unwanted gaps
% 1. \doloopfromto{from}{to}{action}
% do action "action" from line "from" to line "to" of open CSV file
\def\doloopfromto#1#2#3{\ctxlua{thirddata.handlecsv.doloopfromto([==[\thenumexpr{#1}]==],[==[\thenumexpr{#2}]==],[==[\detokenize{#3}]==])}}%
%\def\doloopfromto#1#2#3{\ctxlua{thirddata.handlecsv.doloopfromto([==[\thenumexpr{#1}]==],[==[\thenumexpr{#2}]==],[==[\expanded{#3}]==])}}%

\def\Doloopfromto#1#2#3{% deprecated - old version - no longer recommended
   {\opencsvfile}%
   {\resetnumline}%
   \bfilehook%
   \removeunwantedspaces%
	\ifnum#1<#2\dostepwiserecurse{#1}{#2}{1}{\blinehook{\readline{\recurselevel}}#3\elinehook}%
   \else\dostepwiserecurse{#1}{#2}{-1}{\blinehook{\readline{\recurselevel}}#3\elinehook}%
	\fi%
	\removeunwantedspaces%
	\efilehook%
}%

% 2. \doloopforall  % implicit do \lineaction for all lines of open CSV table
% \doloopforall{\action}  % do \action macro for all lines of open CSV table
\def\doloopforall{\dosinglegroupempty\doloopforAll}%

\def\doloopforAll#1{%
  \doifsomethingelse{#1}{%1 args.
	\doloopfromto{1}{\numrows}{#1}%
	}{%
	\doloopfromto{1}{\numrows}{\lineaction}%
	}%
}%

% 3. \doloopaction % implicit use \lineaction macro
% \doloopaction{\action} % use \action macro for all lines of open CSV file
% \doloopaction{\action}{4} % use \action macro for first 4 lines
% \doloopaction{\action}{2}{5} % use \action macro for lines from 2 to 5
\def\doloopaction{\dotriplegroupempty\doloopAction}

\def\doloopAction#1#2#3{%
\opencsvfile%
% \resetnumline % commented 22.6.2017
\doifsomethingelse{#3}{%3 args.
	\doloopfromto{#2}{#3}{#1}% if 3 arguments then do #1 macro from #2 line to  #3 line
	}{%
	\doifsomethingelse{#2}{%2 args.
	\doloopfromto{1}{#2}{#1}% if 2 arguments then do #1 macro for first #2 lines
	}%
	{\doifsomethingelse{#1}{% 1 arg.
		\doloopfromto{1}{\numrows}{#1}%
		}{% if without arguments then do \lineaction macro for all lines
		\doloopfromto{1}{\numrows}{\lineaction}%
		}%
	}%
	}%
}%


% 4. \doloopif{value1}{[compare_operator]}{value2}{macro_for_doing} % [compareoperators] <, >, ==(eq), ~=(neq), >=, <=, in, ~in, until, while
% actions for rows of open CSV file which are responded of condition
\def\doloopif#1#2#3#4{%
	\edef\tempnumline{\numline}% 23.6.2017
    \readandprocessparameters{#1}{#2}{#3}{#4}%
    \removeunwantedspaces% 25.3.2019
    % \resetnumline % 22.6.2017
    \bfilehook%
    % and now process actual operator
    \processaction[\paroperator][%
     <=>{% {number1}{<}{number2} ... Less
     \doloopfromto{1}{\numrows}{\ctxlua{if #1<#3 then context('\\blinehook\\fourthparam\\elinehook') else thirddata.handlecsv.addtonumline(-1) end}}%
     },% end < ... Less
     >=>{% {number1}{>}{number2} ... Greater
     \doloopfromto{1}{\numrows}{\ctxlua{if #1>#3 then context('\\blinehook\\fourthparam\\elinehook') else thirddata.handlecsv.addtonumline(-1) end}}%
     },% end > ... Greater
     ===>{% {number1}{==}{number2} ... Equal
     \doloopfromto{1}{\numrows}{\ctxlua{if #1==#3 then context('\\blinehook\\fourthparam\\elinehook') else thirddata.handlecsv.addtonumline(-1) end}}%
     },% end == ... Equal
     ~==>{% {number1}{~=}{number2} ... Not Equal
     \doloopfromto{1}{\numrows}{\ctxlua{if #1~=#3 then context('\\blinehook\\fourthparam\\elinehook') else thirddata.handlecsv.addtonumline(-1) end}}%
     },% end ~= ... Not Equal
     >==>{% {number1}{>=}{number2} ... GreaterOrEqual
     \doloopfromto{1}{\numrows}{\ctxlua{if #1>=#3 then context('\\blinehook\\fourthparam\\elinehook') else thirddata.handlecsv.addtonumline(-1) end}}%
     },% end >=  ... GreaterOrEqual
     <==>{% {number1}{<=}{number2} ... LessOrEqual
     \doloopfromto{1}{\numrows}{\ctxlua{if #1<=#3 then context('\\blinehook\\fourthparam\\elinehook') else thirddata.handlecsv.addtonumline(-1) end}}%
     },% end <= ... LessOrEqual
     eq=>{%  command {string1}{==}{string2} is converted to command command {string1}{eq}{string2} ... string1 is equal string2
	 \doloopfromto{1}{\numrows}{\doifelse{#1}{#3}{\blinehook\fourthparam\elinehook}{\addtonumline{-1}}}% 23.06.2017
	 %%%%%\doloopfromto{1}{\numrows}{\ctxlua{if '#1'=='#3' then context('\\blinehook\\fourthparam\\elinehook') else thirddata.handlecsv.addtonumline(-1) end}}%
     },%  end eq
     neq=>{%  command {string1}{~=}{string2} is converted to command command {string1}{neq}{string2} ... string1 is not equal string2
	 \doloopfromto{1}{\numrows}{\doifelse{#1}{#3}{\ctxlua{thirddata.handlecsv.addtonumline(-1)}}{\blinehook\fourthparam\elinehook}}% 23.06.2017
     %%%%%\doloopfromto{1}{\numrows}{\ctxlua{if '#1'~='#3' then context('\\blinehook\\fourthparam\\elinehook') else thirddata.handlecsv.addtonumline(-1) end}}%
     },% end neq
     in=>{% {substring}{in}{string} ... substring is contained inside string
     \doloopfromto{1}{\numrows}{\doifinstringelse{#1}{#3}{\blinehook\fourthparam\elinehook}{\addtonumline{-1}}}% \doifincsnameelse
     },% end in
     ~in=>{% {substring}{~in}{string} ... substring is not contained inside string
     \doloopfromto{1}{\numrows}{\doifinstringelse{#1}{#3}{\addtonumline{-1}}{\blinehook\fourthparam\elinehook}}% \doifincsnameelse
     },% end notin
     repeatuntil=>{% {substring}{until}{string} ... % Repeats the action until the condition is met. If it is not never met, will list all record
	 \doloop{\ctxlua{if '#1'=='#3' then context('\\exitloop') else context('\\ifEOF\\exitloop\\else\\blinehook\\fourthparam\\elinehook\\nextrow\\fi') end}}%
     },% end until % the comma , is very important here!!!
     whiledo=>{% {substring}{untilneq}{string} ... % Repeat action when the condition is met. When the condition is not met for the first line, the action will NOT BE performed!
	 \doloop{\ctxlua{if '#1'~='#3' then context('\\exitloop') else context('\\removeunwantedspaces\\blinehook\\fourthparam\\elinehook\\ifEOF\\exitloop\\else\\nextrow\\fi') end}}%
     },% end untilneq % the comma , is very important here!!!
    ]% end of \processaction%
  \efilehook%
  \setnumline{\tempnumline}%
  \removeunwantedspaces% 30.3.2019
} % end of \doloopif


% specific variations of previous macro \doloopif
\letvalue{doloopifnum}=\doloopif %\doloopifnum{value1}{[compare_operator]}{value2}{macro_for_doing}% [compareoperators] ==, ~=, >, <, >=, <= % FOR COMPATIBILITY ONLY
\def\doloopuntil#1#2#3{\doloopif{#1}{repeatuntil}{#2}{#3}}% \doloopuntil{\Trida}{3.A}{\tableaction}% REPEAT-UNTIL loop: Repeats the action until the condition is met.
\letvalue{repeatuntil}=\doloopuntil%
\def\doloopwhile#1#2#3{\doloopif{#1}{whiledo}{#2}{#3}}% \doloopwhile{\Trida}{3.A}{\tableaction}% Repeat action when the condition is met.
\letvalue{whiledo}=\doloopwhile%

% 5. \filelineaction  % implicit do \lineaction for all lines of current open CSV table
% \filelineaction{filename.csv}   % do \lineaction macro for all lines of specific CSV table (filename.csv)
\def\filelineaction{\dotriplegroupempty\dofilelineaction}%

\def\dofilelineaction#1#2#3{%
	\doifelsenothing{#1}%
	{\opencsvfile\doloopaction%0 parameter - open actual CSV file and do action
	}%
	{\doifelsenothing{#2}%
	{\opencsvfile{#1}\doloopaction%1 parameter - parameter = filename
	}%
	{\doifelsenothing{#3}%
	{\opencsvfile{#1}\doloopaction{\lineaction}{#2}%2 parameters, 1st parameter = filename, 2nd parameter = num of lines
	}%
	{\opencsvfile{#1}\doloopaction{\lineaction}{#2}{#3}%3 parameters, 1st parameter = filename, 2nd parameter = from line, 3rd parameter = to line
	}}}%
}%

% 6. \doloopfornext{<numberofrows>}{<action>}
% do action <action> for next <number> of rows from current line of open CSV file
\def\doloopfornext#1#2{\ctxlua{thirddata.handlecsv.doloopfornext([==[\thenumexpr{#1}]==],[==[\detokenize{#2}]==])}}%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Complete listing macros and commands that can be used (to keep track of all defined macros):
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% \ifissetheader, \ifnotsetheader
% \ifEOF, \ifnotEOF
% \ifemptyline, \ifnotemptyline
% \ifemptylinesmarking, \ifemptylinesnotmarking (they can be set by macros \markemptylines, \notmarkemptylines and \resetmarkemptylines)
% \hookson, \hooksoff
% \resethooks
% user defined hooks macros: \bfilehook, \efilehook, \blinehook, \elinehook,
% \setheader, \unsetheader, (\resetheader - compatibility synonym)
% \setsep{<columnseparator>}, \unsetsep, (\resetsep - compatibility synonym)
% \setfiletoscan{<filetoprocess>}
% \numrows, \numemptyrows, \numnotemptyrows
% \numcols
% \csvfilename
% \thenumexp{<expression>}
% \addto\anymacro{<addingnonexpandedcontent>}, \eaddto\anymacro{<addingexpandedcontent>}
% \getcsvcell[<columnnumber or columnname>,<rownumber>], \csvcell[<columnnumber or columnname>,<rownumber>]
% \currentcell{<columnnumber or columnname}, \nextcell{<columnnumber or columnname}, \previouscell{<columnnumber or columnname}
% and their synonyms \currcell{}, \nextcell{}, \prevcell{}
% \colname[numberofcolumn], \xlscolname[<numberofcolumn>], \cxlscolname[<numberofcolumn>], \texcolname[<numberofcolumn>]
% \indexcolname[<'columnname' or 'xlsname'>]
% \columncontent[<numberofcolumn> or <'columnname'> or <'xlsname'>]
% \numberxlscolname[<'xlsname'>]
% \linepointer, (\lineno, \sernumline are synonyms), \resetlinepointer, \resetlinepointerof[<csvfile>], (\resetlineno, \resetsernumline are synonyms), \setlinepointer{<numberofline>}
% \savelineno=\savelinepointer, \setsavedlineno=\setsavedlinepointer
% \numline, \setnumline{<numberofline>}, \resetnumline
% \addtonumline{<number>}
% \indexofnotemptyline{}, \indexofemptyline{}
% \markemptylines, \notmarkemptylines, \resetmarkemptylines, \removeemptylines
% \nextlineof[csvfile], \prevlineof[csvfile], \nextline, \prevline
% \nextnumline
% \nextrowof[csvfile], \prevrowof[csvfile], \nextrow, \prevrow
% \exitlooptest
% \opencsvfile, \opencsvfile{<filename>}, \closecsvfile{<filename>}
% \readline, \readline{<numberofline>}
% \readandprocessparameters#1#2#3#4 -- for internal use only
% \replacecontentin{<colname/colnumber>}{<substitutefrom>}{<substituteto>}
%
%  Module predefined cycles for processing of lines CSV table:
% \doloopfromto{<fromnumblerline>}{<tonumblerline}{<\actionmacro>}
% \doloopforall, \doloopforall{<\actionmacro>}
% \doloopaction, \doloopaction{<\actionmacro>}, \doloopaction{<\actionmacro>}{<tonumblerline>}, \doloopaction{<\actionmacro>}{<fromnumblerline>}{<tonumblerline>}
% \doloopif{<value1>}{<compare_operator>}{value2}{<\actionmacro>}, (\doloopifnum{<value1>}{<compare_operator>}{value2}{<\actionmacro>} is synonym)
% \doloopuntil{<value1>}{<value2>}{<\actionmacro>} = \repeatuntil{<value1>}{<value2>}{<\actionmacro>}
% \doloopwhile{<value1>}{<value2>}{<\actionmacro>} = \doloopwhiledo{<value1>}{<value2>}{<\actionmacro>}
% \filelineaction, \filelineaction{<filename>}
% \doloopfornext{<+/-numberofrows>}{<\actionmacro>} % use \setlinepointer,  \resetlinepointer (and then set it up \setnumline) to set line pointer. Opening of CSV file automatically reset line pointer.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
]]

-- write definitions into ConTeXt:
thirddata.handlecsv.string2context(string2print)

