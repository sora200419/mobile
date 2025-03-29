// lib/features/community/views/components/post_filter.dart

import 'package:flutter/material.dart';
import 'package:mobiletesting/features/community/models/community_post_model.dart';
import 'package:mobiletesting/features/community/utils/post_utilities.dart';

class PostFilter extends StatelessWidget {
  final PostType? selectedType;
  final Function(PostType?) onTypeSelected;

  const PostFilter({
    Key? key,
    required this.selectedType,
    required this.onTypeSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip(context, null, 'All'),
          ...PostType.values.map((type) {
            return _buildFilterChip(
              context,
              type,
              PostUtilities.getPostTypeLabel(type),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, PostType? type, String label) {
    final isSelected = selectedType == type;
    final color =
        type == null ? Colors.deepPurple : PostUtilities.getPostTypeColor(type);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (_) => onTypeSelected(type),
        backgroundColor: Colors.grey.shade200,
        selectedColor: color.withOpacity(0.2),
        checkmarkColor: color,
        labelStyle: TextStyle(
          color: isSelected ? color : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(color: isSelected ? color : Colors.transparent),
      ),
    );
  }
}
