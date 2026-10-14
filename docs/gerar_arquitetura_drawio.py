"""Gera o documento draw.io da arquitetura lógica do RedePatas.

Uso: python docs/gerar_arquitetura_drawio.py
Todas as caixas, textos e setas são objetos nativos editáveis no diagrams.net.
"""

from __future__ import annotations

import xml.etree.ElementTree as ET
from pathlib import Path


OUTPUT = Path(__file__).resolve().parent / "arquitetura_logica_redepatas.drawio"

PALETTE = {
    "actual": ("#e6f4ea", "#43865b"),
    "future": ("#e8f1fc", "#4f7eac"),
    "external": ("#f4f0e7", "#9e865e"),
    "neutral": ("#ffffff", "#94a3b4"),
    "note": ("#fff7df", "#c69d36"),
}


class Page:
    def __init__(self, parent: ET.Element, name: str, page_id: str, height: int):
        diagram = ET.SubElement(parent, "diagram", {"id": page_id, "name": name})
        model = ET.SubElement(diagram, "mxGraphModel", {
            "dx": "1800", "dy": "1200", "grid": "1", "gridSize": "10",
            "guides": "1", "tooltips": "1", "connect": "1", "arrows": "1",
            "fold": "1", "page": "1", "pageScale": "1", "pageWidth": "1800",
            "pageHeight": str(height), "math": "0", "shadow": "0",
        })
        self.root = ET.SubElement(model, "root")
        ET.SubElement(self.root, "mxCell", {"id": "0"})
        ET.SubElement(self.root, "mxCell", {"id": "1", "parent": "0"})
        self.ids: set[str] = set()

    def box(self, id: str, label: str, x: int, y: int, w: int, h: int,
            kind: str = "neutral", size: int = 14, bold: bool = False):
        fill, stroke = PALETTE[kind]
        style = (
            "rounded=1;whiteSpace=wrap;html=1;align=center;verticalAlign=middle;"
            "spacing=8;shadow=0;"
            f"fillColor={fill};strokeColor={stroke};strokeWidth=1.6;"
            f"fontColor=#243647;fontSize={size};fontStyle={1 if bold else 0};"
        )
        self._vertex(id, label, style, x, y, w, h)

    def frame(self, id: str, title: str, x: int, y: int, w: int, h: int,
              kind: str = "neutral"):
        fill, stroke = PALETTE[kind]
        style = (
            "rounded=1;whiteSpace=wrap;html=1;align=left;verticalAlign=top;"
            "spacingTop=13;spacingLeft=16;container=0;dashed=1;dashPattern=6 4;"
            f"fillColor={fill};strokeColor={stroke};strokeWidth=1.7;"
            "fontColor=#263b4c;fontSize=18;fontStyle=1;"
        )
        self._vertex(id, title, style, x, y, w, h)

    def text(self, id: str, label: str, x: int, y: int, w: int, h: int,
             size: int = 16, bold: bool = False):
        style = (
            "text;html=1;align=left;verticalAlign=middle;whiteSpace=wrap;"
            "strokeColor=none;fillColor=none;"
            f"fontColor=#243647;fontSize={size};fontStyle={1 if bold else 0};"
        )
        self._vertex(id, label, style, x, y, w, h)

    def _vertex(self, id: str, label: str, style: str,
                x: int, y: int, w: int, h: int):
        if id in self.ids:
            raise ValueError(f"ID duplicado: {id}")
        self.ids.add(id)
        cell = ET.SubElement(self.root, "mxCell", {
            "id": id, "value": label, "style": style,
            "vertex": "1", "parent": "1",
        })
        ET.SubElement(cell, "mxGeometry", {
            "x": str(x), "y": str(y), "width": str(w),
            "height": str(h), "as": "geometry",
        })

    def arrow(self, id: str, source: str, target: str, label: str = "",
              dashed: bool = False, color: str = "#60788e"):
        if source not in self.ids or target not in self.ids:
            raise ValueError(f"Ponta da seta não existe: {source} -> {target}")
        style = (
            "edgeStyle=orthogonalEdgeStyle;rounded=1;orthogonalLoop=1;"
            "jettySize=auto;html=1;endArrow=block;endFill=1;"
            f"strokeColor={color};strokeWidth=1.8;fontColor=#33485b;"
            "fontSize=12;labelBackgroundColor=#ffffff;"
            f"dashed={1 if dashed else 0};"
        )
        cell = ET.SubElement(self.root, "mxCell", {
            "id": id, "value": label, "style": style,
            "edge": "1", "parent": "1", "source": source, "target": target,
        })
        ET.SubElement(cell, "mxGeometry", {"relative": "1", "as": "geometry"})


def overview(mxfile: ET.Element):
    p = Page(mxfile, "1 - Visão geral", "architecture-overview", 1180)
    p.text("title", "RedePatas | arquitetura lógica", 40, 20, 900, 42, 26, True)
    p.text("subtitle", "Verde: existe no Flutter  •  Azul: planejado  •  Bege: serviço ou dado externo", 40, 67, 1280, 30, 15)

    p.frame("flutter", "Aplicativo Flutter", 40, 130, 500, 690, "actual")
    p.frame("api", "API ASP.NET Core (C#) — planejada", 650, 130, 500, 690, "future")
    p.frame("database", "PostgreSQL + PostGIS — planejado", 1260, 130, 490, 690, "future")

    p.box("ui", "Telas: login, mapa, filtros, cadastro,<br>detalhes, histórico e alertas", 70, 205, 440, 82, "actual", 15, True)
    p.box("auth_state", "AuthController<br>estado da sessão", 70, 330, 205, 95, "actual", 15, True)
    p.box("data_contract", "RedePatasRepository<br>contrato dos dados", 305, 330, 205, 95, "actual", 15, True)
    p.box("secure_store", "SecureSessionStore<br>tokens no dispositivo", 70, 465, 205, 90, "actual")
    p.box("api_auth_client", "ApiAuthService<br>cliente HTTP pronto", 305, 465, 205, 90, "actual")
    p.box("mocks", "MockAuthService + MockRedePatasRepository<br>dados locais em memória", 70, 605, 440, 95, "actual")
    p.box("api_repo", "ApiRedePatasRepository<br>a implementar no Flutter", 305, 720, 205, 65, "future", 12)

    p.box("controllers", "Endpoints REST + validação de entrada", 680, 205, 440, 82, "future", 15, True)
    p.box("auth_service", "Autenticação<br>login, JWT e refresh token", 680, 330, 205, 100, "future")
    p.box("point_service", "Pontos e animais<br>consultas, cadastro e histórico", 915, 330, 205, 100, "future")
    p.box("spatial_service", "Localização<br>raio, área e município", 680, 485, 205, 100, "future")
    p.box("alert_service", "Alertas<br>preferências e envio push", 915, 485, 205, 100, "future")
    p.box("persistence", "Persistência (EF Core / Npgsql)<br>transações, migrações e índices", 680, 650, 440, 90, "future")

    p.box("postgres", "PostgreSQL<br>dados persistentes", 1290, 205, 430, 90, "future", 16, True)
    p.box("tables", "Usuário e sessão • ponto e recurso<br>manutenção • animal e avistamento<br>foto • município/UF • alertas", 1290, 355, 430, 155, "future")
    p.box("postgis", "PostGIS<br>coordenadas, índices espaciais,<br>busca por raio e limites municipais", 1290, 570, 430, 130, "future")

    p.text("external_title", "Integrações e dados externos", 40, 860, 800, 32, 19, True)
    p.box("tiles", "Tiles de mapa<br>provedor a definir", 40, 920, 290, 90, "external")
    p.box("gps", "GPS do dispositivo", 365, 920, 270, 90, "external")
    p.box("photos", "Arquivos de fotos<br>armazenamento a definir", 670, 920, 300, 90, "external")
    p.box("push", "Serviço de push<br>a definir", 1005, 920, 290, 90, "external")
    p.box("ibge", "Catálogo e limites<br>municipais do IBGE", 1330, 920, 420, 90, "external")
    p.box("current_note", "Estado atual: só a autenticação tem cliente HTTP. Pontos, animais e histórico ainda usam mocks; a API e o banco não existem neste repositório.", 40, 1050, 1710, 70, "note", 14)

    p.arrow("o1", "ui", "auth_state", "login / sessão")
    p.arrow("o2", "ui", "data_contract", "dados do mapa")
    p.arrow("o3", "auth_state", "secure_store", "salva / restaura")
    p.arrow("o4", "auth_state", "api_auth_client", "usa")
    p.arrow("o5", "data_contract", "mocks", "hoje")
    p.arrow("o6", "data_contract", "api_repo", "futuro", True)
    p.arrow("o7", "api_auth_client", "controllers", "HTTPS/JSON", True)
    p.arrow("o8", "api_repo", "controllers", "HTTPS/JSON", True)
    p.arrow("o9", "controllers", "auth_service", "autenticação")
    p.arrow("o10", "controllers", "point_service", "operações")
    p.arrow("o11", "point_service", "spatial_service", "consultas")
    p.arrow("o12", "point_service", "alert_service", "eventos")
    p.arrow("o13", "auth_service", "persistence", "grava / lê")
    p.arrow("o14", "spatial_service", "persistence", "consulta")
    p.arrow("o15", "alert_service", "persistence", "consulta")
    p.arrow("o16", "persistence", "postgres", "SQL")
    p.arrow("o17", "postgres", "tables", "armazena")
    p.arrow("o18", "tables", "postgis", "geometria / índices")


def flows(mxfile: ET.Element):
    p = Page(mxfile, "2 - Fluxos e responsabilidades", "architecture-flows", 1400)
    p.text("title", "RedePatas | fluxos principais", 40, 20, 1200, 42, 26, True)
    p.text("subtitle", "Cada linha mostra a responsabilidade do Flutter, da API C# e do PostgreSQL/PostGIS. Setas azuis representam a integração planejada.", 40, 68, 1650, 36, 15)

    for id, title, x in (("h_fl", "Flutter", 40), ("h_api", "API C#", 630), ("h_db", "PostgreSQL / PostGIS", 1220)):
        p.box(id, title, x, 130, 540, 58, "neutral", 18, True)

    p.text("auth_h", "1. Login e sessão", 40, 220, 490, 32, 18, True)
    p.box("auth_fl", "AuthController → ApiAuthService<br>POST /api/auth/login; GET /me; refresh<br>SecureSessionStore salva tokens", 40, 270, 540, 130, "actual")
    p.box("auth_api", "Valida senha; emite access token<br>e refresh token rotativo; valida Bearer<br>em cada endpoint protegido", 630, 270, 540, 130, "future")
    p.box("auth_db", "USUARIO + TOKEN_RENOVACAO<br>hash da senha e hash do refresh token", 1220, 270, 540, 130, "future")
    p.arrow("f1", "auth_fl", "auth_api", "HTTPS/JSON", True)
    p.arrow("f2", "auth_api", "auth_db", "lê / grava")

    p.text("search_h", "2. Mapa, filtros e cidade", 40, 440, 600, 32, 18, True)
    p.box("search_fl", "GPS / área visível / filtros<br>GET /api/points?bbox=&amp;municipioCodigoIbge=&amp;resource=<br>repositório HTTP alimenta o mapa", 40, 490, 540, 140, "future")
    p.box("search_api", "Valida filtros e pagina resultados<br>combina recurso, situação, área e raio<br>retorna distância e cidade", 630, 490, 540, 140, "future")
    p.box("search_db", "PONTO_APOIO + PONTO_RECURSO<br>FK municipio_codigo_ibge para filtro por cidade<br>PostGIS para proximidade / área", 1220, 490, 540, 140, "future")
    p.arrow("f3", "search_fl", "search_api", "GET", True)
    p.arrow("f4", "search_api", "search_db", "SQL + índice")

    p.text("create_h", "3. Cadastro de ponto e foto", 40, 670, 600, 32, 18, True)
    p.box("create_fl", "Envia latitude e longitude WGS84,<br>recursos e foto; mostra resultado<br>somente após confirmação da API", 40, 720, 540, 140, "future")
    p.box("create_api", "Valida dados e autorização; salva foto<br>classifica município pelas coordenadas<br>grava ponto e recursos em transação", 630, 720, 540, 140, "future")
    p.box("create_db", "PONTO_APOIO + PONTO_RECURSO + FOTO<br>MUNICIPIO/UF e limite espacial<br>latitude/longitude continuam canônicas", 1220, 720, 540, 140, "future")
    p.arrow("f5", "create_fl", "create_api", "POST /api/points", True)
    p.arrow("f6", "create_api", "create_db", "INSERT + ST_Covers")

    p.text("maintenance_h", "4. Manutenção e alertas", 40, 900, 600, 32, 18, True)
    p.box("maintenance_fl", "Registra abastecimento ou falta<br>acompanha pontos; recebe push<br>e abre o ponto correspondente", 40, 950, 540, 140, "future")
    p.box("maintenance_api", "Autoriza e registra manutenção<br>atualiza situação do recurso na transação<br>job consulta preferências e envia push", 630, 950, 540, 140, "future")
    p.box("maintenance_db", "MANUTENCAO + PONTO_RECURSO<br>PONTO_SEGUIDO + PREFERENCIA_ALERTA<br>DISPOSITIVO + NOTIFICACAO", 1220, 950, 540, 140, "future")
    p.arrow("f7", "maintenance_fl", "maintenance_api", "POST /maintenance", True)
    p.arrow("f8", "maintenance_api", "maintenance_db", "transação + consulta")

    p.box("city_note", "Cidade: a API deriva municipio_codigo_ibge de (longitude, latitude) usando o limite municipal no PostGIS. O Flutter envia coordenadas; a UF vem do município. Sem correspondência confiável, o código permanece nulo até revisão.", 40, 1150, 1720, 120, "note", 15)
    p.text("refs", "Modelo de dados detalhado: MODELO_LOGICO_BANCO.md e modelo_logico_redepatas.drawio", 40, 1310, 1700, 32, 14)


def main():
    mxfile = ET.Element("mxfile", {"host": "app.diagrams.net", "type": "device"})
    overview(mxfile)
    flows(mxfile)
    ET.indent(mxfile, space="  ")
    OUTPUT.write_bytes(ET.tostring(mxfile, encoding="utf-8", xml_declaration=True))
    print(f"Gerado: {OUTPUT}")


if __name__ == "__main__":
    main()
