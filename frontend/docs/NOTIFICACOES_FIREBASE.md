# Notificações Firebase — configuração e contrato

O Flutter já integra Firebase Core e Firebase Cloud Messaging em Android/iOS.
Sem configuração válida, o app abre normalmente e informa que os avisos não
estão configurados. Web e desktop continuam sem push.

## Conectar o projeto

1. Crie/selecione seu projeto no console Firebase.
2. Cadastre o app Android com o pacote `br.com.redepatas.redepatas`.
3. Baixe `google-services.json` e coloque em `android/app/google-services.json`.
   O Gradle aplica o plugin Google Services quando esse arquivo está presente.
4. Para iOS, cadastre o bundle ID real do Runner e adicione
   `GoogleService-Info.plist` ao target Runner pelo Xcode. Ative **Push
   Notifications** e **Background Modes → Remote notifications**. Envie a chave
   APNs em Firebase → Configurações → Cloud Messaging. Essa etapa exige macOS/Xcode.
5. Execute `flutter run --dart-define=API_BASE_URL=https://sua-api`.
6. Entre e vá em **Alertas → Ativar notificações no celular**.

Não é necessário mudar o login para Firebase Auth nem o banco para Firestore.
O app usa a configuração nativa, com `Firebase.initializeApp()` sem opções Dart.
Se usar FlutterFire CLI, preserve essa configuração nativa ou ajuste a inicialização
para as opções geradas. Nunca inclua credenciais de conta de serviço no aplicativo.

## Contrato que a API precisa implementar

`PUT /api/me/push-devices` e `DELETE /api/me/push-devices`, ambos autenticados
com `Authorization: Bearer <accessToken>` e corpo JSON:

```json
{"token":"token-FCM-do-aparelho","platform":"android"}
```

Responda 204 ou outro 2xx. O PUT é idempotente e vincula o token exclusivamente
ao usuário autenticado (obtido do token de acesso, nunca do corpo). Suporte vários
aparelhos por usuário. O DELETE remove somente o vínculo do usuário autenticado.
Trate tokens como dados privados e remova os inválidos quando o FCM os rejeitar.
O app sincroniza após login/restauração/renovação e rotação do token FCM. No logout,
tenta remover o vínculo e invalida o token local, inclusive se a API falhar.
Uma falha de cadastro aparece na tela e o botão permite repetir a tentativa.

O backend ainda não existe neste repositório: cadastrar aparelhos, persistir
preferências, buscar pontos reais e enviar o alerta dependem dessa implementação.
Os filtros atuais de raio e acompanhamento continuam locais e não configuram push.

## Mensagem enviada pelo servidor

Use Firebase Admin SDK no servidor com credenciais protegidas, ou a API HTTP v1.
Exemplo do corpo HTTP v1 (o token OAuth do servidor vai no cabeçalho):

```json
{
  "message": {
    "token": "token-FCM-do-aparelho",
    "notification": {
      "title": "Ponto precisa de atenção",
      "body": "O ponto Praça X está há 4 horas sem registro de abastecimento."
    },
    "data": {"type": "supply_overdue", "pointId": "p1"}
  }
}
```

Envie **notification + data**, não somente data: o sistema exibe o aviso em
segundo plano; o Flutter trata o toque com `onMessageOpenedApp` e
`getInitialMessage`. Em primeiro plano, aparece uma mensagem dentro do app com
**Ver ponto**. Um toque pendente é mantido até o login. Se o ponto não estiver
na lista carregada (atualmente mock), a tela informa isso e abre Alertas.
Não há execução periódica nem timer de quatro horas no celular.

## Regra das quatro horas no servidor

Guarde a data UTC do último abastecimento por ponto e recurso. Um job periódico,
por exemplo a cada cinco minutos, consulta os recursos com mais de quatro horas
sem registro, seleciona responsáveis/seguidores com permissão e envia pelo FCM.
Use uma chave única por ponto, recurso, abastecimento de origem e destinatário
para evitar duplicatas, com fila/outbox e tentativas em caso de falha. Revalide o
abastecimento antes do envio para descartar alertas já resolvidos. Novo
abastecimento reinicia o ciclo. O prazo é aproximado, somando intervalo do job
e entrega; push não garante entrega em horário exato. Sem sensor, não afirme
que a água/ração acabou: só é conhecido o tempo sem registro.

## Teste em aparelho

Com Firebase configurado, API implementada e permissão concedida:

- Confirme o PUT autenticado na API, sem registrar tokens em logs públicos.
- Envie a mensagem acima ao token cadastrado com `pointId` existente.
- Com app aberto, confirme o aviso e a ação **Ver ponto**.
- Em segundo plano e encerrado normalmente, toque no aviso e confirme o ponto.
- Repita sem sessão: o ponto deve abrir depois do login.
- Negue a permissão, teste falha da API e use o botão para repetir.
- Saia da conta e confirme que o token antigo deixa de receber avisos.

Forçar parada nas configurações do Android e restrições do sistema podem impedir
entrega até o app ser reaberto. No iOS, valide APNs em dispositivo compatível.

Referências: https://firebase.google.com/docs/flutter/setup e
https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages.
