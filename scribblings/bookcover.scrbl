#lang scribble/manual
@(require (for-label bookcover/draw racket))

@title[#:style '(toc)]{Bookcover: Generating PDFs for book covers}
@author[(author+email "Joel Dueck" "joel@jdueck.net" #:obfuscate? #t)]

@defmodulelang[bookcover]

Creating a cover for a printed book can be one of the most tedious parts of self-publishing. Printing services have requirements for the cover's dimensions. You need to calculate the width of the book's spine based on page count and paper type, add space for bleed, and so forth. If you change anything about the inside of your book, you need to run your calculations all over again.

As an alternative to designing your book's cover with a program like InDesign or Photoshop, you can instead implement it as a Racket program that dynamically calculates everything for you and generates the cover in PDF form each time it is run. This has a few advantages:

@itemlist[
 @item{If your book's page count changes, you can re-run the program and your cover will be adjusted automatically.}
 @item{You can keep your book's cover under version control and track changes more easily (useful when @link["http://pollenpub.com"]{the book itself is also a program}).}
 @item{Your book cover has access to a complete programming environment. Whether it's getting values from a SQL database or using procedurally generated fractal art (@link["https://web.archive.org/web/20081015005111/http://postspectacular.com/process/20080711_faberfindslaunch"]{@italic{Faber Finds} generative book covers}, anyone?): if it can be done with code, it can be very easily placed on your book's cover.}
]

This library/language does nothing very magical; it's just a thin layer on top of the @racketmodname[pict] and @racketmodname[racket/draw] libraries that come with Racket. What it does do is abstract away almost all of the tedious math and setup involved with using those libraries for this particular purpose. I've used it successfully on @hyperlink["https://dicewordbook.com"]{one book}, so I'm reasonably sure it will work for you too.

If you're new to Racket, you would do very well to read @other-doc['(lib "scribblings/quick/quick.scrbl")] first. Not only will you learn the basics of writing Racket programs, but many of the functions used in that tutorial are the same ones you'll be snapping together with the ones in this library to create your book covers.

@bold{NB:} This is my first ever Racket module, and it has had very little testing outside of my own small projects. For these reasons, it should for now be considered unstable: the functions it provides may change. After I've gathered and incorporated some feedback, I will solidify things a bit and make a 1.0.0 version.

The source for this package is at @url["https://github.com/otherjoel/bookcover"].

@local-table-of-contents[]

@include-section["overview.scrbl"]
@include-section["module-reference.scrbl"]
@include-section["appendix.scrbl"]