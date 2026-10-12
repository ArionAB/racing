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

## [b]Opt-in, Transfagarasan (oct 2026).[/b] Semaforul de la tunel era invizibil
## pe telefon: lampa statea la nivelul soselei, cu becuri de 0,34 m fara emisie.
## Cu `glow_energy > 0` becul APRINS foloseste `Palette.glow_material` (emisie pe
## slotul lui, cate un material per culoare, partajat) iar becul STINS ramane
## vizibil si INTUNECAT (slot ASPHALT, pe materialul lumii: zero materiale
## noi). Implicit 0 = comportamentul vechi, bit-identic (Track16 si restul).
@export_range(0.0, 8.0, 0.1) var glow_energy: float = 0.0:
	set(value):
		glow_energy = value
		_rebuild()

## Care becuri ard pe material emisiv (indici in `slots`). Gol = toate. Un bec
## care nu se aprinde niciodata (galbenul semaforului de santier) n-are nevoie
## de materialul lui emisiv, iar garda numara materialele per pista.
@export var glow_bulbs: Array[int] = []:
	set(value):
		glow_bulbs = value
		_rebuild()

## Inaltimea capului lampii fata de nodul-radacina (m). Cu `pole_slot >= 0`
## se construieste si un stalp de la nod pana la cap. Implicit 0 = ca inainte.
@export_range(0.0, 10.0, 0.1) var head_height: float = 0.0:
	set(value):
		head_height = value
		_rebuild()

## Cat iese capul lampii spre -X local, pe o consola orizontala prinsa de stalp
## (semaforul de santier sta pe acostament si priveste peste banda). 0 = capul
## direct pe stalp.
@export_range(0.0, 10.0, 0.1) var arm_length: float = 0.0:
	set(value):
		arm_length = value
		_rebuild()

## Inverseaza ordinea pe verticala: slotul 0 jos, ultimul slot SUS. Implicit
## (fals) slotul 0 sta SUS, deci pe un semafor [verde, galben, rosu] rosul e
## jos — invers decat zice comentariul din `_rebuild`. Raman neatinse pistele
## existente; semaforul de santier din Transfagarasan cere rosul sus, ca in
## viata reala.
@export var invert_stack: bool = false:
	set(value):
		invert_stack = value
		_rebuild()

## Slotul stalpului (negativ = fara stalp).
@export var pole_slot: int = -1:
	set(value):
		pole_slot = value
		_rebuild()

## Latimea unei linii de oprire pe sosea, trasata la nivelul nodului, spre
## interior (-X local). 0 = fara. Doar un indiciu vizual, fara coliziune.
@export_range(0.0, 20.0, 0.5) var stop_line_span: float = 0.0:
	set(value):
		stop_line_span = value
		_rebuild()

## Distanta de la stalp pana la mijlocul liniei de oprire (pe -X local).
@export_range(0.0, 20.0, 0.1) var stop_line_offset: float = 0.0:
	set(value):
		stop_line_offset = value
		_rebuild()

var _bulbs: Array[MeshInstance3D] = []
var _dark: Array[MeshInstance3D] = []
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
	_dark.clear()
	var n := slots.size()
	if n == 0:
		return
	var span := float(n - 1) * spacing
	var hs := Vector3(bulb_size * 1.5, span + bulb_size * 1.6, bulb_size * 0.5)
	if not vertical:
		hs = Vector3(span + bulb_size * 1.6, bulb_size * 1.5, bulb_size * 0.5)
	var head_x := -arm_length
	if pole_slot >= 0 and head_height > 0.0:
		# Stalpul urca pana deasupra capului; consola il leaga de cap.
		var top := head_height + hs.y * 0.5 + 0.1
		add_child(PaletteBox.instance(Vector3(0.22, top + 0.5, 0.22),
			pole_slot, Vector3(0.0, (top - 0.5) * 0.5, -bulb_size * 0.9)))
		if arm_length > 0.0:
			add_child(PaletteBox.instance(Vector3(arm_length + 0.22, 0.18, 0.18),
				pole_slot, Vector3(head_x * 0.5, top, -bulb_size * 0.9)))
	if stop_line_span > 0.0:
		add_child(PaletteBox.instance(Vector3(stop_line_span, 0.1, 2.0),
			Palette.FOAM_WHITE, Vector3(-stop_line_offset, 0.09, 0.0)))
	if housing_slot >= 0:
		add_child(PaletteBox.instance(hs, housing_slot,
			Vector3(head_x, head_height, -bulb_size * 0.4)))
	for i in n:
		var t := float(i) * spacing - span * 0.5
		if invert_stack:
			t = -t
		# Semaforul are ROSUL SUS, ca orice semafor: primul slot din lista e
		# primul din drumul ciclului (verde), deci pe verticala se numara de
		# jos in sus.
		var at := Vector3(0.0, -t, 0.0) if vertical else Vector3(t, 0.0, 0.0)
		at.y += head_height
		at.x += head_x
		var bulb := PaletteBox.instance(Vector3.ONE * bulb_size, slots[i], at)
		bulb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bulb.visible = i == _lit
		if glow_energy > 0.0 and (glow_bulbs.is_empty() or i in glow_bulbs):
			bulb.material_override = Palette.glow_material(slots[i], glow_energy)
		if glow_energy > 0.0:
			# Becul stins: cutie INTUNECATA pe materialul lumii, ca sa se vada
			# ca e o lampa stinsa, nu o gaura.
			var dark := PaletteBox.instance(Vector3.ONE * bulb_size, Palette.ASPHALT, at)
			dark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			dark.visible = i != _lit
			add_child(dark)
			_dark.append(dark)
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
		var on := i == _lit and _blink_on
		_bulbs[i].visible = on
		if i < _dark.size():
			_dark[i].visible = not on


## Ce bec e aprins acum (pentru sonde). -1 = niciunul.
func lit() -> int:
	return _lit if _blink_on else -1
