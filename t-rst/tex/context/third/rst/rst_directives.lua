#!/usr/bin/env texlua
--------------------------------------------------------------------------------
--         FILE:  rst_directives.lua
--        USAGE:  called by rst_parser.lua
--  DESCRIPTION:  Complement to the reStructuredText parser
--       AUTHOR:  Philipp Gesang (Phg), <phg42.2a@gmail.com>
--      CHANGED:  2013-06-03 18:52:35+0200
--------------------------------------------------------------------------------
--

local helpers = helpers or thirddata and thirddata.rst_helpers

--------------------------------------------------------------------------------
-- Directives for use with |substitutions|
--------------------------------------------------------------------------------

local rst_directives     = { }
thirddata.rst_directives = rst_directives
local rst_context        = thirddata.rst

local lpegmatch      = lpeg.match
local stringformat   = string.format
local stringstrip    = string.strip
local tableconcat    = table.concat
local tableflattened = table.flattened
local type           = type

--rst_directives.anonymous     = 0
rst_directives.images        = {}
rst_directives.images.done   = {}
rst_directives.images.values = {}


rst_directives.images.keys = {
    ["width"]   = "width",
    ["size"]    = "width",
    ["caption"] = "caption",
    ["alt"]     = "caption",
    ["scale"]   = "scale",
}

rst_directives.images.values.scale = function (orig)
    -- http://wiki.contextgarden.net/Reference/en/useexternalfigure
    -- scale=1000 is original size; to get 72%, use scale=720.
    return tonumber(orig) * 1000
end

rst_directives.images.values.width = {
    ["fit"]    = "\\hsize",
    ["hsize"]  = "\\hsize",
    ["broad"]  = "\\hsize",
    ["normal"] = "local",
    ["normal"] = "local",
}

-- we won't allow passing arbitrary setups to context
local permitted_setups = {
    "width",
    "scale"
}

local function img_setup (properties)
    local result = ""
    for _, prop in next, permitted_setups do
        if properties[prop] then
            result = result .. prop .. "=" .. properties[prop] .. ","
        end
    end
    if result ~= "" then
        result = "[" .. result .. "]"
    end
    return result
end

local collect_image_properties = function (data)
    local image_directives  = rst_directives.images
    local p_keyval          = helpers.patterns.colon_keyval
    local properties        = { }

    data = tableflattened(data)
    for i=1, #data do
        local str = stringstrip(data[i])
        local key, val = lpegmatch(p_keyval, str)
        if key and val then
            key = image_directives.keys[key] -- sanitize key expression
            local valtype = type(image_directives.values[key])
            if valtype == "table" then
                val = image_directives.values[key][val]
            elseif valtype == "function" then
                val = image_directives.values[key](val)
            end
            properties[key] = val
        end
    end
    return properties
end

--- ordinary image directives are converted to floats

local float_image = function (data)
    rst_context.addsetups "image"
    local inline_parser = rst_context.inline_parser
    local properties
    local anon          = false
    local rdi           = rst_directives.images
    local hp            = helpers.patterns
    local caption       = ""
    local name          = ""

    if data.name then
        name = stringstrip(data.name)
        data.name   = nil
    else
        if next(data[1]) then
            name = data[1][1]
        end
    end

    --rd.anonymous = rd.anonymous + 1
    --anon = true -- indicates a nameless picture
    --name = "anonymous" .. rd.anonymous

    properties = collect_image_properties(data)

    if properties.caption then
        caption = lpegmatch(inline_parser, properties.caption)
        caption = rst_context.escape(caption)
    end

    properties.setup = img_setup(properties) or ""
    local img = ""
--    local images_done = rdi.done
--    if not anon then -- TODO: implement?
--        if not images_done[name] then
--            img = img .. stringformat([[
--
--\useexternalfigure[%s][%s][]%%
--]], name, data)
--        images_done[name] = true
--        end
--        img = img .. stringformat([[
--\def\RSTsubstitution%s{%%
--  \placefigure[here]{%s}{\externalfigure[%s]%s}%%
--}
--]], name, rst_context.escape(lpegmatch(inline_parser, properties.caption)), name, properties.setup)
--    else -- image won't be referenced but used instantly
    img = stringformat(
        "\n\\placefigure[here]{%s}{\\externalfigure[%s]%s}",
        caption,
        name,
        properties.setup)
--    end
    return img
end

--- inline substitutions are converted to bare external figures
local inline_image = function (name, data)
    rst_context.addsetups "image"
    local filename  = data.first
    local p_keyval  = helpers.patterns.colon_keyval
    local properties

    if not filename then --- garbage, ignore
        return ""
    end
    data.first = nil
    filename   = stringstrip(filename)
    properties = collect_image_properties(data)

    local scheme  = "\n\\def\\RSTsubstitution%s{\n  \\externalfigure[%s]%s%%\n}\n"
    local options = ""
    if next(properties) then
        local tmp = { }
        tmp[#tmp+1] = "["
        for key, value in next, properties do
            tmp[#tmp+1] = key
            tmp[#tmp+1] = "={"
            tmp[#tmp+1] = rst_context.escape(value)
            tmp[#tmp+1] = "},"
        end
        tmp[#tmp+1] = "]"
        options = tableconcat(tmp)
    end
    return stringformat(scheme, name, filename, options)
end

rst_directives.image        = float_image
rst_directives.inline_image = inline_image

rst_directives.caution = function(data)
    local inline_parser = rst_context.inline_parser
    rst_context.addsetups("dbend")
    rst_context.addsetups("caution")
    local text = { }
    for i=1, #data do -- paragraphs
        local current = tableconcat(data[i], "\n")
        current = lpegmatch(inline_parser, current)
        current = rst_context.escape(current)
        text[i] = current
    end
    return stringformat([[
\startRSTcaution
%s
\stopRSTcaution
]], tableconcat(text, "\n\n"))
end

rst_directives.danger = function(data)
    local inline_parser = rst_context.inline_parser
    rst_context.addsetups("dbend")
    rst_context.addsetups("danger")
    local text = { }
    for i=1, #data do -- paragraphs
        local current = tableconcat(data[i], "\n")
        current = lpegmatch(inline_parser, current)
        current = rst_context.escape(current)
        text[i] = current
    end
    return stringformat([[
\startRSTdanger
%s
\stopRSTdanger
]], tableconcat(text, "\n\n"))
end

-- http://docutils.sourceforge.net/docs/ref/rst/directives.html
rst_directives.DANGER = function(data)
    local inline_parser = rst_context.inline_parser
    local text = { }
    for i=1, #data do -- paragraphs
        local current = tableconcat(data[i], "\n")
        current = lpegmatch(inline_parser, current)
        current = rst_context.escape(current)
        text[i] = current
    end
    return stringformat([[

%% The Rabbit of Caerbannog
\startlinecorrection
\blank[force,big]
\framed[frame=on,
        corner=round,
        rulethickness=5pt,
        align=middle,
        width=\hsize,
        frameoffset=.5em,
        backgroundoffset=1em,
        background=color,
        backgroundcolor=red,
        foreground=color,
        foregroundcolor=black]{%%
  \language[en-gb]\tfb\bf
  Follow only if ye be men of valour, for the entrance to this cave is guarded
  by a creature so foul, so cruel that no man yet has fought with it and lived.
  Bones of full fifty men lie strewn about its lair. So, brave knights, if you
  do doubt your courage or your strength, come no further, for death awaits you
  all with nasty, big, pointy teeth.%%
  \blank[force,big]
  %s%%
}
\blank[force,big]
\stoplinecorrection
]], tableconcat(text, "\n\n"))
end

rst_directives.mp = function(name, data)
    local mpcode = stringformat([[
\startreusableMPgraphic{%s}
%s
\stopreusableMPgraphic
]], name, data)
    mpcode = mpcode .. stringformat([[
\def\RSTsubstitution%s{%%
  \reuseMPgraphic{%s}%%
}
]], name, name)
    return mpcode
end

--- There’s an issue with buffers leaving trailing spaces due to their
--- implementation.
--- http://archive.contextgarden.net/message/20111108.175913.1d994624.en.html
rst_directives.ctx = function(name, data)
    local ctx = stringformat([[

\startbuffer[%s]
%s\stopbuffer
\def\RSTsubstitution%s{%%
  \getbuffer[%s]\removeunwantedspaces%%
}
]], name, data, name, name)
    return ctx
end

rst_directives.lua = function(name, data)
    local luacode = stringformat([[

\startbuffer[%s]
\startluacode
%s
\stopluacode
\stopbuffer
\def\RSTsubstitution%s{%%
  \getbuffer[%s]\removeunwantedspaces%%
}
]], name, data, name, name)
    return luacode
end

--------------------------------------------------------------------------------
--- Experimental math directive
--------------------------------------------------------------------------------

rst_directives.math = function (name, data)
    data = data or name
    local formula
    if type(data) == "table" then
        local last, i = #data, 1
        while i <= last do
            local line = stringstrip(data[i])
            if line and line ~= "" then
                formula = formula and formula .. " " .. line or line
            end
            i = i + 1
        end
    end
    return stringformat([[
\startformula
%s
\stopformula
]], formula)
end

--------------------------------------------------------------------------------
--- End math directive
--------------------------------------------------------------------------------

rst_directives.replace = function(name, data)
    return stringformat([[

\def\RSTsubstitution%s{%s}
]], name, data)
end

--------------------------------------------------------------------------------
--- Containers.
--------------------------------------------------------------------------------

--- *data*:
---     { [1]  -> directive name,
---       [>1] -> paragraphs }

rst_directives.container = function(data)
    local inline_parser = rst_context.inline_parser
    local tmp = { }
    for i=1, #data do -- paragraphs
        local current = tableconcat(data[i], "\n")
        current = lpegmatch(inline_parser, current)
        current = rst_context.escape(current)
        tmp[i] = current
    end
    local content = tableconcat(tmp, "\n\n")
    local name = data.name
    if name and name ~= "" then
        name = stringstrip(data.name)
        return stringformat([[
\start[%s]%%
%s%%
\stop
]], name, content)
    else
        return stringformat([[
\begingroup%%
%s%%
\endgroup
]], content)
    end
end

-- vim:ft=lua:sw=4:ts=4:expandtab

