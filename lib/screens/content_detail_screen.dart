import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';
import '../widgets/status_badge.dart';

// ─── Provider label helper ────────────────────────────────────────────────────

String _providerLabel(String provider) {
  const labels = <String, String>{
    'linkedin': 'LinkedIn',
    'instagram': 'Instagram',
    'facebook': 'Facebook',
    'tiktok': 'TikTok',
    'youtube': 'YouTube',
  };
  return labels[provider.toLowerCase()] ?? provider;
}

// ─── Content detail screen ────────────────────────────────────────────────────

class ContentDetailScreen extends StatefulWidget {
  final String contentId;

  const ContentDetailScreen({super.key, required this.contentId});

  @override
  State<ContentDetailScreen> createState() => _ContentDetailScreenState();
}

class _ContentDetailScreenState extends State<ContentDetailScreen> {
  ContentItem? _item;
  bool _loading = true;
  String? _error;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<AuthProvider>().api;
      final item = await api.getContent(widget.contentId);
      setState(() => _item = item);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitReview() async {
    setState(() => _actionLoading = true);
    try {
      final api = context.read<AuthProvider>().api;
      final updated = await api.submitReview(widget.contentId);
      setState(() => _item = updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enviado para revisão.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: kErrorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _approve() async {
    setState(() => _actionLoading = true);
    try {
      final api = context.read<AuthProvider>().api;
      final updated = await api.approveContent(widget.contentId);
      setState(() => _item = updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conteúdo aprovado.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: kErrorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _showRejectDialog() async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeitar conteúdo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informe o motivo da rejeição:',
              style: TextStyle(color: kTextSecondary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              autofocus: true,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ex: Texto fora das diretrizes da marca...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: kErrorColor),
            child: const Text('Rejeitar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final reason = reasonCtrl.text.trim();
    setState(() => _actionLoading = true);
    try {
      final api = context.read<AuthProvider>().api;
      final updated = await api.rejectContent(widget.contentId, reason);
      setState(() => _item = updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conteúdo rejeitado.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: kErrorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kCardColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Detalhes do Conteúdo'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
    }

    if (_error != null || _item == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: kErrorColor),
              const SizedBox(height: 12),
              Text(
                _error ?? 'Conteúdo não encontrado.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: kTextSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final item = _item!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status + provider row
          Row(
            children: [
              StatusBadge(status: item.status),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kBorderColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _providerLabel(item.providerTarget),
                  style: const TextStyle(
                    color: kTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Title
          if (item.title.isNotEmpty) ...[
            Text(
              item.title,
              style: const TextStyle(
                color: kTextColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Full text card
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Texto',
                    style: TextStyle(
                      color: kTextSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    item.text,
                    style: const TextStyle(
                      color: kTextColor,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Details card
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.person_outline,
                    label: 'Influenciador',
                    value: item.influencerName ?? '—',
                  ),
                  const Divider(height: 20, color: kBorderColor),
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Criado em',
                    value: _formatDate(item.createdAt),
                  ),
                  if (item.scheduledAt != null) ...[
                    const Divider(height: 20, color: kBorderColor),
                    _DetailRow(
                      icon: Icons.schedule_outlined,
                      label: 'Agendado para',
                      value: _formatDate(item.scheduledAt),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Workflow action buttons
          if (!_actionLoading) ..._buildActions(item.status),
          if (_actionLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(color: kPrimaryColor, strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildActions(String status) {
    if (status == 'draft') {
      return [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _submitReview,
            icon: const Icon(Icons.send_outlined, size: 18),
            label: const Text('Enviar para Revisão'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ];
    }

    if (status == 'review') {
      return [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _approve,
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Aprovar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kSuccessColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showRejectDialog,
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text('Rejeitar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: kErrorColor,
              side: const BorderSide(color: kErrorColor),
            ),
          ),
        ),
      ];
    }

    return [];
  }
}

// ─── Detail row helper ────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: kTextSecondary),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: kTextSecondary, fontSize: 13),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: kTextColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
