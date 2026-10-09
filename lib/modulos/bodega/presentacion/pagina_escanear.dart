import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../compartido/widgets/estados_pantalla.dart';
import '../../../nucleo/errores/fallo.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/utilidades/formatos.dart';
import '../../inventario/dominio/insumo.dart';
import '../../inventario/presentacion/estilos_inventario.dart';
import '../../inventario/presentacion/proveedores_inventario.dart';
import '../dominio/codigo_qr.dart';
import 'proveedores_bodega.dart';
import 'tarjeta_movimiento.dart';

/// Escanea la etiqueta QR de un insumo (o se escribe su código) y muestra su
/// ficha con los movimientos pendientes, para verificar en físico antes de
/// confirmar.
class PaginaEscanear extends ConsumerStatefulWidget {
  const PaginaEscanear({super.key});

  @override
  ConsumerState<PaginaEscanear> createState() => _EstadoPaginaEscanear();
}

class _EstadoPaginaEscanear extends ConsumerState<PaginaEscanear> {
  final _controladorCodigo = TextEditingController();
  MobileScannerController? _camara;
  int? _insumoId;

  @override
  void initState() {
    super.initState();
    _encenderCamara();
  }

  void _encenderCamara() {
    _camara = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  Future<void> _apagarCamara() async {
    final camara = _camara;
    _camara = null;
    await camara?.dispose();
  }

  @override
  void dispose() {
    _controladorCodigo.dispose();
    _camara?.dispose();
    super.dispose();
  }

  void _alDetectar(BarcodeCapture captura) {
    if (_insumoId != null) return;
    final codigo = captura.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
    if (codigo == null) return;
    _mostrarInsumo(codigo);
  }

  Future<void> _mostrarInsumo(String codigo) async {
    final id = idDeInsumoEnCodigo(codigo);
    if (id == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('«$codigo» no es un código de insumo de CostuSoft.')));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _insumoId = id);
    await _apagarCamara(); // Ya se leyó: se libera la cámara.
  }

  void _escanearOtro() {
    _controladorCodigo.clear();
    setState(() {
      _insumoId = null;
      _encenderCamara();
    });
  }

  @override
  Widget build(BuildContext context) {
    final id = _insumoId;
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear insumo')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          if (id == null) ...[
            _VisorCamara(camara: _camara, alDetectar: _alDetectar),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('o escribe el código', style: TextStyle(color: ColoresApp.textoTenue, fontSize: 12.5)),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controladorCodigo,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _mostrarInsumo,
                    decoration: const InputDecoration(
                      hintText: 'Ej.: 48 o costusoft://insumo/48',
                      prefixIcon: Icon(Icons.keyboard_alt_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: () => _mostrarInsumo(_controladorCodigo.text), child: const Text('Buscar')),
              ],
            ),
          ] else ...[
            _FichaInsumo(insumoId: id),
            const SizedBox(height: 16),
            _PendientesDelInsumo(insumoId: id),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _escanearOtro,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Escanear otro insumo'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Vista de la cámara con un recuadro guía y mensajes de error claros.
class _VisorCamara extends StatelessWidget {
  const _VisorCamara({required this.camara, required this.alDetectar});

  final MobileScannerController? camara;
  final void Function(BarcodeCapture) alDetectar;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ColoredBox(
          color: ColoresApp.textoTitulo,
          child: camara == null
              ? const SizedBox.shrink()
              : MobileScanner(
                  controller: camara,
                  onDetect: alDetectar,
                  errorBuilder: (context, error) => _ErrorCamara(error: error),
                  placeholderBuilder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                  overlayBuilder: (context, _) => const _MarcoGuia(),
                ),
        ),
      ),
    );
  }
}

class _MarcoGuia extends StatelessWidget {
  const _MarcoGuia();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 210,
          height: 210,
          decoration: BoxDecoration(
            border: Border.all(color: ColoresApp.verdeClaro, width: 3),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        Positioned(
          bottom: 18,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(99)),
            child: const Text(
              'Apunta a la etiqueta QR del insumo',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorCamara extends StatelessWidget {
  const _ErrorCamara({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final (titulo, detalle) = switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied => (
        'Sin permiso para usar la cámara',
        'Permite el acceso a la cámara en el navegador o en los ajustes del teléfono.',
      ),
      MobileScannerErrorCode.unsupported => (
        'No hay cámara disponible',
        'Este dispositivo no tiene una cámara compatible. Escribe el código abajo.',
      ),
      _ => ('No se pudo abrir la cámara', 'Puedes escribir el código del insumo abajo.'),
    };
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.no_photography_outlined, color: Colors.white70, size: 40),
          const SizedBox(height: 12),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            detalle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _FichaInsumo extends ConsumerWidget {
  const _FichaInsumo({required this.insumoId});

  final int insumoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insumo = ref.watch(proveedorInsumo(insumoId));
    return switch (insumo) {
      AsyncValue(:final value?) => _ContenidoFicha(insumo: value),
      AsyncError(:final error) => EstadoError(
        mensaje: error is FalloNoEncontrado
            ? 'No existe un insumo con el código $insumoId.'
            : (error is Fallo ? error.mensaje : 'No se pudo cargar el insumo.'),
        alReintentar: () => ref.invalidate(proveedorInsumo(insumoId)),
      ),
      _ => const BloqueEsqueleto(alto: 170, radio: 16),
    };
  }
}

class _ContenidoFicha extends StatelessWidget {
  const _ContenidoFicha({required this.insumo});

  final Insumo insumo;

  @override
  Widget build(BuildContext context) {
    final estado = insumo.estado;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code_2_rounded, color: ColoresApp.verde, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Insumo #${insumo.id}',
                  style: const TextStyle(fontSize: 12.5, color: ColoresApp.verde, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                IconoTipoInsumo(tipo: insumo.tipo, tamano: 50),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(insumo.nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      Text(insumo.tipo, style: const TextStyle(color: ColoresApp.textoSecundario)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatos.numero(insumo.stock),
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    color: estado == EstadoStock.disponible ? ColoresApp.textoTitulo : estado.colorTexto,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(insumo.unidadMedida, style: const TextStyle(color: ColoresApp.textoSecundario)),
                ),
                const Spacer(),
                estado.insignia,
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: insumo.nivelRelativo,
                minHeight: 8,
                backgroundColor: ColoresApp.fondoSuave,
                color: estado.colorPunto,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Mínimo: ${Formatos.numero(insumo.stockMinimo)} ${insumo.unidadMedida}',
              style: const TextStyle(fontSize: 12.5, color: ColoresApp.textoSecundario),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendientesDelInsumo extends ConsumerWidget {
  const _PendientesDelInsumo({required this.insumoId});

  final int insumoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendientes = ref.watch(proveedorMovimientosPendientes);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Movimientos pendientes de este insumo',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        switch (pendientes) {
          AsyncValue(:final value?) when value.conInsumo(insumoId).isEmpty => Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: ColoresApp.fondoSuave, borderRadius: BorderRadius.circular(12)),
            child: const Text(
              'No hay entradas ni salidas pendientes con este insumo.',
              style: TextStyle(color: ColoresApp.textoSecundario, fontSize: 13.5),
            ),
          ),
          AsyncValue(:final value?) => Column(
            children: [
              for (final m in value.conInsumo(insumoId))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TarjetaMovimiento(movimiento: m),
                ),
            ],
          ),
          AsyncError(:final error) => Text(
            error is Fallo ? error.mensaje : 'No se pudieron cargar los pendientes.',
            style: const TextStyle(color: ColoresApp.error),
          ),
          _ => const BloqueEsqueleto(alto: 76, radio: 12),
        },
      ],
    );
  }
}
