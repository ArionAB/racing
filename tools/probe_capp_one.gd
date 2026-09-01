extends Node
## Cat de aproape de ax ajunge un modul anume, masurat pe VERTECSII lui reali
## transformati in lume — nu pe un dreptunghi presupus.

func _ready() -> void:
	await get_tree().process_frame
	var scene := load(GameState.TRACK_SCENES[6]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	for i in 8:
		await get_tree().process_frame
	# cele doua fete ale lui Strat0_07, in spatiul benzii
	var nd := track.find_child("Strat0_07", true, false) as Node3D
	if nd != null:
		var xf := nd.global_transform
		for zl in [-3.82, 0.0, 2.25]:
			var w: Vector3 = xf * Vector3(0.0, 1.0, zl)
			print("  fata z=%+.2f -> lateral %.2f m de ax" % [zl,
				absf(track.lateral_distance(track.closest_index_global(w), w))])
	for nm in ["Strat0_07", "Strat0_04"]:
		var node := track.find_child(nm, true, false) as Node3D
		if node == null:
			print(nm, ": nu e in scena")
			continue
		var best := 1e9
		var best_y := 0.0
		var best_local := Vector3.ZERO
		var best_w := Vector3.ZERO
		for mi in node.find_children("*", "MeshInstance3D", true, false):
			var mesh := (mi as MeshInstance3D).mesh
			if mesh == null:
				continue
			var xf := (mi as MeshInstance3D).global_transform
			for si in mesh.get_surface_count():
				var arr := mesh.surface_get_arrays(si)
				var vv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				for v in vv:
					var w: Vector3 = xf * v
					var d: float = absf(track.lateral_distance(
						track.closest_index_global(w), w))
					if d < best:
						best = d
						best_y = w.y
						best_local = v
						best_w = w
		print("%s: cel mai apropiat vertex la %.2f m de ax, la cota y=%.2f, local(%.2f,%.2f,%.2f) lume(%.1f,%.1f,%.1f)" % [
			nm, best, best_y, best_local.x, best_local.y, best_local.z,
			best_w.x, best_w.y, best_w.z])
	# La ce fractie ajunge coltul lui Strat0_07, si la ce fractie a fost pus
	# modulul: daca difera mult, drumul se INTOARCE pe langa el (S), si garda
	# masurata la fractia de asezare nu are cum sa vada apropierea.
	var route := track.route_at(0)
	var np := route.baked.size()
	for pt in [Vector3(123.402, 23.045, -167.465), Vector3(123.8, 29.7, -178.8)]:
		var ci := track.closest_index_global(pt)
		print("  (%.1f, %.1f) -> index %d = frac %.3f, lateral %.2f" % [
			pt.x, pt.z, ci, float(ci) / float(np),
			absf(track.lateral_distance(ci, pt))])
	get_tree().quit(0)
