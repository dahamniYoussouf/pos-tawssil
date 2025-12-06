import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/order_provider.dart';
import 'order_screen.dart';
import 'login_screen.dart';

class CashierSelectionScreen extends StatefulWidget {
  const CashierSelectionScreen({Key? key}) : super(key: key);

  @override
  State<CashierSelectionScreen> createState() => _CashierSelectionScreenState();
}

class _CashierSelectionScreenState extends State<CashierSelectionScreen> {
  // Demo cashiers - En production, charger depuis la BDD
  final List<Map<String, String>> cashiers = [
    {'id': '1', 'name': 'Ahmed', 'code': 'CASH01'},
    {'id': '2', 'name': 'Fatima', 'code': 'CASH02'},
    {'id': '3', 'name': 'Karim', 'code': 'CASH03'},
    {'id': '4', 'name': 'Sara', 'code': 'CASH04'},
  ];

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('restaurant_id');
    
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélectionner le Caissier'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          itemCount: cashiers.length,
          itemBuilder: (context, index) {
            final cashier = cashiers[index];
            return _CashierCard(
              name: cashier['name']!,
              code: cashier['code']!,
              onTap: () {
                context.read<OrderProvider>().selectCashier(cashier['id']!);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const OrderScreen(),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _CashierCard extends StatelessWidget {
  final String name;
  final String code;
  final VoidCallback onTap;

  const _CashierCard({
    required this.name,
    required this.code,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person,
                size: 48,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                code,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
