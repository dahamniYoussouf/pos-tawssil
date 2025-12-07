import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import 'package:provider/provider.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final DatabaseService _db = DatabaseService();
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stats = await _db.getOrdersStatistics();
      setState(() {
        _stats = stats;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncService = context.read<SyncService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques POS'),
        actions: [
          IconButton(
            onPressed: _loadStats,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(TawsilSpacing.md),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : Column(
                    children: [
                      _SyncStatusInline(syncService: syncService),
                      const SizedBox(height: TawsilSpacing.md),
                      Wrap(
                        spacing: TawsilSpacing.md,
                        runSpacing: TawsilSpacing.md,
                        children: [
                          _StatCard(
                            label: 'Commandes totales',
                            value: '${_stats['total_orders'] ?? 0}',
                            color: const Color(0xFF00A859),
                          ),
                          _StatCard(
                            label: 'CA synchronisé',
                            value: '${(_stats['total_revenue'] ?? 0).toStringAsFixed(0)} DA',
                            color: Colors.blue,
                          ),
                          _StatCard(
                            label: 'Commandes du jour',
                            value: '${_stats['today_orders'] ?? 0}',
                            color: Colors.orange,
                          ),
                          _StatCard(
                            label: 'Commandes non sync',
                            value: '${_stats['unsynced_orders'] ?? 0}',
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(TawsilSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TawsilTextStyles.bodySmall),
          const SizedBox(height: 6),
          Text(
            value,
            style: TawsilTextStyles.headingLarge.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncStatusInline extends StatelessWidget {
  final SyncService syncService;
  const _SyncStatusInline({required this.syncService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncStatus>(
      stream: syncService.statusStream,
      initialData: syncService.currentStatus(),
      builder: (context, snapshot) {
        final status = snapshot.data;
        if (status == null) return const SizedBox.shrink();
        final isOk = status.success;
        return Row(
          children: [
            Icon(
              isOk ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
              color: isOk ? const Color(0xFF00A859) : Colors.orange,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                status.message,
                style: TawsilTextStyles.bodySmall.copyWith(
                  color: isOk ? const Color(0xFF006636) : Colors.orange,
                ),
              ),
            ),
            TextButton(
              onPressed: () => syncService.syncAll(),
              child: const Text('Sync'),
            ),
          ],
        );
      },
    );
  }
}
