# Kimerian RPG — demo jugable

Acciónaventura top-down 2D estilo *A Link to the Past* en el universo Kimerian.
Godot 4.7 · GDScript · pixel art 2D · pensada para exportar a web y probar dentro de Telegram.

## Cómo se corre (en hefesto)

```bash
# prueba de carga (arranca, 60 frames, sale)
godot-headless --path . --quit-after 60

# test de movimiento, espada, muerte, contacto e i-frames (exit 0 = todo OK)
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
- [ ] M4b — UI de inventario en pantalla: abrir/cerrar, navegar, usar poción, equipar y descartar
- [ ] M5 — elementos del universo Kimerian (KB de escritura-ia) y arte CC0
- [ ] M6 — export web + publicación en Telegram

## Reglas del proyecto

- GDScript puro: en La Oficina no hay SDK de .NET (decisión: no instalar nada sin Edward).
- El equipo de Orakle (`~/opt/godot-4.7.2-mono`, `export_templates`, atajos `godot-oficina*`) no se toca.
- Arte solo con licencia CC0/gratuita, con fuente anotada en `docs/ARTE.md`.
