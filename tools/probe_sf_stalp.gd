extends Node
## STALPII SOLIZI de pe Track25 (brief san_francisco.md §7 pasul 8d): o masina de joc reala, intr-o
## cursa reala (Race.tscn, cu plasa de repunere a cursei si cu AI-ul la volan dupa impact), trimisa
## DREPT intr-un felinar, un arbore de strada si un semafor, la 10, 20 si 34 m/s.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeSfStalp.tscn [-- --scene=res://...]
##       [--speeds=10,20,34] [--fams=felinar,arbore,semafor]
##
## Masina (CarData 0) pleaca de la 12 m (semaforul de pe muchie: 6 m) inaintea stalpului, cu 0,5 m mai spre carosabil decat el, paralel cu strada (asa se
## loveste un stalp in cursa: o masina iesita pe trotuar), cu viteza data, gaz la fund si volanul spre
## stalp. La primul contact cu CORPUL stalpului (`get_colliding_bodies`, cilindrul `trunk`) sau dupa
## 3 s, volanul trece la AIController (cum conduce orice adversar). Se masoara:
##   - CONTACT: a atins corpul stalpului?
##   - TRECUT PRIN: centrul masinii a ajuns la > 1 m dincolo de stalp, cu stalpul la mai putin de
##     (raza + 0,8 x semilatimea) lateral, FARA contact = tunel;
##   - ARUNCAT: cat a urcat masina (cota maxima in 2 s dupa contact - cota la contact) si cel mai mic
##     cos(inclinare) (1 = drept, < 0 = rasturnata);
##   - OPRIT / DEVIAT: viteza la 0,5 s dupa contact si unghiul cu care a plecat;
##   - RECUPERAT: in 20 s dupa contact, masina e la >= 25 m DINCOLO de stalp pe traseu si merge cu
##     > 8 m/s (timpul pana acolo), cu repunerile (`respawned`) si ejectarile numarate.
## Exit 1 daca un caz a trecut prin stalp, n-a atins nimic (stalp fara coliziune), a fost aruncat
## peste LAUNCH_MAX sau n-a fost recuperat in 20 s.

const RACE_SCENE: String = "res://scenes/race/Race.tscn"
const APPROACH_M: float = 12.0
## Semaforul de pe muchie: inainte de el e intersectia plata plina de masini parcate si arbori (ultima
## masina parcata se termina la 8,55 m inaintea muchiei), deci atacul porneste de la 6 m.
const APPROACH_MAST_M: float = 6.0
const LAUNCH_MAX: float = 1.5
const AIM_IN: float = 0.5
const RECOVER_S: float = 20.0
const STEP: float = 1.0 / 60.0

var _scene := "res://scenes/tracks/Track25.tscn"
var _speeds: Array[float] = [10.0, 20.0, 34.0]
var _fams: Array[String] = ["felinar", "arbore", "semafor"]
var _fails := 0


class RamController extends CarController:
	var target := Vector3.ZERO
	func get_steer() -> float:
		var p := car.global_position
		var f := -car.global_transform.basis.z
		f.y = 0.0
		var d := target - p
		d.y = 0.0
		if f.length() < 0.01 or d.length() < 0.5:
			return 0.0
		var ang := atan2(f.normalized().cross(d.normalized()).y, f.normalized().dot(d.normalized()))
		return clampf(ang * 2.0, -1.0, 1.0)
	func get_throttle() -> float:
		return 1.0


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--scene="):
			_scene = a.trim_prefix("--scene=")
		elif a.begins_with("--speeds="):
			_speeds.clear()
			for s in a.trim_prefix("--speeds=").split(","):
				_speeds.append(float(s))
		elif a.begins_with("--fams="):
			_fams.clear()
			for s in a.trim_prefix("--fams=").split(","):
				_fams.append(s)
	GameState.track_scene_override = _scene
	var idx := GameState.resolve_track_arg("Track25")
	GameState.selected_track = idx
	GameState.selected_car = 0
	GameState.ai_count = 0
	GameState.champ_active = false
	GameState.total_laps = 99
	print("=== ProbeSfStalp: %s ===" % _scene.get_file())
	var rows: Array = []
	for fam in _fams:
		for v in _speeds:
			rows.append(await _case(fam, v))
	print("%-8s %5s %-28s %7s %6s %8s %7s %8s %9s %8s %6s %6s" % ["familie", "v", "stalp", "contact", "tunel",
		"urcare", "cos min", "v+0,5s", "deviere", "recup.", "rep.", "eject"])
	for r: Dictionary in rows:
		print("%-8s %5.0f %-28s %7s %6s %+7.2fm %7.2f %7.1f %8.0f° %8s %6d %6d%s" % [r["fam"], r["v"], r["pole"],
			"da" if r["contact"] else "NU", "DA" if r["tunnel"] else "nu", r["rise"], r["upright"], r["v_after"],
			r["yaw"], ("%.1fs" % r["rec_t"]) if r["rec_t"] >= 0.0 else "NU", r["resp"], r["eject"],
			"   PICA: " + r["why"] if r["why"] != "" else ""])
	print("VERDICT: %s" % ("PICA (%d)" % _fails if _fails > 0 else "OK"))
	get_tree().quit(1 if _fails > 0 else 0)


## Stalpul de lovit dintr-o familie: primul din `sf_poles` care sta pe un trotuar (are corp), cu
## 25 m liberi de dinaintea lui pe directia strazii.
func _pick_pole(track: Track, fam: String) -> Array:
	var poles: Dictionary = track.get_meta("sf_poles", {})
	if not poles.has(fam):
		return []
	var cands := PackedVector3Array(poles[fam])
	# preferinte: felinar si arbore pe strada tramvaiului (B, x ~133..155), semaforul pe a doua muchie
	var best := -1
	for k in cands.size():
		var p := cands[k]
		if fam == "semafor" and absf(p.x - 8.5) < 0.5 and absf(p.z + 72.0) < 1.0:
			best = k
		elif fam != "semafor" and p.x > 120.0 and p.x < 170.0 and p.z < -20.0 and p.z > -90.0 and best < 0:
			best = k
	if best < 0:
		best = 0
	return [cands[best], best]


func _case(fam: String, v0: float) -> Dictionary:
	var race: Node = (load(RACE_SCENE) as PackedScene).instantiate()
	add_child(race)
	var out := {"fam": fam, "v": v0, "pole": "-", "contact": false, "tunnel": false, "rise": 0.0, "upright": 1.0,
		"v_after": -1.0, "yaw": 0.0, "rec_t": -1.0, "resp": 0, "eject": 0, "why": ""}
	# pana la START (numaratoarea ruleaza in fizica)
	var guard := 0
	while int(race.state) != 1 and guard < 2000:      # Race.State.RUNNING
		await get_tree().physics_frame
		guard += 1
	var track: Track = race.track
	var car: Car = race.player
	var pk := _pick_pole(track, fam)
	if pk.is_empty():
		out["why"] = "familie lipsa"
		_fails += 1
		race.queue_free()
		await get_tree().physics_frame
		return out
	var pole: Vector3 = pk[0]
	out["pole"] = "#%d (%.0f, %.1f, %.0f)" % [int(pk[1]), pole.x, pole.y, pole.z]
	# corpul stalpului: StaticBody `trunk` cu forma la < 1 m de talpa
	var body: Node = null
	for b in track.find_children("*", "StaticBody3D", true, false):
		if String((b as Node).get_meta("mod_coliziune", "")) != "trunk":
			continue
		for cs in (b as Node).get_children():
			if cs is CollisionShape3D:
				var cp := (cs as Node3D).global_position
				if Vector2(cp.x - pole.x, cp.z - pole.z).length() < 1.0:
					body = b
	# directia strazii in dreptul stalpului (sensul buclei)
	var ki := track.closest_index_global(pole)
	var n := track.baked.size()
	var dir := track.baked[(ki + 2) % n] - track.baked[(ki - 2 + n) % n]
	dir.y = 0.0
	dir = dir.normalized()
	# linia de atac trece cu AIM_IN m mai spre carosabil decat stalpul: stalpul intra in jumatatea
	# exterioara a botului (cum il ia o masina iesita pe trotuar), iar caroseria nu freaca fatadele
	# (felinarele stau la 1,2 m de ele)
	var to_road := track.baked[ki] - pole
	to_road.y = 0.0
	var inward := dir.cross(Vector3.UP).normalized()
	if inward.dot(to_road) < 0.0:
		inward = -inward
	var aim := pole + inward * AIM_IN
	var start := aim - dir * (APPROACH_MAST_M if fam == "semafor" else APPROACH_M)
	var k0 := track.closest_index_global(start)
	var ground := track.baked[k0].y
	start.y = maxf(pole.y, ground) + 0.8
	var ram := RamController.new()
	ram.target = aim
	car.set_controller(ram)
	car.road_index = k0
	car.last_safe_index = k0
	car.global_position = start
	car.look_at(start + dir, Vector3.UP)
	car.linear_velocity = dir * v0
	car.angular_velocity = Vector3.ZERO
	car.velocity = dir * v0
	var ev := {"resp": 0, "eject": 0}
	car.respawned.connect(func(_c: Car) -> void: ev["resp"] += 1)
	car.ejected.connect(func(_c: Car, _r: Node3D) -> void: ev["eject"] += 1)
	var half := (car.data.body_width * 0.5) if car.data != null else 0.9
	var radius := float((track.get_meta("sf_pole_r", {}) as Dictionary).get(fam, 0.3))
	if body == null:
		out["why"] = "stalpul n-are corp (coliziune)"
	var touched := {}
	var t := 0.0
	var t_c := -1.0
	var y_c := 0.0
	var prev_along := -APPROACH_M
	var handed := false
	var pole_s := track._dists[ki]
	while t < 2.0 + RECOVER_S + 2.0:
		await get_tree().physics_frame
		t += STEP
		var p := car.global_position
		var rel := p - pole
		var along := rel.x * dir.x + rel.z * dir.z
		var lat := absf(rel.x * dir.z - rel.z * dir.x)
		if t_c < 0.0:
			for b in car.get_colliding_bodies():
				touched[String((b as Node).name)] = true
			if body != null:
				for b in car.get_colliding_bodies():
					if b == body:
						t_c = t
						y_c = p.y
						out["contact"] = true
			if t_c < 0.0 and prev_along < 0.0 and along >= 1.0 and lat < radius + 0.8 * half:
				out["tunnel"] = true
			if t_c < 0.0 and t > 3.0 and not handed:
				t_c = t      # nicio atingere in 2 s
				y_c = p.y
		prev_along = along
		if t_c >= 0.0:
			var since := t - t_c
			if since <= 2.0:
				out["rise"] = maxf(float(out["rise"]), p.y - y_c)
				out["upright"] = minf(float(out["upright"]), car.global_transform.basis.y.dot(Vector3.UP))
			if float(out["v_after"]) < 0.0 and since >= 0.5:
				out["v_after"] = car.horizontal_speed()
				var f := -car.global_transform.basis.z
				f.y = 0.0
				if f.length() > 0.1:
					out["yaw"] = rad_to_deg(acos(clampf(f.normalized().dot(dir), -1.0, 1.0)))
			if not handed and since >= 0.6:
				handed = true
				var ai := AIController.new()
				car.set_controller(ai)
				var rng := RandomNumberGenerator.new()
				rng.seed = 7
				var vis: Array[Car] = [car]
				ai.configure(track, rng, vis)
			if handed and float(out["rec_t"]) < 0.0 and car.route == 0:
				var ds := track._dists[car.road_index] - pole_s
				if ds > 25.0 and ds < 400.0 and car.horizontal_speed() > 8.0:
					out["rec_t"] = since
			if float(out["rec_t"]) >= 0.0 and since > float(out["rec_t"]) + 1.0:
				break
			if since > RECOVER_S:
				break
	out["resp"] = ev["resp"]
	out["eject"] = ev["eject"]
	var why: Array[String] = []
	if String(out["why"]) != "":
		why.append(String(out["why"]))
	if not bool(out["contact"]):
		why.append("fara contact (atinse: %s)" % ",".join(touched.keys()))
	if bool(out["tunnel"]):
		why.append("trecut prin stalp")
	if float(out["rise"]) > LAUNCH_MAX:
		why.append("aruncata %.1f m" % float(out["rise"]))
	if float(out["rec_t"]) < 0.0:
		why.append("nerecuperata in %.0f s" % RECOVER_S)
	out["why"] = "; ".join(why)
	if not why.is_empty():
		_fails += 1
	race.queue_free()
	for _i in 3:
		await get_tree().physics_frame
	return out
