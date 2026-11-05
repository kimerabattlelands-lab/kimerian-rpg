class_name Jugador
extends CharacterBody2D

## Jugador estilo Zelda ALttP: movimiento de 8 direcciones con corte nítido
## (sin aceleración, como los clásicos), 5 PV, invulnerabilidad breve con
## parpadeo y retroceso al recibir daño. La espada llega en el siguiente hito.

signal vida_cambiada(actual: int)
signal muerto

const VELOCIDAD := 95.0          # px/s ≈ 3 tiles de 32 px por segundo
const VIDA_MAX := 5
const FRAMES_INVULNERABLE := 45  # ~0,75 s a 60 fps
const FUERZA_RETROCESO := 150.0  # px/s durante el retroceso
const DURACION_RETROCESO := 0.15 # s

var vida: int = VIDA_MAX
var direccion: Vector2 = Vector2.DOWN  # última dirección de movimiento (para sprite/espada)
var _invulnerable: int = 0
var _retroceso: float = 0.0
var _empuje: Vector2 = Vector2.ZERO


func _physics_process(delta: float) -> void:
	if _invulnerable > 0:
		_invulnerable -= 1
		$Cuerpo.visible = (_invulnerable / 3) % 2 == 0  # parpadeo rápido
	else:
		$Cuerpo.visible = true

	if _retroceso > 0.0:
		_retroceso -= delta
		velocity = _empuje
	else:
		var entrada := Input.get_vector("mover_izq", "mover_der", "mover_arriba", "mover_abajo")
		if entrada != Vector2.ZERO:
			direccion = entrada.normalized()
			velocity = direccion * VELOCIDAD
		else:
			velocity = Vector2.ZERO  # corte nítido al soltar
	move_and_slide()


func recibir_danio(cantidad: int, origen: Vector2) -> bool:
	## Devuelve true si el daño se aplicó (false = invulnerable o ya caído).
	if _invulnerable > 0 or vida <= 0:
		return false
	vida = maxi(0, vida - cantidad)
	_invulnerable = FRAMES_INVULNERABLE
	var dir := global_position - origen
	_empuje = (dir if dir != Vector2.ZERO else Vector2.UP).normalized() * FUERZA_RETROCESO
	_retroceso = DURACION_RETROCESO
	vida_cambiada.emit(vida)
	if vida == 0:
		muerto.emit()
	return true
