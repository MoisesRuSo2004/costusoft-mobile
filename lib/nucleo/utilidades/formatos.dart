import 'package:intl/intl.dart';

/// Formatos de presentación en español de Colombia.
abstract final class Formatos {
  static final _entero = NumberFormat('#,##0', 'es_CO');
  static final _decimal = NumberFormat('#,##0.##', 'es_CO');
  static final _fechaCorta = DateFormat('d MMM yyyy', 'es_CO');
  static final _fechaSinAnio = DateFormat('d MMM', 'es_CO');

  /// 28000 → "$ 28.000" (pesos colombianos, con el símbolo adelante como se
  /// escribe en Colombia; el formato `es_CO` de intl lo pone al final).
  static String moneda(num valor) => '\$ ${_entero.format(valor.round())}';

  /// 1234 → "1.234"; 2.5 → "2,5".
  static String numero(num valor) => valor == valor.roundToDouble() ? _entero.format(valor) : _decimal.format(valor);

  /// 2026-10-09 → "9 oct 2026" (sin año si es el año actual).
  static String fecha(DateTime fecha, {DateTime? hoy}) {
    final ahora = hoy ?? DateTime.now();
    return fecha.year == ahora.year ? _fechaSinAnio.format(fecha) : _fechaCorta.format(fecha);
  }

  /// "hace un momento", "hace 5 min", "hace 3 h", "hace 2 días", o la fecha.
  static String haceCuanto(DateTime momento, {DateTime? ahora}) {
    final diferencia = (ahora ?? DateTime.now()).difference(momento);
    if (diferencia.isNegative || diferencia.inMinutes < 1) return 'hace un momento';
    if (diferencia.inHours < 1) return 'hace ${diferencia.inMinutes} min';
    if (diferencia.inDays < 1) return 'hace ${diferencia.inHours} h';
    if (diferencia.inDays == 1) return 'ayer';
    if (diferencia.inDays < 30) return 'hace ${diferencia.inDays} días';
    return 'el ${fecha(momento, hoy: ahora)}';
  }

  /// "1 día" / "5 días".
  static String dias(int cantidad) => cantidad == 1 ? '1 día' : '${numero(cantidad)} días';
}
