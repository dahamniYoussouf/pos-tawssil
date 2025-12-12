import 'order_item.dart';

class Order {
  final String id;
  final String orderNumber;
  final String cashierId;
  final String restaurantId;
  final String orderType;
  final double subtotal;
  final double totalAmount;
  final String paymentMethod;
  final String status;
  final List<OrderItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool synced;

  Order({
    required this.id,
    required this.orderNumber,
    required this.cashierId,
    required this.restaurantId,
    this.orderType = 'pickup',
    required this.subtotal,
    required this.totalAmount,
    required this.paymentMethod,
    this.status = 'pending',
    required this.items,
    required this.createdAt,
    required this.updatedAt,
    this.synced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_number': orderNumber,
      'cashier_id': cashierId,
      'restaurant_id': restaurantId,
      'order_type': orderType,
      'subtotal': subtotal,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'synced': synced ? 1 : 0,
    };
  }

  factory Order.fromMap(
    Map<String, dynamic> orderMap,
    List<Map<String, dynamic>> itemMaps,
  ) {
    return Order(
      id: orderMap['id'],
      orderNumber: orderMap['order_number'],
      cashierId: orderMap['cashier_id'],
      restaurantId: orderMap['restaurant_id'],
      orderType: orderMap['order_type'],
      subtotal: _toDouble(orderMap['subtotal']),
      totalAmount: _toDouble(orderMap['total_amount']),
      paymentMethod: orderMap['payment_method'],
      status: orderMap['status'],
      items: itemMaps.map((m) => OrderItem.fromMap(m)).toList(),
      createdAt: DateTime.parse(orderMap['created_at']),
      updatedAt: DateTime.parse(orderMap['updated_at']),
      synced: orderMap['synced'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'restaurant_id': restaurantId,
      'order_type': orderType,
      'payment_method': paymentMethod,
      'items': items.map((item) {
        final data = <String, dynamic>{
          'menu_item_id': item.menuItemId,
          'menu_item_name': item.menuItemName,
          'unit_price': item.prixUnitaire,
          'quantity': item.quantite,
          'additions': item.additions
              .map((a) => {
                    'addition_id': a.additionId,
                    'quantity': a.quantity,
                  })
              .toList(),
        };
        if (item.instructionsSpeciales != null && item.instructionsSpeciales!.isNotEmpty) {
          data['special_instructions'] = item.instructionsSpeciales;
        }
        return data;
      }).toList(),
    };
  }

  Order copyWith({
    String? id,
    String? orderNumber,
    String? cashierId,
    String? restaurantId,
    String? orderType,
    double? subtotal,
    double? totalAmount,
    String? paymentMethod,
    String? status,
    List<OrderItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? synced,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      cashierId: cashierId ?? this.cashierId,
      restaurantId: restaurantId ?? this.restaurantId,
      orderType: orderType ?? this.orderType,
      subtotal: subtotal ?? this.subtotal,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] ?? json['order_items']) as List<dynamic>? ?? [];

    return Order(
      id: json['id'],
      orderNumber: json['order_number'] ?? '',
      cashierId: json['cashier_id'] ?? '',
      restaurantId: json['restaurant_id'],
      orderType: json['order_type'] ?? 'pickup',
      subtotal: _toDouble(json['subtotal']),
      totalAmount: _toDouble(json['total_amount']),
      paymentMethod: json['payment_method'],
      status: json['status'] ?? 'pending',
      items: rawItems.map((item) => OrderItem.fromJson(item)).toList(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      synced: true,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

}
