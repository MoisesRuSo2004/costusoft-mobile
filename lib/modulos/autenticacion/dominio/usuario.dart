import 'rol_usuario.dart';

/// Persona autenticada en la app.
class Usuario {
  const Usuario({required this.id, required this.nombreUsuario, required this.correo, required this.rol, this.fotoUrl});

  final int id;
  final String nombreUsuario;
  final String correo;
  final RolUsuario rol;
  final String? fotoUrl;

  /// Una o dos letras para el avatar cuando no hay foto.
  String get iniciales {
    final partes = nombreUsuario.split(RegExp(r'[\s._-]+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return (partes[0][0] + partes[1][0]).toUpperCase();
  }

  @override
  bool operator ==(Object otro) =>
      otro is Usuario &&
      otro.id == id &&
      otro.nombreUsuario == nombreUsuario &&
      otro.correo == correo &&
      otro.rol == rol &&
      otro.fotoUrl == fotoUrl;

  @override
  int get hashCode => Object.hash(id, nombreUsuario, correo, rol, fotoUrl);
}
