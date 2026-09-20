#include <stdio.h>
#include <stdlib.h>
#include "memoria.h"

Dia letra_a_dia(char letra) {
    switch (letra) {
        case 'L': return LUNES;
        case 'K': return MARTES;
        case 'M': return MIERCOLES;
        case 'J': return JUEVES;
        case 'V': return VIERNES;
        case 'S': return SABADO;
        default:
            fprintf(stderr, "Advertencia: letra de dia desconocida '%c', se asume LUNES\n", letra);
            return LUNES;
    }
}

Catalogo* crear_catalogo(int capacidad_inicial) {
    if (capacidad_inicial <= 0) {
        capacidad_inicial = 10; // valor por defecto razonable si mandan 0 o negativo
    }

    Catalogo *catalogo = malloc(sizeof(Catalogo));
    if (catalogo == NULL) {
        fprintf(stderr, "Error: no se pudo reservar memoria para el catalogo\n");
        return NULL;
    }

    catalogo->cursos = malloc(sizeof(Curso) * capacidad_inicial);
    if (catalogo->cursos == NULL) {
        fprintf(stderr, "Error: no se pudo reservar memoria para los cursos\n");
        free(catalogo); // importante: liberar lo que sí se alojó antes de salir
        return NULL;
    }

    catalogo->cantidad = 0;
    catalogo->capacidad = capacidad_inicial;
    return catalogo;
}

int agregar_curso(Catalogo *catalogo, Curso curso) {
    if (catalogo == NULL) {
        return 0;
    }

    // Si ya está lleno, duplicar la capacidad antes de agregar
    if (catalogo->cantidad == catalogo->capacidad) {
        int nueva_capacidad = catalogo->capacidad * 2;
        Curso *temp = realloc(catalogo->cursos, sizeof(Curso) * nueva_capacidad);

        if (temp == NULL) {
            fprintf(stderr, "Error: no se pudo ampliar el catalogo\n");
            return 0; // catalogo->cursos NO se toca si realloc falla, sigue valido
        }

        catalogo->cursos = temp;
        catalogo->capacidad = nueva_capacidad;
    }

    catalogo->cursos[catalogo->cantidad] = curso;
    catalogo->cantidad++;
    return 1;
}

void liberar_catalogo(Catalogo *catalogo) {
    if (catalogo == NULL) {
        return; // llamar con NULL no debe romper el programa
    }
    free(catalogo->cursos);
    free(catalogo);
}
