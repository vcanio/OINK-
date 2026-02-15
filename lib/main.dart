import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
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
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFFDFBF7), // HSL(30,30%,97%) roughly
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF85A2), // HSL(350,80%,72%) roughly
            primary: const Color(0xFFFF85A2),
            secondary: const Color(0xFFFFC107), // Goldish
          ),
          textTheme: GoogleFonts.nunitoTextTheme(
            Theme.of(context).textTheme,
          ).apply(
            bodyColor: Colors.black,
            displayColor: Colors.black,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFFDFBF7),
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black),
            titleTextStyle: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        home: const MainScreen(),
      ),
    );
  }
}
