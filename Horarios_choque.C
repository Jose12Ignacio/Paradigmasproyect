#include <stdio.h>
#include <string.h>
#include "models.h"

// Convierte horas y minutos a minutos totales desde medianoche
int horas_minutos(int horas, int minutos) {
    return (60 * horas) + minutos;
}

// Compara dos bloques individuales de horario
int horarios_choque(const Horario *h1, const Horario *h2) {
    // Verificar si es un día distinto
    if (h1->dia != h2->dia) {
        return 0;
    }
    // Verificar si las horas se traslapan
    if (h1->hora_inicio < h2->hora_fin && h2->hora_inicio < h1->hora_fin) {
        return 1;
    }
    
    return 0;
}

// Compara dos grupos completos para detectar traslapes entre sus horarios
int grupo_choque(const Grupo *Gr1, const Grupo *Gr2) {
    for (int i = 0; i < Gr1->Totalhorarios; i++) {
        for (int j = 0; j < Gr2->Totalhorarios; j++) { // Se agregó el incremento j++
            if (horarios_choque(&Gr1->horarios[i], &Gr2->horarios[j])) {
                return 1;
            }
        }
    }
    return 0;
}

// Evalúa todo el catálogo para marcar qué cursos presentan choques de horario
void detectar_choques_catalogo(Curso catalogo[], int total_cursos) {
    
    for (int i = 0; i < total_cursos; i++) {
        catalogo[i].tiene_choque = 0;
    }

    for (int i = 0; i < total_cursos; i++) {
        for (int j = i + 1; j < total_cursos; j++) {
            
            // Si los dos cursos chocan, marcamos ambos
            if (cursos_chocan(&catalogo[i], &catalogo[j])) {
                catalogo[i].tiene_choque = 1;
                catalogo[j].tiene_choque = 1;
            }
        }
    }
}

// Determina si el estudiante cumple los requisitos y correquisitos 
void evaluar_elegibilidad_curso(Curso *curso, char historial[][MAX_CODIGO], int total_aprobados) {
    int requisitos_cumplidos = 0;
    int correquisitos_cumplidos = 0;

    
    // Confirmación de requisitos
    
    if (curso->total_requisitos == 0) {
        requisitos_cumplidos = 1; 
    } else {
        int req_encontrados = 0;
        for (int i = 0; i < curso->total_requisitos; i++) {
            for (int j = 0; j < total_aprobados; j++) {
                if (strcmp(curso->requisitos[i], historial[j]) == 0) {
                    req_encontrados++;
                    break; 
                }
            }
        }
        if (req_encontrados == curso->total_requisitos) {
            requisitos_cumplidos = 1;
        }
    }

   
    if (curso->total_correquisitos == 0) {
        correquisitos_cumplidos = 1; 
    } else {
        int correq_encontrados = 0;
        for (int i = 0; i < curso->total_correquisitos; i++) {
            for (int j = 0; j < total_aprobados; j++) {
                if (strcmp(curso->correquisitos[i], historial[j]) == 0) {
                    correq_encontrados++;
                    break; 
                }
            }
        }
        if (correq_encontrados == curso->total_correquisitos) {
            correquisitos_cumplidos = 1;
        }
    }

    
    
    if (requisitos_cumplidos && correquisitos_cumplidos) {
        curso->es_elegible = 1;
    } else {
        curso->es_elegible = 0;
    }
}