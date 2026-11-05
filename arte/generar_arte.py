#!/usr/bin/env python3
"""Genera los sprites PNG de Kimerian RPG (16x16, pixel art).

No había pack CC0 en el disco (búsqueda `find -iname "*kenney*"` en
/home/babel/Descargas, /home/babel/proyectos y /media/babel: sin resultados
usables), así que el arte se dibuja aquí con python3/PIL. Ver docs/ARTE.md.
Uso: python3 arte/generar_arte.py
"""
from PIL import Image, ImageDraw

T = 16  # lado del sprite (px, 1:1 con el juego)


def lienzo() -> ImageDraw.ImageDraw:
    img = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    return ImageDraw.Draw(img)


def guardar(d: ImageDraw.ImageDraw, nombre: str) -> None:
    d._image.save(f"arte/{nombre}.png")
    print(f"arte/{nombre}.png")


# --- jugador: héroe con capucha verde (túnica + botas) ----------------------
def jugador() -> None:
    d = lienzo()
    o = (26, 26, 34, 255)          # contorno
    verde = (46, 139, 61, 255)     # túnica
    verde_osc = (30, 96, 44, 255)
    piel = (232, 184, 138, 255)
    pelo = (90, 60, 34, 255)
    bota = (107, 66, 38, 255)
    # capucha (fila 1-3)
    d.rectangle([5, 1, 10, 3], fill=verde, outline=o)
    d.point((5, 1), fill=verde_osc); d.point((10, 1), fill=verde_osc)
    # cabeza (fila 3-7)
    d.rectangle([5, 3, 10, 7], fill=piel, outline=o)
    # pelo bajo la capucha
    d.rectangle([5, 3, 10, 3], fill=pelo)
    # ojos (fila 5)
    d.point((6, 5), fill=o); d.point((9, 5), fill=o)
    # túnica (fila 7-12)
    d.rectangle([4, 7, 11, 12], fill=verde, outline=o)
    d.line([(4, 10), (11, 10)], fill=verde_osc)
    # brazos
    d.rectangle([3, 8, 3, 11], fill=piel, outline=o)
    d.rectangle([12, 8, 12, 11], fill=piel, outline=o)
    # botas (fila 13-14)
    d.rectangle([5, 13, 6, 14], fill=bota, outline=o)
    d.rectangle([9, 13, 10, 14], fill=bota, outline=o)
    guardar(d, "jugador")


# --- enemigo: rojo con cuernos (bulto con ojos) ----------------------------
def enemigo() -> None:
    d = lienzo()
    o = (26, 26, 34, 255)
    rojo = (194, 47, 69, 255)
    rojo_osc = (136, 28, 46, 255)
    cuerno = (232, 197, 71, 255)
    ojo = (255, 224, 102, 255)
    # cuernos
    d.polygon([(5, 4), (4, 1), (7, 3)], fill=cuerno, outline=o)
    d.polygon([(10, 3), (11, 1), (9, 4)], fill=cuerno, outline=o)
    # cuerpo redondeado
    d.ellipse([3, 4, 12, 13], fill=rojo, outline=o)
    d.line([(4, 12), (11, 12)], fill=rojo_osc)
    # ojos
    d.rectangle([5, 7, 6, 8], fill=ojo)
    d.rectangle([9, 7, 10, 8], fill=ojo)
    d.point((6, 8), fill=o); d.point((9, 8), fill=o)
    # patas
    d.rectangle([5, 13, 6, 14], fill=rojo_osc, outline=o)
    d.rectangle([9, 13, 10, 14], fill=rojo_osc, outline=o)
    guardar(d, "enemigo")


# --- cristal de corinarius: rombo azul lunar ------------------------------
def cristal_corinarius() -> None:
    d = lienzo()
    o = (26, 26, 34, 255)
    azul = (43, 95, 217, 255)
    azul_cl = (111, 155, 255, 255)
    azul_osc = (23, 58, 143, 255)
    d.polygon([(8, 1), (13, 8), (8, 14), (3, 8)], fill=azul, outline=o)
    d.polygon([(8, 1), (8, 14), (3, 8)], fill=azul_cl)   # faceta izq. clara
    d.polygon([(8, 5), (11, 8), (8, 11)], fill=azul_osc)  # sombra interna
    d.point((6, 4), fill=(210, 228, 255, 255))            # brillo
    guardar(d, "cristal_corinarius")


# --- amuleto de Las Mil Islas: moneda octogonal con isla ------------------
def amuleto_mil_islas() -> None:
    d = lienzo()
    o = (26, 26, 34, 255)
    oro = (232, 197, 71, 255)
    oro_osc = (176, 140, 42, 255)
    mar = (43, 95, 217, 255)
    isla = (46, 139, 61, 255)
    d.polygon([(6, 2), (9, 2), (13, 6), (13, 9), (9, 13), (6, 13),
               (3, 9), (3, 6)], fill=oro, outline=o)
    d.polygon([(7, 5), (9, 5), (11, 9), (5, 9)], fill=isla, outline=o)  # isla
    d.line([(5, 11), (10, 11)], fill=mar)                               # mar
    d.line([(6, 12), (9, 12)], fill=mar)
    d.point((7, 4), fill=(255, 240, 190, 255))                          # brillo
    guardar(d, "amuleto_mil_islas")


# --- botas de abordaje: bota pirata ---------------------------------------
def botas_abordaje() -> None:
    d = lienzo()
    o = (26, 26, 34, 255)
    cuero = (176, 106, 59, 255)
    cuero_osc = (120, 68, 34, 255)
    hebilla = (232, 197, 71, 255)
    d.rectangle([4, 2, 9, 3], fill=cuero_osc, outline=o)   # vuelta
    d.rectangle([5, 4, 8, 10], fill=cuero, outline=o)      # caña
    d.rectangle([4, 11, 12, 14], fill=cuero, outline=o)    # pie
    d.rectangle([4, 14, 12, 14], fill=cuero_osc)
    d.point((6, 7), fill=hebilla)                          # hebilla
    d.point((7, 7), fill=hebilla)
    d.line([(5, 9), (8, 9)], fill=cuero_osc)
    guardar(d, "botas_abordaje")


if __name__ == "__main__":
    import os
    os.makedirs("arte", exist_ok=True)
    jugador()
    enemigo()
    cristal_corinarius()
    amuleto_mil_islas()
    botas_abordaje()
    print("listo: 5 sprites 16x16")
