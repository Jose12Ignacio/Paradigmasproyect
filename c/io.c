#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "io.h"
#include "memoria.h"

/*
 * ============================================================
 *  CONSTANTES INTERNAS DEL PARSER
 * ============================================================
 */

#define MAX_LINEA_CSV 512
#define MAX_TOKEN 128

/*
 * ============================================================
 *  FUNCIONES AUXILIARES (privadas del módulo)
 * ============================================================
 */

static int hora_a_minutos(const char *hora) {
    if (hora == NULL || strlen(hora) != 5) return -1;
    if (hora[2] != ':') return -1;
    if (!isdigit((unsigned char)hora[0]) || !isdigit((unsigned char)hora[1]) ||
        !isdigit((unsigned char)hora[3]) || !isdigit((unsigned char)hora[4])) {
        return -1;
    }
    int hh = (hora[0] - '0') * 10 + (hora[1] - '0');
    int mm = (hora[3] - '0') * 10 + (hora[4] - '0');
    if (hh < 0 || hh > 23 || mm < 0 || mm > 59) return -1;
    return hh * 60 + mm;
}

static int dia_valido(const char *letra) {
    if (letra == NULL || strlen(letra) != 1) return -1;
    char c = letra[0];
    switch (c) {
        case 'L': case 'K': case 'M':
        case 'J': case 'V': case 'S':
            return 1;
        default:
            return -1;
    }
}

static int buscar_curso(const Catalogo *catalogo, const char *codigo) {
    for (int i = 0; i < catalogo->cantidad; i++) {
        if (strcmp(catalogo->cursos[i].codigo, codigo) == 0) {
            return i;
        }
    }
    return -1;
}

static int buscar_grupo(const Curso *curso, int numero_grupo) {
    for (int i = 0; i < curso->total_grupos; i++) {
        if (curso->grupos[i].numero_grupo == numero_grupo) {
            return i;
        }
    }
    return -1;
}

static int parsear_lista_codigos(const char *texto,
                                 char destino[][MAX_CODIGO],
                                 int max_items) {
    if (texto == NULL || strlen(texto) == 0) return 0;

    int count = 0;
    char copia[MAX_TOKEN * 4];
    strncpy(copia, texto, sizeof(copia) - 1);
    copia[sizeof(copia) - 1] = '\0';

    char *token = strtok(copia, ";");
    while (token != NULL && count < max_items) {
        while (*token == ' ' || *token == '\t') token++;
        char *fin = token + strlen(token) - 1;
        while (fin > token && (*fin == ' ' || *fin == '\t')) {
            *fin = '\0';
            fin--;
        }

        if (strlen(token) > 0) {
            strncpy(destino[count], token, MAX_CODIGO - 1);
            destino[count][MAX_CODIGO - 1] = '\0';
            count++;
        }
        token = strtok(NULL, ";");
    }
    return count;
}

static void inicializar_curso(Curso *c) {
    memset(c, 0, sizeof(Curso));
}

static void inicializar_grupo(Grupo *g) {
    memset(g, 0, sizeof(Grupo));
}

/*
 * ============================================================
 *  PARSER PRINCIPAL DEL CSV
 * ============================================================
 */

static int dividir_csv(char *linea, char campos[][MAX_TOKEN], int max_campos) {
    int count = 0;
    int en_comillas = 0;
    char *p = linea;
    char *inicio_campo = linea;

    while (*p != '\0' && count < max_campos) {
        if (*p == '"') {
            en_comillas = !en_comillas;
            memmove(p, p + 1, strlen(p));
            continue;
        }

        if (*p == ',' && !en_comillas) {
            *p = '\0';
            strncpy(campos[count], inicio_campo, MAX_TOKEN - 1);
            campos[count][MAX_TOKEN - 1] = '\0';
            count++;
            inicio_campo = p + 1;
        }
        p++;
    }

    if (count < max_campos) {
        strncpy(campos[count], inicio_campo, MAX_TOKEN - 1);
        campos[count][MAX_TOKEN - 1] = '\0';
        count++;
    }

    return count;
}

static int procesar_linea_csv(char *linea, Catalogo *catalogo) {
    if (strlen(linea) == 0) return 0;

    linea[strcspn(linea, "\r\n")] = '\0';

    if (strncmp(linea, "codigo,", 7) == 0) return 0;

    // 13 columnas ahora (se agregó 'area' al final)
    char campos[13][MAX_TOKEN];
    int n = dividir_csv(linea, campos, 13);
    if (n < 13) {
        fprintf(stderr, "[WARN] Línea con %d campos (esperados 13): %s\n",
                n, linea);
        return 0;
    }

    const char *codigo = campos[0];
    const char *nombre = campos[1];
    const char *creditos_str = campos[2];
    const char *semestre_str = campos[3];
    const char *carrera = campos[4];
    const char *requisitos_str = campos[5];
    const char *correquisitos_str = campos[6];
    const char *grupo_str = campos[7];
    const char *profesor = campos[8];
    const char *dia_str = campos[9];
    const char *hora_inicio_str = campos[10];
    const char *hora_fin_str = campos[11];
    const char *area = campos[12];                       // <-- NUEVO

    int idx_curso = buscar_curso(catalogo, codigo);

    if (idx_curso < 0) {
        Curso nuevo;
        inicializar_curso(&nuevo);

        strncpy(nuevo.codigo, codigo, MAX_CODIGO - 1);
        strncpy(nuevo.nombre, nombre, MAX_NOMBRE - 1);
        nuevo.creditos = atoi(creditos_str);
        nuevo.semestre = atoi(semestre_str);
        strncpy(nuevo.carrera, carrera, MAX_CODIGO - 1);
        strncpy(nuevo.area, area, MAX_AREA - 1);         // <-- NUEVO
        nuevo.total_requisitos = parsear_lista_codigos(
            requisitos_str, nuevo.requisitos, MAX_REQUISITOS);
        nuevo.total_correquisitos = parsear_lista_codigos(
            correquisitos_str, nuevo.correquisitos, MAX_CORREQUISITOS);

        if (!agregar_curso(catalogo, nuevo)) {
            fprintf(stderr, "[ERROR] No se pudo agregar curso %s\n", codigo);
            return 0;
        }
        idx_curso = catalogo->cantidad - 1;
    }

    Curso *curso = &catalogo->cursos[idx_curso];

    if (strlen(grupo_str) == 0) {
        return 1;
    }

    int numero_grupo = atoi(grupo_str);
    if (numero_grupo <= 0) {
        fprintf(stderr, "[WARN] Número de grupo inválido: %s (curso %s)\n",
                grupo_str, codigo);
        return 0;
    }

    int idx_grupo = buscar_grupo(curso, numero_grupo);

    if (idx_grupo < 0) {
        if (curso->total_grupos >= MAX_GRUPOS_POR_CURSO) {
            fprintf(stderr, "[ERROR] Curso %s excede MAX_GRUPOS_POR_CURSO (%d)\n",
                    codigo, MAX_GRUPOS_POR_CURSO);
            return 0;
        }

        Grupo nuevo_grupo;
        inicializar_grupo(&nuevo_grupo);
        nuevo_grupo.numero_grupo = numero_grupo;
        strncpy(nuevo_grupo.profesor, profesor, MAX_PROFESOR - 1);
        nuevo_grupo.Totalhorarios = 0;

        curso->grupos[curso->total_grupos] = nuevo_grupo;
        idx_grupo = curso->total_grupos;
        curso->total_grupos++;
    }

    Grupo *grupo = &curso->grupos[idx_grupo];

    if (dia_valido(dia_str) != 1) {
        fprintf(stderr, "[WARN] Día inválido: '%s' (curso %s grupo %d)\n",
                dia_str, codigo, numero_grupo);
        return 0;
    }

    int hi = hora_a_minutos(hora_inicio_str);
    int hf = hora_a_minutos(hora_fin_str);

    if (hi < 0 || hf < 0 || hf <= hi) {
        fprintf(stderr, "[WARN] Hora inválida: %s-%s (curso %s grupo %d)\n",
                hora_inicio_str, hora_fin_str, codigo, numero_grupo);
        return 0;
    }

    if (grupo->Totalhorarios >= MAX_BLOQUES_POR_GRUPO) {
        fprintf(stderr, "[WARN] Grupo %d de %s excede MAX_BLOQUES_POR_GRUPO\n",
                numero_grupo, codigo);
        return 0;
    }

    Horario *h = &grupo->horarios[grupo->Totalhorarios];
    h->dia = letra_a_dia(dia_str[0]);
    h->hora_inicio = hi;
    h->hora_fin = hf;
    grupo->Totalhorarios++;

    return 1;
}

/*
 * ============================================================
 *  FUNCIONES PÚBLICAS
 * ============================================================
 */

int cargar_catalogo_csv(const char *ruta_csv, Catalogo *catalogo) {
    if (ruta_csv == NULL || catalogo == NULL) {
        fprintf(stderr, "[ERROR] cargar_catalogo_csv: argumento NULL\n");
        return 0;
    }

    FILE *f = fopen(ruta_csv, "r");
    if (f == NULL) {
        fprintf(stderr, "[ERROR] No se pudo abrir: %s\n", ruta_csv);
        return 0;
    }

    char linea[MAX_LINEA_CSV];
    int filas_leidas = 0;
    int filas_validas = 0;

    while (fgets(linea, sizeof(linea), f) != NULL) {
        filas_leidas++;
        if (procesar_linea_csv(linea, catalogo)) {
            filas_validas++;
        }
    }

    fclose(f);

    printf("[OK] %s: %d filas leídas, %d procesadas, %d cursos en catálogo\n",
           ruta_csv, filas_leidas, filas_validas, catalogo->cantidad);

    return 1;
}

int cargar_historial(const char *ruta_historial,
                     char historial[][MAX_CODIGO],
                     int max_cursos) {
    if (ruta_historial == NULL || historial == NULL) {
        fprintf(stderr, "[ERROR] cargar_historial: argumento NULL\n");
        return -1;
    }

    FILE *f = fopen(ruta_historial, "r");
    if (f == NULL) {
        fprintf(stderr, "[ERROR] No se pudo abrir historial: %s\n",
                ruta_historial);
        return -1;
    }

    char linea[256];
    int count = 0;

    while (fgets(linea, sizeof(linea), f) != NULL && count < max_cursos) {
        linea[strcspn(linea, "\r\n")] = '\0';

        char *inicio = linea;
        while (*inicio == ' ' || *inicio == '\t') inicio++;

        char *fin = inicio + strlen(inicio) - 1;
        while (fin > inicio && (*fin == ' ' || *fin == '\t')) {
            *fin = '\0';
            fin--;
        }

        if (strlen(inicio) == 0) continue;
        if (inicio[0] == '#') continue;

        strncpy(historial[count], inicio, MAX_CODIGO - 1);
        historial[count][MAX_CODIGO - 1] = '\0';
        count++;
    }

    fclose(f);

    printf("[OK] %s: %d cursos aprobados en el historial\n",
           ruta_historial, count);

    return count;
}