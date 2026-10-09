import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../modulos/autenticacion/dominio/estado_sesion.dart';
import '../../modulos/autenticacion/presentacion/controlador_sesion.dart';
import '../../nucleo/rutas/rutas_app.dart';
import '../../nucleo/tema/paleta_rol.dart';
import '../../nucleo/utilidades/formatos.dart';
import 'avatar_usuario.dart';

/// Encabezado del inicio de cada rol: fecha, saludo, avatar (lleva al perfil),
/// un chip de estado y una fila de cifras, sobre el degradado del rol.
///
/// Cada rol tiene su color, como en la plataforma web: azul el administrador,
/// azul real Secretaría, verde Bodega y turquesa Institución.
class EncabezadoRol extends ConsumerWidget {
  const EncabezadoRol({super.key, required this.estado, this.cifras = const []});

  /// Chip bajo el saludo (p. ej. "Todo en orden").
  final ChipEncabezado estado;

  /// Cifras destacadas; si está vacía no se muestra la fila.
  final List<CifraEncabezado> cifras;

  String get _saludo {
    final hora = DateTime.now().hour;
    if (hora < 12) return 'Buenos días';
    if (hora < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(proveedorSesion);
    final usuario = sesion is SesionActiva ? sesion.usuario : null;
    final fecha = DateFormat("EEEE, d 'de' MMMM", 'es_CO').format(DateTime.now());

    return FondoRol(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fecha[0].toUpperCase() + fecha.substring(1),
                          style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$_saludo, ${usuario?.nombreUsuario ?? ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  if (usuario != null)
                    GestureDetector(
                      onTap: () => context.go(RutasApp.perfilDe(usuario.rol)),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                        child: AvatarUsuario(usuario: usuario, radio: 22),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              estado,
              if (cifras.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    for (var i = 0; i < cifras.length; i++) ...[
                      if (i > 0) Container(width: 1, height: 32, color: Colors.white24),
                      Expanded(child: cifras[i]),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Degradado del rol con su brillo en la esquina y bordes inferiores
/// redondeados. Lo comparten el encabezado del inicio y la portada del perfil.
class FondoRol extends ConsumerWidget {
  const FondoRol({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paleta = ref.watch(proveedorPaletaRol);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: paleta.degradadoEncabezado,
          stops: const [0, 0.5, 1],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          // Brillo decorativo, como en el domo del login.
          Positioned(
            right: -60,
            top: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [paleta.brillo.withValues(alpha: 0.28), paleta.brillo.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Píldora translúcida con un ícono de color y un texto corto.
class ChipEncabezado extends StatelessWidget {
  const ChipEncabezado({super.key, required this.icono, required this.colorIcono, required this.texto});

  /// Chip mientras cargan los datos.
  const ChipEncabezado.cargando({super.key, required this.texto})
    : icono = Icons.hourglass_empty_rounded,
      colorIcono = Colors.white70;

  final IconData icono;
  final Color colorIcono;
  final String texto;

  /// Ámbar para los avisos, legible sobre cualquier degradado de rol.
  static const colorAlerta = Color(0xFFFCD34D);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 16, color: colorIcono),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              texto,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

/// Número grande con su etiqueta; `null` muestra un guion mientras carga.
class CifraEncabezado extends StatelessWidget {
  const CifraEncabezado({super.key, required this.valor, required this.etiqueta});

  final int? valor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          valor == null ? '–' : Formatos.numero(valor!),
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
        ),
        Text(
          etiqueta,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12),
        ),
      ],
    );
  }
}
