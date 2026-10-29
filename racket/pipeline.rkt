#lang typed/racket
;; pipeline.rkt — pasos puros del pipeline que unen la lectura (Persona 1) con el generador (Persona 2).
;; Sin mutación: todo se resuelve con recursión y valores inmutables.

(require "tipos.rkt" "genericos.rkt")
(provide preparar-candidatos filtrar-por-creditos)

(: buscar-curso (-> String (Listof Curso) (Option Curso)))
(define (buscar-curso codigo cursos)
  (cond [(null? cursos) #f]
        [(string=? (Curso-codigo (car cursos)) codigo) (car cursos)]
        [else (buscar-curso codigo (cdr cursos))]))

;; Lista vacía de números = "todos los grupos"; si no, solo los pedidos que existan.
(: grupos-pedidos (-> (Listof Grupo) (Listof Natural) (Listof Grupo)))
(define (grupos-pedidos grupos numeros)
  (if (null? numeros)
      grupos
      (filter (lambda ([g : Grupo]) (and (member (Grupo-numero g) numeros) #t)) grupos)))

(: ya-incluido? (-> String (Listof Candidato) Boolean))
(define (ya-incluido? codigo candidatos)
  (ormap (lambda ([c : Candidato]) (string=? (Curso-codigo (Candidato-curso c)) codigo)) candidatos))

;; Decide si un interés del estudiante se vuelve Candidato o se descarta (con razón).
(: evaluar-interes (-> Interes (Listof Curso) (Listof Candidato) (U Candidato Descarte)))
(define (evaluar-interes interes cursos ya-elegidos)
  (define codigo (Interes-curso interes))
  (define curso (buscar-curso codigo cursos))
  (cond
    [(ya-incluido? codigo ya-elegidos) (Descarte codigo "repetido en las preferencias")]
    [(not curso) (Descarte codigo "no existe en el catalogo")]
    [(not (Curso-matriculable curso))
     (Descarte codigo (or (Curso-razon curso) "el estudiante no cumple los requisitos"))]
    [(null? (Curso-grupos curso)) (Descarte codigo "no tiene grupos con horario")]
    [else
     (let ([gs (grupos-pedidos (Curso-grupos curso) (Interes-grupos interes))])
       (if (null? gs)
           (Descarte codigo "ninguno de los grupos pedidos existe")
           (Candidato curso gs)))]))

(: preparar-candidatos (-> Catalogo Preferencias Preparacion))
(define (preparar-candidatos catalogo prefs)
  (let loop ([intereses : (Listof Interes) (Preferencias-intereses prefs)]
             [candidatos : (Listof Candidato) '()]
             [descartes : (Listof Descarte) '()])
    (if (null? intereses)
        (Preparacion (reverse candidatos) (reverse descartes))
        (let ([r (evaluar-interes (car intereses) (Catalogo-cursos catalogo) candidatos)])
          (if (Candidato? r)
              (loop (cdr intereses) (cons r candidatos) descartes)
              (loop (cdr intereses) candidatos (cons r descartes)))))))

;; Reutiliza el filtro polimórfico: el mismo filtrar-por/criterio-rango que sirve para cualquier tipo.
(: filtrar-por-creditos (-> Preferencias (Sequenceof Combinacion) (Sequenceof Combinacion)))
(define (filtrar-por-creditos prefs combinaciones)
  (filtrar-por (criterio-rango Combinacion-creditos-totales
                               (Preferencias-creditos-min prefs)
                               (Preferencias-creditos-max prefs))
               combinaciones))
