import 'package:flutter/material.dart';

class AbandonScreen extends StatelessWidget {
  static const routeName = '/abandon';

  const AbandonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Abandon'),
      ),
      body: Center(
        child: Text(
          'Votre adversaire a abandonné',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
