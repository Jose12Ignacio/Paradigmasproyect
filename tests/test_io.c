#include <stdio.h>
#include "io.h"
#include "memoria.h"
#include "Logic.h"
#include "serializar.h"

int main(void) {
    Catalogo *cat = crear_catalogo(10);
    if (!cat) return 1;

    // ============================================================
    // 1. Cargar catálogo desde CSV
    // ============================================================
    if (!cargar_catalogo_csv("data/catalogo_CE.csv", cat)) {
        liberar_catalogo(cat);
        return 1;
    }

    // ============================================================
    // 2. Cargar historial del estudiante
    // ============================================================
    char historial[MAX_CURSOS_HISTORIAL][MAX_CODIGO];
    int total_hist = cargar_historial("data/historial.txt",
                                       historial,
                                       MAX_CURSOS_HISTORIAL);
    if (total_hist < 0) {
        liberar_catalogo(cat);
        return 1;
    }

    // ============================================================
    // 3. Imprimir primeros 3 cursos con sus grupos (debug)
    // ============================================================
    printf("\n--- Muestra de cursos cargados ---\n");
    for (int i = 0; i < 3 && i < cat->cantidad; i++) {
        Curso *c = &cat->cursos[i];
        printf("\n%s - %s (%d cr, sem %d)\n",
               c->codigo, c->nombre, c->creditos, c->semestre);
        printf("  Requisitos: %d\n", c->total_requisitos);
        printf("  Correquisitos: %d\n", c->total_correquisitos);
        printf("  Grupos: %d\n", c->total_grupos);
        for (int g = 0; g < c->total_grupos; g++) {
            Grupo *gr = &c->grupos[g];
            printf("    Grupo %d (%s): %d bloques\n",
                   gr->numero_grupo, gr->profesor, gr->Totalhorarios);
        }
    }

    // ============================================================
    // 4. Detectar choques de horario en todo el catálogo
    // ============================================================
    printf("\n--- Detectando choques de horario ---\n");
    detectar_choques_catalogo(cat->cursos, cat->cantidad);

    int cursos_con_choque = 0;
    for (int i = 0; i < cat->cantidad; i++) {
        if (cat->cursos[i].tiene_choque) cursos_con_choque++;
    }
    printf("[OK] %d cursos con choque de horario detectados\n", cursos_con_choque);

    // ============================================================
    // 5. Evaluar elegibilidad de cada curso
    // ============================================================
    printf("\n--- Evaluando elegibilidad ---\n");
    for (int i = 0; i < cat->cantidad; i++) {
        evaluar_elegibilidad_curso(&cat->cursos[i], historial, total_hist);
    }

    int elegibles = 0;
    for (int i = 0; i < cat->cantidad; i++) {
        if (cat->cursos[i].es_elegible) elegibles++;
    }
    printf("[OK] %d cursos matriculables de %d\n", elegibles, cat->cantidad);

    // ============================================================
    // 6. Exportar a JSON
    // ============================================================
    printf("\n--- Exportando JSON ---\n");
    if (!exportar_json("output/catalogo_CE.json",
                       cat,
                       "Ingeniería en Computadores",
                       "CE",
                       historial,
                       total_hist)) {
        liberar_catalogo(cat);
        return 1;
    }

    // ============================================================
    // 7. Liberar memoria
    // ============================================================
    liberar_catalogo(cat);
    printf("\n[OK] Test completado correctamente\n");
    return 0;
}