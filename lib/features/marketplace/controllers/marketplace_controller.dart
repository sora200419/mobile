import 'package:get/get.dart';
import '../models/marketplace_item.dart';

class MarketplaceController extends GetxController {
  // 用 RxList 来存放商品列表
  var items = <MarketplaceItem>[].obs;

  // 加载数据：这里先写死一些示例数据
  @override
  void onInit() {
    super.onInit();
    fetchItems();
  }

  void fetchItems() {
    // 模拟请求接口，这里先写死
    var mockData = [
      MarketplaceItem(
        id: '1',
        title: '二手教材《Flutter Basics》',
        price: 45.0,
        description: '成色较新，无笔记',
        imageUrl: 'https://picsum.photos/200/300', // 随机图
      ),
      MarketplaceItem(
        id: '2',
        title: 'iPhone 12 二手',
        price: 2500.0,
        description: '保修期内，有轻微划痕',
        imageUrl: 'https://picsum.photos/200/301',
      ),
    ];
    items.value = mockData;
  }

  // 添加商品
  void addItem(MarketplaceItem newItem) {
    items.add(newItem);
  }

  // 根据id获取商品
  MarketplaceItem? getItemById(String id) {
    return items.firstWhereOrNull((item) => item.id == id);
  }
}
