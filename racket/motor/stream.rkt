#lang racket

(require "../tipos.rkt"
         "choque.rkt")

(provide (all-defined-out))

;; 1. Concatenación perezosa de streams
(define (stream-concat-lazy s1 s2-thunk)
  (cond ((stream-empty? s1) (s2-thunk))
        (else (stream-cons (stream-first s1)
                           (stream-concat-lazy (stream-rest s1) s2-thunk)))))

;; 2. Generación perezosa de combinaciones de horario
(define (generar-combinaciones lista-cursos acu)
  (cond ((null? lista-cursos) (stream acu))
        (else (por-grupos (car lista-cursos) (cdr lista-cursos) acu))))

(define (por-grupos grupos resto-cursos acu)
  (cond ((null? grupos) empty-stream)
        ((grupo-valido? (car grupos) acu)
         (stream-concat-lazy
          (generar-combinaciones resto-cursos (cons (car grupos) acu))
          (lambda () (por-grupos (cdr grupos) resto-cursos acu))))
        (else (por-grupos (cdr grupos) resto-cursos acu))))