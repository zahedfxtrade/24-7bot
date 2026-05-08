class AttendanceRecord {
  final String guardId;
  final String date; // YYYY-MM-DD
  String status; // 'P', 'PP', 'A'
  String point; // duty point for that day
  String? nightPoint; // for PP
  int overtimeAmount; // extra amount for single-duty guard doing PP
  int singleDutyAmount; // for double-duty guard doing single duty (P)
  String? absentReason; // reason when status == 'A'

  // Cancel duty fields
  // cancelledDuty: null = not cancelled | 'all' = full cancel | 'day' | 'night'
  String? cancelledDuty;
  String? cancelReason;

  AttendanceRecord({
    required this.guardId,
    required this.date,
    required this.status,
    required this.point,
    this.nightPoint,
    this.overtimeAmount = 0,
    this.singleDutyAmount = 0,
    this.absentReason,
    this.cancelledDuty,
    this.cancelReason,
  });

  Map<String, dynamic> toJson() => {
        'guardId': guardId,
        'date': date,
        'status': status,
        'point': point,
        'nightPoint': nightPoint,
        'overtimeAmount': overtimeAmount,
        'singleDutyAmount': singleDutyAmount,
        'absentReason': absentReason,
        'cancelledDuty': cancelledDuty,
        'cancelReason': cancelReason,
      };

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        guardId: json['guardId'] ?? '',
        date: json['date'] ?? '',
        status: json['status'] ?? 'P',
        point: json['point'] ?? '',
        nightPoint: json['nightPoint'],
        overtimeAmount: json['overtimeAmount'] ?? 0,
        singleDutyAmount: json['singleDutyAmount'] ?? 0,
        absentReason: json['absentReason'],
        cancelledDuty: json['cancelledDuty'],
        cancelReason: json['cancelReason'],
      );
}

class MonthlyAttendanceSummary {
  final String guardId;
  final String monthKey; // YYYY-MM
  int presentDays;
  int doubleDutyDays;
  int absentDays;
  int cancelledDays;
  int overtimeAmount; // total overtime amount (for single-duty guards)
  int singleDutyAmount; // total single-duty amount (for double-duty guards)

  MonthlyAttendanceSummary({
    required this.guardId,
    required this.monthKey,
    this.presentDays = 0,
    this.doubleDutyDays = 0,
    this.absentDays = 0,
    this.cancelledDays = 0,
    this.overtimeAmount = 0,
    this.singleDutyAmount = 0,
  });
}
