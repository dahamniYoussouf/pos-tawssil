import 'dart:typed_data';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:restaurant_app/src/features/orders/models/order_model.dart';

class TicketGenerator {
  static CapabilityProfile? _profile;
  static img.Image? _logoImage;
  static img.Image? _logoMono58;
  static img.Image? _logoMono80;

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
      final data = await rootBundle.load('assets/images/logo.png');
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

        final alpha = a / 255.0;
        final rr = (255 + (r - 255) * alpha).round();
        final gg = (255 + (g - 255) * alpha).round();
        final bb = (255 + (b - 255) * alpha).round();

        final luma = (0.299 * rr + 0.587 * gg + 0.114 * bb).round();
        final isBlack = luma < 200;
        image.setPixelRgba(
          x,
          y,
          isBlack ? 0 : 255,
          isBlack ? 0 : 255,
          isBlack ? 0 : 255,
          255,
        );
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

  static Future<Uint8List> generateTicket({
    required OrderModel order,
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
      'Order #${order.orderNumber}',
      styles: PosStyles(align: PosAlign.left),
    ));

    final createdAt = order.createdAt ?? DateTime.now();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    bytes.addAll(generator.text(
      'Date: ${dateFormat.format(createdAt)}',
      styles: PosStyles(align: PosAlign.left),
    ));

    if ((order.orderType ?? '').isNotEmpty) {
      bytes.addAll(generator.text(
        'Type: ${order.orderType}',
        styles: PosStyles(align: PosAlign.left),
      ));
    }

    bytes.addAll(generator.hr());

    for (final item in order.items) {
      bytes.addAll(generator.text(
        '${item.name} x${item.quantity}',
        styles: PosStyles(align: PosAlign.left, bold: true),
      ));

      bytes.addAll(generator.text(
        '  ${_formatAmount(item.totalPrice)} DA',
        styles: PosStyles(align: PosAlign.left),
      ));

      if (item.specialInstructions != null &&
          item.specialInstructions!.trim().isNotEmpty) {
        bytes.addAll(generator.text(
          '  Note: ${item.specialInstructions}',
          styles: PosStyles(align: PosAlign.left, fontType: PosFontType.fontB),
        ));
      }

      bytes.addAll(generator.feed(1));
    }

    bytes.addAll(generator.hr());

    final subtotal = order.items.fold<double>(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );

    bytes.addAll(generator.text(
      'Subtotal: ${_formatAmount(subtotal)} DA',
      styles: PosStyles(align: PosAlign.left),
    ));

    final deliveryFee = order.deliveryPrice ??
        (order.totalPrice > subtotal ? order.totalPrice - subtotal : 0.0);
    if (deliveryFee > 0) {
      bytes.addAll(generator.text(
        'Delivery: ${_formatAmount(deliveryFee)} DA',
        styles: PosStyles(align: PosAlign.left),
      ));
    }

    bytes.addAll(generator.text(
      'TOTAL: ${_formatAmount(order.totalPrice)} DA',
      styles: PosStyles(
        align: PosAlign.left,
        bold: true,
        height: PosTextSize.size2,
      ),
    ));

    if ((order.paymentMethod ?? '').isNotEmpty) {
      bytes.addAll(generator.feed(1));
      bytes.addAll(generator.text(
        'Payment: ${_formatPaymentMethod(order.paymentMethod!)}',
        styles: PosStyles(align: PosAlign.left),
      ));
    }

    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.text(
      'Thank you!',
      styles: PosStyles(align: PosAlign.center),
    ));

    bytes.addAll(generator.feed(1));
    await _addAppLogo(bytes, generator, paperWidth);
    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.cut());

    return Uint8List.fromList(bytes);
  }

  static Future<Uint8List> generateTestTicket({
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
      'TEST TICKET',
      styles: PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
      ),
    ));
    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.hr());

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    bytes.addAll(generator.text(
      'Date: ${dateFormat.format(DateTime.now())}',
      styles: PosStyles(align: PosAlign.left),
    ));

    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.text(
      'Print OK',
      styles: PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
      ),
    ));

    bytes.addAll(generator.feed(1));
    await _addAppLogo(bytes, generator, paperWidth);
    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.cut());

    return Uint8List.fromList(bytes);
  }

  static String _formatAmount(double amount) {
    return amount.toStringAsFixed(2).replaceAll('.', ',');
  }

  static String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
      case 'cash_on_delivery':
        return 'Cash';
      case 'card':
      case 'credit_card':
        return 'Card';
      case 'mobile_payment':
        return 'Mobile';
      default:
        return method;
    }
  }
}
