extends Node
## Ce azimut de soare da umbre care TAIE banda pe TOT turul, nu doar la POI B.
##
## Runda 5. Motivul pentru care exista: alegerea precedenta (-30) a fost facuta
## masurand o singura portiune, a iesit "lat 0.96" si tot nu se vedea umbra in
## captura de la 0.10. Un numar bun pe un esantion nu spune nimic despre tur.
##
## Se citeste directia REALA din nodul de lumina (ca in probe_capp_shadow), nu
## din euler, si se baleiaza azimutul din 5 in 5 grade peste 40 de esantioane
## de traseu. Pentru fiecare: componenta transversala medie, cea mai proasta
## portiune, cate portiuni raman cu umbra in lungul benzii, si separat scorul
## pe padurea de hornuri (frac 0.04-0.18), unde umbrele lungi sunt identitate.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCappAzimut.tscn -- --track=6


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

	var sun: DirectionalLight3D = null
	var stack: Array[Node] = [track]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if n is DirectionalLight3D:
			sun = n as DirectionalLight3D
	if sun == null:
		print("VERDICT: nu exista DirectionalLight3D")
		get_tree().quit(1)
		return

	var pts: PackedVector3Array = track.baked
	var n_pts := pts.size()
	var elev: float = absf(sun.global_rotation_degrees.x)
	print("")
	print("=== baleiaj de azimut, %d puncte baked, elevatie %.1f ===" % [n_pts, elev])

	# Esantioane de traseu: directia de mers, proiectata pe plan.
	var samples: Array = []
	for i in range(40):
		var f := float(i) / 40.0
		var a: Vector3 = pts[int(f * float(n_pts)) % n_pts]
		var b: Vector3 = pts[(int(f * float(n_pts)) + 12) % n_pts]
		var fwd := Vector2(b.x - a.x, b.z - a.z).normalized()
		samples.append({"f": f, "fwd": fwd})

	# Directia reala a umbrei pentru rotatia curenta, ca ancora de control.
	var cur_dir := -sun.global_transform.basis.z
	var cur_shadow := Vector2(cur_dir.x, cur_dir.z).normalized()
	print("  rotatie curenta %s -> umbra spre (%.2f, %.2f)" % [
		str(sun.global_rotation_degrees), cur_shadow.x, cur_shadow.y])
	print("")
	print("  y     lat_med  lat_min  lung(<0.35)  hornuri(0.04-0.18)")

	var rows: Array = []
	for ydeg in range(-180, 180, 5):
		# Aceeasi constructie ca in track.gd: euler (elev, y, 0), umbra pe -Z.
		var basis := Basis.from_euler(Vector3(deg_to_rad(-elev), deg_to_rad(float(ydeg)), 0.0))
		var d := -basis.z
		var sh := Vector2(d.x, d.z).normalized()
		var lat_sum := 0.0
		var lat_min := 1.0
		var along := 0
		var forest_sum := 0.0
		var forest_n := 0
		for s in samples:
			var fwd: Vector2 = s["fwd"]
			# |cross| = cat de mult taie umbra banda (1 = perpendicular).
			var c: float = absf(sh.x * fwd.y - sh.y * fwd.x)
			lat_sum += c
			lat_min = minf(lat_min, c)
			if c < 0.35:
				along += 1
			var f: float = s["f"]
			if f >= 0.04 and f <= 0.18:
				forest_sum += c
				forest_n += 1
		var forest: float = forest_sum / maxf(1.0, float(forest_n))
		rows.append({"y": ydeg, "lat": lat_sum / float(samples.size()),
			"min": lat_min, "along": along, "forest": forest, "sh": sh})

	for r in rows:
		print("  %5d  %6.3f   %6.3f   %5d        %6.3f" % [
			r["y"], r["lat"], r["min"], r["along"], r["forest"]])

	get_tree().quit(0)
