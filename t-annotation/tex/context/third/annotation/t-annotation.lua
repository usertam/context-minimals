if not modules then modules = { } end modules ['t-annotation'] = {
    version   = 1.000,
    comment   = "Annotations",
    author    = "Wolfgang Schuster",
    copyright = "Wolfgang Schuster",
    license   = "GNU General Public License"
}

thirddata            = thirddata            or {}
thirddata.annotation = thirddata.annotation or {}

local annotation   = thirddata.annotation

local variables    = interfaces.variables

local format       = string.format
local gsub         = string.gsub
local rep          = string.rep
local validstring  = string.valid

local datasets     = job.datasets

local v_yes        = variables.yes
local v_no         = variables.no
local v_auto       = variables.auto
local v_paragraph  = variables.paragraph
local v_text       = variables.text
local v_command    = variables.command
local v_vertical   = variables.vertical
local v_horizontal = variables.horizontal
local v_annotation = variables.annotation
local v_buffer     = variables.buffer

local texsprint    = tex.sprint
local ctxcatcodes  = tex.ctxcatcodes
local txtcatcodes  = tex.txtcatcodes

-- Collect the content of the environment

local data = { }

function annotation.erasedata(name)
    data[name] = nil
end

function annotation.getdata(name)
    local data = data[name]
    return data and data.content or ""
end

function annotation.printdata(environment,name)
    local content, catcodes
    if tex.conditionals['c_annotation_buffer'] and name ~= "" then
        content  = datasets.getdata(environment,name,"content")  or ""
        catcodes = datasets.getdata(environment,name,"catcodes") or ""
    else
        content  = data[name] and data[name]["content"]  or ""
        catcodes = data[name] and data[name]["catcodes"] or ""
    end
    if catcodes == txtcatcodes then
        context.pushcatcodes(txtcatcodes)
    else
        context.pushcatcodes(ctxcatcodes)
    end
    if tex.conditionals['c_annotation_inline'] then
        context(content:strip()) -- remove leading/trailing spaces
    else
        context.viafile(content,format("annotation.%s",validstring(name,"noname")))
    end
    context.popcatcodes()
end

function annotation.parameters(environment,name)
    local data = data[name]
    local parameters = data and data.parameters or ""
    texsprint(ctxcatcodes,parameters)
end

function annotation.dataset(environment,name,parameters,content,catcodes)
    datasets.setdata {
        name = environment,
        tag  = name,
        data = {
            parameters = parameters,
            content    = content,
            catcodes   = catcodes
        }
    }
end

function annotation.collectdata(environment,name,parameters,content,begintag,endtag,catcodes)
    local oldcontent = annotation.getdata(name)
    local content    = content
    local parameters = parameters
    local catcodes   = catcodes
    local nesting    = false
    if oldcontent == "" then
        -- no nested environment
    else
        content = oldcontent .. endtag .. " " .. content
    end
    if select(2,gsub(content,begintag,begintag)) > select(2,gsub(content,endtag,endtag)) then
        nesting = true
    else
        nesting = false
    end
    if not nesting and name ~= "" then
        annotation.dataset(environment,name,parameters,content,catcodes)
    end
    data[name] = { parameters = parameters, content = content, catcodes = catcodes }
    commands.doifelse(nesting)
end

function annotation.savedata(environment,name,parameters,content,catcodes)
    data[name] = { parameters = parameters, content = content, catcodes = catcodes }
end

-- Write the content of the environment to a file

annotation.empty = true

function annotation.open()
    annotation.export = io.open(file.addsuffix(table.concat({tex.jobname,"annotation"},"-"),"txt"),"wb")
end

function annotation.write(title,content)
    local title, content = title:strip(), content
    if annotation.empty == true then
        annotation.open()
        annotation.empty = false
    else
        annotation.export:write("\n\n")
    end
    if title ~= "" then
        annotation.export:write(title)
        annotation.export:write("\n",rep("-",#title),"\n\n")
        content = content:gsub(" \\par ","\n\n")
        annotation.export:write(content)
    end
end

--~ function annotation.write(title,content)
--~     local title, content = title:strip(), content
--~     if annotation.empty == true then
--~         annotation.open()
--~         annotation.empty = false
--~     else
--~         annotation.export:write("\n")
--~     end
--~     annotation.export:write(title.." "..content)
--~ end
