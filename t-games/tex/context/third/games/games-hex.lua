if not modules then modules = { } end modules ['games-hex'] = {
    version   = 1.000,
    comment   = "Hex",
    author    = "Wolfgang Schuster",
    copyright = "Wolfgang Schuster",
    email     = "schuster.wolfgang@googlemail.com",
    license   = "Public Domain"
}

do

thirddata                 = thirddata                 or { }
thirddata.games           = thirddata.games           or { }
thirddata.games.hex       = thirddata.games.hex       or { }
thirddata.games.hex.setup = thirddata.games.hex.setup or { }

local nx       = function()      return thirddata.games.hex.setup.nx       end
local ny       = function()      return thirddata.games.hex.setup.ny       end
local dx       = function()      return thirddata.games.hex.setup.dx       end
local dy       = function()      return thirddata.games.hex.setup.dy       end
local offset   = function()      return thirddata.games.hex.setup.offset   end
local size     = function()      return thirddata.games.hex.setup.size     end
local distance = function()      return thirddata.games.hex.setup.distance end
local bp       = function(value) return number.tobasepoints(value)         end
local sp       = function(value) return value * 65536/(7227/7200)          end

function thirddata.games.hex.board_new()
    thirddata.games.hex.field = { }
    for col=1,nx() do
        thirddata.games.hex.field[col] = { }
        for row=1,ny() do
            thirddata.games.hex.field[col][row] = { color = 0 }
        end
    end
end

function thirddata.games.hex.board_lines()
    for row=1,ny() do
        for col=1,ny() do
            tex.sprint("draw (")
            for rot=0,5 do
                tex.sprint("(" .. bp(size()) .. ",0) rotated (" .. rot*60+90 .. ") --")
            end
            tex.sprint("cycle) shifted (" .. bp(math.cos(math.pi/6)*size()*(2*(col-1)+(row-1))) .. "," .. bp(-size()*1.5*(row-1)) .. ") ; ")
        end
    end
end

function thirddata.games.hex.board_labels()
    for col=1,nx() do
        tex.sprint('label.top(textext("\\doattributes{@@@@gmhex}{labelstyle}{labelcolor}{\\sgfchar{' .. col .. '}}"),%')
        tex.sprint('(' .. bp(-(size()+distance())*math.tan(math.pi/6)+2*(col-1)*math.cos(math.pi/6)*size()) .. ',' .. bp(size()+distance()) .. ')) ;')
    end
    for row=1,ny() do
        tex.sprint('label.lft(textext("\\doattributes{@@@@gmhex}{labelstyle}{labelcolor}{' .. row .. '}"),%')
        tex.sprint('(' .. bp(-math.cos(math.pi/6)*size()-distance()+(row-1)*math.cos(math.pi/6)*size()) .. ',' .. bp(-1.5*(row-1)*size()) .. ')) ;')
    end
end

function thirddata.games.hex.board_stones()
    local color = function(x,y) return thirddata.games.hex.field[x][y]['color'] end
    for col=1,nx() do
        for row=1,ny() do
            if color(col,row)==1 then
                thirddata.games.hex.stone(math.cos(math.pi/6)*size()*(2*(col-1)+(row-1)),-size()*1.5*(row-1),"red")
            elseif color(col,row)==2 then
                thirddata.games.hex.stone(math.cos(math.pi/6)*size()*(2*(col-1)+(row-1)),-size()*1.5*(row-1),"blue")
            end
        end
    end
end

function thirddata.games.hex.stone(x,y,color)
    tex.sprint("fill (")
    for rot=0,5 do
        tex.sprint("(" .. bp(size()) .. ",0) rotated (" .. rot*60+90 .. ") --")
    end
    tex.sprint("cycle) shifted (" .. bp(x) .. "," .. bp(y) .. ")")
    tex.sprint("withcolor \\MPcolor{" .. color .. "} ;")
end

function thirddata.games.hex.board_draw(name)
    tex.sprint("\\startuniqueMPgraphic{" .. name .. "}{}")
    thirddata.games.hex.board_stones()
    thirddata.games.hex.board_lines()
    thirddata.games.hex.board_labels()
    tex.sprint("\\stopuniqueMPgraphic")
end

end
