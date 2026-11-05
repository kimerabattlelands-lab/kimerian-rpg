extends Node2D

## Sala principal: construye la habitación, al jugador, cámara, HUD y enemigos.
## Arranque normal: `godot-headless --path . --quit-after 60` (prueba de carga).
## Con usuario:    `godot-headless --path . -- --test` — batería completa
## (movimiento, espada, muerte de enemigo, contacto, i-frames) y sale con
## código 0 = todo OK / 1 = hay FALLO.

## Preloads: sin referencias al class_name global, que headless no resuelve
## sin pasar por el editor (evitamos la dependencia del class cache).
const FICHA_JUGADOR := preload("res://scripts/jugador.gd")
const FICHA_ENEMIGO := preload("res://scripts/enemigo.gd")
const EscenaJugador := preload("res://scenes/jugador.tscn")
const EscenaEnemigo := preload("res://scenes/enemigo.tscn")

const ANCHO_SALA := 800
const ALTO_SALA := 576
const GROSOR_PARED := 16

const ENEMIGOS_MUNDO: Array = [
	[Vector2(200, 150), true],
	[Vector2(605, 420), true],
]

var jugador  # dinámico a propósito: sin tipo global (ver preload de arriba)
var _hud: Label


func _ready() -> void:
	_registrar_entradas()
	_crear_sala()
	_crear_jugador()
	_crear_hud()
	_crear_enemigos_mundo()
	print("KIMERIAN_LISTO sala=", ANCHO_SALA, "x", ALTO_SALA)
	if OS.get_cmdline_user_args().has("--test"):
		_test_bateria()


func _registrar_entradas() -> void:
	var teclas := {
		"mover_arriba": [KEY_W, KEY_UP],
		"mover_abajo": [KEY_S, KEY_DOWN],
		"mover_izq": [KEY_A, KEY_LEFT],
		"mover_der": [KEY_D, KEY_RIGHT],
		"atacar": [KEY_SPACE, KEY_J, KEY_X],
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


func _crear_enemigos_mundo() -> void:
	for fila in ENEMIGOS_MUNDO:
		var enemigo = EscenaEnemigo.instantiate()
		enemigo.position = fila[0]
		enemigo.ia_activa = fila[1]
		enemigo.objetivo = jugador
		add_child(enemigo)


# --------------------------------------------------------------------- tests

func _pulsar(accion: String) -> void:
	Input.action_press(accion)
	await get_tree().physics_frame
	Input.action_release(accion)


func _test_bateria() -> void:
	## Cinco comprobaciones con salida de una línea cada una; exit 0 solo si
	## las cinco dicen OK. Tiempos en segundos de juego (create_timer).
	var resultados: Array[String] = []

	# 1) Movimiento: 0,5 s pulsando derecha ⇒ >30 px en X y 5 PV intactos.
	var pos0: Vector2 = jugador.global_position
	await _pulsar_mantenido("mover_der", 0.5)
	var dx: float = jugador.global_position.x - pos0.x
	var ok1: bool = dx > 30.0 and jugador.vida == FICHA_JUGADOR.VIDA_MAX
	resultados.append("TEST_MOVIMIENTO dx=%.1f vida=%d -> %s"
			% [dx, jugador.vida, "OK" if ok1 else "FALLO"])

	# 2) Espada: enemigo de prueba (sin IA) a 34 px, 2 PV ⇒ 1 PV tras un golpe.
	var enemigo = EscenaEnemigo.instantiate()
	enemigo.ia_activa = false
	enemigo.objetivo = jugador
	enemigo.position = jugador.global_position + Vector2(34, 0)
	add_child(enemigo)
	jugador.direccion = Vector2.RIGHT
	await _pulsar("atacar")
	await get_tree().create_timer(0.3).timeout
	var ok2: bool = is_instance_valid(enemigo) and enemigo.vida == FICHA_ENEMIGO.VIDA_MAX - 1
	resultados.append("TEST_ESPADA vida_enemigo=%s -> %s"
			% ["libre" if not is_instance_valid(enemigo) else str(enemigo.vida),
			   "OK" if ok2 else "FALLO"])

	# 3) Segunda estocada (tras el CD de 0,53 s) ⇒ muerte y liberación del nodo.
	# El retroceso del primer golpe empujó al enemigo fuera de alcance: el
	# jugador se acercaría, así que el test vuelve a ponerlo a 34 px.
	await get_tree().create_timer(0.35).timeout
	if is_instance_valid(enemigo):
		enemigo.position = jugador.global_position + Vector2(34, 0)
	await _pulsar("atacar")
	await get_tree().create_timer(0.3).timeout
	await get_tree().physics_frame
	var ok3: bool = not is_instance_valid(enemigo)
	resultados.append("TEST_MUERTE enemigo_libre=%s -> %s"
			% [str(ok3), "OK" if ok3 else "FALLO"])

	# 4) Contacto: enemigo a 16 px ⇒ exactamente 1 PV de daño.
	var enemigo2 = EscenaEnemigo.instantiate()
	enemigo2.ia_activa = false
	enemigo2.objetivo = jugador
	enemigo2.position = jugador.global_position + Vector2(16, 0)
	add_child(enemigo2)
	await get_tree().create_timer(0.3).timeout
	var ok4: bool = jugador.vida == FICHA_JUGADOR.VIDA_MAX - 1
	resultados.append("TEST_CONTACTO vida_jugador=%d -> %s"
			% [jugador.vida, "OK" if ok4 else "FALLO"])

	# 5) i-frames: 0,2 s después y sigue pegado ⇒ sin segundo daño (0,75 s de escudo).
	await get_tree().create_timer(0.2).timeout
	var ok5: bool = jugador.vida == FICHA_JUGADOR.VIDA_MAX - 1
	resultados.append("TEST_INVULNERABLE vida=%d -> %s"
			% [jugador.vida, "OK" if ok5 else "FALLO"])

	var todos := true
	for linea in resultados:
		print(linea)
		if "FALLO" in linea:
			todos = false
	get_tree().quit(0 if todos else 1)


func _pulsar_mantenido(accion: String, segundos: float) -> void:
	Input.action_press(accion)
	await get_tree().create_timer(segundos).timeout
	Input.action_release(accion)
	await get_tree().physics_frame
