import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/category.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(children: [
          // 标题
          Container(
            color: Colors.white,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: const Text('设置', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 16),
          // 账本管理
          _section('账本管理', [
            _item('📒', '我的账本', '${provider.ledgers.length}个', onTap: () => _showLedgerManager(context, provider)),
            _item('📊', '预算设置', '未设置'),
          ]),
          // 分类与渠道
          _section('分类与渠道', [
            _item('🏷️', '分类管理', '支出${provider.expenseCategories.length} · 收入${provider.incomeCategories.length}',
              onTap: () => _showCategoryManager(context, provider)),
            _item('💳', '支付渠道管理', '${provider.channels.length}个',
              onTap: () => _showChannelManager(context, provider)),
          ]),
          // 数据管理
          _section('数据管理', [
            _item('💾', '数据备份', ''),
            _item('📤', '导出数据', ''),
            _item('📥', '导入数据', ''),
          ]),
          // 偏好设置
          _section('偏好设置', [
            _item('🌙', '深色模式', '跟随系统'),
            _item('💱', '默认货币', 'CNY ¥'),
            _item('🔒', '安全锁', '未开启'),
          ]),
          // 关于
          _section('关于', [
            _item('ℹ️', '关于应用', 'v1.0.0'),
          ]),
        ]),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600))),
        ...children,
      ]),
    );
  }

  Widget _item(String icon, String label, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
          if (value.isNotEmpty) Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 16, color: Color(0xFF9CA3AF)),
        ]),
      ),
    );
  }

  // ========== 账本管理 ==========
  void _showLedgerManager(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('我的账本', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...provider.ledgers.map((l) => ListTile(
              leading: CircleAvatar(backgroundColor: _parseColor(l.color), radius: 6),
              title: Text(l.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                onPressed: () {
                  provider.deleteLedger(int.parse(l.id!));
                  setModalState(() {});
                },
              ),
            )),
            const SizedBox(height: 8),
            _AddItemRow(hint: '输入账本名称', onAdd: (name) async {
              await provider.addLedger(name, '#4F6EF7');
              setModalState(() {});
            }),
          ]),
        );
      }),
    );
  }

  // ========== 分类管理 ==========
  void _showCategoryManager(BuildContext context, AppProvider provider) {
    String currentType = 'expense';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) {
        final cats = currentType == 'expense' ? provider.expenseCategories : provider.incomeCategories;
        return Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('分类管理', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            // 支出/收入切换
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                _catTypeTab('支出分类', 'expense', currentType, () { setModalState(() => currentType = 'expense'); }),
                _catTypeTab('收入分类', 'income', currentType, () { setModalState(() => currentType = 'income'); }),
              ]),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: cats.length,
                itemBuilder: (ctx, i) {
                  final c = cats[i];
                  return ListTile(
                    leading: Text(c.emoji, style: const TextStyle(fontSize: 28)),
                    title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18, color: Color(0xFF4F6EF7)),
                        onPressed: () => _editCategory(context, provider, c, () => setModalState(() {})),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                        onPressed: () {
                          if (cats.length <= 1) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('至少保留一个分类'))); return; }
                          provider.deleteCategory(int.parse(c.id!)).then((_) => setModalState(() {}));
                        },
                      ),
                    ]),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            _AddCategoryRow(onAdd: (emoji, name) async {
              await provider.addCategory(currentType, emoji, name);
              setModalState(() {});
            }),
          ]),
        );
      }),
    );
  }

  Widget _catTypeTab(String label, String value, String current, VoidCallback onTap) {
    final active = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: active ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))] : [],
          ),
          child: Text(label, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? const Color(0xFF4F6EF7) : const Color(0xFF9CA3AF))),
        ),
      ),
    );
  }

  void _editCategory(BuildContext context, AppProvider provider, Category cat, VoidCallback onDone) {
    final nameCtrl = TextEditingController(text: cat.name);
    String selectedEmoji = cat.emoji;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑分类'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          GestureDetector(
            onTap: () => _showEmojiPicker(context, selectedEmoji, (e) => selectedEmoji = e),
            child: Text(selectedEmoji, style: const TextStyle(fontSize: 40)),
          ),
          const SizedBox(height: 12),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '分类名称', border: OutlineInputBorder())),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(onPressed: () {
            provider.updateCategory(int.parse(cat.id!), name: nameCtrl.text, emoji: selectedEmoji).then((_) {
              onDone();
              Navigator.pop(ctx);
            });
          }, child: const Text('保存')),
        ],
      ),
    );
  }

  void _showEmojiPicker(BuildContext context, String current, Function(String) onSelect) {
    const emojis = ['🍜','🚗','🛒','🏠','🎮','🏥','📚','💬','👕','💄','👶','🐾','🎁','✈️','📦','💰','📈','💼','🧧','💳','🏘️','🎲','☕','🍻','🎂','📱','💻','🎬','🎵','🏀','⚽','🌱','🐶','🐱','👗','👑','🔧','💊','🚌','🚇'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('选择图标'),
        content: Wrap(spacing: 4, runSpacing: 4, children: emojis.map((e) =>
          GestureDetector(
            onTap: () { onSelect(e); Navigator.pop(ctx); },
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: e == current ? const Color(0xFFEEF1FE) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Text(e, style: const TextStyle(fontSize: 24))),
            ),
          ),
        ).toList()),
      ),
    );
  }

  // ========== 支付渠道管理 ==========
  void _showChannelManager(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('支付渠道管理', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...provider.channels.map((ch) => ListTile(
              leading: Text(ch.emoji, style: const TextStyle(fontSize: 24)),
              title: Text(ch.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                onPressed: () => provider.deleteChannel(int.parse(ch.id!)).then((_) => setModalState(() {})),
              ),
            )),
            const SizedBox(height: 8),
            _AddChannelRow(onAdd: (emoji, name) async {
              await provider.addChannel(emoji, name);
              setModalState(() {});
            }),
          ]),
        );
      }),
    );
  }

  Color _parseColor(String hex) {
    final c = hex.replaceAll('#', '');
    return Color(int.parse('FF$c', radix: 16));
  }
}

// ========== 通用添加行组件 ==========
class _AddItemRow extends StatefulWidget {
  final String hint;
  final Function(String) onAdd;
  const _AddItemRow({required this.hint, required this.onAdd});
  @override
  State<_AddItemRow> createState() => _AddItemRowState();
}

class _AddItemRowState extends State<_AddItemRow> {
  final _ctrl = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: TextField(controller: _ctrl, decoration: InputDecoration(
          hintText: widget.hint,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        )),
      ),
      const SizedBox(width: 8),
      ElevatedButton(
        onPressed: () {
          if (_ctrl.text.trim().isNotEmpty) {
            widget.onAdd(_ctrl.text.trim());
            _ctrl.clear();
          }
        },
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F6EF7), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        child: const Text('添加', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    ]);
  }
}

class _AddCategoryRow extends StatefulWidget {
  final Function(String, String) onAdd;
  const _AddCategoryRow({required this.onAdd});
  @override
  State<_AddCategoryRow> createState() => _AddCategoryRowState();
}

class _AddCategoryRowState extends State<_AddCategoryRow> {
  final _ctrl = TextEditingController();
  String _emoji = '😀';
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      GestureDetector(
        onTap: () {
          const emojis = ['🍜','🚗','🛒','🏠','🎮','🏥','📚','💬','👕','💄','👶','🐾','🎁','✈️','📦','💰','📈','💼','🧧','💳','🎲'];
          showDialog(context: context, builder: (ctx) => AlertDialog(
            title: const Text('选择图标'),
            content: Wrap(spacing: 4, runSpacing: 4, children: emojis.map((e) =>
              GestureDetector(onTap: () { setState(() => _emoji = e); Navigator.pop(ctx); },
                child: Padding(padding: const EdgeInsets.all(4), child: Text(e, style: const TextStyle(fontSize: 24)))),
            ).toList()),
          ));
        },
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text(_emoji, style: const TextStyle(fontSize: 28))),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(child: TextField(controller: _ctrl, decoration: const InputDecoration(
        hintText: '输入分类名称',
        border: OutlineInputBorder(),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ))),
      const SizedBox(width: 8),
      ElevatedButton(
        onPressed: () {
          if (_ctrl.text.trim().isNotEmpty) {
            widget.onAdd(_emoji, _ctrl.text.trim());
            _ctrl.clear();
          }
        },
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F6EF7), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        child: const Text('添加', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    ]);
  }
}

class _AddChannelRow extends StatefulWidget {
  final Function(String, String) onAdd;
  const _AddChannelRow({required this.onAdd});
  @override
  State<_AddChannelRow> createState() => _AddChannelRowState();
}

class _AddChannelRowState extends State<_AddChannelRow> {
  final _ctrl = TextEditingController();
  String _emoji = '📦';
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      GestureDetector(
        onTap: () {
          const emojis = ['💵','💚','🔵','💳','🏦','🔄','📦','📱','💰','🎯'];
          showDialog(context: context, builder: (ctx) => AlertDialog(
            title: const Text('选择图标'),
            content: Wrap(spacing: 4, runSpacing: 4, children: emojis.map((e) =>
              GestureDetector(onTap: () { setState(() => _emoji = e); Navigator.pop(ctx); },
                child: Padding(padding: const EdgeInsets.all(4), child: Text(e, style: const TextStyle(fontSize: 24)))),
            ).toList()),
          ));
        },
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text(_emoji, style: const TextStyle(fontSize: 28))),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(child: TextField(controller: _ctrl, decoration: const InputDecoration(
        hintText: '输入渠道名称',
        border: OutlineInputBorder(),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ))),
      const SizedBox(width: 8),
      ElevatedButton(
        onPressed: () {
          if (_ctrl.text.trim().isNotEmpty) {
            widget.onAdd(_emoji, _ctrl.text.trim());
            _ctrl.clear();
          }
        },
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F6EF7), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        child: const Text('添加', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    ]);
  }
}
