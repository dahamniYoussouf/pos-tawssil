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
    final activeAnnouncementsWithImage =
        activeAnnouncements.where((a) => a.image != null).toList();
    if (activeAnnouncementsWithImage.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 180,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: activeAnnouncements.length,
        itemBuilder: (context, index) {
          if (activeAnnouncements[index].image == null) {
            return SizedBox.shrink();
          }
          return SizedBox(
            width: _getCardWidth(),
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 165,
                  width: double.infinity,
                  child: Image.network(
                    activeAnnouncements[index].image!,
                    width: double.infinity,
                    height: 165,
                    fit: BoxFit.fill,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: ColorApp.primary,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 48,
                            color: ColorApp.primary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
