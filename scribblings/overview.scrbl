#lang scribble/manual
@(require (for-label bookcover/draw))

@title{Overview}

The default, most basic paradigm for @racketmodname[bookcover] is a single-file Racket program, which takes information about a single book and generates a single book cover for it:

@codeblock{
 #lang bookcover
 
 (setup #:interior-pdf "the-main-book.pdf"
        #:cover-pdf "cover.pdf")

 (define title (colorize (text "Sunshine for Sal" "Times New Roman, Bold" 48) "blue"))
 (define subtitle (text "A Painfully Long Memoir" "Times New Roman, Italic"))
 (define accent-rect (filled-rectangle (coverwidth)
                                       (/ (pageheight) 3)
                                       #:color "LemonChiffon"
                                       #:draw-border? #f))

 (cover-draw accent-rect 0 (/ (pageheight) 3))
 (frontcover-draw title #:top (* (pageheight) 2/6)
                        #:horiz-center #t)
 (frontcover-draw subtitle #:top (* (pageheight) 3/6)
                           #:horiz-center #t)

 (outline-spine! "blue")
 (outline-bleed!)
}

The very first line is @code{#lang bookcover}, which imports all the functions from this module (as well as @racketmodname[pict] and @racketmodname[racket/draw]) and ensures that the cover PDF is properly closed and saved at the end of your program.

The call to @racket[setup] is important. You will call it at least once in your book cover program and you must give it at least two things: the filename of an existing PDF that will be used as the book's interior, and the filename to use when saving the cover PDF. The size and number of pages in the interior PDF will directly determine the dimensions of your cover. Until you call @racket[setup] you can’t actually draw anything. This function also takes some additional, optional arguments that let you override the @link["https://en.wikipedia.org/wiki/Bleed_%28printing%29"]{bleed width} and the way the spine width is calculated.

Next, the program creates some @racket[pict]s that will later be drawn onto the cover. Again, everything in the @racketmodname[pict] module is available to you automatically. Note the use of no-argument functions like @racket[pageheight] that let you easily base the size and/or placement of these picts on the overall dimensions of the cover. That way, if your book's interior size or page-count change, not only will your cover resize itself appropriately, but the elements on it will adjust as well.