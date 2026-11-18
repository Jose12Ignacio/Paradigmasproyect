:- encoding(utf8).
% Pruebas de evaluador.pl y exportador.pl (Integrante 3).
% Ejecutar desde la carpeta prolog/:
%     swipl -g run_tests -t halt tests/test_evaluador.pl

:- use_module(library(plunit)).
:- consult(reglas_provisionales).   % reglas/politica de juguete, solo para pruebas
:- consult('../evaluador').
:- consult('../exportador').

% --- Combinaciones de prueba (cada una viola algo distinto) ---
fixture(valida,
        [curso('CE-1101', 1, 3, 'CE', programacion),
         curso('TI-1102', 1, 3, 'ATI', gestion)]).
fixture(solo_balance,             % una sola carrera: 100% > 60%
        [curso('CE-1101', 1, 3, 'CE', programacion),
         curso('CE-1104', 1, 3, 'CE', arquitectura)]).
fixture(solo_area,                % 3 cursos de programacion (N = 2)
        [curso('CE-1101', 1, 3, 'CE', programacion),
         curso('CE-1103', 1, 4, 'CE', programacion),
         curso('TI-1400', 1, 3, 'ATI', programacion),
         curso('TI-1102', 1, 3, 'ATI', gestion),
         curso('TI-4200', 1, 3, 'ATI', gestion)]).
fixture(solo_incompatibilidad,    % par incompatible CE-1103 / TI-2402
        [curso('CE-1103', 1, 4, 'CE', programacion),
         curso('TI-2402', 1, 4, 'ATI', programacion)]).
fixture(viola_las_tres,
        [curso('CE-1101', 1, 3, 'CE', programacion),
         curso('CE-1103', 1, 4, 'CE', programacion),
         curso('TI-2402', 1, 4, 'ATI', programacion)]).

% Entrada para el exportador (la que normalmente carga Integrante 1).
combinacion(1, C) :- fixture(valida, C).
combinacion(2, C) :- fixture(solo_balance, C).
combinacion(3, C) :- fixture(solo_area, C).
combinacion(4, C) :- fixture(solo_incompatibilidad, C).
combinacion(5, C) :- fixture(viola_las_tres, C).

:- begin_tests(evaluador).

test(cumple_todo) :-
    fixture(valida, C), evaluar(C, V, R), V == true, R == ninguna.
test(viola_solo_balance) :-
    fixture(solo_balance, C), evaluar(C, V, R), V == false, R == balance_carreras.
test(viola_solo_area) :-
    fixture(solo_area, C), evaluar(C, V, R), V == false, R == limite_area.
test(viola_solo_incompatibilidad) :-
    fixture(solo_incompatibilidad, C), evaluar(C, V, R), V == false, R == incompatibilidad.

% Con varias reglas violadas solo cuenta la PRIMERA segun el orden.
test(orden_por_defecto) :-
    fixture(viola_las_tres, C), evaluar(C, false, R), R == balance_carreras.
test(orden_invertido) :-
    fixture(viola_las_tres, C),
    evaluar_con_orden([incompatibilidad, limite_area, balance_carreras], C, false, R),
    R == incompatibilidad.
test(orden_con_area_primero) :-
    fixture(viola_las_tres, C),
    evaluar_con_orden([limite_area, balance_carreras, incompatibilidad], C, false, R),
    R == limite_area.

% Modo verificacion: el corte no debe dejar pasar respuestas incorrectas.
test(verifica_valida_si) :-
    fixture(valida, C), evaluar(C, true, ninguna).
test(verifica_invalida_como_valida_falla, [fail]) :-
    fixture(solo_balance, C), evaluar(C, true, ninguna).
test(verifica_razon_correcta) :-
    fixture(viola_las_tres, C), evaluar(C, false, balance_carreras).
test(verifica_razon_que_no_es_la_primera_falla, [fail]) :-
    fixture(viola_las_tres, C), evaluar(C, false, incompatibilidad).
test(valida_no_es_false, [fail]) :-
    fixture(valida, C), evaluar(C, false, _).

test(sin_reglas_cumple) :-
    fixture(solo_balance, C), evaluar_con_orden([], C, V, R), V == true, R == ninguna.

:- end_tests(evaluador).

:- begin_tests(exportador).

test(exporta_todas_y_se_lee_de_vuelta) :-
    tmp_file(resultado, Ruta),
    exportar_resultados(Ruta, Resumen),
    Resumen == resumen(5, 1),
    setup_call_cleanup(open(Ruta, read, In, [encoding(utf8)]),
                       json_read_dict(In, Doc),
                       close(In)),
    delete_file(Ruta),
    Doc.total == 5,
    Doc.orden_reglas == ["balance_carreras", "limite_area", "incompatibilidad"],
    Rs = Doc.resultados,
    length(Rs, 5),
    nth1(1, Rs, R1), R1.cumple == true,  R1.razon == null,
    nth1(2, Rs, R2), R2.cumple == false, R2.razon == "balance_carreras",
    nth1(3, Rs, R3), R3.razon == "limite_area",
    nth1(4, Rs, R4), R4.razon == "incompatibilidad",
    nth1(5, Rs, R5), R5.razon == "balance_carreras",
    R1.cursos = [P1|_], P1.curso == "CE-1101", P1.grupo == 1.

:- end_tests(exportador).
