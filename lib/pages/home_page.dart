import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/record.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: RefreshIndicator(
        onRefresh: () => provider.loadAll(),
        child: CustomScrollView(
          slivers: [
            // 顶部区域
            SliverToBoxAdapter(child: _buildHeader(context, provider)),
            // 快捷按钮
            SliverToBoxAdapter(child: _buildQuickActions(context)),
            // 今日明细标题
            SliverToBoxAdapter(child: _buildSectionTitle(context, provider)),
            // 今日明细列表
            _buildBillList(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppProvider provider) {
    final now = DateTime.now();
    final greeting = now.hour < 12 ? '上午好 👋' : now.hour < 18 ? '下午好 👋' : '晚上好 👋';
    final dateStr = '${now.month}月${now.day}日 ${_weekday(now)}';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        children: [
          // 顶部问候+账本选择
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(greeting, style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
              const SizedBox(height: 2),
              Text(dateStr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            ]),
            GestureDetector(
              onTap: () => _showLedgerSelector(context, provider),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFEEF1FE), borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  const Text('📒', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(provider.currentLedger?.name ?? '日常账本',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF4F6EF7), fontWeight: FontWeight.w600)),
                  const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF4F6EF7)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          // 余额卡片
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF4F6EF7), Color(0xFF6B85F9)],
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('本月余额（元）', style: TextStyle(fontSize: 13, color: Colors.white70)),
              const SizedBox(height: 6),
              Text(_formatAmount(provider.monthBalance), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
              const SizedBox(height: 16),
              Container(padding: const EdgeInsets.only(top: 16), decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white24))),
                child: Row(children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('本月收入', style: TextStyle(fontSize: 12, color: Colors.white70)),
                    const SizedBox(height: 2),
                    Text(_formatAmount(provider.monthIncome), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                  ]),
                  const Spacer(),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('本月支出', style: TextStyle(fontSize: 12, color: Colors.white70)),
                    const SizedBox(height: 2),
                    Text(_formatAmount(provider.monthExpense), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                  ]),
                ]),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _goToAdd(context, 'expense'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFDE8EB), foregroundColor: const Color(0xFFF5365C),
              elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('−', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              SizedBox(width: 8), Text('记支出', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _goToAdd(context, 'income'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8F8ED), foregroundColor: const Color(0xFF2DC653),
              elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('+', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              SizedBox(width: 8), Text('记收入', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildSectionTitle(BuildContext context, AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('今日明细', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        Text('支出 ¥${provider.todayExpense.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
      ]),
    );
  }

  Widget _buildBillList(AppProvider provider) {
    if (provider.todayRecords.isEmpty) {
      return SliverFillRemaining(
        child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('📭', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('今天还没有记录', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
        ])),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate((ctx, i) {
        final r = provider.todayRecords[i];
        final cat = provider.getCategoryById(r.categoryId);
        return _buildBillItem(ctx, provider, r, cat?.emoji ?? '📦', cat?.name ?? '未知');
      }, childCount: provider.todayRecords.length),
    );
  }

  Widget _buildBillItem(BuildContext context, AppProvider provider, Record r, String emoji, String catName) {
    final isExpense = r.type == 'expense';
    return GestureDetector(
      onLongPress: () => _showRecordActions(context, provider, r),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Dismissible(
          key: ValueKey(r.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(color: const Color(0xFFF5365C), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => provider.deleteRecord(int.parse(r.id!)),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
            ]),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: isExpense ? const Color(0xFFFDE8EB) : const Color(0xFFE8F8ED),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(catName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
        ),
      ),
    );
  }

  void _showLedgerSelector(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('选择账本', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ...provider.ledgers.map((l) => ListTile(
            leading: CircleAvatar(backgroundColor: _parseColor(l.color), radius: 5),
            title: Text(l.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: l.id == provider.currentLedger?.id
                ? const Icon(Icons.check, color: Color(0xFF4F6EF7))
                : null,
            onTap: () { provider.setCurrentLedger(l); Navigator.pop(ctx); },
          )),
        ]),
      ),
    );
  }

  void _goToAdd(BuildContext context, String type) {
    context.read<AppProvider>().requestSwitchTab(2);
  }

  String _formatAmount(double v) {
    final f = NumberFormat('#,##0.00', 'zh_CN');
    return f.format(v);
  }

  String _weekday(DateTime d) {
    const days = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return days[d.weekday - 1];
  }

  Color _parseColor(String hex) {
    final c = hex.replaceAll('#', '');
    return Color(int.parse('FF$c', radix: 16));
  }

  void _showRecordActions(BuildContext context, AppProvider provider, Record r) {
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
              onTap: () { Navigator.pop(ctx); _showRefundDialog(context, provider, r); },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long, color: Color(0xFF4F6EF7)),
              title: const Text('记报销', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('关联报销到这笔支出'),
              onTap: () { Navigator.pop(ctx); _showReimburseDialog(context, provider, r); },
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

  void _showRefundDialog(BuildContext context, AppProvider provider, Record r) {
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

  void _showReimburseDialog(BuildContext context, AppProvider provider, Record r) {
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
