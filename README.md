# Kimerian RPG — demo jugable

Acciónaventura top-down 2D estilo *A Link to the Past* en el universo Kimerian.
Godot 4.7 · GDScript · pixel art 2D · pensada para exportar a web y probar dentro de Telegram.

## Cómo se corre (en hefesto)

```bash
# prueba de carga (arranca, 60 frames, sale)
godot-headless --path . --quit-after 60

# batería de 16 aserciones (movimiento, combate, inventario, equipo, UI,
# recogida de los 3 objetos Kimerian) — exit 0 = todo OK
godot-headless --path . -- --test
```

En La Oficina (para el editor y el export web):

```bash
godot-oficina --headless --path . --quit-after 60
mkdir -p build
godot-oficina --headless --path . --export-release "Web" build/index.html
```

## Estado

- [x] M1 — sala + jugador (5 PV, 8 direcciones) + cámara + HUD + test headless
- [x] M2 — espada (estocada direccional, CD, retroceso y destello del enemigo)
- [x] M3 — enemigos con IA (patrulla determinista, persecución, contacto 1 PV, 2 PV de vida)
- [x] M4a — inventario (modelo): stacks con tope, desbordamiento a 16 huecos, descarte de pila,
  4 slots de equipo × 3 objetos con propiedades (defensa/velocidad/vida_max) aplicadas al jugador
- [x] M4b — UI de inventario en pantalla: abrir/cerrar con [I], navegar [↑↓], usar/equipar [E],
  descartar pila [Q]; bloquea al jugador mientras está abierta (el mundo sigue)
- [x] M5a — 3 objetos del universo Kimerian como ítems con equipo, tirados en la
  sala y recogibles: **Cristal de corinarius** (cabeza, vida_max +2),
  **Amuleto de Las Mil Islas** (pecho, defensa +1), **Botas de abordaje**
  (botas, velocidad +20). Fuente KB: `materiales/corinarius.md`,
  `lugares/las-mil-islas.md`. Batería de 16 tests en verde.
- [x] M5b — arte CC0: sprites 16×16 generados con `arte/generar_arte.py`
  (no había pack en el disco; ver `docs/ARTE.md` con origen y licencia de
  cada fichero) aplicados a jugador, enemigo y los 3 objetos. Batería de
  16 tests en verde.
- [ ] M5 (resto) — queda: más objetos/lore del KB (la "hoja de
  kimerianita" del ejemplo no existe en el KB: no está canonizada) y
  descripción de equipo en la UI (hoy solo muestra slot + bonus numérico).
- [x] M6 — export web **hecho** y servido: `build/index.html` (39 MB de wasm) en
  `http://100.96.248.5:8099/index.html` por el servicio `kimerian-web` (systemd de usuario, sólo tailnet).
  Verificado con `curl`: 200 en `index.html`, `index.wasm` (39.514.754 B) y `index.pck` (59.172 B).
  El export termina en signal 11 al salir (misma incidencia mono que `--import`): **exporta bien y revienta
  al cerrar**; el build es válido.
- [x] M6 (resto) — **enlace público sin Tailscale**, autorizado por Edward (2026-11-05): repo
  `kimerabattlelands-lab/kimerian-rpg` pasado a **público**, build copiado a `docs/` y GitHub Pages
  servido desde `main:/docs`. Verificado: `index.html=200`, `index.wasm=200` (39.514.754 B),
  `index.js=200` en https://kimerabattlelands-lab.github.io/kimerian-rpg/
  (el servicio tailnet `kimerian-web:8099` queda como opción local).

## Cómo jugar

Abre en el móvil con Tailscale activo: **http://100.96.248.5:8099/index.html**

El servicio se levanta solo (`systemctl --user status kimerian-web`); si se para,
`systemctl --user restart kimerian-web`.

## Reglas del proyecto

- GDScript puro: en La Oficina no hay SDK de .NET (decisión: no instalar nada sin Edward).
- El equipo de Orakle (`~/opt/godot-4.7.2-mono`, `export_templates`, atajos `godot-oficina*`) no se toca.
- Arte solo con licencia CC0/gratuita, con fuente anotada en `docs/ARTE.md`.
