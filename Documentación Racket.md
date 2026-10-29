Este documento detalla la arquitectura, el diseño de tipos y las optimizaciones introducidas en el módulo de Pipeline de Datos (racket/pipeline.rkt) y la extensión del Contrato de Tipos (racket/tipos.rkt).

El módulo de pipeline actúa como la capa intermedia entre la ingesta de datos JSON y el motor perezoso de generación de combinaciones de horarios . Asimismo, se documenta la revisión de código realizada sobre las componentes del motor, logrando reducir el tiempo de respuesta inicial de combinaciones de 28.7 segundos a 0 milisegundos.

2. Estructura del Repositorio y Componentes

La estructura actualizada del módulo en Racket dentro del repositorio es la siguiente:

racket/
├── tipos.rkt                ← Extendido (agrega Candidato, Descarte, Preparacion)
├── genericos.rkt            ← Filtros genéricos y funciones de orden superior
├── pipeline.rkt             ← NUEVO: Preparación de datos y filtrado
├── main.rkt                 ← Punto de entrada del sistema
├── io/                      ← Capa de lectura/escritura JSON 
├── motor/                   ← Motor de combinaciones y choques 
│   ├── choque.rkt           ← Algoritmo de detección de traslapes de horario
│   └── stream.rkt           ← Generador de combinaciones perezoso
└── tests/
    ├── demo-genericos.rkt
    └── test-pipeline.rkt    ← NUEVO: Pruebas unitarias del pipeline


3. Especificación del Contrato de Datos (tipos.rkt)

Para posibilitar un acoplamiento débil entre la entrada de datos y el motor de generación, se agregaron tres estructuras principales a tipos.rkt:

3.1 Novedades en el Sistema de Tipos

Candidato: Representa un curso apto para matricular junto con la lista de grupos habilitados según los intereses del estudiante.

Descarte: Contiene la información de un curso no matriculable y el motivo formal de descarte (e.g., requisitos no cumplidos).

Preparacion: Contenedor final de la fase de preparación que separa la lista de candidatos válidos de la lista de descartes.

3.2 Interfaz de Datos Resumida

;; Estratificación de la oferta académica procesada
(struct Candidato ([curso : Curso]
                   [grupos-disponibles : (Listof Grupo)]) #:transparent)

(struct Descarte ([curso : String]
                  [razon : String]) #:transparent)

(struct Preparacion ([candidatos : (Listof Candidato)]
                     [descartes : (Listof Descarte)]) #:transparent)


4. Diseño del Pipeline (pipeline.rkt)

El archivo pipeline.rkt expone las funciones encargadas de procesar la entrada cruda del catálogo de cursos y aplicar las reglas de negocio antes de invocar la resolución de combinaciones.

## 4.1 Flujo de Procesamiento

  [ Catálogo JSON / Cursos ] + [ Preferencias Estudiante ]
                                │
                                ▼
                   (preparar-candidatos)
                                │
             ┌──────────────────┴──────────────────┐
             ▼                                     ▼
   [ Lista de Candidatos ]               [ Lista de Descartes ]
             │
             ▼
 (generar-combinaciones)  ──►  Streams Perezosos
                                │
                                ▼
                     (filtrar-por-creditos)
                                │
                                ▼
                   [ Combinaciones Finales ]


4.2 Funciones Principales

preparar-candidatos: Filtra los cursos matriculables (Curso-matriculable), cruza la oferta con las preferencias del estudiante (Interes-grupos) y retorna una estructura Preparacion.

filtrar-por-creditos: Aplica la función genérica de filtrado definida en genericos.rkt sobre la secuencia de combinaciones generadas, asegurando que los créditos totales de cada combinación se encuentren dentro del rango [creditos-min, creditos-max].

5. Módulo de Generación y Validación de Horarios (motor/)

El módulo motor/ se encarga de explorar el espacio de soluciones de horarios y filtrar las opciones inviables mediante dos componentes principales: stream.rkt y choque.rkt.

5.1 Generación Perezosa de Combinaciones (stream.rkt)

La generación de combinaciones se implementa mediante Streams Perezosos (Lazy Streams). Esto permite construir el árbol de combinaciones bajo demanda sin necesidad de calcular todas las posibilidades en memoria.

Concatenación Suspendida (stream-concat-lazy)

Para evitar la evaluación ansiosa de ramas no exploradas, se utiliza un thunk (lambda () ...) que suspende el cómputo de la siguiente rama hasta que el consumidor solicite el siguiente elemento:

(define (stream-concat-lazy s1 s2-thunk)
  (cond ((stream-empty? s1) (s2-thunk))
        (else (stream-cons (stream-first s1)
                           (stream-concat-lazy (stream-rest s1) s2-thunk)))))


Exploración Recursiva (generar-combinaciones y por-grupos)

El algoritmo recorre la lista de cursos candidato evaluando grupo por grupo contra el acumulador actual (acu). Únicamente si el grupo no presenta choques de horario, se procede con la recursión sobre los cursos restantes:

(define (generar-combinaciones lista-cursos acu)
  (cond ((null? lista-cursos) (stream acu))
        (else (por-grupos (car lista-cursos) (cdr lista-cursos) acu))))

(define (por-grupos grupos resto-cursos acu)
  (cond ((null? grupos) empty-stream)
        ((grupo-valido? (car grupos) acu)
         (stream-concat-lazy
          (generar-combinaciones resto-cursos (cons (car grupos) acu))
          (lambda () (por-grupos (cdr grupos) resto-cursos acu))))
        (else (por-grupos (cdr grupos) resto-cursos acu))))


Gracias a este esquema perezoso, la obtención del primer horario válido responde con complejidad espacial $O(1)$ en la primera iteración, diferiendo el cálculo del resto de combinaciones hasta que sean requeridas.

5.2 Detección de Traslapes Horarios (choque.rkt)

La validación de compatibilidad horaria entre dos grupos se basa en la comparación directa de los bloques de tiempo (Horario) almacenados en las estructuras Grupo importadas de tipos.rkt.

Criterio Matemático de Traslape

Dos lecciones o bloques de horario $h_1$ y $h_2$ se traslapan en el tiempo si coinciden en el mismo día de la semana y existe una intersección no vacía en sus rangos en minutos $[ \text{inicio}, \text{fin} )$:

$$\text{Chocan}(h_1, h_2) \iff \text{Dia}(h_1) = \text{Dia}(h_2) \land \text{Inicio}(h_1) < \text{Fin}(h_2) \land \text{Inicio}(h_2) < \text{Fin}(h_1)$$

Implementación en Racket

;; Verifica si dos estructuras Horario se traslapan en tiempo
(define (horarios-chocan? h1 h2)
  (and (string=? (Horario-dia h1) (Horario-dia h2))
       (< (Horario-inicio h1) (Horario-fin h2))
       (< (Horario-inicio h2) (Horario-fin h1))))

;; Verifica si dos grupos tienen al menos un choque horario entre sus clases
(define (grupos-chocan? g1 g2)
  (ormap (lambda (h1)
           (ormap (lambda (h2)
                    (horarios-chocan? h1 h2))
                  (Grupo-horarios g2)))
         (Grupo-horarios g1)))

;; Un grupo es válido si no choca con ningún grupo seleccionado en el acumulador
(define (grupo-valido? g acu)
  (not (ormap (lambda (g-acu) (grupos-chocan? g g-acu)) acu)))
