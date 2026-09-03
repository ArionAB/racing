extends Node
## USA DE PIATRA (Cappadocia POI F): are starea „inchis = zid"? Masoara pe
## hazardul REAL din scena, nu pe cifrele din cod.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeDoor.tscn -- --track=6
##
## Ce raporteaza, si de ce fiecare:
##   (a) ciclul — lungimea lui, cat sta inchisa, cat sta deschisa, cat din
##       timp e (macar partial) pe banda. Brieful cere ~23 s si un zid, nu o
##       matura: inainte de modul USA, ciclul era 13.9 s si pe banda 5%.
##   (b) geometria capetelor — in nisa piatra trebuie sa fie COMPLET in afara
##       asfaltului, pe axa trebuie sa fie centrata (|lat| < 0.1 m).
##   (c) zidul, prin fizica — cu usa inchisa, GABARITUL MASINII (cutia de
##       coliziune din Car, 2.2 x 1.0 x 3.8 m) e plimbat lateral peste toata
##       banda cu `intersect_shape`: in fiecare pozitie trebuie sa loveasca
##       usa. Cu usa deschisa, in nicio pozitie. Nu grila de puncte: o
##       piatra rotunda e mai ingusta la sol (la 0.3 m acopera doar ±0.9 m),
##       si un punct la 1.0 m gaseste „gaura" prin care nicio masina nu
##       incape. Testul e „poate trece o masina?", nu „e solid punctul asta?".
##   (d) `door_blocks_in` (ce citeste AI-ul) fata de geometria reala (b) pe tot
##       ciclul: cele doua trebuie sa fie de acord, altfel pilotul decide pe
##       alta usa decat cea din lume.
##   (e) ocolul: la cati metri inainte de usa se despica banda si daca
##       `AIController.DOOR_REACH_M` acopera distanta aia.
##
## Verdict: FAIL daca (a) nu are stare inchisa >= 3 s, (b) capatul din nisa
## atinge asfaltul, (c) zidul are gauri la inaltimea barei, sau (d) nu sunt de
## acord.

const CAR_SCENE: String = "res://scenes/cars/Car.tscn"

var _track_index: int = 6
var _fail: int = 0

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			_track_index = int(arg.trim_prefix("--track="))
	var resolved := GameState.resolve_track_index(_track_index)
	if resolved < 0:
		push_error("probe_door: --track=%d invalid" % _track_index)
		get_tree().quit(2)
		return
	var track := (load(GameState.TRACK_SCENES[resolved]) as PackedScene).instantiate() as Track
	add_child(track)
	for i in 3:
		await get_tree().physics_frame
	var door: SlidingHazard = null
	for child in track.get_children():
		var h := child as SlidingHazard
		if h != null and h.motion == SlidingHazard.Motion.USA:
			door = h
			break
	if door == null:
		print("probe_door: nicio usa (Motion.USA) pe pista. VERDICT: FAIL")
		get_tree().quit(1)
		return
	await _measure(track, door)
	print("VERDICT: %s" % ("FAIL (%d)" % _fail if _fail > 0 else "OK"))
	get_tree().quit(1 if _fail > 0 else 0)

func _check(ok: bool, what: String) -> void:
	print("  [%s] %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fail += 1

func _measure(track: Track, door: SlidingHazard) -> void:
	var amp := door.travel.length()
	var side := door.travel.normalized()
	var hw := door.road_half_width
	var r: float = door.get("_half_extent")
	var cycle := door.door_cycle()
	print("usa la %s, cursa %.2f m pe %s, semilatime %.2f, raza %.2f, perioada %.2f" % [
		door.center, amp, side, hw, r, door.period])
	# Orientarea: -Z al corpului trebuie sa fie in lungul soselei (perpendicular
	# pe cursa), ca fata discului sa fie spre masina.
	var fwd := -door.global_transform.basis.z
	var along_travel := absf(fwd.dot(side))
	_check(along_travel < 0.1, "fata discului spre sosea (|-Z . side| = %.2f, vrem ~0)" % along_travel)

	# (a) + (d): ciclul, pe ceasul hazardului.
	var dt := 0.05
	# Doua cicluri, ca starea inchisa sa nu fie taiata de punctul de start.
	var n := int(2.0 * cycle / dt)
	var on_lane := 0
	var closed := 0
	var open_clear := 0
	var disagree := 0
	var min_off := INF
	var max_off := -INF
	var longest_closed := 0.0
	var run := 0.0
	var t0: float = door.get("_time")
	for i in n:
		var t := t0 + float(i) * dt
		var off: float = door.call("_offset_at", t)
		min_off = minf(min_off, off)
		max_off = maxf(max_off, off)
		var edge := off * amp + r
		var geom_blocks := edge > -hw
		if geom_blocks:
			on_lane += 1
		if absf(off) < 0.001:
			closed += 1
			run += dt
			longest_closed = maxf(longest_closed, run)
		else:
			run = 0.0
		if absf(off + 1.0) < 0.001:
			open_clear += 1
		if door.door_blocks_in(float(i) * dt) != geom_blocks:
			disagree += 1
	print("(a) ciclu %.1f s: inchisa (pe axa) %.1f s, deschisa (in nisa) %.1f s, pe banda %.0f%% din timp, cea mai lunga stare inchisa %.1f s" % [
		cycle, float(closed) * dt * 0.5, float(open_clear) * dt * 0.5, 100.0 * float(on_lane) / float(n), longest_closed])
	_check(longest_closed >= 3.0, "stare inchisa continua >= 3 s")
	_check(absf(cycle - 23.0) < 4.0, "ciclu ~23 s (brief)")
	_check(disagree == 0, "(d) door_blocks_in de acord cu geometria pe tot ciclul (%d dezacorduri)" % disagree)
	# (b) capetele.
	var niche_edge := min_off * amp + r
	var axis_lat := max_off * amp
	print("(b) capete: offset %.2f..%.2f; in nisa marginea pietrei la %.2f m de axa (asfalt pana la %.2f); pe axa |lat| = %.2f" % [
		min_off, max_off, -niche_edge, hw, absf(axis_lat)])
	_check(niche_edge < -hw + 0.01, "in nisa piatra e complet in afara asfaltului")
	_check(absf(axis_lat) < 0.1, "inchisa = centrata pe axa")

	# (c) zidul prin fizica: gabaritul masinii plimbat lateral, usa inchisa
	# apoi deschisa. Cutia e cea din Car (2.2 x 1.0 x 3.8), asezata cu
	# garda la sol ~0.25 m si cu lungimea in lungul soselei.
	var space := get_viewport().world_3d.direct_space_state
	var car_box := BoxShape3D.new()
	car_box.size = Vector3(2.2, 1.0, 3.8)
	var dir := side.cross(Vector3.UP).normalized()
	var basis := Basis.looking_at(-dir, Vector3.UP)
	for state in [["INCHISA", 0.70], ["DESCHISA", 0.20]]:
		door.set("_time", cycle * (float(state[1]) - door.phase))
		for i in 3:
			await get_tree().physics_frame
		var hits_door := 0
		var total := 0
		var gaps: Array = []
		var lat := -(hw - car_box.size.x * 0.5)
		while lat <= hw - car_box.size.x * 0.5 + 0.001:
			total += 1
			var params := PhysicsShapeQueryParameters3D.new()
			params.shape = car_box
			params.transform = Transform3D(basis, door.center + side * lat + Vector3.UP * 0.75)
			params.collision_mask = 0xFFFFFFFF
			var hit := false
			for res in space.intersect_shape(params, 16):
				if res.get("collider") == door:
					hit = true
			if hit:
				hits_door += 1
			else:
				gaps.append("%.1f" % lat)
			lat += 0.1
		print("(c) usa %s (offset %.2f, pozitie %s): gabaritul masinii loveste usa in %d/%d pozitii laterale" % [
			state[0], door.call("_offset_at", door.get("_time")), door.global_position, hits_door, total])
		if state[0] == "INCHISA":
			_check(gaps.is_empty(), "zid: nicio pozitie laterala prin care incape o masina (libere la lat: %s)" % [gaps])
		else:
			_check(hits_door == 0, "deschisa: gabaritul nu atinge usa nicaieri pe banda")

	# (e) ocolul.
	if track.routes.size() > 1:
		var b := track.routes[1]
		var door_idx := track.closest_index_global(door.center, 0)
		var split_idx := track.closest_index_global(b.baked[0], 0)
		var n_pts := track.routes[0].count()
		var d := door_idx - split_idx
		if d < 0:
			d += n_pts
		var split_m := float(d) * track.curve.bake_interval
		print("(e) ocolul '%s' se despica la %.1f m inainte de usa (lure range %.0f m, AI reach %.0f m)" % [
			b.label, split_m, Track.BRANCH_LURE_RANGE, AIController.DOOR_REACH_M])
		_check(split_m + Track.BRANCH_LURE_RANGE * 0.5 < AIController.DOOR_REACH_M,
			"AI-ul citeste usa inainte sa treaca de despicare")
