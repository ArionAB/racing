extends SceneTree
## Sonda TEMPORARA de diagnostic pentru SLOT_REPAINT_BY_BOX pe land_rover.
##
## Incarca land_rover.glb BRUT (fara WorldProp), tipareste AABB-ul local al
## fiecarui MeshInstance3D si cate triunghiuri cad in fiecare regula din
## World Prop.SLOT_REPAINT_BY_BOX["land_rover"], plus UV-ul mediu inainte
## si dupa (ca sa vada daca regula chiar prinde ceva).
##
##   godot --headless --path . --script res://tools/probe_rover_paint.gd

const GLB := "res://assets/models/serengeti/props/land_rover.glb"

func _initialize() -> void:
	var scene: PackedScene = load(GLB)
	if scene == null:
		push_error("nu s-a incarcat %s" % GLB)
		quit(1)
		return
	var root := scene.instantiate()
	root_add(root)
	await process_frame
	_walk(root, Transform3D.IDENTITY)
	quit(0)


func root_add(n: Node) -> void:
	root.add_child(n)


func _walk(n: Node, parent_xf: Transform3D) -> void:
	var n3 := n as Node3D
	var xf := parent_xf
	if n3 != null:
		xf = parent_xf * n3.transform
	var mi := n as MeshInstance3D
	if mi != null and mi.mesh != null:
		print("--- MeshInstance3D: %s (local xf origin=%s) ---" % [n.name, xf.origin])
		_report_mesh(mi.mesh)
	for c in n.get_children():
		_walk(c, xf)


## Regulile din world_prop.gd (copiate manual — sonda nu poate instantia
## WorldProp fara sa treaca prin tot Track14).
const RULES := [
	{"min": Vector3(0.84, -0.05, -2.40), "max": Vector3(1.30, 0.84, 1.80), "slot": "A(dreapta)"},
	{"min": Vector3(-1.30, -0.05, -2.40), "max": Vector3(-0.84, 0.84, 1.80), "slot": "B(stanga)"},
	{"min": Vector3(-1.05, 1.45, -2.30), "max": Vector3(1.05, 1.94, 2.30), "slot": "C(parbriz)"},
]

func _report_mesh(mesh: Mesh) -> void:
	var overall_min := Vector3(1e9, 1e9, 1e9)
	var overall_max := Vector3(-1e9, -1e9, -1e9)
	var counts := {}
	for r in RULES:
		counts[r["slot"]] = 0
	var total_tris := 0
	for s in mesh.get_surface_count():
		var arr := mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		if verts.is_empty():
			continue
		for v in verts:
			overall_min = overall_min.min(v)
			overall_max = overall_max.max(v)
		if idx.is_empty():
			continue
		var tri_count := idx.size() / 3
		total_tris += tri_count
		for t in tri_count:
			var a := idx[t * 3]
			var b := idx[t * 3 + 1]
			var c := idx[t * 3 + 2]
			var centroid := (verts[a] + verts[b] + verts[c]) / 3.0
			for r in RULES:
				var lo: Vector3 = r["min"]
				var hi: Vector3 = r["max"]
				if centroid.x >= lo.x and centroid.x <= hi.x 						and centroid.y >= lo.y and centroid.y <= hi.y 						and centroid.z >= lo.z and centroid.z <= hi.z:
					counts[r["slot"]] += 1
					break
	print("  AABB local: min=%s max=%s" % [overall_min, overall_max])
	print("  total triunghiuri: %d" % total_tris)
	for r in RULES:
		print("  regula %s: %d triunghiuri prinse" % [r["slot"], counts[r["slot"]]])
