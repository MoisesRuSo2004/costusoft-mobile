import 'package:flutter/material.dart';

import '../../modulos/autenticacion/dominio/usuario.dart';
import '../../nucleo/tema/paleta_rol.dart';

/// Foto del usuario (Cloudinary) o sus iniciales, sobre el color de su rol.
class AvatarUsuario extends StatelessWidget {
  const AvatarUsuario({super.key, required this.usuario, this.radio = 28});

  final Usuario usuario;
  final double radio;

  @override
  Widget build(BuildContext context) {
    final iniciales = Text(
      usuario.iniciales,
      style: TextStyle(fontSize: radio * 0.7, fontWeight: FontWeight.w700, color: Colors.white),
    );
    final foto = usuario.fotoUrl;
    return CircleAvatar(
      radius: radio,
      backgroundColor: PaletaRol.de(usuario.rol).acento,
      foregroundImage: foto != null ? NetworkImage(foto) : null,
      onForegroundImageError: foto != null ? (_, _) {} : null,
      child: iniciales,
    );
  }
}
