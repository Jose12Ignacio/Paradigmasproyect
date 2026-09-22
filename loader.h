#ifndef LOADER_H
#define LOADER_H

#include "models.h"

// Carga los cursos y sus grupos desde un archivo CSV.
// Devuelve 1 si la carga fue exitosa, 0 si hubo error de apertura.
int cargar_catalogo_csv(const char *nombre_archivo, Catalogo *catalogo);

// Carga la lista de códigos de cursos aprobados por el estudiante.
// Devuelve 1 si tuvo éxito, 0 si fallo la apertura.
int cargar_historial_txt(const char *nombre_archivo, char historial[][MAX_CODIGO], int *total_aprobados);

#endif // LOADER_H