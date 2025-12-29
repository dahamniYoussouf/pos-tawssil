import 'dart:async';
import 'package:client_app/src/features/restaurant/models/homepage_models.dart';
import 'package:flutter/material.dart';
import 'package:client_app/src/core/res/color_app.dart';

class AnnouncementsWidget extends StatefulWidget {
  final List<AnnouncementModel> announcements;

  const AnnouncementsWidget({
    Key? key,
    required this.announcements,
  }) : super(key: key);

  @override
  State<AnnouncementsWidget> createState() => _AnnouncementsWidgetState();
}

class _AnnouncementsWidgetState extends State<AnnouncementsWidget> {
  late ScrollController _scrollController;
  Timer? _autoScrollTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    final activeAnnouncements = _getActiveAnnouncements();
    if (activeAnnouncements.length <= 1) return;
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_scrollController.hasClients || !mounted) return;
      final cardWidth = _getCardWidth();
      if (cardWidth <= 0) return;
      _currentIndex = (_currentIndex + 1) % activeAnnouncements.length;
      _scrollController.animateTo(
        _currentIndex * cardWidth,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  double _getCardWidth() {
    if (!mounted) return 0;
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth - 40;
  }

  List<AnnouncementModel> _getActiveAnnouncements() {
    return widget.announcements
        .where((a) =>
            a.isActive &&
            DateTime.now().isAfter(a.startDate) &&
            DateTime.now().isBefore(a.endDate))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.announcements.isEmpty) return const SizedBox.shrink();
    final activeAnnouncements = _getActiveAnnouncements();
    if (activeAnnouncements.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 165,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: activeAnnouncements.length,
        itemBuilder: (context, index) {
          return SizedBox(
            width: _getCardWidth(),
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _AnnouncementCard(
                announcement: activeAnnouncements[index],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final AnnouncementModel announcement;

  const _AnnouncementCard({
    Key? key,
    required this.announcement,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getBackgroundColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBorderColor(context),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            announcement.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getTextColor(context),
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (announcement.content != null) ...[
            const SizedBox(height: 8),
            Text(
              announcement.content!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _getTextColor(context),
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Color _getBackgroundColor(BuildContext context) {
    switch (announcement.type) {
      case 'error':
        return ColorApp.redColor.withOpacity(0.1);
      case 'warning':
        return Colors.orange.withOpacity(0.1);
      case 'success':
        return ColorApp.primary.withOpacity(0.1);
      default:
        return ColorApp.primary.withOpacity(0.1);
    }
  }

  Color _getBorderColor(BuildContext context) {
    switch (announcement.type) {
      case 'error':
        return ColorApp.redColor;
      case 'warning':
        return Colors.orange;
      case 'success':
        return ColorApp.primary;
      default:
        return ColorApp.primary;
    }
  }

  Color _getTextColor(BuildContext context) {
    switch (announcement.type) {
      case 'error':
        return ColorApp.redColor;
      case 'warning':
        return Colors.orange.shade800;
      case 'success':
        return ColorApp.primary;
      default:
        return ColorApp.textBlack;
    }
  }
}
