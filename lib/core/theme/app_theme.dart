// Thème AntiVole/YaKo — reconstruit à partir du design system Stitch
// (stitch_yako_design_system, "Modern West African Connectivity").
// C'est désormais la RÉFÉRENCE UNIQUE : toutes les valeurs ci-dessous sont
// copiées depuis les fichiers DESIGN.md / code.html fournis par les
// maquettes, pas inventées ni ajustées à l'oeil.
//
// Rôle des couleurs (différent de l'ancien système "60/30/10 or togolais") :
//  - Vert Forêt (primary)  -> CTA principal partout (boutons, nav active,
//    FAB, AppBar title). C'est la couleur d'action, pas seulement de
//    structure.
//  - Corail/Rouille (secondary/accent) -> réservé au sémantique "Perdu" /
//    urgence (badges, bouton "Signaler un objet perdu").
//  - Or/Olive (tertiary/reward) -> récompenses uniquement.
//  - Fond quasi blanc, à peine teinté (#FCF9F8), pas un gris froid.
import 'package:flutter/material.dart';

/// Palette exacte du design system Stitch (section `colors` de DESIGN.md).
class AppColors {
  AppColors._();

  // --- Surfaces : blanc chaud à peine teinté, presque neutre ---
  static const Color background = Color(0xFFFCF9F8); // "surface" Stitch
  static const Color surface = Color(0xFFFFFFFF); // "surface-container-lowest" -> cartes
  static const Color surfaceContainerLow = Color(0xFFF6F3F2);
  static const Color surfaceContainer = Color(0xFFF0EDEC);
  static const Color surfaceContainerHigh = Color(0xFFEBE7E7);
  static const Color surfaceDim = Color(0xFFDCD9D9);

  // --- Vert Forêt : couleur d'ACTION principale (pas juste structure) ---
  static const Color primary = Color(0xFF006A38);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF008649);
  static const Color onPrimaryContainer = Color(0xFFF6FFF4);
  // Couleur de survol/pression (surface-tint dans Stitch)
  static const Color primaryHover = Color(0xFF006D3A);

  // --- Texte & structure ---
  // Stitch n'a qu'une seule couleur de texte foncé (on-surface) ; l'ancien
  // "ink" distinct est conservé comme alias pour ne pas casser les écrans
  // existants, mais pointe vers la même valeur.
  static const Color onSurface = Color(0xFF1C1B1B);
  static const Color ink = onSurface;
  static const Color onSurfaceVariant = Color(0xFF3E4A3F);
  static const Color outline = Color(0xFF6E7A6F);
  static const Color outlineVariant = Color(0xFFBDCABD);

  // --- Corail/Rouille : sémantique "Perdu" / urgence uniquement ---
  // (secondary dans Stitch — PAS un accent CTA général)
  static const Color accent = Color(0xFFA43C12);
  static const Color onAccent = Color(0xFFFFFFFF);
  static const Color accentContainer = Color(0xFFFE7E4F);
  static const Color onAccentContainer = Color(0xFF6B1F00);

  // --- Or/Olive : récompenses uniquement (tertiary dans Stitch) ---
  static const Color reward = Color(0xFF705D00);
  static const Color rewardContainer = Color(0xFFC9A900);
  static const Color onRewardContainer = Color(0xFF4C3E00);
  static const Color rewardBg = Color(0x26C9A900);

  // --- Erreur (valeur propre définie par Stitch) ---
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // --- Statuts sémantiques ---
  static const Color success = primary; // Retrouvé / Validé / Vérifié
  static const Color warning = reward; // En attente
  // "Perdu" utilise le corail (accent), pas le rouge d'erreur.

  // --- Chips / tints de statut ---
  static const Color statusGreenBg = Color(0x1F006A38);
  static const Color statusOrangeBg = Color(0x26A43C12); // tint corail (Perdu)
  static const Color statusRedBg = Color(0x1FBA1A1A); // tint erreur (destructif)
}

/// Rayons de bordure — voir section "Shapes" de DESIGN.md : composants
/// standards (boutons, champs) 16px, cartes 24px, badges pill.
/// IMPORTANT : chez Stitch les boutons NE sont PAS en pill, contrairement à
/// l'ancien thème — ils ont un radius de 16px comme les champs de saisie.
class AppRadius {
  AppRadius._();

  static const double input = 16; // champs de formulaire ET boutons
  static const double button = 16;
  static const double card = 24; // cartes / bottom sheets
  static const double pill = 999; // badges / chips uniquement
  static const double sm = 4;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

/// Échelle d'espacement — section "Layout & Spacing" de DESIGN.md, unité 4px.
class AppSpacing {
  AppSpacing._();

  static const double base = 4; // "unit" Stitch
  static const double xs = 4;
  static const double stackSm = 8; // "sm"
  static const double stackMd = 16; // "md"
  static const double stackLg = 24; // "lg"
  static const double stackXl = 32; // "xl"
  static const double containerPadding = 20; // marges latérales mobile
  static const double gutter = 12; // "stack-gap" — écart interne row/liste
}

/// Ombres — section "Elevation & Depth" de DESIGN.md : pas d'ombre noire
/// dure, mais un halo diffus (20-30px de flou), très faible opacité (~10%),
/// teinté avec la couleur primaire plutôt que du noir pur.
class AppShadows {
  AppShadows._();

  static List<BoxShadow> soft = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> medium = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.12),
      blurRadius: 30,
      offset: const Offset(0, 8),
    ),
  ];
}

/// Typographie — une seule famille, **Quicksand**, sur tous les niveaux
/// (section "typography" de DESIGN.md). Les tailles/graisses ci-dessous
/// sont copiées telles quelles depuis les tokens Stitch.
class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Quicksand';
  // Alias conservé pour compatibilité — pointe vers la même police.
  static const String displayFontFamily = fontFamily;

  // display-lg-mobile (28/36, w700) — variante mobile du display-lg (32/40),
  // utilisée pour les titres héros (splash, écrans de succès).
  static const TextStyle displayLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 36 / 28,
    letterSpacing: -0.4,
    color: AppColors.onSurface,
  );

  // headline-lg (24/32, w700) — grands titres d'écran ("Content de te revoir")
  static const TextStyle headlineLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 32 / 24,
    color: AppColors.onSurface,
  );

  // headline-md (20/28, w700) — titres d'AppBar, sections
  static const TextStyle headlineMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 28 / 20,
    color: AppColors.onSurface,
  );

  // Pas de "headline-sm" dans Stitch ; taille intermédiaire pragmatique
  // pour les sous-titres de section, même famille/graisse.
  static const TextStyle headlineSm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 24 / 18,
    color: AppColors.onSurface,
  );

  // body-lg (18/26, w500)
  static const TextStyle bodyLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 26 / 18,
    color: AppColors.onSurface,
  );

  // body-md (16/24, w400) — taille de lecture standard Stitch
  static const TextStyle bodyMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    color: AppColors.onSurface,
  );

  // label-bold (14/20, w700)
  static const TextStyle labelLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 20 / 14,
    letterSpacing: 0.1,
    color: AppColors.onSurface,
  );

  // label-sm (12/16, w600)
  static const TextStyle labelSm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 16 / 12,
    letterSpacing: 0.2,
    color: AppColors.onSurfaceVariant,
  );
}

/// Thème global — à brancher dans MaterialApp(theme: AppTheme.light).
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.accent,
      onSecondary: AppColors.onAccent,
      secondaryContainer: AppColors.accentContainer,
      onSecondaryContainer: AppColors.onAccentContainer,
      tertiary: AppColors.reward,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.rewardContainer,
      onTertiaryContainer: AppColors.onRewardContainer,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      error: AppColors.error,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppTextStyles.fontFamily,
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.displayLg,
        headlineLarge: AppTextStyles.headlineLg,
        headlineMedium: AppTextStyles.headlineMd,
        headlineSmall: AppTextStyles.headlineSm,
        bodyLarge: AppTextStyles.bodyLg,
        bodyMedium: AppTextStyles.bodyMd,
        labelLarge: AppTextStyles.labelLg,
        labelSmall: AppTextStyles.labelSm,
      ),

      // AppBar : fond clair (pas vert plein comme avant), titre en vert.
      // Cf. header des maquettes ("bg-surface" + titre "text-primary").
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onSurfaceVariant, // icônes
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
        iconTheme: const IconThemeData(color: AppColors.onSurfaceVariant),
      ),

      // Bottom navigation legacy (BottomNavigationBar)
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.outline,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Bottom navigation (NavigationBar M3) : indicateur pill vert plein
      // derrière l'onglet actif, comme dans les maquettes.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary,
        indicatorShape: const StadiumBorder(),
        elevation: 8,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selectionne = states.contains(WidgetState.selected);
          return AppTextStyles.labelSm.copyWith(
            color: selectionne ? AppColors.onPrimary : AppColors.outline,
            fontWeight: selectionne ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selectionne = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selectionne ? AppColors.onPrimary : AppColors.outline,
          );
        }),
      ),

      // Bouton principal : vert plein, texte blanc, radius 16 (PAS pill —
      // cf. code Stitch "rounded-[16px]" sur le bouton "Se connecter").
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
          disabledForegroundColor: AppColors.onPrimary.withValues(alpha: 0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.containerPadding,
            vertical: 16,
          ),
          textStyle: AppTextStyles.headlineSm,
          elevation: 0,
        ).copyWith(
          overlayColor: WidgetStateProperty.all(AppColors.primaryHover.withValues(alpha: 0.1)),
        ),
      ),

      // Bouton "Ghost" : bordure verte 2px, fond transparent, même radius.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.containerPadding,
            vertical: 16,
          ),
          textStyle: AppTextStyles.headlineSm,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.labelLg,
        ),
      ),

      // Champs de formulaire : fond blanc, bordure 2px visible en permanence
      // (gris clair au repos, vert au focus), radius 16 — PAS un simple fond
      // gris sans bordure comme avant.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.containerPadding,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.outlineVariant, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.outlineVariant, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        floatingLabelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
        hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.outline),
      ),

      // Cartes : radius 24px, pas d'ombre dure (voir AppShadows).
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        margin: EdgeInsets.zero,
      ),

      // Chips / badges : toujours pill.
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.statusGreenBg,
        labelStyle: AppTextStyles.labelSm.copyWith(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        side: BorderSide.none,
      ),

      iconTheme: const IconThemeData(color: AppColors.primary),

      dividerTheme: DividerThemeData(
        color: AppColors.outlineVariant.withValues(alpha: 0.5),
        thickness: 1,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
      ),
    );
  }
}

/// Badges de statut sémantique (Perdu / Trouvé / Validé / En attente...).
/// Usage : StatusBadge(label: 'Perdu', type: StatusType.negative)
enum StatusType { positive, warning, negative }

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.type});

  final String label;
  final StatusType type;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    switch (type) {
      case StatusType.positive:
        bg = AppColors.statusGreenBg;
        fg = AppColors.primary;
        break;
      case StatusType.warning:
        bg = AppColors.rewardBg;
        fg = AppColors.reward;
        break;
      case StatusType.negative:
        bg = AppColors.statusOrangeBg;
        fg = AppColors.accent;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.labelSm.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
