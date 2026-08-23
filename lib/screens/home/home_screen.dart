import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/auth_guard.dart';
import '../../core/utils/category_icons.dart';
import '../../providers/auth_provider.dart';
import '../../providers/categorie_provider.dart';
import '../../providers/correspondance_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/publication_provider.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/onglet_protege.dart';
import '../../widgets/publication_card.dart';
import '../../widgets/skeleton_loader.dart';
import '../correspondances/correspondances_list_screen.dart';
import '../favoris/favoris_screen.dart';
import '../messagerie/conversations_list_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../publications/create_publication_screen.dart';
import '../publications/publication_detail_screen.dart';
import '../search/search_screen.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';

/// Ecran racine post-connexion : navigation par onglets (Accueil, Recherche,
/// Favoris, Messages, Profil). L'onglet Accueil contient le vrai fil
/// d'actualité des publications.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _ongletActuel = 0;

  void _allerAOnglet(int index) => setState(() => _ongletActuel = index);

  List<Widget> _buildOnglets() {
    return [
      _FeedTab(onOuvrirRecherche: () => _allerAOnglet(1)),
      const SearchScreen(),
      OngletProtege(
        message: 'Connecte-toi pour retrouver tes favoris',
        icone: Icons.favorite_border,
        builder: (_) => const FavorisScreen(),
      ),
      OngletProtege(
        message: 'Connecte-toi pour voir tes messages',
        icone: Icons.chat_bubble_outline,
        builder: (_) => const ConversationsListScreen(),
      ),
      OngletProtege(
        message: 'Connecte-toi pour accéder à ton profil',
        icone: Icons.person_outline,
        builder: (_) => const ProfileScreen(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _ongletActuel, children: _buildOnglets()),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _ongletActuel,
        onDestinationSelected: _allerAOnglet,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: 'Recherche'),
          NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Favoris'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Messages'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class _FeedTab extends StatefulWidget {
  final VoidCallback onOuvrirRecherche;

  const _FeedTab({required this.onOuvrirRecherche});

  @override
  State<_FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<_FeedTab> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CategorieProvider>().chargerSiNecessaire();
      context.read<PublicationProvider>().charger();
      if (context.read<AuthProvider>().estConnecte) {
        context.read<NotificationProvider>().charger();
        context.read<CorrespondanceProvider>().charger();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<PublicationProvider>().chargerPageSuivante();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final publicationProvider = context.watch<PublicationProvider>();
    final authProvider = context.watch<AuthProvider>();
    final utilisateur = authProvider.utilisateur;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: publicationProvider.rafraichir,
        color: AppColors.primary,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Barre du haut : salutation + localisation, notifications.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerPadding,
                  AppSpacing.stackLg,
                  AppSpacing.containerPadding,
                  AppSpacing.stackMd,
                ),
                child: _buildEnTete(context, utilisateur?.prenom, authProvider.estConnecte),
              ),
            ),
            SliverToBoxAdapter(child: _buildBarreRecherche(context)),
            if (!authProvider.estConnecte)
              SliverToBoxAdapter(child: _buildBoutonsInvite(context)),
            SliverToBoxAdapter(child: _buildFiltresType(publicationProvider)),
            SliverToBoxAdapter(child: _buildFiltresCategories(publicationProvider)),
            _buildListe(publicationProvider),
          ],
        ),
      ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
          border: Border.all(color: AppColors.surface, width: 4),
          boxShadow: AppShadows.medium,
        ),
        child: FloatingActionButton(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          shape: const CircleBorder(),
          onPressed: () async {
            if (!await exigerConnexion(context, message: 'Connecte-toi pour publier une annonce')) {
              return;
            }
            if (!context.mounted) return;

            final cree = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => CreatePublicationScreen(
                  categorieInitialeId: publicationProvider.categorieIdFiltre,
                ),
              ),
            );
            if (cree == true && mounted) {
              context.read<PublicationProvider>().rafraichir();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Annonce publiée avec succès !')),
              );
            }
          },
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }

  // En-tête : "Salut, {prénom} 👋" + localisation, icônes correspondances
  // et notifications à droite (cercles gris clair, petit point rouge si
  // du nouveau). Fond neutre, plus de bandeau vert plein.
  Widget _buildEnTete(BuildContext context, String? prenom, bool estConnecte) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                estConnecte ? 'Salut, ${prenom ?? ''} 👋' : 'Bienvenue sur YaKo 👋',
                style: AppTextStyles.headlineMd,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Localisation statique pour l'instant — pas encore branchée
              // sur une vraie géoloc/sélecteur de ville.
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, size: 16, color: AppColors.primary),
                  const SizedBox(width: 2),
                  Text(
                    'Lomé, Togo',
                    style: AppTextStyles.labelLg.copyWith(color: AppColors.primary),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.primary),
                ],
              ),
            ],
          ),
        ),
        Consumer<CorrespondanceProvider>(
          builder: (context, correspondanceProvider, _) {
            return _boutonIconeHaut(
              icone: Icons.compare_arrows,
              pastilleVisible: correspondanceProvider.nombreEnAttente > 0,
              tooltip: 'Correspondances possibles',
              onPressed: () async {
                if (await exigerConnexion(context, message: 'Connecte-toi pour voir tes correspondances')) {
                  if (!context.mounted) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CorrespondancesListScreen()),
                  );
                }
              },
            );
          },
        ),
        const SizedBox(width: 8),
        Consumer<NotificationProvider>(
          builder: (context, notificationProvider, _) {
            return _boutonIconeHaut(
              icone: Icons.notifications_outlined,
              pastilleVisible: notificationProvider.nombreNonLues > 0,
              onPressed: () async {
                if (await exigerConnexion(context, message: 'Connecte-toi pour voir tes notifications')) {
                  if (!context.mounted) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                }
              },
            );
          },
        ),
      ],
    );
  }

  Widget _boutonIconeHaut({
    required IconData icone,
    required bool pastilleVisible,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.surfaceContainerLow,
        shape: const CircleBorder(),
      ),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icone, color: AppColors.onSurface),
          if (pastilleVisible)
            Positioned(
              top: -1,
              right: -1,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surfaceContainerLow, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Barre de recherche : pas un vrai champ de texte, un déclencheur stylé
  // qui ouvre l'onglet Recherche (comportement inchangé, juste re-stylé).
  Widget _buildBarreRecherche(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerPadding),
      child: Material(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.input),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.input),
          onTap: widget.onOuvrirRecherche,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.input),
              border: Border.all(color: AppColors.outlineVariant, width: 2),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppColors.outline, size: 22),
                const SizedBox(width: 12),
                Text(
                  'Rechercher un objet perdu ou trouvé...',
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.outline),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBoutonsInvite(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerPadding,
        AppSpacing.stackMd,
        AppSpacing.containerPadding,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              child: const Text('Connexion'),
            ),
          ),
          const SizedBox(width: AppSpacing.stackSm),
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              ),
              child: const Text('Inscription'),
            ),
          ),
        ],
      ),
    );
  }

  // Ligne 1 : type (Tout/Perdu/Trouvé). Sélectionné = fond plein vert,
  // non sélectionné = juste un contour, fond transparent.
  Widget _buildFiltresType(PublicationProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.stackLg),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerPadding),
          children: [
            _pucheType(libelle: 'Tout', selectionne: provider.typeFiltre == null, onTap: () => provider.filtrerParType(null)),
            const SizedBox(width: AppSpacing.stackSm),
            _pucheType(libelle: 'Perdu', selectionne: provider.typeFiltre == 'PERDU', onTap: () => provider.filtrerParType('PERDU')),
            const SizedBox(width: AppSpacing.stackSm),
            _pucheType(libelle: 'Trouvé', selectionne: provider.typeFiltre == 'TROUVE', onTap: () => provider.filtrerParType('TROUVE')),
          ],
        ),
      ),
    );
  }

  Widget _pucheType({required String libelle, required bool selectionne, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selectionne ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: selectionne ? null : Border.all(color: AppColors.outlineVariant, width: 2),
        ),
        child: Text(
          libelle,
          style: AppTextStyles.labelLg.copyWith(
            color: selectionne ? AppColors.onPrimary : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  // Ligne 2 : catégories en icône + libellé (pas des puces de texte).
  Widget _buildFiltresCategories(PublicationProvider provider) {
    return Consumer<CategorieProvider>(
      builder: (context, categorieProvider, _) {
        if (categorieProvider.categories.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.stackMd, bottom: AppSpacing.stackSm),
          child: SizedBox(
            height: 84,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerPadding),
              children: [
                _iconeCategorie(
                  icone: Icons.apps,
                  libelle: 'Toutes',
                  selectionne: provider.categorieIdFiltre == null,
                  onTap: () => provider.filtrerParCategorie(null),
                ),
                ...categorieProvider.categories.map(
                  (categorie) => _iconeCategorie(
                    icone: categorie.icone != null ? iconePourCategorie(categorie.icone!) : Icons.category_outlined,
                    libelle: categorie.nom,
                    selectionne: provider.categorieIdFiltre == categorie.id,
                    onTap: () => provider.filtrerParCategorie(categorie.id),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _iconeCategorie({
    required IconData icone,
    required String libelle,
    required bool selectionne,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.stackMd),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 64,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: selectionne ? AppColors.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Icon(
                  icone,
                  color: selectionne ? AppColors.primary : AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                libelle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSm.copyWith(
                  color: selectionne ? AppColors.primary : AppColors.onSurfaceVariant,
                  fontWeight: selectionne ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListe(PublicationProvider provider) {
    if (provider.chargementInitial && provider.publications.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: PublicationFeedSkeleton(),
      );
    }

    if (provider.erreur != null && provider.publications.isEmpty) {
      return SliverFillRemaining(
        child: EmptyStateWidget(
          icone: Icons.wifi_off,
          titre: 'Impossible de charger le fil',
          message: provider.erreur,
          libelleAction: 'Réessayer',
          onAction: () => provider.rafraichir(),
        ),
      );
    }

    if (provider.publications.isEmpty) {
      return const SliverFillRemaining(
        child: EmptyStateWidget(
          icone: Icons.inventory_2_outlined,
          titre: 'Aucune publication pour le moment',
          message: 'Sois le premier à signaler un objet perdu ou trouvé.',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.only(top: AppSpacing.stackSm, bottom: 90),
      sliver: SliverList.builder(
        itemCount: provider.publications.length + (provider.aPlusDePages ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= provider.publications.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }

          final publication = provider.publications[index];
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
    );
  }
}