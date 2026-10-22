extends Node
## AI care reactioneaza la lovituri (feel: ai-reacts), pe Race.tscn REAL.
##
## Verifica, pe un AI din cursa:
##   1. o lovitura tare de la o masina declanseaza clatinarea: volanul primeste un
##      termen aditiv care apare (varf > 0.15) si se STINGE (zero dupa 2 s);
##      volanul final = baza + clatinare; o lovitura slaba (sub prag) nu face nimic;
##   2. o izbitura REALA (jucatorul intra din spate cu +14 m/s) ajunge la AI prin
##      semnalul `impact` si naste ranchiuna fata de atacator;
##   3. ranchiuna apasa doar cat atacatorul e aproape si IN FATA: masina se
##      muta lateral langa el (la ~un culoar), nu apasa la 45 m, iar dupa
##      `grudge_s` uita (linia revine);
##   4. cinstea: plafonul de viteza si aderentele masinii sunt neschimbate, iar
##      cu `reacts = false` aceleasi lovituri nu fac nimic.
##
## Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeAiReact.tscn

## Pista deschisa (Monument Valley) cu portiuni lungi si line: AI-ul nu se nimereste
## intr-un hairpin sau langa un perete cand masuram reactia.
var _track_idx: int = 12

var _failed: bool = false
var _track: Track
## Indexul de ruta 0 unde incepe cea mai dreapta si plata portiune (vezi `_find_straight`).
var _straight_idx: int = 0


func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true


func _frames(seconds: float) -> void:
	for _i in int(round(seconds * 60.0)):
		await get_tree().physics_frame


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("")
	print("=== AI care reactioneaza ===")
	GameState.total_laps = 99
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--track="):
			_track_idx = int(a.substr(8))
	GameState.selected_track = _track_idx
	var race := (load("res://scenes/race/Race.tscn") as PackedScene).instantiate()
	add_child(race)
	var guard := 0
	while race.get("position_watch") == null and guard < 1500:
		await get_tree().process_frame
		guard += 1
	while race.state != race.State.RUNNING and guard < 3000:
		await get_tree().physics_frame
		guard += 1
	_check(race.state == race.State.RUNNING, "cursa a pornit")
	var player: Car = race.player
	_track = race.track
	_straight_idx = _find_straight()
	# Restul plutonului ramane inghetat pe grila: masuram UN AI, fara trafic care sa-l
	# loveasca din intamplare (o lovitura de la altcineva ar strica numaratorile).
	var ai_car: Car = race.cars[1]
	for c in race.cars:
		if c != ai_car:
			c.on_start_grid = true
	var ctrl := ai_car.controller as AIController
	_check(ctrl != null, "AI-ul ales are AIController")
	if ctrl == null:
		_finish()
		return
	print("  AI la %.1f m/s, reacts=%s" % [ai_car.horizontal_speed(), str(ctrl.reacts)])
	var honest_before := _honesty(ai_car)

	await _test_wobble(ai_car, ctrl, player)
	await _test_weak(ai_car, ctrl, player)
	await _test_grudge(race, ai_car, ctrl, player)
	await _test_reach_and_expiry(ai_car, ctrl, player)
	_check(_honesty(ai_car) == honest_before,
		"cinstit: plafon de viteza si aderente neschimbate (%s)" % str(_honesty(ai_car)))
	await _test_off(ai_car, ctrl, player)
	_finish()


## Cea mai dreapta si plata portiune de 130 m a rutei 0: testele de reactie se fac
## acolo, ca locul unde se nimereste AI-ul (un hairpin, o cornisa) sa nu decida
## rezultatul. Masura = schimbarea de directie + diferenta de cota pe 130 m.
func _find_straight() -> int:
	var r: TrackRoute = _track.route_at(0)
	var n := r.count()
	var step := int(ceil(130.0 / _track.curve.bake_interval))
	var best := 0
	var best_score := INF
	var margin := int(ceil(100.0 / _track.curve.bake_interval))
	for i in range(margin, n - 2 * step - margin, 3):
		var d0 := (r.baked[i + step / 2] - r.baked[i]) * Vector3(1, 0, 1)
		var d1 := (r.baked[i + step] - r.baked[i + step / 2]) * Vector3(1, 0, 1)
		if d0.length_squared() < 1e-4 or d1.length_squared() < 1e-4:
			continue
		# Fara culoare impuse / hazarde pe axa pe portiune: acolo linia AI nu e a lui.
		var free := true
		for k in range(0, step + 8, 6):
			if _track.lane_bias_at(i + k) > 0.0 or absf(_track.lane_forced_at(i + k)) > 0.001:
				free = false
				break
		if not free:
			continue
		var bend := d0.angle_to(d1)
		var rise := absf(r.baked[i + step].y - r.baked[i].y)
		var score := bend + rise * 0.05
		if score < best_score:
			best_score = score
			best = i
	print("  portiune dreapta: index %d din %d (scor %.4f)" % [best, n, best_score])
	return best


## Pune AI-ul pe portiunea dreapta, cu viteza de croaziera, si il lasa sa se aseze.
func _reset_ai(c: Car) -> void:
	var r: TrackRoute = _track.route_at(0)
	var i := _straight_idx
	var dir := (r.baked[i + 4] - r.baked[i]) * Vector3(1, 0, 1)
	dir = dir.normalized()
	c.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP),
		r.baked[i] + Vector3.UP * 0.8)
	c.road_index = i
	# Salt inapoi pe traseu: paznicul de progres l-ar citi ca blocaj si ar porni
	# marsarierul de deblocare (viteza ~0 dupa teleport). Il resetam ca la o repunere.
	var ctrl := c.controller as AIController
	ctrl._reset_progress()
	ctrl._unstick_timer = 0.0
	ctrl._unstick_reversing = false
	ctrl._attempts = 0
	c.linear_velocity = dir * 26.0
	c.angular_velocity = Vector3.ZERO
	await _frames(1.5)


func _honesty(c: Car) -> Array:
	return [c.max_speed, c.speed_scale, c.grip, c.drift_grip, c.drift_grip_at_top]


func _finish() -> void:
	Engine.time_scale = 1.0
	print("")
	print("VERDICT: ", "PROBLEMA" if _failed else "OK")
	get_tree().quit(1 if _failed else 0)


func _emit_hit(c: Car, strength: float, from_right: bool, other: Car) -> void:
	var n := c.global_transform.basis.x * (1.0 if from_right else -1.0)
	c.impact.emit(c, &"car", strength, n, c.global_position, other)


func _test_wobble(c: Car, ctrl: AIController, p: Car) -> void:
	print("")
	print("-- 1. clatinare dupa o lovitura tare (12 m/s) --")
	await _reset_ai(c)
	var n0 := ctrl.react_count
	_emit_hit(c, 12.0, true, p)
	var peak := 0.0
	var ok_sum := true
	var first_lobe := 0.0
	for f in 120:
		await get_tree().physics_frame
		peak = maxf(peak, absf(ctrl.wobble_now))
		if first_lobe == 0.0 and absf(ctrl.wobble_now) > 0.03:
			first_lobe = signf(ctrl.wobble_now)
		if absf(ctrl.get_steer() - clampf(ctrl.base_steer + ctrl.wobble_now, -1.0, 1.0)) > 1e-4:
			ok_sum = false
	print("  reactii: %d, varf clatinare %.3f, dupa 2 s: %.4f" % [
		ctrl.react_count - n0, peak, ctrl.wobble_now])
	_check(ctrl.react_count == n0 + 1, "lovitura tare e procesata o data")
	_check(peak > 0.15, "clatinarea apare (varf > 0.15)")
	_check(peak <= ctrl.wobble_max + 1e-4, "varful nu depaseste wobble_max")
	_check(ctrl.wobble_now == 0.0, "clatinarea se stinge (zero dupa 2 s)")
	_check(ok_sum, "volan final = baza + clatinare, in fiecare cadru")
	# Semn opus pentru lovitura din partea opusa (cand masina nu se roteste).
	await _reset_ai(c)
	var yaw1 := absf(c.angular_velocity.y)
	_emit_hit(c, 12.0, false, p)
	var second_lobe := 0.0
	for f in 160:
		await get_tree().physics_frame
		if second_lobe == 0.0 and absf(ctrl.wobble_now) > 0.03:
			second_lobe = signf(ctrl.wobble_now)
	print("  primul lob: %+d (lovit din dreapta) apoi %+d (din stanga), yaw %.2f" % [
		int(first_lobe), int(second_lobe), yaw1])
	if yaw1 < 0.45:
		_check(first_lobe != 0.0 and second_lobe == -first_lobe,
			"contravirare in sens opus pentru lovitura din partea opusa")
	await _frames(2.0)


func _test_weak(c: Car, ctrl: AIController, p: Car) -> void:
	print("")
	print("-- 1b. lovitura slaba (3 m/s) nu declanseaza nimic --")
	await _reset_ai(c)
	var n0 := ctrl.react_count
	_emit_hit(c, 3.0, true, p)
	var peak := 0.0
	for f in 60:
		await get_tree().physics_frame
		peak = maxf(peak, absf(ctrl.wobble_now))
	print("  reactii: %d, varf %.4f" % [ctrl.react_count - n0, peak])
	_check(ctrl.react_count == n0 and peak == 0.0, "sub prag: fara reactie")


## Fractia laterala a masinii pe ruta 0 (ca `line` din AIController).
func _lat_frac(c: Car) -> float:
	var r: TrackRoute = _track.route_at(0)
	var hw := maxf(_track.width_at_index(c.road_index), 0.001)
	return r.side_at(c.road_index).dot(
		c.global_position - r.baked[r.wrap_index(c.road_index)]) / hw


## Distanta laterala ABSOLUTA (m) dintre `c` si `o` pe ruta 0.
func _lat_gap(race: Node, c: Car, o: Car) -> float:
	var r: TrackRoute = race.track.route_at(0)
	var lat_o := r.side_at(o.road_index).dot(
		o.global_position - r.baked[r.wrap_index(o.road_index)])
	var lat_c := r.side_at(c.road_index).dot(
		c.global_position - r.baked[r.wrap_index(c.road_index)])
	return absf(lat_o - lat_c)


func _test_grudge(race: Node, c: Car, ctrl: AIController, p: Car) -> void:
	print("")
	print("-- 2. izbitura reala din spate => ranchiuna --")
	await _reset_ai(c)
	var fwd := -c.global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	p.on_start_grid = false # jucatorul era inghetat pe grila
	p.global_transform = Transform3D(c.global_transform.basis, c.global_position - fwd * 5.5)
	p.linear_velocity = c.linear_velocity + fwd * 14.0
	p.angular_velocity = Vector3.ZERO
	var n0 := ctrl.react_count
	var got := false
	for f in 150:
		await get_tree().physics_frame
		if ctrl.react_count > n0:
			got = true
			break
	print("  reactii noi: %d, grudge_car=%s, grudge_left=%.2f" % [
		ctrl.react_count - n0, str(ctrl.grudge_car.pilot_name if ctrl.grudge_car else "-"),
		ctrl.grudge_left])
	_check(got, "izbitura reala a ajuns la AI (impact -> reactie)")
	_check(ctrl.grudge_car == p, "atacatorul (jucatorul din spate) e tinta ranchiunii")
	_check(ctrl.grudge_left > 3.0, "ranchiuna proaspata (~4 s)")
	# --- presiune: jucatorul tinut la 14 m in fata, pe acelasi culoar ---
	print("")
	print("-- 3. ranchiuna apasa doar cat atacatorul e aproape si in fata --")
	var lat0 := _lat_gap(race, c, p)
	# Atacatorul la 9 m in fata, pe axa soselei; AI-ul pleaca de pe linia lui.
	var p_lat := 0.0
	for f in 150:
		_hold_ahead(c, p, 9.0, p_lat)
		await get_tree().physics_frame
	var lat1 := _lat_gap(race, c, p)
	print("  la 9 m in fata: blend %.2f, distanta laterala %.2f -> %.2f m (tinta %.1f m)" % [
		ctrl.grudge_blend, lat0, lat1, ctrl.grudge_gap_m])
	_check(ctrl.grudge_blend > 0.8, "linia de ranchiuna s-a instalat (blend > 0.8)")
	_check(absf(lat1 - ctrl.grudge_gap_m) < 1.2,
		"AI s-a asezat langa atacator, la ~un culoar distanta (%.1f m din %.1f m)" % [
			lat1, ctrl.grudge_gap_m])


## Tine atacatorul `dist` m in fata pe DRUM, la fractia laterala FIXA `lat` (nu in
## linie dreapta din bot: in viraj asta ar pune masina alaturi de drum).
func _hold_ahead(c: Car, p: Car, dist: float, lat: float) -> void:
	var tr: Track = _track
	var pos := tr.lookahead_point(c.road_index, dist, lat, 0)
	pos.y += 0.4
	p.global_transform = Transform3D(c.global_transform.basis, pos)
	p.linear_velocity = c.linear_velocity
	p.angular_velocity = Vector3.ZERO


func _test_reach_and_expiry(c: Car, ctrl: AIController, p: Car) -> void:
	print("")
	print("-- 3b. in afara razei: nicio apasare --")
	await _reset_ai(c)
	ctrl.grudge_car = p
	ctrl.grudge_left = 4.0
	var p_lat := _lat_frac(c)
	for f in 120:
		_hold_ahead(c, p, 45.0, p_lat)
		await get_tree().physics_frame
	print("  la 45 m in fata: blend %.3f" % ctrl.grudge_blend)
	_check(ctrl.grudge_blend < 0.05, "atacator la 45 m (> reach): fara apasare")
	print("")
	print("-- 3c. dupa grudge_s uita --")
	ctrl.grudge_car = p
	ctrl.grudge_left = ctrl.grudge_s
	var peak := 0.0
	var t_on := 0.0
	for f in int(ctrl.grudge_s * 60.0) + 90:
		_hold_ahead(c, p, 12.0, p_lat)
		await get_tree().physics_frame
		peak = maxf(peak, ctrl.grudge_blend)
		if ctrl.grudge_left > 0.0:
			t_on += 1.0 / 60.0
	print("  ranchiuna activa %.1f s (grudge_s=%.1f), blend maxim %.2f, la final: car=%s blend=%.3f" % [
		t_on, ctrl.grudge_s, peak, str(ctrl.grudge_car), ctrl.grudge_blend])
	_check(peak > 0.8, "a apasat cat a tinut")
	_check(absf(t_on - ctrl.grudge_s) < 0.2, "a tinut ~grudge_s")
	_check(ctrl.grudge_car == null and ctrl.grudge_blend < 0.01, "a uitat: tinta null, blend 0")


func _test_off(c: Car, ctrl: AIController, p: Car) -> void:
	print("")
	print("-- 4. reacts = false: aceleasi lovituri nu fac nimic --")
	await _reset_ai(c)
	ctrl.reacts = false
	await _frames(0.2)
	var n0 := ctrl.react_count
	_emit_hit(c, 14.0, true, p)
	var peak := 0.0
	for f in 90:
		await get_tree().physics_frame
		peak = maxf(peak, absf(ctrl.wobble_now))
	print("  reactii %d, varf %.4f, grudge_car=%s" % [
		ctrl.react_count - n0, peak, str(ctrl.grudge_car)])
	_check(ctrl.react_count == n0 and peak == 0.0 and ctrl.grudge_car == null,
		"oprit: nicio clatinare, nicio ranchiuna")
	ctrl.reacts = true
