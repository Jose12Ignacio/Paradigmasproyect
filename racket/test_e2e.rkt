#lang typed/racket

;; test_e2e.rkt — Prueba final de la Etapa 2 (Persona 1)
;; Lee, genera combinaciones (usando streams) y exporta.

(require "io/lector.rkt"
         "io/exportador.rkt"
         "pipeline.rkt"
         "tipos.rkt"
         racket/stream) ; Para manejar los streams

;; Declaramos las funciones del motor de tu compañero para que Typed Racket no se queje
(require/typed "motor/stream.rkt"
               [generar-combinaciones (-> (Listof (Listof Grupo)) (Listof Grupo) (Sequenceof (Listof Grupo)))])

;; ==========================================
;; Rutas (ajusta si es necesario)
;; ==========================================
(define ruta-catalogo "C:/Users/Sebastián G/OneDrive/Documentos/TEC/IIS 2026/Paradigmasproyect/Paradigmasproyect/c/output/catalogo_CE.json")
(define ruta-prefs "C:/Users/Sebastián G/OneDrive/Documentos/TEC/IIS 2026/Paradigmasproyect/Paradigmasproyect/racket/preferencias.json")
(define ruta-salida "C:/Users/Sebastián G/OneDrive/Documentos/TEC/IIS 2026/Paradigmasproyect/Paradigmasproyect/racket/salida_etapa2.json")

;; ==========================================
;; Función auxiliar para buscar curso por código
;; ==========================================
(: buscar-curso (-> String (Listof Curso) (Option Curso)))
(define (buscar-curso cod cursos)
  (cond [(null? cursos) #f]
        [(string=? (Curso-codigo (car cursos)) cod) (car cursos)]
        [else (buscar-curso cod (cdr cursos))]))

;; ==========================================
;; FLUJO PRINCIPAL
;; ==========================================
(displayln "1. Leyendo Catálogo y Preferencias...")
(define cat (leer-catalogo-json ruta-catalogo))
(define prefs (leer-preferencias-json ruta-prefs))

(displayln "2. Preparando Candidatos...")
(define prep (preparar-candidatos cat prefs))
(define candidatos (Preparacion-candidatos prep))

(displayln (format "   -> Candidatos válidos: ~a" (length candidatos)))
(displayln (format "   -> Descartes: ~a" (length (Preparacion-descartes prep))))

(displayln "3. Generando combinaciones con Streams")
;; Extraemos solo los grupos de cada candidato
(define lista-grupos (map Candidato-grupos candidatos))

;; Llamamos a la función de tu compañero
(define stream-crudos (generar-combinaciones lista-grupos '()))

;; Convertimos el stream a lista normal para procesarlo
(define combinaciones-crudas (for/list : (Listof (Listof Grupo)) ([g stream-crudos]) g))

(displayln (format "   -> Combinaciones generadas por el motor: ~a" (length combinaciones-crudas)))

(displayln "4. Transformando a estructura Combinacion y calculando créditos...")
(define combinaciones-finales
  (for/list : (Listof Combinacion) ([grupos combinaciones-crudas])
    (define selecciones
      (for/list : (Listof Seleccion) ([g grupos])
        (define c (assert (buscar-curso (Grupo-curso g) (Catalogo-cursos cat)) Curso?))
        (Seleccion (Grupo-curso g) (Grupo-numero g) (Curso-carrera c))))
    
    (define creditos
      (for/sum : Natural ([s selecciones])
        (define c (assert (buscar-curso (Seleccion-curso s) (Catalogo-cursos cat)) Curso?))
        (Curso-creditos c)))
    
    (Combinacion selecciones creditos)))

(displayln "5. Filtrando por rango de créditos...")
(define combinaciones-filtradas (for/list : (Listof Combinacion) ([c (filtrar-por-creditos prefs (in-list combinaciones-finales))]) c))(displayln (format "   -> Combinaciones finales válidas: ~a" (length combinaciones-filtradas)))

(displayln "6. Exportando a JSON")
(exportar-combinaciones ruta-salida combinaciones-filtradas)

(displayln "7   -> Razones de descarte:")
(for ([d (Preparacion-descartes prep)])
  (displayln (format "      * ~a: ~a" (Descarte-curso d) (Descarte-razon d))))

(displayln "¡Flujo End-to-End completado exitosamente!")    