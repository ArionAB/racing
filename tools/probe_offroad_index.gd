extends Node
## #496: dupa offroad, plafonul de viteza ramane taiat pe asfalt?
##
## Plafonul se taie cu `offroad_speed_factor` cand `Track.is_on_road(road_index)`
## e fals, iar `road_index` se urmareste LOCAL (fereastra -8..+24 in jurul celui
## precedent). Sonda plimba un punct pe tăieturi drepte peste iarba (coarda de la
## indexul i la i+k) si pe excursii laterale paralele, cu acelasi tracker ca
## masina, apoi conduce pe asfalt inca 40 de puncte si intreaba: e „pe drum"?
## Daca nu, indexul a ramas agatat si masina ar merge la 45% pana la repunere.
##   godot --headless --path . res://tools/ProbeOffroadIndex.tscn -- --track=4
##   (fara --track: toate pistele)

const STEP_M := 0.5
## Ca la Car: recautarea globala ruleaza la 0,25 s cat pari in afara drumului.
## La 30 m/s, 0,25 s = 7,5 m = 15 pasi de 0,5 m.
const REACQUIRE_EVERY := 15
## `--fara-recautare`: trackerul vechi, doar fereastra locala (linia de baza
## masurata: 134 / 10800 blocaje).
var _reacquire := true
var _tick := 0


func _ready() -> void:
	await get_tree().process_frame
	var only := -1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			only = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
		elif arg == "--fara-recautare":
			_reacquire = false
	var total_fail := 0
	var total_cases := 0
	for ti in GameState.TRACK_SCENES.size():
		if only >= 0 and ti != only:
			continue
		var track := (load(GameState.TRACK_SCENES[ti]) as PackedScene).instantiate() as Track
		get_tree().root.add_child(track)
		await get_tree().process_frame
		await get_tree().process_frame
		var res := _probe(track)
		total_fail += res.x
		total_cases += res.y
		print("[offroad-index] %-28s blocaje %d / %d" % [
			GameState.track_label(ti), res.x, res.y])
		track.queue_free()
		await get_tree().process_frame
	print("[offroad-index] TOTAL blocaje %d / %d" % [total_fail, total_cases])
	print("VERDICT: %s" % ("OK" if total_fail == 0 else "PROBLEMA"))
	get_tree().quit(0)


func _probe(track: Track) -> Vector2i:
	var r: TrackRoute = track.route_at(0)
	var n := r.baked.size()
	var fails := 0
	var cases := 0
	var printed := 0
	for s in 60:
		var i := s * n / 60
		for k in [8, 16, 30, 50]:
			for lateral in [0.0, 14.0, -14.0]:
				var j := r.wrap_index(i + k)
				var a := r.baked[i]
				var b := r.baked[j]
				if lateral != 0.0:
					a += _side(r, i) * lateral
					b += _side(r, j) * lateral
				# Pornim pe drum, la i, cu indexul corect.
				var idx := i
				var pos := r.baked[i]
				idx = _walk(track, idx, pos, a)
				pos = a
				idx = _walk(track, idx, pos, b)
				pos = b
				# Inapoi pe asfalt la j, apoi 40 de puncte pe drum.
				idx = _walk(track, idx, pos, r.baked[j])
				pos = r.baked[j]
				for m in 40:
					var nxt := r.baked[r.wrap_index(j + m + 1)]
					idx = _walk(track, idx, pos, nxt)
					pos = nxt
				cases += 1
				if not track.is_on_road(idx, pos, 0):
					fails += 1
					if printed < 6:
						printed += 1
						print("    blocat: i=%d k=%d lat=%.0f -> idx %d, real %d (%.0f m in urma)"
							% [i, k, lateral, idx, r.wrap_index(j + 40),
								float(r.wrap_index(j + 40 - idx)) * 3.0])
	return Vector2i(fails, cases)


func _walk(track: Track, idx: int, from: Vector3, to: Vector3) -> int:
	var d := from.distance_to(to)
	var steps := maxi(1, int(ceil(d / STEP_M)))
	for s in range(1, steps + 1):
		var p := from.lerp(to, float(s) / float(steps))
		idx = track.closest_index(idx, p, 0)
		_tick += 1
		if _reacquire and _tick % REACQUIRE_EVERY == 0 \
				and not track.is_on_road(idx, p, 0):
			idx = track.reacquire_index(idx, p, 0)
	return idx


func _side(r: TrackRoute, i: int) -> Vector3:
	var t := r.baked[r.wrap_index(i + 1)] - r.baked[i]
	t.y = 0.0
	return Vector3(-t.z, 0.0, t.x).normalized()
