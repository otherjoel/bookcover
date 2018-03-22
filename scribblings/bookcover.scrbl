#lang scribble/manual
@(require (for-label pollen))

@title{bookcover: generating PDFs for book covers}
@author[(author+email "Joel Dueck" "joel@jdueck.net" #:obfuscate? #t)]

@defmodulelang[bookcover]

@section{Introduction}

Creating a digital cover for a printed book can be one of the most tedious parts of self-publishing. Printers and publishers have strict requirements and formulas you must use to calculate the cover's dimensions. You need to calculate the width of the book's spine based on page count and paper type, add space for bleed, and so forth. If you change @emph{anything} about your book --- even just adding a page or two --- you'll need to start all over again.

Instead of building your cover with a GUI in a program like InDesign or Photoshop, you can now create your book cover as a Racket program that does all the calculation for you and generates the cover in PDF form. This has a couple of advantages:

@itemlist[
 @item{If your book's interior page count changes, you can re-run the program and your cover will be adjusted automatically.}
 @item{You can keep your book's cover under version control and track changes more easily (useful when @racketlink[pollen]{the book itself is also a program}).}
 @item{Your book cover has access to a complete programming environment. Whether it's getting values from a SQL database or using procedurally generated fractal art: if it can be done with code, it can be very easily placed on your book's cover.}
]

@subsection{Caveats}

I created this module for my own convenience. It's also my first ever Racket module. For these reasons, it should for now be considered unstable: the functions it provides may change. After I've gathered and incorporated some feedback, I will solidify things a bit and make a 1.0.0 version.

Also note: whenever font rendering is involved, the examples given may not produce the same results on your computer. This is due to differences in the way fonts are @emph{named} on MacOS, Linux and Windows.

@include-section["overview.scrbl"]
@include-section["module-reference.scrbl"]