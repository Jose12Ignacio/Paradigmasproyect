:- encoding(utf8).
% =====================================================================
% carga.pl — Lector del JSON de salida de Racket (Etapa 2)
%
% Lee salida_etapa2.json y agrega hechos combinacion(Id, Cursos) para
% cada combinación, donde Cursos es una lista de términos:
%     curso(Codigo, Grupo, Creditos, Carrera, Area)
%
% El formato de curso/5 coincide con el que esperan reglas.pl y evaluador.pl.
%
% Asume que el JSON tiene (por cada combinación):
%     id_combinacion: N
%     creditos_totales: M
%     selecciones: [
%         {curso: 'CE-1105', grupo: 1, carrera: 'CE', area: 'Computación', creditos: 3}
%     ]
% =====================================================================

:- if(exists_source(library(http/json))).
:- use_module(library(http/json)).
:- else.
:- use_module(library(json)).
:- endif.

:- dynamic combinacion/2.

% cargar_combinaciones(+Ruta)
%   Lee el JSON y agrega hechos combinacion(Id, Cursos) por cada combinación.
cargar_combinaciones(Ruta) :-
    retractall(combinacion(_, _)),
    setup_call_cleanup(
        open(Ruta, read, In, [encoding(utf8)]),
        json_read_dict(In, Dict),
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

% dict_get_required(+Dict, +Key, -Value)
%   Igual que get_dict/3 pero lanza error claro si falta la clave.
dict_get_required(Dict, Key, Value) :-
    (   get_dict(Key, Dict, Value)
    ->  true
    ;   throw(error(missing_key(Key, Dict), _))
    ).