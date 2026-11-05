# Arte — Kimerian RPG (M5b)

Todo el arte de este proyecto es **CC0 / dominio público** (cedido sin
restricciones por el autor). Regla del proyecto: solo CC0 o gratuito, con
fuente anotada aquí.

## Búsqueda de packs en disco (2026-11-05)

Se buscó un pack CC0 ya presente en el disco antes de generar nada:

```bash
find /home/babel/Descargas /home/babel/proyectos /media/babel -iname "*kenney*"
find /home/babel/Descargas /home/babel/proyectos -maxdepth 6 -iname "*kenney*" -not -path "*/.git/*"
```

Resultado: **sin ningún pack usable** (la única coincidencia en `/media/babel`
era un hash de nombre que contenía «cc0» por casualidad, un `.jpeg` sin
relación). Por tanto, según lo acordado, **el arte se generó en este
proyecto** con `python3/PIL` y queda dicho aquí.

## Ficheros

| Fichero | Origen | Licencia |
|---|---|---|
| `arte/jugador.png` (16×16) | Generado por `arte/generar_arte.py` (python3/PIL), pixel art propio: héroe con capucha verde | CC0 |
| `arte/enemigo.png` (16×16) | Ídem: bulto rojo con cuernos y ojos amarillos | CC0 |
| `arte/cristal_corinarius.png` (16×16) | Ídem: rombo azul lunar (corinarius, `materiales/corinarius.md`) | CC0 |
| `arte/amuleto_mil_islas.png` (16×16) | Ídem: moneda octogonal de oro con isla (`lugares/las-mil-islas.md`) | CC0 |
| `arte/botas_abordaje.png` (16×16) | Ídem: bota pirata de cuero con hebilla (`lugares/las-mil-islas.md`) | CC0 |
| `arte/generar_arte.py` | Fuente de todo lo anterior: ejecutar `python3 arte/generar_arte.py` regenera los 5 PNG | CC0 |
| `arte/sprites.gd` | Carga los PNG en runtime (`Image.load` → `ImageTexture`) | — (GDScript, código del proyecto) |

Ningún fichero procede de un tercero: no había pack en el disco.

## Cómo se aplican

- **Jugador** y **enemigo**: nodo `Cuerpo` (Sprite2D) en sus escenas; la
  textura la asigna el script en `_ready()` vía `sprites.gd`.
- **3 objetos** (cristal, amuleto, botas): `_visual_reliquia()` en
  `scripts/main.gd` crea un Sprite2D con `sprites.gd.textura(id)`; el nombre
  del PNG es el id del objeto en `datos_objetos.gd`.

## Nota técnica (pendiente de Orakle)

El binario Godot mono local no puede importar recursos:
`godot-headless --path . --import` revienta con **signal 11** al arranque
(incidencia `pasarela/entrada/2026-11-05-0540-kojima-incidencia-godot-import-signal11.md`,
abierta a Orakle). Por eso los PNG se leen en runtime con
`Image.load("res://arte/…")` en vez de pasar por el importador: mismo
resultado visual, sin `.import`. Cuando Orakle resuelva, se puede migrar a
`ext_resource`/import normal sin cambiar los PNG ni esta tabla.
