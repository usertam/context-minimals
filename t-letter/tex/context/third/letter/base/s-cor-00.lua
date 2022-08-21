if not modules then modules = { } end modules ['s-mod-00'] = {
    version   = 1.000,
    comment   = "companion to mult-aux.mkiv",
    author    = "Wolfgang Schuster",
    copyright = "Wolfgang Schuster",
    license   = "GNU General Public License"
}

thirddata                = thirddata                or { }
thirddata.correspondence = thirddata.correspondence or { }

local concat, toks, settings_to_array, settings_to_hash = table.concat, tex.toks, utilities.parsers.settings_to_array, utilities.parsers.settings_to_hash

local correspondence = thirddata.correspondence
local constants      = interfaces.constants
local variables      = interfaces.variables

local c_titlestyle = constants.titlestyle
local c_titlecolor = constants.titlecolor
local c_textcolor  = constants.textcolor
local c_textstyle  = constants.textstyle
local c_separator  = constants.separator

local v_correspondence = variables.correspondence
local v_letter         = variables.letter
local v_memo           = variables.memo
local v_resume         = variables.resume
local v_frames         = variables.frames
local v_stop           = variables.stop
local v_layer          = variables.layer
local v_section        = variables.section
local v_color          = variables.color
local v_singlesided    = variables.singlesided
local v_reset          = variables.reset
local v_line           = variables.line
local v_top            = variables.top
local v_bottom         = variables.bottom
local v_off            = variables.off
local v_right          = variables.right
local v_page           = variables.page
local v_paper          = variables.paper
local v_text           = variables.text
local v_start          = variables.start
local v_list           = variables.list

-- create synonyms for the default styles

local patterns = {
    [v_letter]   = { "letter-imp-%s.mkiv", "letter-imp-%s.tex", "letter-%s.mkiv", "letter-%s.tex" },
    [v_memo]     = {   "memo-imp-%s.mkiv",   "memo-imp-%s.tex",   "memo-%s.mkiv",   "memo-%s.tex" },
    [v_resume]   = { "resume-imp-%s.mkiv", "resume-imp-%s.tex", "resume-%s.mkiv", "resume-%s.tex" },
    [v_frames]   = { "frames-imp-%s.mkiv", "frames-imp-%s.tex", "frames-%s.mkiv", "frames-%s.tex" },
}

local function action(name,foundname)
    context.startreadingfile()
    context.pushendofline()
    context.unprotect()
    context.input(foundname)
    context.protect()
    context.popendofline()
    context.stopreadingfile()
end

function correspondence.file(environment,name)
    local environment = environment
    local name        = name
    resolvers.uselibrary {
        name     = name,
        patterns = patterns[environment],
        action   = action,
    }
end

correspondence.letter = { }

local function reference_a(environment,value)
    local environment = environment
    local value       = value
    local style       = nil
    context.vbox( function()
        style = concat({environment,value},":")
        context.setevalue("currentcorrespondencestyle",style)
        context.framed( { frame = v_off, location = v_bottom, align = v_right, offset = "0pt" }, function()
            context.usecorrespondencestylestyleandcolor(c_titlestyle,c_titlecolor)
            context.setupinterlinespace()
            context.lettertext(value)
            context.par()
        end )
        context.framed( { frame = v_off, location = v_top, align = v_right, offset = "0pt" }, function()
            context.usecorrespondencestylestyleandcolor(c_textstyle,c_textcolor)
            context.setupinterlinespace()
            context.correspondenceparameter(value)
            context.par()
        end )
    end )
end

function correspondence.letter.reference_a(environment,list)
    local environment = environment
    local list        = settings_to_array(list)
    local style       = nil
    if #list == 1 then
        local value = list[1]
        context.rightaligned( function() reference_a(environment,value) end )
    else
        context.maxaligned( function()
            for index, value in next, list do
                if value == "" or value == v_line then
                    -- ignore empty entries and the “line” keyword
                else
                    if index ~= 1 then context.hfill() end
                    reference_a(environment,value)
                end
            end
        end )
    end
end

function correspondence.letter.reference_b(environment,list)
    local environment = environment
    local list        = settings_to_array(list)
    local style       = nil
    context.vtop( function()
        for _, value in next, list do
            if value == "" then
                -- ignore empty entries in the list
            elseif value == v_line then
                context.blank{v_line}
            else
                context.hbox( function()
                    style = concat({environment,value},":")
                    context.setevalue("currentcorrespondencestyle",style)
                    context.begingroup()
                    context.usecorrespondencestylestyleandcolor(c_titlestyle,c_titlecolor)
                    context.lettertext(value)
                    context.correspondencestyleparameter(c_separator)
                    context.endgroup()
                    context.begingroup()
                    context.usecorrespondencestylestyleandcolor(c_textstyle,c_textcolor)
                    context.correspondenceparameter(value)
                    context.endgroup()
                end )
            end
        end
    end )
end

function correspondence.letter.reference_c(environment,list)
    local environment = environment
    local list        = settings_to_array(list)
    local style       = nil
    for _, value in next, list do
        if value == "" or value == v_line then
            -- ignore empty entries and the “line” keyword
        else
            style = concat({environment,value},":")
            context.setvalue("currentcorrespondencestyle",style)
            context.usecorrespondencestylestyleandcolor(c_textstyle,c_textcolor)
            context.correspondenceparameter(value)
        end
    end
end

function correspondence.letter.reference_d(environment,list)
    local environment = environment
    local list        = settings_to_array(list)
    local style       = nil
    context.vtop( function()
        context.starttabulate( { "|l|l|" }, { before = "", after = "" } )
        for _, value in next, list do
            if value == "" then
                -- ignore empty entries in the list
            elseif value == v_line then
                context.TB()
            else
                style = concat({environment,value},":")
                context.NC()
                    context.setvalue("currentcorrespondencestyle",style)
                    context.usecorrespondencestylestyleandcolor(c_titlestyle,c_titlecolor)
                    context.lettertext(value)
                    context.correspondencestyleparameter(c_separator)
                context.NC()
                    context.setvalue("currentcorrespondencestyle",style)
                    context.usecorrespondencestylestyleandcolor(c_textstyle,c_textcolor)
                    context.correspondenceparameter(value)
                context.NC()
                context.NR()
            end
        end
        context.stoptabulate()
    end )
end

function correspondence.letter.reference_e(environment,list)
    local environment     = environment
    local list            = settings_to_array(list)
    local style, settings = nil
    context.leftaligned( function()
        for _, value in next, list do
            if value == "" or value == v_line then
                -- ignore empty entries and the “line” keyword
            else
                context.unprotect()
                context.correspondence_style_width( environment, value, function() reference_a(environment,value) end )
                context.protect()
            end
        end        
    end )
end

function correspondence.description_split(list)
    local format, items = nil, nil
    if string.find(list,":") then
        format, items = string.splitup(list,":")
        if format ~= v_list then
            items = list
        end
    else
        items = list
    end
    -- the macros are empty be default, change this only when necessary
    context.unprotect()
    if format then context.setvalue("m_correspondence_description_format",format) end
    if items  then context.setvalue("m_correspondence_description_items" ,items ) end
    context.protect()
end