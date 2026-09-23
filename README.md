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
Los algoritmos desarollados en Horarios_choques permiten verificar que los cursos que estén en catalogo no choquen por horarios como  `horarios_choque` y `grupo_choque` y se tenga una verificación de los requisitos y correquisitos para poder matricular el curso con `evaluar_elegibilidad_curso`.
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
```

### 3.1 Manual de Usuario: Compilación y Ejecución

Tener instalado el Compilador GCC (MinGW-w64 / MSYS2 en Windows) y configurar la terminal para decodificar UTF-8.

Ejecutar en la terminal el siguiente comando gcc -Wall -Wextra -g3 main.c memoria.c Horarios_choque.c io.c serializar.c -o output/main.exe

Luego ejecutar el siguiente comando .\output\main.exe

# En PowerShell para garantizar caracteres UTF-8 en consola:
chcp 65001 | Out-Null
.\output\main.exe data/catalogo_CE.csv data/historial_CE.txt output/catalogo_CE.json


## Prueba con Valgrind y gestión de memoria
Se verificó ausencia de fugas con `valgrind --leak-check=full` sobre el
programa completo integrado (`main.c` + todos los módulos), pasando el
catálogo real (27 cursos, 317 filas de horario). Resultado:
dilan@Brownie-laptop:/mnt/c/Users/dilan/OneDrive/Desktop/ParadigmasProyecto/ParadigmasProyect$ valgrind --leak-check=full ./programa data/catalogo_CE.csv historial.txt data/catalogo_CE_salida.json
==4645== Memcheck, a memory error detector
==4645== Copyright (C) 2002-2024, and GNU GPL'd, by Julian Seward et al.
==4645== Using Valgrind-3.26.0 and LibVEX; rerun with -h for copyright info
==4645== Command: ./programa data/catalogo_CE.csv historial.txt data/catalogo_CE_salida.json
==4645==
==================================================
         PLANIFICADOR ACADÉMICO - ETAPA 1
==================================================

[OK] historial.txt: 0 cursos aprobados en el historial
[INFO] Historial cargado con éxito. Cursos aprobados: 0

[INFO] Cargando catálogo desde 'data/catalogo_CE.csv'...
[OK] data/catalogo_CE.csv: 317 filas leídas, 316 procesadas, 27 cursos en catálogo

--------------------------------------------------
Ejecutando procesamiento de lógica académica...
--------------------------------------------------

==================================================
                RESUMEN DE RESULTADOS
==================================================
 Total de cursos cargados : 27
 Cursos elegibles         : 7
 Cursos con choque horario: 26
--------------------------------------------------

DETALLE DE CURSOS EVALUADOS:
[CE-1101] Introducción a la programación    | Elegible: SÍ | Choque: SÍ | Grupos: 2
    └── Choca con: G2 con CE-1103 (G3), G1 con CE-1104 (G1), G1 con CE-2103 (G1), G2 con CS-1502 (G1), G2 con CS-2101 (G2), G2 con CS-2101 (G5), G2 con EL-2113 (G2), G2 con EL-2114 (G2), G1 con EL-2207 (G2), G1 con FI-1101 (G1), G1 con FI-1101 (G2), G2 con FI-1101 (G19), G2 con FI-1101 (G3), G2 con FI-1101 (G4), G1 con FI-1102 (G1), G1 con FI-1102 (G10), G2 con FI-1102 (G11), G2 con FI-1102 (G2), G2 con FI-1102 (G3), G1 con FI-1201 (G11), G1 con FI-1201 (G19), G2 con FI-1201 (G12), G2 con FI-1201 (G2), G2 con FI-1201 (G25), G2 con FI-1202 (G1), G2 con FI-1202 (G7), G1 con MA-0101 (G1), G2 con MA-0101 (G1), G2 con MA-0101 (G2), G1 con MA-1102 (G1), G1 con MA-1102 (G2), G2 con MA-1102 (G1), G2 con MA-1102 (G2), G2 con MA-1102 (G3), G2 con MA-1102 (G4), G1 con MA-1103 (G1), G1 con MA-1103 (G19), G1 con MA-1103 (G2), G2 con MA-1103 (G19), G2 con MA-1103 (G3), G2 con MA-2104 (G4), G1 con QU-1102 (G1), G1 con QU-1102 (G9), G2 con QU-1102 (G10), G2 con QU-1102 (G2), G1 con QU-1106 (G1), G1 con QU-1106 (G2), G2 con QU-1106 (G3)
[CE-1103] Algoritmos y estructuras de datos 1 | Elegible: NO | Choque: SÍ | Grupos: 3
    └── Motivo: No cumple requisitos: CE-1101, CE-1104, MA-1403
    └── Choca con: G3 con CE-1101 (G2), G1 con CE-1105 (G2), G2 con CI-1407 (G2), G2 con CI-1407 (G3), G1 con CS-1502 (G3), G2 con CS-1502 (G4), G3 con CS-1502 (G1), G1 con CS-2101 (G4), G3 con CS-2101 (G2), G3 con CS-2101 (G5), G3 con EL-2113 (G2), G1 con EL-2114 (G1), G3 con EL-2114 (G2), G1 con EL-2207 (G4), G2 con EL-2207 (G1), G1 con FI-1101 (G18), G2 con FI-1101 (G7), G2 con FI-1101 (G8), G3 con FI-1101 (G19), G3 con FI-1101 (G3), G3 con FI-1101 (G4), G3 con FI-1102 (G11), G3 con FI-1102 (G2), G3 con FI-1102 (G3), G1 con FI-1201 (G10), G1 con FI-1201 (G24), G2 con FI-1201 (G14), G2 con FI-1201 (G4), G3 con FI-1201 (G12), G3 con FI-1201 (G2), G3 con FI-1201 (G25), G3 con FI-1202 (G1), G3 con FI-1202 (G7), G1 con MA-0101 (G10), G1 con MA-0101 (G11), G2 con MA-0101 (G3), G2 con MA-0101 (G4), G2 con MA-0101 (G5), G3 con MA-0101 (G1), G3 con MA-0101 (G2), G1 con MA-1102 (G16), G1 con MA-1102 (G17), G1 con MA-1102 (G18), G1 con MA-1102 (G19), G1 con MA-1102 (G20), G2 con MA-1102 (G5), G2 con MA-1102 (G6), G2 con MA-1102 (G7), G2 con MA-1102 (G8), G3 con MA-1102 (G1)
[CE-1104] Fundamentos de sistemas computacionales | Elegible: NO | Choque: SÍ | Grupos: 1
    └── Motivo: No cumple correquisito: CE-1101
    └── Choca con: G1 con CE-1101 (G1), G1 con CE-2103 (G1), G1 con EL-2207 (G2), G1 con FI-1101 (G1), G1 con FI-1101 (G2), G1 con FI-1102 (G1), G1 con FI-1102 (G10), G1 con FI-1201 (G11), G1 con FI-1201 (G19), G1 con MA-0101 (G1), G1 con MA-1102 (G1), G1 con MA-1102 (G2), G1 con MA-1103 (G1), G1 con MA-1103 (G19), G1 con MA-1103 (G2), G1 con QU-1102 (G1), G1 con QU-1102 (G9), G1 con QU-1106 (G1), G1 con QU-1106 (G2)
[CE-1105] Principios de modelado en ingeniería | Elegible: NO | Choque: SÍ | Grupos: 3
    └── Motivo: No cumple requisito: CE-1104
    └── Choca con: G2 con CE-1103 (G1), G2 con CS-1502 (G3), G1 con CS-2101 (G8), G2 con CS-2101 (G4), G3 con CS-2101 (G8), G2 con EL-2114 (G1), G2 con EL-2207 (G4), G2 con FI-1101 (G18), G2 con FI-1201 (G10), G2 con FI-1201 (G24), G1 con MA-0101 (G6), G2 con MA-0101 (G10), G2 con MA-0101 (G11), G3 con MA-0101 (G6), G1 con MA-1102 (G10), G1 con MA-1102 (G9), G2 con MA-1102 (G16), G2 con MA-1102 (G17), G2 con MA-1102 (G18), G2 con MA-1102 (G19), G2 con MA-1102 (G20), G3 con MA-1102 (G10), G3 con MA-1102 (G9), G1 con MA-1103 (G10), G1 con MA-1103 (G9), G2 con MA-1103 (G15), G2 con MA-1103 (G16), G2 con MA-1103 (G17), G3 con MA-1103 (G10), G3 con MA-1103 (G9), G1 con MA-1403 (G3), G3 con MA-1403 (G3), G1 con MA-2104 (G2), G2 con MA-2104 (G5), G3 con MA-2104 (G2), G1 con SO-4604 (G3), G3 con SO-4604 (G3)
[CE-1106] Paradigmas de programación         | Elegible: NO | Choque: SÍ | Grupos: 2
    └── Motivo: No cumple requisito: CE-2103
    └── Choca con: G1 con CI-1407 (G4), G1 con CS-1502 (G2), G1 con CS-1502 (G5), G1 con CS-2101 (G1), G1 con CS-2101 (G3), G2 con CS-2101 (G8), G1 con EL-2113 (G1), G2 con EL-2114 (G4), G1 con EL-2207 (G4), G1 con FI-1101 (G13), G1 con FI-1101 (G14), G1 con FI-1101 (G20), G2 con FI-1101 (G9), G1 con FI-1102 (G7), G1 con FI-1201 (G17), G1 con FI-1201 (G22), G1 con FI-1201 (G7), G2 con FI-1201 (G15), G2 con FI-1201 (G27), G2 con FI-1201 (G5), G1 con FI-1202 (G5), G2 con FI-1202 (G3), G1 con MA-0101 (G7), G1 con MA-0101 (G8), G2 con MA-0101 (G4), G2 con MA-0101 (G5), G2 con MA-0101 (G6), G1 con MA-1102 (G11), G1 con MA-1102 (G12), G1 con MA-1102 (G13), G1 con MA-1102 (G14), G2 con MA-1102 (G10), G2 con MA-1102 (G6), G2 con MA-1102 (G7), G2 con MA-1102 (G8), G2 con MA-1102 (G9), G1 con MA-1103 (G12), G2 con MA-1103 (G10), G2 con MA-1103 (G7), G2 con MA-1103 (G8), G2 con MA-1103 (G9), G1 con MA-1403 (G2), G2 con MA-1403 (G3), G1 con MA-2104 (G1), G2 con MA-2104 (G2), G1 con QU-1102 (G6), G1 con QU-1106 (G9), G1 con SO-4604 (G5), G2 con SO-4604 (G3)
[CE-2103] Algoritmos y estructuras de datos 2 | Elegible: NO | Choque: SÍ | Grupos: 1
    └── Motivo: No cumple requisitos: CE-1103, CE-1105
    └── Choca con: G1 con CE-1101 (G1), G1 con CE-1104 (G1), G1 con EL-2207 (G2), G1 con FI-1101 (G1), G1 con FI-1101 (G2), G1 con FI-1102 (G1), G1 con FI-1102 (G10), G1 con FI-1201 (G11), G1 con FI-1201 (G19), G1 con MA-0101 (G1), G1 con MA-1102 (G1), G1 con MA-1102 (G2), G1 con MA-1103 (G1), G1 con MA-1103 (G19), G1 con MA-1103 (G2), G1 con QU-1102 (G1), G1 con QU-1102 (G9), G1 con QU-1106 (G1), G1 con QU-1106 (G2)
[CE-2201] Laboratorio de circuitos eléctricos | Elegible: NO | Choque: SÍ | Grupos: 2
    └── Motivo: No cumple requisito: FI-1202
    └── Choca con: G1 con CI-1407 (G1), G1 con CS-2101 (G6), G2 con CS-2101 (G6), G1 con EL-2113 (G3), G2 con EL-2113 (G3), G2 con EL-2113 (G4), G1 con PI-2609 (G1), G2 con PI-2609 (G1), G1 con SO-4604 (G1), G2 con SO-4604 (G1)
[CI-0205] Prueba avanzada de inglés          | Elegible: SÍ | Choque: NO | Grupos: 0
[CI-1407] Habilidades de Comunicación en Ingeniería | Elegible: SÍ | Choque: SÍ | Grupos: 4
    └── Choca con: G2 con CE-1103 (G2), G3 con CE-1103 (G2), G4 con CE-1106 (G1), G1 con CE-2201 (G1), G3 con CS-1502 (G4), G1 con CS-2101 (G6), G4 con CS-2101 (G1), G1 con EL-2113 (G3), G4 con EL-2113 (G1), G4 con EL-2114 (G3), G2 con EL-2207 (G1), G3 con EL-2207 (G1), G4 con EL-2207 (G4), G2 con FI-1101 (G5), G2 con FI-1101 (G6), G2 con FI-1101 (G7), G2 con FI-1101 (G8), G3 con FI-1101 (G5), G3 con FI-1101 (G6), G3 con FI-1101 (G7), G3 con FI-1101 (G8), G4 con FI-1101 (G11), G4 con FI-1101 (G13), G4 con FI-1101 (G14), G4 con FI-1101 (G20), G2 con FI-1102 (G4), G2 con FI-1102 (G5), G3 con FI-1102 (G4), G3 con FI-1102 (G5), G4 con FI-1102 (G6), G4 con FI-1102 (G7), G2 con FI-1201 (G14), G2 con FI-1201 (G26), G3 con FI-1201 (G29), G3 con FI-1201 (G3), G3 con FI-1201 (G4), G4 con FI-1201 (G16), G4 con FI-1201 (G17), G3 con FI-1202 (G2), G2 con MA-0101 (G3), G2 con MA-0101 (G4), G3 con MA-0101 (G3), G3 con MA-0101 (G4), G4 con MA-0101 (G7), G4 con MA-0101 (G8), G2 con MA-1102 (G5), G2 con MA-1102 (G6), G3 con MA-1102 (G5), G3 con MA-1102 (G6), G3 con MA-1102 (G8)
[CS-1502] Introducción a la técnica, ciencia y tecnología | Elegible: SÍ | Choque: SÍ | Grupos: 5
    └── Choca con: G1 con CE-1101 (G2), G3 con CE-1103 (G1), G4 con CE-1103 (G2), G1 con CE-1103 (G3), G3 con CE-1105 (G2), G2 con CE-1106 (G1), G5 con CE-1106 (G1), G4 con CI-1407 (G3), G1 con CS-2101 (G5), G2 con CS-2101 (G3), G3 con CS-2101 (G4), G5 con CS-2101 (G3), G1 con EL-2113 (G2), G2 con EL-2113 (G1), G5 con EL-2113 (G1), G1 con EL-2114 (G2), G3 con EL-2114 (G1), G3 con EL-2207 (G4), G4 con EL-2207 (G1), G1 con FI-1101 (G19), G1 con FI-1101 (G3), G1 con FI-1101 (G4), G2 con FI-1101 (G13), G2 con FI-1101 (G14), G2 con FI-1101 (G20), G3 con FI-1101 (G18), G4 con FI-1101 (G7), G4 con FI-1101 (G8), G5 con FI-1101 (G13), G5 con FI-1101 (G14), G5 con FI-1101 (G20), G1 con FI-1102 (G11), G1 con FI-1102 (G2), G1 con FI-1102 (G3), G2 con FI-1102 (G7), G5 con FI-1102 (G7), G1 con FI-1201 (G12), G1 con FI-1201 (G25), G2 con FI-1201 (G22), G2 con FI-1201 (G7), G3 con FI-1201 (G10), G3 con FI-1201 (G24), G4 con FI-1201 (G4), G5 con FI-1201 (G22), G5 con FI-1201 (G7), G1 con FI-1202 (G7), G2 con FI-1202 (G5), G5 con FI-1202 (G5), G1 con MA-0101 (G2), G2 con MA-0101 (G8)
[CS-2101] Ambiente humano                     | Elegible: SÍ | Choque: SÍ | Grupos: 8
    └── Choca con: G2 con CE-1101 (G2), G5 con CE-1101 (G2), G4 con CE-1103 (G1), G2 con CE-1103 (G3), G5 con CE-1103 (G3), G8 con CE-1105 (G1), G4 con CE-1105 (G2), G8 con CE-1105 (G3), G1 con CE-1106 (G1), G3 con CE-1106 (G1), G8 con CE-1106 (G2), G6 con CE-2201 (G1), G6 con CE-2201 (G2), G6 con CI-1407 (G1), G1 con CI-1407 (G4), G5 con CS-1502 (G1), G3 con CS-1502 (G2), G4 con CS-1502 (G3), G3 con CS-1502 (G5), G1 con EL-2113 (G1), G2 con EL-2113 (G2), G3 con EL-2113 (G1), G5 con EL-2113 (G2), G6 con EL-2113 (G3), G6 con EL-2113 (G4), G2 con EL-2114 (G2), G4 con EL-2114 (G1), G5 con EL-2114 (G2), G8 con EL-2114 (G4), G1 con EL-2207 (G4), G4 con EL-2207 (G3), G4 con EL-2207 (G4), G1 con FI-1101 (G13), G1 con FI-1101 (G14), G1 con FI-1101 (G20), G2 con FI-1101 (G19), G2 con FI-1101 (G3), G2 con FI-1101 (G4), G3 con FI-1101 (G13), G3 con FI-1101 (G14), G3 con FI-1101 (G20), G4 con FI-1101 (G17), G4 con FI-1101 (G18), G5 con FI-1101 (G19), G5 con FI-1101 (G3), G5 con FI-1101 (G4), G8 con FI-1101 (G9), G1 con FI-1102 (G7), G2 con FI-1102 (G11), G2 con FI-1102 (G2)
[EL-2113] Circuitos Eléctricos en Corriente Continua | Elegible: NO | Choque: SÍ | Grupos: 4
    └── Motivo: No cumple requisitos: FI-1101, MA-1102
    └── Choca con: G2 con CE-1101 (G2), G2 con CE-1103 (G3), G1 con CE-1106 (G1), G3 con CE-2201 (G1), G3 con CE-2201 (G2), G4 con CE-2201 (G2), G3 con CI-1407 (G1), G1 con CI-1407 (G4), G2 con CS-1502 (G1), G1 con CS-1502 (G2), G1 con CS-1502 (G5), G1 con CS-2101 (G1), G2 con CS-2101 (G2), G1 con CS-2101 (G3), G2 con CS-2101 (G5), G3 con CS-2101 (G6), G4 con CS-2101 (G6), G2 con EL-2114 (G2), G4 con EL-2114 (G3), G1 con EL-2207 (G4), G1 con FI-1101 (G13), G1 con FI-1101 (G14), G1 con FI-1101 (G20), G2 con FI-1101 (G19), G2 con FI-1101 (G3), G2 con FI-1101 (G4), G4 con FI-1101 (G11), G1 con FI-1102 (G7), G2 con FI-1102 (G11), G2 con FI-1102 (G2), G2 con FI-1102 (G3), G4 con FI-1102 (G6), G1 con FI-1201 (G17), G1 con FI-1201 (G22), G1 con FI-1201 (G7), G2 con FI-1201 (G12), G2 con FI-1201 (G2), G2 con FI-1201 (G25), G4 con FI-1201 (G6), G1 con FI-1202 (G5), G2 con FI-1202 (G1), G2 con FI-1202 (G7), G4 con FI-1202 (G4), G1 con MA-0101 (G7), G1 con MA-0101 (G8), G2 con MA-0101 (G1), G2 con MA-0101 (G2), G4 con MA-0101 (G7), G1 con MA-1102 (G11), G1 con MA-1102 (G12)
[EL-2114] Circuitos eléctricos en corriente alterna | Elegible: NO | Choque: SÍ | Grupos: 4
    └── Motivo: No cumple requisitos: EL-2113; correquisitos: EL-2207
    └── Choca con: G2 con CE-1101 (G2), G1 con CE-1103 (G1), G2 con CE-1103 (G3), G1 con CE-1105 (G2), G4 con CE-1106 (G2), G3 con CI-1407 (G4), G2 con CS-1502 (G1), G1 con CS-1502 (G3), G2 con CS-2101 (G2), G1 con CS-2101 (G4), G2 con CS-2101 (G5), G4 con CS-2101 (G8), G2 con EL-2113 (G2), G3 con EL-2113 (G4), G1 con EL-2207 (G4), G1 con FI-1101 (G18), G2 con FI-1101 (G19), G2 con FI-1101 (G3), G2 con FI-1101 (G4), G3 con FI-1101 (G11), G4 con FI-1101 (G9), G2 con FI-1102 (G11), G2 con FI-1102 (G2), G2 con FI-1102 (G3), G3 con FI-1102 (G6), G1 con FI-1201 (G10), G1 con FI-1201 (G24), G2 con FI-1201 (G12), G2 con FI-1201 (G2), G2 con FI-1201 (G25), G3 con FI-1201 (G16), G3 con FI-1201 (G6), G4 con FI-1201 (G15), G4 con FI-1201 (G27), G4 con FI-1201 (G5), G2 con FI-1202 (G1), G2 con FI-1202 (G7), G3 con FI-1202 (G4), G4 con FI-1202 (G3), G1 con MA-0101 (G10), G1 con MA-0101 (G11), G2 con MA-0101 (G1), G2 con MA-0101 (G2), G3 con MA-0101 (G7), G4 con MA-0101 (G4), G4 con MA-0101 (G5), G4 con MA-0101 (G6), G1 con MA-1102 (G16), G1 con MA-1102 (G17), G1 con MA-1102 (G18)
[EL-2207] Elementos activos                   | Elegible: NO | Choque: SÍ | Grupos: 4
    └── Motivo: No cumple requisito: EL-2113
    └── Choca con: G2 con CE-1101 (G1), G4 con CE-1103 (G1), G1 con CE-1103 (G2), G2 con CE-1104 (G1), G4 con CE-1105 (G2), G4 con CE-1106 (G1), G2 con CE-2103 (G1), G1 con CI-1407 (G2), G1 con CI-1407 (G3), G4 con CI-1407 (G4), G4 con CS-1502 (G3), G1 con CS-1502 (G4), G4 con CS-2101 (G1), G3 con CS-2101 (G4), G4 con CS-2101 (G4), G4 con EL-2113 (G1), G4 con EL-2114 (G1), G1 con FI-1101 (G7), G1 con FI-1101 (G8), G2 con FI-1101 (G1), G2 con FI-1101 (G2), G3 con FI-1101 (G17), G4 con FI-1101 (G13), G4 con FI-1101 (G14), G4 con FI-1101 (G18), G4 con FI-1101 (G20), G2 con FI-1102 (G1), G2 con FI-1102 (G10), G3 con FI-1102 (G9), G4 con FI-1102 (G7), G1 con FI-1201 (G14), G1 con FI-1201 (G4), G2 con FI-1201 (G11), G2 con FI-1201 (G19), G3 con FI-1201 (G23), G3 con FI-1201 (G9), G4 con FI-1201 (G10), G4 con FI-1201 (G17), G4 con FI-1201 (G24), G3 con FI-1202 (G6), G1 con MA-0101 (G3), G1 con MA-0101 (G4), G1 con MA-0101 (G5), G2 con MA-0101 (G1), G3 con MA-0101 (G10), G3 con MA-0101 (G11), G3 con MA-0101 (G9), G4 con MA-0101 (G10), G4 con MA-0101 (G11), G4 con MA-0101 (G7)
[FI-1101] Física general 1                   | Elegible: NO | Choque: SÍ | Grupos: 17
    └── Motivo: No cumple requisito: MA-1102
    └── Choca con: G1 con CE-1101 (G1), G2 con CE-1101 (G1), G19 con CE-1101 (G2), G3 con CE-1101 (G2), G4 con CE-1101 (G2), G18 con CE-1103 (G1), G7 con CE-1103 (G2), G8 con CE-1103 (G2), G19 con CE-1103 (G3), G3 con CE-1103 (G3), G4 con CE-1103 (G3), G1 con CE-1104 (G1), G2 con CE-1104 (G1), G18 con CE-1105 (G2), G13 con CE-1106 (G1), G14 con CE-1106 (G1), G20 con CE-1106 (G1), G9 con CE-1106 (G2), G1 con CE-2103 (G1), G2 con CE-2103 (G1), G5 con CI-1407 (G2), G6 con CI-1407 (G2), G7 con CI-1407 (G2), G8 con CI-1407 (G2), G5 con CI-1407 (G3), G6 con CI-1407 (G3), G7 con CI-1407 (G3), G8 con CI-1407 (G3), G11 con CI-1407 (G4), G13 con CI-1407 (G4), G14 con CI-1407 (G4), G20 con CI-1407 (G4), G19 con CS-1502 (G1), G3 con CS-1502 (G1), G4 con CS-1502 (G1), G13 con CS-1502 (G2), G14 con CS-1502 (G2), G20 con CS-1502 (G2), G18 con CS-1502 (G3), G7 con CS-1502 (G4), G8 con CS-1502 (G4), G13 con CS-1502 (G5), G14 con CS-1502 (G5), G20 con CS-1502 (G5), G13 con CS-2101 (G1), G14 con CS-2101 (G1), G20 con CS-2101 (G1), G19 con CS-2101 (G2), G3 con CS-2101 (G2), G4 con CS-2101 (G2)
[FI-1102] Física general 2                   | Elegible: NO | Choque: SÍ | Grupos: 11
    └── Motivo: No cumple requisitos: FI-1101; correquisitos: MA-1102
    └── Choca con: G1 con CE-1101 (G1), G10 con CE-1101 (G1), G11 con CE-1101 (G2), G2 con CE-1101 (G2), G3 con CE-1101 (G2), G11 con CE-1103 (G3), G2 con CE-1103 (G3), G3 con CE-1103 (G3), G1 con CE-1104 (G1), G10 con CE-1104 (G1), G7 con CE-1106 (G1), G1 con CE-2103 (G1), G10 con CE-2103 (G1), G4 con CI-1407 (G2), G5 con CI-1407 (G2), G4 con CI-1407 (G3), G5 con CI-1407 (G3), G6 con CI-1407 (G4), G7 con CI-1407 (G4), G11 con CS-1502 (G1), G2 con CS-1502 (G1), G3 con CS-1502 (G1), G7 con CS-1502 (G2), G7 con CS-1502 (G5), G7 con CS-2101 (G1), G11 con CS-2101 (G2), G2 con CS-2101 (G2), G3 con CS-2101 (G2), G7 con CS-2101 (G3), G9 con CS-2101 (G4), G11 con CS-2101 (G5), G2 con CS-2101 (G5), G3 con CS-2101 (G5), G7 con EL-2113 (G1), G11 con EL-2113 (G2), G2 con EL-2113 (G2), G3 con EL-2113 (G2), G6 con EL-2113 (G4), G11 con EL-2114 (G2), G2 con EL-2114 (G2), G3 con EL-2114 (G2), G6 con EL-2114 (G3), G1 con EL-2207 (G2), G10 con EL-2207 (G2), G9 con EL-2207 (G3), G7 con EL-2207 (G4), G1 con FI-1101 (G1), G10 con FI-1101 (G1), G6 con FI-1101 (G11), G7 con FI-1101 (G13)
[FI-1201] Laboratorio de física general 1    | Elegible: NO | Choque: SÍ | Grupos: 24
    └── Motivo: No cumple correquisito: FI-1101
    └── Choca con: G11 con CE-1101 (G1), G19 con CE-1101 (G1), G12 con CE-1101 (G2), G2 con CE-1101 (G2), G25 con CE-1101 (G2), G10 con CE-1103 (G1), G24 con CE-1103 (G1), G14 con CE-1103 (G2), G4 con CE-1103 (G2), G12 con CE-1103 (G3), G2 con CE-1103 (G3), G25 con CE-1103 (G3), G11 con CE-1104 (G1), G19 con CE-1104 (G1), G10 con CE-1105 (G2), G24 con CE-1105 (G2), G17 con CE-1106 (G1), G22 con CE-1106 (G1), G7 con CE-1106 (G1), G15 con CE-1106 (G2), G27 con CE-1106 (G2), G5 con CE-1106 (G2), G11 con CE-2103 (G1), G19 con CE-2103 (G1), G14 con CI-1407 (G2), G26 con CI-1407 (G2), G29 con CI-1407 (G3), G3 con CI-1407 (G3), G4 con CI-1407 (G3), G16 con CI-1407 (G4), G17 con CI-1407 (G4), G12 con CS-1502 (G1), G25 con CS-1502 (G1), G22 con CS-1502 (G2), G7 con CS-1502 (G2), G10 con CS-1502 (G3), G24 con CS-1502 (G3), G4 con CS-1502 (G4), G22 con CS-1502 (G5), G7 con CS-1502 (G5), G17 con CS-2101 (G1), G2 con CS-2101 (G2), G22 con CS-2101 (G3), G7 con CS-2101 (G3), G10 con CS-2101 (G4), G23 con CS-2101 (G4), G24 con CS-2101 (G4), G9 con CS-2101 (G4), G12 con CS-2101 (G5), G25 con CS-2101 (G5)
[FI-1202] Laboratorio de física general 2    | Elegible: NO | Choque: SÍ | Grupos: 9
    └── Motivo: No cumple requisitos: FI-1201; correquisitos: FI-1102
    └── Choca con: G1 con CE-1101 (G2), G7 con CE-1101 (G2), G1 con CE-1103 (G3), G7 con CE-1103 (G3), G5 con CE-1106 (G1), G3 con CE-1106 (G2), G2 con CI-1407 (G3), G7 con CS-1502 (G1), G5 con CS-1502 (G2), G5 con CS-1502 (G5), G1 con CS-2101 (G2), G5 con CS-2101 (G3), G6 con CS-2101 (G4), G7 con CS-2101 (G5), G3 con CS-2101 (G8), G5 con EL-2113 (G1), G1 con EL-2113 (G2), G7 con EL-2113 (G2), G4 con EL-2113 (G4), G1 con EL-2114 (G2), G7 con EL-2114 (G2), G4 con EL-2114 (G3), G3 con EL-2114 (G4), G6 con EL-2207 (G3), G4 con FI-1101 (G11), G5 con FI-1101 (G13), G5 con FI-1101 (G14), G8 con FI-1101 (G15), G9 con FI-1101 (G15), G6 con FI-1101 (G17), G1 con FI-1101 (G19), G7 con FI-1101 (G19), G5 con FI-1101 (G20), G1 con FI-1101 (G3), G7 con FI-1101 (G3), G1 con FI-1101 (G4), G7 con FI-1101 (G4), G2 con FI-1101 (G5), G2 con FI-1101 (G6), G3 con FI-1101 (G9), G1 con FI-1102 (G11), G7 con FI-1102 (G11), G1 con FI-1102 (G2), G7 con FI-1102 (G2), G1 con FI-1102 (G3), G7 con FI-1102 (G3), G2 con FI-1102 (G4), G2 con FI-1102 (G5), G4 con FI-1102 (G6), G5 con FI-1102 (G7)
[MA-0101] Matemática general                 | Elegible: SÍ | Choque: SÍ | Grupos: 12
    └── Choca con: G1 con CE-1101 (G1), G1 con CE-1101 (G2), G2 con CE-1101 (G2), G10 con CE-1103 (G1), G11 con CE-1103 (G1), G3 con CE-1103 (G2), G4 con CE-1103 (G2), G5 con CE-1103 (G2), G1 con CE-1103 (G3), G2 con CE-1103 (G3), G1 con CE-1104 (G1), G6 con CE-1105 (G1), G10 con CE-1105 (G2), G11 con CE-1105 (G2), G6 con CE-1105 (G3), G7 con CE-1106 (G1), G8 con CE-1106 (G1), G4 con CE-1106 (G2), G5 con CE-1106 (G2), G6 con CE-1106 (G2), G1 con CE-2103 (G1), G3 con CI-1407 (G2), G4 con CI-1407 (G2), G3 con CI-1407 (G3), G4 con CI-1407 (G3), G7 con CI-1407 (G4), G8 con CI-1407 (G4), G2 con CS-1502 (G1), G8 con CS-1502 (G2), G10 con CS-1502 (G3), G11 con CS-1502 (G3), G3 con CS-1502 (G4), G4 con CS-1502 (G4), G5 con CS-1502 (G4), G8 con CS-1502 (G5), G7 con CS-2101 (G1), G8 con CS-2101 (G1), G1 con CS-2101 (G2), G2 con CS-2101 (G2), G8 con CS-2101 (G3), G10 con CS-2101 (G4), G11 con CS-2101 (G4), G9 con CS-2101 (G4), G2 con CS-2101 (G5), G5 con CS-2101 (G8), G6 con CS-2101 (G8), G7 con EL-2113 (G1), G8 con EL-2113 (G1), G1 con EL-2113 (G2), G2 con EL-2113 (G2)
[MA-1102] Cálculo diferencial e integral     | Elegible: NO | Choque: SÍ | Grupos: 21
    └── Motivo: No cumple requisito: MA-0101
    └── Choca con: G1 con CE-1101 (G1), G2 con CE-1101 (G1), G1 con CE-1101 (G2), G2 con CE-1101 (G2), G3 con CE-1101 (G2), G4 con CE-1101 (G2), G16 con CE-1103 (G1), G17 con CE-1103 (G1), G18 con CE-1103 (G1), G19 con CE-1103 (G1), G20 con CE-1103 (G1), G5 con CE-1103 (G2), G6 con CE-1103 (G2), G7 con CE-1103 (G2), G8 con CE-1103 (G2), G1 con CE-1103 (G3), G2 con CE-1103 (G3), G3 con CE-1103 (G3), G4 con CE-1103 (G3), G1 con CE-1104 (G1), G2 con CE-1104 (G1), G10 con CE-1105 (G1), G9 con CE-1105 (G1), G16 con CE-1105 (G2), G17 con CE-1105 (G2), G18 con CE-1105 (G2), G19 con CE-1105 (G2), G20 con CE-1105 (G2), G10 con CE-1105 (G3), G9 con CE-1105 (G3), G11 con CE-1106 (G1), G12 con CE-1106 (G1), G13 con CE-1106 (G1), G14 con CE-1106 (G1), G10 con CE-1106 (G2), G6 con CE-1106 (G2), G7 con CE-1106 (G2), G8 con CE-1106 (G2), G9 con CE-1106 (G2), G1 con CE-2103 (G1), G2 con CE-2103 (G1), G5 con CI-1407 (G2), G6 con CI-1407 (G2), G5 con CI-1407 (G3), G6 con CI-1407 (G3), G8 con CI-1407 (G3), G11 con CI-1407 (G4), G12 con CI-1407 (G4), G13 con CI-1407 (G4), G2 con CS-1502 (G1)
[MA-1103] Cálculo y álgebra lineal          | Elegible: NO | Choque: SÍ | Grupos: 19
    └── Motivo: No cumple requisito: MA-1102
    └── Choca con: G1 con CE-1101 (G1), G19 con CE-1101 (G1), G2 con CE-1101 (G1), G19 con CE-1101 (G2), G3 con CE-1101 (G2), G15 con CE-1103 (G1), G16 con CE-1103 (G1), G17 con CE-1103 (G1), G6 con CE-1103 (G2), G7 con CE-1103 (G2), G19 con CE-1103 (G3), G3 con CE-1103 (G3), G1 con CE-1104 (G1), G19 con CE-1104 (G1), G2 con CE-1104 (G1), G10 con CE-1105 (G1), G9 con CE-1105 (G1), G15 con CE-1105 (G2), G16 con CE-1105 (G2), G17 con CE-1105 (G2), G10 con CE-1105 (G3), G9 con CE-1105 (G3), G12 con CE-1106 (G1), G10 con CE-1106 (G2), G7 con CE-1106 (G2), G8 con CE-1106 (G2), G9 con CE-1106 (G2), G1 con CE-2103 (G1), G19 con CE-2103 (G1), G2 con CE-2103 (G1), G4 con CI-1407 (G2), G5 con CI-1407 (G2), G6 con CI-1407 (G2), G4 con CI-1407 (G3), G5 con CI-1407 (G3), G6 con CI-1407 (G3), G11 con CI-1407 (G4), G12 con CI-1407 (G4), G19 con CS-1502 (G1), G3 con CS-1502 (G1), G12 con CS-1502 (G2), G15 con CS-1502 (G3), G16 con CS-1502 (G3), G17 con CS-1502 (G3), G6 con CS-1502 (G4), G7 con CS-1502 (G4), G12 con CS-1502 (G5), G12 con CS-2101 (G1), G3 con CS-2101 (G2), G12 con CS-2101 (G3)
[MA-1403] Matemática discreta                | Elegible: SÍ | Choque: SÍ | Grupos: 6
    └── Choca con: G5 con CE-1103 (G2), G3 con CE-1105 (G1), G3 con CE-1105 (G3), G2 con CE-1106 (G1), G3 con CE-1106 (G2), G4 con CI-1407 (G2), G5 con CI-1407 (G2), G4 con CI-1407 (G3), G5 con CI-1407 (G3), G1 con CI-1407 (G4), G2 con CI-1407 (G4), G6 con CI-1407 (G4), G2 con CS-1502 (G2), G5 con CS-1502 (G4), G2 con CS-1502 (G5), G2 con CS-2101 (G1), G2 con CS-2101 (G3), G3 con CS-2101 (G8), G2 con EL-2113 (G1), G1 con EL-2113 (G4), G6 con EL-2113 (G4), G1 con EL-2114 (G3), G6 con EL-2114 (G3), G3 con EL-2114 (G4), G5 con EL-2207 (G1), G2 con EL-2207 (G4), G1 con FI-1101 (G11), G6 con FI-1101 (G11), G2 con FI-1101 (G13), G2 con FI-1101 (G14), G2 con FI-1101 (G20), G4 con FI-1101 (G5), G4 con FI-1101 (G6), G5 con FI-1101 (G7), G5 con FI-1101 (G8), G3 con FI-1101 (G9), G4 con FI-1102 (G4), G4 con FI-1102 (G5), G1 con FI-1102 (G6), G6 con FI-1102 (G6), G2 con FI-1102 (G7), G5 con FI-1201 (G14), G3 con FI-1201 (G15), G1 con FI-1201 (G16), G6 con FI-1201 (G16), G2 con FI-1201 (G17), G2 con FI-1201 (G22), G4 con FI-1201 (G26), G3 con FI-1201 (G27), G4 con FI-1201 (G29)
[MA-2104] Cálculo superior                   | Elegible: NO | Choque: SÍ | Grupos: 7
    └── Motivo: No cumple requisito: MA-1103
    └── Choca con: G4 con CE-1101 (G2), G5 con CE-1103 (G1), G4 con CE-1103 (G3), G2 con CE-1105 (G1), G5 con CE-1105 (G2), G2 con CE-1105 (G3), G1 con CE-1106 (G1), G2 con CE-1106 (G2), G7 con CI-1407 (G2), G7 con CI-1407 (G3), G1 con CI-1407 (G4), G4 con CS-1502 (G1), G1 con CS-1502 (G2), G5 con CS-1502 (G3), G1 con CS-1502 (G5), G1 con CS-2101 (G1), G4 con CS-2101 (G2), G1 con CS-2101 (G3), G3 con CS-2101 (G4), G4 con CS-2101 (G5), G2 con CS-2101 (G8), G1 con EL-2113 (G1), G4 con EL-2113 (G2), G5 con EL-2114 (G1), G4 con EL-2114 (G2), G2 con EL-2114 (G4), G3 con EL-2207 (G3), G1 con EL-2207 (G4), G5 con EL-2207 (G4), G1 con FI-1101 (G13), G1 con FI-1101 (G14), G3 con FI-1101 (G17), G5 con FI-1101 (G18), G4 con FI-1101 (G19), G1 con FI-1101 (G20), G4 con FI-1101 (G3), G4 con FI-1101 (G4), G7 con FI-1101 (G5), G7 con FI-1101 (G6), G2 con FI-1101 (G9), G4 con FI-1102 (G11), G4 con FI-1102 (G2), G4 con FI-1102 (G3), G7 con FI-1102 (G4), G7 con FI-1102 (G5), G1 con FI-1102 (G7), G3 con FI-1102 (G9), G5 con FI-1201 (G10), G4 con FI-1201 (G12), G2 con FI-1201 (G15)
[PI-2609] Probabilidad y estadística         | Elegible: NO | Choque: SÍ | Grupos: 3
    └── Motivo: No cumple requisito: MA-2104
    └── Choca con: G3 con CE-1103 (G2), G1 con CE-2201 (G1), G1 con CE-2201 (G2), G1 con CI-1407 (G1), G3 con CI-1407 (G2), G2 con CS-2101 (G4), G1 con CS-2101 (G6), G1 con EL-2113 (G3), G1 con EL-2113 (G4), G3 con EL-2207 (G1), G2 con EL-2207 (G3), G2 con FI-1101 (G15), G2 con FI-1101 (G17), G3 con FI-1101 (G5), G3 con FI-1101 (G6), G3 con FI-1101 (G7), G3 con FI-1101 (G8), G3 con FI-1102 (G4), G3 con FI-1102 (G5), G2 con FI-1102 (G8), G2 con FI-1102 (G9), G3 con FI-1201 (G14), G2 con FI-1201 (G23), G3 con FI-1201 (G26), G2 con FI-1201 (G8), G2 con FI-1201 (G9), G2 con FI-1202 (G6), G2 con FI-1202 (G9), G2 con MA-0101 (G10), G3 con MA-0101 (G3), G3 con MA-0101 (G4), G2 con MA-0101 (G9), G2 con MA-1102 (G15), G2 con MA-1102 (G16), G3 con MA-1102 (G5), G3 con MA-1102 (G6), G2 con MA-1103 (G13), G2 con MA-1103 (G14), G3 con MA-1103 (G4), G3 con MA-1103 (G5), G3 con MA-1103 (G6), G3 con MA-1403 (G4), G3 con MA-1403 (G5), G2 con MA-2104 (G3), G3 con MA-2104 (G7), G2 con QU-1102 (G7), G2 con QU-1102 (G8), G3 con QU-1102 (G11), G2 con QU-1106 (G11), G3 con QU-1106 (G5)
[QU-1102] Laboratorio de química básica 1   | Elegible: NO | Choque: SÍ | Grupos: 13
    └── Motivo: No cumple correquisito: QU-1106
    └── Choca con: G1 con CE-1101 (G1), G9 con CE-1101 (G1), G10 con CE-1101 (G2), G2 con CE-1101 (G2), G4 con CE-1103 (G2), G10 con CE-1103 (G3), G2 con CE-1103 (G3), G1 con CE-1104 (G1), G9 con CE-1104 (G1), G6 con CE-1106 (G1), G1 con CE-2103 (G1), G9 con CE-2103 (G1), G11 con CI-1407 (G2), G3 con CI-1407 (G3), G4 con CI-1407 (G3), G13 con CI-1407 (G4), G10 con CS-1502 (G1), G6 con CS-1502 (G2), G4 con CS-1502 (G4), G6 con CS-1502 (G5), G2 con CS-2101 (G2), G6 con CS-2101 (G3), G8 con CS-2101 (G4), G10 con CS-2101 (G5), G6 con EL-2113 (G1), G10 con EL-2113 (G2), G2 con EL-2113 (G2), G5 con EL-2113 (G4), G10 con EL-2114 (G2), G2 con EL-2114 (G2), G13 con EL-2114 (G3), G5 con EL-2114 (G3), G4 con EL-2207 (G1), G1 con EL-2207 (G2), G9 con EL-2207 (G2), G8 con EL-2207 (G3), G1 con FI-1101 (G1), G9 con FI-1101 (G1), G13 con FI-1101 (G11), G5 con FI-1101 (G11), G6 con FI-1101 (G13), G6 con FI-1101 (G14), G15 con FI-1101 (G15), G7 con FI-1101 (G15), G8 con FI-1101 (G17), G10 con FI-1101 (G19), G2 con FI-1101 (G19), G1 con FI-1101 (G2), G9 con FI-1101 (G2), G6 con FI-1101 (G20)
[QU-1106] Química básica 1                  | Elegible: NO | Choque: SÍ | Grupos: 7
    └── Motivo: No cumple correquisito: QU-1102
    └── Choca con: G1 con CE-1101 (G1), G2 con CE-1101 (G1), G3 con CE-1101 (G2), G7 con CE-1103 (G2), G3 con CE-1103 (G3), G1 con CE-1104 (G1), G2 con CE-1104 (G1), G9 con CE-1106 (G1), G1 con CE-2103 (G1), G2 con CE-2103 (G1), G5 con CI-1407 (G2), G7 con CI-1407 (G2), G5 con CI-1407 (G3), G7 con CI-1407 (G3), G9 con CI-1407 (G4), G3 con CS-1502 (G1), G9 con CS-1502 (G2), G7 con CS-1502 (G4), G9 con CS-1502 (G5), G9 con CS-2101 (G1), G3 con CS-2101 (G2), G9 con CS-2101 (G3), G3 con CS-2101 (G5), G9 con EL-2113 (G1), G3 con EL-2113 (G2), G3 con EL-2114 (G2), G7 con EL-2207 (G1), G1 con EL-2207 (G2), G2 con EL-2207 (G2), G9 con EL-2207 (G4), G1 con FI-1101 (G1), G2 con FI-1101 (G1), G9 con FI-1101 (G13), G9 con FI-1101 (G14), G11 con FI-1101 (G15), G3 con FI-1101 (G19), G1 con FI-1101 (G2), G2 con FI-1101 (G2), G9 con FI-1101 (G20), G3 con FI-1101 (G3), G3 con FI-1101 (G4), G5 con FI-1101 (G5), G5 con FI-1101 (G6), G7 con FI-1101 (G7), G7 con FI-1101 (G8), G1 con FI-1102 (G1), G2 con FI-1102 (G1), G1 con FI-1102 (G10), G2 con FI-1102 (G10), G3 con FI-1102 (G11)
[SO-4604] Seguridad y salud ocupacional       | Elegible: NO | Choque: SÍ | Grupos: 5
    └── Motivo: No cumple requisito: FI-1102
    └── Choca con: G2 con CE-1103 (G2), G3 con CE-1105 (G1), G3 con CE-1105 (G3), G5 con CE-1106 (G1), G3 con CE-1106 (G2), G1 con CE-2201 (G1), G1 con CE-2201 (G2), G1 con CI-1407 (G1), G2 con CI-1407 (G2), G5 con CI-1407 (G4), G5 con CS-2101 (G1), G4 con CS-2101 (G4), G1 con CS-2101 (G6), G5 con EL-2113 (G1), G1 con EL-2113 (G3), G1 con EL-2113 (G4), G5 con EL-2114 (G3), G3 con EL-2114 (G4), G2 con EL-2207 (G1), G4 con EL-2207 (G3), G5 con EL-2207 (G4), G5 con FI-1101 (G11), G5 con FI-1101 (G13), G5 con FI-1101 (G14), G4 con FI-1101 (G15), G4 con FI-1101 (G17), G5 con FI-1101 (G20), G2 con FI-1101 (G5), G2 con FI-1101 (G6), G2 con FI-1101 (G7), G2 con FI-1101 (G8), G3 con FI-1101 (G9), G2 con FI-1102 (G4), G2 con FI-1102 (G5), G5 con FI-1102 (G6), G5 con FI-1102 (G7), G4 con FI-1102 (G8), G4 con FI-1102 (G9), G2 con FI-1201 (G14), G3 con FI-1201 (G15), G5 con FI-1201 (G16), G5 con FI-1201 (G17), G4 con FI-1201 (G23), G2 con FI-1201 (G26), G3 con FI-1201 (G27), G4 con FI-1201 (G8), G4 con FI-1201 (G9), G4 con FI-1202 (G6), G4 con FI-1202 (G9), G4 con MA-0101 (G10)

--------------------------------------------------
Exportando catálogo procesado a JSON...
--------------------------------------------------
[OK] JSON exportado: data/catalogo_CE_salida.json (27 cursos)
[ÉXITO] Archivo 'data/catalogo_CE_salida.json' generado correctamente.

Memoria liberada correctamente. Proceso finalizado.
==4645==
==4645== HEAP SUMMARY:
==4645==     in use at exit: 0 bytes in 0 blocks
==4645==   total heap usage: 19 allocs, 19 frees, 575,800 bytes allocated
==4645==
==4645== All heap blocks were freed -- no leaks are possible
==4645==
==4645== For lists of detected and suppressed errors, rerun with: -s
==4645== ERROR SUMMARY: 0 errors from 0 contexts (suppressed: 0 from 0)
dilan@Brownie-laptop:/mnt/c/Users/dilan/OneDrive/Desktop/ParadigmasProyecto/ParadigmasProyect$