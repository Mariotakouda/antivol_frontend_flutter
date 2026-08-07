import 'package:flutter/material.dart';
import '../core/utils/auth_guard.dart';
import '../models/commentaire_model.dart';
import '../services/commentaire_service.dart';

/// Section commentaires à insérer dans PublicationDetailScreen.
/// Autonome : gère son propre chargement, sans provider global (les commentaires
/// n'ont pas besoin d'être partagés entre écrans).
class CommentSectionWidget extends StatefulWidget {
  final int publicationId;

  const CommentSectionWidget({super.key, required this.publicationId});

  @override
  State<CommentSectionWidget> createState() => _CommentSectionWidgetState();
}

class _CommentSectionWidgetState extends State<CommentSectionWidget> {
  final _service = CommentaireService();
  final _controller = TextEditingController();
  List<CommentaireModel> _commentaires = [];
  bool _chargement = true;
  bool _envoiEnCours = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    try {
      final commentaires = await _service.lister(widget.publicationId);
      if (!mounted) return;
      setState(() {
        _commentaires = commentaires;
        _chargement = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _chargement = false);
    }
  }

  Future<void> _envoyer() async {
    final texte = _controller.text.trim();
    if (texte.isEmpty) return;

    if (!await exigerConnexion(context, message: 'Connecte-toi pour commenter')) return;
    if (!mounted) return;

    setState(() => _envoiEnCours = true);
    _controller.clear();

    try {
      final commentaire = await _service.ajouter(publicationId: widget.publicationId, contenu: texte);
      if (!mounted) return;
      setState(() {
        _commentaires.insert(0, commentaire);
        _envoiEnCours = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _envoiEnCours = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec de l\'envoi du commentaire')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Commentaires (${_commentaires.length})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Ajouter un commentaire...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _envoyer(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _envoiEnCours ? null : _envoyer,
              icon: _envoiEnCours
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_chargement)
          const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
        else if (_commentaires.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Aucun commentaire pour l\'instant', style: TextStyle(color: Colors.grey)),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _commentaires.length,
            itemBuilder: (context, index) {
              final commentaire = _commentaires[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: commentaire.auteurPhoto != null ? NetworkImage(commentaire.auteurPhoto!) : null,
                      child: commentaire.auteurPhoto == null ? const Icon(Icons.person, size: 16) : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(commentaire.auteurNomComplet, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(commentaire.contenu, style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}