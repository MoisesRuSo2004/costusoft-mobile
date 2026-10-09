import 'package:costusoft_mobile/modulos/autenticacion/dominio/rol_usuario.dart';
import 'package:costusoft_mobile/modulos/pedidos/datos/modelos_pedidos.dart';
import 'package:costusoft_mobile/modulos/pedidos/dominio/pedido.dart';
import 'package:costusoft_mobile/modulos/pedidos/dominio/repositorio_pedidos.dart';
import 'package:costusoft_mobile/modulos/pedidos/presentacion/proveedores_pedidos.dart';
import 'package:costusoft_mobile/nucleo/errores/resultado.dart';
import 'package:costusoft_mobile/nucleo/red/respuesta_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Pedido _pedido(int id, {EstadoPedido estado = EstadoPedido.enProduccion}) => Pedido(
  id: id,
  numero: 'PED-$id',
  estado: estado,
  colegio: const ColegioPedido(id: 5, nombre: 'IE Kennedy'),
  prendas: const [],
);

/// 45 pedidos simulados (ids 45..1, el más reciente primero), páginas de 20.
class _RepositorioFalso implements RepositorioPedidos {
  final llamadas = <(int, EstadoPedido?)>[];

  @override
  Future<Resultado<PaginaApi<Pedido>>> listar({
    required int pagina,
    int tamano = 20,
    EstadoPedido? estado,
    int? colegioId,
  }) async {
    llamadas.add((pagina, estado));
    const total = 45;
    final todos = [for (var id = total; id >= 1; id--) _pedido(id)];
    final desde = pagina * tamano;
    final contenido = todos.skip(desde).take(tamano).toList();
    final totalPaginas = (total / tamano).ceil();
    return Exito(
      PaginaApi(
        contenido: contenido,
        numero: pagina,
        tamano: tamano,
        totalElementos: total,
        totalPaginas: totalPaginas,
        esPrimera: pagina == 0,
        esUltima: pagina >= totalPaginas - 1,
      ),
    );
  }

  @override
  Future<Resultado<Pedido>> obtener(int id) async => Exito(_pedido(id));

  @override
  Future<Resultado<List<EventoPedido>>> historial(int id) async => const Exito([]);

  @override
  Future<Resultado<Pedido>> ejecutar(int id, AccionPedido accion) async => Exito(_pedido(id));

  @override
  Future<Resultado<Pedido>> cancelar(int id, String motivo) async => Exito(_pedido(id, estado: EstadoPedido.cancelado));
}

void main() {
  group('lectura del backend', () {
    test('pedido real (PED-2026-09440)', () {
      final p = pedidoDesdeJson({
        'id': 9440,
        'numeroPedido': 'PED-2026-09440',
        'estado': 'EN_PRODUCCION',
        'fechaCreacion': '2026-05-17 21:40:17',
        'fechaEstimadaEntrega': '2026-06-18',
        'observaciones': 'Gracias.!',
        'porcentajeCumplimiento': 100,
        'colegio': {'id': 5, 'nombre': 'Institución Educativa John F. Kennedy'},
        'creadoPor': 'kennedy',
        'detalles': [
          {'nombreUniforme': 'Blusa T.S', 'tipo': 'Diario', 'talla': 'S', 'genero': 'Femenino', 'cantidad': 1},
          {'nombreUniforme': 'Falda', 'talla': '8', 'cantidad': 2},
        ],
      });
      expect(p.estado, EstadoPedido.enProduccion);
      expect(p.totalPrendas, 3);
      expect(p.fechaCreacion, DateTime(2026, 5, 17, 21, 40, 17));
      expect(p.colegio.nombre, contains('Kennedy'));
    });

    test('evento del historial', () {
      final e = eventoDesdeJson({
        'estadoAnterior': 'CONFIRMADO',
        'estadoNuevo': 'EN_PRODUCCION',
        'accion': 'Producción iniciada — stock descontado',
        'realizadoPor': 'bodega',
        'fechaAccion': '2026-05-17 21:42:02',
      });
      expect(e.estadoAnterior, EstadoPedido.confirmado);
      expect(e.estadoNuevo, EstadoPedido.enProduccion);
    });
  });

  group('reglas del flujo (mismas del backend)', () {
    test('cada estado tiene su siguiente acción', () {
      expect(AccionPedido.siguiente(EstadoPedido.borrador), AccionPedido.calcular);
      expect(AccionPedido.siguiente(EstadoPedido.confirmado), AccionPedido.iniciarProduccion);
      expect(AccionPedido.siguiente(EstadoPedido.listoParaEntrega), AccionPedido.entregar);
      expect(AccionPedido.siguiente(EstadoPedido.entregado), isNull);
      expect(AccionPedido.siguiente(EstadoPedido.cancelado), isNull);
    });

    test('solo iniciar producción descuenta stock', () {
      expect(AccionPedido.values.where((a) => a.afectaStock), [AccionPedido.iniciarProduccion]);
    });

    test('Bodega puede producir y entregar, pero no confirmar ni cancelar', () {
      expect(AccionPedido.iniciarProduccion.roles, contains(RolUsuario.bodega));
      expect(AccionPedido.entregar.roles, contains(RolUsuario.bodega));
      expect(AccionPedido.confirmar.roles, isNot(contains(RolUsuario.bodega)));
      expect(puedeCancelar(EstadoPedido.confirmado, RolUsuario.bodega), isFalse);
    });

    test('no se cancela un pedido ya entregado o cancelado', () {
      expect(puedeCancelar(EstadoPedido.enProduccion, RolUsuario.administrador), isTrue);
      expect(puedeCancelar(EstadoPedido.entregado, RolUsuario.administrador), isFalse);
      expect(puedeCancelar(EstadoPedido.cancelado, RolUsuario.administrador), isFalse);
    });

    test('pedido atrasado solo si no está finalizado', () {
      final hoy = DateTime(2026, 10, 8, 15);
      final base = Pedido(
        id: 1,
        numero: 'x',
        estado: EstadoPedido.enProduccion,
        colegio: const ColegioPedido(id: 1, nombre: 'c'),
        prendas: const [],
        fechaEntregaEstimada: DateTime(2026, 10, 5),
      );
      expect(base.diasParaEntrega(hoy), -3);
      expect(base.estaAtrasado(hoy), isTrue);
      final entregado = Pedido(
        id: 1,
        numero: 'x',
        estado: EstadoPedido.entregado,
        colegio: const ColegioPedido(id: 1, nombre: 'c'),
        prendas: const [],
        fechaEntregaEstimada: DateTime(2026, 10, 5),
      );
      expect(entregado.estaAtrasado(hoy), isFalse);
    });
  });

  group('lista paginada en el servidor', () {
    late _RepositorioFalso repositorio;
    late ProviderContainer contenedor;

    setUp(() {
      repositorio = _RepositorioFalso();
      contenedor = ProviderContainer(
        overrides: [proveedorRepositorioPedidos.overrideWithValue(repositorio)],
        retry: (_, _) => null,
      );
    });
    tearDown(() => contenedor.dispose());

    test('carga la primera página y luego las siguientes', () async {
      var lista = await contenedor.read(proveedorListaPedidos.future);
      expect(lista.pedidos, hasLength(20));
      expect(lista.total, 45);
      expect(lista.hayMas, isTrue);

      await contenedor.read(proveedorListaPedidos.notifier).cargarMas();
      await contenedor.read(proveedorListaPedidos.notifier).cargarMas();
      lista = contenedor.read(proveedorListaPedidos).value!;
      expect(lista.pedidos, hasLength(45));
      expect(lista.pedidos.map((p) => p.id).toSet(), hasLength(45), reason: 'sin duplicados');
      expect(lista.hayMas, isFalse);

      await contenedor.read(proveedorListaPedidos.notifier).cargarMas();
      expect(repositorio.llamadas.map((l) => l.$1), [0, 1, 2], reason: 'no pide más cuando ya no hay');
    });

    test('al cambiar el filtro vuelve a la primera página con el filtro', () async {
      await contenedor.read(proveedorListaPedidos.future);
      await contenedor.read(proveedorListaPedidos.notifier).cargarMas();

      contenedor.read(proveedorFiltroPedidos.notifier).elegirEstado(EstadoPedido.listoParaEntrega);
      final lista = await contenedor.read(proveedorListaPedidos.future);
      expect(lista.paginaActual, 0);
      expect(repositorio.llamadas.last, (0, EstadoPedido.listoParaEntrega));
    });

    test('un pedido que cambia de estado sale de la lista filtrada', () async {
      contenedor.read(proveedorFiltroPedidos.notifier).elegirEstado(EstadoPedido.enProduccion);
      await contenedor.read(proveedorListaPedidos.future);

      contenedor.read(proveedorListaPedidos.notifier).reemplazar(_pedido(45, estado: EstadoPedido.listoParaEntrega));
      final ids = contenedor.read(proveedorListaPedidos).value!.pedidos.map((p) => p.id);
      expect(ids, isNot(contains(45)));
    });
  });
}
