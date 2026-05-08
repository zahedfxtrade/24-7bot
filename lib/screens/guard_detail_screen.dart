import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../models/guard.dart';
import '../models/attendance.dart';
import '../services/data_service.dart';
import 'add_guard_screen.dart';

class GuardDetailScreen extends StatefulWidget {
  final String guardId;
  const GuardDetailScreen({super.key, required this.guardId});

  @override
  State<GuardDetailScreen> createState() => _GuardDetailScreenState();
}

class _GuardDetailScreenState extends State<GuardDetailScreen> {
  Guard? guard;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => setState(() => guard = DataService().getGuard(widget.guardId));

  String _currentMonthKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  String _prevMonthKey() {
    final now = DateTime.now();
    final prev = DateTime(now.year, now.month - 1);
    return '${prev.year}-${prev.month.toString().padLeft(2, '0')}';
  }

  List<String> _last6Months() {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final d = DateTime(now.year, now.month - i);
      return '${d.year}-${d.month.toString().padLeft(2, '0')}';
    });
  }

  String _fmtMonth(String mk) {
    final p = mk.split('-');
    return DateFormat('MMMM yyyy').format(DateTime(int.parse(p[0]), int.parse(p[1])));
  }

  @override
  Widget build(BuildContext context) {
    if (guard == null) return const Scaffold(body: Center(child: Text('Guard not found')));
    final g = guard!;
    final mk  = _currentMonthKey();
    final pmk = _prevMonthKey();
    final curr      = DataService().getMonthlySummary(g.id, mk);
    final prev      = DataService().getMonthlySummary(g.id, pmk);
    final currTiffin = DataService().getTiffin(g.id, mk);
    final prevTiffin = DataService().getTiffin(g.id, pmk);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(g.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => AddGuardScreen(guard: g)));
              _load();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _infoCard(g),
          const SizedBox(height: 12),
          _monthCard('Current Month', mk, curr, currTiffin, g),
          const SizedBox(height: 12),
          _monthCard('Previous Month', pmk, prev, prevTiffin, g),
          const SizedBox(height: 12),
          _advanceCard(g),
          const SizedBox(height: 12),
          _actionButtons(g),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── Info card ───────────────────────────────────────────────────────────────

  Widget _infoCard(Guard g) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: g.isDoubleDuty ? AppColors.doubleBlue : AppColors.navyBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Text(g.name[0].toUpperCase(),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                      color: g.isDoubleDuty ? AppColors.doubleBlueText : AppColors.navyBlue))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(g.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: g.isDoubleDuty ? AppColors.doubleBlue : AppColors.presentGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(g.isDoubleDuty ? 'Double Duty' : 'Single Duty',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: g.isDoubleDuty ? AppColors.doubleBlueText : AppColors.presentGreenText)),
              ),
            ])),
          ]),
          const Divider(height: 20),
          _infoRow(Icons.phone_outlined,       'Mobile',   g.mobile.isNotEmpty ? g.mobile : 'Not set'),
          _infoRow(Icons.currency_rupee,        'Salary',   '₹${g.salary}'),
          _infoRow(Icons.location_on_outlined,  'Point',    g.point),
          if (g.isDoubleDuty) ...[
            _infoRow(Icons.wb_sunny_outlined,   'Day Point',   g.dayPoint),
            _infoRow(Icons.nightlight_outlined, 'Night Point', g.nightPoint),
          ],
          // Show history of salary changes if any
          if (g.salaryHistory.length > 1) ...[
            const Divider(height: 16),
            const Text('Salary Change History',
                style: TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            ...g.salaryHistory.reversed.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                const Icon(Icons.history, size: 13, color: AppColors.textLight),
                const SizedBox(width: 6),
                Text(c.effectiveFrom,
                    style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                const SizedBox(width: 8),
                Text('₹${c.salary}  •  ${c.dutyType == 'double' ? 'DD' : 'SD'}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textDark)),
              ]),
            )),
          ],
        ]),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 16, color: AppColors.textGrey),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
        Expanded(child: Text(value,
            style: const TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
    );
  }

  // ─── Month summary card ──────────────────────────────────────────────────────

  Widget _monthCard(String title, String mk, MonthlyAttendanceSummary summary, int tiffin, Guard g) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navyBlue)),
          Text(_fmtMonth(mk), style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
          const SizedBox(height: 12),
          Row(children: [
            _statChip('Present', '${summary.presentDays}', AppColors.presentGreen, AppColors.presentGreenText),
            const SizedBox(width: 8),
            _statChip('Double',  '${summary.doubleDutyDays}', AppColors.doubleBlue, AppColors.doubleBlueText),
            const SizedBox(width: 8),
            _statChip('Absent',  '${summary.absentDays}', AppColors.absentRed, AppColors.absentRedText),
          ]),
          if (summary.overtimeAmount > 0 && !g.isDoubleDuty) ...[
            const SizedBox(height: 8),
            _infoRow(Icons.timer_outlined,     'Overtime', '₹${summary.overtimeAmount}'),
          ],
          if (summary.singleDutyAmount > 0 && g.isDoubleDuty) ...[
            const SizedBox(height: 8),
            _infoRow(Icons.currency_rupee, 'Single Duty', '₹${summary.singleDutyAmount}'),
          ],
          if (tiffin > 0) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => _editTiffin(g, mk, tiffin),
              child: Row(children: [
                Expanded(child: _infoRow(Icons.restaurant_outlined, 'Tiffin', '₹$tiffin')),
                const Icon(Icons.edit_outlined, size: 15, color: AppColors.textGrey),
              ]),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _statChip(String label, String value, Color bg, Color fg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Column(children: [
          Text(value, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 16)),
          Text(label, style: TextStyle(color: fg, fontSize: 10)),
        ]),
      ),
    );
  }

  // ─── Advance card with edit / delete per entry ───────────────────────────────

  Widget _advanceCard(Guard g) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Advance Balance',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            Text('₹${g.advance}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                    color: g.advance > 0 ? AppColors.warning : AppColors.success)),
          ]),
          if (g.advanceLog.isNotEmpty) ...[
            const Divider(height: 16),
            const Text('Advance Entries',
                style: TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...g.advanceLog.reversed.map((e) => _advanceEntryTile(g, e)),
          ],
        ]),
      ),
    );
  }

  Widget _advanceEntryTile(Guard g, AdvanceEntry e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('₹${e.amount}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textDark)),
            const SizedBox(width: 8),
            Text(e.date, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
          ]),
          if (e.remark.isNotEmpty)
            Text(e.remark, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
        ])),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.navyBlue),
          onPressed: () => _editAdvanceEntry(g, e),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
          onPressed: () => _deleteAdvanceEntry(g, e),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ]),
    );
  }

  // ─── Action buttons ──────────────────────────────────────────────────────────

  Widget _actionButtons(Guard g) {
    return Column(children: [
      Row(children: [
        Expanded(child: OutlinedButton.icon(
          onPressed: () => _addAdvance(g),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add Advance'),
        )),
        const SizedBox(width: 10),
        Expanded(child: OutlinedButton.icon(
          onPressed: () => _addTiffin(g),
          icon: const Icon(Icons.restaurant, size: 16),
          label: const Text('Add Tiffin'),
        )),
      ]),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _updateSalaryConfig(g),
          icon: const Icon(Icons.currency_rupee, size: 16),
          label: const Text('Update Salary / Duty Type'),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.warning,
              side: const BorderSide(color: AppColors.warning)),
        ),
      ),
    ]);
  }

  // ─── Add advance ─────────────────────────────────────────────────────────────

  void _addAdvance(Guard g) {
    final amtCtrl = TextEditingController();
    final remCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Advance'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: amtCtrl, keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Amount (₹)', prefixText: '₹ ')),
          const SizedBox(height: 12),
          TextField(controller: remCtrl,
              decoration: const InputDecoration(labelText: 'Remark (optional)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            final amt = int.tryParse(amtCtrl.text.trim());
            if (amt == null || amt <= 0) return;
            await DataService().addAdvance(g.id, amt, remCtrl.text.trim());
            if (mounted) { Navigator.pop(context); _load(); }
          }, child: const Text('Save')),
        ],
      ),
    );
  }

  // ─── Edit advance entry ───────────────────────────────────────────────────────

  void _editAdvanceEntry(Guard g, AdvanceEntry entry) {
    final amtCtrl = TextEditingController(text: entry.amount.toString());
    final remCtrl = TextEditingController(text: entry.remark);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Advance'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Date: ${entry.date}',
              style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
          const SizedBox(height: 12),
          TextField(controller: amtCtrl, keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Amount (₹)', prefixText: '₹ ')),
          const SizedBox(height: 12),
          TextField(controller: remCtrl,
              decoration: const InputDecoration(labelText: 'Remark')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            final amt = int.tryParse(amtCtrl.text.trim());
            if (amt == null || amt <= 0) return;
            await DataService().editAdvance(g.id, entry.id, amt, remCtrl.text.trim());
            if (mounted) { Navigator.pop(context); _load(); }
          }, child: const Text('Update')),
        ],
      ),
    );
  }

  // ─── Delete advance entry ─────────────────────────────────────────────────────

  void _deleteAdvanceEntry(Guard g, AdvanceEntry entry) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Advance'),
        content: Text('Delete ₹${entry.amount} advance from ${entry.date}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await DataService().deleteAdvance(g.id, entry.id);
              if (mounted) { Navigator.pop(context); _load(); }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ─── Add tiffin (month picker) ────────────────────────────────────────────────

  void _addTiffin(Guard g) {
    final ctrl = TextEditingController();
    String selectedMonth = _currentMonthKey();
    final months = _last6Months();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Add Tiffin'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              value: selectedMonth,
              decoration: const InputDecoration(labelText: 'Month',
                  prefixIcon: Icon(Icons.calendar_month, size: 18)),
              items: months.map((m) => DropdownMenuItem(
                  value: m, child: Text(_fmtMonth(m)))).toList(),
              onChanged: (v) { if (v != null) setDlg(() => selectedMonth = v); },
            ),
            const SizedBox(height: 14),
            TextField(controller: ctrl, keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Amount (₹)', prefixText: '₹ ')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(onPressed: () async {
              final amt = int.tryParse(ctrl.text.trim());
              if (amt == null || amt <= 0) return;
              await DataService().addTiffin(g.id, selectedMonth, amt);
              if (mounted) { Navigator.pop(ctx); _load(); }
            }, child: const Text('Save')),
          ],
        ),
      ),
    );
  }

  // ─── Edit / Delete tiffin ─────────────────────────────────────────────────

  void _editTiffin(Guard g, String monthKey, int currentAmount) {
    final ctrl = TextEditingController(text: currentAmount.toString());
    String selectedMonth = monthKey;
    final months = _last6Months();
    // Ensure current month is in the list
    if (!months.contains(monthKey)) months.insert(0, monthKey);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Edit Tiffin'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              value: selectedMonth,
              decoration: const InputDecoration(
                  labelText: 'Month',
                  prefixIcon: Icon(Icons.calendar_month, size: 18)),
              items: months
                  .map((m) => DropdownMenuItem(value: m, child: Text(_fmtMonth(m))))
                  .toList(),
              onChanged: (v) { if (v != null) setDlg(() => selectedMonth = v); },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
              decoration: const InputDecoration(
                  labelText: 'Amount (₹)', prefixText: '₹ '),
            ),
          ]),
          actions: [
            // Delete button on the left
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: ctx,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete Tiffin?'),
                    content: Text(
                        'Remove ₹$currentAmount tiffin for ${_fmtMonth(monthKey)}?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await DataService().deleteTiffin(g.id, monthKey);
                  if (mounted) { Navigator.pop(ctx); _load(); }
                }
              },
              child: const Text('Delete'),
            ),
            const Spacer(),
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final amt = int.tryParse(ctrl.text.trim());
                if (amt == null || amt <= 0) return;
                await DataService()
                    .editTiffin(g.id, monthKey, selectedMonth, amt);
                if (mounted) { Navigator.pop(ctx); _load(); }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Update salary / duty-type mid-month ─────────────────────────────────────

  void _updateSalaryConfig(Guard g) {
    final salCtrl = TextEditingController(text: g.salary.toString());
    final pointCtrl = TextEditingController(text: g.point);
    final dayPointCtrl = TextEditingController(text: g.dayPoint);
    final nightPointCtrl = TextEditingController(text: g.nightPoint);
    String dutyType = g.dutyType;
    // Default effective-from = today
    DateTime effectiveDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Update Salary / Duty'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Effective from date
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: effectiveDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (c, child) => Theme(
                      data: Theme.of(c).copyWith(
                        colorScheme: const ColorScheme.light(primary: AppColors.navyBlue),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setDlg(() => effectiveDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today, size: 16, color: AppColors.navyBlue),
                    const SizedBox(width: 8),
                    Text('Effective from: ${DateFormat('dd MMM yyyy').format(effectiveDate)}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
                  ]),
                ),
              ),
              const SizedBox(height: 6),
              const Text('Changes apply from this date onward in salary slip',
                  style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
              const SizedBox(height: 14),

              TextField(controller: salCtrl, keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'New Salary (₹)', prefixText: '₹ ')),
              const SizedBox(height: 14),

              // Duty type toggle
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(children: [
                  _dutyTile('single', 'Single Duty', dutyType, (v) => setDlg(() => dutyType = v)),
                  Divider(height: 1, color: AppColors.divider),
                  _dutyTile('double', 'Double Duty', dutyType, (v) => setDlg(() => dutyType = v)),
                ]),
              ),
              const SizedBox(height: 14),

              if (dutyType == 'single') ...[
                TextField(controller: pointCtrl,
                    decoration: const InputDecoration(labelText: 'Duty Point')),
              ] else ...[
                TextField(controller: dayPointCtrl,
                    decoration: const InputDecoration(labelText: 'Day Point')),
                const SizedBox(height: 10),
                TextField(controller: nightPointCtrl,
                    decoration: const InputDecoration(labelText: 'Night Point')),
              ],
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(onPressed: () async {
              final sal = int.tryParse(salCtrl.text.trim());
              if (sal == null || sal <= 0) return;
              final effDate =
                  '${effectiveDate.year}-${effectiveDate.month.toString().padLeft(2, '0')}-${effectiveDate.day.toString().padLeft(2, '0')}';
              final point = dutyType == 'single' ? pointCtrl.text.trim() : dayPointCtrl.text.trim();
              await DataService().updateGuardSalaryConfig(
                guardId: g.id,
                effectiveFrom: effDate,
                newSalary: sal,
                newDutyType: dutyType,
                newPoint: point,
                newDayPoint: dutyType == 'double' ? dayPointCtrl.text.trim() : point,
                newNightPoint: dutyType == 'double' ? nightPointCtrl.text.trim() : '',
              );
              if (mounted) { Navigator.pop(ctx); _load(); }
            }, child: const Text('Save')),
          ],
        ),
      ),
    );
  }

  Widget _dutyTile(String value, String label, String current, ValueChanged<String> onChange) {
    final selected = current == value;
    return InkWell(
      onTap: () => onChange(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Expanded(child: Text(label,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
                  color: selected ? AppColors.navyBlue : AppColors.textDark))),
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: selected ? AppColors.navyBlue : AppColors.divider, width: 2),
              color: selected ? AppColors.navyBlue : Colors.transparent,
            ),
            child: selected ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
          ),
        ]),
      ),
    );
  }

  // ─── Delete guard ─────────────────────────────────────────────────────────────

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Guard'),
        content: Text('Delete ${guard!.name}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await DataService().deleteGuard(guard!.id);
              if (mounted) { Navigator.pop(context); Navigator.pop(context, true); }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
