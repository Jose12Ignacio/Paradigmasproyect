:- use_module(reglas).
:- use_module(library(plunit)).

:- begin_tests(reglas_politica).

test(combinacion_valida_todas_las_reglas) :-
    Comb = [
        curso('CE-1106', 1, 4, 'CE', 'prog'),
        curso('MA-1102', 1, 4, 'ATI', 'mate')
    ],
    cumple_balance_carreras(Comb),
    cumple_limite_area(Comb),
    cumple_incompatibilidad(Comb).

test(regla1_limite_porcentaje_exacto) :-
    Comb = [
        curso('CE-1106', 1, 3, 'CE', 'prog'),
        curso('CE-2103', 1, 3, 'CE', 'arq'),
        curso('MA-1102', 1, 2, 'ATI', 'mate')
    ],
    cumple_balance_carreras(Comb).

test(regla1_rechaza_exceso_porcentaje, [fail]) :-
    Comb = [
        curso('CE-1106', 1, 4, 'CE', 'prog'),
        curso('CE-2103', 1, 4, 'CE', 'arq'),
        curso('MA-1102', 1, 2, 'ATI', 'mate')
    ],
    cumple_balance_carreras(Comb).

test(regla1_una_sola_carrera_rechazada_si_max_menor_100, [fail]) :-
    Comb = [
        curso('CE-1106', 1, 4, 'CE', 'prog'),
        curso('MA-1102', 1, 4, 'CE', 'mate')
    ],
    cumple_balance_carreras(Comb).

test(regla2_limite_area_exacto) :-
    Comb = [
        curso('CE-1106', 1, 4, 'CE', 'prog'),
        curso('CE-2103', 1, 4, 'ATI', 'prog'),
        curso('CE-3101', 1, 4, 'CE', 'prog')
    ],
    cumple_limite_area(Comb).

test(regla2_rechaza_exceso_area, [fail]) :-
    Comb = [
        curso('CE-1106', 1, 4, 'CE', 'prog'),
        curso('CE-2103', 1, 4, 'ATI', 'prog'),
        curso('CE-3101', 1, 4, 'CE', 'prog'),
        curso('CE-1103', 1, 4, 'ATI', 'prog')
    ],
    cumple_limite_area(Comb).

test(regla3_rechaza_incompatibilidad_directa, [fail]) :-
    Comb = [
        curso('CE-1106', 1, 4, 'CE', 'prog'),
        curso('CE-2103', 1, 4, 'ATI', 'arq')
    ],
    cumple_incompatibilidad(Comb).

test(regla3_rechaza_incompatibilidad_simetrica, [fail]) :-
    Comb = [
        curso('CE-2103', 1, 4, 'ATI', 'arq'),
        curso('CE-1106', 1, 4, 'CE', 'prog')
    ],
    cumple_incompatibilidad(Comb).

test(regla3_rechaza_par_entre_carreras, [fail]) :-
    Comb = [
        curso('CE-1103', 1, 4, 'CE', 'prog'),
        curso('TI-2402', 1, 4, 'ATI', 'prog')
    ],
    cumple_incompatibilidad(Comb).

test(multimodo_calculo_y_verificacion) :-
    Comb = [
        curso('CE-1106', 1, 4, 'CE', 'prog'),
        curso('CE-2103', 1, 4, 'ATI', 'prog'),
        curso('MA-1102', 1, 4, 'CE', 'mate')
    ],
    cursos_por_area(Comb, 'prog', CantProg),
    CantProg == 2,
    cursos_por_area(Comb, 'mate', 1),
    cursos_por_area(Comb, 'redes', 0).

test(multimodo_generacion_backtracking) :-
    Comb = [
        curso('CE-1106', 1, 4, 'CE', 'prog'),
        curso('CE-2103', 1, 4, 'ATI', 'prog'),
        curso('MA-1102', 1, 4, 'CE', 'mate')
    ],
    findall(Area-Cant, cursos_por_area(Comb, Area, Cant), Resultados),
    Resultados == ['mate'-1, 'prog'-2].

:- end_tests(reglas_politica).