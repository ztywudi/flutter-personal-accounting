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
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _records = [];
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final db = await DatabaseHelper.instance.database;
    final records = await db.query('records', orderBy: 'date DESC');
    
    double income = 0.0;
    double expense = 0.0;
    
    for (var record in records) {
      if (record['type'] == 0) {
        expense += record['amount'] as double;
      } else {
        income += record['amount'] as double;
      }
    }
    
    setState(() {
      _records = records;
      _totalIncome = income;
      _totalExpense = expense;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('个人记账本'),
      ),
      body: Column(
        children: [
          // 统计卡片
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('总收入', style: TextStyle(color: Colors.green)),
                      Text('¥${_totalIncome.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('总支出', style: TextStyle(color: Colors.red)),
                      Text('¥${_totalExpense.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // 记录列表
          Expanded(
            child: _records.isEmpty
                ? const Center(child: Text('暂无记录，点击右下角添加'))
                : ListView.builder(
                    itemCount: _records.length,
                    itemBuilder: (context, index) {
                      final record = _records[index];
                      final isExpense = record['type'] == 0;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isExpense ? Colors.red : Colors.green,
                          child: Icon(
                            isExpense ? Icons.remove : Icons.add,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(record['category'] ?? '未分类'),
                        subtitle: Text(record['note'] ?? ''),
                        trailing: Text(
                          '${isExpense ? '-' : '+'}¥${record['amount'].toStringAsFixed(2)}',
                          style: TextStyle(
                            color: isExpense ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddRecordPage()),
          );
          _loadRecords();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddRecordPage extends StatefulWidget {
  const AddRecordPage({Key? key}) : super(key: key);

  @override
  _AddRecordPageState createState() => _AddRecordPageState();
}

class _AddRecordPageState extends State<AddRecordPage> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  int _type = 0; // 0: 支出, 1: 收入
  String _category = '餐饮';

  final List<String> _expenseCategories = ['餐饮', '交通', '购物', '娱乐', '住房', '医疗', '教育', '其他'];
  final List<String> _incomeCategories = ['工资', '奖金', '投资', '兼职', '其他'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加记录'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // 类型选择
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('支出')),
                ButtonSegment(value: 1, label: Text('收入')),
              ],
              selected: {_type},
              onSelectionChanged: (Set<int> selection) {
                setState(() {
                  _type = selection.first;
                  _category = _type == 0 ? '餐饮' : '工资';
                });
              },
            ),
            const SizedBox(height: 16),
            
            // 金额输入
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '金额',
                prefixText: '¥ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // 分类选择
            const Text('分类', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: (_type == 0 ? _expenseCategories : _incomeCategories)
                  .map((cat) => ChoiceChip(
                        label: Text(cat),
                        selected: _category == cat,
                        onSelected: (selected) {
                          setState(() {
                            _category = cat;
                          });
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            
            // 备注输入
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: '备注',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            // 保存按钮
            ElevatedButton(
              onPressed: _saveRecord,
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveRecord() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入金额')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的金额')),
      );
      return;
    }

    final db = await DatabaseHelper.instance.database;
    await db.insert('records', {
      'amount': amount,
      'category': _category,
      'note': _noteController.text,
      'type': _type,
      'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
    });

    if (mounted) {
      Navigator.pop(context);
    }
  }
}

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

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
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
}
