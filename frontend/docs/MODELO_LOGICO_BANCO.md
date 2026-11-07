# Modelo lógico do banco de dados — RedePatas

O diagrama editável está em [`modelo_logico_redepatas.mmd`](modelo_logico_redepatas.mmd) (Mermaid, edição por texto) e [`modelo_logico_redepatas.drawio`](modelo_logico_redepatas.drawio) (diagrams.net, edição visual). Ambos representam o mesmo modelo do backend C#. Este documento é a especificação do modelo; a implementação atual cobre as tabelas de usuário e renovação de sessão.

## Como editar

**Implementação parcial:** o backend C# implementa `USUARIO`, `TOKEN_RENOVACAO`, `PONTO_APOIO`, `RECURSO`, `PONTO_RECURSO` e fotos vinculadas a pontos, com migrações PostgreSQL. Cadastro e consulta de pontos estão disponíveis; as outras entidades continuam propostas. Veja [como aplicar as migrações](../../backend/rede-patas-backend/README.md).

- Abra o `.drawio` em [diagrams.net](https://app.diagrams.net/), mova caixas e conexões e salve o próprio arquivo. Cada entidade e ligação é um objeto editável.
- Edite o `.mmd` em qualquer editor de texto com visualização Mermaid. Ao mudar o modelo, atualize também a outra versão do diagrama e este documento.
- `PK` é chave primária, `FK` é chave estrangeira e `UK` é chave única. Nas tabelas de associação, as duas colunas marcadas `PK, FK` compõem uma chave primária conjunta.

## Decisões de localização e cidade

**Latitude e longitude são a localização principal.** `PONTO_APOIO` e `AVISTAMENTO` guardam as coordenadas em WGS84, com precisão sugerida `numeric(9,6)`. Latitude aceita de -90 a 90 e longitude de -180 a 180. A coordenada do avistamento pertence ao evento, pois um animal pode mudar de lugar; o cadastro `ANIMAL` guarda sua identidade e descrição, não uma localização fixa.

**O município é uma classificação derivada.** `MUNICIPIO.codigo_ibge` usa o código oficial de sete dígitos. `PONTO_APOIO.municipio_codigo_ibge` e `AVISTAMENTO.municipio_codigo_ibge` são FKs opcionais: podem ficar nulas quando a coordenada ainda não foi classificada. O estado vem de `MUNICIPIO.uf_sigla -> UF.sigla`; não precisa ser duplicado no ponto. Use código IBGE na API (`municipioCodigoIbge`), pois nomes de cidades podem se repetir.

No cadastro ou na alteração da posição, o backend deve determinar o município a partir da latitude/longitude usando limites municipais importados para o banco. Na implementação PostgreSQL/PostGIS, acrescente ao modelo físico `MUNICIPIO.limite geometry(MultiPolygon, 4326)` e `PONTO_APOIO.localizacao geography(Point, 4326)` (idem para `AVISTAMENTO`), como colunas derivadas ou mantidas pelo serviço. Para construir o ponto, a ordem é **longitude, latitude**: `ST_MakePoint(longitude, latitude)`. Busque o polígono com `ST_Covers(limite, ponto)`, que também considera a borda. Em divisas com mais de um resultado, aplique uma regra determinística e sinalize o caso para revisão; sem resultado, deixe a FK nula. Recalcule a classificação sempre que as coordenadas mudarem. Isso evita chamar um serviço externo de geocodificação para cada busca.

O filtro por cidade é uma comparação simples e indexável:

```sql
SELECT p.*
FROM ponto_apoio AS p
WHERE p.municipio_codigo_ibge = :codigo_ibge
  AND p.situacao_geral <> 'inativo';
```

Para o filtro por estado, faça `JOIN municipio m ON m.codigo_ibge = p.municipio_codigo_ibge` e filtre `m.uf_sigla`. Para pontos próximos, use `ST_DWithin(p.localizacao, ST_SetSRID(ST_MakePoint(:longitude, :latitude), 4326)::geography, :raio_metros)`. A mesma consulta pode combinar município, raio, situação e recurso; o backend deve paginar os resultados.

Índices iniciais: B-tree em `ponto_apoio(municipio_codigo_ibge, situacao_geral)`, `avistamento(municipio_codigo_ibge, visto_em)`, `municipio(uf_sigla)` e `ponto_recurso(recurso_codigo, situacao)`; GiST em `ponto_apoio(localizacao)` e `avistamento(localizacao)`. A necessidade de índices adicionais deve ser avaliada com consultas reais.

## Regras das entidades

| Entidade | Papel e regras principais |
| --- | --- |
| `UF`, `MUNICIPIO` | Catálogo administrativo. `codigo_ibge` é texto de 7 caracteres para preservar o identificador, não um número usado em cálculos. O limite geográfico é detalhe físico do banco. |
| `USUARIO`, `TOKEN_RENOVACAO` | Conta e sessões renováveis. Armazene `senha_hash` e `token_hash`, nunca senha ou refresh token em texto. Access token pode ser JWT e não precisa de tabela. |
| `PONTO_APOIO` | Local fixo de suporte. `situacao_geral` trata estados como ativo, atenção e inativo; os problemas específicos ficam em `PONTO_RECURSO`. `criado_por_usuario_id` identifica o autor. Se houver mantenedor com conta, acrescente `mantenedor_usuario_id` opcional ou uma tabela de responsáveis quando essa regra estiver definida. |
| `RECURSO`, `PONTO_RECURSO` | Catálogo de água, ração, abrigo e outros. A associação permite água **e** ração no mesmo ponto. Sua `situacao` registra, para cada recurso, disponível, precisa repor ou indisponível. |
| `MANUTENCAO` | Histórico imutável das ações: verificação, abastecimento, falta informada e manutenção. `recurso_codigo` pode ser nulo para uma ação geral. A API atualiza `PONTO_RECURSO` e insere `MANUTENCAO` na mesma transação. |
| `ANIMAL`, `AVISTAMENTO` | Um animal pode ter vários avistamentos; um avistamento pode não estar vinculado a um animal identificado. Fotos do animal estão ligadas aos avistamentos, com local e momento. |
| `FOTO` | Guarda apenas URL/chave do arquivo, não os bytes. Exatamente uma entre `ponto_id`, `avistamento_id` e `manutencao_id` deve estar preenchida, com restrição `CHECK` no banco. |
| `PONTO_SEGUIDO` | Relação N:N entre usuário e ponto, com PK conjunta. |
| `PREFERENCIA_ALERTA`, `DISPOSITIVO`, `NOTIFICACAO` | Preferências por usuário, tokens para push e registro dos avisos enviados/lidos. `chave_deduplicacao` evita enviar repetidamente o mesmo alerta. |

## Restrições e próximos passos

1. Criar o projeto ASP.NET Core e migrações do PostgreSQL/PostGIS. Definir enums ou `CHECK` para situações, ações e plataformas; timestamps em UTC; FKs e exclusões apropriadas.
2. Importar o catálogo de UFs e municípios com código IBGE e a malha municipal compatível com o sistema de coordenadas. Registrar a versão/ano da malha; quando ela for atualizada, reclassificar pontos e avistamentos.
3. Implementar a classificação espacial no cadastro e na alteração de coordenadas, e testar divisas municipais, pontos sem município e coordenadas inválidas.
4. Implementar endpoints de consulta por caixa do mapa, município, UF, raio e recurso, com paginação. Definir um formato único de DTO e sincronizar os modelos Flutter.
5. Implementar autenticação, rotação/revogação de refresh tokens, autorização para alterações, validação de fotos e proteção contra abuso.
6. Substituir os repositórios mock do Flutter pela API. Migrar fotos para armazenamento de arquivos e configurar as notificações push com consentimento e preferências.

O modelo distingue **dados persistidos** das regras de produto ainda abertas, como moderação de cadastro, confirmação de relatos e definição de quem pode inativar um ponto. Essas decisões podem acrescentar campos/tabelas quando o backend for construído.
