from docx import Document
from docx.shared import Cm, Pt, RGBColor
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from pathlib import Path

rf = [
('RF01', 'Autenticação', 'O sistema deve permitir que o usuário entre com e-mail e senha, restaure uma sessão válida e encerre a sessão.'),
('RF02', 'Mapa de pontos de apoio', 'O sistema deve exibir em um mapa os pontos de água, ração e abrigo, com marcadores e acesso aos detalhes de cada ponto.'),
('RF03', 'Busca e filtros', 'O sistema deve permitir consultar pontos por proximidade, área visível do mapa, tipo de recurso e situação, combinando os filtros selecionados.'),
('RF04', 'Localização', 'O sistema deve permitir utilizar a localização do dispositivo, mediante permissão, ou selecionar manualmente uma região e a posição de um cadastro no mapa.'),
('RF05', 'Cadastro de pontos', 'O sistema deve permitir cadastrar pontos de apoio com nome, descrição, referência, coordenadas, recursos disponíveis e foto, além de informações de manutenção e responsável.'),
('RF06', 'Situação dos recursos', 'O sistema deve permitir informar disponibilidade, falta de água, falta de ração e necessidade de manutenção nos pontos de apoio.'),
('RF07', 'Registro e histórico de manutenção', 'O sistema deve registrar verificações, abastecimentos e ocorrências de manutenção, identificando ponto, ação, autor e data, e permitir consultar o histórico de cada ponto.'),
('RF08', 'Animais e avistamentos', 'O sistema deve permitir cadastrar e consultar avistamentos de animais em situação de rua, com descrição, localização, data e foto, exibindo os registros no mapa e em lista.'),
('RF09', 'Acompanhamento de pontos', 'O sistema deve permitir que o usuário acompanhe e deixe de acompanhar pontos de apoio, mantendo essa seleção vinculada à sua conta.'),
('RF10', 'Preferências de alertas', 'O sistema deve permitir configurar o raio de interesse e os tipos de recurso para recebimento de alertas, bem como ativar ou desativar os avisos.'),
('RF11', 'Envio de alertas', 'O sistema deve notificar o usuário sobre pontos que necessitem de atenção, conforme suas preferências e pontos acompanhados, inclusive com o aplicativo fechado quando houver permissão para notificações.'),
('RF12', 'Fotos dos registros', 'O sistema deve permitir selecionar e enviar fotos para os cadastros de pontos e avistamentos, disponibilizando as imagens na consulta dos respectivos registros.'),
]
rnf = [
('RNF01', 'Proteção da comunicação', 'O sistema deve utilizar HTTPS na comunicação entre o aplicativo e a API.'),
('RNF02', 'Proteção de credenciais', 'O sistema deve armazenar senhas no servidor somente como hashes, guardar tokens em armazenamento protegido no aplicativo e não salvar a senha no dispositivo.'),
('RNF03', 'Controle de acesso', 'O sistema deve validar a autenticação e as permissões no servidor em cada operação protegida e permitir revogar e renovar os tokens de sessão.'),
('RNF04', 'Persistência e integridade', 'O sistema deve preservar os registros após o encerramento do aplicativo e gravar a atualização da situação de um ponto e seu evento de manutenção em uma única transação.'),
('RNF05', 'Eficiência das consultas', 'O sistema deve realizar buscas geográficas no servidor com índices espaciais e paginação, limitando os resultados à área ou ao raio solicitado.'),
('RNF06', 'Usabilidade e compatibilidade', 'O sistema deve apresentar a interface em português, adaptar as telas a diferentes tamanhos de dispositivos Android e iOS e informar estados de carregamento, ausência de resultados e erro.'),
('RNF07', 'Tratamento de falhas', 'O sistema deve informar falhas de conexão e de envio de dados, permitir nova tentativa e confirmar o sucesso de uma gravação somente após a confirmação do servidor.'),
('RNF08', 'Permissões e privacidade', 'O sistema deve solicitar permissão antes de acessar localização, fotos ou notificações e permitir a navegação por uma região escolhida manualmente quando o acesso à localização for negado.'),
]

doc = Document()
sec = doc.sections[0]
sec.page_height, sec.page_width = Cm(29.7), Cm(21)
sec.top_margin = sec.bottom_margin = Cm(1.8)
sec.left_margin = sec.right_margin = Cm(2)
normal = doc.styles['Normal']
normal.font.name = 'Calibri'
normal.font.size = Pt(10.5)
normal.paragraph_format.space_after = Pt(6)
normal.paragraph_format.line_spacing = 1.05
for name in ['Title', 'Heading 1', 'Heading 2']:
    doc.styles[name].font.name = 'Calibri'
    doc.styles[name].font.color.rgb = RGBColor(0, 0, 0)
doc.styles['Title'].font.size = Pt(24)
doc.styles['Heading 1'].font.size = Pt(16)
doc.add_paragraph('Requisitos do RedePatas', 'Title')
doc.add_paragraph('Especificação dos principais requisitos para localizar pontos de apoio a animais em situação de rua e organizar sua manutenção. RF identifica funcionalidades; RNF define condições de qualidade e funcionamento da solução.')
doc.add_heading('Requisitos funcionais', level=1)
def add_items(items):
    for code, title, text in items:
        p = doc.add_paragraph()
        p.paragraph_format.keep_together = True
        p.add_run(f'{code}  {title}\n').bold = True
        p.add_run(text)
add_items(rf)
doc.add_page_break()
doc.add_heading('Requisitos não funcionais', level=1)
add_items(rnf)
doc.core_properties.title = 'Requisitos do RedePatas'
doc.core_properties.subject = 'Requisitos funcionais e não funcionais'
doc.core_properties.author = 'RedePatas'
path = Path('docs/Requisitos_RF_RNF_RedePatas.docx')
doc.save(path)
assert len(rf) == 12 and len(rnf) == 8
assert all(t.startswith('O sistema deve') for _, _, t in rf+rnf)
print(path.resolve())
