#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "serializar.h"

/*
 * ============================================================
 *  CONSTANTES INTERNAS
 * ============================================================
 */

#define VERSION_ESQUEMA "1.1"

/*
 * ============================================================
 *  FUNCIONES AUXILIARES
 * ============================================================
 */

/**
 * Convierte un valor del enum Dia a su letra correspondiente
 * según la convención del TEC: L, K, M, J, V, S.
 */
static const char* dia_a_letra(Dia dia) {
    switch (dia) {
        case LUNES:     return "L";
        case MARTES:    return "K";
        case MIERCOLES: return "M";
        case JUEVES:    return "J";
        case VIERNES:   return "V";
        case SABADO:    return "S";
        default:        return "?";
    }
}

/**
 * Convierte minutos desde medianoche a formato "HH:MM".
 */
static void minutos_a_hora(int minutos, char *buffer, int tam) {
    if (minutos < 0 || minutos >= 24 * 60) {
        snprintf(buffer, tam, "??:??");
        return;
    }
    int hh = minutos / 60;
    int mm = minutos % 60;
    snprintf(buffer, tam, "%02d:%02d", hh, mm);
}

/**
 * Escribe un string JSON escapado. Escapa comillas dobles y
 * backslashes. Los caracteres UTF-8 (tildes, ñ) se emiten tal cual.
 */
static void escribir_string_json(FILE *f, const char *texto) {
    if (texto == NULL) {
        fprintf(f, "null");
        return;
    }
    fputc('"', f);
    for (const char *p = texto; *p != '\0'; p++) {
        if (*p == '"') {
            fprintf(f, "\\\"");
        } else if (*p == '\\') {
            fprintf(f, "\\\\");
        } else if (*p == '\n') {
            fprintf(f, "\\n");
        } else if (*p == '\r') {
            fprintf(f, "\\r");
        } else if (*p == '\t') {
            fprintf(f, "\\t");
        } else {
            fputc(*p, f);
        }
    }
    fputc('"', f);
}

/**
 * Escribe un arreglo JSON de strings a partir de un arreglo de códigos (MAX_CODIGO).
 * Ej: ["CE-1101","CE-1104"]
 */
static void escribir_array_strings(FILE *f,
                                   const char arreglo[][MAX_CODIGO],
                                   int total) {
    fputc('[', f);
    for (int i = 0; i < total; i++) {
        escribir_string_json(f, arreglo[i]);
        if (i < total - 1) fputc(',', f);
    }
    fputc(']', f);
}

/**
 * Escribe un arreglo JSON de strings para el detalle de choques (MAX_TEXTO_CHOQUE).
 */
static void escribir_array_choques(FILE *f,
                                   const char arreglo[][MAX_TEXTO_CHOQUE],
                                   int total) {
    fputc('[', f);
    for (int i = 0; i < total; i++) {
        escribir_string_json(f, arreglo[i]);
        if (i < total - 1) fputc(',', f);
    }
    fputc(']', f);
}

/**
 * Escribe el bloque de horarios de un grupo.
 * Ej: [{"dia":"K","hora_inicio":"07:30","hora_fin":"09:20"}, ...]
 */
static void escribir_horarios(FILE *f, const Grupo *grupo, int indent) {
    fputc('[', f);
    for (int i = 0; i < grupo->Totalhorarios; i++) {
        const Horario *h = &grupo->horarios[i];
        char hi[8], hf[8];
        minutos_a_hora(h->hora_inicio, hi, sizeof(hi));
        minutos_a_hora(h->hora_fin, hf, sizeof(hf));

        fprintf(f, "\n%*s{ ", indent + 2, "");
        fprintf(f, "\"dia\": ");
        escribir_string_json(f, dia_a_letra(h->dia));
        fprintf(f, ", \"hora_inicio\": ");
        escribir_string_json(f, hi);
        fprintf(f, ", \"hora_fin\": ");
        escribir_string_json(f, hf);
        fprintf(f, " }");
        if (i < grupo->Totalhorarios - 1) fputc(',', f);
    }
    if (grupo->Totalhorarios > 0) {
        fprintf(f, "\n%*s", indent, "");
    }
    fputc(']', f);
}

/**
 * Escribe el arreglo de grupos de un curso.
 */
static void escribir_grupos(FILE *f, const Curso *curso, int indent) {
    fputc('[', f);
    for (int g = 0; g < curso->total_grupos; g++) {
        const Grupo *grupo = &curso->grupos[g];
        fprintf(f, "\n%*s{", indent + 2, "");
        fprintf(f, "\n%*s\"numero\": %d,", indent + 4, "", grupo->numero_grupo);

        fprintf(f, "\n%*s\"profesor\": ", indent + 4, "");
        if (strlen(grupo->profesor) > 0) {
            escribir_string_json(f, grupo->profesor);
        } else {
            fprintf(f, "null");
        }

        fprintf(f, ",\n%*s\"horarios\": ", indent + 4, "");
        escribir_horarios(f, grupo, indent + 4);

        fprintf(f, "\n%*s}", indent + 2, "");
        if (g < curso->total_grupos - 1) fputc(',', f);
    }
    if (curso->total_grupos > 0) {
        fprintf(f, "\n%*s", indent, "");
    }
    fputc(']', f);
}

/**
 * Escribe un curso completo en formato JSON.
 */
static void escribir_curso(FILE *f, const Curso *curso, int indent) {
    fprintf(f, "%*s{\n", indent, "");

    // codigo
    fprintf(f, "%*s\"codigo\": ", indent + 2, "");
    escribir_string_json(f, curso->codigo);
    fprintf(f, ",\n");

    // nombre
    fprintf(f, "%*s\"nombre\": ", indent + 2, "");
    escribir_string_json(f, curso->nombre);
    fprintf(f, ",\n");

    // creditos
    fprintf(f, "%*s\"creditos\": %d,\n", indent + 2, "", curso->creditos);

    // semestre
    fprintf(f, "%*s\"semestre\": %d,\n", indent + 2, "", curso->semestre);

    // requisitos
    fprintf(f, "%*s\"requisitos\": ", indent + 2, "");
    escribir_array_strings(f, curso->requisitos, curso->total_requisitos);
    fprintf(f, ",\n");

    // correquisitos
    fprintf(f, "%*s\"correquisitos\": ", indent + 2, "");
    escribir_array_strings(f, curso->correquisitos, curso->total_correquisitos);
    fprintf(f, ",\n");

    // grupos
    fprintf(f, "%*s\"grupos\": ", indent + 2, "");
    escribir_grupos(f, curso, indent + 2);
    fprintf(f, ",\n");

    // tiene_choque
    fprintf(f, "%*s\"tiene_choque\": %s,\n",
            indent + 2, "",
            curso->tiene_choque ? "true" : "false");

    // cursos_con_choque (detallado con grupo)
    fprintf(f, "%*s\"cursos_con_choque\": ", indent + 2, "");
    escribir_array_choques(f, curso->cursos_con_choque, curso->total_choques);
    fprintf(f, ",\n");

    // es_matriculable
    fprintf(f, "%*s\"es_matriculable\": %s,\n",
            indent + 2, "",
            curso->es_elegible ? "true" : "false");

    // razon_no_matriculable
    fprintf(f, "%*s\"razon_no_matriculable\": ", indent + 2, "");
    if (curso->es_elegible || strlen(curso->razon_no_matriculable) == 0) {
        fprintf(f, "null");
    } else {
        escribir_string_json(f, curso->razon_no_matriculable);
    }
    fprintf(f, "\n");

    fprintf(f, "%*s}", indent, "");
}

/**
 * Escribe la fecha en formato YYYY-MM-DD.
 */
static void escribir_fecha_actual(FILE *f) {
    time_t t = time(NULL);
    struct tm *tm_info = localtime(&t);
    char buffer[16];
    strftime(buffer, sizeof(buffer), "%Y-%m-%d", tm_info);
    fprintf(f, "\"%s\"", buffer);
}

/*
 * ============================================================
 *  FUNCIÓN PRINCIPAL
 * ============================================================
 */

int exportar_json(const char *ruta_salida,
                  const Catalogo *catalogo,
                  const char *carrera,
                  const char *siglas,
                  char historial[][MAX_CODIGO],
                  int total_historial) {

    if (ruta_salida == NULL || catalogo == NULL ||
        carrera == NULL || siglas == NULL) {
        fprintf(stderr, "[ERROR] exportar_json: argumento NULL\n");
        return 0;
    }

    FILE *f = fopen(ruta_salida, "w");
    if (f == NULL) {
        fprintf(stderr, "[ERROR] No se pudo abrir para escribir: %s\n",
                ruta_salida);
        return 0;
    }

    // --- metadata ---
    fprintf(f, "{\n");
    fprintf(f, "  \"metadata\": {\n");

    fprintf(f, "    \"carrera\": ");
    escribir_string_json(f, carrera);
    fprintf(f, ",\n");

    fprintf(f, "    \"siglas\": ");
    escribir_string_json(f, siglas);
    fprintf(f, ",\n");

    fprintf(f, "    \"semestres_incluidos\": [0, 1, 2, 3, 4],\n");

    fprintf(f, "    \"total_cursos\": %d,\n", catalogo->cantidad);

    fprintf(f, "    \"version_esquema\": ");
    escribir_string_json(f, VERSION_ESQUEMA);
    fprintf(f, ",\n");

    fprintf(f, "    \"fecha_generacion\": ");
    escribir_fecha_actual(f);
    fprintf(f, ",\n");

    fprintf(f, "    \"estudiante_historial\": ");
    escribir_array_strings(f, historial, total_historial);
    fprintf(f, "\n");

    fprintf(f, "  },\n");

    // --- cursos ---
    fprintf(f, "  \"cursos\": [");
    for (int i = 0; i < catalogo->cantidad; i++) {
        if (i > 0) fprintf(f, ",");
        fprintf(f, "\n");
        escribir_curso(f, &catalogo->cursos[i], 4);
    }
    if (catalogo->cantidad > 0) fprintf(f, "\n  ");
    fprintf(f, "]\n");

    fprintf(f, "}\n");

    fclose(f);

    printf("[OK] JSON exportado: %s (%d cursos)\n",
           ruta_salida, catalogo->cantidad);

    return 1;
}