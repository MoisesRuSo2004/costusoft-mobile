import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../compartido/widgets/aviso_despertando_motor.dart';
import '../../../compartido/widgets/estados_pantalla.dart';
import '../../../nucleo/errores/fallo.dart';
import '../../../nucleo/red/despertar_motor.dart';
import '../../../nucleo/tema/colores_app.dart';
import '../../../nucleo/utilidades/formatos.dart';
import '../../autenticacion/dominio/estado_sesion.dart';
import '../../autenticacion/dominio/rol_usuario.dart';
import '../../autenticacion/presentacion/controlador_sesion.dart';
import '../dominio/insumo.dart';
import '../dominio/prediccion_insumo.dart';
import 'estilos_inventario.dart';
import 'graficas_insumo.dart';
import 'hoja_ajustar_stock.dart';
import 'hoja_etiqueta_qr.dart';
import 'proveedores_inventario.dart';

/// Detalle de un insumo con su análisis de IA (Prophet + XGBoost).
class PaginaDetalleInsumo extends ConsumerWidget {
  const PaginaDetalleInsumo({super.key, required this.insumoId});

  final int insumoId;

  Future<void> _actualizar(WidgetRef ref) async {
    ref.invalidate(proveedorPrediccion(insumoId));
    try {
      ref.invalidate(proveedorInsumos);
      await ref.read(proveedorInsumos.future);
    } on Fallo {
      // La lista anterior se conserva; el error ya se ve en pantalla si aplica.
    }
  }

  Future<void> _ajustarStock(BuildContext context, WidgetRef ref, Insumo insumo) async {
    final actualizado = await mostrarHojaAjustarStock(context, insumo);
    if (actualizado == null || !context.mounted) return;
    // El riesgo depende del stock: se recalcula.
    ref
      ..invalidate(proveedorPrediccion(insumoId))
      ..invalidate(proveedorPredicciones);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Stock actualizado: ${Formatos.numero(actualizado.stock)} ${actualizado.unidadMedida}')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insumo = ref.watch(proveedorInsumo(insumoId));
    final sesion = ref.watch(proveedorSesion);
    final esAdministrador = sesion is SesionActiva && sesion.usuario.rol == RolUsuario.administrador;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del insumo'),
        actions: [
          if (insumo.value case final valor?)
            IconButton(
              tooltip: 'Etiqueta QR',
              onPressed: () => mostrarEtiquetaQr(context, valor),
              icon: const Icon(Icons.qr_code_2_rounded),
            ),
        ],
      ),
      body: switch (insumo) {
        AsyncValue(:final value?) => RefreshIndicator(
          color: ColoresApp.verde,
          onRefresh: () => _actualizar(ref),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _Encabezado(insumo: value),
              const SizedBox(height: 14),
              _TarjetaStock(insumo: value),
              const SizedBox(height: 14),
              if (ref.watch(proveedorVeAnalisisIa)) _TarjetaAnalisisIa(insumo: value),
              if (esAdministrador) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => _ajustarStock(context, ref, value),
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text('Ajustar stock'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Úsalo para corregir el stock después de un conteo físico.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: ColoresApp.textoTenue),
                ),
              ],
            ],
          ),
        ),
        AsyncError(:final error) => EstadoError(
          mensaje: error is Fallo ? error.mensaje : 'No se pudo cargar el insumo.',
          alReintentar: () => ref.invalidate(proveedorInsumo(insumoId)),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.insumo});

  final Insumo insumo;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconoTipoInsumo(tipo: insumo.tipo, tamano: 56),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                insumo.nombre,
                style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w600, color: ColoresApp.textoTitulo),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  insumo.estado.insignia,
                  Text(insumo.tipo, style: const TextStyle(fontSize: 13, color: ColoresApp.textoSecundario)),
                  if (insumo.actualizadoEn != null)
                    Text(
                      '· actualizado ${Formatos.haceCuanto(insumo.actualizadoEn!)}',
                      style: const TextStyle(fontSize: 13, color: ColoresApp.textoTenue),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Stock actual frente al mínimo, con barra y mensaje claro.
class _TarjetaStock extends StatelessWidget {
  const _TarjetaStock({required this.insumo});

  final Insumo insumo;

  @override
  Widget build(BuildContext context) {
    final estado = insumo.estado;
    final diferencia = insumo.stock - insumo.stockMinimo;
    final mensaje = switch (estado) {
      EstadoStock.sinStock =>
        'No queda stock. Se necesitan al menos '
            '${Formatos.numero(insumo.stockMinimo)} ${insumo.unidadMedida}.',
      EstadoStock.stockBajo =>
        'Faltan ${Formatos.numero(-diferencia)} ${insumo.unidadMedida} '
            'para volver al mínimo.',
      EstadoStock.disponible => '${Formatos.numero(diferencia)} ${insumo.unidadMedida} por encima del mínimo.',
    };

    return _Seccion(
      titulo: 'Stock',
      icono: Icons.inventory_2_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatos.numero(insumo.stock),
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  color: estado == EstadoStock.disponible ? ColoresApp.textoTitulo : estado.colorTexto,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  insumo.unidadMedida,
                  style: const TextStyle(fontSize: 15, color: ColoresApp.textoSecundario),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Mínimo', style: TextStyle(fontSize: 12, color: ColoresApp.textoTenue)),
                  Text(
                    '${Formatos.numero(insumo.stockMinimo)} ${insumo.unidadMedida}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ColoresApp.textoEtiqueta),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _BarraStock(insumo: insumo),
          const SizedBox(height: 12),
          Text(mensaje, style: TextStyle(fontSize: 13.5, color: estado.colorTexto, height: 1.4)),
        ],
      ),
    );
  }
}

/// Barra con una marca vertical en el stock mínimo (que queda a la mitad).
class _BarraStock extends StatelessWidget {
  const _BarraStock({required this.insumo});

  final Insumo insumo;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, limites) {
        final ancho = limites.maxWidth;
        return SizedBox(
          height: 30,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: insumo.nivelRelativo,
                    minHeight: 10,
                    backgroundColor: ColoresApp.fondoSuave,
                    color: insumo.estado.colorPunto,
                  ),
                ),
              ),
              Positioned(
                left: ancho / 2 - 1,
                top: 0,
                child: Container(width: 2, height: 18, color: ColoresApp.textoEtiqueta),
              ),
              Positioned(
                left: ancho / 2 - 30,
                width: 60,
                bottom: 0,
                child: const Text(
                  'mínimo',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10.5, color: ColoresApp.textoSecundario),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Resultado de los modelos de IA para el insumo.
class _TarjetaAnalisisIa extends ConsumerWidget {
  const _TarjetaAnalisisIa({required this.insumo});

  final Insumo insumo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prediccion = ref.watch(proveedorPrediccion(insumo.id));
    final segundosDespertando = ref.watch(proveedorDespertarMotor);

    return _Seccion(
      titulo: 'Análisis de IA',
      icono: Icons.auto_awesome_rounded,
      colorIcono: ColoresApp.verde,
      child: switch (prediccion) {
        AsyncValue(:final value?) => _ContenidoAnalisis(insumo: insumo, prediccion: value),
        AsyncError(:final error) => Column(
          children: [
            Text(
              // Solo mensajes pensados para el usuario; nunca el detalle técnico.
              switch (error) {
                FalloServicioIniciando(:final mensaje) || FalloRed(:final mensaje) || FalloNoAutorizado(:final mensaje) => mensaje,
                _ => 'No se pudo obtener el análisis de IA. Intenta de nuevo.',
              },
              style: const TextStyle(color: ColoresApp.textoSecundario),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(proveedorPrediccion(insumo.id)),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
        _ when segundosDespertando != null => AvisoDespertandoMotor(segundos: segundosDespertando),
        _ => const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BloqueEsqueleto(ancho: 140, alto: 28, radio: 99),
            SizedBox(height: 14),
            BloqueEsqueleto(alto: 14),
            SizedBox(height: 8),
            BloqueEsqueleto(ancho: 220, alto: 14),
            SizedBox(height: 16),
            BloqueEsqueleto(alto: 120, radio: 12),
          ],
        ),
      },
    );
  }
}

class _ContenidoAnalisis extends StatelessWidget {
  const _ContenidoAnalisis({required this.insumo, required this.prediccion});

  final Insumo insumo;
  final PrediccionInsumo prediccion;

  @override
  Widget build(BuildContext context) {
    final nivel = prediccion.nivelRiesgo;
    final hayConsumoReciente = prediccion.consumo90Dias > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: nivel.fondo, borderRadius: BorderRadius.circular(99)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                nivel.esPreocupante ? Icons.warning_amber_rounded : Icons.verified_rounded,
                color: nivel.color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Riesgo ${nivel.etiqueta.toLowerCase()}',
                style: TextStyle(fontWeight: FontWeight.w700, color: nivel.color),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(prediccion.mensaje, style: const TextStyle(fontSize: 14.5, color: ColoresApp.textoTitulo, height: 1.45)),
        const SizedBox(height: 16),
        _CuadriculaIndicadores(insumo: insumo, prediccion: prediccion),
        if (prediccion.recomendacion.isNotEmpty) ...[
          const SizedBox(height: 16),
          _Recomendacion(texto: prediccion.recomendacion, urgente: prediccion.alerta),
        ],
        const SizedBox(height: 20),
        const Text(
          'Consumo promedio por día',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ColoresApp.textoEtiqueta),
        ),
        const SizedBox(height: 4),
        Text(
          hayConsumoReciente
              ? 'Compara el consumo de la última semana con el del último mes y trimestre.'
              : 'No hay consumo registrado en los últimos 90 días.',
          style: const TextStyle(fontSize: 12.5, color: ColoresApp.textoSecundario),
        ),
        if (hayConsumoReciente) ...[
          const SizedBox(height: 12),
          GraficaConsumo(prediccion: prediccion, unidad: insumo.unidadMedida),
        ],
        if (prediccion.hayConsumo) ...[
          const SizedBox(height: 20),
          const Text(
            'Proyección del stock',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ColoresApp.textoEtiqueta),
          ),
          const SizedBox(height: 12),
          GraficaProyeccion(insumo: insumo, prediccion: prediccion),
        ],
        const SizedBox(height: 16),
        Text(
          'Pronóstico: Prophet'
          '${prediccion.confianza != null ? ' (confianza ${(prediccion.confianza! * 100).round()} %)' : ''}'
          ' · Riesgo: ${prediccion.modeloEntrenado ? 'XGBoost' : 'reglas de negocio (XGBoost en entrenamiento)'}',
          style: const TextStyle(fontSize: 11.5, color: ColoresApp.textoTenue),
        ),
      ],
    );
  }
}

class _CuadriculaIndicadores extends StatelessWidget {
  const _CuadriculaIndicadores({required this.insumo, required this.prediccion});

  final Insumo insumo;
  final PrediccionInsumo prediccion;

  @override
  Widget build(BuildContext context) {
    final indicadores = [
      (
        'Llega al mínimo',
        prediccion.diasHastaMinimo == null
            ? 'Sin fecha'
            : prediccion.diasHastaMinimo! <= 0
            ? 'Ya está por debajo'
            : 'en ${Formatos.dias(prediccion.diasHastaMinimo!)}',
        prediccion.fechaAlerta == null ? null : Formatos.fecha(prediccion.fechaAlerta!),
      ),
      (
        'Se agota',
        prediccion.diasHastaCero == null ? 'Sin fecha' : 'en ${Formatos.dias(prediccion.diasHastaCero!)}',
        prediccion.fechaAgotamiento == null ? null : Formatos.fecha(prediccion.fechaAgotamiento!),
      ),
      (
        'Consumo diario',
        '${Formatos.numero(double.parse(prediccion.consumoDiario.toStringAsFixed(2)))} ${insumo.unidadMedida}',
        'promedio estimado',
      ),
      ('Últimos 30 días', '${Formatos.numero(prediccion.consumo30Dias)} ${insumo.unidadMedida}', 'consumidos'),
    ];

    return LayoutBuilder(
      builder: (context, limites) {
        final anchoCelda = (limites.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (titulo, valor, detalle) in indicadores)
              Container(
                width: anchoCelda,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: ColoresApp.fondoSuave, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: const TextStyle(fontSize: 12, color: ColoresApp.textoSecundario)),
                    const SizedBox(height: 4),
                    Text(
                      valor,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ColoresApp.textoTitulo),
                    ),
                    if (detalle != null)
                      Text(detalle, style: const TextStyle(fontSize: 11.5, color: ColoresApp.textoTenue)),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Recomendacion extends StatelessWidget {
  const _Recomendacion({required this.texto, required this.urgente});

  final String texto;
  final bool urgente;

  @override
  Widget build(BuildContext context) {
    final color = urgente ? ColoresApp.stockBajoTexto : ColoresApp.disponibleTexto;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: urgente ? ColoresApp.stockBajoFondo : ColoresApp.disponibleFondo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recomendación',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color),
                ),
                const SizedBox(height: 2),
                Text(texto, style: TextStyle(fontSize: 13.5, color: color, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta blanca con título e icono, usada por cada bloque del detalle.
class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.icono, required this.child, this.colorIcono});

  final String titulo;
  final IconData icono;
  final Color? colorIcono;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, size: 18, color: colorIcono ?? ColoresApp.azulMarino),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ColoresApp.textoTitulo),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
