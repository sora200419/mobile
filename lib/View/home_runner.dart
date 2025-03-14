import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobiletesting/services/auth_provider.dart';
import 'package:provider/provider.dart';

class HomeRunner extends StatelessWidget {
  const HomeRunner({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // Number of tab
      child: Scaffold(
        appBar: AppBar(
          title: Text('Runner'),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () {
                Provider.of<AuthProvider>(context, listen: false).logout(context);
              },
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.hourglass_empty), text: "Pending"),
              Tab(icon: Icon(Icons.move_to_inbox), text: "Awaiting Pickup"),
              Tab(icon: Icon(Icons.check_circle), text: "Picked Up"),
              Tab(icon: Icon(Icons.directions_walk), text: "In Transit"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTabContent("Pending"),
            _buildTabContent("Awaiting Pickup"),
            _buildTabContent("Picked up"),
            _buildTabContent("In Transit"),
          ],
        ),
      ),
    );
  }
}

/// **🔥 从 Firebase Firestore 获取数据**
Widget _buildTabContent(String status) {
  return StreamBuilder(
    stream:
        FirebaseFirestore.instance
            .collection('orders') // Firestore 里的集合名称
            .where('status', isEqualTo: status) // 过滤订单状态
            .snapshots(), // 监听数据变化
    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator()); // 加载动画
      }
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return Center(child: Text("No $status orders")); // 没有订单
      }

      // **🔥 解析 Firestore 数据**
      var orders = snapshot.data!.docs;
      return ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          var order = orders[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(order['title']), // 订单标题
              subtitle: Text(
                "From: ${order['from']} → To: ${order['to']}",
              ), // 显示起点和终点
              trailing: Icon(Icons.arrow_forward_ios),
            ),
          );
        },
      );
    },
  );
}
