:- use_module(reglas).
:- use_module(library(plunit)).

:- begin_tests(reglas_politica).

test(combinacion_valida_todas_las_reglas) :-
    Comb = [
        curso('CE1106', 1, 4, 'IC', 'prog'),
        curso('MA1102', 1, 4, 'PI', 'mate')
    ],
    cumple_balance_carreras(Comb),
    cumple_limite_area(Comb),
    cumple_incompatibilidad(Comb).

test(regla1_limite_porcentaje_exacto) :-
    % IC: 6/8 = 75% (cumple <= 75), PI: 2/8 = 25%
    Comb = [
        curso('CE1106', 1, 3, 'IC', 'prog'),
        curso('CE2103', 1, 3, 'IC', 'arq'),
        curso('MA1102', 1, 2, 'PI', 'mate')
    ],
    cumple_balance_carreras(Comb).

test(regla1_rechaza_exceso_porcentaje, [fail]) :-
    % IC: 8/10 = 80% > 75%
    Comb = [
        curso('CE1106', 1, 4, 'IC', 'prog'),
        curso('CE2103', 1, 4, 'IC', 'arq'),
        curso('MA1102', 1, 2, 'PI', 'mate')
    ],
    cumple_balance_carreras(Comb).

test(regla1_una_sola_carrera_rechazada_si_max_menor_100, [fail]) :-
    % IC: 8/8 = 100% > 75%
    Comb = [
        curso('CE1106', 1, 4, 'IC', 'prog'),
        curso('MA1102', 1, 4, 'IC', 'mate')
    ],
    cumple_balance_carreras(Comb).

test(regla2_limite_area_exacto) :-
    % 2 cursos de 'prog' con max_cursos_area(2)
    Comb = [
        curso('CE1106', 1, 4, 'IC', 'prog'),
        curso('CE2103', 1, 4, 'PI', 'prog')
    ],
    cumple_limite_area(Comb).

test(regla2_rechaza_exceso_area, [fail]) :-
    % 3 cursos de 'prog' > 2
    Comb = [
        curso('CE1106', 1, 4, 'IC', 'prog'),
        curso('CE2103', 1, 4, 'PI', 'prog'),
        curso('CE3101', 1, 4, 'IC', 'prog')
    ],
    cumple_limite_area(Comb).

test(regla3_rechaza_incompatibilidad_directa, [fail]) :-
    Comb = [
        curso('CE1106', 1, 4, 'IC', 'prog'),
        curso('CE3101', 1, 4, 'PI', 'arq')
    ],
    cumple_incompatibilidad(Comb).

test(regla3_rechaza_incompatibilidad_simetrica, [fail]) :-
    Comb = [
        curso('CE3101', 1, 4, 'PI', 'arq'),
        curso('CE1106', 1, 4, 'IC', 'prog')
    ],
    cumple_incompatibilidad(Comb).

test(multimodo_calculo_y_verificacion) :-
    Comb = [
        curso('CE1106', 1, 4, 'IC', 'prog'),
        curso('CE2103', 1, 4, 'PI', 'prog'),
        curso('MA1102', 1, 4, 'IC', 'mate')
    ],
    cursos_por_area(Comb, 'prog', CantProg),
    CantProg == 2,
    cursos_por_area(Comb, 'mate', 1),
    cursos_por_area(Comb, 'redes', 0).

test(multimodo_generacion_backtracking) :-
    Comb = [
        curso('CE1106', 1, 4, 'IC', 'prog'),
        curso('CE2103', 1, 4, 'PI', 'prog'),
        curso('MA1102', 1, 4, 'IC', 'mate')
    ],
    findall(Area-Cant, cursos_por_area(Comb, Area, Cant), Resultados),
    Resultados == ['mate'-1, 'prog'-2].

:- end_tests(reglas_politica).
