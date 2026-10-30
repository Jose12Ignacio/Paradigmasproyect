2.1 Arquitectura del proyecto (Etapa 2: Racket)

El módulo de Racket es un programa independiente: lee el JSON que produjo la Etapa 1 (C) y el archivo de
preferencias del estudiante, genera las combinaciones de horario sin choques, las filtra por el rango de
créditos y exporta el archivo que leerá la Etapa 3 (Prolog).

```
catalogo_CE.json (Etapa 1, C)              preferencias del estudiante
            │                                          │
            └────── io/lectura · io/preferencias ──────┘
                                  │  Catalogo + Preferencias           (tipos.rkt)
                                  ▼
                  pipeline.rkt · preparar-candidatos
                                  │  (Listof Candidato) + descartes
                                  ▼
                  motor/ · generar-combinaciones   (stream perezoso, sin choques)
                                  │  (Sequenceof Combinacion)
                                  ▼
                  pipeline.rkt · filtrar-por-creditos   (genericos.rkt)
                                  ▼
                  io/exportador → archivo de salida → Etapa 3 (Prolog)
```

- `racket/tipos.rkt` (Typed Racket): estructuras de datos compartidas y conversiones del JSON.
- `racket/genericos.rkt` (Typed Racket): funciones con polimorfismo paramétrico (`filtrar-por`, `criterio-rango`).
- `racket/pipeline.rkt` (Typed Racket): preparación de candidatos y filtro de créditos.
- `racket/main.rkt` (Typed Racket): integra el pipeline y declara el contrato de cada módulo.
- `racket/io/` ([completar: Persona 1]): lectura del catálogo y de las preferencias, y exportador.
- `racket/motor/` (Racket sin tipos): `stream.rkt` (combinaciones perezosas), `choque.rkt` (choques calculados desde los horarios) y `combinaciones.rkt` (adaptador al contrato de `main.rkt`).
- `racket/tests/` (Typed Racket): `test-pipeline.rkt` y la demostración del filtro genérico.

Frontera entre módulos tipados y no tipados. `main.rkt` importa cada módulo de sus compañeros con
`require/typed`, de modo que esas cuatro declaraciones son el contrato que cada módulo debe cumplir
(por ejemplo, `generar-combinaciones : (Listof Candidato) -> (Sequenceof Combinacion)`). Si un módulo no
respeta su tipo, el error aparece en la frontera y con el nombre de la función, no más adentro.

2.2.1 Decisiones de diseño propias

Typed Racket en el núcleo y sin tipos en el generador. Se eligió Typed Racket para modelar los datos y
para escribir las funciones genéricas, porque permite expresar el polimorfismo paramétrico con `All`.
Al probarlo (Racket 8.10) se encontró que `racket/stream` no trae tipos en Typed Racket y que `stream-cons`
no se puede usar desde código tipado. Las funciones como `stream-filter` sí se importan con
`require/typed`, que es lo que hace `genericos.rkt`; el generador, que necesita `stream-cons`, se escribe
en Racket sin tipos y se conecta a través del contrato de `main.rkt`.

Días y carreras como tipos literales. `Dia` y `Carrera` son uniones de strings literales
(`"L" "K" "M" "J" "V" "S"` y `"CE" "ATI"`), idénticos a los valores del JSON. Los valores inválidos se
rechazan al leer (`string->dia`, `string->carrera`) con un mensaje claro, en lugar de propagarse.
Ejemplo real del plan de estudios: `K` es martes y `M` es miércoles.

Horas como minutos desde medianoche. El JSON trae `"07:30"`; `hora->minutos` la convierte una sola vez
a un `Natural` (450), así que comparar horarios es aritmética y no manipulación de texto.

La preparación no falla: descarta y explica. `preparar-candidatos` convierte los cursos de interés en
`Candidato` (un curso y los grupos entre los que se puede elegir). Lo que no puede entrar al generador
se devuelve como `Descarte` con su razón, en vez de abortar el programa:

- El curso no existe en el catálogo: se descarta con la razón "no existe en el catalogo".
- El estudiante no cumple los requisitos: se descarta con la razón que calculó la Etapa 1.
- El curso no tiene grupos con horario (por ejemplo `CI-0205`): se descarta con "no tiene grupos con horario".
- Se pidieron grupos que no existen: se descarta con "ninguno de los grupos pedidos existe".
- El curso aparece repetido en las preferencias: se descarta con "repetido en las preferencias".
- La lista de grupos viene vacía: se consideran todos los grupos del curso.
- La lista trae varios grupos: se consideran solo esos grupos.

Polimorfismo paramétrico. Hay dos funciones genéricas en `genericos.rkt`:

```racket
(: filtrar-por (All (A) (-> (-> A Boolean) (Sequenceof A) (Sequenceof A))))
(: criterio-rango (All (A) (-> (-> A Natural) Natural Natural (-> A Boolean))))
```

`filtrar-por` filtra cualquier secuencia perezosa con cualquier predicado; `criterio-rango` construye el
predicado "el número que extrae `medida` está entre un mínimo y un máximo". Como `A` es abstracto, la
función no puede depender de la forma de los elementos, y una sola definición sirve para todos los casos.
En el pipeline se usa con `A = Combinacion` para filtrar por créditos totales, y en
`tests/demo-genericos.rkt` con `A = String`, con exactamente las mismas funciones.

Inmutabilidad y recursión. Todas las structs y listas son inmutables y no se usa `set!` en ningún
archivo. El recorrido de las preferencias en `preparar-candidatos` se hace con recursión (`let` con nombre)
y acumuladores que se pasan como argumentos.

Pruebas. `tests/test-pipeline.rkt` cubre los casos de la tabla anterior y el filtro de créditos
(extremos incluidos). Se ejecuta con `racket racket/tests/test-pipeline.rkt`.

2.3 Estructuras de datos desarrolladas

Todas están en `racket/tipos.rkt` y son inmutables (`#:transparent`).

- `Horario` (`dia`, `inicio`, `fin`): un bloque de tiempo; las horas van en minutos.
- `Grupo` (`curso`, `numero`, `profesor`, `horarios`): una sección de un curso.
- `Curso` (`codigo`, `nombre`, `creditos`, `semestre`, `carrera`, `requisitos`, `correquisitos`, `grupos`, `matriculable`, `razon`): un curso del catálogo de la Etapa 1. `razon` es `#f` cuando el JSON trae `null`.
- `Catalogo` (`siglas`, `cursos`, `historial`): el catálogo leído, con el historial del estudiante.
- `Interes` (`curso`, `grupos`): un curso que el estudiante quiere, con los grupos que acepta.
- `Preferencias` (`intereses`, `creditos-min`, `creditos-max`): contenido del archivo de preferencias.
- `Candidato` (`curso`, `grupos`): entrada del generador; de aquí se elige un solo grupo.
- `Descarte` (`curso`, `razon`): un curso pedido que no entra, y por qué.
- `Preparacion` (`candidatos`, `descartes`): resultado de `preparar-candidatos`.
- `Seleccion` (`curso`, `grupo`, `carrera`): un par curso-grupo dentro de una combinación.
- `Combinacion` (`selecciones`, `creditos-totales`): un horario posible, listo para exportar.

`Candidato` es la interfaz entre la preparación y el generador: el generador no necesita conocer las
preferencias ni el catálogo, solo recibe qué cursos y qué grupos puede combinar.

### 2.2.2 Decisiones de diseño: Módulo I/O y Contrato de Salida 

**El formato de salida hacia Prolog (JSON).** Se decidió que la salida de la Etapa 2 sea un archivo JSON (`salida_etapa2.json`). Esta decisión se basa en que Prolog puede parsear JSON de forma sencilla mediante librerías estándar, y mantiene la consistencia con la Etapa 1. El archivo incluye un `id_combinacion` para que Prolog pueda referenciar y descartar horarios completos, los `creditos_totales` de esa combinación, y un arreglo de `selecciones`. Cada selección contiene el par exacto `curso`, `grupo` y la `carrera` de origen del curso, cumpliendo así con los requerimientos mínimos exigidos para esta fase.

**Manejo de vectores JSON a listas en Typed Racket.** Al leer el JSON generado por C, la librería `read-json` de Racket interpreta los arreglos como *vectores*, no como listas. Como nuestras estructuras en `tipos.rkt` exigen listas inmutables, el `io/lector.rkt` implementa funciones de conversión seguras (`any->hash-list`, `any->string-list` y `any->num-list`) que transforman los datos respetando el tipado estricto de Typed Racket.

**Lectura tolerante a fallos y descartes.** El módulo `io/lector.rkt` lee el JSON del catálogo y el archivo `preferencias.json`. Para evitar que un archivo de preferencias mal escrito detenga el programa, cualquier curso pedido que no exista, no tenga grupos o no sea matriculable se maneja mediante la estructura `Descarte` en el `pipeline.rkt`, permitiendo que el flujo continúe procesando los cursos válidos.

### 2.2.3 Caso límite real encontrado en la Etapa 2

**El problema del `list->stream` y los tipos estrictos.**
Durante la integración del motor de combinaciones (que usa streams) con el exportador, nos topamos con un problema de tipos: la función `filtrar-por-creditos` devolvía una secuencia perezosa (Stream) que necesitaba ser convertida a lista para exportarse. Intentamos usar funciones nativas como `stream->list`, pero Typed Racket rechazaba la compilación indicando *"missing type for identifier"*. 

**Solución:** En lugar de forzar un `cast` inseguro, optamos por la solución puramente funcional: utilizar `for/list` nativo de Racket, que es capaz de iterar sobre secuencias perezosas (Streams) y construir la lista final, permitiendo anotar explícitamente el tipo de salida: `(for/list : (Listof Combinacion) ([c stream]) c)`. Esto resolvió el error de tipado y mantuvo el principio de inmutabilidad.

### 2.3.1 Estructuras de datos del módulo I/O

Además de las estructuras principales definidas en `tipos.rkt`, el módulo de lectura maneja internamente:
- **HashTables genéricos:** Al leer el JSON, los objetos se reciben como `(HashTable Symbol Any)`. Usamos aserciones de tipo (`assert`) para asegurar que campos como `"dia"` o `"hora_inicio"` son strings antes de pasarlos a las funciones de conversión (`string->dia`, `hora->minutos`).
- **Conversión de preferencias:** El archivo `preferencias.json` se parsea a la estructura `Preferencias`, que contiene una lista de `Interes`. Si un interés no especifica grupos (lista vacía), el `pipeline` asume que se pueden tomar todos los grupos disponibles de ese curso.

### 2.4 Instrucciones de ejecución

Para probar el flujo completo de la Etapa 2 (desde la lectura de C hasta la exportación para Prolog), ejecutar desde la raíz del proyecto:

```bash
racket racket/test_e2e.rkt