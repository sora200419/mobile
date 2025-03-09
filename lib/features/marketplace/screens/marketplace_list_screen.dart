// lib/features/marketplace/screens/marketplace_list_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/marketplace_controller.dart';
import '../models/marketplace_item.dart';
import 'marketplace_detail_screen.dart';
import 'marketplace_add_item_screen.dart';

class MarketplaceListScreen extends StatelessWidget {
  MarketplaceListScreen({Key? key}) : super(key: key);

  // 初始化控制器
  final MarketplaceController marketplaceController = Get.put(
    MarketplaceController(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('校园二手市场')),
      body: Obx(() {
        // 监听 items 的变化
        final items = marketplaceController.items;
        if (items.isEmpty) {
          return const Center(child: Text('暂无商品'));
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final MarketplaceItem item = items[index];
            return ListTile(
              leading: Image.network(
                item.imageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
              title: Text(item.title),
              subtitle: Text('￥${item.price.toStringAsFixed(2)}'),
              onTap: () {
                // 跳转到详情页
                Get.to(() => MarketplaceDetailScreen(itemId: item.id));
              },
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 跳转到添加商品页面
          Get.to(() => MarketplaceAddItemScreen());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
