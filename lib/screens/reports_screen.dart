import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/app_models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key, this.studentMode = false});
  final bool studentMode;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final studentId = studentMode ? state.currentStudent?.id : null;
        final filteredCalls = state.calls
            .where(
              (call) =>
                  !call.active &&
                  (studentId == null ||
                      state.students.any(
                        (student) =>
                            student.id == studentId &&
                            student.turmaId == call.classId,
                      )),
            )
            .toList();
        final records = state.attendance.where((record) {
          final call = state.calls
              .where((item) => item.id == record.callId)
              .firstOrNull;
          return call != null &&
              filteredCalls.any((filtered) => filtered.id == call.id) &&
              (studentId == null || record.studentId == studentId);
        }).toList();
        final presencas = records.length;
        final totalPossible = studentId == null
            ? filteredCalls.fold<int>(
                0,
                (total, call) =>
                    total + state.studentsForClass(call.classId).length,
              )
            : filteredCalls.length;
        final faltas = (totalPossible - presencas).clamp(0, totalPossible);
        final percentual = totalPossible == 0
            ? 0
            : (presencas / totalPossible * 100).round();
        final monthlySpots = _monthlyRates(state, filteredCalls, studentId);
        final reportText = _reportText(
          state,
          studentId,
          presencas,
          faltas,
          percentual,
          filteredCalls,
        );

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  studentMode
                      ? 'Meu histórico de frequência'
                      : 'Relatórios gerais',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final metricCards = [
                      _SummaryCard(
                        icon: Icons.check_circle_outline,
                        title: '$presencas',
                        subtitle: 'Presenças',
                        color: AppTheme.cyan,
                        onTap: () => _showDetails(
                          context,
                          'Presenças',
                          '$presencas presenças registradas em chamadas encerradas.',
                        ),
                      ),
                      _SummaryCard(
                        icon: Icons.cancel_outlined,
                        title: '$faltas',
                        subtitle: 'Faltas',
                        color: const Color(0xFFEF9A9A),
                        onTap: () => _showDetails(
                          context,
                          'Faltas',
                          '$faltas ausências calculadas com base nas matrículas e chamadas encerradas.',
                        ),
                      ),
                      _SummaryCard(
                        icon: Icons.percent,
                        title: '$percentual%',
                        subtitle: 'Frequência',
                        color: AppTheme.lightCyan,
                        onTap: () => _showDetails(
                          context,
                          'Frequência',
                          '$presencas presenças de $totalPossible registros esperados.',
                        ),
                      ),
                    ];
                    if (constraints.maxWidth < 560) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: metricCards[0]),
                              const SizedBox(width: 8),
                              Expanded(child: metricCards[1]),
                            ],
                          ),
                          const SizedBox(height: 8),
                          metricCards[2],
                        ],
                      );
                    }
                    return Row(
                      children: [
                        for (var i = 0; i < metricCards.length; i++) ...[
                          if (i > 0) const SizedBox(width: 12),
                          Expanded(child: metricCards[i]),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                _ReportCard(
                  title: 'Presenças e faltas',
                  onTap: () => _showDetails(
                    context,
                    'Presenças e faltas',
                    '$presencas presenças • $faltas faltas • $percentual% de frequência.',
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 190,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 3,
                            centerSpaceRadius: 38,
                            sections: [
                              if (presencas > 0)
                                PieChartSectionData(
                                  value: presencas.toDouble(),
                                  title: '$presencas',
                                  color: AppTheme.cyan,
                                  radius: 48,
                                  titleStyle: const TextStyle(
                                    color: AppTheme.navy,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (faltas > 0)
                                PieChartSectionData(
                                  value: faltas.toDouble(),
                                  title: '$faltas',
                                  color: const Color(0xFFEF9A9A),
                                  radius: 48,
                                  titleStyle: const TextStyle(
                                    color: AppTheme.navy,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (totalPossible == 0)
                                PieChartSectionData(
                                  value: 1,
                                  title: '—',
                                  color: Colors.white24,
                                  radius: 48,
                                ),
                            ],
                          ),
                          duration: const Duration(milliseconds: 650),
                        ),
                      ),
                      const Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 20,
                        runSpacing: 8,
                        children: [
                          _ChartLegendItem(
                            color: AppTheme.cyan,
                            label: 'Presenças',
                          ),
                          _ChartLegendItem(
                            color: Color(0xFFEF9A9A),
                            label: 'Faltas',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _ReportCard(
                  title: 'Evolução mensal',
                  onTap: () => _showDetails(
                    context,
                    'Evolução mensal',
                    'Percentual calculado a partir dos registros reais dos últimos seis meses.',
                  ),
                  child: SizedBox(
                    height: 220,
                    child: LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: 5,
                        minY: 0,
                        maxY: 100,
                        gridData: const FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 25,
                              reservedSize: 36,
                              getTitlesWidget: (value, meta) => SideTitleWidget(
                                meta: meta,
                                child: Text(
                                  '${value.toInt()}%',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              reservedSize: 24,
                              getTitlesWidget: (value, meta) => SideTitleWidget(
                                meta: meta,
                                space: 4,
                                child: Text(
                                  _monthLabel(value.round()),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: monthlySpots,
                            isCurved: true,
                            color: AppTheme.lightCyan,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppTheme.cyan.withValues(alpha: 0.25),
                            ),
                          ),
                        ],
                      ),
                      duration: const Duration(milliseconds: 650),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _ReportCard(
                  title: 'Dados por turma',
                  onTap: () => _showDetails(
                    context,
                    'Dados por turma',
                    _classDetails(state, studentId),
                  ),
                  child: Column(
                    children: [
                      for (final turma in state.classes.where(
                        (item) =>
                            studentId == null ||
                            state.students.any(
                              (student) =>
                                  student.id == studentId &&
                                  student.turmaId == item.id,
                            ),
                      ))
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.groups_outlined,
                            color: AppTheme.cyan,
                          ),
                          title: Text(turma.name),
                          subtitle: Text(turma.subject),
                          trailing: Text(
                            '${state.calls.where((call) => call.classId == turma.id && !call.active).length} chamadas',
                          ),
                          onTap: () => _showDetails(
                            context,
                            turma.name,
                            _classDetails(state, studentId, classId: turma.id),
                          ),
                        ),
                      if (state.classes.isEmpty)
                        const ListTile(
                          title: Text('Nenhuma turma cadastrada.'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    await SharePlus.instance.share(
                      ShareParams(text: reportText),
                    );
                  },
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('EXPORTAR RELATÓRIO'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<FlSpot> _monthlyRates(
    AppState state,
    List<AttendanceCall> calls,
    String? studentId,
  ) {
    final now = DateTime.now();
    return List<FlSpot>.generate(6, (index) {
      final month = DateTime(now.year, now.month - 5 + index);
      final callsInMonth = calls.where(
        (call) =>
            call.startedAt.year == month.year &&
            call.startedAt.month == month.month,
      );
      var expected = 0;
      var present = 0;
      for (final call in callsInMonth) {
        final enrolled = studentId == null
            ? state.studentsForClass(call.classId).length
            : 1;
        expected += enrolled;
        present += state.attendance
            .where(
              (record) =>
                  record.callId == call.id &&
                  (studentId == null || record.studentId == studentId),
            )
            .length;
      }
      final rate = expected == 0 ? 0.0 : present / expected * 100;
      return FlSpot(index.toDouble(), rate);
    });
  }

  String _monthLabel(int index) {
    const months = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    final now = DateTime.now();
    final month = DateTime(now.year, now.month - 5 + index).month;
    return months[month - 1];
  }

  String _classDetails(AppState state, String? studentId, {String? classId}) {
    final classes = state.classes.where(
      (item) =>
          (classId == null || item.id == classId) &&
          (studentId == null ||
              state.students.any(
                (student) =>
                    student.id == studentId && student.turmaId == item.id,
              )),
    );
    if (classes.isEmpty) return 'Nenhuma turma disponível.';
    return classes
        .map((turma) {
          final calls = state.calls.where(
            (call) => call.classId == turma.id && !call.active,
          );
          final present = state.attendance.where((record) {
            final call = state.calls
                .where((item) => item.id == record.callId)
                .firstOrNull;
            return call != null &&
                call.classId == turma.id &&
                (studentId == null || record.studentId == studentId);
          }).length;
          final expected = studentId == null
              ? calls.fold<int>(
                  0,
                  (total, call) =>
                      total + state.studentsForClass(call.classId).length,
                )
              : calls.length;
          return '${turma.name} • ${turma.subject}\n'
              '${state.studentsForClass(turma.id).length} alunos • ${calls.length} chamadas • '
              '$present presenças • ${(expected - present).clamp(0, expected)} faltas';
        })
        .join('\n\n');
  }

  String _reportText(
    AppState state,
    String? studentId,
    int presencas,
    int faltas,
    int percentual,
    List<AttendanceCall> calls,
  ) {
    final presentStudents = calls.fold<int>(
      0,
      (total, call) => total + state.attendancesForCall(call.id),
    );
    final absentStudents = calls.fold<int>(
      0,
      (total, call) => total + state.absencesForCall(call.id),
    );
    return 'Relatório de frequência${studentId == null ? '' : ' do aluno'}\n'
        'Chamadas encerradas: ${calls.length}\n'
        'Presenças: ${studentId == null ? presentStudents : presencas}\n'
        'Faltas: ${studentId == null ? absentStudents : faltas}\n'
        'Frequência: $percentual%';
  }

  void _showDetails(BuildContext context, String title, String detail) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(detail)),
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.title,
    required this.child,
    required this.onTap,
  });
  final String title;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Icon(Icons.info_outline, size: 18),
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartLegendItem extends StatelessWidget {
  const _ChartLegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}
