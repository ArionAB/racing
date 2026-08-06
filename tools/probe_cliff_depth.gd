extends SceneTree
## Cat de departe in fata originii ajunge fiecare varianta de faleza.
##
## TrackCliffs aseaza sectiunile la `extra + half_depth` de marginea asfaltului,
## unde `half_depth` e `size.z * 0.5` al PRIMULUI mesh din model. Formula asta
## presupune doua lucruri: ca modelul e centrat pe adancime si ca are un singur
## mesh. Sonda le verifica pe amandoua, comparand jumatatea de adancime cu
## distanta REALA de la origine pana la fata dinspre drum (-Z), peste TOATE
## mesh-urile.
##
## Diferenta dintre ele e cat intra faleza peste asfalt fara ca nimeni sa fi
## cerut asta.
##
## Rulare:
##   godot --headless --path . --script res://tools/probe_cliff_depth.gd

const MODEL_PATH: String = "res://assets/models/cliff_wall.glb"


func _initialize() -> void:
	if not ResourceLoader.exists(MODEL_PATH):
		push_error("lipseste %s" % MODEL_PATH)
		quit(1)
		return
	var scene := (load(MODEL_PATH) as PackedScene).instantiate() as Node3D
	print("%-12s %8s %8s %8s %8s" % ["varianta", "meshuri", "half_z",
		"fata", "eroare"])
	var worst := 0.0
	for child in scene.get_children():
		var n3 := child as Node3D
		if n3 == null:
			continue
		var meshes := _meshes(n3)
		if meshes.is_empty():
			continue
		# Ce foloseste codul azi: primul mesh, jumatate din adancime.
		var first: MeshInstance3D = meshes[0]
		var half_z := first.mesh.get_aabb().size.z * 0.5
		# Ce e adevarat: cel mai in fata punct din TOT modelul, fata de origine.
		var full := _aabb(n3)
		var front := -full.position.z
		var err := front - half_z
		worst = maxf(worst, err)
		print("%-12s %8d %8.2f %8.2f %8.2f"
			% [child.name, meshes.size(), half_z, front, err])
	print("\ncea mai mare eroare: %.2f m in fata fata de cat crede codul" % worst)
	scene.queue_free()
	quit(0)


func _meshes(node: Node, out: Array = []) -> Array:
	var mi := node as MeshInstance3D
	if mi != null and mi.mesh != null:
		out.append(mi)
	for c in node.get_children():
		_meshes(c, out)
	return out


func _aabb(root: Node3D) -> AABB:
	var boxes: Array[AABB] = []
	_collect(root, Transform3D.IDENTITY, boxes)
	if boxes.is_empty():
		return AABB()
	var out: AABB = boxes[0]
	for i in range(1, boxes.size()):
		out = out.merge(boxes[i])
	return out


func _collect(node: Node, xf: Transform3D, out: Array[AABB]) -> void:
	var local := xf
	var spatial := node as Node3D
	if spatial != null:
		local = xf * spatial.transform
	var mi := node as MeshInstance3D
	if mi != null and mi.mesh != null:
		out.append(local * mi.mesh.get_aabb())
	for c in node.get_children():
		_collect(c, local, out)
