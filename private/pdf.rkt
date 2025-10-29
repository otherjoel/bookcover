#lang racket

(require file/gunzip)

;; API to fetch page count and size info for a PDF file.
;; We assume this PDF is for the interior of a book and that all pages are the same size.

(provide (struct-out pdf)
         page-data)

(struct pdf (page-count page-size) #:transparent)

;; We assume:
;;  - We can get the page count by counting occurences of "Type Page[s]" (regex)
;;  - The first encountered "MediaBox" gives the dimensions of the first page
;;  - Both of the above are either visible in the plain bytes of the PDF,
;;    or are contained in "FlateDecode" type compressed streams
;;
;; There are PDFs out there that won't work with this approach. But this has worked for me so far.

;; Bytes -> Bytes
(define (inflate-bytes compressed)
  (define out (open-output-bytes))
  (inflate (open-input-bytes compressed) out)
  (get-output-bytes out))

;; Search for a "stream" (chunk of compressed binary data) in a byte string of PDF data
;; Returns index for use as start of next search, and the uncompressed bytes of the stream
;; Bytes [Int] -> Values: Integer Bytes
(define (next-stream pdf-bytes [start 0])
  (match (regexp-match-positions #px#"stream[\\s]*" pdf-bytes start)
    [(list (cons _ m-end))
     (match (regexp-match-positions #px#"[\\s]*endstream" pdf-bytes m-end)
       [(list (cons close-start close-end))
        (values close-end
                (inflate-bytes
                 (subbytes pdf-bytes
                           (+ 2 m-end) ; skip zlib header
                           close-start)))]
       [_ (values #f #f)])]
    [_ (values #f #f)]))

(define (page-data pdf-filename)
  (define pdf-bytes (file->bytes pdf-filename))
  (define rx-page #px#"/Type[\\s]*/Page(?:[^s]|$)")
  (define plain-count (count values (regexp-match* rx-page pdf-bytes)))
  (define page-size (find-mediabox pdf-bytes))
  (define compressed-count
    (let loop ([start 0]
               [page-count 0])
      (define-values (next-start next-stream-bytes) (next-stream pdf-bytes start))
      (cond
        [next-stream-bytes
         (cond [page-size]
               [(find-mediabox next-stream-bytes)
                => (lambda (ps) (set! page-size ps))])
         (loop next-start
               (+ page-count (count values (regexp-match* rx-page next-stream-bytes))))]
        [else page-count])))
  (pdf (+ plain-count compressed-count) page-size))

;; Bytes (uncompressed) -> (or/c #f (List w h))
(define (find-mediabox data)
  (define mbox-regex #px"/MediaBox\\s*\\[\\s*([0-9.]+)\\s+([0-9.]+)\\s+([0-9.]+)\\s+([0-9.]+)")
  (match (bytes->string/utf-8 data #\?)
    [(regexp mbox-regex (list _ x1 y1 x2 y2))
     (list (- (string->number x2) (string->number x1))
           (- (string->number y2) (string->number y1)))]
    [_ #f]))


