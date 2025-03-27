import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Emergency Help'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            const phoneNumber = 'tel:999';
            if (await canLaunchUrl(Uri.parse(phoneNumber))) {
              await launchUrl(Uri.parse(phoneNumber));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Unable to open the dial interface")),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            shape: CircleBorder(),
            backgroundColor: Colors.red,
            padding: EdgeInsets.all(20),
            minimumSize: Size(300, 300),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.call,
                size: 36,
                color: Colors.white,
              ),
              SizedBox(height: 8),
              Text(
                'Emergency Call',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}