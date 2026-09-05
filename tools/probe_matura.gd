extends Node
## COSUL CARE MATURA BANDA (Cappadocia POI C, brief §2 / §3 „hazardul-semnatura").
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeMatura.tscn -- --track=6
##
## De ce exista: `tools/probe_balloon.gd` (RETRASA, stearsa odata cu sonda asta)
## masura contractul de PLATFORMA — masina sta pe cos si urca cu el. Dupa turul 2
## de la volan (4 sep 2026, handoff §4.8) cosul a fost reproiectat: la varful
## cursei nu mai STA in banda ca un obstacol, ci o TRAVERSEAZA cu ~14 m/s si
## IMPINGE ce prinde. Contractul vechi pica prin design; asta e cel nou.
##
## Memoria `garda-cu-numele-gimmickului`: o sonda care poarta numele gimmickului
## poate fi verde cu gimmickul inexistent de la volan, daca intreaba altceva.
## De aceea fiecare verdict de aici e o CIFRA FATA DE BANDA, in stare ACTIVA —
## nu un numar de noduri si nu o proprietate exportata citita din scena.
##
## Verdictele:
##   V1. COSUL INTRA IN BANDA. Ciclul se parcurge cu ceasul hazardului si se
##       masoara rulajul lateral al centrului cosului in spatiul benzii
##       (`Track.road_coords`, pozitiv spre polita). Trebuie sa plece de pe
##       polita (lat > +6) si sa ajunge la LANE_REACH_M dincolo de ax, cu semnul
##       corect. Pe hw 7, tinta din handoff §4.8 e -6 m: cosul traverseaza
##       aproape toata banda, nu doar o musca de margine.
##   V2. DIRECTIA MATURARII E SPRE VALE. `sweep_dir() . side = -1`, unde `side`
##       e lateralul rutei (spre polita). Prinde capcana bazelor transpuse
##       (memoria `tscn-transform-e-pe-randuri`): o baza scrisa pe coloane iese
##       oglindita si cosul matura spre FALEZA, adica in afara benzii, iar V1 ar
##       putea inca trece daca ancora e destul de aproape de ax.
##   V3. GHIONT, NU ANCORA. O masina reala (Car.tscn) oprita pe ax, in fereastra
##       de maturare, trebuie sa primeasca impuls LATERAL spre vale (viteza
##       laterala > 1 m/s dupa contact) si sa NU fie ancorata: dupa ce cosul
##       trece si urca, distanta masina-cos creste, adica masina nu mai e
##       purtata. Asta e chiar defectul „zidul invizibil" din filmare.
##   V4. TRAUMA DE CAMERA. Cand cosul trece la < SWEEP_TRAUMA_RANGE de masina
##       jucatorului, `ChaseCamera.add_trauma` trebuie chemat. Se pune o camera
##       REALA in grupul `ChaseCamera.GROUP`, cu masina de test ca tinta, si se
##       citeste `trauma` dupa maturare.
##   V5. CICLUL SI DEFAZAJELE. Perioada ~28 s si fazele 0 / 1/3 / 2/3. Se
##       masoara suprapunerea reala a ferestrelor „in banda": daca toate trei
##       cosurile sunt in banda in acelasi timp, cornisa e un zid, nu un ritm.
##
## Iese cu 0 daca toate verdictele trec, 1 altfel.

const CAR_SCENE: String = "res://scenes/cars/Car.tscn"

## Cat de departe dincolo de ax trebuie sa ajunga centrul cosului (m, negativ =
## partea dinspre faleza). Handoff §4.8: lat +8.4 -> -6.5 masurat, pe hw 7.
const LANE_REACH_M: float = -6.0
## De unde trebuie sa plece: de pe polita, in afara benzii.
const POLITA_MIN_LAT_M: float = 6.0
## Cat de aproape de -1 trebuie sa fie `sweep_dir . side` (dot; 1.0 - toleranta).
const SWEEP_DOT_TOL: float = 0.15
## Cat de sus/jos fata de cota drumului mai numara „in banda" (m).
const LANE_Y_TOL: float = 3.0
## Viteza laterala minima pe care trebuie s-o capete masina lovita (m/s).
const MIN_PUSH_LATERAL: float = 1.0
## Cate esantioane pe ciclu la baleiajul lui V1/V5 (28 s / 560 = 50 ms).
const CYCLE_SAMPLES: int = 560

var _track_index: int = 6
var _fails: int = 0
var _track: Track = null
var _balloons: Array[BalloonHazard] = []
## Fereastra „in banda" masurata per balon, in secunde de ciclu: [intrare, iesire].
var _windows: Array[Vector2] = []


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			_track_index = int(arg.trim_prefix("--track="))
	var resolved := GameState.resolve_track_index(_track_index)
	if resolved < 0:
		push_error("probe_matura: --track=%d invalid" % _track_index)
		get_tree().quit(2)
		return
	_track = (load(GameState.TRACK_SCENES[resolved]) as PackedScene).instantiate() as Track
	add_child(_track)
	for _i in 5:
		await get_tree().physics_frame
	for node in _track.find_children("*", "BalloonHazard", true, false):
		var b := node as BalloonHazard
		if b != null:
			_balloons.append(b)
	if _balloons.is_empty():
		print("probe_matura: niciun BalloonHazard pe pista. VERDICT: PICAT")
		get_tree().quit(1)
		return
	print("probe_matura: %d cosuri pe pista '%s'" % [_balloons.size(), _track.name])
	await _v1_v2()
	await _v3_v4()
	_v5()
	print("VERDICT: %s" % ("PICAT (%d)" % _fails if _fails > 0 else "OK"))
	get_tree().quit(1 if _fails > 0 else 0)


func _verdict(ok: bool, text: String) -> void:
	print("  [%s] %s" % ["OK" if ok else "PICAT", text])
	if not ok:
		_fails += 1


## Rulajul lateral al centrului cosului in spatiul benzii, cu semn (pozitiv =
## spre polita), plus cat de departe e de cota drumului acolo.
func _basket_lane(b: BalloonHazard) -> Vector3:
	var bp := b.body().global_position
	var i := _track.closest_index_global(bp, 0)
	var lat := _track.road_coords(i, bp).y
	var dy := bp.y - _track.point_at(i, 0).y
	return Vector3(lat, dy, _track.width_at_index(i))


# ------------------------------------------------- V1 (intrarea in banda) + V2

func _v1_v2() -> void:
	print("--- V1: cosul intra in banda (rulaj lateral fata de axa, m)")
	print("--- V2: directia maturarii spre vale (sweep_dir . side)")
	_windows.clear()
	for b in _balloons:
		var anchor_idx := _track.closest_index_global(b.global_position, 0)
		var side := _track.route_at(0).side_at(anchor_idx)
		var anchor_lat := _track.road_coords(anchor_idx, b.global_position).y
		var min_lat := INF
		var max_lat := -INF
		var min_at := 0.0
		var hw_at_min := 0.0
		var in_lane := 0
		var t_in := -1.0
		var t_out := -1.0
		var prev_in := false
		# Ceasul hazardului, pas cu pas, cu un cadru de fizica intre esantioane:
		# `sync_to_physics` publica pozitia corpului abia dupa pasul de fizica,
		# deci o citire imediat dupa `_place` intoarce cadrul anterior (masurat:
		# rulajul iesea 0.00 m pe toata perioada, adica „nu matura deloc").
		for i in CYCLE_SAMPLES:
			var t := b.period * float(i) / float(CYCLE_SAMPLES)
			b.set("_started", true)
			b.set("_time", t)
			await get_tree().physics_frame
			var m := _basket_lane(b)
			var lat := m.x
			if lat < min_lat:
				min_lat = lat
				min_at = t
				hw_at_min = m.z
			max_lat = maxf(max_lat, lat)
			var inside := absf(lat) <= m.z and absf(m.y) < LANE_Y_TOL
			if inside:
				in_lane += 1
				if not prev_in:
					t_in = t
				t_out = t
			prev_in = inside
		_windows.append(Vector2(t_in, t_out))
		var dt := b.period / float(CYCLE_SAMPLES)
		var secs := float(in_lane) * dt
		print("  %s: ancora la lat %+.2f, rulaj %+.2f .. %+.2f m (min la t=%.1f s, hw %.1f), in banda %.2f s din %.0f (%.1f%%)" % [
			b.name, anchor_lat, min_lat, max_lat, min_at, hw_at_min,
			secs, b.period, 100.0 * secs / b.period])
		_verdict(max_lat > POLITA_MIN_LAT_M,
			"%s pleaca de pe polita (max lat %+.2f > %+.1f)" % [b.name, max_lat, POLITA_MIN_LAT_M])
		_verdict(min_lat <= LANE_REACH_M,
			"%s traverseaza banda (min lat %+.2f <= %+.1f)" % [b.name, min_lat, LANE_REACH_M])
		var dot := b.sweep_dir().dot(side)
		print("    side=%s sweep_dir=%s dot=%+.3f" % [
			side.snapped(Vector3.ONE * 0.001), b.sweep_dir().snapped(Vector3.ONE * 0.001), dot])
		_verdict(dot <= -1.0 + SWEEP_DOT_TOL,
			"%s matura SPRE VALE (dot %+.3f <= %+.3f; +1 = spre faleza, baza transpusa)" % [
				b.name, dot, -1.0 + SWEEP_DOT_TOL])
		# Lasa balonul la starea JOS, ca sa nu influenteze masuratorile urmatoare.
		b.set("_time", 0.0)
		await get_tree().physics_frame


# ------------------------------------------ V3 (ghiont, nu ancora) + V4 (trauma)

func _v3_v4() -> void:
	print("--- V3: masina in banda primeste ghiont lateral spre vale, si nu ramane ancorata")
	print("--- V4: camera primeste trauma cand cosul trece la < %.0f m" % BalloonHazard.SWEEP_TRAUMA_RANGE)
	for b in _balloons:
		await _sweep_trial(b)


func _sweep_trial(b: BalloonHazard) -> void:
	# Momentul in care cosul e cel mai adanc in banda, ca masina sa fie pusa
	# chiar pe traiectoria lui si nu langa ea.
	var deep_t := _deepest_time(b)
	# Pozitia pe ax, la cota drumului, in dreptul cosului la acel moment.
	b.set("_started", true)
	b.set("_time", deep_t)
	await get_tree().physics_frame
	var bp := b.body().global_position
	var idx := _track.closest_index_global(bp, 0)
	var at := _track.point_at(idx, 0) + Vector3.UP * 0.8
	var side := _track.route_at(0).side_at(idx)
	var fwd := -side.cross(Vector3.UP).normalized()

	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(car)
	car.apply_data(GameState.CAR_DATA[0])
	car.track = _track
	car.global_transform = Transform3D(Basis.looking_at(fwd, Vector3.UP), at)
	car.velocity = Vector3.ZERO
	car.route = 0
	car.road_index = idx
	car.last_safe_index = idx
	car.last_safe_route = 0
	car.race_active = true
	car.set_controller(ProbeDriver.new())

	var cam := ChaseCamera.new()
	add_child(cam)
	cam.target = car
	await get_tree().physics_frame

	# Inapoi cu 2 s inainte de cel mai adanc punct, ca masina sa fie pe loc si
	# cosul sa vina peste ea; apoi se lasa ciclul sa curga cu fizica REALA.
	b.set("_time", fposmod(deep_t - 2.0, b.period))
	for _i in 10:
		await get_tree().physics_frame
	var start_pos := car.global_position
	var max_lat_speed := 0.0
	var lat_speed_signed := 0.0
	var contact := false
	var max_trauma := 0.0
	var min_dist := INF
	# 6 s: 2 s de asteptare + maturarea (1.1 s) + ridicarea (1.2 s) + margine.
	for _i in 360:
		await get_tree().physics_frame
		max_trauma = maxf(max_trauma, cam.trauma)
		var d := car.global_position.distance_to(b.body().global_position)
		min_dist = minf(min_dist, d)
		var v := car.velocity
		v.y = 0.0
		var vl := v.dot(side)
		if absf(vl) > max_lat_speed:
			max_lat_speed = absf(vl)
			lat_speed_signed = vl
		if absf(vl) > 0.2:
			contact = true
	var carried := car.global_position.distance_to(b.body().global_position)
	var moved := car.global_position - start_pos
	var moved_lat := moved.dot(side)
	print("  %s: cea mai mica distanta cos-masina %.2f m; viteza laterala max %.2f m/s (%+.2f pe side); deplasare laterala %+.2f m; trauma camera %.3f; aboard %d" % [
		b.name, min_dist, max_lat_speed, lat_speed_signed, moved_lat, max_trauma, b.aboard().size()])
	_verdict(contact and max_lat_speed > MIN_PUSH_LATERAL,
		"%s da ghiont lateral (%.2f m/s > %.1f)" % [b.name, max_lat_speed, MIN_PUSH_LATERAL])
	_verdict(lat_speed_signed < 0.0,
		"%s impinge SPRE VALE, nu spre faleza (%+.2f m/s pe side)" % [b.name, lat_speed_signed])
	# Ancora: dupa ce cosul urca 10 m si se intoarce pe polita, masina nu poate
	# fi inca lipita de el. `_hold_aboard` e doar pentru cine are CENTRUL pe podea.
	_verdict(b.aboard().is_empty() and carried > 5.0,
		"%s NU ancoreaza masina lovita (aboard %d, distanta la final %.1f m)" % [
			b.name, b.aboard().size(), carried])
	_verdict(max_trauma > 0.0,
		"%s da trauma camerei la trecere (%.3f > 0, la %.1f m)" % [b.name, max_trauma, min_dist])
	car.queue_free()
	cam.queue_free()
	b.set("_time", 0.0)
	await get_tree().physics_frame


## Momentul din ciclu la care centrul cosului e cel mai adanc in banda.
## Nu se cere fizica: geometria vine din `_progress`, care e pura.
func _deepest_time(b: BalloonHazard) -> float:
	var best_t := 0.0
	var best_lat := INF
	var basis := b.global_transform.basis
	var origin := b.global_position
	for i in CYCLE_SAMPLES:
		var t := b.period * float(i) / float(CYCLE_SAMPLES)
		var off: Vector3 = b.call("_progress", t)
		var p := origin + basis * Vector3(off.x, 0.0, off.z)
		var idx := _track.closest_index_global(p, 0)
		var lat := _track.road_coords(idx, p).y
		if lat < best_lat:
			best_lat = lat
			best_t = t
	return best_t


# ------------------------------------------------------ V5 (ciclu si defazaje)

func _v5() -> void:
	print("--- V5: ciclul si defazajele (cate cosuri in banda deodata)")
	var period := _balloons[0].period
	var phases: Array[float] = []
	for b in _balloons:
		phases.append(b.phase)
		_verdict(is_equal_approx(b.period, period),
			"%s are aceeasi perioada ca primul (%.1f vs %.1f)" % [b.name, b.period, period])
	print("  perioada %.1f s, faze %s" % [period, phases])
	_verdict(absf(period - 28.0) < 2.0, "perioada ~28 s (brief), masurat %.1f" % period)
	# Ferestrele masurate la V1 sunt in timp de CICLU LOCAL (fara faza). Timpul
	# global la care cosul k e in banda e fereastra lui deplasata cu -phase*period.
	var dt := period / float(CYCLE_SAMPLES)
	var overlap2 := 0
	var overlap3 := 0
	for i in CYCLE_SAMPLES:
		var t := float(i) * dt
		var n := 0
		for k in _balloons.size():
			var w := _windows[k]
			if w.x < 0.0:
				continue
			var local := fposmod(t + _balloons[k].phase * period, period)
			if local >= w.x and local <= w.y:
				n += 1
		if n >= 2:
			overlap2 += 1
		if n >= 3:
			overlap3 += 1
	print("  ferestre locale (s): %s" % [_windows])
	print("  doua cosuri in banda simultan %.2f s/ciclu; toate trei %.2f s/ciclu" % [
		float(overlap2) * dt, float(overlap3) * dt])
	_verdict(overlap3 == 0, "niciodata toate trei cosurile in banda simultan (%.2f s)" % (float(overlap3) * dt))


## Sofer inert: masina sta pe loc si primeste ce vine peste ea.
class ProbeDriver extends CarController:
	func get_throttle() -> float:
		return 0.0

	func get_steer() -> float:
		return 0.0
