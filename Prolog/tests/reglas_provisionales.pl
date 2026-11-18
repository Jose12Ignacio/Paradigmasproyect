:- encoding(utf8).
% =====================================================================
% SOLO PARA PRUEBAS de evaluador.pl / exportador.pl.
% Las reglas y la politica reales son de Integrante 1 y 2 (reglas.pl, politica.pl).
% Este archivo existe para poder probar el control de flujo sin depender de ellos.
% =====================================================================

maximo_porcentaje('CE', 60).
maximo_porcentaje('ATI', 60).
maximo_cursos_area(2).
incompatibles('CE-1103', 'TI-2402').

cumple_balance_carreras(Cursos) :-
    maplist(creditos_de, Cursos, Cr), sum_list(Cr, Total),
    forall(member(curso(_, _, _, Carrera, _), Cursos),
           (   creditos_carrera(Cursos, Carrera, CC),
               maximo_porcentaje(Carrera, Max),
               CC * 100 =< Max * Total )).

cumple_limite_area(Cursos) :-
    maximo_cursos_area(N),
    forall(member(curso(_, _, _, _, Area), Cursos),
           (   findall(x, member(curso(_, _, _, _, Area), Cursos), L),
               length(L, K), K =< N )).

cumple_incompatibilidad(Cursos) :-
    \+ ( member(curso(A, _, _, _, _), Cursos),
         member(curso(B, _, _, _, _), Cursos),
         ( incompatibles(A, B) ; incompatibles(B, A) ) ).

creditos_de(curso(_, _, Cr, _, _), Cr).
creditos_carrera(Cursos, Carrera, Suma) :-
    findall(Cr, member(curso(_, _, Cr, Carrera, _), Cursos), L),
    sum_list(L, Suma).
