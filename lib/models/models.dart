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

// --- Onboarding ---

class OnboardingProgress {
  final String id;
  final List<String> stepsCompleted;
  final List<String> stepsTotal;
  final bool isDismissed;
  final bool isComplete;

  OnboardingProgress({
    required this.id,
    required this.stepsCompleted,
    required this.stepsTotal,
    required this.isDismissed,
    required this.isComplete,
  });

  factory OnboardingProgress.fromJson(Map<String, dynamic> json) =>
      OnboardingProgress(
        id: json['id'] as String,
        stepsCompleted: List<String>.from(json['steps_completed'] ?? []),
        stepsTotal: List<String>.from(json['steps_total'] ?? []),
        isDismissed: json['is_dismissed'] as bool? ?? false,
        isComplete: json['is_complete'] as bool? ?? false,
      );
}

// --- Editorial Planning ---

class EditorialSlot {
  final String id;
  final String planId;
  final String date;
  final String timeSlot;
  final String platform;
  final String pillar;
  final String theme;
  final String objective;
  final String? contentItemId;

  EditorialSlot({
    required this.id,
    required this.planId,
    required this.date,
    required this.timeSlot,
    required this.platform,
    required this.pillar,
    required this.theme,
    required this.objective,
    this.contentItemId,
  });

  factory EditorialSlot.fromJson(Map<String, dynamic> json) => EditorialSlot(
        id: json['id'] as String,
        planId: json['plan_id'] as String,
        date: json['date'] as String? ?? '',
        timeSlot: json['time_slot'] as String? ?? 'morning',
        platform: json['platform'] as String? ?? '',
        pillar: json['pillar'] as String? ?? '',
        theme: json['theme'] as String? ?? '',
        objective: json['objective'] as String? ?? 'awareness',
        contentItemId: json['content_item_id'] as String?,
      );
}

class EditorialPlan {
  final String id;
  final String orgId;
  final String? costCenterId;
  final String periodType;
  final String periodStart;
  final String periodEnd;
  final String status;
  final String? aiRationale;
  final List<EditorialSlot> slots;

  EditorialPlan({
    required this.id,
    required this.orgId,
    this.costCenterId,
    required this.periodType,
    required this.periodStart,
    required this.periodEnd,
    required this.status,
    this.aiRationale,
    required this.slots,
  });

  factory EditorialPlan.fromJson(Map<String, dynamic> json) => EditorialPlan(
        id: json['id'] as String,
        orgId: json['org_id'] as String,
        costCenterId: json['cost_center_id'] as String?,
        periodType: json['period_type'] as String? ?? 'week',
        periodStart: json['period_start'] as String? ?? '',
        periodEnd: json['period_end'] as String? ?? '',
        status: json['status'] as String? ?? 'draft',
        aiRationale: json['ai_rationale'] as String?,
        slots: (json['slots'] as List? ?? [])
            .map((e) => EditorialSlot.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// --- Repurpose ---

class RepurposeResult {
  final String sourceId;
  final List<RepurposeItem> created;

  RepurposeResult({required this.sourceId, required this.created});

  factory RepurposeResult.fromJson(Map<String, dynamic> json) =>
      RepurposeResult(
        sourceId: json['source_id'] as String? ?? '',
        created: (json['created'] as List? ?? [])
            .map((e) => RepurposeItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class RepurposeItem {
  final String id;
  final String platform;
  final String preview;

  RepurposeItem({required this.id, required this.platform, required this.preview});

  factory RepurposeItem.fromJson(Map<String, dynamic> json) => RepurposeItem(
        id: json['id'] as String,
        platform: json['platform'] as String? ?? '',
        preview: json['preview'] as String? ?? '',
      );
}
