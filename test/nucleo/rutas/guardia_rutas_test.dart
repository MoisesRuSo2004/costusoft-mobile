import 'package:costusoft_mobile/modulos/autenticacion/dominio/estado_sesion.dart';
import 'package:costusoft_mobile/modulos/autenticacion/dominio/rol_usuario.dart';
import 'package:costusoft_mobile/modulos/autenticacion/dominio/usuario.dart';
import 'package:costusoft_mobile/nucleo/rutas/guardia_rutas.dart';
import 'package:costusoft_mobile/nucleo/rutas/rutas_app.dart';
import 'package:flutter_test/flutter_test.dart';

SesionActiva _sesionDe(RolUsuario rol) =>
    SesionActiva(Usuario(id: 1, nombreUsuario: 'piedad', correo: 'p@costusoft.com', rol: rol));

void main() {
  group('sin saber aún si hay sesión', () {
    test('cualquier ruta lleva a la carga', () {
      expect(calcularRedireccion(const SesionPendiente(), RutasApp.adminInicio), RutasApp.carga);
    });

    test('en la carga se queda', () {
      expect(calcularRedireccion(const SesionPendiente(), RutasApp.carga), isNull);
    });
  });

  group('sin sesión', () {
    test('una ruta protegida lleva al ingreso', () {
      expect(calcularRedireccion(const SinSesion(), RutasApp.bodegaPendientes), RutasApp.ingreso);
    });

    test('en el ingreso se queda', () {
      expect(calcularRedireccion(const SinSesion(), RutasApp.ingreso), isNull);
    });
  });

  group('con sesión', () {
    test('del ingreso pasa al inicio de su rol', () {
      expect(calcularRedireccion(_sesionDe(RolUsuario.administrador), RutasApp.ingreso), RutasApp.adminInicio);
      expect(calcularRedireccion(_sesionDe(RolUsuario.bodega), RutasApp.ingreso), RutasApp.bodegaPendientes);
      expect(calcularRedireccion(_sesionDe(RolUsuario.institucion), RutasApp.carga), RutasApp.institucionPedidos);
    });

    test('el rol Usuario comparte el panel de administración', () {
      expect(calcularRedireccion(_sesionDe(RolUsuario.usuario), RutasApp.adminIa), isNull);
    });

    test('Bodega no puede abrir rutas de administración', () {
      expect(calcularRedireccion(_sesionDe(RolUsuario.bodega), RutasApp.adminInicio), RutasApp.bodegaPendientes);
    });

    test('Institución no puede abrir rutas de bodega', () {
      expect(
        calcularRedireccion(_sesionDe(RolUsuario.institucion), RutasApp.bodegaEscanear),
        RutasApp.institucionPedidos,
      );
    });

    test('una ruta propia del rol se respeta', () {
      expect(calcularRedireccion(_sesionDe(RolUsuario.bodega), RutasApp.bodegaMovimientos), isNull);
    });

    test('un prefijo parecido no engaña a la guardia', () {
      expect(calcularRedireccion(_sesionDe(RolUsuario.administrador), '/administracion'), RutasApp.adminInicio);
    });
  });

  group('enlace directo (ruta solicitada antes de restaurar la sesión)', () {
    test('al restaurar la sesión va a la ruta pedida si es del rol', () {
      expect(
        calcularRedireccion(_sesionDe(RolUsuario.administrador), RutasApp.carga, rutaSolicitada: '/admin/inventario/8'),
        '/admin/inventario/8',
      );
    });

    test('si la ruta pedida es de otro rol, va al inicio del suyo', () {
      expect(
        calcularRedireccion(_sesionDe(RolUsuario.bodega), RutasApp.carga, rutaSolicitada: RutasApp.adminInventario),
        RutasApp.bodegaPendientes,
      );
    });
  });

  group('Rutas de detalle por rol', () {
    test('Bodega abre el detalle dentro de su sección', () {
      expect(RutasApp.detalleInsumo(RolUsuario.bodega, 36), '/bodega/inventario/36');
      expect(RutasApp.detallePedido(RolUsuario.bodega, 9), '/bodega/pendientes/pedido/9');
    });

    test('Administrador y Usuario usan la sección de administración', () {
      expect(RutasApp.detalleInsumo(RolUsuario.administrador, 36), '/admin/inventario/36');
      expect(RutasApp.detallePedido(RolUsuario.usuario, 9), '/admin/pedidos/9');
    });

    test('Bodega puede entrar a su inventario y a la cola de pedidos', () {
      expect(calcularRedireccion(_sesionDe(RolUsuario.bodega), RutasApp.bodegaDetalleInsumo(36)), isNull);
      expect(calcularRedireccion(_sesionDe(RolUsuario.bodega), '${RutasApp.bodegaPedidos}?estado=CONFIRMADO'), isNull);
      expect(calcularRedireccion(_sesionDe(RolUsuario.bodega), RutasApp.adminInventario), RutasApp.bodegaPendientes);
    });
  });
}
