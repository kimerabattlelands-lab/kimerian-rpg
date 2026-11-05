extends RefCounted

## Inventario con stacks, descarte y 4 huecos de equipo (cabeza, pecho, botas,
## casco). Modelo puro: no pinta nada; la UI se engancha a la señal
## `actualizado`. Todo el contenido está en datos_objetos.gd.

signal actualizado

const DATOS := preload("res://scripts/datos_objetos.gd")
const MAX_HUECOS := 16
const SLOTS_EQUIPO: Array = ["cabeza", "pecho", "botas", "casco"]

var huecos: Array = []      # Dictionary {id, cantidad} o null, tamaño fijo
var equipados: Dictionary = {}  # slot -> id o null


func _init() -> void:
	huecos.resize(MAX_HUECOS)
	huecos.fill(null)
	for slot in SLOTS_EQUIPO:
		equipados[slot] = null


func agregar(id: String, cantidad: int = 1) -> bool:
	## Primero funde en pilas existentes, luego llena huecos vacíos partiendo
	## por el tope de stack. Devuelve true si entró todo; false = sobró algo.
	if not DATOS.OBJETOS.has(id):
		return false
	var restante := cantidad
	var tope: int = DATOS.OBJETOS[id].get("stack", 1)
	for hueco in huecos:
		if restante <= 0:
			break
		if hueco != null and hueco.id == id and hueco.cantidad < tope:
			var mover: int = mini(tope - hueco.cantidad, restante)
			hueco.cantidad += mover
			restante -= mover
	for i in huecos.size():
		if restante <= 0:
			break
		if huecos[i] == null:
			var meter: int = mini(tope, restante)
			huecos[i] = {"id": id, "cantidad": meter}
			restante -= meter
	actualizado.emit()
	return restante == 0


func descartar(indice: int) -> bool:
	## Desecha el hueco entero (pila incluida).
	if indice < 0 or indice >= MAX_HUECOS or huecos[indice] == null:
		return false
	huecos[indice] = null
	actualizado.emit()
	return true


func equipar(indice: int) -> bool:
	## Equipa el objeto del hueco en su slot; si el slot ya estaba ocupado,
	## el objeto anterior vuelve al hueco que se acaba de vaciar (intercambio).
	if indice < 0 or indice >= MAX_HUECOS or huecos[indice] == null:
		return false
	var hueco: Dictionary = huecos[indice]
	var slot: String = DATOS.OBJETOS[hueco.id].get("slot", "")
	if slot == "":
		return false  # no es objeto equipable
	var anterior = equipados[slot]
	equipados[slot] = hueco.id
	huecos[indice] = anterior
	actualizado.emit()
	return true


func desequipar(slot: String) -> bool:
	## Devuelve el objeto equipado al primer hueco libre. false = inventario lleno.
	if not equipados.has(slot) or equipados[slot] == null:
		return false
	for i in huecos.size():
		if huecos[i] == null:
			huecos[i] = {"id": equipados[slot], "cantidad": 1}
			equipados[slot] = null
			actualizado.emit()
			return true
	return false


func bonus(stat: String) -> int:
	## Suma del efecto `stat` entre todo lo equipado.
	var suma := 0
	for slot in SLOTS_EQUIPO:
		var id = equipados[slot]
		if id != null:
			suma += DATOS.OBJETOS[id].efectos.get(stat, 0)
	return suma


func total(id: String) -> int:
	var suma := 0
	for hueco in huecos:
		if hueco != null and hueco.id == id:
			suma += hueco.cantidad
	return suma


func contar_ocupados() -> int:
	var n := 0
	for hueco in huecos:
		if hueco != null:
			n += 1
	return n


func indice_de(id: String) -> int:
	for i in huecos.size():
		if huecos[i] != null and huecos[i].id == id:
			return i
	return -1


func quitar_uno(indice: int) -> bool:
	## Consume una unidad; si era la última, vacía el hueco (fin de la pila).
	if indice < 0 or indice >= MAX_HUECOS or huecos[indice] == null:
		return false
	var hueco: Dictionary = huecos[indice]
	hueco.cantidad -= 1
	if hueco.cantidad <= 0:
		huecos[indice] = null
	actualizado.emit()
	return true
