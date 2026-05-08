import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../services/data_service.dart';
import '../services/auto_backup_service.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});
  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen>
    with WidgetsBindingObserver {
  bool _exporting = false;
  bool _importing = false;
  String? _statusMessage;
  bool _statusIsError = false;

  // Pending auto-backup
  String? _pendingBackupPath;
  String? _lastBackupTimeStr;

  DataService get _ds => DataService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPending();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-check when user comes back to app (e.g. returning from Drive)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPending();
  }

  Future<void> _checkPending() async {
    final path = await AutoBackupService.getPendingBackupPath();
    final time = await AutoBackupService.getLastBackupTime();
    if (mounted) {
      setState(() {
        _pendingBackupPath = path;
        _lastBackupTimeStr = time;
      });
    }
  }

  String _formatBackupTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return iso;
    }
  }

  void _showStatus(String msg, {required bool isError}) {
    setState(() {
      _statusMessage = msg;
      _statusIsError = isError;
    });
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _statusMessage = null);
    });
  }

  // ─── Upload pending to Google Drive ──────────────────────────────────────

  Future<void> _uploadPending() async {
    if (_pendingBackupPath == null) return;
    await AutoBackupService.uploadPending(context);
    await _checkPending(); // clear banner
  }

  // ─── Manual backup → Google Drive ────────────────────────────────────────

  Future<void> _backupToGoogleDrive() async {
    setState(() => _exporting = true);
    try {
      final path = await _ds.saveBackupToFile();
      final result = await Share.shareXFiles(
        [XFile(path, mimeType: 'application/json')],
        subject: 'DSS Attendance Backup',
        text: 'Dadaji Security Services backup – upload to Google Drive.',
      );
      if (result.status == ShareResultStatus.success ||
          result.status == ShareResultStatus.dismissed) {
        _showStatus('Backup ready! Choose Google Drive from the share sheet.',
            isError: false);
      }
    } catch (e) {
      _showStatus('Backup failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // ─── Restore from Google Drive ────────────────────────────────────────────

  Future<void> _restoreFromGoogleDrive() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null) return;

    final confirm = await _confirmDialog(
      title: 'Replace all data?',
      body:
          'Restoring will REPLACE all current guards, attendance & tiffin history.\n\nThis cannot be undone.',
      confirmLabel: 'Restore & Replace',
      isDestructive: true,
    );
    if (confirm != true) return;

    setState(() => _importing = true);
    try {
      String jsonStr;
      if (result.files.single.bytes != null) {
        jsonStr = String.fromCharCodes(result.files.single.bytes!);
      } else if (result.files.single.path != null) {
        jsonStr = await File(result.files.single.path!).readAsString();
      } else {
        _showStatus('Could not read file. Please try again.', isError: true);
        return;
      }
      final err = await _ds.importBackup(jsonStr);
      _showStatus(
        err == null
            ? '✅ Restore successful! All data restored.'
            : err,
        isError: err != null,
      );
    } catch (e) {
      _showStatus('Restore failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _openGoogleDrive() async {
    final appUri = Uri.parse('googledrive://');
    final webUri = Uri.parse('https://drive.google.com');
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri);
    } else {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String body,
    required String confirmLabel,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: isDestructive
                ? ElevatedButton.styleFrom(backgroundColor: AppColors.error)
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final guardsCount = _ds.guards.length;
    final attendanceCount = _ds.attendance.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          // ── Pending backup banner ──────────────────────────────────────────
          if (_pendingBackupPath != null)
            _PendingBackupBanner(
              backupTime: _formatBackupTime(_lastBackupTimeStr),
              onUpload: _uploadPending,
              onDismiss: () async {
                await AutoBackupService.clearPending();
                await _checkPending();
              },
            ),
          if (_pendingBackupPath != null) const SizedBox(height: 14),

          // ── Status banner ──────────────────────────────────────────────────
          if (_statusMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _statusIsError
                    ? AppColors.absentRed
                    : AppColors.presentGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(
                    _statusIsError
                        ? Icons.error_outline
                        : Icons.check_circle_outline,
                    size: 18,
                    color: _statusIsError
                        ? AppColors.absentRedText
                        : AppColors.presentGreenText),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(_statusMessage!,
                        style: TextStyle(
                            fontSize: 13,
                            color: _statusIsError
                                ? AppColors.absentRedText
                                : AppColors.presentGreenText))),
              ]),
            ),

          // ── Data summary ───────────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current Data',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navyBlue)),
                    const SizedBox(height: 12),
                    _infoRow(Icons.shield_outlined, 'Guards', '$guardsCount'),
                    _infoRow(Icons.calendar_today_outlined,
                        'Attendance Records', '$attendanceCount'),
                    if (_lastBackupTimeStr != null) ...[
                      const SizedBox(height: 4),
                      _infoRow(Icons.history, 'Last Backup',
                          _formatBackupTime(_lastBackupTimeStr)),
                    ],
                  ]),
            ),
          ),
          const SizedBox(height: 20),

          // ── Auto backup info + manual trigger ─────────────────────────────
          Card(
            color: AppColors.navyBlue.withOpacity(0.04),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.navyBlue.withOpacity(0.15)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.navyBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.schedule,
                          color: AppColors.navyBlue, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('Auto Backup – Every Night 11:00 PM',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.navyBlue)),
                        SizedBox(height: 4),
                        Text(
                          'Backup file is automatically saved to Downloads every night. '
                          'A notification will appear — open the app anytime and tap '
                          '"Upload to Google Drive" to sync it.',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textGrey,
                              height: 1.5),
                        ),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => AutoBackupService.triggerNow(context),
                      icon: const Icon(Icons.backup_outlined, size: 18),
                      label: const Text('Backup Now (Manual)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navyBlue,
                        side: const BorderSide(color: AppColors.navyBlue),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Manual backup to Google Drive ──────────────────────────────────
          _SectionHeader(
            icon: Icons.cloud_upload_outlined,
            iconColor: const Color(0xFF1A73E8),
            title: 'Backup to Google Drive',
            subtitle:
                'Creates a backup file and opens the share sheet to upload to Google Drive.',
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _exporting ? null : _backupToGoogleDrive,
              icon: _exporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.cloud_upload_outlined),
              label:
                  Text(_exporting ? 'Preparing…' : 'Backup → Google Drive'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _openGoogleDrive,
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Open Google Drive'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1A73E8),
              side: const BorderSide(color: Color(0xFF1A73E8)),
              padding: const EdgeInsets.symmetric(vertical: 11),
            ),
          ),

          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 20),

          // ── Restore ────────────────────────────────────────────────────────
          _SectionHeader(
            icon: Icons.cloud_download_outlined,
            iconColor: const Color(0xFF0F9D58),
            title: 'Restore from Google Drive',
            subtitle:
                'Opens the file picker — tap Browse → Google Drive to select your backup.',
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _importing ? null : _restoreFromGoogleDrive,
              icon: _importing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.cloud_download_outlined),
              label:
                  Text(_importing ? 'Restoring…' : 'Restore from Google Drive'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F9D58),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 16),

          // Tips
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.navyBlue.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('How it works',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.navyBlue)),
                  SizedBox(height: 8),
                  Text(
                    '🌙 Every night at 11 PM:\n'
                    '   • Backup file saved automatically to Downloads\n'
                    '   • Notification appears on your phone\n\n'
                    '📲 Next time you open the app (even next morning):\n'
                    '   • A yellow banner shows at the top\n'
                    '   • Tap "Upload to Google Drive" on that banner\n'
                    '   • Select Google Drive in the share sheet → Done!\n\n'
                    '📥 To restore on a new phone:\n'
                    '   • Tap "Restore from Google Drive"\n'
                    '   • Browse → Google Drive → pick dadaji_backup.json',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textGrey, height: 1.7),
                  ),
                ]),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Icon(icon, size: 16, color: AppColors.textGrey),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

// ─── Pending Backup Banner ────────────────────────────────────────────────────

class _PendingBackupBanner extends StatelessWidget {
  final String backupTime;
  final VoidCallback onUpload;
  final VoidCallback onDismiss;

  const _PendingBackupBanner({
    required this.backupTime,
    required this.onUpload,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withOpacity(0.6), width: 1.5),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('🌙', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Auto Backup Ready',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF795548))),
              if (backupTime.isNotEmpty)
                Text('Backed up at $backupTime',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textGrey)),
            ]),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.textGrey),
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ]),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onUpload,
            icon: const Icon(Icons.cloud_upload_outlined, size: 18),
            label: const Text('Upload to Google Drive'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A73E8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              textStyle: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      const SizedBox(width: 12),
      Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.textDark)),
        const SizedBox(height: 3),
        Text(subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
      ])),
    ]);
  }
}
