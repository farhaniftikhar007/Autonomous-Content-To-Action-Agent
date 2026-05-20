import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/agent_screen.dart';
import 'screens/alert_screen.dart';
import 'screens/upload_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/live_logs_screen.dart';
import 'services/command_center_provider.dart';
import 'widgets/resilient_widgets.dart';

void main() {
  // Capture unexpected rendering exceptions with a crash-safe cyberpunk boundary screen
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ErrorCard(
              title: "CRITICAL SYSTEM INTERRUPT",
              error: details.exception,
            ),
          ),
        ),
      ),
    );
  };
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CommandCenterProvider(),
      child: MaterialApp(
        title: 'AI Inventory Agent',
        theme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: const Color(0xFF121212),
          cardColor: const Color(0xFF1E1E1E),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1F1F1F),
            elevation: 0,
          ),
        ),
        home: MainNavigation(),
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  static List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(),
    AlertScreen(),
    UploadScreen(),
    AgentScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: SafeArea(
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF1E1E1E),
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey,
          currentIndex: _selectedIndex,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.warning_amber_rounded),
              label: 'Alerts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.cloud_upload),
              label: 'Upload',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.smart_toy),
              label: 'Agent',
            ),
          ],
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
