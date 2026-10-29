#lang typed/racket
(require "../tipos.rkt" "../genericos.rkt")

;; Datos copiados del JSON real (CE-1101, grupos 1 y 2)
(define ce-1101 : Curso
  (Curso "CE-1101" "Introduccion a la programacion" 3 1 (string->carrera "CE") '() '()
         (list (Grupo "CE-1101" 1 "Schmidt Peralta Jeff"
                      (list (Horario (string->dia "K") (hora->minutos "07:30") (hora->minutos "09:20"))
                            (Horario (string->dia "J") (hora->minutos "07:30") (hora->minutos "09:20"))))
               (Grupo "CE-1101" 2 "Schmidt Peralta Jeff"
                      (list (Horario (string->dia "K") (hora->minutos "09:30") (hora->minutos "11:20")))))
         #t #f))
(displayln (list (Curso-codigo ce-1101) (length (Curso-grupos ce-1101))
                 (Horario-inicio (car (Grupo-horarios (car (Curso-grupos ce-1101)))))))

(define combos : (Listof Combinacion)
  (list (Combinacion (list (Seleccion "CE-1101" 1 "CE")) 4)
        (Combinacion (list (Seleccion "CE-1101" 2 "CE") (Seleccion "MA-1102" 1 "CE")) 8)
        (Combinacion (list (Seleccion "TI-1000" 1 "ATI")) 3)))

;; Instancia 1: A = Combinacion, filtrar por rango de créditos
(define (creditos-de [c : Combinacion]) : Natural (Combinacion-creditos-totales c))
(define en-rango (filtrar-por (criterio-rango creditos-de 4 8) combos))
(displayln (for/list : (Listof Natural) ([c : Combinacion en-rango]) (creditos-de c)))

;; Instancia 2: A = String, el MISMO filtrar-por y criterio-rango con otro tipo
(define cortos (filtrar-por (criterio-rango (lambda ([s : String]) (string-length s)) 1 3)
                            (list "a" "abcd" "xyz")))
(displayln (for/list : (Listof String) ([s : String cortos]) s))
