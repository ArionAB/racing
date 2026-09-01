extends Node
## Ce geometrie de POI D intra in carosabil.
##
## ProbeRace a prins masini blocate la frac 0.459 pe Bloc_130/164/171 si pe un
## `state_col` — adica pe grohotisul si pe TREPTELE adaugate in runda 3.
## Treptele n-aveau garda de carosabil deloc: ele se ancoreaza pe fata
## peretelui, si s-a presupus ca fata peretelui e departe de drum. Nu e peste
## tot — peretele are pinteni, si o treapta care iese 2.6 m dintr-un pinten
## ajunge pe banda.
##
## Se masoara lateralul MINIM pe o fereastra de indici (traseul e un S aici),
## pe colturile reale ale fiecarei cutii.

func _ready() -> void:
	await get_tree().process_frame
	var scene := load(GameState.TRACK_SCENES[6]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var base := track.get_node_or_null("DecorManual/D) Canionul rosu")
	var route := track.route_at(0)
	var n := route.baked.size()
	for grp_name in ["Strate", "Grohotis"]:
		var grp := base.get_node_or_null(grp_name)
		if grp == null:
			continue
		var bad := 0
		for c in grp.get_children():
			var n3 := c as Node3D
			if n3 == null:
				continue
			var worst := 1e9
			var meshes: Array = []
			if n3 is MeshInstance3D:
				meshes.append(n3)
			for mi in n3.find_children("*", "MeshInstance3D", true, false):
				meshes.append(mi)
			for mi in meshes:
				var mm := (mi as MeshInstance3D).mesh
				if mm == null:
					continue
				var xf := (mi as MeshInstance3D).global_transform
				var ab := mm.get_aabb()
				for i in 8:
					var wp: Vector3 = xf * ab.get_endpoint(i)
					var ci: int = track.closest_index_global(wp)
					for w in range(-40, 41, 4):
						var iw: int = ((ci + w) % n + n) % n
						worst = minf(worst,
							absf(track.lateral_distance(iw, wp)))
			var f: float = track.frac_at_position(n3.global_transform.origin) \
				if track.has_method("frac_at_position") else -1.0
			var hw: float = 6.0
			if worst < hw + 3.0:
				bad += 1
				print("%s/%s  lateral MIN %.2f m  poz=(%.0f,%.0f,%.0f)"
					% [grp_name, n3.name, worst,
					n3.global_transform.origin.x,
					n3.global_transform.origin.y,
					n3.global_transform.origin.z])
		print("--- %s: %d piese in carosabil (prag %.1f m) ---"
			% [grp_name, bad, 9.0])
	get_tree().quit(0)
