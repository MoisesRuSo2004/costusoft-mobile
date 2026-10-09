import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../compartido/widgets/texto_markdown.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/utilidades/formatos.dart';
import '../dominio/entidades_ia.dart';
import 'proveedores_ia.dart';

/// Conversación con el agente de IA: resumen del día, consultas rápidas
/// sobre el inventario y preguntas libres.
///
/// Con [sugerencias] queda en modo institucional (coordinador de un colegio):
/// sin resumen del día ni consultas del taller, solo esas preguntas sugeridas.
class PestanaAsistente extends ConsumerStatefulWidget {
  const PestanaAsistente({super.key, this.sugerencias, this.ejemplo = '¿Qué insumos debo comprar esta semana?'});

  final List<String>? sugerencias;

  /// Pregunta de ejemplo en la invitación a escribir.
  final String ejemplo;

  @override
  ConsumerState<PestanaAsistente> createState() => _EstadoPestanaAsistente();
}

class _EstadoPestanaAsistente extends ConsumerState<PestanaAsistente> with AutomaticKeepAliveClientMixin {
  final _controladorTexto = TextEditingController();
  final _desplazamiento = ScrollController();

  @override
  bool get wantKeepAlive => true; // Conserva la conversación al cambiar de pestaña.

  @override
  void dispose() {
    _controladorTexto.dispose();
    _desplazamiento.dispose();
    super.dispose();
  }

  void _bajarAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_desplazamiento.hasClients) return;
      _desplazamiento.animateTo(
        _desplazamiento.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _enviarPregunta([String? sugerida]) async {
    final pregunta = (sugerida ?? _controladorTexto.text).trim();
    if (pregunta.isEmpty) return;
    if (sugerida == null) _controladorTexto.clear();
    setState(() {});
    final chat = ref.read(proveedorChat.notifier).preguntar(pregunta);
    _bajarAlFinal();
    await chat;
    _bajarAlFinal();
  }

  Future<void> _ejecutar(Future<void> Function() accion) async {
    final tarea = accion();
    _bajarAlFinal();
    await tarea;
    _bajarAlFinal();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final mensajes = ref.watch(proveedorChat);
    final respondiendo = mensajes.any((m) => m.esperando);
    final controlador = ref.read(proveedorChat.notifier);
    final sugerencias = widget.sugerencias;

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _desplazamiento,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            children: [
              if (sugerencias == null) ...[const _TarjetaResumenDelDia(), const SizedBox(height: 18)],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      sugerencias == null ? 'Consultas rápidas' : 'Preguntas sugeridas',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ColoresApp.textoEtiqueta,
                      ),
                    ),
                  ),
                  if (mensajes.isNotEmpty)
                    TextButton.icon(
                      onPressed: respondiendo ? null : controlador.limpiar,
                      icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                      label: const Text('Limpiar chat'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (sugerencias case final preguntas?)
                    for (final pregunta in preguntas)
                      _FichaConsulta(
                        etiqueta: pregunta,
                        ayuda: 'Preguntar al asistente',
                        icono: Icons.chat_bubble_outline_rounded,
                        alTocar: respondiendo ? null : () => _enviarPregunta(pregunta),
                      )
                  else ...[
                    for (final tipo in TipoConsultaIa.values)
                      _FichaConsulta(
                        etiqueta: tipo.etiqueta,
                        ayuda: tipo.descripcion,
                        alTocar: respondiendo ? null : () => _ejecutar(() => controlador.consultar(tipo)),
                      ),
                    _FichaConsulta(
                      etiqueta: 'Orden de compra',
                      ayuda: 'Orden sugerida con los insumos en stock bajo',
                      icono: Icons.receipt_long_outlined,
                      alTocar: respondiendo ? null : () => _ejecutar(controlador.generarOrdenCompra),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              if (mensajes.isEmpty)
                _InvitacionAPreguntar(ejemplo: widget.ejemplo)
              else
                for (final mensaje in mensajes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: mensaje.autor == AutorMensaje.usuario
                        ? _BurbujaUsuario(texto: mensaje.texto)
                        : _BurbujaAsistente(mensaje: mensaje),
                  ),
            ],
          ),
        ),
        _BarraPregunta(
          controlador: _controladorTexto,
          habilitada: !respondiendo,
          alCambiar: () => setState(() {}),
          alEnviar: _enviarPregunta,
        ),
      ],
    );
  }
}

class _TarjetaResumenDelDia extends ConsumerWidget {
  const _TarjetaResumenDelDia();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumen = ref.watch(proveedorResumenDelDia);
    final controlador = ref.read(proveedorResumenDelDia.notifier);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ColoresApp.azulMedio, ColoresApp.azulMarino, ColoresApp.azulProfundo],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColoresApp.verdeClaro.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.wb_sunny_outlined, color: ColoresApp.verdeClaro, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumen del día',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Prioridades, insumos críticos y pedidos',
                      style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              if (resumen is AsyncData<RespuestaIa>)
                IconButton(
                  tooltip: 'Generar de nuevo',
                  onPressed: controlador.generar,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                ),
            ],
          ),
          const SizedBox(height: 14),
          switch (resumen) {
            null => FilledButton.icon(
              onPressed: controlador.generar,
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: const Text('Generar resumen'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
            ),
            AsyncData(:final value) => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextoMarkdown(value.texto),
                  _PieRespuesta(respuesta: value),
                ],
              ),
            ),
            AsyncError(:final error) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mensajeDeError(error), style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: controlador.generar,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                  ),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
            _ => const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                ),
                SizedBox(width: 12),
                Text('Analizando el inventario…', style: TextStyle(color: Colors.white)),
              ],
            ),
          },
        ],
      ),
    );
  }
}

class _FichaConsulta extends StatelessWidget {
  const _FichaConsulta({required this.etiqueta, required this.ayuda, required this.alTocar, this.icono});

  final String etiqueta;
  final String ayuda;
  final VoidCallback? alTocar;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: ayuda,
      child: ActionChip(
        avatar: Icon(icono ?? Icons.auto_awesome_outlined, size: 16, color: ColoresApp.verde),
        label: Text(etiqueta),
        onPressed: alTocar,
        backgroundColor: ColoresApp.fondo,
        side: const BorderSide(color: ColoresApp.borde),
        shape: const StadiumBorder(),
        labelStyle: const TextStyle(fontSize: 13, color: ColoresApp.textoEtiqueta, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _InvitacionAPreguntar extends StatelessWidget {
  const _InvitacionAPreguntar({required this.ejemplo});

  final String ejemplo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: ColoresApp.fondoSuave, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          const Icon(Icons.chat_bubble_outline_rounded, color: ColoresApp.textoTenue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Toca una sugerencia o escribe tu pregunta, por ejemplo: «$ejemplo»',
              style: const TextStyle(color: ColoresApp.textoSecundario, fontSize: 13.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _BurbujaUsuario extends StatelessWidget {
  const _BurbujaUsuario({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: ColoresApp.verde,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(texto, style: const TextStyle(color: Colors.white, fontSize: 14.5, height: 1.4)),
        ),
      ),
    );
  }
}

class _BurbujaAsistente extends StatelessWidget {
  const _BurbujaAsistente({required this.mensaje});

  final MensajeChat mensaje;

  @override
  Widget build(BuildContext context) {
    final contenido = mensaje.esperando
        ? const _Escribiendo()
        : mensaje.error != null
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline_rounded, color: ColoresApp.error, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(mensaje.error!, style: const TextStyle(color: ColoresApp.error)),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextoMarkdown(mensaje.texto),
              if (mensaje.respuesta != null) _PieRespuesta(respuesta: mensaje.respuesta!),
            ],
          );

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ColoresApp.fondo,
          border: Border.all(color: ColoresApp.borde),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 16, color: ColoresApp.verde),
                const SizedBox(width: 6),
                Text(
                  mensaje.titulo ?? 'Asistente CostuSoft',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: ColoresApp.verde),
                ),
                const Spacer(),
                if (!mensaje.esperando && mensaje.error == null)
                  IconButton(
                    tooltip: 'Copiar respuesta',
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    color: ColoresApp.textoTenue,
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: mensaje.texto));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Respuesta copiada')));
                      }
                    },
                    icon: const Icon(Icons.copy_rounded),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            contenido,
          ],
        ),
      ),
    );
  }
}

/// "modelo · 3,7 s" bajo cada respuesta.
class _PieRespuesta extends StatelessWidget {
  const _PieRespuesta({required this.respuesta});

  final RespuestaIa respuesta;

  @override
  Widget build(BuildContext context) {
    final partes = [
      if (respuesta.modelo != null) respuesta.modelo!,
      if (respuesta.tiempo != null)
        '${Formatos.numero(double.parse((respuesta.tiempo!.inMilliseconds / 1000).toStringAsFixed(1)))} s',
    ];
    if (partes.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(partes.join(' · '), style: const TextStyle(fontSize: 11, color: ColoresApp.textoTenue)),
    );
  }
}

/// Tres puntos animados mientras la IA responde.
class _Escribiendo extends StatefulWidget {
  const _Escribiendo();

  @override
  State<_Escribiendo> createState() => _EstadoEscribiendo();
}

class _EstadoEscribiendo extends State<_Escribiendo> with SingleTickerProviderStateMixin {
  late final AnimationController _animacion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _animacion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _animacion,
          builder: (_, _) => Row(
            children: [
              for (var i = 0; i < 3; i++)
                Container(
                  margin: const EdgeInsets.only(right: 5),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ColoresApp.verde.withValues(
                      alpha: 0.3 + 0.7 * (((_animacion.value * 3 - i) % 3) < 1 ? 1 : 0),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Text('Analizando…', style: TextStyle(fontSize: 13, color: ColoresApp.textoSecundario)),
      ],
    );
  }
}

class _BarraPregunta extends StatelessWidget {
  const _BarraPregunta({
    required this.controlador,
    required this.habilitada,
    required this.alCambiar,
    required this.alEnviar,
  });

  final TextEditingController controlador;
  final bool habilitada;
  final VoidCallback alCambiar;
  final VoidCallback alEnviar;

  @override
  Widget build(BuildContext context) {
    final puedeEnviar = habilitada && controlador.text.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: const BoxDecoration(
        color: ColoresApp.fondo,
        border: Border(top: BorderSide(color: ColoresApp.borde)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controlador,
                enabled: habilitada,
                minLines: 1,
                maxLines: 4,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onChanged: (_) => alCambiar(),
                onSubmitted: (_) => alEnviar(),
                decoration: const InputDecoration(
                  hintText: 'Pregúntale al asistente…',
                  counterText: '',
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Enviar',
              onPressed: puedeEnviar ? alEnviar : null,
              style: IconButton.styleFrom(
                backgroundColor: ColoresApp.verde,
                disabledBackgroundColor: ColoresApp.borde,
                fixedSize: const Size(48, 48),
              ),
              icon: const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
