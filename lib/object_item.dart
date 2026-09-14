class ObjectItem {
  const ObjectItem({required this.id, required this.name, this.data});

  factory ObjectItem.fromJson(Map<String, dynamic> json) {
    return ObjectItem(
      id: json['id'] as String,
      name: json['name'] as String,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  final String id;
  final String name;
  final Map<String, dynamic>? data;

  Map<String, dynamic> toJson() => {'name': name, 'data': data};
}
