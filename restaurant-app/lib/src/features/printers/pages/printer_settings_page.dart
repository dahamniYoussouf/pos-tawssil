import 'package:flutter/material.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';
import '../models/restaurant_printer.dart';
import '../services/local_printer_scanner.dart';
import '../services/local_print_service.dart';
import '../services/printer_api_service.dart';
import '../services/print_service.dart';

class PrinterSettingsPage extends StatefulWidget {
  const PrinterSettingsPage({super.key});

  @override
  State<PrinterSettingsPage> createState() => _PrinterSettingsPageState();
}

class _PrinterSettingsPageState extends State<PrinterSettingsPage> {
  final PrinterApiService _printerApi = PrinterApiService();
  final PrintService _printService = PrintService();

  List<RestaurantPrinter> _printers = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadPrinters();
  }

  Future<void> _loadPrinters() async {
    setState(() {
      _loading = true;
    });
    try {
      final printers = await _printerApi.fetchPrinters();
      if (!mounted) return;
      setState(() {
        _printers = printers;
      });
    } catch (e) {
      _showError(_errorMessage(e));
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _createPrinter({
    required String name,
    required String type,
    required String ip,
    required int port,
    required bool isEnabled,
    required int paperWidthMm,
  }) async {
    try {
      await _printerApi.createPrinter(
        name: name,
        type: type,
        ip: ip,
        port: port,
        isEnabled: isEnabled,
        paperWidthMm: paperWidthMm,
      );
      await _loadPrinters();
    } catch (e) {
      _showError(_errorMessage(e));
    }
  }

  Future<void> _updatePrinter(RestaurantPrinter printer) async {
    try {
      await _printerApi.updatePrinter(
        printerId: printer.id,
        name: printer.name,
        type: printer.type,
        ip: printer.ip,
        port: printer.port,
        isEnabled: printer.isEnabled,
        paperWidthMm: printer.paperWidthMm,
      );
      await _loadPrinters();
    } catch (e) {
      _showError(_errorMessage(e));
    }
  }

  Future<void> _deletePrinter(RestaurantPrinter printer) async {
    try {
      await _printerApi.deletePrinter(printer.id);
      await _loadPrinters();
    } catch (e) {
      _showError(_errorMessage(e));
    }
  }

  Future<void> _scanNetwork() async {
    setState(() {
      _loading = true;
    });
    final results = await LocalPrinterScanner.quickScan();
    setState(() {
      _loading = false;
    });
    if (!mounted) return;
    _showDetectedPrinters(results);
  }

  Future<void> _testSpecificIp() async {
    final controller = TextEditingController();
    final ip = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Test IP'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Printer IP',
              hintText: '192.168.1.10',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Test'),
            ),
          ],
        );
      },
    );
    if (ip == null || ip.isEmpty) return;

    setState(() {
      _loading = true;
    });
    final results = await LocalPrinterScanner.testSpecificIP(ip);
    setState(() {
      _loading = false;
    });
    if (!mounted) return;
    _showDetectedPrinters(results);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _errorMessage(Object error) {
    final text = error.toString();
    if (text.startsWith('Exception: ')) {
      return text.substring('Exception: '.length);
    }
    return text;
  }

  void _showDetectedPrinters(List<Map<String, dynamic>> results) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        if (results.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No printers found.'),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final item = results[index];
            final ip = item['ip']?.toString() ?? '';
            final port = item['port']?.toString() ?? '9100';
            return ListTile(
              title: Text('$ip:$port'),
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _openPrinterDialog(
                    presetIp: ip,
                    presetPort: int.tryParse(port) ?? 9100,
                  );
                },
                child: const Text('Add'),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openPrinterDialog({
    RestaurantPrinter? printer,
    String? presetIp,
    int? presetPort,
  }) async {
    final isEdit = printer != null;
    final nameController = TextEditingController(text: printer?.name ?? '');
    final ipController = TextEditingController(
      text: presetIp ?? printer?.ip ?? '',
    );
    final portController = TextEditingController(
      text: (presetPort ?? printer?.port ?? 9100).toString(),
    );

    String typeValue = printer?.type ?? 'general';
    int paperWidth = printer?.paperWidthMm ?? 80;
    bool isEnabled = printer?.isEnabled ?? true;

    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Printer' : 'Add Printer'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: ipController,
                        decoration: const InputDecoration(labelText: 'IP Address'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'IP is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: portController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Port'),
                        validator: (value) {
                          final parsed = int.tryParse(value ?? '');
                          if (parsed == null || parsed <= 0) {
                            return 'Invalid port';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: typeValue,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: const [
                          DropdownMenuItem(value: 'general', child: Text('General')),
                          DropdownMenuItem(value: 'caisse', child: Text('Cash')),
                          DropdownMenuItem(value: 'cuisine', child: Text('Kitchen')),
                          DropdownMenuItem(value: 'bar', child: Text('Bar')),
                        ],
                        onChanged: (value) {
                          setModalState(() {
                            typeValue = value ?? 'general';
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: paperWidth,
                        decoration: const InputDecoration(labelText: 'Paper Width'),
                        items: const [
                          DropdownMenuItem(value: 58, child: Text('58 mm')),
                          DropdownMenuItem(value: 80, child: Text('80 mm')),
                        ],
                        onChanged: (value) {
                          setModalState(() {
                            paperWidth = value ?? 80;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Enabled'),
                        value: isEnabled,
                        onChanged: (value) {
                          setModalState(() {
                            isEnabled = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final name = nameController.text.trim();
                    final ip = ipController.text.trim();
                    final port = int.parse(portController.text.trim());
                    if (isEdit && printer != null) {
                      final updated = printer.copyWith(
                        name: name,
                        type: typeValue,
                        ip: ip,
                        port: port,
                        isEnabled: isEnabled,
                        paperWidthMm: paperWidth,
                      );
                      await _updatePrinter(updated);
                    } else {
                      await _createPrinter(
                        name: name,
                        type: typeValue,
                        ip: ip,
                        port: port,
                        isEnabled: isEnabled,
                        paperWidthMm: paperWidth,
                      );
                    }
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _testPrinter(RestaurantPrinter printer) async {
    try {
      final isReachable = await LocalPrintService.isPrinterAccessible(printer);
      if (!isReachable) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Printer not reachable.')),
        );
        return;
      }
      await _printService.printTestTicket(printer);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test ticket sent.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Print failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPage,
      appBar: AppBar(
        title: const Text('Printer Settings'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryColor,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'add':
                  _openPrinterDialog();
                  break;
                case 'scan':
                  _scanNetwork();
                  break;
                case 'test_ip':
                  _testSpecificIp();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'add', child: Text('Add Printer')),
              PopupMenuItem(value: 'scan', child: Text('Scan Network')),
              PopupMenuItem(value: 'test_ip', child: Text('Test IP')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _printers.isEmpty
              ? const Center(child: Text('No printers configured.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _printers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final printer = _printers[index];
                    return Card(
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.print),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    printer.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (!printer.isEnabled)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('Disabled'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('IP: ${printer.ip}:${printer.port}'),
                            Text('Type: ${printer.type}'),
                            Text('Paper: ${printer.paperWidthMm}mm'),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  onPressed: () => _testPrinter(printer),
                                  icon: const Icon(Icons.print),
                                  tooltip: 'Test print',
                                ),
                                IconButton(
                                  onPressed: () => _openPrinterDialog(
                                    printer: printer,
                                  ),
                                  icon: const Icon(Icons.edit),
                                  tooltip: 'Edit',
                                ),
                                IconButton(
                                  onPressed: () => _deletePrinter(printer),
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: 'Delete',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
