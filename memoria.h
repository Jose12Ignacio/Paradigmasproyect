#ifndef MEMORIA_H
#define MEMORIA_H

#include "models.h"

// Reserva un catálogo con espacio inicial para 'capacidad_inicial' cursos.
// Devuelve NULL si falla la reserva de memoria.
Catalogo* crear_catalogo(int capacidad_inicial);

// Agrega un curso al catálogo. Si ya no hay espacio, duplica la capacidad
// automáticamente (realloc). Devuelve 1 si tuvo éxito, 0 si falló.
int agregar_curso(Catalogo *catalogo, Curso curso);

// Libera toda la memoria reservada por el catálogo (el arreglo de cursos
// y el catálogo mismo). Seguro de llamar con catalogo == NULL.
void liberar_catalogo(Catalogo *catalogo);

#endif // MEMORIA_H
