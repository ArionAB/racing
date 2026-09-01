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
	# Cat de LAT e modulul de fapt pe fiecare felie de inaltime: hull-ul de
	# coliziune cuprinde si streasina de sus, deci la 0.8 m (inaltimea la care
	# masoara ProbeCappClear) latimea poate fi alta decat cea a bbox-ului.
	var ps2 := load(PATHS[0]) as PackedScene
	var inst2 := ps2.instantiate()
	get_tree().root.add_child(inst2)
	await get_tree().process_frame
	for mi2 in inst2.find_children("*", "MeshInstance3D", true, false):
		var mesh2 := (mi2 as MeshInstance3D).mesh
		if mesh2 == null:
			continue
		for si in mesh2.get_surface_count():
			var arr2 := mesh2.surface_get_arrays(si)
			var vv: PackedVector3Array = arr2[Mesh.ARRAY_VERTEX]
			for band in [0.0, 0.8, 2.0, 6.0, 12.0]:
				var mn := 1e9
				var mx := -1e9
				for v in vv:
					if absf(v.y - band) < 1.2:
						mn = minf(mn, v.z)
						mx = maxf(mx, v.z)
				if mx > mn:
					print("  la y=%.1f m: z de la %.2f la %.2f (latime %.2f)" % [
						band, mn, mx, mx - mn])
	get_tree().quit(0)
