#lang typed/racket
;; tipos.rkt — contrato de datos entre los 3 módulos (equivalente al models.h de C).
;; Refleja el JSON real de la Etapa 1 (version_esquema 1.2). Todas las structs y listas son inmutables.

(provide (all-defined-out))

;; Literales de string: coinciden 1 a 1 con lo que trae el JSON ("CE", "K", ...)
(define-type Carrera (U "CE" "ATI"))
(define-type Dia (U "L" "K" "M" "J" "V" "S"))   ; K = Martes, M = Miércoles

(struct Horario ([dia : Dia] [inicio : Natural] [fin : Natural]) #:transparent)

(struct Grupo ([curso : String]
               [numero : Natural]
               [profesor : String]
               [horarios : (Listof Horario)]) #:transparent)

(struct Curso ([codigo : String]
               [nombre : String]
               [creditos : Natural]
               [semestre : Natural]
               [carrera : Carrera]
               [area : String]
               [requisitos : (Listof String)]
               [correquisitos : (Listof String)]
               [grupos : (Listof Grupo)]
               [matriculable : Boolean]
               [razon : (Option String)]) #:transparent)

(struct Catalogo ([siglas : Carrera]
                  [cursos : (Listof Curso)]
                  [historial : (Listof String)]) #:transparent)

(struct Interes ([curso : String] [grupos : (Listof Natural)]) #:transparent)

(struct Preferencias ([intereses : (Listof Interes)]
                      [creditos-min : Natural]
                      [creditos-max : Natural]) #:transparent)

(struct Seleccion ([curso : String]
                   [grupo : Natural]
                   [creditos : Natural]
                   [carrera : Carrera]
                   [area : String]) #:transparent)

(struct Combinacion ([selecciones : (Listof Seleccion)]
                     [creditos-totales : Natural]) #:transparent)

;; ---- Conversiones de la frontera JSON -> tipos ----

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

;; ---- Interfaz entre la preparación y el generador de combinaciones ----

(struct Candidato ([curso : Curso] [grupos : (Listof Grupo)]) #:transparent)
(struct Descarte ([curso : String] [razon : String]) #:transparent)
(struct Preparacion ([candidatos : (Listof Candidato)]
                     [descartes : (Listof Descarte)]) #:transparent)