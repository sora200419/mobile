// lib/features/marketplace/screens/marketplace_add_item_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart'; // 用来生成随机ID
import '../controllers/marketplace_controller.dart';
import '../models/marketplace_item.dart';

class MarketplaceAddItemScreen extends StatefulWidget {
  const MarketplaceAddItemScreen({Key? key}) : super(key: key);

  @override
  State<MarketplaceAddItemScreen> createState() =>
      _MarketplaceAddItemScreenState();
}

class _MarketplaceAddItemScreenState extends State<MarketplaceAddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  String title = '';
  String description = '';
  double price = 0.0;
  String imageUrl = '';

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MarketplaceController>();

    return Scaffold(
      appBar: AppBar(title: const Text('发布商品')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: '商品标题'),
                onSaved: (value) => title = value ?? '',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '标题不能为空';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: '价格'),
                keyboardType: TextInputType.number,
                onSaved: (value) => price = double.tryParse(value ?? '0') ?? 0,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '价格不能为空';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: '商品描述'),
                onSaved: (value) => description = value ?? '',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '描述不能为空';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: '图片URL'),
                onSaved: (value) => imageUrl = value ?? '',
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    // 生成随机ID
                    final newItem = MarketplaceItem(
                      id: const Uuid().v4(),
                      title: title,
                      price: price,
                      description: description,
                      imageUrl:
                          imageUrl.isNotEmpty
                              ? imageUrl
                              : 'https://picsum.photos/200/300', // 没填就给个默认
                    );
                    controller.addItem(newItem);
                    Get.back(); // 返回列表
                  }
                },
                child: const Text('发布'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
