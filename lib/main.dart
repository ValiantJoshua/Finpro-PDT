import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'alarm_settings.dart';
import 'stopwatch_page.dart';
import 'timer_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Define the color palette
    const Color primaryColor = Color(0xFF6C63FF);
    const Color secondaryColor = Color(0xFF4D8DEE);
    const Color darkColor = Color(0xFF2D3748);
    const Color lightColor = Color(0xFFF7FAFC);

    return MaterialApp(
      title: 'Focus Timer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: primaryColor,
          secondary: secondaryColor,
          surface: darkColor,
          background: darkColor,
        ),
        scaffoldBackgroundColor: darkColor,
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
          iconTheme: const IconThemeData(color: lightColor),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: darkColor,
          selectedItemColor: primaryColor,
          unselectedItemColor: lightColor.withOpacity(0.6),
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
        ),
        cardTheme: CardThemeData(
          color: darkColor.withOpacity(0.7),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const AlarmSettingsPage(),
    const StopwatchPage(),
    const TimerPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.alarm),
            label: 'Alarm',
            backgroundColor: Theme.of(context).colorScheme.surface,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.timer),
            label: 'Stopwatch',
            backgroundColor: Theme.of(context).colorScheme.surface,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.hourglass_bottom),
            label: 'Timer',
            backgroundColor: Theme.of(context).colorScheme.surface,
          ),
        ],
      ),
    );
  }
}