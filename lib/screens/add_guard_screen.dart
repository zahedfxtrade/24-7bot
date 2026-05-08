import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../theme.dart';
import '../models/guard.dart';
import '../services/data_service.dart';

class AddGuardScreen extends StatefulWidget {
  final Guard? guard; // if editing
  const AddGuardScreen({super.key, this.guard});

  @override
  State<AddGuardScreen> createState() => _AddGuardScreenState();
}

class _AddGuardScreenState extends State<AddGuardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  // Single duty
  final _pointCtrl = TextEditingController();
  String _singleShift = 'day'; // 'day' or 'night'
  // Double duty
  final _dayPointCtrl = TextEditingController();
  final _nightPointCtrl = TextEditingController();

  String _dutyType = 'single';
  bool _saving = false;

  bool get isEditing => widget.guard != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final g = widget.guard!;
      _nameCtrl.text = g.name;
      _mobileCtrl.text = g.mobile;
      _salaryCtrl.text = g.salary.toString();
      _dutyType = g.dutyType;
      if (g.isDoubleDuty) {
        _dayPointCtrl.text = g.dayPoint;
        _nightPointCtrl.text = g.nightPoint;
      } else {
        _pointCtrl.text = g.point;
        // Detect shift from stored data (point == dayPoint → day, else night)
        _singleShift =
            (g.nightPoint.isNotEmpty && g.nightPoint != g.dayPoint)
                ? 'night'
                : 'day';
        // More reliable: we store shift in a way dayPoint == point for day,
        // nightPoint == point for night. Re-derive:
        _singleShift = (g.dayPoint == g.point) ? 'day' : 'night';
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _salaryCtrl.dispose();
    _pointCtrl.dispose();
    _dayPointCtrl.dispose();
    _nightPointCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final name = _nameCtrl.text.trim();
    final mobile = _mobileCtrl.text.trim();
    final salary =
        int.parse(_salaryCtrl.text.trim().replaceAll(',', ''));

    String point, dayPoint, nightPoint;

    if (_dutyType == 'double') {
      dayPoint = _dayPointCtrl.text.trim();
      nightPoint = _nightPointCtrl.text.trim();
      // Default point = day point (as requested)
      point = dayPoint;
    } else {
      point = _pointCtrl.text.trim();
      // For single duty: store the shift in dayPoint / nightPoint fields
      dayPoint = _singleShift == 'day' ? point : '';
      nightPoint = _singleShift == 'night' ? point : '';
    }

    if (isEditing) {
      final g = widget.guard!;
      g.name = name;
      g.mobile = mobile;
      g.salary = salary;
      g.point = point;
      g.dayPoint = dayPoint;
      g.nightPoint = nightPoint;
      g.dutyType = _dutyType;
      await DataService().updateGuard(g);
    } else {
      final guard = Guard(
        id: const Uuid().v4(),
        name: name,
        mobile: mobile,
        salary: salary,
        point: point,
        dayPoint: dayPoint,
        nightPoint: nightPoint,
        dutyType: _dutyType,
      );
      await DataService().addGuard(guard);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Guard' : 'Add Guard'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Save',
                    style: TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionLabel('Guard Information'),
            const SizedBox(height: 12),
            _buildField(
              controller: _nameCtrl,
              label: 'Guard Name *',
              hint: 'Enter full name',
              icon: Icons.person_outline,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
              capitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _mobileCtrl,
              label: 'Mobile Number',
              hint: 'Enter mobile number (optional)',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _salaryCtrl,
              label: 'Monthly Salary *',
              hint: 'Enter amount in ₹',
              icon: Icons.currency_rupee,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Salary is required' : null,
              prefix: '₹ ',
            ),
            const SizedBox(height: 24),
            _sectionLabel('Duty Configuration'),
            const SizedBox(height: 12),
            // Duty type selector
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  _dutyOption(
                    'single',
                    'Single Duty',
                    'Regular guard – one shift per day',
                    Icons.person,
                  ),
                  Divider(height: 1, color: AppColors.divider),
                  _dutyOption(
                    'double',
                    'Double Duty',
                    'Day & night shift – salary includes both',
                    Icons.people,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (_dutyType == 'single') ...[
              // Point name
              _buildField(
                controller: _pointCtrl,
                label: 'Duty Point / Location *',
                hint: 'e.g. Main Gate, Block A',
                icon: Icons.location_on_outlined,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Duty point is required'
                    : null,
                capitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 14),
              // Shift selector (Day / Night)
              _sectionLabel('Shift'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    _shiftOption(
                        'day', 'Day Shift', Icons.wb_sunny_outlined),
                    Divider(height: 1, color: AppColors.divider),
                    _shiftOption('night', 'Night Shift',
                        Icons.nightlight_outlined),
                  ],
                ),
              ),
            ] else ...[
              // Double duty: only day point and night point
              _buildField(
                controller: _dayPointCtrl,
                label: 'Day Duty Point *',
                hint: 'Day shift location',
                icon: Icons.wb_sunny_outlined,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Day point is required'
                    : null,
                capitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _nightPointCtrl,
                label: 'Night Duty Point *',
                hint: 'Night shift location',
                icon: Icons.nightlight_outlined,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Night point is required'
                    : null,
                capitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.navyBlue.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: const [
                  Icon(Icons.info_outline,
                      size: 14, color: AppColors.navyBlue),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Day point is used as the default point for this guard.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.navyBlue),
                    ),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textGrey,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _dutyOption(
      String value, String title, String subtitle, IconData icon) {
    final selected = _dutyType == value;
    return InkWell(
      onTap: () => setState(() => _dutyType = value),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon,
                color: selected ? AppColors.navyBlue : AppColors.textGrey,
                size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: selected
                              ? AppColors.navyBlue
                              : AppColors.textDark)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textGrey)),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: selected
                        ? AppColors.navyBlue
                        : AppColors.divider,
                    width: 2),
                color:
                    selected ? AppColors.navyBlue : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check,
                      size: 12, color: AppColors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _shiftOption(String value, String title, IconData icon) {
    final selected = _singleShift == value;
    return InkWell(
      onTap: () => setState(() => _singleShift = value),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon,
                color: selected ? AppColors.navyBlue : AppColors.textGrey,
                size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: selected
                          ? AppColors.navyBlue
                          : AppColors.textDark)),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: selected
                        ? AppColors.navyBlue
                        : AppColors.divider,
                    width: 2),
                color:
                    selected ? AppColors.navyBlue : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check,
                      size: 12, color: AppColors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    TextCapitalization capitalization = TextCapitalization.none,
    String? prefix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      textCapitalization: capitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null
            ? Icon(icon, size: 20, color: AppColors.textGrey)
            : null,
        prefixText: prefix,
      ),
    );
  }
}
