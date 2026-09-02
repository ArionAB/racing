extends Node
## De pe ce fractii se VEDE stratul rosu, si de pe care nu.
##
## Tenta ajunge pe 93% din vertecsii de sub cota 26 (ProbeCappStrat), dar in
## capturile de la 0.06/0.10/0.14 nu se vede rosu deloc — fiindca acolo drumul
## e pe platou la cota ~48, iar masa rosie e cu 20+ m mai jos si in afara
## cadrului. Sonda nu mai intreaba "exista tenta", ci "de unde se vede":
## pentru fiecare fractie, cat teren sub linia stratului cade in fata camerei,
## in conul de vizibilitate.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCappUndeRosu.tscn -- --track=6


func _ready() -> void:
	await get_tree().process_frame
	var idx := 6
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var strata_line := float(track.theme_flag("strata_line", 26.0))
	var pts: PackedVector3Array = track.baked
	var n := pts.size()

	var terr: MeshInstance3D = null
	var best := 0
	var stack: Array[Node] = [track]
	while not stack.is_empty():
		var nd: Node = stack.pop_back()
		for c in nd.get_children():
			stack.append(c)
		if nd is MeshInstance3D:
			var mi := nd as MeshInstance3D
			if mi.mesh != null:
				var vc: int = mi.mesh.get_faces().size()
				if vc > best:
					best = vc
					terr = mi
	var arrs: Array = terr.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrs[Mesh.ARRAY_VERTEX]
	var low: PackedVector3Array = PackedVector3Array()
	for v in verts:
		var w := v + terr.global_position
		if w.y < strata_line:
			low.append(w)

	print("")
	print("=== de unde se vede stratul rosu (linia %.0f m) ===" % strata_line)
	print("  vertecsi sub linie: %d" % low.size())
	print("")
	print("  frac  cota_drum  vertecsi_rosii_in_fata  cel_mai_apropiat")
	for i in range(25):
		var f := float(i) / 25.0
		var i0 := int(f * float(n)) % n
		var car: Vector3 = pts[i0]
		var ahead: Vector3 = pts[(i0 + 12) % n]
		var fwd := (ahead - car); fwd.y = 0.0; fwd = fwd.normalized()
		var cam := car - fwd * 12.5 + Vector3(0, 10, 0)
		var seen := 0
		var nearest := 1e9
		for w in low:
			var to := w - cam
			var d := to.length()
			if d > 300.0:
				continue
			# in fata camerei, in conul de ~34 grade pe orizontala
			var flat := Vector3(to.x, 0, to.z).normalized()
			if flat.dot(fwd) < 0.62:
				continue
			# si SUB orizontala camerei (masa se vede peste buza, in jos)
			if to.y > -2.0:
				continue
			seen += 1
			nearest = minf(nearest, d)
		print("  %.2f  %8.1f  %20d  %15s" % [f, car.y, seen,
			("%.0f m" % nearest) if nearest < 1e8 else "-"])
	get_tree().quit(0)
