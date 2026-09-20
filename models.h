#ifndef MODELS_H
#define MODELS_H

#include "constants.h"

/*
 * ---------------------------------------------------------------
 *  DIA: enum en vez de texto, porque Logic.h compara
 *  h1->dia != h2->dia directamente (comparación por valor).
 *  Si esto se define como texto, esa comparación se rompe.
 * ---------------------------------------------------------------
 */
typedef enum {
    LUNES,
    MARTES,
    MIERCOLES,
    JUEVES,
    VIERNES,
    SABADO
} Dia;

/*
 * ---------------------------------------------------------------
 *  HORARIO: un bloque de tiempo (nombres exactos que usa
 *  horarios_choque en Horarios_choque.C)
 * ---------------------------------------------------------------
 */
typedef struct {
    Dia dia;
    int hora_inicio;   // minutos desde medianoche, ej. 07:00 -> 420
    int hora_fin;
} Horario;

/*
 * ---------------------------------------------------------------
 *  GRUPO: nombres exactos que usa grupo_choque
 * ---------------------------------------------------------------
 */
typedef struct {
    int     numero_grupo;
    Horario horarios[MAX_BLOQUES_POR_GRUPO];
    int     Totalhorarios;   // tal cual lo escribió tu compañero
} Grupo;

/*
 * ---------------------------------------------------------------
 *  CURSO: nombres exactos que usa detectar_choques_catalogo
 *  y evaluar_elegibilidad_curso
 * ---------------------------------------------------------------
 */
typedef struct {
    char codigo[MAX_CODIGO];
    char nombre[MAX_NOMBRE];
    int  creditos;

    Grupo grupos[MAX_GRUPOS_POR_CURSO];
    int   total_grupos;

    char requisitos[MAX_REQUISITOS][MAX_CODIGO];
    int  total_requisitos;

    char correquisitos[MAX_CORREQUISITOS][MAX_CODIGO];
    int  total_correquisitos;

    int tiene_choque;   // 0 o 1, tal como lo asigna Horarios_choque.C
    int es_elegible;    // 0 o 1
} Curso;

/*
 * ---------------------------------------------------------------
 *  CATALOGO: colección dinámica de cursos (tu parte: malloc/realloc)
 * ---------------------------------------------------------------
 */
typedef struct {
    Curso *cursos;
    int    cantidad;
    int    capacidad;
} Catalogo;

#endif // MODELS_H
