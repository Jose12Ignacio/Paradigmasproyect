#lang typed/racket

;; exportador.rkt — Módulo de Salida (Persona 1)
;; Escribe las combinaciones finales en el JSON que consumirá Prolog.
;; Utiliza indentación para que el archivo generado sea legible por humanos.

(require typed/json
         "../tipos.rkt")

(provide exportar-combinaciones)

;; 1. Convertir una Selección a un HashTable
(: seleccion->hash (-> Seleccion (HashTable Symbol Any)))
(define (seleccion->hash s)
  (hash 'curso (Seleccion-curso s)
        'grupo (Seleccion-grupo s)
        'carrera (Seleccion-carrera s)))

;; 2. Convertir una Combinación a un HashTable
(: combinacion->hash (-> Natural Combinacion (HashTable Symbol Any)))
(define (combinacion->hash id comb)
  (hash 'id_combinacion id
        'creditos_totales (Combinacion-creditos-totales comb)
        'selecciones (for/list : (Listof (HashTable Symbol Any)) 
                       ([s (Combinacion-selecciones comb)])
                       (seleccion->hash s))))

;; 3. Función principal
(: exportar-combinaciones (-> String (Listof Combinacion) Void))
(define (exportar-combinaciones ruta combinaciones)
  
  ;; Armamos la lista de combinaciones. Usamos in-naturals que genera 1, 2, 3...
  (define lista-combinaciones
    (for/list : (Listof (HashTable Symbol Any)) 
      ([c combinaciones]
       [i : Natural (in-naturals 1)]) 
      (combinacion->hash i c)))

  ;; Armamos el hash final con la metadata
  (define json-final
    (hash 'metadata (hash 'version_esquema "2.0"
                          'total_combinaciones (length combinaciones)
                          'fecha_generacion "2026-10-29")
          'combinaciones lista-combinaciones))
  
  ;; Escribimos el archivo con formato "Pretty Print" (indentado con 4 espacios)
  (with-output-to-file ruta
    (lambda () 
      (write-json (cast json-final JSExpr) 
                  (current-output-port) 
                  #:indent 4))
    #:exists 'replace)
  
  (displayln (format "[OK] Exportadas ~a combinaciones a ~a" 
                     (length combinaciones) ruta)))