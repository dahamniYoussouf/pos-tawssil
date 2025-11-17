import 'package:restaurant_app/src/features/orders/models/order_model.dart';

class FakeOrdersData {
  static List<OrderModel> getFakeOrders() {
    return [
      OrderModel(
        id: '1',
        orderNumber: 'X-123456789',
        status: OrderStatus.pending,
        items: [
          OrderItem(
            id: '1',
            name: 'Burger double',
            quantity: 1,
            price: 750.0,
            imageUrl: null,
          ),
          OrderItem(
            id: '2',
            name: 'Pizza 4 fromages',
            quantity: 1,
            price: 800.0,
            imageUrl: null,
          ),
          OrderItem(
            id: '3',
            name: 'Hamoud bida',
            quantity: 2,
            price: 200.0,
            imageUrl: null,
          ),
        ],
        totalPrice: 2450.0,
        deliveryAddress: '123 Rue Example, Alger',
        createdAt: DateTime(2024, 9, 13, 11, 0),
        deliveryDistance: 2.5,
        deliveryTimeMinutes: 10,
        deliveryPrice: 500.0,
      ),
      OrderModel(
        id: '2',
        orderNumber: 'X-987654321',
        status: OrderStatus.pending,
        items: [
          OrderItem(
            id: '4',
            name: 'Tacos',
            quantity: 2,
            price: 600.0,
            imageUrl: null,
          ),
          OrderItem(
            id: '5',
            name: 'Sandwich',
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
        deliveryPrice: 500.0,
      ),
      OrderModel(
        id: '3',
        orderNumber: 'X-555666777',
        status: OrderStatus.pending,
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
        deliveryPrice: 500.0,
      ),
    ];
  }
}

