class ServiceModel {
  final String id;
  final String walkerId;
  String type;
  double price;           // Para paseo (x hora) y cuidado (x día)
  double? priceSmall;    // Baño: precio perro pequeño
  double? priceMedium;   // Baño: precio perro mediano
  double? priceLarge;    // Baño: precio perro grande
  String? description;
  String? imageUrl;
  bool isActive;
  final DateTime createdAt;
  DateTime updatedAt;

  ServiceModel({
    required this.id,
    required this.walkerId,
    required this.type,
    required this.price,
    this.priceSmall,
    this.priceMedium,
    this.priceLarge,
    this.description,
    this.imageUrl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id'] as String,
      walkerId: map['walker_id'] as String,
      type: map['type'] as String,
      price: (map['price'] as num? ?? 0).toDouble(),
      priceSmall: map['price_small'] != null
          ? (map['price_small'] as num).toDouble()
          : null,
      priceMedium: map['price_medium'] != null
          ? (map['price_medium'] as num).toDouble()
          : null,
      priceLarge: map['price_large'] != null
          ? (map['price_large'] as num).toDouble()
          : null,
      description: map['description'] as String?,
      imageUrl: map['image_url'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'walker_id': walkerId,
      'type': type,
      'price': price,
      'price_small': priceSmall,
      'price_medium': priceMedium,
      'price_large': priceLarge,
      'description': description,
      'image_url': imageUrl,
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  String get typeLabel {
    switch (type) {
      case 'paseo':
        return 'Paseo';
      case 'cuidado':
        return 'Cuidado';
      case 'baño':
        return 'Baño';
      default:
        return type;
    }
  }

  String get typeEmoji {
    switch (type) {
      case 'paseo':
        return '🦮';
      case 'cuidado':
        return '🏠';
      case 'baño':
        return '🛁';
      default:
        return '🐾';
    }
  }

  // Unidad de cobro según tipo
  String get priceUnit {
    switch (type) {
      case 'paseo':
        return 'hora';
      case 'cuidado':
        return 'día';
      case 'baño':
        return 'según tamaño';
      default:
        return '';
    }
  }

  // Resumen de precio para mostrar en UI
  String get priceSummary {
    switch (type) {
      case 'paseo':
        return '\$${price.toStringAsFixed(0)} COP/hora';
      case 'cuidado':
        return '\$${price.toStringAsFixed(0)} COP/día';
      case 'baño':
        final parts = <String>[];
        if (priceSmall != null) parts.add('Pequeño: \$${priceSmall!.toStringAsFixed(0)}');
        if (priceMedium != null) parts.add('Mediano: \$${priceMedium!.toStringAsFixed(0)}');
        if (priceLarge != null) parts.add('Grande: \$${priceLarge!.toStringAsFixed(0)}');
        return parts.isEmpty ? 'Sin precio definido' : parts.join(' · ');
      default:
        return '\$${price.toStringAsFixed(0)} COP';
    }
  }

  // Precio para una mascota según su tamaño (para baño)
  double? priceForSize(String size) {
    switch (size) {
      case 'pequeño':
        return priceSmall;
      case 'mediano':
        return priceMedium;
      case 'grande':
        return priceLarge;
      default:
        return null;
    }
  }
}
