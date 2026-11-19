import 'package:flutter/foundation.dart';

import '../models/app_models.dart';
import '../services/app_data_store.dart';

class AppState extends ChangeNotifier {
  AppState({AppDataStore? store})
    : _store = store ?? SharedPreferencesAppDataStore() {
    initialized = _load();
  }

  final AppDataStore _store;
  late final Future<void> initialized;
  Future<void> _pendingPersistence = Future<void>.value();
  UserRole? role;
  String? email;
  final List<AppStudent> students = [];
  final List<AppTeacher> teachers = [];
  final List<AppClass> classes = [];
  final List<AttendanceCall> calls = [];
  final List<AttendanceRecord> attendance = [];

  bool get isLoggedIn => role != null;

  AppStudent? get currentStudent {
    if (email == null) return null;
    for (final student in students) {
      if (student.email.toLowerCase() == email) return student;
    }
    return null;
  }

  AppTeacher? get currentTeacher {
    if (email == null) return null;
    for (final teacher in teachers) {
      if (teacher.email.toLowerCase() == email) return teacher;
    }
    return null;
  }

  String get currentUserName {
    return switch (role) {
      UserRole.aluno => currentStudent?.name ?? email ?? 'Aluno',
      UserRole.professor => currentTeacher?.name ?? email ?? 'Professor',
      UserRole.administrador => 'Administrador',
      null => '',
    };
  }

  AttendanceCall? get activeCall {
    for (final call in calls.reversed) {
      if (call.active) return call;
    }
    return null;
  }

  Future<void> _load() async {
    final snapshot = await _store.load();
    students.addAll(snapshot.students);
    teachers.addAll(snapshot.teachers);
    classes.addAll(snapshot.classes);
    calls.addAll(snapshot.calls);
    attendance.addAll(snapshot.attendance);

    if (classes.isEmpty) {
      classes.addAll([
        AppClass(
          id: 'turma-1',
          name: '2º Ano A',
          subject: 'Matemática',
          teacherId: 'prof-1',
        ),
        AppClass(
          id: 'turma-2',
          name: '2º Ano B',
          subject: 'Português',
          teacherId: 'prof-1',
        ),
        AppClass(
          id: 'turma-3',
          name: '3º Ano A',
          subject: 'História',
          teacherId: 'prof-1',
        ),
      ]);
    }
    if (teachers.isEmpty) {
      teachers.add(
        AppTeacher(
          id: 'prof-1',
          name: 'Maria Souza',
          email: 'professor@teste.com',
        ),
      );
    }
    if (students.isEmpty) {
      students.addAll([
        AppStudent(
          id: 'aluno-1',
          name: 'João Silva',
          email: 'aluno@teste.com',
          turmaId: 'turma-1',
        ),
        AppStudent(
          id: 'aluno-2',
          name: 'Ana Costa',
          email: 'ana@teste.com',
          turmaId: 'turma-1',
        ),
        AppStudent(
          id: 'aluno-3',
          name: 'Lucas Lima',
          email: 'lucas@teste.com',
          turmaId: 'turma-2',
        ),
      ]);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> flushPersistence() => _pendingPersistence;

  Future<void> _persist() {
    final snapshot = AppDataSnapshot(
      students: List.of(students),
      teachers: List.of(teachers),
      classes: List.of(classes),
      calls: List.of(calls),
      attendance: List.of(attendance),
    );
    final write = _pendingPersistence.then((_) async {
      await _store.save(snapshot);
    });
    _pendingPersistence = write;
    return write;
  }

  bool login(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    if (normalized == 'aluno@teste.com') {
      role = UserRole.aluno;
    } else if (normalized == 'professor@teste.com') {
      role = UserRole.professor;
    } else if (normalized == 'admin@teste.com') {
      role = UserRole.administrador;
    } else {
      role = UserRole.aluno;
    }
    email = normalized;
    if (role == UserRole.aluno && currentStudent == null) {
      students.add(
        AppStudent(
          id: 'aluno-${normalized.hashCode.abs()}',
          name: normalized.split('@').first,
          email: normalized,
          turmaId: classes.isNotEmpty ? classes.first.id : '',
        ),
      );
      _persist();
    }
    notifyListeners();
    return true;
  }

  void logout() {
    role = null;
    email = null;
    notifyListeners();
  }

  bool addStudent(AppStudent student) {
    final duplicateEmail = students.any(
      (item) =>
          item.id != student.id &&
          item.email.trim().toLowerCase() == student.email.trim().toLowerCase(),
    );
    if (duplicateEmail) return false;
    final index = students.indexWhere((item) => item.id == student.id);
    if (index >= 0) {
      students[index] = student;
    } else {
      students.add(student);
    }
    _persist();
    notifyListeners();
    return true;
  }

  void removeStudent(String id) {
    students.removeWhere((item) => item.id == id);
    attendance.removeWhere((item) => item.studentId == id);
    _persist();
    notifyListeners();
  }

  bool addTeacher(AppTeacher teacher) {
    final duplicateEmail = teachers.any(
      (item) =>
          item.id != teacher.id &&
          item.email.trim().toLowerCase() == teacher.email.trim().toLowerCase(),
    );
    if (duplicateEmail) return false;
    final index = teachers.indexWhere((item) => item.id == teacher.id);
    if (index >= 0) {
      teachers[index] = teacher;
    } else {
      teachers.add(teacher);
    }
    _persist();
    notifyListeners();
    return true;
  }

  void removeTeacher(String id) {
    teachers.removeWhere((item) => item.id == id);
    for (var index = 0; index < classes.length; index++) {
      final turma = classes[index];
      if (turma.teacherId == id) {
        classes[index] = AppClass(
          id: turma.id,
          name: turma.name,
          subject: turma.subject,
        );
      }
    }
    _persist();
    notifyListeners();
  }

  void addClass(AppClass turma) {
    final index = classes.indexWhere((item) => item.id == turma.id);
    if (index >= 0) {
      classes[index] = turma;
    } else {
      classes.add(turma);
    }
    _persist();
    notifyListeners();
  }

  bool removeClass(String id) {
    if (students.any((student) => student.turmaId == id) ||
        calls.any((call) => call.classId == id)) {
      return false;
    }
    classes.removeWhere((item) => item.id == id);
    _persist();
    notifyListeners();
    return true;
  }

  AttendanceCall startCall(String classId, String subject) {
    if (activeCall != null) endCall(activeCall!.id);
    final call = AttendanceCall(
      id: 'chamada-${DateTime.now().millisecondsSinceEpoch}',
      classId: classId,
      subject: subject,
      startedAt: DateTime.now(),
      teacherId: currentTeacher?.id,
    );
    calls.add(call);
    _persist();
    notifyListeners();
    return call;
  }

  void endCall(String callId) {
    final call = calls.where((item) => item.id == callId).firstOrNull;
    if (call != null) call.active = false;
    _persist();
    notifyListeners();
  }

  String registerAttendance(String callId, {required String studentId}) {
    final call = calls.where((item) => item.id == callId).firstOrNull;
    if (call == null) return 'Chamada não encontrada.';
    if (!call.active) return 'Esta chamada foi encerrada.';
    final student = students.where((item) => item.id == studentId).firstOrNull;
    if (student == null) return 'Aluno não encontrado.';
    if (student.turmaId != call.classId) {
      return 'Esta chamada não pertence à turma do aluno.';
    }
    if (attendance.any(
      (item) => item.callId == callId && item.studentId == studentId,
    )) {
      return 'Presença já registrada para esta chamada.';
    }
    attendance.add(
      AttendanceRecord(
        callId: callId,
        studentId: studentId,
        recordedAt: DateTime.now(),
      ),
    );
    _persist();
    notifyListeners();
    return 'Presença registrada com sucesso.';
  }

  int attendancesForStudent(String studentId) =>
      attendance.where((item) => item.studentId == studentId).length;

  int completedAttendancesForStudent(String studentId) => attendance.where((
    record,
  ) {
    final call = calls.where((item) => item.id == record.callId).firstOrNull;
    return record.studentId == studentId && call != null && !call.active;
  }).length;

  int callsForStudent(String studentId) {
    final student = students.where((item) => item.id == studentId).firstOrNull;
    if (student == null) return 0;
    return calls
        .where((call) => call.classId == student.turmaId && !call.active)
        .length;
  }

  int attendancesForCall(String callId) =>
      attendance.where((item) => item.callId == callId).length;

  List<AppStudent> studentsForClass(String classId) =>
      students.where((student) => student.turmaId == classId).toList();

  List<AttendanceRecord> attendanceForStudent(String studentId) =>
      attendance.where((record) => record.studentId == studentId).toList();

  int absencesForStudent(String studentId) {
    final turma = students
        .where((item) => item.id == studentId)
        .firstOrNull
        ?.turmaId;
    if (turma == null) return 0;
    final missedCalls = calls
        .where(
          (item) =>
              item.classId == turma &&
              !item.active &&
              !attendance.any(
                (record) =>
                    record.callId == item.id && record.studentId == studentId,
              ),
        )
        .length;
    return missedCalls;
  }

  int absencesForCall(String callId) {
    final call = calls.where((item) => item.id == callId).firstOrNull;
    if (call == null) return 0;
    final enrolled = studentsForClass(call.classId).length;
    return (enrolled - attendancesForCall(callId)).clamp(0, enrolled);
  }
}
