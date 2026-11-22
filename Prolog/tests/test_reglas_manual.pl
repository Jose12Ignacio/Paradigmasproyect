:- encoding(utf8).

% =====================================================================
% test_reglas_manual.pl
% Prueba manual de las 3 reglas de política académica.
% Se ejecuta desde la carpeta tests/ y busca los módulos en el directorio padre.
% =====================================================================

% Agregar el directorio padre al path de búsqueda de módulos
:- asserta(user:file_search_path(library, '..')).
:- use_module(library(reglas)).
:- use_module(library(politica)).

% =====================================================================
% CASOS DE PRUEBA
% =====================================================================

% Prueba 1: Combinación que viola REGLA 2 (4 cursos de Computación, máx 3)
combinacion_limite_area([
    curso('CE-1103', 1, 4, 'CE', 'Computación'),
    curso('CE-1104', 1, 3, 'CE', 'Computación'),
    curso('CE-1105', 1, 3, 'CE', 'Computación'),
    curso('CE-1101', 1, 3, 'CE', 'Computación')
]).

% Prueba 2: Combinación que viola REGLA 3 (par incompatible)
combinacion_incompatible([
    curso('CE-1106', 1, 3, 'CE', 'Computación'),
    curso('CE-3101', 1, 4, 'CE', 'Computación')
]).

% Prueba 3: Combinación que CUMPLE REGLA 1 (balance)
% 2 CE (7 créditos) + 1 ATI (3 créditos). Total 10. CE = 70%. (Cumple si el máximo es 75%).
combinacion_balance_ok([
    curso('CE-1103', 1, 4, 'CE', 'Computación'),
    curso('CE-1104', 1, 3, 'CE', 'Computación'),
    curso('TI-1400', 1, 3, 'ATI', 'Tecnologías de Información')
]).

% Prueba 4: Combinación que VIOLA REGLA 1 (balance)
% 4 CE (13 créditos) + 1 ATI (3 créditos). Total 16. CE = 81.25%. (Viola si el máximo es 75%).
combinacion_balance_fail([
    curso('CE-1103', 1, 4, 'CE', 'Computación'),
    curso('CE-1104', 1, 3, 'CE', 'Computación'),
    curso('CE-1105', 1, 3, 'CE', 'Computación'),
    curso('CE-1101', 1, 3, 'CE', 'Computación'),
    curso('TI-1400', 1, 3, 'ATI', 'Tecnologías de Información')
]).

% =====================================================================
% EJECUCIÓN DE PRUEBAS
% =====================================================================

main :-
    format("=== PRUEBA DE REGLAS ===~n~n"),
    
    format("1. Combinacion con 4 cursos de Computacion (max 3):~n"),
    combinacion_limite_area(C1),
    ( cumple_limite_area(C1) 
    -> format("   -> CUMPLE (mal)~n") 
    ;  format("   -> VIOLA (correcto)~n") 
    ),
    
    format("~n2. Combinacion con CE-1106 y CE-3101 (incompatibles):~n"),
    combinacion_incompatible(C2),
    ( cumple_incompatibilidad(C2) 
    -> format("   -> CUMPLE (mal)~n") 
    ;  format("   -> VIOLA (correcto)~n") 
    ),
    
    format("~n3. Combinacion con 2 CE y 1 ATI (balance CE alrededor de 70%):~n"),
    combinacion_balance_ok(C3),
    ( cumple_balance_carreras(C3) 
    -> format("   -> CUMPLE (correcto)~n") 
    ;  format("   -> VIOLA (mal)~n") 
    ),
    
    format("~n4. Combinacion con 4 CE y 1 ATI (balance CE alrededor de 81%):~n"),
    combinacion_balance_fail(C4),
    ( cumple_balance_carreras(C4) 
    -> format("   -> CUMPLE (mal)~n") 
    ;  format("   -> VIOLA (correcto)~n") 
    ),
    
    format("~n=== FIN ===~n").