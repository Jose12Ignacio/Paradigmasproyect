:- encoding(utf8).
% =====================================================================
% main.pl  (Integrante 3)  -  Etapa 3: evaluador de politica academica
%
% Uso:
%     swipl main.pl <combinaciones_de_racket> <resultado>
%     swipl main.pl                          (usa combinaciones.json y resultado.json)
% Uso interactivo (sin ejecutar main):
%     swipl -l main.pl
%     ?- ejecutar('combinaciones.json', 'resultado.json').
%
% politica.pl se vuelve a leer del disco en CADA ejecucion, asi que los
% valores que se editen en ese archivo (incluso durante la defensa) se
% aplican en la siguiente corrida sin tocar nada mas.
% =====================================================================

:- initialization(main, main).

:- consult(evaluador).     % Integrante 3: evaluar/3 con ! y \+
:- consult(exportador).    % Integrante 3: recorrido por backtracking + JSON
:- consult(carga).         % Integrante 1: cargar_combinaciones/1
:- consult(reglas).        % Integrante 2: cumple_balance_carreras/1, cumple_limite_area/1, cumple_incompatibilidad/1

main(Argv) :-
    catch(ejecutar_con_argumentos(Argv), Error, manejar_error(Error)).

ejecutar_con_argumentos([Entrada, Salida]) :-
    !,
    ejecutar(Entrada, Salida).
ejecutar_con_argumentos([]) :-
    !,
    ejecutar('combinaciones.json', 'resultado.json').
ejecutar_con_argumentos(_) :-
    format(user_error, "Uso: swipl main.pl <combinaciones_de_racket> <resultado>~n", []),
    halt(1).

% ejecutar(+Entrada, +Salida): un ciclo completo (politica -> carga -> evaluacion -> archivo).
ejecutar(Entrada, Salida) :-
    cargar_politica,
    cargar_combinaciones(Entrada),                 % Integrante 1
    advertir_carreras_sin_politica,
    exportar_resultados(Salida, resumen(Total, Cumplen)),
    Rechazadas is Total - Cumplen,
    format("Combinaciones evaluadas: ~d (cumplen: ~d, rechazadas: ~d)~n",
           [Total, Cumplen, Rechazadas]),
    format("Resultado escrito en: ~w~n", [Salida]),
    advertir_si_vacio(Total).

% Si una carrera de los datos no tiene porcentaje en politica.pl, la regla 1 FALLA para
% toda combinacion que la incluya y todas se rechazan con balance_carreras, sin ningun
% error. Este aviso lo hace visible antes de evaluar.
advertir_carreras_sin_politica :-
    findall(Carrera,
            (   combinacion(_, Cursos),
                member(curso(_, _, _, Carrera, _), Cursos) ),
            Todas),
    sort(Todas, Carreras),
    forall(( member(Carrera, Carreras),
             \+ politica:max_porcentaje_carrera(Carrera, _) ),
           format(user_error,
                  "Aviso: la carrera '~w' no tiene porcentaje maximo en politica.pl; ~w~n",
                  [Carrera, "las combinaciones que la incluyan se rechazaran por balance_carreras."])).

advertir_si_vacio(0) :-
    !,
    format(user_error, "Aviso: no se encontro ninguna combinacion en la entrada.~n", []).
advertir_si_vacio(_).

% Vuelve a leer politica.pl SIEMPRE (if(true)), desde la carpeta de este script,
% sin importar desde donde se ejecute swipl.
cargar_politica :-
    directorio_script(Dir),
    directory_file_path(Dir, 'politica.pl', Ruta),
    load_files(Ruta, [if(true), silent(true)]).

directorio_script(Dir) :-
    source_file(main(_), Archivo),
    file_directory_name(Archivo, Dir).

manejar_error(Error) :-
    print_message(error, Error),
    halt(1).
