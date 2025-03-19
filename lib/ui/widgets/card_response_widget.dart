import 'package:flutter/material.dart';

class CardResponseWidget extends StatefulWidget {
  final String cardType; // "complement" ou "definition"
  final List<String>? options; // Utilisé si cardType == "definition"
  final void Function(String response) onSubmit;
  /// Pour une carte "definition", représente le texte de la question/définition.
  /// Pour une carte "complement", représente le mot-clé.
  final String? questionText;

  const CardResponseWidget({
    super.key,
    required this.cardType,
    this.options,
    required this.onSubmit,
    this.questionText,
  });

  @override
  State<CardResponseWidget> createState() => _CardResponseWidgetState();
}

class _CardResponseWidgetState extends State<CardResponseWidget>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleTextSubmit() {
    final response = _controller.text;
    widget.onSubmit(response);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Card(
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: widget.cardType == 'definition' && widget.options != null
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Afficher la définition (la question) en haut, à l'intérieur de la carte.
              if (widget.questionText != null)
                Text(
                  widget.questionText!,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 4),
              // Afficher en petit et italique le texte d'instruction.
              Text(
                'Choisissez la bonne réponse',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Afficher les options sous forme de liste verticale.
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: widget.options!.map((option) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => widget.onSubmit(option),
                      child: Text(option),
                    ),
                  );
                }).toList(),
              ),
            ],
          )
              : // Pour les cartes "complement"
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Afficher le mot-clé en haut de la carte.
              if (widget.questionText != null)
                Text(
                  widget.questionText!,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 16),
              // Champ de saisie pour la réponse.
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: "Entrez votre réponse ici",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Bouton de validation.
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _handleTextSubmit,
                child: const Text("Valider"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
