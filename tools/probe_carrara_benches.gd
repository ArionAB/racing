extends Node
## Garda de TREPTE a pistei Carrara (Track23, indexul 15): masoara pe geometria REALA (raze fizice
## contra terenului si fetelor, nu pe campul `ground_y`) doua lucruri.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCarraraBenches.tscn -- --mode=prof
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCarraraBenches.tscn -- --mode=reveal
##
## `--mode=prof` — profile perpendiculare pe drum (linii N-S, fiindca terasele sunt E-V), de la un
## drum la vecinul lui. Pentru fiecare profil: BANCUL (cat de plat, <= 10 grade, e terenul chiar
## inaintea fetei) si FATA (cea mai inalta alunecare continua de panta >= 45 grade): inaltime,
## rulaj, panta medie. Contractul pasului 4: fata urca >= 5 m cu panta medie >= 70 grade, iar
## bancul are >= 4 m plat inaintea ei, la >= 5 fractii pe fiecare pereche de terase.
##
## `--mode=reveal` — din camera REALA de joc (10 m sus, 12,5 m in spate, 28,7 grade in jos, FOV 68,
## 16:9; aceleasi formule ca `tools/snapshot.gd --gamecam`), la puncte de-a lungul lui E: ce parte
## din cadru loveste teren/drum la <= +8 m (fundul carierei) si daca fundul se vede deloc.

const HW := 4.5
const STEP := 0.25

## (nume, x harta, y de pornire, y de sosire). y harta; gz = -y. Directia = de la `y_from` la `y_to`.
const PROFILES := [
	["T1>T2", [-85.0, -70.0, -55.0, -40.0, -25.0, -10.0], 105.0, 67.0],
	["T2>T1", [-85.0, -70.0, -55.0, -40.0, -25.0, -10.0], 67.0, 105.0],
	["T2>T3", [-55.0, -45.0, -35.0, -25.0, -15.0, -5.0], 67.0, 29.0],
	["T3>T2", [-55.0, -45.0, -35.0, -25.0, -15.0, -5.0], 29.0, 67.0],
	["T3>pit", [-30.0, -20.0, -10.0, 0.0, 10.0, 20.0], 29.0, -35.0],
	["E>pit", [80.0, 55.0, 30.0, 5.0, -20.0, -45.0, -70.0, -95.0], -112.0, -20.0, true],
]

var _space: PhysicsDirectSpaceState3D


func _arg(name: String, fallback: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--%s=" % name):
			return a.trim_prefix("--%s=" % name)
	return fallback


func _ready() -> void:
	await get_tree().process_frame
	var scene_path := _arg("scene", "res://scenes/tracks/Track23.tscn")
	var track := (load(scene_path) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	for _i in 14:
		await get_tree().process_frame
		await get_tree().physics_frame
	_space = get_viewport().world_3d.direct_space_state
	var mode := _arg("mode", "prof")
	if mode == "prof":
		_profiles()
	elif mode == "reveal":
		_reveal(track)
	elif mode == "edge":
		_edge(track)
	elif mode == "info":
		_info(track)
	elif mode == "view":
		_view(track)
	elif mode == "ray":
		for pair in _arg("pts", "").split(";"):
			var xy := pair.split(",")
			print("  raza la (%s, %s): y fizic %.2f" % [xy[0], xy[1], _ground_at(float(xy[0]), -float(xy[1]))])
	get_tree().quit()


func _ground_at(x: float, z: float) -> float:
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, 140.0, z), Vector3(x, -60.0, z))
	q.collide_with_areas = false
	var h := _space.intersect_ray(q)
	if h.is_empty():
		return NAN
	return (h["position"] as Vector3).y


func _profiles() -> void:
	var tot_ok := 0
	var tot := 0
	for spec in PROFILES:
		var name: String = spec[0]
		var xs: Array = spec[1]
		var y_from: float = spec[2]
		var y_to: float = spec[3]
		var all_faces: bool = spec.size() > 4 and bool(spec[4])
		var sgn := signf(y_to - y_from)
		var n := int(absf(y_to - y_from) / STEP) + 1
		print("=== %s ===" % name)
		for x in xs:
			var hs := PackedFloat32Array()
			hs.resize(n)
			for i in n:
				var y := y_from + sgn * float(i) * STEP
				hs[i] = _ground_at(float(x), -y)
			var faces := _faces(hs)
			var line := "  x=%7.1f " % float(x)
			if faces.is_empty():
				line += " nicio fata"
				tot += 1
			var shown := 0
			for f: Dictionary in faces:
				shown += 1
				var ok: bool = f["rise"] >= 5.0 and f["mean_deg"] >= 70.0 and f["flat_before"] >= 4.0
				if all_faces or shown == 1:
					tot += 1
					if ok:
						tot_ok += 1
				line += " | fata %d @%5.1f m de axa: banc plat %5.1f m, cota %6.2f -> %6.2f, rise %5.2f m, run %4.2f m, panta medie %5.1f gr (max %5.1f) %s" % [
					shown, f["at"], f["flat_before"], f["top"], f["bot"], f["rise"], f["run"],
					f["mean_deg"], f["max_deg"], "OK" if ok else "--"]
				if not all_faces:
					break
			print(line)
	print("PROFILE: %d / %d trec (rise>=5, panta medie>=70, bench plat>=4 m)" % [tot_ok, tot])


## Fetele dintr-un profil: grupuri continue de pasi (0.25 m) cu panta >= 45 grade, imbinate cand le
## desparte <= 0.5 m. Pentru fiecare: inaltimea, rulajul, panta medie si cat de PLAT (<= 10 grade, pe
## ferestre de 0.5 m) e terenul chiar inaintea ei, mergand inapoi.
func _faces(hs: PackedFloat32Array) -> Array:
	var n := hs.size()
	var out: Array = []
	var edge_i := int((HW + 1.5) / STEP)   # dupa marginea asfaltului si berma
	var steep := PackedByteArray()
	steep.resize(n)
	for i in n - 1:
		var a := hs[i]
		var b := hs[i + 1]
		if not is_nan(a) and not is_nan(b) and rad_to_deg(atan2(absf(b - a), STEP)) >= 45.0:
			steep[i] = 1
	var i := edge_i
	while i < n - 1:
		if steep[i] == 1:
			var j := i
			var last := i
			while j < n - 1 and j - last <= 2:
				if steep[j] == 1:
					last = j
				j += 1
			var i1 := last + 1
			var rise := absf(hs[i1] - hs[i])
			if rise >= 1.0:
				var run := float(i1 - i) * STEP
				var mx := 0.0
				for k in range(i, i1):
					mx = maxf(mx, rad_to_deg(atan2(absf(hs[k + 1] - hs[k]), STEP)))
				# primii 0.75 m dinaintea fetei pot fi inceputul rampei fine (esantionul nimereste
				# la jumatatea unui triunghi): se sar si NU se numara ca plat.
				var flat := 0.0
				var k2 := i - 3
				while k2 > 2:
					var d := absf(hs[k2 + 1] - hs[k2 - 1])
					if rad_to_deg(atan2(d, 2.0 * STEP)) > 10.0:
						break
					flat += STEP
					k2 -= 1
				out.append({"at": float(i) * STEP, "rise": rise, "run": run,
					"mean_deg": rad_to_deg(atan2(rise, maxf(run, 0.001))), "max_deg": mx,
					"top": maxf(hs[i], hs[i1]), "bot": minf(hs[i], hs[i1]), "flat_before": flat})
			i = i1 + 1
		else:
			i += 1
	return out


func _reveal(track: Track) -> void:
	var route := track.routes[0]
	var pts: PackedVector3Array = route.baked
	var n := pts.size()
	var fovy := 68.0
	var aspect := 16.0 / 9.0
	var th := tan(deg_to_rad(fovy) * 0.5)
	var W := 128
	var H := 72
	var f0 := float(_arg("f0", "0.592"))
	var f1 := float(_arg("f1", "0.696"))
	var count := int(_arg("n", "14"))
	var seen_ok := 0
	var shares := []
	print("=== reveal de pe E: camera de joc, %dx%d raze ===" % [W, H])
	for s in count:
		var f := f0 + (f1 - f0) * float(s) / float(maxi(count - 1, 1))
		var idx := int(f * float(n)) % n
		var focus: Vector3 = pts[idx]
		var ahead: Vector3 = pts[route.wrap_index(idx + 12)]
		var dir := (ahead - focus).normalized()
		var cam_pos := focus - dir * ChaseCamera.DEFAULT_DISTANCE + Vector3.UP * ChaseCamera.DEFAULT_HEIGHT
		var tgt := focus + dir * ChaseCamera.LOOK_AHEAD + Vector3.UP * ChaseCamera.LOOK_HEIGHT
		var basis := Basis.looking_at(tgt - cam_pos, Vector3.UP)
		var low := 0
		var low_near := 0
		var sky := 0
		var min_y := 1e9
		for j in H:
			for i in W:
				var u := (2.0 * (float(i) + 0.5) / float(W) - 1.0) * th * aspect
				var v := (1.0 - 2.0 * (float(j) + 0.5) / float(H)) * th
				var d := (basis * Vector3(u, v, -1.0)).normalized()
				var q := PhysicsRayQueryParameters3D.create(cam_pos, cam_pos + d * 400.0)
				q.collide_with_areas = false
				var h := _space.intersect_ray(q)
				if h.is_empty():
					sky += 1
					continue
				var p: Vector3 = h["position"]
				min_y = minf(min_y, p.y)
				if p.y <= 8.0:
					low += 1
					if cam_pos.distance_to(p) <= 200.0:
						low_near += 1
		var share := 100.0 * float(low) / float(W * H)
		shares.append(share)
		var visible := share >= 1.0
		if visible:
			seen_ok += 1
		print("  frac %.3f  (x %.0f, y %.1f, cota %.1f)  fundul (<= +8 m) in cadru: %5.1f %%  (la <= 200 m: %5.1f %%)  cer %4.1f %%  cota min lovita %.1f  %s" % [
			f, focus.x, -focus.z, focus.y, share, 100.0 * float(low_near) / float(W * H),
			100.0 * float(sky) / float(W * H), min_y, "VAZUT" if visible else "ascuns"])
	var sum := 0.0
	for s in shares:
		sum += float(s)
	print("REVEAL: fundul vazut (>= 1 %% din cadru) la %d / %d puncte (%.0f %%); cadru mediu %.1f %%" % [
		seen_ok, count, 100.0 * float(seen_ok) / float(count), sum / float(count)])


## `--mode=view` — ce vede camera REALA de joc din TEREN, pe clase de panta (normala lovita, doar
## `TerrainBody`): plat (< 12 grade), PANTA (12-65 grade: dunele netede pe care criticul le citeste
## „relief neted") si FATA (>= 65 grade: gradonul taiat). `--fracs=0.07,0.16` (implicit capturile lui B).
## Procentele sunt din tot cadrul (cerul si decorul raman in rest).
func _view(track: Track) -> void:
	var route := track.routes[0]
	var pts: PackedVector3Array = route.baked
	var n := pts.size()
	var th := tan(deg_to_rad(ChaseCamera.BASE_FOV) * 0.5)
	var aspect := 16.0 / 9.0
	var W := 160
	var H := 90
	for fs in _arg("fracs", "0.07,0.105,0.16,0.25").split(","):
		var f := float(fs)
		var idx := int(f * float(n)) % n
		var focus: Vector3 = pts[idx]
		var ahead: Vector3 = pts[route.wrap_index(idx + 12)]
		var dir := (ahead - focus).normalized()
		var cam_pos := focus - dir * ChaseCamera.DEFAULT_DISTANCE + Vector3.UP * ChaseCamera.DEFAULT_HEIGHT
		var tgt := focus + dir * ChaseCamera.LOOK_AHEAD + Vector3.UP * ChaseCamera.LOOK_HEIGHT
		var basis := Basis.looking_at(tgt - cam_pos, Vector3.UP)
		var cnt := {"plat": 0, "panta": 0, "fata": 0, "alt": 0, "cer": 0}
		# panta pe jumatatea de SUS a cadrului (fundalul, unde stau dunele din capturi)
		var slope_top := 0
		var img := Image.create(W, H, false, Image.FORMAT_RGB8)
		for j in H:
			for i in W:
				var u := (2.0 * (float(i) + 0.5) / float(W) - 1.0) * th * aspect
				var v := (1.0 - 2.0 * (float(j) + 0.5) / float(H)) * th
				var d := (basis * Vector3(u, v, -1.0)).normalized()
				var q := PhysicsRayQueryParameters3D.create(cam_pos, cam_pos + d * 400.0)
				q.collide_with_areas = false
				var h := _space.intersect_ray(q)
				if h.is_empty():
					cnt["cer"] += 1
					img.set_pixel(i, j, Color(0.6, 0.8, 1.0))
					continue
				var col: Object = h["collider"]
				if not (col is Node and (col as Node).name == "TerrainBody"):
					cnt["alt"] += 1
					img.set_pixel(i, j, Color(0.3, 0.3, 0.3))
					continue
				var deg := rad_to_deg(acos(clampf((h["normal"] as Vector3).y, -1.0, 1.0)))
				if deg < 12.0:
					cnt["plat"] += 1
					img.set_pixel(i, j, Color(0.9, 0.85, 0.7))
				elif deg < 65.0:
					cnt["panta"] += 1
					img.set_pixel(i, j, Color(0.9, 0.2, 0.1))
					if j < H / 2:
						slope_top += 1
				else:
					cnt["fata"] += 1
					img.set_pixel(i, j, Color(0.1, 0.4, 0.9))
		var tot := float(W * H)
		var out_dir := _arg("img", "")
		if out_dir != "":
			img.resize(W * 4, H * 4, Image.INTERPOLATE_NEAREST)
			img.save_png("%s/view_%s.png" % [out_dir, fs])
		print("VIEW frac %.3f (x %.0f, y %.0f, cota %.1f): plat %5.1f %%  PANTA %5.1f %% (sus %4.1f %%)  FATA %5.1f %%  decor/drum %5.1f %%  cer %4.1f %%" % [
			f, focus.x, -focus.z, focus.y, 100.0 * cnt["plat"] / tot, 100.0 * cnt["panta"] / tot,
			100.0 * slope_top / tot, 100.0 * cnt["fata"] / tot, 100.0 * cnt["alt"] / tot, 100.0 * cnt["cer"] / tot])


## `--mode=edge`: treapta (m) dintre carosabil si teren LA MARGINEA soselei, pe ambele laturi. Terenul sta la
## cota soselei - 0.3 (GROUND_DROP), deci un prag peste ~0.3 m e un zid pentru roata (memoria
## `suprafete-cu-goluri-si-praguri`). Raporteaza intervalele de tur unde |treapta| iese din [0, 0.45].
func _edge(track: Track) -> void:
	var route := track.routes[0]
	var pts: PackedVector3Array = route.baked
	var n := pts.size()
	# pe fiecare latura, la 0.4 m de margine: intervale continue de fractii cu treapta in afara de [-0.9, +0.15]
	for sgn in [-1.0, 1.0]:
		var run_start := -1.0
		var run_min := 0.0
		var run_max := 0.0
		var last_f := -1.0
		var out: PackedStringArray = []
		for i in range(0, n, 2):
			var p := pts[i]
			var q := pts[route.wrap_index(i + 2)]
			var dir := (q - p).normalized()
			var right := Vector3(-dir.z, 0.0, dir.x).normalized()
			var hw: float = track._sampler.half_width_at(i)
			var x: float = p.x + right.x * float(sgn) * (hw + 0.4)
			var z: float = p.z + right.z * float(sgn) * (hw + 0.4)
			var step: float = track._terrain_mesh_y(x, z) - p.y
			var f := float(i) / float(n)
			var bad := step > 0.15 or step < -0.9
			if bad:
				if run_start < 0.0:
					run_start = f
					run_min = step
					run_max = step
				run_min = minf(run_min, step)
				run_max = maxf(run_max, step)
				last_f = f
			elif run_start >= 0.0:
				out.append("    frac %.3f - %.3f: treapta %+.2f .. %+.2f m" % [run_start, last_f, run_min, run_max])
				run_start = -1.0
		if run_start >= 0.0:
			out.append("    frac %.3f - %.3f: treapta %+.2f .. %+.2f m" % [run_start, last_f, run_min, run_max])
		print("EDGE latura %s (0.4 m de margine): %d intervale cu treapta in afara de [-0.9, +0.15] m" % [
			"STANGA" if sgn < 0.0 else "DREAPTA", out.size()])
		for l in out:
			print(l)


## `--mode=info`: cat teren fin s-a generat (randuri / coloane fine) si cate triunghiuri are terenul.
func _info(track: Track) -> void:
	var rows := 0
	var cols := 0
	for b in track._fine_row:
		rows += int(b)
	for b in track._fine_col:
		cols += int(b)
	var terrain := track.find_child("Terrain", true, false) as MeshInstance3D
	var tris := 0
	if terrain != null:
		var arr := terrain.mesh.surface_get_arrays(0)
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		tris = idx.size() / 3
	print("INFO: randuri fine %d, coloane fine %d (din %d celule pe latura), triunghiuri teren %d" % [
		rows, cols, track._terr_cells, tris])
