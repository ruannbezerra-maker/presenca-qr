import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/models/app_models.dart';
import 'package:flutter_application_1/providers/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('troca de perfil não mantém a sessão anterior', () async {
    final state = AppState();
    await state.initialized;

    expect(state.login('aluno@teste.com'), isTrue);
    expect(state.role, UserRole.aluno);
    expect(state.currentStudent?.name, 'João Silva');

    state.logout();
    expect(state.email, isNull);
    expect(state.role, isNull);

    expect(state.login('professor@teste.com'), isTrue);
    expect(state.role, UserRole.professor);
    expect(state.currentTeacher?.name, 'Maria Souza');
  });

  test(
    'aceita aluno de demonstração e impede presença duplicada ou cruzada',
    () async {
      final state = AppState();
      await state.initialized;
      state.login('aluno@teste.com');
      final student = state.currentStudent!;
      final call = state.startCall('turma-1', 'Matemática');

      expect(
        state.registerAttendance(call.id, studentId: student.id),
        'Presença registrada com sucesso.',
      );
      expect(
        state.registerAttendance(call.id, studentId: student.id),
        'Presença já registrada para esta chamada.',
      );
      expect(
        state.registerAttendance(call.id, studentId: 'aluno-3'),
        'Esta chamada não pertence à turma do aluno.',
      );

      state.endCall(call.id);
      expect(
        state.registerAttendance(call.id, studentId: student.id),
        'Esta chamada foi encerrada.',
      );
    },
  );

  test('cadastros e frequências permanecem após logout e recarga', () async {
    final state = AppState();
    await state.initialized;
    state.login('aluno@teste.com');
    final call = state.startCall('turma-1', 'Matemática');
    state.registerAttendance(call.id, studentId: state.currentStudent!.id);
    state.endCall(call.id);
    state.logout();
    await state.flushPersistence();

    final reloaded = AppState();
    await reloaded.initialized;
    expect(reloaded.calls, hasLength(1));
    expect(reloaded.attendance, hasLength(1));
    expect(reloaded.isLoggedIn, isFalse);
    expect(
      reloaded.students.firstWhere((student) => student.id == 'aluno-1').name,
      'João Silva',
    );
  });

  test('turma não pode ser removida enquanto tiver relações', () async {
    final state = AppState();
    await state.initialized;

    expect(state.removeClass('turma-1'), isFalse);
    state.removeStudent('aluno-1');
    state.removeStudent('aluno-2');
    expect(state.removeClass('turma-1'), isTrue);
  });

  test(
    'e-mails de cadastro são únicos sem distinção entre maiúsculas',
    () async {
      final state = AppState();
      await state.initialized;

      expect(
        state.addStudent(
          AppStudent(
            id: 'aluno-novo',
            name: 'Novo Aluno',
            email: 'novo@teste.com',
            turmaId: 'turma-1',
          ),
        ),
        isTrue,
      );
      expect(
        state.addStudent(
          AppStudent(
            id: 'aluno-duplicado',
            name: 'Duplicado',
            email: 'NOVO@TESTE.COM',
            turmaId: 'turma-1',
          ),
        ),
        isFalse,
      );
    },
  );
}
