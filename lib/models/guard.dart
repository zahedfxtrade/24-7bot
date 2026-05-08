class Guard {
  final String id;
  String name;
  String mobile;
  int salary;
  String point;
  String dayPoint;
  String nightPoint;
  String dutyType; // 'single' or 'double'
  int advance;
  List<AdvanceEntry> advanceLog;
  Map<String, int> tiffin; // monthKey -> amount
  List<SalarySlipRecord> salarySlipHistory;

  // Tracks mid-month salary/duty-type changes.
  // Each entry records what changed and from which date it is effective.
  List<SalaryConfig> salaryHistory;

  Guard({
    required this.id,
    required this.name,
    this.mobile = '',
    required this.salary,
    required this.point,
    this.dayPoint = '',
    this.nightPoint = '',
    this.dutyType = 'single',
    this.advance = 0,
    List<AdvanceEntry>? advanceLog,
    Map<String, int>? tiffin,
    List<SalarySlipRecord>? salarySlipHistory,
    List<SalaryConfig>? salaryHistory,
  })  : advanceLog = advanceLog ?? [],
        tiffin = tiffin ?? {},
        salarySlipHistory = salarySlipHistory ?? [],
        salaryHistory = salaryHistory ?? [];

  bool get isDoubleDuty => dutyType == 'double';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'mobile': mobile,
        'salary': salary,
        'point': point,
        'dayPoint': dayPoint,
        'nightPoint': nightPoint,
        'dutyType': dutyType,
        'advance': advance,
        'advanceLog': advanceLog.map((e) => e.toJson()).toList(),
        'tiffin': tiffin,
        'salarySlipHistory': salarySlipHistory.map((e) => e.toJson()).toList(),
        'salaryHistory': salaryHistory.map((e) => e.toJson()).toList(),
      };

  factory Guard.fromJson(Map<String, dynamic> json) => Guard(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        mobile: json['mobile'] ?? '',
        salary: json['salary'] ?? 0,
        point: json['point'] ?? '',
        dayPoint: json['dayPoint'] ?? json['point'] ?? '',
        nightPoint: json['nightPoint'] ?? json['point'] ?? '',
        dutyType: json['dutyType'] ?? json['duty_type'] ?? 'single',
        advance: json['advance'] ?? 0,
        advanceLog: (json['advanceLog'] as List<dynamic>? ?? [])
            .map((e) => AdvanceEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        tiffin: Map<String, int>.from(json['tiffin'] ?? {}),
        salarySlipHistory: (json['salarySlipHistory'] as List<dynamic>? ?? [])
            .map((e) => SalarySlipRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
        salaryHistory: (json['salaryHistory'] as List<dynamic>? ?? [])
            .map((e) => SalaryConfig.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ─── AdvanceEntry ─────────────────────────────────────────────────────────────
// Now has a unique id so individual entries can be edited / deleted.

class AdvanceEntry {
  final String id; // unique per entry, used for edit/delete
  final String date; // YYYY-MM-DD
  int amount;
  String remark;

  AdvanceEntry({
    required this.id,
    required this.date,
    required this.amount,
    required this.remark,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'amount': amount,
        'remark': remark,
      };

  factory AdvanceEntry.fromJson(Map<String, dynamic> json) => AdvanceEntry(
        // older data may not have 'id' – generate one from date+amount
        id: json['id'] as String? ??
            '${json['date']}_${json['amount']}_${json.hashCode}',
        date: json['date'] ?? '',
        amount: json['amount'] ?? 0,
        remark: json['remark'] ?? '',
      );
}

// ─── SalaryConfig ─────────────────────────────────────────────────────────────
// Records a salary / duty-type change with the date it became effective.
// When calculating salary we look up which config was active for each day.

class SalaryConfig {
  final String effectiveFrom; // YYYY-MM-DD – first day this config applies
  final int salary;
  final String dutyType; // 'single' or 'double'
  final String point;
  final String dayPoint;
  final String nightPoint;

  SalaryConfig({
    required this.effectiveFrom,
    required this.salary,
    required this.dutyType,
    required this.point,
    required this.dayPoint,
    required this.nightPoint,
  });

  Map<String, dynamic> toJson() => {
        'effectiveFrom': effectiveFrom,
        'salary': salary,
        'dutyType': dutyType,
        'point': point,
        'dayPoint': dayPoint,
        'nightPoint': nightPoint,
      };

  factory SalaryConfig.fromJson(Map<String, dynamic> json) => SalaryConfig(
        effectiveFrom: json['effectiveFrom'] ?? '',
        salary: json['salary'] ?? 0,
        dutyType: json['dutyType'] ?? 'single',
        point: json['point'] ?? '',
        dayPoint: json['dayPoint'] ?? '',
        nightPoint: json['nightPoint'] ?? '',
      );
}

// ─── SalarySlipRecord ─────────────────────────────────────────────────────────
// Snapshot stored when owner marks a month as paid.

class SalarySlipRecord {
  final String monthKey;
  final String paidDate;
  final int totalDays;
  final int presentDays;
  final int doubleDutyDays;
  final int absentDays;
  final int overtimeAmount;
  final int singleDutyAmount;
  final int totalEarnings;
  final int advance;
  final List<AdvanceEntry> advanceEntries; // snapshot of entries at time of pay
  final int tiffin;
  final int netSalary;
  // For mid-month salary changes: list of salary segments
  final List<SalarySegment> segments;

  SalarySlipRecord({
    required this.monthKey,
    required this.paidDate,
    required this.totalDays,
    required this.presentDays,
    required this.doubleDutyDays,
    required this.absentDays,
    required this.overtimeAmount,
    required this.singleDutyAmount,
    required this.totalEarnings,
    required this.advance,
    required this.advanceEntries,
    required this.tiffin,
    required this.netSalary,
    required this.segments,
  });

  int get workDays => presentDays + doubleDutyDays;

  Map<String, dynamic> toJson() => {
        'monthKey': monthKey,
        'paidDate': paidDate,
        'totalDays': totalDays,
        'presentDays': presentDays,
        'doubleDutyDays': doubleDutyDays,
        'absentDays': absentDays,
        'overtimeAmount': overtimeAmount,
        'singleDutyAmount': singleDutyAmount,
        'totalEarnings': totalEarnings,
        'advance': advance,
        'advanceEntries': advanceEntries.map((e) => e.toJson()).toList(),
        'tiffin': tiffin,
        'netSalary': netSalary,
        'segments': segments.map((s) => s.toJson()).toList(),
      };

  factory SalarySlipRecord.fromJson(Map<String, dynamic> json) =>
      SalarySlipRecord(
        monthKey: json['monthKey'] ?? '',
        paidDate: json['paidDate'] ?? '',
        totalDays: json['totalDays'] ?? 0,
        presentDays: json['presentDays'] ?? 0,
        doubleDutyDays: json['doubleDutyDays'] ?? 0,
        absentDays: json['absentDays'] ?? 0,
        overtimeAmount: json['overtimeAmount'] ?? 0,
        singleDutyAmount: json['singleDutyAmount'] ?? 0,
        totalEarnings: json['totalEarnings'] ?? 0,
        advance: json['advance'] ?? 0,
        advanceEntries: (json['advanceEntries'] as List<dynamic>? ?? [])
            .map((e) => AdvanceEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        tiffin: json['tiffin'] ?? 0,
        netSalary: json['netSalary'] ?? 0,
        segments: (json['segments'] as List<dynamic>? ?? [])
            .map((s) => SalarySegment.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

// ─── SalarySegment ────────────────────────────────────────────────────────────
// One contiguous block within a month where salary + duty-type was the same.
// Used to show the split salary calculation in the salary slip.

class SalarySegment {
  final int salary; // monthly salary for this segment
  final String dutyType;
  final int totalDaysInMonth; // used to derive daily rate
  final int workDays; // P + PP days in this segment
  final int presentDays;
  final int doubleDutyDays;
  final int absentDays;
  final int basePay;
  final int overtimeAmount;
  final int singleDutyAmount;
  final int segmentTotal; // basePay + overtime/singleDuty
  final String fromDate; // YYYY-MM-DD
  final String toDate; // YYYY-MM-DD

  SalarySegment({
    required this.salary,
    required this.dutyType,
    required this.totalDaysInMonth,
    required this.workDays,
    required this.presentDays,
    required this.doubleDutyDays,
    required this.absentDays,
    required this.basePay,
    required this.overtimeAmount,
    required this.singleDutyAmount,
    required this.segmentTotal,
    required this.fromDate,
    required this.toDate,
  });

  double get dailyRate => salary / totalDaysInMonth;

  Map<String, dynamic> toJson() => {
        'salary': salary,
        'dutyType': dutyType,
        'totalDaysInMonth': totalDaysInMonth,
        'workDays': workDays,
        'presentDays': presentDays,
        'doubleDutyDays': doubleDutyDays,
        'absentDays': absentDays,
        'basePay': basePay,
        'overtimeAmount': overtimeAmount,
        'singleDutyAmount': singleDutyAmount,
        'segmentTotal': segmentTotal,
        'fromDate': fromDate,
        'toDate': toDate,
      };

  factory SalarySegment.fromJson(Map<String, dynamic> json) => SalarySegment(
        salary: json['salary'] ?? 0,
        dutyType: json['dutyType'] ?? 'single',
        totalDaysInMonth: json['totalDaysInMonth'] ?? 30,
        workDays: json['workDays'] ?? 0,
        presentDays: json['presentDays'] ?? 0,
        doubleDutyDays: json['doubleDutyDays'] ?? 0,
        absentDays: json['absentDays'] ?? 0,
        basePay: json['basePay'] ?? 0,
        overtimeAmount: json['overtimeAmount'] ?? 0,
        singleDutyAmount: json['singleDutyAmount'] ?? 0,
        segmentTotal: json['segmentTotal'] ?? 0,
        fromDate: json['fromDate'] ?? '',
        toDate: json['toDate'] ?? '',
      );
}
