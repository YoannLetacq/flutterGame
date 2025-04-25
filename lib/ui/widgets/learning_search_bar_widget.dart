import 'package:flutter/material.dart';

class LearningSearchBar extends StatelessWidget {
  final String query;
  final ValueChanged<String> onSearch;

  const LearningSearchBar({
    super.key,
    required this.query,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        onChanged: onSearch,
        controller: TextEditingController(text: query),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          suffixIcon: query.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => onSearch(''),
          )
              : null,
          hintText: 'Rechercher une notion…',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
