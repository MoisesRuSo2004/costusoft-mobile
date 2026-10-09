import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../compartido/widgets/aviso_en_linea.dart';
import '../../../compartido/widgets/campo_con_etiqueta.dart';
import '../../../compartido/widgets/encabezado_domo.dart';
import '../../../nucleo/errores/fallo.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../datos/preferencias_ingreso.dart';
import '../dominio/estado_sesion.dart';
import 'controlador_sesion.dart';
import 'hoja_recuperar_clave.dart';

/// Pantalla de inicio de sesión, con el mismo diseño del login web.
/// Al ingresar, el enrutador lleva automáticamente al inicio del rol.
class PaginaIngreso extends ConsumerStatefulWidget {
  const PaginaIngreso({super.key});

  @override
  ConsumerState<PaginaIngreso> createState() => _EstadoPaginaIngreso();
}

class _EstadoPaginaIngreso extends ConsumerState<PaginaIngreso> {
  final _llaveFormulario = GlobalKey<FormState>();
  final _controladorUsuario = TextEditingController();
  final _controladorClave = TextEditingController();
  final _focoClave = FocusNode();
  bool _ocultarClave = true;
  bool _recordarme = false;
  bool _enviando = false;
  bool _intentoEnviar = false;
  Fallo? _fallo;

  @override
  void initState() {
    super.initState();
    _precargarUsuarioRecordado();
  }

  Future<void> _precargarUsuarioRecordado() async {
    final usuario = await ref.read(proveedorUsuarioRecordado.future);
    if (!mounted || usuario == null || usuario.isEmpty) return;
    setState(() {
      _controladorUsuario.text = usuario;
      _recordarme = true;
    });
  }

  @override
  void dispose() {
    _controladorUsuario.dispose();
    _controladorClave.dispose();
    _focoClave.dispose();
    super.dispose();
  }

  Future<void> _ingresar() async {
    if (_enviando) return;
    if (!_intentoEnviar) setState(() => _intentoEnviar = true);
    if (!(_llaveFormulario.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _enviando = true;
      _fallo = null;
    });

    final preferencias = ref.read(proveedorPreferenciasIngreso);
    final usuario = _controladorUsuario.text;
    final fallo = await ref
        .read(proveedorSesion.notifier)
        .iniciarSesion(nombreUsuario: usuario, clave: _controladorClave.text);

    if (fallo == null) {
      await (_recordarme ? preferencias.recordarUsuario(usuario) : preferencias.olvidarUsuario());
    }
    if (!mounted) return;
    setState(() {
      _enviando = false;
      _fallo = fallo;
    });
  }

  /// Mensaje del backend para un campo, si lo envió (400 de validación).
  String? _errorDeCampo(String campo) => switch (_fallo) {
    FalloValidacion(:final erroresPorCampo) => erroresPorCampo[campo],
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final estado = ref.watch(proveedorSesion);
    final motivo = estado is SinSesion ? estado.motivo : null;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, limites) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: limites.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    const EncabezadoDomo(),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 448),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                          child: AutofillGroup(
                            child: Form(
                              key: _llaveFormulario,
                              // Tras el primer intento, los errores se actualizan al escribir.
                              autovalidateMode: _intentoEnviar
                                  ? AutovalidateMode.onUserInteraction
                                  : AutovalidateMode.disabled,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Iniciar sesión',
                                    style: textos.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 26,
                                      color: ColoresApp.textoTitulo,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Bienvenido de nuevo. Ingresa tus credenciales para acceder a tu panel.',
                                    style: textos.bodyLarge?.copyWith(color: ColoresApp.textoSecundario, height: 1.5),
                                  ),
                                  const SizedBox(height: 28),
                                  if (_fallo != null)
                                    AvisoEnLinea.error(_fallo!.mensaje)
                                  else if (motivo != null)
                                    AvisoEnLinea.informacion(motivo),
                                  CampoConEtiqueta(
                                    etiqueta: 'Usuario',
                                    obligatorio: true,
                                    campo: TextFormField(
                                      controller: _controladorUsuario,
                                      enabled: !_enviando,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [AutofillHints.username],
                                      onFieldSubmitted: (_) => _focoClave.requestFocus(),
                                      decoration: InputDecoration(
                                        hintText: 'Tu nombre de usuario',
                                        errorText: _errorDeCampo('username'),
                                      ),
                                      validator: (valor) => (valor == null || valor.trim().length < 3)
                                          ? 'Ingresa tu usuario (mínimo 3 caracteres)'
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  CampoConEtiqueta(
                                    etiqueta: 'Contraseña',
                                    obligatorio: true,
                                    campo: TextFormField(
                                      controller: _controladorClave,
                                      focusNode: _focoClave,
                                      enabled: !_enviando,
                                      obscureText: _ocultarClave,
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const [AutofillHints.password],
                                      onFieldSubmitted: (_) => _ingresar(),
                                      decoration: InputDecoration(
                                        hintText: 'Tu contraseña',
                                        errorText: _errorDeCampo('password'),
                                        suffixIcon: IconButton(
                                          tooltip: _ocultarClave ? 'Mostrar contraseña' : 'Ocultar contraseña',
                                          icon: Icon(
                                            _ocultarClave ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                          ),
                                          onPressed: () => setState(() => _ocultarClave = !_ocultarClave),
                                        ),
                                      ),
                                      validator: (valor) =>
                                          (valor == null || valor.length < 3) ? 'Ingresa tu contraseña' : null,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _FilaRecordarYRecuperar(
                                    recordarme: _recordarme,
                                    alCambiarRecordarme: _enviando
                                        ? null
                                        : (valor) => setState(() => _recordarme = valor),
                                    alOlvidarClave: () => mostrarHojaRecuperarClave(context),
                                  ),
                                  const SizedBox(height: 20),
                                  _BotonIngresar(enviando: _enviando, alPresionar: _ingresar),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const _PieDePagina(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilaRecordarYRecuperar extends StatelessWidget {
  const _FilaRecordarYRecuperar({
    required this.recordarme,
    required this.alCambiarRecordarme,
    required this.alOlvidarClave,
  });

  final bool recordarme;
  final ValueChanged<bool>? alCambiarRecordarme;
  final VoidCallback alOlvidarClave;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: alCambiarRecordarme == null ? null : () => alCambiarRecordarme!(!recordarme),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: recordarme,
                onChanged: alCambiarRecordarme == null ? null : (valor) => alCambiarRecordarme!(valor ?? false),
                visualDensity: VisualDensity.compact,
              ),
              const Text('Recuérdame', style: TextStyle(color: ColoresApp.textoEtiqueta, fontSize: 14)),
              const SizedBox(width: 8),
            ],
          ),
        ),
        TextButton(
          onPressed: alOlvidarClave,
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
          child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(fontSize: 14)),
        ),
      ],
    );
  }
}

class _BotonIngresar extends StatelessWidget {
  const _BotonIngresar({required this.enviando, required this.alPresionar});

  final bool enviando;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    // Mientras ingresa sigue verde (como en la web); `_ingresar` ignora toques repetidos.
    return FilledButton(
      onPressed: alPresionar,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: enviando
            ? const Row(
                key: ValueKey('enviando'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  Text('Ingresando...'),
                ],
              )
            : const Text('Ingresar', key: ValueKey('ingresar')),
      ),
    );
  }
}

class _PieDePagina extends StatelessWidget {
  const _PieDePagina();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Text(
        '© ${DateTime.now().year} CostuSoft — Todos los derechos reservados',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11, color: ColoresApp.bordeFuerte),
      ),
    );
  }
}
