import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../compartido/widgets/aviso_en_linea.dart';
import '../../../compartido/widgets/campo_con_etiqueta.dart';
import '../../../nucleo/errores/resultado.dart';
import '../../../nucleo/tema/colores_app.dart';
import 'controlador_sesion.dart';

/// Abre la hoja inferior de "¿Olvidaste tu contraseña?".
Future<void> mostrarHojaRecuperarClave(BuildContext context) =>
    showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (_) => const _HojaRecuperarClave());

/// Réplica de `(auth)/recuperar-password/page.tsx`: pide el correo y solicita
/// al backend el enlace de recuperación. El enlace del correo abre la página
/// de restablecimiento de la web, como cuando se pide desde allá.
///
/// El backend responde lo mismo exista o no el correo (anti-enumeración), así
/// que el mensaje de éxito es propio, igual que en la web.
class _HojaRecuperarClave extends ConsumerStatefulWidget {
  const _HojaRecuperarClave();

  @override
  ConsumerState<_HojaRecuperarClave> createState() => _EstadoHojaRecuperarClave();
}

class _EstadoHojaRecuperarClave extends ConsumerState<_HojaRecuperarClave> {
  final _llaveFormulario = GlobalKey<FormState>();
  final _controladorCorreo = TextEditingController();
  static final _formatoCorreo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  bool _enviando = false;

  /// Correo al que se envió el enlace; si no es nulo se muestra el éxito.
  String? _correoEnviado;
  String? _mensajeError;

  @override
  void dispose() {
    _controladorCorreo.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!(_llaveFormulario.currentState?.validate() ?? false)) return;
    final correo = _controladorCorreo.text.trim();
    setState(() {
      _enviando = true;
      _mensajeError = null;
    });
    final resultado = await ref.read(proveedorSesion.notifier).solicitarRecuperacionClave(correo);
    if (!mounted) return;
    setState(() {
      _enviando = false;
      switch (resultado) {
        case Exito():
          _correoEnviado = correo;
        case Falla(:final fallo):
          _mensajeError = fallo.mensaje;
      }
    });
  }

  void _enviarAOtroCorreo() => setState(() {
    _correoEnviado = null;
    _controladorCorreo.clear();
  });

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final tecladoAbierto = MediaQuery.viewInsetsOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + tecladoAbierto),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _IconoCorreo(),
          const SizedBox(height: 16),
          Text(
            'Recuperar contraseña',
            style: textos.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: ColoresApp.textoTitulo),
          ),
          const SizedBox(height: 6),
          Text(
            'Ingresa tu correo y te enviaremos un enlace para restablecer tu contraseña. '
            'El enlace expira en 15 minutos.',
            style: textos.bodyMedium?.copyWith(color: ColoresApp.textoSecundario, height: 1.6),
          ),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (hijo, animacion) => FadeTransition(
              opacity: animacion,
              child: ScaleTransition(scale: Tween(begin: 0.96, end: 1.0).animate(animacion), child: hijo),
            ),
            child: _correoEnviado != null
                ? _EstadoEnviado(
                    key: const ValueKey('enviado'),
                    correo: _correoEnviado!,
                    alEnviarAOtro: _enviarAOtroCorreo,
                  )
                : _construirFormulario(),
          ),
        ],
      ),
    );
  }

  Widget _construirFormulario() {
    return Form(
      key: _llaveFormulario,
      child: Column(
        key: const ValueKey('formulario'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CampoConEtiqueta(
            etiqueta: 'Correo electrónico',
            obligatorio: true,
            campo: TextFormField(
              controller: _controladorCorreo,
              enabled: !_enviando,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.send,
              onChanged: (_) {
                if (_mensajeError != null) setState(() => _mensajeError = null);
              },
              onFieldSubmitted: (_) => _enviar(),
              decoration: const InputDecoration(
                hintText: 'tu@correo.com',
                prefixIcon: Icon(Icons.mail_outline_rounded, size: 18),
              ),
              validator: (valor) {
                final correo = valor?.trim() ?? '';
                if (correo.isEmpty) return 'El correo es obligatorio.';
                return _formatoCorreo.hasMatch(correo) ? null : 'Ingresa un correo válido.';
              },
            ),
          ),
          const SizedBox(height: 20),
          if (_mensajeError != null) AvisoEnLinea.error(_mensajeError!),
          FilledButton.icon(
            onPressed: _enviando ? null : _enviar,
            icon: _enviando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                  )
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(_enviando ? 'Enviando...' : 'Enviar enlace de recuperación'),
          ),
        ],
      ),
    );
  }
}

/// Cuadro azul claro con el sobre, como el encabezado de la web.
class _IconoCorreo extends StatelessWidget {
  const _IconoCorreo();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: ColoresApp.infoFondo,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ColoresApp.infoBordeSuave),
        ),
        child: const Icon(Icons.mail_outline_rounded, size: 22, color: ColoresApp.azulMarino),
      ),
    );
  }
}

/// "¡Revisa tu correo!" con el correo usado y la sugerencia de mirar spam.
class _EstadoEnviado extends StatelessWidget {
  const _EstadoEnviado({super.key, required this.correo, required this.alEnviarAOtro});

  final String correo;
  final VoidCallback alEnviarAOtro;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: ColoresApp.exitoFondo,
              shape: BoxShape.circle,
              border: Border.all(color: ColoresApp.exitoBorde, width: 2),
            ),
            child: const Icon(Icons.check_circle_outline_rounded, size: 40, color: ColoresApp.exitoIcono),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '¡Revisa tu correo!',
          textAlign: TextAlign.center,
          style: textos.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: ColoresApp.textoTitulo),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Si la dirección '),
              TextSpan(
                text: correo,
                style: const TextStyle(fontWeight: FontWeight.w600, color: ColoresApp.textoTitulo),
              ),
              const TextSpan(text: ' está registrada, recibirás un enlace de recuperación en los próximos minutos.'),
            ],
          ),
          textAlign: TextAlign.center,
          style: textos.bodyMedium?.copyWith(color: ColoresApp.textoSecundario, height: 1.7),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: ColoresApp.exitoFondo,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ColoresApp.exitoBorde),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.mark_email_unread_outlined, size: 15, color: ColoresApp.exitoTitulo),
                  const SizedBox(width: 6),
                  Text(
                    'Revisa tu bandeja de entrada',
                    style: textos.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: ColoresApp.exitoTitulo),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Te enviamos un correo con el enlace de recuperación. Si no lo ves en unos minutos, '
                'revisa la carpeta de spam o correo no deseado.',
                style: textos.bodySmall?.copyWith(color: ColoresApp.exitoTexto, height: 1.6),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido')),
        const SizedBox(height: 4),
        TextButton(
          onPressed: alEnviarAOtro,
          style: TextButton.styleFrom(foregroundColor: ColoresApp.azulMarino),
          child: const Text('Enviar a otro correo'),
        ),
      ],
    );
  }
}
