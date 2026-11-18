#ifndef MODELS_H
#define MODELS_H

#include "constants.h"

/*
 *  DIA: enum en vez de texto, porque Logic.h compara
 *  h1->dia != h2->dia directamente (comparación por valor).
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
 *  HORARIO: un bloque de tiempo.
 */
typedef struct {
    Dia dia;
    int hora_inicio;   // minutos desde medianoche
    int hora_fin;
} Horario;

/*
 *  GRUPO: una sección de un curso.
 */
typedef struct {
    int     numero_grupo;
    char    profesor[MAX_PROFESOR];
    Horario horarios[MAX_BLOQUES_POR_GRUPO];
    int     Totalhorarios;
} Grupo;

/*
 *  CURSO: información completa de un curso.
 */
typedef struct {
    char codigo[MAX_CODIGO];
    char nombre[MAX_NOMBRE];
    int  creditos;
    int  semestre;
    char carrera[MAX_CODIGO];
    char area[MAX_AREA];              // <-- NUEVO

    Grupo grupos[MAX_GRUPOS_POR_CURSO];
    int   total_grupos;

    char requisitos[MAX_REQUISITOS][MAX_CODIGO];
    int  total_requisitos;

    char correquisitos[MAX_CORREQUISITOS][MAX_CODIGO];
    int  total_correquisitos;

    int tiene_choque;
    char cursos_con_choque[MAX_CHOQUES][MAX_TEXTO_CHOQUE];
    int  total_choques;
    int es_elegible;

    char razon_no_matriculable[MAX_NOMBRE];
} Curso;

/*
 *  CATALOGO: colección dinámica de cursos.
 */
typedef struct {
    Curso *cursos;
    int    cantidad;
    int    capacidad;
} Catalogo;

#endif // MODELS_H