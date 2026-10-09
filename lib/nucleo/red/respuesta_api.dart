/// Espejo de `ApiResponse<T>` del backend Spring Boot:
/// `{ success, message, data, timestamp }`.
class RespuestaApi<T> {
  const RespuestaApi({required this.exito, required this.mensaje, this.datos, this.fecha});

  factory RespuestaApi.desdeJson(Map<String, dynamic> json, T Function(Object? json) convertirDatos) {
    final datosCrudos = json['data'];
    return RespuestaApi(
      exito: json['success'] as bool? ?? false,
      mensaje: json['message'] as String? ?? '',
      datos: datosCrudos == null ? null : convertirDatos(datosCrudos),
      fecha: DateTime.tryParse(json['timestamp'] as String? ?? ''),
    );
  }

  final bool exito;
  final String mensaje;
  final T? datos;
  final DateTime? fecha;
}

/// Espejo de `PageDTO<T>` del backend:
/// `{ content, number, size, totalElements, totalPages, first, last }`.
class PaginaApi<T> {
  const PaginaApi({
    required this.contenido,
    required this.numero,
    required this.tamano,
    required this.totalElementos,
    required this.totalPaginas,
    required this.esPrimera,
    required this.esUltima,
  });

  factory PaginaApi.desdeJson(Map<String, dynamic> json, T Function(Map<String, dynamic> json) convertirElemento) =>
      PaginaApi(
        contenido: (json['content'] as List<dynamic>? ?? const [])
            .map((e) => convertirElemento(e as Map<String, dynamic>))
            .toList(),
        numero: json['number'] as int? ?? 0,
        tamano: json['size'] as int? ?? 0,
        totalElementos: json['totalElements'] as int? ?? 0,
        totalPaginas: json['totalPages'] as int? ?? 0,
        esPrimera: json['first'] as bool? ?? true,
        esUltima: json['last'] as bool? ?? true,
      );

  final List<T> contenido;
  final int numero;
  final int tamano;
  final int totalElementos;
  final int totalPaginas;
  final bool esPrimera;
  final bool esUltima;

  bool get hayMasPaginas => !esUltima;
}
