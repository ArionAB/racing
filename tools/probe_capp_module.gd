extends Node
## Dimensiunile REALE ale modulelor de kit folosite in canion (POI D).
## Scara se deduce din metri masurati, nu dintr-un factor ghicit.

const PATHS := [
	"res://assets/models/cappadocia/rocks/cliff_band_module.glb",
	"res://assets/models/rocks/rock_large.glb",
	"res://assets/models/rocks/rock_medium.glb",
	"res://assets/models/rocks/rock_small.glb",
	"res://assets/models/rocks/rock_cluster.glb",
	"res://assets/models/cappadocia/plants/poplar_a.glb",
	"res://assets/models/cappadocia/plants/shrub_dry.glb",
]

func _aabb(n: Node, acc: AABB, first: Array) -> AABB:
	var out := acc
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		var m := mi.mesh
		if m != null:
			var b := mi.global_transform * m.get_aabb()
			if first[0]:
				out = b
				first[0] = false
			else:
				out = out.merge(b)
	for c in n.get_children():
		out = _aabb(c, out, first)
	return out

func _ready() -> void:
	for p in PATHS:
		var ps := load(p) as PackedScene
		if ps == null:
			print(p, " -> LIPSA")
			continue
		var inst := ps.instantiate()
		get_tree().root.add_child(inst)
		await get_tree().process_frame
		var first := [true]
		var b := _aabb(inst, AABB(), first)
		var tris := 0
		for mi in inst.find_children("*", "MeshInstance3D", true, false):
			var mm := (mi as MeshInstance3D).mesh
			if mm != null:
				for s in mm.get_surface_count():
					var arr := mm.surface_get_arrays(s)
					var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
					if idx.size() > 0:
						tris += idx.size() / 3
					else:
						var vt: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
						tris += vt.size() / 3
		print("%s\n   size(%.2f x %.2f x %.2f) origin_off(%.2f,%.2f,%.2f) tris %d" % [
			p.get_file(), b.size.x, b.size.y, b.size.z,
			b.position.x, b.position.y, b.position.z, tris])
		inst.queue_free()
	get_tree().quit(0)
