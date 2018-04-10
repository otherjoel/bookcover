#lang racket/base
(require racket/system bookcover/draw)

(dummy-pdf "my-book.pdf" (inches->pts 4) (inches->pts 6) #:pages 100)

;; ~~~ Begin example program: ~~~
(setup #:interior-pdf "my-book.pdf"
       #:cover-pdf "example-cover.pdf")

(define title (text "Sunshine for Sal" "Plantin Std, Semibold" 42))
(define subtitle (text "A Painfully Verbose Memoir" '(italic . "Plantin Std") 24))
(define accent (filled-rectangle (coverwidth)
                                 (/ (pageheight) 3)
                                 #:color "LemonChiffon"
                                 #:draw-border? #f))

(cover-draw accent 0 (/ (pageheight) 3))
(frontcover-draw title #:top (* (pageheight) 2/5) #:horiz-center? #t)
(frontcover-draw subtitle #:top (* (pageheight) 3/6) #:horiz-center? #t)

(outline-spine! "red")
(outline-bleed!)
;; ~~~ End example program ~~~

(finish-cover)
(case (system-type)
  [(macosx) (system "sips -s format png --out example-cover.png example-cover.pdf")]
  [else (print "Not on Mac OS; find another way to create example-cover.png from example-cover.pdf\n")])

(delete-file "my-book.pdf")

(define (list-fonts str)
  (filter (lambda(s) (string=? str (substring s 0 (min (string-length str) (string-length s)))))
          (get-face-list #:all-variants? #t)))