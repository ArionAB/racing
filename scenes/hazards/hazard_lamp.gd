@tool
class_name HazardLamp
extends Node3D
## Semnalul luminos al unui hazard ciclic — semafor de santier, girofar de
## macara, luminile unei treceri — construit FARA material nou.
##
## [b]Cum se aprinde un bec fara material propriu[/b]. Un bec e in mod normal
## un `StandardMaterial3D` nesumbrit caruia i se schimba `albedo_color` (asa
## fac `TrainHazard` si `LiftBridgeHazard`), adica inca un material per hazard
## intr-o garda care numara materialele per pista. Aici becurile sunt cutii pe
## atlasul de paleta, cate una per culoare, si „aprins" inseamna VIZIBIL:
## comutam `visible`, nu culoarea. Zero materiale noi, si semnalul se citeste
## la fel de bine de la 100 m — pe ecranul unui telefon, un bec e oricum doi
## pixeli colorati.
##
## Ce se pierde: becurile nu ard in intuneric, fiindca albedo-ul de pe atlas
## nu e emisiv. Cand tema Chongqing isi aduce clasa emisiva partajata
## (`neon_emissive`, brief §4) becurile pot trece pe ea fara sa se schimbe
## nimic aici — materialul e o singura linie in `_build`.

## Cat de mare e un bec (latura cutiei).
@export_range(0.1, 1.5, 0.05) var bulb_size: float = 0.34:
	set(value):
		bulb_size = value
		_rebuild()

## Distanta dintre becuri.
@export_range(0.2, 3.0, 0.05) var spacing: float = 0.72:
	set(value):
		spacing = value
		_rebuild()

## Becurile stau unul peste altul (semafor) sau unul langa altul (trecere).
@export var vertical: bool = true:
	set(value):
		vertical = value
		_rebuild()

## Sloturile de paleta ale becurilor, in ordine (0 = primul).
@export var slots: Array[int] = [Palette.CACTUS_GREEN, Palette.CAR_YELLOW,
	Palette.KERB_RED]:
	set(value):
		slots = value
		_rebuild()

## Carcasa din spatele becurilor. Gol (slot negativ) = fara carcasa.
@export var housing_slot: int = Palette.ASPHALT:
	set(value):
		housing_slot = value
		_rebuild()

var _bulbs: Array[MeshInstance3D] = []
var _lit: int = -1
var _blink_on: bool = true


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_bulbs.clear()
	var n := slots.size()
	if n == 0:
		return
	var span := float(n - 1) * spacing
	if housing_slot >= 0:
		var hs := Vector3(bulb_size * 1.5, span + bulb_size * 1.6, bulb_size * 0.5)
		if not vertical:
			hs = Vector3(span + bulb_size * 1.6, bulb_size * 1.5, bulb_size * 0.5)
		add_child(PaletteBox.instance(hs, housing_slot,
			Vector3(0.0, 0.0, -bulb_size * 0.4)))
	for i in n:
		var t := float(i) * spacing - span * 0.5
		# Semaforul are ROSUL SUS, ca orice semafor: primul slot din lista e
		# primul din drumul ciclului (verde), deci pe verticala se numara de
		# jos in sus.
		var at := Vector3(0.0, -t, 0.0) if vertical else Vector3(t, 0.0, 0.0)
		var bulb := PaletteBox.instance(Vector3.ONE * bulb_size, slots[i], at)
		bulb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bulb.visible = i == _lit
		add_child(bulb)
		_bulbs.append(bulb)


## Aprinde becul `idx` (-1 = toate stinse). Idempotent.
func set_lit(idx: int) -> void:
	_lit = idx
	_blink_on = true
	_apply()


## Aprinde `idx` intermitent: `on` vine din ceasul hazardului, ca sa nu existe
## doua surse de timp.
func blink(idx: int, on: bool) -> void:
	_lit = idx
	_blink_on = on
	_apply()


func _apply() -> void:
	for i in _bulbs.size():
		_bulbs[i].visible = i == _lit and _blink_on


## Ce bec e aprins acum (pentru sonde). -1 = niciunul.
func lit() -> int:
	return _lit if _blink_on else -1
