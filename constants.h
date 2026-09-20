#ifndef CONSTANTS_H
#define CONSTANTS_H

// --- Tamaños de texto ---
#define MAX_CODIGO 10          // ej. "CE1103" + null terminator
#define MAX_NOMBRE 100

// --- Límites por curso/grupo (arreglos fijos: un curso no tiene decenas de grupos) ---
#define MAX_GRUPOS_POR_CURSO 6
#define MAX_BLOQUES_POR_GRUPO 4     // bloques de horario por grupo (ej. lun+mie+vie = 3)
#define MAX_REQUISITOS 5
#define MAX_CORREQUISITOS 5

// --- Historial del estudiante ---
#define MAX_CURSOS_HISTORIAL 60     // 4 semestres * 2 carreras, con margen

#endif // CONSTANTS_H
