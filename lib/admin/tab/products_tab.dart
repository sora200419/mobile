import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductsTab extends StatelessWidget {
  final CollectionReference products = FirebaseFirestore.instance.collection('products');

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Delete"),
          content: Text("Are you sure you want to delete this product?"),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text("Delete", style: TextStyle(color: Colors.red)),
              onPressed: () {
                products.doc(docId).delete();
                Navigator.of(context).pop();
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
      color: Colors.transparent, // 背景透明，继承父级背景色
      child: StreamBuilder<QuerySnapshot>(
        stream: products.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: TextStyle(color: Colors.black54),
              ),
            );
          }
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          var docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Text(
                "No products found",
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
            );
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              return Card(
                color: Colors.white,
                child: ListTile(
                  leading: data['imageUrl'] != null
                      ? Image.network(
                          data['imageUrl'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : Icon(Icons.image),
                  title: Text(data['name'] ?? 'No Name'),
                  subtitle: Text("Price: \$${data['price'] ?? 'N/A'}"),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
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