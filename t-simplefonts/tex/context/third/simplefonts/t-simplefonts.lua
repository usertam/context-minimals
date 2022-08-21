if not modules then modules = { } end modules ['t-simplefonts'] = {
    version   = 1.000,
    comment   = "Simplefonts",
    author    = "Wolfgang Schuster",
    copyright = "Wolfgang Schuster",
    email     = "schuster.wolfgang@googlemail.com",
    license   = "GNU General Public License"
}

local texsprint, ctxcatcodes, prtcatcodes, format, lower, gsub, find = tex.sprint, tex.ctxcatcodes, tex.prtcatcodes, string.format, string.lower, string.gsub, string.find

thirddata             = thirddata             or { }
thirddata.simplefonts = thirddata.simplefonts or { }

local simplefonts = thirddata.simplefonts 

simplefonts.fontlist   = simplefonts.fontlist   or { }
simplefonts.extlist    = simplefonts.extlist    or { }
simplefonts.features   = simplefonts.features   or { }
simplefonts.scripts    = simplefonts.scripts    or { }
simplefonts.languages  = simplefonts.languages  or { }

simplefonts.fontlist = {
    ["hiraginokakugothicpro"] = -- Hiragino Kaku Gothic Pro
        {
            ["normal"] =
                {
                    regular     = "hirakakuprow3" ,
                    italic      = "hirakakuprow3" ,
                    bold        = "hirakakuprow6" ,
                    bolditalic  = "hirakakuprow6" ,
                 } ,
        } ,
    ["hiraginokakugothicpron"] = -- Hiragino Kaku Gothic ProN
        {
            ["normal"] =
                {
                    regular     = "hirakakupronw3" ,
                    italic      = "hirakakupronw3" ,
                    bold        = "hirakakupronw6" ,
                    bolditalic  = "hirakakupronw6" ,
                } ,
        } ,
    ["hiraginokakugothicstd"] = -- Hiragino Kaku Gothic Std
        {
            ["normal"] =
                {
                    regular     = "hirakakustdw8" ,
                    italic      = "hirakakustdw8" ,
                    bold        = "hirakakustdw8" ,
                    bolditalic  = "hirakakustdw8" ,
                } ,
        } ,
    ["hiraginokakugothicstdn"] = -- Hiragino Kaku Gothic StdN
        {
            ["normal"] =
                {
                    regular     = "hirakakustdnw8" ,
                    italic      = "hirakakustdnw8" ,
                    bold        = "hirakakustdnw8" ,
                    bolditalic  = "hirakakustdnw8" ,
                } ,
        } ,
    ["hiraginomarugothicpro"] = -- Hiragino Maru Gothic Pro
        {
            ["normal"] =
                {
                    regular     = "hiramaruprow4" ,
                    italic      = "hiramaruprow4" ,
                    bold        = "hiramaruprow4" ,
                    bolditalic  = "hiramaruprow4" ,
                } ,
        } ,
    ["hiraginomarugothicpron"] = -- Hiragino Maru Gothic ProN
        {
            ["normal"] =
                {
                    regular     = "hiramarupronw4" ,
                    italic      = "hiramarupronw4" ,
                    bold        = "hiramarupronw4" ,
                    bolditalic  = "hiramarupronw4" ,
                } ,
        } ,
    ["hiraginominchopro"] = -- Hiragino Mincho Pro
        {
            ["normal"] =
                {
                    regular     = "hiraminprow3" ,
                    italic      = "hiraminprow3" ,
                    bold        = "hiraminprow6" ,
                    bolditalic  = "hiraminprow6" ,
                } ,
        } ,
    ["hiraginominchopron"] = -- Hiragino Mincho ProN
        {
            ["normal"] =
                {
                    regular     = "hiraminpronw3" ,
                    italic      = "hiraminpronw3" ,
                    bold        = "hiraminpronw6" ,
                    bolditalic  = "hiraminpronw6" ,
                } ,
        } ,
    ["latinmodernmono"] = -- Latin Modern Mono
        {
            ["normal"] =
                {
                    regular     = "lmmono10regular"       ,
                    bold        = "lmmonolt10bold"        ,
                    italic      = "lmmono10italic"        ,
                    slanted     = "lmmono10italic"        ,
                    bolditalic  = "lmmonolt10boldoblique" ,
                    boldslanted = "lmmonolt10boldoblique" ,
                    caps        = "lmmonocaps10regular"   ,
                    slantedcaps = "lmmonocaps10oblique"   ,
                } ,
        } ,
    ["latinmodernroman"] = -- Latin Modern Roman
        {
            ["normal"] =
                {
                    regular     = "lmroman10regular"      ,
                    bold        = "lmroman10bold"         ,
                    italic      = "lmroman10italic"       ,
                    slanted     = "lmromanslant10regular" ,
                    bolditalic  = "lmroman10bolditalic"   ,
                    boldslanted = "lmromanslant10bold"    ,
                    caps        = "lmromancaps10regular"  ,
                    slantedcaps = "lmromancaps10oblique"  ,
                } ,
        } ,
    ["latinmodernsans"] = -- Latin Modern Sans
        {
            ["normal"] =
                {
                    regular     = "lmsans10regular"     ,
                    bold        = "lmsans10bold"        ,
                    italic      = "lmsans10oblique"     ,
                    slanted     = "lmsans10oblique"     ,
                    bolditalic  = "lmsans10boldoblique" ,
                    boldslanted = "lmsans10boldoblique" ,
                } ,
        } ,
}

function simplefonts.selectfont(font,name,extension,style,weight)
    local fontname = {}
    local truename = name
    local name     = lower(gsub(name,"[^a-zA-Z0-9]",""))
    if extension ~= "" then
        ext = find(extension,"*")
        if ext ~= nil then
            fontname = gsub(extension,"*",name)
        else
            fontname = extension
        end
        fontname = "name:" .. lower(gsub(fontname,"[^a-zA-Z0-9]",""))
    else
        if string.match(truename,"file:") then -- can't i check for 'file:' and 'name:' with one string.match?
            fontname = truename
        elseif string.match(truename,"name:") then
            fontname = truename
        elseif simplefonts.fontlist[name] then
            if simplefonts.fontlist[name][weight] then
                if simplefonts.fontlist[name][weight][style] then
                    fontname = simplefonts.fontlist[name][weight][style]
                else
                    fontname = simplefonts.fontlist[name][weight]["regular"]
                end
            elseif simplefonts.fontlist[name]["normal"] then
                if simplefonts.fontlist[name]["normal"][style] then
                    fontname = simplefonts.fontlist[name]["normal"][style]
                else
                    fontname = simplefonts.fontlist[name]["normal"]["regular"]
                end
            end
            fontname = "name:" .. fontname
        else
            -- use comma list
            for _, v in ipairs(simplefonts.extlist[weight][style]) do
                fontname = name .. v
                if global.fonts.names.exists(fontname) then
                    fontname = "name:" .. fontname
                    break
                else
                    --~ interfaces.showmessage("simplefonts","1",fontname) -- wrong place
                    fontname = "DefaultFont" -- no font is found
                end
            end
        end
    end
    --~ print(fontname)
    if fontname == "DefaultFont" then
        interfaces.showmessage("simplefonts","1",name)
    end
    texsprint(prtcatcodes,format("\\setvalue{\\????sf %s%s}{%s}",font,style,fontname))
end

function simplefonts.normalizefontname(name)
    local fontname = lower(gsub(name,"[^a-zA-Z0-9]","")) -- remove spaces and hyphens etc. from the user specified name
    texsprint(ctxcatcodes,fontname)
end

function simplefonts.parameter(key,value,list)
    local feature   = simplefonts.features  [key]
    local script    = simplefonts.scripts   [value]
    local language  = simplefonts.languages [value]
    if feature then
        texsprint(format("\\addvalue{%s}{%s=%s}",list,feature,value))
        --~ print("feature: " .. feature .. " = " .. value)
    else
        if key == "script" then
            if script then
                texsprint(format("\\addvalue{%s}{%s=%s}",list,key,script))
                --~ print("script: " script)
            else
                interfaces.showmessage("simplefonts","4",value)
            end
        elseif key == "language" then
            if language then
                texsprint(format("\\addvalue{%s}{%s=%s}",list,key,language))
                --~ print("language: " language)
            else
                interfaces.showmessage("simplefonts","5",value)
            end
        end
    end
end
