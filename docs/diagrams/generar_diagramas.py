"""Genera los diagramas del documento de diseño de CostuSoft Móvil.

Uso:  py -3.11 docs/diagrams/generar_diagramas.py
Salida: PNG en la misma carpeta de este script.
"""
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Ellipse, FancyArrowPatch, FancyBboxPatch

OUT = Path(__file__).parent

DARK = "#0f0f1a"
GOLD = "#c8a96e"
GOLD_DARK = "#a8843a"
INK = "#1f2333"
MUTED = "#5b6075"
LINE = "#8a8fa3"
FILL = {
    "mobile": "#fbf6ec",
    "backend": "#eef1f8",
    "ml": "#eef7f1",
    "data": "#f4f0f8",
    "ext": "#f6f6f6",
}
EDGE = {
    "mobile": GOLD_DARK,
    "backend": "#3d4f86",
    "ml": "#2f7a52",
    "data": "#6b4c93",
    "ext": "#7a7a7a",
}

plt.rcParams["font.family"] = "DejaVu Sans"


def canvas(w, h):
    fig, ax = plt.subplots(figsize=(w, h), dpi=200)
    ax.set_xlim(0, w * 10)
    ax.set_ylim(0, h * 10)
    ax.axis("off")
    fig.patch.set_facecolor("white")
    return fig, ax


def box(ax, x, y, w, h, title, lines=(), kind="backend", title_size=9.5, body_size=7.6):
    ax.add_patch(
        FancyBboxPatch(
            (x, y), w, h,
            boxstyle="round,pad=0.25,rounding_size=1.2",
            linewidth=1.3, edgecolor=EDGE[kind], facecolor=FILL[kind],
        )
    )
    ty = y + h - 2.4
    ax.text(x + w / 2, ty, title, ha="center", va="center",
            fontsize=title_size, fontweight="bold", color=INK)
    for i, line in enumerate(lines):
        ax.text(x + w / 2, ty - 3.0 - i * 2.5, line, ha="center", va="center",
                fontsize=body_size, color=MUTED)


def group(ax, x, y, w, h, label, color):
    ax.add_patch(
        FancyBboxPatch(
            (x, y), w, h,
            boxstyle="round,pad=0.3,rounding_size=2",
            linewidth=1.1, edgecolor=color, facecolor="none", linestyle=(0, (4, 3)),
        )
    )
    ax.text(x + 1.5, y + h - 1.6, label, ha="left", va="center",
            fontsize=8, fontweight="bold", color=color)


def polyline(ax, pts, color=LINE, ls="-", lw=1.2):
    """Línea quebrada con punta de flecha en el último segmento."""
    xs, ys = zip(*pts[:-1])
    ax.plot(xs, ys, color=color, ls=ls, lw=lw)
    arrow(ax, pts[-2], pts[-1], color=color, ls=ls)


def arrow(ax, p1, p2, label=None, color=LINE, both=False, style="-|>", ls="-", label_offset=(0, 1.3), fs=7, rad=0.0):
    a = FancyArrowPatch(
        p1, p2,
        arrowstyle=("<|-|>" if both else style), mutation_scale=11,
        linewidth=1.2, color=color, linestyle=ls, shrinkA=2, shrinkB=2,
        connectionstyle=f"arc3,rad={rad}",
    )
    ax.add_patch(a)
    if label:
        mx, my = (p1[0] + p2[0]) / 2 + label_offset[0], (p1[1] + p2[1]) / 2 + label_offset[1]
        ax.text(mx, my, label, ha="center", va="center", fontsize=fs, color=INK,
                bbox=dict(boxstyle="round,pad=0.2", fc="white", ec="none"))


def title(ax, w, h, text, sub=None):
    ax.text(w * 5, h * 10 - 2.6, text, ha="center", va="center",
            fontsize=13, fontweight="bold", color=DARK)
    if sub:
        ax.text(w * 5, h * 10 - 5.2, sub, ha="center", va="center", fontsize=8.5, color=MUTED)


def save(fig, name):
    fig.savefig(OUT / name, bbox_inches="tight", pad_inches=0.15, facecolor="white")
    plt.close(fig)
    print("ok", name)


# ─────────────────────────────────────────────────────────────────────────────
# 1. Arquitectura general
# ─────────────────────────────────────────────────────────────────────────────
def arquitectura_general():
    W, H = 13.5, 8.8
    fig, ax = canvas(W, H)
    title(ax, W, H, "Arquitectura general — CostuSoft Control + CostuSoft Móvil",
          "La app móvil consume únicamente el backend Spring Boot (fachada única / API Gateway)")

    # Columna izquierda: clientes
    group(ax, 2, 24, 34, 51, "CLIENTES", GOLD_DARK)
    box(ax, 4, 52, 30, 17, "App Móvil Flutter",
        ["Android / iOS", "Admin · Bodega · Institución", "BD local Drift + cola offline"], "mobile")
    box(ax, 4, 27, 30, 15, "Frontend Web", ["Next.js 16 + TypeScript", "4 paneles por rol"], "mobile")
    box(ax, 4, 4, 30, 12, "Power BI", ["Dashboard ejecutivo"], "ext")

    # Columna central: núcleo cloud
    group(ax, 44, 24, 48, 51, "NÚCLEO CLOUD (Render)", "#3d4f86")
    box(ax, 47, 50, 42, 19, "Backend API REST",
        ["Spring Boot 3.4.5 · 17 módulos REST", "JWT HS512 + refresh · RBAC (4 roles)",
         "Nuevo: dispositivos + envío push"], "backend")
    box(ax, 47, 27, 20, 14, "Predicción ML", ["FastAPI", "Prophet + XGBoost"], "ml")
    box(ax, 69, 27, 20, 14, "Optimización ILP", ["FastAPI", "PuLP / CBC"], "ml")
    box(ax, 47, 4, 42, 12, "Supabase — PostgreSQL 16", ["16 tablas · PgBouncer :6543 · SSL"], "data")

    # Columna derecha: servicios externos
    box(ax, 102, 58, 26, 11, "Groq Cloud", ["Agente IA (LLM)"], "ext")
    box(ax, 102, 42, 26, 11, "Firebase (FCM)", ["Notificaciones push"], "ext")
    box(ax, 102, 26, 26, 11, "Cloudinary", ["Imágenes / evidencias"], "ext")
    box(ax, 102, 10, 26, 11, "Resend", ["Correo transaccional"], "ext")

    # Flechas cliente → backend
    arrow(ax, (34, 61), (47, 61), "REST + JWT", color=GOLD_DARK, both=True, label_offset=(0, 1.8))
    polyline(ax, [(34, 35), (40, 35), (40, 55), (47, 55)], color=GOLD_DARK)
    # Backend → microservicios
    arrow(ax, (57, 50), (57, 41), "X-API-Token", fs=6.5, label_offset=(0, 0))
    arrow(ax, (79, 50), (79, 41), "X-API-Token", fs=6.5, label_offset=(0, 0))
    # Datos
    polyline(ax, [(89, 52), (94, 52), (94, 10), (89, 10)], color="#6b4c93")
    ax.text(95, 31, "JPA", fontsize=6.5, color="#6b4c93")
    arrow(ax, (57, 27), (57, 16), "SQLAlchemy", fs=6.5, label_offset=(0, 0), color="#6b4c93")
    arrow(ax, (79, 27), (79, 16), "SQLAlchemy", fs=6.5, label_offset=(0, 0), color="#6b4c93")
    arrow(ax, (34, 10), (47, 10), "lectura", fs=6.5)
    # Backend → externos
    arrow(ax, (89, 66), (102, 64), "REST", fs=6.5)
    arrow(ax, (89, 63), (102, 48), "FCM v1", fs=6.5)
    arrow(ax, (89, 60), (102, 32), None)
    arrow(ax, (89, 58), (102, 16), None)
    # FCM → app (push) por encima de todo
    polyline(ax, [(128, 47.5), (131, 47.5), (131, 78), (19, 78), (19, 69)], color=GOLD, ls=(0, (4, 3)))
    ax.text(75, 79.6, "push FCM → dispositivo (pedido listo, riesgo CRÍTICO, movimiento pendiente)",
            fontsize=7, color=GOLD_DARK, ha="center")
    save(fig, "01_arquitectura_general.png")


# ─────────────────────────────────────────────────────────────────────────────
# 2. Clean Architecture de la app
# ─────────────────────────────────────────────────────────────────────────────
def arquitectura_limpia():
    W, H = 12, 5.6
    fig, ax = canvas(W, H)
    title(ax, W, H, "Arquitectura interna de la app (Clean Architecture por módulo)",
          "Las dependencias apuntan hacia el dominio; el dominio no conoce Flutter, Dio ni Drift")
    box(ax, 4, 38, 112, 9, "PRESENTACIÓN  (lib/modulos/*/presentacion)",
        ["Pantallas y widgets (Material 3)  ·  Controladores Riverpod (Notifier / AsyncNotifier)  ·  Rutas go_router con guardas por rol"],
        "mobile")
    box(ax, 4, 23, 112, 9, "DOMINIO  (lib/modulos/*/dominio)  — Dart puro",
        ["Entidades inmutables (freezed)  ·  Contratos de repositorio (abstract)  ·  Casos de uso  ·  Resultado<T> / Fallo"],
        "backend")
    box(ax, 4, 8, 112, 9, "DATOS  (lib/modulos/*/datos)",
        ["Repositorios (implementación)  ·  Fuente remota (Dio)  ·  Fuente local (Drift / almacenamiento cifrado)  ·  DTO + conversores"],
        "ml")
    arrow(ax, (60, 38), (60, 32), "depende de", color=INK, label_offset=(8, 0))
    arrow(ax, (60, 17), (60, 23), "implementa", color=INK, label_offset=(8, 0))
    box(ax, 4, 0, 112, 5, "NÚCLEO (lib/nucleo): configuración · cliente HTTP + interceptores · errores · rutas · tema · registro",
        [], "data", title_size=8)
    ax.texts[-1].set_y(2.5)
    save(fig, "02_arquitectura_limpia.png")


# ─────────────────────────────────────────────────────────────────────────────
# 3. Casos de uso
# ─────────────────────────────────────────────────────────────────────────────
def actor(ax, x, y, name):
    ax.add_patch(plt.Circle((x, y + 4.2), 1.3, fill=False, lw=1.3, color=INK))
    ax.plot([x, x], [y + 2.9, y - 0.2], color=INK, lw=1.3)
    ax.plot([x - 2, x + 2], [y + 1.9, y + 1.9], color=INK, lw=1.3)
    ax.plot([x, x - 1.6], [y - 0.2, y - 2.6], color=INK, lw=1.3)
    ax.plot([x, x + 1.6], [y - 0.2, y - 2.6], color=INK, lw=1.3)
    ax.text(x, y - 4.3, name, ha="center", va="center", fontsize=8, fontweight="bold", color=INK)


def uc(ax, x, y, text, kind="mobile", w=27, h=5.2):
    ax.add_patch(Ellipse((x, y), w, h, lw=1.1, edgecolor=EDGE[kind], facecolor=FILL[kind]))
    ax.text(x, y, text, ha="center", va="center", fontsize=7, color=INK)


def casos_de_uso():
    W, H = 13, 11
    fig, ax = canvas(W, H)
    title(ax, W, H, "Diagrama de casos de uso — CostuSoft Móvil",
          "Dorado: núcleo móvil · Azul: consumo de IA · Verde: funcionalidades móviles avanzadas")
    ax.add_patch(FancyBboxPatch((24, 2), 84, 98, boxstyle="round,pad=0.3,rounding_size=2",
                                lw=1.2, edgecolor=DARK, facecolor="none"))
    ax.text(66, 98, "Sistema: CostuSoft Móvil", ha="center", fontsize=9, fontweight="bold", color=DARK)

    cases = {
        "login": (46, 91, "CU01 Iniciar sesión", "mobile"),
        "bio": (88, 91, "CU02 Desbloqueo biométrico", "ml"),
        "push": (88, 82, "CU13 Recibir notificación push", "ml"),
        "dash": (46, 76, "CU03 Ver dashboard resumen", "mobile"),
        "riesgo": (46, 70, "CU04 Ver riesgo de\ndesabastecimiento (ML)", "backend"),
        "briefing": (46, 64, "CU05 Leer briefing diario IA", "backend"),
        "chat": (46, 58, "CU06 Chat IA (texto / voz)", "backend"),
        "optim": (46, 52, "CU07 Consultar plan óptimo ILP", "backend"),
        "pedidos": (46, 46, "CU08 Gestionar estado\nde pedidos", "mobile"),
        "mov": (88, 44, "CU16 Consultar inventario\n(solo lectura)", "mobile"),
        "escanear": (88, 36, "CU09 Escanear QR de insumo", "ml"),
        "confirmar": (88, 28, "CU11 Confirmar / rechazar\nmovimiento", "mobile"),
        "offline": (88, 20, "CU12 Trabajar sin conexión\ny sincronizar", "ml"),
        "seguir": (46, 14, "CU14 Seguir estado de\nmis pedidos (timeline)", "mobile"),
        "chatinst": (46, 7, "CU15 Asistente IA institucional", "backend"),
    }
    for x, y, t, k in cases.values():
        uc(ax, x, y, t, k, w=30, h=5.4)

    def left(k):
        x, y, *_ = cases[k]
        return (x - 15, y)

    def right(k):
        x, y, *_ = cases[k]
        return (x + 15, y)

    actor(ax, 11, 88, "Usuario\nautenticado")
    actor(ax, 11, 62, "Administrador")
    actor(ax, 11, 30, "Bodega")
    actor(ax, 11, 9, "Institución")
    actor(ax, 121, 84, "FCM")
    actor(ax, 121, 50, "Backend\nCostuSoft")

    def link(a, b):
        ax.plot([a[0], b[0]], [a[1], b[1]], color=LINE, lw=0.9)

    link((14, 90), left("login"))
    link((14, 89), left("push"))
    for k in ["dash", "riesgo", "briefing", "chat", "optim", "pedidos"]:
        link((14, 63), left(k))
    for k in ["mov", "escanear", "confirmar", "offline"]:
        link((14, 31), left(k))
    for k in ["seguir", "chatinst"]:
        link((14, 10), left(k))
    link((118, 85), right("push"))
    ax.plot([118, 108], [51, 51], color="#b9bccb", lw=0.9, ls=(0, (3, 2)))
    ax.text(113, 46.5, "consumido por\ntodos los CU", fontsize=6.3, color=MUTED, ha="center")

    # Generalización: Administrador, Bodega e Institución heredan de Usuario autenticado
    for y in (62, 30, 9):
        ax.plot([8.5, 3], [y + 2, y + 2], color=INK, lw=0.9)
    ax.plot([3, 3], [11, 80], color=INK, lw=0.9)
    ax.plot([3, 8.5], [80, 80], color=INK, lw=0.9)
    ax.add_patch(plt.Polygon([[8.5, 78.6], [8.5, 81.4], [10.6, 80]], closed=True, fc="white", ec=INK, lw=0.9))

    arrow(ax, left("bio"), right("login"), "«extend»", color=GOLD_DARK, ls=(0, (3, 2)), fs=6.5, label_offset=(0, 1.5))
    arrow(ax, (88, 33.3), (88, 30.7), None, color=GOLD_DARK, ls=(0, (3, 2)))
    ax.text(89.5, 32, "«extend»", fontsize=6.3, color=GOLD_DARK, va="center")
    save(fig, "03_casos_de_uso.png")


# ─────────────────────────────────────────────────────────────────────────────
# 4. Navegación
# ─────────────────────────────────────────────────────────────────────────────
def screen(ax, x, y, text, kind="mobile", w=17, h=6):
    box(ax, x, y, w, h, text, [], kind, title_size=7.6)
    return (x, y, w, h)


def navegacion():
    W, H = 14, 9.4
    fig, ax = canvas(W, H)
    title(ax, W, H, "Diagrama de navegación — go_router con redirección por rol",
          "Barra inferior por rol (StatefulShellRoute) · las pantallas hijas se apilan sobre su pestaña")

    screen(ax, 4, 74, "Splash\n(restaura sesión)", "data", w=18)
    screen(ax, 32, 74, "Login", "data", w=18)
    screen(ax, 60, 74, "Desbloqueo\nbiométrico", "ml", w=18)
    screen(ax, 92, 74, "Redirección\npor rol (JWT)", "data", w=20)
    arrow(ax, (22, 77), (32, 77), "sin sesión", fs=6.3, label_offset=(0, 1.4))
    arrow(ax, (13, 80), (69, 80), "sesión guardada + biometría", fs=6.3, rad=-0.18, label_offset=(0, 6.2))
    polyline(ax, [(41, 74), (41, 71.5), (102, 71.5), (102, 74)])
    ax.text(60, 72.6, "login ok", fontsize=6.3, color=INK, ha="center")
    arrow(ax, (78, 77), (92, 77), "ok", fs=6.3, label_offset=(0, 1.4))

    group(ax, 2, 32, 64, 36, "ADMIN — barra inferior (5 pestañas)", GOLD_DARK)
    for i, t in enumerate(["Inicio", "Inventario", "IA", "Pedidos", "Perfil"]):
        screen(ax, 4 + i * 12.2, 56, t, "mobile", w=11, h=5)
    detalle = [("Notifica-\nciones", "ml"), ("Detalle\ninsumo +\npronóstico", "backend"),
               ("Briefing\nRiesgo\nPlan ILP\nChat", "backend"), ("Detalle\npedido\n(estados)", "mobile")]
    for i, (t, k) in enumerate(detalle):
        x = 4 + i * 12.2
        box(ax, x, 35, 11, 15, t, [], k, title_size=7)
        ax.texts[-1].set_y(42.5)
        arrow(ax, (x + 5.5, 56), (x + 5.5, 50))

    group(ax, 70, 32, 62, 36, "BODEGA — barra inferior (5 pestañas)", "#2f7a52")
    for i, t in enumerate(["Pendientes", "Escanear", "Inventario", "Movimien-\ntos", "Perfil"]):
        screen(ax, 71.5 + i * 12, 56, t, "mobile", w=11.4, h=5)
    for i, (t, k) in enumerate([("Verificar\nmovimiento\n+ pedidos\n(paginados)", "mobile"),
                                ("Cámara QR\n→ ficha +\npendientes", "ml"),
                                ("Detalle\n(sin IA)\n+ etiqueta\nQR", "mobile"),
                                ("Historial\npaginado", "mobile")]):
        x = 71.5 + i * 12
        box(ax, x, 35, 11.4, 15, t, [], k, title_size=6.6)
        ax.texts[-1].set_y(42.5)
        arrow(ax, (x + 5.7, 56), (x + 5.7, 50))

    group(ax, 2, 2, 64, 25, "INSTITUCIÓN — barra inferior (alcance extendido)", "#6b4c93")
    for i, t in enumerate(["Mis pedidos", "Asistente IA", "Perfil"]):
        screen(ax, 4 + i * 20, 15, t, "mobile", w=18, h=5)
    screen(ax, 4, 4, "Seguimiento (timeline)", "mobile", w=18, h=6)
    arrow(ax, (13, 15), (13, 10))

    polyline(ax, [(95, 74), (95, 70), (34, 70), (34, 68.6)], color=GOLD_DARK)
    ax.text(80, 68.9, "ADMIN / USER", fontsize=6.5, color=GOLD_DARK, ha="center")
    arrow(ax, (104, 74), (104, 68.6), "BODEGA", color="#2f7a52", fs=6.5, label_offset=(5, 0))
    polyline(ax, [(112, 77), (135, 77), (135, 29.5), (40, 29.5), (40, 27.4)], color="#6b4c93")
    ax.text(135, 50, "INSTITUCION", fontsize=6.5, color="#6b4c93", rotation=90, ha="center", va="center",
            bbox=dict(boxstyle="round,pad=0.2", fc="white", ec="none"))

    lx, ly = 72, 25
    ax.text(lx, ly, "Reglas de navegación", fontsize=8, fontweight="bold", color=INK)
    reglas = [
        "• Sin token válido → /login (guarda global)",
        "• Rol fuera de la ruta → redirección a su home",
        "• Refresh fallido (401) → cierre de sesión",
        "• Push abre deep link: /pedidos/:id, /movimientos/:id",
        "• Atrás en Android respeta la pila de cada pestaña",
    ]
    for i, r in enumerate(reglas):
        ax.text(lx, ly - 3.6 - i * 3.3, r, fontsize=7.2, color=MUTED)
    save(fig, "04_navegacion.png")


# ─────────────────────────────────────────────────────────────────────────────
# 5. Secuencia de autenticación y renovación del token
# ─────────────────────────────────────────────────────────────────────────────
def secuencia_auth():
    W, H = 12.5, 8.4
    fig, ax = canvas(W, H)
    title(ax, W, H, "Secuencia: autenticación, sesión y renovación transparente del token")
    parts = [("Usuario", 10), ("UI / Riverpod", 33), ("AuthInterceptor\n(Dio)", 58),
             ("SecureStorage", 83), ("Spring Boot\n/api/auth", 110)]
    top = 72
    for name, x in parts:
        box(ax, x - 9, top, 18, 6, name, [], "data" if x != 33 else "mobile", title_size=7.6)
        ax.plot([x, x], [top, 4], color="#c9cbd6", lw=1, ls=(0, (4, 3)))

    def msg(y, a, b, text, dashed=False):
        arrow(ax, (a, y), (b, y), text, color=INK if not dashed else MUTED,
              ls=(0, (3, 2)) if dashed else "-", fs=6.6, label_offset=(0, 1.3))

    X = dict(u=10, ui=33, it=58, ss=83, be=110)
    msg(67, X["u"], X["ui"], "usuario + contraseña")
    msg(63, X["ui"], X["be"], "POST /api/auth/login")
    msg(59, X["be"], X["ui"], "ApiResponse{accessToken, refreshToken, usuario.rol}", True)
    msg(55, X["ui"], X["ss"], "guardar tokens cifrados (Keystore/Keychain)")
    ax.text(X["ui"] + 1.5, 51, "↳ go_router redirige al home según el rol", fontsize=6.8, color=INK)

    ax.add_patch(FancyBboxPatch((3, 9), 114, 38, boxstyle="round,pad=0.2,rounding_size=1",
                                lw=1, edgecolor=GOLD_DARK, facecolor="#fffaf0", alpha=0.6))
    ax.text(5, 45, "Petición protegida (cualquier endpoint)", fontsize=7.4, fontweight="bold", color=GOLD_DARK)
    msg(41, X["ui"], X["it"], "GET /api/prediccion/todos")
    msg(37, X["it"], X["ss"], "leer accessToken")
    msg(33, X["it"], X["be"], "Authorization: Bearer <access>")
    msg(29, X["be"], X["it"], "401 (token expirado)", True)
    msg(25, X["it"], X["be"], "POST /api/auth/refresh {refreshToken}  (single-flight)")
    msg(21, X["be"], X["it"], "nuevos tokens", True)
    msg(17, X["it"], X["ss"], "rotar tokens")
    msg(13, X["it"], X["be"], "reintentar petición original")
    ax.text(5, 6, "Si el refresh falla (7 días vencido / revocado) → se limpia el almacenamiento y el router lleva a /login.",
            fontsize=7, color=MUTED)
    save(fig, "05_secuencia_auth.png")


# ─────────────────────────────────────────────────────────────────────────────
# 6. Offline-first: cola de sincronización
# ─────────────────────────────────────────────────────────────────────────────
def offline():
    W, H = 12.5, 5.6
    fig, ax = canvas(W, H)
    title(ax, W, H, "Estrategia offline-first para Bodega (patrón Outbox)")
    box(ax, 3, 24, 20, 14, "Confirmar /\nrechazar\n(Bodega)", [], "mobile")
    box(ax, 30, 24, 22, 14, "Repositorio", ["¿hay conexión?"], "backend")
    box(ax, 60, 34, 24, 12, "API Spring Boot", ["PATCH /{id}/confirmar", "PATCH /{id}/rechazar"], "backend", body_size=7)
    box(ax, 60, 12, 24, 14, "Drift (SQLite)", ["tabla outbox", "+ caché (insumos,", "pendientes, pedidos)"], "ml", body_size=7)
    box(ax, 93, 12, 26, 14, "SyncService", ["connectivity_plus +", "workmanager (2º plano)"], "ml", body_size=7)
    arrow(ax, (23, 31), (30, 31), "guardar")
    arrow(ax, (52, 34), (60, 40), "online", label_offset=(-2, 1.5))
    arrow(ax, (52, 28), (60, 20), "offline → encolar", label_offset=(-3, -1.8))
    arrow(ax, (84, 19), (93, 19), "pendientes")
    arrow(ax, (106, 26), (84, 41), "reenvío FIFO con\nclave idempotente", label_offset=(6, 2))
    ax.text(3, 5, "La UI muestra el estado de cada acción: Pendiente de enviar · Enviada · Conflicto. El stock solo cambia en el "
                  "servidor: si otra persona ya procesó el movimiento, el backend rechaza el envío y la app muestra el conflicto.",
            fontsize=7, color=MUTED, wrap=True)
    save(fig, "06_offline_outbox.png")


if __name__ == "__main__":
    arquitectura_general()
    arquitectura_limpia()
    casos_de_uso()
    navegacion()
    secuencia_auth()
    offline()
