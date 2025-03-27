import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DataAnalysisPage extends StatefulWidget {
  const DataAnalysisPage({Key? key}) : super(key: key);

  @override
  _DataAnalysisPageState createState() => _DataAnalysisPageState();
}

class _DataAnalysisPageState extends State<DataAnalysisPage> {
  String _selectedView = 'transactions';
  bool _isDescending = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Data Analysis"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter and Sort Row
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Filter Dropdown
                  SizedBox(
                    width: 200,
                    child: DropdownButton<String>(
                      value: _selectedView,
                      isExpanded: true,
                      items:
                          <String>[
                            'transactions',
                            'tasks',
                          ].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value.toUpperCase()),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedView = newValue!;
                        });
                      },
                    ),
                  ),
                  // Sort Button
                  IconButton(
                    icon: Icon(
                      _isDescending ? Icons.arrow_downward : Icons.arrow_upward,
                    ),
                    onPressed: () {
                      setState(() {
                        _isDescending = !_isDescending;
                      });
                    },
                  ),
                ],
              ),
            ),

            // Conditional content
            if (_selectedView == 'transactions') ...[
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Transactions",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('transactions')
                        .orderBy('createdAt', descending: _isDescending)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No transactions found"));
                  }
                  final totalTransactions = snapshot.data!.docs.length;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          "Total Transactions: $totalTransactions",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: totalTransactions,
                        itemBuilder: (context, index) {
                          final transaction = snapshot.data!.docs[index];
                          final data =
                              transaction.data() as Map<String, dynamic>;
                          String createdAt = "N/A";
                          if (data['createdAt'] != null) {
                            createdAt = DateFormat(
                              'yyyy-MM-dd HH:mm:ss',
                            ).format((data['createdAt'] as Timestamp).toDate());
                          }
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              title: Text(
                                "Product: ${data['productTitle'] ?? 'N/A'}",
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Amount: ${data['amount'] ?? 'N/A'}"),
                                  Text("Buyer: ${data['buyerName'] ?? 'N/A'}"),
                                  Text(
                                    "Seller: ${data['sellerName'] ?? 'N/A'}",
                                  ),
                                  Text("Status: ${data['status'] ?? 'N/A'}"),
                                  Text("Created At: $createdAt"),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ] else ...[
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Tasks",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('tasks')
                        .orderBy('createdAt', descending: _isDescending)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No tasks found"));
                  }
                  final totalTasks = snapshot.data!.docs.length;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          "Total Tasks: $totalTasks",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: totalTasks,
                        itemBuilder: (context, index) {
                          final task = snapshot.data!.docs[index];
                          final data = task.data() as Map<String, dynamic>;
                          String deadline = "N/A";
                          if (data['deadline'] != null) {
                            deadline = DateFormat(
                              'yyyy-MM-dd HH:mm:ss',
                            ).format((data['deadline'] as Timestamp).toDate());
                          }
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              title: Text("Task: ${data['title'] ?? 'N/A'}"),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Category: ${data['category'] ?? 'N/A'}",
                                  ),
                                  Text(
                                    "Requester: ${data['requesterName'] ?? 'N/A'}",
                                  ),
                                  Text(
                                    "Provider: ${data['providerName'] ?? 'N/A'}",
                                  ),
                                  Text("Status: ${data['status'] ?? 'N/A'}"),
                                  Text("Deadline: $deadline"),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
