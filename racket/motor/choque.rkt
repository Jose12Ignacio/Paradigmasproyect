#lang racket

(require "../tipos.rkt")

(provide (all-defined-out))

;; Verifica si dos estructuras Horario se traslapan en tiempo
(define (horarios-chocan? h1 h2)
  (and (string=? (Horario-dia h1) (Horario-dia h2))
       (< (Horario-inicio h1) (Horario-fin h2))
       (< (Horario-inicio h2) (Horario-fin h1))))

;; Verifica si dos grupos tienen al menos un choque horaria entre sus clases
(define (grupos-chocan? g1 g2)
  (ormap (lambda (h1)
           (ormap (lambda (h2)
                    (horarios-chocan? h1 h2))
                  (Grupo-horarios g2)))
         (Grupo-horarios g1)))

;; Un grupo es válido si no choca con ningún grupo seleccionado en el acumulador
(define (grupo-valido? g acu)
  (not (ormap (lambda (g-acu) (grupos-chocan? g g-acu)) acu)))