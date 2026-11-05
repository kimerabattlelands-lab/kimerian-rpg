extends RefCounted

## Texturas por id. Los PNG del proyecto van con `preload`: la resolución
## ocurre al compilar el script (y el export compila con la base de imports),
## así que en export apunta directo al `.ctex` importado. Es la única vía que
## funciona en export — `Image.load` avisa literal: «this will not work on
## export» (era el workaround del crash `--import` del mono local; los imports
## ya existen desde 2026-11-05, ver arte/*.png.import y .godot/imported/).
##
## Ids nuevos: añadir la línea con preload aquí. Fallback `load()` para ids
## que existan en disco sin preload (solo sirve en entorno con project dir).

const TEXTURAS := {
	"jugador": preload("res://arte/jugador.png"),
	"enemigo": preload("res://arte/enemigo.png"),
	"cristal_corinarius": preload("res://arte/cristal_corinarius.png"),
	"amuleto_mil_islas": preload("res://arte/amuleto_mil_islas.png"),
	"botas_abordaje": preload("res://arte/botas_abordaje.png"),
}


static func textura(id: String) -> Texture2D:
	if TEXTURAS.has(id):
		return TEXTURAS[id]
	var ruta := "res://arte/%s.png" % id
	if ResourceLoader.exists(ruta):
		return load(ruta)
	push_error("sprites: sin textura para id=%s (falta preload o import)" % id)
	return null
