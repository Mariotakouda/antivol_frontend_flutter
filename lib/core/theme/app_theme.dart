// Thème AntiVole — identité graphique Togo (drapeau).
// Règle de couleurs 60/30/10 :
//  - 60% Fond      -> AppColors.background / surface
//  - 30% Structure -> AppColors.primary (Vert Forêt togolais #006A4E)
//  - 10% Accent    -> AppColors.accent  (Or togolais #FFD100)
import 'package:flutter/material.dart';

/// Couleurs officielles du drapeau togolais.
class AppColors {
  AppColors._();

  // --- Fond (60%) ---
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF3F4F5);
  static const Color surfaceContainer = Color(0xFFEDEEEF);
  static const Color surfaceContainerHigh = Color(0xFFE7E8E9);
  static const Color surfaceDim = Color(0xFFD9DADB);

  // --- Structure & Textes (30%) : Vert Forêt togolais ---
  static const Color primary = Color(0xFF006A4E);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF00543E);
  static const Color onPrimaryContainer = Color(0xFFF6FFF9);
  static const Color onSurface = Color(0xFF191C1D);
  static const Color onSurfaceVariant = Color(0xFF3D4A40);
  static const Color outline = Color(0xFF6D7A70);
  static const Color outlineVariant = Color(0xFFBCCABE);

  // --- Accent (10%) : Or togolais — CTA principal uniquement ---
  static const Color accent = Color(0xFFFFD100);
  static const Color onAccent = Color(0xFF191C1D); // texte foncé, l'or est trop clair pour du blanc
  static const Color accentContainer = Color(0xFFE6BC00);
  static const Color onAccentContainer = Color(0xFF3D2E00);

  // --- Statuts sémantiques ---
  static const Color success = primary; // Retrouvé / Validé / Vérifié
  static const Color warning = accent; // En attente / Urgent
  static const Color error = Color(0xFFD21034); // Rouge togolais — Perdu / Refuser / Supprimer
  static const Color errorContainer = Color(0xFFFFDAD9);
  static const Color onErrorContainer = Color(0xFF5C0009);

  // --- Chips de statut (fond clair 10% opacité + texte coloré) ---
  static const Color statusGreenBg = Color(0x1A006A4E);
  static const Color statusOrangeBg = Color(0x33FFD100);
  static const Color statusRedBg = Color(0x1AD21034);
}

/// Rayons de bordure (section "Shapes" de DESIGN.md).
class AppRadius {
  AppRadius._();

  static const double input = 8; // champs de formulaire
  static const double card = 20; // cartes / modales
  static const double pill = 999; // boutons
  static const double sm = 4;
  static const double md = 12;
  static const double lg = 16;
}

/// Échelle d'espacement 8px (section "Layout & Spacing").
class AppSpacing {
  AppSpacing._();

  static const double base = 8;
  static const double containerPadding = 16;
  static const double gutter = 12;
  static const double stackSm = 4;
  static const double stackMd = 16;
  static const double stackLg = 24;
}

/// Typographie Roboto.
class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Roboto';

  static const TextStyle displayLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 40 / 32,
    letterSpacing: -0.02 * 32,
    color: AppColors.primary,
  );

  static const TextStyle headlineMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 32 / 24,
    color: AppColors.primary,
  );

  static const TextStyle headlineSm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
    color: AppColors.primary,
  );

  static const TextStyle bodyLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    color: AppColors.onSurface,
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    color: AppColors.onSurface,
  );

  static const TextStyle labelLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 20 / 14,
    letterSpacing: 0.1,
    color: AppColors.onSurface,
  );

  static const TextStyle labelSm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 16 / 11,
    letterSpacing: 0.5,
    color: AppColors.onSurfaceVariant,
  );
}

/// Thème global de l'application, à brancher dans MaterialApp(theme: AppTheme.light).
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

      // Header / AppBar en vert ivoirien (30% - Structure)
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.onPrimary,
        ),
      ),

      // Bottom navigation blanche, onglet actif en vert (widget legacy
      // BottomNavigationBar)
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.outline,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Bottom navigation blanche, onglet actif en vert (widget Material 3
      // NavigationBar, utilisé dans HomeScreen)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.statusGreenBg,
        elevation: 8,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selectionne = states.contains(WidgetState.selected);
          return AppTextStyles.labelSm.copyWith(
            color: selectionne ? AppColors.primary : AppColors.outline,
            fontWeight: selectionne ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selectionne = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selectionne ? AppColors.primary : AppColors.outline,
          );
        }),
      ),

      // Bouton d'action principal (CTA) : orange ivoirien, pill-shape (10% accent)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.containerPadding,
            vertical: 14,
          ),
          textStyle: AppTextStyles.labelLg,
          elevation: 0,
        ),
      ),

      // Bouton secondaire : outline vert ivoirien (30% structure)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.containerPadding,
            vertical: 14,
          ),
          textStyle: AppTextStyles.labelLg,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.labelLg,
        ),
      ),

      // Champs de formulaire : fond gris doux, focus vert ivoirien, radius 8px
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.containerPadding,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: AppTextStyles.bodyMd,
        floatingLabelStyle: const TextStyle(color: AppColors.primary),
      ),

      // Cartes : fond blanc, radius 20px, ombre douce (Level 1)
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        margin: EdgeInsets.zero,
      ),

      // Chips de statut
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
    );
  }
}

/// Badges de statut sémantique réutilisables (Perdu / Trouvé / Validé / En attente...).
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
        bg = AppColors.statusOrangeBg;
        fg = AppColors.accent;
        break;
      case StatusType.negative:
        bg = AppColors.statusRedBg;
        fg = AppColors.error;
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