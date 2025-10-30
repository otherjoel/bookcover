#lang info

(define collection "bookcover")
(define version "1.0")
(define scribblings '(("scribblings/bookcover.scrbl" (multi-page))))
(define deps '("base"
               "draw-lib"
               "pict-lib"))
(define test-omit-paths '("scribblings/make-dummy.rkt"
                          "scribblings/example-cover.rkt"))
(define build-deps '("draw-doc"
                     "pict-doc"
                     "racket-doc"
                     "rackunit-lib"
                     "scribble-lib"))
(define license 'LGPL-3.0-only)
