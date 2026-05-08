import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../theme.dart';
import '../models/tiffin.dart';
import '../services/data_service.dart';

// ─── Main Tiffin Screen ───────────────────────────────────────────────────────

class TiffinScreen extends StatefulWidget {
  const TiffinScreen({super.key});
  @override
  State<TiffinScreen> createState() => _TiffinScreenState();
}

class _TiffinScreenState extends State<TiffinScreen> {
  DateTime _selectedDate = DateTime.now();

  String get _dateKey => DateFormat('yyyy-MM-dd').format(_selectedDate);
  String get _displayDate => DateFormat('EEE, dd MMM yyyy').format(_selectedDate);
  bool get _isToday => _dateKey == DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final services = DataService().tiffinServices;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tiffin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Go to today',
            onPressed: () => setState(() => _selectedDate = DateTime.now()),
          ),
        ],
      ),
      body: Column(children: [
        // Date strip
        Container(
          color: AppColors.navyBlue,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: AppColors.white),
              onPressed: () => setState(
                  () => _selectedDate = _selectedDate.subtract(const Duration(days: 1))),
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
                    if (_isToday) ...[
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
                  ? () => setState(
                      () => _selectedDate = _selectedDate.add(const Duration(days: 1)))
                  : null,
            ),
          ]),
        ),

        // Services list
        Expanded(
          child: services.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.lunch_dining, size: 56, color: AppColors.textLight),
                    const SizedBox(height: 12),
                    const Text('No tiffin services added yet',
                        style: TextStyle(color: AppColors.textGrey, fontSize: 15)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _showAddServiceDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Tiffin Service'),
                    ),
                  ]),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: services.length,
                  itemBuilder: (ctx, i) {
                    final svc = services[i];
                    return _TiffinServiceCard(
                      service: svc,
                      date: _dateKey,
                      onTap: () => _openServiceDetail(svc),
                      onMenuEdit: () => _showEditServiceDialog(svc),
                      onMenuDelete: () => _confirmDelete(svc),
                      onMenuReport: () => _openReport(svc),
                    );
                  },
                ),
        ),
      ]),
      floatingActionButton: services.isEmpty
          ? null
          : FloatingActionButton(
              heroTag: 'tiffin_fab',
              backgroundColor: AppColors.navyBlue,
              foregroundColor: AppColors.white,
              onPressed: _showAddServiceDialog,
              child: const Icon(Icons.add),
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
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _showAddServiceDialog() {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Tiffin Service'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Service Name *')),
          const SizedBox(height: 8),
          TextField(
              controller: mobileCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Mobile Number')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                await DataService().addTiffinService(TiffinService(
                  id: const Uuid().v4(),
                  name: nameCtrl.text.trim(),
                  mobile: mobileCtrl.text.trim(),
                ));
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                }
              },
              child: const Text('Save')),
        ],
      ),
    );
  }

  void _showEditServiceDialog(TiffinService svc) {
    final nameCtrl = TextEditingController(text: svc.name);
    final mobileCtrl = TextEditingController(text: svc.mobile);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Tiffin Service'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Service Name *')),
          const SizedBox(height: 8),
          TextField(
              controller: mobileCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Mobile Number')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                svc.name = nameCtrl.text.trim();
                svc.mobile = mobileCtrl.text.trim();
                await DataService().updateTiffinService(svc);
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                }
              },
              child: const Text('Save')),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(TiffinService svc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete ${svc.name}?'),
        content: const Text('All delivery records for this service will also be deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await DataService().deleteTiffinService(svc.id);
      if (mounted) setState(() {});
    }
  }

  void _openServiceDetail(TiffinService svc) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) =>
              TiffinServiceDetailScreen(service: svc, initialDate: _selectedDate)),
    ).then((_) => setState(() {}));
  }

  void _openReport(TiffinService svc) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TiffinReportScreen(service: svc)),
    );
  }
}

// ─── Service card ──────────────────────────────────────────────────────────────

class _TiffinServiceCard extends StatelessWidget {
  final TiffinService service;
  final String date;
  final VoidCallback onTap;
  final VoidCallback onMenuEdit;
  final VoidCallback onMenuDelete;
  final VoidCallback onMenuReport;

  const _TiffinServiceCard({
    required this.service,
    required this.date,
    required this.onTap,
    required this.onMenuEdit,
    required this.onMenuDelete,
    required this.onMenuReport,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DataService();
    final afternoon = ds.getTiffinEntry(service.id, date, 'afternoon');
    final night = ds.getTiffinEntry(service.id, date, 'night');
    final afCount = afternoon?.totalDabbas ?? 0;
    final ntCount = night?.totalDabbas ?? 0;
    final total = afCount + ntCount;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: AppColors.navyBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.lunch_dining, color: AppColors.navyBlue, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(service.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textDark)),
                if (service.mobile.isNotEmpty)
                  Text(service.mobile,
                      style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                const SizedBox(height: 4),
                if (total > 0)
                  Row(children: [
                    if (afCount > 0)
                      _ShiftBadge(label: '☀️ $afCount', color: AppColors.gold),
                    if (afCount > 0 && ntCount > 0) const SizedBox(width: 6),
                    if (ntCount > 0)
                      _ShiftBadge(label: '🌙 $ntCount', color: AppColors.navyBlue),
                    const SizedBox(width: 8),
                    Text('= $total dabbas',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark)),
                  ])
                else
                  const Text('No dabbas recorded today',
                      style: TextStyle(fontSize: 11, color: AppColors.textLight)),
              ]),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') onMenuEdit();
                if (v == 'report') onMenuReport();
                if (v == 'delete') onMenuDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit Service')),
                PopupMenuItem(value: 'report', child: Text('View Monthly Report')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              icon: const Icon(Icons.more_vert, color: AppColors.textGrey),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ShiftBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _ShiftBadge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Service Detail Screen ─────────────────────────────────────────────────────

class TiffinServiceDetailScreen extends StatefulWidget {
  final TiffinService service;
  final DateTime initialDate;
  const TiffinServiceDetailScreen(
      {super.key, required this.service, required this.initialDate});
  @override
  State<TiffinServiceDetailScreen> createState() =>
      _TiffinServiceDetailScreenState();
}

class _TiffinServiceDetailScreenState extends State<TiffinServiceDetailScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  String get _dateKey => DateFormat('yyyy-MM-dd').format(_selectedDate);
  String get _displayDate => DateFormat('EEE, dd MMM yyyy').format(_selectedDate);
  bool get _isToday => _dateKey == DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final ds = DataService();
    final afternoon = ds.getTiffinEntry(widget.service.id, _dateKey, 'afternoon');
    final night = ds.getTiffinEntry(widget.service.id, _dateKey, 'night');
    final afTotal = afternoon?.totalDabbas ?? 0;
    final ntTotal = night?.totalDabbas ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.service.name)),
      body: Column(children: [
        // Date strip
        Container(
          color: AppColors.navyBlue,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: AppColors.white),
              onPressed: () => setState(() =>
                  _selectedDate = _selectedDate.subtract(const Duration(days: 1))),
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
                    if (_isToday) ...[
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
                  ? () => setState(() =>
                      _selectedDate = _selectedDate.add(const Duration(days: 1)))
                  : null,
            ),
          ]),
        ),

        // Day total chip
        if (afTotal > 0 || ntTotal > 0)
          Container(
            color: AppColors.navyBlue.withOpacity(0.04),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              if (afTotal > 0)
                _ShiftBadge(label: '☀️ Afternoon: $afTotal', color: AppColors.gold),
              if (afTotal > 0 && ntTotal > 0) const SizedBox(width: 8),
              if (ntTotal > 0)
                _ShiftBadge(label: '🌙 Night: $ntTotal', color: AppColors.navyBlue),
              const Spacer(),
              Text('Total: ${afTotal + ntTotal} dabbas',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark)),
            ]),
          ),

        // Two big shift cards
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Expanded(
                child: _ShiftCard(
                  shift: 'afternoon',
                  emoji: '☀️',
                  label: 'Afternoon',
                  entry: afternoon,
                  service: widget.service,
                  date: _dateKey,
                  onSaved: () => setState(() {}),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _ShiftCard(
                  shift: 'night',
                  emoji: '🌙',
                  label: 'Night',
                  entry: night,
                  service: widget.service,
                  date: _dateKey,
                  onSaved: () => setState(() {}),
                ),
              ),
            ]),
          ),
        ),
      ]),
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
    if (picked != null) setState(() => _selectedDate = picked);
  }
}

// ─── Shift Card – big tappable card with +/– stepper ─────────────────────────

class _ShiftCard extends StatelessWidget {
  final String shift;
  final String emoji;
  final String label;
  final TiffinEntry? entry;
  final TiffinService service;
  final String date;
  final VoidCallback onSaved;

  const _ShiftCard({
    required this.shift,
    required this.emoji,
    required this.label,
    required this.entry,
    required this.service,
    required this.date,
    required this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    final count = entry?.totalDabbas ?? 0;
    final color = shift == 'afternoon' ? AppColors.gold : AppColors.navyBlue;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: count > 0
            ? BorderSide(color: color.withOpacity(0.4), width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _openDabbaDialog(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
            const SizedBox(height: 12),
            if (count > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text('$count dabbas',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: color)),
              ),
              const SizedBox(height: 10),
              Text('Tap to edit', style: TextStyle(fontSize: 12, color: color.withOpacity(0.7))),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.navyBlue.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text('Tap to add dabbas',
                    style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textGrey,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  void _openDabbaDialog(BuildContext context) {
    int current = entry?.totalDabbas ?? 0;
    final ctrl = TextEditingController(text: current > 0 ? '$current' : '');
    final color = shift == 'afternoon' ? AppColors.gold : AppColors.navyBlue;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, ss) {
        void bump(int delta) {
          final v = (int.tryParse(ctrl.text) ?? 0) + delta;
          if (v >= 0) {
            ctrl.text = '$v';
            ctrl.selection =
                TextSelection.fromPosition(TextPosition(offset: ctrl.text.length));
            ss(() {});
          }
        }

        return AlertDialog(
          title: Text('$emoji $label Dabbas – ${service.name}'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('How many dabbas were delivered?',
                style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
            const SizedBox(height: 20),
            // Stepper row
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _StepBtn(
                icon: Icons.remove,
                color: AppColors.absentRedText,
                bg: AppColors.absentRed,
                onTap: () => bump(-1),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  autofocus: true,
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: color),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: color),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: color, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (_) => ss(() {}),
                ),
              ),
              const SizedBox(width: 16),
              _StepBtn(
                icon: Icons.add,
                color: AppColors.presentGreenText,
                bg: AppColors.presentGreen,
                onTap: () => bump(1),
              ),
            ]),
            const SizedBox(height: 8),
            // Quick pick buttons
            Wrap(
              spacing: 8,
              children: [1, 2, 3, 4, 5, 6, 8, 10].map((n) {
                return ActionChip(
                  label: Text('$n'),
                  backgroundColor: color.withOpacity(0.1),
                  labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
                  onPressed: () {
                    ctrl.text = '$n';
                    ctrl.selection = TextSelection.fromPosition(
                        TextPosition(offset: ctrl.text.length));
                    ss(() {});
                  },
                );
              }).toList(),
            ),
          ]),
          actions: [
            if (entry != null)
              TextButton(
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                onPressed: () async {
                  await DataService().deleteTiffinEntry(entry!.id);
                  if (ctx.mounted) Navigator.pop(ctx);
                  onSaved();
                },
                child: const Text('Remove'),
              ),
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final count = int.tryParse(ctrl.text.trim()) ?? 0;
                if (count <= 0) {
                  // treat as delete/clear
                  if (entry != null) {
                    await DataService().deleteTiffinEntry(entry!.id);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  onSaved();
                  return;
                }
                await DataService().addTiffinEntry(TiffinEntry(
                  id: const Uuid().v4(),
                  serviceId: service.id,
                  date: date,
                  shift: shift,
                  dabbas: count,
                ));
                if (ctx.mounted) Navigator.pop(ctx);
                onSaved();
              },
              child: const Text('Save'),
            ),
          ],
        );
      }),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;
  const _StepBtn(
      {required this.icon,
      required this.color,
      required this.bg,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

// ─── Monthly Report Screen ─────────────────────────────────────────────────────

class TiffinReportScreen extends StatefulWidget {
  final TiffinService service;
  const TiffinReportScreen({super.key, required this.service});
  @override
  State<TiffinReportScreen> createState() => _TiffinReportScreenState();
}

class _TiffinReportScreenState extends State<TiffinReportScreen> {
  DateTime _month = DateTime.now();
  String get _monthKey => DateFormat('yyyy-MM').format(_month);
  String get _monthDisplay => DateFormat('MMMM yyyy').format(_month);

  @override
  Widget build(BuildContext context) {
    final ds = DataService();
    final entries = ds.getTiffinEntriesForMonth(widget.service.id, _monthKey);

    int totalDabbas = 0;
    int afternoonTotal = 0;
    int nightTotal = 0;

    for (final e in entries) {
      totalDabbas += e.totalDabbas;
      if (e.shift == 'afternoon') afternoonTotal += e.totalDabbas;
      if (e.shift == 'night') nightTotal += e.totalDabbas;
    }

    // Group by date
    final byDate = <String, List<TiffinEntry>>{};
    for (final e in entries) {
      byDate.putIfAbsent(e.date, () => []).add(e);
    }
    final sortedDates = byDate.keys.toList()..sort();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('${widget.service.name} – Report')),
      body: Column(children: [
        // Month selector
        Container(
          color: AppColors.navyBlue,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: AppColors.white),
              onPressed: () => setState(
                  () => _month = DateTime(_month.year, _month.month - 1)),
            ),
            Expanded(
              child: Center(
                  child: Text(_monthDisplay,
                      style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15))),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: AppColors.white),
              onPressed:
                  DateTime(_month.year, _month.month + 1).isAfter(DateTime.now())
                      ? null
                      : () => setState(
                          () => _month = DateTime(_month.year, _month.month + 1)),
            ),
          ]),
        ),

        Expanded(
          child: entries.isEmpty
              ? const Center(
                  child: Text('No deliveries recorded this month.',
                      style: TextStyle(color: AppColors.textGrey)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Summary cards
                    Row(children: [
                      Expanded(
                          child: _StatCard(
                              icon: Icons.lunch_dining,
                              color: AppColors.navyBlue,
                              label: 'Total Dabbas',
                              value: '$totalDabbas')),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _StatCard(
                              icon: Icons.wb_sunny_outlined,
                              color: AppColors.gold,
                              label: 'Afternoon',
                              value: '$afternoonTotal')),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _StatCard(
                              icon: Icons.nightlight_outlined,
                              color: AppColors.navyBlue,
                              label: 'Night',
                              value: '$nightTotal')),
                    ]),
                    const SizedBox(height: 20),

                    // Daily log
                    const Text('Daily Log',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    ...sortedDates.map((date) {
                      final dayEntries = byDate[date]!;
                      final fmt = DateFormat('EEE, dd MMM')
                          .format(DateTime.parse(date));
                      final dayTotal =
                          dayEntries.fold(0, (s, e) => s + e.totalDabbas);
                      final af = dayEntries
                          .where((e) => e.shift == 'afternoon')
                          .fold(0, (s, e) => s + e.totalDabbas);
                      final nt = dayEntries
                          .where((e) => e.shift == 'night')
                          .fold(0, (s, e) => s + e.totalDabbas);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Row(children: [
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(fmt,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: AppColors.navyBlue)),
                                const SizedBox(height: 4),
                                Row(children: [
                                  if (af > 0) ...[
                                    const Text('☀️ ',
                                        style: TextStyle(fontSize: 12)),
                                    Text('$af',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textDark)),
                                    const SizedBox(width: 12),
                                  ],
                                  if (nt > 0) ...[
                                    const Text('🌙 ',
                                        style: TextStyle(fontSize: 12)),
                                    Text('$nt',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textDark)),
                                  ],
                                ]),
                              ]),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.navyBlue.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('$dayTotal dabbas',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AppColors.navyBlue)),
                            ),
                          ]),
                        ),
                      );
                    }),
                  ],
                ),
        ),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _StatCard(
      {required this.icon,
      required this.color,
      required this.label,
      required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppColors.textGrey),
            textAlign: TextAlign.center),
      ]),
    );
  }
}
