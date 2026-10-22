#ifndef LOGIC_H
#define LOGIC_H
#include "models.h"

int horas_minutos(int horas, int minutos);
int horarios_choque(const Horario *h1, const Horario *h2);
int grupo_choque(const Grupo *Gr1, const Grupo *Gr2);
int cursos_chocan(const Curso *c1, const Curso *c2);
void detectar_choques_catalogo(Curso catalogo[], int total_cursos);
void evaluar_elegibilidad_curso(Curso *curso, char historial[][MAX_CODIGO], int total_aprobados);

#endif