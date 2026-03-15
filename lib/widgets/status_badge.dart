import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  static const _config = <String, ({Color bg, Color text, String label})>{
    'draft': (bg: Color(0xFFF3F4F6), text: Color(0xFF374151), label: 'Rascunho'),
    'review': (bg: Color(0xFFFEF3C7), text: Color(0xFF92400E), label: 'Revisão'),
    'approved': (bg: Color(0xFFD1FAE5), text: Color(0xFF065F46), label: 'Aprovado'),
    'scheduled': (bg: Color(0xFFDBEAFE), text: Color(0xFF1E40AF), label: 'Agendado'),
    'publishing': (bg: Color(0xFFE0E7FF), text: Color(0xFF3730A3), label: 'Publicando'),
    'posted': (bg: Color(0xFFD1FAE5), text: Color(0xFF065F46), label: 'Publicado'),
    'failed': (bg: Color(0xFFFEE2E2), text: Color(0xFF991B1B), label: 'Falhou'),
    'rejected': (bg: Color(0xFFFEE2E2), text: Color(0xFF991B1B), label: 'Rejeitado'),
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _config[status] ??
        (bg: const Color(0xFFF3F4F6), text: const Color(0xFF374151), label: status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cfg.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        cfg.label,
        style: TextStyle(
          color: cfg.text,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
