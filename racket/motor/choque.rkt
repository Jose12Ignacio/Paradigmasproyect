#lang racket

(require "tipos.rkt")

(provide (all-defined-out))

;; Lógica de choque con la lista que proviene de C
(define (grupos-chocan? g1 g2)
  (cond ((member (grupo-numero g2) (grupo-choques g1)) #t)
        (else #f)))

(define (grupo-valido? g acu)
  (cond((null? acu) #t)
    ((grupos-chocan? g (car acu)) #f)
    ((grupos-chocan? (car acu) g) #f)
    (else (grupo-valido? g (cdr acu)))))