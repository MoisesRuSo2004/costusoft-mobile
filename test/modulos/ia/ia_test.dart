import 'dart:async';

import 'package:costusoft_mobile/modulos/autenticacion/dominio/estado_sesion.dart';
import 'package:costusoft_mobile/modulos/autenticacion/presentacion/controlador_sesion.dart';
import 'package:costusoft_mobile/modulos/ia/datos/modelos_ia.dart';
import 'package:costusoft_mobile/modulos/ia/dominio/entidades_ia.dart';
import 'package:costusoft_mobile/modulos/ia/dominio/repositorio_ia.dart';
import 'package:costusoft_mobile/modulos/ia/presentacion/proveedores_ia.dart';
import 'package:costusoft_mobile/nucleo/errores/fallo.dart';
import 'package:costusoft_mobile/nucleo/errores/resultado.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _RepositorioIaFalso implements RepositorioIa {
  Completer<Resultado<RespuestaIa>> pendiente = Completer();
  final preguntas = <String>[];

  @override
  Future<Resultado<RespuestaIa>> preguntar(String pregunta) {
    preguntas.add(pregunta);
    return pendiente.future;
  }

  @override
  Future<Resultado<RespuestaIa>> consultar(TipoConsultaIa tipo) => pendiente.future;

  @override
  Future<Resultado<RespuestaIa>> generarOrdenCompra() => pendiente.future;

  @override
  Future<Resultado<RespuestaIa>> obtenerResumenDelDia() => pendiente.future;
}

void main() {
  group('lectura de la optimización (snake_case del backend)', () {
    test('respuesta de POST /api/optimizacion', () {
      final plan = planDesdeRespuesta({
        'id': 181,
        'colegio_id': 5,
        'nombre_colegio': 'IE John F. Kennedy',
        'estado': 'OPTIMAL',
        'utilidad_total': 28000.0,
        'plan': {'blusa_diario_femenino': 1, 'pantalon_ef': 0},
        'recursos': {
          'tela_drill': {'usado': 10, 'disponible': 10, 'holgura': 0, 'utilizacion_pct': 100, 'unidad_medida': 'm'},
          'hilo': {'usado': 2, 'disponible': 10, 'holgura': 8, 'utilizacion_pct': 20, 'unidad_medida': 'conos'},
        },
        'insumo_labels': {'tela_drill': 'Tela Drill'},
        'mensaje': 'Solución óptima.',
        'fecha_ejecucion': '2026-10-08T13:00:00',
      });
      expect(plan.esOptimo, isTrue);
      expect(plan.totalPrendas, 1);
      expect(plan.usoInsumos.first.nombre, 'Tela Drill', reason: 'usa la etiqueta y ordena por utilización');
      expect(plan.usoInsumos.first.esLimitante, isTrue);
      expect(plan.usoInsumos.last.esLimitante, isFalse);
    });

    test('elemento del historial (otras claves)', () {
      final plan = planDesdeHistorial({
        'id': 180,
        'estado_solucion': 'OPTIMAL',
        'utilidad_total': 28000.0,
        'nombre_colegio': 'IE John F. Kennedy',
        'plan_produccion': {'blusa_diario_femenino': 1, 'falda_diario_femenino': 1},
        'fecha_ejecucion': '2026-10-03T19:39:36.796679',
      });
      expect(plan.totalPrendas, 2);
      expect(plan.fecha, isNotNull);
    });

    test('nombres legibles de prendas', () {
      expect(nombrePrenda('pantalon_diario_masculino'), 'Pantalón diario masculino');
      expect(nombrePrenda('sueter_educacion_fisica'), 'Suéter educación física');
      expect(nombrePrenda('x3_pantalon_ef'), 'X3 pantalón educación física');
    });
  });

  group('conversación con el asistente', () {
    late _RepositorioIaFalso repositorio;
    late ProviderContainer contenedor;

    setUp(() {
      repositorio = _RepositorioIaFalso();
      contenedor = ProviderContainer(
        overrides: [
          proveedorRepositorioIa.overrideWithValue(repositorio),
          // El chat se reinicia al cambiar de usuario: aquí no hay sesión real.
          proveedorSesion.overrideWith(_SesionFalsa.new),
        ],
      );
    });
    tearDown(() => contenedor.dispose());

    test('muestra la pregunta y "escribiendo", luego la respuesta', () async {
      final chat = contenedor.read(proveedorChat.notifier);
      final envio = chat.preguntar('  ¿Qué compro?  ');

      var mensajes = contenedor.read(proveedorChat);
      expect(mensajes.map((m) => m.autor), [AutorMensaje.usuario, AutorMensaje.asistente]);
      expect(mensajes.first.texto, '¿Qué compro?');
      expect(mensajes.last.esperando, isTrue);

      repositorio.pendiente.complete(const Exito(RespuestaIa(texto: '**Hilo verde**')));
      await envio;

      mensajes = contenedor.read(proveedorChat);
      expect(mensajes.last.esperando, isFalse);
      expect(mensajes.last.texto, '**Hilo verde**');
    });

    test('un error de la IA queda en la burbuja, sin perder la pregunta', () async {
      final envio = contenedor.read(proveedorChat.notifier).preguntar('hola');
      repositorio.pendiente.complete(const Falla(FalloServidor('Límite diario de Groq')));
      await envio;

      final mensajes = contenedor.read(proveedorChat);
      expect(mensajes, hasLength(2));
      expect(mensajes.last.error, 'Límite diario de Groq');
    });

    test('no envía otra pregunta mientras la IA responde', () async {
      final chat = contenedor.read(proveedorChat.notifier);
      final primera = chat.preguntar('primera');
      await chat.preguntar('segunda');
      expect(repositorio.preguntas, ['primera']);

      repositorio.pendiente.complete(const Exito(RespuestaIa(texto: 'ok')));
      await primera;
    });
  });
}

class _SesionFalsa extends ControladorSesion {
  @override
  EstadoSesion build() => const SinSesion();
}
