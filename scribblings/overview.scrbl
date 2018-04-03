#lang scribble/manual

@(require bookcover/draw)
@(require (for-label racket bookcover/draw))

@title{Overview}

@section{Installation}

The @code{bookcover} library works on Linux, Mac OS, and Windows. You need a working installation of Racket first.

To install @code{bookcover} from the command line:

@exec{raco pkg install bookcover}

To install from DrRacket, click @menuitem["File" "Install Package ..."]. Type @exec{bookcover} in the text box, then click @exec{Install}. When it's finished, close and relaunch DrRacket.

@section{Important Concepts}

@subsection{Bleed}

Printing services usually require that a certain small amount of space be added to all sides of your book cover for @deftech{bleed}. This is an area of the cover that will be trimmed off after the cover is printed. If you have color or graphics that will extend right out to the very edge of your cover, you should have extend them all the way to the edge of the bleed area: this prevents small variations in the trimming process from producing noticable slivers of un-inked area at the edge of your cover.

Of course, if your cover doesn't have anything on it that will touch the edges, you will have no use for bleed. But it will still be there, and you'll still have to account for it.

@subsection{Points}

For historical reasons, the dimensions of a PDF file in Racket are given in @deftech{points}: there are 72 points in an inch, and @number->string[(cm->pts 1)] points in a centimeter (sorry, metric folks).

If you'd prefer to us 

@section{Quick Start}

The most basic way to use @racketmodname[bookcover] is as a single-file Racket program, which takes information about a single book and generates a single book cover for it:

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

The very first line is @code{#lang bookcover}, which provides all the functions from @racketmodname[bookcover/draw] (as well as @racketmodname[pict] and @racketmodname[racket/draw]) and ensures that the cover PDF is properly closed and saved at the end of your program.

The call to @racket[setup] is important. You will call it at least once in your book cover program and you must give it at least two things: the filename of an existing PDF that will be used as the book's interior, and the filename to use when saving the cover PDF. The size and number of pages in the interior PDF will directly determine the dimensions of your cover. Until you call @racket[setup] you can’t actually draw anything. This function also takes some additional, optional arguments that let you override the @link["https://en.wikipedia.org/wiki/Bleed_%28printing%29"]{bleed width} and the way the spine width is calculated.

Next, the program creates some @racket[pict]s that will later be drawn onto the cover. Again, everything in the @racketmodname[pict] module is available to you automatically. Note the use of no-argument functions like @racket[pageheight] that let you easily base the size and/or placement of these picts on the overall dimensions of the cover. That way, if your book's interior size or page-count change, not only will your cover resize itself appropriately, but the elements on it will adjust as well.