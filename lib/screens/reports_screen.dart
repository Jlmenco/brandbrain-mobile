import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _reportType = 'metrics_overview';
  DateTimeRange? _range;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _range = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _displayDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _range,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: kPrimaryColor,
            onPrimary: Colors.white,
            surface: kCardColor,
            onSurface: kTextColor,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _range = picked);
  }

  Future<void> _generateReport() async {
    final auth = context.read<AuthProvider>();
    final cc = auth.selectedCC;
    final org = auth.selectedOrg;
    if (cc == null || _range == null) return;

    setState(() => _loading = true);
    try {
      final url = auth.api.getReportUrl(
        dateFrom: _fmtDate(_range!.start),
        dateTo: _fmtDate(_range!.end),
        ccId: cc.id,
        orgId: org?.id,
        reportType: _reportType,
      );

      final token = await auth.api.getToken();
      final fullUrl = '$url&token=$token';

      await Clipboard.setData(ClipboardData(text: fullUrl));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link do relatório copiado! Abra no navegador para baixar.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: kErrorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final ccName = auth.selectedCC?.name ?? 'Nenhuma marca selecionada';

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        title: const Text('Relatórios'),
        backgroundColor: kCardColor,
        foregroundColor: kTextColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand info
            Text(
              ccName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 16),

            // Date range
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PERÍODO',
                      style: TextStyle(
                        color: kTextSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickRange,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: kBorderColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 16, color: kTextSecondary),
                            const SizedBox(width: 8),
                            Text(
                              _range != null
                                  ? '${_displayDate(_range!.start)} — ${_displayDate(_range!.end)}'
                                  : 'Selecionar período',
                              style: const TextStyle(
                                color: kTextColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Report type
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TIPO DE RELATÓRIO',
                      style: TextStyle(
                        color: kTextSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ReportTypeOption(
                      title: 'Visão Geral de Métricas',
                      subtitle: 'Impressões, curtidas, seguidores e engajamento',
                      icon: Icons.bar_chart,
                      value: 'metrics_overview',
                      groupValue: _reportType,
                      onChanged: (v) => setState(() => _reportType = v),
                    ),
                    const Divider(height: 16, color: kBorderColor),
                    _ReportTypeOption(
                      title: 'Performance de Conteúdo',
                      subtitle: 'Análise detalhada por conteúdo publicado',
                      icon: Icons.article_outlined,
                      value: 'content_performance',
                      groupValue: _reportType,
                      onChanged: (v) => setState(() => _reportType = v),
                    ),
                    const Divider(height: 16, color: kBorderColor),
                    _ReportTypeOption(
                      title: 'Relatório Mensal Completo',
                      subtitle: 'Métricas + conteúdo + tendências',
                      icon: Icons.summarize_outlined,
                      value: 'full_monthly',
                      groupValue: _reportType,
                      onChanged: (v) => setState(() => _reportType = v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Generate button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _loading || auth.selectedCC == null ? null : _generateReport,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.download_outlined, size: 18),
                label: Text(_loading ? 'Gerando...' : 'Gerar Relatório PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportTypeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  const _ReportTypeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      child: Row(
        children: [
          Icon(icon, size: 20, color: selected ? kPrimaryColor : kTextSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: selected ? kTextColor : kTextSecondary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: kTextSecondary),
                ),
              ],
            ),
          ),
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            size: 20,
            color: selected ? kPrimaryColor : kTextSecondary,
          ),
        ],
      ),
    );
  }
}
