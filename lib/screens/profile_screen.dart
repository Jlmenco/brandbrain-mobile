import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Sair da conta',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: kTextColor,
          ),
        ),
        content: const Text(
          'Tem certeza que deseja sair?',
          style: TextStyle(fontSize: 14, color: kTextSecondary),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: kTextSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kErrorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      if (context.mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final org = auth.selectedOrg;
    final orgs = auth.orgs;

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: kCardColor,
        foregroundColor: kTextColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: kTextColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // Avatar + org name + role
          _AvatarSection(org: org),

          const SizedBox(height: 24),

          // Org switcher (only when more than one org)
          if (orgs.length > 1) ...[
            _SectionLabel(label: 'Organização'),
            const SizedBox(height: 8),
            _OrgSwitcher(orgs: orgs, selectedOrg: org, auth: auth),
            const SizedBox(height: 24),
          ],

          // Conta section
          _SectionLabel(label: 'Conta'),
          const SizedBox(height: 8),
          _LogoutTile(onTap: () => _confirmLogout(context)),

          const SizedBox(height: 40),

          // Version text
          const Center(
            child: Text(
              'Brand Brain Mobile v1.0.0',
              style: TextStyle(fontSize: 12, color: kTextMuted),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Avatar + name + role
// ---------------------------------------------------------------------------

class _AvatarSection extends StatelessWidget {
  final Organization? org;

  const _AvatarSection({required this.org});

  String _roleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return 'Proprietário';
      case 'admin':
        return 'Administrador';
      case 'editor':
        return 'Editor';
      case 'viewer':
        return 'Visualizador';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgName = org?.name ?? '—';
    final roleText = org != null ? _roleLabel(org!.role) : '';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderColor),
      ),
      child: Column(
        children: [
          // Avatar circle with "BB" initials
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: kPrimaryColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              'BB',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            orgName,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: kTextColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          if (roleText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                roleText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: kPrimaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Org switcher
// ---------------------------------------------------------------------------

class _OrgSwitcher extends StatelessWidget {
  final List<Organization> orgs;
  final Organization? selectedOrg;
  final AuthProvider auth;

  const _OrgSwitcher({
    required this.orgs,
    required this.selectedOrg,
    required this.auth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor),
      ),
      child: Column(
        children: List.generate(orgs.length, (index) {
          final org = orgs[index];
          final isSelected = selectedOrg?.id == org.id;
          final isLast = index == orgs.length - 1;

          return InkWell(
            onTap: () => auth.selectOrg(org),
            borderRadius: BorderRadius.vertical(
              top: index == 0 ? const Radius.circular(12) : Radius.zero,
              bottom: isLast ? const Radius.circular(12) : Radius.zero,
            ),
            child: Container(
              decoration: BoxDecoration(
                border: isSelected
                    ? Border.all(color: kPrimaryColor, width: 1.5)
                    : null,
                borderRadius: BorderRadius.vertical(
                  top: index == 0 ? const Radius.circular(12) : Radius.zero,
                  bottom: isLast ? const Radius.circular(12) : Radius.zero,
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            org.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected ? kPrimaryColor : kTextColor,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_rounded,
                              color: kPrimaryColor, size: 20),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Divider(height: 1, thickness: 1, color: kBorderColor),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Logout tile
// ---------------------------------------------------------------------------

class _LogoutTile extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: kErrorColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.logout_rounded,
                  color: kErrorColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Sair',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kErrorColor,
                ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded,
                  color: kTextMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section label helper
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: kTextMuted,
        letterSpacing: 0.8,
      ),
    );
  }
}
