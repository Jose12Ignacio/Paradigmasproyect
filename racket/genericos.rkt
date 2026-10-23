#lang typed/racket
;; genericos.rkt — funciones con polimorfismo paramétrico (All (A) ...).
;; racket/stream no trae tipos en Typed Racket, así que se importa con require/typed.

(provide filtrar-por criterio-rango)

(require/typed racket/stream
  [stream-filter (All (A) (-> (-> A Boolean) (Sequenceof A) (Sequenceof A)))])

;; Filtra CUALQUIER secuencia perezosa con CUALQUIER predicado, sin conocer el tipo A.
(: filtrar-por (All (A) (-> (-> A Boolean) (Sequenceof A) (Sequenceof A))))
(define (filtrar-por pred secuencia)
  (stream-filter pred secuencia))

;; Fábrica de criterios: "el número que extrae `medida` está en [minimo, maximo]".
;; Sirve para créditos de una Combinacion, para la cantidad de grupos de un Curso, etc.
(: criterio-rango (All (A) (-> (-> A Natural) Natural Natural (-> A Boolean))))
(define (criterio-rango medida minimo maximo)
  (lambda ([x : A])
    (let ([n (medida x)])
      (and (>= n minimo) (<= n maximo)))))
