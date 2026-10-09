import 'package:costusoft_mobile/nucleo/errores/fallo.dart';
import 'package:costusoft_mobile/nucleo/errores/resultado.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Exito.transformar convierte el valor', () {
    const Resultado<int> resultado = Exito(2);
    final convertido = resultado.transformar((v) => v * 10);
    expect(convertido.cuando(exito: (v) => v, falla: (_) => -1), 20);
  });

  test('Falla.transformar conserva el fallo', () {
    const Resultado<int> resultado = Falla(FalloRed());
    final convertido = resultado.transformar((v) => v * 10);
    expect(convertido.esExito, isFalse);
    expect(convertido.cuando(exito: (_) => null, falla: (f) => f), isA<FalloRed>());
  });
}
