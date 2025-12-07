class OrderHistoryFilters {
  final List<String>? status;
  final String? orderType;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final double? minPrice;
  final double? maxPrice;
  final String? search;

  OrderHistoryFilters({
    this.status,
    this.orderType,
    this.dateFrom,
    this.dateTo,
    this.minPrice,
    this.maxPrice,
    this.search,
  });

  OrderHistoryFilters copyWith({
    List<String>? status,
    String? orderType,
    DateTime? dateFrom,
    DateTime? dateTo,
    double? minPrice,
    double? maxPrice,
    String? search,
  }) {
    return OrderHistoryFilters(
      status: status ?? this.status,
      orderType: orderType ?? this.orderType,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      search: search ?? this.search,
    );
  }

  Map<String, dynamic> toQueryParams() {
    return {
      if (status != null && status!.isNotEmpty) 'status': status,
      if (orderType != null && orderType!.isNotEmpty) 'order_type': orderType,
      if (dateFrom != null) 'date_from': _formatDate(dateFrom!),
      if (dateTo != null) 'date_to': _formatDate(dateTo!),
      if (minPrice != null) 'min_price': minPrice,
      if (maxPrice != null) 'max_price': maxPrice,
      if (search != null && search!.isNotEmpty) 'search': search,
    };
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool get hasFilters {
    return (status != null && status!.isNotEmpty) ||
        (orderType != null && orderType!.isNotEmpty) ||
        dateFrom != null ||
        dateTo != null ||
        minPrice != null ||
        maxPrice != null ||
        (search != null && search!.isNotEmpty);
  }

  OrderHistoryFilters clear() {
    return OrderHistoryFilters();
  }
}

