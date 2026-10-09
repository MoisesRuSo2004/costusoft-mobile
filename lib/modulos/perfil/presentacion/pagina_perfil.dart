import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../compartido/widgets/avatar_usuario.dart';
import '../../../compartido/widgets/aviso_en_linea.dart';
import '../../../compartido/widgets/encabezado_rol.dart';
import '../../../nucleo/sin_conexion/sincronizacion.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/tema/paleta_rol.dart';
import '../../autenticacion/dominio/estado_sesion.dart';
import '../../autenticacion/dominio/usuario.dart';
import '../../autenticacion/presentacion/controlador_sesion.dart';

/// Perfil del usuario autenticado y cierre de sesión. Es igual para todos los
/// roles; solo cambia el color de la portada.
class PaginaPerfil extends ConsumerWidget {
  const PaginaPerfil({super.key});

  Future<void> _confirmarCierre(BuildContext context, WidgetRef ref) async {
    final porEnviar = ref.read(proveedorSincronizacion).pendientes;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Seguro que quieres salir? Tendrás que ingresar tus credenciales de nuevo.'),
            if (porEnviar > 0) ...[
              const SizedBox(height: 14),
              AvisoEnLinea.error(
                porEnviar == 1
                    ? 'Tienes 1 cambio sin enviar. Si cierras sesión ahora, se perderá.'
                    : 'Tienes $porEnviar cambios sin enviar. Si cierras sesión ahora, se perderán.',
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(contexto, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(contexto, true), child: const Text('Cerrar sesión')),
        ],
      ),
    );
    if (confirmado ?? false) await ref.read(proveedorSesion.notifier).cerrarSesion();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(proveedorSesion);
    if (estado is! SesionActiva) return const Scaffold(body: SizedBox.shrink());
    final usuario = estado.usuario;
    final tema = Theme.of(context);

    final paleta = PaletaRol.de(usuario.rol);

    return Scaffold(
      backgroundColor: ColoresApp.fondoSuave,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          _Portada(usuario: usuario, paleta: paleta),
          const SizedBox(height: 12),
          Center(
            child: Text(usuario.nombreUsuario, style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          Center(
            child: Chip(
              label: Text(usuario.rol.etiqueta),
              backgroundColor: paleta.acentoSuave,
              labelStyle: TextStyle(color: paleta.acento, fontWeight: FontWeight.w600),
              side: BorderSide.none,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.alternate_email_rounded),
                        title: const Text('Correo'),
                        subtitle: Text(usuario.correo.isEmpty ? 'Sin correo registrado' : usuario.correo),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.badge_outlined),
                        title: const Text('Rol en CostuSoft'),
                        subtitle: Text(usuario.rol.etiqueta),
                      ),
                      const Divider(height: 1),
                      const ListTile(
                        leading: Icon(Icons.verified_user_outlined),
                        title: Text('Sesión protegida'),
                        subtitle: Text('Tus credenciales se guardan cifradas y la sesión se renueva sola.'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => _confirmarCierre(context, ref),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Cerrar sesión'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: tema.colorScheme.error,
                    side: BorderSide(color: tema.colorScheme.error.withValues(alpha: 0.5)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Portada con el degradado del rol; el avatar queda montado sobre su borde.
class _Portada extends StatelessWidget {
  const _Portada({required this.usuario, required this.paleta});

  final Usuario usuario;
  final PaletaRol paleta;

  static const _radioAvatar = 46.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Padding(
          // Espacio para la mitad del avatar que sobresale.
          padding: const EdgeInsets.only(bottom: _radioAvatar),
          child: FondoRol(
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, _radioAvatar + 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mi perfil',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'CostuSoft ${paleta.nombre}',
                        style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Aro blanco que despega el avatar de la portada.
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: ColoresApp.fondoSuave,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: paleta.acento.withValues(alpha: 0.25), blurRadius: 18, offset: const Offset(0, 6)),
            ],
          ),
          child: AvatarUsuario(usuario: usuario, radio: _radioAvatar),
        ),
      ],
    );
  }
}
