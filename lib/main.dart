import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '个人记账本',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF667eea),
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF667eea),
          foregroundColor: Colors.white,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

// ==================== 主界面（底部导航） ====================
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomePage(),
    const StatisticsPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: const Color(0xFF667eea),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: '账单'),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: '统计'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '设置'),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AddRecordPage()));
                setState(() {});
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

// ==================== 首页 - 账单列表 ====================
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _selectedMonth = DateTime.now();
  List<Map<String, dynamic>> _records = [];
  double _monthIncome = 0;
  double _monthExpense = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await DatabaseHelper.instance.database;
    final monthStr = DateFormat('yyyy-MM').format(_selectedMonth);
    final records = await db.query(
      'records',
      where: "date LIKE ?",
      whereArgs: ['$monthStr%'],
      orderBy: 'date DESC, id DESC',
    );

    double income = 0, expense = 0;
    for (var r in records) {
      if (r['type'] == 0) {
        expense += r['amount'] as double;
      } else {
        income += r['amount'] as double;
      }
    }

    setState(() {
      _records = records;
      _monthIncome = income;
      _monthExpense = expense;
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final balance = _monthIncome - _monthExpense;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _changeMonth(-1),
            ),
            Text(DateFormat('yyyy年M月').format(_selectedMonth)),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _changeMonth(1),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 统计卡片
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('本月结余', style: TextStyle(color: Colors.white70, fontSize: 14)),
                Text(
                  '¥${balance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statItem('收入', _monthIncome, Colors.lightGreenAccent),
                    Container(width: 1, height: 40, color: Colors.white24),
                    _statItem('支出', _monthExpense, Colors.redAccent),
                  ],
                ),
              ],
            ),
          ),
          // 记录列表
          Expanded(
            child: _records.isEmpty
                ? const Center(
                    child: Text('本月暂无记录', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _records.length,
                    itemBuilder: (context, index) {
                      final record = _records[index];
                      final isExpense = record['type'] == 0;
                      final cat = CategoryConfig.getCategory(record['type'], record['category']);

                      return Dismissible(
                        key: ValueKey(record['id']),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) async {
                          final db = await DatabaseHelper.instance.database;
                          await db.delete('records', where: 'id = ?', whereArgs: [record['id']]);
                          _loadData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已删除'), duration: Duration(seconds: 1)),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: cat['color'] as Color,
                              child: Text(cat['icon'] as String, style: const TextStyle(fontSize: 20)),
                            ),
                            title: Text(
                              record['category'] ?? '未分类',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${record['date']}${record['note'] != null && record['note'].isNotEmpty ? ' · ${record['note']}' : ''}',
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                            trailing: Text(
                              '${isExpense ? '-' : '+'}¥${(record['amount'] as double).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isExpense ? Colors.red : Colors.green,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        Text(
          '¥${amount.toStringAsFixed(2)}',
          style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// ==================== 统计页面 ====================
class StatisticsPage extends StatefulWidget {
  const StatisticsPage({Key? key}) : super(key: key);

  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  DateTime _selectedMonth = DateTime.now();
  int _type = 0; // 0: 支出, 1: 收入
  Map<String, double> _stats = {};
  double _total = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final db = await DatabaseHelper.instance.database;
    final monthStr = DateFormat('yyyy-MM').format(_selectedMonth);
    final results = await db.rawQuery(
      'SELECT category, SUM(amount) as total FROM records WHERE type = ? AND date LIKE ? GROUP BY category ORDER BY total DESC',
      [_type, '$monthStr%'],
    );

    Map<String, double> stats = {};
    double total = 0;
    for (var row in results) {
      stats[row['category'] as String] = row['total'] as double;
      total += row['total'] as double;
    }

    setState(() {
      _stats = stats;
      _total = total;
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    });
    _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('统计'),
      ),
      body: Column(
        children: [
          // 月份选择
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(DateFormat('yyyy年M月').format(_selectedMonth),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),
          // 收支切换
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('支出统计')),
                ButtonSegment(value: 1, label: Text('收入统计')),
              ],
              selected: {_type},
              onSelectionChanged: (Set<int> s) {
                setState(() => _type = s.first);
                _loadStats();
              },
            ),
          ),
          const SizedBox(height: 16),
          // 总计
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${_type == 0 ? "总支出" : "总收入"}: ¥${_total.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _type == 0 ? Colors.red : Colors.green,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 分类统计列表
          Expanded(
            child: _stats.isEmpty
                ? const Center(child: Text('暂无数据', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _stats.length,
                    itemBuilder: (context, index) {
                      final cat = _stats.keys.elementAt(index);
                      final amount = _stats[cat]!;
                      final percent = _total > 0 ? amount / _total : 0.0;
                      final catInfo = CategoryConfig.getCategory(_type, cat);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(catInfo['icon'] as String, style: const TextStyle(fontSize: 24)),
                                  const SizedBox(width: 12),
                                  Text(cat, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  Text('¥${amount.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // 进度条
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percent,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey[200],
                                  color: catInfo['color'] as Color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('${(percent * 100).toStringAsFixed(1)}%',
                                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ==================== 设置页面 ====================
class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline, color: Color(0xFF667eea)),
            title: const Text('关于'),
            subtitle: const Text('个人记账本 v1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: '个人记账本',
                applicationVersion: '1.0.0',
                children: const [Text('\n简单易用的个人记账应用')],
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('清空所有数据'),
            subtitle: const Text('删除全部记账记录（不可恢复）'),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('确认清空'),
                  content: const Text('确定要删除所有记账记录吗？此操作不可恢复！'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('确定', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                final db = await DatabaseHelper.instance.database;
                await db.delete('records');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已清空所有数据')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

// ==================== 添加记录页面 ====================
class AddRecordPage extends StatefulWidget {
  const AddRecordPage({Key? key}) : super(key: key);

  @override
  _AddRecordPageState createState() => _AddRecordPageState();
}

class _AddRecordPageState extends State<AddRecordPage> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  int _type = 0;
  String _category = '餐饮';
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入金额')));
      return;
    }
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入有效金额')));
      return;
    }

    final db = await DatabaseHelper.instance.database;
    await db.insert('records', {
      'amount': amount,
      'category': _category,
      'note': _noteController.text.trim(),
      'type': _type,
      'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categories = CategoryConfig.getCategoriesByType(_type);
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加记账'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('保存', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 收支切换
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('支出')),
              ButtonSegment(value: 1, label: Text('收入')),
            ],
            selected: {_type},
            onSelectionChanged: (Set<int> s) {
              setState(() {
                _type = s.first;
                _category = CategoryConfig.getCategoriesByType(_type).first['name'] as String;
              });
            },
          ),
          const SizedBox(height: 24),

          // 金额输入
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('金额', style: TextStyle(color: Colors.grey, fontSize: 14)),
                Row(
                  children: [
                    const Text('¥', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '0.00',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 分类选择
          const Text('选择分类', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = _category == cat['name'];
              return GestureDetector(
                onTap: () => setState(() => _category = cat['name'] as String),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? (cat['color'] as Color) : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected ? null : Border.all(color: Colors.transparent),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(cat['icon'] as String, style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 4),
                      Text(
                        cat['name'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // 日期选择
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: const Icon(Icons.calendar_today, color: Color(0xFF667eea)),
              title: const Text('日期'),
              trailing: Text(DateFormat('yyyy-MM-dd').format(_selectedDate),
                  style: const TextStyle(color: Color(0xFF667eea))),
              onTap: _pickDate,
            ),
          ),
          const SizedBox(height: 16),

          // 备注
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              labelText: '备注（可选）',
              prefixIcon: const Icon(Icons.edit_note),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

// ==================== 分类配置 ====================
class CategoryConfig {
  static const _expenseCategories = [
    {'name': '餐饮', 'icon': '🍚', 'color': Color(0xFFFF6B6B)},
    {'name': '交通', 'icon': '🚗', 'color': Color(0xFF4ECDC4)},
    {'name': '购物', 'icon': '🛒', 'color': Color(0xFFFFBE0B)},
    {'name': '娱乐', 'icon': '🎮', 'color': Color(0xFF7209B7)},
    {'name': '住房', 'icon': '🏠', 'color': Color(0xFF4361EE)},
    {'name': '医疗', 'icon': '💊', 'color': Color(0xFFF72585)},
    {'name': '教育', 'icon': '📚', 'color': Color(0xFF3A0CA3)},
    {'name': '通讯', 'icon': '📱', 'color': Color(0xFF06D6A0)},
    {'name': '人情', 'icon': '🎁', 'color': Color(0xFFE63946)},
    {'name': '其他', 'icon': '📦', 'color': Color(0xFF6C757D)},
  ];

  static const _incomeCategories = [
    {'name': '工资', 'icon': '💰', 'color': Color(0xFF2EC4B6)},
    {'name': '奖金', 'icon': '🎉', 'color': Color(0xFFE71D36)},
    {'name': '投资', 'icon': '📈', 'color': Color(0xFF011627)},
    {'name': '兼职', 'icon': '💼', 'color': Color(0xFF7209B7)},
    {'name': '红包', 'icon': '🧧', 'color': Color(0xFFE63946)},
    {'name': '其他', 'icon': '💵', 'color': Color(0xFF6C757D)},
  ];

  static List<Map<String, dynamic>> getCategoriesByType(int type) {
    return type == 0 ? _expenseCategories : _incomeCategories;
  }

  static Map<String, dynamic> getCategory(int type, String name) {
    final list = getCategoriesByType(type);
    return list.firstWhere(
      (c) => c['name'] == name,
      orElse: () => {'name': name, 'icon': '📦', 'color': const Color(0xFF6C757D)},
    );
  }
}

// ==================== 数据库 ====================
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('accounting.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = p.join(documentsDirectory.path, filePath);
    return await openDatabase(path, version: 2, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        note TEXT,
        type INTEGER NOT NULL,
        date TEXT NOT NULL
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 兼容旧数据
    }
  }
}
