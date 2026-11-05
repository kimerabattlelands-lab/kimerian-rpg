extends CharacterBody2D

## Enemigo básico: patrulla en ciclo determinista (sin RNG), persigue al
## jugador si se acerca, daña por contacto (1 PV, con i-frames del jugador)
## y muere a los 2 golpes de espada con retroceso y destello.

signal muerto

const PATRULLA := 40.0
const PERSECUCION := 68.0
const DETECCION := 150.0
const VIDA_MAX := 2
const DANO_CONTACTO := 1
const DISTANCIA_CONTACTO := 20.0   # px: toque (7+7) es 14, margen holgado
const PERIODO_PATRULLA := 1.5      # s por tramo antes de girar
const FUERZA_RETROCESO := 120.0
const DURACION_RETROCESO := 0.15

const CICLO: Array = [Vector2.LEFT, Vector2.UP, Vector2.RIGHT, Vector2.DOWN]

var vida: int = VIDA_MAX
var objetivo  # jugador — dinámico a propósito: sin tipo global (class cache)
var ia_activa: bool = true
var _indice_ciclo: int = 0
var _tiempo_tramo: float = 0.0
var _retroceso: float = 0.0
var _empuje: Vector2 = Vector2.ZERO


func _physics_process(delta: float) -> void:
	if _retroceso > 0.0:
		_retroceso -= delta
		velocity = _empuje
	elif ia_activa:
		velocity = _calcular_velocidad(delta)
	else:
		velocity = Vector2.ZERO

	var antes: Vector2 = global_position
	move_and_slide()

	if ia_activa and _retroceso <= 0.0 and global_position.is_equal_approx(antes):
		_avanzar_ciclo()  # atascado contra muro u otro cuerpo: gira ya

	_contacto()


func _calcular_velocidad(delta: float) -> Vector2:
	if objetivo != null:
		var dist: float = global_position.distance_to(objetivo.global_position)
		if dist < DETECCION:
			return (objetivo.global_position - global_position).normalized() * PERSECUCION
	_tiempo_tramo -= delta
	if _tiempo_tramo <= 0.0:
		_avanzar_ciclo()
	return CICLO[_indice_ciclo] * PATRULLA


func _avanzar_ciclo() -> void:
	_indice_ciclo = (_indice_ciclo + 1) % CICLO.size()
	_tiempo_tramo = PERIODO_PATRULLA


func _contacto() -> void:
	if objetivo == null or vida <= 0:
		return
	var dist: float = global_position.distance_to(objetivo.global_position)
	if dist < DISTANCIA_CONTACTO and objetivo.has_method("recibir_danio"):
		objetivo.recibir_danio(DANO_CONTACTO, global_position)


func recibir_danio(cantidad: int, origen: Vector2) -> bool:
	## Misma interfaz que el jugador: espada y enemigos se llaman igual.
	if vida <= 0:
		return false
	vida = maxi(0, vida - cantidad)
	var dir := global_position - origen
	_empuje = (dir if dir != Vector2.ZERO else Vector2.UP).normalized() * FUERZA_RETROCESO
	_retroceso = DURACION_RETROCESO
	var brillo := create_tween()
	brillo.tween_property(self, "modulate", Color(2.0, 1.2, 1.2), 0.05)
	brillo.tween_property(self, "modulate", Color.WHITE, 0.1)
	if vida == 0:
		muerto.emit()
		queue_free()
	return true
