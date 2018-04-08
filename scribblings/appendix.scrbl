#lang scribble/manual

@(require bookcover/draw)
@(require (for-label bookcover/draw))

@title{Appendix}

@section{Bleed}

Printing services usually require that a certain small amount of space be added to all sides of your book cover for @deftech{bleed}. This is an ``extra'' area of the cover that will be trimmed off after the cover is printed.

In print, the rule is: never end color/graphics at or near the trimmed edge of the paper. If you try, every tiny variation in the actual trimming process will be glaringly obvious and ugly. If you want a graphical element to extend right out to the trimmed edge of your cover, you always extend it past the trim line, all the way through the bleed area. That way, no matter where the trimmer's blade slices, there won't be any slivers of un-inked area at the edge of your cover.

Of course, if your cover doesn't have anything on it that will touch the edges, you will have no use for bleed. But the printing service will require it anyway.

@section{Points}

For historical reasons, the dimensions of a PDF files in Racket are specified in @deftech{points}: there are 72 points in an inch, and @number->string[(cm->pts 1)] points in a centimeter (sorry, metric folks).

If you want to specify convert to points using your favorite units, use @secref["unit_convert"].