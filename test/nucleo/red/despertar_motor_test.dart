import 'package:costusoft_mobile/nucleo/errores/fallo.dart';
import 'package:costusoft_mobile/nucleo/errores/resultado.dart';
import 'package:costusoft_mobile/nucleo/red/despertar_motor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ejecuta [conMotorDespierto] dentro de un proveedor, con pausas cortas.
Future<T> _ejecutar<T>(
  ProviderContainer contenedor,
  Future<Resultado<T>> Function() accion, {
  Duration limite = const Duration(seconds: 2),
}) {
  final proveedor = FutureProvider.autoDispose<T>(
    (ref) => conMotorDespierto(ref, accion, limite: limite, pausa: const Duration(milliseconds: 10)),
  );
  final suscripcion = contenedor.listen(proveedor, (_, _) {});
  addTearDown(suscripcion.close);
  return contenedor.read(proveedor.future);
}

void main() {
  late ProviderContainer contenedor;
  // Igual que la app (main.dart): sin reintento automático de Riverpod.
  setUp(() => contenedor = ProviderContainer(retry: (_, _) => null));
  tearDown(() => contenedor.dispose());

  test('reintenta mientras el motor arranca y devuelve los datos', () async {
    var intentos = 0;
    final datos = await _ejecutar(contenedor, () async {
      intentos++;
      return intentos < 3 ? const Falla<int>(FalloServicioIniciando()) : const Exito(42);
    });
    expect(datos, 42);
    expect(intentos, 3);
    expect(contenedor.read(proveedorDespertarMotor), isNull, reason: 'al terminar deja de mostrar la espera');
  });

  test('un 409 del backend anterior también se toma como arranque', () async {
    var intentos = 0;
    final datos = await _ejecutar(contenedor, () async {
      intentos++;
      return intentos == 1 ? const Falla<String>(FalloConflicto('Verifique el puerto 8001')) : const Exito('ok');
    });
    expect(datos, 'ok');
  });

  test('no reintenta errores que no son de arranque', () async {
    var intentos = 0;
    await expectLater(
      _ejecutar<int>(contenedor, () async {
        intentos++;
        return const Falla(FalloNoEncontrado('El insumo no existe.'));
      }),
      throwsA(isA<FalloNoEncontrado>()),
    );
    expect(intentos, 1);
  });

  test('al agotar el tiempo da un mensaje para el usuario, sin detalles técnicos', () async {
    final fallo = await _ejecutar<int>(
      contenedor,
      () async => const Falla(FalloConflicto('Verifique que el servicio Python esté corriendo en el puerto 8001.')),
      limite: const Duration(milliseconds: 50),
    ).then<Object?>((_) => null, onError: (Object e) => e);
    expect(fallo, isA<FalloServicioIniciando>());
    final mensaje = (fallo! as Fallo).mensaje;
    expect(mensaje, isNot(contains('8001')));
    expect(mensaje, contains('motor de análisis'));
  });

  test('esFalloDeArranque', () {
    expect(esFalloDeArranque(const FalloServidor('x', 503)), isTrue);
    expect(esFalloDeArranque(const FalloServidor('x', 500)), isFalse);
    expect(esFalloDeArranque(const FalloTiempoAgotado()), isTrue);
    expect(esFalloDeArranque(const FalloPermiso()), isFalse);
  });
}
