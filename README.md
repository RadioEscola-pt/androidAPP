# Escola de Rádio Amador — Android

Aplicação de estudo para o exame de radioamador (ANACOM) e companheira móvel
do [radioescola.pt](https://radioescola.pt).

Permite praticar as três categorias, fazer um exame simulado cronometrado com
as regras reais e rever a matéria com repetição espaçada. O progresso é
guardado no mesmo formato que o site usa, para poder passar de um para o outro.

## Repositório

- **`flutter_app/`** — a aplicação Flutter. É aqui que decorre o
  desenvolvimento.
- **`app/`** — a aplicação Android nativa original, publicada na Play Store.
  Descontinuada; a versão Flutter veio substituí-la.

## Como começar

É preciso o [SDK do Flutter](https://docs.flutter.dev/get-started/install)
(3.11 ou superior).

```bash
cd flutter_app
flutter pub get
flutter run
```

## Desenvolvimento

```bash
flutter test       # correr os testes
flutter analyze    # correr o linter
flutter build apk  # compilar para Android
```

## Banco de perguntas

As perguntas e as imagens em `flutter_app/assets/` são geradas a partir do
repositório do site, para nunca divergirem do que o radioescola.pt mostra. Não
edites estes ficheiros à mão.

Para as atualizar, a partir do repositório do site:

```bash
bun run content:build --mobile=/caminho/para/radioescola-android/flutter_app
```

O comando recompila as perguntas, inclui as explicações — que no site são
servidas à parte — e copia as imagens que elas referem. Para mudar uma
pergunta, altera-a em `content/questions/` no site e volta a correr o comando.

Para confirmar que o que está aqui está atualizado, sem escrever nada:

```bash
bun run content:check --mobile=/caminho/para/radioescola-android/flutter_app
```

Notas para quem contribui, incluindo a assinatura das versões, em
[CLAUDE.md](CLAUDE.md).
