#lang scribble/manual

@(require (for-label racket bookcover/draw racket/draw pict pict/convert))

@title{Module Reference}

@defmodule[bookcover/draw]

The functions you need, the functions you crave.

@defproc[(setup [#:interior-pdf interior-pdf-filename path-string?]
                [#:cover-pdf cover-pdf-filename path-string?]
                [#:bleed-pts bleed-pts real? (current-bleed-pts)]
                [#:spine-calculator spinewidth-calc (exact-positive-integer? . -> . real?) (createspace-spine 'white-bw)])
         void?]{
  Loads the interior pdf, calculates the cover dimensions, and sets all the parameters.}

@defproc[(current-cover-dc) (or/c null? (is-a?/c pdf-dc%))]{
  Returns the @racket[pdf-dc%] object for the currently active book cover, or @racket[null] if @racket[setup] has not yet been called since either the start of the program or since the last time @racket[finish-cover] was called.}

@defproc[(finish-cover) void?]{
  Properly closes the @racket[pdf-dc%] for the current book cover.

 When using @code{#lang bookcover} this function is automatically called at the very end of your program.

 If you want to generate more than one book cover in the same program, you must call this function once in between calls to @racket[setup].}

@section{Spine width calculators}

In order to properly calculate the overall width of the book cover, the module needs (among other things) a way to calculate the thickness of your book's spine.

This @deftech{spine width calculator} is any function that takes a page count (a positive integer) and returns a value in points.

You may pass any such function to the @racket[#:spine-calculator] argument of @racket[setup]; if you choose not to, @racket[setup] will default to the function returned by @racket[(createspace-spine 'white-bw)] --- that is, it will assume you are having your book printed by Createspace, on their white paper, in black and white.

Different printers specify different ways of calculating the spine width of your book. As a convenience, this module provides some functions which return ready-made @tech{spine width calculators} that cover the most common cases, but you can also supply your own.

@defproc[(createspace-spine [paper-type (or/c 'white-bw 'cream-bw 'color)])
         (exact-positive-integer? . -> . real?)]{
  Returns a @tech{spine width calculator} function that uses the constants provided by Createspace for calculating spine width by multiplying the page count by one of three constant values: @racket[0.002252] for black-and-white printing on white paper, @racket[0.0025] for black-and-white printing on cream paper, and @racket[0.002347] for color printing.}
          
@defproc[(using-ppi [pages-per-inch real?])
         (exact-positive-integer? . -> . real?)]{
  Returns a @tech{spine width calculator} function that multiplies its page-count argument by @racket[(/ 1 pages-per-inch)].

 Use this if your printing service instructs you to calculate spine width using a PPI value for a particular paper type.}

@section{Measurement functions}

@deftogether[(@defproc[(bleed) real?]
              @defproc[(pageheight) real?]
              @defproc[(pagewidth) real?]
              @defproc[(spinewidth) real?]
              @defproc[(coverwidth) real?])]{
Return the actual measurement of the element on the @racket[current-cover-dc], already divided by the scaling factor.

The @racket[pagewidth], @racket[pageheight] and @racket[coverwidth] functions each include the width of the bleed on all applicable sides:

@itemlist[
  @item{The @racket[pagewidth] includes the width of the bleed along @bold{one} edge (i.e. the right edge for the front cover, the left edge for the back cover).}
  @item{The @racket[coverwidth] and @racket[pageheight] include the width of the bleed along @bold{two} edges (top and bottom for height, left and right for width).}
]}

@deftogether[(@defproc[(spinerightedge) real?]
              @defproc[(spineleftedge) real?])]{
Returns the coordinates of the spine's left or right edge on the @racket[current-cover-dc], already divided by the scaling factor.

These would be most commonly used when placing elements with reference to the back cover's right edge or the front cover's left edge.}

@defproc[(centering-offset [pic pict-convertible?]
                           [context-dim real?]
                           [dim-func (pict? . -> . real?) pict-width])
          real?]{
Returns an offset that, when used as an x- or y-offset for @racket[pic], would exactly center it within @racket[context-dim].

If centering vertically, use @racket[pict-height] as the last argument.
}

@section{Drawing functions}

@deftogether[(
 @defproc[(outline-spine! [#:color color (or/c string? (is-a?/c color%) (list/c byte? byte? byte?)) "black"]) void?]
 @defproc[(outline-bleed! [#:color color (or/c string? (is-a?/c color%) (list/c byte? byte? byte?)) "black"]) void?])]{
 Draw an outline of the spine or bleed areas, respectively, on the cover, using a dashed line colored with @racket[color].}

@defproc[(cover-draw [pic pict-convertible?] [x real?] [y real?]) void?]{Draw @racket[pic] on the current cover, with its top left corner at @racket[x], @racket[y].}

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
Draw @racket[pic] on the front or back cover.
     
When @racket[hcenter] is @racket[#t], @racket[left] is ignored; Likewise when @racket[vcenter] is @racket[#t], @racket[top] is ignored.

 The @racket[#:top] and @racket[#:left] arguments should @emph{not} include the bleed area --- i.e., a value of @racket[0] for either of these coordinates will place @racket[pic] at the very inside edge of the bleed.}

@defproc[(spine-draw [pic pict-convertible?]
                     [top-offset real? 0]) void?]{
Draw @racket[pic] horizontally centered on the spine, optionally offset from the top of the spine by @racket[top-offset].

By design, this function does not check or care if @racket[pic] will fit inside the spine width.}

@section{Testing}

@defproc[(dummy-pdf [output-pdf path-string?]
                    [width-pts real?]
                    [height-pts real?]
                    [#:pages page-count exact-positive-integer? 1]) void?]{
Creates a PDF with @racket[page-count] pages using the given dimensions and saves it to @racket[output-pdf]. The width and height are given in @tech{points}.

This PDF can be useful for mocking up a cover if you don't yet have a PDF of your book's interior to pass to the @racket[setup] function, or for rapidly experimenting with different paper sizes.}

@defproc[(check-cover [#:unit-display unit-func (real? . -> . string?) pts->inches-string]) void?]{
  Prints out a bunch of information about the current bleed, interior PDF page size, spine width calculation and cover size. Dimensions are formatted using @racket[unit-func].}

@section{Unit conversions}

@deftogether[(@defproc[(pts->inches-string [points real?]) string?]
              @defproc[(pts->cm-string [points real?]) string?])]{
Convert @tech{points} to inches or centimeters, respectively, in string form with the unit appended. Included for use with @racket[check-cover], though perhaps you will find other uses for them.}

@deftogether[(@defproc[(inches->pts [inches real?]) real?]
              @defproc[(cm->pts [cm real?]) real?])]{
Convert @racket[inches] and @racket[cm] to @tech{points}, respectively. Created mainly for convenience with @racket[dummy-pdf].}