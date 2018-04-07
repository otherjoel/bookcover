#lang scribble/manual

@(require bookcover/draw
          racket/file
          racket/runtime-path)
@(require (for-label racket bookcover/draw))

@title{Overview}

@section{Installation}

The @code{bookcover} library works on Linux, Mac OS, and Windows. You need a working installation of Racket first.

To install @code{bookcover} from the command line:

@exec{raco pkg install bookcover}

To install from DrRacket, click @menuitem["File" "Install Package ..."]. Type @exec{bookcover} in the text box, then click @exec{Install}. When it's finished, close and relaunch DrRacket.

@section{Quick Start}

The most basic way to use @racketmodname[bookcover] is as a single-file Racket program, which takes information about a single book and generates a single book cover for it. 

Here's an example book cover program:

@(define-runtime-path example-cover-rkt "example-cover.rkt")
@(define-runtime-path example-cover-png "example-cover.png")

@filebox["example-cover.rkt"]{@codeblock{
@file->string[example-cover-rkt]
}}

To try this out for yourself, save this program as @filepath{example-cover.rkt} in the same folder as a PDF file @filepath{my-book.pdf} (as seen in the call to @racket[setup] above). If you don't have such a file, add this line of code immediately before the line with @racket[setup] on it:

@codeblock{
(dummy-pdf "my-book.pdf" (inches->pts 4) (inches->pts 6) #:pages 100)
}

When @filepath{my-book.pdf} is has 100 pages which are 4 inches wide by 6 inches tall, running this program produces a file @filepath{example-cover.pdf} that looks like this (shown at reduced scale):

@centered{@image[example-cover-png #:scale 0.3]}

Note the anatomy of the book cover: it's a single image that ``wraps'' around the entire book, starting with the back cover on the far left, then the spine, then the front cover.

If you were to change the page count of @filepath{my-book.pdf} from 100 to 50 and re-run this program, you'd see the width of the spine (the area inside the red lines) automatically shrink to half of its original width.

@subsection{Anatomy of a book cover program}

Let's look at this example program in more detail.

The very first line is @code{#lang bookcover}, which provides all the functions from @racketmodname[bookcover/draw] (as well as @racketmodname[pict] and @racketmodname[racket/draw]) and ensures that the cover PDF is properly closed and saved at the end of your program.

The call to @racket[setup] is important: until you do it, you can’t actually draw anything. You will call it at least once in your book cover program, and you must give it at least two things: the filename of an existing PDF that will be used as the book's interior, and the filename to use when saving the cover PDF. The size and number of pages in the interior PDF will directly determine the dimensions of your cover.  This function also takes some additional, optional arguments that let you override the default @tech{bleed} width and/or the default @tech{spine width calculator}.

Next, the program creates some @racket[pict]s that will later be drawn onto the cover. Again, everything in the @racketmodname[pict] module is available to you automatically. Note the use of no-argument @secref["measurement-functions"] like @racket[pageheight] that let you easily base the size and/or placement of these picts on the overall dimensions of the cover. That way, if your book's interior size or page-count change, not only will your cover's overall dimensions resize appropriately, but the elements on it can adjust their size and placement as well. (Web developers will recognize this practice as ``responsive design''.)

Finally, the program uses @secref["Drawing_functions"] to draw these @racket[pict]s onto the cover, again using measurement functions to derive coordinates. Two of these functions, @racket[outline-spine!] and @racket[outline-bleed!] simply draw dashed lines around their respective special areas; they are useful for reference during the design phase, but you will want to remove them or comment them out before generating your final cover.

@margin-note{This might seem obvious, but note that the @emph{order} in which you draw things is important: wherever two elements overlap, the first one will be covered up by the second one.}