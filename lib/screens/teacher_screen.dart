import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_app_shell.dart';
import 'login_screen.dart';
import 'reports_screen.dart';

class TeacherScreen extends StatefulWidget {
  const TeacherScreen({super.key});

  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  int index = 0;

  void logout() {
    context.read<AppState>().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _ClassesPage(),
      const _CallPage(),
      const _HistoryPage(),
      const ReportsScreen(),
      _TeacherSettings(onLogout: logout),
    ];
    return ResponsiveAppShell(
      title: 'Painel do professor',
      selectedIndex: index,
      onDestinationSelected: (value) => setState(() => index = value),
      maxContentWidth: 1000,
      actions: [
        IconButton(
          tooltip: 'Perfil',
          onPressed: () => setState(() => index = 4),
          icon: const Icon(Icons.account_circle_outlined),
        ),
      ],
      body: pages[index],
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.groups_outlined),
          label: 'Turmas',
        ),
        NavigationDestination(icon: Icon(Icons.qr_code_2), label: 'Chamada'),
        NavigationDestination(icon: Icon(Icons.history), label: 'Histórico'),
        NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Relatórios'),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          label: 'Perfil',
        ),
      ],
    );
  }
}

class _ClassesPage extends StatelessWidget {
  const _ClassesPage();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final teacherId = state.currentTeacher?.id;
        final classes = state.classes.where(
          (turma) => teacherId == null || turma.teacherId == teacherId,
        );
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Olá, ${state.currentUserName}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Minhas turmas e alunos',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            if (classes.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Nenhuma turma vinculada'),
                  subtitle: Text(
                    'O administrador pode vincular suas turmas ao perfil.',
                  ),
                ),
              ),
            for (final turma in classes)
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.cyan,
                    foregroundColor: AppTheme.navy,
                    child: Icon(Icons.groups),
                  ),
                  title: Text(turma.name),
                  subtitle: Text(
                    '${turma.subject} • ${state.studentsForClass(turma.id).length} alunos',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      _showRoster(context, state, turma.id, turma.name),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showRoster(
    BuildContext context,
    AppState state,
    String classId,
    String name,
  ) {
    final students = state.studentsForClass(classId);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.65,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: students.isEmpty
                    ? const Center(
                        child: Text('Nenhum aluno cadastrado nesta turma.'),
                      )
                    : ListView(
                        children: [
                          for (final student in students)
                            ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.person_outline),
                              ),
                              title: Text(student.name),
                              subtitle: Text(student.email),
                              trailing: Text(
                                '${state.attendancesForStudent(student.id)} presenças',
                                style: const TextStyle(
                                  color: AppTheme.lightCyan,
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallPage extends StatefulWidget {
  const _CallPage();

  @override
  State<_CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<_CallPage> {
  String? selectedClassId;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final teacherId = state.currentTeacher?.id;
        final classes = state.classes
            .where((turma) => teacherId == null || turma.teacherId == teacherId)
            .toList();
        final active = state.activeCall;
        final selected = classes
            .where((item) => item.id == selectedClassId)
            .firstOrNull;
        final currentClass = active == null
            ? selected
            : state.classes
                  .where((item) => item.id == active.classId)
                  .firstOrNull;
        if (selected == null &&
            classes.isNotEmpty &&
            selectedClassId != classes.first.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => selectedClassId = classes.first.id);
          });
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Chamada por QR Code',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue:
                      selected?.id ??
                      (classes.isEmpty ? null : classes.first.id),
                  decoration: const InputDecoration(labelText: 'Turma'),
                  items: [
                    for (final turma in classes)
                      DropdownMenuItem(
                        value: turma.id,
                        child: Text(
                          '${turma.name} • ${turma.subject}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: active != null || classes.isEmpty
                      ? null
                      : (value) => setState(() => selectedClassId = value),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: active == null
                    ? Column(
                        children: [
                          const Icon(
                            Icons.qr_code_2,
                            size: 78,
                            color: AppTheme.cyan,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            classes.isEmpty
                                ? 'Vincule uma turma para iniciar.'
                                : 'Nenhuma chamada ativa',
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: selected == null
                                ? null
                                : () => state.startCall(
                                    selected.id,
                                    selected.subject,
                                  ),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('INICIAR CHAMADA'),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          if (currentClass != null)
                            Text(
                              '${currentClass.name} • ${active.subject}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          const SizedBox(height: 12),
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 250,
                              maxHeight: 250,
                            ),
                            child: QrImageView(
                              data: 'presenca-qr:${active.id}',
                              backgroundColor: Colors.white,
                              eyeStyle: const QrEyeStyle(color: Colors.black),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${state.attendancesForCall(active.id)} presentes • '
                            '${(state.studentsForClass(active.classId).length - state.attendancesForCall(active.id)).clamp(0, state.studentsForClass(active.classId).length)} aguardando',
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _showCallRoster(context, state, active.id),
                            icon: const Icon(Icons.people_outline),
                            label: const Text('VER ALUNOS'),
                          ),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: () => state.endCall(active.id),
                            icon: const Icon(Icons.stop_circle_outlined),
                            label: const Text('ENCERRAR CHAMADA'),
                          ),
                        ],
                      ),
              ),
            ),
            if (active != null && currentClass != null) ...[
              const SizedBox(height: 8),
              const Text(
                'Presenças registradas',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              for (final student in state.studentsForClass(active.classId))
                Card(
                  child: ListTile(
                    leading: Icon(
                      state.attendance.any(
                            (record) =>
                                record.callId == active.id &&
                                record.studentId == student.id,
                          )
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: AppTheme.cyan,
                    ),
                    title: Text(student.name),
                    subtitle: Text(
                      state.attendance.any(
                            (record) =>
                                record.callId == active.id &&
                                record.studentId == student.id,
                          )
                          ? 'Presente'
                          : 'Aguardando registro',
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  void _showCallRoster(BuildContext context, AppState state, String callId) {
    final call = state.calls.where((item) => item.id == callId).firstOrNull;
    if (call == null) return;
    final rows = state
        .studentsForClass(call.classId)
        .map((student) {
          final present = state.attendance.any(
            (record) =>
                record.callId == callId && record.studentId == student.id,
          );
          return '${student.name}: ${present
              ? 'presente'
              : call.active
              ? 'aguardando'
              : 'ausente'}';
        })
        .join('\n');
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Status da chamada'),
        content: SingleChildScrollView(
          child: Text(rows.isEmpty ? 'Nenhum aluno vinculado.' : rows),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('FECHAR'),
          ),
        ],
      ),
    );
  }
}

class _HistoryPage extends StatelessWidget {
  const _HistoryPage();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final teacherId = state.currentTeacher?.id;
        final calls =
            state.calls
                .where(
                  (call) =>
                      teacherId == null ||
                      call.teacherId == teacherId ||
                      state.classes.any(
                        (turma) =>
                            turma.id == call.classId &&
                            turma.teacherId == teacherId,
                      ),
                )
                .toList()
              ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Histórico de chamadas',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (calls.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Nenhuma chamada registrada ainda.'),
                ),
              ),
            for (final call in calls)
              Card(
                child: ListTile(
                  leading: Icon(
                    call.active
                        ? Icons.radio_button_checked
                        : Icons.check_circle,
                    color: call.active ? AppTheme.cyan : Colors.white54,
                  ),
                  title: Text(call.subject),
                  subtitle: Text(
                    '${state.classes.where((item) => item.id == call.classId).firstOrNull?.name ?? 'Turma removida'}\n'
                    '${call.startedAt.day}/${call.startedAt.month}/${call.startedAt.year} • '
                    '${state.attendancesForCall(call.id)} presentes • ${state.absencesForCall(call.id)} faltas',
                  ),
                  isThreeLine: true,
                  trailing: Text(call.active ? 'Ativa' : 'Encerrada'),
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(call.subject),
                      content: Text(
                        'Status: ${call.active ? 'ativa' : 'encerrada'}\n'
                        'Presenças: ${state.attendancesForCall(call.id)}\n'
                        'Faltas: ${state.absencesForCall(call.id)}',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('FECHAR'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TeacherSettings extends StatelessWidget {
  const _TeacherSettings({required this.onLogout});
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Perfil e configurações',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.cyan,
                    foregroundColor: AppTheme.navy,
                    child: Icon(Icons.person),
                  ),
                  title: Text(state.currentUserName),
                  subtitle: Text('${state.email ?? ''}\nPerfil: Professor'),
                  isThreeLine: true,
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Perfil do professor'),
                      content: Text(
                        '${state.currentUserName}\n${state.email ?? ''}\nModo demonstração',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('FECHAR'),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.storage_outlined),
                  title: Text('Armazenamento local'),
                  subtitle: Text(
                    'Chamadas e frequências permanecem salvas neste dispositivo.',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sair da conta'),
                  subtitle: const Text(
                    'Voltar à tela de login para trocar de perfil',
                  ),
                  onTap: onLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
