class Channel {
  final String? id;
  final String emoji;
  final String name;

  Channel({this.id, required this.emoji, required this.name});

  Map<String, dynamic> toMap() => {'id': id, 'emoji': emoji, 'name': name};

  factory Channel.fromMap(Map<String, dynamic> map) =>
      Channel(id: map['id'], emoji: map['emoji'], name: map['name']);
}