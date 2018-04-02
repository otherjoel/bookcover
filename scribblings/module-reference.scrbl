#lang scribble/manual

@(require scribble/example)
@(require (for-label racket bookcover/draw
                     racket/draw
                     pict
                     pict/convert))

@(define codebox (make-base-eval))
@(codebox '(require bookcover/draw))

@title{Module Reference}

@defmodule[bookcover/draw]

This module is automatically imported by @code{#lang bookcover}. The only difference between @code{(require bookcover/draw)} and @code{#lang bookcover} is that with the former, @racket[finish-cover] is not automatically called at the end of your program. You might prefer to use the @racket[require] form when doing something fancier than creating just a single static cover; for example, when defining your own functions that create multiple book covers of the same style for different titles.

@defproc[(setup [#:interior-pdf interior-pdf path-string?]
                [#:cover-pdf cover-pdf-filename path-string?]
                [#:bleed-pts bleed-pts real? (* 0.125 72)]
                [#:spine-calculator spinewidth-calc (exact-positive-integer? . -> . real?) (createspace-spine 'white-bw)])
         void?]{
Calculate the size of the book cover that would properly fit an existing PDF file @racket[interior-pdf]; set the return values for all the @secref["measurement-functions"]; and create a @racket[pdf-dc%] object for drawing on the book cover, which will be saved as @racket[cover-pdf-filename].

The cover dimensions are calculated as follows:

@itemlist[#:style 'ordered
  @item{The width and height of the first page in @racket[interior-pdf] are used as the size of the front and back covers.}
  @item{The page count of @racket[interior-pdf] is passed to @racket[spinewidth-calc] to determine the width of the spine. (See @tech{spine width calculators}.)}
  @item{A width equal to @racket[bleed-pts] is added to all four edges of the cover.}
]

Examples:

@codeblock{
 ; The minimum viable setup call
 (setup #:interior-pdf "my-book-contents.pdf"
        #:cover-pdf "cover.pdf")

 ; Using more options:
 (setup #:interior-pdf "my-book-contents.pdf"
                    #:cover-pdf "cover.pdf"
                    #:spinewidth-calc (using-ppi 339) ; Calculate spine width using 339 PPI
                    #:bleed-pts (inches->pts 0.25))   ; Use 1/4" bleed
                    
 }
}


@defproc[(current-cover-dc) (or/c null? (is-a?/c pdf-dc%))]{
  Returns the @racket[pdf-dc%] object for the currently active book cover, in case you want to draw on it directly with functions in @racketmodname[racket/draw].

If @racket[setup] has not yet been called since the start of the program, or if it hasn't been called since the last time @racket[finish-cover] was called, then there is no active cover, and @racket[current-cover-dc] will return @racket[null].}

@defproc[(finish-cover) void?]{
  Properly closes the @racket[pdf-dc%] for the current book cover, sets @racket[current-cover-dc] to null, and zeroes out the return values of all the @secref["measurement-functions"].

This function is automatically called at the very end of your program when using @code{#lang bookcover}.

It is also called automatically on successive calls to @racket[setup] whenever @racket[current-cover-dc] is not equal to @racket[null].}

@section{Spine width calculators}

In order to properly calculate the overall width of the book cover, the module needs (among other things) a way to calculate the thickness of your book's spine.

This @deftech{spine width calculator} is any function that takes a page count (a positive integer) and returns a value in @tech{points}.

You may pass any such function to the @racket[#:spine-calculator] argument of @racket[setup]; if you choose not to, @racket[setup] will default to the function returned by @racket[(createspace-spine 'white-bw)] --- that is, it will assume you are having your book printed by Createspace, on their white paper, in black and white.

Different printers specify different ways of calculating the spine width of your book. As a convenience, this module provides some functions which return ready-made @tech{spine width calculators} that cover the most common cases, but you can also supply your own.

@defproc[(createspace-spine [paper-type (or/c 'white-bw 'cream-bw 'color)])
         (exact-positive-integer? . -> . real?)]{
  Returns a @tech{spine width calculator} function that uses the constants provided by Createspace for their different paper types: @racket[0.002252] for black-and-white printing on white paper, @racket[0.0025] for black-and-white printing on cream paper, and @racket[0.002347] for color printing.

@examples[#:eval codebox
          (define spine-func (createspace-spine 'cream-bw))
          (spine-func 330)
          ]
}
          
@defproc[(using-ppi [pages-per-inch real?])
         (exact-positive-integer? . -> . real?)]{
  Returns a @tech{spine width calculator} function that multiplies its page-count argument by @racket[(/ 1 pages-per-inch 72.0)] to get a width in @tech{points}.

 Use this if your printing service instructs you to calculate spine width using a PPI value for a particular paper type.

@examples[#:eval codebox
          (define ppi-spine (using-ppi 442))
          (ppi-spine 78)
]
}

@section{Drawing functions}

@defproc[(cover-draw [pic pict-convertible?] [x real?] [y real?]) void?]{Draw @racket[pic] on the current cover, with its top left corner at @racket[x], @racket[y]. The @racket[0] coordinates for @racket[x] and @racket[y] start on the very outside edge of the bleed.}

@deftogether[(
  @defproc[(frontcover-draw [pic pict-convertible?]
                            [#:top top real? 0]
                            [#:left left real? 0]
                            [#:horiz-center hcenter any/c #f]
                            [#:vert-center  vcenter any/c #f]) void?]
   @defproc[(backcover-draw [pic pict-convertible?]
                            [#:top top real? 0]
                            [#:left left real? 0]
                            [#:horiz-center hcenter any/c #f]
                            [#:vert-center  vcenter any/c #f]) void?])]{
Draw @racket[pic] on the front or back cover. The @racket[0] coordinates for the @racket[#:top] and @racket[#:left] arguments start at the very outside edge of the bleed.
     
When @racket[hcenter] is @racket[#t], @racket[left] is ignored; likewise when @racket[vcenter] is @racket[#t], @racket[top] is ignored.}

@defproc[(spine-draw [pic pict-convertible?]
                     [top-offset real? 0]) void?]{
Draw @racket[pic] horizontally centered on the spine, optionally offset from the top of the spine by @racket[top-offset].

By design, this function does not check or care if @racket[pic] will fit inside @racket[spinewidth].

@codeblock{
; Draw some text on the spine
(define spine-title
  (text "My Book Title" "Helvetica" 10 (degrees->radians 270)))
  
(spine-draw spine-title (centering-offset spine-title page-height pict-height))
           
; Draw a blue rectangle that wraps around the spine equally on front and back
(define spine-rectangle
  (filled-rectangle (* (spinewidth) 4)
                    (pageheight)
                    #:color "lightblue"
                    #:draw-border #f))
                       
(spine-draw spine-rectangle)
}
}

@deftogether[(
 @defproc[(outline-spine! [#:color color (or/c string? (is-a?/c color%) (list/c byte? byte? byte?)) "black"]) void?]
 @defproc[(outline-bleed! [#:color color (or/c string? (is-a?/c color%) (list/c byte? byte? byte?)) "black"]) void?])]{
 Draw an outline of the spine or bleed areas, respectively, on the cover, using a dashed line colored with @racket[color]. Useful for verifying placement, but you will want to omit these outlines from your finished cover.}

@section[#:tag "measurement-functions"]{Measurement functions}

When @emph{setting up} your cover, everything is specified in @tech{points}. In a simple world, you could just use those same point values as coordinates for drawing on your cover. But PDF objects in Racket also have a scaling factor that is applied after the object is created. So those original point values need to be divided by that scaling factor in order to get values that you can properly use for placing elements.

The module keeps track of the cover's scaling value for you, and provides these measurement functions that return values that are ready to use for calculating where to place things on your cover.

@deftogether[(@defproc[(bleed) real?]
              @defproc[(pageheight) real?]
              @defproc[(pagewidth) real?]
              @defproc[(spinewidth) real?]
              @defproc[(coverwidth) real?])]{
Return the actual measurement of the element on the @racket[current-cover-dc], already divided by the scaling factor.

The @racket[pagewidth], @racket[pageheight] and @racket[coverwidth] functions each include the width of the bleed on all applicable sides:

@itemlist[
  @item{The @racket[(pagewidth)] includes the width of the bleed along @bold{one} edge (i.e. the right edge for the front cover, the left edge for the back cover).}
  @item{The @racket[(coverwidth)] and @racket[(pageheight)] include the width of the bleed along @bold{two} edges (top and bottom for height, left and right for width).}
]}

@deftogether[(@defproc[(spineleftedge) real?]
              @defproc[(spinerightedge) real?])]{
Returns the x-coordinate of the spine's left or right edge on the @racket[current-cover-dc], already divided by the scaling factor.}

@defproc[(centering-offset [pic pict-convertible?]
                           [context-dim real?]
                           [dim-func (pict? . -> . real?) pict-width])
          real?]{
Returns an offset that, when used as an x- or y-offset for @racket[pic], would exactly center it within @racket[context-dim].

If centering vertically, use @racket[pict-height] as the last argument.

@examples[#:eval codebox
(define blue-rectangle (filled-rectangle 20 60 #:color "blue"))
(centering-offset blue-rectangle 100)
(centering-offset blue-rectangle 250 pict-height)
]
}


@section{Testing}

@defproc[(dummy-pdf [output-pdf path-string?]
                    [width-pts real?]
                    [height-pts real?]
                    [#:pages page-count exact-positive-integer? 1]) void?]{
Creates a PDF with @racket[page-count] pages using the given dimensions and saves it to @racket[output-pdf]. The width and height are given in @tech{points}. If @racket[output-pdf] exists, it will be silently overwritten.

This PDF can be useful for mocking up a cover if you don't yet have a PDF of your book's interior to pass to the @racket[setup] function, or for rapidly experimenting with different paper sizes. See the documentation for @racket[check-cover] for an example.
}

@defproc[(check-cover [#:unit-display unit-func (real? . -> . string?) pts->inches-string]) void?]{
  Prints out a bunch of information about the current bleed, interior PDF page size, spine width calculation and cover size. Dimensions are formatted using @racket[unit-func].

@examples[#:eval codebox
(dummy-pdf "test.pdf" (inches->pts 4) (inches->pts 6) #:pages 99)
(setup #:interior-pdf "test.pdf"
       #:cover-pdf "test-cover.pdf")
(check-cover)
]}

@section{Unit conversions}

@deftogether[(@defproc[(pts->inches-string [points real?]) string?]
              @defproc[(pts->cm-string [points real?]) string?])]{
Convert @tech{points} to inches or centimeters, respectively, in string form with the unit appended. Included for use with @racket[check-cover], though perhaps you will find other uses for them.
@examples[#:eval codebox
          (pts->inches-string 72)
          (pts->cm-string 72)
]
}

@deftogether[(@defproc[(inches->pts [inches real?]) real?]
              @defproc[(cm->pts [cm real?]) real?])]{
Convert @racket[inches] and @racket[cm] to @tech{points}, respectively. Created mainly for convenience with @racket[setup] and @racket[dummy-pdf].

@examples[#:eval codebox
          (inches->pts 1)
          (cm->pts 1)
]
}