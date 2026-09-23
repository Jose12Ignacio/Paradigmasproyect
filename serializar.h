#ifndef SERIALIZAR_H
#define SERIALIZAR_H

#include "models.h"

/*
 * ============================================================
 *  serializar.h - Exportador del catálogo en formato JSON
 * ============================================================
 *
 *  Este módulo escribe el catálogo enriquecido (con flags de choque
 *  y elegibilidad) en formato JSON. El archivo generado es el
 *  CONTRATO DE DATOS que consume la Etapa 2 del proyecto (Racket).
 *
 *  El esquema JSON está documentado en el README, sección 2.4.2.
 * ============================================================
 */

/**
 * Exporta el catálogo completo a un archivo JSON.
 *
 * @param ruta_salida      Ruta del archivo JSON a generar
 *                         (ej. "output/catalogo_CE.json")
 * @param catalogo         Catálogo con los cursos ya cargados y evaluados
 *                         (tiene_choque y es_elegible deben estar seteados)
 * @param carrera          Nombre completo de la carrera
 *                         (ej. "Ingeniería en Computadores")
 * @param siglas           Siglas de la carrera (ej. "CE", "ATI")
 * @param historial        Arreglo de códigos aprobados por el estudiante
 * @param total_historial  Cantidad de cursos aprobados
 *
 * @return 1 si tuvo éxito, 0 si falló (no se pudo abrir el archivo,
 *         argumento NULL).
 */
int exportar_json(const char *ruta_salida,
                  const Catalogo *catalogo,
                  const char *carrera,
                  const char *siglas,
                  char historial[][MAX_CODIGO],
                  int total_historial);

#endif // SERIALIZAR_H