:- encoding(utf8).
% =====================================================================
% evaluador.pl  (Integrante 3)
%
% Evaluador maestro: dada UNA combinacion, decide si cumple la politica y,
% si no, cual es la PRIMERA regla que viola (segun orden_reglas/1).
%
% Depende de los predicados de Integrante 2 (reglas.pl). Cada uno tiene
% exito si la combinacion CUMPLE esa regla:
%     cumple_balance_carreras/1  cumple_limite_area/1  cumple_incompatibilidad/1
%
% Una combinacion es una lista de terminos:
%     curso(Codigo, Grupo, Creditos, Carrera, Area)
% =====================================================================

% Orden de evaluacion. Es parte del diseno: la PRIMERA regla de la lista que
% se viole es la unica razon que se reporta. Cambiar el orden aqui cambia la
% razon de las combinaciones que violan mas de una regla (ver README).
orden_reglas([balance_carreras, limite_area, incompatibilidad]).

% Une el nombre de cada regla con su predicado de Integrante 2.
cumple_regla(balance_carreras, Cursos) :- cumple_balance_carreras(Cursos).
cumple_regla(limite_area, Cursos)      :- cumple_limite_area(Cursos).
cumple_regla(incompatibilidad, Cursos) :- cumple_incompatibilidad(Cursos).

% primera_violada(+Reglas, +Cursos, -Razon)
%   Recorre las reglas EN ORDEN. La negacion por falla (\+) detecta la regla
%   que NO se cumple y el corte (!) detiene la busqueda en la primera:
%   ninguna regla posterior se evalua ni puede cambiar la razon.
%   Si la regla se cumple, \+ falla y se sigue con la siguiente clausula.
%   La razon se une DESPUES del corte, para que el corte siga siendo
%   correcto aunque Razon llegue ya instanciada.
primera_violada([Regla|_], Cursos, Razon) :-
    \+ cumple_regla(Regla, Cursos),
    !,
    Razon = Regla.
primera_violada([_|Resto], Cursos, Razon) :-
    primera_violada(Resto, Cursos, Razon).

% evaluar(+Cursos, -Veredicto, -Razon)
%   Veredicto = true  y Razon = ninguna       si cumple todas las reglas.
%   Veredicto = false y Razon = <primera regla violada> en caso contrario.
evaluar(Cursos, Veredicto, Razon) :-
    orden_reglas(Orden),
    evaluar_con_orden(Orden, Cursos, Veredicto, Razon).

% Igual que evaluar/3 pero con el orden como argumento (sirve para el
% analisis del README: mismo dato, distinto orden, distinta razon).
evaluar_con_orden(Orden, Cursos, Veredicto, Razon) :-
    primera_violada(Orden, Cursos, Violada),
    !,
    Veredicto = false,
    Razon = Violada.
% Solo se llega aqui si NINGUNA regla se violo. Si Veredicto o Razon llegan
% instanciados con otro valor, esta clausula falla, como debe ser.
evaluar_con_orden(_, _, true, ninguna).
