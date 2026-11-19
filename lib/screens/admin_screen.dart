import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_app_shell.dart';
import 'login_screen.dart';
import 'reports_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
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
      const _StudentsPage(),
      const _TeachersPage(),
      const _ClassesAdminPage(),
      const ReportsScreen(),
      _AdminSettings(onLogout: logout),
    ];
    return ResponsiveAppShell(
      title: 'Painel administrativo',
      selectedIndex: index,
      onDestinationSelected: (value) => setState(() => index = value),
      maxContentWidth: 1050,
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
          icon: Icon(Icons.school_outlined),
          label: 'Alunos',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'Professores',
        ),
        NavigationDestination(
          icon: Icon(Icons.groups_outlined),
          label: 'Turmas',
        ),
        NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Relatórios'),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          label: 'Config',
        ),
      ],
    );
  }
}

class _StudentsPage extends StatelessWidget {
  const _StudentsPage();

  Future<void> editStudent(
    BuildContext context,
    AppState state, {
    AppStudent? student,
  }) async {
    final nameController = TextEditingController(text: student?.name);
    final emailController = TextEditingController(text: student?.email);
    String turmaId =
        student?.turmaId ??
        (state.classes.isNotEmpty ? state.classes.first.id : '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(student == null ? 'Cadastrar aluno' : 'Editar aluno'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: turmaId.isEmpty ? null : turmaId,
                  decoration: const InputDecoration(labelText: 'Turma'),
                  items: [
                    for (final turma in state.classes)
                      DropdownMenuItem(
                        value: turma.id,
                        child: Text(turma.name),
                      ),
                  ],
                  onChanged: (value) {
                    setDialogState(() => turmaId = value ?? '');
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        turmaId.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Informe nome, e-mail e turma do aluno.'),
          ),
        );
      }
      return;
    }
    final added = state.addStudent(
      AppStudent(
        id: student?.id ?? 'aluno-${DateTime.now().millisecondsSinceEpoch}',
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        turmaId: turmaId,
      ),
    );
    if (!added && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Já existe um aluno com este e-mail.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) => Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () => editStudent(context, state),
          child: const Icon(Icons.add),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          children: [
            const Text(
              'Alunos',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            for (final student in state.students)
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.cyan,
                    foregroundColor: AppTheme.navy,
                    child: Icon(Icons.person),
                  ),
                  title: Text(student.name),
                  subtitle: Text(student.email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Editar',
                        onPressed: () =>
                            editStudent(context, state, student: student),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Excluir',
                        onPressed: () => state.removeStudent(student.id),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TeachersPage extends StatelessWidget {
  const _TeachersPage();

  Future<void> editTeacher(
    BuildContext context,
    AppState state, {
    AppTeacher? teacher,
  }) async {
    final nameController = TextEditingController(text: teacher?.name);
    final emailController = TextEditingController(text: teacher?.email);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          teacher == null ? 'Cadastrar professor' : 'Editar professor',
        ),
        content: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(labelText: 'E-mail'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (saved != true ||
        nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty) {
      return;
    }
    final added = state.addTeacher(
      AppTeacher(
        id: teacher?.id ?? 'prof-${DateTime.now().millisecondsSinceEpoch}',
        name: nameController.text.trim(),
        email: emailController.text.trim(),
      ),
    );
    if (!added && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Já existe um professor com este e-mail.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) => Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () => editTeacher(context, state),
          child: const Icon(Icons.add),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          children: [
            const Text(
              'Professores',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            for (final teacher in state.teachers)
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.cyan,
                    foregroundColor: AppTheme.navy,
                    child: Icon(Icons.person),
                  ),
                  title: Text(teacher.name),
                  subtitle: Text(teacher.email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () =>
                            editTeacher(context, state, teacher: teacher),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        onPressed: () => state.removeTeacher(teacher.id),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ClassesAdminPage extends StatelessWidget {
  const _ClassesAdminPage();

  Future<void> editClass(
    BuildContext context,
    AppState state, {
    AppClass? turma,
  }) async {
    final nameController = TextEditingController(text: turma?.name);
    final subjectController = TextEditingController(text: turma?.subject);
    String? teacherId = turma?.teacherId;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(turma == null ? 'Cadastrar turma' : 'Editar turma'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nome da turma'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(labelText: 'Disciplina'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: teacherId,
                  decoration: const InputDecoration(
                    labelText: 'Professor responsável',
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Sem professor'),
                    ),
                    for (final teacher in state.teachers)
                      DropdownMenuItem<String?>(
                        value: teacher.id,
                        child: Text(
                          teacher.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => setDialogState(() => teacherId = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    if (saved != true ||
        nameController.text.trim().isEmpty ||
        subjectController.text.trim().isEmpty) {
      return;
    }
    state.addClass(
      AppClass(
        id: turma?.id ?? 'turma-${DateTime.now().millisecondsSinceEpoch}',
        name: nameController.text.trim(),
        subject: subjectController.text.trim(),
        teacherId: teacherId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) => Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () => editClass(context, state),
          child: const Icon(Icons.add),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          children: [
            const Text(
              'Turmas',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            for (final turma in state.classes)
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.cyan,
                    foregroundColor: AppTheme.navy,
                    child: Icon(Icons.groups),
                  ),
                  title: Text(turma.name),
                  subtitle: Text(
                    '${turma.subject} • '
                    '${state.teachers.where((teacher) => teacher.id == turma.teacherId).firstOrNull?.name ?? 'Sem professor'}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () =>
                            editClass(context, state, turma: turma),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Excluir',
                        onPressed: () async {
                          final removed = state.removeClass(turma.id);
                          if (!removed && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Não é possível excluir uma turma com alunos ou chamadas vinculadas.',
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AdminSettings extends StatelessWidget {
  const _AdminSettings({required this.onLogout});
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
                    child: Icon(Icons.admin_panel_settings_outlined),
                  ),
                  title: Text(state.currentUserName),
                  subtitle: Text('${state.email ?? ''}\nPerfil: Administrador'),
                  isThreeLine: true,
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Perfil do administrador'),
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
                  leading: Icon(Icons.science_outlined),
                  title: Text('Modo demonstração'),
                  subtitle: Text(
                    'Login livre para testes; não representa autenticação real.',
                  ),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.storage_outlined),
                  title: Text('Armazenamento local'),
                  subtitle: Text(
                    'Cadastros, chamadas e frequências permanecem neste dispositivo.',
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
