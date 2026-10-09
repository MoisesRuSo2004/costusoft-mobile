/// Contenido de la etiqueta QR de un insumo.
String codigoQrDeInsumo(int insumoId) => 'costusoft://insumo/$insumoId';

final _conRuta = RegExp(r'insumo[s]?/(\d+)', caseSensitive: false);
final _conPrefijo = RegExp(r'^INS-?(\d+)$', caseSensitive: false);
final _soloNumero = RegExp(r'^\d+$');

/// Obtiene el id del insumo de un código leído o escrito a mano.
///
/// Acepta `costusoft://insumo/12`, una URL que termine en `/insumo/12`,
/// `INS-12` o simplemente `12`. Devuelve `null` si no es un código válido.
int? idDeInsumoEnCodigo(String codigo) {
  final texto = codigo.trim();
  if (texto.isEmpty) return null;
  final coincidencia = _conRuta.firstMatch(texto) ?? _conPrefijo.firstMatch(texto);
  final numero = coincidencia?.group(1) ?? (_soloNumero.hasMatch(texto) ? texto : null);
  final id = numero == null ? null : int.tryParse(numero);
  return (id == null || id <= 0) ? null : id;
}
