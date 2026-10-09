import 'package:flutter/material.dart';

/// Paleta de CostuSoft, tomada de la plataforma web (`LoginForm.tsx` y
/// `(auth)/layout.tsx`) para que la app y la web se vean como un solo producto.
abstract final class ColoresApp {
  // ── Marca ─────────────────────────────────────────────────────────────
  /// Verde principal: botones de acción.
  static const verde = Color(0xFF3AAD17);

  /// Verde claro: foco de campos, casillas marcadas, brillos del logo.
  static const verdeClaro = Color(0xFF49C21B);

  /// Azul marino: enlaces y encabezados.
  static const azulMarino = Color(0xFF0B3D91);
  static const azulMedio = Color(0xFF0D4FA8);
  static const azulProfundo = Color(0xFF072D6E);
  static const azulNoche = Color(0xFF041D47);

  // ── Superficies ───────────────────────────────────────────────────────
  static const fondo = Color(0xFFFFFFFF);
  static const fondoSuave = Color(0xFFF9FAFB);
  static const borde = Color(0xFFE5E7EB);
  static const bordeFuerte = Color(0xFFD1D5DB);

  // ── Textos ────────────────────────────────────────────────────────────
  /// Títulos (casi negro).
  static const textoTitulo = Color(0xFF111827);

  /// Etiquetas de campos.
  static const textoEtiqueta = Color(0xFF374151);

  /// Descripciones y textos secundarios (gris suave).
  static const textoSecundario = Color(0xFF6B7280);

  /// Iconos y textos de ayuda.
  static const textoTenue = Color(0xFF9CA3AF);

  // ── Estados ───────────────────────────────────────────────────────────
  static const error = Color(0xFFDC2626);
  static const errorObligatorio = Color(0xFFEF4444);
  static const errorFondo = Color(0xFFFEF2F2);
  static const errorBorde = Color(0xFFFECACA);
  static const infoFondo = Color(0xFFEFF6FF);
  static const infoBorde = Color(0xFFBFDBFE);
  static const exitoFondo = Color(0xFFF0FDF4);
  static const exitoBorde = Color(0xFFBBF7D0);
  static const exitoIcono = Color(0xFF16A34A);
  static const exitoTitulo = Color(0xFF166534);
  static const exitoTexto = Color(0xFF15803D);
  static const infoBordeSuave = Color(0xFFDBEAFE);

  // ── Estado del stock (InventarioClient.tsx) ───────────────────────────
  static const disponibleFondo = Color(0xFFF0FDF4);
  static const disponibleTexto = Color(0xFF16A34A);
  static const disponiblePunto = Color(0xFF22C55E);
  static const stockBajoFondo = Color(0xFFFFFBEB);
  static const stockBajoTexto = Color(0xFFB45309);
  static const stockBajoPunto = Color(0xFFF59E0B);
  static const sinStockFondo = Color(0xFFFEF2F2);
  static const sinStockTexto = Color(0xFFDC2626);
  static const sinStockPunto = Color(0xFFEF4444);

  // ── Semáforo de riesgo del modelo XGBoost (mismos tonos que la web) ───
  static const riesgoBajo = Color(0xFF16A34A);
  static const riesgoMedio = Color(0xFFF59E0B);
  static const riesgoAlto = Color(0xFFDC2626);
  static const riesgoCritico = Color(0xFF991B1B);
  static const riesgoDesconocido = Color(0xFF9CA3AF);
}
