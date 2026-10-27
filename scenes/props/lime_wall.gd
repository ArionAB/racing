@tool
class_name LimeWalls
extends StaticBody3D
## ZIDURI SUBTIRI DE VAR ALBASTRU (Jodhpur, Track17, POI D/D′) — piesa din cod,
## aprobata de coordonator in runda 3: kitul n-are o casa sub ~6,3 m adancime,
## iar ulicioara si buzunarul dintre ea si bucla au 3-8 m. Criticul orb cerea
## „doua fronturi continue de case albastre umar la umar" pe ulicioara si
## „fara sol vizibil" intre case pe strada.
##
## Fiecare zid e un bloc de lungime x adancime x inaltime (local X = in lungul
## frontului, +Z = fata spre culoar), cu parapet pe coama, ferestre pe etaje si
## o usa la parter. TOATE zidurile zonei stau intr-un singur nod: mesh-urile se
## unesc pe material (var deschis, indigo, usi, ferestre) si pe celule de
## CELL_M, deci cateva draw call-uri, nu 3 pe zid (masurat la prima varianta,
## un nod per zid: +650 de desene pe pista).
##
## FARA material nou: peretele ia exact materialul clasei caselor
## (`Palette.triplanar_class_material("blue_lime_light"/"_indigo")`, aceeasi
## instanta ca pe `blue_house_*`), usa atlasul lumii, ferestrele `jod_window`
## (se aprind cu `dusk_lamps`). Materialele se pun AMANAT: `WorldProp` (parintele
## DecorManual) trece in `_ready` pe TOATE MeshInstance3D din subarbore si le
## pune materialul lumii — masurat: zidurile ieseau pe atlas, slotul 0.
## AO simplu in vertex colors (baza mai inchisa), ca la kit. Coliziune: o cutie
## pe fiecare zid, toate pe acest corp static.
##
## Construit in `_ready` (nu amanat), ca sa apara in capturi (memoria
## `decorul-amanat-nu-e-in-captura`); doar materialele sunt amanate.

## Per zid: pozitia bazei (lume, centrul amprentei), yaw-ul fetei, dimensiunile
## (lungime, adancime, inaltime) si steagurile: bit 0 indigo, bit 1 usa,
## bitii 2-3 ferestre pe fata (0-3), bitii 4-5 ferestre pe spate, bit 6
## prispa (treapta joasa la baza fatadei: fara parapet, fara goluri).
@export var origins: PackedVector3Array = PackedVector3Array()
@export var yaws: PackedFloat32Array = PackedFloat32Array()
@export var sizes: PackedVector3Array = PackedVector3Array()
@export var flags: PackedInt32Array = PackedInt32Array()

const CELL_M := 150.0
const PARAPET_H := 0.75
const PARAPET_T := 0.22
const FLOOR_H := 2.9
const WIN_W := 0.7
const WIN_H := 1.0
## Sloturile atlasului: usa (lemn, ca `House_Trim`), fereastra (ca `House_Glow`).
const DOOR_SLOT := 9
const WIN_SLOT := 20
## AO copt: baza la 0,72, coama la 1,0.
const AO_BASE := 0.72

var _meshes: Array = [] # [MeshInstance3D, kind]
var _built := false


func _ready() -> void:
	if _built:
		return
	_built = true
	global_transform = Transform3D.IDENTITY
	var cells := {}
	for i in origins.size():
		var o := origins[i]
		var key := Vector2i(floori(o.x / CELL_M), floori(o.z / CELL_M))
		if not cells.has(key):
			var sts := []
			for k in 4:
				var st := SurfaceTool.new()
				st.begin(Mesh.PRIMITIVE_TRIANGLES)
				sts.append(st)
			cells[key] = {"st": sts, "n": [0, 0, 0, 0]}
		var cell: Dictionary = cells[key]
		var xf := Transform3D(Basis(Vector3.UP, yaws[i]), o)
		var sz := sizes[i]
		var fl := flags[i] if i < flags.size() else 0
		var wall_k := 1 if (fl & 1) != 0 else 0
		if (fl & 64) != 0:
			_box(cell["st"][wall_k], xf, Vector3(-sz.x * 0.5, 0.0, -sz.y * 0.5),
				Vector3(sz.x * 0.5, sz.z, sz.y * 0.5), sz.z, false)
			cell["n"][wall_k] += 1
		else:
			_wall(cell["st"][wall_k], xf, sz)
			cell["n"][wall_k] += 1
			var nd := _openings(cell["st"][2], cell["st"][3], xf, sz, fl, i)
			cell["n"][2] += nd.x
			cell["n"][3] += nd.y
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		# sizes = (lungime, adancime, inaltime); cutia e (X, Y, Z) locale.
		box.size = Vector3(sz.x, sz.z, sz.y)
		cs.shape = box
		cs.transform = Transform3D(xf.basis, o + Vector3.UP * (sz.z * 0.5))
		add_child(cs)
	for key: Vector2i in cells:
		var cell: Dictionary = cells[key]
		for k in 4:
			if int(cell["n"][k]) == 0:
				continue
			var st: SurfaceTool = cell["st"][k]
			if k < 2:
				st.generate_normals()
			var mi := MeshInstance3D.new()
			mi.name = "%s_%d_%d" % [["Var", "Indigo", "Usi", "Ferestre_Glow"][k], key.x, key.y]
			mi.mesh = MeshCpu.with_lods(st.commit())
			if k == 3:
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(mi)
			_meshes.append([mi, k])
	_apply_materials.call_deferred()


func _apply_materials() -> void:
	for e: Array in _meshes:
		var mi: MeshInstance3D = e[0]
		match int(e[1]):
			0:
				mi.material_override = Palette.triplanar_class_material("blue_lime_light")
			1:
				mi.material_override = Palette.triplanar_class_material("blue_lime_indigo")
			2:
				mi.material_override = Palette.world_material()
			3:
				mi.material_override = Palette.shader_material("jod_window")


func _ao(y: float, h: float) -> Color:
	var k := clampf(y / maxf(h, 0.1), 0.0, 1.0)
	var v := lerpf(AO_BASE, 1.0, sqrt(k))
	return Color(v, v, v)


## Corpul + parapetul unui zid, in coordonate de lume.
func _wall(st: SurfaceTool, xf: Transform3D, sz: Vector3) -> void:
	var hx := sz.x * 0.5
	var hz := sz.y * 0.5
	var h := sz.z
	_box(st, xf, Vector3(-hx, 0.0, -hz), Vector3(hx, h, hz), h, false)
	var t := PARAPET_T
	var y1 := h + PARAPET_H
	_box(st, xf, Vector3(-hx, h, hz - t), Vector3(hx, y1, hz), h, true)
	_box(st, xf, Vector3(-hx, h, -hz), Vector3(hx, y1, -hz + t), h, true)
	_box(st, xf, Vector3(-hx, h, -hz + t), Vector3(-hx + t, y1, hz - t), h, true)
	_box(st, xf, Vector3(hx - t, h, -hz + t), Vector3(hx, y1, hz - t), h, true)


## Cutie din 5 fete (fara fundul). Godot: fata din fata e in sensul acelor de
## ceas, vazuta din afara.
func _box(st: SurfaceTool, xf: Transform3D, a: Vector3, b: Vector3, h: float,
		top_ao: bool) -> void:
	var c := [Vector3(a.x, a.y, a.z), Vector3(b.x, a.y, a.z), Vector3(b.x, a.y, b.z),
		Vector3(a.x, a.y, b.z), Vector3(a.x, b.y, a.z), Vector3(b.x, b.y, a.z),
		Vector3(b.x, b.y, b.z), Vector3(a.x, b.y, b.z)]
	var quads := [[3, 2, 6, 7], [1, 0, 4, 5], [0, 3, 7, 4], [2, 1, 5, 6], [7, 6, 5, 4]]
	for q: Array in quads:
		var v: Array[Vector3] = [c[q[0]], c[q[1]], c[q[2]], c[q[3]]]
		for tri: Array in [[0, 2, 1], [0, 3, 2]]:
			for i: int in tri:
				st.set_color(Color(1, 1, 1) if top_ao else _ao(v[i].y, h))
				st.set_uv(Vector2.ZERO)
				st.add_vertex(xf * v[i])


## Usa si ferestrele: panouri lipite de fata (+0,03 m), UV colapsat pe slot.
## Intoarce (usi, ferestre) puse.
func _openings(st_door: SurfaceTool, st_win: SurfaceTool, xf: Transform3D,
		sz: Vector3, fl: int, idx: int) -> Vector2i:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7919 * (idx + 1)
	var hx := sz.x * 0.5
	var hz := sz.y * 0.5
	var nd := 0
	var nw := 0
	var door := (fl & 2) != 0
	for face: float in [1.0, -1.0]:
		var n := ((fl >> 2) & 3) if face > 0.0 else ((fl >> 4) & 3)
		if n <= 0:
			continue
		var z := face * (hz + 0.03)
		var floors := maxi(int(floor((sz.z - 0.4) / FLOOR_H)), 1)
		for f in floors:
			var cy := float(f) * FLOOR_H + 1.6
			for k in n:
				var cx := -hx + sz.x * (float(k) + 0.5) / float(n) + rng.randf_range(-0.2, 0.2)
				if f == 0 and door and face > 0.0 and k == n / 2:
					_panel(st_door, xf, Vector3(cx, 0.0, z), 1.0, 2.2, face, DOOR_SLOT)
					nd += 1
				else:
					_panel(st_win, xf, Vector3(cx, cy - WIN_H * 0.5, z), WIN_W, WIN_H, face, WIN_SLOT)
					nw += 1
	return Vector2i(nd, nw)


func _panel(st: SurfaceTool, xf: Transform3D, base: Vector3, w: float, h: float,
		face: float, slot: int) -> void:
	var uv := Palette.uv(slot)
	var x0 := base.x - w * 0.5
	var x1 := base.x + w * 0.5
	var p := [Vector3(x0, base.y, base.z), Vector3(x1, base.y, base.z),
		Vector3(x1, base.y + h, base.z), Vector3(x0, base.y + h, base.z)]
	var order := [0, 2, 1, 0, 3, 2] if face > 0.0 else [0, 1, 2, 0, 2, 3]
	var nrm := xf.basis * Vector3(0, 0, face)
	for i: int in order:
		st.set_normal(nrm)
		st.set_color(Color(1, 1, 1))
		st.set_uv(uv)
		st.add_vertex(xf * p[i])
