import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'screens/splash_screen.dart';
import 'services/auto_backup_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: AppColors.navyBlue,
    statusBarIconBrightness: Brightness.light,
  ));
  // Initialise daily auto-backup (schedules Workmanager + notifications)
  await AutoBackupService.init();
  runApp(const DadajiApp());
}

class DadajiApp extends StatelessWidget {
  const DadajiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dadaji Security Services',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
