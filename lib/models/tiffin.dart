// ─── TiffinService ────────────────────────────────────────────────────────────

class TiffinService {
  final String id;
  String name;
  String mobile;

  TiffinService({
    required this.id,
    required this.name,
    this.mobile = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'mobile': mobile,
      };

  factory TiffinService.fromJson(Map<String, dynamic> json) => TiffinService(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        mobile: json['mobile'] ?? '',
      );
}

// ─── TiffinEntry ──────────────────────────────────────────────────────────────
// One delivery record: service + date + shift + dabba count (simple number).

class TiffinEntry {
  final String id;
  final String serviceId;
  final String date;   // YYYY-MM-DD
  final String shift;  // 'afternoon' | 'night'
  int dabbas;          // total dabbas for this shift

  TiffinEntry({
    required this.id,
    required this.serviceId,
    required this.date,
    required this.shift,
    required this.dabbas,
  });

  // Backward-compat: if old data has pointDabbas, sum them
  int get totalDabbas => dabbas;

  Map<String, dynamic> toJson() => {
        'id': id,
        'serviceId': serviceId,
        'date': date,
        'shift': shift,
        'dabbas': dabbas,
      };

  factory TiffinEntry.fromJson(Map<String, dynamic> json) {
    // Legacy: old entries stored pointDabbas map
    int count = json['dabbas'] as int? ?? 0;
    if (count == 0 && json['pointDabbas'] != null) {
      final map = Map<String, dynamic>.from(json['pointDabbas'] as Map);
      count = map.values.fold(0, (s, v) => s + (v as int));
    }
    return TiffinEntry(
      id: json['id'] ?? '',
      serviceId: json['serviceId'] ?? '',
      date: json['date'] ?? '',
      shift: json['shift'] ?? 'afternoon',
      dabbas: count,
    );
  }
}
