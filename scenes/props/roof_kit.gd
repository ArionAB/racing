@tool
class_name RoofKit
extends Node3D
## MOBILIERUL TERASELOR (Jodhpur, Track17, POI D, runda 4): rezervoare negre
## de apa, ghivece cu copaci mici si franghii de rufe colorate, generate din
## cod pe atlasul lumii. Criticul orb (runda 3): „pe aproape fiecare terasa din
## referinta sunt 1–3 rezervoare NEGRE cilindrice, un copac mic in ghiveci,
## rufe/panze colorate; la noi un butoi maro si fete mari goale".
##
## De ce nu `rooftop_tank.glb`: rezervorul kitului e pe slotul 28 (LOG_DARK,
## #4A3526, maro), iar referinta il are negru. Aici corpul e pe slotul 26
## (#1A2A33, aproape negru) — ACELASI material (`Palette.world_material()`),
## doar alt UV, deci niciun material nou. Totul se uneste intr-un singur mesh
## pe celula de CELL_M (cateva desene pe toata zona, nu unul pe piesa).
## Fara coliziune: stau pe acoperisuri (ca `rooftop_tank`, clasa `none`).
##
## Construit in `_ready` (nu amanat), ca sa apara in capturi; materialul se
## pune amanat, dupa `WorldProp` (vezi `LimeWalls`).

## Rezervoare: baza (lume) si scara (1 = 1,25 m diametru, 1,3 m inaltime).
@export var tanks: PackedVector3Array = PackedVector3Array()
@export var tank_scales: PackedFloat32Array = PackedFloat32Array()
## Ghivece: baza (lume); coroana deasupra.
@export var pots: PackedVector3Array = PackedVector3Array()
## Franghii de rufe: perechi de capete (lume, la cota franghiei).
@export var lines: PackedVector3Array = PackedVector3Array()

const CELL_M := 150.0
const TANK_SLOT := 26
const TANK_RIM_SLOT := 5
const POT_SLOT := 23
const CROWN_SLOTS := [21, 12]
const POLE_SLOT := 9
const ROPE_SLOT := 28
## Panzele: rosu, galben, roz, portocaliu, albastru, verde.
const CLOTH_SLOTS := [14, 16, 31, 30, 15, 21]
const SEG := 12

var _meshes: Array[MeshInstance3D] = []
var _built := false


func _ready() -> void:
	if _built:
		return
	_built = true
	global_transform = Transform3D.IDENTITY
	var cells := {}
	for i in tanks.size():
		var sc := tank_scales[i] if i < tank_scales.size() else 1.0
		_tank(_cell(cells, tanks[i]), tanks[i], sc, i)
	for i in pots.size():
		_pot(_cell(cells, pots[i]), pots[i], i)
	for i in range(0, lines.size() - 1, 2):
		_line(_cell(cells, lines[i]), lines[i], lines[i + 1], i)
	for key: Vector2i in cells:
		var st: SurfaceTool = cells[key]
		var mi := MeshInstance3D.new()
		mi.name = "Terase_%d_%d" % [key.x, key.y]
		mi.mesh = MeshCpu.with_lods(st.commit())
		mi.lod_bias = 0.5 # piese mici (rezervoare, ghivece, sfori): vezi BazaarKit
		add_child(mi)
		_meshes.append(mi)
	_apply_materials.call_deferred()


func _apply_materials() -> void:
	for mi in _meshes:
		mi.material_override = Palette.world_material()


func _cell(cells: Dictionary, p: Vector3) -> SurfaceTool:
	var key := Vector2i(floori(p.x / CELL_M), floori(p.z / CELL_M))
	if not cells.has(key):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		cells[key] = st
	return cells[key]


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, slot: int,
		ca: float = 1.0, cb: float = 1.0, cc: float = 1.0) -> void:
	# Normala plata, sensul acelor de ceas vazut din afara (Godot).
	var n := (c - a).cross(b - a).normalized()
	var uv := Palette.uv(slot)
	for pr: Array in [[a, ca], [b, cb], [c, cc]]:
		st.set_normal(n)
		st.set_uv(uv)
		var v: float = pr[1]
		st.set_color(Color(v, v, v))
		st.add_vertex(pr[0])


func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		slot: int, two_sided: bool = false) -> void:
	_tri(st, a, b, c, slot)
	_tri(st, a, c, d, slot)
	if two_sided:
		_tri(st, a, c, b, slot)
		_tri(st, a, d, c, slot)


## Cilindru: inel de SEG laturi, cu capac sus (si bombat, daca dome > 0).
func _cyl(st: SurfaceTool, base: Vector3, r0: float, r1: float, h: float,
		slot: int, dome: float, seg: int, ao0: float) -> void:
	for k in seg:
		var a0 := TAU * float(k) / float(seg)
		var a1 := TAU * float(k + 1) / float(seg)
		var d0 := Vector3(cos(a0), 0.0, sin(a0))
		var d1 := Vector3(cos(a1), 0.0, sin(a1))
		var b0 := base + d0 * r0
		var b1 := base + d1 * r0
		var t0 := base + d0 * r1 + Vector3.UP * h
		var t1 := base + d1 * r1 + Vector3.UP * h
		# Laturile cu normale RADIALE (netede): cu normala plata rezervorul
		# iesea fatetat, cu fete aproape negre (captura 0,380).
		var uv := Palette.uv(slot)
		for vv: Array in [[b0, d0, ao0], [b1, d1, ao0], [t0, d0, 1.0],
				[b1, d1, ao0], [t1, d1, 1.0], [t0, d0, 1.0]]:
			st.set_normal(vv[1])
			st.set_uv(uv)
			var c: float = vv[2]
			st.set_color(Color(c, c, c))
			st.add_vertex(vv[0])
		var top := base + Vector3.UP * (h + dome)
		_tri(st, t0, t1, top, slot)


func _tank(st: SurfaceTool, p: Vector3, sc: float, idx: int) -> void:
	var r := 0.62 * sc
	var h := 1.1 * sc
	# Corpul cu doua nervuri (inele putin mai late), capacul bombat.
	_cyl(st, p, r, r, h * 0.45, TANK_SLOT, 0.0, SEG, 0.55)
	_cyl(st, p + Vector3.UP * h * 0.45, r * 1.04, r * 1.04, 0.06 * sc, TANK_SLOT, 0.0, SEG, 1.0)
	_cyl(st, p + Vector3.UP * (h * 0.45 + 0.06 * sc), r, r, h * 0.55 - 0.06 * sc,
		TANK_SLOT, 0.18 * sc, SEG, 1.0)
	# Gura de vizitare: un disc mic, gri, pe capac.
	_cyl(st, p + Vector3.UP * (h + 0.14 * sc), 0.2 * sc, 0.2 * sc, 0.08 * sc,
		TANK_RIM_SLOT, 0.0, 8, 1.0)


func _pot(st: SurfaceTool, p: Vector3, idx: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 104729 * (idx + 1)
	_cyl(st, p, 0.22, 0.3, 0.45, POT_SLOT, 0.0, 8, 0.6)
	# Tulpina + coroana: sfera joasa (6 x 4), putin turtita.
	var trunk_h := rng.randf_range(0.35, 0.6)
	_cyl(st, p + Vector3.UP * 0.45, 0.05, 0.04, trunk_h, POLE_SLOT, 0.0, 4, 1.0)
	var c := p + Vector3.UP * (0.45 + trunk_h + 0.3)
	var rr := rng.randf_range(0.42, 0.6)
	var slot: int = CROWN_SLOTS[rng.randi() % CROWN_SLOTS.size()]
	var rings := 4
	var segs := 6
	var yaw := rng.randf_range(0.0, TAU)
	for i in rings:
		var p0 := PI * float(i) / float(rings)
		var p1 := PI * float(i + 1) / float(rings)
		for k in segs:
			var a0 := yaw + TAU * float(k) / float(segs)
			var a1 := yaw + TAU * float(k + 1) / float(segs)
			var v := func(ph: float, a: float) -> Vector3:
				return c + Vector3(sin(ph) * cos(a) * rr, cos(ph) * rr * 0.8, sin(ph) * sin(a) * rr)
			var q00: Vector3 = v.call(p0, a0)
			var q01: Vector3 = v.call(p0, a1)
			var q10: Vector3 = v.call(p1, a0)
			var q11: Vector3 = v.call(p1, a1)
			var ao := lerpf(1.0, 0.7, float(i) / float(rings))
			if i > 0:
				_tri(st, q00, q10, q01, slot, ao, ao, ao)
			if i < rings - 1:
				_tri(st, q01, q10, q11, slot, ao, ao, ao)


## Franghie intre doi stalpi, cu panze colorate atarnate, pas regulat.
func _line(st: SurfaceTool, a: Vector3, b: Vector3, idx: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7727 * (idx + 3)
	var dir := b - a
	dir.y = 0.0
	var ln := dir.length()
	if ln < 1.0:
		return
	dir /= ln
	var side := Vector3.UP.cross(dir).normalized()
	# Stalpii: de la acoperis (1,6 m sub franghie) pana la franghie.
	for e: Vector3 in [a, b]:
		var s0 := e - Vector3.UP * 1.6
		var w := 0.05
		var c0 := s0 + (dir + side) * w
		var c1 := s0 + (dir - side) * w
		var c2 := s0 + (-dir - side) * w
		var c3 := s0 + (-dir + side) * w
		var up := Vector3.UP * 1.65
		_quad(st, c0, c0 + up, c1 + up, c1, POLE_SLOT, true)
		_quad(st, c1, c1 + up, c2 + up, c2, POLE_SLOT, true)
		_quad(st, c2, c2 + up, c3 + up, c3, POLE_SLOT, true)
		_quad(st, c3, c3 + up, c0 + up, c0, POLE_SLOT, true)
	# Franghia: panglica subtire.
	var t := Vector3.UP * 0.03
	_quad(st, a - t, b - t, b + t, a + t, ROPE_SLOT, true)
	# Panzele.
	var x := 0.15
	var k := rng.randi() % CLOTH_SLOTS.size()
	while x < ln - 0.5:
		var w := rng.randf_range(0.45, 0.7)
		if x + w > ln - 0.1:
			break
		var hgt := rng.randf_range(0.7, 1.05)
		var p0 := a + dir * x + (b.y - a.y) * (x / ln) * Vector3.UP
		var p1 := a + dir * (x + w) + (b.y - a.y) * ((x + w) / ln) * Vector3.UP
		var sw := side * rng.randf_range(-0.08, 0.08)
		_quad(st, p0, p1, p1 - Vector3.UP * hgt + sw, p0 - Vector3.UP * hgt + sw,
			CLOTH_SLOTS[k % CLOTH_SLOTS.size()], true)
		k += 1
		x += w + rng.randf_range(0.08, 0.2)
