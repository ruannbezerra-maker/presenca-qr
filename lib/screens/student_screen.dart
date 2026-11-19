import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_app_shell.dart';
import 'login_screen.dart';
import 'qr_scanner_screen.dart';
import 'reports_screen.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  int index = 0;

  void logout(BuildContext context) {
    context.read<AppState>().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _StudentHome(onScan: () => setState(() => index = 2)),
      const ReportsScreen(studentMode: true),
      const QRScannerScreen(),
      _SettingsPage(onLogout: () => logout(context)),
    ];
    return ResponsiveAppShell(
      title: 'PRESENÇA QR',
      selectedIndex: index,
      onDestinationSelected: (value) => setState(() => index = value),
      maxContentWidth: 960,
      actions: [
        IconButton(
          tooltip: 'Perfil',
          onPressed: () => setState(() => index = 3),
          icon: const Icon(Icons.account_circle_outlined),
        ),
      ],
      body: pages[index],
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Início',
        ),
        NavigationDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics),
          label: 'Frequência',
        ),
        NavigationDestination(
          icon: Icon(Icons.qr_code_scanner),
          label: 'Ler QR',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Config',
        ),
      ],
    );
  }
}

class _StudentHome extends StatelessWidget {
  const _StudentHome({required this.onScan});
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final student = state.currentStudent;
        if (student == null) {
          return const Center(
            child: Text('Não foi possível carregar o perfil.'),
          );
        }
        final presencas = state.completedAttendancesForStudent(student.id);
        final faltas = state.absencesForStudent(student.id);
        final total = state.callsForStudent(student.id);
        final percentual = total == 0
            ? 100
            : ((presencas / total) * 100).round();
        final turma = state.classes
            .where((item) => item.id == student.turmaId)
            .firstOrNull;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 27,
                  backgroundColor: AppTheme.cyan,
                  foregroundColor: AppTheme.navy,
                  child: Icon(Icons.person, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Olá, ${student.name}!',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Aluno • veja sua frequência',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 430;
                final cards = [
                  _MetricCard(
                    icon: Icons.percent,
                    title: '$percentual%',
                    subtitle: 'Presença',
                    color: AppTheme.cyan,
                    onTap: () => _showMetric(
                      context,
                      'Frequência',
                      '$presencas presenças em $total chamadas encerradas.',
                    ),
                  ),
                  _MetricCard(
                    icon: Icons.cancel_outlined,
                    title: '$faltas',
                    subtitle: 'Faltas',
                    color: const Color(0xFFEF9A9A),
                    onTap: () => _showMetric(
                      context,
                      'Faltas',
                      'Faltas calculadas a partir de chamadas encerradas da sua turma.',
                    ),
                  ),
                  _MetricCard(
                    icon: Icons.menu_book_outlined,
                    title: '${turma == null ? 0 : 1}',
                    subtitle: 'Aulas hoje',
                    color: AppTheme.lightCyan,
                    onTap: () => _showMetric(
                      context,
                      'Aulas de hoje',
                      turma?.name ?? 'Nenhuma turma vinculada.',
                    ),
                  ),
                ];
                if (compact) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 10),
                          Expanded(child: cards[1]),
                        ],
                      ),
                      const SizedBox(height: 10),
                      cards[2],
                    ],
                  );
                }
                return Row(
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(child: cards[i]),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Aulas do dia',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showMetric(
                    context,
                    'Minha turma',
                    turma == null
                        ? 'Nenhuma turma vinculada.'
                        : '${turma.name} • ${turma.subject}',
                  ),
                  icon: const Icon(Icons.groups_outlined),
                  label: const Text('Turma'),
                ),
              ],
            ),
            if (turma == null)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Sem turma vinculada'),
                  subtitle: Text(
                    'Peça ao administrador para vincular seu cadastro a uma turma.',
                  ),
                ),
              )
            else
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.cyan,
                    foregroundColor: AppTheme.navy,
                    child: Icon(Icons.school),
                  ),
                  title: Text(turma.subject),
                  subtitle: Text(turma.name),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showMetric(context, turma.name, turma.subject),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('LER QR CODE'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: AppTheme.cyan,
                foregroundColor: AppTheme.navy,
              ),
            ),
            const SizedBox(height: 18),
            Card(
              child: ListTile(
                leading: const Icon(Icons.history, color: AppTheme.lightCyan),
                title: const Text('Histórico de frequência'),
                subtitle: Text('$presencas presenças • $faltas faltas'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(
                        title: const Text('Histórico de frequência'),
                      ),
                      body: const ReportsScreen(studentMode: true),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMetric(BuildContext context, String title, String detail) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(detail),
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white70),
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

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({required this.onLogout});
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final student = state.currentStudent;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Configurações',
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
                    subtitle: Text('${state.email ?? ''}\nPerfil: Aluno'),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Perfil do aluno'),
                        content: Text(
                          'Nome: ${student?.name ?? state.currentUserName}\n'
                          'E-mail: ${state.email ?? ''}\n'
                          'Turma: ${student?.turmaId ?? 'Não vinculada'}\n'
                          'Acesso em modo demonstração.',
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
                      'Os dados são salvos localmente neste dispositivo.',
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
        );
      },
    );
  }
}
