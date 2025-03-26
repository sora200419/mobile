import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../details/product_details.dart';

class ProductsTab extends StatelessWidget {
  final CollectionReference products = FirebaseFirestore.instance.collection(
    'products',
  );

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
    return Container(
      color: Colors.transparent,
      child: StreamBuilder<QuerySnapshot>(
        stream: products.orderBy('createdAt', descending: true).snapshots(),
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
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No products found",
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
            );
          }

          // product list
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              return Card(
                color: Colors.white,
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ProductDetailsPage(
                              productId: docs[index].id,
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
                      Text("Price: \$${data['price']?.toString() ?? 'N/A'}"),
                      Text(
                        "Seller: ${data['sellerName'] ?? 'Unknown'}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        "Status: ${data['status'] ?? 'N/A'}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    onPressed: () => _confirmDelete(context, docs[index].id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}