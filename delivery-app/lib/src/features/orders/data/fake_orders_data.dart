import 'package:delivery_app/src/features/orders/models/client_model.dart';
import 'package:delivery_app/src/features/orders/models/order_model.dart';

class FakeOrdersData {
  // Track order statuses for simulator mode
  static final Map<String, String> _orderStatuses = {};

  static void updateOrderStatus(String orderId, String newStatus) {
    _orderStatuses[orderId] = newStatus;
  }

  static String getOrderStatus(String orderId, String defaultStatus) {
    return _orderStatuses[orderId] ?? defaultStatus;
  }

  static List<OrderModel> getFakeOrders() {
    return [
      _createFakeOrder1(),
      _createFakeOrder2(),
      _createFakeOrder3(),
    ];
  }

  static OrderModel _createFakeOrder1() {
    final status = getOrderStatus('1', OrderStatus.pending);
    return OrderModel(
      id: '1',
      orderNumber: '123456789',
      status: status,
      items: [
        OrderItem(
          id: '1',
          name: 'Plat Arabi',
          quantity: 2,
          price: 650.0,
          imageUrl: null,
        ),
        OrderItem(
          id: '2',
          name: 'Coca Cola',
          quantity: 2,
          price: 70.0,
          imageUrl: null,
        ),
        OrderItem(
          id: '3',
          name: 'Shawarma',
          quantity: 1,
          price: 360.0,
          imageUrl: null,
        ),
      ],
      totalPrice: 1800.0,
      deliveryAddress: 'Local 10, Cite 40 Logts Btb4, Bab Ezzouar',
      createdAt: DateTime(2024, 9, 13, 11, 0),
      deliveryDistance: 2.5,
      deliveryTimeMinutes: 12,
      deliveryPrice: 300.0,
      restaurantName: 'Le Gourmet Burger',
      restaurantAddress: 'Cite 123, Bab Ezzouar, Alger',
      client: const ClientModel(
        name: 'moncef azzouz',
        phoneNumber: '+213 555 123 456',
        address: 'Local 10, Cite 40 Logts Btb4, Bab Ezzouar',
        email: 'test@example.com',
      ),
    );
  }

  static OrderModel _createFakeOrder2() {
    final status = getOrderStatus('2', OrderStatus.pending);
    return OrderModel(
      id: '2',
      orderNumber: '987654321',
      status: status,
      items: [
        OrderItem(
          id: '4',
          name: 'Tacos XL',
          quantity: 2,
          price: 600.0,
          imageUrl: null,
        ),
        OrderItem(
          id: '5',
          name: 'Sandwich Poulet',
          quantity: 1,
          price: 450.0,
          imageUrl: null,
        ),
      ],
      totalPrice: 1650.0,
      deliveryAddress: '456 Avenue Test, Oran',
      createdAt: DateTime(2024, 9, 13, 12, 30),
      deliveryDistance: 3.2,
      deliveryTimeMinutes: 15,
      deliveryPrice: 400.0,
      restaurantName: 'Tacos de Lyon',
      restaurantAddress: 'Boulevard des Martyrs, Oran',
      client: const ClientModel(
        name: 'sarra',
        phoneNumber: '+213 555 789 012',
        address: '456 Avenue Test, Oran',
        email: 'test@example.com',
      ),
    );
  }

  static OrderModel _createFakeOrder3() {
    final status = getOrderStatus('3', OrderStatus.pending);
    return OrderModel(
      id: '3',
      orderNumber: '555666777',
      status: status,
      items: [
        OrderItem(
          id: '6',
          name: 'Pizza Margherita',
          quantity: 1,
          price: 900.0,
          imageUrl: null,
        ),
        OrderItem(
          id: '7',
          name: 'Coca Cola',
          quantity: 2,
          price: 150.0,
          imageUrl: null,
        ),
      ],
      totalPrice: 1200.0,
      deliveryAddress: '789 Boulevard Sample, Constantine',
      createdAt: DateTime(2024, 9, 13, 13, 15),
      deliveryDistance: 1.8,
      deliveryTimeMinutes: 8,
      deliveryPrice: 300.0,
      restaurantName: 'Pizzeria Bella',
      restaurantAddress: 'Rue de la Marne, Constantine',
      client: const ClientModel(
        name: 'Sara Meziane',
        phoneNumber: '+213 555 345 678',
        address: '789 Boulevard Sample, Constantine',
        email: 'sara.meziane@example.com',
      ),
    );
  }

  static OrderModel? getFakeOrderById(String id) {
    try {
      return getFakeOrders().firstWhere((order) => order.id == id);
    } catch (_) {
      return null;
    }
  }
}
