// lib\features\task\views\task_rating_screen.dart
import 'package:flutter/material.dart';
import 'package:mobiletesting/features/task/model/task_model.dart';
import 'package:mobiletesting/features/task/services/rating_service.dart';

class TaskRatingScreen extends StatefulWidget {
  final Task task;
  final String userIdToRate; // ID of the user being rated
  final String userNameToRate; // Name of the user being rated

  const TaskRatingScreen({
    Key? key,
    required this.task,
    required this.userIdToRate,
    required this.userNameToRate,
  }) : super(key: key);

  @override
  State<TaskRatingScreen> createState() => _TaskRatingScreenState();
}

class _TaskRatingScreenState extends State<TaskRatingScreen> {
  final RatingService _ratingService = RatingService();
  final TextEditingController _commentController = TextEditingController();

  double _rating = 3.0; // Default rating
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // Submit the rating
  Future<void> _submitRating() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _ratingService.rateUser(
        widget.task.id!,
        widget.userIdToRate,
        _rating,
        comment:
            _commentController.text.isNotEmpty ? _commentController.text : null,
      );

      // Close the rating screen and return to previous screen
      Navigator.pop(context, true);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rating submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting rating: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate Service')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Task title
            Text(
              'Task: ${widget.task.title}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // User being rated
            Text(
              'Rating: ${widget.userNameToRate}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Rating stars
            const Text(
              'How would you rate the service?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Star rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1.0;

                return IconButton(
                  icon: Icon(
                    _rating >= starValue ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = starValue;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 8),

            // Rating value text
            Text(
              '${_rating.toStringAsFixed(1)} / 5.0',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),

            // Comment field
            const Text(
              'Add a comment (optional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Share your experience...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              maxLength: 200,
            ),
            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child:
                    _isSubmitting
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text(
                          'Submit Rating',
                          style: TextStyle(fontSize: 16),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
