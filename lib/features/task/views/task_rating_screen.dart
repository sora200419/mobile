// lib/features/task/views/task_rating_screen.dart
import 'package:flutter/material.dart';
import 'package:campuslink/features/task/model/task_model.dart';
import 'package:campuslink/features/task/services/rating_service.dart';

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
  bool _hasAlreadyRated = false;
  bool _isCheckingRating = true;

  @override
  void initState() {
    super.initState();
    _checkExistingRating();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // Check if user has already rated this task
  Future<void> _checkExistingRating() async {
    setState(() {
      _isCheckingRating = true;
    });

    try {
      bool hasRated = await _ratingService.hasUserRatedTask(widget.task.id!);

      if (hasRated) {
        if (mounted) {
          setState(() {
            _hasAlreadyRated = true;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'You have already rated this task. Thank you for your feedback!',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );

          // Return to previous screen after a short delay
          Future.delayed(Duration(seconds: 3), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        }
      }
    } catch (e) {
      print('Error checking existing rating: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingRating = false;
        });
      }
    }
  }

  // Submit the rating
  Future<void> _submitRating() async {
    if (_isSubmitting || _hasAlreadyRated) return;

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
      if (mounted) {
        Navigator.pop(context, true);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rating submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Check if error is about already having rated
        if (e.toString().contains('already rated')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You have already rated this task'),
              backgroundColor: Colors.orange,
            ),
          );

          setState(() {
            _hasAlreadyRated = true;
          });

          // Return to previous screen after a short delay
          Future.delayed(Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        } else {
          // Show generic error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error submitting rating: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while checking if user has already rated
    if (_isCheckingRating) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rate Service')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show "already rated" message if user has already rated
    if (_hasAlreadyRated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rate Service')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              const Text(
                'You have already rated this task',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Thank you for your feedback!',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Return'),
              ),
            ],
          ),
        ),
      );
    }

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

            // Rating description based on selection
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getRatingDescription(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getRatingExplanation(),
                    style: TextStyle(color: Colors.amber.shade900),
                  ),
                ],
              ),
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

  // Get rating description text based on selected rating
  String _getRatingDescription() {
    if (_rating >= 5) return 'Excellent!';
    if (_rating >= 4) return 'Very Good';
    if (_rating >= 3) return 'Good';
    if (_rating >= 2) return 'Fair';
    return 'Poor';
  }

  // Get rating explanation text based on selected rating
  String _getRatingExplanation() {
    if (_rating >= 5) return 'Exceptional service, exceeded expectations';
    if (_rating >= 4) return 'Great service, would recommend';
    if (_rating >= 3) return 'Satisfactory service, met expectations';
    if (_rating >= 2) return 'Some issues, but completed the task';
    return 'Significant issues with service quality';
  }
}
