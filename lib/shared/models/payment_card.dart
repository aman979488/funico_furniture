class PaymentCard {
  final String id;
  final String cardHolderName;
  final String cardNumber;
  final String expiryDate; // MM/YY
  final String cvv;
  final String
  cardType; // 'mastercard', 'visa', 'paypal', 'apple_pay', 'google_pay', 'cod'
  final bool isDefault;

  const PaymentCard({
    required this.id,
    required this.cardHolderName,
    required this.cardNumber,
    required this.expiryDate,
    this.cvv = '',
    this.cardType = 'mastercard',
    this.isDefault = false,
  });

  String get maskedNumber {
    final clean = cardNumber.replaceAll(' ', '');
    if (clean.length < 4) return cardNumber;
    return '•••• •••• •••• ${clean.substring(clean.length - 4)}';
  }

  factory PaymentCard.fromMap(Map<String, dynamic> map, {String id = ''}) {
    return PaymentCard(
      id: (map['id'] as String?) ?? id,
      cardHolderName: (map['cardHolderName'] as String?) ?? '',
      cardNumber: (map['cardNumber'] as String?) ?? '',
      expiryDate: (map['expiryDate'] as String?) ?? '',
      cvv: (map['cvv'] as String?) ?? '',
      cardType: (map['cardType'] as String?) ?? 'mastercard',
      isDefault: (map['isDefault'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cardHolderName': cardHolderName,
      'cardNumber': cardNumber,
      'expiryDate': expiryDate,
      'cvv': cvv,
      'cardType': cardType,
      'isDefault': isDefault,
    };
  }

  PaymentCard copyWith({
    String? id,
    String? cardHolderName,
    String? cardNumber,
    String? expiryDate,
    String? cvv,
    String? cardType,
    bool? isDefault,
  }) {
    return PaymentCard(
      id: id ?? this.id,
      cardHolderName: cardHolderName ?? this.cardHolderName,
      cardNumber: cardNumber ?? this.cardNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      cvv: cvv ?? this.cvv,
      cardType: cardType ?? this.cardType,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
