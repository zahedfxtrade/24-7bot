import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/guard.dart';
import '../services/data_service.dart';
import 'add_guard_screen.dart';
import 'guard_detail_screen.dart';

class GuardsScreen extends StatefulWidget {
  const GuardsScreen({super.key});

  @override
  State<GuardsScreen> createState() => _GuardsScreenState();
}

class _GuardsScreenState extends State<GuardsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Guard> get _filteredGuards {
    final guards = DataService().guards;
    if (_query.isEmpty) return guards;
    return guards
        .where((g) =>
            g.name.toLowerCase().contains(_query.toLowerCase()) ||
            g.point.toLowerCase().contains(_query.toLowerCase()) ||
            g.mobile.contains(_query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final guards = _filteredGuards;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', height: 32),
            const SizedBox(width: 8),
            const Text('Guards'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              '${DataService().guards.length} Total',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.lightGold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: AppColors.navyBlue,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(color: AppColors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by name, point or mobile...',
                hintStyle:
                    TextStyle(color: AppColors.white.withOpacity(0.5), fontSize: 14),
                prefixIcon:
                    Icon(Icons.search, color: AppColors.white.withOpacity(0.7)),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: AppColors.white, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.gold, width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Guards list
          Expanded(
            child: guards.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: guards.length,
                    itemBuilder: (ctx, i) => _GuardCard(
                      guard: guards[i],
                      onRefresh: () => setState(() {}),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addGuard,
        backgroundColor: AppColors.navyBlue,
        foregroundColor: AppColors.white,
        elevation: 4,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined,
              size: 64, color: AppColors.textLight),
          const SizedBox(height: 12),
          Text(
            _query.isEmpty ? 'No guards added yet' : 'No guards found',
            style: const TextStyle(
                color: AppColors.textGrey, fontSize: 15),
          ),
          if (_query.isEmpty) ...[
            const SizedBox(height: 8),
            const Text('Tap + to add a guard',
                style: TextStyle(color: AppColors.textLight, fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Future<void> _addGuard() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddGuardScreen()),
    );
    if (result == true) setState(() {});
  }
}

class _GuardCard extends StatelessWidget {
  final Guard guard;
  final VoidCallback onRefresh;

  const _GuardCard({required this.guard, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final isDouble = guard.isDoubleDuty;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => GuardDetailScreen(guardId: guard.id)),
          );
          onRefresh();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isDouble
                      ? AppColors.doubleBlue
                      : AppColors.navyBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    guard.name.isNotEmpty
                        ? guard.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: isDouble
                          ? AppColors.doubleBlueText
                          : AppColors.navyBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            guard.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDouble
                                ? AppColors.doubleBlue
                                : AppColors.presentGreen,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isDouble ? 'DD' : 'SD',
                            style: TextStyle(
                              color: isDouble
                                  ? AppColors.doubleBlueText
                                  : AppColors.presentGreenText,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: AppColors.textGrey),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            guard.point,
                            style: const TextStyle(
                                color: AppColors.textGrey, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (guard.mobile.isNotEmpty) ...[
                          const Icon(Icons.phone_outlined,
                              size: 13, color: AppColors.textGrey),
                          const SizedBox(width: 3),
                          Text(
                            guard.mobile,
                            style: const TextStyle(
                                color: AppColors.textGrey, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.currency_rupee,
                            size: 13, color: AppColors.gold),
                        Text(
                          '${guard.salary.toStringAsFixed(0)} / month',
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (guard.advance > 0) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.warning_amber_rounded,
                              size: 13, color: AppColors.warning),
                          Text(
                            'Adv: ₹${guard.advance}',
                            style: const TextStyle(
                                color: AppColors.warning, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textLight, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
