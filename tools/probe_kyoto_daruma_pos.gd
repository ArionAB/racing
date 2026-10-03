extends Node
## GARDA: e turnul daruma-otoshi ASEZAT pe marginea soselei reale a lui Track18?
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeKyotoDarumaPos.tscn
##
## De ce exista (memoria hazard-dezaliniat-contamineaza-verdictul): pozitia vine din
## generator (curba Python, plata), iar drumul REAL e bake-ul Catmull-Rom din Godot:
## aici se masoara ce a iesit, nu ce s-a calculat. Inlocuieste `ProbeKyotoTubPos`
## pentru hazardul curent (tubul nu mai e in scena).
##
## Contracte: (a) originea hazardului sta pe axa (|lateral| <= 0.6 m); (b) -Z local e
## pe sensul de mers (cos >= 0.99); (c) centrul turnului sta la semilatime + gol +
## raza discului, pe partea `side` (+-0.6 m); (d) `outward()` arata spre partea
## turnului; (e) turnul NU intra in banda: fata lui dinspre drum e la >= 1 m de marginea
## asfaltului; (f) semilatimea locala = cea declarata (5.5 m); (g) turnul e in cadru
## de la 150 la 35 m inaintea lui (|azimut| <= 30, fata de directia drumului, pe
## >= 80% din puncte) si capul (9.3 m) sta sub plafonul camerei (10 m peste drum);
## (h) fata turnului priveste spre masina care vine (unghi intre fata si directia
## spre camera <= 40 grade, pe >= 80% din puncte).

func _ready() -> void:
	await get_tree().process_frame
	var idx := GameState.resolve_track_index(18)
	var scene := load(GameState.TRACK_SCENES[idx]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().physics_frame
	var hz: DarumaOtoshiHazard = null
	for n in get_tree().get_nodes_in_group(DarumaOtoshiHazard.AI_GROUP):
		hz = n as DarumaOtoshiHazard
	if hz == null:
		print("PROBLEMA: niciun DarumaOtoshiHazard in scena")
		get_tree().quit(1)
		return
	var i := track.closest_index_global(hz.global_position)
	var rc := track.road_coords(i, hz.global_position)
	var f := track.frac_at(i)
	var hw := track.width_at_index(i)
	var side_v := track.routes[0].side_at(i)
	var tang := (track.point_at(i + 1) - track.point_at(i)).normalized()
	var fwd := -hz.global_transform.basis.z
	var cos_t := Vector2(fwd.x, fwd.z).normalized().dot(Vector2(tang.x, tang.z).normalized())
	var tw := hz.tower_node()
	var trc := track.road_coords(i, tw.global_position)
	var out_dot := hz.outward().dot(Vector3(side_v.x, 0, side_v.z).normalized())
	var r := hz.disc_diameter * 0.5
	var want_c := float(hz.side) * (hw + hz.tower_gap + r)
	var inner_face := absf(trc.y) - r - hw
	var lines: Array[String] = []
	lines.append("frac %.4f  semilatime locala %.2f m (declarata %.2f)" % [f, hw, hz.road_half_width])
	var a := absf(rc.y) <= 0.6
	lines.append("  [%s] (a) origine pe axa: lateral %+.2f m" % ["PASS" if a else "PROBLEMA", rc.y])
	var b := cos_t >= 0.99
	lines.append("  [%s] (b) -Z pe sensul de mers: cos %.4f" % ["PASS" if b else "PROBLEMA", cos_t])
	var c := absf(trc.y - want_c) <= 0.6
	lines.append("  [%s] (c) centrul turnului, partea %+d: lateral %+.2f (asteptat %+.2f)" % [
		"PASS" if c else "PROBLEMA", hz.side, trc.y, want_c])
	var d := out_dot >= 0.99
	lines.append("  [%s] (d) outward() spre partea turnului: dot %.3f" % ["PASS" if d else "PROBLEMA", out_dot])
	var e := inner_face >= 1.0
	lines.append("  [%s] (e) fata turnului la %.2f m de marginea asfaltului (minim 1.0)" % [
		"PASS" if e else "PROBLEMA", inner_face])
	var g := absf(hw - hz.road_half_width) <= 0.3
	lines.append("  [%s] (f) semilatime locala = declarata: %.2f vs %.2f" % [
		"PASS" if g else "PROBLEMA", hw, hz.road_half_width])
	# (g) cadru si (h) fata, pe punctele coapte de la 35 la 150 m inaintea turnului.
	var route := track.routes[0]
	var n_pts := route.baked.size()
	var tp := tw.global_position
	var in_frame := 0
	var facing := 0
	var total := 0
	var worst_az := 0.0
	var worst_face := 0.0
	var face_dir := (tw.global_transform.basis * Vector3(0, 0, 1)) # +Z model = fata
	face_dir.y = 0.0
	face_dir = face_dir.normalized()
	var arc := 0.0 # metri pe axa, inapoi de la turn (nu distanta in plan: bucla se intoarce)
	for k in range(1, n_pts):
		var p: Vector3 = route.baked[((i - k) % n_pts + n_pts) % n_pts]
		var p_prev: Vector3 = route.baked[((i - k + 1) % n_pts + n_pts) % n_pts]
		arc += Vector2(p.x - p_prev.x, p.z - p_prev.z).length()
		if arc > 150.0:
			break
		if arc < 35.0:
			continue
		var p_next: Vector3 = route.baked[((i - k + 1) % n_pts + n_pts) % n_pts]
		var heading := Vector2(p_next.x - p.x, p_next.z - p.z).normalized()
		var to_tower := Vector2(tp.x - p.x, tp.z - p.z).normalized()
		var az := rad_to_deg(acos(clampf(heading.dot(to_tower), -1.0, 1.0)))
		var to_cam := Vector3(p.x - tp.x, 0.0, p.z - tp.z).normalized()
		var fa := rad_to_deg(acos(clampf(face_dir.dot(to_cam), -1.0, 1.0)))
		total += 1
		worst_az = maxf(worst_az, az)
		worst_face = maxf(worst_face, fa)
		if az <= 30.0:
			in_frame += 1
		if fa <= 40.0:
			facing += 1
	var frac_frame := float(in_frame) / maxf(float(total), 1.0)
	var frac_face := float(facing) / maxf(float(total), 1.0)
	var top := hz.base_height + float(DarumaOtoshiHazard.LEVELS) * hz.disc_height + 2.72
	var gg := total >= 8 and frac_frame >= 0.8 and top < 10.0
	lines.append("  [%s] (g) in cadru pe [150,35] m: %d/%d puncte la |azimut| <= 30 (%.0f%%, cel mai rau %.0f grade, prag 80%%); varf %.2f m < 10 m"
		% ["PASS" if gg else "PROBLEMA", in_frame, total, 100.0 * frac_frame, worst_az, top])
	var hh := total >= 8 and frac_face >= 0.8
	lines.append("  [%s] (h) fata spre masina care vine: %d/%d puncte la <= 40 grade fata de directia spre camera (%.0f%%, cel mai rau %.0f grade)"
		% ["PASS" if hh else "PROBLEMA", facing, total, 100.0 * frac_face, worst_face])
	for l in lines:
		print(l)
	var ok := a and b and c and d and e and g and gg and hh
	print("turn lume: (%.1f, %.1f, %.1f)  axa: (%.1f, %.1f, %.1f)" % [
		tw.global_position.x, tw.global_position.y, tw.global_position.z,
		track.point_at(i).x, track.point_at(i).y, track.point_at(i).z])
	print("VERDICT: %s" % ("PASS" if ok else "PROBLEMA"))
	get_tree().quit(0 if ok else 1)
