import '../../modulos/autenticacion/dominio/rol_usuario.dart';

/// Rutas de la app (documento de diseño, sección 9).
/// Cada rol tiene su propio prefijo y su barra inferior.
abstract final class RutasApp {
  static const carga = '/carga';
  static const ingreso = '/ingreso';

  // Administrador y Usuario
  static const prefijoAdmin = '/admin';
  static const adminInicio = '/admin/inicio';
  static const adminInventario = '/admin/inventario';
  static String adminDetalleInsumo(int id) => '$adminInventario/$id';
  static const adminIa = '/admin/ia';
  static const adminPedidos = '/admin/pedidos';
  static String adminDetallePedido(int id) => '$adminPedidos/$id';
  static const adminPerfil = '/admin/perfil';

  // Bodega
  static const prefijoBodega = '/bodega';
  static const bodegaPendientes = '/bodega/pendientes';
  static const bodegaPedidos = '$bodegaPendientes/pedidos';
  static String bodegaDetallePedido(int id) => '$bodegaPendientes/pedido/$id';
  static const bodegaInventario = '/bodega/inventario';
  static String bodegaDetalleInsumo(int id) => '$bodegaInventario/$id';
  static const bodegaEscanear = '/bodega/escanear';
  static const bodegaMovimientos = '/bodega/movimientos';
  static const bodegaPerfil = '/bodega/perfil';

  // Institución
  static const prefijoInstitucion = '/institucion';
  static const institucionPedidos = '/institucion/pedidos';
  static String institucionSeguimiento(int id) => '$institucionPedidos/$id';
  static const institucionAsistente = '/institucion/asistente';
  static const institucionPerfil = '/institucion/perfil';

  /// Detalle de un insumo dentro de la sección de cada rol.
  static String detalleInsumo(RolUsuario? rol, int id) =>
      rol == RolUsuario.bodega ? bodegaDetalleInsumo(id) : adminDetalleInsumo(id);

  /// Detalle de un pedido dentro de la sección de cada rol.
  static String detallePedido(RolUsuario? rol, int id) =>
      rol == RolUsuario.bodega ? bodegaDetallePedido(id) : adminDetallePedido(id);

  /// Prefijo de las rutas que puede visitar cada rol.
  static String prefijoDe(RolUsuario rol) => switch (rol) {
    RolUsuario.administrador || RolUsuario.usuario => prefijoAdmin,
    RolUsuario.bodega => prefijoBodega,
    RolUsuario.institucion => prefijoInstitucion,
  };

  /// Perfil dentro de la sección de cada rol.
  static String perfilDe(RolUsuario rol) => switch (rol) {
    RolUsuario.administrador || RolUsuario.usuario => adminPerfil,
    RolUsuario.bodega => bodegaPerfil,
    RolUsuario.institucion => institucionPerfil,
  };

  /// Pantalla de inicio de cada rol después de iniciar sesión.
  static String inicioDe(RolUsuario rol) => switch (rol) {
    RolUsuario.administrador || RolUsuario.usuario => adminInicio,
    RolUsuario.bodega => bodegaPendientes,
    RolUsuario.institucion => institucionPedidos,
  };
}
