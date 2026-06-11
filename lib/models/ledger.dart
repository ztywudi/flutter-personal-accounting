class Ledger {
  final String? id;
  final String name;
  final String color; // 十六进制颜色
  final int sortOrder;

  Ledger({
    this.id,
    required this.name,
    this.color = '#4F6EF7',
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'sort_order': sortOrder,
    };
  }

  factory Ledger.fromMap(Map<String, dynamic> map) {
    return Ledger(
      id: map['id'],
      name: map['name'],
      color: map['color'] ?? '#4F6EF7',
      sortOrder: map['sort_order'] ?? 0,
    );
  }
}
