#!/usr/bin/env texlua
--------------------------------------------------------------------------------
--         FILE:  rst_helpers.lua
--        USAGE:  called by rst_parser.lua
--  DESCRIPTION:  Complement to the reStructuredText parser
--       AUTHOR:  Philipp Gesang (Phg), <phg42.2a@gmail.com>
--      CHANGED:  2014-03-02 19:20:28+0100
--------------------------------------------------------------------------------
--

local P, R, S, V, lpegmatch
    = lpeg.P, lpeg.R, lpeg.S, lpeg.V, lpeg.match

local C,   Carg, Cb, Cc, Cg,
      Cmt, Cp,   Cs, Ct 
    = lpeg.C,   lpeg.Carg, lpeg.Cb, lpeg.Cc, lpeg.Cg,
      lpeg.Cmt, lpeg.Cp,   lpeg.Cs, lpeg.Ct

local helpers
helpers       = thirddata.rst_helpers
helpers.table = {}
helpers.cell  = {}

local utf    = unicode.utf8
local utflen = utf.len

local stringstrip  = string.strip
local stringformat = string.format

function helpers.dbg_writef(...)
    if helpers.rst_debug then
        io.write(stringformat(...))
    end
end

local dbg_write = helpers.dbg_writef

helpers.patterns  = {}

do
    local p = helpers.patterns
    p.dash   = P"-"
    p.equals = P"="
    p.plus   = P"+"
    p.bar    = P"|"
    p.eol    = P"\n"
    p.last   = -P(1)
    p.space  = P" "

    p.dash_or_equals = p.dash + p.equals

    p.celldelim   = p.bar + p.plus
    p.cellcontent = (1 - p.celldelim)
    p.cell        = p.celldelim * C((1 - p.celldelim)^1) * #p.celldelim
    p.cell_line   = p.plus * p.dash^1 * #p.plus
    p.dashesonly  = p.dash^1  * p.last
    p.spacesonly  = p.space^1 * p.last

    p.col_start = Cp() * p.dash_or_equals^1
    p.col_stop  = p.dash_or_equals^1 * Cp()
    p.column_starts = Ct(p.col_start * ( p.space^1 * p.col_start)^1)
    p.column_stops  = Ct(p.col_stop  * ( p.space^1 * p.col_stop)^1)

    p.st_headsep = p.equals^1 * (p.space^1 * p.equals^1)^1
    p.st_colspan = p.dash^1 * (p.space^1 * p.dash^1)^0 * p.space^0 * p.last
    p.st_span_starts = Ct(Cp() * p.dash^1 * (p.space^1 * Cp() * p.dash^1)^0)
    p.st_span_stops  = Ct(p.dash^1 * Cp() * (p.space^1 * p.dash^1 * Cp())^0)


    p.cells = P{
        [1] = "cells",
        cells = p.celldelim 
              * (C(V"in_cell")
               * (V"matchwidth" * C(V"in_cell"))^1),

        in_cell = p.cellcontent^1
                + (p.dash - p.cellcontent)^1,

        matchwidth = Cmt(C(p.celldelim) * Carg(1), function(s,i,del, layout)
                         local pos = 1
                         local lw  = layout.widths
                         for n=1, #lw do
                             pos = pos + lw[n] + 1
                             if (i - 1) == pos then return true end
                         end
                         return false
                     end),
    }

    p.sep_line = p.plus * (p.dash^1   * p.plus)^1 * p.last
    p.sep_head = p.plus * (p.equals^1 * p.plus)^1 * p.last

    p.sep_part = ((1 - p.cell_line)^0 * p.cell_line) - p.sep_line

    p.new_row = p.sep_line + p.sep_head + p.sep_part

    p.whitespace = S" \t\v\r\n"^1
    p.strip = p.whitespace^0 * C((1 - (p.whitespace * p.last))^1) * p.whitespace^0 * p.last


    local colon = P":"
    local escaped_colon = P"\\:"
    local nocolon = (escaped_colon + (1 - colon))^1
    p.colon_right = nocolon * colon
    p.colon_keyval = colon^-1 * C(nocolon) * colon * p.space^1 * C((1 - (p.space^0 * P(-1)))^1)

    -- color expression matching for text roles
    local digit = R"09"
    local dot   = P"."
    local colvalue = digit * dot * digit^1
                   + digit
                   + dot * digit^1
    local coldelim = P"_" + P"-"
    p.rgbvalues = P"rgb_"
                * Ct( C(colvalue) * coldelim * C(colvalue) * coldelim * C(colvalue) )
end

function helpers.cell.create(raw, n_row, n_col, parent, variant)
    local p = helpers.patterns
    local cell = {}
    cell.stripped = raw and p.strip:match(raw) or ""
    cell.content  = raw
    cell.width    = raw and utflen(raw) or 0
    cell.bytes    = raw and #raw or 0
    cell.variant  = "normal" -- [normal|separator|y_continue|x_continue]
    cell.pos      = {}
    cell.pos.x    = n_col
    cell.pos.y    = n_row
    cell.span     = {}
    cell.span.x   = 1
    cell.span.y   = 1
    cell.parent   = parent
    return cell
end

function helpers.cell.get_x_span(content, layout, init)
    local acc = 0
    local lw = layout.widths
    for n=init, #lw do
        acc = acc + lw[n] + 1
        if utflen(content) + 1 == acc then 
            return n - init
        end
    end
    return false
end


-- Extending a cell by 1 cell horizontally.
function helpers.cell.add_x (cell)
    cell.span.x = cell.span.x + 1
end


local function set_layout (line)
    local p = helpers.patterns
    local layout = {}
    local slice = Ct((p.plus * C(p.dash^1) * #p.plus)^1)

    layout.widths = {}
    layout.slices = {}
    local elms = lpegmatch(slice, line)
    for n=1, #elms do
        local elm = elms[n]
        layout.widths[n] = #elm
        layout.slices[n] =  elm
    end
    return layout
end

function helpers.table.create(raw)
    local newtab = {}
    newtab.rows  = {}
    newtab.layout = set_layout(raw[1])

    local p = helpers.patterns

    newtab.resolve_parent = function(row, col, array)
        local array = array or newtab.rows
        local cell  = array[row][col]
        local par_row, par_col = row, col
        if cell.parent then
            par_row, par_col = newtab.resolve_parent(cell.parent.y, cell.parent.x)
        end
        return par_row, par_col
    end

    newtab.__init = function()
        local hc = helpers.cell
        local rowcount = 0
        local newtablayout = newtab.layout
        for nr=1, #raw do
            local row = raw[nr]
            newtab.rows[nr] = {}
            local this_row = newtab.rows[nr]
            this_row.sepline = p.sep_line:match(row)
            this_row.sephead = p.sep_head:match(row)
            this_row.seppart = p.sep_part:match(row)
            if this_row.sephead then
                newtab.has_head = true
                newtab.head_end = nr
            end

            local splitted = { p.cells:match(row, 1, newtablayout) }
            local pos_layout, pos_row = 1, 1
            local make_empty = {}
            make_empty.n, make_empty.parent = 0, nil

            while pos_layout <= #newtablayout.widths do
                local splitpos = splitted[pos_layout]
                local layoutwidth = newtablayout.widths[pos_layout]
                local span = 1
                local this

                if make_empty.n > 0 then
                    make_empty.n = make_empty.n - 1
                    this = hc.create("", nr, pos_layout, make_empty.parent)
                    this.parent  = make_empty.parent
                    p_row, p_col = newtab.resolve_parent(this.parent.y, this.parent.x)
                    local thisparent = newtab.rows[p_row][p_col]
                    if this_row.sepline or this_row.sephead or
                        newtab.rows[p_row][p_col].variant == "separator" then
                        this.variant = "separator"
                    else
                        this.variant = "empty1"
                    end
                else
                    local cellwidth = utflen(splitpos)
                    if cellwidth > layoutwidth then
                        span = span + hc.get_x_span(splitpos, newtablayout, pos_layout)
                    end
                    pos_row = pos_row + span
                    this = hc.create(splitpos, nr, pos_layout, nil)
                    if p.dashesonly:match(splitpos) or
                        this_row.sepline or this_row.sephead then
                        this.variant = "separator"
                    end
                    this.span.x = span
                    make_empty.n = span - 1
                    make_empty.parent = span > 1 and { y = nr, x = pos_layout } or nil
                end

                this_row[pos_layout] = this
                pos_layout = pos_layout + 1
            end -- while
        end -- for loop over rows

        local oldrows = newtab.rows
        local newrows = oldrows
        for nc=1, #newtablayout.widths do
            local width = newtablayout.widths[nc]
            -- this is gonna be extremely slow but at least it's readable
            local newrow
            local currentrow = 1
            for nr=1, #newrows do
                local row = newrows[nr]
                local cell = row[nc]
                dbg_write("nc: %s, nr:%2s | %9s | ", nc, nr,cell.variant)
                if  row.sepline or row.sephead
                    or p.dashesonly:match(cell.content)
                    or cell.variant == "separator" then -- separator; skipping and beginning new row
                    newrows[nr][nc] = cell
                    currentrow = currentrow + 1
                    newrow = true
                    dbg_write("new >%24s< ", cell.stripped)
                    if cell.parent then dbg_write("parent |") else dbg_write("no par |") end
                else
                    dbg_write("old >%24s< ", cell.stripped)
                    if cell.parent then dbg_write("parent |") else dbg_write("no par |") end
                    if newrow then
                        newrows[nr][nc] = cell
                        currentrow = currentrow + 1
                    else -- continuing parent

                        local par_row, par_col
                        local parent
                        if cell.parent then
                            par_row, par_col = newtab.resolve_parent(cell.parent.y, cell.parent.x, newrows)
                            dbg_write(" use %s,%2s | ", par_col, par_row)
                        else -- Using vertical predecessor.
                            par_row, par_col = newtab.resolve_parent(nr-1,nc, newrows)
                            dbg_write(" new %s,%2s | ", par_col, par_row)
                        end
                        parent = newrows[par_row][par_col]

                        if newrows[nr].seppart then
                            dbg_write("span++")
                            parent.span.y   = parent.span.y + 1
                        end

                            parent.content  = parent.content  .. cell.content
                            parent.stripped = parent.stripped .. " " .. cell.stripped
                            cell.variant = "empty2"
                        cell.parent  = { x = par_col, y = par_row }
                    end
                    newrow = false
                end
                dbg_write("\n")
                newrows[nr][nc] = cell
            end -- for loop over rows
        end -- for loop over columns
        --newtab.rows = oldrows
        newtab.rows = newrows
    end

    newtab.__init()

--[[
    newtab.__draw_debug = function()
        for nr=1, #newtab.rows do
            local row = newtab.rows[nr]
            for nc=1, #row do
                local cell = row[nc]
                local field = cell.variant:sub(1,7)
                if cell.parent then
                    field = field .. string.format(" %s,%2s",cell.parent.x, cell.parent.y)
                end
                dbg_write("%12s | ", field)
            end
            dbg_write("\n")
        end
    end
--]]

    return newtab
end



function helpers.table.resolve_parent (row, col, array)
    local cell = array[row][col]
    local par_row, par_col = row, col
    if cell.parent then
        par_row, par_col = self.resolve_parent(cell.parent.y, cell.parent.x)
    end
    return par_row, par_col
end


-- Check the column boundaries of a simple table.
function helpers.get_st_boundaries (str)
    local p_column_starts = helpers.patterns.column_starts
    local p_column_stops  = helpers.patterns.column_stops
    local starts, stops, slices, elms = { }, { }, { }, nil

    elms = lpegmatch(p_column_starts, str)
    for n=1, #elms do
        local elm = elms[n]
        slices[n] = { start = elm }
        starts[elm] = true
    end

    elms = lpegmatch(p_column_stops, str)
    for n=1, #elms do
        local elm = elms[n]
        slices[n]["stop"]  = elm
        stops[elm] = true
    end
    return { starts = starts, stops = stops, slices = slices }
end

function helpers.table.simple(raw)
    local rows = {}
    local multispans = {}
    local bounds = helpers.get_st_boundaries(raw[1])
    local p = helpers.patterns

    for nr=1, #raw do
        local row = raw[nr]
        local newrow = {}
        if not p.st_headsep:match(row) and
           not p.st_colspan:match(row) then
            local starts, stops = {}, {}
            local check_span = false
            if p.st_colspan:match(raw[nr+1]) then  -- expect spans over several columns
                starts = p.st_span_starts:match(raw[nr+1])
                stops  = p.st_span_stops :match(raw[nr+1])
                check_span = true
            else
                for ncol=1, #bounds.slices do
                    local slice = bounds.slices[ncol]
                    starts[ncol] = slice.start
                    stops [ncol] = slice.stop
                end
            end

            for nc=1, #starts do
                local start = starts[nc]
                -- last column can exceed layout width
                local stop = nc ~= #starts and stops[nc] or #row
                local cell = {
                    content = "",
                    span   = { x = 1, y = 1 },
                }
                cell.content = stringstrip(row:sub(start, stop))
                if check_span then
                    local start_at, stop_at
                    for ncol=1, #bounds.slices do
                        local slice = bounds.slices[ncol]
                        if slice.start == start then
                            start_at = ncol
                        end
                        if start_at and
                           not (ncol == #bounds.slices) then
                            if slice.stop == stop then
                                stop_at = ncol
                                break
                            end
                        else -- last column, width doesn't matter
                            stop_at = ncol
                        end
                    end
                    cell.span.x = 1 + stop_at - start_at
                end
                newrow[nc] = cell
            end
        elseif p.st_colspan:match(row) then
            newrow.ignore = true
        elseif not rows.head_end    and
                nr > 1 and #raw > nr then -- ends the header
            rows.head_end = nr
            newrow.head_sep = true
            newrow.ignore = true
        else
            newrow.ignore = true
        end
        rows[nr] = newrow
    end

    for nr=1, #rows do
        local row = rows[nr]
        if not row.ignore and row[1].content == "" then
            row.ignore = true
            for nc=1, #row do
                local cell = row[nc]
                local par_row, par_col = helpers.table.resolve_parent(nr - 1, nc, rows)
                parent = rows[par_row][par_col]
                parent.content = parent.content .. " " .. cell.content
                cell.content = ""
            end

        end
    end

    return rows
end

helpers.list = {}

do
    local c = {}
    c.roman = S"ivxlcdm"^1
    c.Roman = S"IVXLCDM"^1
    c.alpha = R"az" - P"i" - P"v" - P"x" - P"l"
    c.Alpha = R"AZ" - P"I" - P"V" - P"X" - P"L"
    c.digit = R"09"^1
    c.auto  = P"#"

    local stripme   = S" ()."
    local dontstrip = 1 - stripme
    local itemstripper = stripme^0 * C(dontstrip^1) * stripme^0

    local con = function (str)
        str = itemstripper:match(str)
        for conv, pat in next, c do
            if pat:match(str) then
                return conv
            end
        end
        return false
    end
    helpers.list.conversion = con

    local rnums = {
        i = 1,
        v = 5,
        x = 10,
        l = 50,
        c = 100,
        d = 500,
        m = 1000,
    }

    local function roman_to_arab (str)
        local n = 1
        local curr, succ
        local max_three = { }
        local value = 0
        while n <= #str do
            if curr and curr == max_three[#max_three] then
                if #max_three >= 3 then
                    return "Not a number"
                else
                    max_three[#max_three+1] = curr
                end     
            else    
                max_three = { curr }
            end     

            curr = rnums[str:sub(n,n)] or 1

            n = n + 1
            succ = str:sub(n,n)

            if succ and succ ~= "" then
                succ = rnums[succ]
                if curr < succ then
                    --n = n + 1
                    --value = value + succ - curr
                    value = value  - curr
                else    
                    value = value + curr
                end     
            else    
                value = value + curr
            end     
        end     
        return value
    end
    helpers.list.roman_to_arab = roman_to_arab

    local suc = function (str, old)
        str, old = itemstripper:match(str), itemstripper:match(old)
        local n_str, n_old = tonumber(str), tonumber(old)
        if n_str and n_old then -- arabic numeral
            return n_str == n_old + 1
        end

        local con_str, con_old = con(str), con(old)
        if con_str == "alpha"  or
           con_str == "Alpha" then
            return str:byte() == old:byte() + 1
        else -- “I'm a Roman!” - “A woman?” - “No, *Roman*! - Au!” - “So your father was a woman?”
            if not (str:lower() == str  or
                    str:upper() == str) then -- uneven cased --> fail
                return false
            end

            local trc = thirddata.rst.state.roman_cache
            n_str = trc[str] or nil
            n_old = trc[old] or nil
            if not n_str then
                n_str = roman_to_arab(str:lower())
                trc[str] = n_str
            end
            if not n_old then
                n_old = roman_to_arab(old:lower())
                trc[old] = n_old
            end
            return n_str == n_old + 1 
        end
    end
    helpers.list.successor = suc

    local greater = function (str, old)
        str, old = itemstripper:match(str), itemstripper:match(old)
        local n_str, n_old = tonumber(str), tonumber(old)
        if n_str and n_old then -- arabic numeral
            return n_str > n_old
        end

        local con_str, con_old = con(str), con(old)
        if con_str == "alpha"  or
           con_str == "Alpha" then
            return str:byte() > old:byte()
        else
            if not (str:lower() == str  or
                    str:upper() == str) then -- uneven cased --> fail
                return false
            end


            local trc = thirddata.rst.state.roman_cache
            n_str = trc[str] or nil
            n_old = trc[old] or nil
            if not n_str then
                n_str = roman_to_arab(str:lower())
                trc[str] = n_str
            end
            if not n_old then
                n_old = roman_to_arab(old:lower())
                trc[old] = n_old
            end
            return n_str > n_old
        end
    end
    helpers.list.greater = greater

    local gd = function(str)
        str = itemstripper:match(str)
        local value
        local con_str = con(str)
        if con_str == "alpha"  or
           con_str == "Alpha" then
            return str:byte()
        else
            if not (str:lower() == str  or
                    str:upper() == str) then
                return false
            end

            local trc = thirddata.rst.state.roman_cache
            n_str = trc[str] or nil
            if not n_str then
                n_str = roman_to_arab(str:lower())
                trc[str] = n_str
            end
            return n_str
        end
    end

    helpers.list.get_decimal = gd
end

helpers.string = {}

do
    --- This grammar inside the function is slightly faster than the
    --- same as an upvalue with the value of “width” repeatedly given
    --- via lpeg.Carg(). This holds for repeated calls as well.
    local ulen = utflen
    function helpers.string.wrapat (str, width)
        local width = width or 65
        local linelength = 0
        local wrap = P{
            [1] = "wrapper",

            wrapper       = Cs(V"nowhitespace"^0 * (Cs(V"wrapme") + V"other")^1),
            whitespace    = S" \t\v" + P"\n" / function() linelength = 0 end,
            nowhitespace  = 1 - V"whitespace",
            typing        = P[[\\type{]]  * (1 - P"}")^0 * P"}",
            typingenv     = P[[\\starttyping]] * (1 - P[[\\stoptyping]])^0 * P[[\\stoptyping]],
            ignore        = V"typing" + V"typingenv",
            --- the initial whitespace of the “other” pattern must not
            --- be enforced (“^1”) as it will break the exceptions
            --- (“ignore” pattern)! In general it is better to have the
            --- wrapper ignore some valid breaks than to not have it
            --- matching some valid strings at all.
            other         = Cmt(V"whitespace"^0 * (V"ignore" + (1 - V"whitespace")^1), function(s,i,w)
                                   linelength = linelength + ulen(w)
                                   return true
                               end),
            wrapme = Cmt(V"whitespace"^1 * (1 - V"whitespace" - V"ignore")^1, function(s,i,w)
                        local lw = ulen(w)
                        if linelength + lw > width then
                            linelength = lw
                            return true
                        end
                        return false
                    end) / function (word) return "\n" .. word:match("[^%s]+") end,
        }

        local reflowed = wrap:match(str)
        return reflowed
    end
end

