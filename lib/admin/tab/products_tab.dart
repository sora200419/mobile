import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../details/product_details.dart';

class ProductsTab extends StatefulWidget {
  const ProductsTab({Key? key}) : super(key: key);

  @override
  _ProductsTabState createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {
  final CollectionReference products = FirebaseFirestore.instance.collection(
    'products',
  );
  String _searchQuery = '';
  String? _selectedStatus;
  String _sortField = 'createdAt';
  bool _isDescending = true;

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Product"),
          content: const Text(
            "This action cannot be undone. Delete this product",
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
              onPressed: () async {
                try {
                  await products.doc(docId).delete();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Product deleted")),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to delete product: $e")),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // search bar
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim().toLowerCase();
                    });
                  },
                ),
              ),
            ],
          ),
        ),

        // Filters row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              // Status filter
              Expanded(
                flex: 2,
                child: DropdownButton<String>(
                  value: _selectedStatus ?? 'All',
                  isExpanded: true,
                  items:
                      ['All', 'Available', 'Reserved', 'Sold']
                          .map(
                            (status) => DropdownMenuItem<String>(
                              value: status,
                              child: Text(status),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value == 'All' ? null : value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Sort field filter
              Expanded(
                flex: 2,
                child: DropdownButton<String>(
                  value: _sortField,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(value: 'createdAt', child: Text('Time')),
                    DropdownMenuItem(value: 'price', child: Text('Price')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _sortField = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Sort order toggle
              IconButton(
                icon: Icon(
                  _isDescending ? Icons.arrow_downward : Icons.arrow_upward,
                  color: Colors.grey,
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

        // product list
        Expanded(
          child: Container(
            color: Colors.transparent,
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  _selectedStatus == null
                      ? products
                          .orderBy(_sortField, descending: _isDescending)
                          .snapshots()
                      : products
                          .where('status', isEqualTo: _selectedStatus)
                          .orderBy(_sortField, descending: _isDescending)
                          .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print("Error fetching products: ${snapshot.error}");
                  return Center(
                    child: Text(
                      "Error: ${snapshot.error}",
                      style: const TextStyle(color: Colors.black54),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting ||
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data!.docs;

                // filter product list (searching)
                var filteredDocs =
                    docs.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      String title =
                          (data['title'] ?? '').toString().toLowerCase();
                      String sellerName =
                          (data['sellerName'] ?? '').toString().toLowerCase();
                      return title.contains(_searchQuery) ||
                          sellerName.contains(_searchQuery);
                    }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No products found",
                      style: TextStyle(fontSize: 18, color: Colors.black54),
                    ),
                  );
                }

                // product list
                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var data =
                        filteredDocs[index].data() as Map<String, dynamic>;
                    return Card(
                      color: Colors.white,
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ProductDetailsPage(
                                    productId: filteredDocs[index].id,
                                    productData: data,
                                  ),
                            ),
                          );
                        },
                        leading:
                            data['imageUrl'] != null &&
                                    data['imageUrl'].toString().isNotEmpty
                                ? Image.network(
                                  data['imageUrl'],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          const Icon(Icons.broken_image),
                                )
                                : const Icon(Icons.image),
                        title: Text(
                          data['title'] ?? 'No Title',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Price: \$${data['price']?.toString() ?? 'N/A'}",
                            ),
                            Text(
                              "Seller: ${data['sellerName'] ?? 'Unknown'}",
                              style: const TextStyle(color: Colors.grey),
                            ),
                            Text(
                              "Status: ${data['status'] ?? 'N/A'}",
                              style: TextStyle(
                                color: _getStatusColor(data['status']),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (data['createdAt'] != null)
                              Text(
                                "Posted: ${_formatDate(data['createdAt'].toDate())}",
                                style: const TextStyle(color: Colors.grey),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_forever,
                            color: Colors.red,
                          ),
                          onPressed:
                              () => _confirmDelete(
                                context,
                                filteredDocs[index].id,
                              ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Available':
        return Colors.green;
      case 'Reserved':
        return Colors.orange;
      case 'Sold':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
