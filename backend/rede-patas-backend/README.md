# API RedePatas

Requer .NET 10 e PostgreSQL. A conexão fica em `ConnectionStrings:Postgres` e pode ser substituída pela variável de ambiente `ConnectionStrings__Postgres`. Use segredos locais para credenciais fora do ambiente de estudo.

## Criar as tabelas e executar

Na pasta deste arquivo:

```powershell
dotnet run --project rede-patas-backend -- --migrate
dotnet run --project rede-patas-backend
```

O primeiro comando aplica a migração de `usuario` e `token_renovacao` e encerra. As demais entidades do modelo lógico ainda não foram implementadas. A inicialização normal não altera o esquema.

No frontend, configure a URL exibida pela API:

```powershell
flutter run --dart-define=API_BASE_URL=https://localhost:PORTA
```

Em celular/emulador use o endereço do computador acessível pelo dispositivo e um certificado confiável; `localhost` no celular se refere ao próprio aparelho.

## Cadastro e autenticação

`POST /api/auth/register` recebe `name`, `email` e `password`. Nome: 2–150 caracteres; e-mail: até 254; senha: 8–128. Nome e e-mail são aparados, e o e-mail é convertido para minúsculas. O banco garante sua unicidade. UUID, status `ativo` e data UTC são gerados no servidor. Senhas são armazenadas com `PasswordHasher` do ASP.NET Core Identity, apenas em `senha_hash`.

Cadastro retorna 201 com `user: { id, name, email }`, `accessToken`, `refreshToken` e `expiresAt`. E-mail duplicado retorna 409 e dados inválidos retornam 400. O app inicia a sessão ao receber o cadastro.

`POST /api/auth/login`, `GET /api/auth/me`, `POST /api/auth/refresh` e `POST /api/auth/logout` seguem o contrato do frontend. O token de acesso usa o Bearer Token do ASP.NET Core (opaco e protegido, duração de 15 minutos). O token de renovação expira em 30 dias, é salvo somente como hash, é rotacionado atomicamente e é revogado no logout. O token de acesso já emitido permanece válido até expirar. Preserve as chaves do ASP.NET Core Data Protection entre reinicializações e compartilhe-as caso execute múltiplas instâncias.

## Verificação

```powershell
dotnet build
dotnet run --project rede-patas-backend.Tests
```

O teste de integração usa PostgreSQL e cria um banco temporário com nome aleatório `redepatas_test_*`, removido ao terminar. A conta de banco precisa de permissão para criar bancos. A conexão de teste pode ser definida em `REDEPATAS_TEST_POSTGRES`; por padrão, usa a configuração de desenvolvimento. Verifica a migração, os campos persistidos, hashes, duplicidade, cadastro, login, autenticação, renovação e logout.
