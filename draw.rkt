#lang racket

;; Convenience functions for creating and drawing on book covers

(provide (all-from-out racket/draw
                       pict))

(provide (contract-out [existing-pdf? (path-string? . -> . boolean?)]))

(provide (contract-out
          [setup (->* (#:interior-pdf (and/c path-string? existing-pdf?)
                       #:cover-pdf path-string?)
                      (#:bleed-pts (and/c real? (not/c negative?))
                       #:spine-calculator (exact-positive-integer? . -> . real?))
                      void?)]))

(provide
 (contract-out
  [createspace-spine ((or/c 'white-bw 'cream-bw 'color) . -> . (exact-positive-integer? . -> . real?))]
  [using-ppi         (real?                             . -> . (exact-positive-integer? . -> . real?))]))

(provide
 (contract-out
  [inches->pts (real? . -> . real?)]
  [cm->pts     (real? . -> . real?)]
  [dummy-pdf   (->* (path-string?
                     real?
                     real?)
                    (#:pages exact-positive-integer?)
                    void?)]))

(provide (contract-out [current-cover-dc (-> (or/c null? (is-a?/c pdf-dc%)))]))
(provide finish-cover)

(provide
 (contract-out
  [bleed          (-> real?)]
  [pageheight     (-> real?)]
  [pagewidth      (-> real?)]
  [spinewidth     (-> real?)]
  [coverwidth     (-> real?)]
  [spinerightedge (-> real?)]
  [spineleftedge  (-> real?)]))

(provide
 (contract-out
  [outline-spine! (() ((or/c string? (is-a?/c color%) (list/c byte? byte? byte?))) . ->* . void?)]
  [outline-bleed! (() ((or/c string? (is-a?/c color%) (list/c byte? byte? byte?))) . ->* . void?)]))

(provide
 (contract-out
  [centering-offset (->* (pict-convertible? ; the pict
                          real?)
                         ((pict? . -> . real?))
                         real?)]
  [frontcover-draw (->* (pict-convertible?)
                        (#:top real?
                         #:left real?
                         #:horiz-center? any/c
                         #:vert-center? any/c)
                        void?)]
  [backcover-draw  (->* (pict-convertible?)
                        (#:top real?
                         #:left real?
                         #:horiz-center? any/c
                         #:vert-center? any/c)
                        void?)]
  [cover-draw      (pict-convertible? real? real? . -> . void?)]
  [spine-draw      (->* (pict-convertible?) (real?) void?)]))

(provide
 (contract-out
  [pts->inches-string (real? . -> . string?)]
  [pts->cm-string     (real? . -> . string?)]
  [check-cover (->* () 
                    (#:unit-display (real? . -> . string?))
                    void?)]))

;; ~~~ Requires ~~~

(require pict
         pict/convert
         racket/draw)

(module+ test
  (require rackunit))

;; ~~~ Spine width multipliers ~~~

(define (createspace-spine paper-type)
  (define spine-multipliers
    (hash 'white-bw 0.002252
          'cream-bw 0.002500
          'color    0.002347))
  (cond [(member paper-type (hash-keys spine-multipliers))
         (lambda (pages) (* pages (hash-ref spine-multipliers paper-type) 72.0))]
        [else
         (raise-argument-error 'paper-type (format "one of: ~a" (hash-keys spine-multipliers)) paper-type)]))
         
(define (using-ppi pages-per-inch)
  (lambda (pages) (* pages (/ 1 pages-per-inch) 72.0)))

(module+ test
  (check-equal? 16.2144 ((createspace-spine 'white-bw) 100))
  (check-equal? 18.0 ((createspace-spine 'cream-bw) 100))
  (check-equal? 16.729416 ((createspace-spine 'color) 99))
  (check-exn exn:fail:contract?
             (lambda () (createspace-spine 'glitterbomb)))

  (check-equal? 25.0 ((using-ppi 288) 100)))

;; ~~~ Private parameters (not provided) ~~~

(define default-bleed-inches 0.125)

(define current-spinewidth-calculator (make-parameter (createspace-spine 'white-bw)))

(define current-bleed-pts (make-parameter (* default-bleed-inches 72)))
(define current-pagewidth-pts  (make-parameter 0))
(define current-pageheight-pts (make-parameter 0))
(define current-spinewidth-pts (make-parameter 0))
(define current-coverwidth-pts (make-parameter 0))
(define current-interior-pagecount (make-parameter 0))
(define current-scaling (make-parameter 0))

; some derived values
(define (current-spineleftedge-pts) (current-pagewidth-pts))
(define (current-spinerightedge-pts) (+ (current-pagewidth-pts) (current-spinewidth-pts)))

(define all-numeric-parameters
  (list current-bleed-pts
        current-pagewidth-pts
        current-pageheight-pts
        current-spinewidth-pts
        current-coverwidth-pts
        current-interior-pagecount
        current-scaling))

(define (reset-numeric-parameters)
  (for ([param (in-list all-numeric-parameters)])
       (param 0)))

(define (set-current-scaling!)
  (define x (box 0))
  (define y (box 0))
  (send (current-ps-setup) get-scaling x y)
  (current-scaling (unbox x)))

;; ~~~ Measurement Functions ~~~

(define (bleed) (/ (current-bleed-pts) (current-scaling)))
(define (pagewidth) (/ (current-pagewidth-pts) (current-scaling)))
(define (pageheight) (/ (current-pageheight-pts) (current-scaling)))
(define (spinewidth) (/ (current-spinewidth-pts) (current-scaling)))
(define (coverwidth) (/ (current-coverwidth-pts) (current-scaling)))
(define (spineleftedge) (/ (current-spineleftedge-pts) (current-scaling)))
(define (spinerightedge) (/ (current-spinerightedge-pts) (current-scaling)))

;; ~~~ Dubious home-grown PDF file inspectors (not provided for liabity reasons) ~~~

; Get # of pages
(define (page-count pdf-filename)
  (define pdf (open-input-file pdf-filename))
  
  (for/sum ([line (in-port read-line pdf)])
           (let ([x (regexp-match #px"/Type[\\s]*/Page(?:[^s]|$)" line)])
             (if x (count values x) 0))))

; Look for occurences of the form "/MediaBox [0.0 0.0 612.0 792.0]"
; and return the box dimensions
(define (has-media-box? str)
  (define mediabox-px #px"/MediaBox\\s*\\[\\s*([0-9\\.])+\\s+([0-9\\.])+\\s+([0-9\\.]+)\\s+([0-9\\.]+)\\s*\\]")
  (let* ([x (regexp-match mediabox-px str)])
    (cond
      [x
       (match-let ([(list start-x start-y end-x end-y) (map string->number (rest x))])
         (list (- end-x start-x) (- end-y start-y)))]
      [else #f])))

; Find the first MediaBox in a PDF and call that the page size (works most of the time)
(define (page-size pdf-filename)
  (define pdf (open-input-file pdf-filename))

  (for/last ([line (stop-after (in-port read-line pdf) has-media-box?)])
            (has-media-box? line)))

;; ~~~ Unit conversions ~~~

(define (inches->pts inches) (* inches 72.0))
(define (cm->pts cm) (* (/ cm 2.54) 72.0))

(define (rounder num) (/ (round (* 1000 num)) 1000)) ; not provided
(define (pts->inches-string pts) (format "~a″" (rounder (/ pts 72.0))))
(define (pts->cm-string pts) (format "~acm" (rounder (* (/ pts 72.0) 2.54))))

(module+ test
  (check-equal? 72.0 (inches->pts 1))
  (check-equal? 72.0 (cm->pts 2.54))
  (check-equal? "1.0″" (pts->inches-string 72))
  (check-equal? "2.54cm" (pts->cm-string 72)))

;; ~~~ Cover Setup/Teardown ~~~

(define (setup #:interior-pdf interior-pdf-filename
               #:cover-pdf cover-pdf-filename
               #:bleed-pts [bleed-pts (current-bleed-pts)]
               #:spine-calculator [spinewidth-calc (createspace-spine 'white-bw)])
  (unless (null? (current-cover-dc))
    (finish-cover))
  
  ; Pull information out of the interior PDF and set parameters
  (match-define (list interior-width-pts interior-height-pts)
    (page-size interior-pdf-filename))
  (current-interior-pagecount (page-count interior-pdf-filename))
  (set-current-scaling!)
  (current-pagewidth-pts  (+ interior-width-pts (current-bleed-pts)))
  (current-pageheight-pts (+ interior-height-pts (* 2 (current-bleed-pts))))

  (current-spinewidth-calculator spinewidth-calc)
  (current-spinewidth-pts (spinewidth-calc (current-interior-pagecount)))
  
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

(define current-cover-dc (make-parameter null))
  
(define (finish-cover)
  (unless (null? (current-cover-dc))
    (reset-numeric-parameters)
    (send* (current-cover-dc)
      (end-page)
      (end-doc))))

;; ~~~ Drawing functions ~~~

(define (centering-offset pic context-dim [dim-func pict-width])
  (/ (- context-dim (dim-func pic)) 2))

(define (frontcover-draw pic
                         #:top [y 0]
                         #:left [x 0]
                         #:horiz-center? [hcenter #f]
                         #:vert-center? [vcenter #f])
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
                        #:horiz-center? [hcenter #f]
                        #:vert-center? [vcenter #f])
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

(define (outline-spine! [linecolor "black"])
  (define spineline (colorize (linewidth 0.2 (linestyle 'dot (vline 1 (pageheight)))) linecolor))
  (draw-pict spineline (current-cover-dc) (spineleftedge) 0)
  (draw-pict spineline (current-cover-dc) (spinerightedge) 0))

(define (outline-bleed! [linecolor "black"])
  (define rect (rectangle (- (coverwidth) (* 2 (bleed))) (- (pageheight) (* 2 (bleed)))))
  (draw-pict (linewidth 0.2 (linestyle 'dot (colorize rect linecolor)))
             (current-cover-dc)
             (bleed)
             (bleed)))

;; ~~~ Testing/Diagnostics ~~~

(define (file-extension file)
  (string-downcase (last (string-split file "."))))

(define (existing-pdf? file)
  (and (file-exists? file)
       (string=? "pdf" (file-extension file))))

(define (dummy-pdf filename width-pts height-pts #:pages [pages 1])
  (define dummy-dc (new pdf-dc%
                        [interactive #f]
                        [as-eps #f]
                        [use-paper-bbox #f]
                        [width width-pts]
                        [height height-pts]
                        [output filename]))
  (define t (text "JUST TESTING" "Arial" (round (/ width-pts 10))))
  (define ctr-x (centering-offset t width-pts))
  (define ctr-y (centering-offset t height-pts pict-height))
  
  (define (scrawl-testing)
    (draw-pict t dummy-dc ctr-x ctr-y))

  (send* dummy-dc
    (start-doc "useless string")
    (start-page))

  (scrawl-testing)
  
  (unless (< pages 2)
    (for ([n (in-range 1 pages)])
         (send* dummy-dc
           (end-page)
           (start-page))
         (scrawl-testing)))
  
  (send* dummy-dc
    (end-page)
    (end-doc)))

(define (check-cover #:unit-display [unit-func pts->inches-string])
  (define interior-pagewidth-pts (unit-func (- (current-pagewidth-pts) (current-bleed-pts))))
  (define interior-pageheight-pts (unit-func (- (current-pageheight-pts) (* 2 (current-bleed-pts)))))
  (match-define-values (size-x size-y) (send (current-cover-dc) get-size))
  (printf "pdf-dc% get-size:     ~a ⨉ ~a\n" size-x size-y)
  (printf "Cover size (w/bleed): ~a ⨉ ~a (~apts ⨉ ~apts, w/scaling ~a ⨉ ~a)\n"
          (unit-func (current-coverwidth-pts))
          (unit-func (current-pageheight-pts))
          (current-coverwidth-pts)
          (current-pageheight-pts)
          (rounder (coverwidth))
          (rounder (pageheight)))
  (printf "Scaling factor:       ~a\n" (current-scaling))
  (printf "Bleed:                ~a (~a)\n" (unit-func (current-bleed-pts)) (bleed))
  (printf "Interior PDF size:    ~a ⨉ ~a\n" interior-pagewidth-pts interior-pageheight-pts)
  (printf "Interior pagecount:   ~a pages\n" (current-interior-pagecount))
  (printf "Spine multiplier:     ~a\n" ((current-spinewidth-calculator) 1))
  (printf "Spine width:          ~a (= ~a pages ⨉ ~a in inches)\n"
          (unit-func (current-spinewidth-pts)) (current-interior-pagecount) ((current-spinewidth-calculator) 1))
  
  (cond [(< (current-interior-pagecount) 101)
         (printf "CreateSpace would not allow text on spine (pages < 101)")]
        [(< (current-interior-pagecount) 130)
         (printf "CreateSpace does not recommend text on spine (pages < 130)")]))

(module+ test
  (check-equal? (void) (dummy-pdf "test-interior.pdf" (inches->pts 4) (inches->pts 6) #:pages 100))
  (check-equal? (void) (setup #:interior-pdf "test-interior.pdf"
                              #:cover-pdf "test-cover.pdf"
                              #:bleed-pts (inches->pts 0.25)
                              #:spine-calculator (using-ppi 360)))
  (check-equal? (void) (check-cover))
  (check-equal? 767.5 (coverwidth))
  (check-equal? 562.5 (pageheight))
  (delete-file "test-interior.pdf"))