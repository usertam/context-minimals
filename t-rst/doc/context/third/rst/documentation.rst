========================
Features Not Implemented
========================
Nesting
*******
Proper nesting. So far only lists support real nested structures.
There's no way you could have real paragraphs or bulleted lists
inside table cells. The problem is that with true nesting some
jobs like the dissection of tables would have to be moved from
the formatter to the parser. If you feel you need thoroughly
nested structures -- e.g. grid tables in footnotes or bullet lists
inside simple tables inside enumerations inside quotations inside
footnotes -- you should consider including |CONTEXT| code as
substitution directives. (OTOH docutils' new and old LaTeX
formatter seems to have problems with tables in footnotes as
well. Not to mention its preference for enclosing random nested
structures in ``quote``-environments.)

Should you find yourself in desparate need of tables or whatever
structures inside footnotes then I might agree to find a solution
if you ask.

Hyperlinks
**********
The hyperlink implementation should be fine in general use if you
avoid certain situations.

- Never ever call your hyperlink targets ``anon_#``, where ``#``
  stands for  any integer. Just don't do it, OK? Great.

- Referencing a structure element like a section heading by means
  of an *empty link block* does work. However, if the element in
  question requests a page break (e.g. the vanilla
  ``\chapter{#1}`` command), the reference will link to the
  previous page instead and become useless. You can avoid this
  behaviour by referencing the section directly or by targetting
  the first paragraph in the section instead.

- Link chaining does not work with internal references. This is
  considered a low-priority bug and will be addressed during the
  next big hyperlink overhaul.

=====
Usage
=====
Invocation from the Command Line
********************************
|rstcontext| is integrated into the ``mtxrun`` command as a
script, which relies, naturally, on the Lua interpreter of
|LUATEX|. Therefore, |rstcontext| might not run at all on other
Lua installations, at least not without modification of the
source. Fortunately, every |CONTEXT| user is equipped with
|LUATEX| nowadays so this dependency should be trivial.

To generate |CONTEXT| code from a |rst| document named
``infile.rst``, call ``mtxrun``: ::

     $mtxrun --script rst --if=infile.rst --of=outfile.tex

You should now have a file ``outfile.tex`` that is ready to be
run by |CONTEXT|. With some exceptions the generated code is
downward compatible with MkII, thus it does not matter for a
start whether you decide to test it with ``texexec`` or
``context``.

The resulting |TEX| file has rather a basic layout, if at all.
This is intentional as you are expected to include it in a
document after specifying your own setups.
An example for prepended setups can be found in the environment
for this manual (``mod/doc/context/third/rst/manual.tex``).

.. caution::
    The output of |rstcontext| automatically inserts necessary
    setups for the components found in the input. Therefore, the
    ``\starttext`` and ``\stoptext`` commands are part of the
    output and may not be specified in your setups file.
    For now you have to use the |CONTEXT| command 
    ``\appendtoks <token> \to \starttext`` to add content like
    title pages and indices to the result. This mechanism works
    reliable as long as you have an eye on the order in which the
    tokens are given. Again, have a look at ``manual.tex`` to get
    an impression how useful this can be. User hooks for these
    and other common constructs are thought of but have yet to be
    implemented.

To build the documentation, first create a temporary directory
somewhere safe. Then copy or symlink the Lua files from
``mod/tex/context/third/rst/`` and the manual source there as
well: ::

    $mkdir tmp; cd tmp
    $ln -s ../mod/doc/context/third/rst/documentation.rst .

Now run |rstcontext| on the main documentation file as follows: ::

    $mtxrun --script rst --if=documentation.rst --of=doc.tex

Now run |CONTEXT| on the layout file: ::

    $context ../mod/doc/context/third/rst/manual.tex

This will include the generated code after a couple of setups --
voilà, you have successfully built ``manual.pdf``. (Note that the
commands you have to issue in each of the steps vary across
different OS. In the literal form the example might only work on
Linux or POSIX compliant systems.)

Module
******

A provisional module for MkIV is included (``t-rst.mkiv``).
Actually, the converter was thought of as a module for direct
rendering of |rst| input initially, but certain objections
diverted me from this path.

-   *Typography*. It’s all about the details. No matter how good your
    converter is, auto-generated code will not reach |TEX|’s
    omnipotence and flexibility. |rstcontext| is a tool to
    generate raw material for your typesetting job, not a
    typesetting system in itself.

-   *Testing*. Never underestimate the insights gained from reading
    the resulting |CONTEXT| file. Quite some effort has been
    undertaken to make it human-readable, especially the setups.

-   *MkII*. I’m not an MkII user at all, and compatibility with
    it is not a primary objective for |rstcontext|.
    However, an effort has been made to keep the output essentially
    MkII clean. Do not expect Unicode to work without
    precautions.

During the development readability of the generated code was
alway one of the main goals of |rstcontext|. Quite some computing
effort is made to reflow even simple things as paragraphs into
a shape understandable by more than only the |TEX| machine.
If you should at one point decide that your project is
ripe for the typographical finish and you want to add local
changes in form of |TEX| code only, you should be able to use the
output of |rstcontext| as starting point.

However, using the module may have advantages when testing. There
is a usage example in ``moduletest.tex``, introducing the macro
``\\typesetRSTfile``.  Another example in ``hybridtest.tex``
demonstrates the |CONTEXT| command ``\\RST`` as well as the
corresponding environment.

To install the module simply copy the files into your local |TEX|
tree, i.e. if the minimals reside in ``~/context/``, you would
issue the following line: :: 

    $cp -r ./mod/* ~/context/tex/texmf-local/

Then rebuild the filename database running ``context
--generate``. The module should be ready for use now.

RST projects
************

In addition to the simple command ``\\typesetRSTfile`` the module
also provides means for handling multiple |rst| input files. This
is achieved by so-called *inclusions*. An inclusion has to be
defined first, using the macro ``\\defineRSTinclusion``, which
receives up to three arguments in brackets. The first one
specifies the *identifier* by which the inclusion will be
referred to afterwards (cf. |CONTEXT|’s ``\\useURL`` command). The
second argument, which is mandatory as well, takes the file to be
associated with an inclusion. Finally, optional setups can be
passed to the parser via the third argument (cf. the section on
`Tabs`_). E.g.: ::

    \usemodule[rst]
    \defineRSTinclusion [first][inc-first.rst]
    \defineRSTinclusion[second][inc-second.rst][expandtab=true,shiftwidth=8]
    \defineRSTinclusion [third][inc-third.rst]

Those inclusions are afterwards accessible *within* the
``\\[start|stop]project`` environment, and can be dereferenced by
``\\RSTinclusion``, which takes the identifier as a single
argument in brackets: ::

    \startRSTproject
    \RSTinclusion [first]
    \RSTinclusion[second]
    \RSTinclusion [third]
    \stopRSTproject

Within the project environment, |rstcontext| allows for arbitrary
|CONTEXT| markup.

=========
Examples
=========

|rstcontext| was developed for the largest part by going through
the |rst| specification_ step by step and tested against the
examples given both in the spec and in the `quick reference`_.
Therefore you should refer to those examples first (and drop me a
note immediately if any of them stopped working).
All kinds of text blocks and inline markup have been implemented
with the exception of anything mentioned in the section on
`Features Not Implemented`_.
Some of them that I have not found a real-world usage for (such
as *definition lists*) do not yet have a presentable output --
there is room for improvements that should be supplied by
somebody who actually uses those features.

.. _specification: http://docutils.sourceforge.net/docs/ref/rst/restructuredtext.html
.. _quick reference: http://docutils.sourceforge.net/docs/user/rst/quickref.html

Block Quotes
************

The *block quote* syntax is fully supported, including
attributions. For instance, the next snippet: ::

    Some people have made the mistake of seeing Shunt’s work as a
    load of rubbish about railway timetables, but clever people
    like me, who talk loudly in restaurants, see this as a
    deliberate ambiguity, a plea for understanding in a
    mechanized world.

    --- Gavin Millarrrrrrrrrr on Neville Shunt

gets you a neatly indented quotation, typeset in a slightly
smaller font magnitude.

    Some people have made the mistake of seeing Shunt’s work as a
    load of rubbish about railway timetables, but clever people
    like me, who talk loudly in restaurants, see this as a
    deliberate ambiguity, a plea for understanding in a
    mechanized world.

    --- Gavin Millarrrrrrrrrr on Neville Shunt

Don’t forget proper indentation.

Numbered List
*************

Save for nesting lists are fully implemented in |rstcontext|.
The following code typesets a triple-nested list with different
kinds of bulleting / numbering: ::

    i.   First order list, first entry.

    ii.  First order list, second entry.

    iii. First order list, third entry.

        -   Second order list, first entry.

            #.  Third order list, first entry.
            #.  Third order list, second entry.
            #.  Third order list, third entry.
                Real nesting rules!

        -   Second order list, second entry.

    iv.  First order list, fourth entry.

    v.   First order list, fifth entry.

The result looks like this:

i.   First order list, first entry.

ii.  First order list, second entry.

iii. First order list, third entry.

    -   Second order list, first entry.

        #.  Third order list, first entry.
        #.  Third order list, second entry.
        #.  Third order list, third entry.
            Real nesting rules!

    -   Second order list, second entry.

iv.  First order list, fourth entry.

v.   First order list, fifth entry.

.. caution:: 
    Don’t forget the blank lines between list items.

Line Blocks
***********

Line blocks are a convenient environment for parts of the text
that need to preserve line breaks and indentation. This makes it
the first choice for most kinds of poems: ::

    | When does a dream begin? 
    |   Does it start with a goodnight kiss? 
    |       Is it conceived or simply achieved?
    | When does a dream begin? 
    |
    | When does a dream begin? 
    |   Is it born in a moment of bliss? 
    |       Or is it begun when two hearts are one?
    | When does a dream exist? 
    |
    | The vision of you appears somehow 
        Impossible to resist 
    | But I'm not imagining seeing you 
        For who could have dreamed of this? 
    |
    | When does a dream begin? 
    |   When reality is dismissed? 
    |       Or does it commence when we lose all pretence?
    | When does a dream begin?

Indentation, continued lines, etc. should work out without
problems:

| When does a dream begin? 
|   Does it start with a goodnight kiss? 
|       Is it conceived or simply achieved?
| When does a dream begin? 
|
| When does a dream begin? 
|   Is it born in a moment of bliss? 
|       Or is it begun when two hearts are one?
| When does a dream exist? 
|
| The vision of you appears somehow 
      Impossible to resist 
| But I'm not imagining seeing you 
      For who could have dreamed of this? 
|
| When does a dream begin? 
|   When reality is dismissed? 
|       Or does it commence when we lose all pretence?
| When does a dream begin?


==========
Directives
==========
Admonitions
************
The following admonition directives have been implemented:

Caution
-------
The *caution* directive results in the text being prefixed by one
“dangerous bend” symbol in order to resemble the “wizards only”
passages of the TeXbook.
For example, the directive: ::

    .. caution:: White mice do worse in experiments than grey mice.

will result in the following:

.. caution:: White mice do worse in experiments than grey mice.

Danger
------
Similar to the *caution* directive, the *danger* directive
prefixes the given text with two “dangerous bends” giving it the
look of Knuths’s “esoteric” annotations.

.. danger:: Be nice to the parser: 
    Don’t forget to align paragraphs that end a literal
    block!


Images
******
Including pictures is easy using the *image* directive: simply
supply it the name of the image file as in ``.. image:: cow``.
If the format is supported by |CONTEXT| the suffix can be
neglected.

The placement of images can be controlled via a set of optional
arguments, each of which has to be specified on single line in
``key: value`` style: ::

    .. image:: cow
        width: hsize
        caption: A generic Dutch cow.

This will place your image somewhere close to the spot where you
defined it. (The placement parameter to ``placefigure`` will be
set to ``here`` by default.)

.. image:: cow
    cow.pdf
    width: hsize
    alt: A generic Dutch cow (*bos primigenius taurus*).

The supported parameters are ``width``
(alias: ``size``), ``caption`` and ``scale``.
The *width* parameter accepts the values ``hsize`` 
(alias: ``fit``, ``broad``) or ``normal``.
Alternatively, the *scale* parameter allows for arbitrary
manipulation of the desired magnification; it defaults to ``1``
(unscaled).
The value passed as *caption* parameter will be used in as the
caption text of the image.

.. |CONTEXT| ctx:: \CONTEXT
.. |TEX| ctx:: \TeX
.. |PDFTEX| ctx:: \PDFTEX
.. |LUATEX| ctx:: \LUATEX
.. |rstcontext| ctx:: \bgroup\em rst\egroup\kern.5pt\CONTEXT
.. |rst| ctx:: \bgroup\rm re\egroup\bgroup\ss Structured\egroup\bgroup\rm Text\egroup
.. |LATEX| ctx:: \LATEX

.. _outline: http://docutils.sourceforge.net/docs/ref/rst/restructuredtext.html
.. _docutils: http://docutils.sourceforge.net/
.. _Pandoc: http://johnmacfarlane.net/pandoc/

Containers
**********

Upon request |rstcontext| now supports another kind of
directive, namely containers_.
Due to their being defined explicitly in terms of HTML,
*containers* lack a corresponding construct in |CONTEXT| (or
|TEX| for that matter).
Some parts of |CONTEXT| (e. g. ``\\framed``) come quite close with
respect to functionality as well as generality.
However, none of the candidates alone covers the entire spectrum
of functionality that containers_ are supposed to.
For that reason the implementation leaves them essentially
undefined.

If an explicit name is specified, then the ``container``
directive maps to the environment of that name.
Anonymous containers are interpreted as a |TEX| group.
Any text block inside the element is treated as ordinary
paragraph.
In below example the content will be handled as if between
``\\startxyzzy`` and ``\\stopxyzzy``, where it is up to the user to
define the *xyzzy* environment::

    This is a paragraph.

    .. container:: xyzzy

        whatever

        foo **bar** baz

    This is another paragraph.

The middle part translates to |CONTEXT| as follows::

    \start[xyzzy]%
    whatever

    foo {\sc bar} baz
    \stop

Note that the ``\\start[foo]``/``\\stop``-environment is equivalent
to ``\\startfoo``/``\\stopfoo``, except that the environment
doesn’t actually need to be defined.

.. caution::
    Support for the *container* directive is considered
    experimental.
    Suggestions for improving or extending the current
    implementation are always welcome.

.. _containers: http://docutils.sourceforge.net/docs/ref/rst/directives.html#container

=======================
Substitution Directives
=======================

There are substitution directives for simple *replacing* and
for insertion of |LUATEX|’s three languages: |mp|, Lua and,
of course, |TEX|.

.. |mp| replace:: \METAPOST

Ordinary text replacement is done via the ``replace``
substitution directive. E.g. in the main text you consistently
use ``|replaceme|`` and have all its occurences substituted by
``I wasn’t in the mood to write out this long sentence.``
like in the next snippet:

::

    .. |replaceme| replace::
        I wasn’t in the mood to write out this long sentence.

The code insertions work similarly. You have to specify some
phrase that gets substituted by the code you supply.
E.g. this document accesses the fancy logos predefined in the
|CONTEXT| core via substitutions: ::
    
    .. |CONTEXT| ctx:: \CONTEXT
    .. |LUATEX| ctx:: \LUATEX

Etc. pp. The respective directive names are ``ctx``, ``mp`` and
``lua``. In order to get a |circle| drawn on spot, you would
define a Metapost substitution:

::

    .. |circle| mp::
        fill fullcircle scaled(8) withcolor blue;

================
Special Features
================
Text Roles
**********

The default *role* for interpreted text is *emphasis*.

The role marker provides explicit access to formatting commands.
The formatting routine for inline literals can be called with the
role marker :literal:`literal`, strong emphasis likewise is
achieved via the role marker :literal:`strong_emphasis`.

Other roles that lack an equivalent among inline markup are
``bold``, :ss:`ss` (alias :literal:`sans_serif`),
``uppercase``, ``lowercase`` and colors.
Color roles begin with the string ``color_`` (the underscore is
compulsive), followed by either the string ``rgb_`` or a 
`valid color name`__.
An rgb vector is specified in decimal.
Its values can be separated by either dashes or underscores.
Thus, ``color_rgb_.3_.5_.8`` is a valid rgb expression, as is
``color_rgb_0-1-0``.
Unforturnately, the colon character ``:`` has to be escaped in
color expressions, e.g. ``color_gray\:5``.

__ http://wiki.contextgarden.net/Colors#Using_predefined_colors:_.5Csetupcolor

For example, to give Mr. Neville Shunt’s work an apt
typographic representation you can use these roles instead of
the standard inline markup: ::

    :color_rgb_.9_.2_.7:`Chuff`, chuff, :literal:`chuffwoooooch`,
    woooooch! Sssssssss, sssssssss!  :uppercase:`Diddledum`,
    `diddledum`, diddlealum.  :literal:`Toot`, toot. The train
    :bold:`now` standing :color_gray\:5:`at` platform :ss:`eight,
    tch`, tch, :color_rgb_0-1-0:`tch`,
    :color_rgb_.5-.6-.2:`diddledum`, diddledum.
    :lowercase:`Chuffff`, :strong_emphasis:`chuffffiTff`
    eeeeeeeeeaaaaaaaaa :color_red:`Vooooommmmm`.

which yields when passed through |rstcontext|:

:color_rgb_.9_.2_.7:`Chuff`, chuff, :literal:`chuffwoooooch`,
woooooch! Sssssssss, sssssssss!  :uppercase:`Diddledum`,
`diddledum`, diddlealum.  :literal:`Toot`, toot. The train
:bold:`now` standing :color_gray\:5:`at` platform :ss:`eight,
tch`, tch, :color_rgb_0-1-0:`tch`,
:color_rgb_.5-.6-.2:`diddledum`, diddledum. :lowercase:`Chuffff`,
:strong_emphasis:`chuffffiTff` eeeeeeeeeaaaaaaaaa
:color_red:`Vooooommmmm`.

**************************
Bibliography and Citations
**************************

.. caution::
    Not much for now concerning the usage of Taco’s bib system.
    It’s just that I use my own bibliography system and never
    became sufficiently familiar with the standard |CONTEXT|
    approach.  *If you feel that the current support should be
    improved then feel free to contact me!* I will need somebody
    for testing.

When |rstcontext| first encounters a citation (``[texbook]_``) it
automatically looks up a bibliography in the working directory by
the name of ``\jobname``. E.g. with a main file ``manual.tex``
bibtex will use the database called ``manual.bib``.  Symlinking
your bibliography file in the local tree should suffice and you
can keep whatever directory structure you prefer.  (Speaking for
myself, bib data usually resides in its own subdirectory, so I’d
use symlinks, too.)

****
Tabs
****
The |rst| specification requests that tabs (ASCII no 9) be
treated as spaces_. Converting your tabs to spaces might be a
good preparation for an |rstcontext| run. However, as of version
123 |rstcontext| comes with built-in tab expansion. It can be
enabled by supplying an optional argument to the
``typesetRSTfile`` command: ::

    \usemodule[rst]
    \typesetRSTfile[expandtab=true,shiftwidth=4]{myfile.rst}

The argument ``expandtab`` triggers a prepocessing step which
expands all tabulation characters (``\t`` and ``\v``) into the
correct amount of spaces. Optionally, the tab stop distance can
be configured using the ``shiftwidth`` parameter, which defaults
to 4.

.. _spaces: http://docutils.sourceforge.net/docs/ref/rst/restructuredtext.html#whitespace

===================
About this software
===================

The docutils_ provide means to translate the extra-convenient
markup language |rst| into various formats like PDF, HTML and
|LATEX|, unfortunately omitting the One True Macro System:
|CONTEXT|.

As far as I am aware of it, there is some support for |rst| in
Pandoc_ but as it relies on a rather large set of dependencies it
proved very difficult (too difficult for me) to install on my
favourite distribution.
From the `interactive demo`__ I gather that support for |rst|’s
language features is not very extensive and the result did not
even come with proper setups.
Additionally, it’s written in a language I am not familiar with
and that does not make use of one the most awesome features of
all the the extended capabilities |LUATEX| provides: the Lua
interpreter.

For quite some time I was thinking about how to implement an
|rst| parser in |LUATEX|, until some discussion__ emerged on the
|CONTEXT| mailing list that indicates a broader interest in
convenient markup languages across the community.
As the alternatives mentioned above don’t meet the expectations
of a normal |CONTEXT| user, the initial step to write
|rstcontext| was done.
Handling most of the corner cases and usability features of |rst|
proved in the end not nearly as easy as I imagined.

__ http://johnmacfarlane.net/pandoc/try
__ http://archive.contextgarden.net/message/20100814.051917.28caafcd.en.html

.. caution::
    |rstcontext| is experimental software and neither feature
    complete nor thoroughly commented. Keep this in mind before you
    start using it. Anything might still be subject to change, so
    expect breakage *in case you start relying on exceptional
    behaviour* (read: bugs) that does not conform to the |rst|
    specification. Consider filing a bug report instead and wait for
    me (the maintainer) to fix it, because regardless of how much
    testing I do myself I alway run into the weirdest issues only 
    during the actual deployment of the software. Thus, if you notice
    that |rstcontext| does not adhere to the outline_ of |rst|
    according to the Docutils documentation, very likely you have
    discovered a corner case I was not aware of.

.. |circle| mp::
    fill fullcircle scaled(8) withcolor blue;


=======
License
=======

::

    Copyright 2010-2014 Philipp Gesang. All rights reserved.

    Redistribution and use in source and binary forms, with or
    without modification, are permitted provided that the
    following conditions are met:

        1. Redistributions of source code must retain the above
           copyright notice, this list of conditions and the
           following disclaimer.

        2. Redistributions in binary form must reproduce the
           above copyright notice, this list of conditions and
           the following disclaimer in the documentation and/or
           other materials provided with the distribution.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER ``AS IS''
    AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
    FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
    SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
    DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
    CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
    PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
    DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
    AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
    ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
    ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


.. vim:tw=65
