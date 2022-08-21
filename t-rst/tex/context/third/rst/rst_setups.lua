#!/usr/bin/env texlua
--------------------------------------------------------------------------------
--         FILE:  rst_setups.lua
--        USAGE:  called by rst_parser.lua
--  DESCRIPTION:  Complement to the reStructuredText parser
--       AUTHOR:  Philipp Gesang (Phg), <phg42.2a@gmail.com>
--      CHANGED:  2013-06-03 18:52:29+0200
--------------------------------------------------------------------------------
--

local optional_setups   = { }
thirddata.rst_setups    = optional_setups
local rst_directives    = thirddata.rst_directives
local rst_context       = thirddata.rst

local stringformat      = string.format
local stringstrip       = string.strip
local stringgsub        = string.gsub

function optional_setups.footnote_symbol ()
    local setup = [[
%---------------------------------------------------------------%
% Footnotes with symbol conversion                              %
%---------------------------------------------------------------%
\definenote[symbolnote][footnote]
\setupnote [symbolnote][way=bypage,numberconversion=set 2]
]]
    return setup
end

function optional_setups.footnotes ()
    local tf = rst_context.state.footnotes
    local fn = [[

%---------------------------------------------------------------%
% Footnotes                                                     %
%---------------------------------------------------------------%
]]
    local buffer = [[

%% %s
\startbuffer[%s]
%s\stopbuffer
]]
    
    for nf, note in next, tf.numbered do
        fn = fn .. stringformat(buffer, "Autonumbered footnote", "__footnote_number_"..nf, note)
    end
    for nf, note in next, tf.autolabel do
        fn = fn .. stringformat(buffer, "Labeled footnote", "__footnote_label_"..nf, note)
    end
    for nf, note in next, tf.symbol do
        fn = fn .. stringformat(buffer, "Symbol footnote", "__footnote_symbol_"..nf, note)
    end
    return fn
end

function optional_setups.references ()
    local refs  = rst_context.collected_references
    local crefs = rst_context.context_references
    local arefs = rst_context.anonymous_set
    
    local function urlescape (str)
        return str:gsub("#", "\\#")
    end

    local function resolve_indirect (r)
        if r and r:match(".*_$") then -- pointing elsewhere
            local look_me_up = r:match("^`?([^`]*)`?_$")
            local result = resolve_indirect (refs[look_me_up])
            if result then
                return result
            else
                if rst_context.structure_references[look_me_up] then
                    -- Internal link, no useURL etc.
                    return false
                end
            end
        end
        return r
    end

    local refsection = [[

%---------------------------------------------------------------%
% References                                                    %
%---------------------------------------------------------------%

]]
    local references = {}
    local ref_keys   = {}
    for ref, target in next, refs do
        ref_keys[#ref_keys+1] = [[__target_]] .. rst_context.whitespace_to_underscore(ref)
        target = resolve_indirect(target)
        if target ~= false then
            ref_text = ref
            if arefs[ref_text] then
                ref_text = rst_context.anonymous_links[tonumber(arefs[ref_text])]
            end
            references[#references+1] = stringformat([[
\useURL[__target_%s] [%s] []   [%s] ]], rst_context.whitespace_to_underscore(ref), urlescape(target), ref_text)
        end
    end
    refsection = refsection .. table.concat(references, "\n")
    -- this is needed in order to select the right reference command later
    refsection = refsection .. "\n\n" .. [[\def \RSTexternalreferences{]] .. table.concat(ref_keys, ",") .. [[}

% #1 target name, #2 link text
\def\RSTchoosegoto#1#2{%
  \rawdoifinsetelse{#1}{\RSTexternalreferences}%
    {\from[#1]}%
    {\goto{#2}[#1]}%
}
]]

    return refsection
end

function optional_setups.substitutions ()
    local directives = rst_directives
    local substitutions = [[

%---------------------------------------------------------------%
% Substitutions                                                 %
%---------------------------------------------------------------%
]]
    local rs = rst_context.substitutions
    for name, content in next, rs do
        local id, data = content.directive, content.data
        local directive = directives[id]
        if directive then
            substitutions = substitutions .. directive(name, data)
        else
            err(id .. " does not exist.")
        end
    end
    return substitutions
end

function optional_setups.directive ()
    --local dirstr = [[

--%---------------------------------------------------------------%
--% Directives                                                    %
--%---------------------------------------------------------------%
--]]
    --return dirstr
    return ""
end

function optional_setups.blockquote ()
    return [[

%---------------------------------------------------------------%
% Blockquotes                                                   %
%---------------------------------------------------------------%
\setupdelimitedtext  [blockquote][style={\tfx}] % awful placeholder
\definedelimitedtext[attribution][blockquote]
\setupdelimitedtext [attribution][style={\tfx\it}]
]]
end

function optional_setups.deflist ()
    return [[

%---------------------------------------------------------------%
% Definitionlist                                                %
%---------------------------------------------------------------%
\def\startRSTdefinitionlist{
  \bgroup
  \def      \RSTdeflistterm##1{{\bf ##1}}
  \def\RSTdeflistclassifier##1{\hbox to 1em{\it ##1}}
  \def\RSTdeflistdefinition##1{%
    \startnarrower[left]
    ##1%
    \stopnarrower}
  \def\RSTdeflistparagraph ##1{%
    \startparagraph{%
      \noindentation ##1
    \stopparagraph}
  }
}

\let\stopRSTdefinitionlist\egroup
]]
end

function optional_setups.lines ()
    return [[

%---------------------------------------------------------------%
% Lines environment (line blocks)                               %
%---------------------------------------------------------------%

\setuplines[%
  space=on,%
  before={\startlinecorrection\blank[small]},%
  after={\blank[small]\stoplinecorrection},%
]
]]
end

function optional_setups.breaks ()
    return [[

%---------------------------------------------------------------%
% Fancy transitions                                             %
%---------------------------------------------------------------%

% Get Wolfgang’s module at <https://bitbucket.org/wolfs/fancybreak>.
\usemodule[fancybreak]
\setupfancybreak[symbol=star]
]]
end

function optional_setups.fieldlist ()
    return [[

%---------------------------------------------------------------%
% Fieldlists                                                    %
%---------------------------------------------------------------%

\def\startRSTfieldlist{%
  \bgroup%
  \unexpanded\def\RSTfieldname##1{\bTR\bTC ##1\eTC}
  \unexpanded\def\RSTfieldbody##1{\bTC ##1\eTC\eTR}
%
  \setupTABLE[c][first] [background=color, backgroundcolor=grey, style=\bf]
  \setupTABLE[c][2]     [align=right]
  \setupTABLE[c][each]  [frame=off]
  \setupTABLE[r][each]  [frame=off]
  \bTABLE[split=yes,option=stretch]
  \bTABLEhead
  \bTR
   \bTH  Field       \eTH
   \bTH  Body        \eTH
  \eTR
  \eTABLEhead
  \bTABLEbody
}

\def\stopRSTfieldlist{%
  %\eTABLEbody % doesn't work, temporarily moved to rst_context.field_list()
  \eTABLE
  \egroup%
}
]]
end

function optional_setups.dbend ()
    -- There's just no reason for not providing this.
    optional_setups.dbend_done = true
    return [[
%---------------------------------------------------------------%
% Dangerous bend                                                %
%---------------------------------------------------------------%

\loadmapfile [manfnt.map]
\definefontsynonym [bends] [manfnt]

\def\GetSym#1{\getglyph{bends}{\char#1}}

\startsymbolset [Dangerous Bends]
    \definesymbol [dbend]       [\GetSym{127}]
    \definesymbol [lhdbend]     [\GetSym{126}]
    \definesymbol [lhdbend]     [\GetSym{0}]
\stopsymbolset

\setupsymbolset [Dangerous Bends]

]]
end

function optional_setups.caution ()
    local result = ""
    --if not optional_setups.dbend_done then
        --result = result .. optional_setups.dbend()
    --end
    return result .. [[
%---------------------------------------------------------------%
% Caution directive                                             %
%---------------------------------------------------------------%

\usemodule[lettrine]

\setbox0=\hbox{\symbol[dbend]}
\newskip\RSTbendskip
\RSTbendskip=\wd0
\advance\RSTbendskip by 1em % These two lines should add
\advance\RSTbendskip by 1pt % 13.4pt in mkiv and 13.14983pt in mkii
                            % to make the indent equal to the indent
                            % of the “danger” directive.
                            % (2*(width)dbend + (kern)1pt + 1em

\def\startRSTcaution{%
\startparagraph
\dontleavehmode\lettrine[Lines=2,Raise=.6,Findent=\RSTbendskip,Nindent=0pt]{\symbol[dbend]}{}%
}

\let\stopRSTcaution\stopparagraph

]]

end

function optional_setups.danger ()
    local result = ""
    --if not optional_setups.dbend_done then
        --result = result .. optional_setups.dbend()
    --end
    return result .. [[
%---------------------------------------------------------------%
% Danger directive                                              %
%---------------------------------------------------------------%

\usemodule[lettrine]

\def\startRSTdanger{%
\startparagraph
\lettrine[Lines=2,Raise=.6,Findent=1em,Nindent=0pt]{\symbol[dbend]\kern 1pt\symbol[dbend]}{}%
}

\let\stopRSTdanger\stopparagraph

]]

end

function optional_setups.citations ()
    local cit = [[
%---------------------------------------------------------------%
% Citations                                                     %
%---------------------------------------------------------------%
\setupbibtex[database=\jobname]
]]
    

    return cit
end

function optional_setups.citator ()
    local cit = [[
%---------------------------------------------------------------%
% Citator Options                                               %
%---------------------------------------------------------------%
\usemodule[citator]
\loadbibdb{\jobname.bib}
\setupcitator[sortmode=authoryear]
\setupcite[mainmode=authoryear]

\startbuffer[bibliography]
\chapter{References}
\setupbodyfont[small]
\bibbykey{shorthand}{all}{author}
\stopbuffer

\prependtoks \getbuffer[bibliography] \to \everystoptext
]]

    return cit
end

function optional_setups.image ()
    local image = [[

%---------------------------------------------------------------%
% images                                                        %
%---------------------------------------------------------------%
\setupexternalfigure[location={local,global,default}]

]]
    return image
end

return optional_setups

-- vim:ft=lua:sw=4:ts=4:expandtab:tw=80
