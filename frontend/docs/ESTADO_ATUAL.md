# RedePatas: estado atual e plano de implementação

**Atualizado em 14 de outubro de 2026.** O RedePatas é um protótipo Flutter para localizar pontos de água, ração e abrigo, registrar animais em situação de rua e coordenar a manutenção desses pontos. O aplicativo pode ser executado e navegado com dados fictícios de Curitiba. A API C# e o banco de dados ainda não existem neste repositório; por isso, os registros do mapa não sobrevivem ao encerramento do app.

Este documento descreve o que funciona hoje, como o código está organizado e o trabalho necessário para chegar a uma primeira versão com usuários e dados reais. **Login de demonstração não é autenticação real:** ele serve para testar a navegação até que a API C# seja construída.

O [diagrama de arquitetura lógica](arquitetura_logica_redepatas.drawio) apresenta em duas páginas a visão geral dos componentes e os fluxos principais entre Flutter, API C# e PostgreSQL/PostGIS. Os elementos já existentes e os planejados têm cores distintas.

## Como executar e verificar

```bash
flutter pub get
flutter run
flutter analyze
flutter test
```

Na tela inicial, use **Entrar com conta de demonstração** ou informe `voluntario@redepatas.app` e `123456`. O mapa precisa de internet para carregar os tiles. O botão de localização pede permissão para o GPS; sem ela, a visualização começa no centro fictício de Curitiba. A última execução de `flutter analyze` não apontou problemas e os três testes existentes passaram.

Quando os endpoints de autenticação existirem, é possível testar o cliente HTTP já implementado com:

```bash
flutter run --dart-define=API_BASE_URL=https://seu-servidor
```

Essa variável troca **somente o login** para a API. Pontos, animais, histórico e alertas continuam mockados até a implementação do repositório HTTP correspondente. Para emulador Android e dispositivo físico, a URL precisa ser alcançável pelo próprio dispositivo; `localhost` no celular não é o computador de desenvolvimento.

## Arquitetura atual

O Flutter exibe as telas e recebe ações do usuário. `RedePatasRepository` fornece pontos, animais e histórico, hoje por meio de `MockRedePatasRepository`. `AuthController` mantém o estado de autenticação e escolhe entre login e mapa. `MockAuthService` permite a demonstração; `ApiAuthService` já conhece o contrato HTTP proposto para a futura API C#. A sessão é serializada por `AuthSession` e gravada por `SecureSessionStore` com `flutter_secure_storage`.

```text
Usuário
  └─ telas Flutter
      ├─ AuthController ─ AuthService ─ armazenamento protegido
      └─ RedePatasRepository ─ dados mockados em memória

Futuro: AuthService e RedePatasRepository ─ HTTPS ─ API ASP.NET Core ─ banco e fotos
```

No app nativo, a sessão salva contém ID, nome, e-mail, access token, refresh token e expiração; **a senha não é salva**. Ao iniciar, o controlador tenta restaurá-la. No modo API, `/api/auth/me` valida um access token ainda vigente; quando ele vence ou recebe 401, `/api/auth/refresh` tenta renová-lo. Se a renovação falhar, o login reaparece. O backend deverá validar o token em cada operação protegida: o estado da interface não é prova de autorização. O mock gera tokens fictícios válidos localmente por sete dias.

## Organização de pastas e arquivos

| Caminho | Responsabilidade atual |
| --- | --- |
| `lib/main.dart` | Inicia o aplicativo Flutter. |
| `lib/app/redepatas_app.dart` | Define tema, cria repositório e autenticação, escolhe login ou área principal. |
| `lib/auth/auth_session.dart` | Modelo e serialização da sessão. |
| `lib/auth/auth_controller.dart` | Estado logado/deslogado, restauração, entrada, saída e expiração. |
| `lib/auth/auth_service.dart` | Contrato de autenticação e serviço mock com conta de demonstração. |
| `lib/auth/api_auth_service.dart` | Cliente HTTP de login, consulta da sessão, renovação e logout. |
| `lib/auth/session_store.dart` | Contrato do armazenamento; versão protegida e versão em memória para testes. |
| `lib/domain/models.dart` | Modelos de ponto, animal, recurso, status e evento de manutenção. |
| `lib/data/repository.dart` | Contrato de dados e implementação mock, com alterações somente em memória. |
| `lib/data/mock/mock_points.dart` | Pontos fictícios de Curitiba. |
| `lib/data/mock/mock_animals.dart` | Animais fictícios e fotos de exemplo. |
| `lib/data/mock/mock_maintenance.dart` | Histórico inicial fictício. |
| `lib/data/map_config.dart` | URL dos tiles e identificação do cliente de mapa. |
| `lib/ui/login_page.dart` | Formulário de login, erros e acesso à conta de demonstração. |
| `lib/ui/home_shell.dart` | Navegação, mapa, filtros, lista, alertas e painel da comunidade. |
| `lib/ui/entry_sheet.dart` | Cadastro de ponto ou animal, foto da galeria, GPS e ajuste no mapa. |
| `lib/ui/detail_sheets.dart` | Detalhes, acompanhamento, atualização de situação e histórico. |
| `lib/ui/common.dart` | Cores, indicadores de status, imagens, tempo e distância. |
| `test/widget_test.dart` | Testa restauração/logout mock e entrada na interface. |
| `test/api_auth_service_test.dart` | Testa o contrato HTTP esperado para login, renovação e logout. |
| `android/` e `ios/` | Projetos nativos; permissões de internet/localização e descrição do acesso às fotos. |
| `web/`, `windows/`, `linux/`, `macos/` | Estruturas geradas pelo Flutter; ainda sem validação específica de publicação. |
| `pubspec.yaml` e `pubspec.lock` | Dependências e versões resolvidas. |
| `README.md` | Início rápido e decisões técnicas resumidas. |

Dependências principais: `flutter_map` e `latlong2` para mapa/coordenadas, `geolocator` para GPS, `image_picker` para fotos da galeria, `flutter_secure_storage` para sessão e `http` para autenticação via API. As telas usam `StatefulWidget` para interação; os repositórios e o controlador avisam mudanças com `ChangeNotifier`.

## Requisitos e situação atual

| Requisito | Situação | O que funciona e o que falta |
| --- | --- | --- |
| Mapa de pontos de apoio | **Protótipo funcional** | Marcadores e detalhes aparecem sobre OpenStreetMap; os pontos vêm dos mocks. |
| Pontos próximos e distância | **Parcial** | A distância é calculada no celular. O GPS é acionado pelo usuário; sem ele, usa Curitiba. Falta busca por área/raio no servidor. |
| Filtros por recurso | **Parcial** | Há filtros individuais para água, ração e abrigo. Faltam filtro conjunto água + ração, “outros”, filtros combinados e status. |
| Cadastro de ponto | **Protótipo funcional** | Nome, descrição, referência, recursos, frequência, responsável, quantidade, foto e posição podem ser informados. Falta validação de qualidade, envio de foto e persistência. |
| Situação e abastecimento | **Parcial** | É possível marcar abastecido/verificado, falta de água, falta de ração ou manutenção; o histórico em memória é atualizado. O estado inativo existe no modelo, mas não há fluxo de desativação. |
| Histórico de manutenção | **Protótipo funcional** | Eventos iniciais e ações feitas na sessão aparecem no detalhe e na comunidade. Falta gravar autor autenticado, data do servidor, evidências e persistência. |
| Acompanhar ponto | **Parcial** | O botão altera o estado em memória. Falta associação com usuário e sincronização. |
| Animais no mapa | **Protótipo funcional** | Há marcadores, lista, detalhes, fotos e cadastro de avistamento. Falta persistência, atualização de avistamento e regras para registros repetidos. |
| Concentração de animais | **Demonstração ilustrativa** | A comunidade agrupa os mocks em duas regiões por longitude. Não é uma análise geográfica real nem um mapa de calor. |
| Alertas de pontos próximos | **Somente dentro do app** | A aba calcula pontos em atenção com raio e acompanhamento durante a sessão. Não existem push, processamento em segundo plano nem preferências salvas. |
| Login e sessão | **Mock + cliente HTTP preparado** | Tela, restauração e logout funcionam. A API C#, o cadastro de usuários e a validação real ainda não existem. |
| Fotos | **Parcial** | Fotos de exemplo usam URLs externas; novas fotos são lidas da galeria e mantidas em memória. Falta upload, armazenamento, tratamento e exclusão. |

## Decisões de dados e serviços

### Localização, cidade e estado

Latitude e longitude em WGS84 devem ser os dados principais do ponto ou avistamento. A busca por proximidade deve usar índice espacial no banco e consultar a área visível ou um raio. O [modelo lógico proposto](MODELO_LOGICO_BANCO.md) adiciona `municipio_codigo_ibge` opcional e derivado para filtros administrativos e relatórios; a UF vem do cadastro do município. Isso não substitui as coordenadas. O app ainda não possui esses campos, classificação espacial nem filtro por município.

Uma opção de banco é PostgreSQL com PostGIS; se a disciplina exigir SQL Server, seu tipo espacial também atende à busca por raio. A escolha deve ser fechada antes das migrações. O modelo propõe classificar coordenadas por limites municipais oficiais carregados no banco, no cadastro ou em processamento posterior, aceitando revisão e valores desconhecidos. Evite chamar geocodificação em toda consulta ao mapa.

### Custo do mapa e dos avisos

`flutter_map` exibe dados OpenStreetMap. O protótipo usa os tiles públicos de `tile.openstreetmap.org`, com atribuição visível. O serviço público está sujeito à [política de uso de tiles](https://operations.osmfoundation.org/policies/tiles/); antes da publicação, é preciso definir um provedor compatível com o volume previsto ou hospedar tiles. “Dados abertos” não significa hospedagem ilimitada sem custo. GPS usa o serviço do dispositivo; backend, fotos e notificações também precisam de orçamento e limites operacionais.

O usuário deverá configurar raio, recursos e pontos acompanhados. Para push, um serviço no backend precisa detectar mudanças relevantes, selecionar destinatários, evitar mensagens repetidas e enviar aos tokens dos dispositivos. O app terá de solicitar permissão, cadastrar/atualizar o token de push e permitir desativação.

## Trabalho pendente para uma primeira versão real

As caixas abaixo representam entregas ainda não concluídas. A ordem preserva dependências: decisões e banco antes da integração; integração antes de testes completos e publicação.

### 1. Fechar regras do produto

- [ ] Definir público e permissões: mapa aberto sem conta ou login obrigatório; quem pode criar, editar, inativar e moderar pontos e animais.
- [ ] Definir estados e transições. Decidir se água e ração terão estados separados; um status único não expressa bem a falta simultânea dos dois recursos.
- [ ] Definir o que significa “verificado”, “abastecido”, “precisa de manutenção” e quando um registro fica desatualizado.
- [ ] Definir campos obrigatórios, tamanho e tipo de foto, limites de quantidade, política de registros duplicados e regras de remoção.
- [ ] Escolher banco espacial, hospedagem, serviço de tiles, armazenamento de fotos e serviço de push dentro do orçamento disponível.
- [ ] Definir regiões atendidas, política de privacidade, retenção de localização/fotos e canal para reportar conteúdo incorreto.

### 2. Construir a API e o banco em C#

- [ ] Criar projeto ASP.NET Core, configuração por ambiente, migrações e documentação OpenAPI.
- [ ] Modelar usuários, pontos, recursos, avistamentos, fotos, eventos de manutenção, acompanhamentos, preferências de alerta e dispositivos push.
- [ ] Adicionar latitude/longitude e índice espacial; implementar consultas por área visível, raio, recurso e status com paginação.
- [ ] Adicionar cidade/UF opcionais, identificador de município quando disponível e processo de derivação/correção.
- [ ] Criar `POST /api/auth/login`, `GET /api/auth/me`, `POST /api/auth/refresh` e `POST /api/auth/logout` com o JSON descrito no `README.md`.
- [ ] Criar cadastro de conta, recuperação de senha e verificação de e-mail se essas ações forem necessárias ao lançamento.
- [ ] Usar hash de senha, access token curto, refresh token rotativo e revogável, HTTPS e autorização por usuário/ação.
- [ ] Criar endpoints CRUD para pontos e animais, upload de fotos, histórico, atualização de situação, acompanhamento e preferências.
- [ ] Gravar atualização de status e evento de manutenção em uma transação; registrar ID do autor e horário do servidor.
- [ ] Validar entrada no servidor, limitar abuso, tratar concorrência, moderar denúncias e impedir alterações indevidas.
- [ ] Implementar armazenamento de fotos, miniaturas, exclusão e limites de tamanho/formato.
- [ ] Criar processamento de regiões com concentração de avistamentos usando grade/agrupamento espacial e período definido.
- [ ] Criar tarefas de detecção de pontos em atenção e envio de push com controle de duplicidade e preferência do usuário.

### 3. Conectar o Flutter aos dados reais

- [ ] Implementar `ApiRedePatasRepository` com os mesmos métodos de `RedePatasRepository`, substituir o mock em `redepatas_app.dart` e expor estados de carregamento, vazio e erro.
- [ ] Adaptar a interface do repositório para consultas por área/raio, páginas e filtros no servidor; buscar novamente ao mover o mapa sem disparar requisições excessivas.
- [ ] Criar cliente HTTP compartilhado que envie `Authorization: Bearer`, renove no 401 uma vez, trate 403 e limpe dados privados no logout.
- [ ] Fazer upload da foto antes ou junto do cadastro, trocar bytes locais por referência persistida e exibir falhas de envio.
- [ ] Persistir acompanhamentos, preferências de alerta e histórico por usuário; substituir o autor “Você” pelo usuário autenticado.
- [ ] Ajustar cadastro para cidade/UF quando necessários, sem depender deles para posicionar o marcador.
- [ ] Completar filtro água + ração, “outros”, status e combinações; permitir ver pontos inativos conforme a regra de produto.
- [ ] Completar o fluxo dos animais: novos avistamentos, edição/arquivamento, possível identificação de duplicados e datas confiáveis.
- [ ] Substituir o agrupamento fixo por dados reais de concentração retornados pela API e mostrar as regiões no mapa.
- [ ] Implementar push no celular, registro de token, preferências persistidas, abertura do ponto ao tocar no aviso e tratamento de permissões.
- [ ] Tratar GPS negado, desligado ou impreciso; permitir escolher outra região manualmente sem depender do GPS.

### 4. Preparar qualidade, segurança e publicação

- [ ] Testar API, permissões e consultas espaciais com casos reais, inclusive fronteiras de município e falta simultânea de recursos.
- [ ] Testar integração Flutter–API para login, expiração/renovação, cadastro, foto, filtros, histórico e erros de rede.
- [ ] Testar em aparelhos Android e iOS, diferentes tamanhos de tela, acessibilidade e conexão lenta/intermitente.
- [ ] Definir cache e comportamento offline; mostrar quando os dados estiverem antigos e evitar registrar ações sem confirmação do servidor.
- [ ] Revisar privacidade de localização e imagens; remover metadados sensíveis de fotos quando necessário e oferecer exclusão de dados.
- [ ] Configurar logs, monitoramento, backup, migrações e restauração do banco.
- [ ] Preparar ícones, nome, telas de abertura, textos de permissões, política de privacidade e publicação nas lojas.
- [ ] Verificar limites e atribuições do provedor de mapa escolhido; testar o consumo previsto antes do lançamento.
- [ ] Criar ambiente de homologação, pipeline de build/testes e procedimento de deploy e reversão.

## Critério para considerar o MVP concluído

O primeiro lançamento com dados reais estará pronto quando um usuário puder criar conta ou entrar, abrir o mapa na região escolhida, consultar pontos por proximidade e recurso, cadastrar ponto/animal com foto, registrar manutenção, acompanhar pontos e receber avisos conforme preferências. Essas ações precisam sobreviver ao reinício do app, respeitar as permissões do usuário e funcionar com os endpoints e o banco C#. O fluxo deve ser testado em Android e iOS; a política de tiles, fotos e push deve ser compatível com o uso previsto.
