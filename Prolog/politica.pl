:- encoding(utf8).
% =====================================================================
% politica.pl — Hechos de política académica (Etapa 3)
%
% Valores que se pueden modificar durante la defensa:
%   - max_porcentaje_carrera/2
%   - max_cursos_area/1
%   - par_incompatible/2
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
%
% Nota: la relación es simétrica, así que solo se declara una dirección.
% ---------------------------------------------------------------------

% --- Ingeniería en Computadores ---

% Mantiene compatibilidad con tests_reglas.pl (test existente)
par_incompatible('CE1106', 'CE3101').
% Paradicmas vs. Arquitectura de Computadores I
% Justificación: ambos tienen carga alta de proyectos de programación
% simultáneos (4 paradigmas + programación a bajo nivel/simulación),
% disparando sobrecarga operativa en semanas de entrega.
par_incompatible('CE1106', 'CE2103').

% --- Administración de Tecnologías de Información (ATI) ---

% Nota: los pares de abajo son de ejemplo, ajusta los códigos a los
% cursos reales de ATI que estén en el catálogo.
par_incompatible('TI1400', 'MA1102').   % Intro programación vs. Cálculo
% Justificación: ambos son de primer/segundo semestre con alta carga
% de laboratorio y evaluaciones paralelas, sobrecargando el inicio.
par_incompatible('CI1106', 'CI1107').    % Comunicación escrita vs. oral
% Justificación: ambos implican producción de textos/presentaciones
% simultáneas con entregas semanales, compitiendo por tiempo del estudiante.