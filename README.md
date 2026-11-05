# Kimerian RPG — demo jugable

Acciónaventura top-down 2D estilo *A Link to the Past* en el universo Kimerian.
Godot 4.7 · GDScript · pixel art 2D · pensada para exportar a web y probar dentro de Telegram.

## Cómo se corre (en hefesto)

```bash
# prueba de carga (arranca, 60 frames, sale)
godot-headless --path . --quit-after 60

# test de movimiento (código de salida 0 = OK)
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
- [ ] M2 — espada y combate
- [ ] M3 — enemigos con IA
- [ ] M4 — inventario (stacks, descarte) y 4 slots de equipo × 3 objetos
- [ ] M5 — elementos del universo Kimerian (KB de escritura-ia) y arte CC0
- [ ] M6 — export web + publicación en Telegram

## Reglas del proyecto

- GDScript puro: en La Oficina no hay SDK de .NET (decisión: no instalar nada sin Edward).
- El equipo de Orakle (`~/opt/godot-4.7.2-mono`, `export_templates`, atajos `godot-oficina*`) no se toca.
- Arte solo con licencia CC0/gratuita, con fuente anotada en `docs/ARTE.md`.
