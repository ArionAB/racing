extends Node
func _ready() -> void:
	await get_tree().process_frame
	var ps := load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)]) as PackedScene
	var track := ps.instantiate() as Track
	add_child(track)
	for _i in 10:
		await get_tree().process_frame
	var r := track.routes[0]
	var n := r.count()
	# unde sta fiecare hazard pe pista
	for nm in ["PasajRotativ","Macara","CuloarCeata","Monorail","Telecabina3D"]:
		var h = track.find_child(nm, false, false)
		if h == null:
			print("LIPSA ", nm); continue
		var idx := track.closest_index_global(h.global_position)
		var f := float(idx)/float(n)
		var d: float = r.baked[idx].distance_to(h.global_position)
		print("%s: frac %.3f  dist_de_axa %.2f m  hw %.2f  pos %s" % [nm, f, d, track.width_at_index(idx), str(h.global_position)])
	# ce corpuri solide stau pe axa in zona 0.60-0.70
	var space := get_viewport().world_3d.direct_space_state
	print("--- gabarit pe axa, frac 0.60-0.70 (latime libera in jurul axei) ---")
	var i := int(0.60*n)
	while i < int(0.71*n):
		var p: Vector3 = r.baked[i]
		var fwd: Vector3 = (r.baked[(i+3)%n]-p).normalized()
		var right := fwd.cross(Vector3.UP).normalized()
		var hw: float = track.width_at_index(i)
		# matura lateral: cauta primul obstacol la 0.5 m peste asfalt
		var free_l := hw
		var free_r := hw
		for s in [1.0, -1.0]:
			var t := 0.0
			while t < hw:
				var q := p + right*t*s + Vector3.UP*0.55
				var sh := PhysicsShapeQueryParameters3D.new()
				var bx := BoxShape3D.new()
				bx.size = Vector3(1.7, 1.0, 3.9)
				sh.shape = bx
				sh.transform = Transform3D(Basis.looking_at(fwd, Vector3.UP), q)
				sh.collide_with_areas = false
				var hits := space.intersect_shape(sh, 4)
				var bad := false
				for hh in hits:
					var col = hh.get("collider")
					if col == null: continue
					var nmm := str(col.name)
					if nmm.begins_with("Car"): continue
					bad = true
				if bad:
					if s > 0.0: free_r = t
					else: free_l = t
					break
				t += 0.5
		var fr := float(i)/float(n)
		if free_l < hw - 0.4 or free_r < hw - 0.4:
			print("  frac %.3f  liber stanga %.1f  dreapta %.1f  (hw %.1f)" % [fr, free_l, free_r, hw])
		i += max(1, int(0.002*n))
	get_tree().quit()
