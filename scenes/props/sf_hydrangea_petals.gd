extends Node3D
## Petalele hortensiilor din serpentinele San Francisco (Track25, brief san_francisco.md §2
## „Scurtatura”, §7 pasul 6): cand o masina loveste blocul SOLID al unui ac (corpul static
## `SerpStraturi`, deja existent), din stratul de hortensii de deasupra zboara petale roz sau
## albastre. Hortensiile raman doar vizuale: nicio coliziune noua, nicio zona noua pe drum.
##
## Declansatorul e semnalul `Car.impact` (tipul `wall`, cu corpul lovit), adica acelasi prag pe care
## il folosesc sunetul si camera la izbituri (`impact_min_dv`, cu pauza proprie a masinii). O masina
## care se freaca de zid nu emite impacturi peste prag in fiecare tick, iar fiecare strat are in plus
## pauza lui (`cooldown_s`). Petalele sunt rafalele de frunze ale managerului comun `PropDebris`
## (3 rafale x 8 placi, un singur material partajat, culoarea pe particula): zero materiale noi si
## plafonul de particule al managerului.
##
## Masinile apar dupa pista, deci nodul le cauta in grupul `cars` din cand in cand si se leaga la
## fiecare o singura data.

## Centrele fetei de sus a blocurilor solide (lume), cate unul pe ac. Le scrie generatorul.
@export var bed_tops: PackedVector3Array = PackedVector3Array()
## Pauza per strat (s): un strat nu mai arunca petale pana nu trece.
@export var cooldown_s: float = 1.0
## Lovitura la care rafala e plina (dv orizontal, m/s); sub ea, mai putine si mai lente.
@export var full_dv: float = 14.0
@export var pink: Color = Color(0.95, 0.55, 0.75)
@export var blue: Color = Color(0.55, 0.65, 1.0)

const PropDebris := preload("res://scenes/props/prop_debris.gd")
const BODY_NAME := &"SerpStraturi"

var _cool: PackedFloat32Array = PackedFloat32Array()
var _scan_left: float = 0.0
var _flip: bool = false
## Statistici pentru sonde.
var bursts: int = 0
var refused: int = 0


func _ready() -> void:
	_cool.resize(bed_tops.size())
	_cool.fill(0.0)
	# Managerul comun se creeaza AMANAT la prima cerere (PropDebris._ensure), deci prima rafala
	# s-ar pierde: il cerem de acum.
	if not Engine.is_editor_hint():
		PropDebris._ensure(get_tree())


func _physics_process(delta: float) -> void:
	for i in _cool.size():
		_cool[i] = maxf(_cool[i] - delta, 0.0)
	_scan_left -= delta
	if _scan_left > 0.0:
		return
	_scan_left = 0.5
	for c in get_tree().get_nodes_in_group(&"cars"):
		var car := c as Car
		if car != null and not car.impact.is_connected(_on_impact):
			car.impact.connect(_on_impact)


func _on_impact(_car: Car, kind: StringName, strength: float, normal: Vector3, point: Vector3,
		other: Node) -> void:
	if kind != &"wall" or other == null or other.name != BODY_NAME or bed_tops.is_empty():
		return
	var best := -1
	var bd := INF
	for i in bed_tops.size():
		var d := Vector2(bed_tops[i].x - point.x, bed_tops[i].z - point.z).length()
		if d < bd:
			bd = d
			best = i
	if _cool[best] > 0.0:
		refused += 1
		return
	_cool[best] = cooldown_s
	var k := clampf(strength / full_dv, 0.2, 1.0)
	var at := Vector3(point.x, bed_tops[best].y + 0.4, point.z)
	var dir := Vector3(normal.x, 0.0, normal.z) * 0.6 + Vector3.UP
	_flip = not _flip
	if PropDebris.leaf_burst(get_tree(), at, dir, k, pink if _flip else blue):
		bursts += 1
