import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette "Ocre & Atlantique" : couleurs chaudes et terreuses inspirées de
/// Dakar (terre cuite, sable, ocre) associées au bleu de l'océan Atlantique.
/// Volontairement éloignée du bleu/violet Material par défaut.
class AppColors {
  AppColors._();

  /// Couleur primaire : terre cuite, utilisée pour les actions principales.
  static const Color terracotta = Color(0xFFB54A24);

  /// Ocre doré décoratif (fonds de badges, chips non sélectionnées).
  static const Color ocreSable = Color(0xFFD9A441);

  /// Version foncée de l'ocre, utilisée quand le texte doit rester lisible.
  static const Color ocreProfond = Color(0xFF96631C);

  /// Bleu atlantique : couleur tertiaire, pour l'information et l'eau.
  static const Color bleuAtlantique = Color(0xFF1D6E7A);

  /// Vert baobab : succès, disponibilité.
  static const Color vertBaobab = Color(0xFF4C7A4C);

  /// Rouille : alerte modérée (occupation élevée).
  static const Color rouilleAlerte = Color(0xFFA84A22);

  /// Brique : alerte forte (occupation complète).
  static const Color briqueSature = Color(0xFF8C2F2F);

  /// Fond général de l'application (sable clair).
  static const Color sableClair = Color(0xFFF5EEE1);

  /// Fond des cartes et surfaces surélevées (légèrement plus clair).
  static const Color sableCarte = Color(0xFFFBF6EC);

  /// Teinte utilisée pour les séparateurs et bordures discrètes.
  static const Color sableBordure = Color(0xFFE4D5B7);

  /// Texte principal : brun charbon chaud (jamais noir pur).
  static const Color charbonChaud = Color(0xFF2B221B);
}

/// Thème visuel de l'application : identité organique ancrée dans le
/// contexte de Dakar (palette terreuse, typographie de caractère, coins
/// arrondis naturels). Centralisé ici pour rester facile à ajuster.
class AppTheme {
  AppTheme._();

  static final ColorScheme _lightScheme = const ColorScheme.light().copyWith(
    primary: AppColors.terracotta,
    onPrimary: Colors.white,
    primaryContainer: AppColors.terracotta.withValues(alpha: 0.12),
    onPrimaryContainer: AppColors.terracotta,
    secondary: AppColors.ocreProfond,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.ocreSable.withValues(alpha: 0.22),
    onSecondaryContainer: AppColors.ocreProfond,
    tertiary: AppColors.bleuAtlantique,
    onTertiary: Colors.white,
    tertiaryContainer: AppColors.bleuAtlantique.withValues(alpha: 0.14),
    onTertiaryContainer: AppColors.bleuAtlantique,
    error: AppColors.briqueSature,
    onError: Colors.white,
    surface: AppColors.sableCarte,
    onSurface: AppColors.charbonChaud,
    surfaceContainerHighest: const Color(0xFFEFE3CE),
    onSurfaceVariant: AppColors.charbonChaud.withValues(alpha: 0.72),
    outline: AppColors.sableBordure,
    outlineVariant: AppColors.sableBordure.withValues(alpha: 0.6),
    shadow: AppColors.charbonChaud,
  );

  /// Construit la typographie : Fraunces (serif de caractère) pour les
  /// titres et noms de ligne, Manrope (chaleureuse et lisible) pour le
  /// corps de texte — à la place d'Inter/Roboto par défaut.
  static TextTheme _buildTextTheme(TextTheme base) {
    final bodyTheme = GoogleFonts.manropeTextTheme(base);

    TextStyle display(TextStyle? style, {FontWeight weight = FontWeight.w600}) =>
        GoogleFonts.fraunces(textStyle: style, fontWeight: weight);

    return bodyTheme.copyWith(
      displayLarge: display(bodyTheme.displayLarge, weight: FontWeight.w700),
      displayMedium: display(bodyTheme.displayMedium, weight: FontWeight.w700),
      displaySmall: display(bodyTheme.displaySmall),
      headlineLarge: display(bodyTheme.headlineLarge),
      headlineMedium: display(bodyTheme.headlineMedium),
      headlineSmall: display(bodyTheme.headlineSmall),
      titleLarge: display(bodyTheme.titleLarge),
      titleMedium: display(bodyTheme.titleMedium, weight: FontWeight.w600),
    );
  }

  static ThemeData get light {
    final base = ThemeData(brightness: Brightness.light, useMaterial3: true);
    final textTheme = _buildTextTheme(base.textTheme).apply(
      bodyColor: AppColors.charbonChaud,
      displayColor: AppColors.charbonChaud,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: _lightScheme,
      scaffoldBackgroundColor: AppColors.sableClair,
      textTheme: textTheme,
      fontFamily: GoogleFonts.manrope().fontFamily,
      splashColor: AppColors.terracotta.withValues(alpha: 0.08),
      highlightColor: AppColors.terracotta.withValues(alpha: 0.04),

      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.charbonChaud,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: AppColors.charbonChaud),
      ),

      // Coins arrondis naturels, ombre chaude discrète plutôt que du flat
      // design pur : les cartes ont un léger relief.
      cardTheme: CardThemeData(
        elevation: 3,
        color: AppColors.sableCarte,
        shadowColor: AppColors.charbonChaud.withValues(alpha: 0.25),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.terracotta,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.terracotta.withValues(alpha: 0.35),
          minimumSize: const Size(48, 48),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.terracotta,
          minimumSize: const Size(48, 48),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.sableCarte,
        selectedColor: AppColors.terracotta,
        disabledColor: AppColors.sableBordure,
        labelStyle: textTheme.labelLarge!,
        secondaryLabelStyle: textTheme.labelLarge!.copyWith(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.sableCarte,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.charbonChaud.withValues(alpha: 0.45),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.terracotta, width: 1.5),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: AppColors.charbonChaud.withValues(alpha: 0.08),
        space: 32,
        thickness: 1,
      ),

      iconTheme: const IconThemeData(color: AppColors.charbonChaud),

      listTileTheme: ListTileThemeData(
        iconColor: AppColors.charbonChaud.withValues(alpha: 0.7),
        minVerticalPadding: 14,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.sableCarte,
        surfaceTintColor: Colors.transparent,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.sableCarte,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
