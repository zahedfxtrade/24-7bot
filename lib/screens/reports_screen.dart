import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../services/data_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedMonth = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  List<String> get _months {
    final opts = <String>[];
    final now = DateTime.now();
    for (int i = 0; i < 6; i++) {
      final d = DateTime(now.year, now.month - i);
      opts.add('${d.year}-${d.month.toString().padLeft(2, '0')}');
    }
    return opts;
  }

  String _fmt(String mk) {
    final p = mk.split('-');
    return DateFormat('MMMM yyyy').format(DateTime(int.parse(p[0]), int.parse(p[1])));
  }

  @override
  Widget build(BuildContext context) {
    final guards = DataService().guards;
    final ds = DataService();

    int totalPresent = 0, totalDouble = 0, totalAbsent = 0;
    int totalSalaryPayable = 0, totalAdvance = 0;

    for (final g in guards) {
      final s = ds.calculateSalary(g.id, _selectedMonth);
      totalPresent += s.presentDays;
      totalDouble += s.doubleDutyDays;
      totalAbsent += s.absentDays;
      if (s.netSalary > 0) totalSalaryPayable += s.netSalary;
      totalAdvance += g.advance;
    }

    final pointMap = <String, List<String>>{};
    for (final g in guards) {
      pointMap.putIfAbsent(g.point, () => []).add(g.name);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Reports & Overview')),
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
              prefixIcon: const Icon(Icons.bar_chart, color: AppColors.gold, size: 20),
              filled: true, fillColor: Colors.white.withOpacity(0.12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
            items: _months.map((m) => DropdownMenuItem(value: m,
                child: Text(_fmt(m), style: const TextStyle(color: AppColors.white)))).toList(),
            onChanged: (v) { if (v != null) setState(() => _selectedMonth = v); },
          ),
        ),
        Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
          // Summary cards
          Row(children: [
            _StatCard('Guards', '${guards.length}', Icons.shield, AppColors.navyBlue),
            const SizedBox(width: 10),
            _StatCard('Single Duty', '${guards.where((g) => !g.isDoubleDuty).length}', Icons.person, AppColors.presentGreenText),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _StatCard('Double Duty', '${guards.where((g) => g.isDoubleDuty).length}', Icons.people, AppColors.doubleBlueText),
            const SizedBox(width: 10),
            _StatCard('Total Advance', '₹$totalAdvance', Icons.account_balance_wallet, AppColors.warning),
          ]),
          const SizedBox(height: 16),
          // Monthly stats
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${_fmt(_selectedMonth)} – Attendance', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navyBlue)),
              const SizedBox(height: 12),
              Row(children: [
                _MiniStat('Present', '$totalPresent', AppColors.presentGreen, AppColors.presentGreenText),
                const SizedBox(width: 8),
                _MiniStat('PP', '$totalDouble', AppColors.doubleBlue, AppColors.doubleBlueText),
                const SizedBox(width: 8),
                _MiniStat('Absent', '$totalAbsent', AppColors.absentRed, AppColors.absentRedText),
              ]),
              const Divider(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Total Payable', style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
                Text('₹$totalSalaryPayable', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navyBlue)),
              ]),
            ],
          ))),
          const SizedBox(height: 12),
          // Points
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Guards by Location', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navyBlue)),
              const SizedBox(height: 12),
              ...pointMap.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.gold),
                    const SizedBox(width: 4),
                    Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.navyBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Text('${e.value.length}', style: const TextStyle(fontSize: 11, color: AppColors.navyBlue, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Wrap(spacing: 6, children: e.value.map((name) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.divider)),
                    child: Text(name, style: const TextStyle(fontSize: 12, color: AppColors.textDark)),
                  )).toList()),
                ]),
              )),
            ],
          ))),
          const SizedBox(height: 12),
          // Per guard summary
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${_fmt(_selectedMonth)} – Guard Summary', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navyBlue)),
              const SizedBox(height: 12),
              if (guards.isEmpty) const Text('No guards', style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
              ...guards.map((g) {
                final s = ds.calculateSalary(g.id, _selectedMonth);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Container(width: 34, height: 34,
                        decoration: BoxDecoration(color: AppColors.navyBlue.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                        child: Center(child: Text(g.name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navyBlue, fontSize: 14)))),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(g.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark)),
                      Text('${s.workDays}d worked • Adv: ₹${g.advance}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                    ])),
                    Text('₹${s.netSalary}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                        color: s.netSalary >= 0 ? AppColors.success : AppColors.error)),
                  ]),
                );
              }),
            ],
          ))),
          // About
          const SizedBox(height: 12),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, children: [
              Image.asset('assets/images/logo.png', height: 50),
              const SizedBox(height: 8),
              const Text('Dadaji Security Services', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.navyBlue)),
              const Text('Safeguarding Your Peace of Mind', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
              const Divider(height: 20),
              const Text('Developed by Mohd Zahed', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
              const SizedBox(height: 4),
              const Text('📸 zahedfxtrade', style: TextStyle(fontSize: 12, color: AppColors.navyBlue)),
              const Text('✉️ zahedfxtrade@gmail.com', style: TextStyle(fontSize: 12, color: AppColors.navyBlue)),
            ],
          ))),
          const SizedBox(height: 24),
        ])),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Card(child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
      ]),
    ]))),
  );
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color bg, fg;
  const _MiniStat(this.label, this.value, this.bg, this.fg);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(value, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 18)),
        Text(label, style: TextStyle(color: fg, fontSize: 11)),
      ]),
    ),
  );
}
