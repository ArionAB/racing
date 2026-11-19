extends Node
## GARDA TEMPLULUI PRIN CARE SE TRECE (Angkor, Track24, zona B — 19 nov 2026).
##
## Cererea dezvoltatorului: „for a map that the main attraction is the temple we are not even
## going through the temple ... i want a hazard in the temple and to have a chunk of the map
## driving through the temple”. Garda tine in viata exact cele doua lucruri cerute, pe scena reala:
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeAngkorTemplu.tscn
##   ... -- --sabotaj=<nume>     (fiecare contract are sabotajul lui, care trebuie sa-l pice)
##
## Statica (geometrie + noduri), fara cursa: cursa e ProbeRace `--angkor`.
##
##   (a) PRIN TEMPLU [sabotaj: ocol]: axa soselei sta >= 85 m, legat, INAUNTRUL masivului
##       (|x| <= 52 si |z| <= 52 fata de turnul central din origine) si trece la < 15 m de axa
##       turnului. Traseul vechi (arcul de pe gazon, la 55 m de turnuri) avea 0 m.
##   (b) INCHIS [sabotaj: tub]: pe toata portiunea, raze din axa gasesc corpul tubului deasupra
##       (tavan) si pe ambele laturi (pereti), la cel mult latimea soselei + 0,6 m: nu exista
##       iesire laterala din templu si nici tavan lipsa.
##   (c) O SINGURA PIELE [sabotaj: piele]: exact unul dintre tub si model se deseneaza. Cu modelul
##       `DecorManual/AngkorWat` in scena, tubul e ascuns (`tube_visible = false`) si modelul nu
##       are corp (`coliziune = "none"`): tot ce se loveste e tubul, tot ce se vede e modelul.
##       Fara model in scena garda PICA: templul fara interior nu se livreaza.
##   (d) CAMERA SI INTUNERICUL [sabotaj: camera]: zona de camera a tubului acopera portiunea, cu
##       tavanul declarat (memoria `camera-zone-tavan-per-sala`) si cu intuneric > 0.
##   (e) LATIMEA [sabotaj: latime]: sala are >= 15 m la mijlocul arcului si portalurile >= 11,5 m
##       (gramada din turul 1 ajunge aici la ~9 s de la start).
##   (f) GONGURILE [sabotaj: gong]: >= 3 `GongHazard` in `Hazarduri`, toate in tub, cu discul
##       intreg pe carosabil (nu in perete), pivotul sub tavan, orientate pe sensul de mers
##       (-Z local la < 15 grade de tangenta) si cu o TRECERE CURATA pe fiecare rand: un gol de
##       >= 3,2 m intre discuri sau intre disc si perete (hazard care se poate citi, nu zid).

const MASSIF_HALF: float = 52.0
const INSIDE_MIN_M: float = 85.0
const TOWER_PASS_MAX_M: float = 15.0
const HALL_MIN_W: float = 15.0
const PORTAL_MIN_W: float = 11.5
const GONG_MIN: int = 3
const GONG_ROW_M: float = 4.0        # gongurile la mai putin de atat pe axa sunt acelasi rand
const CLEAN_GAP_M: float = 3.2
const ANGLE_MAX_DEG: float = 15.0

var _fails: Array[String] = []
var _sabotage: String = ""


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--sabotaj="):
			_sabotage = arg.trim_prefix("--sabotaj=")
	await get_tree().process_frame
	var scene := load("res://scenes/tracks/Track24.tscn") as PackedScene
	var track := scene.instantiate() as Track
	var sig := track.get_node_or_null("Hazarduri/TunelTemplu") as TunnelSignalHazard
	if _sabotage == "tub" and sig != null:
		sig.tunnel_length = 40.0            # tubul se termina in sala: jumatate de templu fara pereti
	if _sabotage == "piele" and sig != null:
		sig.tube_visible = true             # tubul desenat PESTE model
	if _sabotage == "gong":
		for g in _gongs(track):
			(g as Node3D).position += (g as Node3D).transform.basis.x * 9.0   # in perete
			break
	get_tree().root.add_child(track)
	for _k in 6:
		await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	print("=== ANGKOR, templul prin care se trece%s ===" % (
		" [SABOTAJ: %s]" % _sabotage if _sabotage != "" else ""))
	var span := _inside_span(track)
	_check_through(track, span)
	_check_enclosed(track, span)
	_check_skin(track, sig)
	_check_camera(track, span)
	_check_width(track, span)
	_check_gongs(track, sig)
	print("")
	if _fails.is_empty():
		print("VERDICT: OK")
		get_tree().quit(0)
	else:
		for f in _fails:
			print("  ✘ " + f)
		print("VERDICT: PROBLEMA (%d)" % _fails.size())
		get_tree().quit(1)


func _fail(msg: String) -> void:
	_fails.append(msg)


func _gongs(track: Node) -> Array[Node]:
	var out: Array[Node] = []
	var hz := track.get_node_or_null("Hazarduri")
	if hz == null:
		return out
	for c in hz.get_children():
		var sc := c.get_script() as Script
		if sc != null and sc.resource_path.ends_with("gong_hazard.gd"):
			out.append(c)
	return out


## Cel mai lung sir LEGAT de puncte coapte din masiv: [i0, i1] (indici pe ruta 0) si lungimea.
func _inside_span(track: Track) -> Dictionary:
	var r := track.routes[0]
	var n := r.count()
	var best := {"i0": 0, "i1": -1, "m": 0.0, "near": INF}
	var cur0 := -1
	var cur_m := 0.0
	var cur_near := INF
	for i in n:
		var p: Vector3 = r.baked[i]
		var inside := absf(p.x) <= MASSIF_HALF and absf(p.z) <= MASSIF_HALF
		if _sabotage == "ocol":
			inside = false
		if inside:
			if cur0 < 0:
				cur0 = i
				cur_m = 0.0
				cur_near = INF
			else:
				cur_m += r.baked[i].distance_to(r.baked[i - 1])
			cur_near = minf(cur_near, Vector2(p.x, p.z).length())
			if cur_m > float(best["m"]):
				best = {"i0": cur0, "i1": i, "m": cur_m, "near": cur_near}
		else:
			cur0 = -1
	return best


func _check_through(_track: Track, span: Dictionary) -> void:
	var m := float(span["m"])
	var near := float(span["near"])
	print("(a) prin templu: %.1f m de axa in masiv (>= %.0f), la %.1f m de axa turnului central (< %.0f)" % [
		m, INSIDE_MIN_M, near, TOWER_PASS_MAX_M])
	if m < INSIDE_MIN_M:
		_fail("(a) soseaua sta doar %.1f m in templu (cerut >= %.0f)" % [m, INSIDE_MIN_M])
	elif near > TOWER_PASS_MAX_M:
		_fail("(a) soseaua trece la %.1f m de turnul central (cerut < %.0f)" % [near, TOWER_PASS_MAX_M])


func _ray(track: Track, from: Vector3, to: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collision_mask = 0xFFFFFFFF
	q.hit_back_faces = true
	return track.get_world_3d().direct_space_state.intersect_ray(q)


func _check_enclosed(track: Track, span: Dictionary) -> void:
	var r := track.routes[0]
	var i0 := int(span["i0"])
	var i1 := int(span["i1"])
	if i1 <= i0:
		_fail("(b) nu exista portiune in templu de verificat")
		return
	var open_top := 0
	var open_side := 0
	var checked := 0
	# 6 m inauntru de la fiecare fatada: capacele portalurilor nu sunt pereti laterali.
	var skip_m := 6.0
	var acc := 0.0
	var total := float(span["m"])
	for i in range(i0 + 1, i1):
		acc += r.baked[i].distance_to(r.baked[i - 1])
		if acc < skip_m or acc > total - skip_m:
			continue
		checked += 1
		var p: Vector3 = track.to_global(r.baked[i])
		var side: Vector3 = r.side_at(i)
		var hw := track.width_at_index(i)
		var up := _ray(track, p + Vector3.UP * 1.0, p + Vector3.UP * 30.0)
		if up.is_empty() or not String((up["collider"] as Node).name).begins_with("TunnelBore"):
			open_top += 1
		for sgn: float in [-1.0, 1.0]:
			var a := p + Vector3.UP * 1.2
			var hit := _ray(track, a, a + side * sgn * (hw + 0.6))
			if hit.is_empty():
				open_side += 1
	print("(b) inchis: %d puncte verificate, fara tavan %d, fara perete %d" % [checked, open_top, open_side])
	if checked < 20:
		_fail("(b) prea putine puncte in templu (%d)" % checked)
	if open_top > 0:
		_fail("(b) %d puncte din templu n-au tavanul tubului deasupra" % open_top)
	if open_side > 0:
		_fail("(b) %d raze laterale ies din templu fara sa loveasca un perete" % open_side)


func _check_skin(track: Track, sig: TunnelSignalHazard) -> void:
	var model := track.get_node_or_null("DecorManual/AngkorWat")
	if sig == null:
		_fail("(c) lipseste Hazarduri/TunelTemplu")
		return
	var bore_drawn := false
	for c in track.get_children():
		var mi := c as MeshInstance3D
		if mi == null or mi.material_override == null:
			continue
		# Tubul desenat e un MeshInstance3D direct sub pista, cu AABB-ul pe masiv si inalt cat sala.
		var bb := mi.get_aabb()
		if bb.size.y > 15.0 and bb.size.x > 60.0 and bb.size.x < 90.0 and absf(bb.get_center().x + 14.0) < 12.0:
			bore_drawn = true
	var col := String(model.get_meta("coliziune", "")) if model != null else ""
	print("(c) piele: model in scena %s (coliziune \"%s\"), tub desenat %s, tube_visible %s" % [
		model != null, col, bore_drawn, sig.tube_visible])
	if model == null:
		_fail("(c) modelul templului (DecorManual/AngkorWat) lipseste din scena: templul n-are interior")
		return
	if col != "none":
		_fail("(c) modelul templului are corp (\"%s\"): corpul e doar tubul" % col)
	if sig.tube_visible or bore_drawn:
		_fail("(c) tubul se deseneaza peste model (tube_visible trebuie false)")


func _check_camera(track: Track, span: Dictionary) -> void:
	var cz: CameraZone = null
	for c in track.get_children():
		if c is CameraZone and String(c.name).begins_with("TunnelCameraZone"):
			# cea a templului: zona cu fractiile in B (0.05-0.14)
			if (c as CameraZone).frac_from > 0.05 and (c as CameraZone).frac_from < 0.14:
				cz = c as CameraZone
	if _sabotage == "camera" and cz != null:
		cz.darkness = 0.0
	if cz == null:
		_fail("(d) nu exista zona de camera a tubului pe B")
		return
	var f0 := track.frac_at(int(span["i0"]))
	var f1 := track.frac_at(int(span["i1"]))
	print("(d) camera: zona %.3f-%.3f peste templul %.3f-%.3f, tavan %.1f m, intuneric %.2f" % [
		cz.frac_from, cz.frac_to, f0, f1, cz.ceiling, cz.darkness])
	if cz.frac_from > f0 + 0.004 or cz.frac_to < f1 - 0.004:
		_fail("(d) zona de camera nu acopera templul")
	if cz.darkness <= 0.0:
		_fail("(d) templul n-are intuneric (darkness 0)")
	if cz.ceiling > 12.0:
		_fail("(d) tavanul declarat (%.1f m) nu e al navei" % cz.ceiling)


func _check_width(track: Track, span: Dictionary) -> void:
	var i0 := int(span["i0"])
	var i1 := int(span["i1"])
	if i1 <= i0:
		return
	var w_in := 2.0 * track.width_at_index(i0)
	var w_out := 2.0 * track.width_at_index(i1)
	var w_mid := 2.0 * track.width_at_index((i0 + i1) / 2)
	if _sabotage == "latime":
		w_mid = 9.0
	print("(e) latime: portal intrare %.1f m, mijlocul salii %.1f m, portal iesire %.1f m" % [w_in, w_mid, w_out])
	if w_mid < HALL_MIN_W:
		_fail("(e) sala are %.1f m (cerut >= %.1f)" % [w_mid, HALL_MIN_W])
	if w_in < PORTAL_MIN_W or w_out < PORTAL_MIN_W:
		_fail("(e) un portal are sub %.1f m (%.1f / %.1f)" % [PORTAL_MIN_W, w_in, w_out])


func _check_gongs(track: Track, sig: TunnelSignalHazard) -> void:
	var gongs := _gongs(track)
	print("(f) gonguri: %d (>= %d)" % [gongs.size(), GONG_MIN])
	if gongs.size() < GONG_MIN:
		_fail("(f) doar %d gonguri in templu (cerut >= %d)" % [gongs.size(), GONG_MIN])
		return
	var r := track.routes[0]
	var rows: Array = []   # [{m, items: [[lat, radius]], hw}]
	for g in gongs:
		var n3 := g as Node3D
		var p := track.to_local(n3.global_position)
		var i: int = track.call("_closest_baked_index", p)
		var side: Vector3 = r.side_at(i)
		var lat := (p - r.baked[i]).dot(side)
		var hw := track.width_at_index(i)
		var radius := float(n3.get("radius"))
		var hang := float(n3.get("hang_height"))
		var tan := (r.baked[r.wrap_index(i + 1)] - r.baked[r.wrap_index(i - 1)]).normalized()
		var fwd := -n3.global_transform.basis.z.normalized()
		var ang := rad_to_deg(acos(clampf(fwd.dot(tan), -1.0, 1.0)))
		var up := _ray(track, n3.global_position + Vector3.UP * 0.5, n3.global_position + Vector3.UP * 40.0)
		var ceil_h := (float(up["position"].y) - n3.global_position.y) if not up.is_empty() else -1.0
		var m := 0.0
		if sig != null:
			m = n3.global_position.distance_to(sig.global_position)
		print("    %s: lateral %+.2f m (carosabil +-%.2f), raza %.2f, pivot %.1f m, tavan %.1f m, unghi %.1f grade" % [
			n3.name, lat, hw, radius, hang, ceil_h, ang])
		if ceil_h < 0.0:
			_fail("(f) %s nu e in tub (fara tavan deasupra)" % n3.name)
		elif hang > ceil_h - 0.2:
			_fail("(f) %s: pivotul (%.1f m) e in tavan (%.1f m)" % [n3.name, hang, ceil_h])
		if absf(lat) + radius > hw - 0.1:
			_fail("(f) %s: discul iese din carosabil (lateral %+.2f, raza %.2f, semilatime %.2f)" % [
				n3.name, lat, radius, hw])
		if ang > ANGLE_MAX_DEG:
			_fail("(f) %s: -Z local la %.1f grade de sensul de mers" % [n3.name, ang])
		var placed := false
		for row in rows:
			if absf(float(row["i"]) - float(i)) * 2.0 < GONG_ROW_M * 1.2 and \
					r.baked[i].distance_to(r.baked[int(row["i"])]) < GONG_ROW_M:
				(row["items"] as Array).append([lat, radius])
				placed = true
				break
		if not placed:
			rows.append({"i": i, "hw": hw, "items": [[lat, radius]], "m": m})
	for row in rows:
		var hw := float(row["hw"])
		var items: Array = row["items"]
		items.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
		var edge := -hw
		var best := 0.0
		for it in items:
			best = maxf(best, (float(it[0]) - float(it[1])) - edge)
			edge = float(it[0]) + float(it[1])
		best = maxf(best, hw - edge)
		print("    rand la %.0f m de portal: %d gong(uri), cea mai lata trecere curata %.1f m" % [
			float(row["m"]), items.size(), best])
		if best < CLEAN_GAP_M:
			_fail("(f) randul de la %.0f m n-are trecere curata (%.1f m, cerut >= %.1f)" % [
				float(row["m"]), best, CLEAN_GAP_M])
