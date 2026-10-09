import '../../../nucleo/errores/resultado.dart';
import '../../../nucleo/red/respuesta_api.dart';
import 'movimiento.dart';

/// Entradas y salidas del almacén: `/api/entradas` y `/api/salidas`.
///
/// Bodega solo confirma o rechaza; registrar movimientos es tarea de
/// Administrador y Usuario (el backend lo restringe con `@PreAuthorize`).
abstract interface class RepositorioMovimientos {
  /// Página de movimientos; con [estado] filtra en el servidor.
  Future<Resultado<PaginaApi<Movimiento>>> listar(
    TipoMovimiento tipo, {
    required int pagina,
    int tamano = 20,
    EstadoMovimiento? estado,
  });

  Future<Resultado<Movimiento>> obtener(TipoMovimiento tipo, int id);

  /// Confirma el movimiento: el stock se actualiza en ese momento.
  Future<Resultado<Movimiento>> confirmar(TipoMovimiento tipo, int id);

  Future<Resultado<Movimiento>> rechazar(TipoMovimiento tipo, int id, String motivo);
}
