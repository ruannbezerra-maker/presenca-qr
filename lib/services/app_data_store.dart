import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_models.dart';

class AppDataSnapshot {
  const AppDataSnapshot({
    required this.students,
    required this.teachers,
    required this.classes,
    required this.calls,
    required this.attendance,
  });

  final List<AppStudent> students;
  final List<AppTeacher> teachers;
  final List<AppClass> classes;
  final List<AttendanceCall> calls;
  final List<AttendanceRecord> attendance;
}

abstract interface class AppDataStore {
  Future<AppDataSnapshot> load();
  Future<void> save(AppDataSnapshot snapshot);
}

class SharedPreferencesAppDataStore implements AppDataStore {
  @override
  Future<AppDataSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppDataSnapshot(
      students: _readList(prefs.getStringList('students'), AppStudent.fromJson),
      teachers: _readList(prefs.getStringList('teachers'), AppTeacher.fromJson),
      classes: _readList(prefs.getStringList('classes'), AppClass.fromJson),
      calls: _readList(prefs.getStringList('calls'), AttendanceCall.fromJson),
      attendance: _readList(
        prefs.getStringList('attendance'),
        AttendanceRecord.fromJson,
      ),
    );
  }

  @override
  Future<void> save(AppDataSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'students',
      _encodeList(snapshot.students, (item) => item.toJson()),
    );
    await prefs.setStringList(
      'teachers',
      _encodeList(snapshot.teachers, (item) => item.toJson()),
    );
    await prefs.setStringList(
      'classes',
      _encodeList(snapshot.classes, (item) => item.toJson()),
    );
    await prefs.setStringList(
      'calls',
      _encodeList(snapshot.calls, (item) => item.toJson()),
    );
    await prefs.setStringList(
      'attendance',
      _encodeList(snapshot.attendance, (item) => item.toJson()),
    );
  }

  List<T> _readList<T>(
    List<String>? values,
    T Function(Map<String, dynamic>) decode,
  ) {
    return (values ?? []).map((value) {
      return decode(jsonDecode(value) as Map<String, dynamic>);
    }).toList();
  }

  List<String> _encodeList<T>(
    Iterable<T> values,
    Map<String, dynamic> Function(T) encode,
  ) {
    return values.map((value) => jsonEncode(encode(value))).toList();
  }
}
