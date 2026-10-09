import 'dart:convert';

import 'package:costusoft_mobile/nucleo/sesion/almacen_tokens.dart';
import 'package:costusoft_mobile/nucleo/sesion/gestor_tokens.dart';
import 'package:costusoft_mobile/nucleo/sesion/tokens_sesion.dart';
import 'package:flutter_test/flutter_test.dart';

/// JWT sin firma válida (JwtDecoder no verifica firmas) con el vencimiento dado.
String _jwtQueVence(DateTime vence) {
  String parte(Map<String, Object> json) => base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${parte({'alg': 'HS512'})}.${parte({'sub': 'piedad', 'exp': vence.millisecondsSinceEpoch ~/ 1000})}.firma';
}

class _AlmacenEnMemoria implements AlmacenTokens {
  TokensSesion? guardados;

  @override
  Future<TokensSesion?> leer() async => guardados;

  @override
  Future<void> guardar(TokensSesion tokens) async => guardados = tokens;

  @override
  Future<void> borrar() async => guardados = null;
}

void main() {
  final ahora = DateTime(2026, 10, 8, 12);
  late _AlmacenEnMemoria almacen;

  setUp(() => almacen = _AlmacenEnMemoria());

  GestorTokens crearGestor(RenovadorTokens renovador) =>
      GestorTokens(almacen: almacen, renovador: renovador, reloj: () => ahora);

  test('varias renovaciones simultáneas hacen una sola llamada al backend', () async {
    var llamadas = 0;
    final gestor = crearGestor((_) async {
      llamadas++;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return TokensSesion(acceso: 'nuevo-$llamadas', renovacion: 'r2');
    });
    await gestor.guardar(const TokensSesion(acceso: 'viejo', renovacion: 'r1'));

    final resultados = await Future.wait([gestor.renovar(), gestor.renovar(), gestor.renovar()]);

    expect(llamadas, 1);
    expect(resultados, ['nuevo-1', 'nuevo-1', 'nuevo-1']);
    expect(almacen.guardados?.renovacion, 'r2');
  });

  test('si el backend rechaza la renovación, borra la sesión y avisa', () async {
    final gestor = crearGestor((_) async => throw const RenovacionRechazada());
    await gestor.guardar(const TokensSesion(acceso: 'viejo', renovacion: 'r1'));
    final aviso = expectLater(gestor.sesionExpirada, emits(null));

    expect(await gestor.renovar(), isNull);
    await aviso;
    expect(gestor.tieneSesion, isFalse);
    expect(almacen.guardados, isNull);
  });

  test('un error de red no borra la sesión', () async {
    final gestor = crearGestor((_) async => throw Exception('sin red'));
    await gestor.guardar(const TokensSesion(acceso: 'viejo', renovacion: 'r1'));

    expect(await gestor.renovar(), isNull);
    expect(gestor.tieneSesion, isTrue);
  });

  test('tokenAccesoVigente renueva solo si el token está por vencer', () async {
    var llamadas = 0;
    final gestor = crearGestor((_) async {
      llamadas++;
      return TokensSesion(acceso: _jwtQueVence(ahora.add(const Duration(hours: 1))), renovacion: 'r2');
    });

    final vigente = _jwtQueVence(ahora.add(const Duration(minutes: 30)));
    await gestor.guardar(TokensSesion(acceso: vigente, renovacion: 'r1'));
    expect(await gestor.tokenAccesoVigente(), vigente);
    expect(llamadas, 0);

    await gestor.guardar(TokensSesion(acceso: _jwtQueVence(ahora.add(const Duration(seconds: 10))), renovacion: 'r1'));
    await gestor.tokenAccesoVigente();
    expect(llamadas, 1);
  });

  test('cargar recupera los tokens guardados', () async {
    almacen.guardados = const TokensSesion(acceso: 'a', renovacion: 'r');
    final gestor = crearGestor((_) async => throw UnimplementedError());
    await gestor.cargar();
    expect(gestor.tokenAcceso, 'a');
  });
}
