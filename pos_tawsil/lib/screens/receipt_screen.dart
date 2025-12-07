// lib/screens/receipt_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_theme.dart';
import '../models/order.dart';
import '../services/print_service.dart';

class ReceiptScreen extends StatelessWidget {
  final Order order;

  const ReceiptScreen({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TawsilColors.background,
      appBar: AppBar(
        backgroundColor: TawsilColors.primary,
        title: Text('Reçu ${order.orderNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded),
            onPressed: () => _printReceipt(context),
            tooltip: 'Imprimer',
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () => _shareReceipt(context),
            tooltip: 'Partager',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TawsilSpacing.lg),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: TawsilElevation.md,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TawsilBorderRadius.lg),
              ),
              child: Padding(
                padding: const EdgeInsets.all(TawsilSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const Divider(height: TawsilSpacing.xl),
                    _buildOrderInfo(),
                    const Divider(height: TawsilSpacing.xl),
                    _buildItemsList(),
                    const Divider(height: TawsilSpacing.xl),
                    _buildTotals(),
                    const SizedBox(height: TawsilSpacing.xl),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(TawsilSpacing.md),
          decoration: BoxDecoration(
            color: TawsilColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(TawsilBorderRadius.full),
          ),
          child: Icon(
            Icons.restaurant_rounded,
            size: 48,
            color: TawsilColors.primary,
          ),
        ),
        const SizedBox(height: TawsilSpacing.md),
        Text(
          'POS TAWSIL',
          style: TawsilTextStyles.displayMedium.copyWith(
            color: TawsilColors.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: TawsilSpacing.xs),
        Text(
          'Restaurant',
          style: TawsilTextStyles.bodyMedium.copyWith(
            color: TawsilColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOrderInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'INFORMATIONS COMMANDE',
          style: TawsilTextStyles.headingSmall.copyWith(
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: TawsilSpacing.md),
        _buildInfoRow('Numéro', order.orderNumber),
        _buildInfoRow('Date', _formatDateTime(order.createdAt)),
        _buildInfoRow('Type', order.orderType == 'pickup' ? 'Sur place' : 'Livraison'),
        _buildInfoRow('Paiement', _formatPaymentMethod(order.paymentMethod)),
        _buildInfoRow('Statut', _formatStatus(order.status)),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TawsilSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TawsilTextStyles.bodyMedium.copyWith(
              color: TawsilColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TawsilTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ARTICLES',
          style: TawsilTextStyles.headingSmall.copyWith(
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: TawsilSpacing.md),
        ...order.items.map((item) => _buildItemRow(item)).toList(),
      ],
    );
  }

  Widget _buildItemRow(dynamic item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TawsilSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: TawsilColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(TawsilBorderRadius.sm),
            ),
            child: Center(
              child: Text(
                'x${item.quantite}',
                style: TawsilTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: TawsilColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: TawsilSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.photoUrl != null && (item.photoUrl as String).isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(TawsilBorderRadius.sm),
                        child: Image.network(
                          item.photoUrl,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 52,
                            height: 52,
                            color: TawsilColors.background,
                            child: const Icon(Icons.fastfood, size: 20, color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.menuItemName?.isNotEmpty == true ? item.menuItemName : 'Article',
                            style: TawsilTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (item.instructionsSpeciales != null &&
                              item.instructionsSpeciales.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Note: ${item.instructionsSpeciales}',
                              style: TawsilTextStyles.bodySmall.copyWith(
                                fontStyle: FontStyle.italic,
                                color: TawsilColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (item.additions.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: item.additions.map<Widget>((add) {
                      final addName = (add.nom as String?)?.isNotEmpty == true ? add.nom : 'Supplément';
                      return Chip(
                        label: Text(
                          '$addName x${add.quantity} (+${add.total.toStringAsFixed(0)} DA)',
                          style: TawsilTextStyles.bodySmall,
                        ),
                        backgroundColor: TawsilColors.background,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${item.prixUnitaire.toStringAsFixed(2)} DA × ${item.quantite}',
                  style: TawsilTextStyles.bodySmall.copyWith(
                    color: TawsilColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${item.prixTotal.toStringAsFixed(2)} DA',
            style: TawsilTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: TawsilColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotals() {
    return Column(
      children: [
        _buildTotalRow('Sous-total', order.subtotal, false),
        const SizedBox(height: TawsilSpacing.sm),
        const Divider(),
        const SizedBox(height: TawsilSpacing.sm),
        _buildTotalRow('TOTAL', order.totalAmount, true),
      ],
    );
  }

  Widget _buildTotalRow(String label, double amount, bool isTotal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? TawsilTextStyles.headingMedium
              : TawsilTextStyles.bodyMedium.copyWith(
                  color: TawsilColors.textSecondary,
                ),
        ),
        Text(
          '${amount.toStringAsFixed(2)} DA',
          style: isTotal
              ? TawsilTextStyles.priceLarge
              : TawsilTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(TawsilSpacing.md),
          decoration: BoxDecoration(
            color: TawsilColors.background,
            borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
          ),
          child: Column(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: TawsilColors.success,
                size: 32,
              ),
              const SizedBox(height: TawsilSpacing.sm),
              Text(
                'Merci de votre visite !',
                style: TawsilTextStyles.headingSmall.copyWith(
                  color: TawsilColors.success,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TawsilSpacing.xs),
              Text(
                'À bientôt',
                style: TawsilTextStyles.bodySmall.copyWith(
                  color: TawsilColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: TawsilSpacing.lg),
        Text(
          'Reçu généré le ${_formatDateTime(DateTime.now())}',
          style: TawsilTextStyles.bodySmall.copyWith(
            color: TawsilColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
        'à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatPaymentMethod(String method) {
    switch (method) {
      case 'cash_on_delivery':
        return 'Espèces';
      case 'baridi_mob':
        return 'Baridi Mob';
      case 'bank_transfer':
        return 'Virement bancaire';
      default:
        return method;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'accepted':
        return 'Acceptée';
      case 'preparing':
        return 'En préparation';
      case 'delivered':
        return 'Livrée';
      case 'declined':
        return 'Annulée';
      default:
        return status;
    }
  }

  Future<void> _printReceipt(BuildContext context) async {
    try {
      final printer = PrintService();
      await printer.printOrder(order);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: TawsilSpacing.sm),
              const Text('Reçu envoyé à l\'imprimante'),
            ],
          ),
          backgroundColor: TawsilColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur d\'impression: ${e.toString()}'),
          backgroundColor: TawsilColors.error,
        ),
      );
    }
  }

  Future<void> _shareReceipt(BuildContext context) async {
    final receiptText = _generateReceiptText();
    await Clipboard.setData(ClipboardData(text: receiptText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: TawsilSpacing.sm),
            const Text('Reçu copié dans le presse-papiers'),
          ],
        ),
        backgroundColor: TawsilColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
        ),
      ),
    );
  }

  String _generateReceiptText() {
    final buffer = StringBuffer();
    buffer.writeln('-----------------------------');
    buffer.writeln('       POS TAWSIL');
    buffer.writeln('       Restaurant');
    buffer.writeln('-----------------------------');
    buffer.writeln();
    buffer.writeln('Commande: ${order.orderNumber}');
    buffer.writeln('Date: ${_formatDateTime(order.createdAt)}');
    buffer.writeln('Type: ${order.orderType == 'pickup' ? 'Sur place' : 'Livraison'}');
    buffer.writeln('Paiement: ${_formatPaymentMethod(order.paymentMethod)}');
    buffer.writeln();
    buffer.writeln('ARTICLES');
    buffer.writeln('-----------------------------');
    for (var item in order.items) {
      buffer.writeln();
      buffer.writeln('${item.quantite}× ${item.menuItemName}');
      if (item.instructionsSpeciales != null && item.instructionsSpeciales!.isNotEmpty) {
        buffer.writeln('   Note: ${item.instructionsSpeciales}');
      }
      for (var add in item.additions) {
        buffer.writeln('   + ${add.nom} x${add.quantity} (${add.total.toStringAsFixed(0)} DA)');
      }
      buffer.writeln('   ${item.prixUnitaire.toStringAsFixed(2)} DA × ${item.quantite} = ${item.prixTotal.toStringAsFixed(2)} DA');
    }
    buffer.writeln();
    buffer.writeln('Sous-total: ${order.subtotal.toStringAsFixed(2)} DA');
    buffer.writeln('TOTAL: ${order.totalAmount.toStringAsFixed(2)} DA');
    buffer.writeln('-----------------------------');
    buffer.writeln('Merci de votre visite !');
    buffer.writeln('À bientôt');
    return buffer.toString();
  }
}
