#lang racket/base

(require bookcover/draw)
(dummy-pdf "my-book.pdf" (inches->pts 4) (inches->pts 6) #:pages 100)