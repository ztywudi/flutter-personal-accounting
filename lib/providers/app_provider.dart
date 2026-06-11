import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../models/record.dart';
import '../models/category.dart';
import '../models/ledger.dart';
import '../models/channel.dart';
import '../database/db_helper.dart';

class AppProvider extends ChangeNotifier {
  final Database db;
  AppProvider(this.db);

  // ========== 状态 ==========
  List<Ledger> _ledgers = [];
  Ledger? _currentLedger;
  List<Category> _expenseCategories = [];
  List<Category> _incomeCategories = [];
  List<Channel> _channels = [];
  List<Record> _todayRecords = [];
  List<Record> _monthRecords = [];

  // Getters
  List<Ledger> get ledgers => _ledgers;
  Ledger? get currentLedger => _currentLedger;
  List<Category> get expenseCategories => _expenseCategories;
  List<Category> get incomeCategories => _incomeCategories;
  List<Channel> get channels => _channels;
  List<Record> get todayRecords => _todayRecords;
  List<Record> get monthRecords => _monthRecords;

  // ========== 加载所有数据 ==========
  Future<void> loadAll() async {
    await Future.wait([
      loadLedgers(),
      loadCategories(),
      loadChannels(),
      loadTodayRecords(),
      loadMonthRecords(),
    ]);
  }

  // ========== 账本 ==========
  Future<void> loadLedgers() async {
    final maps = await DBHelper.instance.queryAll('ledgers');
    _ledgers = maps.map((m) => Ledger.fromMap(m)).toList();
    if (_ledgers.isNotEmpty && _currentLedger == null) {
      _currentLedger = _ledgers.first;
    }
    notifyListeners();
  }

  void setCurrentLedger(Ledger ledger) {
    _currentLedger = ledger;
    loadTodayRecords();
    loadMonthRecords();
    notifyListeners();
  }

  Future<void> addLedger(String name, String color) async {
    await DBHelper.instance.insert('ledgers', {'name': name, 'color': color, 'sort_order': _ledgers.length});
    await loadLedgers();
  }

  Future<void> deleteLedger(int id) async {
    await DBHelper.instance.delete('ledgers', 'id = ?', [id]);
    if (_currentLedger?.id == id.toString()) {
      _currentLedger = _ledgers.isNotEmpty ? _ledgers.first : null;
    }
    await loadLedgers();
  }

  // ========== 分类 ==========
  Future<void> loadCategories() async {
    final maps = await DBHelper.instance.queryAll('categories');
    final all = maps.map((m) => Category.fromMap(m)).toList();
    _expenseCategories = all.where((c) => c.type == 'expense').toList();
    _incomeCategories = all.where((c) => c.type == 'income').toList();
    notifyListeners();
  }

  Future<void> addCategory(String type, String emoji, String name) async {
    final cats = type == 'expense' ? _expenseCategories : _incomeCategories;
    await DBHelper.instance.insert('categories', {
      'type': type, 'emoji': emoji, 'name': name, 'sort_order': cats.length,
    });
    await loadCategories();
  }

  Future<void> updateCategory(int id, {String? name, String? emoji}) async {
    final values = <String, dynamic>{};
    if (name != null) values['name'] = name;
    if (emoji != null) values['emoji'] = emoji;
    await DBHelper.instance.update('categories', values, 'id = ?', [id]);
    await loadCategories();
  }

  Future<void> deleteCategory(int id) async {
    await DBHelper.instance.delete('categories', 'id = ?', [id]);
    await loadCategories();
  }

  // ========== 支付渠道 ==========
  Future<void> loadChannels() async {
    final maps = await DBHelper.instance.queryAll('channels');
    _channels = maps.map((m) => Channel.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> addChannel(String emoji, String name) async {
    await DBHelper.instance.insert('channels', {'emoji': emoji, 'name': name});
    await loadChannels();
  }

  Future<void> deleteChannel(int id) async {
    await DBHelper.instance.delete('channels', 'id = ?', [id]);
    await loadChannels();
  }

  // ========== 记录 ==========
  Future<void> loadTodayRecords() async {
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final ledgerFilter = _currentLedger != null ? 'AND ledger_id = ${_currentLedger!.id}' : '';
    final maps = await DBHelper.instance.rawQuery(
      'SELECT * FROM records WHERE date = ? $ledgerFilter ORDER BY created_at DESC',
      [dateStr],
    );
    _todayRecords = maps.map((m) => Record.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> loadMonthRecords() async {
    final now = DateTime.now();
    final start = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
    final end = '${now.year}-${now.month.toString().padLeft(2, '0')}-31';
    final ledgerFilter = _currentLedger != null ? 'AND ledger_id = ${_currentLedger!.id}' : '';
    final maps = await DBHelper.instance.rawQuery(
      'SELECT * FROM records WHERE date BETWEEN ? AND ? $ledgerFilter ORDER BY date DESC, created_at DESC',
      [start, end],
    );
    _monthRecords = maps.map((m) => Record.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> addRecord(Record record) async {
    await DBHelper.instance.insert('records', record.toMap());
    await loadTodayRecords();
    await loadMonthRecords();
  }

  Future<void> deleteRecord(int id) async {
    await DBHelper.instance.delete('records', 'id = ?', [id]);
    await loadTodayRecords();
    await loadMonthRecords();
  }

  // ========== 退款/报销关联 ==========
  /// 查询某条记录的所有关联记录（退款/报销）
  Future<List<Record>> getRelatedRecords(String recordId) async {
    final maps = await DBHelper.instance.rawQuery(
      'SELECT * FROM records WHERE related_record_id = ? ORDER BY created_at DESC',
      [recordId],
    );
    return maps.map((m) => Record.fromMap(m)).toList();
  }

  /// 添加退款记录，自动关联
  Future<void> addRefund(String originalRecordId, double refundAmount, {String? remark, String channel = '现金'}) async {
    // 查出原始记录
    final maps = await DBHelper.instance.rawQuery(
      'SELECT * FROM records WHERE id = ?',
      [originalRecordId],
    );
    if (maps.isEmpty) return;
    final originalRecord = Record.fromMap(maps.first);

    // 查找"退款"分类
    final refundCatMaps = await DBHelper.instance.rawQuery(
      'SELECT * FROM categories WHERE type = ? AND name = ?',
      ['income', '退款'],
    );
    String refundCategoryId;
    if (refundCatMaps.isNotEmpty) {
      refundCategoryId = refundCatMaps.first['id'].toString();
    } else {
      // 如果没有退款分类，创建一个
      final sortOrder = _incomeCategories.length;
      final id = await DBHelper.instance.insert('categories', {
        'type': 'income', 'emoji': '💳', 'name': '退款', 'sort_order': sortOrder,
      });
      refundCategoryId = id.toString();
      await loadCategories();
    }

    // 创建退款记录
    final refundRecord = Record(
      ledgerId: originalRecord.ledgerId,
      type: 'income',
      amount: refundAmount,
      categoryId: refundCategoryId,
      remark: remark ?? '退款：${originalRecord.remark ?? getCategoryName(originalRecord.categoryId)}',
      channel: channel,
      relatedRecordId: originalRecordId,
      relationType: 'refund',
      date: DateTime.now(),
    );
    await DBHelper.instance.insert('records', refundRecord.toMap());
    await loadTodayRecords();
    await loadMonthRecords();
  }

  /// 添加报销记录，自动关联
  Future<void> addReimbursement(String originalRecordId, double reimburseAmount, {String? remark, String channel = '现金'}) async {
    // 查出原始记录
    final maps = await DBHelper.instance.rawQuery(
      'SELECT * FROM records WHERE id = ?',
      [originalRecordId],
    );
    if (maps.isEmpty) return;
    final originalRecord = Record.fromMap(maps.first);

    // 查找"报销"分类
    final reimCatMaps = await DBHelper.instance.rawQuery(
      'SELECT * FROM categories WHERE type = ? AND name = ?',
      ['income', '报销'],
    );
    String reimCategoryId;
    if (reimCatMaps.isNotEmpty) {
      reimCategoryId = reimCatMaps.first['id'].toString();
    } else {
      // 如果没有报销分类，创建一个
      final sortOrder = _incomeCategories.length;
      final id = await DBHelper.instance.insert('categories', {
        'type': 'income', 'emoji': '📋', 'name': '报销', 'sort_order': sortOrder,
      });
      reimCategoryId = id.toString();
      await loadCategories();
    }

    // 创建报销记录
    final reimRecord = Record(
      ledgerId: originalRecord.ledgerId,
      type: 'income',
      amount: reimburseAmount,
      categoryId: reimCategoryId,
      remark: remark ?? '报销：${originalRecord.remark ?? getCategoryName(originalRecord.categoryId)}',
      channel: channel,
      relatedRecordId: originalRecordId,
      relationType: 'reimbursement',
      date: DateTime.now(),
    );
    await DBHelper.instance.insert('records', reimRecord.toMap());
    await loadTodayRecords();
    await loadMonthRecords();
  }

  // ========== Tab切换通知 ==========
  int _pendingTabIndex = -1;
  int get pendingTabIndex => _pendingTabIndex;
  void requestSwitchTab(int index) {
    _pendingTabIndex = index;
    notifyListeners();
  }
  void clearPendingTab() {
    _pendingTabIndex = -1;
  }

  // ========== 统计 ==========
  double get monthIncome => _monthRecords
      .where((r) => r.type == 'income')
      .fold(0.0, (sum, r) => sum + r.amount);

  double get monthExpense => _monthRecords
      .where((r) => r.type == 'expense')
      .fold(0.0, (sum, r) => sum + r.actualAmount);

  double get monthBalance => monthIncome - monthExpense;

  double get todayExpense => _todayRecords
      .where((r) => r.type == 'expense')
      .fold(0.0, (sum, r) => sum + r.actualAmount);

  // 按分类统计支出
  Map<String, double> get expenseByCategory {
    final map = <String, double>{};
    for (final r in _monthRecords.where((r) => r.type == 'expense')) {
      map[r.categoryId] = (map[r.categoryId] ?? 0) + r.actualAmount;
    }
    return map;
  }

  // 按日统计
  Map<String, Map<String, double>> get dailyStats {
    final map = <String, Map<String, double>>{};
    for (final r in _monthRecords) {
      final key = r.date.toIso8601String().substring(0, 10);
      map[key] ??= {'income': 0, 'expense': 0};
      if (r.type == 'expense') {
        map[key]!['expense'] = (map[key]!['expense'] ?? 0) + r.actualAmount;
      } else {
        map[key]!['income'] = (map[key]!['income'] ?? 0) + r.amount;
      }
    }
    return map;
  }

  // 获取分类名称和emoji
  String getCategoryName(String categoryId) {
    final id = int.tryParse(categoryId);
    if (id == null) return '未知';
    final cat = [..._expenseCategories, ..._incomeCategories].where((c) => c.id == categoryId).firstOrNull;
    return cat?.name ?? '未知';
  }

  String getCategoryEmoji(String categoryId) {
    final cat = [..._expenseCategories, ..._incomeCategories].where((c) => c.id == categoryId).firstOrNull;
    return cat?.emoji ?? '📦';
  }

  Category? getCategoryById(String categoryId) {
    return [..._expenseCategories, ..._incomeCategories].where((c) => c.id == categoryId).firstOrNull;
  }
}
