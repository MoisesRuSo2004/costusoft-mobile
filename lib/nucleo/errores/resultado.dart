import 'fallo.dart';

/// Resultado de una operación que puede fallar, sin lanzar excepciones.
/// Es [Exito] con los datos o [Falla] con el [Fallo].
sealed class Resultado<T> {
  const Resultado();

  bool get esExito => this is Exito<T>;

  R cuando<R>({required R Function(T datos) exito, required R Function(Fallo fallo) falla}) => switch (this) {
    Exito<T>(:final datos) => exito(datos),
    Falla<T>(:final fallo) => falla(fallo),
  };

  Resultado<R> transformar<R>(R Function(T datos) conversion) => switch (this) {
    Exito<T>(:final datos) => Exito(conversion(datos)),
    Falla<T>(:final fallo) => Falla(fallo),
  };
}

final class Exito<T> extends Resultado<T> {
  const Exito(this.datos);

  final T datos;
}

final class Falla<T> extends Resultado<T> {
  const Falla(this.fallo);

  final Fallo fallo;
}
