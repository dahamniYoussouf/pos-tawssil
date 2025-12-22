import 'package:client_app/src/core/res/color_app.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:client_app/l10n/app_localizations.dart';
import '../services/autocomplete_service.dart';

class AutocompleteDropdown extends StatefulWidget {
  final TextEditingController controller;
  final Function(String)? onSuggestionSelected;

  const AutocompleteDropdown({
    Key? key,
    required this.controller,
    this.onSuggestionSelected,
  }) : super(key: key);

  @override
  State<AutocompleteDropdown> createState() => _AutocompleteDropdownState();
}

class _AutocompleteDropdownState extends State<AutocompleteDropdown> {
  // Constants
  static const _primaryColor = ColorApp.primary;
  static const _debounceDelay = Duration(milliseconds: 300);
  static const _minQueryLength = 2;
  static const _maxSuggestions = 8;
  static const _overlayOffset = 8.0;
  static const _maxOverlayHeight = 320.0;

  // State
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  final AutocompleteService _autocompleteService = AutocompleteService();

  OverlayEntry? _overlayEntry;
  Timer? _debounceTimer;

  List<String> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _removeOverlay();
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final query = widget.controller.text.trim();

    _debounceTimer?.cancel();

    if (query.length < _minQueryLength) {
      _hideSuggestions();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _debounceTimer = Timer(_debounceDelay, () {
      _fetchSuggestions(query);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    try {
      final suggestions =
          await _autocompleteService.getRestaurantSuggestions(query);

      if (!mounted) return;

      setState(() {
        _suggestions = suggestions.take(_maxSuggestions).toList();
        _isLoading = false;
        _showSuggestions = _suggestions.isNotEmpty && _focusNode.hasFocus;
      });

      _updateOverlay();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _suggestions = [];
        _isLoading = false;
        _showSuggestions = false;
      });
      _removeOverlay();
    }
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus && _suggestions.isNotEmpty) {
      setState(() {
        _showSuggestions = true;
      });
      _updateOverlay();
    } else {
      // Delay hiding to allow tap events to register
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_focusNode.hasFocus) {
          _hideSuggestions();
        }
      });
    }
  }

  void _hideSuggestions() {
    setState(() {
      _showSuggestions = false;
    });
    _removeOverlay();
  }

  void _updateOverlay() {
    _removeOverlay();

    if (_showSuggestions && _suggestions.isNotEmpty && _focusNode.hasFocus) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + _overlayOffset),
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: _maxOverlayHeight,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    thickness: 0.5,
                    indent: 56,
                    endIndent: 16,
                    color: Colors.grey.shade200,
                  ),
                  itemBuilder: (context, index) =>
                      _buildSuggestionItem(_suggestions[index]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionItem(String suggestion) {
    final query = widget.controller.text.trim().toLowerCase();

    return InkWell(
      onTap: () {
        widget.controller.text = suggestion;
        widget.controller.selection = TextSelection.fromPosition(
          TextPosition(offset: suggestion.length),
        );
        _focusNode.unfocus();
        _hideSuggestions();

        if (widget.onSuggestionSelected != null) {
          widget.onSuggestionSelected!(suggestion);
        }
      },
      splashColor: _primaryColor.withOpacity(0.1),
      highlightColor: _primaryColor.withOpacity(0.05),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.restaurant,
                color: Colors.grey.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: RichText(
                text: _buildHighlightedText(suggestion, query),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  TextSpan _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return _buildTextSpan(text, isHighlighted: false);
    }

    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    int start = 0;
    int index = lowerText.indexOf(lowerQuery);

    while (index != -1) {
      if (index > start) {
        spans.add(
            _buildTextSpan(text.substring(start, index), isHighlighted: false));
      }

      spans.add(_buildTextSpan(
        text.substring(index, index + query.length),
        isHighlighted: true,
      ));

      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }

    if (start < text.length) {
      spans.add(_buildTextSpan(text.substring(start), isHighlighted: false));
    }

    return TextSpan(children: spans);
  }

  TextSpan _buildTextSpan(String text, {required bool isHighlighted}) {
    return TextSpan(
      text: text,
      style: TextStyle(
        fontSize: 15,
        color: isHighlighted ? _primaryColor : Colors.black87,
        fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
      ),
    );
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final hasFocus = _focusNode.hasFocus;
    final hasText = widget.controller.text.isNotEmpty;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFocus ? _primaryColor : Colors.grey.shade300,
            width: hasFocus ? 2 : 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: hasFocus ? _primaryColor : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: localizations.searchRestaurantPlaceholder,
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
            if (_isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(_primaryColor),
                ),
              )
            else if (hasText)
              GestureDetector(
                onTap: () {
                  widget.controller.clear();
                  _hideSuggestions();
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.grey.shade700,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
