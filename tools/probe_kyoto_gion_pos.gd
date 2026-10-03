extends Node
## GARDA: e carul Gion Matsuri ASEZAT pe soseaua reala a lui Track18 si se misca in
## lungul unei linii perpendiculare pe ea?
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeKyotoGionPos.tscn
##
## De ce exista (memoria hazard-dezaliniat-contamineaza-verdictul): pozitia vine din
## generator (curba Python, plata), iar drumul REAL e bake-ul Catmull-Rom din Godot.
## Se masoara ce a iesit INAINTE de orice ProbeRace. Inlocuieste `ProbeKyotoDarumaPos`
## pentru hazardul curent.
##
## Contracte: (a) originea sta pe axa (|lateral| <= 0.6 m); (b) -Z local pe sensul de mers
## (cos >= 0.99); (c) semilatimea locala = cea declarata; (d) in toate fazele de odihna +
## telegraf, NICIUN colt al amprentei (roti si trasatori inclusi) nu atinge asfaltul
## (>= 1 m de margine); (e) pe toata traversarea, corpul ramane pe linia lui (|z local|
## <= 0.01 m) si pozitia e continua (salt maxim pe cadru); (f) rotile ating solul real
## (raycast independent de profilul hazardului): nu plutesc, nu se ingroapa; (g) carul e
## in cadru de la 150 la 35 m inaintea lui (|azimut| <= 30 spre ambele odihne, pe >= 80%
## din puncte); plafonul camerei se tipareste ca tabel.

const CAM_HEIGHT: float = 10.0
const CAM_BACK: float = 12.5
const CAM_PITCH_DEG: float = 28.75 # inclinarea in jos a camerei de joc
const FOV_REST_HALF: float = 34.0
const FOV_FAST_HALF: float = 38.0


func _ready() -> void:
	await get_tree().process_frame
	var idx := GameState.resolve_track_index(18)
	var scene := load(GameState.TRACK_SCENES[idx]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().physics_frame
	var hz: GionMatsuriHazard = null
	for n in get_tree().get_nodes_in_group(GionMatsuriHazard.AI_GROUP):
		hz = n as GionMatsuriHazard
	if hz == null:
		print("PROBLEMA: niciun GionMatsuriHazard in scena")
		get_tree().quit(1)
		return
	hz.force_clock(0.0)
	for _k in 40:
		await get_tree().physics_frame
		if hz.ground_ready():
			break
	await get_tree().physics_frame
	var lines: Array[String] = []
	var ok := true
	var i := track.closest_index_global(hz.global_position)
	var rc := track.road_coords(i, hz.global_position)
	var f := track.frac_at(i)
	var hw := track.width_at_index(i)
	var tang := (track.point_at(i + 1) - track.point_at(i)).normalized()
	var fwd := -hz.global_transform.basis.z
	var cos_t := Vector2(fwd.x, fwd.z).normalized().dot(Vector2(tang.x, tang.z).normalized())
	lines.append("frac %.4f  semilatime locala %.2f m (declarata %.2f); profil sol construit: %s"
		% [f, hw, hz.road_half_width, str(hz.ground_ready())])
	var a := absf(rc.y) <= 0.6
	lines.append("  [%s] (a) origine pe axa: lateral %+.2f m" % [_pf(a), rc.y])
	var b := cos_t >= 0.99
	lines.append("  [%s] (b) -Z pe sensul de mers: cos %.4f" % [_pf(b), cos_t])
	var c := absf(hw - hz.road_half_width) <= 0.3
	lines.append("  [%s] (c) semilatime locala = declarata: %.2f vs %.2f" % [_pf(c), hw, hz.road_half_width])
	ok = ok and a and b and c

	# (d) amprenta in odihna si telegraf: coltul cel mai apropiat de asfalt, in lateral
	# fata de axa REALA (road_coords), pe ambele margini.
	var worst_gap := INF
	var rest_samples := 0
	for l in 2:
		for t_local in [0.2, hz.rest_seconds * 0.5, hz.rest_seconds + 0.2,
				hz.rest_seconds + hz.telegraph_seconds - 0.05]:
			var g := float(l) * hz.leg_seconds() + float(t_local)
			hz.force_clock(g)
			await get_tree().physics_frame
			rest_samples += 1
			var xc := hz.cart_x()
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					# colt al amprentei: lungime + latime (roti si trasatori)
					var local := Vector3(xc + sx * hz.cart_length * 0.5, 0.0,
						sz * (hz.cart_width * 0.5 + 0.6))
					var wp := hz.to_global(local)
					var ri := track.closest_index_global(wp)
					var rcc := track.road_coords(ri, wp)
					var gap := absf(rcc.y) - track.width_at_index(ri)
					worst_gap = minf(worst_gap, gap)
	var d := worst_gap >= 1.0 and rest_samples >= 8
	lines.append("  [%s] (d) odihna+telegraf (%d faze, ambele margini): coltul amprentei cel mai apropiat e la %.2f m de asfalt (minim 1,0)"
		% [_pf(d), rest_samples, worst_gap])
	ok = ok and d

	# (e) continuitate si aliniere pe toata traversarea
	hz.force_clock(0.0)
	var prev_x := hz.cart_x()
	var max_jump := 0.0
	var max_z := 0.0
	var steps := 0
	var t := 0.0
	var total := hz.total_seconds()
	var min_body_x := INF
	var max_body_x := -INF
	while t < total - 0.02:
		t += 1.0 / 60.0
		hz.seek(t)
		await get_tree().physics_frame
		steps += 1
		var x := hz.cart_x()
		max_jump = maxf(max_jump, absf(x - prev_x))
		prev_x = x
		var bl := hz.to_local(hz.body().global_position)
		max_z = maxf(max_z, absf(bl.z))
		min_body_x = minf(min_body_x, bl.x)
		max_body_x = maxf(max_body_x, bl.x)
	var e := max_z <= 0.01 and max_jump <= 0.12 and steps >= 1000
	lines.append("  [%s] (e) %d cadre: |z local| maxim %.3f m, salt maxim pe cadru %.3f m (<= 0,12 = %.1f m/s), corp pe X local de la %+.2f la %+.2f (odihna +-%.2f)"
		% [_pf(e), steps, max_z, max_jump, 0.12 * 60.0, min_body_x, max_body_x, hz.rest_x()])
	ok = ok and e

	# (f) profilul solului
	var gtxt := ""
	for k in range(-8, 9):
		gtxt += "%+.2f " % hz.ground_at(float(k) * 2.0)
	lines.append("  profil sol al hazardului (x = -16..16 pas 2, cota fata de radacina): " + gtxt)
	# raycast independent de profilul hazardului (garda circulara): sub fiecare roata,
	# distanta intre talpa rotii si sol
	var space := hz.get_world_3d().direct_space_state
	var worst_float := -INF
	var worst_sink := INF
	var samples_f := 0
	var move0 := hz.rest_seconds + hz.telegraph_seconds
	for tt in [0.5, move0 + hz.cross_seconds * 0.25, move0 + hz.cross_seconds * 0.5,
			move0 + hz.cross_seconds * 0.75, hz.leg_seconds() + 0.5]:
		hz.force_clock(float(tt))
		await get_tree().physics_frame
		for wi in 4:
			var w := hz.wheel_node(wi)
			var foot := w.global_position + Vector3.DOWN * GionMatsuriHazard.WHEEL_RADIUS
			var q := PhysicsRayQueryParameters3D.create(foot + Vector3.UP * 6.0,
				foot + Vector3.DOWN * 6.0)
			q.collision_mask = Track.CAMERA_BLOCKER_LAYER
			var hit := space.intersect_ray(q)
			if hit.is_empty():
				continue
			samples_f += 1
			var gap2 := foot.y - (hit.position as Vector3).y # + = plutesc
			worst_float = maxf(worst_float, gap2)
			worst_sink = minf(worst_sink, gap2)
	var ff := samples_f >= 12 and worst_float <= 0.5 and worst_sink >= -0.45
	lines.append("  [%s] (f) rotile pe sol (raycast independent, %d masuratori): cel mai rau plutesc %.2f m, cel mai rau ingropat %.2f m (plutire <= 0,5, ingropare <= 0,45)"
		% [_pf(ff), samples_f, worst_float, -worst_sink])
	ok = ok and ff

	# (g) cadru + plafon
	var route := track.routes[0]
	var n_pts := route.baked.size()
	var in_frame := 0
	var totalp := 0
	var worst_az := 0.0
	var arc := 0.0
	var axis_p := hz.global_position
	for k in range(1, n_pts):
		var p: Vector3 = route.baked[((i - k) % n_pts + n_pts) % n_pts]
		var p_prev: Vector3 = route.baked[((i - k + 1) % n_pts + n_pts) % n_pts]
		arc += Vector2(p.x - p_prev.x, p.z - p_prev.z).length()
		if arc > 150.0:
			break
		if arc < 35.0:
			continue
		var heading := Vector2(p_prev.x - p.x, p_prev.z - p.z).normalized()
		var worst_here := 0.0
		for sx in [-1.0, 1.0]:
			var tp := hz.to_global(Vector3(sx * hz.rest_x(), 0.0, 0.0))
			var to_cart := Vector2(tp.x - p.x, tp.z - p.z).normalized()
			worst_here = maxf(worst_here, rad_to_deg(acos(clampf(heading.dot(to_cart), -1.0, 1.0))))
		totalp += 1
		worst_az = maxf(worst_az, worst_here)
		if worst_here <= 30.0:
			in_frame += 1
	var gg := totalp >= 8 and float(in_frame) / maxf(float(totalp), 1.0) >= 0.8
	lines.append("  [%s] (g) in cadru pe [150,35] m: %d/%d puncte cu |azimut| <= 30 spre ambele odihne (cel mai rau %.0f grade, prag 80%%)"
		% [_pf(gg), in_frame, totalp, worst_az])
	ok = ok and gg
	var roof := 10.6
	var mast := 21.2
	lines.append("  plafonul camerei (10 m sus, 12,5 m in spate, fov 68 / 76 la viteza) vs acoperis %.1f m si varful catargului %.1f m:" % [roof, mast])
	var pitch := deg_to_rad(CAM_PITCH_DEG)
	for dist in [30.0, 50.0, 80.0, 120.0, 150.0]:
		var dcam: float = dist + CAM_BACK
		var c_rest: float = CAM_HEIGHT + dcam * tan(deg_to_rad(FOV_REST_HALF) - pitch)
		var c_fast: float = CAM_HEIGHT + dcam * tan(deg_to_rad(FOV_FAST_HALF) - pitch)
		lines.append("    la %3.0f m: plafon %.1f m (repaus) / %.1f m (viteza)  acoperis %s  varf catarg %s"
			% [dist, c_rest, c_fast, "in cadru" if roof <= c_rest else "TAIAT",
			"in cadru" if mast <= c_rest else "taiat (corect: se vede baza si coloana)"])
	for l in lines:
		print(l)
	print("carul lume: (%.1f, %.1f, %.1f)  axa: (%.1f, %.1f, %.1f)" % [
		axis_p.x, axis_p.y, axis_p.z,
		track.point_at(i).x, track.point_at(i).y, track.point_at(i).z])
	print("VERDICT: %s" % ("PASS" if ok else "PROBLEMA"))
	get_tree().quit(0 if ok else 1)


func _pf(v: bool) -> String:
	return "PASS" if v else "PROBLEMA"
