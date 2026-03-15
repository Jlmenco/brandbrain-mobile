import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<AuthProvider>().api;
      final items = await api.listNotifications(limit: 50);
      if (mounted) {
        setState(() {
          _notifications = items;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _markRead(AppNotification notification) async {
    if (notification.isRead) return;
    try {
      final api = context.read<AuthProvider>().api;
      await api.markNotificationRead(notification.id);
      if (mounted) {
        setState(() {
          final idx = _notifications.indexWhere((n) => n.id == notification.id);
          if (idx != -1) {
            _notifications[idx] = notification.copyWith(isRead: true);
          }
        });
      }
    } catch (_) {
      // silently ignore mark-read errors — notification state stays unread
    }
  }

  String _formatTimestamp(String createdAt) {
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Agora';
      if (diff.inMinutes < 60) return '${diff.inMinutes}min atrás';
      if (diff.inHours < 24) return '${diff.inHours}h atrás';
      if (diff.inDays == 1) return 'Ontem';
      if (diff.inDays < 7) return '${diff.inDays}d atrás';

      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    } catch (_) {
      return createdAt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        title: const Text('Notificações'),
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: kPrimaryColor),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: kErrorColor),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: kTextSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchNotifications,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: kPrimaryColor,
      onRefresh: _fetchNotifications,
      child: _notifications.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              itemCount: _notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return _NotificationCard(
                  notification: _notifications[index],
                  onTap: () => _markRead(_notifications[index]),
                  formatTimestamp: _formatTimestamp,
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 40,
                  color: kPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Nenhuma notificação',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kTextColor,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Você está em dia com tudo.',
                style: TextStyle(fontSize: 14, color: kTextSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final String Function(String) formatTimestamp;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.formatTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnread ? kPrimaryColor.withValues(alpha: 0.3) : kBorderColor,
            width: isUnread ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left unread indicator bar
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: isUnread ? kPrimaryColor : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Unread dot
                      Padding(
                        padding: const EdgeInsets.only(top: 5, right: 10),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isUnread
                                ? kPrimaryColor
                                : Colors.transparent,
                          ),
                        ),
                      ),
                      // Title + body + timestamp
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    notification.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isUnread
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: kTextColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  formatTimestamp(notification.createdAt),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: kTextMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification.body,
                              style: const TextStyle(
                                fontSize: 13,
                                color: kTextSecondary,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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
    );
  }
}
