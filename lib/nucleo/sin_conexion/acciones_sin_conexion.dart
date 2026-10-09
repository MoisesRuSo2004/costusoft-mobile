import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../errores/fallo.dart';
import '../errores/resultado.dart';
import 'almacen_local.dart';
import 'bandeja_salida.dart';
import 'estado_red.dart';
import 'sincronizacion.dart';

/// `ref.invalidate` de un `Ref` o de un `WidgetRef`: permite que la misma
/// función refresque las pantallas desde un widget o tras sincronizar.
typedef Invalidador = void Function(ProviderOrFamily proveedor);

/// Resultado de un cambio que puede quedar en cola si no hay conexión.
sealed class ResultadoAccion<T> {
  const ResultadoAccion();
}

final class AccionAplicada<T> extends ResultadoAccion<T> {
  const AccionAplicada(this.datos);

  final T datos;
}

/// Se guardó en la bandeja de salida y se enviará al volver la conexión.
final class AccionEnCola<T> extends ResultadoAccion<T> {
  const AccionEnCola();
}

final class AccionFallida<T> extends ResultadoAccion<T> {
  const AccionFallida(this.fallo);

  final Fallo fallo;
}

/// Envía un cambio al servidor o, si no se puede, lo deja en la bandeja.
///
/// Va directo a la bandeja si ya se sabe que no hay conexión o si quedan
/// cambios anteriores sin enviar (así se respeta el orden). Si el envío falla
/// porque la petición no salió del dispositivo, también se encola; cualquier
/// otro error (p. ej. una regla del negocio) se devuelve tal cual.
Future<ResultadoAccion<T>> ejecutarOEncolar<T>(
  WidgetRef ref, {
  required SolicitudPendiente solicitud,
  required Future<Resultado<T>> Function() enviar,
}) async {
  Future<ResultadoAccion<T>> encolar() async {
    await ref.read(proveedorBandejaSalida).agregar(solicitud);
    unawaited(ref.read(proveedorSincronizacion.notifier).sincronizar());
    return AccionEnCola<T>();
  }

  if (!ref.read(proveedorRed).enLinea || ref.read(proveedorSincronizacion).pendientes > 0) return encolar();

  final resultado = await enviar();
  if (resultado case Falla(fallo: FalloRed(noSeEnvio: true))) {
    ref.read(proveedorRed.notifier).marcarSinConexion();
    return encolar();
  }
  return switch (resultado) {
    Exito(:final datos) => AccionAplicada(datos),
    Falla(:final fallo) => AccionFallida(fallo),
  };
}
