class Address {
  final String id;
  final String name; // e.g. "Home", "Office", "Apartment"
  final String details; // street address / building
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final bool isDefault;
  final String? phoneNumber;

  const Address({
    required this.id,
    required this.name,
    required this.details,
    this.city = '',
    this.state = '',
    this.postalCode = '',
    this.country = 'India',
    this.isDefault = false,
    this.phoneNumber,
  });

  String get fullAddress {
    final parts = [
      details,
      city,
      state,
      postalCode,
      country,
    ].where((s) => s.trim().isNotEmpty).toList();
    return parts.join(', ');
  }

  factory Address.fromMap(Map<String, dynamic> map, {String id = ''}) {
    return Address(
      id: (map['id'] as String?) ?? id,
      name: (map['name'] as String?) ?? 'Home',
      details: (map['details'] as String?) ?? '',
      city: (map['city'] as String?) ?? '',
      state: (map['state'] as String?) ?? '',
      postalCode: (map['postalCode'] as String?) ?? '',
      country: (map['country'] as String?) ?? 'India',
      isDefault: (map['isDefault'] as bool?) ?? false,
      phoneNumber: map['phoneNumber'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'details': details,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
      'isDefault': isDefault,
      'phoneNumber': phoneNumber,
    };
  }

  Address copyWith({
    String? id,
    String? name,
    String? details,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    bool? isDefault,
    String? phoneNumber,
  }) {
    return Address(
      id: id ?? this.id,
      name: name ?? this.name,
      details: details ?? this.details,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      isDefault: isDefault ?? this.isDefault,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}
