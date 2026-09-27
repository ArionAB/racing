extends SceneTree
## Sonda de REGRESIE: hash pe o grila de `_sampler.ground_y(wx, wz)` pentru o
## pista, ca sa dovedeasca "identic la bit" inainte/dupa o schimbare de cod
## global (aici: mecanismul de falie liniara din CliffFace, opt-in pe
## Fiordland). Nu inlocuieste ProbeBuried/ProbeLayout — masoara O SINGURA
## intrebare: campul de inaltime al altor piste s-a miscat cu o unitate?
##
##   godot --headless --path . --script res://tools/probe_ground_hash.gd -- --track=9
##
## Grila: 200x200 puncte in AABB-ul traseului (+ marja), pas fix — determinista
## intre rulari cat timp codul nu s-a schimbat. Tipareste hash + cateva
## esantioane brute, ca o diferenta sa poata fi localizata fara re-rulare.

const GRID_N: int = 200

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var track_arg := -1
	for a in args:
		if a.begins_with("--track="):
			track_arg = int(a.substr(8))
	if track_arg < 0:
		print("Foloseste --track=N (numar de SCENA, ca probe_decor)")
		quit(1)
		return
	var path := "res://scenes/tracks/Track%02d.tscn" % track_arg
	if not ResourceLoader.exists(path):
		print("Nu exista %s" % path)
		quit(1)
		return
	var scene := load(path) as PackedScene
	var track := scene.instantiate() as Track
	root.add_child(track)
	await process_frame
	await process_frame

	var sampler = track.get("_sampler")
	if sampler == null:
		print("Track%02d: NU are _sampler dupa rebuild" % track_arg)
		quit(1)
		return

	# AABB aproximativ din punctele baked, plus marja ca sa prinda si versanti.
	var min_x := INF
	var max_x := -INF
	var min_z := INF
	var max_z := -INF
	var n: int = sampler.point_count()
	for i in n:
		var p: Vector3 = sampler.baked_point(i)
		min_x = minf(min_x, p.x)
		max_x = maxf(max_x, p.x)
		min_z = minf(min_z, p.z)
		max_z = maxf(max_z, p.z)
	var margin := 60.0
	min_x -= margin
	max_x += margin
	min_z -= margin
	max_z += margin

	var h: int = 5381
	var samples: PackedFloat32Array = PackedFloat32Array()
	for ix in GRID_N:
		var wx: float = min_x + (max_x - min_x) * float(ix) / float(GRID_N - 1)
		for iz in GRID_N:
			var wz: float = min_z + (max_z - min_z) * float(iz) / float(GRID_N - 1)
			var y: float = sampler.ground_y(wx, wz)
			# Rotunjire la 1mm, ca zgomotul de float pe ultimul bit sa nu strice
			# un hash care altfel ar trebui sa fie identic.
			var yi: int = int(round(y * 1000.0))
			h = ((h << 5) + h) ^ yi
			h = h & 0x7FFFFFFF
			if (ix * GRID_N + iz) % 9973 == 0:
				samples.append(y)

	print("Track%02d: grid=%dx%d aabb=(%.1f,%.1f)-(%.1f,%.1f)" % [
		track_arg, GRID_N, GRID_N, min_x, min_z, max_x, max_z])
	print("HASH=%d" % h)
	print("SAMPLES=%s" % str(samples))
	quit(0)
