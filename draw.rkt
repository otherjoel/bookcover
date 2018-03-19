#lang racket

; Convenience functions for creating and drawing on book covers

(provide (all-from-out racket/draw
                       pict))

; Key function: prepares the pdf-dc% for the cover, and sets all parameters.
; You will call this function at least once in every program that uses this package.
(provide (contract-out
          [setup (->*
                  ; required arguments
                  (#:interior-pdf path-string? 
                   #:cover-pdf path-string?)

                  ; optional arguments
                  (#:bleed real?
                   #:spine-calculator (exact-integer? . -> . real?))

                  ; return result
                  void?)]))

; Functions that return a function suitable for the #:spine-calculator argument for setup
(provide
 (contract-out
  [createspace-spine ((symbols 'white-bw 'cream-bw 'color) . -> . (exact-integer? . -> . real?))]
  [using-ppi         (real?                                . -> . (exact-integer? . -> . real?))]))

(provide
 (contract-out
  ; Get the pdf-dc% for the current cover
  [current-cover-dc (-> (is-a?/c pdf-dc%))]))

; Close out the current cover PDF.
; This is called automatically if your program uses #lang bookcover
(provide finish-cover-dc)

; Get coordinates/dimensions of various elements of the current cover
; These have the current scaling already factored in so they can be used directly in drawing functions.
(provide
 (contract-out
  [bleed          (-> real?)]
  [pageheight     (-> real?)]
  [pagewidth      (-> real?)]
  [spinewidth     (-> real?)]
  [coverwidth     (-> real?)]
  [spinerightedge (-> real?)]
  [spineleftedge  (-> real?)]))

; Draw dashed lines on the cover showing the bleed and spine areas.
; Optionally pass in a color to use for the line.
(provide
 (contract-out
  [outline-spine! (() ((or/c string? (is-a?/c color%) (list/c byte? byte? byte?))) . ->* . void?)]
  [outline-bleed! (() ((or/c string? (is-a?/c color%) (list/c byte? byte? byte?))) . ->* . void?)]))

; Convenience functions for drawing on the cover using picts
(provide
 (contract-out
  ; Generic helper, provides offset to center a pict within a given dimension
  [centering-offset (->*
                     ; required:
                     (pict-convertible? ; the pict
                      real?)            ; dimension within which to center
                     ; optional:
                     ((pict? . -> . real?)) ; function that will be called to get the dimension of the pict
                     ; result:
                     real?)]

  ; Draw on the FRONT cover with centering or using coords relative to the front cover's top left
  [frontcover-draw (->* (pict-convertible?)    ; required arguments
                        (#:top real?           ; optional arguments
                         #:left real?
                         #:horiz-center any/c
                         #:vert-center any/c)
                        void?)]                ; return value

  ; Draw on the BACK cover with centering or using coords relative to the back cover's top left
  [backcover-draw  (->* (pict-convertible?)    ; required arguments
                        (#:top real?           ; optional arguments
                         #:left real?
                         #:horiz-center any/c
                         #:vert-center any/c)
                        void?)]                ; return value

  ; Draw anywhere on the cover
  [cover-draw      (pict-convertible? real? real? . -> . void?)]

  ; Draw something centered on the spine, with an optional top offset
  [spine-draw      (pict-convertible? real?       . -> . void?)]))

; Just prints out a bunch of measurements and diagnostic stuff about the current cover.
(provide check-cover)

; End of provides!

(require pict
         pict/convert
         racket/draw
         pdf-read)

(define (createspace-spine paper-type)
  (define spine-multipliers
    (hash 'white-bw 0.002252
          'cream-bw 0.002500
          'color    0.002347))
  (cond [(member paper-type (hash-keys spine-multipliers))
         (lambda (pages) (* pages (hash-ref spine-multipliers paper-type)))]
        [else
         (raise-argument-error 'paper-type (format "one of: ~a" (hash-keys spine-multipliers)) paper-type)]))
         
(define (using-ppi pages-per-inch)
  (lambda (pages) (* pages (/ 1 pages-per-inch))))

(define default-bleed-inches 0.125)

(define (local-uri-string filename)
  (string-append "file:"
                 (path->string (build-path (current-directory) filename))))

(define current-spinewidth-calculator (make-parameter (createspace-spine 'white-bw)))

(define current-bleed-pts (make-parameter (* default-bleed-inches 72)))
(define current-pagewidth-pts  (make-parameter 0))
(define current-pageheight-pts (make-parameter 0))
(define current-spinewidth-pts (make-parameter 0))
(define current-coverwidth-pts (make-parameter 0))
(define current-interior-pagecount (make-parameter 0))

(define current-cover-dc (make-parameter null))

; Derived values
(define (current-spineleftedge-pts)
  (current-pagewidth-pts))

(define (current-spinerightedge-pts)
  (+ (current-pagewidth-pts) (current-spinewidth-pts)))

(define (current-scaling)
  (define x (box 0))
  (define y (box 0))
  (send (current-ps-setup) get-scaling x y)
  (unbox x))

(define (bleed) (/ (current-bleed-pts) (current-scaling)))
(define (pagewidth) (/ (current-pagewidth-pts) (current-scaling)))
(define (pageheight) (/ (current-pageheight-pts) (current-scaling)))
(define (spinewidth) (/ (current-spinewidth-pts) (current-scaling)))
(define (coverwidth) (/ (current-coverwidth-pts) (current-scaling)))
(define (spineleftedge) (/ (current-spineleftedge-pts) (current-scaling)))
(define (spinerightedge) (/ (current-spinerightedge-pts) (current-scaling)))

(define (setup #:interior-pdf interior-pdf-filename
               #:cover-pdf cover-pdf-filename
               #:bleed [bleed-pts (current-bleed-pts)]
               #:spine-calculator [spinewidth-calc (createspace-spine 'white-bw)])

  ; Pull information out of the interior PDF and set parameters
  (define intpdf (open-pdf-uri (local-uri-string interior-pdf-filename) #f))
  (match-define (list interior-width-pts interior-height-pts)
    (page-size intpdf))
  (current-interior-pagecount (pdf-count-pages intpdf))
  (current-pagewidth-pts  (+ interior-width-pts (current-bleed-pts)))
  (current-pageheight-pts (+ interior-height-pts (* 2 (current-bleed-pts))))

  (current-spinewidth-calculator spinewidth-calc)
  (current-spinewidth-pts (* (spinewidth-calc (current-interior-pagecount)) 72))
  
  (current-coverwidth-pts (+ (* (current-pagewidth-pts) 2) (current-spinewidth-pts)))

  (current-cover-dc (new pdf-dc%
                         [interactive #f]
                         [use-paper-bbox #f]
                         [width (current-coverwidth-pts)]
                         [height (current-pageheight-pts)]
                         [output cover-pdf-filename]))
  (send* (current-cover-dc)
    (start-doc "useless string")
    (start-page)))

(define (outline-spine [linecolor "black"])
  (draw-pict (colorize (linewidth 0.2 (linestyle 'dot (vline 1 (pageheight)))) linecolor) (current-cover-dc) (spineleftedge) 0)
  (draw-pict (colorize (linewidth 0.2 (linestyle 'dot (vline 1 (pageheight)))) linecolor) (current-cover-dc) (spinerightedge) 0))

(define (outline-bleed [linecolor "black"])
  (draw-pict (linewidth 0.2 (linestyle 'dot (colorize (rectangle (- (coverwidth) (* 2 (bleed))) (- (pageheight) (* 2 (bleed)))) linecolor)))
             (current-cover-dc)
             (bleed)
             (bleed)))
  
(define (finish-cover-dc)
  (send* (current-cover-dc)
    (end-page)
    (end-doc)))

; Returns an offset that will center pic within a given length.
(define (centering-offset pic context-dim [dim-func pict-width])
  (/ (- context-dim (dim-func pic)) 2))

(define (frontcover-draw pic
                         #:top [y 0]
                         #:left [x 0]
                         #:horiz-center [hcenter #f]
                         #:vert-center [vcenter #f])
  (define top-offset
    (cond [vcenter (/ (- (pageheight) (pict-height pic)) 2)]
          [else (+ (bleed) y)]))
  (define left-offset
    (cond [hcenter (+ (spinerightedge) (/ (- (pagewidth) (bleed) (pict-width pic)) 2))]
          [else (+ (spinerightedge) x)]))

  (draw-pict pic (current-cover-dc) left-offset top-offset))
  
(define (backcover-draw pic
                        #:top [x 0]
                        #:left [y 0]
                        #:horiz-center [hcenter #f]
                        #:vert-center [vcenter #f])
  (define top-offset
    (cond [vcenter (/ (- (pageheight) (pict-height pic)) 2)]
          [else (+ (bleed) y)]))
  (define left-offset
    (cond [hcenter (/ (- (pagewidth) (bleed) (pict-width pic)) 2)]
          [else (+ (bleed) x)]))
  
  (draw-pict pic (current-cover-dc) left-offset top-offset))

(define (cover-draw pic x y)
  (draw-pict pic (current-cover-dc) x y))

(define (spine-draw pic [top-offset 0])
  (define leftedge (+ (spineleftedge) (centering-offset pic (spinewidth))))
  (draw-pict pic (current-cover-dc) leftedge top-offset))

(define (rounder num) (/ (round (* 1000 num)) 1000))
(define (pts->inches pts) (format "~a″" (rounder (/ pts 72.0))))
(define (pts->cm pts) (format "~acm" (rounder (* (/ pts 72.0) 2.54))))

(define (check-cover [unit-func pts->inches])
  (define interior-pagewidth-pts (unit-func (- (current-pagewidth-pts) (current-bleed-pts))))
  (define interior-pageheight-pts (unit-func (- (current-pageheight-pts) (* 2 (current-bleed-pts)))))
  (printf "Bleed:                ~a\n" (unit-func (current-bleed-pts)))
  (printf "Interior PDF size:    ~a ⨉ ~a\n" interior-pagewidth-pts interior-pageheight-pts)
  (printf "Interior pagecount:   ~a pages\n" (current-interior-pagecount))
  (printf "Spine multiplier:     ~a\n" ((current-spinewidth-calculator) 1))
  (printf "Spine width:          ~a (= ~a pages ⨉ ~a in inches)\n"
          (unit-func (current-spinewidth-pts)) (current-interior-pagecount) ((current-spinewidth-calculator) 1))
  (printf "Cover size (w/bleed): ~a ⨉ ~a\n\n" (unit-func (current-coverwidth-pts)) (unit-func (current-pageheight-pts)))
  (cond [(< (current-interior-pagecount) 101)
         (printf "CreateSpace would not allow text on spine (pages < 101)")]
        [(< (current-interior-pagecount) 130)
         (printf "CreateSpace does not recommend text on spine (pages < 130)")])
  )