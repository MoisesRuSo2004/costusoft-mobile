import 'package:costusoft_mobile/modulos/autenticacion/dominio/estado_sesion.dart';
import 'package:costusoft_mobile/modulos/autenticacion/dominio/rol_usuario.dart';
import 'package:costusoft_mobile/modulos/autenticacion/dominio/usuario.dart';
import 'package:costusoft_mobile/modulos/autenticacion/presentacion/controlador_sesion.dart';
import 'package:costusoft_mobile/modulos/autenticacion/presentacion/guardia_inactividad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sesión activa de prueba que registra los cierres por inactividad.
class _SesionFalsa extends ControladorSesion {
  int cierresPorInactividad = 0;

  @override
  EstadoSesion build() => const SesionActiva(
    Usuario(id: 1, nombreUsuario: 'admin', correo: 'admin@costusoft.test', rol: RolUsuario.administrador),
  );

  @override
  Future<void> cerrarPorInactividad() async {
    cierresPorInactividad++;
    state = const SinSesion(motivo: 'Tu sesión se cerró por inactividad. Inicia sesión de nuevo.');
  }
}

void main() {
  late DateTime reloj;
  late _SesionFalsa sesion;

  Future<void> montar(WidgetTester tester) async {
    reloj = DateTime(2026, 10, 9, 8);
    sesion = _SesionFalsa();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [proveedorSesion.overrideWith(() => sesion)],
        child: MaterialApp(
          home: GuardiaInactividad(
            limite: const Duration(minutes: 30),
            aviso: const Duration(minutes: 5),
            revision: const Duration(seconds: 1),
            ahora: () => reloj,
            child: const Scaffold(body: Center(child: Text('Inventario'))),
          ),
        ),
      ),
    );
  }

  Future<void> esperar(WidgetTester tester, Duration tiempo) async {
    reloj = reloj.add(tiempo);
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('avisa 5 minutos antes y cierra la sesión al cumplirse 30', (tester) async {
    await montar(tester);
    await esperar(tester, const Duration(minutes: 24));
    expect(find.text('¿Sigues ahí?'), findsNothing);

    await esperar(tester, const Duration(minutes: 1, seconds: 30));
    expect(find.text('¿Sigues ahí?'), findsOneWidget);
    expect(find.textContaining('4:30'), findsOneWidget);

    await esperar(tester, const Duration(minutes: 5));
    expect(sesion.cierresPorInactividad, 1);
    expect(find.text('¿Sigues ahí?'), findsNothing);
  });

  testWidgets('"Seguir conectado" reinicia el tiempo', (tester) async {
    await montar(tester);
    await esperar(tester, const Duration(minutes: 26));
    await tester.tap(find.text('Seguir conectado'));
    await tester.pump();
    expect(find.text('¿Sigues ahí?'), findsNothing);

    await esperar(tester, const Duration(minutes: 20));
    expect(sesion.cierresPorInactividad, 0);
  });

  testWidgets('tocar la app cuenta como actividad', (tester) async {
    await montar(tester);
    await esperar(tester, const Duration(minutes: 20));
    await tester.tap(find.text('Inventario'));
    await esperar(tester, const Duration(minutes: 20));
    expect(find.text('¿Sigues ahí?'), findsNothing);
    expect(sesion.cierresPorInactividad, 0);
  });

  testWidgets('al volver del segundo plano tras el límite cierra al instante', (tester) async {
    await montar(tester);
    reloj = reloj.add(const Duration(hours: 2)); // la app estuvo suspendida
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(sesion.cierresPorInactividad, 1);
  });
}
