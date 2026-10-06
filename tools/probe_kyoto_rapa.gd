extends Node
## PROFILUL rapei de sub scena Kiyomizu (Track18): cota terenului fata de punte,
## din 5 in 5 m pe ax si pe laterale. Masoara MESH-ul de teren cu raze (ce vede
## si loveste masina), nu campul `ground_y`.
##   godot --headless --path . res://tools/ProbeKyotoRapa.tscn
func _ready() -> void:
	await get_tree().process_frame
	var idx := GameState.resolve_track_index(18)
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().physics_frame
	var space := track.get_world_3d().direct_space_state
	var lats := [0.0, 8.0, 12.0, 15.0, 20.0, 30.0, 40.0]
	var n := track.baked.size()
	print("cota teren (m) SUB punte; coloane = lateral de ax (m), stanga/dreapta simetric (min dintre ele)")
	print("  frac    s(m)  punte   " + "  ".join(lats.map(func(l): return "%5.0f" % l)))
	var last_s := -100.0
	var worst := 1e9
	for i in n:
		var f := track.frac_at(i)
		if f < 0.268 or f > 0.322:
			continue
		var s: float = track._dists[i]
		if s - last_s < 5.0:
			continue
		last_s = s
		var p := track.baked[i]
		var side := track.routes[0].side_at(i)
		var row := ""
		for l in lats:
			var vals: Array[float] = []
			for sg in [-1.0, 1.0]:
				var q: Vector3 = p + side * l * sg
				var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(
					q + Vector3.UP * 60.0, q + Vector3.DOWN * 80.0, 1 << 0))
				var y: float = hit.position.y if not hit.is_empty() else -99.0
				# axa: terenul de sub drum nu e interogat (drumul e corp); folosim
				# terrain_mesh_y pe ax
				if l == 0.0:
					y = track._terrain_mesh_y(q.x, q.z)
				vals.append(y)
			var y2: float = minf(vals[0], vals[1])
			var d := p.y - y2
			if l >= 15.0 and f > 0.275 and f < 0.303:
				worst = minf(worst, d)
			row += " %5.1f" % d
		print("  %.4f %6.0f %6.1f  %s" % [f, s, p.y, row])
	print("adancime minima sub punte la >=15 m lateral, pe lungimea scenei: %.1f m" % worst)
	get_tree().quit()
