"""Gera um diagrama diagrams.net nativo a partir do modelo Mermaid.

Uso: python docs/gerar_drawio.py
As entidades, campos e relações continuam editáveis individualmente no .drawio.
"""

from __future__ import annotations

import html
import re
import xml.etree.ElementTree as ET
from pathlib import Path


BASE = Path(__file__).resolve().parent
SOURCE = BASE / "modelo_logico_redepatas.mmd"
TARGET = BASE / "modelo_logico_redepatas.drawio"

POSITIONS = {
    "UF": (30, 30),
    "MUNICIPIO": (30, 200),
    "USUARIO": (30, 450),
    "TOKEN_RENOVACAO": (30, 790),
    "PONTO_APOIO": (410, 30),
    "RECURSO": (410, 460),
    "PONTO_RECURSO": (410, 630),
    "MANUTENCAO": (410, 850),
    "ANIMAL": (810, 30),
    "AVISTAMENTO": (810, 260),
    "FOTO": (810, 550),
    "PONTO_SEGUIDO": (1210, 30),
    "PREFERENCIA_ALERTA": (1210, 220),
    "DISPOSITIVO": (1210, 440),
    "NOTIFICACAO": (1210, 650),
}

COLORS = {
    "UF": ("#e8f3fd", "#5088b5"),
    "MUNICIPIO": ("#e8f3fd", "#5088b5"),
    "USUARIO": ("#f0ebfa", "#8165ac"),
    "TOKEN_RENOVACAO": ("#f0ebfa", "#8165ac"),
    "PONTO_APOIO": ("#e7f4e8", "#539562"),
    "RECURSO": ("#e7f4e8", "#539562"),
    "PONTO_RECURSO": ("#e7f4e8", "#539562"),
    "MANUTENCAO": ("#e7f4e8", "#539562"),
    "ANIMAL": ("#fff1df", "#c48b42"),
    "AVISTAMENTO": ("#fff1df", "#c48b42"),
    "FOTO": ("#fff1df", "#c48b42"),
    "PONTO_SEGUIDO": ("#f0ebfa", "#8165ac"),
    "PREFERENCIA_ALERTA": ("#f0ebfa", "#8165ac"),
    "DISPOSITIVO": ("#f0ebfa", "#8165ac"),
    "NOTIFICACAO": ("#f0ebfa", "#8165ac"),
}


def parse_model(source: str):
    entities: dict[str, list[str]] = {}
    relationships: list[tuple[str, str, str, str]] = []
    current = None
    for raw in source.splitlines():
        line = raw.strip()
        if not line or line.startswith("%%") or line in ("erDiagram", "direction LR"):
            continue
        match = re.fullmatch(r"(\w+)\s*\{", line)
        if match:
            current = match.group(1)
            entities[current] = []
        elif line == "}":
            current = None
        elif current:
            entities[current].append(line)
        else:
            match = re.fullmatch(r"(\w+)\s+(\S+)\s+(\w+)\s*:\s*(.+)", line)
            if not match:
                raise ValueError(f"Relação inválida: {line}")
            relationships.append(match.groups())
    if set(entities) != set(POSITIONS):
        raise ValueError(f"Ajuste POSITIONS para as entidades: {set(entities) ^ set(POSITIONS)}")
    return entities, relationships


def cardinality(marker: str):
    return {"||": "1", "|o": "0..1", "o|": "0..1", "o{": "0..N", "}o": "0..N", "|{": "1..N", "}|": "1..N"}[marker]


def build():
    entities, relationships = parse_model(SOURCE.read_text(encoding="utf-8"))
    mxfile = ET.Element("mxfile", {"host": "app.diagrams.net", "type": "device"})
    diagram = ET.SubElement(mxfile, "diagram", {"id": "redepatas-logico", "name": "Modelo logico"})
    model = ET.SubElement(diagram, "mxGraphModel", {
        "dx": "1600", "dy": "1100", "grid": "1", "gridSize": "10", "guides": "1",
        "tooltips": "1", "connect": "1", "arrows": "1", "fold": "1", "page": "1",
        "pageScale": "1", "pageWidth": "1800", "pageHeight": "1350", "math": "0", "shadow": "0",
    })
    root = ET.SubElement(model, "root")
    ET.SubElement(root, "mxCell", {"id": "0"})
    ET.SubElement(root, "mxCell", {"id": "1", "parent": "0"})

    for name, fields in entities.items():
        x, y = POSITIONS[name]
        fill, stroke = COLORS[name]
        width = 335
        height = 46 + 22 * len(fields)
        lines = [f'<div style="font-size:15px"><b>{html.escape(name)}</b></div>']
        for field in fields:
            parts = field.split()
            datatype, field_name = parts[0], parts[1]
            markers = " ".join(parts[2:])
            key = f" <b>[{html.escape(markers)}]</b>" if markers else ""
            lines.append(f'<div style="text-align:left">{html.escape(field_name)} : {html.escape(datatype)}{key}</div>')
        cell = ET.SubElement(root, "mxCell", {
            "id": name,
            "value": "".join(lines),
            "style": f"rounded=1;whiteSpace=wrap;html=1;align=left;verticalAlign=top;spacing=10;"
                     f"fillColor={fill};strokeColor={stroke};fontColor=#273441;fontSize=12;",
            "vertex": "1", "parent": "1",
        })
        ET.SubElement(cell, "mxGeometry", {
            "x": str(x), "y": str(y), "width": str(width), "height": str(height), "as": "geometry",
        })

    for i, (source, marker, target, label) in enumerate(relationships, 1):
        left, right = cardinality(marker[:2]), cardinality(marker[-2:])
        cell = ET.SubElement(root, "mxCell", {
            "id": f"rel-{i}", "value": f"{html.escape(label)} ({left}:{right})",
            "style": "edgeStyle=orthogonalEdgeStyle;rounded=1;orthogonalLoop=1;jettySize=auto;"
                     "html=1;strokeColor=#697887;strokeWidth=1.5;endArrow=none;startArrow=none;"
                     "fontSize=10;fontColor=#344454;labelBackgroundColor=#ffffff;",
            "edge": "1", "parent": "1", "source": source, "target": target,
        })
        ET.SubElement(cell, "mxGeometry", {"relative": "1", "as": "geometry"})

    ET.indent(mxfile, space="  ")
    TARGET.write_bytes(ET.tostring(mxfile, encoding="utf-8", xml_declaration=True))
    print(f"Gerado: {TARGET} ({len(entities)} entidades, {len(relationships)} relações)")


if __name__ == "__main__":
    build()
