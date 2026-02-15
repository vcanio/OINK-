import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'reports_screen.dart';
import 'goals_screen.dart';
import 'settings_screen.dart';
import 'add_transaction_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    DashboardScreen(onSeeAllPressed: () => _onTabTapped(1)),
    const HistoryScreen(),
    const SizedBox(), // Placeholder for Add button
    const ReportsScreen(),
    const GoalsScreen(),
  ];

  void _onTabTapped(int index) {
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
      );
    } else if (index == 4) {
        // Settings is not in the tab bar per se, but wait...
        // Requirement: "BottomNavigationBar con 5 tabs: Inicio, Historial, Agregar (...), Reportes, Metas"
        // Wait, where is Settings?
        // "Configuración: Info app + mascota, exportar JSON, importar JSON, borrar datos"
        // It's a screen, but not listed in the 5 tabs.
        // Maybe I should add a Settings button in the Dashboard AppBar?
        // Ah, the user didn't specify where Settings goes in the nav bar.
        // But dashboard has "OINK!" title and "mascota".
        // Let's add a Settings icon in the Dashboard AppBar to navigate to SettingsScreen.
        // For now, let's keep the tabs as requested.
        setState(() {
          _currentIndex = index;
        });
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFFF85A2),
          unselectedItemColor: Colors.grey.shade400,
          showUnselectedLabels: true,
          selectedLabelStyle: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 12),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Inicio',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              label: 'Historial',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF85A2), Color(0xFFFFC107)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x40FF85A2),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
              ),
              label: '',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_rounded),
              label: 'Reportes',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.flag_rounded),
              label: 'Metas',
            ),
          ],
        ),
      ),
    );
  }
}
