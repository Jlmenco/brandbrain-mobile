import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';
import '../widgets/status_badge.dart';

// ─── Provider icon badge ─────────────────────────────────────────────────────

class _ProviderBadge extends StatelessWidget {
  final String provider;

  const _ProviderBadge({required this.provider});

  static const _labels = <String, (String, Color)>{
    'linkedin': ('in', Color(0xFF0A66C2)),
    'instagram': ('ig', Color(0xFFE1306C)),
    'facebook': ('fb', Color(0xFF1877F2)),
    'tiktok': ('tt', Color(0xFF010101)),
    'youtube': ('yt', Color(0xFFFF0000)),
  };

  @override
  Widget build(BuildContext context) {
    final key = provider.toLowerCase();
    final cfg = _labels[key] ?? (provider.substring(0, 2).toLowerCase(), kTextSecondary);
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: cfg.$2,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        cfg.$1.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── Filter chip row ──────────────────────────────────────────────────────────

const _kFilters = <(String, String)>[
  ('', 'Todos'),
  ('draft', 'Rascunho'),
  ('review', 'Revisão'),
  ('approved', 'Aprovado'),
  ('posted', 'Publicado'),
];

// ─── Content list screen ──────────────────────────────────────────────────────

class ContentListScreen extends StatefulWidget {
  const ContentListScreen({super.key});

  @override
  State<ContentListScreen> createState() => _ContentListScreenState();
}

class _ContentListScreenState extends State<ContentListScreen> {
  static const _pageSize = 20;

  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  Timer? _debounce;
  String _statusFilter = '';
  String _searchQuery = '';

  final List<ContentItem> _items = [];
  int _total = 0;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPage(reset: true));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      if (!_loading && _hasMore) _loadPage();
    }
  }

  Future<void> _loadPage({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _items.clear();
        _hasMore = true;
      }
    });

    final auth = context.read<AuthProvider>();
    final ccId = auth.selectedCC?.id;
    if (ccId == null) {
      setState(() {
        _loading = false;
        _error = 'Nenhum centro de custo selecionado.';
      });
      return;
    }

    try {
      final result = await auth.api.listContent(
        ccId,
        status: _statusFilter.isEmpty ? null : _statusFilter,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        skip: _items.length,
        limit: _pageSize,
      );
      setState(() {
        _items.addAll(result.items);
        _total = result.total;
        _hasMore = _items.length < result.total;
      });
    } catch (e) {
      setState(() => _error = e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: kErrorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onRefresh() => _loadPage(reset: true);

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _searchQuery = value);
      _loadPage(reset: true);
    });
  }

  void _setFilter(String status) {
    if (status == _statusFilter) return;
    setState(() => _statusFilter = status);
    _loadPage(reset: true);
  }

  String _formatDate(String iso) {
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
        title: const Text('Conteúdos'),
        backgroundColor: kCardColor,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar conteúdos...',
                hintStyle: const TextStyle(color: kTextSecondary, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: kTextSecondary, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                isDense: true,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status filter chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _kFilters.length,
              separatorBuilder: (_, i) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final (value, label) = _kFilters[i];
                final selected = _statusFilter == value;
                return FilterChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) => _setFilter(value),
                  selectedColor: kPrimaryColor.withAlpha(25),
                  checkmarkColor: kPrimaryColor,
                  labelStyle: TextStyle(
                    color: selected ? kPrimaryColor : kTextSecondary,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: selected ? kPrimaryColor : kBorderColor,
                  ),
                  backgroundColor: kCardColor,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                );
              },
            ),
          ),

          // Total label
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Text(
              _loading && _items.isEmpty
                  ? 'Carregando...'
                  : '$_total resultado${_total != 1 ? 's' : ''}',
              style: const TextStyle(color: kTextSecondary, fontSize: 12),
            ),
          ),

          // List
          Expanded(
            child: RefreshIndicator(
              color: kPrimaryColor,
              onRefresh: _onRefresh,
              child: _error != null && _items.isEmpty
                  ? _buildError()
                  : _items.isEmpty && !_loading
                      ? _buildEmpty()
                      : ListView.separated(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                          itemCount: _items.length + (_hasMore ? 1 : 0),
                          separatorBuilder: (_, i) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            if (index == _items.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: kPrimaryColor,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }
                            return _ContentCard(
                              item: _items[index],
                              formatDate: _formatDate,
                              onTap: () => context.push('/conteudo/${_items[index].id}'),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/novo-conteudo'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        tooltip: 'Novo conteúdo',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: kErrorColor),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Erro ao carregar.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: kTextSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadPage(reset: true),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.article_outlined, size: 56, color: kBorderColor),
            const SizedBox(height: 12),
            const Text(
              'Nenhum conteúdo encontrado.',
              style: TextStyle(color: kTextSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Content card ─────────────────────────────────────────────────────────────

class _ContentCard extends StatelessWidget {
  final ContentItem item;
  final String Function(String) formatDate;
  final VoidCallback onTap;

  const _ContentCard({
    required this.item,
    required this.formatDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final preview = item.text.length > 90
        ? '${item.text.substring(0, 90).trimRight()}…'
        : item.text;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: provider badge + title + status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProviderBadge(provider: item.providerTarget),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.title.isNotEmpty)
                          Text(
                            item.title,
                            style: const TextStyle(
                              color: kTextColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (preview.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            preview,
                            style: const TextStyle(
                              color: kTextSecondary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: item.status),
                ],
              ),
              const SizedBox(height: 10),
              // Footer row: influencer + date
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: kTextSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.influencerName ?? '—',
                      style: const TextStyle(color: kTextSecondary, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.calendar_today_outlined,
                      size: 13, color: kTextSecondary),
                  const SizedBox(width: 4),
                  Text(
                    formatDate(item.createdAt),
                    style: const TextStyle(color: kTextSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
