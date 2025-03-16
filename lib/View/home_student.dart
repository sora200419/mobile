// lib/View/home_student.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobiletesting/providers/auth_provider.dart';
// Import other screens as you implement them

class HomeStudent extends StatefulWidget {
  const HomeStudent({Key? key}) : super(key: key);

  @override
  State<HomeStudent> createState() => _HomeStudentState();
}

class _HomeStudentState extends State<HomeStudent> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    StudentDashboard(),
    MarketplaceListScreen(),
    ServiceRequestScreen(), // To be implemented
    CommunityScreen(), // To be implemented
    ProfileScreen(), // To be implemented
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("CampusLink"),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              // Navigate to notifications
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              authProvider.logout(context);
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Marketplace',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.miscellaneous_services),
            label: 'Services',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Community'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// Create a dashboard widget for the home tab
class StudentDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome, ${authProvider.username ?? 'Student'}!",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "What would you like to do today?",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          // Quick access section
          Text("Quick Access", style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: 10),

          // Feature grids
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _buildFeatureCard(
                context,
                "Buy Items",
                Icons.shopping_cart,
                Colors.blue,
                () {
                  // Navigate to marketplace
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
              ),
              _buildFeatureCard(
                context,
                "Sell Items",
                Icons.sell,
                Colors.green,
                () {
                  // Navigate to create listing
                },
              ),
              _buildFeatureCard(
                context,
                "Request Service",
                Icons.room_service,
                Colors.orange,
                () {
                  // Navigate to service request
                },
              ),
              _buildFeatureCard(
                context,
                "Campus Events",
                Icons.event,
                Colors.purple,
                () {
                  // Navigate to events
                },
              ),
            ],
          ),

          SizedBox(height: 20),

          // Recent activity section
          Text(
            "Recent Activity",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 10),

          // Recent activities list
          _buildRecentActivityList(),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Card(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityList() {
    return Card(
      child: ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: 3, // Display only a few recent activities
        itemBuilder: (context, index) {
          // Replace with actual data from Firebase
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.withOpacity(0.2),
              child: Icon(Icons.history, color: Colors.blue),
            ),
            title: Text("Activity ${index + 1}"),
            subtitle: Text("Recent activity description"),
            trailing: Text("${index + 1}h ago"),
          );
        },
      ),
    );
  }
}
