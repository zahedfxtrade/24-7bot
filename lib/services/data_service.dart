import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/guard.dart';
import '../models/attendance.dart';
import '../models/tiffin.dart';

class DataService extends ChangeNotifier {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  List<Guard> _guards = [];
  List<AttendanceRecord> _attendance = [];
  List<TiffinService> _tiffinServices = [];
  List<TiffinEntry> _tiffinEntries = [];
  bool _loaded = false;

  List<Guard> get guards => List.unmodifiable(_guards);
  List<AttendanceRecord> get attendance => List.unmodifiable(_attendance);
  List<TiffinService> get tiffinServices => List.unmodifiable(_tiffinServices);
  List<TiffinEntry> get tiffinEntries => List.unmodifiable(_tiffinEntries);

  // ─── Known points (autocomplete) ────────────────────────────────────────────
  /// Collects all unique point names from guards + attendance records.
  List<String> get knownPoints {
    final points = <String>{};
    for (final g in _guards) {
      if (g.point.isNotEmpty) points.add(g.point);
      if (g.dayPoint.isNotEmpty) points.add(g.dayPoint);
      if (g.nightPoint.isNotEmpty) points.add(g.nightPoint);
    }
    for (final a in _attendance) {
      if (a.point.isNotEmpty) points.add(a.point);
      if ((a.nightPoint ?? '').isNotEmpty) points.add(a.nightPoint!);
    }
    

    final list = points.toList()..sort();
    return list;
  }

  // ─── File helpers ────────────────────────────────────────────────────────────

  Future<File> get _guardsFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/guards.json');
  }

  Future<File> get _attendanceFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/attendance.json');
  }

  Future<File> get _tiffinServicesFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/tiffin_services.json');
  }

  Future<File> get _tiffinEntriesFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/tiffin_entries.json');
  }

  // ─── Load ────────────────────────────────────────────────────────────────────

  Future<void> load() async {
    if (_loaded) return;
    try {
      final gf = await _guardsFile;
      if (await gf.exists()) {
        final list = jsonDecode(await gf.readAsString()) as List<dynamic>;
        _guards = list.map((e) => Guard.fromJson(e)).toList();
      }
    } catch (_) {}
    try {
      final af = await _attendanceFile;
      if (await af.exists()) {
        final list = jsonDecode(await af.readAsString()) as List<dynamic>;
        _attendance = list.map((e) => AttendanceRecord.fromJson(e)).toList();
      }
    } catch (_) {}
    try {
      final tf = await _tiffinServicesFile;
      if (await tf.exists()) {
        final list = jsonDecode(await tf.readAsString()) as List<dynamic>;
        _tiffinServices = list.map((e) => TiffinService.fromJson(e)).toList();
      }
    } catch (_) {}
    try {
      final te = await _tiffinEntriesFile;
      if (await te.exists()) {
        final list = jsonDecode(await te.readAsString()) as List<dynamic>;
        _tiffinEntries = list.map((e) => TiffinEntry.fromJson(e)).toList();
      }
    } catch (_) {}
    _loaded = true;
  }

  // ─── Save ────────────────────────────────────────────────────────────────────

  Future<void> saveGuards() async {
    final f = await _guardsFile;
    await f.writeAsString(jsonEncode(_guards.map((g) => g.toJson()).toList()));
    notifyListeners();
  }

  Future<void> saveAttendance() async {
    final f = await _attendanceFile;
    await f.writeAsString(jsonEncode(_attendance.map((a) => a.toJson()).toList()));
    notifyListeners();
  }

  Future<void> saveTiffinServices() async {
    final f = await _tiffinServicesFile;
    await f.writeAsString(jsonEncode(_tiffinServices.map((s) => s.toJson()).toList()));
    notifyListeners();
  }

  Future<void> saveTiffinEntries() async {
    final f = await _tiffinEntriesFile;
    await f.writeAsString(jsonEncode(_tiffinEntries.map((e) => e.toJson()).toList()));
    notifyListeners();
  }

  // ─── Backup helpers ──────────────────────────────────────────────────────────

  String buildBackupJson() {
    final data = {
      'version': 3,
      'exportedAt': DateTime.now().toIso8601String(),
      'guards': _guards.map((g) => g.toJson()).toList(),
      'attendance': _attendance.map((a) => a.toJson()).toList(),
      'tiffinServices': _tiffinServices.map((s) => s.toJson()).toList(),
      'tiffinEntries': _tiffinEntries.map((e) => e.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Save backup to temp directory — no storage permission needed on any Android version.
  /// File is shared via share sheet (Google Drive, WhatsApp, etc.)
  Future<String> saveBackupToFile() async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/dadaji_backup.json');
    await file.writeAsString(buildBackupJson());
    return file.path;
  }

  /// Import from JSON string. Returns null on success, error string on failure.
  Future<String?> importBackup(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      _guards = (data['guards'] as List<dynamic>)
          .map((e) => Guard.fromJson(e as Map<String, dynamic>))
          .toList();
      _attendance = (data['attendance'] as List<dynamic>)
          .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      if (data.containsKey('tiffinServices')) {
        _tiffinServices = (data['tiffinServices'] as List<dynamic>)
            .map((e) => TiffinService.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (data.containsKey('tiffinEntries')) {
        _tiffinEntries = (data['tiffinEntries'] as List<dynamic>)
            .map((e) => TiffinEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      await saveGuards();
      await saveAttendance();
      await saveTiffinServices();
      await saveTiffinEntries();
      return null;
    } catch (e) {
      return 'Failed to import: $e';
    }
  }

  // ─── Guards CRUD ─────────────────────────────────────────────────────────────

  Future<void> addGuard(Guard guard) async {
    if (guard.salaryHistory.isEmpty) {
      guard.salaryHistory.add(SalaryConfig(
        effectiveFrom: DateTime.now().toIso8601String().substring(0, 10),
        salary: guard.salary,
        dutyType: guard.dutyType,
        point: guard.point,
        dayPoint: guard.dayPoint,
        nightPoint: guard.nightPoint,
      ));
    }
    _guards.add(guard);
    _guards.sort((a, b) => a.name.compareTo(b.name));
    await saveGuards();
  }

  Future<void> updateGuard(Guard guard) async {
    final idx = _guards.indexWhere((g) => g.id == guard.id);
    if (idx != -1) {
      _guards[idx] = guard;
      _guards.sort((a, b) => a.name.compareTo(b.name));
      await saveGuards();
    }
  }

  Future<void> updateGuardSalaryConfig({
    required String guardId,
    required String effectiveFrom,
    required int newSalary,
    required String newDutyType,
    required String newPoint,
    required String newDayPoint,
    required String newNightPoint,
  }) async {
    final guard = getGuard(guardId);
    if (guard == null) return;
    guard.salaryHistory.removeWhere((c) => c.effectiveFrom == effectiveFrom);
    guard.salaryHistory.add(SalaryConfig(
      effectiveFrom: effectiveFrom,
      salary: newSalary,
      dutyType: newDutyType,
      point: newPoint,
      dayPoint: newDayPoint,
      nightPoint: newNightPoint,
    ));
    guard.salaryHistory.sort((a, b) => a.effectiveFrom.compareTo(b.effectiveFrom));
    guard.salary = newSalary;
    guard.dutyType = newDutyType;
    guard.point = newPoint;
    guard.dayPoint = newDayPoint;
    guard.nightPoint = newNightPoint;
    await saveGuards();
  }

  Future<void> deleteGuard(String id) async {
    _guards.removeWhere((g) => g.id == id);
    _attendance.removeWhere((a) => a.guardId == id);
    await saveGuards();
    await saveAttendance();
  }

  Guard? getGuard(String id) {
    try {
      return _guards.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  SalaryConfig? _configForDate(Guard guard, String date) {
    if (guard.salaryHistory.isEmpty) return null;
    SalaryConfig? best;
    for (final c in guard.salaryHistory) {
      if (c.effectiveFrom.compareTo(date) <= 0) {
        if (best == null || c.effectiveFrom.compareTo(best.effectiveFrom) > 0) {
          best = c;
        }
      }
    }
    return best;
  }

  // ─── Attendance ──────────────────────────────────────────────────────────────

  AttendanceRecord? getAttendance(String guardId, String date) {
    try {
      return _attendance.firstWhere((a) => a.guardId == guardId && a.date == date);
    } catch (_) {
      return null;
    }
  }

  List<AttendanceRecord> getAttendanceForDate(String date) =>
      _attendance.where((a) => a.date == date).toList();

  List<AttendanceRecord> getAttendanceForMonth(String guardId, String monthKey) =>
      _attendance.where((a) => a.guardId == guardId && a.date.startsWith(monthKey)).toList();

  Future<void> markAttendance(AttendanceRecord record) async {
    final idx = _attendance
        .indexWhere((a) => a.guardId == record.guardId && a.date == record.date);
    if (idx != -1) {
      _attendance[idx] = record;
    } else {
      _attendance.add(record);
    }
    await saveAttendance();
  }

  MonthlyAttendanceSummary getMonthlySummary(String guardId, String monthKey) {
    final records = getAttendanceForMonth(guardId, monthKey);
    final summary = MonthlyAttendanceSummary(guardId: guardId, monthKey: monthKey);
    for (final r in records) {
      if (r.status == 'A') {
        summary.absentDays++;
      } else if (r.status == 'PP') {
        summary.doubleDutyDays++;
        summary.overtimeAmount += r.overtimeAmount;
        if (r.cancelledDuty != null) summary.cancelledDays++;
      } else if (r.status == 'P') {
        summary.presentDays++;
        summary.singleDutyAmount += r.singleDutyAmount;
        if (r.cancelledDuty == 'all') summary.cancelledDays++;
      }
    }
    return summary;
  }

  // ─── Advance ─────────────────────────────────────────────────────────────────

  Future<void> addAdvance(String guardId, int amount, String remark) async {
    final guard = getGuard(guardId);
    if (guard == null) return;
    guard.advance += amount;
    guard.advanceLog.add(AdvanceEntry(
      id: const Uuid().v4(),
      date: DateTime.now().toIso8601String().substring(0, 10),
      amount: amount,
      remark: remark,
    ));
    await saveGuards();
  }

  Future<void> editAdvance(
      String guardId, String entryId, int newAmount, String newRemark) async {
    final guard = getGuard(guardId);
    if (guard == null) return;
    final idx = guard.advanceLog.indexWhere((e) => e.id == entryId);
    if (idx == -1) return;
    final old = guard.advanceLog[idx];
    guard.advance = guard.advance - old.amount + newAmount;
    guard.advanceLog[idx] =
        AdvanceEntry(id: entryId, date: old.date, amount: newAmount, remark: newRemark);
    await saveGuards();
  }

  Future<void> deleteAdvance(String guardId, String entryId) async {
    final guard = getGuard(guardId);
    if (guard == null) return;
    final entry = guard.advanceLog.firstWhere((e) => e.id == entryId,
        orElse: () => AdvanceEntry(id: '', date: '', amount: 0, remark: ''));
    if (entry.id.isEmpty) return;
    guard.advance -= entry.amount;
    if (guard.advance < 0) guard.advance = 0;
    guard.advanceLog.removeWhere((e) => e.id == entryId);
    await saveGuards();
  }

  Future<void> clearAdvance(String guardId) async {
    final guard = getGuard(guardId);
    if (guard == null) return;
    guard.advance = 0;
    await saveGuards();
  }

  // ─── Guard Tiffin (per-guard monthly deduction) ───────────────────────────────

  Future<void> addTiffin(String guardId, String monthKey, int amount) async {
    final guard = getGuard(guardId);
    if (guard == null) return;
    guard.tiffin[monthKey] = (guard.tiffin[monthKey] ?? 0) + amount;
    await saveGuards();
  }

  Future<void> editTiffin(
      String guardId, String oldMonthKey, String newMonthKey, int newAmount) async {
    final guard = getGuard(guardId);
    if (guard == null) return;
    guard.tiffin.remove(oldMonthKey);
    guard.tiffin[newMonthKey] = newAmount;
    await saveGuards();
  }

  Future<void> deleteTiffin(String guardId, String monthKey) async {
    final guard = getGuard(guardId);
    if (guard == null) return;
    guard.tiffin.remove(monthKey);
    await saveGuards();
  }

  Future<void> clearTiffin(String guardId, String monthKey) async {
    final guard = getGuard(guardId);
    if (guard == null) return;
    guard.tiffin.remove(monthKey);
    await saveGuards();
  }

  int getTiffin(String guardId, String monthKey) {
    final guard = getGuard(guardId);
    return guard?.tiffin[monthKey] ?? 0;
  }

  // ─── Tiffin Services CRUD ─────────────────────────────────────────────────────

  Future<void> addTiffinService(TiffinService service) async {
    _tiffinServices.add(service);
    _tiffinServices.sort((a, b) => a.name.compareTo(b.name));
    await saveTiffinServices();
  }

  Future<void> updateTiffinService(TiffinService service) async {
    final idx = _tiffinServices.indexWhere((s) => s.id == service.id);
    if (idx != -1) {
      _tiffinServices[idx] = service;
      await saveTiffinServices();
    }
  }

  Future<void> deleteTiffinService(String id) async {
    _tiffinServices.removeWhere((s) => s.id == id);
    _tiffinEntries.removeWhere((e) => e.serviceId == id);
    await saveTiffinServices();
    await saveTiffinEntries();
  }

  TiffinService? getTiffinService(String id) {
    try {
      return _tiffinServices.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  // ─── Tiffin Entries CRUD ──────────────────────────────────────────────────────

  Future<void> addTiffinEntry(TiffinEntry entry) async {
    // Replace existing entry for same service + date + shift
    _tiffinEntries.removeWhere((e) =>
        e.serviceId == entry.serviceId &&
        e.date == entry.date &&
        e.shift == entry.shift);
    _tiffinEntries.add(entry);
    await saveTiffinEntries();
  }

  Future<void> deleteTiffinEntry(String id) async {
    _tiffinEntries.removeWhere((e) => e.id == id);
    await saveTiffinEntries();
  }

  List<TiffinEntry> getTiffinEntriesForDate(String serviceId, String date) =>
      _tiffinEntries.where((e) => e.serviceId == serviceId && e.date == date).toList();

  List<TiffinEntry> getTiffinEntriesForMonth(String serviceId, String monthKey) =>
      _tiffinEntries.where((e) => e.serviceId == serviceId && e.date.startsWith(monthKey)).toList();

  TiffinEntry? getTiffinEntry(String serviceId, String date, String shift) {
    try {
      return _tiffinEntries.firstWhere(
          (e) => e.serviceId == serviceId && e.date == date && e.shift == shift);
    } catch (_) {
      return null;
    }
  }

  /// All unique point names known to the tiffin system
  List<String> get tiffinPoints {
    final points = <String>{};
    

    final list = points.toList()..sort();
    return list;
  }

  // ─── Salary calculation ───────────────────────────────────────────────────────

  SalarySlip calculateSalary(String guardId, String monthKey) {
    final guard = getGuard(guardId);
    if (guard == null) throw Exception('Guard not found');

    final year = int.parse(monthKey.split('-')[0]);
    final month = int.parse(monthKey.split('-')[1]);
    final totalDays = DateTime(year, month + 1, 0).day;

    final records = getAttendanceForMonth(guardId, monthKey);
    final segments = _buildSegments(guard, monthKey, year, month, totalDays, records);

    int totalPresentDays = 0;
    int totalDoubleDutyDays = 0;
    int totalAbsentDays = 0;
    int totalOvertimeAmount = 0;
    int totalSingleDutyAmount = 0;
    int totalEarnings = 0;

    for (final seg in segments) {
      totalPresentDays += seg.presentDays;
      totalDoubleDutyDays += seg.doubleDutyDays;
      totalAbsentDays += seg.absentDays;
      totalOvertimeAmount += seg.overtimeAmount;
      totalSingleDutyAmount += seg.singleDutyAmount;
      totalEarnings += seg.segmentTotal;
    }

    final tiffin = getTiffin(guardId, monthKey);
    final advanceToDeduct = guard.advance;
    final advanceEntries = List<AdvanceEntry>.from(guard.advanceLog);
    final netSalary = totalEarnings - advanceToDeduct - tiffin;

    return SalarySlip(
      guard: guard,
      monthKey: monthKey,
      totalDays: totalDays,
      presentDays: totalPresentDays,
      doubleDutyDays: totalDoubleDutyDays,
      absentDays: totalAbsentDays,
      overtimeAmount: totalOvertimeAmount,
      singleDutyAmount: totalSingleDutyAmount,
      totalEarnings: totalEarnings,
      advance: advanceToDeduct,
      advanceEntries: advanceEntries,
      tiffin: tiffin,
      netSalary: netSalary,
      segments: segments,
    );
  }

  List<SalarySegment> _buildSegments(
    Guard guard,
    String monthKey,
    int year,
    int month,
    int totalDays,
    List<AttendanceRecord> records,
  ) {
    final monthStart = '$monthKey-01';
    final monthEnd = '$monthKey-${totalDays.toString().padLeft(2, '0')}';
    final configs = <SalaryConfig>[];

    if (guard.salaryHistory.isEmpty) {
      configs.add(SalaryConfig(
        effectiveFrom: monthStart,
        salary: guard.salary,
        dutyType: guard.dutyType,
        point: guard.point,
        dayPoint: guard.dayPoint,
        nightPoint: guard.nightPoint,
      ));
    } else {
      SalaryConfig? atStart;
      for (final c in guard.salaryHistory) {
        if (c.effectiveFrom.compareTo(monthStart) <= 0) {
          if (atStart == null || c.effectiveFrom.compareTo(atStart.effectiveFrom) > 0) {
            atStart = c;
          }
        }
      }
      if (atStart != null) configs.add(atStart);
      for (final c in guard.salaryHistory) {
        if (c.effectiveFrom.compareTo(monthStart) > 0 &&
            c.effectiveFrom.compareTo(monthEnd) <= 0) {
          configs.add(c);
        }
      }
      final seen = <String>{};
      configs.retainWhere((c) => seen.add(c.effectiveFrom));
      configs.sort((a, b) => a.effectiveFrom.compareTo(b.effectiveFrom));
      if (configs.isEmpty) {
        final fallback = guard.salaryHistory.first;
        configs.add(SalaryConfig(
          effectiveFrom: monthStart,
          salary: fallback.salary,
          dutyType: fallback.dutyType,
          point: fallback.point,
          dayPoint: fallback.dayPoint,
          nightPoint: fallback.nightPoint,
        ));
      }
    }

    final result = <SalarySegment>[];
    for (int i = 0; i < configs.length; i++) {
      final cfg = configs[i];
      final segFrom = i == 0
          ? monthStart
          : cfg.effectiveFrom.compareTo(monthStart) < 0
              ? monthStart
              : cfg.effectiveFrom;
      final segTo = i < configs.length - 1
          ? _prevDay(configs[i + 1].effectiveFrom)
          : monthEnd;

      int presentDays = 0, doubleDutyDays = 0, absentDays = 0;
      int overtimeAmount = 0, singleDutyAmount = 0;
      for (final r in records) {
        if (r.date.compareTo(segFrom) >= 0 && r.date.compareTo(segTo) <= 0) {
          if (r.status == 'A') {
            absentDays++;
          } else if (r.status == 'PP') {
            if (r.cancelledDuty == 'all') {
              // Both shifts cancelled — treat as absent (no pay)
              absentDays++;
            } else if (r.cancelledDuty == 'day' || r.cancelledDuty == 'night') {
              // One shift cancelled — counts as single present (P)
              presentDays++;
              // DD guard doing only one shift → no singleDutyAmount deduction
              // (singleDutyAmount is only for a P record on a DD guard, not half-PP)
            } else {
              // No cancellation — full double duty
              doubleDutyDays++;
              if (cfg.dutyType != 'double') overtimeAmount += r.overtimeAmount;
            }
          } else if (r.status == 'P') {
            if (r.cancelledDuty == 'all') {
              // Duty fully cancelled — treat as absent (no pay)
              absentDays++;
            } else {
              presentDays++;
              if (cfg.dutyType == 'double') singleDutyAmount += r.singleDutyAmount;
            }
          }
        }
      }

      final workDays = presentDays + doubleDutyDays;
      final dailyRate = cfg.salary / totalDays;
      final basePay = (dailyRate * workDays).round();
      final segTotal = basePay -
          (cfg.dutyType == 'double' ? singleDutyAmount : 0) +
          (cfg.dutyType != 'double' ? overtimeAmount : 0);

      result.add(SalarySegment(
        salary: cfg.salary,
        dutyType: cfg.dutyType,
        totalDaysInMonth: totalDays,
        workDays: workDays,
        presentDays: presentDays,
        doubleDutyDays: doubleDutyDays,
        absentDays: absentDays,
        basePay: basePay,
        overtimeAmount: overtimeAmount,
        singleDutyAmount: singleDutyAmount,
        segmentTotal: segTotal,
        fromDate: segFrom,
        toDate: segTo,
      ));
    }
    return result;
  }

  String _prevDay(String dateStr) {
    final d = DateTime.parse(dateStr).subtract(const Duration(days: 1));
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  // ─── Mark salary as paid ──────────────────────────────────────────────────────

  Future<void> markSalaryPaid(String guardId, String monthKey) async {
    final guard = getGuard(guardId);
    if (guard == null) return;

    final slip = calculateSalary(guardId, monthKey);
    final year = int.parse(monthKey.split('-')[0]);
    final month = int.parse(monthKey.split('-')[1]);
    final totalDays = DateTime(year, month + 1, 0).day;

    guard.salarySlipHistory.removeWhere((r) => r.monthKey == monthKey);
    guard.salarySlipHistory.add(SalarySlipRecord(
      monthKey: monthKey,
      paidDate: DateTime.now().toIso8601String().substring(0, 10),
      totalDays: totalDays,
      presentDays: slip.presentDays,
      doubleDutyDays: slip.doubleDutyDays,
      absentDays: slip.absentDays,
      overtimeAmount: slip.overtimeAmount,
      singleDutyAmount: slip.singleDutyAmount,
      totalEarnings: slip.totalEarnings,
      advance: slip.advance,
      advanceEntries: List.from(slip.advanceEntries),
      tiffin: slip.tiffin,
      netSalary: slip.netSalary,
      segments: slip.segments,
    ));

    guard.advance = 0;
    guard.advanceLog.clear();
    guard.tiffin.remove(monthKey);
    await saveGuards();
  }

  SalarySlipRecord? getPaidSlipRecord(String guardId, String monthKey) {
    final guard = getGuard(guardId);
    if (guard == null) return null;
    try {
      return guard.salarySlipHistory.firstWhere((r) => r.monthKey == monthKey);
    } catch (_) {
      return null;
    }
  }
}

// ─── SalarySlip (in-memory calculation result) ───────────────────────────────

class SalarySlip {
  final Guard guard;
  final String monthKey;
  final int totalDays;
  final int presentDays;
  final int doubleDutyDays;
  final int absentDays;
  final int overtimeAmount;
  final int singleDutyAmount;
  final int totalEarnings;
  final int advance;
  final List<AdvanceEntry> advanceEntries;
  final int tiffin;
  final int netSalary;
  final List<SalarySegment> segments;

  SalarySlip({
    required this.guard,
    required this.monthKey,
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
  int get dailyRate => totalDays > 0 ? guard.salary ~/ totalDays : 0;
}
