#lang racket
(require json)

(define (probar-lectura)
  ;; RUTA ABSOLUTA DIRECTA
  (define ruta-json "C:/Users/Sebastián G/OneDrive/Documentos/TEC/IIS 2026/Paradigmasproyect/Paradigmasproyect/c/output/catalogo_CE.json")
  
  (displayln "Leyendo el catálogo desde C...")
  
  (define catalogo (with-input-from-file ruta-json read-json))
  
  (define metadata (hash-ref catalogo 'metadata))
  (define cursos (hash-ref catalogo 'cursos))
  
  (displayln (string-append "Carrera: " (hash-ref metadata 'carrera)))
  (displayln (string-append "Total de cursos: " (number->string (hash-ref metadata 'total_cursos))))
  
  (define primer-curso (first cursos))
  (displayln "\n--- Primer curso encontrado ---")
  (displayln (string-append "Código: " (hash-ref primer-curso 'codigo)))
  (displayln (string-append "Nombre: " (hash-ref primer-curso 'nombre)))
  (displayln (string-append "Créditos: " (number->string (hash-ref primer-curso 'creditos))))
  (displayln (string-append "Carrera: " (hash-ref primer-curso 'carrera))))

(probar-lectura)