import 'package:flutter/material.dart';

import 'colores_app.dart';

/// Tema de la app: fondo blanco, Poppins, verde para las acciones y azul
/// marino para enlaces, igual que la plataforma web.
abstract final class TemaApp {
  static const fuente = 'Poppins';

  /// Radio de esquinas de campos, botones y tarjetas.
  static const radio = 12.0;

  static ThemeData get claro {
    const colores = ColorScheme(
      brightness: Brightness.light,
      primary: ColoresApp.verde,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE3F6DA),
      onPrimaryContainer: Color(0xFF1C5A0A),
      secondary: ColoresApp.azulMarino,
      onSecondary: Colors.white,
      secondaryContainer: ColoresApp.infoFondo,
      onSecondaryContainer: ColoresApp.azulMarino,
      error: ColoresApp.error,
      onError: Colors.white,
      errorContainer: ColoresApp.errorFondo,
      onErrorContainer: ColoresApp.error,
      surface: ColoresApp.fondo,
      onSurface: ColoresApp.textoTitulo,
      onSurfaceVariant: ColoresApp.textoSecundario,
      surfaceContainerLowest: ColoresApp.fondo,
      surfaceContainerLow: ColoresApp.fondoSuave,
      surfaceContainer: ColoresApp.fondoSuave,
      surfaceContainerHigh: Color(0xFFF3F4F6),
      surfaceContainerHighest: Color(0xFFE5E7EB),
      outline: ColoresApp.bordeFuerte,
      outlineVariant: ColoresApp.borde,
    );

    final bordes = BorderRadius.circular(radio);
    OutlineInputBorder borde(Color color, [double ancho = 1.5]) => OutlineInputBorder(
      borderRadius: bordes,
      borderSide: BorderSide(color: color, width: ancho),
    );

    final base = ThemeData(useMaterial3: true, colorScheme: colores, fontFamily: fuente);
    final textos = base.textTheme.apply(
      fontFamily: fuente,
      bodyColor: ColoresApp.textoTitulo,
      displayColor: ColoresApp.textoTitulo,
    );

    return base.copyWith(
      scaffoldBackgroundColor: ColoresApp.fondo,
      textTheme: textos,
      appBarTheme: AppBarTheme(
        backgroundColor: ColoresApp.fondo,
        foregroundColor: ColoresApp.textoTitulo,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: textos.titleLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 20),
      ),
      dividerTheme: const DividerThemeData(color: ColoresApp.borde, space: 1),
      cardTheme: CardThemeData(
        elevation: 0,
        color: ColoresApp.fondo,
        shape: RoundedRectangleBorder(
          borderRadius: bordes,
          side: const BorderSide(color: ColoresApp.borde),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColoresApp.fondo,
        hintStyle: const TextStyle(color: ColoresApp.textoTenue),
        prefixIconColor: ColoresApp.textoTenue,
        suffixIconColor: ColoresApp.textoTenue,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: borde(ColoresApp.borde),
        enabledBorder: borde(ColoresApp.borde),
        disabledBorder: borde(ColoresApp.borde),
        focusedBorder: borde(ColoresApp.verdeClaro, 1.8),
        errorBorder: borde(ColoresApp.errorObligatorio),
        focusedErrorBorder: borde(ColoresApp.error, 1.8),
        errorStyle: const TextStyle(color: ColoresApp.error, fontSize: 12),
      ),
      filledButtonTheme: FilledButtonThemeData(
        // Alto cómodo para el dedo; el ancho lo decide cada pantalla.
        style: FilledButton.styleFrom(
          backgroundColor: ColoresApp.verde,
          foregroundColor: Colors.white,
          // Deshabilitado = gris, para que no parezca que se puede tocar.
          disabledBackgroundColor: ColoresApp.borde,
          disabledForegroundColor: ColoresApp.textoTenue,
          minimumSize: const Size(64, 50),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: bordes),
          textStyle: const TextStyle(fontFamily: fuente, fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 50),
          shape: RoundedRectangleBorder(borderRadius: bordes),
          side: const BorderSide(color: ColoresApp.borde, width: 1.5),
          textStyle: const TextStyle(fontFamily: fuente, fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ColoresApp.azulMarino,
          textStyle: const TextStyle(fontFamily: fuente, fontWeight: FontWeight.w500),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.selected) ? ColoresApp.verdeClaro : ColoresApp.fondo,
        ),
        side: const BorderSide(color: ColoresApp.bordeFuerte, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: ColoresApp.verde),
      chipTheme: base.chipTheme.copyWith(
        side: const BorderSide(color: ColoresApp.borde),
        labelStyle: const TextStyle(fontFamily: fuente, color: ColoresApp.textoEtiqueta, fontSize: 13),
        backgroundColor: ColoresApp.fondoSuave,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ColoresApp.fondo,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: textos.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ColoresApp.fondo,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        // Compacta: Bodega y Administrador tienen 5 pestañas con nombres largos.
        height: 64,
        elevation: 0,
        backgroundColor: ColoresApp.fondo,
        surfaceTintColor: Colors.transparent,
        indicatorColor: ColoresApp.verde.withValues(alpha: 0.14),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (estados) => IconThemeData(
            size: 22,
            color: estados.contains(WidgetState.selected) ? ColoresApp.verde : ColoresApp.textoTenue,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (estados) => TextStyle(
            fontFamily: fuente,
            fontSize: 11,
            letterSpacing: 0,
            // Sin negrita: el color del rol ya marca la pestaña activa.
            fontWeight: estados.contains(WidgetState.selected) ? FontWeight.w500 : FontWeight.w400,
            color: estados.contains(WidgetState.selected) ? ColoresApp.verde : ColoresApp.textoSecundario,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ColoresApp.textoTitulo,
        contentTextStyle: const TextStyle(fontFamily: fuente, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: bordes),
      ),
    );
  }
}
