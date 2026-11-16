@tool
extends Node3D
## Mobilierul MIC de strada din San Francisco (Track25, valul 2, inventar §5.3: M4 hidrant / cutie
## postala / automat de ziare / cos / con, M8 capcane de crabi / lada / colac de franghie), ca
## `BumpProp`: corp rigid ADORMIT pe care masina il imprastie (stratul 9: razele suspensiei, camera
## si AI-ul nu-l vad), cu `home` — se intoarce la locul lui cand s-a oprit si nu e nimeni la 30 m,
## deci nu ramane in drum.
##
## De ce un nod cu script si nu o instanta GLB in `DecorManual` cu `coliziune = "bump"`: fisierele
## multi-varianta (`sf_street_props.glb`, `sf_crab_traps.glb`) au toate variantele suprapuse in
## origine, iar BumpProp isi masoara cutia din AABB-ul TUTUROR mesh-urilor modelului, ascunse sau
## nu — un hidrant ar fi primit cutia cutiei postale. Aici se pastreaza DOAR nodul `part`. Si un
## BumpProp sub un nod cu script nu intra in coacerea MultiMesh a decorului manual (vezi BumpProp).
##
## Asezarea: generatorul (tools/gen_sf_route.py) pune nodul pe teren (harta coapta); la rulare,
## dupa primul pas de fizica, o raza verticala il lasa pe sol, ca la masinile parcate.

## Fisierul cu variantele.
@export var model: PackedScene:
	set(v):
		model = v
		if is_inside_tree():
			_build()
## Numele nodului-varianta din GLB (gol = tot modelul).
@export var part: String = "":
	set(v):
		part = v
		if is_inside_tree():
			_build()
## Masa (kg); 0 = densitatea de jucarie a BumpProp (0,3-4 kg).
@export var mass_kg: float = 0.0
@export var go_home: bool = true
@export var snap_to_ground: bool = true

const SNAP_REACH_M: float = 2.0

var _body_root: Node3D


func _ready() -> void:
	_build()
	if Engine.is_editor_hint():
		return
	_activate.call_deferred()


func _build() -> void:
	if _body_root != null and is_instance_valid(_body_root):
		_body_root.free()
	_body_root = null
	if model == null:
		return
	var inst := model.instantiate() as Node3D
	var src: Node3D = inst
	if not part.is_empty():
		src = inst.find_child(part, true, false) as Node3D
	if src == null:
		push_warning("SfStreetPiece %s: nu gasesc varianta '%s'" % [name, part])
		inst.free()
		return
	_body_root = Node3D.new()
	_body_root.name = "Body"
	var meshes: Array[Node] = src.find_children("*", "MeshInstance3D", true, false)
	if src is MeshInstance3D:
		meshes.push_front(src)
	for n in meshes:
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		var copy := MeshInstance3D.new()
		copy.name = mi.name
		copy.mesh = mi.mesh
		# transformarea fata de VARIANTA (originea ei = baza piesei, centrata)
		var xf := Transform3D.IDENTITY
		var cur: Node = mi
		while cur != null and cur != src:
			xf = (cur as Node3D).transform * xf
			cur = cur.get_parent()
		copy.transform = xf
		copy.material_override = Palette.world_material()
		_body_root.add_child(copy)
	inst.free()
	add_child(_body_root)


## Dupa primul pas de fizica: pe sol, apoi corp rigid.
func _activate() -> void:
	await get_tree().physics_frame
	if not is_inside_tree() or _body_root == null:
		return
	if snap_to_ground:
		var from := global_position + Vector3.UP * SNAP_REACH_M
		var to := global_position + Vector3.DOWN * SNAP_REACH_M
		var q := PhysicsRayQueryParameters3D.create(from, to, 1)
		var hit := get_world_3d().direct_space_state.intersect_ray(q)
		if not hit.is_empty() and (hit["normal"] as Vector3).y > 0.7:
			global_position = hit["position"]
	var opts := {"home": go_home}
	if mass_kg > 0.0:
		opts["mass"] = mass_kg
	var body := BumpProp.wrap(_body_root, opts)
	if body != null:
		body.add_to_group(&"sf_street_bodies")
