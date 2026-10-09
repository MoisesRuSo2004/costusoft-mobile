"""Genera el ícono de la app CostuSoft a partir del isotipo de la plataforma web.

Fuente: `isotipo_web.png`, extraído de `frontend-costusoft/public/logo/logo.svg`
(el SVG trae el isotipo como PNG de 1536 × 1024 con una máscara de luminancia).

Salidas en `assets/icono/` (las consume flutter_launcher_icons, ver pubspec):
  icono_app.png           1024 × 1024, fondo azul completo (iOS, web, Android antiguo)
  icono_fondo.png         capa de fondo del ícono adaptable de Android
  icono_primer_plano.png  isotipo dentro de la zona segura del ícono adaptable
  icono_monocromo.png     silueta blanca para los íconos temáticos de Android 13+
  res/drawable-*/ic_notificacion.png  icono blanco de la barra de estado (push)
  splash_vacio.png        imagen transparente: en Android 12+ el splash nativo
                          queda azul liso y la cortina de inicio arma el logo

Uso (desde costusoft-mobile):
  dart run flutter_launcher_icons
  python docs/icono/generar_icono.py   (después: reemplaza el favicon)
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

RAIZ = Path(__file__).resolve().parents[2]
SALIDA = RAIZ / "assets" / "icono"
LADO = 1024
ALTO_ADAPTABLE = 0.65
DENSIDADES_NOTIFICACION = {"drawable-mdpi": 24, "drawable-hdpi": 36, "drawable-xhdpi": 48, "drawable-xxhdpi": 72, "drawable-xxxhdpi": 96}

# Mismos tonos que el domo del ingreso (lib/nucleo/tema/colores_app.dart).
AZUL_MEDIO = (13, 79, 168)
AZUL_MARINO = (11, 61, 145)
AZUL_PROFUNDO = (7, 45, 110)
VERDE_CLARO = (73, 194, 27)


def mezclar(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def fondo_azul():
    """Degradado diagonal como el domo, con un brillo verde suave detrás de las barras."""
    fondo = Image.new("RGB", (LADO, LADO))
    pixeles = fondo.load()
    for y in range(LADO):
        for x in range(LADO):
            t = (x + y) / (2 * (LADO - 1))
            pixeles[x, y] = mezclar(AZUL_MEDIO, AZUL_MARINO, t / 0.45) if t < 0.45 else mezclar(
                AZUL_MARINO, AZUL_PROFUNDO, (t - 0.45) / 0.55
            )
    brillo = Image.new("L", (LADO, LADO), 0)
    ImageDraw.Draw(brillo).ellipse((LADO * 0.30, LADO * 0.36, LADO * 0.86, LADO * 0.92), fill=38)
    brillo = brillo.filter(ImageFilter.GaussianBlur(LADO * 0.12))
    fondo.paste(Image.new("RGB", (LADO, LADO), VERDE_CLARO), mask=brillo)
    return fondo.convert("RGBA")


def isotipo():
    imagen = Image.open(Path(__file__).with_name("isotipo_web.png")).convert("RGBA")
    caja = imagen.getchannel("A").point(lambda v: 255 if v > 24 else 0).getbbox()
    return imagen.crop(caja)


def centrar(arte, alto_relativo, lienzo=None):
    """Escala el arte a una fracción del alto del lienzo y lo centra (un poco
    a la derecha: la aguja deja aire a la izquierda y el peso visual son las barras)."""
    lienzo = lienzo if lienzo is not None else Image.new("RGBA", (LADO, LADO), (0, 0, 0, 0))
    alto = round(LADO * alto_relativo)
    ancho = round(arte.width * alto / arte.height)
    arte = arte.resize((ancho, alto), Image.LANCZOS)
    x = (LADO - ancho) // 2 + round(LADO * 0.012)
    y = (LADO - alto) // 2
    lienzo.alpha_composite(arte, (x, y))
    return lienzo


def sombra(arte, alto_relativo):
    """Sombra difusa bajo el isotipo para despegarlo del fondo."""
    capa = centrar(arte, alto_relativo)
    alfa = capa.getchannel("A").filter(ImageFilter.GaussianBlur(18)).point(lambda v: v * 0.35)
    resultado = Image.new("RGBA", (LADO, LADO), (2, 16, 48, 0))
    resultado.putalpha(alfa)
    return resultado


def main():
    SALIDA.mkdir(parents=True, exist_ok=True)
    arte = isotipo()

    # Ícono completo: el sistema (iOS, web) le aplica su propia máscara.
    completo = fondo_azul()
    completo.alpha_composite(sombra(arte, 0.60), (0, 12))
    centrar(arte, 0.60, completo)
    completo.convert("RGB").save(SALIDA / "icono_app.png", optimize=True)

    # Ícono adaptable: zona segura = círculo de 66/108 del lado. Android
    # además encoge el primer plano un 16 % por lado (inset del XML que genera
    # flutter_launcher_icons): 0.65 × 0.68 ≈ 44 % del ícono final.
    fondo_azul().convert("RGB").save(SALIDA / "icono_fondo.png", optimize=True)
    primer_plano = Image.new("RGBA", (LADO, LADO), (0, 0, 0, 0))
    primer_plano.alpha_composite(sombra(arte, ALTO_ADAPTABLE), (0, 13))
    centrar(arte, ALTO_ADAPTABLE, primer_plano)
    primer_plano.save(SALIDA / "icono_primer_plano.png", optimize=True)

    # Monocromo: solo la silueta (Android la tiñe con el color del tema).
    silueta = centrar(arte, ALTO_ADAPTABLE)
    blanco = Image.new("RGBA", (LADO, LADO), (255, 255, 255, 0))
    blanco.putalpha(silueta.getchannel("A"))
    blanco.save(SALIDA / "icono_monocromo.png", optimize=True)

    Image.new("RGBA", (288, 288), (0, 0, 0, 0)).save(SALIDA / "splash_vacio.png", optimize=True)

    # Icono de la barra de estado para las notificaciones (Android): silueta
    # blanca ajustada a 24 dp, en cada densidad.
    silueta_ajustada = arte.getchannel("A")
    for carpeta, lado in DENSIDADES_NOTIFICACION.items():
        lienzo = Image.new("RGBA", (lado, lado), (255, 255, 255, 0))
        alto = round(lado * 22 / 24)
        ancho = round(arte.width * alto / arte.height)
        alfa = silueta_ajustada.resize((ancho, alto), Image.LANCZOS)
        blanco = Image.new("RGBA", (ancho, alto), (255, 255, 255, 0))
        blanco.putalpha(alfa)
        lienzo.alpha_composite(blanco, ((lado - ancho) // 2, (lado - alto) // 2))
        destino = RAIZ / "android" / "app" / "src" / "main" / "res" / carpeta
        destino.mkdir(parents=True, exist_ok=True)
        lienzo.save(destino / "ic_notificacion.png", optimize=True)

    # flutter_launcher_icons deja el favicon en 16 px: se reemplaza por uno de 32.
    completo.convert("RGB").resize((32, 32), Image.LANCZOS).save(RAIZ / "web" / "favicon.png", optimize=True)
    print("Íconos generados en", SALIDA)


if __name__ == "__main__":
    main()
