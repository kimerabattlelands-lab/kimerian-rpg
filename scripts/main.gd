extends Node2D

## Sala principal: construye la habitación, al jugador, cámara, HUD, enemigos
## e inventario.
## Arranque normal: `godot-headless --path . --quit-after 60` (prueba de carga).
## Con usuario:    `godot-headless --path . -- --test` — batería de 22
## aserciones (movimiento, espada, muerte, contacto, i-frames, stacks,
## descarte, defensa, velocidad, la UI: abrir/usar/descartar/cerrar, los
## 3 objetos Kimerian recogidos de la sala, controles táctiles: mover,
## ataque y botón de objetos, y los botones USAR/TIRAR/CERRAR del panel);
## exit 0 = todo OK.

## Preloads: sin referencias al class_name global, que headless no resuelve
## sin pasar por el editor (evitamos la dependencia del class cache).
const FICHA_JUGADOR := preload("res://scripts/jugador.gd")
const FICHA_ENEMIGO := preload("res://scripts/enemigo.gd")
const FICHA_INVENTARIO := preload("res://scripts/inventario.gd")
const FICHA_DATOS := preload("res://scripts/datos_objetos.gd")
const FICHA_UI := preload("res://scripts/ui_inventario.gd")
const FICHA_TACTIL := preload("res://scripts/ui_tactil.gd")
const EscenaJugador := preload("res://scenes/jugador.tscn")
const EscenaEnemigo := preload("res://scenes/enemigo.tscn")

const ANCHO_SALA := 800
const ALTO_SALA := 576
const GROSOR_PARED := 16

const ENEMIGOS_MUNDO: Array = [
	[Vector2(200, 150), true],
	[Vector2(605, 420), true],
]

## Objetos del universo Kimerian tirados en la sala: [id, posición]. El jugador
## los recoge al pisarlos (área con mask = capa 2, la del jugador).
const RELIQUIAS_MUNDO: Array = [
	["cristal_corinarius", Vector2(90, 90)],
	["amuleto_mil_islas", Vector2(710, 90)],
	["botas_abordaje", Vector2(90, 490)],
]

var jugador  # dinámico a propósito: sin tipo global (ver preload de arriba)
var inventario  # RefCounted del inventario (mismo motivo)
var ui  # CanvasLayer de la UI (mismo motivo)
var ui_tactil  # CanvasLayer de controles táctiles (mismo motivo)
var _hud: Label
var _reliquias: Dictionary = {}  # id -> Area2D en sala (borrado al recoger)


func _ready() -> void:
	var es_test: bool = OS.get_cmdline_user_args().has("--test")
	_registrar_entradas()
	_crear_sala()
	_crear_jugador()
	_crear_hud()
	_crear_inventario()
	_crear_ui()
	_crear_reliquias()
	_crear_tactil()
	_crear_enemigos_mundo(not es_test)  # sin IA en test: nada se mueve solo
	print("KIMERIAN_LISTO sala=", ANCHO_SALA, "x", ALTO_SALA)
	if es_test:
		_test_bateria()


func _registrar_entradas() -> void:
	var teclas := {
		"mover_arriba": [KEY_W, KEY_UP],
		"mover_abajo": [KEY_S, KEY_DOWN],
		"mover_izq": [KEY_A, KEY_LEFT],
		"mover_der": [KEY_D, KEY_RIGHT],
		"atacar": [KEY_SPACE, KEY_J, KEY_X],
		"abrir_inventario": [KEY_I, KEY_TAB],
		"usar": [KEY_E, KEY_ENTER],
		"descartar": [KEY_Q],
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
	for i in jugador.vida_max:  # corona con el equipo: los corazones crecen
		texto += "♥" if i < v else "♡"
	return texto


func _crear_inventario() -> void:
	inventario = FICHA_INVENTARIO.new()
	jugador.inventario = inventario
	inventario.actualizado.connect(func() -> void: jugador.refrescar_estadisticas())


func _crear_ui() -> void:
	ui = FICHA_UI.new()
	ui.inventario = inventario
	ui.jugador = jugador
	add_child(ui)


func _crear_tactil() -> void:
	ui_tactil = FICHA_TACTIL.new()
	add_child(ui_tactil)


func _crear_enemigos_mundo(con_ia: bool) -> void:
	for fila in ENEMIGOS_MUNDO:
		var enemigo = EscenaEnemigo.instantiate()
		enemigo.position = fila[0]
		enemigo.ia_activa = fila[1] and con_ia
		enemigo.objetivo = jugador
		add_child(enemigo)


func _crear_reliquias() -> void:
	## Objeto tirado en el suelo: área de recogida + formas simples
	## (Polygon2D con el color del objeto y Label con su nombre).
	for fila in RELIQUIAS_MUNDO:
		var id: String = fila[0]
		var area := Area2D.new()
		area.position = fila[1]
		area.collision_layer = 0
		area.collision_mask = 2  # capa del jugador
		var forma := CollisionShape2D.new()
		var circulo := CircleShape2D.new()
		circulo.radius = 14.0
		forma.shape = circulo
		area.add_child(forma)
		area.add_child(_visual_reliquia(id))
		var etiqueta := Label.new()
		etiqueta.text = FICHA_DATOS.OBJETOS[id].nombre
		etiqueta.position = Vector2(-56, 14)
		etiqueta.add_theme_font_size_override("font_size", 10)
		area.add_child(etiqueta)
		area.body_entered.connect(func(cuerpo: Node2D) -> void: _recoger(id, area, cuerpo))
		add_child(area)
		_reliquias[id] = area


func _visual_reliquia(id: String) -> Sprite2D:
	## Sprite PNG generado (arte/generar_arte.py, ver docs/ARTE.md); el
	## nombre del fichero es el id del objeto en datos_objetos.gd.
	var sprite := Sprite2D.new()
	sprite.texture = preload("res://arte/sprites.gd").textura(id)
	return sprite


func _recoger(id: String, area: Area2D, cuerpo: Node2D) -> void:
	## Entra el jugador ⇒ al inventario. Si no cabe (lleno), el objeto
	## se queda en la sala.
	if cuerpo != jugador:
		return
	if inventario.agregar(id):
		_reliquias.erase(id)
		area.queue_free()


# --------------------------------------------------------------------- tests

func _pulsar(accion: String) -> void:
	Input.action_press(accion)
	await get_tree().physics_frame
	Input.action_release(accion)


func _test_bateria() -> void:
	## Veintidós comprobaciones, una línea por aserción; exit 0 solo si las
	## veintidós dicen OK. Tiempos en segundos de juego (create_timer).
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

	# Fuera el enemigo del contacto: si vive, golpearía al expirar los i-frames
	# y arruinaría los aserciones siguientes.
	enemigo2.queue_free()

	# 6) Inventario: (a) la poción funde en stack —2 en 1 hueco—, (b) 120
	# monedas se parten por el tope de stack (99 + 21 en dos huecos) y (c) 2000
	# monedas más NO caben: se llenan los 16 huecos y devuelve false.
	var caben_pociones: bool = inventario.agregar("pocion", 2)
	var huecos_con_pocion: int = inventario.contar_ocupados()
	var caben_monedas: bool = inventario.agregar("moneda", 120)
	var monedas_split: int = inventario.total("moneda")
	var huecos_split: int = inventario.contar_ocupados()
	var caben_2000: bool = inventario.agregar("moneda", 2000)
	var ok6: bool = caben_pociones and inventario.total("pocion") == 2 \
			and huecos_con_pocion == 1 and caben_monedas and monedas_split == 120 \
			and huecos_split == 3 and not caben_2000 \
			and inventario.contar_ocupados() == 16
	resultados.append("TEST_INVENTARIO pila_pocion=%d huecos=%d/16 monedas=%d desbordado=%s -> %s"
			% [inventario.total("pocion"), inventario.contar_ocupados(),
			   inventario.total("moneda"), str(not caben_2000),
			   "OK" if ok6 else "FALLO"])

	# 7) Descarte: tirar el hueco de pociones ⇒ la pila entera desaparece y
	# los 16 huecos pasan a 15.
	inventario.descartar(inventario.indice_de("pocion"))
	var ok7: bool = inventario.total("pocion") == 0 and inventario.contar_ocupados() == 15
	resultados.append("TEST_DESCARTE huecos=%d pociones=%d -> %s"
			% [inventario.contar_ocupados(), inventario.total("pocion"),
			   "OK" if ok7 else "FALLO"])

	# 8) Equipo defensa: casco de bronce (+1) ⇒ el contacto de 1 PV se absorbe
	# entero. Se espera a que caduquen los i-frames del paso 4 (0,75 s).
	await get_tree().create_timer(0.35).timeout
	inventario.agregar("casco_bronce")
	var ok8a: bool = inventario.equipar(inventario.indice_de("casco_bronce"))
	var ok8b: bool = inventario.bonus("defensa") == 1 and jugador.defensa == 1
	var enemigo3 = EscenaEnemigo.instantiate()
	enemigo3.ia_activa = false
	enemigo3.objetivo = jugador
	enemigo3.position = jugador.global_position + Vector2(16, 0)
	add_child(enemigo3)
	await get_tree().create_timer(0.3).timeout
	var ok8c: bool = jugador.vida == FICHA_JUGADOR.VIDA_MAX - 1  # sigue en 4: golpe absorbido
	var ok8: bool = ok8a and ok8b and ok8c
	resultados.append("TEST_EQUIPO_DEFENSA defensa=%d vida=%d -> %s"
			% [jugador.defensa, jugador.vida, "OK" if ok8 else "FALLO"])

	# 9) Equipo velocidad: botas ligeras (+30) ⇒ velocidad efectiva sube.
	inventario.agregar("botas_ligeras")
	var ok9a: bool = inventario.equipar(inventario.indice_de("botas_ligeras"))
	var ok9: bool = ok9a and is_equal_approx(
			jugador.velocidad_efectiva, FICHA_JUGADOR.VELOCIDAD + 30.0)
	resultados.append("TEST_EQUIPO_VEL velocidad=%.0f -> %s"
			% [jugador.velocidad_efectiva, "OK" if ok9 else "FALLO"])
	enemigo3.queue_free()

	# 10) UI: [I] abre ⇒ panel visible, jugador bloqueado y sin moverse.
	inventario.agregar("pocion", 1)  # el hueco 0 siempre está libre: ahí cae
	await _pulsar("abrir_inventario")
	await get_tree().physics_frame
	await get_tree().physics_frame  # asentar el bloqueo antes de medir
	var pos_ui: Vector2 = jugador.global_position
	await _pulsar_mantenido("mover_der", 0.3)
	var dx_ui: float = jugador.global_position.x - pos_ui.x
	var ok10: bool = ui.abierto and jugador.entrada_bloqueada and absf(dx_ui) < 1.0
	resultados.append("TEST_UI_ABRIR abierto=%s dx=%.1f -> %s"
			% [str(ui.abierto), dx_ui, "OK" if ok10 else "FALLO"])

	# 11) [E] usa la poción del cursor: cura 4 → 5 PV y consume la unidad.
	var pociones_antes: int = inventario.total("pocion")
	await _pulsar("usar")
	await get_tree().physics_frame
	await get_tree().physics_frame  # asentar: la UI reacciona con un frame de retardo
	var ok11: bool = jugador.vida == FICHA_JUGADOR.VIDA_MAX \
			and inventario.total("pocion") == pociones_antes - 1
	resultados.append("TEST_UI_USAR vida=%d pociones=%d -> %s"
			% [jugador.vida, inventario.total("pocion"), "OK" if ok11 else "FALLO"])

	# 12) [↓] salta al siguiente hueco ocupado (monedas) y [Q] tira la pila.
	await _pulsar("mover_abajo")
	await get_tree().physics_frame
	await get_tree().physics_frame  # asentar el cursor
	var monedas_antes: int = inventario.total("moneda")
	await _pulsar("descartar")
	await get_tree().physics_frame
	await get_tree().physics_frame  # asentar el descarte
	var ok12: bool = ui.cursor == 1 and inventario.total("moneda") == monedas_antes - 99
	resultados.append("TEST_UI_DESCARTE cursor=%d monedas=%d -> %s"
			% [ui.cursor, inventario.total("moneda"), "OK" if ok12 else "FALLO"])

	# 13) [I] cierra ⇒ desbloquea y vuelve a andar.
	await _pulsar("abrir_inventario")
	await get_tree().physics_frame
	await get_tree().physics_frame  # asentar el cierre
	var pos_fin: Vector2 = jugador.global_position
	await _pulsar_mantenido("mover_der", 0.4)
	await get_tree().physics_frame
	var dx_fin: float = jugador.global_position.x - pos_fin.x
	var ok13: bool = not ui.abierto and not jugador.entrada_bloqueada and dx_fin > 20.0
	resultados.append("TEST_UI_CERRAR dx=%.1f -> %s"
			% [dx_fin, "OK" if ok13 else "FALLO"])

	# 14) Objeto Kimerian 1: cristal de corinarius en la sala ⇒ al pisarlo entra
	# en el inventario, su nodo desaparece y, equipado en cabeza, la vida máxima
	# sube de 5 a 7 (bonus +2).
	var cristal = _reliquias["cristal_corinarius"]
	jugador.global_position = cristal.global_position
	await get_tree().physics_frame
	await get_tree().physics_frame  # asentar el solape del área
	var ok14a: bool = inventario.total("cristal_corinarius") == 1 \
			and not _reliquias.has("cristal_corinarius")
	var ok14b: bool = ok14a and inventario.equipar(inventario.indice_de("cristal_corinarius"))
	var ok14: bool = ok14b and inventario.bonus("vida_max") == 2 \
			and jugador.vida_max == FICHA_JUGADOR.VIDA_MAX + 2
	resultados.append("TEST_OBJ_K1_CRISTAL recogido=%s vida_max=%d -> %s"
			% [str(ok14a), jugador.vida_max, "OK" if ok14 else "FALLO"])

	# 15) Objeto Kimerian 2: amuleto de Las Mil Islas ⇒ recogido y equipado en
	# pecho, la defensa efectiva queda en 1 (el casco de bronce cedió su hueco
	# de cabeza al cristal en el paso anterior).
	var amuleto = _reliquias["amuleto_mil_islas"]
	jugador.global_position = amuleto.global_position
	await get_tree().physics_frame
	await get_tree().physics_frame
	var ok15a: bool = inventario.total("amuleto_mil_islas") == 1 \
			and not _reliquias.has("amuleto_mil_islas")
	var ok15b: bool = ok15a and inventario.equipar(inventario.indice_de("amuleto_mil_islas"))
	var ok15: bool = ok15b and inventario.bonus("defensa") == 1 \
			and jugador.defensa == 1
	resultados.append("TEST_OBJ_K2_AMULETO recogido=%s defensa=%d -> %s"
			% [str(ok15a), jugador.defensa, "OK" if ok15 else "FALLO"])

	# 16) Objeto Kimerian 3: botas de abordaje ⇒ recogidas y equipadas, sustituyen
	# a las botas ligeras (+30 ⇒ +20): velocidad efectiva 95 + 20 = 115.
	var botas = _reliquias["botas_abordaje"]
	jugador.global_position = botas.global_position
	await get_tree().physics_frame
	await get_tree().physics_frame
	var ok16a: bool = inventario.total("botas_abordaje") == 1 \
			and not _reliquias.has("botas_abordaje")
	var ok16b: bool = ok16a and inventario.equipar(inventario.indice_de("botas_abordaje"))
	var ok16: bool = ok16b and inventario.bonus("velocidad") == 20 \
			and is_equal_approx(jugador.velocidad_efectiva,
					FICHA_JUGADOR.VELOCIDAD + 20.0)
	resultados.append("TEST_OBJ_K3_BOTAS recogido=%s velocidad=%.0f -> %s"
			% [str(ok16a), jugador.velocidad_efectiva, "OK" if ok16 else "FALLO"])

	# 17) Táctil: las 6 zonas existen y un toque mantenido en ▶ mueve al jugador.
	var ok17a: bool = ui_tactil.zonas.size() == 6 and ui_tactil.activo
	var pos_t: Vector2 = jugador.global_position
	ui_tactil.toque(77, ui_tactil.centro("der"), true)
	await get_tree().create_timer(0.3).timeout
	ui_tactil.toque(77, ui_tactil.centro("der"), false)
	await get_tree().physics_frame
	await get_tree().physics_frame  # el release aplazado ya se aplicó
	var dx_t: float = jugador.global_position.x - pos_t.x
	var ok17: bool = ok17a and dx_t > 20.0
	resultados.append("TEST_TACTIL_MOVER zonas=%d dx=%.1f -> %s"
			% [ui_tactil.zonas.size(), dx_t, "OK" if ok17 else "FALLO"])

	# 18) Táctil ataque: toque en A ⇒ estocada que baja al enemigo de 2 a 1 PV.
	var enemigo4 = EscenaEnemigo.instantiate()
	enemigo4.ia_activa = false
	enemigo4.objetivo = jugador
	enemigo4.position = jugador.global_position + Vector2(34, 0)
	add_child(enemigo4)
	jugador.direccion = Vector2.RIGHT
	ui_tactil.toque(78, ui_tactil.centro("ataque"), true)
	await get_tree().create_timer(0.15).timeout
	ui_tactil.toque(78, ui_tactil.centro("ataque"), false)
	await get_tree().physics_frame
	var ok18: bool = is_instance_valid(enemigo4) \
			and enemigo4.vida == FICHA_ENEMIGO.VIDA_MAX - 1
	resultados.append("TEST_TACTIL_ATAQUE vida_enemigo=%s -> %s"
			% ["libre" if not is_instance_valid(enemigo4) else str(enemigo4.vida),
			   "OK" if ok18 else "FALLO"])
	enemigo4.queue_free()

	# 19) Táctil objetos: toque en OBJ ⇒ abre y vuelve a cerrar el inventario.
	ui_tactil.toque(79, ui_tactil.centro("objetos"), true)
	await get_tree().physics_frame
	await get_tree().physics_frame
	ui_tactil.toque(79, ui_tactil.centro("objetos"), false)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var abrio_con_toque: bool = ui.abierto
	ui_tactil.toque(80, ui_tactil.centro("objetos"), true)
	await get_tree().physics_frame
	await get_tree().physics_frame
	ui_tactil.toque(80, ui_tactil.centro("objetos"), false)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var ok19: bool = abrio_con_toque and not ui.abierto \
			and not jugador.entrada_bloqueada
	resultados.append("TEST_TACTIL_OBJETOS abrio=%s cerro=%s -> %s"
			% [str(abrio_con_toque), str(not ui.abierto),
			   "OK" if ok19 else "FALLO"])

	# 20) Toque rápido (baja y sube en el mismo frame): el edge no se pierde
	# porque el release se aplaza un frame — la estocada sale igual.
	await get_tree().create_timer(0.6).timeout  # enfriamiento de la estocada 18
	ui_tactil.toque(81, ui_tactil.centro("ataque"), true)
	ui_tactil.toque(81, ui_tactil.centro("ataque"), false)  # mismo frame
	await get_tree().physics_frame  # F+1 arranca: el ataque se dispara en sus callbacks
	await get_tree().physics_frame  # F+2: ya procesado ⇒ el swing está activo
	var golpe_rapido: bool = jugador.espada.visible
	await get_tree().create_timer(0.3).timeout  # dejar terminar el swing
	var ok20: bool = golpe_rapido
	resultados.append("TEST_TACTIL_TOQUE_RAPIDO espada=%s -> %s"
			% [str(golpe_rapido), "OK" if ok20 else "FALLO"])

	# 21) Botones del panel: con una poción en el cursor, USAR cura y consume;
	# los tres botones están visibles solo con el panel abierto.
	inventario.descartar(0)          # hueco 0 libre para la poción
	inventario.agregar("pocion", 1)
	await _pulsar("abrir_inventario")
	await get_tree().physics_frame
	await get_tree().physics_frame
	await _pulsar("mover_arriba")    # cursor del hueco 1 (libre) al 0 (poción)
	await get_tree().physics_frame
	await get_tree().physics_frame
	jugador.vida = 4  # herida artificial: el equipo actual tiene el máximo en 7
	var vida_antes: int = jugador.vida
	var btn_usar: Button = ui.botones["usar"]
	btn_usar.pressed.emit()
	await get_tree().physics_frame
	await get_tree().physics_frame
	var ok21: bool = btn_usar.visible and ui.botones["tirar"].visible \
			and ui.botones["cerrar"].visible \
			and jugador.vida == vida_antes + 2 \
			and inventario.total("pocion") == 0
	resultados.append("TEST_BOTONES_USAR vida=%d->%d pociones=%d -> %s"
			% [vida_antes, jugador.vida, inventario.total("pocion"),
			   "OK" if ok21 else "FALLO"])

	# 22) Botón CERRAR ⇒ sale del panel sin teclado (la duda de Edward en móvil).
	var btn_cerrar: Button = ui.botones["cerrar"]
	btn_cerrar.pressed.emit()
	await get_tree().physics_frame
	await get_tree().physics_frame
	var ok22: bool = not ui.abierto and not jugador.entrada_bloqueada
	resultados.append("TEST_BOTON_CERRAR cerrado=%s -> %s"
			% [str(not ui.abierto), "OK" if ok22 else "FALLO"])

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
