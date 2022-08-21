if not modules then modules = { } end modules ['games-go'] = {
    version   = 1.000,
    comment   = "Go",
    author    = "Wolfgang Schuster",
    copyright = "Wolfgang Schuster",
    email     = "schuster.wolfgang@googlemail.com",
    license   = "Public Domain"
}

do

thirddata                    = thirddata                    or { }
thirddata.games              = thirddata.games              or { }
thirddata.games.go           = thirddata.games.go           or { }
thirddata.games.go.field     = thirddata.games.go.field     or { }
thirddata.games.go.setup     = thirddata.games.go.setup     or { }
thirddata.games.go.deadstone = thirddata.games.go.deadstone or { }

local nx          = function()      return thirddata.games.go.setup.nx            end
local ny          = function()      return thirddata.games.go.setup.ny            end
local dx          = function()      return thirddata.games.go.setup.dx            end
local dy          = function()      return thirddata.games.go.setup.dy            end
local offset      = function()      return thirddata.games.go.setup.offset        end
local size        = function()      return thirddata.games.go.setup.stonesize     end
local board       = function()      return thirddata.games.go.setup.board         end
local distance    = function()      return thirddata.games.go.setup.labeldistance end
local symbolset   = function()      return thirddata.games.go.setup.symbolset     end
local alternative = function()      return thirddata.games.go.setup.alternative   end
local bp          = function(value) return number.tobasepoints(value)             end
local sp          = function(value) return value * 65536/(7227/7200)              end
local line        = function(k,v,s) return bp(thirddata.games.go.lines [k][v]*s)  end 
local arrow       = function(k,v,s) return bp(thirddata.games.go.arrows[k][v]*s)  end 

-- Drawing functions

thirddata.games.go.lastcolor   = 0
thirddata.games.go.currentmove = 0

function thirddata.games.go.move(color)
    thirddata.games.go.lastcolor   = color
    thirddata.games.go.currentmove = thirddata.games.go.currentmove + 1
end

thirddata.games.go.linecount = 0
thirddata.games.go.lines     = { }

function thirddata.games.go.line(x1,y1,x2,y2)
    thirddata.games.go.linecount = thirddata.games.go.linecount + 1
    thirddata.games.go.lines[thirddata.games.go.linecount] = { x1, y1, x2, y2 }
end

thirddata.games.go.arrowcount = 0
thirddata.games.go.arrows     = { }

function thirddata.games.go.arrow(x1,y1,x2,y2)
    thirddata.games.go.arrowcount = thirddata.games.go.arrowcount + 1
    thirddata.games.go.arrows[thirddata.games.go.arrowcount] = { x1, y1, x2, y2 }
end

function thirddata.games.go.board_color()
    if thirddata.games.go.setup['backgroundcolor'] ~= nil then
        tex.sprint("board := currentpicture ;")
        tex.sprint("currentpicture := nullpicture ;")
        tex.sprint("fill unitsquare xyscaled (" .. bp((nx()-1)*dx()+2*offset()) .. "," .. bp((ny()-1)*dy()+2*offset()) .. ")")
        tex.sprint("shifted (" .. bp(-offset()) .. "," .. bp(-offset()) .. ")")
        tex.sprint("withcolor \\MPcolor{" .. thirddata.games.go.setup['backgroundcolor'] .. "} ;")
        tex.sprint("addto currentpicture also board ;")
    end
end

thirddata.games.go.setup.figurewidth  = 0
thirddata.games.go.setup.figureheight = 0

function thirddata.games.go.board_figure()
    local width   = thirddata.games.go.setup.figurewidth
    local height  = thirddata.games.go.setup.figureheight
    local columns = math.floor( ((nx()-1)*dx()+2*offset()) / width  ) -- floor and not ceil because
    local rows    = math.floor( ((ny()-1)*dy()+2*offset()) / height ) -- I start from 0 and not 1
    if thirddata.games.go.setup['backgroundimage'] ~= nil then
        tex.sprint("board := currentpicture ;")
        tex.sprint("currentpicture := nullpicture ;")
        for row=0,rows do
            for col=0,columns do
                tex.sprint('externalfigure "' .. thirddata.games.go.setup['backgroundimage'] .. '"')
                tex.sprint('xyscaled (' .. bp(width) .. ',' .. bp(height) .. ')')
                tex.sprint('shifted (' .. bp(-offset()+row*width) .. ',' .. bp(-offset()+col*height) .. ') ;')
            end
        end
        tex.sprint("mine := unitsquare xyscaled (" .. bp((nx()-1)*dx()+2*offset()) .. "," .. bp((ny()-1)*dy()+2*offset()) .. ")")
        tex.sprint("        shifted (" .. bp(-offset()) .. "," .. bp(-offset()) .. ") ;")
        tex.sprint("clip currentpicture to mine ;")
        tex.sprint("addto currentpicture also board ;")
    end
end

function thirddata.games.go.board_new()
    local xy = 0
    thirddata.games.go.field[0] = { }
    for col=0,nx()+1 do
        thirddata.games.go.field[0][col] = { }
        for row=0,ny()+1 do
            if col==0 then
                xy = 3
            elseif col==nx()+1 then
                xy = 3
            elseif row==0 then
                xy = 3
            elseif row==ny()+1 then
                xy = 3
            else
                xy = 0
            end
            thirddata.games.go.field[0][col][row] = { color = xy, marker = nil, label = nil, move = nil }
        end
    end
end

function thirddata.games.go.board_copy(from,to)
    thirddata.games.go.field[to] = { }
    for k,v in pairs(thirddata.games.go.field[from]) do
        thirddata.games.go.field[to][k] = { }
        for x,y in pairs(thirddata.games.go.field[from][k]) do
            thirddata.games.go.field[to][k][x] = { }
            for a,b in pairs(thirddata.games.go.field[from][k][x]) do
               thirddata.games.go.field[to][k][x][a] = thirddata.games.go.field[from][k][x][a]
            end
        end
    end
end

function thirddata.games.go.board_lines_solid()
    for col=1,nx() do
        tex.sprint("draw (" .. bp((col-1)*dx()) .. ",0) -- (" .. bp((col-1)*dx()) .. "," .. bp((ny()-1)*dy()) .. ") ;")
    end
    for row=1,ny() do
        tex.sprint("draw (0," .. bp((row-1)*dy()) .. ") -- (" .. bp((nx()-1)*dx()) .. "," .. bp((row-1)*dy()) .. ") ;")
    end
end

function thirddata.games.go.board_lines_gap()
    -- draw horizontal rules
    for row=2,ny()-1 do
        for col=1,nx()-1 do
            if thirddata.games.go.field[0][col][row]['color'] == 0 then
                    tex.sprint("draw (" .. bp((col-1)*dx()) .. "," .. bp((row-1)*dy()) .. ") -- (" .. bp((col)*dx()) .. "," .. bp((row-1)*dy()) .. ") ;")
            else
                if thirddata.games.go.field[0][col+1][row]['color'] == 0 then
                    tex.sprint("draw (" .. bp((col-1)*dx()) .. "," .. bp((row-1)*dy()) .. ") -- (" .. bp((col)*dx()) .. "," .. bp((row-1)*dy()) .. ") ;")
                end
            end
        end
    end
    -- draw vertical rules
    for col=2,nx()-1 do
        for row=1,ny()-1 do
            if thirddata.games.go.field[0][col][row]['color'] == 0 then
                    tex.sprint("draw (" .. bp((col-1)*dx()) .. "," .. bp((row-1)*dy()) .. ") -- (" .. bp((col-1)*dx()) .. "," .. bp((row)*dy()) .. ") ;")
            else
                if thirddata.games.go.field[0][col][row+1]['color'] == 0 then
                    tex.sprint("draw (" .. bp((col-1)*dx()) .. "," .. bp((row-1)*dy()) .. ") -- (" .. bp((col-1)*dx()) .. "," .. bp((row)*dy()) .. ") ;")
                end
            end
        end
    end
    -- draw border frame
    tex.sprint("draw (0,0) -- (0," .. bp((ny()-1)*dy()) .. ") ;")
    tex.sprint("draw (" .. bp((nx()-1)*dx()).. ",0) -- (" .. bp((nx()-1)*dx()).. "," .. bp((ny()-1)*dy()) .. ") ;")
    tex.sprint("draw (0,0) -- (" .. bp((nx()-1)*dx()) .. ",0) ;")
    tex.sprint("draw (0," .. bp((ny()-1)*dy()).. ") -- (" .. bp((nx()-1)*dx()).. "," .. bp((ny()-1)*dy()) .. ") ;")
end

-- Note: I need to define the alternatives before I can use the test

thirddata.games.go.linestyles =
    {
        a = thirddata.games.go.board_lines_solid ,
        b = thirddata.games.go.board_lines_gap   ,
    }

function thirddata.games.go.board_lines()
    if thirddata.games.go.linestyles[alternative()]==nil then
        thirddata.games.go.board_lines_solid()
    else
        thirddata.games.go.linestyles[alternative()]()
    end
end

function thirddata.games.go.board_hoshi()
    for col=1,nx() do
        for row=1,ny() do
            tex.sprint("\\ifcsname go:hoshi:" .. row .. ":" .. col .. ":" .. board() .. "\\endcsname")
            tex.sprint("\\csname go:marker:hoshi\\endcsname")
            tex.sprint("{" .. bp(size()/5) .. "}")
            tex.sprint("{" .. bp((col-1)*dx()) .. "}")
            tex.sprint("{" .. bp((row-1)*dy()) .. "}")
            tex.sprint("\\fi")
        end
    end
end

function thirddata.games.go.board_stones()
    for col=1,nx() do
        for row=1,ny() do
            local color = thirddata.games.go.field[0][col][row]['color']
            if color==1 then
                tex.sprint("\\csname go:stone:" .. symbolset() .. ":black\\endcsname")
                tex.sprint("{" .. bp(size()) .. "}")
                tex.sprint("{" .. bp((col-1)*dx()) .. "}")
                tex.sprint("{" .. bp((row-1)*dy()) .. "}")
            elseif color==2 then
                tex.sprint("\\csname go:stone:" .. symbolset() .. ":white\\endcsname")
                tex.sprint("{" .. bp(size()) .. "}")
                tex.sprint("{" .. bp((col-1)*dx()) .. "}")
                tex.sprint("{" .. bp((row-1)*dy()) .. "}")
            end
        end
    end
end

function thirddata.games.go.board_marker()
    for col=1,nx() do
        for row=1,ny() do
            local marker = thirddata.games.go.field[0][col][row]['marker']
            local label  = thirddata.games.go.field[0][col][row]['label']
            if marker==nil then
            elseif marker=='label' then
                tex.sprint("\\csname go:marker:label\\endcsname")
                tex.sprint("{" .. label .. "}")
                tex.sprint("{" .. bp((col-1)*dx()) .. "}")
                tex.sprint("{" .. bp((row-1)*dy()) .. "}")
            else
                tex.sprint("\\ifcsname go:marker:" .. marker .. "\\endcsname")
                tex.sprint("\\csname go:marker:" .. marker .. "\\endcsname")
                tex.sprint("{" .. nx() .. "}")
                tex.sprint("{" .. ny() .. "}")
                tex.sprint("{" .. bp(dx()) .. "}")
                tex.sprint("{" .. bp(dy()) .. "}")
                tex.sprint("{" .. bp(size()) .. "}")
                tex.sprint("{" .. bp((col-1)*dx()) .. "}")
                tex.sprint("{" .. bp((row-1)*dy()) .. "}")
                tex.sprint("{" .. bp(offset()) .. "}")
                tex.sprint("\\fi")
            end
        end
    end
end

function thirddata.games.go.board_label()
    for col=1,nx() do
        tex.sprint('label.bot(textext("\\doattributes{@@@@gmgo}{labelstyle}{labelcolor}{\\sgfchar{' .. col .. '}}"),%')
        tex.sprint('(' .. bp((col-1)*dx()) .. ',' .. bp(-distance()) .. ')) ;')
    end
    for row=1,ny() do
        tex.sprint('label.lft(textext("\\doattributes{@@@@gmgo}{labelstyle}{labelcolor}{' .. row .. '}"),%')
        tex.sprint('(' .. bp(-distance()) .. ',' .. bp((row-1)*dy()) .. ')) ;')
    end
end

function thirddata.games.go.board_markerlines()
    for k, v in pairs(thirddata.games.go.lines) do
        tex.sprint("draw (" .. line(k,1,dx()) .. "," .. line(k,2,dy()) .. ") -- ")
        tex.sprint("     (" .. line(k,3,dx()) .. "," .. line(k,4,dy()) .. ") ;  ")
    end
end

function thirddata.games.go.board_markerarrows()
    for k, v in pairs(thirddata.games.go.arrows) do
        tex.sprint("drawarrow (" .. arrow(k,1,dx()) .. "," .. arrow(k,2,dy()) .. ") -- ")
        tex.sprint("          (" .. arrow(k,3,dx()) .. "," .. arrow(k,4,dy()) .. ") ;  ")
    end
end

function thirddata.games.go.board_size()
    tex.sprint("setbounds currentpicture to unitsquare %")
    tex.sprint("xyscaled (" .. bp((nx()-1)*dx()+2*offset()) .. "," .. bp((ny()-1)*dy()+2*offset()) .. ")")
    tex.sprint("shifted (" .. bp(-offset()) .. "," .. bp(-offset()) .. ") ;")
    tex.sprint("draw boundingbox currentpicture withpen pensquare scaled 1.2 ;")
end

function thirddata.games.go.board_draw(name)
    tex.sprint("\\startuseMPgraphic{" .. name .. "}{}")
    tex.sprint("path mine ; picture board ;")
    -- thirddata.games.go.board_figure() -- not here, I have to do this at the end
    thirddata.games.go.board_lines()
    thirddata.games.go.board_hoshi()
    thirddata.games.go.board_stones()
    thirddata.games.go.board_marker()
    thirddata.games.go.board_markerlines()
    thirddata.games.go.board_markerarrows()
    thirddata.games.go.board_label()
    thirddata.games.go.board_size()
    thirddata.games.go.board_color()
    thirddata.games.go.board_figure()
    tex.sprint("\\stopuseMPgraphic")
end


-- Deadstone calculator

local stone  = function() return thirddata.games.go.deadstone.stone  end
local enemy  = function() return thirddata.games.go.deadstone.enemy  end
local wall   = function() return thirddata.games.go.deadstone.wall   end
local marked = function() return thirddata.games.go.deadstone.marked end
local error  = function() return thirddata.games.go.deadstone.error  end
local dead   = function() return thirddata.games.go.deadstone.dead   end

function thirddata.games.go.deadstone.black()
    thirddata.games.go.deadstone.stone  = 1
    thirddata.games.go.deadstone.enemy  = 2
    thirddata.games.go.deadstone.wall   = 3
    thirddata.games.go.deadstone.marked = 4
    thirddata.games.go.deadstone.error  = 6
    thirddata.games.go.deadstone.dead   = 7
end

function thirddata.games.go.deadstone.white()
    thirddata.games.go.deadstone.stone  = 2
    thirddata.games.go.deadstone.enemy  = 1
    thirddata.games.go.deadstone.wall   = 3
    thirddata.games.go.deadstone.marked = 5
    thirddata.games.go.deadstone.error  = 6
    thirddata.games.go.deadstone.dead   = 7
end

thirddata.games.go.deadstone.deadcount = 2

function thirddata.games.go.deadstone.doprocesstones()
    for i=1,2 do -- for the moment, I have to check the code
        thirddata.games.go.deadstone.markstones()
    end
    thirddata.games.go.deadstone.deadstones()
    for n=1,thirddata.games.go.deadstone.deadcount do
        thirddata.games.go.deadstone.checkstones()
    end
    thirddata.games.go.deadstone.revertstones()
end

function thirddata.games.go.deadstone.processtones()
    -- we placed a black stone
    if thirddata.games.go.lastcolor==1 then
        thirddata.games.go.deadstone.process_white()
        thirddata.games.go.deadstone.process_black()
    -- we placed a white stone
    elseif thirddata.games.go.lastcolor==2 then
        thirddata.games.go.deadstone.process_black()
        thirddata.games.go.deadstone.process_white()
    end
end

function thirddata.games.go.deadstone.process_black()
    thirddata.games.go.deadstone.black()
    thirddata.games.go.deadstone.doprocesstones()
end

function thirddata.games.go.deadstone.process_white()
    thirddata.games.go.deadstone.white()
    thirddata.games.go.deadstone.doprocesstones()
end

local field        = function(x,y) return thirddata.games.go.field[0][x][y]['color']   end
-- local field_top    = function(x,y) return thirddata.games.go.field[0][x][y+1]['color'] end
-- local field_bottom = function(x,y) return thirddata.games.go.field[0][x][y-1]['color'] end
local field_bottom = function(x,y) return thirddata.games.go.field[0][x][y+1]['color'] end
local field_top    = function(x,y) return thirddata.games.go.field[0][x][y-1]['color'] end
local field_left   = function(x,y) return thirddata.games.go.field[0][x-1][y]['color'] end
local field_right  = function(x,y) return thirddata.games.go.field[0][x+1][y]['color'] end

--[[ldx--
<p>The <ldx:function>markstones</ldx:function> mark the stones if they
have the right stones on their sides or let them keep untouched.</p>
--ldx]]--

function thirddata.games.go.deadstone.markstones()
    for col=1,nx() do
        for row=1,ny() do
            if field(col,row)==stone() then
                if (field_left(col,row)==wall()
                        or field_left(col,row)==enemy()
                        or field_left(col,row)==marked())
                    and (field_right(col,row)==wall()
                        or field_right(col,row)==enemy()
                        or field_right(col,row)==stone())
                    and (field_bottom(col,row)==wall()
                        or field_bottom(col,row)==enemy()
                        or field_bottom(col,row)==marked())
                    and (field_top(col,row)==wall()
                        or field_top(col,row)==enemy()
                        or field_top(col,row)==stone())
                then
                    thirddata.games.go.field[0][col][row]['color'] = marked()
                end
            end
        end
    end
end

--[[ldx--
<p>The <ldx:function>deadstones</ldx:function> set stones with the value marked
to dead if the conditions in the function are true.</p>
--ldx]]--

function thirddata.games.go.deadstone.deadstones()
    for col=nx(),1,-1 do
        for row=ny(),1,-1 do
            if field(col,row)==marked() then
                if (field_left(col,row)==wall()
                        or field_left(col,row)==enemy()
                        or field_left(col,row)==marked())
                    and (field_right(col,row)==enemy()
                        or field_right(col,row)==wall()
                        or field_right(col,row)==dead())
                    and (field_bottom(col,row)==enemy()
                        or field_bottom(col,row)==wall()
                        or field_bottom(col,row)==dead())
                then
                    thirddata.games.go.field[0][col][row]['color'] = dead()
                end
            end
        end
    end
end

--[[ldx--
<p>Because the <ldx:function>deadstones</ldx:function> can sometimes set
already living stones to dead. To prevent this in the final result this
function looks through all stones with a loop in reverse direction and
reset the values to their original value if the stone is not dead and
should remain on the board. The function is currently called twice within
processtones but this can be changed with the counter deadcount.</p>
--ldx]]--

function thirddata.games.go.deadstone.checkstones()
    for col=1,nx() do
        for row=1,ny() do
            if field(col,row)==marked() then
                thirddata.games.go.field[0][col][row]['color'] = stone()
            elseif thirddata.games.go.field[0][col][row]['color']==dead() then
                if (field_left(col,row)==dead()
                        or field_left(col,row)==enemy()
                        or field_left(col,row)==wall())
                    and (field_right(col,row)==dead()
                        or field_right(col,row)==enemy()
                        or field_right(col,row)==wall())
                    and (field_bottom(col,row)==dead()
                        or field_bottom(col,row)==enemy()
                        or field_bottom(col,row)==wall())
                    and (field_top(col,row)==dead()
                        or field_top(col,row)==enemy()
                        or field_top(col,row)==wall())
                then
                    thirddata.games.go.field[0][col][row]['color'] = dead()
                else
                    thirddata.games.go.field[0][col][row]['color'] = stone()
                end
            end
        end
    end
end

--[[ldx--
<p>The last thing to do after all dead stones are found on the board
is to remove them and to reset all other stones which are still in a
marked state or we will get wrong input for the next move.</p>
--ldx]]--

function thirddata.games.go.deadstone.revertstones()
    for col=1,nx() do
        for row=1,ny() do
            if thirddata.games.go.field[0][col][row]['color']==marked() then
                thirddata.games.go.field[0][col][row] = stone()
            elseif thirddata.games.go.field[0][col][row]['color']==dead() then
                thirddata.games.go.field[0][col][row]['color'] = 0
            end
        end
    end
end

end


-- SGF parser

do

    thirddata           = thirddata           or { }
    thirddata.games     = thirddata.games     or { }
    thirddata.games.sgf = thirddata.games.sgf or { }

    local function command(name,x)
        tex.sprint(string.format("\\csname sgf!%s\\endcsname{%s}",name,x))
    end

    local nodes = { }

    function nodes.B (x) command("black"    ,x) end
    function nodes.W (x) command("white"    ,x) end
    function nodes.AW(x) command("addwhite" ,x) end
    function nodes.C (x) command("comment"  ,x) end

    local function action(what,data)
        local a = nodes[what]
        if a then
            for w in string.gmatch(data, "%b[]") do
                a(string.sub(w,2,-2))
            end
        else
            print("unknown action: " .. what)
        end
    end

    local function nodecontent(str)
        tex.sprint(string.format("\\csname sgf!node\\endcsname{%s}",string.sub(str,2)))
    end

    local space      = lpeg.S(' \r\n')^1
    local lcletter   = lpeg.R("az")
    local ucletter   = lpeg.R("AZ")
    local letter     = lcletter + ucletter

    local propindent = ucletter^1

    local property   = lpeg.C(propindent) * lpeg.C{ (lpeg.P("[") * (1 - lpeg.S"[]")^0 * lpeg.P("]"))^1} / action
	
    local function nest(str)
        tex.sprint(tex.ctxcatcodes,string.format("\\parsesgf{%s}",string.sub(str,2,-2)))
    end

    local node   = lpeg.P{ ";" * (propindent * (lpeg.P("[") * (1 - lpeg.S"[]")^0 * lpeg.P("]"))^1)^1} / nodecontent
    local branch = lpeg.P{ "(" * ((1 - lpeg.S"()") + lpeg.V(1))^0 * ")" } / nest

    local parser = (branch + node + property + space)^0

    function thirddata.games.sgf.parse(str)
        parser:match(str)
    end

end
