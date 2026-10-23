#lang racket

(struct grupo (curso carrera creditos horario) #:transparent)
(struct combinacion (grupos creditos-totales) #:transparent)


;; 1. Streams

(define (stream-concat-lazy s1 s2-thunk)
  (cond ((stream-empty? s1) (s2-thunk))
        (else (stream-cons (stream-first s1)
                           (stream-concat-lazy (stream-rest s1) s2-thunk)))))


;; 2. Validación de cursos

(define (grupo-valido? g acu)
  #t) 

(define (generar-combinaciones lista-cursos acu)
  (cond ((null? lista-cursos) (stream acu))
        (else
         (let* ((primer-curso (car lista-cursos))
                (resto-cursos (cdr lista-cursos))
                (grupos-sin-choque (filter (lambda (g) (grupo-valido? g acu)) 
                                           primer-curso))
            
                (lista-de-streams (map (lambda (g) 
                                         (generar-combinaciones resto-cursos (cons g acu)))
                                       grupos-sin-choque)))
           
           
           (foldr (lambda (st acc)
                    (stream-concat-lazy st (lambda () acc)))
                  empty-stream
                  lista-de-streams)))))


