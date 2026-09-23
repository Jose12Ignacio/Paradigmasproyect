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

/**
 * Convierte una hora "HH:MM" a minutos desde medianoche.
 * Retorna -1 si el formato es inválido.
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

/**
 * Convierte la letra del CSV (L, K, M, J, V, S) al enum Dia.
 * Reutiliza letra_a_dia() de memoria.c pero de forma segura:
 * retorna -1 si la letra no es válida.
 */
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

/**
 * Busca un curso por código en el catálogo.
 * Retorna el índice en catalogo->cursos, o -1 si no existe.
 */
static int buscar_curso(const Catalogo *catalogo, const char *codigo) {
    for (int i = 0; i < catalogo->cantidad; i++) {
        if (strcmp(catalogo->cursos[i].codigo, codigo) == 0) {
            return i;
        }
    }
    return -1;
}

/**
 * Busca un grupo por número dentro de un curso.
 * Retorna el índice en curso->grupos, o -1 si no existe.
 */
static int buscar_grupo(const Curso *curso, int numero_grupo) {
    for (int i = 0; i < curso->total_grupos; i++) {
        if (curso->grupos[i].numero_grupo == numero_grupo) {
            return i;
        }
    }
    return -1;
}

/**
 * Parsea una lista de códigos separados por ';' y los mete en un
 * arreglo de strings. Retorna la cantidad de códigos parseados.
 *
 * Ejemplo: "CE-1101;CE-1104;MA-1403" -> ["CE-1101","CE-1104","MA-1403"]
 */
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
        // Quitar espacios al inicio y final
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

/**
 * Inicializa un curso en cero.
 */
static void inicializar_curso(Curso *c) {
    memset(c, 0, sizeof(Curso));
}

/**
 * Inicializa un grupo en cero.
 */
static void inicializar_grupo(Grupo *g) {
    memset(g, 0, sizeof(Grupo));
}

/*
 * ============================================================
 *  PARSER PRINCIPAL DEL CSV
 * ============================================================
 */

/**
 * Divide una línea CSV por comas, respetando comillas dobles.
 * Retorna la cantidad de campos parseados.
 *
 * Soporta: "campo con coma, adentro" que se parsea como un solo campo.
 */
static int dividir_csv(char *linea, char campos[][MAX_TOKEN], int max_campos) {
    int count = 0;
    int en_comillas = 0;
    char *p = linea;
    char *inicio_campo = linea;

    while (*p != '\0' && count < max_campos) {
        if (*p == '"') {
            en_comillas = !en_comillas;
            // Mover el contenido para saltar la comilla
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

    // Último campo (después de la última coma o si no hay comas)
    if (count < max_campos) {
        strncpy(campos[count], inicio_campo, MAX_TOKEN - 1);
        campos[count][MAX_TOKEN - 1] = '\0';
        count++;
    }

    return count;
}

/**
 * Procesa una línea del CSV y actualiza el catálogo.
 * Retorna 1 si tuvo éxito, 0 si la línea debe ignorarse.
 */
static int procesar_linea_csv(char *linea, Catalogo *catalogo) {
    // Ignorar líneas vacías
    if (strlen(linea) == 0) return 0;

    // Quitar \n y \r
    linea[strcspn(linea, "\r\n")] = '\0';

    // Ignorar encabezado
    if (strncmp(linea, "codigo,", 7) == 0) return 0;

    // Dividir en campos
    char campos[11][MAX_TOKEN];
    int n = dividir_csv(linea, campos, 11);
    if (n < 11) {
        fprintf(stderr, "[WARN] Línea con %d campos (esperados 11): %s\n",
                n, linea);
        return 0;
    }

    // Extraer campos
    const char *codigo = campos[0];
    const char *nombre = campos[1];
    const char *creditos_str = campos[2];
    const char *semestre_str = campos[3];
    const char *requisitos_str = campos[4];
    const char *correquisitos_str = campos[5];
    const char *grupo_str = campos[6];
    const char *profesor = campos[7];
    const char *dia_str = campos[8];
    const char *hora_inicio_str = campos[9];
    const char *hora_fin_str = campos[10];

    // --- Buscar o crear el curso ---
    int idx_curso = buscar_curso(catalogo, codigo);

    if (idx_curso < 0) {
        // Curso nuevo: crear
        Curso nuevo;
        inicializar_curso(&nuevo);

        strncpy(nuevo.codigo, codigo, MAX_CODIGO - 1);
        strncpy(nuevo.nombre, nombre, MAX_NOMBRE - 1);
        nuevo.creditos = atoi(creditos_str);
        nuevo.semestre = atoi(semestre_str);
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

    // --- Si la fila no tiene grupo, no hay horario que agregar ---
    if (strlen(grupo_str) == 0) {
        return 1;  // curso sin grupos, ya quedó registrado
    }

    // --- Parsear número de grupo ---
    int numero_grupo = atoi(grupo_str);
    if (numero_grupo <= 0) {
        fprintf(stderr, "[WARN] Número de grupo inválido: %s (curso %s)\n",
                grupo_str, codigo);
        return 0;
    }

    // --- Buscar o crear el grupo ---
    int idx_grupo = buscar_grupo(curso, numero_grupo);

    if (idx_grupo < 0) {
        // Grupo nuevo
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

    // --- Validar y parsear el día ---
    if (dia_valido(dia_str) != 1) {
        fprintf(stderr, "[WARN] Día inválido: '%s' (curso %s grupo %d)\n",
                dia_str, codigo, numero_grupo);
        return 0;
    }

    // --- Validar y parsear las horas ---
    int hi = hora_a_minutos(hora_inicio_str);
    int hf = hora_a_minutos(hora_fin_str);

    if (hi < 0 || hf < 0 || hf <= hi) {
        fprintf(stderr, "[WARN] Hora inválida: %s-%s (curso %s grupo %d)\n",
                hora_inicio_str, hora_fin_str, codigo, numero_grupo);
        return 0;
    }

    // --- Agregar el bloque horario al grupo ---
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

    // Buffer de lectura amplio para permitir comentarios largos.
    // Si se usara MAX_CODIGO + 16, los comentarios largos se cortarían
    // en pedazos y sus fragmentos se interpretarían como códigos válidos.
    char linea[256];
    int count = 0;

    while (fgets(linea, sizeof(linea), f) != NULL && count < max_cursos) {
        // Quitar \n y \r
        linea[strcspn(linea, "\r\n")] = '\0';

        // Quitar espacios al inicio
        char *inicio = linea;
        while (*inicio == ' ' || *inicio == '\t') inicio++;

        // Quitar espacios al final
        char *fin = inicio + strlen(inicio) - 1;
        while (fin > inicio && (*fin == ' ' || *fin == '\t')) {
            *fin = '\0';
            fin--;
        }

        // Ignorar líneas vacías
        if (strlen(inicio) == 0) continue;

        // Ignorar comentarios (líneas que empiezan con #)
        if (inicio[0] == '#') continue;

        // Guardar el código en el historial
        strncpy(historial[count], inicio, MAX_CODIGO - 1);
        historial[count][MAX_CODIGO - 1] = '\0';
        count++;
    }

    fclose(f);

    printf("[OK] %s: %d cursos aprobados en el historial\n",
           ruta_historial, count);

    return count;
}