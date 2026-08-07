import 'package:flutter/material.dart';
import '../services/signalement_service.dart';

/// Bottom sheet pour signaler une publication. S'ouvre via showModalBottomSheet.
class ReportPublicationSheet extends StatefulWidget {
  final int publicationId;
  final double latitude;
  final double longitude;
  final String adresse;

  const ReportPublicationSheet({
    super.key,
    required this.publicationId,
    required this.latitude,
    required this.longitude,
    required this.adresse,
  });

  @override
  State<ReportPublicationSheet> createState() => _ReportPublicationSheetState();
}

class _ReportPublicationSheetState extends State<ReportPublicationSheet> {
  final _service = SignalementService();
  final _commentaireController = TextEditingController();
  String _type = 'FAUSSE_ALERTE';
  bool _envoiEnCours = false;

  @override
  void dispose() {
    _commentaireController.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    if (_commentaireController.text.trim().isEmpty) return;

    setState(() => _envoiEnCours = true);

    try {
      await _service.signaler(
        publicationId: widget.publicationId,
        commentaire: _commentaireController.text.trim(),
        type: _type,
        latitude: widget.latitude,
        longitude: widget.longitude,
        adresse: widget.adresse,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _envoiEnCours = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec de l\'envoi du signalement')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Signaler cette publication', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _type,
            decoration: const InputDecoration(labelText: 'Motif', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'FAUSSE_ALERTE', child: Text('Fausse alerte')),
              DropdownMenuItem(value: 'VU', child: Text("J'ai vu cet objet ailleurs")),
              DropdownMenuItem(value: 'TROUVE', child: Text('Objet déjà retrouvé')),
            ],
            onChanged: (val) => setState(() => _type = val!),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentaireController,
            decoration: const InputDecoration(labelText: 'Explique en quelques mots', border: OutlineInputBorder()),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _envoiEnCours ? null : _envoyer,
            child: _envoiEnCours
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Envoyer le signalement'),
          ),
        ],
      ),
    );
  }
}
