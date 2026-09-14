extends Node
## Serpentinele Hiram Bingham (Machu Picchu, POI G): razele acelor pe axa si
## GENERATORUL traseului autobuzului (BusHazard).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeMachuAce.tscn
##   ... -- --from=0.69 --to=0.90 --min-radius=13
##
## Ce face:
##   1. masoara raza de viraj pe axa (circumraza din 3 puncte la ~12 m, exact
##      ca ProbeLayout) in fereastra ceruta si raporteaza fiecare AC (minim
##      local) cu fractia, pozitia si raza; verdict: toate >= --min-radius;
##   2. masoara, cu raycast pe terenul real, care parte a drumului e mai JOASA
##      (golul) la fiecare 5 m — nu se ghiceste din brief, se citeste;
##   3. tipareste curba autobuzului (PackedVector3Array, coordonate de lume =
##      locale ale pistei), de SUS in jos, pe DREAPTA LUI (jumatatea din
##      stanga urcatorului), cu capetele in afara drumului. Se lipeste in
##      Track15.tscn ca `curve` al nodului BusHazard; iesirea spre exterior la
##      ace o face `apex_outer_m` la rulare, nu curba. Lungimea si durata
##      coborarii la `--speed` se raporteaza, ca `period` sa se aleaga peste.
##
##      De ce „dreapta lui" si nu „jumatatea dinspre gol": masurat (pasul 2),
##      terenul de langa serpentine e aproape plat — caderi de 0-5 m la 10 m
##      lateral, cu partea mai joasa schimbandu-se de la o dreapta la alta —
##      deci nu exista un gol pe care sa-l tii. Iar pe un drum cu ace, orice
##      regula „aceeasi parte fizica pe toate dreptele" duce la o traversare a
##      benzii celuilalt la fiecare ac; „fiecare pe dreapta lui" e singura
##      fara traversari, si e ce fac autobuzele reale.
##
## De ce generator si nu gizmo: curba autobuzului are ~100 de puncte care
## depind de axa, de latimea drumului si de partea golului; desenata de mana
## ar ramane in urma la prima ajustare a traseului. Se regenereaza cu o
## rulare si se lipeste.
##
## Sensul „exteriorului" e derivat, nu ghicit (memoria rotatii-in-builder-
## semnul): unghiul cu semn dintre doua coarde consecutive, fata de UP, in
## sensul de URCARE al pistei; pentru autobuz (care coboara) exteriorul e
## acelasi curb fizic, doar ca in sensul lui e pe partea cealalta.

const TRACK_INDEX: int = 8 # Track15 in GameState.TRACK_SCENES
const STEP_M: float = 12.0
const SAMPLE_M: float = 5.0
## Cat de departe de axa se citeste terenul pentru „care parte e golul".
const SIDE_PROBE_M: float = 10.0
## Cat de departe inainte/inapoi de un ac incepe autobuzul sa iasa spre
## exterior (m de curba). Mai mult = diagonala mai blanda.
const WIDE_RAMP_M: float = 22.0
## Peste curbura asta (1/m) se considera ac; 1/40 = raza 40 m.
const HAIRPIN_KAPPA: float = 1.0 / 40.0
## Cat de departe de marginea drumului stau capetele curbei (ascuns / reaparut).
const END_OFF_M: float = 14.0

var _failed: bool = false


func _ready() -> void:
	await get_tree().process_frame
	var f_from := 0.69
	var f_to := 0.90
	var min_radius := 13.0
	var speed := 7.0
	var bus_width := 3.6
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--from="):
			f_from = float(arg.trim_prefix("--from="))
		elif arg.begins_with("--to="):
			f_to = float(arg.trim_prefix("--to="))
		elif arg.begins_with("--min-radius="):
			min_radius = float(arg.trim_prefix("--min-radius="))
		elif arg.begins_with("--speed="):
			speed = float(arg.trim_prefix("--speed="))
		elif arg.begins_with("--bus-width="):
			bus_width = float(arg.trim_prefix("--bus-width="))
	var scene := load(GameState.TRACK_SCENES[TRACK_INDEX]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	for _f in 3:
		await get_tree().physics_frame

	var r: TrackRoute = track.routes[0]
	var n := r.count()
	var step := maxi(1, int(STEP_M / maxf(track.curve.bake_interval, 0.1)))
	print("")
	print("=== %s: acele serpentinelor in [%.3f, %.3f] (pas circumraza %d puncte ~%.0f m) ==="
		% [track.track_name, f_from, f_to, step, STEP_M])

	# --- 1. razele: minime locale ale circumrazei in fereastra ---------------
	var radii: PackedFloat32Array = PackedFloat32Array()
	radii.resize(n)
	for i in n:
		radii[i] = _circumradius(r.baked[r.wrap_index(i - step)], r.baked[i],
			r.baked[r.wrap_index(i + step)])
	var hairpins: Array[Dictionary] = []
	var i0 := int(f_from * float(n))
	var i1 := int(f_to * float(n))
	var in_turn := false
	var best_r := INF
	var best_i := -1
	for i in range(i0, i1 + 1):
		var rad := radii[i]
		if rad < 40.0:
			if not in_turn:
				in_turn = true
				best_r = INF
			if rad < best_r:
				best_r = rad
				best_i = i
		elif in_turn:
			in_turn = false
			hairpins.append({"i": best_i, "r": best_r})
	if in_turn:
		hairpins.append({"i": best_i, "r": best_r})
	for h in hairpins:
		var i: int = h.i
		var p: Vector3 = r.baked[i]
		var hw := track.width_at_index(i)
		var ok: bool = float(h.r) >= min_radius
		print("  ac la frac %.3f  (%.1f, %.1f, %.1f)  raza pe axa %.2f m  semi-latime %.1f  %s"
			% [r.frac_at(i), p.x, p.y, p.z, h.r, hw, "OK" if ok else "SUB %.0f" % min_radius])
		if not ok:
			_failed = true
	print("  ace gasite: %d" % hairpins.size())

	# --- 2. partea golului, la fiecare 5 m ------------------------------------
	var space := track.get_world_3d().direct_space_state
	var per := maxi(1, int(SAMPLE_M / maxf(track.curve.bake_interval, 0.1)))
	print("")
	print("  frac    x       y      z      R     stanga(-)  dreapta(+)  gol")
	var gol_sign: PackedFloat32Array = PackedFloat32Array()
	gol_sign.resize(n)
	for i in range(i0, i1 + 1):
		var p: Vector3 = r.baked[i]
		var side: Vector3 = r.side_at(i)
		var yl := _ground_at(space, p - side * SIDE_PROBE_M)
		var yr := _ground_at(space, p + side * SIDE_PROBE_M)
		var s := 1.0 if yr < yl else -1.0
		gol_sign[i] = s
		if (i - i0) % per == 0:
			print("  %.3f %7.1f %6.1f %7.1f %6.1f  %6.1f    %6.1f    %s"
				% [r.frac_at(i), p.x, p.y, p.z, minf(radii[i], 999.0), yl - p.y, yr - p.y,
					"dreapta" if s > 0.0 else "stanga"])

	# --- 3. curba autobuzului, de sus in jos -----------------------------------
	# Curbura CU SEMN in sensul de urcare (+ = viraj la stanga), netezita pe
	# ±STEP_M; ponderea de „ac" se intinde cu WIDE_RAMP_M inainte si dupa.
	var kappa: PackedFloat32Array = PackedFloat32Array()
	kappa.resize(n)
	for i in n:
		var a: Vector3 = r.baked[r.wrap_index(i - step)]
		var b: Vector3 = r.baked[i]
		var c: Vector3 = r.baked[r.wrap_index(i + step)]
		var t1 := c - b
		var t2 := b - a
		t1.y = 0.0
		t2.y = 0.0
		if t1.length_squared() < 0.01 or t2.length_squared() < 0.01:
			kappa[i] = 0.0
			continue
		var ang := t2.normalized().signed_angle_to(t1.normalized(), Vector3.UP)
		kappa[i] = ang / STEP_M
	var ramp := maxi(1, int(WIDE_RAMP_M / maxf(track.curve.bake_interval, 0.1)))
	var pts := PackedVector3Array()
	var lane_prev := 0.0
	var first_lane := 0.0
	var last_lane := 0.0
	var first_side := Vector3.ZERO
	var last_side := Vector3.ZERO
	var first_dir := Vector3.ZERO
	var last_dir := Vector3.ZERO
	var k := 0
	for i in range(i1, i0 - 1, -per):
		# Ponderea de ac: cea mai mare curbura din fereastra ±ramp, cu semn
		# al celei mai apropiate curburi mari (exteriorul ei).
		var w := 0.0
		var sgn := 0.0
		for j in range(i - ramp, i + ramp + 1):
			var kj := absf(kappa[r.wrap_index(j)])
			var wj := clampf(kj / HAIRPIN_KAPPA, 0.0, 1.0)
			# Scade liniar cu distanta pana la ramp: diagonala, nu treapta.
			wj *= 1.0 - float(absi(j - i)) / float(ramp + 1)
			if wj > w:
				w = wj
				sgn = signf(kappa[r.wrap_index(j)])
		var hw := track.width_at_index(i)
		var lane_amp := hw - bus_width * 0.5
		# Dreapta AUTOBUZULUI = stanga urcatorului = -side_at (side_at e
		# pozitiv spre dreapta in sensul de urcare). `w`/`sgn` raman
		# calculate ca sa se poata reveni la „exteriorul acului in curba".
		var lane := -lane_amp
		if w > 0.0 and sgn != 0.0:
			pass
		var p: Vector3 = r.baked[i]
		var side: Vector3 = r.side_at(i)
		var dir: Vector3 = (r.baked[r.wrap_index(i - 1)] - r.baked[r.wrap_index(i + 1)])
		dir.y = 0.0
		dir = dir.normalized() # sensul de COBORARE
		var q := p + side * lane
		pts.append(q)
		if k == 0:
			first_lane = lane
			first_side = side
			first_dir = dir
		last_lane = lane
		last_side = side
		last_dir = dir
		lane_prev = lane
		k += 1
	# Capetele: in afara drumului, pe prelungirea benzii, la END_OFF_M de margine.
	var hw0 := track.width_at_index(i1)
	var hw1 := track.width_at_index(i0)
	var start := pts[0] - first_dir * (END_OFF_M + 6.0) + first_side * signf(first_lane) * (hw0 - absf(first_lane) + END_OFF_M * 0.5)
	var stop := pts[pts.size() - 1] + last_dir * (END_OFF_M + 6.0) + last_side * signf(last_lane) * (hw1 - absf(last_lane) + END_OFF_M * 0.5)
	pts.insert(0, start)
	pts.append(stop)
	var length := 0.0
	for j in range(1, pts.size()):
		length += pts[j].distance_to(pts[j - 1])
	print("")
	print("  curba autobuzului: %d puncte, %.0f m, coborare %.1f s la %.1f m/s (period trebuie sa fie peste)"
		% [pts.size(), length, length / speed, speed])
	print("  primul punct (reapare, ascuns): (%.1f, %.1f, %.1f); ultimul: (%.1f, %.1f, %.1f)"
		% [start.x, start.y, start.z, stop.x, stop.y, stop.z])
	# Formatul .tscn: (in, out, pos) x N, cu manere zero, si point_count.
	var flat := PackedFloat32Array()
	for q in pts:
		for v in [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, q.x, q.y, q.z]:
			flat.append(v)
	var parts := PackedStringArray()
	for v in flat:
		parts.append("%s" % [snappedf(v, 0.01)])
	print("")
	print("[sub_resource type=\"Curve3D\" id=\"Curve3D_autobuz\"]")
	print("_data = {")
	print("\"points\": PackedVector3Array(%s)," % ", ".join(parts))
	var tilts := PackedStringArray()
	for _q in pts:
		tilts.append("0")
	print("\"tilts\": PackedFloat32Array(%s)" % ", ".join(tilts))
	print("}")
	print("point_count = %d" % pts.size())
	print("")
	print("VERDICT: %s" % ("PROBLEMA — ac sub raza minima" if _failed else "OK"))
	track.queue_free()
	await get_tree().process_frame
	get_tree().quit(1 if _failed else 0)


func _ground_at(space: PhysicsDirectSpaceState3D, p: Vector3) -> float:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 40.0, p - Vector3.UP * 120.0)
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return -999.0
	return (hit.position as Vector3).y


func _circumradius(a: Vector3, b: Vector3, c: Vector3) -> float:
	var p := Vector2(a.x, a.z)
	var q := Vector2(b.x, b.z)
	var s := Vector2(c.x, c.z)
	var ab := p.distance_to(q)
	var bc := q.distance_to(s)
	var ca := s.distance_to(p)
	var area2 := absf((q.x - p.x) * (s.y - p.y) - (s.x - p.x) * (q.y - p.y))
	if area2 < 1e-6:
		return INF
	return ab * bc * ca / (2.0 * area2)
