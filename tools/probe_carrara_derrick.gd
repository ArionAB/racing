extends Node
## Sonda tehnica Carrara (d): derrick-ul = CraneHazard cu catarg de 16 m.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCarraraDerrick.tscn
##   (optional, dupa `--`): --quick  (fara baleiajul de decalaj)
##
## Brief carrara.md par.2 POI C, par.3 ("Derrick-ul cu bloc"), par.7 pasul 1 (d).
## Stand-in: `tower_crane.glb` (Chongqing, catarg 22.05 m) cu `model_scale` =
## 16 / 22.05 si `prefab_slab.glb` ca sarcina. ZERO COD in CraneHazard: sonda
## masoara daca ruta asta tine contractul.
##
## Ce se masoara (cotele REALE din lume, nu exporturile):
##   - inaltimea catargului din mesh vs. pivotul bratului (CraneHazard NU le
##     deriva din model: JIB_HEIGHT si SLAB_SIZE sunt constante);
##   - cota reala a sarcinii deasupra drumului la trecere, si matura laterala;
##   - 4 masini din garaj prin sarcina la 15 si 25 m/s: invartit + ghiontit,
##     NU oprit (precedent Chongqing: 22.0 -> 1.1 m/s e ESECUL; contractul
##     cere >= 60% din viteza de intrare in fereastra de impact de 0.5 s).
## Iese cu cod 1 la orice verdict picat SAU la zero masuratori.

const Common := preload("res://tools/probe_carrara_common.gd")
const CraneScript := preload("res://scenes/hazards/crane_hazard.gd")

const MAST_TARGET: float = 16.0
const REACH: float = 13.0          # raza efectiva a sarcinii (m)
const PERIOD: float = 23.0
const CLEARANCE: float = 0.6
const ROAD_HALF: float = 4.5
const TOWER_OFFSET: float = 7.0
const LANES: Array[float] = [-3.0, 0.0, 3.0]
## Decalajul ciclului (ca prima trecere sa vina la ~5 s si masinile sa nu
## porneasca de la sute de metri). CraneHazard aduna `phase` si la ceas si la
## unghi, deci unghiul e decalat cu 2 * phase rotatii (masurat, nu presupus).
const PHASE: float = 0.0

const KEEP_MIN: float = 0.60
const SHOVE_MIN: float = 0.2
const FLIP_COS: float = 0.3
const GARAGE: Array[int] = [1, 0, 4, 3]
const SPEEDS: Array[float] = [15.0, 25.0]

var _fails: int = 0
var _quick: bool = false
var _scale: float
## Calibrarea pe configuratia Chongqing (catarg 22.05, brat 13, turn la 7).
var _ref22: bool = false
## Pe ce parte a drumului sta turnul: -1 stanga (brief), +1 dreapta (ca ProbeCrane).
var _side: int = -1
var _phase: float = PHASE
var _results: Array[Dictionary] = []


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--quick":
			_quick = true
		elif a == "--right":
			_side = 1
	await get_tree().process_frame
	# Inaltimea reala a catargului din mesh (nu o cifra din brief).
	var crane := (load(CraneScript.CRANE_MODEL) as PackedScene).instantiate() as Node3D
	var mast_mesh := crane.find_child("TowerCrane", true, false) as MeshInstance3D
	var real_mast := mast_mesh.get_aabb().size.y
	crane.free()
	_scale = MAST_TARGET / real_mast
	print("")
	print("=== CARRARA (d): derrick-ul (CraneHazard, catarg 16 m) ===")
	print("    mesh-ul tower_crane.glb: catarg %.3f m; JIB_HEIGHT din cod = %.2f; model_scale = %.4f; hook_radius = %.3f (=> raza efectiva %.2f m)"
		% [real_mast, CraneScript.JIB_HEIGHT, _scale, REACH / _scale, REACH])
	_verdict(absf(real_mast - CraneScript.JIB_HEIGHT) < 0.01,
		"constanta JIB_HEIGHT (%.2f) = catargul masurat in mesh (%.3f)" % [CraneScript.JIB_HEIGHT, real_mast])
	await _pick_phase()
	print("    faza aleasa %.3f (trecerea cu z>0 vine la ~4.5 s dupa pornire)" % _phase)
	var geo := await _measure_geometry()
	var sw := await _measure_sweep()
	await _measure_hits(sw)
	await _calibrate_vs_chongqing()
	print("")
	print("=== %s ===" % ("PICAT: %d verdicte" % _fails if _fails > 0 else "TOATE OK"))
	get_tree().quit(1 if _fails > 0 else 0)


func _verdict(ok: bool, text: String) -> void:
	print("  [%s] %s" % ["OK" if ok else "PICAT", text])
	if not ok:
		_fails += 1


func _cube_scene(side: float) -> PackedScene:
	# Cub cu originea la CARLIG (centrul fetei de sus), ca prefab_slab.glb.
	var root := Node3D.new()
	root.name = "MarbleCube"
	var mi := MeshInstance3D.new()
	mi.name = "Cube"
	var bm := BoxMesh.new()
	bm.size = Vector3(side, side, side)
	mi.mesh = bm
	mi.position = Vector3(0.0, -side * 0.5, 0.0)
	root.add_child(mi)
	mi.owner = root
	var ps := PackedScene.new()
	ps.pack(root)
	root.free()
	return ps


func _world(slab: PackedScene) -> Dictionary:
	var root := Node3D.new()
	root.name = "World"
	add_child(root)
	Common.make_ground(root)
	var hz: CraneHazard = CraneScript.new()
	hz.name = "Derrick"
	hz.model_scale = 1.0 if _ref22 else _scale
	hz.hook_radius = REACH / hz.model_scale
	hz.period = 20.0 if _ref22 else PERIOD
	hz.phase = _phase
	hz.load_clearance = 0.5 if _ref22 else CLEARANCE
	hz.tower_side = _side
	hz.tower_offset = TOWER_OFFSET
	hz.road_half_width = ROAD_HALF
	if slab != null:
		hz.slab_model = slab
	root.add_child(hz)
	return {"root": root, "hz": hz}


func _free_world(w: Dictionary) -> void:
	(w["root"] as Node).queue_free()
	await get_tree().physics_frame
	await get_tree().physics_frame


func _world_aabb(n: Node) -> AABB:
	var boxes: Array[AABB] = []
	for m in n.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if mi.mesh != null and mi.visible:
			boxes.append(mi.global_transform * mi.get_aabb())
	if n is MeshInstance3D:
		var me := n as MeshInstance3D
		boxes.append(me.global_transform * me.get_aabb())
	if boxes.is_empty():
		return AABB()
	var out: AABB = boxes[0]
	for i in range(1, boxes.size()):
		out = out.merge(boxes[i])
	return out


# -------------------------------------------------------- cote din model

func _measure_geometry() -> Dictionary:
	print("")
	print("--- (1) cotele reale: catarg, pivot, brat, sarcina (dupa model_scale)")
	var w := _world(null)
	var hz: CraneHazard = w["hz"]
	await get_tree().physics_frame
	await get_tree().physics_frame
	var mast := hz.find_child("TowerCrane", true, false) as MeshInstance3D
	var mb := _world_aabb(mast)
	var mast_col := hz.get_node("Mast").get_child(0) as CollisionShape3D
	var box := mast_col.shape as BoxShape3D
	var col_top := mast_col.global_position.y + box.size.y * 0.5
	var pivot_y := hz._jib_pivot.global_position.y
	var jib := hz._jib_pivot.find_child("Jib", true, false) as MeshInstance3D
	# jib in spatiul PIVOTULUI (independent de unghiul de rotatie)
	var jb: AABB = jib.transform * jib.get_aabb()
	# carligul modelat: varful de jos al bratului (y minim) si z-ul lui
	var hook_z := 0.0
	var n_hook := 0
	var faces := jib.mesh.get_faces()
	var ymin := INF
	for v in faces:
		ymin = minf(ymin, v.y)
	for v in faces:
		if v.y < ymin + 0.3:
			hook_z += v.z
			n_hook += 1
	hook_z = hook_z / maxf(float(n_hook), 1.0) * _scale
	print("    mesh catarg (lume): y %.3f .. %.3f (inaltime %.3f m); colizor catarg: sus la %.3f m" % [
		mb.position.y, mb.end.y, mb.size.y, col_top])
	print("    pivotul bratului la y = %.3f m (scop: %.2f)" % [pivot_y, MAST_TARGET])
	print("    mesh brat (in spatiul pivotului): y %+.2f .. %+.2f, z %+.2f .. %+.2f" % [
		jb.position.y, jb.end.y, jb.position.z, jb.end.z])
	print("    carligul DESENAT in brat e la z = %.2f m; sarcina atarna la z = %.2f m (hook_radius*scale)" % [
		hook_z, -hz.hook_radius * hz.model_scale])
	_verdict(absf(mb.end.y - MAST_TARGET) < 0.05, "catargul din mesh are %.3f m (scop 16.0)" % mb.end.y)
	_verdict(absf(pivot_y - MAST_TARGET) < 0.05 and absf(col_top - MAST_TARGET) < 0.05,
		"pivotul (%.3f) si colizorul catargului (%.3f) cobora cu el la 16 m" % [pivot_y, col_top])
	_verdict(absf(pivot_y - mb.end.y) < 0.05, "pivotul sta in varful catargului din mesh (diferenta %.3f m)" % (pivot_y - mb.end.y))
	# sarcina: prefab_slab (default) vs cub de marmura de 2.5 m
	var slab_node := hz._load.find_child("PrefabSlab", true, false) as Node3D
	var sb := _world_aabb(slab_node)
	var col := hz._load.get_child(1) as CollisionShape3D
	var cbox := col.shape as BoxShape3D
	print("    sarcina prefab_slab: vizual %.2f x %.2f x %.2f m, colizor %.2f x %.2f x %.2f m (SLAB_SIZE*scale)" % [
		sb.size.x, sb.size.y, sb.size.z, cbox.size.x, cbox.size.y, cbox.size.z])
	var visual_bottom := sb.position.y
	var coll_bottom := col.global_position.y - cbox.size.y * 0.5
	print("    talpa vizuala a sarcinii y=%.3f, talpa colizorului y=%.3f (diferenta %.3f m)" % [visual_bottom, coll_bottom, visual_bottom - coll_bottom])
	# 0.12 m * scale e decalajul propriu al clasei (SLAB_TOP_OFFSET), prezent si la
	# 22 m: talpa vizuala sta ceva mai jos decat colizorul.
	_verdict(absf(visual_bottom - coll_bottom) < 0.15, "colizorul sarcinii acopera vizualul prefab_slab pe verticala (diferenta %.3f m)" % (visual_bottom - coll_bottom))
	await _free_world(w)
	# cub de 2.5 m: sa se vada ce face colizorul constant
	var side := 2.5 / _scale
	var w2 := _world(_cube_scene(side))
	var hz2: CraneHazard = w2["hz"]
	await get_tree().physics_frame
	await get_tree().physics_frame
	var cube := hz2._load.find_child("Cube", true, false) as Node3D
	var cb := _world_aabb(cube)
	var col2 := hz2._load.get_child(1) as CollisionShape3D
	var cbox2 := col2.shape as BoxShape3D
	print("    INFO cub de marmura 2.5 m (model %.3f m x scale %.4f): vizual %.2f x %.2f x %.2f m, colizor %.2f x %.2f x %.2f m, talpa vizuala y=%.3f vs colizor y=%.3f"
		% [side, _scale, cb.size.x, cb.size.y, cb.size.z, cbox2.size.x, cbox2.size.y, cbox2.size.z,
		cb.position.y, col2.global_position.y - cbox2.size.y * 0.5])
	print("    INFO colizorul sarcinii e SLAB_SIZE*scale indiferent de model: un bloc de alta forma are colizor de prefabricat (%.2f x %.2f x %.2f)"
		% [CraneScript.SLAB_SIZE.x * _scale, CraneScript.SLAB_SIZE.y * _scale, CraneScript.SLAB_SIZE.z * _scale])
	await _free_world(w2)
	return {}


# -------------------------------------------------- matura sarcinii pe drum

func _measure_sweep() -> Dictionary:
	print("")
	print("--- (2) matura sarcinii: cota deasupra drumului si acoperirea benzilor")
	var w := _world(null)
	var hz: CraneHazard = w["hz"]
	await get_tree().physics_frame
	var frames := int(PERIOD * 2.2 * 60.0)
	var t := 0.0
	var prev_x := 0.0
	var prev_set := false
	var crossings: Array[Dictionary] = []
	var over_s := 0.0
	var min_bottom_over := INF
	var tip_speed := 0.0
	var tip_n := 0
	var prev_load := Vector3.ZERO
	var lane_min := {}
	var lane_occ := {}
	for lane in LANES:
		lane_min[lane] = INF
		lane_occ[lane] = 0.0
	var load_col := hz._load.get_child(1) as CollisionShape3D
	var half_x := (load_col.shape as BoxShape3D).size.x * 0.5
	var first_period_n := 0
	for f in frames:
		await get_tree().physics_frame
		t += Common.STEP
		var c := load_col.global_position
		var bottom := hz.load_bottom()
		if prev_set:
			if (prev_x > 0.0) != (c.x > 0.0):
				crossings.append({"t": t, "z": c.z, "bottom": bottom, "vx": (c.x - prev_x) / Common.STEP,
					"dir": signf(c.x - prev_x), "speed": hz.load_velocity().length()})
			tip_speed += Vector2(c.x - prev_load.x, c.z - prev_load.z).length() / Common.STEP
			tip_n += 1
		prev_x = c.x
		prev_load = c
		prev_set = true
		if absf(c.x) <= ROAD_HALF:
			over_s += Common.STEP
			min_bottom_over = minf(min_bottom_over, bottom)
		for lane in LANES:
			var d := absf(c.x - lane)
			if t < PERIOD:
				lane_min[lane] = minf(lane_min[lane], d)
				if d <= half_x + 0.9: # semilatimea sarcinii + a caroseriei
					lane_occ[lane] += Common.STEP
	if crossings.is_empty():
		_verdict(false, "zero treceri ale sarcinii peste axa (nimic masurat)")
		await _free_world(w)
		return {}
	var tip := tip_speed / maxf(float(tip_n), 1.0)
	print("    viteza medie a sarcinii %.2f m/s (2*pi*%.1f/%.0f = %.2f; brief spune ~4 m/s)" % [
		tip, REACH, PERIOD, TAU * REACH / PERIOD])
	print("    treceri peste axa drumului (centrul sarcinii x=0), in %.1f s:" % (frames * Common.STEP))
	for c in crossings:
		print("      t=%6.2f s  z=%+7.2f m  cota talpa colizor %.3f m deasupra drumului  viteza x %+.2f m/s  |v| %.2f m/s"
			% [c["t"], c["z"], c["bottom"], c["vx"], c["speed"]])
	print("    peste asfalt (centrul, |x|<=%.1f): %.2f s pe %.0f s; cota minima a talpii pe asfalt %.3f m (scop %.2f)"
		% [ROAD_HALF, over_s / 2.2, PERIOD, min_bottom_over, CLEARANCE])
	for lane in LANES:
		print("    banda x=%+.1f: centrul sarcinii trece la %.3f m de axa; in banda (|dx| <= %.2f) %.2f s pe rotatie"
			% [lane, lane_min[lane], half_x + 0.9, lane_occ[lane]])
		_verdict(lane_min[lane] <= 1.5 and lane_occ[lane] > 0.3,
			"sarcina acopera banda x=%+.1f" % lane)
	_verdict(absf(min_bottom_over - CLEARANCE) <= 0.25,
		"talpa sarcinii trece la %.3f m deasupra drumului (scop %.2f +-0.25, leganarea include)" % [min_bottom_over, CLEARANCE])
	_verdict(min_bottom_over < 1.1, "sub inaltimea caroseriei (1.10): %.3f" % min_bottom_over)
	_verdict(min_bottom_over > 0.0, "nu intra in asfalt (%.3f)" % min_bottom_over)
	var per_rot := 0
	for c in crossings:
		if c["t"] < PERIOD:
			per_rot += 1
	print("    treceri pe rotatie: %d" % per_rot)
	_verdict(per_rot == 2, "doua treceri pe rotatie (%d)" % per_rot)
	await _free_world(w)
	var usable: Array[Dictionary] = []
	for c in crossings:
		if c["t"] >= 3.5 and usable.size() < 2:
			usable.append(c)
	return {"crossings": usable}


# ------------------------------------------------------------------ masini

func _run_car(idx: int, speed: float, z0: float, with_hz: bool, t_run: float) -> Dictionary:
	var w := _world(null)
	if not with_hz:
		(w["hz"] as Node).queue_free()
		await get_tree().physics_frame
	var car := Common.spawn_car(w["root"], idx, 0.0, z0, speed)
	var ev := {"hit_t": -1.0, "respawn": 0, "recover": 0, "eject": 0, "upright": 0, "wall": 0, "crush": 0}
	var clock := [0.0]
	car.crushed.connect(func(_c: Car, _s: float) -> void:
		ev["crush"] += 1
		if ev["hit_t"] < 0.0:
			ev["hit_t"] = clock[0])
	car.respawned.connect(func(_c: Car) -> void: ev["respawn"] += 1)
	car.recovery_started.connect(func(_c: Car, _s: float) -> void: ev["recover"] += 1)
	car.ejected.connect(func(_c: Car, _r: Node3D) -> void: ev["eject"] += 1)
	car.uprighted.connect(func(_c: Car) -> void: ev["upright"] += 1)
	car.wall_hit.connect(func(_c: Car, _i: float) -> void: ev["wall"] += 1)
	var rec := Common.Rec.new()
	for f in int(t_run * 60.0):
		await get_tree().physics_frame
		clock[0] += Common.STEP
		rec.add(clock[0], car)
	await _free_world(w)
	return {"rec": rec, "ev": ev}


func _measure_hits(sw: Dictionary) -> void:
	print("")
	print("--- (3) masini prin sarcina (hazard activ), banda x=0")
	if sw.is_empty() or (sw["crossings"] as Array).is_empty():
		_verdict(false, "fara treceri masurate nu pot lovi masini")
		return
	var crossings: Array = sw["crossings"]
	var deltas: Array[float] = [0.0]
	if not _quick:
		deltas = [-0.5, 0.0, 0.5]
	var names: Array[String] = []
	for i in GARAGE:
		var d: CarData = GameState.CAR_DATA[i]
		names.append("%s (m=%.0f)" % [d.display_name, 100.0 * d.mass_factor])
	print("    masini: %s" % ", ".join(names))
	print("    coloane: masina, viteza, trecerea, decalaj | t_atingere | viteza inainte -> minim in 0.5 s (pastrat) | minim 3 s | lateral max/final | yaw max/final | spin vizual | strivire | urcare | inclinare | rasturnata | revenire | timp pierdut | semnale")
	var primary: Array[Dictionary] = []
	for idx in GARAGE:
		for v in SPEEDS:
			for ci in crossings.size():
				var cr: Dictionary = crossings[ci]
				for dl in deltas:
					if dl != 0.0 and ci != 0:
						continue
					var z_x: float = cr["z"]
					var t_x: float = cr["t"]
					var p_star := -z_x
					var z0 := z_x + v * t_x
					var t_run := t_x + 14.0
					if z0 > 760.0:
						_verdict(false, "start la z=%.0f depaseste podeaua (alege PHASE)" % z0)
						continue
					var cname: String = (GameState.CAR_DATA[idx] as CarData).display_name
					var c0 := await _run_car(idx, v, z0, false, t_run)
					var t_c := Common.time_at_progress(c0["rec"], p_star)
					if t_c == INF:
						_verdict(false, "controlul %s nu ajunge la z=%.1f" % [cname, z_x])
						continue
					var z1 := z0 + v * (t_x + dl - t_c)
					var ctrl := await _run_car(idx, v, z1, false, t_run)
					var hit := await _run_car(idx, v, z1, true, t_run)
					var ev: Dictionary = hit["ev"]
					if ev["hit_t"] < 0.0:
						print("    %-12s %2.0f m/s tr%d d=%+.1f | NEATINSA" % [cname, v, ci, dl])
						if dl == 0.0:
							_verdict(false, "%s la %.0f m/s, trecerea %d: sarcina NU a atins masina la decalaj 0" % [cname, v, ci])
						continue
					var a := Common.analyze(hit["rec"], ctrl["rec"], ev["hit_t"])
					if a.is_empty():
						_verdict(false, "analiza goala (%s)" % cname)
						continue
					a["name"] = cname
					a["speed"] = v
					a["cross"] = ci
					a["delta"] = dl
					a["ev"] = ev
					_results.append(a)
					var rec_s: String = ("%.2f" % a["recover_s"]) if a["recover_s"] != INF else "NICIODATA"
					print("    %-12s %2.0f m/s tr%d d=%+.1f | t=%.2f | %5.2f -> %5.2f (%3.0f%%) | %5.2f | lat %.2f/%+.2f | yaw %.1f/%+.1f | spin %.2f | crush %.2f | rise %.2f | tilt %.1f | flip %.2fs | rev %s | loss %+.2f s | resp %d rec %d ej %d upr %d wall %d | vpeak %.1f"
						% [cname, v, ci, dl, ev["hit_t"], a["v_before"], a["v_min"], 100.0 * a["kept"], a["v_min3"],
						a["lat_max"], a["lat_end"], a["yaw_max_deg"], a["yaw_end_deg"], a["spin_max"], a["crush_max"],
						a["rise"], a["tilt_max_deg"], a["flipped_s"], rec_s, a["loss"],
						ev["respawn"], ev["recover"], ev["eject"], ev["upright"], ev["wall"], a["v_peak"]])
					if dl == 0.0:
						primary.append(a)
	if primary.size() < GARAGE.size() * SPEEDS.size() * crossings.size():
		_verdict(false, "doar %d din %d combinatii centrale masurate" % [primary.size(), GARAGE.size() * SPEEDS.size() * crossings.size()])
		return
	for v in SPEEDS:
		var mins: Dictionary = {}
		var lats: Dictionary = {}
		var n := 0
		for a in primary:
			if a["speed"] == v and a["cross"] == 0:
				mins[snappedf(a["v_min"], 0.001)] = true
				lats[snappedf(a["lat_max"], 0.001)] = true
				n += 1
		_verdict(mins.size() == n and lats.size() == n and n >= 4,
			"la %.0f m/s cifrele difera intre masini (%d viteze-minim distincte, %d deviatii laterale distincte, din %d)"
			% [v, mins.size(), lats.size(), n])
	var worst_keep := INF
	var worst_who := ""
	var any_flip := false
	var any_recover := false
	var never := false
	var no_spin := false
	var no_shove := false
	var any_spike := false
	var worst_loss := -INF
	for a in _results:
		if a["delta"] == 0.0:
			if a["kept"] < worst_keep:
				worst_keep = a["kept"]
				worst_who = "%s %.0f m/s tr%d" % [a["name"], a["speed"], a["cross"]]
			worst_loss = maxf(worst_loss, a["loss"])
			if a["spin_max"] <= 0.0:
				no_spin = true
			if a["lat_max"] < SHOVE_MIN:
				no_shove = true
		if a["up_min"] < FLIP_COS or a["flipped_s"] > 0.0:
			any_flip = true
		var ev: Dictionary = a["ev"]
		if ev["respawn"] > 0 or ev["recover"] > 0 or ev["eject"] > 0:
			any_recover = true
		if a["recover_s"] == INF:
			never = true
		if a["v_peak"] > a["v_before"] + 8.0:
			any_spike = true
	_verdict(worst_keep >= KEEP_MIN,
		"contact = matura, NU zid: viteza pastrata in fereastra de 0.5 s >= %.0f%% la toate cele %d combinatii centrale (cea mai rea: %.0f%%, %s)"
		% [100.0 * KEEP_MIN, primary.size(), 100.0 * worst_keep, worst_who])
	_verdict(not no_spin, "toate loviturile centrale invart masina (spin vizual > 0)")
	_verdict(not no_shove, "toate loviturile centrale ghiontesc lateral (>= %.1f m; cele grele mai putin, hazard_mass_ratio)" % SHOVE_MIN)
	_verdict(not any_flip, "nicio rasturnare in %d rulaje (prag cos < %.1f)" % [_results.size(), FLIP_COS])
	_verdict(not any_recover, "nicio repunere / ejectare / recovery")
	_verdict(not never, "toate masinile isi revin (viteza >= 90%% din control si deviere < 0.5 m)")
	_verdict(not any_spike, "nicio viteza anormala dupa lovitura")
	print("    timp pierdut maxim la loviturile centrale: %.2f s (brief: derrick ~ +1.5 s)" % worst_loss)


## Aceeasi harnica pe configuratia Chongqing (scara 1, catarg 22.05, ciclu 20 s,
## Muscle la 22 m/s, ca ProbeCrane): arata daca diferenta fata de cifra
## documentata (21.72 -> 12.98 m/s, 60%) vine din harnica sau din derrick.
func _calibrate_one(ref: bool, side: int) -> Dictionary:
	_ref22 = ref
	var keep_side := _side
	_side = side
	await _pick_phase()
	var sw := await _measure_sweep_quiet()
	_ref22 = ref
	var cr: Dictionary = {}
	for c in sw["crossings"]:
		if c["z"] > 0.0 and 22.0 * float(c["t"]) < 760.0:
			cr = c
			break
	if cr.is_empty():
		print("    (calibrare: nicio trecere cu z>0 sub 760 m de start; crossings=%s)" % str(sw["crossings"]))
		_side = keep_side
		_phase = PHASE
		return {}
	var v := 22.0
	var z_x: float = cr["z"]
	var t_x: float = cr["t"]
	var z0 := z_x + v * t_x
	var t_run := t_x + 14.0
	var c0 := await _run_car(0, v, z0, false, t_run)
	var t_c := Common.time_at_progress(c0["rec"], -z_x)
	var z1 := z0 + v * (t_x - t_c)
	var ctrl := await _run_car(0, v, z1, false, t_run)
	var hit := await _run_car(0, v, z1, true, t_run)
	var ev: Dictionary = hit["ev"]
	_side = keep_side
	_phase = PHASE
	if ev["hit_t"] < 0.0:
		return {}
	return Common.analyze(hit["rec"], ctrl["rec"], ev["hit_t"])


## Faza care aduce prima trecere cu z>0 la ~4.5 s dupa pornire: o masurare cu
## faza 0, apoi decalajul (CraneHazard decaleaza unghiul cu 2 * phase rotatii).
func _pick_phase() -> void:
	_phase = 0.0
	var probe0 := await _measure_sweep_quiet()
	var t0 := -1.0
	for c in probe0["crossings"]:
		if c["z"] > 0.0:
			t0 = c["t"]
			break
	var period := 20.0 if _ref22 else PERIOD
	if t0 > 0.0:
		_phase = fposmod((t0 - 4.5) / (2.0 * period), 0.5)


func _measure_sweep_quiet() -> Dictionary:
	var w := _world(null)
	var hz: CraneHazard = w["hz"]
	await get_tree().physics_frame
	var t := 0.0
	var prev_x := 0.0
	var prev_set := false
	var out: Array[Dictionary] = []
	var load_col := hz._load.get_child(1) as CollisionShape3D
	for f in int(hz.period * 1.5 * 60.0):
		await get_tree().physics_frame
		t += Common.STEP
		var c := load_col.global_position
		if prev_set and (prev_x > 0.0) != (c.x > 0.0) and t >= 3.5 and out.size() < 2:
			out.append({"t": t, "z": c.z})
		prev_x = c.x
		prev_set = true
	await _free_world(w)
	return {"crossings": out}


func _calibrate_vs_chongqing() -> void:
	print("")
	print("--- (4) calibrare: aceeasi harnica pe configuratia Chongqing (22 m) vs derrick 16 m, Muscle 22 m/s, trecerea 0")
	for side in [1, -1]:
		for ref in [true, false]:
			var a := await _calibrate_one(ref, side)
			_ref22 = false
			if a.is_empty():
				_verdict(false, "calibrare: sarcina n-a atins masina (ref22=%s, turn %+d)" % [str(ref), side])
				continue
			print("    turn %s, %s: %.2f -> %.2f m/s in 0.5 s (%.0f%%), lateral %.2f m, spin %.2f, strivire %.2f, urcare %.2f, pierdut %+.2f s"
				% ["dreapta" if side > 0 else "stanga ", "Chongqing 22 m" if ref else "derrick 16 m  ", a["v_before"], a["v_min"], 100.0 * a["kept"],
				a["lat_max"], a["spin_max"], a["crush_max"], a["rise"], a["loss"]])
	print("    (ProbeCrane documentat: 21.72 -> 12.98 m/s, 60%)")
