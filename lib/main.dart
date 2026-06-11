import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'database/db_helper.dart';
import 'providers/app_provider.dart';
import 'pages/home_page.dart';
import 'pages/bill_page.dart';
import 'pages/add_record_page.dart';
import 'pages/stat_page.dart';
import 'pages/setting_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await DBHelper.instance.database;
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(db),
      child: const AccountingApp(),
    ),
  );
}

class AccountingApp extends StatelessWidget {
  const AccountingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '记账',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F6EF7),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'PingFang SC',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Color(0xFF1A1D26),
        ),
      ),
      home: const MainNavigator(),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const BillPage(),
    const AddRecordPage(),
    const StatPage(),
    const SettingPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tab = provider.pendingTabIndex;
      if (tab >= 0) {
        provider.clearPendingTab();
        setState(() => _currentIndex = tab);
      }
    });

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 0.5)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.home_rounded, '首页'),
                _navItem(1, Icons.receipt_long_rounded, '账单'),
                _addButton(),
                _navItem(3, Icons.bar_chart_rounded, '统计'),
                _navItem(4, Icons.settings_rounded, '设置'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final selected = _currentIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _currentIndex = index),
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: selected ? const Color(0xFF4F6EF7) : const Color(0xFF9CA3AF)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: selected ? const Color(0xFF4F6EF7) : const Color(0xFF9CA3AF),
            )),
          ],
        ),
      ),
    );
  }

  Widget _addButton() {
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = 2),
      child: Transform.translate(
        offset: const Offset(0, -10),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF4F6EF7),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [BoxShadow(color: const Color(0xFF4F6EF7).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
