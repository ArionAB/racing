extends Node
## Garda geometrica a pontonului San Francisco (Track25, brief san_francisco.md §7 pasul 6).
## Raze verticale pe coliziunea REALA (nu `ground_y`, care extrapoleaza), din 4 in 4 m pe ponton:
##   1. carosabilul e la cota cheiului (+3) pe toata latimea;
##   2. spre GOLF (nord): la 1,5 m dincolo de asfalt solul e cu >= 1,5 m sub drum (muchia cade,
##      nu e plaja), iar la 8 m e sub apa (cine cade ajunge in apa, deci in plasa de mare);
##   3. spre ORAS (sud): la 1,5 m dincolo de asfalt solul e la cota drumului +- 0,35 m (rapa nu
##      sapa pe partea gresita: un prag acolo e zid pentru suspensie);
##   4. plasa de mare (SeaRespawn) sta SUB cota apei si deasupra fundului de la 8 m.
## Sabotaj: `--side=1` cere rapa pe partea sudului (citeste aceeasi scena, dar intoarce
## asteptarile) — trebuie sa pice.
##
## `--fall`: CADEREA, cu masini reale (fara AI). Fiecare masina din `--cars` pleaca pe cheiul de
## nord, inaintea pontonului, cu 26 m/s pe axa; la x_gap - 14 trage de volan spre golul dintre doi
## stalpi (greseala: iesirea larga / impinsa), cade in apa, e repusa (plasa de mare), apoi tine axa
## pana la capatul pontonului. Masoara: a cazut?, unde a fost repusa (pe carosabil?), pierderea
## de timp pana la capatul pontonului fata de aceeasi masina care tine axa. Tinta brief: ~2 s.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeSfPonton.tscn [-- --side=1]
##   ... -- --fall [--cars=1,2,3,5] [--gaps=0,3,6]

const SCENE: String = "res://scenes/tracks/Track25.tscn"

var _fail: int = 0


func _check(ok: bool, what: String) -> void:
	print("  [%s] %s" % ["OK " if ok else "PICAT", what])
	if not ok:
		_fail += 1


func _ray(space: PhysicsDirectSpaceState3D, x: float, z: float) -> float:
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, 60.0, z), Vector3(x, -80.0, z), 1)
	var hit := space.intersect_ray(q)
	return float((hit["position"] as Vector3).y) if not hit.is_empty() else -999.0


class PierPilot extends CarController:
	var z0: float = 0.0
	var turn_at_x: float = INF
	var target := Vector3.INF
	var fell: bool = false
	func get_steer() -> float:
		var p := car.global_position
		var t := Vector3(p.x + 14.0, p.y, z0)
		if not fell and p.x >= turn_at_x:
			t = target
		var f := -car.global_transform.basis.z
		f.y = 0.0
		var d := t - p
		d.y = 0.0
		if f.length() < 0.01 or d.length() < 0.01:
			return 0.0
		var ang := atan2(f.normalized().cross(d.normalized()).y, f.normalized().dot(d.normalized()))
		return clampf(ang * 2.5, -1.0, 1.0)
	func get_throttle() -> float:
		return 1.0


func _ready() -> void:
	var swap := false
	var fall := false
	for arg in OS.get_cmdline_user_args():
		if arg == "--side=1":
			swap = true
		elif arg == "--fall":
			fall = true
	var track := (load(SCENE) as PackedScene).instantiate() as Track
	add_child(track)
	for _f in 4:
		await get_tree().physics_frame
	if not track.has_meta("sf_ponton"):
		print("probe_sf_ponton: scena n-are metadata/sf_ponton")
		get_tree().quit(2)
		return
	var ends: Array = track.get_meta("sf_ponton")
	var a: Vector3 = ends[0]
	var b: Vector3 = ends[1]
	var space := track.get_world_3d().direct_space_state
	var hw := track.width_at_index(track.closest_index_global((a + b) * 0.5))
	if fall:
		await _fall_runs(track, a, b, hw)
		return
	print("")
	print("=== PONTON (Track25): x %.0f..%.0f, z %.1f, cota %.1f, semilatimea %.1f%s ===" % [
		a.x, b.x, a.z, a.y, hw, " — SABOTAJ: partile inversate" if swap else ""])
	var north := -1.0 if not swap else 1.0     # golful e spre -Z (nord)
	var worst_road := 0.0
	var worst_lip := 99.0
	var worst_far := -99.0
	var worst_land := 0.0
	var n := 0
	var x := a.x + 2.0
	while x <= b.x - 2.0:
		n += 1
		for lat in [-hw + 0.5, 0.0, hw - 0.5]:
			worst_road = maxf(worst_road, absf(_ray(space, x, a.z + lat) - a.y))
		worst_lip = minf(worst_lip, a.y - _ray(space, x, a.z + north * (hw + 1.5)))
		worst_far = maxf(worst_far, _ray(space, x, a.z + north * (hw + 8.0)))
		worst_land = maxf(worst_land, absf(_ray(space, x, a.z - north * (hw + 1.5)) - a.y))
		if OS.get_cmdline_user_args().has("--detail"):
			print("    x %5.1f: buza -%.2f, la 8 m %.2f, spre oras %+.2f" % [x,
				a.y - _ray(space, x, a.z + north * (hw + 1.5)), _ray(space, x, a.z + north * (hw + 8.0)),
				_ray(space, x, a.z - north * (hw + 1.5)) - a.y])
		x += 4.0
	# profilul transversal la mijlocul pontonului (nord = -Z = golful)
	var xm := (a.x + b.x) * 0.5
	var prof := PackedStringArray()
	for d in [-30.0, -16.0, -10.0, -7.5, -6.5, 0.0, 6.5, 7.5, 10.0, 16.0]:
		prof.append("%+.1f:%.2f" % [d, _ray(space, xm, a.z + d)])
	print("  profil la x %.0f (dz:cota, negativ = spre golf): %s" % [xm, " ".join(prof)])
	var sea_top := -999.0
	for c in track.get_children():
		if c is RespawnZone and String(c.name) == "SeaRespawn":
			for s in c.get_children():
				if s is CollisionShape3D and (s as CollisionShape3D).shape is BoxShape3D:
					var bx := (s as CollisionShape3D).shape as BoxShape3D
					sea_top = maxf(sea_top, (s as CollisionShape3D).global_position.y + bx.size.y * 0.5)
	var water_y := sea_top + 1.2          # Track._build_sea_respawn: plafonul plasei = apa - 1,2
	print("  %d sectiuni; apa la %.2f, plasa de mare pana la %.2f" % [n, water_y, sea_top])
	_check(worst_road < 0.25, "carosabilul la cota cheiului: abatere maxima %.2f m (< 0,25)" % worst_road)
	_check(worst_lip >= 1.5, "spre golf, la 1,5 m de asfalt: solul cu cel putin %.2f m sub drum (>= 1,5)" % worst_lip)
	_check(worst_far < water_y - 0.5, "spre golf, la 8 m: solul cel mai inalt la %.2f (sub apa: < %.2f)" % [worst_far, water_y - 0.5])
	_check(worst_land < 0.35, "spre oras, la 1,5 m de asfalt: abatere de la drum %.2f m (< 0,35)" % worst_land)
	_check(sea_top > -900.0 and absf(water_y) < 0.5 and sea_top > worst_far,
		"plasa de mare sub apa (%.2f; apa la %.2f, ~0) si peste fundul de la 8 m (%.2f)" % [sea_top, water_y, worst_far])
	print("VERDICT: %s" % ("OK" if _fail == 0 else "PICAT (%d)" % _fail))
	get_tree().quit(0 if _fail == 0 else 1)


## Modul --fall (vezi antetul).
func _fall_runs(track: Track, a: Vector3, b: Vector3, hw: float) -> void:
	var cars: Array[int] = [1, 2, 3, 5]
	var gaps: Array[int] = [0, 4, 8]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--cars="):
			cars.clear()
			for s in arg.trim_prefix("--cars=").split(","):
				cars.append(int(s))
		elif arg.begins_with("--gaps="):
			gaps.clear()
			for s in arg.trim_prefix("--gaps=").split(","):
				gaps.append(int(s))
	# stalpii: golurile sunt la mijloc intre doi vecini
	var posts: Array[float] = []
	var holder := track.get_node_or_null("Ponton/Stalpi")
	if holder != null:
		for c in holder.get_children():
			if c is CollisionShape3D:
				posts.append((c as CollisionShape3D).global_position.x)
	posts.sort()
	print("")
	print("=== PONTON: CADEREA (%d stalpi) — masina, golul (x), a cazut, repusa la, pe carosabil, pierderea pana la x %.0f ===" % [posts.size(), b.x])
	var losses: Array[float] = []
	var falls := 0
	var runs := 0
	for ci in cars:
		var base := await _pier_run(track, ci, a, b, hw, INF, Vector3.INF)
		for gi in gaps:
			if gi + 1 >= posts.size():
				continue
			var gx := (posts[gi] + posts[gi + 1]) * 0.5
			var r := await _pier_run(track, ci, a, b, hw, gx - 14.0, Vector3(gx + 4.0, a.y, a.z - hw - 6.0))
			runs += 1
			var data: CarData = GameState.CAR_DATA[ci]
			var rp: Vector3 = r["resp_at"]
			var on_road := bool(r["fell"]) and absf(rp.z - a.z) < hw and absf(rp.y - a.y) < 1.6
			if bool(r["fell"]):
				falls += 1
				losses.append(float(r["t"]) - float(base["t"]))
			print("  %-12s gol x %5.1f | %s | repusa (%.0f, %.1f, %.0f) | %s | %+5.2f s (fara cadere %.2f s)" % [
				data.display_name.left(12), gx, "CAZUT " if bool(r["fell"]) else "ramas ",
				rp.x, rp.y, rp.z, "pe carosabil" if on_road else "IN AFARA   ",
				float(r["t"]) - float(base["t"]), float(base["t"])])
	losses.sort()
	print("  caderi %d / %d incercari; pierderea mediana %.2f s (min %.2f, max %.2f)" % [falls, runs,
		losses[losses.size() / 2] if not losses.is_empty() else -1.0,
		losses[0] if not losses.is_empty() else -1.0, losses[losses.size() - 1] if not losses.is_empty() else -1.0])
	get_tree().quit(0 if falls > 0 else 1)


func _pier_run(track: Track, ci: int, a: Vector3, b: Vector3, hw: float, turn_x: float,
		target: Vector3) -> Dictionary:
	var data: CarData = GameState.CAR_DATA[ci]
	var car := (load("res://scenes/cars/Car.tscn") as PackedScene).instantiate() as Car
	add_child(car)
	car.apply_data(data)
	car.track = track
	var start := Vector3(a.x - 30.0, a.y + 0.6, a.z)
	var si := track.closest_index_global(start)
	car.global_transform = Transform3D(Basis.looking_at(Vector3(1, 0, 0), Vector3.UP), start)
	car.velocity = Vector3(26.0, 0, 0)
	car.linear_velocity = Vector3(26.0, 0, 0)
	car.road_index = si
	car.last_safe_index = si
	var ctl := PierPilot.new()
	ctl.z0 = a.z
	ctl.turn_at_x = turn_x
	ctl.target = target
	car.set_controller(ctl)
	car.race_active = true
	var ev := {"fell": false, "at": Vector3.ZERO}
	car.respawned.connect(func(c: Car) -> void:
		ev["fell"] = true
		ev["at"] = c.global_position
		ctl.fell = true)
	var t := 0.0
	while t < 30.0:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		var p := car.global_position
		if p.x >= b.x and absf(p.z - a.z) < hw + 1.0 and p.y > a.y - 1.0:
			break
	car.queue_free()
	await get_tree().physics_frame
	return {"t": t, "fell": ev["fell"], "resp_at": ev["at"]}
