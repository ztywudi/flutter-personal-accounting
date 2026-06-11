import '../utils/time_of_day.dart';

class Record {
  final String? id;
  final String ledgerId;
  final String type; // 'expense' | 'income'
  final double amount;
  final String categoryId;
  final String? remark;
  final String channel; // 支付渠道
  final double discount; // 优惠/折扣金额（默认0）
  final String? relatedRecordId; // 关联的原始记录ID（退款/报销关联到原支出记录）
  final String relationType; // 关联类型：'none' | 'refund' | 'reimbursement'
  final DateTime date;
  final MyTimeOfDay? time; // 具体时间（可选）
  final DateTime createdAt;

  Record({
    this.id,
    required this.ledgerId,
    required this.type,
    required this.amount,
    required this.categoryId,
    this.remark,
    this.channel = '现金',
    this.discount = 0,
    this.relatedRecordId,
    this.relationType = 'none',
    required this.date,
    this.time,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 计算属性：支出时 = amount - discount；收入时 = amount
  double get actualAmount => type == 'expense' ? amount - discount : amount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ledger_id': ledgerId,
      'type': type,
      'amount': amount,
      'category_id': categoryId,
      'remark': remark,
      'channel': channel,
      'discount': discount,
      'related_record_id': relatedRecordId,
      'relation_type': relationType,
      'date': date.toIso8601String().substring(0, 10),
      'time': time != null ? '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}' : null,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Record.fromMap(Map<String, dynamic> map) {
    return Record(
      id: map['id']?.toString(),
      ledgerId: map['ledger_id'].toString(),
      type: map['type'],
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['category_id'].toString(),
      remark: map['remark'],
      channel: map['channel'] ?? '现金',
      discount: (map['discount'] as num?)?.toDouble() ?? 0,
      relatedRecordId: map['related_record_id']?.toString(),
      relationType: map['relation_type'] as String? ?? 'none',
      date: DateTime.parse(map['date']),
      time: map['time'] != null ? _parseTime(map['time']) : null,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  static MyTimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    return MyTimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}
