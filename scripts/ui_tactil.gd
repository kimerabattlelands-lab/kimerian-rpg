extends CanvasLayer

## Controles táctiles (M7): cruz de movimiento, ataque y botón de objetos.
## Zonas propias con `InputEventScreenTouch` (multitouch real, sin la
## emulación de ratón que rompe toques simultáneos). Los toques mandan a las
## MISMAS acciones del teclado, así que el resto del juego no se entera de la
## fuente. El release se aplaza un frame para que un toque rápido (abajo+arriba
## en el mismo frame) siempre genere el edge `just_pressed`.
## El test headless entra por `toque()` directamente.

const ACCIONES := {
	"arriba": "mover_arriba",
	"abajo": "mover_abajo",
	"izq": "mover_izq",
	"der": "mover_der",
	"ataque": "atacar",
	"objetos": "abrir_inventario",
}

const TEXTOS := {
	"izq": "◀", "der": "▶", "arriba": "▲", "abajo": "▼",
	"ataque": "A", "objetos": "OBJ",
}

var zonas: Dictionary = {}        # nombre -> Rect2 en coords de viewport (640×360)
var activo: bool = true
var _toques: Dictionary = {}      # idx de toque -> nombre de zona
var _soltar_pendiente: Array = []  # idx a liberar en el próximo physics frame


func _ready() -> void:
	layer = 5  # sobre el juego y el HUD; por debajo de la UI de inventario (10)
	_definir_zonas()
	_pintar_visuales()


func _definir_zonas() -> void:
	zonas["izq"] = Rect2(16, 296, 56, 56)
	zonas["abajo"] = Rect2(76, 296, 56, 56)
	zonas["der"] = Rect2(136, 296, 56, 56)
	zonas["arriba"] = Rect2(76, 240, 56, 56)
	zonas["ataque"] = Rect2(560, 288, 64, 64)
	zonas["objetos"] = Rect2(572, 8, 60, 32)


func _pintar_visuales() -> void:
	for nombre in zonas:
		var r: Rect2 = zonas[nombre]
		var caja := ColorRect.new()
		caja.position = r.position
		caja.size = r.size
		caja.color = Color(1, 1, 1, 0.18)
		caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(caja)
		var etiqueta := Label.new()
		etiqueta.text = TEXTOS[nombre]
		etiqueta.position = r.position
		etiqueta.size = r.size
		etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		etiqueta.add_theme_font_size_override("font_size", 20)
		etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(etiqueta)


func _input(event: InputEvent) -> void:
	if not activo:
		return
	if event is InputEventScreenTouch:
		toque(event.index, event.position, event.pressed)


func toque(idx: int, pos: Vector2, abajo: bool) -> void:
	## Punto único de entrada: lo llama _input en dispositivo y el test en headless.
	if abajo:
		var nombre := zona_en(pos)
		if nombre == "" or _toques.has(idx):
			return
		_toques[idx] = nombre
		Input.action_press(ACCIONES[nombre])
	elif _toques.has(idx):
		_soltar_pendiente.append(idx)  # liberar en el próximo frame, nunca antes


func zona_en(pos: Vector2) -> String:
	for nombre in zonas:
		if (zonas[nombre] as Rect2).has_point(pos):
			return nombre
	return ""


func centro(zona: String) -> Vector2:
	return (zonas[zona] as Rect2).get_center()


func _physics_process(_delta: float) -> void:
	for idx in _soltar_pendiente:
		if _toques.has(idx):
			var nombre: String = _toques[idx]
			_toques.erase(idx)
			Input.action_release(ACCIONES[nombre])
	_soltar_pendiente.clear()
