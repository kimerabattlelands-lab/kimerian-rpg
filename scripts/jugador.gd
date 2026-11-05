class_name Jugador
extends CharacterBody2D

## Jugador estilo Zelda ALttP: movimiento de 8 direcciones con corte nítido,
## 5 PV con invulnerabilidad y retroceso, y espada con estocada en la
## dirección que mira (hitbox cuadrada adelantada, golpe corto con CD).

signal vida_cambiada(actual: int)
signal muerto

const VELOCIDAD := 95.0           # px/s ≈ 3 tiles de 32 px por segundo
const VIDA_MAX := 5
const FRAMES_INVULNERABLE := 45   # ~0,75 s a 60 fps
const FUERZA_RETROCESO := 150.0   # px/s durante el retroceso
const DURACION_RETROCESO := 0.15  # s

const DANO_ESPADA := 1
const ALCANCE_ESPADA := 20.0      # px de adelanto del centro de la hitbox
const TAMANO_ESPADA := 24.0       # px de lado
const DURACION_GOLPE := 0.18      # s
const ENFRIAMIENTO_ATAQUE := 0.35 # s de espera tras cada golpe

var vida: int = VIDA_MAX
var vida_max: int = VIDA_MAX          # base + bonus del equipo
var defensa: int = 0                  # suma de bonus "defensa" del equipo
var velocidad_efectiva: float = VELOCIDAD  # base + bonus "velocidad" del equipo
var inventario                         # asignado por main; RefCounted dinámico
var direccion: Vector2 = Vector2.DOWN  # última dirección (sprite y espada)
var _invulnerable: int = 0
var _retroceso: float = 0.0
var _empuje: Vector2 = Vector2.ZERO
var _golpeando: float = 0.0
var _cd_ataque: float = 0.0
var _ya_golpeados: Array = []  # cuerpos ya tocados en esta estocada

var espada: Area2D


func _ready() -> void:
	_crear_espada()


func _crear_espada() -> void:
	espada = Area2D.new()
	espada.collision_layer = 0
	espada.collision_mask = 4  # capa enemigo
	var forma := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(TAMANO_ESPADA, TAMANO_ESPADA)
	forma.shape = rect
	espada.add_child(forma)
	var hoja := Polygon2D.new()
	var h := TAMANO_ESPADA / 2.0
	hoja.polygon = PackedVector2Array([
		Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)])
	hoja.color = Color(0.78, 0.8, 0.86)
	espada.add_child(hoja)
	add_child(espada)
	espada.visible = false
	espada.monitoring = true  # siempre activa: miramos solapes durante el golpe


func _physics_process(delta: float) -> void:
	if _invulnerable > 0:
		_invulnerable -= 1
		$Cuerpo.visible = (_invulnerable / 3) % 2 == 0  # parpadeo rápido
	else:
		$Cuerpo.visible = true

	if _cd_ataque > 0.0:
		_cd_ataque -= delta
	if _golpeando > 0.0:
		_golpeando -= delta
		_procesar_golpe()
		if _golpeando <= 0.0:
			espada.visible = false
			_ya_golpeados.clear()

	if _retroceso > 0.0:
		_retroceso -= delta
		velocity = _empuje
	else:
		var entrada := Input.get_vector("mover_izq", "mover_der", "mover_arriba", "mover_abajo")
		if entrada != Vector2.ZERO:
			direccion = entrada.normalized()
			velocity = direccion * velocidad_efectiva
		else:
			velocity = Vector2.ZERO  # corte nítido al soltar
		if Input.is_action_just_pressed("atacar") and _cd_ataque <= 0.0:
			_atacar()
	move_and_slide()


func _atacar() -> void:
	_golpeando = DURACION_GOLPE
	_cd_ataque = DURACION_GOLPE + ENFRIAMIENTO_ATAQUE
	_ya_golpeados.clear()
	espada.visible = true
	_posicionar_espada()


func _posicionar_espada() -> void:
	espada.global_position = global_position + direccion * ALCANCE_ESPADA
	espada.rotation = direccion.angle()


func _procesar_golpe() -> void:
	_posicionar_espada()
	for cuerpo in espada.get_overlapping_bodies():
		if cuerpo in _ya_golpeados:
			continue
		_ya_golpeados.append(cuerpo)
		if cuerpo.has_method("recibir_danio"):
			cuerpo.recibir_danio(DANO_ESPADA, global_position)


func recibir_danio(cantidad: int, origen: Vector2) -> bool:
	## Devuelve true si el daño se aplicó (false = invulnerable o ya caído).
	if _invulnerable > 0 or vida <= 0:
		return false
	var danio := cantidad - defensa
	if danio <= 0:
		return false  # la armadura absorbe el golpe entero (sin i-frames: no toca)
	vida = maxi(0, vida - danio)
	_invulnerable = FRAMES_INVULNERABLE
	var dir := global_position - origen
	_empuje = (dir if dir != Vector2.ZERO else Vector2.UP).normalized() * FUERZA_RETROCESO
	_retroceso = DURACION_RETROCESO
	vida_cambiada.emit(vida)
	if vida == 0:
		muerto.emit()
	return true


func refrescar_estadisticas() -> void:
	## Recalcula vida máxima, defensa y velocidad a partir del equipo equipado.
	if inventario == null:
		return
	var bonus_vida: int = inventario.bonus("vida_max")
	var nuevo_max: int = VIDA_MAX + bonus_vida
	if nuevo_max > vida_max:
		vida += nuevo_max - vida_max  # equipar vida máxima otorga corazones ya
	vida_max = maxi(1, nuevo_max)
	vida = mini(vida, vida_max)
	defensa = inventario.bonus("defensa")
	velocidad_efectiva = VELOCIDAD + inventario.bonus("velocidad")
	vida_cambiada.emit(vida)
