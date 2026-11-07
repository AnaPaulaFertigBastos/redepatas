# RedePatas: estado atual e plano de conclusão

Atualizado em 6 de novembro de 2026. Prioridade definida: entrega da disciplina. Qualquer usuário autenticado e ativo pode registrar manutenção. Nenhum commit foi realizado nesta etapa.

## O que já existe

- Flutter com mapa, GPS, filtros individuais, cadastro, detalhes, comunidade e alertas dentro do aplicativo.
- API ASP.NET Core e PostgreSQL com migrações, cadastro de conta, login, sessão persistida, renovação e logout.
- Cadastro e leitura de pontos reais, recursos e foto opcional. O servidor atribui autor e data.
- Acompanhamento persistido por usuário, com operações idempotentes de seguir/deixar de seguir e isolamento entre contas.
- Manutenção por usuário autenticado: abastecido/verificado, atenção, falta de água ou ração. Situação, recursos e histórico são gravados em uma transação; o histórico identifica o autor real e usa o horário do servidor.
- Flutter lê situação e histórico da API, recupera acompanhamentos após login e limpa os dados de pontos/histórico ao sair ou trocar de conta. Falha de carregamento oferece nova tentativa.
- Recebimento de push preparado no cliente; ainda depende da configuração Firebase e dos endpoints no backend.

Sem `API_BASE_URL`, o aplicativo continua em demonstração. Com API, pontos, manutenção e acompanhamentos são reais; **animais ainda usam dados demonstrativos e cadastros em memória**. As preferências de alerta também ficam em memória.

## Plano de execução priorizado

| Ordem | Entrega | Critério de conclusão | Situação |
| --- | --- | --- | --- |
| 1 | Persistir acompanhamento | Seguir, reiniciar e recuperar; outra conta não vê nem remove o vínculo | Implementado nesta etapa |
| 2 | Persistir manutenção e histórico | Usuário diferente do criador registra ação; servidor salva autor, data e situação atomicamente | Implementado nesta etapa |
| 3 | Persistir animais e fotos | Cadastro e consulta na API, migração, cliente Flutter e teste de recarga sem mocks | Pendente |
| 4 | Completar filtros | Água + ração, outros e situação; filtros combináveis e estado vazio claro | Pendente |
| 5 | Persistir preferências de alerta | Raio e opções recuperados por conta após reinício | Pendente |
| 6 | Concluir notificações | Registrar/remover aparelho, configurar Firebase, enviar aviso e abrir o ponto ao tocar | Pendente; requer projeto Firebase |
| 7 | Validar entrega em aparelho | Cadastro, login, ponto com foto, manutenção, acompanhamento, animal e erro de rede em Android | Pendente |
| 8 | Preparar apresentação | Roteiro reproduzível, instruções de execução e documentação coerente com o que foi entregue | Plano atualizado; apresentação pendente |

A próxima implementação deve ser a persistência dos animais, aproveitando os campos e a interface existentes. Depois, concluir filtros e preferências. Não apresentar push como funcional até validar o envio real. Se houver requisitos específicos da avaliação, confrontá-los com esta lista antes de encerrar a entrega.

## Limites que continuam visíveis

- A listagem de pontos e de histórico retorna no máximo 500 itens; não há paginação nem consulta espacial no servidor.
- A situação geral representa uma única classificação. Os recursos têm situação própria, mas a tela ainda não representa falta simultânea de água e ração em separado.
- Inativação, edição, exclusão e moderação precisam de regras próprias; manutenção não permite inativar um ponto.
- Animais e concentração regional continuam ilustrativos. Não existe análise geográfica real.
- Fotos são arquivos locais do servidor. Miniaturas, processamento completo e armazenamento externo estão pendentes.
- Há tratamento de erro com nova tentativa, mas ainda faltam estados de carregamento/vazio mais completos e uma política offline.
- Não foi feita validação visual em aparelho nesta etapa.

## Executar e verificar

Na pasta `backend/rede-patas-backend`:

```powershell
dotnet run --project rede-patas-backend -- --migrate
dotnet run --project rede-patas-backend
```

A migração `202611060001_ParticipacaoPontos` adiciona acompanhamento e manutenção, sem substituir os pontos existentes. Ela precisa ser aplicada no banco usado pelo app. Os testes aplicam migrações em um banco temporário isolado; não equivalem a atualizar o banco de desenvolvimento.

Na pasta `frontend`:

```powershell
flutter run --dart-define=API_BASE_URL=https://ENDERECO-DA-API
flutter analyze
flutter test
```

A URL precisa ser alcançável pelo celular/emulador. Para demonstração sem API, omita a variável e use a conta de demonstração.

Os testes do backend ficam em `rede-patas-backend.Tests`: executam migrações em banco temporário, verificam autenticação, cadastro, fotos, acompanhamento privado/idempotente e manutenção por outro usuário. A conexão de teste e as instruções estão no README do backend.

## Verificação desta etapa

- Análise Flutter sem apontamentos e nove testes aprovados.
- Compilação do backend sem avisos/erros e 36 verificações de integração aprovadas em PostgreSQL temporário, incluindo migração, isolamento entre contas e manutenção por outro usuário.
- O banco de desenvolvimento não foi migrado nesta etapa; execute `--migrate` antes de usar os novos endpoints.

## Depois da entrega acadêmica

Para uso público: consultas espaciais e paginação, política de moderação e exclusão, tratamento e retenção de fotos/localização, recuperação de senha, configuração de CORS e limites por usuário, HTTPS, backup/restauração, logs/monitoramento, hospedagem, provedor de tiles adequado, testes de carga e validação Android/iOS. Essas entregas não estão concluídas nem são substituídas pelos testes locais.
