:- encoding(utf8).
% =====================================================================
% exportador.pl  (Integrante 3)
%
% Recorre TODAS las combinaciones cargadas por backtracking, evalua cada una
% y escribe el archivo de salida (contrato con la Etapa 4, Java).
%
% Sin assert/retract: los resultados se acumulan con findall/3 y se pasan
% como argumentos. combinacion/2 la llena el cargador de Integrante 1.
% =====================================================================

:- if(exists_source(library(json))).
:- use_module(library(json)).
:- else.
:- use_module(library(http/json)).
:- endif.

% La carga de entrada (Integrante 1) agrega hechos combinacion(Id, Cursos).
:- dynamic combinacion/2.

% exportar_resultados(+RutaSalida, -Resumen)
%   Resumen = resumen(Total, Cumplen)
exportar_resultados(Ruta, resumen(Total, Cumplen)) :-
    findall(Resultado,
            (   combinacion(Id, Cursos),                    % backtracking sobre TODAS
                resultado_combinacion(Id, Cursos, Resultado)
            ),
            Resultados),
    length(Resultados, Total),
    include(cumple_resultado, Resultados, Validos),
    length(Validos, Cumplen),
    orden_reglas(Orden),
    Documento = _{total: Total, orden_reglas: Orden, resultados: Resultados},
    escribir_json(Ruta, Documento).

cumple_resultado(Resultado) :-
    get_dict(cumple, Resultado, true).

% Un resultado por combinacion: pares curso-grupo, veredicto y razon.
resultado_combinacion(Id, Cursos,
                      _{id: Id, cursos: Pares, cumple: Veredicto, razon: Razon}) :-
    maplist(par_curso_grupo, Cursos, Pares),
    evaluar(Cursos, Veredicto, Interna),
    razon_exportable(Interna, Razon).

par_curso_grupo(curso(Codigo, Grupo, _, _, _), _{curso: Codigo, grupo: Grupo}).

% 'ninguna' (uso interno) se exporta como null, que Java lee de forma nativa.
razon_exportable(ninguna, null).
razon_exportable(Razon, Razon) :-
    Razon \== ninguna.

escribir_json(Ruta, Documento) :-
    setup_call_cleanup(
        open(Ruta, write, Out, [encoding(utf8)]),
        ( json_write_dict(Out, Documento), nl(Out) ),
        close(Out)).
