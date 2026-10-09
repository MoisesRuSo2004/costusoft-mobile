import 'dart:async';

import 'package:costusoft_mobile/compartido/widgets/encabezado_domo.dart';
import 'package:costusoft_mobile/modulos/autenticacion/dominio/repositorio_autenticacion.dart';
import 'package:costusoft_mobile/modulos/autenticacion/dominio/usuario.dart';
import 'package:costusoft_mobile/modulos/autenticacion/presentacion/controlador_sesion.dart';
import 'package:costusoft_mobile/modulos/carga/presentacion/cortina_inicio.dart';
import 'package:costusoft_mobile/modulos/carga/presentacion/logo_animado.dart';
import 'package:costusoft_mobile/nucleo/errores/fallo.dart';
import 'package:costusoft_mobile/nucleo/errores/resultado.dart';
import 'package:costusoft_mobile/nucleo/red/verificador_servidor.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _VerificadorFalso extends VerificadorServidor {
  _VerificadorFalso(this.respuestas) : super(Dio());

  /// Una respuesta por llamada; la última se repite.
  final List<Resultado<Duration>> respuestas;
  int llamadas = 0;

  @override
  Future<Resultado<Duration>> verificar({Duration? tiempoMaximo}) async =>
      respuestas[(llamadas++).clamp(0, respuestas.length - 1)];
}

class _RepositorioFalso implements RepositorioAutenticacion {
  final restauracion = Completer<Resultado<Usuario?>>();

  @override
  Future<Resultado<Usuario?>> restaurarSesion() => restauracion.future;

  @override
  Stream<void> get sesionExpirada => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocacion) => super.noSuchMethod(invocacion);
}

void main() {
  late _RepositorioFalso repositorio;

  Future<void> montar(WidgetTester tester, {List<Resultado<Duration>>? servidor}) async {
    repositorio = _RepositorioFalso();
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          proveedorRepositorioAutenticacion.overrideWithValue(repositorio),
          proveedorVerificadorServidor.overrideWithValue(
            _VerificadorFalso(servidor ?? [const Exito(Duration(milliseconds: 50))]),
          ),
          // Sin decodificar imágenes en la prueba: la intro corre igual.
          proveedorCapasLogo.overrideWith((ref) => Future<CapasLogo>.error('sin imágenes')),
        ],
        child: const MaterialApp(home: CortinaInicio(child: Text('Página de destino'))),
      ),
    );
    await tester.pump(); // carga de las capas: arranca la intro
  }

  /// Avanza [duracion] en cuadros de 100 ms, como haría la pantalla.
  Future<void> avanzar(WidgetTester tester, Duration duracion) async {
    for (var t = Duration.zero; t < duracion; t += const Duration(milliseconds: 100)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  bool cortinaVisible() => find.byType(DomoAzul).evaluate().isNotEmpty;

  testWidgets('sin sesión: termina la intro, sube y deja ver la página', (tester) async {
    await montar(tester);
    repositorio.restauracion.complete(const Exito(null));
    await tester.pump();
    expect(cortinaVisible(), isTrue);

    await avanzar(tester, const Duration(milliseconds: 1000));
    expect(cortinaVisible(), isTrue, reason: 'la intro se ve completa aunque el servidor ya respondió');

    await avanzar(tester, const Duration(milliseconds: 1100)); // fin de la intro
    await avanzar(tester, const Duration(milliseconds: 1200)); // subida
    await tester.pump();
    expect(cortinaVisible(), isFalse);
    expect(find.text('Página de destino'), findsOneWidget);
  });

  testWidgets('servidor lento: espera con el logo y avisa que está conectando', (tester) async {
    await montar(tester);
    await avanzar(tester, const Duration(milliseconds: 2200));
    await avanzar(tester, const Duration(milliseconds: 400));
    expect(find.text('Conectando con CostuSoft…'), findsOneWidget);

    await avanzar(tester, const Duration(seconds: 6));
    expect(find.text('Despertando el servidor, puede tardar unos segundos…'), findsOneWidget);

    repositorio.restauracion.complete(const Exito(null));
    await avanzar(tester, const Duration(milliseconds: 1600));
    expect(cortinaVisible(), isFalse);
  });

  testWidgets('error del servidor: muestra el mensaje y Reintentar vuelve a verificar', (tester) async {
    await montar(
      tester,
      servidor: [const Falla(FalloServidor('Servidor en mantenimiento.')), const Exito(Duration(milliseconds: 50))],
    );
    await avanzar(tester, const Duration(milliseconds: 2200));
    await avanzar(tester, const Duration(milliseconds: 400));
    expect(find.text('Servidor en mantenimiento.'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    repositorio.restauracion.complete(const Exito(null));
    await avanzar(tester, const Duration(milliseconds: 1600));
    expect(cortinaVisible(), isFalse);
  });
}
