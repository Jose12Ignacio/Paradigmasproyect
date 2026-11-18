### Motor de Reglas de Política Académica (`reglas.pl`)

El módulo `reglas` valida de forma declarativa cada combinación de horario frente a los parámetros definidos en `politica.pl`[cite: 3]. En cumplimiento con las restricciones del paradigma lógico, el estado y los cálculos intermedios se resuelven exclusivamente mediante recursión, acumuladores y unificación, sin recurrir a predicados dinámicos (`assert`/`retract`) ni variables globales[cite: 4].

#### 1. Resumen de Predicados Exportados

| Predicado | Modo | Descripción |
| :--- | :--- | :--- |
| `cumple_balance_carreras/1` | `(+)` | Verifica que ninguna carrera exceda su porcentaje máximo de créditos permitido[cite: 3]. |
| `cumple_limite_area/1` | `(+)` | Comprueba que ninguna área académica supere el tope de $N$ cursos[cite: 3]. |
| `cumple_incompatibilidad/1` | `(+)` | Garantiza que la combinación no contenga pares de cursos incompatibles[cite: 3]. |
| `son_incompatibles/2` | `(?, ?)` | Evalúa de forma simétrica si dos códigos de curso son incompatibles entre sí[cite: 3]. |
| `cursos_por_area/3` | `(+, ?, ?)` | Predicado multi-modo que calcula, verifica o enumera la cantidad de cursos por área[cite: 3]. |

#### 2. Funcionamiento de las Reglas de Política

* **Regla 1 — Balance entre carreras (`cumple_balance_carreras(+Combinacion)`):**
  Calcula recursivamente los créditos totales de la combinación (`creditos_totales/2`) y extrae las carreras distintas presentes mediante `findall/3` y `sort/2`. Para cada carrera, suma sus créditos (`creditos_carrera/3`), consulta su límite en `max_porcentaje_carrera(Carrera, MaxPorcentaje)` y exige que `(CredCarrera * 100) / TotalCreditos =< MaxPorcentaje`[cite: 3].
  * **Caso límite (combinación de una sola carrera):** Si todos los cursos pertenecen a una única carrera (100 % de los créditos), el predicado la acepta únicamente cuando el parámetro configurado para esa carrera es `>= 100`, y la rechaza automáticamente si el tope es menor, sin requerir lógica adicional.

* **Regla 2 — Límite por área (`cumple_limite_area(+Combinacion)`):**
  Consulta el máximo permitido en `max_cursos_area(MaxN)`, obtiene las áreas únicas de la combinación (`areas_unicas/2`) y delega el conteo de cada área al predicado `cursos_por_area/3`, validando que `Cantidad =< MaxN`[cite: 3].

* **Regla 3 — Incompatibilidad simétrica (`cumple_incompatibilidad(+Combinacion)`):**
  Se apoya en `son_incompatibles/2`, que consulta tanto `par_incompatible(CursoA, CursoB)` como `par_incompatible(CursoB, CursoA)` para garantizar simetría sin duplicar hechos[cite: 3]. Luego, `cumple_incompatibilidad/1` usa negación por falla (`\+`) para asegurar que no existan dos cursos distintos en la combinación que formen un par prohibido[cite: 3].

#### 3. Pares de Cursos Incompatibles y Justificación

*(Nota para el equipo: confirmar que los códigos coincidan con los planes extendidos a 8 semestres en `politica.pl`[cite: 2, 4]).*

| Par Incompatible | Carreras Involucradas | Justificación Académica |
| :--- | :--- | :--- |
| `par_incompatible('CE1106', 'CE3101')` | Ingeniería en Computadores | Ambos cursos exigen proyectos de programación intensivos y entregas acumulativas en paralelo, generando sobrecarga práctica en el mismo semestre[cite: 4]. |
| `par_incompatible('MA1102', 'MA2104')` | Ingeniería en Computadores / Plan 2 | Son asignaturas matemáticas con alta densidad teórica y evaluaciones colegiadas en bloques horarios cercanos que comprometen el rendimiento académico[cite: 4]. |

#### 4. Predicado Multi-Modo (`cursos_por_area/3`)

El predicado `cursos_por_area(Combinacion, Area, Cantidad)` soporta múltiples modos de instanciación[cite: 3]:
* Cuando `Area` viene instanciada (`nonvar(Area)`), aplica corte (`!`) y ejecuta directamente `contar_area/3`, permitiendo tanto calcular la cantidad como verificar un valor esperado (retornando `0` si el área no aparece en la combinación).
* Cuando `Area` es una variable libre (`var(Area)`), extrae primero las áreas sin repetidos con `areas_unicas/2` (evitando soluciones duplicadas por *backtracking*) y enumera cada área junto con su conteo mediante `member/2`[cite: 3].

##### Ejemplos de consulta en `swipl`

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

#### 5. Ejecución de Pruebas Unitarias

El archivo `tests_reglas.pl` contiene 10 pruebas automatizadas con `plunit` que verifican combinaciones válidas, límites exactos, rechazos por cada política, simetría de incompatibilidad y todos los modos de `cursos_por_area/3`:

```bash
cd Prolog
swipl -s tests_reglas.pl -g run_tests -t halt
```