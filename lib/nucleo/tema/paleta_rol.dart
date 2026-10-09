import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../modulos/autenticacion/dominio/estado_sesion.dart';
import '../../modulos/autenticacion/dominio/rol_usuario.dart';
import '../../modulos/autenticacion/presentacion/controlador_sesion.dart';
import 'colores_app.dart';

/// Colores de cada rol, tomados de la plataforma web (sidebar, topbar y fondo
/// de cada panel: `components/<rol>/layout/*Sidebar.tsx` y `*Topbar.tsx`).
class PaletaRol {
  const PaletaRol({
    required this.nombre,
    required this.degradado,
    required this.paradas,
    required this.degradadoEncabezado,
    required this.brillo,
    required this.navegacion,
    required this.acento,
    required this.indicador,
    required this.acentoSuave,
    required this.fondo,
  });

  /// Subtítulo de la marca en la web ("Control", "Bodega"…).
  final String nombre;

  /// Degradado vertical del sidebar (de arriba a abajo) y sus paradas.
  final List<Color> degradado;
  final List<double> paradas;

  /// Degradado diagonal del encabezado del inicio: del tono vivo del rol a su
  /// tono profundo, como el encabezado azul del administrador.
  final List<Color> degradadoEncabezado;

  /// Brillo decorativo en la esquina del encabezado.
  final Color brillo;

  /// Pestaña activa de la barra inferior.
  final Color navegacion;

  /// Color principal del rol (íconos y textos activos del topbar).
  final Color acento;

  /// Indicador de la opción activa en el sidebar.
  final Color indicador;

  /// Fondo suave del acento (chip del topbar).
  final Color acentoSuave;

  /// Fondo de las páginas del panel.
  final Color fondo;

  static const administrador = PaletaRol(
    nombre: 'Control',
    degradado: [Color(0xFF0B3D91), Color(0xFF072D6E), Color(0xFF041D47)],
    paradas: [0, 0.6, 1],
    degradadoEncabezado: [ColoresApp.azulMedio, ColoresApp.azulMarino, ColoresApp.azulProfundo],
    brillo: ColoresApp.verdeClaro,
    navegacion: ColoresApp.verde,
    acento: Color(0xFF0B3D91),
    indicador: Color(0xFF49C21B),
    acentoSuave: Color(0xFFF0F5FF),
    fondo: Color(0xFFF5F6FA),
  );

  static const usuario = PaletaRol(
    nombre: 'Secretaria',
    degradado: [Color(0xFF0F172A), Color(0xFF172554), Color(0xFF1D4ED8)],
    paradas: [0, 0.55, 1],
    degradadoEncabezado: [Color(0xFF1D4ED8), Color(0xFF1E3A8A), Color(0xFF172554)],
    brillo: Color(0xFF60A5FA),
    navegacion: Color(0xFF1D4ED8),
    acento: Color(0xFF1D4ED8),
    indicador: Color(0xFF60A5FA),
    acentoSuave: Color(0xFFEFF6FF),
    fondo: Color(0xFFF5F7FB),
  );

  static const bodega = PaletaRol(
    nombre: 'Bodega',
    degradado: [Color(0xFF14532D), Color(0xFF166534), Color(0xFF052E16)],
    paradas: [0, 0.45, 1],
    degradadoEncabezado: [Color(0xFF15803D), Color(0xFF166534), Color(0xFF14532D)],
    brillo: Color(0xFF86EFAC),
    navegacion: Color(0xFF15803D),
    acento: Color(0xFF15803D),
    indicador: Color(0xFF86EFAC),
    acentoSuave: Color(0xFFF0FDF4),
    fondo: Color(0xFFF4F8F4),
  );

  static const institucion = PaletaRol(
    nombre: 'Portal Institucional',
    degradado: [Color(0xFF065F73), Color(0xFF0E7490), Color(0xFF06485E)],
    paradas: [0, 0.6, 1],
    degradadoEncabezado: [Color(0xFF0891B2), Color(0xFF0E7490), Color(0xFF065F73)],
    brillo: Color(0xFF22D3EE),
    navegacion: Color(0xFF0891B2),
    acento: Color(0xFF0891B2),
    indicador: Color(0xFF22D3EE),
    acentoSuave: Color(0xFFECF9FC),
    fondo: Color(0xFFF5F6FA),
  );

  static PaletaRol de(RolUsuario rol) => switch (rol) {
    RolUsuario.administrador => administrador,
    RolUsuario.usuario => usuario,
    RolUsuario.bodega => bodega,
    RolUsuario.institucion => institucion,
  };
}

/// Paleta del rol con sesión activa (la del administrador si no hay sesión).
final proveedorPaletaRol = Provider<PaletaRol>((ref) {
  final sesion = ref.watch(proveedorSesion);
  return sesion is SesionActiva ? PaletaRol.de(sesion.usuario.rol) : PaletaRol.administrador;
});
