import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'modulos/actualizaciones/presentacion/aviso_actualizacion.dart';
import 'modulos/autenticacion/presentacion/guardia_inactividad.dart';
import 'modulos/bodega/presentacion/proveedores_bodega.dart';
import 'modulos/carga/presentacion/cortina_inicio.dart';
import 'modulos/inventario/presentacion/proveedores_inventario.dart';
import 'modulos/pedidos/presentacion/proveedores_pedidos.dart';
import 'modulos/tablero/presentacion/proveedores_tablero.dart';
import 'nucleo/notificaciones/controlador_avisos.dart';
import 'nucleo/rutas/enrutador_app.dart';
import 'nucleo/sin_conexion/acciones_sin_conexion.dart';
import 'nucleo/sin_conexion/bandeja_salida.dart';
import 'nucleo/sin_conexion/estado_red.dart';
import 'nucleo/sin_conexion/sincronizacion.dart';
import 'nucleo/tema/tema_app.dart';

class AplicacionCostuSoft extends ConsumerWidget {
  const AplicacionCostuSoft({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Al volver la conexión, los datos de la copia local se reemplazan por
    // los del servidor.
    ref.listen(proveedorRed, (anterior, actual) {
      if (anterior?.enLinea == false && actual.enLinea) _refrescarDatos(ref.invalidate);
    });
    // Cada cambio de la bandeja de salida que el servidor aceptó.
    ref.listen(proveedorAccionesAplicadas, (_, aplicadas) {
      for (final accion in aplicadas.value ?? const <AccionPendiente>[]) {
        final recurso = accion.solicitud.recurso;
        if (recurso.startsWith('pedidos/')) {
          invalidarTrasCambiarPedido(ref.invalidate, int.parse(recurso.split('/').last), afectaStock: true);
          ref.invalidate(proveedorListaPedidos);
          ref.invalidate(proveedorPedidosPorAtender);
        } else {
          invalidarTrasVerificar(ref.invalidate);
        }
      }
    });

    // Avisos push: en pantalla con la app abierta y al tocar la notificación.
    ref.watch(proveedorEscuchaAvisos);

    return MaterialApp.router(
      title: 'CostuSoft',
      scaffoldMessengerKey: llaveMensajeroApp,
      debugShowCheckedModeBanner: false,
      theme: TemaApp.claro,
      themeMode: ThemeMode.light,
      routerConfig: ref.watch(proveedorEnrutador),
      // La cortina de inicio tapa la app al abrirla y se retira sola.
      builder: (_, enrutador) => CortinaInicio(
        child: GuardiaInactividad(child: AvisoActualizacion(child: enrutador ?? const SizedBox.shrink())),
      ),
      locale: const Locale('es', 'CO'),
      supportedLocales: const [Locale('es', 'CO'), Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}

/// Consultas principales que se vuelven a pedir al recuperar la conexión.
/// Las predicciones de IA no se incluyen: son costosas y cambian poco.
void _refrescarDatos(Invalidador invalidar) {
  invalidar(proveedorInsumos);
  invalidar(proveedorResumenTablero);
  invalidar(proveedorConteoPedidos);
  invalidar(proveedorListaPedidos);
  invalidar(proveedorMovimientosPendientes);
  invalidar(proveedorPedidosPorAtender);
  invalidar(proveedorHistorialMovimientos);
}
