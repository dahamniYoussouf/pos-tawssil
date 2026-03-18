import 'dart:typed_data';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import '../models/order.dart';

/// Générateur de tickets ESC/POS pour l'impression locale
/// Génère le même format que le backend pour la cohérence
class TicketGenerator {
  static CapabilityProfile? _profile;
  static img.Image? _logoImage;
  static img.Image? _logoMono58;
  static img.Image? _logoMono80;
  
  /// Charge le profil de capacité une seule fois
  static Future<CapabilityProfile> _getProfile() async {
    _profile ??= await CapabilityProfile.load();
    return _profile!;
  }

  static PaperSize _resolvePaperSize(int paperWidth) {
    return paperWidth <= 58 ? PaperSize.mm58 : PaperSize.mm80;
  }

  static int _maxWidthPxForPaper(PaperSize size) {
    return size == PaperSize.mm58 ? 384 : 576;
  }

  static Future<img.Image?> _loadLogoImage() async {
    if (_logoImage != null) return _logoImage;
    try {
      final data = await rootBundle.load('assets/images/logo_green.webp');
      final bytes = data.buffer.asUint8List();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      _logoImage = decoded;
      return _logoImage;
    } catch (_) {
      return null;
    }
  }

  static img.Image _toMono(img.Image src) {
    // Convert to white background then threshold to 1-bit style.
    final image = img.copyResize(src, width: src.width, height: src.height);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final dynamic pixel = image.getPixel(x, y);
        int r;
        int g;
        int b;
        int a;
        if (pixel is int) {
          r = img.getRed(pixel);
          g = img.getGreen(pixel);
          b = img.getBlue(pixel);
          a = img.getAlpha(pixel);
        } else {
          r = (pixel.r as num).round();
          g = (pixel.g as num).round();
          b = (pixel.b as num).round();
          a = (pixel.a as num).round();
        }

        // Blend with white if transparent.
        final alpha = a / 255.0;
        final rr = (255 + (r - 255) * alpha).round();
        final gg = (255 + (g - 255) * alpha).round();
        final bb = (255 + (b - 255) * alpha).round();

        // Luma and strong threshold so logo prints darker.
        final luma = (0.299 * rr + 0.587 * gg + 0.114 * bb).round();
        final isBlack = luma < 200;
        image.setPixelRgba(x, y, isBlack ? 0 : 255, isBlack ? 0 : 255, isBlack ? 0 : 255, 255);
      }
    }
    return image;
  }

  static img.Image? _getMonoLogo(PaperSize size, int targetWidth) {
    if (size == PaperSize.mm58 && _logoMono58 != null) return _logoMono58;
    if (size == PaperSize.mm80 && _logoMono80 != null) return _logoMono80;
    if (_logoImage == null) return null;

    final resized = img.copyResize(_logoImage!, width: targetWidth);
    final mono = _toMono(resized);
    if (size == PaperSize.mm58) {
      _logoMono58 = mono;
    } else {
      _logoMono80 = mono;
    }
    return mono;
  }

  static Future<bool> _addAppLogo(
    List<int> bytes,
    Generator generator,
    int paperWidth,
  ) async {
    await _loadLogoImage();
    final paperSize = _resolvePaperSize(paperWidth);
    final maxWidth = _maxWidthPxForPaper(paperSize);
    final targetWidth = (maxWidth * 0.30).round();
    final mono = _getMonoLogo(paperSize, targetWidth);
    if (mono == null) return false;

    bytes.addAll(generator.image(mono, align: PosAlign.center));
    bytes.addAll(generator.feed(1));
    return true;
  }

  /// Génère un ticket ESC/POS pour une commande
  static Future<Uint8List> generateEscPosTicket({
    required Order order,
    required String restaurantName,
    required int paperWidth,
    String? cashierName,
    String? cashierCode,
  }) async {
    final profile = await _getProfile();
    final generator = Generator(_resolvePaperSize(paperWidth), profile);
    final List<int> bytes = [];

    // Initialisation
    bytes.addAll(generator.reset());
    bytes.addAll(generator.text('', styles: PosStyles(align: PosAlign.center)));
    
    // En-tête : Nom du restaurant
    bytes.addAll(generator.text(
      restaurantName.toUpperCase(),
      styles: PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    ));
    bytes.addAll(generator.feed(1));

    // Informations de la commande
    bytes.addAll(generator.text(
      'Commande #${order.orderNumber}',
      styles: PosStyles(align: PosAlign.left),
    ));
    
    // Date et heure
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    bytes.addAll(generator.text(
      'Date: ${dateFormat.format(order.createdAt)}',
      styles: PosStyles(align: PosAlign.left),
    ));

    // Type de commande
    if (order.orderType.isNotEmpty) {
      final orderTypeLabel = order.orderType == 'delivery' 
          ? 'Livraison' 
          : order.orderType == 'pickup' 
              ? 'A emporter' 
              : order.orderType;
      bytes.addAll(generator.text(
        'Type: $orderTypeLabel',
        styles: PosStyles(align: PosAlign.left),
      ));
    }

    // Caissier (si disponible)
    if (cashierName != null && cashierName.isNotEmpty) {
      bytes.addAll(generator.text(
        'Caissier: $cashierName${cashierCode != null ? ' ($cashierCode)' : ''}',
        styles: PosStyles(align: PosAlign.left),
      ));
    }

    bytes.addAll(generator.hr());

    // Articles de la commande
    for (final item in order.items) {
      // Nom de l'article avec quantité
      bytes.addAll(generator.text(
        '${item.menuItemName} x${item.quantite}',
        styles: PosStyles(align: PosAlign.left, bold: true),
      ));
      
      // Prix total de l'article
      bytes.addAll(generator.text(
        '  ${_formatAmount(item.prixTotal)} DA',
        styles: PosStyles(align: PosAlign.left),
      ));

      // Instructions spéciales
      if (item.instructionsSpeciales != null && item.instructionsSpeciales!.isNotEmpty) {
        bytes.addAll(generator.text(
          '  Note: ${item.instructionsSpeciales}',
          styles: PosStyles(align: PosAlign.left, fontType: PosFontType.fontB),
        ));
      }

      // Additions (suppléments)
      if (item.additions.isNotEmpty) {
        for (final addition in item.additions) {
          final additionName = addition.nom;
          final additionQty = addition.quantity;
          final additionTotal = addition.total;
          
          bytes.addAll(generator.text(
            '  + $additionName x$additionQty (${_formatAmount(additionTotal)} DA)',
            styles: PosStyles(align: PosAlign.left, fontType: PosFontType.fontB),
          ));
        }
      }
      
      bytes.addAll(generator.feed(1));
    }

    bytes.addAll(generator.hr());

    // Totaux
    bytes.addAll(generator.text(
      'Sous-total: ${_formatAmount(order.subtotal)} DA',
      styles: PosStyles(align: PosAlign.left),
    ));

    // Frais de livraison (si applicable)
    if (order.orderType == 'delivery' && order.totalAmount > order.subtotal) {
      final deliveryFee = order.totalAmount - order.subtotal;
      if (deliveryFee > 0) {
        bytes.addAll(generator.text(
          'Livraison:  ${_formatAmount(deliveryFee)} DA',
          styles: PosStyles(align: PosAlign.left),
        ));
      }
    }

    // Total en gras
    bytes.addAll(generator.text(
      'TOTAL: ${_formatAmount(order.totalAmount)} DA',
      styles: PosStyles(align: PosAlign.left, bold: true, height: PosTextSize.size2),
    ));

    // Méthode de paiement
    if (order.paymentMethod.isNotEmpty) {
      bytes.addAll(generator.feed(1));
      bytes.addAll(generator.text(
        'Paiement: ${_formatPaymentMethod(order.paymentMethod)}',
        styles: PosStyles(align: PosAlign.left),
      ));
    }

    bytes.addAll(generator.feed(2));

    // Message de fin
    bytes.addAll(generator.text(
      'Merci de votre visite !',
      styles: PosStyles(align: PosAlign.center),
    ));

    bytes.addAll(generator.feed(1));
    await _addAppLogo(bytes, generator, paperWidth);
    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.cut());

    return Uint8List.fromList(bytes);
  }

  /// Génère un ticket selon le type d'imprimante
  /// caisse -> ticket complet, cuisine/bar -> items & notes, general -> résumé
  static Future<Uint8List> generateTicketByType({
    required String type,
    required Order order,
    required String restaurantName,
    required int paperWidth,
    String? cashierName,
    String? cashierCode,
  }) async {
    final normalized = type.toLowerCase();
    if (normalized == 'cuisine' || normalized == 'bar') {
      return generateKitchenTicket(
        order: order,
        restaurantName: restaurantName,
        paperWidth: paperWidth,
      );
    }
    if (normalized == 'general') {
      return generateSummaryTicket(
        order: order,
        restaurantName: restaurantName,
        paperWidth: paperWidth,
        cashierName: cashierName,
        cashierCode: cashierCode,
      );
    }
    return generateEscPosTicket(
      order: order,
      restaurantName: restaurantName,
      paperWidth: paperWidth,
      cashierName: cashierName,
      cashierCode: cashierCode,
    );
  }

  /// Ticket cuisine: articles + notes, sans prix
  static Future<Uint8List> generateKitchenTicket({
    required Order order,
    required String restaurantName,
    required int paperWidth,
  }) async {
    final profile = await _getProfile();
    final generator = Generator(_resolvePaperSize(paperWidth), profile);
    final List<int> bytes = [];

    bytes.addAll(generator.reset());
    bytes.addAll(generator.text('', styles: PosStyles(align: PosAlign.center)));

    bytes.addAll(generator.text(
      restaurantName.toUpperCase(),
      styles: PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    ));
    bytes.addAll(generator.feed(1));

    bytes.addAll(generator.text(
      'TICKET CUISINE',
      styles: PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2),
    ));
    bytes.addAll(generator.feed(1));

    bytes.addAll(generator.text(
      'Commande #${order.orderNumber}',
      styles: PosStyles(align: PosAlign.left),
    ));

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    bytes.addAll(generator.text(
      'Date: ${dateFormat.format(order.createdAt)}',
      styles: PosStyles(align: PosAlign.left),
    ));

    if (order.orderType.isNotEmpty) {
      final orderTypeLabel = order.orderType == 'delivery'
          ? 'Livraison'
          : order.orderType == 'pickup'
              ? 'A emporter'
              : order.orderType;
      bytes.addAll(generator.text(
        'Type: $orderTypeLabel',
        styles: PosStyles(align: PosAlign.left),
      ));
    }

    bytes.addAll(generator.hr());

    for (final item in order.items) {
      bytes.addAll(generator.text(
        '${item.menuItemName} x${item.quantite}',
        styles: PosStyles(align: PosAlign.left, bold: true),
      ));

      if (item.instructionsSpeciales != null && item.instructionsSpeciales!.isNotEmpty) {
        bytes.addAll(generator.text(
          '  Note: ${item.instructionsSpeciales}',
          styles: PosStyles(align: PosAlign.left, fontType: PosFontType.fontB),
        ));
      }

      if (item.additions.isNotEmpty) {
        for (final addition in item.additions) {
          final additionName = addition.nom;
          final additionQty = addition.quantity;
          bytes.addAll(generator.text(
            '  + $additionName x$additionQty',
            styles: PosStyles(align: PosAlign.left, fontType: PosFontType.fontB),
          ));
        }
      }

      bytes.addAll(generator.feed(1));
    }

    bytes.addAll(generator.hr());
    bytes.addAll(generator.feed(1));
    await _addAppLogo(bytes, generator, paperWidth);
    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.cut());

    return Uint8List.fromList(bytes);
  }

  /// Ticket général: résumé (totaux + infos essentielles)
  static Future<Uint8List> generateSummaryTicket({
    required Order order,
    required String restaurantName,
    required int paperWidth,
    String? cashierName,
    String? cashierCode,
  }) async {
    final profile = await _getProfile();
    final generator = Generator(_resolvePaperSize(paperWidth), profile);
    final List<int> bytes = [];

    bytes.addAll(generator.reset());
    bytes.addAll(generator.text('', styles: PosStyles(align: PosAlign.center)));

    bytes.addAll(generator.text(
      restaurantName.toUpperCase(),
      styles: PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    ));
    bytes.addAll(generator.feed(1));

    bytes.addAll(generator.text(
      'TICKET GENERAL',
      styles: PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2),
    ));
    bytes.addAll(generator.feed(1));

    bytes.addAll(generator.text(
      'Commande #${order.orderNumber}',
      styles: PosStyles(align: PosAlign.left),
    ));

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    bytes.addAll(generator.text(
      'Date: ${dateFormat.format(order.createdAt)}',
      styles: PosStyles(align: PosAlign.left),
    ));

    if (order.orderType.isNotEmpty) {
      final orderTypeLabel = order.orderType == 'delivery'
          ? 'Livraison'
          : order.orderType == 'pickup'
              ? 'A emporter'
              : order.orderType;
      bytes.addAll(generator.text(
        'Type: $orderTypeLabel',
        styles: PosStyles(align: PosAlign.left),
      ));
    }

    if (cashierName != null && cashierName.isNotEmpty) {
      bytes.addAll(generator.text(
        'Caissier: $cashierName${cashierCode != null ? ' ($cashierCode)' : ''}',
        styles: PosStyles(align: PosAlign.left),
      ));
    }

    bytes.addAll(generator.hr());

    final itemCount = order.items.fold<int>(0, (sum, item) => sum + item.quantite);
    bytes.addAll(generator.text(
      'Articles: $itemCount',
      styles: PosStyles(align: PosAlign.left),
    ));

    bytes.addAll(generator.text(
      'TOTAL: ${_formatAmount(order.totalAmount)} DA',
      styles: PosStyles(align: PosAlign.left, bold: true),
    ));

    if (order.paymentMethod.isNotEmpty) {
      bytes.addAll(generator.text(
        'Paiement: ${_formatPaymentMethod(order.paymentMethod)}',
        styles: PosStyles(align: PosAlign.left),
      ));
    }

    bytes.addAll(generator.feed(1));
    await _addAppLogo(bytes, generator, paperWidth);
    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.cut());

    return Uint8List.fromList(bytes);
  }

  /// Génère un ticket de test pour vérifier l'imprimante
  static Future<Uint8List> generateTestTicket({
    required String restaurantName,
    required int paperWidth,
  }) async {
    final profile = await _getProfile();
    final generator = Generator(_resolvePaperSize(paperWidth), profile);
    final List<int> bytes = [];
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    // Initialisation
    bytes.addAll(generator.reset());
    bytes.addAll(generator.text('', styles: PosStyles(align: PosAlign.center)));
    
    // En-tête : Nom du restaurant
    bytes.addAll(generator.text(
      restaurantName.toUpperCase(),
      styles: PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    ));
    bytes.addAll(generator.feed(1));
    
    // Titre du test
    bytes.addAll(generator.text(
      'TICKET DE TEST',
      styles: PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
      ),
    ));
    bytes.addAll(generator.feed(1));
    
    bytes.addAll(generator.hr());
    
    // Informations
    bytes.addAll(generator.text(
      'Date: ${dateFormat.format(DateTime.now())}',
      styles: PosStyles(align: PosAlign.left),
    ));
    
    bytes.addAll(generator.text(
      'Imprimante: Test de connexion',
      styles: PosStyles(align: PosAlign.left),
    ));
    
    bytes.addAll(generator.feed(2));
    
    // Lignes de test
    bytes.addAll(generator.text(
      'Ligne de test 1',
      styles: PosStyles(align: PosAlign.left),
    ));
    bytes.addAll(generator.text(
      'Ligne de test 2',
      styles: PosStyles(align: PosAlign.left, bold: true),
    ));
    bytes.addAll(generator.text(
      'Ligne de test 3',
      styles: PosStyles(align: PosAlign.left, fontType: PosFontType.fontB),
    ));
    
    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.hr());
    
    // Message de succès (sans emoji pour compatibilité ESC/POS)
    bytes.addAll(generator.text(
      'Impression OK',
      styles: PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
      ),
    ));
    
    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.text(
      'Merci de votre visite !',
      styles: PosStyles(align: PosAlign.center),
    ));

    bytes.addAll(generator.feed(1));
    await _addAppLogo(bytes, generator, paperWidth);
    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.cut());

    return Uint8List.fromList(bytes);
  }

  /// Génère la commande ESC/POS pour ouvrir le tiroir-caisse
  static Future<Uint8List> generateCashDrawerCommand() async {
    final profile = await _getProfile();
    final generator = Generator(PaperSize.mm80, profile);
    final List<int> bytes = [];

    bytes.addAll(generator.reset());
    bytes.addAll(generator.drawer());
    
    return Uint8List.fromList(bytes);
  }

  /// Formate un montant en DA (Dinar Algérien)
  static String _formatAmount(double amount) {
    return amount.toStringAsFixed(2).replaceAll('.', ',');
  }

  /// Formate la méthode de paiement
  static String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
      case 'cash_on_delivery':
        return 'Espèces';
      case 'card':
      case 'credit_card':
        return 'Carte bancaire';
      case 'mobile_payment':
        return 'Paiement mobile';
      default:
        return method;
    }
  }
}
