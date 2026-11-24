:- encoding(utf8).
% =====================================================================
% politica.pl — Hechos de política académica (Etapa 3)
% =====================================================================

:- module(politica, [
    max_porcentaje_carrera/2,
    max_cursos_area/1,
    par_incompatible/2
]).

% REGLA 1: Balance entre carreras
max_porcentaje_carrera('CE', 75).
max_porcentaje_carrera('ATI', 75).

% REGLA 2: Límite por área
max_cursos_area(3).

% REGLA 3: Incompatibilidad (simétrica en reglas.pl)
par_incompatible('CE-1103', 'TI-2402').
par_incompatible('CE-1106', 'CE-2103').
par_incompatible('CE-1106', 'CE-3101').
par_incompatible('TI-1400', 'MA-1102').
par_incompatible('CI-1106', 'CI-1107').