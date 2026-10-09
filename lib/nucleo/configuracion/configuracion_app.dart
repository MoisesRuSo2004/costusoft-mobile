/// Configuración por entorno, inyectada al compilar con
/// `--dart-define-from-file=env/<entorno>.json`.
enum EntornoApp { desarrollo, produccion }

class ConfiguracionApp {
  const ConfiguracionApp({required this.entorno, required this.urlBaseApi});

  factory ConfiguracionApp.desdeEntorno() {
    const entorno = String.fromEnvironment('ENTORNO', defaultValue: 'desarrollo');
    const urlBase = String.fromEnvironment('URL_BASE_API', defaultValue: 'http://localhost:8080');
    return const ConfiguracionApp(
      entorno: entorno == 'produccion' ? EntornoApp.produccion : EntornoApp.desarrollo,
      urlBaseApi: urlBase,
    );
  }

  final EntornoApp entorno;
  final String urlBaseApi;

  bool get esProduccion => entorno == EntornoApp.produccion;

  // El plan gratuito de Render "duerme" los servicios: la primera petición
  // puede tardar 30-60 s, por eso los tiempos de espera son generosos.
  // Ojo: en web, el tiempo de conexión de Dio cuenta hasta recibir la
  // respuesta, no solo hasta conectar.
  Duration get tiempoMaximoConexion => const Duration(seconds: 45);
  Duration get tiempoMaximoRespuesta => const Duration(seconds: 60);
}
