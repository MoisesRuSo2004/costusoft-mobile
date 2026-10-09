import '../../../nucleo/errores/resultado.dart';
import 'resumen_tablero.dart';

/// Datos del tablero de inicio del administrador.
abstract interface class RepositorioTablero {
  /// Totales, alertas de stock y movimientos (`/api/dashboard/resumen`).
  Future<Resultado<ResumenTablero>> obtenerResumen();

  /// Cantidad de pedidos en cada estado.
  Future<Resultado<ConteoPedidos>> contarPedidos();
}
