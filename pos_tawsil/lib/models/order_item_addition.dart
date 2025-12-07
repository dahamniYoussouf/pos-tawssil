class OrderItemAddition {
  final String additionId;
  final String nom;
  final double prix;
  final int quantity;

  const OrderItemAddition({
    required this.additionId,
    required this.nom,
    required this.prix,
    this.quantity = 1,
  });

  double get total => prix * quantity;

  factory OrderItemAddition.fromJson(Map<String, dynamic> json) {
    return OrderItemAddition(
      additionId: json['addition_id'] ?? json['id'],
      nom: json['nom'] ?? '',
      prix: _parseDouble(json['prix_unitaire'] ?? json['prix']),
      quantity: json['quantite'] ?? json['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'addition_id': additionId,
      'nom': nom,
      'prix': prix,
      'quantity': quantity,
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
