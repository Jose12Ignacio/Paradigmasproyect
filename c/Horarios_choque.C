#include <stdio.h>
#include <string.h>
#include "models.h"
#include "Logic.h"

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
        for (int j = 0; j < Gr2->Totalhorarios; j++) {
            if (horarios_choque(&Gr1->horarios[i], &Gr2->horarios[j])) {
                return 1;
            }
        }
    }
    return 0;
}

// Compara dos cursos completos: choca si ALGÚN grupo del curso A
// choca con ALGÚN grupo del curso B.
int cursos_chocan(const Curso *c1, const Curso *c2) {
    for (int i = 0; i < c1->total_grupos; i++) {
        for (int j = 0; j < c2->total_grupos; j++) {
            if (grupo_choque(&c1->grupos[i], &c2->grupos[j])) {
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

    // Confirmación de correquisitos
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

    // Llenar el campo razon_no_matriculable
    if (curso->es_elegible) {
        curso->razon_no_matriculable[0] = '\0';   // cadena vacía
    } else {
        char faltantes[60] = "";
        int primera = 1;

        // Buscar requisitos faltantes
        for (int i = 0; i < curso->total_requisitos; i++) {
            int encontrado = 0;
            for (int j = 0; j < total_aprobados; j++) {
                if (strcmp(curso->requisitos[i], historial[j]) == 0) {
                    encontrado = 1;
                    break;
                }
            }
            if (!encontrado) {
                if (!primera) strcat(faltantes, ", ");
                strcat(faltantes, curso->requisitos[i]);
                primera = 0;
            }
        }

        // Buscar correquisitos faltantes
        char faltantes_correq[60] = "";
        int primera_correq = 1;
        for (int i = 0; i < curso->total_correquisitos; i++) {
            int encontrado = 0;
            for (int j = 0; j < total_aprobados; j++) {
                if (strcmp(curso->correquisitos[i], historial[j]) == 0) {
                    encontrado = 1;
                    break;
                }
            }
            if (!encontrado) {
                if (!primera_correq) strcat(faltantes_correq, ", ");
                strcat(faltantes_correq, curso->correquisitos[i]);
                primera_correq = 0;
            }
        }

        // Armar el mensaje final según lo que falte
        if (strlen(faltantes) > 0 && strlen(faltantes_correq) > 0) {
            snprintf(curso->razon_no_matriculable, MAX_NOMBRE,
                     "No cumple requisitos: %s; correquisitos: %s",
                     faltantes, faltantes_correq);
        } else if (strlen(faltantes) > 0) {
            if (strchr(faltantes, ',') != NULL) {
                snprintf(curso->razon_no_matriculable, MAX_NOMBRE,
                         "No cumple requisitos: %s", faltantes);
            } else {
                snprintf(curso->razon_no_matriculable, MAX_NOMBRE,
                         "No cumple requisito: %s", faltantes);
            }
        } else if (strlen(faltantes_correq) > 0) {
            if (strchr(faltantes_correq, ',') != NULL) {
                snprintf(curso->razon_no_matriculable, MAX_NOMBRE,
                         "No cumple correquisitos: %s", faltantes_correq);
            } else {
                snprintf(curso->razon_no_matriculable, MAX_NOMBRE,
                         "No cumple correquisito: %s", faltantes_correq);
            }
        } else {
            snprintf(curso->razon_no_matriculable, MAX_NOMBRE,
                     "No matriculable");
        }
    }
}