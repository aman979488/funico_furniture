// TODO: product.dart
import '../../core/constants/app_assets.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.image,
    this.rating = 0,
    this.soldCount = 0,
    this.description = '',
    this.colors = const [],
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final String image; // asset path ya network URL
  final double rating;
  final int soldCount;
  final String description;
  final List<int> colors; // Color value, jaise 0xFFA0624A

  /// Firestore document se Product banane ke liye.
  factory Product.fromMap(Map<String, dynamic> map, {String? id}) {
    return Product(
      id: id ?? (map['id'] as String? ?? ''),
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      image: map['image'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      soldCount: (map['soldCount'] as num?)?.toInt() ?? 0,
      description: map['description'] as String? ?? '',
      colors: List<int>.from(map['colors'] as List? ?? const []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'image': image,
      'rating': rating,
      'soldCount': soldCount,
      'description': description,
      'colors': colors,
    };
  }

  /// UI banate waqt dummy data (Firebase jodne se pehle).
  static const sampleProducts = <Product>[
    Product(
      id: '1',
      name: 'Mid Century Sofa',
      category: 'Sofa',
      price: 280.00,
      image: AppAssets.sofa,
      rating: 4.8,
      soldCount: 8374,
      description: 'Comfortable mid century style sofa for your living room.',
      colors: [0xFFA0624A, 0xFF7A9CC6, 0xFFB026FF],
    ),
    Product(
      id: '2',
      name: 'Modern Wingback',
      category: 'Chair',
      price: 140.00,
      image: AppAssets.chair,
      rating: 4.7,
      soldCount: 6120,
      description: 'Modern wingback chair with wooden frame.',
      colors: [0xFF808080, 0xFF7A9CC6, 0xFFFF9F1C],
    ),
    Product(
      id: '3',
      name: 'Mini Wooden Table',
      category: 'Table',
      price: 64.00,
      image: AppAssets.table,
      rating: 4.6,
      soldCount: 4210,
      description: 'Small handcrafted wooden table.',
      colors: [0xFFA0624A, 0xFF0FB5A6],
    ),
    Product(
      id: '4',
      name: 'Parabolic Reflector',
      category: 'Lamp',
      price: 70.00,
      image: AppAssets.lamp,
      rating: 4.9,
      soldCount: 3920,
      description: 'Copper finish pendant lamp.',
      colors: [0xFFA0624A, 0xFFB026FF, 0xFF808080],
    ),
  ];
}