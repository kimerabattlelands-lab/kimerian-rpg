extends CanvasLayer

## UI de inventario en texto (M4b): panel a pantalla completa sobre el juego,
## columna izquierda = huecos ocupados con cursor, derecha = equipo + ayuda.
## Se abre/cierra con la acción "abrir_inventario"; mientras está abierta,
## bloquea la entrada del jugador (el mundo sigue corriendo, como en los
## clásicos). Testeable en headless: todo el estado es visible por script.

const DATOS := preload("res://scripts/datos_objetos.gd")

var inventario  # asignado por main (sin tipo global: class cache headless)
var jugador
var abierto: bool = false
var cursor: int = 0

var _fondo: ColorRect
var _izq: Label
var _der: Label
var botones: Dictionary = {}  # nombre -> Button (lo lee el test)


func _ready() -> void:
	layer = 10
	_fondo = ColorRect.new()
	_fondo.color = Color(0.0, 0.0, 0.05, 0.82)
	_fondo.anchor_right = 1.0
	_fondo.anchor_bottom = 1.0
	add_child(_fondo)
	_izq = Label.new()
	_izq.position = Vector2(14, 10)
	_izq.add_theme_font_size_override("font_size", 16)
	add_child(_izq)
	_der = Label.new()
	_der.position = Vector2(372, 10)
	_der.add_theme_font_size_override("font_size", 16)
	add_child(_der)
	_crear_botones_tactiles()
	cerrar()  # arranca cerrada (es seguro: main asigna jugador antes de add_child)
	if inventario != null:
		inventario.actualizado.connect(_si_abierto)


func _physics_process(_delta: float) -> void:
	if not abierto:
		if Input.is_action_just_pressed("abrir_inventario"):
			abrir()
		return
	if Input.is_action_just_pressed("abrir_inventario"):
		cerrar()
	elif Input.is_action_just_pressed("mover_abajo"):
		_mover_cursor(1)
	elif Input.is_action_just_pressed("mover_arriba"):
		_mover_cursor(-1)
	elif Input.is_action_just_pressed("usar"):
		_usar()
	elif Input.is_action_just_pressed("descartar"):
		_descartar()
	elif Input.is_action_just_pressed("atacar"):
		_usar()  # en móvil, el botón A = usar/equipar con el panel abierto


func _crear_botones_tactiles() -> void:
	## Franja inferior (fuera de las zonas del pad: x 240-500): USAR / TIRAR /
	## CERRAR. Capa 10 ⇒ por encima de todo; los botones GUI responden al toque
	## y su `pressed` llama a la MISMA lógica que E/Q/I del teclado.
	var modelos := {
		"usar": [Vector2(240, 312), "USAR", _usar],
		"tirar": [Vector2(326, 312), "TIRAR", _descartar],
		"cerrar": [Vector2(412, 312), "CERRAR", cerrar],
	}
	for nombre in modelos:
		var b := Button.new()
		b.position = modelos[nombre][0]
		b.size = Vector2(80, 34)
		b.text = modelos[nombre][1]
		b.add_theme_font_size_override("font_size", 14)
		b.pressed.connect(modelos[nombre][2])
		add_child(b)
		botones[nombre] = b


func abrir() -> void:
	abierto = true
	if jugador != null:
		jugador.entrada_bloqueada = true
	_fondo.visible = true
	_izq.visible = true
	_der.visible = true
	for b in botones.values():
		b.visible = true
	_pintar()


func cerrar() -> void:
	abierto = false
	if jugador != null:
		jugador.entrada_bloqueada = false
	_fondo.visible = false
	_izq.visible = false
	_der.visible = false
	for b in botones.values():
		b.visible = false


func _si_abierto() -> void:
	if abierto:
		_pintar()


func _mover_cursor(paso: int) -> void:
	## Salta entre huecos ocupados (los vacíos no se seleccionan).
	var n: int = inventario.huecos.size()
	var i := cursor
	for _intento in n:
		i = posmod(i + paso, n)
		if inventario.huecos[i] != null:
			cursor = i
			_pintar()
			return


func _descartar() -> void:
	inventario.descartar(cursor)
	_pintar()


func _usar() -> void:
	var hueco = inventario.huecos[cursor]
	if hueco == null:
		return
	var datos: Dictionary = DATOS.OBJETOS[hueco.id]
	if datos.get("slot", "") != "":
		inventario.equipar(cursor)
	elif datos.efectos.has("vida") and jugador != null:
		if jugador.curar(datos.efectos.vida):
			inventario.quitar_uno(cursor)  # solo consume si curó algo
	_pintar()


func _pintar() -> void:
	if inventario == null:
		return
	var lineas: Array[String] = ["= INVENTARIO ="]
	var hay_algo := false
	for i in inventario.huecos.size():
		var hueco = inventario.huecos[i]
		if hueco == null:
			continue
		hay_algo = true
		var marca := "> " if i == cursor else "  "
		lineas.append(marca + "%2d. %s x%d"
				% [i + 1, DATOS.OBJETOS[hueco.id].nombre, hueco.cantidad])
	if not hay_algo:
		lineas.append("  (vacío)")
	_izq.text = "\n".join(lineas)

	var equipo: Array[String] = ["= EQUIPO =", ""]
	for slot in inventario.SLOTS_EQUIPO:
		var id = inventario.equipados[slot]
		equipo.append("  %s: %s" % [slot, "—" if id == null else DATOS.OBJETOS[id].nombre])
	equipo.append("")
	equipo.append("[E] usar · [Q] tirar · [I] cerrar")
	equipo.append("o los botones de abajo (táctil)")
	_der.text = "\n".join(equipo)
