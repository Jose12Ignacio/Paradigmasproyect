#lang typed/racket

;; test_e2e.rkt — Prueba final de la Etapa 2
;; Lee ambos catálogos (CE y ATI), los unifica sin duplicados, genera combinaciones y exporta.

(require "io/lector.rkt"
         "io/exportador.rkt"
         "pipeline.rkt"
         "tipos.rkt"
         racket/stream)

(require/typed "motor/stream.rkt"
               [generar-combinaciones (-> (Listof (Listof Grupo)) (Listof Grupo) (Sequenceof (Listof Grupo)))])

;; ==========================================
;; Rutas
;; ==========================================
(define ruta-catalogo-ce "../c/output/catalogo_CE.json")
(define ruta-catalogo-ati "../c/output/catalogo_ATI.json")
(define ruta-prefs "preferencias.json")
(define ruta-salida "salida_etapa2.json")

;; ==========================================
;; Funciones auxiliares
;; ==========================================
(: buscar-curso (-> String (Listof Curso) (Option Curso)))
(define (buscar-curso cod cursos)
  (cond [(null? cursos) #f]
        [(string=? (Curso-codigo (car cursos)) cod) (car cursos)]
        [else (buscar-curso cod (cdr cursos))]))

(: unificar-cursos (-> (Listof Curso) (Listof Curso) (Listof Curso)))
(define (unificar-cursos cursos-ce cursos-ati)
  (define codigos-ce (map Curso-codigo cursos-ce))
  (define cursos-ati-nuevos
    (filter (lambda ([c : Curso]) (not (member (Curso-codigo c) codigos-ce))) cursos-ati))
  (append cursos-ce cursos-ati-nuevos))

;; ==========================================
;; FLUJO PRINCIPAL
;; ==========================================
(displayln "1. Leyendo Catálogos (CE + ATI) y Preferencias...")

(define cat-ce (leer-catalogo-json ruta-catalogo-ce))
(define cat-ati (leer-catalogo-json ruta-catalogo-ati))

(define cursos-unificados (unificar-cursos (Catalogo-cursos cat-ce) (Catalogo-cursos cat-ati)))
(define historial-unificado (append (Catalogo-historial cat-ce) (Catalogo-historial cat-ati)))
(define cat-unificado (Catalogo "CE" cursos-unificados historial-unificado))

(displayln (format "   -> Cursos CE: ~a" (length (Catalogo-cursos cat-ce))))
(displayln (format "   -> Cursos ATI: ~a" (length (Catalogo-cursos cat-ati))))
(displayln (format "   -> Cursos unificados: ~a" (length cursos-unificados)))

(define prefs (leer-preferencias-json ruta-prefs))

(displayln "2. Preparando Candidatos...")
(define prep (preparar-candidatos cat-unificado prefs))
(define candidatos (Preparacion-candidatos prep))

(displayln (format "   -> Candidatos válidos: ~a" (length candidatos)))
(displayln (format "   -> Descartes: ~a" (length (Preparacion-descartes prep))))

(displayln "3. Generando combinaciones con Streams")
(define lista-grupos (map Candidato-grupos candidatos))
(define stream-crudos (generar-combinaciones lista-grupos '()))
(define combinaciones-crudas (for/list : (Listof (Listof Grupo)) ([g stream-crudos]) g))
(displayln (format "   -> Combinaciones generadas por el motor: ~a" (length combinaciones-crudas)))

(displayln "4. Transformando a estructura Combinacion y calculando créditos...")
(define combinaciones-finales
  (for/list : (Listof Combinacion) ([grupos combinaciones-crudas])
    (define selecciones
      (for/list : (Listof Seleccion) ([g grupos])
        (define c (assert (buscar-curso (Grupo-curso g) cursos-unificados) Curso?))
        (Seleccion (Grupo-curso g) (Grupo-numero g) (Curso-creditos c) (Curso-carrera c) (Curso-area c))))
    
    (define creditos
      (for/sum : Natural ([s selecciones])
        (define c (assert (buscar-curso (Seleccion-curso s) cursos-unificados) Curso?))
        (Curso-creditos c)))
    
    (Combinacion selecciones creditos)))

(displayln "5. Filtrando por rango de créditos...")
(define combinaciones-filtradas 
  (for/list : (Listof Combinacion) ([c (filtrar-por-creditos prefs (in-list combinaciones-finales))]) c))

(displayln (format "   -> Combinaciones finales válidas: ~a" (length combinaciones-filtradas)))

(displayln "6. Exportando a JSON")
(exportar-combinaciones ruta-salida combinaciones-filtradas)

(displayln "7. Razones de descarte:")
(for ([d (Preparacion-descartes prep)])
  (displayln (format "      * ~a: ~a" (Descarte-curso d) (Descarte-razon d))))

(displayln "¡Flujo End-to-End completado exitosamente!")