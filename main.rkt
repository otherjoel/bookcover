#lang racket

; #lang bookcover - A language for making book covers

(provide (rename-out [bookcover-begin #%module-begin])
         (except-out [all-from-out racket] #%module-begin)
         (all-from-out "draw.rkt"))

(require "draw.rkt"
         br/define
         racket/draw
         pict
         pdf-read)

(module* reader syntax/module-reader 
  bookcover)

(define-macro-cases bookcover-begin
  [(bookcover-begin (setup SETUP-ARGS ...) EXPRESSIONS ...)
   #'(#%module-begin
      (setup SETUP-ARGS ...)
      EXPRESSIONS ...
      (finish-cover-dc))]
  [(bookcover-begin EXPRESSIONS ...)
   #'(#%module-begin
      (println "No setup?!?!?")
      EXPRESSIONS ...)])

