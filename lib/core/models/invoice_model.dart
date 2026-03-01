// lib/core/models/invoice_model.dart

enum InvoiceStatus { draft, sent, paid, overdue, cancelled }

class InvoiceItemModel {
  final String description;
  final int quantity;
  final double unitPrice;

  InvoiceItemModel({
    required this.description,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;

  factory InvoiceItemModel.fromMap(Map<String, dynamic> map) {
    return InvoiceItemModel(
      description: map['description'] ?? '',
      quantity: map['quantity'] ?? 1,
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'description': description,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'total': total,
      };
}

class InvoiceModel {
  final String id;
  final String businessId;
  final String invoiceNumber;
  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final String? bookingId;
  final List<InvoiceItemModel> items;
  final double subtotal;
  final double taxRate;       // e.g. 0.08 = 8%
  final double taxAmount;
  final double total;
  final InvoiceStatus status;
  final String? stripePaymentId;
  final String? notes;
  final DateTime date;
  final DateTime? dueDate;
  final DateTime? paidAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  InvoiceModel({
    required this.id,
    required this.businessId,
    required this.invoiceNumber,
    required this.customerName,
    required this.customerPhone,
    this.customerEmail,
    this.bookingId,
    required this.items,
    required this.subtotal,
    required this.taxRate,
    required this.taxAmount,
    required this.total,
    this.status = InvoiceStatus.draft,
    this.stripePaymentId,
    this.notes,
    required this.date,
    this.dueDate,
    this.paidAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory InvoiceModel.fromMap(Map<String, dynamic> map, String id) {
    final itemsList = (map['items'] as List<dynamic>? ?? [])
        .map((i) => InvoiceItemModel.fromMap(Map<String, dynamic>.from(i)))
        .toList();

    return InvoiceModel(
      id: id,
      businessId: map['businessId'] ?? '',
      invoiceNumber: map['invoiceNumber'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      customerEmail: map['customerEmail'],
      bookingId: map['bookingId'],
      items: itemsList,
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      taxRate: (map['taxRate'] ?? 0).toDouble(),
      taxAmount: (map['taxAmount'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      status: InvoiceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => InvoiceStatus.draft,
      ),
      stripePaymentId: map['stripePaymentId'],
      notes: map['notes'],
      date: DateTime.parse(map['date']),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      paidAt: map['paidAt'] != null ? DateTime.parse(map['paidAt']) : null,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'businessId': businessId,
        'invoiceNumber': invoiceNumber,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerEmail': customerEmail,
        'bookingId': bookingId,
        'items': items.map((i) => i.toMap()).toList(),
        'subtotal': subtotal,
        'taxRate': taxRate,
        'taxAmount': taxAmount,
        'total': total,
        'status': status.name,
        'stripePaymentId': stripePaymentId,
        'notes': notes,
        'date': date.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'paidAt': paidAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  // ── Helpers ──
  String get formattedTotal => '\$${total.toStringAsFixed(2)}';
  String get formattedSubtotal => '\$${subtotal.toStringAsFixed(2)}';
  String get formattedTax => '\$${taxAmount.toStringAsFixed(2)}';

  String get statusLabel {
    switch (status) {
      case InvoiceStatus.draft:     return 'Draft';
      case InvoiceStatus.sent:      return 'Sent';
      case InvoiceStatus.paid:      return 'Paid';
      case InvoiceStatus.overdue:   return 'Overdue';
      case InvoiceStatus.cancelled: return 'Cancelled';
    }
  }

  String get formattedDate {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  InvoiceModel copyWith({
    InvoiceStatus? status,
    String? stripePaymentId,
    DateTime? paidAt,
    DateTime? updatedAt,
  }) {
    return InvoiceModel(
      id: id,
      businessId: businessId,
      invoiceNumber: invoiceNumber,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      bookingId: bookingId,
      items: items,
      subtotal: subtotal,
      taxRate: taxRate,
      taxAmount: taxAmount,
      total: total,
      status: status ?? this.status,
      stripePaymentId: stripePaymentId ?? this.stripePaymentId,
      notes: notes,
      date: date,
      dueDate: dueDate,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}