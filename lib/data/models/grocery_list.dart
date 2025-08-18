class GroceryList {
  final int? id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GroceryList({
    this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create a new grocery list
  factory GroceryList.create({
    required String name,
  }) {
    final now = DateTime.now();
    return GroceryList(
      name: name.trim(),
      createdAt: now,
      updatedAt: now,
    );
  }

  // Create from database map
  factory GroceryList.fromMap(Map<String, dynamic> map) {
    return GroceryList(
      id: map['id'] as int?,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create a copy with updated fields
  GroceryList copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroceryList(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Update the name and updatedAt timestamp
  GroceryList updateName(String newName) {
    return copyWith(
      name: newName.trim(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroceryList &&
        other.id == id &&
        other.name == name &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, createdAt, updatedAt);
  }

  @override
  String toString() {
    return 'GroceryList(id: $id, name: $name, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
