import 'package:costusoft_mobile/modulos/autenticacion/dominio/rol_usuario.dart';
import 'package:costusoft_mobile/nucleo/notificaciones/controlador_avisos.dart';
import 'package:costusoft_mobile/nucleo/rutas/rutas_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('una entrada o salida pendiente abre los pendientes de Bodega', () {
    expect(
      rutaDeAviso({'tipo': 'MOVIMIENTO_PENDIENTE', 'movimiento': 'ENTRADA', 'movimientoId': '15'}),
      RutasApp.bodegaPendientes,
    );
  });

  test('un pedido listo abre su seguimiento (o la lista si no trae id)', () {
    expect(rutaDeAviso({'tipo': 'PEDIDO_LISTO', 'pedidoId': '7'}), RutasApp.institucionSeguimiento(7));
    expect(rutaDeAviso({'tipo': 'PEDIDO_LISTO'}), RutasApp.institucionPedidos);
  });

  test('el aviso de prueba no abre ninguna pantalla', () {
    expect(rutaDeAviso({'tipo': 'PRUEBA'}), isNull);
    expect(rutaDeAviso(const {}), isNull);
  });

  test('reciben avisos Institución y Bodega', () {
    expect(rolesConAvisos, {RolUsuario.institucion, RolUsuario.bodega});
  });
}
