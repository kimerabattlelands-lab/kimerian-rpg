extends Node2D

## Sala principal: construye la habitación, al jugador, cámara y HUD.
## Arranque normal: `godot-headless --path . --quit-after 60` (prueba de carga).
## Con usuario:    `godot-headless --path . -- --test` (test de movimiento,
## sale con código 0 = OK, 1 = FALLO).

## Preloads: sin referencias al class_name global, que headless no resuelve
## sin pasar por el editor (evitamos la dependencia del class cache).
const FICHA_JUGADOR := preload("res://scripts/jugador.gd")
const EscenaJugador := preload("res://scenes/jugador.tscn")

const ANCHO_SALA := 800
const ALTO_SALA := 576
const GROSOR_PARED := 16

var jugador  # dinámico a propósito: sin tipo global (ver preload de arriba)
var _hud: Label


func _ready() -> void:
	_registrar_entradas()
	_crear_sala()
	_crear_jugador()
	_crear_hud()
	print("KIMERIAN_LISTO sala=", ANCHO_SALA, "x", ALTO_SALA)
	if OS.get_cmdline_user_args().has("--test"):
		_test_movimiento()


func _registrar_entradas() -> void:
	var teclas := {
		"mover_arriba": [KEY_W, KEY_UP],
		"mover_abajo": [KEY_S, KEY_DOWN],
		"mover_izq": [KEY_A, KEY_LEFT],
		"mover_der": [KEY_D, KEY_RIGHT],
	}
	for accion in teclas:
		if InputMap.has_action(accion):
			continue
		InputMap.add_action(accion)
		for tecla in teclas[accion]:
			var ev := InputEventKey.new()
			ev.physical_keycode = tecla
			InputMap.action_add_event(accion, ev)


func _crear_sala() -> void:
	var suelo := Polygon2D.new()
	suelo.polygon = PackedVector2Array([
		Vector2.ZERO, Vector2(ANCHO_SALA, 0),
		Vector2(ANCHO_SALA, ALTO_SALA), Vector2(0, ALTO_SALA)])
	suelo.color = Color("1e3a24")
	add_child(suelo)
	# Muros perimetrales
	_pared(Vector2(ANCHO_SALA / 2.0, GROSOR_PARED / 2.0), Vector2(ANCHO_SALA, GROSOR_PARED))
	_pared(Vector2(ANCHO_SALA / 2.0, ALTO_SALA - GROSOR_PARED / 2.0), Vector2(ANCHO_SALA, GROSOR_PARED))
	_pared(Vector2(GROSOR_PARED / 2.0, ALTO_SALA / 2.0), Vector2(GROSOR_PARED, ALTO_SALA))
	_pared(Vector2(ANCHO_SALA - GROSOR_PARED / 2.0, ALTO_SALA / 2.0), Vector2(GROSOR_PARED, ALTO_SALA))


func _pared(centro: Vector2, tam: Vector2) -> void:
	var cuerpo := StaticBody2D.new()
	cuerpo.position = centro
	cuerpo.collision_layer = 1  # mundo
	var forma := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = tam
	forma.shape = rect
	cuerpo.add_child(forma)
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([
		Vector2(-tam.x / 2.0, -tam.y / 2.0), Vector2(tam.x / 2.0, -tam.y / 2.0),
		Vector2(tam.x / 2.0, tam.y / 2.0), Vector2(-tam.x / 2.0, tam.y / 2.0)])
	visual.color = Color("4a4a55")
	cuerpo.add_child(visual)
	add_child(cuerpo)


func _crear_jugador() -> void:
	jugador = EscenaJugador.instantiate()
	jugador.position = Vector2(ANCHO_SALA / 2.0, ALTO_SALA / 2.0)
	add_child(jugador)
	var cam := Camera2D.new()
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = ANCHO_SALA
	cam.limit_bottom = ALTO_SALA
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	jugador.add_child(cam)
	cam.make_current()


func _crear_hud() -> void:
	var capa := CanvasLayer.new()
	add_child(capa)
	_hud = Label.new()
	_hud.position = Vector2(8, 6)
	_hud.text = _texto_vida(jugador.vida)
	capa.add_child(_hud)
	jugador.vida_cambiada.connect(func(actual: int) -> void: _hud.text = _texto_vida(actual))


func _texto_vida(v: int) -> String:
	var texto := "VIDA "
	for i in FICHA_JUGADOR.VIDA_MAX:
		texto += "♥" if i < v else "♡"
	return texto


func _test_movimiento() -> void:
	## Pulsa "mover_der" 0,5 s y exige que el jugador se haya desplazado
	## y conserve los 5 PV. Sale con código 0 (OK) o 1 (FALLO).
	var pos0: Vector2 = jugador.global_position
	Input.action_press("mover_der")
	await get_tree().create_timer(0.1).timeout
	print("DBG fuerza=", Input.get_action_strength("mover_der"),
			" accion_registrada=", InputMap.has_action("mover_der"),
			" vel=", jugador.velocity, " pos=", jugador.global_position,
			" proc_fisicas=", jugador.is_physics_processing())
	await get_tree().create_timer(0.4).timeout
	Input.action_release("mover_der")
	await get_tree().physics_frame
	var dx: float = jugador.global_position.x - pos0.x
	var ok: bool = dx > 30.0 and jugador.vida == FICHA_JUGADOR.VIDA_MAX
	print("TEST_MOVIMIENTO dx=", "%.1f" % dx, " vida=", jugador.vida, " -> ", "OK" if ok else "FALLO")
	get_tree().quit(0 if ok else 1)
