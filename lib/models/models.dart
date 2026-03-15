class Organization {
  final String id;
  final String name;
  final String role;

  Organization({required this.id, required this.name, required this.role});

  factory Organization.fromJson(Map<String, dynamic> json) => Organization(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        role: json['role'] as String? ?? '',
      );
}

class CostCenter {
  final String id;
  final String name;
  final String orgId;

  CostCenter({required this.id, required this.name, required this.orgId});

  factory CostCenter.fromJson(Map<String, dynamic> json) => CostCenter(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        orgId: json['org_id'] as String? ?? '',
      );
}

class ContentItem {
  final String id;
  final String title;
  final String text;
  final String status;
  final String providerTarget;
  final String createdAt;
  final String? scheduledAt;
  final String? influencerName;

  ContentItem({
    required this.id,
    required this.title,
    required this.text,
    required this.status,
    required this.providerTarget,
    required this.createdAt,
    this.scheduledAt,
    this.influencerName,
  });

  factory ContentItem.fromJson(Map<String, dynamic> json) => ContentItem(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        text: json['text'] as String? ?? '',
        status: json['status'] as String? ?? 'draft',
        providerTarget: json['provider_target'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
        scheduledAt: json['scheduled_at'] as String?,
        influencerName: json['influencer_name'] as String?,
      );
}

class PaginatedContent {
  final List<ContentItem> items;
  final int total;

  PaginatedContent({required this.items, required this.total});

  factory PaginatedContent.fromJson(Map<String, dynamic> json) =>
      PaginatedContent(
        items: (json['items'] as List)
            .map((e) => ContentItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: json['total'] as int? ?? 0,
      );
}

class Influencer {
  final String id;
  final String name;
  final String niche;
  final String providerTarget;

  Influencer({
    required this.id,
    required this.name,
    required this.niche,
    required this.providerTarget,
  });

  factory Influencer.fromJson(Map<String, dynamic> json) => Influencer(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        niche: json['niche'] as String? ?? '',
        providerTarget: json['provider_target'] as String? ?? '',
      );
}

class MetricsOverview {
  final int totalImpressions;
  final int totalLikes;
  final int totalComments;
  final int totalShares;
  final int totalClicks;
  final int totalFollowersDelta;
  final int totalPosts;

  MetricsOverview({
    required this.totalImpressions,
    required this.totalLikes,
    required this.totalComments,
    required this.totalShares,
    required this.totalClicks,
    required this.totalFollowersDelta,
    required this.totalPosts,
  });

  factory MetricsOverview.fromJson(Map<String, dynamic> json) =>
      MetricsOverview(
        totalImpressions: json['total_impressions'] as int? ?? 0,
        totalLikes: json['total_likes'] as int? ?? 0,
        totalComments: json['total_comments'] as int? ?? 0,
        totalShares: json['total_shares'] as int? ?? 0,
        totalClicks: json['total_clicks'] as int? ?? 0,
        totalFollowersDelta: json['total_followers_delta'] as int? ?? 0,
        totalPosts: json['total_posts'] as int? ?? 0,
      );
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final bool isRead;
  final String createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        isRead: json['is_read'] as bool? ?? false,
        createdAt: json['created_at'] as String? ?? '',
      );

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        title: title,
        body: body,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );
}
