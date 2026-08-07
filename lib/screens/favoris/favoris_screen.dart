import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/favori_provider.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/publication_card.dart';
import '../publications/publication_detail_screen.dart';

class FavorisScreen extends StatefulWidget {
  const FavorisScreen({super.key});

  @override
  State<FavorisScreen> createState() => _FavorisScreenState();
}

class _FavorisScreenState extends State<FavorisScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoriProvider>().charger();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FavoriProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mes favoris')),
      body: provider.chargement
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : provider.erreur != null && provider.favoris.isEmpty
              ? EmptyStateWidget(
                  icone: Icons.wifi_off,
                  titre: 'Impossible de charger tes favoris',
                  message: provider.erreur,
                  libelleAction: 'Réessayer',
                  onAction: provider.charger,
                )
              : provider.favoris.isEmpty
                  ? const EmptyStateWidget(
                      icone: Icons.favorite_border,
                      titre: 'Aucun favori pour le moment',
                      message: "Touche le cœur sur une annonce pour la retrouver ici.",
                    )
                  : RefreshIndicator(
                      onRefresh: provider.charger,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackSm),
                        itemCount: provider.favoris.length,
                        itemBuilder: (context, index) {
                          final publication = provider.favoris[index];
                          return PublicationCard(
                            publication: publication,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PublicationDetailScreen(publicationId: publication.id),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}