#lang typed/racket
(require "io/lector.rkt" "tipos.rkt")

(define ruta-catalogo "C:/Users/Sebastián G/OneDrive/Documentos/TEC/IIS 2026/Paradigmasproyect/Paradigmasproyect/c/output/catalogo_CE.json")
(define ruta-prefs "C:/Users/Sebastián G/OneDrive/Documentos/TEC/IIS 2026/Paradigmasproyect/Paradigmasproyect/racket/preferencias.json")

(displayln "--- Leyendo Catálogo ---")
(define cat (leer-catalogo-json ruta-catalogo))
(displayln (format "Carrera: ~a" (Catalogo-siglas cat)))
(displayln (format "Total Cursos: ~a" (length (Catalogo-cursos cat))))

(displayln "\n--- Leyendo Preferencias ---")
(define prefs (leer-preferencias-json ruta-prefs))
(displayln (format "Créditos Min: ~a" (Preferencias-creditos-min prefs)))
(displayln (format "Créditos Max: ~a" (Preferencias-creditos-max prefs)))
(displayln (format "Cursos de interés: ~a" (length (Preferencias-intereses prefs))))