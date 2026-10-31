class_name BusDepot
extends Node3D
## CAPATUL autobuzului (issue #600): „trebuie sa porneasca de undeva si sa se
## opreasca undeva, nu sa apara subit si sa dispara subit”.
##
## Un [BusHazard] sta ascuns intre doua coborari (13 s din 75), si pana acum
## aparea / disparea in aer liber, pe un deal, vazut de pe tot bazinul (masurat:
## 26-50 de pozitii de camera il vedeau la capatul de sus si la cel de jos). O
## ocluzie reala nu se poate face din teren, deci capetele sunt CLADIRI: o
## cochera cu usa rulanta.
##
##   PLECARE (`mode = EXIT`): autobuzul e ARATAT in cochera, cu usa inchisa
##     (zidurile il ascund). Usa urca (scade in sus, ca o rulanta), autobuzul
##     asteapta `BusHazard.dwell_s` si iese; cand coada a trecut de prag, usa
##     coboara la loc.
##   SOSIRE (`mode = ENTRY`): usa se deschide cand autobuzul e la `open_ahead_m`
##     de prag; autobuzul intra, iar cand coada a trecut pragul usa coboara. Capatul
##     curbei e destul de adanc ca `BusHazard._hide` (teleportarea sus) sa cada
##     DUPA ce usa s-a inchis — niciun cadru in care autobuzul dispare cu usa
##     deschisa (garda: tools/probe_bus_depot.gd).
##
## Geometria: sistemul local are pragul in z = 0, interiorul spre -Z (adancimea
## `depth`), apropierea spre +Z. Nodul se pune pe pista cu `yaw_deg`
## (rotatia in jurul lui Y; z local ajunge pe directia de mers la iesire).
##
## Un singur mesh pe materialul partajat al lumii (`Palette.world_material()`,
## sloturi de paleta pe UV) — zero materiale noi. Usa e al doilea mesh (se
## scaleaza pe Y). Coliziune: placa cu fundatie, doi pereti, peretele din spate,
## acoperisul si usa — tot ce ascunde si ochiului ascunde si razei garzii.
## Raza de teren a autobuzului (`PathMover._ground_y`) porneste doar 4 m
## deasupra lui, deci sub acoperis (`inner_height` >= 4.1): nimereste podeaua.

enum Mode { EXIT, ENTRY }

## GALERIE FARA USA (trenul PeruRail, issue #601): aceeasi cutie, fara usa si
## fara platforma — `has_door = false`, `apron_length = 0`, culori prin
## `wall_slot` / `roof_slot` / `lintel_slot`. Capul de tunel al unui obiect
## care trebuie sa dispara sub ochii jucatorului: obiectul intra, iese din
## cadru, iar teleportarea (ascunderea) cade in interior. Cutia e destul de
## lunga ca garnitura intreaga sa incapa (vezi `depth`).
@export var has_door: bool = true
@export var wall_slot: int = Palette.MARBLE_GREY
@export var roof_slot: int = Palette.TILE_TERRACOTTA
@export var lintel_slot: int = Palette.CAR_YELLOW

## Autobuzul servit (nod BusHazard).
@export var bus_path: NodePath
@export var mode: Mode = Mode.EXIT
## Rotatia in jurul lui Y (grade). z local = directia de iesire a autobuzului.
@export_range(-180.0, 180.0, 1.0) var yaw_deg: float = 0.0
## Adancimea interiorului (m). Autobuzul are 6.2 m; capatul curbei sta la
## `depth - 3.5` m de prag, deci coada ramane in interior si botul nu atinge fundul.
@export_range(8.0, 80.0, 0.5) var depth: float = 14.0
## Latimea libera (m) — autobuzul are 3.7.
@export_range(4.0, 9.0, 0.1) var inner_width: float = 5.8
## Inaltimea libera (m) — autobuzul are 3.1.
@export_range(4.1, 8.0, 0.1) var inner_height: float = 4.4
## Cat de adanc coboara fundatia sub podea (m): peste terenul care fuge.
@export_range(0.0, 30.0, 0.5) var foundation_drop: float = 0.0
## Platforma din fata pragului (m), la cota podelei.
@export_range(0.0, 20.0, 0.5) var apron_length: float = 8.0
@export_range(0.0, 12.0, 0.5) var apron_half_width: float = 3.6
## ENTRY: usa incepe sa se deschida cand autobuzul e la atata de prag.
@export_range(5.0, 80.0, 1.0) var open_ahead_m: float = 40.0
@export_range(0.2, 3.0, 0.05) var open_seconds: float = 0.8
@export_range(0.2, 3.0, 0.05) var close_seconds: float = 0.7

const WALL: float = 0.5
const SLAB: float = 0.4
const ROOF: float = 0.3
const LINTEL_H: float = 0.9
## Cat sta usa inchisa-deschisa: scara pe Y la usa „deschisa” (adunata sus).
const DOOR_OPEN_SCALE: float = 0.03
## Coada autobuzului (semilungime 3.1 + marja) trebuie sa treaca de prag.
const TAIL_CLEAR: float = 3.8
## Cat de departe lateral de axa mai conteaza autobuzul pentru usa (m).
const LATERAL_REACH: float = 12.0

var _bus: BusHazard
var _door: Node3D
## 1.0 = inchisa, 0.0 = deschisa.
var _closed: float = 1.0
var _door_shape: BoxShape3D
var _door_cs: CollisionShape3D
var _door_h: float = 0.0


func _ready() -> void:
	rotation.y = deg_to_rad(yaw_deg)
	_build()
	if not bus_path.is_empty():
		_bus = get_node_or_null(bus_path) as BusHazard


func _build() -> void:
	var hw := inner_width * 0.5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ap_hw := maxf(apron_half_width, hw + WALL)
	var z_back := -depth - WALL
	# Placa (podeaua) si apron-ul, o singura cutie.
	var slab_z0 := z_back
	var slab_z1 := apron_length
	_box(st, Vector3(0.0, -SLAB * 0.5, (slab_z0 + slab_z1) * 0.5),
		Vector3(ap_hw * 2.0, SLAB, slab_z1 - slab_z0), Palette.CONCRETE, 0.9)
	if foundation_drop > 0.0:
		_box(st, Vector3(0.0, -SLAB - foundation_drop * 0.5, (slab_z0 + slab_z1) * 0.5),
			Vector3(ap_hw * 2.0 - 0.4, foundation_drop, slab_z1 - slab_z0 - 0.4),
			Palette.MARBLE_GREY, 0.8)
	# Pereti laterali si spate: granit, ca zidaria cetatii.
	for s: float in [-1.0, 1.0]:
		_box(st, Vector3(s * (hw + WALL * 0.5), inner_height * 0.5, -depth * 0.5),
			Vector3(WALL, inner_height, depth), wall_slot, 1.0)
	_box(st, Vector3(0.0, inner_height * 0.5, z_back + WALL * 0.5),
		Vector3(inner_width + WALL * 2.0, inner_height, WALL), wall_slot, 0.95)
	# Buiandrugul, in galben Consettur, peste usa.
	var door_h := inner_height - LINTEL_H
	_box(st, Vector3(0.0, door_h + LINTEL_H * 0.5, 0.0),
		Vector3(inner_width + WALL * 2.0, LINTEL_H, WALL + 0.4), lintel_slot, 1.0)
	# Acoperis: tabla, cu streasina.
	_box(st, Vector3(0.0, inner_height + ROOF * 0.5, -depth * 0.5 + 0.4),
		Vector3(inner_width + WALL * 2.0 + 1.2, ROOF, depth + WALL + 1.6), roof_slot, 1.0)
	var mi := MeshInstance3D.new()
	mi.name = "Cochera"
	mi.mesh = st.commit()
	mi.material_override = Palette.world_material()
	add_child(mi)

	if has_door:
		# Usa rulanta: pivot sus, scara pe Y. Lamele alternate, ca sa citeasca a rulanta.
		_door = Node3D.new()
		_door.name = "Usa"
		_door.position = Vector3(0.0, door_h, 0.0)
		var dst := SurfaceTool.new()
		dst.begin(Mesh.PRIMITIVE_TRIANGLES)
		var slats := maxi(int(round(door_h / 0.55)), 3)
		var sh := door_h / float(slats)
		for i in slats:
			_box(dst, Vector3(0.0, -(float(i) + 0.5) * sh, 0.0),
				Vector3(inner_width, sh, 0.16),
				Palette.PAINTED_METAL if i % 2 == 0 else Palette.RUST_METAL, 1.0)
		var dmi := MeshInstance3D.new()
		dmi.mesh = dst.commit()
		dmi.material_override = Palette.world_material()
		_door.add_child(dmi)
		add_child(_door)
		_apply_door()

	# Coliziune (vezi antet). Usa are corp, redimensionat odata cu
	# ea (scara unui corp fizic nu se aplica): inchisa e un zid si pentru raze —
	# garda o foloseste ca ocluzor — iar deschisa e o lama de 13 cm sus.
	_door_h = door_h
	var body := StaticBody3D.new()
	body.name = "Corp"
	add_child(body)
	_shape(body, Vector3(0.0, -(SLAB + foundation_drop) * 0.5, (slab_z0 + slab_z1) * 0.5),
		Vector3(ap_hw * 2.0, SLAB + foundation_drop, slab_z1 - slab_z0))
	for s: float in [-1.0, 1.0]:
		_shape(body, Vector3(s * (hw + WALL * 0.5), inner_height * 0.5, -depth * 0.5),
			Vector3(WALL, inner_height, depth))
	_shape(body, Vector3(0.0, inner_height * 0.5, z_back + WALL * 0.5),
		Vector3(inner_width + WALL * 2.0, inner_height, WALL))
	_shape(body, Vector3(0.0, door_h + LINTEL_H * 0.5, 0.0),
		Vector3(inner_width + WALL * 2.0, LINTEL_H, WALL + 0.4))
	_shape(body, Vector3(0.0, inner_height + ROOF * 0.5, -depth * 0.5 + 0.4),
		Vector3(inner_width + WALL * 2.0 + 1.2, ROOF, depth + WALL + 1.6))
	if has_door:
		_door_cs = CollisionShape3D.new()
		_door_shape = BoxShape3D.new()
		_door_shape.size = Vector3(inner_width, door_h, 0.16)
		_door_cs.shape = _door_shape
		_door_cs.position = Vector3(0.0, door_h * 0.5, 0.0)
		body.add_child(_door_cs)
	_apply_door()


func _shape(body: StaticBody3D, center: Vector3, size: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	cs.position = center
	body.add_child(cs)


func _physics_process(delta: float) -> void:
	if _door == null:
		return
	if _bus == null:
		if not bus_path.is_empty():
			_bus = get_node_or_null(bus_path) as BusHazard
		if _bus == null:
			return
	var want_open := want_door_open()
	var step := delta / (open_seconds if want_open else close_seconds)
	_closed = clampf(_closed + (-step if want_open else step), 0.0, 1.0)
	_apply_door()


## Pozitia autobuzului in sistemul cocherei: z = la cati metri de prag, + spre
## apropiere, − in interior. Public ca garda sa citeasca aceeasi cifra.
func bus_local_z() -> float:
	return to_local(_bus.body_position()).z


## Autobuzul in sistemul cocherei (x lateral, z ca mai sus).
func bus_local() -> Vector3:
	return to_local(_bus.body_position())


## Regula usii, intr-un loc: o citeste si garda.
func want_door_open() -> bool:
	if _bus == null or _bus.is_hidden():
		return false
	var p := bus_local()
	var z := p.z
	# Doar autobuzul de langa prag: drumul de sus trece la 100+ m lateral de
	# cochera de jos, dar z local al lui ar putea cadea in interval.
	if absf(p.x) > LATERAL_REACH:
		return false
	match mode:
		Mode.EXIT:
			return z < TAIL_CLEAR
		_:
			return z < open_ahead_m and z > -TAIL_CLEAR
	return false


## 0 = deschisa complet, 1 = inchisa complet.
func door_closed_amount() -> float:
	return _closed


func _apply_door() -> void:
	if _door == null:
		return
	var e := _closed * _closed * (3.0 - 2.0 * _closed)
	var k := lerpf(DOOR_OPEN_SCALE, 1.0, e)
	_door.scale.y = k
	if _door_shape != null:
		_door_shape.size.y = _door_h * k
		_door_cs.position.y = _door_h - _door_h * k * 0.5


func _box(st: SurfaceTool, c: Vector3, size: Vector3, slot: int, shade: float) -> void:
	var h := size * 0.5
	var uv := Palette.uv(slot)
	var p := [
		c + Vector3(-h.x, -h.y, -h.z), c + Vector3(h.x, -h.y, -h.z),
		c + Vector3(h.x, -h.y, h.z), c + Vector3(-h.x, -h.y, h.z),
		c + Vector3(-h.x, h.y, -h.z), c + Vector3(h.x, h.y, -h.z),
		c + Vector3(h.x, h.y, h.z), c + Vector3(-h.x, h.y, h.z),
	]
	# fata, indici, normala. Infasurare ca in TrainHazard._box.
	var faces := [
		[[4, 5, 6, 7], Vector3.UP, 1.0],
		[[1, 0, 3, 2], Vector3.DOWN, 0.6],
		[[0, 1, 5, 4], Vector3.FORWARD, 0.85],
		[[2, 3, 7, 6], Vector3.BACK, 0.85],
		[[3, 0, 4, 7], Vector3.LEFT, 0.8],
		[[1, 2, 6, 5], Vector3.RIGHT, 0.8],
	]
	for f: Array in faces:
		var idx: Array = f[0]
		var n: Vector3 = f[1]
		var col := Color(shade * float(f[2]), shade * float(f[2]), shade * float(f[2]))
		for tri: Array in [[0, 1, 2], [0, 2, 3]]:
			for k: int in tri:
				st.set_normal(n)
				st.set_uv(uv)
				st.set_color(col)
				st.add_vertex(p[idx[k]])
