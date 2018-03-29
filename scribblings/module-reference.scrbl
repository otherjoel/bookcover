#lang scribble/manual

@(require (for-label racket bookcover/draw racket/draw pict))

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

@section{Drawing functions}

@deftogether[(
 @defproc[(outline-spine! [#:color color (or/c string? (is-a?/c color%) (list/c byte? byte? byte?)) "black"]) void?]
 @defproc[(outline-bleed! [#:color color (or/c string? (is-a?/c color%) (list/c byte? byte? byte?)) "black"]) void?])]{
 Draw an outline of the spine or bleed areas, respectively, on the cover, using a dashed line colored with @racket[color].}