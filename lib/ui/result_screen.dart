import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  static const routeName = '/result';

  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultats'),
      ),
      body: Center(
        child: Text(
          'Résultats de la partie',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
