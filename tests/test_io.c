#include <stdio.h>
#include "io.h"
#include "memoria.h"

int main(void) {
    Catalogo *cat = crear_catalogo(10);
    if (!cat) return 1;

    if (!cargar_catalogo_csv("data/catalogo_CE.csv", cat)) {
        liberar_catalogo(cat);
        return 1;
    }

    // Imprimir primeros 3 cursos con sus grupos
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

    // Probar historial
    char historial[MAX_CURSOS_HISTORIAL][MAX_CODIGO];
    int total = cargar_historial("data/historial.txt", historial, MAX_CURSOS_HISTORIAL);
    printf("\nHistorial: %d cursos\n", total);
    for (int i = 0; i < total; i++) {
        printf("  %s\n", historial[i]);
    }

    liberar_catalogo(cat);
    return 0;
}