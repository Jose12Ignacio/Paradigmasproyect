### Motor de Reglas de Política Académica (`reglas.pl`)

El módulo `reglas` valida de forma declarativa cada combinación de horario frente a los parámetros definidos en `politica.pl`[cite: 3]. En cumplimiento con las restricciones del paradigma lógico, el estado y los cálculos intermedios se resuelven exclusivamente mediante recursión, acumuladores y unificación, sin recurrir a predicados dinámicos (`assert`/`retract`) ni variables globales[cite: 4].

 1. Resumen de Predicados Exportados

| Predicado | Modo | Descripción |
| :--- | :--- | :--- |
| `cumple_balance_carreras/1` | `(+)` | Verifica que ninguna carrera exceda su porcentaje máximo de créditos permitido[cite: 3]. |
| `cumple_limite_area/1` | `(+)` | Comprueba que ninguna área académica supere el tope de $N$ cursos[cite: 3]. |
| `cumple_incompatibilidad/1` | `(+)` | Garantiza que la combinación no contenga pares de cursos incompatibles[cite: 3]. |
| `son_incompatibles/2` | `(?, ?)` | Evalúa de forma simétrica si dos códigos de curso son incompatibles entre sí[cite: 3]. |
| `cursos_por_area/3` | `(+, ?, ?)` | Predicado multi-modo que calcula, verifica o enumera la cantidad de cursos por área[cite: 3]. |

 2. Funcionamiento de las Reglas de Política

* **Regla 1 — Balance entre carreras (`cumple_balance_carreras(+Combinacion)`):**
  Calcula recursivamente los créditos totales de la combinación (`creditos_totales/2`) y extrae las carreras distintas presentes mediante `findall/3` y `sort/2`. Para cada carrera, suma sus créditos (`creditos_carrera/3`), consulta su límite en `max_porcentaje_carrera(Carrera, MaxPorcentaje)` y exige que `(CredCarrera * 100) / TotalCreditos =< MaxPorcentaje`[cite: 3].
  * **Caso límite (combinación de una sola carrera):** Si todos los cursos pertenecen a una única carrera (100 % de los créditos), el predicado la acepta únicamente cuando el parámetro configurado para esa carrera es `>= 100`, y la rechaza automáticamente si el tope es menor, sin requerir lógica adicional.

* **Regla 2 — Límite por área (`cumple_limite_area(+Combinacion)`):**
  Consulta el máximo permitido en `max_cursos_area(MaxN)`, obtiene las áreas únicas de la combinación (`areas_unicas/2`) y delega el conteo de cada área al predicado `cursos_por_area/3`, validando que `Cantidad =< MaxN`[cite: 3].

* **Regla 3 — Incompatibilidad simétrica (`cumple_incompatibilidad(+Combinacion)`):**
  Se apoya en `son_incompatibles/2`, que consulta tanto `par_incompatible(CursoA, CursoB)` como `par_incompatible(CursoB, CursoA)` para garantizar simetría sin duplicar hechos[cite: 3]. Luego, `cumple_incompatibilidad/1` usa negación por falla (`\+`) para asegurar que no existan dos cursos distintos en la combinación que formen un par prohibido[cite: 3].

 3. Pares de Cursos Incompatibles y Justificación

*(Nota para el equipo: confirmar que los códigos coincidan con los planes extendidos a 8 semestres en `politica.pl`[cite: 2, 4]).*

| Par Incompatible | Carreras Involucradas | Justificación Académica |
| :--- | :--- | :--- |
| `par_incompatible('CE1106', 'CE3101')` | Ingeniería en Computadores | Ambos cursos exigen proyectos de programación intensivos y entregas acumulativas en paralelo, generando sobrecarga práctica en el mismo semestre[cite: 4]. |
| `par_incompatible('MA1102', 'MA2104')` | Ingeniería en Computadores / Plan 2 | Son asignaturas matemáticas con alta densidad teórica y evaluaciones colegiadas en bloques horarios cercanos que comprometen el rendimiento académico[cite: 4]. |

 4. Predicado Multi-Modo (`cursos_por_area/3`)

El predicado `cursos_por_area(Combinacion, Area, Cantidad)` soporta múltiples modos de instanciación[cite: 3]:
* Cuando `Area` viene instanciada (`nonvar(Area)`), aplica corte (`!`) y ejecuta directamente `contar_area/3`, permitiendo tanto calcular la cantidad como verificar un valor esperado (retornando `0` si el área no aparece en la combinación).
* Cuando `Area` es una variable libre (`var(Area)`), extrae primero las áreas sin repetidos con `areas_unicas/2` (evitando soluciones duplicadas por *backtracking*) y enumera cada área junto con su conteo mediante `member/2`[cite: 3].

# Ejemplos de consulta en `swipl`

Iniciando el intérprete desde la carpeta `Prolog/` con `swipl -s reglas.pl`[cite: 4]:

**Modo 1 — Cálculo de cantidad (`+, +, -`):** Obtiene cuántos cursos pertenecen a un área específica[cite: 3].
```prolog
?- Comb = [curso('CE1106',1,4,'IC','prog'), curso('CE2103',1,4,'IC','prog'), curso('MA1102',1,4,'PI','mate')],
   cursos_por_area(Comb, 'prog', Cant).
Cant = 2.
```

**Modo 2 — Verificación booleana (`+, +, +`):** Comprueba si la combinación tiene exactamente $N$ cursos de un área dada[cite: 3].
```prolog
?- Comb = [curso('CE1106',1,4,'IC','prog'), curso('CE2103',1,4,'IC','prog'), curso('MA1102',1,4,'PI','mate')],
   cursos_por_area(Comb, 'mate', 1).
true.

?- Comb = [curso('CE1106',1,4,'IC','prog'), curso('MA1102',1,4,'PI','mate')],
   cursos_por_area(Comb, 'redes', 0).
true.
```

**Modo 3 — Generación por *backtracking* (`+, -, -`):** Enumera todas las áreas presentes en la combinación junto con su conteo[cite: 3].
```prolog
?- Comb = [curso('CE1106',1,4,'IC','prog'), curso('CE2103',1,4,'IC','prog'), curso('MA1102',1,4,'PI','mate')],
   cursos_por_area(Comb, Area, Cant).
Area = mate,
Cant = 1 ;
Area = prog,
Cant = 2.
```

**Modo 4 — Búsqueda por cantidad objetivo (`+, -, +`):** Encuentra qué áreas dentro de la combinación tienen exactamente $N$ cursos[cite: 3].
```prolog
?- Comb = [curso('CE1106',1,4,'IC','prog'), curso('CE2103',1,4,'IC','prog'), curso('MA1102',1,4,'PI','mate')],
   cursos_por_area(Comb, Area, 2).
Area = prog.
```

 5. Ejecución de Pruebas Unitarias

El archivo `tests_reglas.pl` contiene 10 pruebas automatizadas con `plunit` que verifican combinaciones válidas, límites exactos, rechazos por cada política, simetría de incompatibilidad y todos los modos de `cursos_por_area/3`:

```bash
cd Prolog
swipl -s tests_reglas.pl -g run_tests -t halt

```

2.1 Arquitectura del proyecto (Etapa 3: evaluador, recorrido y exportación)

Esta parte toma cada combinación de horario que generó Racket, decide si cumple la política académica y, si no,
cuál es la **primera** regla que viola. Después escribe el resultado en un archivo para la Etapa 4 (Java).

```
combinaciones de Racket ──► carga.pl ──► hechos combinacion(Id, Cursos)
                                                  │
        politica.pl ──► reglas.pl                 ▼
        (parámetros)    (3 reglas)  ──►  evaluador.pl  evaluar/3
                                                  │
                                                  ▼
                                         exportador.pl  (recorre todas)
                                                  │
                                                  ▼
                                       resultado.json ──► Etapa 4 (Java)
```

Archivos de esta parte (carpeta `Prolog/`):

- `evaluador.pl`: `evaluar/3`, el evaluador maestro, con corte y negación por falla.
- `exportador.pl`: recorre todas las combinaciones por backtracking y escribe el JSON.
- `main.pl`: script que une los pasos y se ejecuta con `swipl`.
- `tests/test_evaluador.pl`: pruebas de la parte anterior, con reglas provisionales para no depender de otros módulos.

 Cómo se ejecuta

```
swipl Prolog/main.pl <combinaciones_de_racket.json> <resultado.json>
```

Sin argumentos usa `combinaciones.json` y `resultado.json`. Para llamarlo desde la consola de Prolog sin ejecutar
el programa principal:

```
swipl -l Prolog/main.pl
?- ejecutar('combinaciones.json', 'resultado.json').
```

`politica.pl` se vuelve a leer del disco en **cada ejecución** (`load_files/2` con `if(true)`, desde la carpeta del
script, sin importar desde dónde se llame a `swipl`). Si se cambia un valor de la política, por ejemplo durante la
defensa, basta con volver a ejecutar. Esto se comprobó también dentro de una misma sesión: al subir el máximo de
una carrera de 60 % a 100 %, la siguiente llamada a `ejecutar/2` ya usó el valor nuevo.

Nota: `swipl` carga como código cualquier argumento que termine en `.pl`. Si el archivo de entrada tuviera esa
extensión, hay que escribir `--` antes de los argumentos.

2.2 Decisiones de diseño

 2.2.1 Razón de rechazo y orden de las reglas

La razón de rechazo es la primera regla violada, según una lista de orden:

```prolog
orden_reglas([balance_carreras, limite_area, incompatibilidad]).

primera_violada([Regla|_], Cursos, Razon) :-
    \+ cumple_regla(Regla, Cursos),
    !,
    Razon = Regla.
primera_violada([_|Resto], Cursos, Razon) :-
    primera_violada(Resto, Cursos, Razon).
```

La negación por falla (`\+`) detecta la regla que **no** se cumple y el corte (`!`) detiene la búsqueda ahí:
ninguna regla posterior se evalúa ni puede cambiar la razón. Si la regla sí se cumple, `\+` falla y se pasa a la
siguiente cláusula.

**La razón se une después del corte y no en la cabeza de la cláusula.** Se probó la alternativa
(`evaluar(C, false, R) :- ..., !.` seguida de `evaluar(_, true, ninguna).`) y tiene un error real: la consulta
`evaluar(C, true, ninguna)` sobre una combinación que viola el balance de carreras **tiene éxito**, porque la
unificación `false = true` falla antes de llegar al corte y se cae a la segunda cláusula. Con la razón unida
después del corte, esa consulta falla, como debe ser.

**Orden por defecto:** primero el balance entre carreras, después el límite por área y al final la
incompatibilidad, que es el orden en que la política enumera las reglas. Además va de lo que afecta a toda la
combinación (porcentajes de créditos) a lo que depende de pares concretos de cursos. [Confirmar con el equipo.]

**Un caso donde el orden cambia la razón.** La combinación `CE-1101`, `CE-1103` (ambas de CE) y `TI-2402` viola
las tres reglas a la vez: CE tiene 63,6 % de los créditos, hay tres cursos de programación y `CE-1103` /
`TI-2402` son incompatibles. Con las reglas reales y la misma combinación, solo cambia la razón según el orden:

- `[balance_carreras, limite_area, incompatibilidad]` reporta `balance_carreras`.
- `[limite_area, balance_carreras, incompatibilidad]` reporta `limite_area`.
- `[incompatibilidad, limite_area, balance_carreras]` reporta `incompatibilidad`.

El veredicto es el mismo (`cumple: false`); solo cambia cuál de las tres violaciones se informa. [Reemplazar el
ejemplo por una combinación real de la salida de Racket cuando esté disponible.]

 Formato de salida: JSON

```json
{
  "total": 3,
  "orden_reglas": ["balance_carreras", "limite_area", "incompatibilidad"],
  "resultados": [
    { "id": 2, "cursos": [ {"curso": "CE-1101", "grupo": 1}, {"curso": "CE-1104", "grupo": 1} ],
      "cumple": false, "razon": "balance_carreras" }
  ]
}
```

Cada combinación trae su lista de pares curso-grupo, `cumple` (booleano) y `razon` (la primera regla violada, o
`null` si cumple). Se eligió JSON porque Java lo lee con Jackson o Gson sin escribir un analizador propio, porque
las listas de pares tienen largo variable y en CSV habría que inventar una convención para separarlas, y porque
`true`, `false` y `null` son valores nativos, sin convertir texto. Se agregaron `total` y `orden_reglas` para que
Java sepa cuántas combinaciones hay y con qué orden se evaluó cada razón. Si la entrada no tiene ninguna
combinación, el archivo sale con `total: 0` y una lista vacía, y el programa avisa por pantalla.

 2.2.2 Casos límite reales

**Combinación de una sola carrera.** La política dice que una combinación de una sola carrera es válida mientras
no supere su máximo, y una sola carrera ocupa el 100 % de los créditos. Por eso el resultado depende del valor
configurado: con un máximo del 60 % la combinación `CE-1101` + `CE-1104` se rechaza con `balance_carreras`; si se
edita `politica.pl` y el máximo pasa a 100 %, la misma combinación se acepta sin tocar el código. Con máximos
menores a 100 %, toda combinación de una sola carrera se rechaza. Se dejó así a propósito: es una consecuencia
directa de la regla, no un error del programa. [Reemplazar los códigos y porcentajes por los de la política real.]

**Una carrera de los datos que la política no conoce.** La regla 1 consulta el porcentaje máximo de cada carrera
presente. Si `politica.pl` no define uno para alguna (por ejemplo, la política habla de `IC` y `PI` pero los datos
de Racket traen `CE` y `ATI`), la consulta falla, la regla se considera incumplida y **todas** las combinaciones
que incluyan esa carrera se rechazan con `balance_carreras`, sin ningún mensaje de error. Se comprobó con tres
combinaciones: con la política correcta cumplía una; con los nombres equivocados se rechazaban las tres.
`main.pl` imprime ahora un aviso (`advertir_carreras_sin_politica`) cuando una carrera de los datos no tiene
porcentaje, para que el problema sea visible antes de evaluar. Esto ocurrió de verdad al integrar los módulos: `carga.pl` leía el JSON con `json_read_dict/2`, que devuelve *strings* (`"CE"`), mientras que `politica.pl` declara *átomos* (`'CE'`). Ambos se ven iguales con `write/1`, pero no unifican, así que las tres combinaciones de prueba se rechazaban con `balance_carreras` aunque la política sí definía `CE` y `ATI`. El aviso de `main.pl` lo hizo visible y se corrigió leyendo el JSON con la opción `value_string_as(atom)`: con ese único cambio, de las tres combinaciones cumplieron dos y la tercera (solo cursos de CE) se rechazó por el balance. [Confirmar con Integrante 1 que el cambio quedó en `carga.pl`.]

2.3 Predicados principales y consultas

**`evaluar(+Cursos, ?Veredicto, ?Razon)`** se puede usar en dos modos. Con las reglas reales y la política de
ejemplo (CE y ATI con máximo 60 %, hasta 2 cursos por área):

Modo de cálculo (`Veredicto` y `Razon` sin instanciar):

```prolog
?- evaluar([curso('CE-1101',1,3,'CE',programacion),
            curso('CE-1104',1,3,'CE',arquitectura)], V, R).
V = false, R = balance_carreras.

?- evaluar([curso('CE-1101',1,3,'CE',programacion),
            curso('TI-1102',1,3,'ATI',gestion)], V, R).
V = true, R = ninguna.
```

Modo de verificación (todo instanciado):

```prolog
?- evaluar(UnaCarrera, false, balance_carreras).   % true
?- evaluar(UnaCarrera, true, ninguna).             % false: sí viola una regla
?- evaluar(Valida, true, ninguna).                 % true
?- evaluar(TresViolaciones, false, incompatibilidad).  % false: la primera es balance_carreras
```

La última consulta falla aunque la combinación sí viola la incompatibilidad, porque esa no es la **primera**
violada. Es justo lo que garantiza el corte con la unión posterior.

**`evaluar_con_orden(+Orden, +Cursos, ?Veredicto, ?Razon)`** es lo mismo con el orden como argumento; sirve para el
análisis de la sección 2.2.1.

**`exportar_resultados(+Ruta, -resumen(Total, Cumplen))`** recorre todas las combinaciones cargadas con
`findall/3`, que explora `combinacion/2` por backtracking, y escribe el JSON. No se usa `assert` ni `retract` para
guardar resultados: la lista de resultados se pasa como argumento.

 Pruebas

`Prolog/tests/test_evaluador.pl` (14 pruebas) cubre una combinación válida, una que viola cada regla, una que
viola las tres con tres órdenes distintos, las consultas en modo verificación y la exportación leída de vuelta.
Se ejecuta con:

```
swipl -g run_tests -t halt Prolog/tests/test_evaluador.pl
```

Probado con SWI-Prolog 9.0.4.
