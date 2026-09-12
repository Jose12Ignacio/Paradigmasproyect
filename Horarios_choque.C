#include <stdio.h>
#include <string.h>

int horas_minutos(int horas, int minutos){
return (60*horas)+ minutos;
}


int horarios_choque(const Horario *h1, const Horario *h2) {
    // Verificar si es un día distinto
    if (h1->dia != h2->dia) {
        return 0;
    }
    // Se verifica si las horas no chocan 
    if (h1->hora_inicio < h2->hora_fin && h2->hora_inicio < h1->hora_fin) {
        return 1;
    }
    
    return 0;
}

int grupo_choque(Grupo *Gr1, Grupo *Gr2){
for(int i=0; i < *Gr1->Totalhorarios; i++){
    for(int j=0; j< Gr2->Totalhorarios;){
        if (horarios_choque(&Gr1->horarios[i],&Gr2->horarios[j])){
            return 1;
        }
    }
}
return 0;
}