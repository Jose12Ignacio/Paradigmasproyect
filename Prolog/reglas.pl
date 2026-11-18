:- module(reglas, [
    cumple_balance_carreras/1,
    cumple_limite_area/1,
    cumple_incompatibilidad/1,
    son_incompatibles/2,
    cursos_por_area/3
]).

:- use_module(politica).

%% =========================================================================
%% REGLA 1: Balance entre carreras
%% Ninguna carrera presente puede superar su porcentaje maximo de creditos.
%% Una combinacion de una sola carrera es valida si su maximo configurado >= 100.
%% =========================================================================

cumple_balance_carreras(Combinacion) :-
    creditos_totales(Combinacion, TotalCreditos),
    TotalCreditos > 0,
    carreras_unicas(Combinacion, Carreras),
    verificar_porcentajes_carreras(Carreras, Combinacion, TotalCreditos).

creditos_totales([], 0).
creditos_totales([curso(_, _, Cred, _, _) | Resto], Total) :-
    creditos_totales(Resto, SubTotal),
    Total is SubTotal + Cred.

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

creditos_carrera([], _, 0).
creditos_carrera([curso(_, _, Cred, Carrera, _) | Resto], Carrera, Total) :-
    !,
    creditos_carrera(Resto, Carrera, SubTotal),
    Total is SubTotal + Cred.
creditos_carrera([_ | Resto], Carrera, Total) :-
    creditos_carrera(Resto, Carrera, Total).

%% =========================================================================
%% REGLA 2: Limite por area
%% Ninguna area en la combinacion puede tener mas de N cursos.
%% =========================================================================

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

%% =========================================================================
%% REGLA 3: Incompatibilidad (relacion simetrica)
%% Una combinacion no puede incluir ambos cursos de un par incompatible.
%% =========================================================================

son_incompatibles(CursoA, CursoB) :-
    par_incompatible(CursoA, CursoB).
son_incompatibles(CursoA, CursoB) :-
    par_incompatible(CursoB, CursoA).

cumple_incompatibilidad(Combinacion) :-
    \+ (
        member(curso(Cod1, _, _, _, _), Combinacion),
        member(curso(Cod2, _, _, _, _), Combinacion),
        Cod1 \= Cod2,
        son_incompatibles(Cod1, Cod2)
    ).

%% =========================================================================
%% PREDICADO MULTI-MODO (Requerimiento funcional 5)
%% Modo (+, +, -): Calcula cuantos cursos de un area especifica hay.
%% Modo (+, +, +): Verifica si la combinacion tiene N cursos de un area.
%% Modo (+, -, -): Genera por backtracking cada area presente y su conteo.
%% Modo (+, -, +): Busca por backtracking las areas con exactamente N cursos.
%% =========================================================================

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
