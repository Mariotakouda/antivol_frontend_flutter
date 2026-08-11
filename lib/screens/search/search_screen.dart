import 'package:flutter/material.dart';
import '../../models/publication_model.dart';
import '../../services/search_service.dart';
import '../../widgets/publication_card.dart';
import '../publications/publication_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _service = SearchService();
  final _controller = TextEditingController();
  String? _filtreType;
  List<PublicationModel> _resultats = [];
  bool _chargement = false;
  bool _aDejaCherche = false;

  Future<void> _rechercher() async {
    setState(() => _chargement = true);

    try {
      final resultat = await _service.rechercher(
        motCle: _controller.text.trim(),
        type: _filtreType,
      );
      if (!mounted) return;
      setState(() {
        _resultats = resultat.data;
        _chargement = false;
        _aDejaCherche = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _chargement = false;
        _aDejaCherche = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Rechercher un objet...',
            border: InputBorder.none,
          ),
          style: const TextStyle(color: Color.fromARGB(255, 7, 7, 7), fontSize: 18),
          cursorColor: const Color.fromARGB(255, 214, 213, 213),
          onSubmitted: (_) => _rechercher(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _rechercher),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Tout'),
                  selected: _filtreType == null,
                  onSelected: (_) {
                    setState(() => _filtreType = null);
                    _rechercher();
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Perdu'),
                  selected: _filtreType == 'PERDU',
                  onSelected: (_) {
                    setState(() => _filtreType = 'PERDU');
                    _rechercher();
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Trouvé'),
                  selected: _filtreType == 'TROUVE',
                  onSelected: (_) {
                    setState(() => _filtreType = 'TROUVE');
                    _rechercher();
                  },
                ),
              ],
            ),
          ),
          Expanded(child: _construireContenu()),
        ],
      ),
    );
  }

  Widget _construireContenu() {
    if (_chargement) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_aDejaCherche) {
      return const Center(
        child: Text('Tape un mot-clé et appuie sur Entrée', style: TextStyle(color: Colors.grey)),
      );
    }

    if (_resultats.isEmpty) {
      return const Center(child: Text('Aucun résultat'));
    }

    return ListView.builder(
      itemCount: _resultats.length,
      itemBuilder: (context, index) {
        final publication = _resultats[index];
        return PublicationCard(
          publication: publication,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PublicationDetailScreen(publicationId: publication.id)),
          ),
        );
      },
    );
  }
}
