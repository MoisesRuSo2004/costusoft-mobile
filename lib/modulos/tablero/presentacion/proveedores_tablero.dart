import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/errores/resultado.dart';
import '../../../nucleo/red/cliente_http.dart';
import '../datos/fuente_remota_tablero.dart';
import '../datos/repositorio_tablero_impl.dart';
import '../dominio/repositorio_tablero.dart';
import '../dominio/resumen_tablero.dart';

final proveedorRepositorioTablero = Provider<RepositorioTablero>(
  (ref) => RepositorioTableroImpl(FuenteRemotaTablero(ref.watch(proveedorClienteHttp))),
);

T _datosOLanzar<T>(Resultado<T> resultado) => switch (resultado) {
  Exito(:final datos) => datos,
  Falla(:final fallo) => throw fallo,
};

final proveedorResumenTablero = FutureProvider<ResumenTablero>(
  (ref) async => _datosOLanzar(await ref.read(proveedorRepositorioTablero).obtenerResumen()),
);

final proveedorConteoPedidos = FutureProvider<ConteoPedidos>(
  (ref) async => _datosOLanzar(await ref.read(proveedorRepositorioTablero).contarPedidos()),
);
