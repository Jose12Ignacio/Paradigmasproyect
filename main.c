#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "constants.h"
#include "models.h"
#include "memoria.h"
#include "Logic.h"
#include "io.h"
#include "serializar.h"
int main(int argc, char *argv[]) {
// Definición de rutas por defecto
const char *ruta_csv = "catalogo_CE.csv";
const char *ruta_historial = "historial.txt";
const char *ruta_salida = "catalogo_CE.json";
const char *carrera = "Ingeniería en Computadores";
const char *siglas = "CE";
// Permitir pasar parámetros opcionales por línea de comandos:
// ./programa [ruta_csv] [ruta_historial] [ruta_salida]
if (argc > 1) ruta_csv = argv[1];
if (argc > 2) ruta_historial = argv[2];
if (argc > 3) ruta_salida = argv[3];

printf("==================================================\n");
printf("         PLANIFICADOR ACADÉMICO - ETAPA 1         \n");
printf("==================================================\n\n");

// 1. Crear el catálogo dinámico
Catalogo *catalogo = crear_catalogo(10);
if (catalogo == NULL) {
    fprintf(stderr, "[ERROR CRÍTICO] No se pudo inicializar la memoria del catálogo.\n");
    return EXIT_FAILURE;
}

// 2. Cargar historial de materias aprobadas por el estudiante
char historial[MAX_CURSOS_HISTORIAL][MAX_CODIGO];
int total_aprobados = cargar_historial(ruta_historial, historial, MAX_CURSOS_HISTORIAL);

if (total_aprobados < 0) {
    printf("[WARN] No se pudo leer '%s'. Se procederá con historial vacío.\n", ruta_historial);
    total_aprobados = 0;
} else {
    printf("[INFO] Historial cargado con éxito. Cursos aprobados: %d\n", total_aprobados);
    if (total_aprobados > 0) {
        printf("       Cursos: ");
        for (int i = 0; i < total_aprobados; i++) {
            printf("%s%s", historial[i], (i < total_aprobados - 1) ? ", " : "\n");
        }
    }
}
printf("\n");

// 3. Cargar catálogo desde CSV
printf("[INFO] Cargando catálogo desde '%s'...\n", ruta_csv);
if (!cargar_catalogo_csv(ruta_csv, catalogo)) {
    fprintf(stderr, "[ERROR] Falló la carga del archivo CSV '%s'.\n", ruta_csv);
    liberar_catalogo(catalogo);
    return EXIT_FAILURE;
}
printf("\n");

// 4. Ejecutar lógica de procesamiento
printf("--------------------------------------------------\n");
printf("Ejecutando procesamiento de lógica académica...\n");
printf("--------------------------------------------------\n");

// a) Detectar choques de horario en el catálogo
detectar_choques_catalogo(catalogo->cursos, catalogo->cantidad);

// b) Evaluar la elegibilidad académica de cada curso
int total_elegibles = 0;
int total_con_choque = 0;

for (int i = 0; i < catalogo->cantidad; i++) {
    evaluar_elegibilidad_curso(&catalogo->cursos[i], historial, total_aprobados);

    if (catalogo->cursos[i].es_elegible) {
        total_elegibles++;
    }
    if (catalogo->cursos[i].tiene_choque) {
        total_con_choque++;
    }
}

// 5. Mostrar reporte impreso en consola
printf("\n==================================================\n");
printf("                RESUMEN DE RESULTADOS             \n");
printf("==================================================\n");
printf(" Total de cursos cargados : %d\n", catalogo->cantidad);
printf(" Cursos elegibles         : %d\n", total_elegibles);
printf(" Cursos con choque horario: %d\n", total_con_choque);
printf("--------------------------------------------------\n\n");

printf("DETALLE DE CURSOS EVALUADOS:\n");
for (int i = 0; i < catalogo->cantidad; i++) {
    Curso *c = &catalogo->cursos[i];
    printf("[%s] %-35s | Elegible: %-2s | Choque: %-2s | Grupos: %d\n",
           c->codigo,
           c->nombre,
           c->es_elegible ? "SÍ" : "NO",
           c->tiene_choque ? "SÍ" : "NO",
           c->total_grupos);

    if (!c->es_elegible && strlen(c->razon_no_matriculable) > 0) {
        printf("    └── Motivo: %s\n", c->razon_no_matriculable);
    }
    if (c->tiene_choque && c->total_choques > 0) {
        printf("    └── Choca con: ");
        for (int k = 0; k < c->total_choques; k++) {
            printf("%s%s", c->cursos_con_choque[k], (k < c->total_choques - 1) ? ", " : "");
        }
        printf("\n");
    }
}
printf("\n");

// 6. Exportar resultado final a JSON
printf("--------------------------------------------------\n");
printf("Exportando catálogo procesado a JSON...\n");
printf("--------------------------------------------------\n");
if (exportar_json(ruta_salida, catalogo, carrera, siglas, historial, total_aprobados)) {
    printf("[ÉXITO] Archivo '%s' generado correctamente.\n", ruta_salida);
} else {
    fprintf(stderr, "[ERROR] No se pudo exportar el archivo JSON.\n");
}

// 7. Liberar memoria
liberar_catalogo(catalogo);
printf("\nMemoria liberada correctamente. Proceso finalizado.\n");

return EXIT_SUCCESS;


}
