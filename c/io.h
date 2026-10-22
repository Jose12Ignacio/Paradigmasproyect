#ifndef IO_H
#define IO_H

#include "models.h"

/*
 * ============================================================
 *  io.h - Módulo de entrada/salida del catálogo
 * ============================================================
 *
 *  Responsabilidades:
 *    - Leer el CSV del catálogo de cursos (uno por carrera)
 *    - Leer el archivo de historial del estudiante
 *
 *  El CSV se genera con scripts/convertir_excel.py a partir
 *  del Excel institucional. Cada fila representa UN bloque
 *  horario de un grupo. El parser consolida filas del mismo
 *  curso y del mismo grupo.
 * ============================================================
 */

/**
 * Carga el catálogo de cursos desde un archivo CSV.
 *
 * @param ruta_csv        Ruta al archivo CSV (ej. "data/catalogo_CE.csv")
 * @param catalogo        Catalogo ya creado con crear_catalogo() donde se
 *                        van a agregar los cursos. NO se libera aquí.
 *
 * @return 1 si tuvo éxito, 0 si falló (archivo no existe, formato inválido,
 *         error de memoria).
 *
 * Nota: el catálogo debe haberse creado antes con crear_catalogo().
 *       Esta función usa agregar_curso() para añadir los cursos.
 */
int cargar_catalogo_csv(const char *ruta_csv, Catalogo *catalogo);

/**
 * Carga el historial del estudiante desde un archivo de texto.
 *
 * Formato: un código de curso por línea (ej. "CE-1101"). Líneas vacías
 * y espacios se ignoran. Las líneas que empiecen con '#' se tratan
 * como comentarios.
 *
 * @param ruta_historial  Ruta al archivo (ej. "data/historial.txt")
 * @param historial       Arreglo de strings donde se guardan los códigos.
 * @param max_cursos      Tamaño máximo del arreglo (MAX_CURSOS_HISTORIAL)
 *
 * @return Cantidad de cursos leídos (>=0), o -1 si falló la apertura.
 */
int cargar_historial(const char *ruta_historial,
                     char historial[][MAX_CODIGO],
                     int max_cursos);

#endif // IO_H