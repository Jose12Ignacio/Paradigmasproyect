:- encoding(utf8).
% =====================================================================
% carga.pl — Lector del JSON de salida de Racket (Etapa 2)
% =====================================================================

:- use_module(library(http/json)).

:- dynamic combinacion/2.

% cargar_combinaciones(+Ruta)
cargar_combinaciones(Ruta) :-
    retractall(combinacion(_, _)),
    setup_call_cleanup(
        open(Ruta, read, In, [encoding(utf8)]),
        json_read_dict(In, Dict, [value_string_as(atom)]),
        close(In)),
    dict_get_required(Dict, combinaciones, Combinaciones),
    forall(member(Comb, Combinaciones), agregar_combinacion(Comb)).

agregar_combinacion(Comb) :-
    dict_get_required(Comb, id_combinacion, Id),
    dict_get_required(Comb, selecciones, Selecciones),
    maplist(seleccion_a_curso, Selecciones, Cursos),
    assertz(combinacion(Id, Cursos)).

seleccion_a_curso(Sel, curso(Codigo, Grupo, Creditos, Carrera, Area)) :-
    dict_get_required(Sel, curso, Codigo),
    dict_get_required(Sel, grupo, Grupo),
    dict_get_required(Sel, creditos, Creditos),
    dict_get_required(Sel, carrera, Carrera),
    dict_get_required(Sel, area, Area).

dict_get_required(Dict, Key, Value) :-
    (   get_dict(Key, Dict, Value)
    ->  true
    ;   throw(error(missing_key(Key, Dict), _))
    ).