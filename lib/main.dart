import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'theme/app_theme.dart';
import 'models/transaction.dart';
import 'models/savings_goal.dart';
import 'providers/oink_provider.dart';
import 'screens/main_screen.dart'; // We will create this

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(SavingsGoalAdapter());
  
  await initializeDateFormatting('es_CL', null);

  runApp(const OinkApp());
}

class OinkApp extends StatelessWidget {
  const OinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OinkProvider()..loadData()),
      ],
      child: MaterialApp(
        title: 'OINK!',
        debugShowCheckedModeBanner: false,
theme: AppTheme.lightTheme,
        home: const MainScreen(),
      ),
    );
  }
}
