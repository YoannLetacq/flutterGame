import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/models/card_model.dart';
import 'package:untitled/services/card_service.dart';
import 'package:untitled/ui/widgets/learning_card_widget.dart';
import 'package:untitled/ui/widgets/learning_search_bar_widget.dart';
import 'package:untitled/ui/widgets/learning_toggle_view_widget.dart';
import 'package:untitled/ui/widgets/learning_view_mode.dart';

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  List<CardModel> _all = [], _filtered = [];
  LearningViewMode _view = LearningViewMode.grid;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final cards = await context.read<CardService>().fetchCards();
    setState(() => _all = _filtered = cards);
  }

  void _search(String q) {
    q = q.trim();
    setState(() {
      _query = q;
      _filtered = _all.where((c) {
        final n = c.name.toLowerCase();
        final e = c.explanation.toLowerCase();
        return n.contains(q.toLowerCase()) || e.contains(q.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isGrid = _view == LearningViewMode.grid;
    return Scaffold(
      body: Column(
        children: [
          LearningSearchBar(query: _query, onSearch: _search),
          LearningToggleView(viewMode: _view, onToggle: (m) => setState(() => _view = m)),
          const SizedBox(height: 8),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('Aucune carte trouvée.'))
                : isGrid
                ? GridView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _filtered.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: .9,
              ),
              itemBuilder: (_, i) => LearningCard(card: _filtered[i], viewMode: _view),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _filtered.length,
              itemBuilder: (_, i) => LearningCard(card: _filtered[i], viewMode: _view),
            ),
          ),
        ],
      ),
    );
  }
}
