class MarketplaceItem {
  final String id;
  final String title;
  final double price;
  final String description;
  final String imageUrl; // 如果有商品图片

  MarketplaceItem({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.imageUrl,
  });

  // 如果你要从 JSON 解析，可以加个 factory
  factory MarketplaceItem.fromJson(Map<String, dynamic> json) {
    return MarketplaceItem(
      id: json['id'] as String,
      title: json['title'] as String,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
    );
  }

  // 转 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'description': description,
      'imageUrl': imageUrl,
    };
  }
}
