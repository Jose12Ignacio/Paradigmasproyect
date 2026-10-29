#lang typed/racket
;; Pruebas de pipeline.rkt (Persona 3). Ejecutar con: racket racket/tests/test-pipeline.rkt
(require typed/rackunit "../tipos.rkt" "../pipeline.rkt")

(define (g [c : String] [n : Natural]) : Grupo
  (Grupo c n "Prof" (list (Horario "K" 450 560))))

(define (curso [cod : String] [cr : Natural] [ok : Boolean] [gs : (Listof Grupo)]) : Curso
  (Curso cod cod cr 1 "CE" '() '() gs ok (if ok #f "no cumple requisitos")))

(define catalogo : Catalogo
  (Catalogo "CE"
            (list (curso "A" 3 #t (list (g "A" 1) (g "A" 2) (g "A" 3)))
                  (curso "B" 4 #f (list (g "B" 1)))
                  (curso "C" 0 #t '()))
            '()))

(define (prefs [is : (Listof Interes)]) : Preferencias (Preferencias is 3 7))
(define (codigos [p : Preparacion]) : (Listof String)
  (map (lambda ([c : Candidato]) (Curso-codigo (Candidato-curso c))) (Preparacion-candidatos p)))
(define (razones [p : Preparacion]) : (Listof String)
  (map Descarte-razon (Preparacion-descartes p)))

;; lista vacía de grupos = todos los grupos del curso
(let ([p (preparar-candidatos catalogo (prefs (list (Interes "A" '()))))])
  (check-equal? (codigos p) '("A"))
  (check-equal? (length (Candidato-grupos (car (Preparacion-candidatos p)))) 3))

;; grupos específicos: solo los pedidos (varios grupos por curso)
(let ([p (preparar-candidatos catalogo (prefs (list (Interes "A" '(1 3)))))])
  (check-equal? (map Grupo-numero (Candidato-grupos (car (Preparacion-candidatos p)))) '(1 3)))

;; descartes con su razón
(check-equal? (razones (preparar-candidatos catalogo (prefs (list (Interes "B" '()))))) '("no cumple requisitos"))
(check-equal? (razones (preparar-candidatos catalogo (prefs (list (Interes "C" '()))))) '("no tiene grupos con horario"))
(check-equal? (razones (preparar-candidatos catalogo (prefs (list (Interes "Z" '()))))) '("no existe en el catalogo"))
(check-equal? (razones (preparar-candidatos catalogo (prefs (list (Interes "A" '(9)))))) '("ninguno de los grupos pedidos existe"))
(check-equal? (razones (preparar-candidatos catalogo (prefs (list (Interes "A" '()) (Interes "A" '(1))))))
              '("repetido en las preferencias"))

;; sin intereses -> nada que generar
(check-equal? (codigos (preparar-candidatos catalogo (prefs '()))) '())

;; filtro de créditos (inclusivo en ambos extremos) sobre una secuencia perezosa
(define (combo [cr : Natural]) : Combinacion (Combinacion '() cr))
(define (creditos-de [s : (Sequenceof Combinacion)]) : (Listof Natural)
  (for/list : (Listof Natural) ([c : Combinacion s]) (Combinacion-creditos-totales c)))
(check-equal? (creditos-de (filtrar-por-creditos (Preferencias '() 3 7) (list (combo 2) (combo 3) (combo 7) (combo 8))))
              '(3 7))
(check-equal? (creditos-de (filtrar-por-creditos (Preferencias '() 10 12) (list (combo 2) (combo 8)))) '())

(displayln "pipeline: todas las pruebas pasaron")
