import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/record.dart' as models;
import '../models/category.dart';
import '../utils/time_of_day.dart';

class AddRecordPage extends StatefulWidget {
  const AddRecordPage({super.key});

  @override
  State<AddRecordPage> createState() => _AddRecordPageState();
}

class _AddRecordPageState extends State<AddRecordPage> {
  String _type = 'expense';
  String _amount = '';
  int _selectedCatIndex = 0;
  String _selectedChannel = '现金';
  DateTime _selectedDate = DateTime.now();
  MyTimeOfDay? _selectedTime;
  bool _timeEnabled = false;
  String _discount = '';  // 优惠金额字符串
  final _remarkController = TextEditingController();

  // ignore: unused_element
  List<Category> get _categories =>
      _type == 'expense'
          ? context.read<AppProvider>().expenseCategories
          : context.read<AppProvider>().incomeCategories;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final cats = _type == 'expense' ? provider.expenseCategories : provider.incomeCategories;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.read<AppProvider>().requestSwitchTab(0)),
        title: const Text('记一笔', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // 支出/收入切换
          _buildTypeTabs(),
          // 金额显示
          _buildAmountDisplay(),
          // 分类网格
          Expanded(child: _buildCategoryGrid(cats)),
          // 备注+日期时间+支付渠道
          _buildMetaRow(),
          // 支付渠道选择
          // 数字键盘
          _buildNumpad(),
        ],
      ),
    );
  }

  Widget _buildTypeTabs() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() { _type = 'expense'; _selectedCatIndex = 0; }),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(
                  color: _type == 'expense' ? const Color(0xFFF5365C) : Colors.transparent,
                  width: 2.5,
                )),
              ),
              child: Text('支出', textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: _type == 'expense' ? const Color(0xFFF5365C) : const Color(0xFF9CA3AF),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() { _type = 'income'; _selectedCatIndex = 0; }),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(
                  color: _type == 'income' ? const Color(0xFF2DC653) : Colors.transparent,
                  width: 2.5,
                )),
              ),
              child: Text('收入', textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: _type == 'income' ? const Color(0xFF2DC653) : const Color(0xFF9CA3AF),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountDisplay() {
    final discountVal = _discount.isNotEmpty ? (double.tryParse(_discount) ?? 0.0) : 0.0;
    final amountVal = _amount.isNotEmpty ? (double.tryParse(_amount) ?? 0.0) : 0.0;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('¥', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey[600])),
              const SizedBox(width: 4),
              Text(_amount.isEmpty ? '0' : _amount,
                style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: Color(0xFF1A1D26), letterSpacing: -1),
              ),
            ],
          ),
          if (discountVal > 0 && _type == 'expense') ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('优惠 -¥${discountVal.toStringAsFixed(discountVal == discountVal.roundToDouble() ? 0 : 2)}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFFF59E0B), fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Text('实际 ¥${(amountVal - discountVal).toStringAsFixed((amountVal - discountVal) == (amountVal - discountVal).roundToDouble() ? 0 : 2)}',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1A1D26), fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(List<Category> cats) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5, childAspectRatio: 0.85, mainAxisSpacing: 4, crossAxisSpacing: 4,
      ),
      itemCount: cats.length,
      itemBuilder: (ctx, i) {
        final selected = i == _selectedCatIndex;
        return GestureDetector(
          onTap: () => setState(() => _selectedCatIndex = i),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: selected ? const Color(0xFFEEF1FE) : Colors.transparent,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(cats[i].emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 2),
                Text(cats[i].name, style: TextStyle(
                  fontSize: 10,
                  color: selected ? const Color(0xFF4F6EF7) : const Color(0xFF6B7280),
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetaRow() {
    final dateLabel = _isToday(_selectedDate) ? '今天' : '${_selectedDate.month}月${_selectedDate.day}日';
    final timeLabel = _timeEnabled && _selectedTime != null
        ? ' ${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
        : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
      child: Row(
        children: [
          const Icon(Icons.edit_note, size: 18, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _remarkController,
              decoration: const InputDecoration(
                hintText: '添加备注...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          // 日期时间按钮
          GestureDetector(
            onTap: _showDateTimePicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today, size: 14, color: Color(0xFF4F6EF7)),
                const SizedBox(width: 4),
                Text('$dateLabel$timeLabel', style: const TextStyle(fontSize: 12, color: Color(0xFF4F6EF7), fontWeight: FontWeight.w500)),
              ]),
            ),
          ),
          const SizedBox(width: 6),
          // 支付渠道按钮
          GestureDetector(
            onTap: () => _showChannelSelector(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: _selectedChannel != '现金' ? const Color(0xFFEEF1FE) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const Icon(Icons.payment, size: 14, color: Color(0xFF4F6EF7)),
                const SizedBox(width: 4),
                Text(_selectedChannel, style: TextStyle(
                  fontSize: 12,
                  color: _selectedChannel != '现金' ? const Color(0xFF4F6EF7) : const Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                )),
              ]),
            ),
          ),
          if (_type == 'expense') ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _showDiscountInput,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: _discount.isNotEmpty && double.tryParse(_discount) != null && double.parse(_discount) > 0
                      ? const Color(0xFFFFF7E6) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  const Icon(Icons.local_offer, size: 14, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 4),
                  Text(_discount.isNotEmpty && double.tryParse(_discount) != null && double.parse(_discount) > 0
                      ? '-¥$_discount' : '优惠',
                    style: const TextStyle(fontSize: 12, color: Color(0xFFF59E0B), fontWeight: FontWeight.w500),
                  ),
                ]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  void _showDateTimePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _DateTimePicker(
        initialDate: _selectedDate,
        initialTime: _selectedTime,
        timeEnabled: _timeEnabled,
        onConfirm: (date, time, timeOn) {
          setState(() {
            _selectedDate = date;
            _selectedTime = time;
            _timeEnabled = timeOn;
          });
        },
      ),
    );
  }

  void _showChannelSelector() {
    final provider = context.read<AppProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('选择支付方式', style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: provider.channels.map((ch) => GestureDetector(
                onTap: () {
                  setState(() => _selectedChannel = ch.name);
                  Navigator.pop(ctx);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _selectedChannel == ch.name ? const Color(0xFF4F6EF7) : const Color(0xFFE5E7EB), width: 1.5),
                    color: _selectedChannel == ch.name ? const Color(0xFFEEF1FE) : Colors.white,
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(ch.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(ch.name, style: TextStyle(
                      fontSize: 12, fontWeight: _selectedChannel == ch.name ? FontWeight.w600 : FontWeight.w500,
                      color: _selectedChannel == ch.name ? const Color(0xFF4F6EF7) : const Color(0xFF6B7280),
                    )),
                  ]),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showDiscountInput() {
    String tempDiscount = _discount;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('输入优惠金额', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              controller: TextEditingController(text: _discount),
              decoration: InputDecoration(
                hintText: '请输入优惠金额',
                prefixText: '¥ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (v) => tempDiscount = v,
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () { setState(() { _discount = ''; }); Navigator.pop(ctx); },
                child: const Text('清除优惠'),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () { setState(() { _discount = tempDiscount; }); Navigator.pop(ctx); },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F6EF7)),
                child: const Text('确定', style: TextStyle(color: Colors.white)),
              )),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 18),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
      child: Column(
        children: [
          Row(children: [
            _numKey('1'), _numKey('2'), _numKey('3'),
            _numKey('⌫', isDel: true),
          ]),
          Row(children: [
            _numKey('4'), _numKey('5'), _numKey('6'),
            _numKey('完成', isConfirm: true),
          ]),
          Row(children: [
            _numKey('7'), _numKey('8'), _numKey('9'),
          ]),
          Row(children: [
            _numKey('.'), _numKey('0'), _numKey('00'),
          ]),
        ],
      ),
    );
  }

  Widget _numKey(String label, {bool isDel = false, bool isConfirm = false}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: SizedBox(
          height: 46,
          child: ElevatedButton(
            onPressed: () {
              if (isConfirm) {
                _confirmAdd();
              } else if (isDel) {
                _inputDel();
              } else {
                _inputNum(label);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isConfirm ? const Color(0xFF4F6EF7) : const Color(0xFFF3F4F6),
              foregroundColor: isConfirm ? Colors.white : const Color(0xFF1A1D26),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: EdgeInsets.zero,
            ),
            child: Text(
              isConfirm ? '完成' : label,
              style: TextStyle(
                fontSize: isConfirm ? 15 : 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _inputNum(String n) {
    if (n == '.' && _amount.contains('.')) return;
    if (_amount.contains('.') && _amount.split('.')[1].length >= 2) return;
    if (_amount == '0' && n != '.' && n != '00') _amount = '';
    setState(() => _amount += n);
  }

  void _inputDel() {
    if (_amount.isNotEmpty) {
      setState(() => _amount = _amount.substring(0, _amount.length - 1));
    }
  }

  void _confirmAdd() {
    if (_amount.isEmpty || _amount == '0' || double.tryParse(_amount) == null) return;
    final provider = context.read<AppProvider>();
    final cats = _type == 'expense' ? provider.expenseCategories : provider.incomeCategories;
    if (cats.isEmpty || _selectedCatIndex >= cats.length) return;

    final record = models.Record(
      ledgerId: provider.currentLedger?.id ?? '1',
      type: _type,
      amount: double.parse(_amount),
      categoryId: cats[_selectedCatIndex].id ?? '0',
      remark: _remarkController.text.isEmpty ? null : _remarkController.text,
      channel: _selectedChannel,
      discount: _type == 'expense' ? (_discount.isNotEmpty ? (double.tryParse(_discount) ?? 0.0) : 0.0) : 0.0,
      date: _selectedDate,
      time: _selectedTime,
    );

    final savedAmount = _amount;
    provider.addRecord(record).then((_) {
      setState(() {
        _amount = '';
        _discount = '';
        _remarkController.clear();
        _selectedChannel = '现金';
        _selectedDate = DateTime.now();
        _selectedTime = null;
        _timeEnabled = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ 记账成功！¥$savedAmount'), backgroundColor: const Color(0xFF2DC653), duration: const Duration(seconds: 1)),
      );
      provider.requestSwitchTab(0);
    });
  }
}

// ========== 日期时间选择器 ==========
class _DateTimePicker extends StatefulWidget {
  final DateTime initialDate;
  final MyTimeOfDay? initialTime;
  final bool timeEnabled;
  final Function(DateTime, MyTimeOfDay?, bool) onConfirm;

  const _DateTimePicker({
    required this.initialDate,
    this.initialTime,
    required this.timeEnabled,
    required this.onConfirm,
  });

  @override
  State<_DateTimePicker> createState() => _DateTimePickerState();
}

class _DateTimePickerState extends State<_DateTimePicker> {
  late DateTime _selectedDate;
  late int _hour;
  late int _minute;
  late bool _timeOn;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _hour = widget.initialTime?.hour ?? 9;
    _minute = widget.initialTime?.minute ?? 30;
    _timeOn = widget.timeEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // ignore: unused_local_variable
    final firstDay = DateTime(now.year, now.month, 1);
    // ignore: unused_local_variable
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final isToday = _selectedDate.year == now.year && _selectedDate.month == now.month && _selectedDate.day == now.day;
    String preview = isToday ? '已选择：今天' : '已选择：${_selectedDate.month}月${_selectedDate.day}日';
    if (_timeOn) preview += ' ${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('选择日期和时间', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          // 日历
          CalendarDatePicker(
            initialDate: _selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            onDateChanged: (d) => setState(() => _selectedDate = d),
          ),
          const SizedBox(height: 8),
          // 时间开关
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('选择具体时间', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            Switch(
              value: _timeOn,
              activeColor: const Color(0xFF4F6EF7),
              onChanged: (v) => setState(() => _timeOn = v),
            ),
          ]),
          if (_timeOn) ...[
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _timeInput(_hour, (v) => setState(() => _hour = v.clamp(0, 23)))),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text(':', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
              Expanded(child: _timeInput(_minute, (v) => setState(() => _minute = v.clamp(0, 59)))),
              const SizedBox(width: 8),
              const Text('24小时制', style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
            ]),
          ],
          const SizedBox(height: 16),
          // 预览
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFEEF1FE), borderRadius: BorderRadius.circular(10)),
            child: Text(preview, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4F6EF7))),
          ),
          const SizedBox(height: 12),
          // 确认按钮
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                widget.onConfirm(_selectedDate, _timeOn ? MyTimeOfDay(hour: _hour, minute: _minute) : null, _timeOn);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F6EF7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
                shadowColor: const Color(0xFF4F6EF7).withOpacity(0.35),
              ),
              child: const Text('✓ 确认选择', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeInput(int value, Function(int) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: () => onChanged(value - 1),
            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
          ),
          Text(value.toString().padLeft(2, '0'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF4F6EF7))),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: () => onChanged(value + 1),
            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
