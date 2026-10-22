extends Node
## Bordura care scutura suspensia (docs/feel_checklist.md, `surface-voice`,
## partea de fizica).
##
## Contractele, pe o pista reala cu borduri (Race.tscn):
##   1. `Track.kerb_at` coincide cu geometria: un punct pe banda dintre
##      latime-KERB_WIDTH si latime, pe un index cu bordura, e bordura; pe axa
##      soselei si dincolo de margine nu e.
##   2. O masina tinuta pe banda bordurii la 25 m/s: `on_kerb` e adevarat in
##      cea mai mare parte a timpului, iar compresia arcurilor sare intre cadre de cel putin
##      1.6 ori mai mult decat cu `kerb_rumble_enabled = false`.
##   3. Oprita pe bordura (1 m/s): fara scuturat (variatia ramane sub dubla
##      celei de pe drum). Pe axa soselei: `on_kerb` fals, fara scuturat.
## Sabotaj (trebuie sa PICE): `-- --off` pune kerb_rumble_enabled = false.
##
## Ruleaza CA SCENA (alege o pista cu borduri; implicit cauta una):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeKerb.tscn -- [--track=N]

const STEP: float = 1.0 / 60.0
const RACE_SCENE := "res://scenes/race/Race.tscn"

var _failed: bool = false
var _off: bool = false


## Consumatorii lui `on_kerb` (sunet + camera), numarati in _ride: cadre cu
## zdranganeala pornita in CarAudio si cadre cu pragul de trauma al camerei.
var _audio_on: float = 0.0
var _cam_on: float = 0.0


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _ready() -> void:
	_off = "--off" in OS.get_cmdline_user_args()
	var idx := -1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	print("")
	print("=== Bordura scutura suspensia ===")
	if _off:
		print("  (SABOTAJ: kerb_rumble_enabled = false)")
	var candidates: Array[int] = [2, 0, 1, 3, 5, 7, 8, 9]
	if idx >= 0:
		candidates = [idx]
	var measured := false
	for t in candidates:
		var ok := await _try_track(t)
		if ok:
			measured = true
			break
	# Zero masuratori nu e succes (garda-verde-pe-zero-masuratori).
	_check(measured, "o pista cu borduri a fost gasita si masurata")
	print("")
	print("VERDICT: ", "PROBLEMA" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)


func _try_track(t: int) -> bool:
	GameState.selected_track = t
	GameState.champ_active = false
	GameState.total_laps = 99
	var race := (load(RACE_SCENE) as PackedScene).instantiate() as Race
	add_child(race)
	var track: Track = race.track
	var spots: Array[int] = []
	for i in track._kerb_idx.size():
		if track._kerb_idx[i] == 1 and i % 2 == 0:
			spots.append(i)
	print("-- pista %d (%s): %d indici cu bordura --" % [t, track.track_name, spots.size()])
	if spots.size() < 30:
		race.queue_free()
		await get_tree().physics_frame
		return false
	var guard := 0
	while race.state != Race.State.RUNNING and guard < 1800:
		await get_tree().physics_frame
		guard += 1
	await _test_geometry(track, spots)
	await _test_ride(race, track, spots)
	race.queue_free()
	await get_tree().physics_frame
	return true


func _test_geometry(track: Track, spots: Array[int]) -> void:
	print("")
	print("-- 1. kerb_at coincide cu banda --")
	var bad := 0
	for k in 20:
		var i := spots[(k * spots.size()) / 20]
		var w := track.width_at_index(i)
		var side := track._side_at(i)
		var base := track.baked[i]
		var on := track.kerb_at(i, base + side * (w - 0.4))
		var on_neg := track.kerb_at(i, base - side * (w - 0.4))
		var mid := track.kerb_at(i, base)
		var out := track.kerb_at(i, base + side * (w + 0.5))
		if not (on and on_neg) or mid or out:
			bad += 1
	_check(bad == 0, "20 puncte esantion: banda da, axa si exteriorul nu (gresite: %d)" % bad)


class ScriptDriver:
	extends CarController
	func get_throttle() -> float:
		return 0.0


## Tine masina pe linia de lateral dorit pe un tronson cu borduri (viteza data
## de-a lungul tangentei), si intoarce deviatia standard a compresiei medii a
## arcurilor + fractia de cadre cu on_kerb.
func _ride(race: Race, track: Track, spots: Array[int], lat_from_edge: float,
		speed: float, rumble: bool) -> Vector2:
	var car := race.player
	car.set_controller(ScriptDriver.new())
	car.kerb_rumble_enabled = rumble and not _off
	var start := spots[spots.size() / 3]
	# Cel mai lung tronson continuu de borduri de la start.
	var i0 := start
	var side := track._side_at(i0)
	var w := track.width_at_index(i0)
	var pos: Vector3 = track.baked[i0] + side * (w - lat_from_edge)
	var tang: Vector3 = (track.baked[(i0 + 3) % track.baked.size()] - track.baked[i0])
	tang.y = 0.0
	tang = tang.normalized()
	car.global_transform = Transform3D(Basis.looking_at(tang, Vector3.UP), pos + Vector3.UP * 0.6)
	car.linear_velocity = tang * speed
	car.angular_velocity = Vector3.ZERO
	car.race_active = true
	car.road_index = i0 # indexul masinii e cautat local: il asezam noi
	car.last_safe_index = i0
	var samples: Array = []
	var on_frames := 0
	var frames := 0
	var audio_frames := 0
	var cam_frames := 0
	# ImpactFeel tremura camera doar in cursa pornita.
	race.state = Race.State.RUNNING
	for f in 90:
		# Menti viteza pe tangenta locala si atrage spre linia de lateral dorita.
		var idx := track.closest_index(car.road_index, car.global_position)
		var s2 := track._side_at(idx)
		var w2 := track.width_at_index(idx)
		var t2: Vector3 = (track.baked[(idx + 3) % track.baked.size()] - track.baked[idx])
		t2.y = 0.0
		t2 = t2.normalized()
		var lat := (car.global_position - track.baked[idx]).dot(s2)
		var want := w2 - lat_from_edge
		var v := t2 * speed + s2 * clampf((want - lat) * 6.0, -3.0, 3.0)
		v.y = car.linear_velocity.y
		car.linear_velocity = v
		car.rotation.y = atan2(-t2.x, -t2.z) # botul pe tangenta, ca pe un viraj real
		await get_tree().physics_frame
		if f >= 20:
			frames += 1
			if car.on_kerb:
				on_frames += 1
			var au: Node = car.get(&"_audio")
			if au != null and au.get(&"on_kerb") == true:
				audio_frames += 1
			if race.camera != null and race.camera.trauma >= 0.1:
				cam_frames += 1
			# Cea mai agitata roata: bordura nu o loveste pe fiecare in acelasi moment.
			samples.append(car.wheel_compression.duplicate())
	# Variatia RAPIDA: abaterea patratica medie a diferentei de la un cadru la
	# altul (panta drumului muta media, nu intra aici).
	var worst := 0.0
	for wi in 4:
		var sq := 0.0
		for k in range(1, samples.size()):
			var d: float = (samples[k] as Array)[wi] - (samples[k - 1] as Array)[wi]
			sq += d * d
		worst = maxf(worst, sqrt(sq / float(maxi(samples.size() - 1, 1))))
	_audio_on = float(audio_frames) / float(maxi(frames, 1))
	_cam_on = float(cam_frames) / float(maxi(frames, 1))
	if race.camera != null:
		race.camera.trauma = 0.0
	return Vector2(worst, float(on_frames) / float(maxi(frames, 1)))


func _test_ride(race: Race, track: Track, spots: Array[int]) -> void:
	print("")
	print("-- 2. pe bordura la 25 m/s --")
	var on := await _ride(race, track, spots, 0.45, 25.0, true)
	var on_audio := _audio_on
	var on_cam := _cam_on
	var off := await _ride(race, track, spots, 0.45, 25.0, false)
	print("  cu scuturat: salt/cadru %.4f m, pe bordura %.0f%% din cadre; fara: salt/cadru %.4f m"
		% [on.x, on.y * 100.0, off.x])
	_check(on.y >= 0.6, "on_kerb adevarat in >= 60% din cadre")
	_check(on.x >= 1.6 * maxf(off.x, 0.0015), "saltul compresiei intre cadre >= 1.6x fata de fara scuturat")
	print("  zdranganeala in sunet %.0f%% din cadre, camera tremura %.0f%%"
		% [on_audio * 100.0, on_cam * 100.0])
	_check(on_audio >= 0.6 * on.y, "sunetul de bordura urmeaza on_kerb (CarAudio)")
	_check(on_cam >= 0.6 * on.y, "camera tremura pe bordura (ImpactFeel)")
	print("")
	print("-- 3. oprita pe bordura si pe axa soselei --")
	var slow := await _ride(race, track, spots, 0.45, 1.0, true)
	var road := await _ride(race, track, spots, track.width_at_index(spots[spots.size() / 3]), 25.0, true)
	print("  1 m/s pe bordura: salt/cadru %.4f m; 25 m/s pe axa: salt/cadru %.4f m, pe bordura %.0f%%"
		% [slow.x, road.x, road.y * 100.0])
	_check(slow.x < 0.5 * on.x, "oprita pe bordura nu scutura (< jumatate din 25 m/s)")
	_check(road.y < 0.05, "pe axa soselei on_kerb ramane fals")
	print("  pe axa: sunet %.0f%%, camera %.0f%%" % [_audio_on * 100.0, _cam_on * 100.0])
	_check(_audio_on < 0.05 and _cam_on < 0.05, "pe axa: fara zdranganeala si fara tremur")
