class ShoppingItem {
  final String id;
  final String name;
  final bool purchased;

  const ShoppingItem({
    required this.id,
    required this.name,
    required this.purchased,
  });

  ShoppingItem copyWith({
    String? id,
    String? name,
    bool? purchased,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      purchased: purchased ?? this.purchased,
    );
  }
}
