#lang bookcover

(setup #:interior-pdf "my-book.pdf"
       #:cover-pdf "example-cover.pdf")

(define title    (colorize (text "Sunshine for Sal" (cons 'bold "Times New Roman") 48) "blue"))
(define subtitle (text "A Painfully Verbose Memoir" (cons 'italic "Times New Roman") 26))
(define accent   (filled-rectangle (coverwidth)
                                   (/ (pageheight) 3)
                                   #:color "LemonChiffon"
                                   #:draw-border? #f))

(cover-draw accent 0 (/ (pageheight) 3))
(frontcover-draw title #:top (* (pageheight) 2/6) #:horiz-center? #t)
(frontcover-draw subtitle #:top (* (pageheight) 3/6) #:horiz-center? #t)

(outline-spine! "red")
(outline-bleed!)
