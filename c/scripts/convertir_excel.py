#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
convertir_excel.py
Script de conversión del Excel 'Plan de estudios CE y ATI.xlsx'
a los CSV de entrada para el programa en C del proyecto CEmestre.

Genera:
    - data/catalogo_CE.csv
    - data/catalogo_ATI.csv
    - reportes/reporte_limpieza.txt

Autor: Integrante 1 - Módulo I/O
"""

import openpyxl
import csv
import os
import re
from datetime import datetime

# ============================================================
# RUTAS (resueltas relativas al script, para funcionar desde cualquier CWD)
# ============================================================

BASE_DIR = os.path.dirname(os.path.abspath(__file__))       # .../c/scripts
PROYECTO_DIR = os.path.dirname(BASE_DIR)                    # .../c

ARCHIVO_EXCEL = os.path.join(PROYECTO_DIR, "Plan de estudios CE y ATI.xlsx")
DIR_DATA = os.path.join(PROYECTO_DIR, "data")
DIR_REPORTES = os.path.join(PROYECTO_DIR, "reportes")

# ============================================================
# CONSTANTES
# ============================================================

MAPA_DIAS = {
    "LUN": "L", "MAR": "K", "MIE": "M", "JUE": "J", "VIE": "V", "SAB": "S",
    "LUNES": "L", "MARTES": "K", "MIERCOLES": "M", "MIÉRCOLES": "M",
    "JUEVES": "J", "VIERNES": "V", "SABADO": "S", "SÁBADO": "S",
}

MAPA_AREAS = {
    "CE": "Computación",
    "TI": "Tecnologías de Información",
    "MA": "Matemática",
    "FI": "Física",
    "QU": "Química",
    "EL": "Electrónica",
    "CI": "Comunicación e Idiomas",
    "CS": "Ciencias Sociales",
    "SO": "Salud Ocupacional",
    "PI": "Producción Industrial",
    "AE": "Administración y Emprendimiento",
}

AREA_DEFAULT = "Otra"

CORRECCIONES_CODIGOS = {
    "F1 1101": "FI-1101",
    "F1-1101": "FI-1101",
    "TI 4501": "TI-4500",
    "TI-4501": "TI-4500",
    "TI4501": "TI-4500",
    "MA2404": "MA-2404",
    "MA2405": "MA-2404",
    "MA2406": "MA-2404",
    "MA2407": "MA-2404",
    "MA2408": "MA-2404",
    "MA2409": "MA-2404",
    "MA2106": "MA-2105",
    "MA-2106": "MA-2105",
}

CORRECCIONES_NOMBRES = {
    "Habilidades de comunicación en ingenieía": "Habilidades de Comunicación en Ingeniería",
    "Habilidades de comunicación en ingeniería": "Habilidades de Comunicación en Ingeniería",
    "Comuncación oral": "Comunicación Oral",
    "Comunicación oral": "Comunicación Oral",
    "Exámen diagnóstico": "Examen Diagnóstico",
    "Examen diagnóstico": "Examen Diagnóstico",
    "Modelos organizacionales y gestion de TI": "Modelos Organizacionales y Gestión de TI",
    "Modelos organizacionales y gestión de TI": "Modelos Organizacionales y Gestión de TI",
    "Circuitos eléctricos en corriente contínua": "Circuitos Eléctricos en Corriente Continua",
    "Circuitos eléctricos en corriente continua": "Circuitos Eléctricos en Corriente Continua",
    "Fundamentos de Arquitectura de Computadores": "Fundamentos de Arquitectura de Computadores",
    "Laboratorio física general 1": "Laboratorio de Física General 1",
    "Laboratorio física general 2": "Laboratorio de Física General 2",
    "Introducción a la técnica ciencia y tecnología": "Introducción a la Técnica, Ciencia y Tecnología",
    "Introducción a la técnica, ciencia y tecnología": "Introducción a la Técnica, Ciencia y Tecnología",
    "Formulación y evaluación de proyectos de ti": "Formulación y Evaluación de Proyectos de TI",
    "Adquisición de ti": "Adquisición de TI",
    "Auditoría de ti": "Auditoría de TI",
    "Administración de servicios de tecnologías de información i": "Administración de Servicios de Tecnologías de Información I",
}

CSV_HEADER = [
    "codigo", "nombre", "creditos", "semestre", "carrera",
    "requisitos", "correquisitos",
    "grupo", "profesor", "dia", "hora_inicio", "hora_fin",
    "area",
]

# ============================================================
# ESTADO GLOBAL
# ============================================================

reporte_lineas = []

def log(mensaje, nivel="INFO"):
    prefijo = {
        "INFO": "[INFO]",
        "WARN": "[WARN]",
        "ERROR": "[ERROR]",
        "OK": "[OK]",
    }.get(nivel, "[INFO]")
    linea = f"{prefijo} {mensaje}"
    reporte_lineas.append(linea)
    print(linea)

# ============================================================
# NORMALIZACIÓN
# ============================================================

def normalizar_codigo(codigo_raw):
    if codigo_raw is None:
        return None
    codigo = str(codigo_raw).strip()

    if codigo in CORRECCIONES_CODIGOS:
        log(f"Corrección de código: '{codigo}' -> '{CORRECCIONES_CODIGOS[codigo]}'", "WARN")
        return CORRECCIONES_CODIGOS[codigo]

    match = re.match(r"^([A-Z]{2})\s*-?\s*(\d{4})$", codigo.upper())
    if match:
        return f"{match.group(1)}-{match.group(2)}"

    log(f"Código no reconocido: '{codigo}'", "WARN")
    return codigo

def normalizar_dia(dia_raw):
    if dia_raw is None:
        return None
    dia = str(dia_raw).strip().upper()
    return MAPA_DIAS.get(dia)

def normalizar_hora(hora_raw):
    if hora_raw is None:
        return None
    hora = str(hora_raw).strip()
    match = re.match(r"^(\d{1,2}):(\d{2})$", hora)
    if match:
        hh = int(match.group(1))
        mm = int(match.group(2))
        if 0 <= hh <= 23 and 0 <= mm <= 59:
            return f"{hh:02d}:{mm:02d}"
    log(f"Hora no reconocida: '{hora}'", "WARN")
    return None

def normalizar_profesor(nombre_raw):
    if nombre_raw is None:
        return None
    nombre = str(nombre_raw).strip()
    if not nombre:
        return None
    return " ".join(p.capitalize() for p in nombre.split())

def normalizar_nombre_curso(nombre_raw):
    if nombre_raw is None:
        return None
    nombre = str(nombre_raw).strip()
    nombre = re.sub(r"\s*\(\s*\d+\s*\)\s*$", "", nombre).strip()
    if nombre in CORRECCIONES_NOMBRES:
        nombre = CORRECCIONES_NOMBRES[nombre]
    return nombre

def asignar_area(codigo):
    if codigo is None or "-" not in codigo:
        return AREA_DEFAULT
    prefijo = codigo.split("-")[0].upper()
    return MAPA_AREAS.get(prefijo, AREA_DEFAULT)

def separar_requisitos_y_correquisitos(texto):
    if texto is None:
        return [], []
    t = str(texto).strip()
    if not t or t == "-":
        return [], []

    reqs = []
    correqs = []
    partes = re.split(r"[,\n;]+|\s{2,}", t)
    for p in partes:
        p = p.strip()
        if not p or p == "-":
            continue
        es_correq = "(Correquisito)" in p or "(correquisito)" in p.lower()
        codigo_limpio = re.sub(r"\(Correquisito\)", "", p, flags=re.IGNORECASE).strip()
        if not codigo_limpio:
            continue
        codigo = normalizar_codigo(codigo_limpio)
        if codigo:
            if es_correq:
                if codigo not in correqs:
                    correqs.append(codigo)
            else:
                if codigo not in reqs:
                    reqs.append(codigo)
    return reqs, correqs

# ============================================================
# LECTURA DEL PLAN DE ESTUDIOS
# ============================================================

def leer_plan_estudios(wb, nombre_hoja, fila_inicio, carrera):
    ws = wb[nombre_hoja]
    cursos = {}

    for fila in ws.iter_rows(min_row=fila_inicio, values_only=True):
        for i in range(1, 19, 2):  # 1,3,...,17 -> Bloques 0 a 8
            celda_curso = fila[i] if i < len(fila) else None
            celda_reqs = fila[i + 1] if i + 1 < len(fila) else None

            if celda_curso is None:
                continue

            curso_txt = str(celda_curso).strip()
            if not curso_txt or curso_txt == "-":
                continue

            match = re.match(r"^(.+?)\s*-\s*(.+?)\s*\(\s*(\d+)\s*\)\s*$", curso_txt)
            if not match:
                log(f"No se pudo parsear curso: '{curso_txt}'", "WARN")
                continue

            codigo_raw = match.group(1).strip()
            nombre_raw = match.group(2).strip()
            creditos = int(match.group(3))

            codigo = normalizar_codigo(codigo_raw)
            nombre = normalizar_nombre_curso(nombre_raw)
            area = asignar_area(codigo)
            semestre = (i - 1) // 2

            reqs, correqs = separar_requisitos_y_correquisitos(celda_reqs)

            cursos[codigo] = {
                "codigo": codigo,
                "nombre": nombre,
                "creditos": creditos,
                "semestre": semestre,
                "carrera": carrera,
                "area": area,
                "requisitos": reqs,
                "correquisitos": correqs,
            }

    log(f"Hoja '{nombre_hoja}': {len(cursos)} cursos leídos", "OK")
    return cursos

# ============================================================
# LECTURA DE HORARIOS
# ============================================================

def parsear_horario_CE(texto):
    """Parsea 'MAR[07:30-09:20] JUE[07:30-09:20]'."""
    if texto is None:
        return []
    t = str(texto).strip()
    if not t:
        return []

    bloques = []
    matches = re.findall(r"([A-Z]+)\[(\d{1,2}:\d{2})-(\d{1,2}:\d{2})\]", t)
    for dia_raw, hi_raw, hf_raw in matches:
        dia = normalizar_dia(dia_raw)
        hi = normalizar_hora(hi_raw)
        hf = normalizar_hora(hf_raw)
        if dia and hi and hf:
            bloques.append((dia, hi, hf))
    return bloques

def parsear_horario_ATI(texto):
    """
    Parsea formatos ATI:
      - 'Lunes - 18:00 , 20:50'
      - 'Martes y Jueves - 9:30 , 11:20'  (día compuesto)
      - 'Miercoles - 15:00 18:50'         (sin coma)
      - 'Miercoles - 17:0:20:50'          (hora mal formada)
    """
    if texto is None:
        return []
    t = str(texto).strip()
    if not t:
        return []

    # Normalizar 'Miercoles - 17:0:20:50' -> 'Miercoles - 17:00 , 20:50'
    t = re.sub(r"(\d{1,2}):(\d):(\d{2}):(\d{2})", r"\1:0\2 , \3:\4", t)
    # Normalizar 'Miercoles - 15:00 18:50' -> 'Miercoles - 15:00 , 18:50'
    t = re.sub(r"(\d{1,2}:\d{2})\s+(\d{1,2}:\d{2})", r"\1 , \2", t)

    # Caso 1: día simple 'Lunes - 18:00 , 20:50'
    match = re.match(
        r"^([A-Za-zÁÉÍÓÚáéíóúñÑ]+)\s*-\s*(\d{1,2}:\d{2})\s*,\s*(\d{1,2}:\d{2})$",
        t
    )
    if match:
        dia_raw, hi_raw, hf_raw = match.groups()
        dia = normalizar_dia(dia_raw)
        hi = normalizar_hora(hi_raw)
        hf = normalizar_hora(hf_raw)
        if dia and hi and hf:
            return [(dia, hi, hf)]

    # Caso 2: día compuesto 'Martes y Jueves - 9:30 , 11:20'
    match = re.match(
        r"^([A-Za-zÁÉÍÓÚáéíóúñÑ]+)\s+y\s+([A-Za-zÁÉÍÓÚáéíóúñÑ]+)\s*-\s*(\d{1,2}:\d{2})\s*,\s*(\d{1,2}:\d{2})$",
        t
    )
    if match:
        dia1_raw, dia2_raw, hi_raw, hf_raw = match.groups()
        dia1 = normalizar_dia(dia1_raw)
        dia2 = normalizar_dia(dia2_raw)
        hi = normalizar_hora(hi_raw)
        hf = normalizar_hora(hf_raw)
        if dia1 and dia2 and hi and hf:
            return [(dia1, hi, hf), (dia2, hi, hf)]

    return []

def leer_horarios(wb, nombre_hoja, fila_inicio, es_CE):
    ws = wb[nombre_hoja]
    cursos = {}

    for fila in ws.iter_rows(min_row=fila_inicio, values_only=True):
        codigo_raw = fila[1] if len(fila) > 1 else None
        nombre_raw = fila[2] if len(fila) > 2 else None
        grupo_raw = fila[3] if len(fila) > 3 else None
        horario_raw = fila[4] if len(fila) > 4 else None
        profesor_raw = fila[6] if len(fila) > 6 else None

        if codigo_raw is None or grupo_raw is None:
            continue

        codigo = normalizar_codigo(codigo_raw)
        nombre = normalizar_nombre_curso(nombre_raw)
        try:
            grupo = int(grupo_raw)
        except (ValueError, TypeError):
            log(f"Grupo no numérico: '{grupo_raw}' en {codigo}", "WARN")
            continue

        profesor = normalizar_profesor(profesor_raw)

        # Parsear horario: probar ambos formatos (fallback cruzado)
        if es_CE:
            bloques = parsear_horario_CE(horario_raw)
            if not bloques:
                bloques = parsear_horario_ATI(horario_raw)
        else:
            bloques = parsear_horario_ATI(horario_raw)
            if not bloques:
                bloques = parsear_horario_CE(horario_raw)

        if not bloques:
            log(f"Sin bloques horarios válidos: {codigo} grupo {grupo} -> {horario_raw!r}", "WARN")
            continue

        if codigo not in cursos:
            cursos[codigo] = {"nombre": nombre, "grupos": {}}

        if grupo in cursos[codigo]["grupos"]:
            gdata = cursos[codigo]["grupos"][grupo]
            for b in bloques:
                if b not in gdata["horarios"]:
                    gdata["horarios"].append(b)
            if not gdata["profesor"] and profesor:
                gdata["profesor"] = profesor
        else:
            cursos[codigo]["grupos"][grupo] = {
                "profesor": profesor,
                "horarios": list(bloques),
            }

    log(f"Hoja '{nombre_hoja}': {len(cursos)} cursos con horarios leídos", "OK")
    return cursos

# ============================================================
# RECONCILIACIÓN DE CÓDIGOS
# ============================================================

def reconciliar_codigos(plan, horarios, carrera):
    nombre_a_codigos = {}
    for cod, info in plan.items():
        nombre_norm = info["nombre"].strip().lower()
        nombre_a_codigos.setdefault(nombre_norm, []).append(cod)

    codigo_sin_guion = {cod.replace("-", "").upper(): cod for cod in plan.keys()}

    horarios_reconciliados = {}
    descartados = []
    reconciliados = []

    for cod_grupo, info_grupo in horarios.items():
        cod_final = None
        razon = None

        if cod_grupo in plan:
            cod_final = cod_grupo
        elif cod_grupo.replace("-", "").upper() in codigo_sin_guion:
            cod_final = codigo_sin_guion[cod_grupo.replace("-", "").upper()]
            razon = "match por código sin guion"
        else:
            nombre_norm = (info_grupo["nombre"] or "").strip().lower()
            candidatos = nombre_a_codigos.get(nombre_norm, [])
            if len(candidatos) == 1:
                cod_final = candidatos[0]
                razon = f"match por nombre '{info_grupo['nombre']}'"
            elif len(candidatos) > 1:
                log(f"[{carrera}] Ambigüedad: código '{cod_grupo}' con nombre "
                    f"'{info_grupo['nombre']}' coincide con {candidatos}. Se descarta.", "WARN")
                descartados.append((cod_grupo, info_grupo["nombre"], "ambiguo por nombre"))
                continue

        if cod_final is None:
            log(f"[{carrera}] Código '{cod_grupo}' (nombre '{info_grupo['nombre']}') "
                f"no está en el plan y no se pudo reconciliar. Se DESCARTA.", "WARN")
            descartados.append((cod_grupo, info_grupo["nombre"], "sin match"))
            continue

        if cod_final != cod_grupo:
            log(f"[{carrera}] Reconciliado: '{cod_grupo}' -> '{cod_final}' ({razon})", "WARN")
            reconciliados.append((cod_grupo, cod_final, razon))

        if cod_final in horarios_reconciliados:
            for num, gdata in info_grupo["grupos"].items():
                if num in horarios_reconciliados[cod_final]:
                    for b in gdata["horarios"]:
                        if b not in horarios_reconciliados[cod_final][num]["horarios"]:
                            horarios_reconciliados[cod_final][num]["horarios"].append(b)
                else:
                    horarios_reconciliados[cod_final][num] = gdata
        else:
            horarios_reconciliados[cod_final] = info_grupo["grupos"]

    log(f"[{carrera}] Reconciliación: {len(reconciliados)} mapeados, "
        f"{len(descartados)} descartados", "INFO")
    return horarios_reconciliados, reconciliados, descartados

# ============================================================
# ESCRITURA DEL CSV
# ============================================================

def escribir_csv(ruta, plan, horarios, cursos_sin_horario=None):
    cursos_sin_horario = cursos_sin_horario or set()
    filas = []

    for codigo, info in plan.items():
        if codigo in horarios:
            grupos = horarios[codigo]
            for num_grupo in sorted(grupos.keys()):
                gdata = grupos[num_grupo]
                for dia, hi, hf in gdata["horarios"]:
                    filas.append([
                        info["codigo"], info["nombre"], info["creditos"],
                        info["semestre"], info["carrera"],
                        ";".join(info["requisitos"]),
                        ";".join(info["correquisitos"]),
                        num_grupo, gdata["profesor"] or "",
                        dia, hi, hf,
                        info["area"],
                    ])
        else:
            filas.append([
                info["codigo"], info["nombre"], info["creditos"],
                info["semestre"], info["carrera"],
                ";".join(info["requisitos"]),
                ";".join(info["correquisitos"]),
                "", "", "", "", "",
                info["area"],
            ])

    filas.sort(key=lambda f: (f[0], str(f[7]), str(f[9])))

    with open(ruta, "w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(CSV_HEADER)
        writer.writerows(filas)

    log(f"CSV escrito: {ruta} ({len(filas)} filas)", "OK")
    return len(filas)

# ============================================================
# MAIN
# ============================================================

def main():
    log("=" * 60)
    log("CONVERSIÓN EXCEL -> CSV", "INFO")
    log(f"Fecha: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    log(f"Excel: {ARCHIVO_EXCEL}")
    log("=" * 60)

    os.makedirs(DIR_DATA, exist_ok=True)
    os.makedirs(DIR_REPORTES, exist_ok=True)

    log(f"Cargando {ARCHIVO_EXCEL}...")
    wb = openpyxl.load_workbook(ARCHIVO_EXCEL)

    # ============ CE ============
    log("\n--- PROCESANDO CE ---")
    plan_CE = leer_plan_estudios(wb, "CE", fila_inicio=4, carrera="CE")
    horarios_CE_raw = leer_horarios(wb, "Grupos CE", fila_inicio=2, es_CE=True)
    horarios_CE, reconc_CE, descart_CE = reconciliar_codigos(plan_CE, horarios_CE_raw, "CE")

    sin_horario_CE = set(plan_CE.keys()) - set(horarios_CE.keys())
    if sin_horario_CE:
        log(f"Cursos del plan sin horario en CE: {sorted(sin_horario_CE)}", "WARN")

    escribir_csv(
        os.path.join(DIR_DATA, "catalogo_CE.csv"),
        plan_CE, horarios_CE, cursos_sin_horario=sin_horario_CE,
    )

    # ============ ATI ============
    log("\n--- PROCESANDO ATI ---")
    plan_ATI = leer_plan_estudios(wb, "ATI", fila_inicio=3, carrera="ATI")
    horarios_ATI_raw = leer_horarios(wb, "Grupos ATI", fila_inicio=3, es_CE=False)
    horarios_ATI, reconc_ATI, descart_ATI = reconciliar_codigos(plan_ATI, horarios_ATI_raw, "ATI")

    sin_horario_ATI = set(plan_ATI.keys()) - set(horarios_ATI.keys())
    if sin_horario_ATI:
        log(f"Cursos del plan sin horario en ATI: {sorted(sin_horario_ATI)}", "WARN")

    escribir_csv(
        os.path.join(DIR_DATA, "catalogo_ATI.csv"),
        plan_ATI, horarios_ATI, cursos_sin_horario=sin_horario_ATI,
    )

    # ============ RESUMEN ============
    log("\n" + "=" * 60)
    log("RESUMEN", "INFO")
    log(f"CE  - Cursos plan: {len(plan_CE)}, con horario: {len(horarios_CE)}")
    log(f"ATI - Cursos plan: {len(plan_ATI)}, con horario: {len(horarios_ATI)}")
    log("=" * 60)

    ruta_reporte = os.path.join(DIR_REPORTES, "reporte_limpieza.txt")
    with open(ruta_reporte, "w", encoding="utf-8") as f:
        f.write("\n".join(reporte_lineas))
    log(f"Reporte guardado: {ruta_reporte}", "OK")

if __name__ == "__main__":
    main()