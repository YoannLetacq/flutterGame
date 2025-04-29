import 'package:flutter/material.dart';

class LearningSearchBar extends StatefulWidget {
  final String query;
  final ValueChanged<String> onSearch;

  const LearningSearchBar({
    super.key,
    required this.query,
    required this.onSearch,
  });

  @override
  State<LearningSearchBar> createState() => _LearningSearchBarState();
}

class _LearningSearchBarState extends State<LearningSearchBar> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.query);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _ctrl,
        onChanged: widget.onSearch,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _ctrl.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _ctrl.clear();
              widget.onSearch('');
            },
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
