#include <stdio.h>
#include "io.h"
#include "memoria.h"
#include "Logic.h"
#include "serializar.h"

/*
 * ============================================================
 *  test_io.c - Prueba end-to-end del módulo I/O
 * ============================================================
 *
 *  Este programa:
 *    1. Carga el catálogo de CE y de ATI desde sus CSV
 *    2. Carga el historial de cada carrera
 *    3. Detecta choques de horario en ambos catálogos
 *    4. Evalúa la elegibilidad de cada curso para cada historial
 *    5. Exporta cada catálogo enriquecido a JSON
 *
 *  El resultado final son dos archivos:
 *    - output/catalogo_CE.json
 *    - output/catalogo_ATI.json
 * ============================================================
 */

/**
 * Procesa una carrera completa: carga catálogo, historial,
 * detecta choques, evalúa elegibilidad y exporta JSON.
 *
 * @param nombre_csv    Ruta del CSV del catálogo
 * @param nombre_hist   Ruta del archivo de historial
 * @param ruta_salida   Ruta del JSON de salida
 * @param nombre_carrera Nombre completo de la carrera
 * @param siglas        Siglas (CE o ATI)
 *
 * @return 1 si todo salió bien, 0 si algo falló
 */
static int procesar_carrera(const char *nombre_csv,
                             const char *nombre_hist,
                             const char *ruta_salida,
                             const char *nombre_carrera,
                             const char *siglas) {
    printf("\n");
    printf("============================================================\n");
    printf("  Procesando carrera: %s (%s)\n", nombre_carrera, siglas);
    printf("============================================================\n");

    // 1. Crear catálogo
    Catalogo *cat = crear_catalogo(10);
    if (cat == NULL) {
        fprintf(stderr, "[ERROR] No se pudo crear el catálogo\n");
        return 0;
    }

    // 2. Cargar catálogo desde CSV
    if (!cargar_catalogo_csv(nombre_csv, cat)) {
        liberar_catalogo(cat);
        return 0;
    }

    // 3. Cargar historial
    char historial[MAX_CURSOS_HISTORIAL][MAX_CODIGO];
    int total_hist = cargar_historial(nombre_hist,
                                       historial,
                                       MAX_CURSOS_HISTORIAL);
    if (total_hist < 0) {
        liberar_catalogo(cat);
        return 0;
    }

    // 4. Detectar choques
    printf("\n--- Detectando choques de horario ---\n");
    detectar_choques_catalogo(cat->cursos, cat->cantidad);

    int cursos_con_choque = 0;
    for (int i = 0; i < cat->cantidad; i++) {
        if (cat->cursos[i].tiene_choque) cursos_con_choque++;
    }
    printf("[OK] %d cursos con choque de horario detectados\n", cursos_con_choque);

    // 5. Evaluar elegibilidad
    printf("\n--- Evaluando elegibilidad ---\n");
    for (int i = 0; i < cat->cantidad; i++) {
        evaluar_elegibilidad_curso(&cat->cursos[i], historial, total_hist);
    }

    int elegibles = 0;
    for (int i = 0; i < cat->cantidad; i++) {
        if (cat->cursos[i].es_elegible) elegibles++;
    }
    printf("[OK] %d cursos matriculables de %d\n", elegibles, cat->cantidad);

    // 6. Exportar JSON
    printf("\n--- Exportando JSON ---\n");
    if (!exportar_json(ruta_salida,
                       cat,
                       nombre_carrera,
                       siglas,
                       historial,
                       total_hist)) {
        liberar_catalogo(cat);
        return 0;
    }

    // 7. Liberar
    liberar_catalogo(cat);
    return 1;
}

int main(void) {
    printf("============================================================\n");
    printf("  TEST END-TO-END DEL MODULO I/O\n");
    printf("============================================================\n");

    int ok_CE = procesar_carrera(
        "data/catalogo_CE.csv",
        "data/historial_CE.txt",
        "output/catalogo_CE.json",
        "Ingeniería en Computadores",
        "CE"
    );

    int ok_ATI = procesar_carrera(
        "data/catalogo_ATI.csv",
        "data/historial_ATI.txt",
        "output/catalogo_ATI.json",
        "Administración de Tecnologías de Información",
        "ATI"
    );

    printf("\n");
    printf("============================================================\n");
    printf("  RESUMEN FINAL\n");
    printf("============================================================\n");
    printf("  CE  : %s\n", ok_CE ? "OK" : "FALLO");
    printf("  ATI : %s\n", ok_ATI ? "OK" : "FALLO");
    printf("============================================================\n");

    if (!ok_CE || !ok_ATI) {
        return 1;
    }

    printf("\n[OK] Test completado correctamente\n");
    return 0;
}