extends Node
## SECTIUNI TRANSVERSALE prin banda de maree (Ha Long, Track22, ruta 1).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeHlBanda.tscn \
##       -- [--step=8] [--route=1]
##
## Pentru fiecare punct copt al benzii, la `step` metri: cota benzii si ce
## loveste un raycast vertical la laterale de -12..+12 m. Raspunde la „banda e
## ingropata sub teren?” si „pe ce stau gardurile?” fara sa ghicesti din poza.

func _ready() -> void:
	var step := 8.0
	var ri := 1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--step="):
			step = float(a.substr(7))
		elif a.begins_with("--route="):
			ri = int(a.substr(8))
	var track := (load("res://scenes/tracks/Track22.tscn") as PackedScene).instantiate()
	add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().physics_frame
	var routes: Array = track.get("routes")
	var r = routes[ri]
	print("=== ProbeHlBanda: ruta %d '%s', %d puncte, %.1f m, hw %.1f, suprafata %s ==="
		% [ri, r.label, r.count(), r.dists[r.count() - 1], r.half_width, r.surface])
	var space := get_viewport().world_3d.direct_space_state
	var lats: Array[float] = [-12.0, -8.0, -6.0, -5.0, -4.0, -2.0, 0.0, 2.0, 4.0, 5.0, 6.0, 8.0, 12.0]
	var d_max := 1e9
	var pts := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--to="):
			d_max = float(a.substr(5))
		elif a.begins_with("--pts="):
			pts = a.substr(6)
	# `--pts=x,z;x,z`: cota si ce se loveste in puncte date (decorul de la gura).
	for pair in pts.split(";", false):
		var xz := pair.split(",")
		var p := Vector3(float(xz[0]), 40.0, float(xz[1]))
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(p, p + Vector3.DOWN * 80.0))
		var mi: int = routes[0].closest_index_global(Vector3(p.x, 0.0, p.z))
		var road_lat: float = routes[0].lateral_distance(mi, Vector3(p.x, 0.0, p.z)) 			- float(track.call("width_at_index", mi))
		var lane_i: int = r.closest_index_global(Vector3(p.x, 0.0, p.z))
		var lane_lat: float = r.lateral_distance(lane_i, Vector3(p.x, 0.0, p.z))
		print("  pct (%.1f, %.1f): y=%s  %s | la %.1f m de marginea soselei, %.1f m de axa benzii (d %.1f)" % [
			p.x, p.z, "gol" if hit.is_empty() else "%.2f" % hit["position"].y,
			"" if hit.is_empty() else String((hit["collider"] as Node).name), road_lat, lane_lat, r.dists[lane_i]])
	var head := "   d      x       z    banda |"
	for l: float in lats:
		head += " %6.1f" % l
	print(head)
	var next := 0.0
	for i in r.count():
		if r.dists[i] < next and i != r.count() - 1:
			continue
		if r.dists[i] > d_max:
			break
		next = r.dists[i] + step
		var b: Vector3 = track.to_global(r.baked[i])
		var side: Vector3 = r.side_at(i)
		var line := "%5.1f %7.1f %7.1f %6.2f s(%+.2f,%+.2f) |" % [r.dists[i], b.x, b.z, b.y, side.x, side.z]
		for l: float in lats:
			var p := b + side * l + Vector3.UP * 40.0
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(p, p + Vector3.DOWN * 80.0))
			if hit.is_empty():
				line += "   gol "
			else:
				var y: float = hit["position"].y
				var col := hit.get("collider") as Node
				var tag := " "
				if col != null and String(col.name).begins_with("Road"):
					tag = "r"
				elif col != null and col is StaticBody3D and String(col.name).contains("Terrain"):
					tag = "t"
				elif col != null:
					tag = String(col.name).substr(0, 1).to_lower()
				line += " %5.2f%s" % [y, tag]
		print(line)
	# Linia gardului (TrackBranch.edge_fence) la capete: unde incepe fiecare
	# latura si daca acolo stalpul e liber de sosea. (Instantele MultiMesh nu se
	# pot citi headless — serverul de randare fals nu pastreaza bufferul — deci
	# punctele se recalculeaza cu aceeasi functie pe care o foloseste Track.)
	if not r.fence.is_empty():
		var total: float = r.dists[r.count() - 1]
		var lat: float = r.half_width - float(r.fence.get("inset", 0.4))
		var trim: float = float(r.fence.get("trim", 8.0))
		print("--- gardul: linia la +/-%.2f m, trim %.1f m, banda %.1f m ---" % [lat, trim, total])
		for d: float in [trim, trim + 2.4, trim + 4.8, trim + 7.2, total - trim - 4.8, total - trim - 2.4, total - trim]:
			for sg: float in [-1.0, 1.0]:
				var p: Vector3 = track.call("_fence_point", r, d, lat * sg)
				print("  d %6.1f  latura %+.0f  (%.1f, %.2f, %.1f)  %s" % [d, sg, p.x, p.y, p.z,
					"liber" if bool(track.call("_branch_rail_clear", p)) else "PE SOSEA (sarit)"])
	get_tree().quit(0)
