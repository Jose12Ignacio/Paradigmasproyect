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
    // 1. Limpiar flags y contadores
    for (int i = 0; i < total_cursos; i++) {
        catalogo[i].tiene_choque = 0;
        catalogo[i].total_choques = 0;
    }

    // 2. Comparar pares de cursos y detallar el choque entre grupos
    for (int i = 0; i < total_cursos; i++) {
        Curso *c1 = &catalogo[i];

        for (int j = i + 1; j < total_cursos; j++) {
            Curso *c2 = &catalogo[j];

            // Iterar sobre cada grupo de c1 y c2
            for (int g1 = 0; g1 < c1->total_grupos; g1++) {
                Grupo *gr1 = &c1->grupos[g1];

                for (int g2 = 0; g2 < c2->total_grupos; g2++) {
                    Grupo *gr2 = &c2->grupos[g2];

                    // Si hay colisión entre el grupo gr1 y el grupo gr2
                    if (grupo_choque(gr1, gr2)) {
                        c1->tiene_choque = 1;
                        c2->tiene_choque = 1;

                        // Registrar en c1: "G<num> con <codigo_rival> (G<num>)"
                        if (c1->total_choques < MAX_CHOQUES) {
                            snprintf(c1->cursos_con_choque[c1->total_choques],
                                     MAX_TEXTO_CHOQUE,
                                     "G%d con %s (G%d)",
                                     gr1->numero_grupo, c2->codigo, gr2->numero_grupo);
                            c1->total_choques++;
                        }

                        // Registrar en c2 la relación simétrica
                        if (c2->total_choques < MAX_CHOQUES) {
                            snprintf(c2->cursos_con_choque[c2->total_choques],
                                     MAX_TEXTO_CHOQUE,
                                     "G%d con %s (G%d)",
                                     gr2->numero_grupo, c1->codigo, gr1->numero_grupo);
                            c2->total_choques++;
                        }
                    }
                }
            }
        }
    }
}

// Determina si el estudiante cumple los requisitos y correquisitos
void evaluar_elegibilidad_curso(Curso *curso, char historial[][MAX_CODIGO], int total_aprobados) {
    int requisitos_cumplidos = 0;

    // Confirmación de requisitos previos únicamente
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

    // La elegibilidad depende únicamente de los requisitos
    curso->es_elegible = requisitos_cumplidos;

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

        // Armar el mensaje final según los requisitos faltantes
        if (strlen(faltantes) > 0) {
            if (strchr(faltantes, ',') != NULL) {
                snprintf(curso->razon_no_matriculable, MAX_NOMBRE,
                         "No cumple requisitos: %s", faltantes);
            } else {
                snprintf(curso->razon_no_matriculable, MAX_NOMBRE,
                         "No cumple requisito: %s", faltantes);
            }
        } else {
            snprintf(curso->razon_no_matriculable, MAX_NOMBRE,
                     "No matriculable");
        }
    }
}