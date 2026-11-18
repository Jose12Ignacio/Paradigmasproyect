:- use_module(reglas).
:- use_module(library(plunit)).

% Estas pruebas usan los valores de politica.pl (carreras 'CE' y 'ATI',
% maximo 75 % por carrera, maximo 3 cursos por area) y sus pares incompatibles
% ('CE-1106'/'CE-2103' y 'CE-1103'/'TI-2402'). Si se cambia la politica, hay que
% ajustar los numeros.

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
    % CE: 6/8 = 75% (cumple <= 75), ATI: 2/8 = 25%
    Comb = [
        curso('CE-1106', 1, 3, 'CE', 'prog'),
        curso('CE-2103', 1, 3, 'CE', 'arq'),
        curso('MA-1102', 1, 2, 'ATI', 'mate')
    ],
    cumple_balance_carreras(Comb).

test(regla1_rechaza_exceso_porcentaje, [fail]) :-
    % CE: 8/10 = 80% > 75%
    Comb = [
        curso('CE-1106', 1, 4, 'CE', 'prog'),
        curso('CE-2103', 1, 4, 'CE', 'arq'),
        curso('MA-1102', 1, 2, 'ATI', 'mate')
    ],
    cumple_balance_carreras(Comb).

test(regla1_una_sola_carrera_rechazada_si_max_menor_100, [fail]) :-
    % CE: 8/8 = 100% > 75%
    Comb = [
        curso('CE-1106', 1, 4, 'CE', 'prog'),
        curso('MA-1102', 1, 4, 'CE', 'mate')
    ],
    cumple_balance_carreras(Comb).

test(regla2_limite_area_exacto) :-
    % 3 cursos de 'prog' con max_cursos_area(3)
    Comb = [
        curso('CE-1106', 1, 4, 'CE', 'prog'),
        curso('CE-2103', 1, 4, 'ATI', 'prog'),
        curso('CE-3101', 1, 4, 'CE', 'prog')
    ],
    cumple_limite_area(Comb).

test(regla2_rechaza_exceso_area, [fail]) :-
    % 4 cursos de 'prog' > 3
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
    % mismo contenido en las dos carreras
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
