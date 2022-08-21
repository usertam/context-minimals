# context-simpleslides

SimpleSlides presentation module for ConTeXt<br>
by Aditya Mahajan and Thomas A. Schmitz


## Introduction

This module is meant to facilitate writing presentations in ConTeXt. It
provides a consistent interface and macros; there are different styles which
give different output. The module has been written for projector-based
presentations, so elements which are typical for screen presentations (such
as interactive hyperlinks or tables of contents) are not included.
The module is meant for an academic environment, specifically in the humanities.
Hence, it has the following characteristics:

* The look is rather sober. In academia, presentations are not meant to showcase fancy TeX effects; nothing should divert the audience’s attention from the content.
* The module is written for slides which exhibit text and/or images. From my own experience with TeX-based presentations, I have provided a setup for horizontal (landscape) pictures and for vertical (portrait) pictures, which are accompanied by an area for explanatory text.
* A simple switch in the module setup command will produce different output.
* It is easy to customize the module or to add more styles.

The macros are commented rather extensively to give users (especially users
relatively new to ConTeXt) the chance to understand the mechanisms and
create their own styles. Of course, I did not invent this code on my own. My
thanks are due, as always, to Hans Hagen, whose presentation modules in the
ConTeXt core have been a wonderful source of inspiration, to Mojca
Miklavec, who provided help with Metapost, and to Aditya Mahajan, who helped
tremendously in cleaning up the code and making the user interface more
consistent.

Thomas A. Schmitz

## Installation

The directories of this repository belong in one of the `texmf` trees,
e.g. `texmf-local`, `texmf-project` or `texmf-modules`.

It makes sense to clone it as `t-simpleslides` and merge it with the other modules,
as outlined on the [wiki](https://wiki.contextgarden.net/Modules#ConTeXt_LMTX).

Afterwards run `mtxrun --generate` to refresh the file database.

To update, run `git pull` and `mtxrun --generate` again.

## Example

```
\usemodule[simpleslides][
    style=BigNumber,
    % available options depend on the style
    color=red,
    %alternative=square, % "Framed" only
    font=Gothic,
]

\setupTitle
  [title={Presentation Title},
   author={F.~Author, S.~Another},
   date={Date / Occasion}]

\setupexternalfigures[location={local,global,default}]

\starttext

\placeTitle


\SlideTitle{Make Titles Informative}

\startitemize
  \item Use bullets points when appropriate.
  \item Use pictures when possible
  \item Do not put too much information on one slide
\stopitemize

\IncludePicture
  [horizontal]
  [cow] % Name of the image
  {A Dutch Cow} % Title of the slide

\IncludePicture
  [horizontal]
  [cow] % Name of the image
  [highlight=yes,
   grid=yes]
  {A Dutch Cow with a grid} % Title of the slide

\IncludePicture
  [horizontal]
  [cow] % Name of the image
  [highlight=yes,
   grid=yes,
   steps=5, % Each grid block is broken into these many parts.
   subgrid=yes]
  {A Dutch Cow with a fine grid} % Title of the slide

\IncludePicture
  [horizontal]
  [cow] % Name of the image
  [highlight=yes,
   grid=yes,
   subgrid=yes,
   alternative=circle,
   color=orange,
   x=1.4,
   y=8.2,
   xscale=1.5,
   shadow=bottomleft]
  {The head of a dutch cow}


\IncludePicture
  [horizontal]
  [cow] % Name of the image
  [highlight=yes,
   grid=no,
   subgrid=no,
   alternative=circle,
   color=orange,
   x=1.4,
   y=8.2,
   xscale=1.5,
   shadow=bottomleft]
   {The head of a dutch cow}

\IncludePicture
  [horizontal]
  [cow] % Name of the image
  [highlight=yes,
   grid=no,
   subgrid=no,
   alternative=arrow,
   color=orange,
   x=0.4,
   y=6.8,
   direction=-90,
   length=3cm,
   shadow=topright]
   {The mouth of a dutch cow}

\IncludePicture
  [horizontal]
  [cow] % Name of the image
  [highlight=yes,
   grid=no,
   subgrid=no,
   alternative=focus,
   color=orange,
   x=1.4,
   y=8.2,
   xscale=1.5,
   opacity=0.5]
   {The head of a dutch cow}

\IncludePicture
  [vertical]
  [mill]
  [width=\NormalWidth]
  {The windmills are an example of a green energy source.}

\SlideTitle{Summary}

\startitemize
  \item The {\em first main message} of your talk in one or two lines.
  \item The {\em second main message} of your talk in one or two lines.
  \item Perhaps a {\em third message}, but not more than that.
\stopitemize

\stoptext
```
