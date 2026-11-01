# RedePatas

Protótipo Flutter para localizar e manter pontos de água, ração e abrigo para animais em situação de rua. A interface está em português e usa dados fictícios de Curitiba.

O inventário das funcionalidades, a estrutura completa dos arquivos e o plano de trabalho estão em [docs/ESTADO_ATUAL.md](docs/ESTADO_ATUAL.md).
Uma versão para Word está em [docs/RedePatas_documentacao_atual.docx](docs/RedePatas_documentacao_atual.docx).
O modelo lógico do futuro banco está em [docs/MODELO_LOGICO_BANCO.md](docs/MODELO_LOGICO_BANCO.md), com diagramas editáveis em [Mermaid](docs/modelo_logico_redepatas.mmd) e [diagrams.net](docs/modelo_logico_redepatas.drawio).
O [diagrama de arquitetura lógica](docs/arquitetura_logica_redepatas.drawio) mostra o Flutter, a futura API C#, o PostgreSQL/PostGIS e os fluxos de login, mapa, cadastro e manutenção. As duas páginas são editáveis no diagrams.net.

## Executar

```bash
flutter pub get
flutter run
```

Na tela de login, toque em **Entrar com conta de demonstração** ou use `voluntario@redepatas.app` / `123456`. Essa conta existe apenas no mock. O mapa usa internet. Clique no botão de localização para pedir acesso ao GPS; sem permissão, o app inicia na região de demonstração. No mapa, toque nos marcadores para abrir os detalhes. O botão **Adicionar** registra pontos ou animais. Esses registros ficam em memória e desaparecem ao reiniciar o aplicativo; a sessão de login é salva separadamente.

## Login e sessão

Na tela de acesso, **Registre-se** abre o formulário de nome, e-mail, senha e confirmação de senha. Com `API_BASE_URL` configurada, o cadastro é salvo na tabela `usuario` e inicia a sessão automaticamente. Sem API, o modo de demonstração informa que o cadastro real exige conexão. Veja a [configuração do backend e das migrações](../backend/rede-patas-backend/README.md).

- `lib/auth/auth_controller.dart` é a fonte de verdade do estado de autenticação para o frontend. Ao abrir o app, ele restaura a sessão antes de escolher entre login e mapa. Após entrar, mantém o usuário em memória e avisa as telas; ao sair, apaga a sessão e volta ao login.
- `lib/auth/session_store.dart` salva o JSON da sessão com `flutter_secure_storage` (armazenamento protegido no Android/iOS). Guarda identificação do usuário, token de acesso, token de renovação e expiração. **A senha nunca é salva.**
- `lib/auth/auth_service.dart` é a implementação mock. Ela aceita apenas a conta de demonstração e gera tokens fictícios que expiram em sete dias. Isso controla a navegação, mas não autentica um usuário real.
- `lib/auth/api_auth_service.dart` já implementa o contrato HTTP de login, validação da sessão, renovação e logout. Para ativá-lo, execute `flutter run --dart-define=API_BASE_URL=https://seu-servidor`. Sem essa variável, o app usa o mock. Os dados de pontos e animais continuam mockados até conectar `RedePatasRepository` à API.
- Se o token de acesso vencer, o controlador chama `restore()`: no modo API, o serviço tenta renovar a sessão; se a renovação for rejeitada, remove os tokens e apresenta o login. O backend continua sendo a autoridade: cada endpoint protegido deve validar o token, independentemente do que a interface mostra.

Contrato esperado do backend:

| Método | Rota | Corpo/resposta |
| --- | --- | --- |
| POST | `/api/auth/register` | Recebe `name`, `email`, `password`; cria usuário e devolve sessão (201); e-mail duplicado (409) |
| POST | `/api/auth/login` | Recebe `email`, `password`; devolve usuário e tokens |
| GET | `/api/auth/me` | Valida `Authorization: Bearer <accessToken>`; responde 200 ou 401 |
| POST | `/api/auth/refresh` | Recebe `refreshToken`; devolve novos tokens (rotação) ou 401 |
| POST | `/api/auth/logout` | Revoga o `refreshToken` recebido |

Formato de resposta esperado em `login` e `refresh`:

```json
{
  "user": { "id": "u1", "name": "Ana", "email": "ana@example.com" },
  "accessToken": "...",
  "refreshToken": "...",
  "expiresAt": "2026-10-14T18:00:00Z"
}
```

Na API ASP.NET Core, use senha com hash (por exemplo, ASP.NET Core Identity), access token de curta duração e refresh token revogável e rotativo. As demais chamadas autenticadas deverão enviar o access token no cabeçalho `Authorization`; o futuro repositório HTTP dos pontos deve tratar um 401 renovando e repetindo a requisição uma vez. Em Flutter Web, o armazenamento do plugin requer HTTPS ou localhost; para produção web, avalie uma sessão com cookie HttpOnly no backend. O app atual foi desenhado principalmente para celular.

## Organização

| Caminho | Função |
| --- | --- |
| `lib/domain/models.dart` | Modelos de ponto, animal, recurso, status e manutenção |
| `lib/data/mock/` | Dados fictícios separados por assunto |
| `lib/data/repository.dart` | Contrato de dados e implementação mock em memória |
| `lib/data/map_config.dart` | Endereço dos tiles e identificação do aplicativo |
| `lib/auth/` | Login, sessão, armazenamento protegido e cliente HTTP de autenticação |
| `lib/ui/` | Mapa, listas, cadastro, detalhes, alertas e histórico |

Para conectar a API C#, implemente `RedePatasRepository` com chamadas HTTP e substitua `MockRedePatasRepository` em `lib/app/redepatas_app.dart`. Mantenha os modelos e as telas. A implementação atual usa `ChangeNotifier`; após cada resposta da API, atualize o estado e chame `notifyListeners()`.

## Contrato sugerido para a API ASP.NET Core

| Método | Rota | Objetivo |
| --- | --- | --- |
| GET | `/api/points?minLat=&minLon=&maxLat=&maxLon=&resource=&status=` | Pontos na área visível, com filtros |
| POST | `/api/points` | Criar ponto com coordenadas, recursos e dados básicos |
| GET | `/api/points/{id}/maintenance` | Histórico de manutenção |
| POST | `/api/points/{id}/maintenance` | Registrar verificação, abastecimento ou falta de recurso; atualizar o status na mesma transação |
| GET | `/api/animals?minLat=&minLon=&maxLat=&maxLon=` | Animais na área visível |
| POST | `/api/animals` | Registrar avistamento e localização |
| POST | `/api/uploads` | Enviar foto e receber URL/ID de mídia |
| GET/PUT | `/api/me/alert-preferences` | Raio e tipos de aviso do usuário |
| POST/DELETE | `/api/me/followed-points/{id}` | Acompanhar ou deixar de acompanhar um ponto |

Use `latitude` e `longitude` numéricas (WGS84) como dados centrais de localização. No banco PostgreSQL com PostGIS, uma coluna espacial `geography(Point, 4326)` com índice GiST permite busca por raio e caixa do mapa. Se o curso exigir SQL Server, use `geography` e índice espacial. O servidor deve calcular distância e filtrar pontos em uma área; evitar baixar todos os pontos para o celular quando a base crescer.

**Cidade e estado:** o modelo lógico armazena `municipio_codigo_ibge` opcional no ponto e no avistamento; a UF é obtida por `MUNICIPIO -> UF`. As coordenadas continuam sendo a fonte da localização. No cadastro ou na alteração de posição, o backend pode classificar as coordenadas usando limites municipais carregados no banco. O filtro por cidade usa o código IBGE indexado, sem consultar geocodificação a cada busca. Veja as regras, consultas e casos de divisa em [docs/MODELO_LOGICO_BANCO.md](docs/MODELO_LOGICO_BANCO.md).

Status e histórico devem ser entidades separadas. Cada ação deve guardar `pointId`, `action`, `authorId`, `createdAt` e, se necessário, a foto da visita. Recomenda-se autenticação e moderação para impedir cadastros falsos, spam e mudanças de status abusivas. Fotos exigem armazenamento separado do banco (arquivo/objeto) e política de privacidade; no protótipo, fotos recém-escolhidas ficam apenas na memória.

## Mapa e notificações sem custo obrigatório

O app usa `flutter_map` com dados do OpenStreetMap e tiles do servidor público do OSM para demonstração. A biblioteca e os dados são livres, mas o servidor público tem [política de uso](https://operations.osmfoundation.org/policies/tiles/): identificação do aplicativo, atribuição, cache e limites de uso. Antes de lançar para muitos usuários, configure em `map_config.dart` um serviço de tiles com plano gratuito suficiente para o tráfego ou hospede os próprios tiles. Não há garantia de serviço gratuito ilimitado. A atribuição ao OpenStreetMap aparece no mapa.

Os alertas atuais são calculados dentro do aplicativo a partir do raio e dos pontos acompanhados. O recebimento de push pelo Firebase Cloud Messaging já está integrado no Android/iOS: veja a [configuração e o contrato da API](docs/NOTIFICACOES_FIREBASE.md). Para ativar, conecte o projeto Firebase e implemente no backend o cadastro de aparelhos e o envio. Raio e preferências também terão de ser persistidos pela API; o protótipo os guarda apenas durante a sessão.

## Limites do protótipo

- Os dados iniciais e as regiões de avistamento são ilustrativos.
- O login mock não valida usuários reais; cadastro e autenticação reais exigem a API C# e a migração do PostgreSQL.
- Os pontos e as preferências não são persistidos; o envio de push depende de projeto Firebase configurado e backend, ainda ausentes.
- Fotos mockadas são URLs externas de demonstração; fotos adicionadas ficam na memória.
- O filtro de proximidade e a distância são calculados no aparelho para o conjunto pequeno de mocks.
