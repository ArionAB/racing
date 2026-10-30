extends Node
## Sonda tehnica Carrara (c): sania de lizzatura = RockfallHazard care ALUNECA.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCarraraSled.tscn
##   (optional, dupa `--`): --quick  (fara baleiajul de decalaj si fara benzile +-3)
##                          --glb=res://...  (sania din kit in locul cutiilor sintetice;
##                                            golul se masoara sub talpile GLB-ului,
##                                            varianta „lunga" se sare)
##
## Brief carrara.md §3 ("Sania de lizzatura"), §6 (5), §7 pasul 1 (c). Scena e
## SINTETICA (nu exista traseu inca): drum drept de 9 m, un jgheab de 30 grade
## care vine din DREAPTA si taie drumul in diagonala (40 de grade fata de axa),
## si platforma plata din stanga. Sania e un stand-in din PRIMITIVE (BoxMesh,
## 12 triunghiuri fiecare): talpa de lemn + bloc de marmura de 2 m.
##
## Contractul e scris ca CIFRA fata de banda (memoria garda-cu-numele-
## gimmickului), cu hazardul in starea lui ACTIVA:
##   (1) nu pluteste si nu se ingroapa: golul dintre talpa si suprafata, masurat
##       cu o raza sub fiecare colt al talpii, pe tot traseul;
##   (2) taie drumul: intra/iese din asfalt, si acopera fiecare banda;
##   (3) `roll_model = false` nu roteste modelul cu distanta; `true` il roteste;
##   (4) 4 masini de mase diferite, lovite lateral la 15 si 25 m/s: deplasare
##       laterala, viteza dupa, schimbare de directie, rasturnare, timp de
##       revenire, timp pierdut fata de o rulare de control.
## Iese cu cod 1 la orice verdict picat SAU la zero masuratori.

const Common := preload("res://tools/probe_carrara_common.gd")

# ---- geometria scenei sintetice
const ANGLE_DEG: float = 40.0      # unghiul jgheabului fata de axa drumului
const SLOPE_DEG: float = 30.0
const CHUTE_HALF: float = 2.5
const EASE_K: float = 4.0          # lungimea racordarii concave de jos (m); raza ~ k / tan(panta) = 6.9 m
const S_END: float = -10.0         # unde jgheabul ajunge la cota drumului
const S_START: float = -27.0       # primul punct al traseului
const S_STOP: float = 16.0         # ultimul punct (pe platforma din stanga)
const S_PLATEAU: float = -34.0
const SLED_SPEED: float = 6.5
const TARGET_CYCLE: float = 41.0
const LANES: Array[float] = [-3.0, 0.0, 3.0]

# ---- contractul
const MAX_FLOAT: float = 0.15
## Un talp rigid de 2.4 m pe o racordare concava de raza ~7 m intra in suprafata
## cu sageata coardei: L^2 / (8 R) = 0.10 m la capete. 0.15 = geometria, nu defect.
const MAX_SINK: float = 0.15
const LOSS_MIN: float = 0.4
const LOSS_MAX: float = 1.6
const FLIP_COS: float = 0.3

## police_sports (m=90, cea mai usoara din garaj), muscle (135, referinta),
## firetruck (200), bus (260, cea mai grea).
const GARAGE: Array[int] = [1, 0, 4, 3]
const SPEEDS: Array[float] = [15.0, 25.0]

var _fails: int = 0
var _quick: bool = false
var _ease: float = EASE_K
var _sin: float
var _cos: float
var _results: Array[Dictionary] = []
## --glb: modelul din kit (carrara/props/lizza_sled.glb). Talpa de contact a
## sanii din kit: talpile la X +-1,01, de la Z +1,20 (spate) la -0,70 (de
## acolo in fata varful e ridicat, ca la o sanie) -- coordonate de MODEL, cu
## originea GLB-ului la talpa (nodul `Sled_Wood` sta in origine).
var _glb: String = ""
const GLB_BASE_NODE := "Sled_Wood"
const GLB_CONTACT: Array[Vector3] = [Vector3(-1.01, 0.0, 1.20), Vector3(1.01, 0.0, 1.20),
	Vector3(-1.01, 0.0, -0.70), Vector3(1.01, 0.0, -0.70), Vector3(0.0, 0.0, 0.25)]


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--quick":
			_quick = true
		elif a.begins_with("--glb="):
			_glb = a.substr(6)
	_sin = sin(deg_to_rad(ANGLE_DEG))
	_cos = cos(deg_to_rad(ANGLE_DEG))
	await get_tree().process_frame
	print("")
	print("=== CARRARA (c): sania de lizzatura (RockfallHazard, roll_model) ===")
	if _glb != "":
		print("    MODEL: %s (talpa de contact %s)" % [_glb, str(GLB_CONTACT)])
	var clr := await _measure_clearance("ideala", 2.4, 2.4, 0.4, 2.0, true)
	if _glb == "":
		await _measure_clearance("lunga", 2.2, 3.6, 0.35, 2.0, false)
	_ease = 8.0
	print("")
	print("    (racordare concava de 8 m in loc de 4: raza ~14 m)")
	await _measure_clearance("ideala, racordare lenta", 2.4, 2.4, 0.4, 2.0, false)
	_ease = EASE_K
	await _measure_rotation()
	await _measure_hits(clr)
	print("")
	print("=== %s ===" % ("PICAT: %d verdicte" % _fails if _fails > 0 else "TOATE OK"))
	get_tree().quit(1 if _fails > 0 else 0)


func _verdict(ok: bool, text: String) -> void:
	print("  [%s] %s" % ["OK" if ok else "PICAT", text])
	if not ok:
		_fails += 1


# ------------------------------------------------------------- geometria

func _plan(s: float, u: float) -> Vector2:
	# d = (-sin, -cos) in planul XZ (sensul saniei), n = (cos, -sin)
	return Vector2(-_sin * s + _cos * u, -_cos * s - _sin * u)


func _chute_y(s: float) -> float:
	var t := S_END - maxf(s, S_PLATEAU)
	if t <= 0.0:
		return 0.0
	var f := t * t / (2.0 * _ease) if t < _ease else t - _ease * 0.5
	return tan(deg_to_rad(SLOPE_DEG)) * f


func _p3(s: float, u: float) -> Vector3:
	var p := _plan(s, u)
	return Vector3(p.x, _chute_y(s), p.y)


func _build_chute(parent: Node) -> void:
	var faces := PackedVector3Array()
	var s := S_PLATEAU
	var ds := 0.5
	var du := 0.5
	while s < -4.0:
		var u := -CHUTE_HALF
		while u < CHUTE_HALF - 0.001:
			var a := _p3(s, u)
			var b := _p3(s + ds, u)
			var c := _p3(s + ds, u + du)
			var d := _p3(s, u + du)
			for tri in [[a, b, c], [a, c, d]]:
				var n: Vector3 = (tri[1] - tri[0]).cross(tri[2] - tri[0])
				if n.y < 0.0:
					faces.append_array(PackedVector3Array([tri[0], tri[2], tri[1]]))
				else:
					faces.append_array(PackedVector3Array([tri[0], tri[1], tri[2]]))
			u += du
		s += ds
	var body := StaticBody3D.new()
	body.name = "Chute"
	var cs := CollisionShape3D.new()
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	cs.shape = shape
	body.add_child(cs)
	parent.add_child(body)


func _sled_scene(width: float, length: float, base_h: float, block: float) -> PackedScene:
	if _glb != "":
		return load(_glb) as PackedScene
	var root := Node3D.new()
	root.name = "Sled"
	var base := MeshInstance3D.new()
	base.name = "Base"
	var bm := BoxMesh.new()
	bm.size = Vector3(width, base_h, length)
	base.mesh = bm
	base.position = Vector3(0.0, base_h * 0.5, 0.0)
	root.add_child(base)
	base.owner = root
	var blk := MeshInstance3D.new()
	blk.name = "Block"
	var km := BoxMesh.new()
	km.size = Vector3(block, block, block)
	blk.mesh = km
	blk.position = Vector3(0.0, base_h + block * 0.5, 0.0)
	root.add_child(blk)
	blk.owner = root
	var ps := PackedScene.new()
	ps.pack(root)
	root.free()
	return ps


func _route_curve() -> Curve3D:
	var c := Curve3D.new()
	for s in [S_START, -15.0, S_END, -5.0, 0.0, 8.0, S_STOP]:
		c.add_point(_p3(s, 0.0))
	return c


## Lumea sintetica: podea + jgheab + hazardul. `roll` = roll_model.
func _world(scene: PackedScene, roll: bool, with_hazard: bool) -> Dictionary:
	var root := Node3D.new()
	root.name = "World"
	add_child(root)
	Common.make_ground(root)
	var hz: RockfallHazard = null
	if with_hazard:
		_build_chute(root)
		hz = RockfallHazard.new()
		hz.name = "Sled"
		hz.route = _route_curve()
		hz.route_speed = SLED_SPEED
		hz.model_scene = scene
		hz.roll_model = roll
		root.add_child(hz)
		hz.period = TARGET_CYCLE
	return {"root": root, "hz": hz}


func _free_world(w: Dictionary) -> void:
	(w["root"] as Node).queue_free()
	await get_tree().physics_frame
	await get_tree().physics_frame


func _ground(space: PhysicsDirectSpaceState3D, p: Vector3, ex: Array[RID]) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(p.x, p.y + 6.0, p.z), Vector3(p.x, p.y - 40.0, p.z), 0xFFFFFFFF, ex)
	return space.intersect_ray(q)


# ----------------------------------------------------- (1)+(2) golul si drumul

func _measure_clearance(label: String, width: float, length: float, base_h: float,
		block: float, gating: bool) -> Dictionary:
	print("")
	print("--- sania '%s': talpa %.1f x %.1f x %.2f m + bloc %.1f m, pe jgheab de %.0f grade" % [
		label, width, length, base_h, block, SLOPE_DEG])
	var scene := _sled_scene(width, length, base_h, block)
	var w := _world(scene, false, true)
	var hz: RockfallHazard = w["hz"]
	await get_tree().physics_frame
	var radius := hz._radius
	var container := hz._pivot.get_child(0) as Node3D
	var base := container.find_child(GLB_BASE_NODE if _glb != "" else "Base", true, false) as Node3D
	print("    raza masurata de hazard: %.3f m (sfera de coliziune); inaltime model %.2f m, jumatate %.3f"
		% [radius, base_h + block, (base_h + block) * 0.5])
	print("    traseu %.1f m, durata unei treceri %.2f s, cross_time %.2f s, ciclu setat %.1f s -> rock_pause = %.2f s"
		% [hz._route_len, hz._route_travel, hz.cross_time(), TARGET_CYCLE,
		TARGET_CYCLE - hz._route_travel])
	var space := get_viewport().world_3d.direct_space_state
	var ex: Array[RID] = [hz._rock.get_rid()]
	var corners: Array[Vector3] = []
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			corners.append(Vector3(sx * width * 0.5, -base_h * 0.5, sz * length * 0.5))
	corners.append(Vector3(0.0, -base_h * 0.5, 0.0))
	if _glb != "":
		corners = GLB_CONTACT.duplicate()
	var max_gap := -INF
	var max_gap_perp := -INF
	var min_gap := INF
	var where_max := Vector3.ZERO
	var where_min := Vector3.ZERO
	var gap_slope_max := -INF
	var gap_flat_max := -INF
	var n_samples := 0
	var cx: Array[Vector3] = []
	var ct: Array[float] = []
	var t := 0.0
	var shadow_on := -1.0
	var tilt_max := 0.0
	var frames_total := int((TARGET_CYCLE + hz._route_travel * 0.5) * 60.0) if gating \
		else int((hz._route_travel + 1.0) * 60.0)
	var vis_prev := false
	var vis_edges: Array[float] = []
	var sync_err_max := 0.0
	var phys_speed_road := 0.0
	var phys_speed_n := 0
	var prev_c := Vector3.ZERO
	var unaligned := 0.0
	for f in frames_total:
		await get_tree().physics_frame
		t += Common.STEP
		var vis := hz._rock.visible
		if vis and not vis_prev:
			vis_edges.append(t)
		vis_prev = vis
		if not vis or vis_edges.size() > 1:
			continue
		var c := hz._rock.global_position
		sync_err_max = maxf(sync_err_max, c.distance_to(hz.to_global(hz._last_pos)))
		if hz._telegraph.visible and shadow_on < 0.0:
			shadow_on = t
		n_samples += 1
		cx.append(c)
		ct.append(t)
		if n_samples > 1 and absf(c.x) <= Common.ROAD_HALF:
			phys_speed_road += Vector2(c.x - prev_c.x, c.z - prev_c.z).length() / Common.STEP
			phys_speed_n += 1
		prev_c = c
		tilt_max = maxf(tilt_max, rad_to_deg(acos(clampf(
			hz._pivot.global_transform.basis.y.dot(Vector3.UP), -1.0, 1.0))))
		var bt := base.global_transform
		var under := _ground(space, c, ex)
		var on_slope: bool = not under.is_empty() and (under["position"] as Vector3).y > 0.3
		# Primul cadru al primului ciclu: sania tocmai a aparut sus, inca neorientata
		# (prima aliniere vine la cadrul 2). Se numara in `unaligned`, nu in gol.
		if n_samples == 1:
			unaligned = tilt_max
			continue
		for corner in corners:
			var pw := bt * corner
			var hit := _ground(space, pw, ex)
			if hit.is_empty():
				continue
			var gp: float = pw.y - (hit["position"] as Vector3).y
			var nrm: Vector3 = hit["normal"]
			max_gap_perp = maxf(max_gap_perp, gp * absf(nrm.y))
			if gp > max_gap:
				max_gap = gp
				where_max = pw
			if gp < min_gap:
				min_gap = gp
				where_min = pw
			if on_slope:
				gap_slope_max = maxf(gap_slope_max, gp)
			else:
				gap_flat_max = maxf(gap_flat_max, gp)
	print("    (cadrul 1 al primului ciclu, orientare inca neaplicata, exclus din gol: inclinare %.1f grade)" % unaligned)
	print("    esantioane: %d cadre; diferenta pozitie ceruta vs corp: max %.3f m" % [n_samples, sync_err_max])
	print("    GOL talpa-suprafata (vertical, + = pluteste, - = intra in sol): max %+.3f m la %s, min %+.3f m la %s"
		% [max_gap, str(where_max.snapped(Vector3.ONE * 0.01)), min_gap,
		str(where_min.snapped(Vector3.ONE * 0.01))])
	print("      pe panta max %+.3f, pe plat max %+.3f; perpendicular pe suprafata max %+.3f; inclinarea modelului max %.1f grade"
		% [gap_slope_max, gap_flat_max, max_gap_perp, tilt_max])
	if n_samples == 0 or max_gap == -INF:
		_verdict(false, "sania '%s': zero masuratori" % label)
		await _free_world(w)
		return {}
	var tag := "" if gating else "  [informativ]"
	var ok_float := max_gap <= MAX_FLOAT
	var ok_sink := min_gap >= -MAX_SINK
	if gating:
		_verdict(ok_float, "sania '%s' nu pluteste: gol max %+.3f m (prag %.2f)" % [label, max_gap, MAX_FLOAT])
		_verdict(ok_sink, "sania '%s' nu se ingroapa: gol min %+.3f m (prag -%.2f)" % [label, min_gap, MAX_SINK])
	else:
		print("  [INFO] sania '%s': gol max %+.3f, min %+.3f (%s)%s" % [label, max_gap, min_gap,
			"ar trece" if ok_float and ok_sink else "AR PICA", tag])
		await _free_world(w)
		return {"ok": true}

	# ---- drumul: intrare/iesire din asfalt si benzile
	var t_in := -1.0
	var t_out := -1.0
	var p_in := Vector3.ZERO
	var p_out := Vector3.ZERO
	for i in cx.size():
		if absf(cx[i].x) <= Common.ROAD_HALF:
			if t_in < 0.0:
				t_in = ct[i]
				p_in = cx[i]
			t_out = ct[i]
			p_out = cx[i]
	if t_in < 0.0:
		_verdict(false, "centrul saniei nu intra niciodata pe asfalt (zero masuratori pe drum)")
		await _free_world(w)
		return {}
	var speed_road := phys_speed_road / maxf(float(phys_speed_n), 1.0)
	print("    pe asfalt (centrul, |x| <= %.1f): intra la t=%.2f s in (%.2f, %.2f, %.2f), iese la t=%.2f s in (%.2f, %.2f, %.2f); %.2f s pe drum"
		% [Common.ROAD_HALF, t_in, p_in.x, p_in.y, p_in.z, t_out, p_out.x, p_out.y, p_out.z, t_out - t_in])
	print("    viteza centrului pe asfalt (plan): %.2f m/s (cerut 6-7); unghiul fata de axa %.1f grade"
		% [speed_road, rad_to_deg(atan2(absf(p_out.x - p_in.x), absf(p_out.z - p_in.z)))])
	_verdict(speed_road >= 6.0 and speed_road <= 7.0, "viteza pe drum %.2f m/s in 6-7" % speed_road)
	var lane_info := {}
	for lane in LANES:
		var dmin := INF
		var t_lane := 0.0
		var z_lane := 0.0
		var occ := 0.0
		for i in cx.size():
			var d := absf(cx[i].x - lane)
			if d < dmin:
				dmin = d
				t_lane = ct[i]
				z_lane = cx[i].z
			if d <= 1.5:
				occ += Common.STEP
		lane_info[lane] = {"t": t_lane, "z": z_lane}
		print("    banda x=%+.1f: centrul saniei trece la %.3f m de axa (t=%.2f s, z=%+.2f); in banda (|dx| <= 1.5) %.2f s"
			% [lane, dmin, t_lane, z_lane, occ])
		_verdict(dmin <= 1.5 and occ > 0.5,
			"sania acopera banda x=%+.1f (%.3f m de axa, %.2f s in banda)" % [lane, dmin, occ])
	var t_vis0: float = vis_edges[0] if not vis_edges.is_empty() else 0.0
	var cross_abs: float = lane_info[0.0]["t"]
	print("    umbra de avertizare apare cu %.2f s inaintea trecerii peste axa (TELEGRAPH din cod = %.1f s; brief cere 2 s)"
		% [cross_abs - shadow_on, RockfallHazard.TELEGRAPH])
	print("    sania apare la t=%.2f s si ajunge pe axa la %.2f s dupa aparitie (vizibila pe jgheab inainte de asta)"
		% [t_vis0, cross_abs - t_vis0])
	if vis_edges.size() >= 2:
		var cyc := vis_edges[1] - vis_edges[0]
		print("    ciclul masurat (aparitie -> aparitie): %.2f s (cerut ~41)" % cyc)
		_verdict(absf(cyc - TARGET_CYCLE) < 0.1, "ciclul e %.2f s" % cyc)
	else:
		_verdict(false, "n-am prins doua aparitii pentru ciclu")
	await _free_world(w)
	return {"lanes": lane_info, "t_cross": cross_abs}


# --------------------------------------------------------------- (3) rotatia

func _measure_rotation() -> void:
	print("")
	print("--- (3) rotatia modelului in jurul axei de rostogolire")
	var scene := _sled_scene(2.4, 2.4, 0.4, 2.0)
	var out := {}
	for roll in [false, true]:
		var w := _world(scene, roll, true)
		var hz: RockfallHazard = w["hz"]
		await get_tree().physics_frame
		var prev: Quaternion = hz._pivot.transform.basis.get_rotation_quaternion()
		var q0 := prev
		var total := 0.0
		var frames := int((hz._route_travel + 0.5) * 60.0)
		var n := 0
		for f in frames:
			await get_tree().physics_frame
			if not hz._rock.visible:
				continue
			n += 1
			var q: Quaternion = hz._pivot.transform.basis.get_rotation_quaternion()
			total += prev.angle_to(q)
			prev = q
		var net := q0.angle_to(prev)
		print("    roll_model=%s: rotatie totala acumulata %.1f grade (%.2f ture), net start->capat %.1f grade; traseu %.1f m / raza %.3f = %.0f grade la rostogolire; %d cadre"
			% [str(roll), rad_to_deg(total), rad_to_deg(total) / 360.0, rad_to_deg(net),
			hz._route_len, hz._radius, rad_to_deg(hz._route_len / hz._radius), n])
		out[roll] = rad_to_deg(total)
		await _free_world(w)
	if not out.has(true) or float(out[true]) <= 0.0:
		_verdict(false, "zero masuratori de rotatie")
		return
	_verdict(float(out[true]) > 360.0, "roll_model=true ROTESTE modelul (%.0f grade)" % float(out[true]))
	_verdict(float(out[false]) < 90.0,
		"roll_model=false NU se rostogoleste (%.1f grade acumulate, prag 90; inclinarea pe panta nu e rostogolire)"
		% float(out[false]))


# ------------------------------------------------------------------ (4) masini

func _run_car(idx: int, speed: float, lane: float, z0: float, with_sled: bool,
		t_run: float) -> Dictionary:
	var scene := _sled_scene(2.4, 2.4, 0.4, 2.0)
	var w := _world(scene, false, with_sled)
	var car := Common.spawn_car(w["root"], idx, lane, z0, speed)
	var ev := {"hit_t": -1.0, "crush": 0, "respawn": 0, "recover": 0, "eject": 0, "upright": 0, "wall": 0}
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


func _measure_hits(clr: Dictionary) -> void:
	print("")
	print("--- (4) masini lovite de sanie (stare activa, lateral)")
	if clr.is_empty():
		_verdict(false, "fara geometrie de sanie nu pot lovi masini")
		return
	var lanes: Dictionary = clr["lanes"]
	var lane_list: Array[float] = [0.0]
	var deltas: Array[float] = [0.0]
	if not _quick:
		lane_list = LANES.duplicate()
		deltas = [-0.6, 0.0, 0.6]
	var names: Array[String] = []
	for i in GARAGE:
		var d: CarData = GameState.CAR_DATA[i]
		names.append("%s (m=%.0f)" % [d.display_name, 100.0 * d.mass_factor])
	print("    masini: %s" % ", ".join(names))
	print("    coloane: masina, viteza, banda, decalaj(s) | t_atingere | viteza inainte -> minim in 0.5 s (pastrat) | minim 3 s | lateral max/final | yaw max/final | inclinare | rasturnata | revenire | timp pierdut | semnale")
	var primary: Array[Dictionary] = []
	for idx in GARAGE:
		for v in SPEEDS:
			for lane in lane_list:
				for dl in deltas:
					if lane != 0.0 and dl != 0.0:
						continue
					var li: Dictionary = lanes[lane]
					var z_lane: float = li["z"]
					var p_star := -z_lane
					var t_x: float = li["t"]
					var z0 := z_lane + v * t_x
					var t_run := t_x + 14.0
					var c0 := await _run_car(idx, v, lane, z0, false, t_run)
					var t_c := Common.time_at_progress(c0["rec"], p_star)
					var cname: String = (GameState.CAR_DATA[idx] as CarData).display_name
					if t_c == INF:
						_verdict(false, "controlul %s nu ajunge la z=%.1f" % [cname, z_lane])
						continue
					var z1 := z0 + v * (t_x + dl - t_c)
					var ctrl := await _run_car(idx, v, lane, z1, false, t_run)
					var hit := await _run_car(idx, v, lane, z1, true, t_run)
					var ev: Dictionary = hit["ev"]
					if ev["hit_t"] < 0.0:
						print("    %-12s %2.0f m/s x=%+.0f d=%+.1f | NEATINSA (sania a trecut pe langa)" % [cname, v, lane, dl])
						if dl == 0.0:
							_verdict(false, "%s la %.0f m/s, banda %+.0f: sania NU a atins masina la decalaj 0" % [cname, v, lane])
						continue
					var a := Common.analyze(hit["rec"], ctrl["rec"], ev["hit_t"])
					if a.is_empty():
						_verdict(false, "analiza goala (%s)" % cname)
						continue
					a["name"] = cname
					a["speed"] = v
					a["lane"] = lane
					a["delta"] = dl
					a["idx"] = idx
					a["ev"] = ev
					_results.append(a)
					var rec_s: String = ("%.2f" % a["recover_s"]) if a["recover_s"] != INF else "NICIODATA"
					print("    %-12s %2.0f m/s x=%+.0f d=%+.1f | t=%.2f | %5.2f -> %5.2f (%3.0f%%) | %5.2f | lat %.2f/%+.2f | yaw %.1f/%+.1f | tilt %.1f | flip %.2fs | rev %s | loss %+.2f s | resp %d rec %d ej %d upr %d wall %d crush %d | vpeak %.1f xabs %.1f"
						% [cname, v, lane, dl, ev["hit_t"], a["v_before"], a["v_min"], 100.0 * a["kept"],
						a["v_min3"], a["lat_max"], a["lat_end"], a["yaw_max_deg"], a["yaw_end_deg"],
						a["tilt_max_deg"], a["flipped_s"], rec_s, a["loss"],
						ev["respawn"], ev["recover"], ev["eject"], ev["upright"], ev["wall"], ev["crush"],
						a["v_peak"], a["x_abs_max"]])
					if lane == 0.0 and dl == 0.0:
						primary.append(a)
	# ---- verdicte
	if primary.size() < GARAGE.size() * SPEEDS.size():
		_verdict(false, "doar %d din %d combinatii centrale masurate" % [primary.size(), GARAGE.size() * SPEEDS.size()])
		return
	for v in SPEEDS:
		var mins: Dictionary = {}
		var lats: Dictionary = {}
		var n := 0
		for a in primary:
			if a["speed"] == v:
				# 0,01 mm, nu 1 mm: verdictul prinde mecanismul NECONECTAT (cifre
				# identice la bit), nu doua mase care raspund aproape la fel. Sania v2
				# (raza 1,200) da 1,05298 / 1,05314 m deviere la Muscle / Pompieri:
				# diferite, dar egale la rotunjirea de 1 mm.
				mins[snappedf(a["v_min"], 0.00001)] = true
				lats[snappedf(a["lat_max"], 0.00001)] = true
				n += 1
		_verdict(mins.size() == n and lats.size() == n and n >= 4,
			"la %.0f m/s cifrele difera intre masini (%d valori distincte de viteza-minim, %d de deviere laterala, din %d)"
			% [v, mins.size(), lats.size(), n])
	var worst_loss := -INF
	var best_loss := INF
	var any_flip := false
	var any_recover := false
	var never := false
	var any_spike := false
	for a in _results:
		if a["lane"] == 0.0 and a["delta"] == 0.0:
			worst_loss = maxf(worst_loss, a["loss"])
			best_loss = minf(best_loss, a["loss"])
		if a["up_min"] < FLIP_COS or a["flipped_s"] > 0.0:
			any_flip = true
		var ev: Dictionary = a["ev"]
		if ev["respawn"] > 0 or ev["recover"] > 0 or ev["eject"] > 0:
			any_recover = true
		if a["recover_s"] == INF:
			never = true
		if a["v_peak"] > a["v_before"] + 8.0:
			any_spike = true
	_verdict(not any_flip, "nicio rasturnare in %d rulaje (prag cos < %.1f)" % [_results.size(), FLIP_COS])
	_verdict(not any_recover, "nicio repunere / ejectare / recovery")
	_verdict(not never, "toate masinile isi revin (viteza >= 90%% din control si deviere < 0.5 m)")
	_verdict(not any_spike, "nicio viteza anormala dupa lovitura (corp cinematic aparut in masina)")
	_verdict(best_loss >= LOSS_MIN and worst_loss <= LOSS_MAX,
		"timp pierdut ~ +1 s (ghiont): %.2f .. %.2f s pe cele 8 combinatii centrale (prag %.1f-%.1f)"
		% [best_loss, worst_loss, LOSS_MIN, LOSS_MAX])
