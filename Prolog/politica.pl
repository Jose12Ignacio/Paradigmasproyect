:- encoding(utf8).
% =====================================================================
% politica.pl — Hechos de política académica (Etapa 3)
%
% Valores que se pueden modificar durante la defensa:
%   - max_porcentaje_carrera/2
%   - max_cursos_area/1
%   - par_incompatible/2
%
% IMPORTANTE: carreras y códigos de curso se escriben EXACTAMENTE como vienen en
% los datos ('CE', 'ATI', 'CE-1103', con guion). Si no coinciden, la regla no se
% activa (regla 3) o rechaza todo (regla 1).
%
% La relación de incompatibilidad es SIMÉTRICA (la maneja son_incompatibles/2
% en reglas.pl), así que solo hay que declarar cada par una vez.
% =====================================================================

:- module(politica, [
    max_porcentaje_carrera/2,
    max_cursos_area/1,
    par_incompatible/2
]).

% ---------------------------------------------------------------------
% REGLA 1: Balance entre carreras
% Porcentaje máximo de créditos que una carrera puede aportar al total.
% ---------------------------------------------------------------------
max_porcentaje_carrera('CE', 75).
max_porcentaje_carrera('ATI', 75).

% ---------------------------------------------------------------------
% REGLA 2: Límite por área
% Máximo de cursos de una misma área en una combinación.
% ---------------------------------------------------------------------
max_cursos_area(3).

% ---------------------------------------------------------------------
% REGLA 3: Incompatibilidad
% Pares de cursos que NO deberían matricularse juntos en el mismo semestre.
% Nota: la relación es simétrica, así que solo se declara una dirección.
% ---------------------------------------------------------------------

% Entre las dos carreras
% CE-1103 (Algoritmos y estructuras de datos 1, CE) y TI-2402 (Algoritmos y
% estructuras de datos, ATI): es el mismo contenido en las dos carreras, así que
% llevar ambos en el mismo semestre no aporta nada y duplica la carga.
par_incompatible('CE-1103', 'TI-2402').

% --- Ingeniería en Computadores ---

% CE-1106 (Paradigmas de programación) y CE-2103 (Algoritmos y estructuras de
% datos 2): ambos tienen proyectos de programación extensos, y llevarlos juntos
% concentra las entregas del semestre (decisión del equipo).
par_incompatible('CE-1106', 'CE-2103').

% --- Administración de Tecnologías de Información (ATI) ---

% TI-1400 (Introducción a la programación) y MA-1102 (Cálculo diferencial e
% integral): ambos son de los primeros semestres y con evaluaciones frecuentes
% (decisión del equipo).
par_incompatible('TI-1400', 'MA-1102').

% CI-1106 (Comunicación escrita) y CI-1107 (Comunicación oral): ambos exigen
% producir textos o presentaciones con entregas semanales (decisión del equipo).
par_incompatible('CI-1106', 'CI-1107').
