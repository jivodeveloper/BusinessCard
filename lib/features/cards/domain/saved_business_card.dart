import 'package:cloud_firestore/cloud_firestore.dart';

class SavedBusinessCard {
  const SavedBusinessCard({
    required this.id,
    required this.displayName,
    required this.company,
    required this.phone,
    required this.email,
    required this.createdAt,
    this.remark = '',
    this.imagePath,
    this.remotePath,
    this.createdBy = '',
    this.ownerEmail = '',
  });

  final String id;
  final String displayName;
  final String company;
  final String phone;
  final String email;
  final DateTime createdAt;
  final String remark;
  final String? imagePath;
  final String? remotePath;
  final String createdBy;
  final String ownerEmail;

  String get subtitle {
    if (company.isNotEmpty && phone.isNotEmpty) {
      return '$company • $phone';
    }
    if (company.isNotEmpty) {
      return company;
    }
    return phone;
  }

  String get description {
    final parts = <String>[
      if (displayName.trim().isNotEmpty) 'Name: $displayName',
      if (company.trim().isNotEmpty) 'Company: $company',
      if (phone.trim().isNotEmpty) 'Phone: $phone',
      if (email.trim().isNotEmpty) 'Email: $email',
    ];
    return parts.join('\n');
  }

  Map<String, dynamic> toFirestoreMap({
    String? ownerUid,
    String? ownerEmail,
    String? createdBy,
  }) {
    return {
      'image_path': remotePath ?? imagePath ?? '',
      'created_date': FieldValue.serverTimestamp(),
      'remarks': remark,
      'description': description,
      'name': displayName,
      'company': company,
      'phone': phone,
      'email': email,
      if (ownerUid != null && ownerUid.trim().isNotEmpty) 'owner_uid': ownerUid,
      if (ownerEmail != null && ownerEmail.trim().isNotEmpty)
        'owner_email': ownerEmail.trim(),
      if (createdBy != null && createdBy.trim().isNotEmpty)
        'created_by': createdBy.trim(),
    };
  }

  factory SavedBusinessCard.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final createdValue = data['created_date'];
    DateTime createdAt;
    if (createdValue is Timestamp) {
      createdAt = createdValue.toDate();
    } else if (createdValue is DateTime) {
      createdAt = createdValue;
    } else {
      createdAt = DateTime.now();
    }

    final description = (data['description'] as String? ?? '').trim();
    final parsedLines = description
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    String extractValue(String prefix) {
      final match = parsedLines.cast<String?>().firstWhere(
        (line) => line != null && line.startsWith(prefix),
        orElse: () => null,
      );
      if (match == null) {
        return '';
      }
      return match.substring(prefix.length).trim();
    }

    return SavedBusinessCard(
      id: id,
      displayName: (data['name'] as String? ?? '').trim().isNotEmpty
          ? (data['name'] as String).trim()
          : extractValue('Name:'),
      company: (data['company'] as String? ?? '').trim().isNotEmpty
          ? (data['company'] as String).trim()
          : extractValue('Company:'),
      phone: (data['phone'] as String? ?? '').trim().isNotEmpty
          ? (data['phone'] as String).trim()
          : extractValue('Phone:'),
      email: (data['email'] as String? ?? '').trim().isNotEmpty
          ? (data['email'] as String).trim()
          : extractValue('Email:'),
      createdAt: createdAt,
      remark: data['remarks'] as String? ?? '',
      imagePath: data['image_path'] as String?,
      remotePath: data['image_path'] as String?,
      createdBy: data['created_by'] as String? ?? '',
      ownerEmail: data['owner_email'] as String? ?? '',
    );
  }

  SavedBusinessCard copyWith({
    String? id,
    String? displayName,
    String? company,
    String? phone,
    String? email,
    DateTime? createdAt,
    String? remark,
    String? imagePath,
    String? remotePath,
    String? createdBy,
    String? ownerEmail,
  }) {
    return SavedBusinessCard(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      company: company ?? this.company,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      remark: remark ?? this.remark,
      imagePath: imagePath ?? this.imagePath,
      remotePath: remotePath ?? this.remotePath,
      createdBy: createdBy ?? this.createdBy,
      ownerEmail: ownerEmail ?? this.ownerEmail,
    );
  }
}
