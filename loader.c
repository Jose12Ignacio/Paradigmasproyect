#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "loader.h"
#include "memoria.h"

// Función auxiliar para buscar un curso existente en el catálogo por su código
static Curso* buscar_curso(Catalogo *catalogo, const char *codigo) {
    for (int i = 0; i < catalogo->cantidad; i++) {
        if (strcmp(catalogo->cursos[i].codigo, codigo) == 0) {
            return &catalogo->cursos[i];
        }
    }
    return NULL;
}

// Convierte cadenas separadas por comas/puntos y comas en un arreglo de cadenas (para reqs/correqs)
static int parsear_lista_codigos(char *cadena, char destino[][MAX_CODIGO], int max_limite) {
    if (cadena == NULL || strlen(cadena) == 0 || strcmp(cadena, "NINGUNO") == 0) {
        return 0;
    }
    int contador = 0;
    char *token = strtok(cadena, ";|");
    while (token != NULL && contador < max_limite) {
        // Limpiar espacios en blanco al inicio o fin
        while (*token == ' ') token++;
        strncpy(destino[contador], token, MAX_CODIGO - 1);
        destino[contador][MAX_CODIGO - 1] = '\0';
        contador++;
        token = strtok(NULL, ";|");
    }
    return contador;
}

int cargar_catalogo_csv(const char *nombre_archivo, Catalogo *catalogo) {
    FILE *archivo = fopen(nombre_archivo, "r");
    if (archivo == NULL) {
        fprintf(stderr, "Error: no se pudo abrir el archivo %s\n", nombre_archivo);
        return 0;
    }

    char linea[512];
    // Omitir la linea de encabezado del CSV
    if (fgets(linea, sizeof(linea), archivo) == NULL) {
        fclose(archivo);
        return 0;
    }

    /* Formato esperado del CSV por fila:
       codigo,nombre,creditos,semestre,num_grupo,profesor,dia_letra,hora_inicio,hora_fin,requisitos,correquisitos */
    while (fgets(linea, sizeof(linea), archivo)) {
        // Eliminar salto de linea al final
        linea[strcspn(linea, "\r\n")] = 0;
        char codigo[MAX_CODIGO], nombre[MAX_NOMBRE], profesor[MAX_PROFESOR];
        char req_str[100] = "", correq_str[100] = "";
        char dia_letra;
        int creditos, semestre, num_grupo, h_ini, h_fin;

        // Lectura de campos mediante sscanf con separador comas
        int leidos = sscanf(linea, "%[^,],%[^,],%d,%d,%d,%[^,],%c,%d,%d,%[^,],%s",
                            codigo, nombre, &creditos, &semestre,
                            &num_grupo, profesor, &dia_letra, &h_ini, &h_fin,
                            req_str, correq_str);

        if (leidos < 9) continue; // Fila incompleta o inválida
        // Buscar si el curso ya fue registrado previamente en el catálogo
        Curso *curso = buscar_curso(catalogo, codigo);
        if (curso == NULL) {
            Curso nuevo_curso;
            memset(&nuevo_curso, 0, sizeof(Curso));
            strncpy(nuevo_curso.codigo, codigo, MAX_CODIGO - 1);
            strncpy(nuevo_curso.nombre, nombre, MAX_NOMBRE - 1);
            nuevo_curso.creditos = creditos;
            nuevo_curso.semestre = semestre;

            // Parsear requisitos y correquisitos
            nuevo_curso.total_requisitos = parsear_lista_codigos(req_str, nuevo_curso.requisitos, MAX_REQUISITOS);
            nuevo_curso.total_correquisitos = parsear_lista_codigos(correq_str, nuevo_curso.correquisitos, MAX_CORREQUISITOS);

            agregar_curso(catalogo, nuevo_curso);
            curso = &catalogo->cursos[catalogo->cantidad - 1];
        }
        // Buscar o agregar el grupo correspondiente al curso
        Grupo *grupo = NULL;
        for (int g = 0; g < curso->total_grupos; g++) {
            if (curso->grupos[g].numero_grupo == num_grupo) {
                grupo = &curso->grupos[g];
                break;
            }
        }
        if (grupo == NULL && curso->total_grupos < MAX_GRUPOS_POR_CURSO) {
            grupo = &curso->grupos[curso->total_grupos];
            grupo->numero_grupo = num_grupo;
            strncpy(grupo->profesor, profesor, MAX_PROFESOR - 1);
            grupo->Totalhorarios = 0;
            curso->total_grupos++;
        }
        // Agregar el bloque de horario al grupo si aún hay espacio
        if (grupo != NULL && grupo->Totalhorarios < MAX_BLOQUES_POR_GRUPO) {
            Horario *h = &grupo->horarios[grupo->Totalhorarios];
            h->dia = letra_a_dia(dia_letra);
            h->hora_inicio = h_ini;
            h->hora_fin = h_fin;
            grupo->Totalhorarios++;
        }
    }

    fclose(archivo);
    return 1;
}

int cargar_historial_txt(const char *nombre_archivo, char historial[][MAX_CODIGO], int *total_aprobados) {
    FILE *archivo = fopen(nombre_archivo, "r");
    if (archivo == NULL) {
        fprintf(stderr, "Advertencia: no se pudo abrir el historial %s. Se asume historial vacio.\n", nombre_archivo);
        *total_aprobados = 0;
        return 0;
    }

    char codigo[MAX_CODIGO];
    *total_aprobados = 0;

    while (fscanf(archivo, "%9s", codigo) == 1 && *total_aprobados < MAX_CURSOS_HISTORIAL) {
        strncpy(historial[*total_aprobados], codigo, MAX_CODIGO - 1);
        historial[*total_aprobados][MAX_CODIGO - 1] = '\0';
        (*total_aprobados)++;
    }

    fclose(archivo);
    return 1;
}