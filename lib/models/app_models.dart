enum UserRole { aluno, professor, administrador }

class AppStudent {
  AppStudent({
    required this.id,
    required this.name,
    required this.email,
    required this.turmaId,
  });
  final String id;
  final String name;
  final String email;
  final String turmaId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'turmaId': turmaId,
  };
  factory AppStudent.fromJson(Map<String, dynamic> json) => AppStudent(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    turmaId: json['turmaId'] as String,
  );
}

class AppTeacher {
  AppTeacher({required this.id, required this.name, required this.email});
  final String id;
  final String name;
  final String email;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email};
  factory AppTeacher.fromJson(Map<String, dynamic> json) => AppTeacher(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
  );
}

class AppClass {
  AppClass({
    required this.id,
    required this.name,
    required this.subject,
    this.teacherId,
  });
  final String id;
  final String name;
  final String subject;
  final String? teacherId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'subject': subject,
    'teacherId': teacherId,
  };
  factory AppClass.fromJson(Map<String, dynamic> json) => AppClass(
    id: json['id'] as String,
    name: json['name'] as String,
    subject: json['subject'] as String,
    teacherId: json['teacherId'] as String?,
  );
}

class AttendanceCall {
  AttendanceCall({
    required this.id,
    required this.classId,
    required this.subject,
    required this.startedAt,
    this.teacherId,
    this.active = true,
  });
  final String id;
  final String classId;
  final String subject;
  final DateTime startedAt;
  final String? teacherId;
  bool active;

  Map<String, dynamic> toJson() => {
    'id': id,
    'classId': classId,
    'subject': subject,
    'startedAt': startedAt.toIso8601String(),
    'teacherId': teacherId,
    'active': active,
  };
  factory AttendanceCall.fromJson(Map<String, dynamic> json) => AttendanceCall(
    id: json['id'] as String,
    classId: json['classId'] as String,
    subject: json['subject'] as String,
    startedAt: DateTime.parse(json['startedAt'] as String),
    teacherId: json['teacherId'] as String?,
    active: json['active'] as bool,
  );
}

class AttendanceRecord {
  AttendanceRecord({
    required this.callId,
    required this.studentId,
    required this.recordedAt,
  });
  final String callId;
  final String studentId;
  final DateTime recordedAt;

  Map<String, dynamic> toJson() => {
    'callId': callId,
    'studentId': studentId,
    'recordedAt': recordedAt.toIso8601String(),
  };
  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        callId: json['callId'] as String,
        studentId: json['studentId'] as String,
        recordedAt: DateTime.parse(json['recordedAt'] as String),
      );
}
