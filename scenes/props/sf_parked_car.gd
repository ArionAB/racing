@tool
extends Node3D
## Masina parcata de pe strazile San Francisco (Track25, brief san_francisco.md §3 „Masinile
## parcate”, §7 pasul 6). PLACEHOLDER: trei caroserii din cutii (sedan, hatchback, duba), in
## culori stinse din atlasul de paleta (zero materiale noi: `Palette.world_material()`), cu AO
## pe vertex. Modelele reale vin cu foaia de assets.
##
## In joc piesa devine `BumpProp` (corp rigid ADORMIT, stratul 9: masinile il lovesc, razele
## suspensiei, camera si AI-ul nu-l vad) cu masa unei masini de joc, nu de jucarie, si cu
## `home` (se intoarce la locul ei cand s-a oprit si nu e nimeni la 30 m), deci nu ramane in
## drum. O masina parcata are 3,7 m: peste plafonul de marime al decorului bump-abil (2 m), deci
## cere `max_footprint` explicit — vezi `BumpProp.wrap`.
##
## Asezarea: generatorul (tools/gen_sf_route.py) pune nodul la cota estimata a drumului din
## dreptul lui; la rulare, dupa primul pas de fizica (terenul are coliziune abia atunci), o raza
## verticala pe stratul 1 il lasa pe sol. Fara sol sub el (> 4 m), ramane unde l-a pus scena.

## 0 sedan, 1 hatchback, 2 duba.
@export_range(0, 2) var body_kind: int = 0:
	set(v):
		body_kind = v
		if is_inside_tree():
			_build()
## Slotul de paleta al caroseriei (culori stinse: PAINTED_METAL, CORAL_SAND, ROCK_LIGHT...).
@export var color_slot: int = Palette.PAINTED_METAL:
	set(v):
		color_slot = v
		if is_inside_tree():
			_build()
## Valul 2 (nov 2026): caroseria e modelul `sf_parked_{sedan,wagon,van}.glb` (scris de
## tools/gen_sf_route.py), recolorat pe instanta: fetele cu UV pe slotul 11 (vopseaua, singurul
## lucru de pe 11 in model) trec pe `color_slot`. Un mesh per (caroserie, slot), cu LOD-urile
## importului (aceiasi indici -> `MeshCpu.surface_lods`), pe materialul lumii: zero materiale noi.
## COLIZIUNEA ramane cea a placeholderului (gabaritul lui, prin optiunea `box` a BumpProp), ca
## toate contactele masurate la pasul 6 sa ramana valabile; stins = placeholderul din cutii.
@export var use_glb: bool = false:
	set(v):
		use_glb = v
		if is_inside_tree():
			_build()
## Masa (kg). Masinile de joc: 100 x mass_factor (Politia 90, Buggy 100, Autobuzul 260).
@export var mass_kg: float = 140.0
## Se intoarce la locul ei dupa ce s-a oprit (BumpProp `home`).
@export var go_home: bool = true
## Cauta solul la rulare (raza verticala); stins = exact transformul din scena.
@export var snap_to_ground: bool = true

## Dimensiunile caroseriei (latime, lungime) — aceleasi la toate trei, ca locurile de parcare
## sa nu depinda de varianta.
const WIDTH: float = 1.9
const LENGTH: float = 3.7
## Plafonul de marime cerut de BumpProp pentru piesa asta (diagonala nu conteaza: AABB-ul e
## masurat fara rotatia radacinii).
const FOOTPRINT_M: float = 4.5
const SNAP_REACH_M: float = 4.0
## Modelele valului 2, pe `body_kind` (0 sedan, 1 break, 2 duba). Botul pe -Z, ca placeholderul.
const MODELS: Array[String] = [
	"res://assets/models/sanfrancisco/vehicles/sf_parked_sedan.glb",
	"res://assets/models/sanfrancisco/vehicles/sf_parked_wagon.glb",
	"res://assets/models/sanfrancisco/vehicles/sf_parked_van.glb",
]
## Slotul vopselei in GLB (measure_sf_street.py: caroseria toata pe 11, nimic altceva pe el).
const BODY_SLOT: int = Palette.PAINTED_METAL

static var _meshes: Dictionary = {}
static var _glb_meshes: Dictionary = {}
static var _glb_src: Dictionary = {}

var _mi: MeshInstance3D


func _ready() -> void:
	_build()
	if Engine.is_editor_hint():
		return
	_activate.call_deferred()


func _build() -> void:
	if _mi != null and is_instance_valid(_mi):
		_mi.free()
	_mi = MeshInstance3D.new()
	_mi.name = "Body"
	var glb: ArrayMesh = glb_mesh_for(body_kind, color_slot) if use_glb else null
	_mi.mesh = glb if glb != null else mesh_for(body_kind, color_slot)
	_mi.material_override = Palette.world_material()
	add_child(_mi)


## Dupa primul pas de fizica: pe sol, apoi corp rigid.
func _activate() -> void:
	await get_tree().physics_frame
	if not is_inside_tree():
		return
	if snap_to_ground:
		var from := global_position + Vector3.UP * SNAP_REACH_M
		var to := global_position + Vector3.DOWN * SNAP_REACH_M
		var q := PhysicsRayQueryParameters3D.create(from, to, 1)
		var hit := get_world_3d().direct_space_state.intersect_ray(q)
		if not hit.is_empty():
			var n: Vector3 = hit["normal"]
			var fwd := -global_transform.basis.z
			fwd = (fwd - n * fwd.dot(n)).normalized()
			if fwd.length_squared() > 0.5 and n.y > 0.7:
				global_transform = Transform3D(Basis.looking_at(fwd, n), hit["position"])
	add_to_group(&"sf_parked_cars")
	# Gabaritul de coliziune e MEREU al placeholderului (vezi `use_glb`).
	var body := BumpProp.wrap(_mi, {"mass": mass_kg, "home": go_home,
		"max_footprint": FOOTPRINT_M, "box": mesh_for(body_kind, color_slot).get_aabb()})
	if body != null:
		body.add_to_group(&"sf_parked_bodies")
		body.set_meta("sf_parked_home", body.global_position)


## Mesh-ul variantei (partajat intre instante cu aceeasi varianta si culoare). Cutii cu fete
## plate, UV spre slotul de paleta, AO pe vertex (jos mai inchis). ~150 de triunghiuri, fara
## LOD: e sub pragul la care un LOD scade ceva (CLAUDE.md cere LOD pe copiile mesh-urilor
## importate, care au mii de triunghiuri).
static func mesh_for(kind: int, slot: int) -> ArrayMesh:
	var key := "%d_%d" % [kind, slot]
	if _meshes.has(key):
		return _meshes[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var w := WIDTH
	var l := LENGTH
	var body_h := 0.55
	var floor_y := 0.28
	match kind:
		0: # sedan: cabina la mijloc, portbagaj
			_box(st, Vector3(0, floor_y, 0), Vector3(w, body_h, l), slot, 0.62, 0.95)
			_box(st, Vector3(0, floor_y + body_h, 0.15), Vector3(w * 0.86, 0.5, l * 0.48),
				slot, 0.85, 1.0)
			_glass(st, Vector3(0, floor_y + body_h + 0.08, 0.15), Vector3(w * 0.88, 0.34, l * 0.46))
		1: # hatchback: cabina spre spate, scurta
			_box(st, Vector3(0, floor_y, 0), Vector3(w, body_h, l * 0.92), slot, 0.62, 0.95)
			_box(st, Vector3(0, floor_y + body_h, 0.32), Vector3(w * 0.86, 0.55, l * 0.55),
				slot, 0.85, 1.0)
			_glass(st, Vector3(0, floor_y + body_h + 0.1, 0.30), Vector3(w * 0.88, 0.36, l * 0.5))
		_: # duba: un singur volum inalt
			_box(st, Vector3(0, floor_y, 0), Vector3(w, 1.05, l), slot, 0.6, 0.95)
			_box(st, Vector3(0, floor_y + 1.05, 0.25), Vector3(w * 0.96, 0.28, l * 0.78),
				slot, 0.9, 1.0)
			_glass(st, Vector3(0, floor_y + 0.62, -l * 0.5 + 0.18), Vector3(w * 0.9, 0.38, 0.4))
	# rotile: cutii negre la colturi (sub caroserie, vizibile din lateral)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_box(st, Vector3(sx * (w * 0.5 - 0.17), 0.0, sz * (l * 0.5 - 0.62)),
				Vector3(0.36, 0.56, 0.62), Palette.VOLCANIC_BLACK, 0.5, 0.7)
	st.generate_normals()
	var mesh := st.commit()
	_meshes[key] = mesh
	return mesh


## Mesh-ul modelului GLB al caroseriei `kind`, recolorat pe `slot` (partajat intre instantele cu
## aceeasi caroserie si culoare). Pe slotul vopselei din model se intoarce chiar mesh-ul importat;
## altfel o copie cu ACEIASI indici (doar UV-ul mutat pe slotul nou, cu acelasi decalaj in slot),
## care poarta LOD-urile importului. Null daca modelul lipseste (ramane placeholderul).
static func glb_mesh_for(kind: int, slot: int) -> ArrayMesh:
	var key := "%d_%d" % [kind, slot]
	if _glb_meshes.has(key):
		return _glb_meshes[key]
	var src := _glb_source(clampi(kind, 0, MODELS.size() - 1))
	if src == null:
		return null
	if slot == BODY_SLOT:
		_glb_meshes[key] = src
		return src
	var shift := float(slot - BODY_SLOT) / float(Palette.SLOTS)
	var out := ArrayMesh.new()
	for s in src.get_surface_count():
		var arrays := MeshCpu.surface_arrays(src, s)
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		for i in uvs.size():
			var u := uvs[i]
			if int(floor(u.x * float(Palette.SLOTS))) == BODY_SLOT:
				u.x += shift
				uvs[i] = u
		arrays[Mesh.ARRAY_TEX_UV] = uvs
		MeshCpu.add_surface(out, arrays, MeshCpu.surface_lods(src, s))
	_glb_meshes[key] = out
	return out


## Mesh-ul importat al caroseriei (singurul MeshInstance3D din GLB, la origine).
static func _glb_source(kind: int) -> ArrayMesh:
	if _glb_src.has(kind):
		return _glb_src[kind]
	var mesh: ArrayMesh = null
	if ResourceLoader.exists(MODELS[kind]):
		var inst := (load(MODELS[kind]) as PackedScene).instantiate()
		for c in inst.find_children("*", "MeshInstance3D", true, false):
			mesh = (c as MeshInstance3D).mesh as ArrayMesh
			break
		inst.free()
	_glb_src[kind] = mesh
	return mesh


static func _glass(st: SurfaceTool, base: Vector3, size: Vector3) -> void:
	_box(st, base, size, Palette.ASPHALT, 0.8, 0.9)


## Cutie cu baza centrata in `base` (y = talpa), fete separate (normale plate).
static func _box(st: SurfaceTool, base: Vector3, size: Vector3, slot: int, ao_lo: float,
		ao_hi: float) -> void:
	var uv := Palette.uv(slot)
	var hx := size.x * 0.5
	var hz := size.z * 0.5
	var y0 := base.y
	var y1 := base.y + size.y
	var c := [
		Vector3(-hx, y0, -hz), Vector3(hx, y0, -hz), Vector3(hx, y0, hz), Vector3(-hx, y0, hz),
		Vector3(-hx, y1, -hz), Vector3(hx, y1, -hz), Vector3(hx, y1, hz), Vector3(-hx, y1, hz),
	]
	for i in c.size():
		c[i] = c[i] + Vector3(base.x, 0.0, base.z)
	var lo := Color(ao_lo, ao_lo, ao_lo)
	var hi := Color(ao_hi, ao_hi, ao_hi)
	# fete: (a, b, c, d) in sens trigonometric privit din afara; Godot vrea fata in sens ORAR,
	# deci triunghiurile se emit invers (0, 2, 1 / 0, 3, 2)
	var faces := [
		[4, 7, 6, 5],  # sus
		[0, 1, 2, 3],  # jos
		[3, 2, 6, 7],  # +z
		[1, 0, 4, 5],  # -z
		[2, 1, 5, 6],  # +x
		[0, 3, 7, 4],  # -x
	]
	for f in faces:
		var p: Array = [c[f[0]], c[f[1]], c[f[2]], c[f[3]]]
		var cols: Array = []
		for q: Vector3 in p:
			cols.append(lo if q.y <= y0 + 0.001 else hi)
		for idx in [0, 2, 1, 0, 3, 2]:
			st.set_uv(uv)
			st.set_color(cols[idx])
			st.add_vertex(p[idx])
