extends Node
## PODURILE si ESAFODAJUL scenei (Track18, grupa INT-C): ce a pus fiecare
## ModulePlacer (numar, saget cusaturi) si GOLUL real al podului trenului,
## masurat prin proiectia triunghiurilor pe planul (lateral, y), nu din AABB.
##   godot --headless --path . res://tools/ProbeKyotoPoduri.tscn
func _ready() -> void:
	await get_tree().process_frame
	var idx := GameState.resolve_track_index(18)
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	for k in 6:
		await get_tree().process_frame
	await get_tree().physics_frame
	for p in track.find_children("*", "Node3D", true, false):
		var mp := p as ModulePlacer
		if mp == null:
			continue
		print("%-16s module=%d built=%s gap_max=%.3f m suprapunere_max=%.3f m yaw_pas_max=%.2f deg scara_y=%.2f..%.2f"
			% [mp.name, mp.module_count, mp.built, mp.max_seam_gap_m, mp.max_seam_overlap_m, mp.max_yaw_step_deg, mp.min_scale_used, mp.max_scale_used])
	# Golul real al podului trenului: triunghiurile Truss_Stone + Truss_Iron +
	# Truss_Deck in coordonate de LUME, proiectate pe (lateral fata de axa drumului,
	# y). Banda libera = intervalul lateral fara triunghi intre road_y si road_y+H.
	var holder := track.get_node("Poduri/PodulTrenului").get_child(0) as Node3D
	var route := track.route_at(0)
	var ci := route.closest_index_global(holder.global_position)
	var road := route.baked[ci]
	var side := route.side_at(ci)
	print("pod: pozitie %s drum y=%.2f (idx %d, frac %.4f)  yaw=%.1f" % [holder.global_position, road.y, ci, route.frac_at(ci), rad_to_deg(holder.global_rotation.y)])
	for h in [1.0, 3.0, 6.0, 6.25, 7.0]:
		var covered := {}
		for mi in holder.find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			if not m.visible or m.mesh == null:
				continue
			for s in m.mesh.get_surface_count():
				var arr := m.mesh.surface_get_arrays(s)
				var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
				for t in range(0, ix.size(), 3):
					var a := m.global_transform * vs[ix[t]]
					var b := m.global_transform * vs[ix[t + 1]]
					var c := m.global_transform * vs[ix[t + 2]]
					# triunghi la inaltimea h fata de drum? aproximam: orice triunghi
					# a carui fereastra y contine road.y+h si al carui lateral e in [lo,hi]
					var ys := [a.y, b.y, c.y]
					if minf(minf(ys[0], ys[1]), ys[2]) > road.y + h or maxf(maxf(ys[0], ys[1]), ys[2]) < road.y + h:
						continue
					var ls := [(a - road).dot(side), (b - road).dot(side), (c - road).dot(side)]
					var lo := minf(minf(ls[0], ls[1]), ls[2])
					var hi := maxf(maxf(ls[0], ls[1]), ls[2])
					for q in range(int(floor(lo * 10.0)), int(ceil(hi * 10.0)) + 1):
						covered[q] = true
		# cea mai larga banda libera care contine axa
		var l := 0
		while not covered.has(l) and l > -300:
			l -= 1
		var r := 0
		while not covered.has(r) and r < 300:
			r += 1
		print("  la +%.2f m deasupra drumului: gol liber lateral %.2f m  (%.1f .. %.1f)" % [h, (r - l - 1) / 10.0, l / 10.0, r / 10.0])
	get_tree().quit()
