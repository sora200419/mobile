// lib/features/community/utils/post_utilities.dart

import 'package:flutter/material.dart';
import 'package:campuslink/features/community/models/community_post_model.dart';

class PostUtilities {
  // Get color based on post type
  static Color getPostTypeColor(PostType type) {
    switch (type) {
      case PostType.general:
        return Colors.deepPurple;
      case PostType.lostFound:
        return Colors.orange;
      case PostType.jobPosting:
        return Colors.green;
      case PostType.studyMaterial:
        return Colors.blue;
      case PostType.event:
        return Colors.red;
    }
  }

  // Get label for post type
  static String getPostTypeLabel(PostType type) {
    switch (type) {
      case PostType.general:
        return 'General';
      case PostType.lostFound:
        return 'Lost & Found';
      case PostType.jobPosting:
        return 'Job';
      case PostType.studyMaterial:
        return 'Study';
      case PostType.event:
        return 'Event';
    }
  }

  // Get icon for post type
  static IconData getPostTypeIcon(PostType type) {
    switch (type) {
      case PostType.general:
        return Icons.chat_bubble_outline;
      case PostType.lostFound:
        return Icons.search;
      case PostType.jobPosting:
        return Icons.work_outline;
      case PostType.studyMaterial:
        return Icons.book_outlined;
      case PostType.event:
        return Icons.event;
    }
  }

  // Format metadata based on post type (for specialized post types)
  static Map<String, Widget> getFormattedMetadata(CommunityPost post) {
    final Map<String, Widget> formattedData = {};

    if (post.metadata == null) return formattedData;

    switch (post.type) {
      case PostType.lostFound:
        if (post.metadata!.containsKey('itemType')) {
          formattedData['Item Type'] = Text(post.metadata!['itemType']);
        }
        if (post.metadata!.containsKey('location')) {
          formattedData['Location'] = Text(post.metadata!['location']);
        }
        if (post.metadata!.containsKey('date')) {
          formattedData['Date'] = Text(post.metadata!['date']);
        }
        if (post.metadata!.containsKey('isFound')) {
          final isFound = post.metadata!['isFound'] as bool;
          formattedData['Status'] = Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isFound ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isFound ? 'Found' : 'Lost',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }
        break;

      case PostType.jobPosting:
        if (post.metadata!.containsKey('jobType')) {
          formattedData['Job Type'] = Text(post.metadata!['jobType']);
        }
        if (post.metadata!.containsKey('salary')) {
          formattedData['Salary'] = Text(post.metadata!['salary']);
        }
        if (post.metadata!.containsKey('location')) {
          formattedData['Location'] = Text(post.metadata!['location']);
        }
        if (post.metadata!.containsKey('duration')) {
          formattedData['Duration'] = Text(post.metadata!['duration']);
        }
        if (post.metadata!.containsKey('contact')) {
          formattedData['Contact'] = Text(post.metadata!['contact']);
        }
        break;

      case PostType.studyMaterial:
        if (post.metadata!.containsKey('subject')) {
          formattedData['Subject'] = Text(post.metadata!['subject']);
        }
        if (post.metadata!.containsKey('course')) {
          formattedData['Course'] = Text(post.metadata!['course']);
        }
        if (post.metadata!.containsKey('materialType')) {
          formattedData['Material Type'] = Text(post.metadata!['materialType']);
        }
        break;

      case PostType.event:
        if (post.metadata!.containsKey('date')) {
          formattedData['Date'] = Text(post.metadata!['date']);
        }
        if (post.metadata!.containsKey('time')) {
          formattedData['Time'] = Text(post.metadata!['time']);
        }
        if (post.metadata!.containsKey('location')) {
          formattedData['Location'] = Text(post.metadata!['location']);
        }
        if (post.metadata!.containsKey('organizer')) {
          formattedData['Organizer'] = Text(post.metadata!['organizer']);
        }
        break;

      case PostType.general:
        // General posts don't have specialized metadata
        break;
    }

    return formattedData;
  }

  // Get metadata form fields based on post type
  static List<Widget> getMetadataFormFields(
    PostType type,
    Map<String, dynamic> metadata,
    Function(String, dynamic) onMetadataChanged,
  ) {
    final List<Widget> fields = [];

    switch (type) {
      case PostType.lostFound:
        fields.add(
          DropdownButtonFormField<String>(
            value: metadata['itemType'] as String?,
            decoration: const InputDecoration(labelText: 'Item Type'),
            items:
                ['Electronics', 'Books', 'Clothing', 'ID/Cards', 'Other'].map((
                  value,
                ) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
            onChanged: (value) => onMetadataChanged('itemType', value),
          ),
        );
        fields.add(const SizedBox(height: 16));
        fields.add(
          TextFormField(
            initialValue: metadata['location'] as String?,
            decoration: const InputDecoration(labelText: 'Location'),
            onChanged: (value) => onMetadataChanged('location', value),
          ),
        );
        fields.add(const SizedBox(height: 16));
        fields.add(
          TextFormField(
            initialValue: metadata['date'] as String?,
            decoration: const InputDecoration(labelText: 'Date'),
            onChanged: (value) => onMetadataChanged('date', value),
          ),
        );
        fields.add(const SizedBox(height: 16));
        fields.add(
          SwitchListTile(
            title: const Text('Is this a found item?'),
            value: metadata['isFound'] as bool? ?? false,
            onChanged: (value) => onMetadataChanged('isFound', value),
          ),
        );
        break;

      case PostType.jobPosting:
        fields.add(
          DropdownButtonFormField<String>(
            value: metadata['jobType'] as String?,
            decoration: const InputDecoration(labelText: 'Job Type'),
            items:
                [
                  'Part-time',
                  'Full-time',
                  'Internship',
                  'Temporary',
                  'Volunteer',
                  'Other',
                ].map((value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
            onChanged: (value) => onMetadataChanged('jobType', value),
          ),
        );
        fields.add(const SizedBox(height: 16));
        fields.add(
          TextFormField(
            initialValue: metadata['salary'] as String?,
            decoration: const InputDecoration(labelText: 'Salary/Compensation'),
            onChanged: (value) => onMetadataChanged('salary', value),
          ),
        );
        fields.add(const SizedBox(height: 16));
        fields.add(
          TextFormField(
            initialValue: metadata['location'] as String?,
            decoration: const InputDecoration(labelText: 'Location'),
            onChanged: (value) => onMetadataChanged('location', value),
          ),
        );
        fields.add(const SizedBox(height: 16));
        fields.add(
          TextFormField(
            initialValue: metadata['duration'] as String?,
            decoration: const InputDecoration(labelText: 'Duration'),
            onChanged: (value) => onMetadataChanged('duration', value),
          ),
        );
        fields.add(const SizedBox(height: 16));
        fields.add(
          TextFormField(
            initialValue: metadata['contact'] as String?,
            decoration: const InputDecoration(labelText: 'Contact Information'),
            onChanged: (value) => onMetadataChanged('contact', value),
          ),
        );
        break;

      case PostType.studyMaterial:
        fields.add(
          TextFormField(
            initialValue: metadata['subject'] as String?,
            decoration: const InputDecoration(labelText: 'Subject'),
            onChanged: (value) => onMetadataChanged('subject', value),
          ),
        );
        fields.add(const SizedBox(height: 16));
        fields.add(
          TextFormField(
            initialValue: metadata['course'] as String?,
            decoration: const InputDecoration(labelText: 'Course/Class'),
            onChanged: (value) => onMetadataChanged('course', value),
          ),
        );
        fields.add(const SizedBox(height: 16));
        fields.add(
          DropdownButtonFormField<String>(
            value: metadata['materialType'] as String?,
            decoration: const InputDecoration(labelText: 'Material Type'),
            items:
                [
                  'Notes',
                  'Book',
                  'Past Paper',
                  'Assignment',
                  'Tutorial',
                  'Other',
                ].map((value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
            onChanged: (value) => onMetadataChanged('materialType', value),
          ),
        );
        break;

      case PostType.event:
        fields.add(
          TextFormField(
            initialValue: metadata['date'] as String?,
            decoration: const InputDecoration(labelText: 'Event Date'),
            onChanged: (value) => onMetadataChanged('date', value),
          ),
        );
        fields.add(const SizedBox(height: 16));
        fields.add(
          TextFormField(
            initialValue: metadata['time'] as String?,
            decoration: const InputDecoration(labelText: 'Event Time'),
            onChanged: (value) => onMetadataChanged('time', value),
          ),
        );
        fields.add(const SizedBox(height: 16));
        fields.add(
          TextFormField(
            initialValue: metadata['location'] as String?,
            decoration: const InputDecoration(labelText: 'Event Location'),
            onChanged: (value) => onMetadataChanged('location', value),
          ),
        );
        fields.add(const SizedBox(height: 16));
        fields.add(
          TextFormField(
            initialValue: metadata['organizer'] as String?,
            decoration: const InputDecoration(labelText: 'Organizer'),
            onChanged: (value) => onMetadataChanged('organizer', value),
          ),
        );
        break;

      case PostType.general:
        // No additional fields for general posts
        break;
    }

    return fields;
  }

  // Get default metadata for post type
  static Map<String, dynamic> getDefaultMetadata(PostType type) {
    switch (type) {
      case PostType.lostFound:
        return {
          'itemType': 'Other',
          'location': '',
          'date': '',
          'isFound': false,
        };
      case PostType.jobPosting:
        return {
          'jobType': 'Part-time',
          'salary': '',
          'location': '',
          'duration': '',
          'contact': '',
        };
      case PostType.studyMaterial:
        return {'subject': '', 'course': '', 'materialType': 'Notes'};
      case PostType.event:
        return {'date': '', 'time': '', 'location': '', 'organizer': ''};
      case PostType.general:
        return {};
    }
  }
}
