import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';

// ─── Platform options ─────────────────────────────────────────────────────────

const _kPlatforms = <(String, String)>[
  ('linkedin', 'LinkedIn'),
  ('instagram', 'Instagram'),
  ('facebook', 'Facebook'),
  ('tiktok', 'TikTok'),
  ('youtube', 'YouTube'),
];

// ─── Create content screen ────────────────────────────────────────────────────

class CreateContentScreen extends StatefulWidget {
  const CreateContentScreen({super.key});

  @override
  State<CreateContentScreen> createState() => _CreateContentScreenState();
}

class _CreateContentScreenState extends State<CreateContentScreen> {
  static const _minChars = 10;
  static const _maxChars = 2200;

  final _textCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<Influencer> _influencers = [];
  bool _influencersLoading = true;
  String? _influencersError;

  String? _selectedInfluencerId;
  String _selectedPlatform = 'linkedin';

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInfluencers());
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInfluencers() async {
    final auth = context.read<AuthProvider>();
    final orgId = auth.selectedOrg?.id;
    if (orgId == null) {
      setState(() {
        _influencersLoading = false;
        _influencersError = 'Nenhuma organização selecionada.';
      });
      return;
    }
    setState(() {
      _influencersLoading = true;
      _influencersError = null;
    });
    try {
      final list = await auth.api.listInfluencers(orgId);
      setState(() => _influencers = list);
    } catch (e) {
      setState(() => _influencersError = e.toString());
    } finally {
      setState(() => _influencersLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedInfluencerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um influenciador.'),
          backgroundColor: kErrorColor,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final ccId = auth.selectedCC?.id;
    if (ccId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum centro de custo selecionado.'),
          backgroundColor: kErrorColor,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await auth.api.createContent(
        ccId: ccId,
        influencerId: _selectedInfluencerId!,
        providerTarget: _selectedPlatform,
        text: _textCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conteúdo criado com sucesso.')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: kErrorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kCardColor,
        leading: TextButton(
          onPressed: _submitting ? null : () => context.pop(),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: kTextSecondary, fontSize: 14),
          ),
        ),
        leadingWidth: 88,
        title: const Text('Novo Conteúdo'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: kPrimaryColor,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Criar',
                      style: TextStyle(
                        color: kPrimaryColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Influencer selector ──────────────────────────────────────
              _SectionLabel(label: 'Influenciador'),
              const SizedBox(height: 8),
              _buildInfluencerSelector(),

              const SizedBox(height: 20),

              // ── Platform selector ────────────────────────────────────────
              _SectionLabel(label: 'Plataforma'),
              const SizedBox(height: 8),
              _buildPlatformSelector(),

              const SizedBox(height: 20),

              // ── Text content ─────────────────────────────────────────────
              _SectionLabel(label: 'Texto do conteúdo'),
              const SizedBox(height: 8),
              _buildTextInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfluencerSelector() {
    if (_influencersLoading) {
      return const SizedBox(
        height: 44,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(color: kPrimaryColor, strokeWidth: 2),
          ),
        ),
      );
    }

    if (_influencersError != null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              _influencersError!,
              style: const TextStyle(color: kErrorColor, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: _loadInfluencers,
            child: const Text('Tentar novamente'),
          ),
        ],
      );
    }

    if (_influencers.isEmpty) {
      return const Text(
        'Nenhum influenciador cadastrado.',
        style: TextStyle(color: kTextSecondary, fontSize: 13),
      );
    }

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _influencers.length,
        separatorBuilder: (_, i) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final inf = _influencers[index];
          final selected = _selectedInfluencerId == inf.id;
          return ChoiceChip(
            label: Text(inf.name),
            selected: selected,
            onSelected: (_) => setState(() => _selectedInfluencerId = inf.id),
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
    );
  }

  Widget _buildPlatformSelector() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _kPlatforms.length,
        separatorBuilder: (_, i) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (value, label) = _kPlatforms[index];
          final selected = _selectedPlatform == value;
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => setState(() => _selectedPlatform = value),
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
    );
  }

  Widget _buildTextInput() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _textCtrl,
      builder: (context, value, child) {
        final charCount = value.text.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextFormField(
              controller: _textCtrl,
              minLines: 6,
              maxLines: 14,
              maxLength: _maxChars,
              buildCounter: (context,
                      {required currentLength,
                      required isFocused,
                      required maxLength}) =>
                  null,
              decoration: const InputDecoration(
                hintText: 'Escreva o texto do conteúdo...',
                alignLabelWithHint: true,
              ),
              validator: (v) {
                final text = v?.trim() ?? '';
                if (text.length < _minChars) {
                  return 'O texto deve ter ao menos $_minChars caracteres.';
                }
                return null;
              },
            ),
            const SizedBox(height: 4),
            Text(
              '$charCount / $_maxChars',
              style: TextStyle(
                color: charCount > _maxChars ? kErrorColor : kTextSecondary,
                fontSize: 12,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Section label helper ─────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: kTextSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
      ),
    );
  }
}
