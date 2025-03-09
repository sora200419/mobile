// lib/features/marketplace/screens/marketplace_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/marketplace_controller.dart';

class MarketplaceDetailScreen extends StatelessWidget {
  final String itemId;

  const MarketplaceDetailScreen({Key? key, required this.itemId})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MarketplaceController>();
    final item = controller.getItemById(itemId);

    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('商品详情')),
        body: const Center(child: Text('商品不存在')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(item.title)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.network(item.imageUrl, fit: BoxFit.cover),
            const SizedBox(height: 16),
            Text(
              item.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              '￥${item.price.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, color: Colors.red),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(item.description),
            ),
            // TODO: 这里可以加按钮，比如「联系卖家」、「加入购物车」等
          ],
        ),
      ),
    );
  }
}
