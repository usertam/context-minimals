Cyrillic Numerals in ConTeXt
================================================================================

Module for typesetting Cyrillic numbers. Take your time to read the manual under
``./doc/context/third/cyrillicnumbers/cyrillicnumbers.tex``. To build the
documentation a recent versions of ConTeXt will be needed.

Installation
================================================================================

First, get a checkout from BitBucket_: ::

    hg clone http://bitbucket.org/phg/context-cyrillicnumbers

In the next step, copy the files into the path of your ConTeXt distribution.
Assuming it is installed in $HOME/context/, you would accomplish this like
so: ::

    cd context-cyrillicnumbers
    cp -r doc/ tex/ ~/context/tex/texmf-modules/

Finally, rebuild the file name database: ::

    context --generate

and the module is ready to use!

License
================================================================================

All code and documentation is licensed under a modified BSD license, see the
file COPYING in the repository root.

Author
================================================================================

This module was written by Philipp Gesang, ``megas.kapaneus`` at ``gmail`` dot
``com`` (find me on BitBucket_).

.. _BitBucket:  http://bitbucket.org/phg


