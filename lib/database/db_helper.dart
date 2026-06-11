import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  DBHelper._();
  static final DBHelper instance = DBHelper._();

  Database? _database;
  Future<Database> get database async => _database ??= await _initDB();

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'accounting.db');
    return await openDatabase(path, version: 2, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future<void> _onCreate(Database db, int version) async {
    // 账本表
    await db.execute('''
      CREATE TABLE ledgers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color TEXT NOT NULL DEFAULT '#4F6EF7',
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 分类表
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        emoji TEXT NOT NULL,
        name TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 支付渠道表
    await db.execute('''
      CREATE TABLE channels (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        emoji TEXT NOT NULL,
        name TEXT NOT NULL
      )
    ''');

    // 记录表
    await db.execute('''
      CREATE TABLE records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ledger_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        category_id INTEGER NOT NULL,
        remark TEXT,
        channel TEXT NOT NULL DEFAULT '现金',
        discount REAL NOT NULL DEFAULT 0,
        related_record_id INTEGER,
        relation_type TEXT NOT NULL DEFAULT 'none',
        date TEXT NOT NULL,
        time TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (ledger_id) REFERENCES ledgers(id),
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    // 插入默认账本
    await db.insert('ledgers', {'name': '日常账本', 'color': '#4F6EF7', 'sort_order': 0});
    await db.insert('ledgers', {'name': '旅行基金', 'color': '#2DC653', 'sort_order': 1});
    await db.insert('ledgers', {'name': '宝宝开销', 'color': '#FF8C42', 'sort_order': 2});

    // 插入默认支出分类
    final expenseCategories = [
      {'type': 'expense', 'emoji': '🍜', 'name': '餐饮', 'sort_order': 0},
      {'type': 'expense', 'emoji': '🚗', 'name': '交通', 'sort_order': 1},
      {'type': 'expense', 'emoji': '🛒', 'name': '购物', 'sort_order': 2},
      {'type': 'expense', 'emoji': '🏠', 'name': '住房', 'sort_order': 3},
      {'type': 'expense', 'emoji': '🎮', 'name': '娱乐', 'sort_order': 4},
      {'type': 'expense', 'emoji': '🏥', 'name': '医疗', 'sort_order': 5},
      {'type': 'expense', 'emoji': '📚', 'name': '教育', 'sort_order': 6},
      {'type': 'expense', 'emoji': '💬', 'name': '通讯', 'sort_order': 7},
      {'type': 'expense', 'emoji': '👕', 'name': '服饰', 'sort_order': 8},
      {'type': 'expense', 'emoji': '💄', 'name': '美容', 'sort_order': 9},
      {'type': 'expense', 'emoji': '👶', 'name': '亲子', 'sort_order': 10},
      {'type': 'expense', 'emoji': '🐾', 'name': '宠物', 'sort_order': 11},
      {'type': 'expense', 'emoji': '🎁', 'name': '人情', 'sort_order': 12},
      {'type': 'expense', 'emoji': '✈️', 'name': '旅行', 'sort_order': 13},
      {'type': 'expense', 'emoji': '📦', 'name': '其他', 'sort_order': 14},
    ];
    for (final c in expenseCategories) {
      await db.insert('categories', c);
    }

    // 插入默认收入分类
    final incomeCategories = [
      {'type': 'income', 'emoji': '💰', 'name': '工资', 'sort_order': 0},
      {'type': 'income', 'emoji': '📈', 'name': '理财', 'sort_order': 1},
      {'type': 'income', 'emoji': '🎁', 'name': '奖金', 'sort_order': 2},
      {'type': 'income', 'emoji': '💼', 'name': '兼职', 'sort_order': 3},
      {'type': 'income', 'emoji': '🧧', 'name': '红包', 'sort_order': 4},
      {'type': 'income', 'emoji': '💳', 'name': '退款', 'sort_order': 5},
      {'type': 'income', 'emoji': '🏘️', 'name': '租金', 'sort_order': 6},
      {'type': 'income', 'emoji': '🎲', 'name': '其他', 'sort_order': 7},
      {'type': 'income', 'emoji': '📋', 'name': '报销', 'sort_order': 8},
    ];
    for (final c in incomeCategories) {
      await db.insert('categories', c);
    }

    // 插入默认支付渠道
    final channels = [
      {'emoji': '💵', 'name': '现金'},
      {'emoji': '💚', 'name': '微信'},
      {'emoji': '🔵', 'name': '支付宝'},
      {'emoji': '💳', 'name': '银行卡'},
      {'emoji': '🏦', 'name': '信用卡'},
      {'emoji': '🔄', 'name': '转账'},
      {'emoji': '📦', 'name': '其他'},
    ];
    for (final ch in channels) {
      await db.insert('channels', ch);
    }
  }

  // 数据库版本升级逻辑
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE records ADD COLUMN discount REAL NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE records ADD COLUMN related_record_id INTEGER');
      await db.execute("ALTER TABLE records ADD COLUMN relation_type TEXT NOT NULL DEFAULT 'none'");
    }
  }

  // ========== 通用 CRUD ==========
  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await database;
    return db.query(table);
  }

  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    return db.insert(table, values);
  }

  Future<int> update(String table, Map<String, dynamic> values, String where, List<Object> whereArgs) async {
    final db = await database;
    return db.update(table, values, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(String table, String where, List<Object> whereArgs) async {
    final db = await database;
    return db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<Object>? args]) async {
    final db = await database;
    return db.rawQuery(sql, args);
  }
}
