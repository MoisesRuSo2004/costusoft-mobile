import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../nucleo/tema/paleta_rol.dart';
import 'franja_conexion.dart';

/// Una pestaña de la navegación principal.
class DestinoNavegacion {
  const DestinoNavegacion({required this.etiqueta, required this.icono, required this.iconoSeleccionado});

  final String etiqueta;
  final IconData icono;
  final IconData iconoSeleccionado;
}

/// Marco con la barra de navegación inferior de cada rol.
/// Cada pestaña conserva su propia pila de pantallas, y la pestaña activa
/// se pinta con el color del rol.
class MarcoNavegacion extends ConsumerWidget {
  const MarcoNavegacion({super.key, required this.navegacion, required this.destinos});

  final StatefulNavigationShell navegacion;
  final List<DestinoNavegacion> destinos;

  void _irA(int indice) {
    // Tocar la pestaña activa vuelve a su pantalla inicial.
    navegacion.goBranch(indice, initialLocation: indice == navegacion.currentIndex);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    final activo = ref.watch(proveedorPaletaRol).navegacion;
    final base = tema.navigationBarTheme;
    bool seleccionado(Set<WidgetState> estados) => estados.contains(WidgetState.selected);
    return Scaffold(
      body: navegacion,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FranjaConexion(),
          DecoratedBox(
            // Línea sutil que separa la barra del contenido.
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colores.outlineVariant.withValues(alpha: 0.4))),
            ),
            child: NavigationBarTheme(
              data: base.copyWith(
                indicatorColor: activo.withValues(alpha: 0.14),
                iconTheme: WidgetStateProperty.resolveWith(
                  (estados) => base.iconTheme?.resolve(estados)?.copyWith(color: seleccionado(estados) ? activo : null),
                ),
                labelTextStyle: WidgetStateProperty.resolveWith(
                  (estados) =>
                      base.labelTextStyle?.resolve(estados)?.copyWith(color: seleccionado(estados) ? activo : null),
                ),
              ),
              child: NavigationBar(
                selectedIndex: navegacion.currentIndex,
                onDestinationSelected: _irA,
                destinations: [
                  for (final destino in destinos)
                    NavigationDestination(
                      icon: Icon(destino.icono),
                      selectedIcon: Icon(destino.iconoSeleccionado),
                      label: destino.etiqueta,
                      tooltip: destino.etiqueta,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
