# API RedePatas

Requer .NET 10 e PostgreSQL. A conexão fica em `ConnectionStrings:Postgres` e pode ser substituída pela variável de ambiente `ConnectionStrings__Postgres`. Use segredos locais para credenciais fora do ambiente de estudo.

## Criar as tabelas e executar

Na pasta deste arquivo:

```powershell
dotnet run --project rede-patas-backend -- --migrate
dotnet run --project rede-patas-backend
```

O primeiro comando aplica as migrações de autenticação e de pontos e encerra. A inicialização normal não altera o esquema.

No frontend, configure a URL exibida pela API:

```powershell
flutter run --dart-define=API_BASE_URL=https://localhost:PORTA
```

Em celular/emulador use o endereço do computador acessível pelo dispositivo e um certificado confiável; `localhost` no celular se refere ao próprio aparelho.

## Cadastro e autenticação

`POST /api/auth/register` recebe `name`, `email` e `password`. Nome: 2–150 caracteres; e-mail: até 254; senha: 8–128. Nome e e-mail são aparados, e o e-mail é convertido para minúsculas. O banco garante sua unicidade. UUID, status `ativo` e data UTC são gerados no servidor. Senhas são armazenadas com `PasswordHasher` do ASP.NET Core Identity, apenas em `senha_hash`.

Cadastro retorna 201 com `user: { id, name, email }`, `accessToken`, `refreshToken` e `expiresAt`. E-mail duplicado retorna 409 e dados inválidos retornam 400. O app inicia a sessão ao receber o cadastro.

`POST /api/auth/login`, `GET /api/auth/me`, `POST /api/auth/refresh` e `POST /api/auth/logout` seguem o contrato do frontend. O token de acesso usa o Bearer Token do ASP.NET Core (opaco e protegido, duração de 15 minutos). O token de renovação expira em 30 dias, é salvo somente como hash, é rotacionado atomicamente e é revogado no logout. O token de acesso já emitido permanece válido até expirar. Preserve as chaves do ASP.NET Core Data Protection entre reinicializações e compartilhe-as caso execute múltiplas instâncias.

## Cadastro de pontos

`POST /api/pontos` exige o token Bearer e recebe JSON com `name`, `description`, `latitude`, `longitude`, `address`, `schedule`, `maintainer`, `animalCount`, `resources` (lista de `water`, `food`, `shelter`, `other`) e `photoBase64` opcional. O servidor valida os campos, usa o ID do usuário autenticado como autor e grava o ponto e seus recursos juntos. A foto opcional é limitada a 5 MB, recebe nome gerado no servidor e é servida em `/uploads/pontos/`. `GET /api/pontos` carrega os 500 pontos mais recentes. No app, o modo API usa esses endpoints para cadastrar e carregar pontos; animais continuam demonstrativos. Situação, histórico e acompanhamento estão integrados aos endpoints abaixo.

Execute novamente `--migrate` antes de iniciar a API após atualizar o código.

## Verificação

```powershell
dotnet build
dotnet run --project rede-patas-backend.Tests
```

O teste de integração usa PostgreSQL e cria um banco temporário com nome aleatório `redepatas_test_*`, removido ao terminar. A conta de banco precisa de permissão para criar bancos. A conexão de teste pode ser definida em `REDEPATAS_TEST_POSTGRES`; por padrão, usa a configuração de desenvolvimento. Verifica a migração, os campos persistidos, hashes, duplicidade, cadastro, login, autenticação, renovação e logout.

## Manutenção e acompanhamento

Todos os endpoints abaixo exigem usuário autenticado e ativo:

| Método | Rota | Comportamento |
| --- | --- | --- |
| GET | `/api/me/followed-points` | IDs acompanhados somente pelo usuário atual |
| PUT / DELETE | `/api/me/followed-points/{id}` | Seguir/deixar de seguir, de forma idempotente |
| GET | `/api/manutencoes` | Últimos 500 eventos, com nome do autor e data UTC |
| POST | `/api/pontos/{id}/maintenance` | Recebe `status`: `supplied`, `attention`, `needsWater` ou `needsFood` |

Qualquer usuário ativo pode registrar manutenção. O servidor define o texto da ação, o autor e a data; situação, recursos e evento são gravados atomicamente. Falta de água/ração só pode ser registrada quando o recurso existe. Inativação não faz parte desta operação. A migração `202611060001_ParticipacaoPontos` adiciona as duas tabelas necessárias.

O limite padrão continua em 20 requisições por minuto, compartilhado pela política atual. `RateLimiting__PermitLimit` permite configurar esse limite; os testes usam 200 para validar os fluxos sem esgotar a janela.
