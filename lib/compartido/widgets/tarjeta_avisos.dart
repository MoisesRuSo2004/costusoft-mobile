import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../modulos/autenticacion/dominio/rol_usuario.dart';
import '../../modulos/autenticacion/presentacion/controlador_sesion.dart';
import '../../nucleo/notificaciones/controlador_avisos.dart';
import '../../nucleo/notificaciones/servicio_notificaciones.dart';
import '../../nucleo/tema/colores_app.dart';
import '../../nucleo/tema/paleta_rol.dart';

/// Para qué sirven los avisos según el rol.
String _paraQue(RolUsuario? rol) => switch (rol) {
  RolUsuario.bodega => 'Te avisamos al instante cuando haya entradas o salidas por confirmar.',
  _ => 'Te avisamos al instante cuando tus uniformes estén listos para entrega.',
};

/// Invita a activar los avisos push. El permiso se pide al tocar el botón:
/// los navegadores lo exigen así y es más claro para el usuario saber para
/// qué se le pide. No se muestra si ya están activos o el rol no los recibe.
class TarjetaAvisos extends ConsumerWidget {
  const TarjetaAvisos({super.key});

  Future<void> _activar(BuildContext context, WidgetRef ref) async {
    await ref.read(proveedorAvisos.notifier).activar();
    if (!context.mounted) return;
    final activos = ref.read(proveedorAvisos).value == EstadoAvisos.activos;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          activos
              ? 'Listo: los avisos están activos en este teléfono.'
              : 'No se activaron los avisos. Puedes hacerlo luego desde la configuración.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avisos = ref.watch(proveedorAvisos);
    final paleta = ref.watch(proveedorPaletaRol);
    final acento = paleta.acento;
    final (titulo, texto, mostrarBoton) = switch (avisos.value) {
      EstadoAvisos.sinPreguntar => ('Activa los avisos', _paraQue(ref.watch(proveedorRolActual)), true),
      EstadoAvisos.bloqueados => (
        'Avisos bloqueados',
        'Para recibirlos, permite las notificaciones de CostuSoft en la configuración del teléfono o del navegador.',
        false,
      ),
      _ => (null, null, false),
    };
    if (titulo == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: paleta.acentoSuave,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: acento.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(
              mostrarBoton ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
              color: acento,
              size: 26,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(texto!, style: const TextStyle(fontSize: 12.5, color: ColoresApp.textoEtiqueta, height: 1.35)),
                ],
              ),
            ),
            if (mostrarBoton) ...[
              const SizedBox(width: 10),
              FilledButton(
                onPressed: avisos.isLoading ? null : () => _activar(context, ref),
                style: FilledButton.styleFrom(
                  backgroundColor: acento,
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Activar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Fila del perfil: estado de los avisos y un aviso de prueba para comprobar
/// que llegan a este teléfono. Solo aparece para los roles que los reciben.
class FilaAvisosPerfil extends ConsumerStatefulWidget {
  const FilaAvisosPerfil({super.key});

  @override
  ConsumerState<FilaAvisosPerfil> createState() => _FilaAvisosPerfilState();
}

class _FilaAvisosPerfilState extends ConsumerState<FilaAvisosPerfil> {
  bool _enviando = false;

  Future<void> _probar() async {
    setState(() => _enviando = true);
    final entregados = await ref.read(proveedorAvisos.notifier).enviarPrueba();
    if (!mounted) return;
    setState(() => _enviando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(switch (entregados) {
          null => 'No se pudo enviar el aviso de prueba. Revisa tu conexión.',
          0 => 'El servidor no encontró este teléfono. Desactiva y vuelve a activar los avisos.',
          _ => 'Aviso enviado: debería llegarte en unos segundos.',
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(proveedorAvisos).value;
    if (estado == null || estado == EstadoAvisos.noDisponible) return const SizedBox.shrink();
    final activos = estado == EstadoAvisos.activos;
    return Column(
      children: [
        const Divider(height: 1),
        ListTile(
          leading: Icon(activos ? Icons.notifications_active_outlined : Icons.notifications_off_outlined),
          title: const Text('Notificaciones'),
          subtitle: Text(switch (estado) {
            EstadoAvisos.activos => 'Activas en este teléfono.',
            EstadoAvisos.bloqueados => 'Bloqueadas en la configuración del teléfono.',
            _ => 'Sin activar.',
          }),
          trailing: switch (estado) {
            EstadoAvisos.activos => TextButton(
              onPressed: _enviando ? null : _probar,
              child: Text(_enviando ? 'Enviando…' : 'Probar'),
            ),
            EstadoAvisos.sinPreguntar => TextButton(
              onPressed: () => ref.read(proveedorAvisos.notifier).activar(),
              child: const Text('Activar'),
            ),
            _ => null,
          },
        ),
      ],
    );
  }
}
