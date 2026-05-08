import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../models/guard.dart';
import '../models/attendance.dart';
import '../services/data_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  final Set<String> _selected = {};
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _dateKey => DateFormat('yyyy-MM-dd').format(_selectedDate);
  String get _displayDate => DateFormat('EEE, dd MMM yyyy').format(_selectedDate);

  Map<String, AttendanceRecord> _buildAttendanceMap() {
    final dayAttendance = DataService().getAttendanceForDate(_dateKey);
    return {for (var a in dayAttendance) a.guardId: a};
  }

  List<Guard> get _filteredGuards {
    final guards = DataService().guards;
    if (_searchQuery.isEmpty) return guards;
    return guards.where((g) => g.name.toLowerCase().contains(_searchQuery)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final guards = DataService().guards;
    final attendanceMap = _buildAttendanceMap();
    final dayAttendance = attendanceMap.values.toList();
    final filteredGuards = _filteredGuards;
    final isToday = _dateKey == DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Go to today',
            onPressed: () => setState(() {
              _selectedDate = DateTime.now();
              _selected.clear();
            }),
          ),
        ],
      ),
      body: Column(children: [
        Container(
          color: AppColors.navyBlue,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: AppColors.white),
              onPressed: () => setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                _selected.clear();
              }),
            ),
            Expanded(
              child: GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.calendar_today, color: AppColors.gold, size: 16),
                    const SizedBox(width: 8),
                    Text(_displayDate,
                        style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    if (isToday) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(10)),
                        child: const Text('Today',
                            style: TextStyle(
                                fontSize: 10,
                                color: AppColors.navyBlue,
                                fontWeight: FontWeight.w700)),
                      )
                    ],
                  ]),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: AppColors.white),
              onPressed: _selectedDate.isBefore(DateTime.now())
                  ? () => setState(() {
                        _selectedDate = _selectedDate.add(const Duration(days: 1));
                        _selected.clear();
                      })
                  : null,
            ),
          ]),
        ),
        Container(
          color: AppColors.navyBlue.withOpacity(0.04),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search guard name…',
              prefixIcon: const Icon(Icons.search, color: AppColors.textGrey),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textGrey),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
        if (dayAttendance.isNotEmpty)
          Container(
            color: AppColors.navyBlue.withOpacity(0.04),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              _summaryChip('P', dayAttendance.where((a) => a.status == 'P').length,
                  AppColors.presentGreenText, AppColors.presentGreen),
              const SizedBox(width: 8),
              _summaryChip('PP', dayAttendance.where((a) => a.status == 'PP').length,
                  AppColors.doubleBlueText, AppColors.doubleBlue),
              const SizedBox(width: 8),
              _summaryChip('A', dayAttendance.where((a) => a.status == 'A').length,
                  AppColors.absentRedText, AppColors.absentRed),
              const Spacer(),
              Text('${dayAttendance.length}/${guards.length} marked',
                  style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
            ]),
          ),
        Expanded(
          child: guards.isEmpty
              ? const Center(
                  child: Text('No guards added yet',
                      style: TextStyle(color: AppColors.textGrey)))
              : filteredGuards.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.search_off, color: AppColors.textLight, size: 40),
                        const SizedBox(height: 8),
                        Text('No guard named "$_searchQuery"',
                            style: const TextStyle(color: AppColors.textGrey)),
                      ]),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredGuards.length,
                      itemBuilder: (ctx, i) {
                        final g = filteredGuards[i];
                        final rec = attendanceMap[g.id];
                        final isSelected = _selected.contains(g.id);
                        return _AttendanceGuardTile(
                          guard: g,
                          record: rec,
                          isSelected: isSelected,
                          onTap: () => setState(() {
                            if (isSelected)
                              _selected.remove(g.id);
                            else
                              _selected.add(g.id);
                          }),
                          onCancelDuty: rec != null ? () => _cancelDuty(g, rec) : null,
                        );
                      },
                    ),
        ),
      ]),
      bottomNavigationBar: _selected.isNotEmpty ? _buildActionBar() : null,
    );
  }

  Widget _summaryChip(String label, int count, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text('$label: $count',
          style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, -3))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${_selected.length} guard(s) selected',
            style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _actionBtn('P\nPresent', AppColors.presentGreen,
              AppColors.presentGreenText, () => _markSelected('P'))),
          const SizedBox(width: 8),
          Expanded(child: _actionBtn('PP\nDouble Duty', AppColors.doubleBlue,
              AppColors.doubleBlueText, () => _markSelected('PP'))),
          const SizedBox(width: 8),
          Expanded(child: _actionBtn('A\nAbsent', AppColors.absentRed,
              AppColors.absentRedText, () => _markSelected('A'))),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => setState(() => _selected.clear()),
            icon: const Icon(Icons.close, color: AppColors.textGrey),
          ),
        ]),
      ]),
    );
  }

  Widget _actionBtn(String label, Color bg, Color fg, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Center(
            child: Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: fg, fontWeight: FontWeight.w700, fontSize: 13, height: 1.3))),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
              primary: AppColors.navyBlue, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null)
      setState(() {
        _selectedDate = picked;
        _selected.clear();
      });
  }

  Future<void> _markSelected(String status) async {
    final selectedIds = List<String>.from(_selected);
    final ds = DataService();

    if (status == 'P') {
      for (final id in selectedIds) {
        final g = ds.getGuard(id)!;
        if (g.isDoubleDuty) {
          final result = await _askDDSingleDuty(g);
          if (result != null) {
            await ds.markAttendance(AttendanceRecord(
                guardId: id,
                date: _dateKey,
                status: 'P',
                point: result['point'] as String,
                singleDutyAmount: result['amount'] as int));
          }
        } else {
          final result = await _askSDPoint(g);
          if (result != null) {
            await ds.markAttendance(AttendanceRecord(
                guardId: id,
                date: _dateKey,
                status: 'P',
                point: result['point'] as String));
          }
        }
      }
    } else if (status == 'PP') {
      for (final id in selectedIds) {
        final g = ds.getGuard(id)!;
        if (g.isDoubleDuty) {
          final result = await _askDDDoubleDutyPoints(g);
          if (result != null) {
            await ds.markAttendance(AttendanceRecord(
                guardId: id,
                date: _dateKey,
                status: 'PP',
                point: result['dayPoint'] as String,
                nightPoint: result['nightPoint'] as String));
          }
        } else {
          final result = await _askOvertimeDetails(g);
          if (result != null) {
            await ds.markAttendance(AttendanceRecord(
                guardId: id,
                date: _dateKey,
                status: 'PP',
                point: result['point'] as String,
                nightPoint: result['nightPoint'] as String,
                overtimeAmount: result['amount'] as int));
          }
        }
      }
    } else {
      for (final id in selectedIds) {
        final g = ds.getGuard(id)!;
        final reason = await _askAbsentReason(g);
        if (reason != null) {
          await ds.markAttendance(AttendanceRecord(
              guardId: id,
              date: _dateKey,
              status: 'A',
              point: g.point,
              absentReason: reason));
        }
      }
    }

    if (mounted) setState(() => _selected.clear());
  }

  // ─── Cancel duty ────────────────────────────────────────────────────────────

  Future<void> _cancelDuty(Guard g, AttendanceRecord rec) async {
    if (rec.status == 'PP') {
      final choice = await _askCancelPPChoice(g, rec);
      if (choice == null) return;
      final reason = await _askCancelReason(g, choice);
      if (reason == null) return;
      rec.cancelledDuty = choice;
      rec.cancelReason = reason;
      await DataService().markAttendance(rec);
      if (mounted) setState(() {});
    } else {
      if (rec.cancelledDuty != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${g.name}\'s duty already cancelled. Reason: ${rec.cancelReason}'),
              backgroundColor: AppColors.absentRedText,
            ),
          );
        }
        return;
      }
      final reason = await _askCancelReason(g, 'all');
      if (reason == null) return;
      rec.cancelledDuty = 'all';
      rec.cancelReason = reason;
      await DataService().markAttendance(rec);
      if (mounted) setState(() {});
    }
  }

  Future<String?> _askCancelPPChoice(Guard g, AttendanceRecord rec) async {
    final cancelledDuty = rec.cancelledDuty;
    final dayAlreadyCancelled = cancelledDuty == 'day' || cancelledDuty == 'all';
    final nightAlreadyCancelled = cancelledDuty == 'night' || cancelledDuty == 'all';

    if (dayAlreadyCancelled && nightAlreadyCancelled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${g.name}\'s both duties are already cancelled.'),
            backgroundColor: AppColors.absentRedText,
          ),
        );
      }
      return null;
    }

    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Cancel Duty – ${g.name}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
            'Guard has Double Duty (PP).\nWhich duty do you want to cancel?',
            style: TextStyle(fontSize: 13, color: AppColors.textGrey),
          ),
          const SizedBox(height: 16),
          if (!dayAlreadyCancelled)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.wb_sunny_outlined, color: AppColors.gold),
              ),
              title: const Text('Day Duty', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(rec.point.isNotEmpty ? rec.point : '–',
                  style: const TextStyle(fontSize: 12)),
              onTap: () => Navigator.pop(context, 'day'),
            ),
          if (!nightAlreadyCancelled)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.navyBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.nightlight_outlined, color: AppColors.navyBlue),
              ),
              title: const Text('Night Duty', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text((rec.nightPoint ?? '').isNotEmpty ? rec.nightPoint! : '–',
                  style: const TextStyle(fontSize: 12)),
              onTap: () => Navigator.pop(context, 'night'),
            ),
          if (!dayAlreadyCancelled && !nightAlreadyCancelled)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.absentRed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.cancel_outlined, color: AppColors.absentRedText),
              ),
              title: const Text('Both Duties', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Cancel Day + Night', style: TextStyle(fontSize: 12)),
              onTap: () => Navigator.pop(context, 'all'),
            ),
          if (dayAlreadyCancelled)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(children: [
                const Icon(Icons.info_outline, size: 14, color: AppColors.textGrey),
                const SizedBox(width: 4),
                const Text('Day duty already cancelled',
                    style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
              ]),
            ),
          if (nightAlreadyCancelled)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(children: [
                const Icon(Icons.info_outline, size: 14, color: AppColors.textGrey),
                const SizedBox(width: 4),
                const Text('Night duty already cancelled',
                    style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
              ]),
            ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back')),
        ],
      ),
    );
  }

  Future<String?> _askCancelReason(Guard g, String dutyChoice) async {
    final ctrl = TextEditingController();
    final dutyLabel = dutyChoice == 'day'
        ? 'Day Duty'
        : dutyChoice == 'night'
            ? 'Night Duty'
            : 'Duty';
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Cancel $dutyLabel – ${g.name}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Enter reason for cancellation:',
              style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Reason',
              hintText: "e.g. Guard didn't show up, Client request…",
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context,
                  ctrl.text.trim().isNotEmpty ? ctrl.text.trim() : 'No reason given');
            },
            child: const Text('Cancel Duty'),
          ),
        ],
      ),
    );
  }

  // ─── Point dialogs ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> _askSDPoint(Guard g) async {
    final allPoints = DataService().knownPoints;
    final pointCtrl = TextEditingController(text: g.point);
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${g.name} – Present (P)'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Confirm duty point for today:',
              style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
          const SizedBox(height: 12),
          _PointField(controller: pointCtrl, label: 'Duty Point', allPoints: allPoints),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'point': pointCtrl.text.trim().isNotEmpty ? pointCtrl.text.trim() : g.point,
                });
              },
              child: const Text('Confirm & Save')),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _askDDSingleDuty(Guard g) async {
    final allPoints = DataService().knownPoints;
    String shift = 'day';
    final pointCtrl = TextEditingController(text: g.dayPoint.isNotEmpty ? g.dayPoint : g.point);
    final amtCtrl = TextEditingController();

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, ss) {
        return AlertDialog(
          title: Text('${g.name} – Single Duty (P)'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Double duty guard doing single duty.\nSelect shift:',
                  style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: _ShiftChip(
                    label: 'Day Duty',
                    selected: shift == 'day',
                    onTap: () => ss(() {
                      shift = 'day';
                      pointCtrl.text = g.dayPoint.isNotEmpty ? g.dayPoint : g.point;
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ShiftChip(
                    label: 'Night Duty',
                    selected: shift == 'night',
                    onTap: () => ss(() {
                      shift = 'night';
                      pointCtrl.text = g.nightPoint.isNotEmpty ? g.nightPoint : g.point;
                    }),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              _PointField(controller: pointCtrl, label: 'Duty Point', allPoints: allPoints),
              const SizedBox(height: 8),
              TextField(
                controller: amtCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Single Duty Amount (₹)', prefixText: '₹ '),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx, {
                    'shift': shift,
                    'point': pointCtrl.text.trim().isNotEmpty ? pointCtrl.text.trim() : g.point,
                    'amount': int.tryParse(amtCtrl.text.trim()) ?? 0,
                  });
                },
                child: const Text('Confirm & Save')),
          ],
        );
      }),
    );
  }

  Future<Map<String, dynamic>?> _askDDDoubleDutyPoints(Guard g) async {
    final allPoints = DataService().knownPoints;
    final dayCtrl = TextEditingController(text: g.dayPoint.isNotEmpty ? g.dayPoint : g.point);
    final nightCtrl = TextEditingController(text: g.nightPoint);

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${g.name} – Double Duty (PP)'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Confirm day & night duty points:',
                style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
            const SizedBox(height: 12),
            _PointField(controller: dayCtrl, label: 'Day Point', allPoints: allPoints),
            const SizedBox(height: 8),
            _PointField(controller: nightCtrl, label: 'Night Point', allPoints: allPoints),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'dayPoint': dayCtrl.text.trim().isNotEmpty ? dayCtrl.text.trim() : g.dayPoint,
                  'nightPoint': nightCtrl.text.trim().isNotEmpty
                      ? nightCtrl.text.trim()
                      : g.nightPoint,
                });
              },
              child: const Text('Confirm & Save')),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _askOvertimeDetails(Guard g) async {
    final allPoints = DataService().knownPoints;
    final pointCtrl = TextEditingController(text: g.point);
    final nightCtrl = TextEditingController();
    final amtCtrl = TextEditingController();

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${g.name} – Double Duty (PP)'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Single duty guard doing overtime:',
                style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
            const SizedBox(height: 10),
            _PointField(controller: pointCtrl, label: 'Day Point', allPoints: allPoints),
            const SizedBox(height: 8),
            _PointField(controller: nightCtrl, label: 'Night Point', allPoints: allPoints),
            const SizedBox(height: 8),
            TextField(
              controller: amtCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Overtime Amount (₹)', prefixText: '₹ '),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'point': pointCtrl.text.trim().isNotEmpty ? pointCtrl.text.trim() : g.point,
                  'nightPoint': nightCtrl.text.trim(),
                  'amount': int.tryParse(amtCtrl.text.trim()) ?? 0,
                });
              },
              child: const Text('Confirm & Save')),
        ],
      ),
    );
  }

  Future<String?> _askAbsentReason(Guard g) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${g.name} – Absent (A)'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Enter reason for absence:',
              style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Reason',
              hintText: 'e.g. Sick leave, Personal work…',
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context,
                    ctrl.text.trim().isNotEmpty ? ctrl.text.trim() : 'No reason given');
              },
              child: const Text('Mark Absent')),
        ],
      ),
    );
  }
}

// ─── Point field with autocomplete ──────────────────────────────────────────

class _PointField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final List<String> allPoints;
  const _PointField(
      {required this.controller, required this.label, required this.allPoints});
  @override
  State<_PointField> createState() => _PointFieldState();
}

class _PointFieldState extends State<_PointField> {
  List<String> _suggestions = [];
  void _onChanged(String val) {
    final q = val.toLowerCase();
    setState(() {
      _suggestions = q.isEmpty
          ? []
          : widget.allPoints
              .where((p) => p.toLowerCase().contains(q) && p.toLowerCase() != q)
              .take(5)
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
              controller: widget.controller,
              onChanged: _onChanged,
              decoration: InputDecoration(labelText: widget.label)),
          if (_suggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)
                ],
              ),
              child: Column(
                children: _suggestions
                    .map((s) => InkWell(
                          onTap: () {
                            widget.controller.text = s;
                            widget.controller.selection =
                                TextSelection.fromPosition(
                                    TextPosition(offset: s.length));
                            setState(() => _suggestions = []);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Row(children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 14, color: AppColors.textGrey),
                              const SizedBox(width: 6),
                              Text(s, style: const TextStyle(fontSize: 13)),
                            ]),
                          ),
                        ))
                    .toList(),
              ),
            ),
        ]);
  }
}

// ─── Shift chip ──────────────────────────────────────────────────────────────

class _ShiftChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ShiftChip(
      {required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.navyBlue
              : AppColors.navyBlue.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected ? AppColors.navyBlue : AppColors.divider),
        ),
        child: Center(
            child: Text(label,
                style: TextStyle(
                    color: selected ? AppColors.white : AppColors.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 13))),
      ),
    );
  }
}

// ─── Guard tile ──────────────────────────────────────────────────────────────

class _AttendanceGuardTile extends StatelessWidget {
  final Guard guard;
  final AttendanceRecord? record;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onCancelDuty;

  const _AttendanceGuardTile({
    required this.guard,
    this.record,
    required this.isSelected,
    required this.onTap,
    this.onCancelDuty,
  });

  Color get _statusBg => record == null
      ? Colors.transparent
      : record!.status == 'P'
          ? AppColors.presentGreen
          : record!.status == 'PP'
              ? AppColors.doubleBlue
              : AppColors.absentRed;

  Color get _statusFg => record == null
      ? AppColors.textLight
      : record!.status == 'P'
          ? AppColors.presentGreenText
          : record!.status == 'PP'
              ? AppColors.doubleBlueText
              : AppColors.absentRedText;

  String get _pointDisplay {
    if (record == null) return guard.point;
    if (record!.status == 'PP') {
      final day = record!.point.isNotEmpty ? record!.point : '–';
      final night =
          (record!.nightPoint ?? '').isNotEmpty ? record!.nightPoint! : '–';
      return 'Day: $day  •  Night: $night';
    }
    return record!.point.isNotEmpty ? record!.point : guard.point;
  }

  bool get _hasCancellation => record?.cancelledDuty != null;

  String get _cancellationLabel {
    final cd = record?.cancelledDuty;
    if (cd == null) return '';
    if (cd == 'day') return '☀️ Day Cancelled';
    if (cd == 'night') return '🌙 Night Cancelled';
    return '🚫 Duty Cancelled';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isSelected
            ? const BorderSide(color: AppColors.navyBlue, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: isSelected ? AppColors.navyBlue : AppColors.divider,
                    width: 2),
                color: isSelected ? AppColors.navyBlue : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
              Text(guard.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textDark)),
              Row(children: [
                Text(guard.isDoubleDuty ? 'DD' : 'SD',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textGrey)),
                const Text(' • ',
                    style: TextStyle(color: AppColors.textLight)),
                Expanded(
                    child: Text(_pointDisplay,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textGrey),
                        overflow: TextOverflow.ellipsis)),
              ]),
              if (record != null &&
                  record!.status == 'A' &&
                  (record!.absentReason ?? '').isNotEmpty)
                Text('Reason: ${record!.absentReason}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.absentRedText)),
              if (record != null &&
                  record!.status == 'PP' &&
                  record!.overtimeAmount > 0)
                Text('OT: ₹${record!.overtimeAmount}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.doubleBlueText)),
              if (record != null &&
                  record!.status == 'P' &&
                  record!.singleDutyAmount > 0)
                Text('Amt: ₹${record!.singleDutyAmount}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.presentGreenText)),
              if (_hasCancellation) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.absentRed,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_cancellationLabel,
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.absentRedText,
                          fontWeight: FontWeight.w600)),
                ),
                if ((record!.cancelReason ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('Why: ${record!.cancelReason}',
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.absentRedText)),
                  ),
              ],
            ])),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 44,
                height: 36,
                decoration: BoxDecoration(
                    color: _statusBg,
                    borderRadius: BorderRadius.circular(8)),
                child: Center(
                    child: Text(record?.status ?? '–',
                        style: TextStyle(
                            color: _statusFg,
                            fontWeight: FontWeight.w700,
                            fontSize: 14))),
              ),
              if (record != null && onCancelDuty != null) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: onCancelDuty,
                  child: Container(
                    width: 44,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.absentRed,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text('✕ Cancel',
                          style: TextStyle(
                              color: AppColors.absentRedText,
                              fontSize: 9,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ]),
          ]),
        ),
      ),
    );
  }
}
