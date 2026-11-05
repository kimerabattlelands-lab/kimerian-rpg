extends RefCounted

## Carga de sprites PNG en runtime.
##
## El binario Godot mono local no puede importar recursos:
## `godot-headless --path . --import` revienta con signal 11 antes de
## importar nada (incidencia 2026-11-05-0540 abierta a Orakle). Mientras
## tanto, los PNG se leen con Image.load y se convierten en ImageTexture:
## mismo resultado visual, sin pasar por el importador. Ver docs/ARTE.md.


static func textura(id: String) -> Texture2D:
	## "jugador" → res://arte/jugador.png (mismo nombre que el id del objeto).
	var img := Image.new()
	var err := img.load("res://arte/%s.png" % id)
	if err != OK:
		push_error("sprites: no se pudo leer res://arte/%s.png (err %d)" % [id, err])
		return null
	return ImageTexture.create_from_image(img)
