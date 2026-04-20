import 'dart:convert';

import 'package:http/http.dart' as http;

class OpenFoodFactsProduct {
  const OpenFoodFactsProduct({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imageUrl,
    this.barcode,
    this.brand,
    this.quantity,
  });

  final String title;
  final String subtitle;
  final String description;
  final String? imageUrl;
  final String? barcode;
  final String? brand;
  final String? quantity;
}

class OpenFoodFactsService {
  Future<OpenFoodFactsProduct?> fetchProductByBarcode(String barcode) async {
    final normalizedBarcode = barcode.trim();
    if (normalizedBarcode.isEmpty) {
      return null;
    }

    final uri = Uri.https(
      'world.openfoodfacts.org',
      '/api/v2/product/$normalizedBarcode.json',
      <String, String>{
        'fields': 'product_name,brands,quantity,generic_name,image_front_small_url,code',
      },
    );

    final response = await http.get(
      uri,
      headers: const {
        'User-Agent': 'smart_inventory_and_expiry_tracker/1.0',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('OpenFoodFacts request failed with status ${response.statusCode}.');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final status = decoded['status'];
    if (status is int && status != 1) {
      return null;
    }

    final product = decoded['product'];
    if (product is! Map<String, dynamic>) {
      return null;
    }

    return _mapProduct(product);
  }

  Future<List<OpenFoodFactsProduct>> fetchFeaturedProducts() async {
    final uri = Uri.https(
      'world.openfoodfacts.org',
      '/api/v2/search',
      <String, String>{
        'page_size': '3',
        'sort_by': 'popularity',
        'fields': 'product_name,brands,quantity,generic_name,image_front_small_url,code',
      },
    );

    final response = await http.get(
      uri,
      headers: const {
        'User-Agent': 'smart_inventory_and_expiry_tracker/1.0',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('OpenFoodFacts request failed with status ${response.statusCode}.');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final products = decoded['products'];

    if (products is! List) {
      return const <OpenFoodFactsProduct>[];
    }

    return products
        .whereType<Map<String, dynamic>>()
        .map(_mapProduct)
        .where((product) => product.title.isNotEmpty)
        .toList(growable: false);
  }

  OpenFoodFactsProduct _mapProduct(Map<String, dynamic> json) {
    final title = _firstNonEmpty([
      json['product_name'] as String?,
      json['generic_name'] as String?,
      json['brands'] as String?,
      'OpenFoodFacts product',
    ]);

    final brands = (json['brands'] as String?)?.trim();
    final quantity = (json['quantity'] as String?)?.trim();
    final subtitleParts = <String>[];

    if (brands != null && brands.isNotEmpty) {
      subtitleParts.add(brands);
    }
    if (quantity != null && quantity.isNotEmpty) {
      subtitleParts.add(quantity);
    }

    final subtitle = subtitleParts.isEmpty ? 'Fetched from OpenFoodFacts' : subtitleParts.join(' • ');
    final description = _firstNonEmpty([
      json['generic_name'] as String?,
      brands,
      quantity,
      'Product data provided by OpenFoodFacts.',
    ]);

    return OpenFoodFactsProduct(
      title: title,
      subtitle: subtitle,
      description: description,
      imageUrl: json['image_front_small_url'] as String?,
      barcode: (json['code'] as String?)?.trim(),
      brand: brands,
      quantity: quantity,
    );
  }

  String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final candidate = value?.trim();
      if (candidate != null && candidate.isNotEmpty) {
        return candidate;
      }
    }
    return '';
  }
}