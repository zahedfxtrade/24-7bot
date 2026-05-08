import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../models/guard.dart';
import '../services/data_service.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});
  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  String _selectedMonth = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final prev = DateTime(now.year, now.month - 1);
    _selectedMonth = '${prev.year}-${prev.month.toString().padLeft(2, '0')}';
  }

  List<String> get _monthOptions {
    final now = DateTime.now();
    return List.generate(12, (i) {
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
    final guards = DataService().guards;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Payments')),
      body: Column(children: [
        Container(
          color: AppColors.navyBlue,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: DropdownButtonFormField<String>(
            value: _selectedMonth,
            dropdownColor: AppColors.navyBlue,
            style: const TextStyle(color: AppColors.white, fontSize: 14),
            icon: const Icon(Icons.arrow_drop_down, color: AppColors.gold),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.calendar_month, color: AppColors.gold, size: 20),
              filled: true,
              fillColor: Colors.white.withOpacity(0.12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.gold)),
            ),
            items: _monthOptions.map((m) => DropdownMenuItem(
                value: m,
                child: Text(_fmtMonth(m), style: const TextStyle(color: AppColors.white)))).toList(),
            onChanged: (v) { if (v != null) setState(() => _selectedMonth = v); },
          ),
        ),
        Expanded(
          child: guards.isEmpty
              ? const Center(child: Text('No guards added yet',
                  style: TextStyle(color: AppColors.textGrey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: guards.length,
                  itemBuilder: (ctx, i) => _PaymentCard(
                    guard: guards[i],
                    monthKey: _selectedMonth,
                    onRefresh: () => setState(() {}),
                  ),
                ),
        ),
      ]),
    );
  }
}

// ─── Payment card (list item) ────────────────────────────────────────────────

class _PaymentCard extends StatelessWidget {
  final Guard guard;
  final String monthKey;
  final VoidCallback onRefresh;

  const _PaymentCard({required this.guard, required this.monthKey, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final ds = DataService();
    final paidRecord = ds.getPaidSlipRecord(guard.id, monthKey);
    final isPaid = paidRecord != null;

    int workDays, netSalary, advance, tiffin;
    List<SalarySegment> segments;

    if (isPaid) {
      workDays  = paidRecord.workDays;
      netSalary = paidRecord.netSalary;
      advance   = paidRecord.advance;
      tiffin    = paidRecord.tiffin;
      segments  = paidRecord.segments;
    } else {
      final slip = ds.calculateSalary(guard.id, monthKey);
      workDays  = slip.workDays;
      netSalary = slip.netSalary;
      advance   = slip.advance;
      tiffin    = slip.tiffin;
      segments  = slip.segments;
    }

    final multiSegment = segments.length > 1;
    final netColor = netSalary >= 0 ? AppColors.success : AppColors.error;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showSlip(context, isPaid, paidRecord),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: AppColors.navyBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(guard.name[0].toUpperCase(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                      color: AppColors.navyBlue))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(guard.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
                        color: AppColors.textDark))),
                if (isPaid)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.presentGreen,
                        borderRadius: BorderRadius.circular(20)),
                    child: const Text('PAID',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                            color: AppColors.presentGreenText)),
                  ),
              ]),
              const SizedBox(height: 2),
              Text('$workDays days worked${multiSegment ? " (split salary)" : ""}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
              if (advance > 0 || tiffin > 0)
                Text('Adv: ₹$advance${tiffin > 0 ? " • Tiffin: ₹$tiffin" : ""}',
                    style: const TextStyle(fontSize: 11, color: AppColors.warning)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('₹$netSalary',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: netColor)),
              const Text('Net Salary', style: TextStyle(fontSize: 10, color: AppColors.textGrey)),
            ]),
          ]),
        ),
      ),
    );
  }

  void _showSlip(BuildContext context, bool isPaid, SalarySlipRecord? record) {
    if (isPaid && record != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _SlipSheet(
          guard: guard,
          monthKey: monthKey,
          isPaid: true,
          paidRecord: record,
        ),
      );
    } else {
      final slip = DataService().calculateSalary(guard.id, monthKey);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _SlipSheet(
          guard: guard,
          monthKey: monthKey,
          isPaid: false,
          liveSlip: slip,
          onPaid: () async {
            await DataService().markSalaryPaid(guard.id, monthKey);
            onRefresh();
          },
        ),
      );
    }
  }
}

// ─── Salary slip bottom sheet (handles both live and historical) ──────────────

class _SlipSheet extends StatelessWidget {
  final Guard guard;
  final String monthKey;
  final bool isPaid;
  final SalarySlip? liveSlip;
  final SalarySlipRecord? paidRecord;
  final VoidCallback? onPaid;

  const _SlipSheet({
    required this.guard,
    required this.monthKey,
    required this.isPaid,
    this.liveSlip,
    this.paidRecord,
    this.onPaid,
  });

  String _fmtMonth(String mk) {
    final p = mk.split('-');
    return DateFormat('MMMM yyyy').format(DateTime(int.parse(p[0]), int.parse(p[1])));
  }

  String _fmtDate(String d) {
    // d = YYYY-MM-DD → DD MMM
    final parts = d.split('-');
    return DateFormat('dd MMM').format(DateTime(int.parse(parts[0]),
        int.parse(parts[1]), int.parse(parts[2])));
  }

  // Extract values from either source
  int get _totalDays    => isPaid ? paidRecord!.totalDays    : liveSlip!.totalDays;
  int get _presentDays  => isPaid ? paidRecord!.presentDays  : liveSlip!.presentDays;
  int get _doubleDays   => isPaid ? paidRecord!.doubleDutyDays : liveSlip!.doubleDutyDays;
  int get _absentDays   => isPaid ? paidRecord!.absentDays   : liveSlip!.absentDays;
  int get _totalEarnings=> isPaid ? paidRecord!.totalEarnings: liveSlip!.totalEarnings;
  int get _advance      => isPaid ? paidRecord!.advance      : liveSlip!.advance;
  int get _tiffin       => isPaid ? paidRecord!.tiffin       : liveSlip!.tiffin;
  int get _netSalary    => isPaid ? paidRecord!.netSalary    : liveSlip!.netSalary;
  int get _workDays     => _presentDays + _doubleDays;
  List<SalarySegment> get _segments => isPaid ? paidRecord!.segments : liveSlip!.segments;
  List<AdvanceEntry> get _advanceEntries =>
      isPaid ? paidRecord!.advanceEntries : liveSlip!.advanceEntries;

  @override
  Widget build(BuildContext context) {
    final netColor = _netSalary >= 0 ? AppColors.success : AppColors.error;
    final multiSeg = _segments.length > 1;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: ctrl,
          padding: const EdgeInsets.all(24),
          children: [
            // Handle
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),

            // Header
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPaid ? AppColors.presentGreen : AppColors.navyBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.receipt_long,
                    color: isPaid ? AppColors.presentGreenText : AppColors.navyBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Text('Salary Slip',
                      style: TextStyle(fontSize: 11, color: AppColors.textGrey, letterSpacing: 1)),
                  if (isPaid) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.presentGreen,
                          borderRadius: BorderRadius.circular(20)),
                      child: const Text('PAID',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                              color: AppColors.presentGreenText)),
                    ),
                  ],
                ]),
                Text(guard.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
                Text(_fmtMonth(monthKey),
                    style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
                if (isPaid)
                  Text('Paid on ${paidRecord!.paidDate}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
              ])),
            ]),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),

            // Overall attendance summary
            _row('Total Days in Month', '$_totalDays days'),
            _row('Total Work Days', '$_workDays days'),
            _row('Present (P)', '$_presentDays days', muted: true),
            _row('Double Duty (PP)', '$_doubleDays days', muted: true),
            _row('Absent (A)', '$_absentDays days', muted: true),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),

            // ── Salary segments ───────────────────────────────────────────────
            if (multiSeg) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.navyBlue.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: const [
                  Icon(Icons.info_outline, size: 14, color: AppColors.navyBlue),
                  SizedBox(width: 6),
                  Expanded(child: Text('Salary changed mid-month — calculated separately per period.',
                      style: TextStyle(fontSize: 12, color: AppColors.navyBlue))),
                ]),
              ),
              const SizedBox(height: 12),
            ],

            ..._segments.map((seg) => _buildSegmentBlock(seg, multiSeg)),

            const Divider(),
            _row('Gross Earnings', '₹$_totalEarnings', bold: true),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),

            // ── Advance entries itemized ──────────────────────────────────────
            if (_advanceEntries.isNotEmpty) ...[
              const Text('Advance Deductions',
                  style: TextStyle(fontSize: 12, color: AppColors.textGrey,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              ..._advanceEntries.map((e) => _advanceRow(e)),
              _row('Total Advance', '– ₹$_advance', color: AppColors.error),
              const SizedBox(height: 4),
            ] else if (_advance > 0) ...[
              _row('Advance', '– ₹$_advance', color: AppColors.error),
            ],

            if (_tiffin > 0)
              _row('Tiffin', '– ₹$_tiffin', color: AppColors.error),

            const SizedBox(height: 8),
            // Net salary box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _netSalary >= 0 ? AppColors.presentGreen : AppColors.absentRed,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Net Salary',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: netColor)),
                Text('₹$_netSalary',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: netColor)),
              ]),
            ),
            const SizedBox(height: 20),

            // Actions
            if (!isPaid) ...[
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onPaid?.call();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Payment done! Advance & tiffin reset.'),
                      backgroundColor: AppColors.success));
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Mark as Paid'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 0)),
              ),
              const SizedBox(height: 10),
            ],
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 0)),
              child: Text(isPaid ? 'Close' : 'Pay Later'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─── Build one salary segment block ─────────────────────────────────────────

  Widget _buildSegmentBlock(SalarySegment seg, bool showHeader) {
    final isDD = seg.dutyType == 'double';
    final dailyRate = seg.dailyRate.round();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (showHeader) ...[
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.navyBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_fmtDate(seg.fromDate)} – ${_fmtDate(seg.toDate)}  •  ₹${seg.salary}/mo  •  ${isDD ? "DD" : "SD"}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: AppColors.navyBlue),
              ),
            ),
          ]),
          const SizedBox(height: 10),
        ],
        _row('Salary / Month', '₹${seg.salary}', muted: true),
        _row('Daily Rate', '₹$dailyRate', muted: true),
        _row('Work Days', '${seg.workDays} days', muted: true),
        _row('Base Pay', '₹${seg.basePay}', muted: false),
        if (!isDD && seg.overtimeAmount > 0)
          _row('Overtime (PP)', '+ ₹${seg.overtimeAmount}', color: AppColors.success),
        if (isDD && seg.singleDutyAmount > 0)
          _row('Single Duty', '+ ₹${seg.singleDutyAmount}', color: AppColors.success),
        const Divider(height: 10),
        _row('Segment Total', '₹${seg.segmentTotal}', bold: true),
      ]),
    );
  }

  // ─── One advance entry row ───────────────────────────────────────────────────

  Widget _advanceRow(AdvanceEntry e) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(children: [
        const Icon(Icons.remove_circle_outline, size: 14, color: AppColors.error),
        const SizedBox(width: 6),
        Text(e.date, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
        const SizedBox(width: 6),
        Text('₹${e.amount}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: AppColors.error)),
        if (e.remark.isNotEmpty) ...[
          const SizedBox(width: 6),
          Expanded(child: Text(e.remark,
              style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
              overflow: TextOverflow.ellipsis)),
        ],
      ]),
    );
  }

  // ─── Shared row widget ───────────────────────────────────────────────────────

  Widget _row(String label, String value,
      {bool bold = false, bool muted = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: TextStyle(fontSize: 13,
                color: muted ? AppColors.textGrey : AppColors.textDark,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
        Text(value,
            style: TextStyle(fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: color ?? AppColors.textDark)),
      ]),
    );
  }
}
