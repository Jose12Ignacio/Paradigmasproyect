## 2.1 Arquitectura del proyecto

El módulo en C se organiza en capas separadas por archivo:

- **`models.h`**: definición de las structs del dominio (`Curso`, `Grupo`,
  `Horario`, `Catalogo`). No contiene lógica, solo tipos.
- **`constants.h`**: todas las constantes del programa (tamaños máximos de
  arreglos, etc.), separadas del código para facilitar ajustes sin tocar
  la lógica.
- **`memoria.h` / `memoria.c`**: gestión dinámica del catálogo
  (`crear_catalogo`, `agregar_curso`, `liberar_catalogo`).
- **`Logic.h` / `Horarios_choque.C`**: detección de choques de horario y
  validación de requisitos/correquisitos.
- **`convertir_excel.py`**: script de conversión del plan de estudios
  institucional (Excel) a los CSV de entrada del programa en C.
- **`main.c`**: punto de entrada que integra todo lo anterior. _(pendiente
  de integración final)_

**Flujo de datos:**

```
Excel plan de estudios
        │  (convertir_excel.py)
        ▼
catalogo_CE.csv / catalogo_ATI.csv
        │  (loader en C, pendiente)
        ▼
Catalogo en memoria (structs de models.h)
        │
        ├── detectar_choques_catalogo()   → marca tieneChoqueHorario
        └── evaluar_elegibilidad_curso()  → marca esMatriculable
        │
        ▼
Archivo de salida (contrato para la Etapa 2 en Racket)
```
## 2.2 Algoritmos de manejo de información y modelo lógico
Los algoritmos desarollados en Horarios_choques permiten verificar que los cursos que estén en catalogo no choquen por horarios y se tenga una verificación de los requisitos y correquisitos para poder matricular el curso deseado.
La lógica del programa es encargarse de procesar el catálogo de cursos cargado en memoria para determinar dos aspectos críticos: la colisión de horarios entre asignaturas y la elegibilidad académica del estudiante según su historial.


## 2.3 Estructuras de datos desarrolladas

### `Horario`
Representa un bloque de tiempo (un día y un rango de horas). Las horas se
almacenan como enteros en minutos desde medianoche en lugar de strings,
para que la detección de choques se reduzca a comparar intervalos
numéricos en vez de parsear texto en cada comparación.

### `Grupo`
Una sección específica de un curso, con uno o más `Horario` (un curso puede
reunirse en varios días) y el nombre del profesor a cargo. Se usó un
arreglo fijo de bloques (`MAX_BLOQUES_POR_GRUPO`) porque, en el catálogo
real recolectado (317 filas para Ingeniería en Computadores), ningún grupo
supera los 2-3 bloques semanales.

### `Curso`
Agrupa la información oficial del curso (código, nombre, créditos, semestre
del plan de estudios), sus grupos disponibles, sus requisitos/correquisitos,
y dos banderas calculadas por el módulo lógico: `tiene_choque` y
`es_elegible`. Mantener estas banderas dentro de la misma struct evita
sincronizar estructuras paralelas al momento de exportar.

### `Catalogo`
Colección de todos los cursos cargados. A diferencia de las structs
anteriores, `Catalogo.cursos` se reserva dinámicamente con
`malloc`/`realloc` en lugar de un arreglo de tamaño fijo, porque el número
real de cursos (dos carreras × 4 semestres) varía según la carrera elegida
por el grupo y no se conoce en tiempo de compilación.

**Gestión de memoria:** `liberar_catalogo` libera primero el arreglo interno
y después el catálogo, en ese orden. `agregar_curso` usa una variable
temporal al hacer `realloc`, para no perder el puntero original si la
reserva de memoria falla. Se verificó ausencia de fugas con
`valgrind --leak-check=full`. _(agregar resultado/captura una vez esté
`main.c` integrado)_

---

### Aporte al caso límite (2.2.2): el campo `dia`



El catálogo se recibe como CSV generado a partir del Excel institucional.
Ese script codifica cada día de la semana con una sola letra: `L, K, M, J,
V, S`. El problema es que esta abreviatura **no sigue el orden alfabético
intuitivo**: como `M` ya está tomada por "Martes" en la abreviatura de tres
letras (`MAR`), "Miércoles" usa `M` y "Martes" usa `K`:

| Letra | Día |
|---|---|
| L | Lunes |
| K | **Martes** |
| M | **Miércoles** |
| J | Jueves |
| V | Viernes |
| S | Sábado |

Si se asume el orden "obvio", la detección de choques falla silenciosamente:
dos cursos que chocan un martes se comparan como si fueran días distintos.
**Solución:** `Dia` se definió como `enum` (no texto) en `models.h`, con la
conversión letra→enum centralizada en una sola función (`letra_a_dia()`),
para que la convención se corrija en un solo lugar si hace falta.

## 2.4 Módulo I/O y Dataset 

### 2.4.1 Recolección y limpieza del dataset

El dataset se construyó a partir del **plan de estudios oficial del TEC** y la **Guía de Horarios institucional**, cubriendo los primeros 4 semestres de dos carreras:

- **Ingeniería en Computadores (CE)**: 27 cursos
- **Administración de Tecnologías de Información (ATI)**: 27 cursos

La información se recolectó y limpió manualmente en un archivo Excel intermedio, que luego se convirtió a formato CSV mediante un script en Python (`convertir_excel.py`). Esta separación (Excel manual → CSV programático) permite auditar visualmente cada corrección aplicada al dataset y evita errores de transcripción directa.

**Estructura del Excel fuente**:

| Hoja | Contenido |
|---|---|
| `CE` | Plan de estudios de CE (cursos, créditos, requisitos, correquisitos) |
| `ATI` | Plan de estudios de ATI (mismo formato) |
| `Grupos CE` | Horarios y profesores de cada grupo de CE |
| `Grupos ATI` | Horarios y profesores de cada grupo de ATI |

**Resultado de la limpieza**: los CSV generados contienen 316 filas para CE y 210 filas para ATI, donde cada fila representa un bloque horario de un grupo específico.

### 2.4.2 Formato de salida: justificación y contrato con Etapa 2

**Decisión:** el formato de salida del módulo en C es **JSON**, con **un archivo por carrera** (`catalogo_CE.json` y `catalogo_ATI.json`).

**Justificación técnica ligada al problema**:

1. **La estructura de los datos es jerárquica, no tabular.** Un curso contiene múltiples grupos, y cada grupo contiene múltiples bloques horarios. Adicionalmente, cada curso tiene listas de requisitos y correquisitos de tamaño variable. Representar esta jerarquía en CSV obliga a duplicar la información del curso en cada fila o a inventar sub-formatos frágiles dentro de una celda (ej. `"1:L-07:30-09:20|2:K-13:30-15:20"`).

2. **El consumidor es Racket.** La Etapa 2 lee este archivo con `(read-json)`, obteniendo directamente listas y hashes nativos. Con CSV, el parser tendría que reagrupar filas por código y parsear strings de horarios, reconstruyendo en la Etapa 2 la estructura que ya existía en la Etapa 1.

3. **Fidelidad de tipos.** JSON distingue `true`/`false` booleanos de strings, y números de strings. En CSV todo es texto y el consumidor debe convertir. Los flags `tiene_choque` y `es_matriculable` se leen como `#t`/`#f` en Racket sin conversión.

**Esquema del JSON**:

```json
{
  "metadata": {
    "carrera": "Ingeniería en Computadores",
    "siglas": "CE",
    "semestres_incluidos": [0, 1, 2, 3, 4],
    "total_cursos": 27,
    "version_esquema": "1.1",
    "fecha_generacion": "2026-09-22"
  },
  "cursos": [
    {
      "codigo": "CE-1101",
      "nombre": "Introducción a la Programación",
      "creditos": 3,
      "semestre": 1,
      "requisitos": [],
      "correquisitos": [],
      "grupos": [
        {
          "numero": 1,
          "profesor": "Schmidt Peralta Jeff",
          "horarios": [
            { "dia": "K", "hora_inicio": "07:30", "hora_fin": "09:20" },
            { "dia": "J", "hora_inicio": "07:30", "hora_fin": "09:20" }
          ]
        }
      ],
      "tiene_choque": false,
      "cursos_con_choque": [],
      "es_matriculable": true,
      "razon_no_matriculable": null
    }
  ]
}