import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  MetricsOverview? _metrics;
  int _pendingReviewCount = 0;
  String? _error;
  OnboardingProgress? _onboarding;
  List<EditorialPlan> _editorialPlans = [];

  final _numFmt = NumberFormat('#,##0', 'pt_BR');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    final api = auth.api;
    final cc = auth.selectedCC;

    if (cc == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final orgId = auth.selectedOrg?.id;
      final results = await Future.wait([
        api.listContent(cc.id, status: 'review', limit: 1),
        api.getMetricsOverview(cc.id),
      ]);

      final paginated = results[0] as PaginatedContent;
      final metrics = results[1] as MetricsOverview;

      // Load onboarding + editorial (non-blocking)
      OnboardingProgress? onboarding;
      List<EditorialPlan> plans = [];
      if (orgId != null) {
        try {
          onboarding = await api.getOnboardingProgress(orgId);
        } catch (_) {}
        try {
          plans = await api.listEditorialPlans(orgId, ccId: cc.id);
        } catch (_) {}
      }

      setState(() {
        _pendingReviewCount = paginated.total;
        _metrics = metrics;
        _onboarding = onboarding;
        _editorialPlans = plans;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orgName = auth.selectedOrg?.name ?? '';
    final ccName = auth.selectedCC?.name ?? '';

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: kCardColor,
        foregroundColor: kTextColor,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: kPrimaryColor,
        onRefresh: _loadData,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
            : _error != null
                ? _buildError()
                : _buildContent(orgName, ccName),
      ),
    );
  }

  Widget _buildError() {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 48, color: kErrorColor),
              const SizedBox(height: 12),
              Text(
                'Erro ao carregar dados',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kTextColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _error!,
                style: const TextStyle(fontSize: 13, color: kTextSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _loadData,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent(String orgName, String ccName) {
    final metrics = _metrics;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildGreeting(orgName, ccName),
        const SizedBox(height: 12),
        if (_onboarding != null && !_onboarding!.isDismissed && !_onboarding!.isComplete) ...[
          _buildOnboardingCard(),
          const SizedBox(height: 12),
        ],
        if (_pendingReviewCount > 0) ...[
          _buildAlertBanner(),
          const SizedBox(height: 12),
        ],
        _buildMetricGrid(metrics),
        const SizedBox(height: 16),
        if (metrics != null) _buildEngagementCard(metrics),
        if (_editorialPlans.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildEditorialCard(),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/relatorios'),
            icon: const Icon(Icons.summarize_outlined, size: 18),
            label: const Text('Gerar Relatório'),
            style: OutlinedButton.styleFrom(
              foregroundColor: kPrimaryColor,
              side: const BorderSide(color: kPrimaryColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting(String orgName, String ccName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Olá, bem-vindo!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: kTextColor,
          ),
        ),
        if (orgName.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            orgName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: kPrimaryColor,
            ),
          ),
        ],
        if (ccName.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            ccName,
            style: const TextStyle(fontSize: 13, color: kTextSecondary),
          ),
        ],
      ],
    );
  }

  Widget _buildAlertBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: kWarningBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: kWarningText, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$_pendingReviewCount ${_pendingReviewCount == 1 ? 'conteúdo aguarda' : 'conteúdos aguardam'} revisão.',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: kWarningText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricGrid(MetricsOverview? metrics) {
    final items = [
      _MetricCardData(
        label: 'Impressões',
        value: metrics != null ? _numFmt.format(metrics.totalImpressions) : '—',
        icon: Icons.visibility,
        color: const Color(0xFF6366F1),
      ),
      _MetricCardData(
        label: 'Curtidas',
        value: metrics != null ? _numFmt.format(metrics.totalLikes) : '—',
        icon: Icons.favorite,
        color: const Color(0xFFEF4444),
      ),
      _MetricCardData(
        label: 'Posts',
        value: metrics != null ? _numFmt.format(metrics.totalPosts) : '—',
        icon: Icons.article,
        color: const Color(0xFF059669),
      ),
      _MetricCardData(
        label: 'Seguidores',
        value: metrics != null
            ? (metrics.totalFollowersDelta >= 0
                ? '+${_numFmt.format(metrics.totalFollowersDelta)}'
                : _numFmt.format(metrics.totalFollowersDelta))
            : '—',
        icon: Icons.people,
        color: const Color(0xFFF59E0B),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      children: items.map(_buildMetricCard).toList(),
    );
  }

  Widget _buildMetricCard(_MetricCardData data) {
    return Card(
      color: kCardColor,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(data.icon, color: data.color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: kTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.label,
                  style: const TextStyle(fontSize: 12, color: kTextSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementCard(MetricsOverview metrics) {
    return Card(
      color: kCardColor,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Engajamento',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 14),
            _buildEngagementRow(
              icon: Icons.chat_bubble_outline,
              label: 'Comentários',
              value: _numFmt.format(metrics.totalComments),
              color: const Color(0xFF6366F1),
            ),
            const Divider(height: 20, color: kBorderColor),
            _buildEngagementRow(
              icon: Icons.share_outlined,
              label: 'Compartilhamentos',
              value: _numFmt.format(metrics.totalShares),
              color: const Color(0xFF059669),
            ),
            const Divider(height: 20, color: kBorderColor),
            _buildEngagementRow(
              icon: Icons.ads_click_outlined,
              label: 'Cliques',
              value: _numFmt.format(metrics.totalClicks),
              color: const Color(0xFFF59E0B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: kTextSecondary),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: kTextColor,
          ),
        ),
      ],
    );
  }

  // --- Onboarding checklist card ---

  static const _stepLabels = {
    'profile_setup': 'Configurar perfil',
    'first_influencer': 'Criar influenciador',
    'brand_kit': 'Configurar brand kit',
    'first_content': 'Criar primeiro conteúdo',
    'first_publish': 'Publicar conteúdo',
    'connect_social': 'Conectar rede social',
  };

  Widget _buildOnboardingCard() {
    final ob = _onboarding!;
    final completed = ob.stepsCompleted.length;
    final total = ob.stepsTotal.length;
    final progress = total > 0 ? completed / total : 0.0;

    return Card(
      color: kCardColor,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.rocket_launch_outlined, color: kPrimaryColor, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Primeiros Passos',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kTextColor),
                  ),
                ),
                Text(
                  '$completed/$total',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kPrimaryColor),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: kBorderColor,
                color: kPrimaryColor,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),
            ...ob.stepsTotal.map((step) {
              final done = ob.stepsCompleted.contains(step);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(
                      done ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 18,
                      color: done ? kSuccessColor : kTextSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _stepLabels[step] ?? step,
                      style: TextStyle(
                        fontSize: 13,
                        color: done ? kTextSecondary : kTextColor,
                        decoration: done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // --- Editorial planning card ---

  Widget _buildEditorialCard() {
    final plan = _editorialPlans.first;
    final pendingSlots = plan.slots.where((s) => s.contentItemId == null).toList();

    return Card(
      color: kCardColor,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: kPrimaryColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Plano Editorial (${plan.periodType == 'week' ? 'Semanal' : 'Mensal'})',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kTextColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${plan.periodStart} a ${plan.periodEnd} — ${plan.slots.length} slots',
              style: const TextStyle(fontSize: 12, color: kTextSecondary),
            ),
            if (plan.aiRationale != null && plan.aiRationale!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                plan.aiRationale!,
                style: const TextStyle(fontSize: 12, color: kTextSecondary, fontStyle: FontStyle.italic),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (pendingSlots.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Próximos slots:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextSecondary),
              ),
              const SizedBox(height: 6),
              ...pendingSlots.take(4).map((slot) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${slot.date} — ${slot.theme}',
                            style: const TextStyle(fontSize: 12, color: kTextColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          slot.platform,
                          style: const TextStyle(fontSize: 11, color: kTextSecondary),
                        ),
                      ],
                    ),
                  )),
              if (pendingSlots.length > 4)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+${pendingSlots.length - 4} mais',
                    style: const TextStyle(fontSize: 11, color: kTextSecondary),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricCardData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}
