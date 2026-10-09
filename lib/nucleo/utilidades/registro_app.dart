import 'package:logger/logger.dart';

/// Registro (logger) único de la app. En producción solo guarda advertencias
/// y errores.
final registroApp = Logger(
  printer: PrettyPrinter(methodCount: 0, errorMethodCount: 6, lineLength: 100),
  level: const bool.fromEnvironment('dart.vm.product') ? Level.warning : Level.debug,
);
