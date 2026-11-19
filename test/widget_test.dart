import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/providers/app_state.dart';
import 'package:flutter_application_1/screens/login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login mostra somente e-mail, senha e recuperação', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Esqueci minha senha'), findsOneWidget);
    expect(find.text('ENTRAR'), findsOneWidget);
    expect(find.text('Matrícula escolar'), findsNothing);
  });

  testWidgets('os três perfis navegam e encerram sessão nos tamanhos-alvo', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    const sizes = [
      Size(360, 800),
      Size(375, 812),
      Size(390, 844),
      Size(430, 932),
      Size(1366, 768),
    ];
    const accounts = [
      (
        'aluno@teste.com',
        'Olá, João Silva!',
        ['Início', 'Frequência', 'Ler QR', 'Config'],
      ),
      (
        'professor@teste.com',
        'Painel do professor',
        ['Turmas', 'Chamada', 'Histórico', 'Relatórios', 'Perfil'],
      ),
      (
        'admin@teste.com',
        'Painel administrativo',
        ['Alunos', 'Professores', 'Turmas', 'Relatórios', 'Config'],
      ),
    ];
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    for (final size in sizes) {
      tester.view.physicalSize = size;
      for (final (email, expectedTitle, destinations) in accounts) {
        await tester.enterText(find.byType(TextField).first, email);
        await tester.enterText(find.byType(TextField).at(1), 'senha-demo');
        await tester.tap(find.text('ENTRAR'));
        await tester.pumpAndSettle();
        expect(find.text(expectedTitle), findsOneWidget);

        for (final destination in destinations) {
          await tester.tap(find.byKey(ValueKey('navigation-$destination')));
          if (destination == 'Ler QR') {
            await tester.pump(const Duration(milliseconds: 500));
          } else {
            await tester.pumpAndSettle();
          }
          expect(
            tester.takeException(),
            isNull,
            reason: '$size • $email • $destination',
          );
        }

        await tester.tap(find.byIcon(Icons.account_circle_outlined));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sair da conta'));
        await tester.pumpAndSettle();
        expect(find.text('E-mail'), findsOneWidget);
      }
    }
  });

  testWidgets('login e cadastro continuam utilizáveis com teclado aberto', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'admin@teste.com');
    await tester.enterText(find.byType(TextField).at(1), 'senha-demo');
    await tester.ensureVisible(find.text('ENTRAR'));
    await tester.tap(find.text('ENTRAR'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('navigation-Alunos')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Aluno de teste');
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
