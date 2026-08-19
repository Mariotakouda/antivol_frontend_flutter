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
            // Barre du haut (logo + correspondances/notifications) :
            // disparaît en scrollant vers le bas, réapparaît instantanément
            // dès qu'on scrolle vers le haut, même très légèrement.
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: AppColors.surface,
              elevation: 0,
              automaticallyImplyLeading: false,
              toolbarHeight: 100, // le logo fait 90px de haut, + marge
              titleSpacing: 0,
              title: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerPadding),
                child: _buildBarreHaut(),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildCarteVerte(context, utilisateur?.prenom, authProvider.estConnecte),
            ),
            SliverToBoxAdapter(child: _buildFiltreType(publicationProvider)),
            SliverToBoxAdapter(child: _buildFiltreCategories(publicationProvider)),
            _buildListe(publicationProvider),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
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
        icon: const Icon(Icons.add),
        label: const Text('Publier'),
      ),
    );
  }

  // Barre du haut (logo + icônes correspondances/notifications). Pas de
  // SafeArea ici : le SliverAppBar qui l'englobe gère déjà l'espace sous
  // la barre de statut automatiquement.
  Widget _buildBarreHaut() {
    return Row(
      children: [
        const _YaKoWordmark(),
        const Spacer(),
        Consumer<CorrespondanceProvider>(
          builder: (context, correspondanceProvider, _) {
            final enAttente = correspondanceProvider.nombreEnAttente;
            return IconButton(
              icon: Badge(
                isLabelVisible: enAttente > 0,
                label: Text('$enAttente'),
                backgroundColor: AppColors.accent,
                child: const Icon(Icons.compare_arrows, color: AppColors.primary),
              ),
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
        Consumer<NotificationProvider>(
          builder: (context, notificationProvider, _) {
            final nonLues = notificationProvider.nombreNonLues;
            return IconButton(
              icon: Badge(
                isLabelVisible: nonLues > 0,
                label: Text('$nonLues'),
                backgroundColor: AppColors.accent,
                child: const Icon(Icons.notifications_outlined, color: AppColors.primary),
              ),
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

  // Carte verte arrondie : salutation (si connecté), recherche, et
  // boutons Connexion/Inscription (si invité). Fait défiler normalement
  // avec le reste du contenu (pas de comportement flottant ici).
  Widget _buildCarteVerte(BuildContext context, String? prenom, bool estConnecte) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.stackSm),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.containerPadding),
        padding: const EdgeInsets.all(AppSpacing.gutter),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (estConnecte) ...[
              Text(
                'Bonjour, ${prenom ?? ''}',
                style: AppTextStyles.headlineSm.copyWith(color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.stackSm),
            ],
            Material(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                onTap: widget.onOuvrirRecherche,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.white.withValues(alpha: 0.85), size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Rechercher un objet...',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (!estConnecte) ...[
              const SizedBox(height: AppSpacing.stackSm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 1.5),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                      ),
                      child: const Text('Inscription'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFiltreType(PublicationProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerPadding,
        AppSpacing.stackMd,
        AppSpacing.containerPadding,
        AppSpacing.stackMd,
      ),
      // Segmented control : fond gris clair, onglet actif en carte blanche
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            _segmentType(provider, null, 'Tout'),
            _segmentType(provider, 'PERDU', 'Perdu'),
            _segmentType(provider, 'TROUVE', 'Trouvé'),
          ],
        ),
      ),
    );
  }

  Widget _segmentType(PublicationProvider provider, String? type, String libelle) {
    final selectionne = provider.typeFiltre == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => provider.filtrerParType(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selectionne ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm + 4),
            boxShadow: selectionne
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)]
                : null,
          ),
          child: Text(
            libelle,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelLg.copyWith(
              color: selectionne ? AppColors.primary : AppColors.onSurfaceVariant,
              fontWeight: selectionne ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFiltreCategories(PublicationProvider provider) {
    return Consumer<CategorieProvider>(
      builder: (context, categorieProvider, _) {
        if (categorieProvider.categories.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.containerPadding),
            children: [
              _puceCategorie(provider, null, 'Toutes', null),
              const SizedBox(width: AppSpacing.stackSm),
              ...categorieProvider.categories.map(
                (categorie) => Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.stackSm),
                  child: _puceCategorie(provider, categorie.id, categorie.nom, categorie.icone),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _puceCategorie(PublicationProvider provider, int? id, String libelle, String? icone) {
    final selectionne = provider.categorieIdFiltre == id;
    return GestureDetector(
      onTap: () => provider.filtrerParCategorie(id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selectionne ? AppColors.statusGreenBg : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selectionne ? AppColors.primary.withValues(alpha: 0.3) : AppColors.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icone != null ? iconePourCategorie(icone) : Icons.apps,
              size: 16,
              color: selectionne ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              libelle,
              style: AppTextStyles.labelLg.copyWith(
                color: selectionne ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListe(PublicationProvider provider) {
    if (provider.chargementInitial && provider.publications.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
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

/// Logo YaKo utilisé dans l'en-tête de l'accueil (le vrai fichier image,
/// pas un texte stylisé).
class _YaKoWordmark extends StatelessWidget {
  const _YaKoWordmark();

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      // Décale le logo vers la gauche pour compenser la marge restante
      // dans le fichier image. Ajuste la valeur (en pixels) au besoin.
      offset: const Offset(-8, 0),
      child: Image.asset(
        'assets/images/logo1.png',
        height: 78,
        fit: BoxFit.contain,
      ),
    );
  }
}