class Category {
  final String? id;
  final String type; // 'expense' | 'income'
  final String emoji;
  final String name;
  final int sortOrder;

  Category({
    this.id,
    required this.type,
    required this.emoji,
    required this.name,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'emoji': emoji,
      'name': name,
      'sort_order': sortOrder,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      type: map['type'],
      emoji: map['emoji'],
      name: map['name'],
      sortOrder: map['sort_order'] ?? 0,
    );
  }

  Category copyWith({String? name, String? emoji, int? sortOrder}) {
    return Category(
      id: id,
      type: type,
      emoji: emoji ?? this.emoji,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
