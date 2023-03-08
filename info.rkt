#lang info

(define collection "bookcover")
(define version "0.1")
(define scribblings '(("scribblings/bookcover.scrbl" (multi-page))))
(define deps '("base"
               "beautiful-racket-lib"
               "draw-lib"
               "pict-lib"))
(define test-omit-paths '("scribblings/make-dummy.rkt"
                          "scribblings/example-cover.rkt"))
(define build-deps '("draw-doc"
                     "pict-doc"
                     "racket-doc"
                     "rackunit-lib"
                     "scribble-lib"
                     "slideshow-doc"))
