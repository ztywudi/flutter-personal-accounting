import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/record.dart';

class BillPage extends StatefulWidget {
  const BillPage({super.key});
  @override
  State<BillPage> createState() => _BillPageState();
}

class _BillPageState extends State<BillPage> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final records = provider.monthRecords;

    // 按日期分组
    final grouped = <String, List<Record>>{};
    for (final r in records) {
      final key = r.date.toIso8601String().substring(0, 10);
      grouped[key] ??= [];
      grouped[key]!.add(r);
    }
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(children: [
        // 标题栏
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('账单', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            IconButton(icon: const Icon(Icons.search, color: Color(0xFF9CA3AF)), onPressed: () {}),
          ]),
        ),
        // 月份选择
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeMonth(-1)),
            Text('${_currentMonth.year}年${_currentMonth.month}月', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeMonth(1)),
          ]),
        ),
        // 月度汇总
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ]),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _summaryItem('收入', provider.monthIncome, const Color(0xFF2DC653)),
            _summaryItem('支出', provider.monthExpense, const Color(0xFFF5365C)),
            _summaryItem('结余', provider.monthBalance, const Color(0xFF4F6EF7)),
          ]),
        ),
        // 账单列表
        Expanded(
          child: sortedKeys.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('📭', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text('本月暂无记录', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: sortedKeys.length,
                  itemBuilder: (ctx, i) {
                    final key = sortedKeys[i];
                    final dayRecords = grouped[key]!;
                    final dayIncome = dayRecords.where((r) => r.type == 'income').fold(0.0, (s, r) => s + r.amount);
                    final dayExpense = dayRecords.where((r) => r.type == 'expense').fold(0.0, (s, r) => s + r.amount);
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(_formatDate(key), style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
                          Text('收${dayIncome.toInt()} · 支${dayExpense.toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF))),
                        ]),
                      ),
                      ...dayRecords.map((r) => _buildBillItem(provider, r)),
                    ]);
                  },
                ),
        ),
      ]),
    );
  }

  Widget _summaryItem(String label, double value, Color color) {
    return Column(children: [
      Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
      const SizedBox(height: 4),
      Text(value.toInt().toString(), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: color)),
    ]);
  }

  Widget _buildBillItem(AppProvider provider, Record r) {
    final cat = provider.getCategoryById(r.categoryId);
    final isExpense = r.type == 'expense';
    return GestureDetector(
      onLongPress: () => _showRecordActions(provider, r),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ]),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: isExpense ? const Color(0xFFFDE8EB) : const Color(0xFFE8F8ED),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(cat?.emoji ?? '📦', style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(cat?.name ?? '未知', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Wrap(children: [
              if (r.remark != null) Text(r.remark!, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
              if (r.channel != '现金') Container(
                margin: const EdgeInsets.only(left: 6, top: 3),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(4)),
                child: Text(r.channel, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
              ),
              if (r.discount > 0)
                Container(
                  margin: const EdgeInsets.only(left: 4, top: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: const Color(0xFFFFF7E6), borderRadius: BorderRadius.circular(4)),
                  child: Text('优惠¥${r.discount.toStringAsFixed(r.discount == r.discount.roundToDouble() ? 0 : 2)}',
                    style: const TextStyle(fontSize: 10, color: Color(0xFFF59E0B))),
                ),
              if (r.relationType == 'refund')
                Container(
                  margin: const EdgeInsets.only(left: 4, top: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: const Color(0xFFE8F8ED), borderRadius: BorderRadius.circular(4)),
                  child: const Text('退款', style: TextStyle(fontSize: 10, color: Color(0xFF2DC653))),
                ),
              if (r.relationType == 'reimbursement')
                Container(
                  margin: const EdgeInsets.only(left: 4, top: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: const Color(0xFFEEF1FE), borderRadius: BorderRadius.circular(4)),
                  child: const Text('报销', style: TextStyle(fontSize: 10, color: Color(0xFF4F6EF7))),
                ),
            ]),
          ])),
          Text(
            '${isExpense ? "-" : "+"}${r.actualAmount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700,
              color: isExpense ? const Color(0xFFF5365C) : const Color(0xFF2DC653),
            ),
          ),
          if (r.discount > 0 && isExpense)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text('¥${r.amount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF),
                  decoration: TextDecoration.lineThrough)),
            ),
        ]),
      ),
    );
  }

  void _changeMonth(int offset) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + offset, 1);
    });
    context.read<AppProvider>().loadMonthRecords();
  }

  String _formatDate(String isoDate) {
    final d = DateTime.parse(isoDate);
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return '${d.month.toString().padLeft(2, '0')}月${d.day.toString().padLeft(2, '0')}日 ${weekdays[d.weekday - 1]}';
  }

  void _showRecordActions(AppProvider provider, Record r) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('账单操作', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          if (r.type == 'expense') ...[
            ListTile(
              leading: const Icon(Icons.replay, color: Color(0xFF2DC653)),
              title: const Text('记退款', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('关联退款到这笔支出'),
              onTap: () { Navigator.pop(ctx); _showRefundDialog(provider, r); },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long, color: Color(0xFF4F6EF7)),
              title: const Text('记报销', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('关联报销到这笔支出'),
              onTap: () { Navigator.pop(ctx); _showReimburseDialog(provider, r); },
            ),
          ],
          if (r.relationType != 'none')
            FutureBuilder<List<Record>>(
              future: provider.getRelatedRecords(r.relatedRecordId ?? r.id!),
              builder: (ctx, snap) {
                if (!snap.hasData || snap.data!.isEmpty) return const SizedBox();
                return Column(children: [
                  const Divider(),
                  const Text('关联记录', style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
                  ...snap.data!.map((rel) => ListTile(
                    leading: Text(provider.getCategoryEmoji(rel.categoryId), style: const TextStyle(fontSize: 20)),
                    title: Text('${rel.relationType == 'refund' ? '退款' : '报销'} ¥${rel.actualAmount.toStringAsFixed(2)}'),
                    subtitle: Text(rel.remark ?? ''),
                  )),
                ]);
              },
            ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
            title: const Text('删除', style: TextStyle(color: Color(0xFFEF4444))),
            onTap: () { provider.deleteRecord(int.parse(r.id!)); Navigator.pop(ctx); },
          ),
        ]),
      ),
    );
  }

  void _showRefundDialog(AppProvider provider, Record r) {
    String refundAmount = r.actualAmount.toStringAsFixed(2);
    String remark = '退款：${provider.getCategoryName(r.categoryId)}';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('记退款', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('原支出：¥${r.actualAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
            const SizedBox(height: 16),
            TextField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              controller: TextEditingController(text: refundAmount),
              decoration: InputDecoration(
                labelText: '退款金额',
                prefixText: '¥ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (v) => refundAmount = v,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: TextEditingController(text: remark),
              decoration: InputDecoration(
                labelText: '备注',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (v) => remark = v,
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2DC653)),
                onPressed: () {
                  final amount = double.tryParse(refundAmount) ?? 0;
                  if (amount > 0) {
                    provider.addRefund(r.id!, amount, remark: remark, channel: r.channel);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('确认退款', style: TextStyle(color: Colors.white)),
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  void _showReimburseDialog(AppProvider provider, Record r) {
    String reimburseAmount = r.actualAmount.toStringAsFixed(2);
    String remark = '报销：${provider.getCategoryName(r.categoryId)}';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('记报销', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('原支出：¥${r.actualAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
            const SizedBox(height: 16),
            TextField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              controller: TextEditingController(text: reimburseAmount),
              decoration: InputDecoration(
                labelText: '报销金额',
                prefixText: '¥ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (v) => reimburseAmount = v,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: TextEditingController(text: remark),
              decoration: InputDecoration(
                labelText: '备注',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (v) => remark = v,
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F6EF7)),
                onPressed: () {
                  final amount = double.tryParse(reimburseAmount) ?? 0;
                  if (amount > 0) {
                    provider.addReimbursement(r.id!, amount, remark: remark, channel: r.channel);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('确认报销', style: TextStyle(color: Colors.white)),
              )),
            ]),
          ]),
        ),
      ),
    );
  }
}
