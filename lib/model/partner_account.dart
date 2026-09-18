import 'package:flutter/material.dart';

/// نوع الشراكة الذي يطلبه صاحب الحساب.
enum PartnerRole {
  /// يقيم فعاليات وأنشطة (مهرجانات، ورش، حفلات...).
  organizer(
    'organizer',
    'منظّم فعاليات',
    'أقيم فعاليات وأنشطة وأرغب بنشرها في الدليل.',
    Icons.celebration_rounded,
  ),

  /// يملك أو يدير منشأة ثابتة (مقهى، متحف، منتزه...).
  venueOwner(
    'venue_owner',
    'مالك منشأة',
    'أملك أو أدير مكاناً ثابتاً وأرغب بإضافته وتحديث بياناته.',
    Icons.storefront_rounded,
  );

  const PartnerRole(this.code, this.label, this.description, this.icon);

  /// القيمة المخزّنة في قاعدة البيانات.
  final String code;
  final String label;
  final String description;
  final IconData icon;

  static PartnerRole? fromCode(String? code) {
    for (final role in PartnerRole.values) {
      if (role.code == code) return role;
    }
    return null;
  }
}

/// حالة مراجعة طلب الشراكة.
enum PartnerStatus {
  pending('pending', 'قيد المراجعة'),
  approved('approved', 'شريك معتمد'),
  rejected('rejected', 'طلب مرفوض');

  const PartnerStatus(this.code, this.label);

  final String code;
  final String label;

  static PartnerStatus? fromCode(String? code) {
    for (final status in PartnerStatus.values) {
      if (status.code == code) return status;
    }
    return null;
  }
}

/// صف واحد من جدول `partner_accounts` يمثّل طلب الشراكة الخاص بالمستخدم الحالي.
class PartnerAccount {
  final String id;
  final String userId;
  final PartnerRole role;
  final PartnerStatus status;
  final String displayName;
  final String? contactPhone;
  final String? website;
  final String? notes;

  /// ملاحظة الفريق عند الرفض (أو عند طلب معلومات إضافية).
  final String? reviewNote;
  final DateTime? createdAt;
  final DateTime? reviewedAt;

  const PartnerAccount({
    required this.id,
    required this.userId,
    required this.role,
    required this.status,
    required this.displayName,
    this.contactPhone,
    this.website,
    this.notes,
    this.reviewNote,
    this.createdAt,
    this.reviewedAt,
  });

  bool get isApproved => status == PartnerStatus.approved;
  bool get isPending => status == PartnerStatus.pending;
  bool get isRejected => status == PartnerStatus.rejected;

  factory PartnerAccount.fromJson(Map<String, dynamic> json) {
    return PartnerAccount(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      role:
          PartnerRole.fromCode(json['partner_type'] as String?) ??
          PartnerRole.venueOwner,
      status:
          PartnerStatus.fromCode(json['status'] as String?) ??
          PartnerStatus.pending,
      displayName: (json['display_name'] as String?) ?? '',
      contactPhone: json['contact_phone'] as String?,
      website: json['website'] as String?,
      notes: json['notes'] as String?,
      reviewNote: json['review_note'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      reviewedAt: DateTime.tryParse(json['reviewed_at']?.toString() ?? ''),
    );
  }
}
