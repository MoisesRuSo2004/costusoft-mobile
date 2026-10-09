/// Roles del backend (`Usuario.rol`). Definen qué panel ve cada persona.
enum RolUsuario {
  administrador('ADMIN', 'Administrador'),
  usuario('USER', 'Usuario'),
  bodega('BODEGA', 'Bodega'),
  institucion('INSTITUCION', 'Institución');

  const RolUsuario(this.codigo, this.etiqueta);

  /// Valor exacto que envía el backend.
  final String codigo;

  /// Nombre para mostrar en la interfaz.
  final String etiqueta;

  /// Convierte el código del backend. Un código desconocido se trata como
  /// `usuario`, el rol con menos permisos de los paneles internos.
  static RolUsuario desdeCodigo(String? codigo) =>
      values.firstWhere((rol) => rol.codigo == codigo?.toUpperCase(), orElse: () => RolUsuario.usuario);
}
