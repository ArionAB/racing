class_name GlbWorld
extends Node3D
## Incarca un GLB arbitrar ca lume condusibila: fiecare MeshInstance3D primeste
## un StaticBody3D cu forma trimesh si backface_collision (fara asta masina cade
## prin poligoanele orientate invers — acelasi motiv ca in
## Track._add_mesh_with_collision).
##
## Destinatia reala: exporturile Marble (World Labs) — mesh-uri GLB de
## 100-200 MB care NU intra in repo. De aceea exista doua cai de incarcare:
##   res://...        scena importata de Godot (asset din repo, pentru teste)
##   cale absoluta    GLTFDocument.append_from_file, fara pipeline de import —
##                    fisierul e citit direct de pe disc, la rulare
##
## GlbWorld nu stie nimic de trasee, tururi sau AI: e doar geometrie + coliziune.
## Spina de drum, waypoint-urile si logica de cursa raman treaba lui Track.

@export var glb_path: String = ""
@export var world_scale: float = 1.0

## Cutia care cuprinde toate mesh-urile, in spatiul lumii. Valida dupa build().
var bounds: AABB
var mesh_count: int = 0
var triangle_count: int = 0

func _ready() -> void:
	if not glb_path.is_empty():
		build(glb_path, world_scale)


func build(path: String, scale_factor: float = 1.0) -> bool:
	var root := _load_glb(path)
	if root == null:
		push_error("GlbWorld: nu pot incarca '%s'" % path)
		return false
	root.scale = Vector3.ONE * maxf(scale_factor, 0.001)
	add_child(root)
	bounds = AABB()
	mesh_count = 0
	triangle_count = 0
	_collide_recursive(root)
	return mesh_count > 0


## Raycast vertical prin lume. De apelat doar din context de fizica
## (_physics_process), dupa cel putin un cadru de la build().
func ground_hit(x: float, z: float) -> Dictionary:
	var from := Vector3(x, bounds.end.y + 10.0, z)
	var to := Vector3(x, bounds.position.y - 1.0, z)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	return get_world_3d().direct_space_state.intersect_ray(query)


func _load_glb(path: String) -> Node3D:
	if path.begins_with("res://"):
		if not ResourceLoader.exists(path):
			return null
		var packed := load(path) as PackedScene
		return null if packed == null else packed.instantiate() as Node3D
	# Cale de disc: ocoleste importul, exact cum va sosi un export Marble.
	if not FileAccess.file_exists(path):
		return null
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(path, state) != OK:
		return null
	return doc.generate_scene(state) as Node3D


func _collide_recursive(node: Node) -> void:
	var inst := node as MeshInstance3D
	if inst != null and inst.mesh != null and inst.visible:
		var faces := inst.mesh.get_faces()
		if not faces.is_empty():
			var body := StaticBody3D.new()
			var shape := CollisionShape3D.new()
			var tri := inst.mesh.create_trimesh_shape()
			tri.backface_collision = true
			shape.shape = tri
			body.add_child(shape)
			inst.add_child(body)
			var box := inst.global_transform * inst.mesh.get_aabb()
			bounds = box if mesh_count == 0 else bounds.merge(box)
			mesh_count += 1
			triangle_count += faces.size() / 3
	for child in node.get_children():
		_collide_recursive(child)
