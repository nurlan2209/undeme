import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/sos_location.dart';

class PendingSosItem {
  PendingSosItem({
    required this.id,
    required this.location,
    required this.reason,
    required this.createdAt,
    this.attempt = 0,
  });

  final String id;
  final SosLocation location;
  final String reason;
  final DateTime createdAt;
  final int attempt;

  PendingSosItem copyWith({int? attempt}) => PendingSosItem(
        id: id,
        location: location,
        reason: reason,
        createdAt: createdAt,
        attempt: attempt ?? this.attempt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'location': location.toJson(),
        'reason': reason,
        'createdAt': createdAt.toIso8601String(),
        'attempt': attempt,
      };

  factory PendingSosItem.fromJson(Map<String, dynamic> json) {
    return PendingSosItem(
      id: json['id']?.toString() ?? '',
      location: SosLocation.fromJson(
          Map<String, dynamic>.from(json['location'] as Map)),
      reason: json['reason']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      attempt: (json['attempt'] as num?)?.toInt() ?? 0,
    );
  }
}

class OfflineSosQueue {
  OfflineSosQueue._();

  static final OfflineSosQueue instance = OfflineSosQueue._();

  static const _key = 'pending_sos_queue';

  Future<List<PendingSosItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return <PendingSosItem>[];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return <PendingSosItem>[];
    }

    return decoded
        .whereType<Map>()
        .map((item) => PendingSosItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> save(List<PendingSosItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(items.map((item) => item.toJson()).toList());
    await prefs.setString(_key, payload);
  }

  Future<void> enqueue(PendingSosItem item) async {
    final items = await load();
    items.add(item);
    await save(items);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
