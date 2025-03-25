import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobiletesting/services/auth_provider.dart';
import 'package:mobiletesting/admin/tab/posts_tab.dart';
import 'package:mobiletesting/admin/tab/products_tab.dart';
import 'package:mobiletesting/admin/data_analysis.dart';
import 'package:mobiletesting/admin/settings.dart';
import 'package:mobiletesting/admin/user_management.dart';

class HomeAdmin extends StatefulWidget {
  const HomeAdmin({super.key});

  @override
  _HomeAdminState createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeTabPage(),
          UserManagementPage(),
          DataAnalysisPage(),
          SettingsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },

        backgroundColor: Colors.teal,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.6),
        showSelectedLabels: true,
        showUnselectedLabels: false,
        elevation: 2,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "User",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Data Analysis",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}

class HomeTabPage extends StatelessWidget {
  const HomeTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return Text(
                "Admin - ${authProvider.username ?? 'Loading...'}",
                style: TextStyle(color: Colors.white),
              );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () {
                Navigator.pushNamed(context, '/notifications');
              },
            ),
          ],
          backgroundColor: Colors.teal,
          elevation: 2,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(fontSize: 16),
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: [
              Tab(text: "Posts"),
              Tab(text: "Products"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            PostsTab(),
            ProductsTab(),
          ],
        ),
      ),
    );
  }
}