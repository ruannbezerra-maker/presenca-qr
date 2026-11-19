# Presença QR

Aplicativo Flutter demonstrativo para chamadas escolares com QR Code. Os cadastros, turmas, chamadas e frequências ficam no armazenamento local do dispositivo. O login de demonstração não valida credenciais reais e nunca salva a senha digitada.

## Executar

```shell
flutter pub get
flutter run
```

## Acessos de demonstração

Digite qualquer senha com um dos e-mails abaixo:

| E-mail | Perfil |
| --- | --- |
| `aluno@teste.com` | Aluno |
| `professor@teste.com` | Professor |
| `admin@teste.com` | Administrador |

Qualquer outro e-mail abre um perfil de aluno de demonstração. Para trocar de perfil, use **Configurações / Perfil → Sair da conta** e entre novamente; os dados locais permanecem salvos.

## Câmera e QR Code

No Android e iOS, autorize o acesso à câmera quando solicitado. O Android declara a permissão de câmera no manifesto e o iOS apresenta a justificativa de uso.

No navegador, a câmera depende de um contexto seguro (**HTTPS** ou `localhost`) e da permissão concedida nas configurações do navegador. Ambientes de preview embutidos no VS Code podem não encaminhar uma câmera; nesse caso, teste no navegador externo ou em um dispositivo com câmera. O leitor mostra uma alternativa de seleção de imagem em plataformas móveis compatíveis. Se não houver câmera, a tela continua utilizável e explica o motivo.

## Estrutura e integração futura

- `lib/models`: entidades e relações entre alunos, professores, turmas, chamadas e frequências.
- `lib/providers`: sessão e estado de apresentação.
- `lib/screens` e `lib/widgets`: telas e componentes Flutter.
- `lib/services/app_data_store.dart`: contrato de persistência e implementação local com `SharedPreferences`.

O serviço de armazenamento é separado do estado da interface para permitir uma futura implementação baseada em Firebase Authentication e Cloud Firestore. Firebase ainda não está configurado; o login livre é apenas demonstração e não oferece segurança de autenticação.
