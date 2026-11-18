#lang typed/racket

;; lector.rkt — Módulo de Entrada/Salida (Persona 1)
;; Lee el JSON de C y el JSON de preferencias, y los convierte a los tipos de tipos.rkt.

(require typed/json
         "../tipos.rkt")

(: leer-catalogo-json (-> String Catalogo))
(: leer-preferencias-json (-> String Preferencias))
(provide leer-catalogo-json leer-preferencias-json)

;; ==========================================
;; Funciones auxiliares de conversión
;; ==========================================

;; Convierte cualquier cosa (Vector, Lista) a una lista de Strings
(: any->string-list (-> Any (Listof String)))
(define (any->string-list v)
  (cond
    [(vector? v) (for/list ([x (in-vector v)]) (assert x string?))]
    [(list? v) (for/list ([x v]) (assert x string?))]
    [else '()]))

;; Convierte cualquier cosa a una lista de Números
(: any->num-list (-> Any (Listof Natural)))
(define (any->num-list v)
  (cond
    [(vector? v) (for/list ([x (in-vector v)]) (assert x exact-nonnegative-integer?))]
    [(list? v) (for/list ([x v]) (assert x exact-nonnegative-integer?))]
    [else '()]))

;; Convierte una lista genérica a una lista de HashTables
(: any->hash-list (-> Any (Listof (HashTable Symbol Any))))
(define (any->hash-list v)
  (cond
    [(vector? v) 
     (for/list : (Listof (HashTable Symbol Any)) ([x (in-vector v)]) 
       (cast x (HashTable Symbol Any)))]
    [(list? v) 
     (for/list : (Listof (HashTable Symbol Any)) ([x v]) 
       (cast x (HashTable Symbol Any)))]
    [else '()]))

;; ==========================================
;; 1. LECTURA DEL CATÁLOGO (Generado por C)
;; ==========================================

(: parsear-horarios (-> (Listof (HashTable Symbol Any)) (Listof Horario)))
(define (parsear-horarios lista-horarios)
  (for/list ([h lista-horarios])
    (Horario (string->dia (assert (hash-ref h 'dia) string?))
             (hora->minutos (assert (hash-ref h 'hora_inicio) string?))
             (hora->minutos (assert (hash-ref h 'hora_fin) string?)))))

(: parsear-grupos (-> String (Listof (HashTable Symbol Any)) (Listof Grupo)))
(define (parsear-grupos codigo-curso lista-grupos)
  (for/list ([g lista-grupos])
    (define prof (hash-ref g 'profesor))
    (Grupo codigo-curso
           (assert (hash-ref g 'numero) exact-nonnegative-integer?)
           (if (string? prof) prof "Por asignar")
           (parsear-horarios (any->hash-list (hash-ref g 'horarios))))))

(: parsear-curso (-> (HashTable Symbol Any) Curso))
(define (parsear-curso c)
  (define codigo (assert (hash-ref c 'codigo) string?))
  (define razon (hash-ref c 'razon_no_matriculable))
  (Curso codigo
         (assert (hash-ref c 'nombre) string?)
         (assert (hash-ref c 'creditos) exact-nonnegative-integer?)
         (assert (hash-ref c 'semestre) exact-nonnegative-integer?)
         (string->carrera (assert (hash-ref c 'carrera) string?))
         (any->string-list (hash-ref c 'requisitos))
         (any->string-list (hash-ref c 'correquisitos))
         (parsear-grupos codigo (any->hash-list (hash-ref c 'grupos)))
         (assert (hash-ref c 'es_matriculable) boolean?)
         (if (string? razon) razon #f)))

(define (leer-catalogo-json ruta)
  (define data (assert (with-input-from-file ruta read-json) hash?))
  (define meta (assert (hash-ref data 'metadata) hash?))
  (define cursos-json (any->hash-list (hash-ref data 'cursos)))
  
  (Catalogo (string->carrera (assert (hash-ref meta 'siglas) string?))
            (for/list ([c cursos-json]) (parsear-curso c))
            (any->string-list (hash-ref meta 'estudiante_historial))))

;; ==========================================
;; 2. LECTURA DE PREFERENCIAS (Nuevo archivo)
;; ==========================================

(: parsear-interes (-> (HashTable Symbol Any) Interes))
(define (parsear-interes i)
  (Interes (assert (hash-ref i 'codigo) string?)
           (any->num-list (hash-ref i 'grupos))))

(define (leer-preferencias-json ruta)
  (define data (assert (with-input-from-file ruta read-json) hash?))
  (Preferencias (for/list ([i (any->hash-list (hash-ref data 'cursos))]) 
                  (parsear-interes i))
                (assert (hash-ref data 'creditos_min) exact-nonnegative-integer?)
                (assert (hash-ref data 'creditos_max) exact-nonnegative-integer?)))