:- encoding(utf8).
% =====================================================================
% reglas.pl — Reglas de política académica (Etapa 3)
% =====================================================================

:- module(reglas, [
    cumple_balance_carreras/1,
    cumple_limite_area/1,
    cumple_incompatibilidad/1,
    son_incompatibles/2,
    cursos_por_area/3
]).

:- use_module(politica).

%% Áreas que son "neutras" (no cuentan para el balance de carreras).
es_area_neutra('Matemática').
es_area_neutra('Física').
es_area_neutra('Química').
es_area_neutra('Ciencias Sociales').
es_area_neutra('Comunicación e Idiomas').
es_area_neutra('Salud Ocupacional').
es_area_neutra('Producción Industrial').
es_area_neutra('Administración y Emprendimiento').

%% REGLA 1: Balance entre carreras
cumple_balance_carreras(Combinacion) :-
    creditos_totales(Combinacion, TotalCreditos),
    TotalCreditos > 0,
    carreras_unicas(Combinacion, Carreras),
    verificar_porcentajes_carreras(Carreras, Combinacion, TotalCreditos).

% Solo cuenta créditos de carreras "puras" (ignora cursos neutros)
creditos_totales([], 0).
creditos_totales([curso(_, _, Cred, _, Area) | Resto], Total) :-
    (   es_area_neutra(Area)
    ->  creditos_totales(Resto, Total)
    ;   creditos_totales(Resto, SubTotal),
        Total is SubTotal + Cred
    ).

carreras_unicas(Combinacion, CarrerasUnicas) :-
    findall(Carrera, member(curso(_, _, _, Carrera, _), Combinacion), Todas),
    sort(Todas, CarrerasUnicas).

verificar_porcentajes_carreras([], _, _).
verificar_porcentajes_carreras([Carrera | Resto], Combinacion, TotalCreditos) :-
    creditos_carrera(Combinacion, Carrera, CredCarrera),
    max_porcentaje_carrera(Carrera, MaxPorcentaje),
    Porcentaje is (CredCarrera * 100) / TotalCreditos,
    Porcentaje =< MaxPorcentaje,
    verificar_porcentajes_carreras(Resto, Combinacion, TotalCreditos).

% Solo cuenta créditos de la carrera específica (ignora cursos neutros)
creditos_carrera([], _, 0).
creditos_carrera([curso(_, _, Cred, Carrera, Area) | Resto], Carrera, Total) :-
    !,
    (   es_area_neutra(Area)
    ->  creditos_carrera(Resto, Carrera, Total)
    ;   creditos_carrera(Resto, Carrera, SubTotal),
        Total is SubTotal + Cred
    ).
creditos_carrera([_ | Resto], Carrera, Total) :-
    creditos_carrera(Resto, Carrera, Total).

%% REGLA 2: Límite por área
cumple_limite_area(Combinacion) :-
    max_cursos_area(MaxN),
    areas_unicas(Combinacion, Areas),
    verificar_areas(Areas, Combinacion, MaxN).

areas_unicas(Combinacion, AreasUnicas) :-
    findall(Area, member(curso(_, _, _, _, Area), Combinacion), Todas),
    sort(Todas, AreasUnicas).

verificar_areas([], _, _).
verificar_areas([Area | Resto], Combinacion, MaxN) :-
    cursos_por_area(Combinacion, Area, Cantidad),
    Cantidad =< MaxN,
    verificar_areas(Resto, Combinacion, MaxN).

%% REGLA 3: Incompatibilidad
son_incompatibles(CursoA, CursoB) :- par_incompatible(CursoA, CursoB).
son_incompatibles(CursoA, CursoB) :- par_incompatible(CursoB, CursoA).

cumple_incompatibilidad(Combinacion) :-
    \+ (
        member(curso(Cod1, _, _, _, _), Combinacion),
        member(curso(Cod2, _, _, _, _), Combinacion),
        Cod1 \= Cod2,
        son_incompatibles(Cod1, Cod2)
    ).

%% PREDICADO MULTI-MODO
cursos_por_area(Combinacion, Area, Cantidad) :-
    nonvar(Area), !,
    contar_area(Combinacion, Area, Cantidad).
cursos_por_area(Combinacion, Area, Cantidad) :-
    var(Area),
    areas_unicas(Combinacion, Areas),
    member(Area, Areas),
    contar_area(Combinacion, Area, Cantidad).

contar_area([], _, 0).
contar_area([curso(_, _, _, _, Area) | Resto], Area, Cantidad) :-
    !,
    contar_area(Resto, Area, SubCantidad),
    Cantidad is SubCantidad + 1.
contar_area([_ | Resto], Area, Cantidad) :-
    contar_area(Resto, Area, Cantidad).