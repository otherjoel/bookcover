#lang racket/base

;; #lang bookcover - A language for making book covers

(require (for-syntax racket/base syntax/parse)
         "draw.rkt"
         racket/draw
         pict)

(provide (rename-out [bookcover-begin #%module-begin])
         (except-out [all-from-out racket/base] #%module-begin)
         (all-from-out pict)
         (all-from-out "draw.rkt"))

(module* reader syntax/module-reader 
  bookcover)

(define-syntax (bookcover-begin stx)
  (syntax-parse stx
    [(_ e:expr ...)
     #'(#%module-begin
        e ...
        (finish-cover))]))
