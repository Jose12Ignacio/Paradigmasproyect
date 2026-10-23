#lang typed/racket
;; tipos.rkt — contrato de datos entre los 3 módulos (equivalente al models.h de C).
;; Refleja el JSON real de la Etapa 1 (version_esquema 1.1). Todas las structs y listas son inmutables.

(provide (all-defined-out))

;; Literales de string: coinciden 1 a 1 con lo que trae el JSON ("CE", "K", ...)
(define-type Carrera (U "CE" "ATI"))
(define-type Dia (U "L" "K" "M" "J" "V" "S"))   ; K = Martes, M = Miércoles

(struct Horario ([dia : Dia] [inicio : Natural] [fin : Natural]) #:transparent) ; minutos desde medianoche

(struct Grupo ([curso : String]            ; código del curso al que pertenece (el JSON lo trae anidado; se agrega al leer)
               [numero : Natural]
               [profesor : String]
               [horarios : (Listof Horario)]) #:transparent)

(struct Curso ([codigo : String]
               [nombre : String]
               [creditos : Natural]
               [semestre : Natural]
               [carrera : Carrera]
               [requisitos : (Listof String)]
               [correquisitos : (Listof String)]
               [grupos : (Listof Grupo)]
               [matriculable : Boolean]          ; es_matriculable
               [razon : (Option String)]) #:transparent) ; razon_no_matriculable (null -> #f)

(struct Catalogo ([siglas : Carrera]
                  [cursos : (Listof Curso)]
                  [historial : (Listof String)]) #:transparent) ; metadata.estudiante_historial

;; Preferencias del estudiante (archivo nuevo de la Etapa 2; formato a confirmar con Persona 1)
(struct Interes ([curso : String] [grupos : (Listof Natural)]) #:transparent)
(struct Preferencias ([intereses : (Listof Interes)]
                      [creditos-min : Natural]
                      [creditos-max : Natural]) #:transparent)

;; Salida: una combinación = un grupo por curso
(struct Seleccion ([curso : String] [grupo : Natural] [carrera : Carrera]) #:transparent)
(struct Combinacion ([selecciones : (Listof Seleccion)]
                     [creditos-totales : Natural]) #:transparent)

;; ---- Conversiones de la frontera JSON -> tipos (las usa el lector de Persona 1) ----

(: hora->minutos (-> String Natural))
(define (hora->minutos s)
  (match (string-split s ":")
    [(list h m)
     (let ([hh (string->number h)] [mm (string->number m)])
       (if (and (exact-nonnegative-integer? hh) (exact-nonnegative-integer? mm))
           (+ (* 60 hh) mm)
           (error 'hora->minutos "hora invalida: ~a" s)))]
    [_ (error 'hora->minutos "se esperaba HH:MM, se recibio: ~a" s)]))

(: string->dia (-> String Dia))
(define (string->dia s)
  (cond [(string=? s "L") "L"] [(string=? s "K") "K"] [(string=? s "M") "M"]
        [(string=? s "J") "J"] [(string=? s "V") "V"] [(string=? s "S") "S"]
        [else (error 'string->dia "letra de dia desconocida: ~a" s)]))

(: string->carrera (-> String Carrera))
(define (string->carrera s)
  (cond [(string=? s "CE") "CE"] [(string=? s "ATI") "ATI"]
        [else (error 'string->carrera "carrera desconocida: ~a" s)]))
