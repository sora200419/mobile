import 'package:flutter/material.dart';
import 'package:mobiletesting/services/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:mobiletesting/features/task/model/task_model.dart';
import 'package:mobiletesting/features/task/services/task_service.dart';
import 'package:mobiletesting/View/home_runner.dart';


class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreen createState() => _ProfileScreen();
}

class _ProfileScreen extends State<ProfileScreen> {
  String username = "";
  String signature = "Briefly introduce yourself!";

  File? _image;
  String? _imageUrl;
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _loadProfilePicture();
  }

  // todo: complete profile edit

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile == null) {
      return;
    }

    File imageFile = File(pickedFile.path);

    try {
      // upload image to Firebase Storage
      Reference ref = FirebaseStorage.instance.ref().child(
        'profilePicture/$userId.jpg',
      );
      await ref.putFile(imageFile);

      // get download URL
      String downloadURL = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'profilePicture': downloadURL,
      }, SetOptions(merge: true));

      setState(() {
        _image = imageFile;
        _imageUrl = downloadURL;
      });
    } catch (e) {
      print("Error uploading image: $e");
    }
  }

  Future<void> _loadProfilePicture() async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      setState(() {
        _imageUrl = userDoc['profilePicture'];
      });
    }
  }

  Future<void> _loadUsername() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.fetchUsername();
    setState(() {
      username = authProvider.username!;
    });
  }

  void _editProfile() {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController nameController = TextEditingController(
          text: username,
        );
        TextEditingController signatureController = TextEditingController(
          text: signature,
        );

        return AlertDialog(
          title: Text("Edit Profile"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: "Username"),
              ),
              TextField(
                controller: signatureController,
                decoration: InputDecoration(labelText: "Signature"),
              ),
              ElevatedButton(
                onPressed: () {
                  _pickImage();
                },
                child: Text("Change Profile Picture"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                String newUsername =
                    nameController.text; // todo: rewrite firestore data
                String newSignature = signatureController.text;
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .update({'name': newUsername, 'signature': newSignature});
                setState(() {
                  username = newUsername;
                  signature = newSignature;
                });
                Navigator.pop(context);
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        actions: [IconButton(icon: Icon(Icons.edit), onPressed: _editProfile)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return Dialog(
                          child: InteractiveViewer(
                            child: Image.asset(
                              'assets/profile.jpg',
                            ), // todo: user profile pic
                          ),
                        );
                      },
                    );
                  },
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage:
                        _imageUrl != null
                            ? NetworkImage(_imageUrl!)
                            : AssetImage('assets/profile.jpg'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        signature,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Completed Order",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: TaskListWidget(
              taskStream: TaskService().getTasksForRunnerByStatus("completed"),
              searchQuery: '',
            ),
          ),
        ],
      ),
    );
  }
}
