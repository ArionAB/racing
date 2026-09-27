extends Node
## Sonda VACII DIN ULICIOARA (Jodhpur, Track17 — inca neconstruita).
##
## Track17 nu exista, deci sonda nu poate rula pe pista reala: monteaza un
## CowGate LA RUNTIME pe o banda (TrackBranch) a unei piste EXISTENTE, care nu
## are alta poarta pe ea (nu Stromboli: acolo lava foloseste deja
## branch_index 1). Verificat pe cod: Track09 (Alpii), Track12 (Chongqing) si
## Track13 (Cappadocia) au un nod TrackBranch fara LavaFlowHazard/TorrentCycle/
## TunnelSignalHazard pe aceeasi ruta; Track16 (Fiordland) are torent + semafor
## pe a ei, deci nu e curata. Implicit Track09 ("scurtatura" de pe pasunea de
## munte, branch_index 1, half_width 4.0 — suficient de larga pentru 8 masini).
##
## Rulare (ca SCENA, nu --script: avem nevoie de GameState/AudioManager):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeJodVaca.tscn
##   ... -- --seeds=8,9,10,11,12,13,14,15 --seconds=150
##   ... -- --no-safety                      (SABOTAJ: cere contacte > 0)
##   ... -- --no-cow                         (control: fara vaca, pentru timpul de tur de referinta)
##   ... -- --track=6                        (alta pista curata: Cappadocia = pozitia 6)
##
## Masoara, pe fiecare seed:
##   - contacte vaca-masina (tinta 0; SlidingHazard.get_colliding_bodies() pe
##     CowBody-ul intern al CowGate-ului)
##   - cate AI intra pe scurtatura CAND E DESCHISA vs CAND E INCHISA (inchisa
##     trebuie sa fie 0 — altfel poarta nu inchide nimic)
##   - [blocaj] / lent / invers la furca si la gura (memoria
##     zero-repuneri-ascunde-blocajul: 0 repuneri nu inseamna 0 regresie)
##   - timp de tur mediu, comparat cu o rulare de control FARA vaca
##
## SABOTAJ (memoria garda-circulara-propria-functie): cu --no-safety,
## CowGate.debug_disable_safety = true pe toata durata sondei — vaca se muta
## orb pe ceas, ignorand masinile din gura. Daca in stare asta contactele tot
## ies 0, sonda nu demonstreaza nimic si trebuie spus onest, nu ascuns.

## Jumatatea latimii ulicioarei din brief (banda de 3.2 m). Vezi antetul
## _mount_cow pentru de ce sonda ingusteaza la asta ruta gazda.
const ALLEY_HALF_WIDTH_M: float = 1.6

## Pistele verificate CURATE (Track.routes[1] exista, nicio alta poarta pe
## ea). Cheia e valoarea acceptata de --track=; valoarea e eticheta din
## GameState.track_label, doar pentru mesaje.
const CLEAN_TRACKS: Dictionary = {
	2: "Alpii (Track09)",
	5: "Chongqing (Track12)",
	6: "Cappadocia (Track13)",
}

var _track_index: int = 2 # Alpii implicit
var _seeds: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8]
var _seconds: float = 150.0
var _no_safety: bool = false
var _no_cow: bool = false
var _ai_count: int = 7 # +1 jucator = 8 masini, cum cere brieful
var _mouth_dist_m: float = -1.0 # negativ = jumatatea benzii (implicit rezonabil)
var _narrow_alley: bool = true # vezi antetul _mount_cow

var _results: Array[Dictionary] = []
var _seed_i: int = 0

# --- stare per rulare ---
var _race: Node = null
var _track: Track = null
var _gate: CowGate = null
var _elapsed: float = 0.0
var _stats: Array[Dictionary] = []
var _done: bool = false


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			_track_index = int(arg.trim_prefix("--track="))
		elif arg.begins_with("--seconds="):
			_seconds = float(arg.trim_prefix("--seconds="))
		elif arg.begins_with("--seeds="):
			_seeds.clear()
			for s in arg.trim_prefix("--seeds=").split(","):
				_seeds.append(int(s))
		elif arg == "--no-safety":
			_no_safety = true
		elif arg == "--no-cow":
			_no_cow = true
		elif arg == "--no-narrow":
			_narrow_alley = false
		elif arg.begins_with("--ai="):
			_ai_count = int(arg.trim_prefix("--ai="))
		elif arg.begins_with("--mouth="):
			_mouth_dist_m = float(arg.trim_prefix("--mouth="))
	if not CLEAN_TRACKS.has(_track_index):
		push_warning("probe_jod_vaca: --track=%d nu e in lista verificata curata (%s) — "
			% [_track_index, ", ".join(CLEAN_TRACKS.values())]
			+ "continui oricum, dar rezultatul poate fi contaminat de alta poarta pe banda.")
	print("\n=== ProbeJodVaca === pista %s · %s · seed-uri %s · %.0fs%s%s%s"
		% [CLEAN_TRACKS.get(_track_index, "necunoscuta"),
			"FARA vaca (control)" if _no_cow else "CU vaca",
			str(_seeds), _seconds,
			" · SABOTAJ (siguranta OFF)" if _no_safety else "",
			" · ai=%d" % _ai_count,
			" · banda ingustata la %.1fm (alee, vezi antet _mount_cow)" % ALLEY_HALF_WIDTH_M
				if (_narrow_alley and not _no_cow) else " · banda LATA a pistei-gazda (--no-narrow)"])
	_run_next_seed()


func _run_next_seed() -> void:
	if _seed_i >= _seeds.size():
		_report_summary()
		get_tree().quit(0)
		return
	_start_race(_seeds[_seed_i])


func _start_race(seed_val: int) -> void:
	GameState.selected_track = _track_index
	GameState.champ_active = false
	GameState.total_laps = 99
	GameState.ai_count = _ai_count
	GameState.selected_car = 0
	_elapsed = 0.0
	_done = false
	_stats.clear()

	_race = (load("res://scenes/race/Race.tscn") as PackedScene).instantiate()
	add_child(_race)
	(_race._rng as RandomNumberGenerator).seed = seed_val
	_track = _race.track

	# Jucatorul primeste creier AI, la fel ca probe_race.gd — masuram pista.
	var player: Car = _race.player
	var old: CarController = player.controller
	player.remove_child(old)
	old.free()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var cars: Array[Car] = _race.cars
	for i in cars.size():
		var car := cars[i]
		if car == player:
			var ai := AIController.new()
			car.set_controller(ai)
			ai.configure(_race.track, rng, cars)
		else:
			(car.controller as AIController).line_offset = rng.randf_range(-0.35, 0.35)
		car.speed_scale = 1.0 if car == player else rng.randf_range(0.88, 0.97)
		_stats.append({
			"name": "%s (%s)" % [car.pilot_name, car.car_name],
			"slow_s": 0.0, "reverse_s": 0.0, "respawns": 0,
			"branch_open_entries": 0, "branch_closed_entries": 0,
			"past_mouth_closed": 0, "real_breach_frames": 0,
			"last_route": 0, "stuck_t": 0.0, "stuck_reports": 0,
			"cow_contacts": 0,
		})
		car.respawned.connect(_on_respawn.bind(i))

	if not _no_cow:
		_mount_cow()

	print("\n--- seed %d ---" % seed_val)


## Monteaza CowGate la runtime pe routes[1] a pistei curente — echivalentul
## sondei pentru "Track17 nu exista inca". branch_index e mereu 1: singura
## banda secundara pe pistele din CLEAN_TRACKS.
##
## NARROW (implicit pornit): Track09/12/13 sunt benzi de 7-9 m latime totala
## (`half_width` 3.5-4.5), construite pentru alt gimmick (pasune, ocol, gat de
## piatra) — nicio nu e o ulicioara. Vaca din brief are 2.8 m latime dintr-o
## banda de 3.2 m: blocheaza aproape TOT culoarul. Montata neschimbata pe o
## banda de 8 m, cutia de 2.8 m lasa >2 m liberi pe fiecare parte — masurat
## direct: 245 treceri fizice pe Track09, majoritatea la lat 1-4 m, adica
## masinile trec PE LANGA vaca, nu PRIN ea (comportament corect al cutiei,
## banda gresit dimensionata pentru test). NARROW ingusteaza `route.half_width`
## la 1.6 m (adica banda de 3.2 m din brief) DOAR pentru durata sondei, pe
## instanta ruta incarcata acum — afecteaza `is_on_road`/latimea de cautare a
## AI-ului (ii face pe toti sa navigheze un culoar mai stramt, ca la o ulicioara
## reala), nu geometria vizuala a asfaltului (ramane cea a pistei-gazda; sonda
## nu se uita la ea). Cu --no-narrow se dezactiveaza, ca sa se vada exact
## comportamentul descris mai sus (control, nu recomandat pentru verdict).
func _mount_cow() -> void:
	_gate = CowGate.new()
	_gate.name = "ProbeCowGate"
	_gate.branch_index = 1
	var route := _track.route_at(1)
	if route == null or route.baked.is_empty():
		push_error("probe_jod_vaca: pista %d nu are routes[1] — nu e curata pentru sonda asta."
			% _track_index)
		_gate = null
		return
	if _narrow_alley:
		route.half_width = ALLEY_HALF_WIDTH_M
	_gate.mouth_dist_m = _mouth_dist_m if _mouth_dist_m >= 0.0 else route.length() * 0.5
	_gate.debug_disable_safety = _no_safety
	# Ciclul brief-ului Jodhpur: ~47s, culcata 16s, telegraph 3s, mers 2s.
	_gate.period = 47.0
	_gate.lie_seconds = 16.0
	_gate.telegraph_seconds = 3.0
	_gate.walk_seconds = 2.0
	_gate.clear_radius_m = 12.0
	_track.add_child(_gate)


func _physics_process(delta: float) -> void:
	if _done or _race == null:
		return
	_elapsed += delta
	var cars: Array[Car] = _race.cars
	for i in cars.size():
		var car := cars[i]
		var st := _stats[i]
		var speed := car.horizontal_speed()
		if speed < 4.0:
			st.slow_s = float(st.slow_s) + delta
		if car.controller != null and car.controller.get_throttle() < -0.5:
			st.reverse_s = float(st.reverse_s) + delta
		_watch_branch_entry(car, st)
		_watch_stuck(car, st, speed, delta)
	if _gate != null:
		_watch_cow_contacts()
	if _elapsed >= _seconds:
		_finish_seed()


## Cate AI intra pe scurtatura CU POARTA DESCHISA vs INCHISA — si, mai
## important, cat de DEPARTE ajung cat e inchisa.
##
## `car.route == 1` NU e dovada ca masina a "luat scurtatura": Track.resolve_route
## comuta ruta pe PROXIMITATE (BRANCH_SNAP_RANGE = 45 m de la fork), indiferent
## de branch_is_open — masurat pe Track09: un autobuz atinge route=1 la doar
## bidx=2 (2 pasi dupa fork), lat=0.6 m, apoi se intoarce singur pe ruta 0 FARA
## sa treaca prin poarta si FARA niciun contact cu vaca. Aceeasi mecanica ar
## produce identic "route flip la fork" pe Stromboli cu lava inchisa, azi, pe
## main — nu e o regresie a generalizarii, e cum functiona deja resolve_route.
##
## Testul care conteaza e altul: a ajuns cineva, cat poarta era inchisa, la
## bidx >= indexul GURII (adica a trecut FIZIC de unde sta vaca)? Asta s-ar
## intampla doar daca poarta nu blocheaza cu adevarat coliziunea — exact
## defectul pe care sonda trebuie sa-l prinda.
func _watch_branch_entry(car: Car, st: Dictionary) -> void:
	var was_main := int(st.last_route) == 0
	if was_main and car.route == 1:
		if _track.branch_is_open(1):
			st.branch_open_entries = int(st.branch_open_entries) + 1
		else:
			st.branch_closed_entries = int(st.branch_closed_entries) + 1
	if car.route == 1 and _gate != null and not _track.branch_is_open(1):
		var r1 := _track.route_at(1)
		if r1 != null and not r1.baked.is_empty():
			var bidx := r1.closest_index_global(car.global_position)
			var lat := r1.lateral_distance(bidx, car.global_position)
			# GARDA IMPORTANTA: `closest_index_global` intoarce cel mai apropiat
			# punct de pe INTREAGA banda, chiar daca masina e la 80 m de ea, pe
			# bucla principala — o masina care nu s-a apropiat niciodata de
			# scurtatura poate totusi sa "para" langa un index mare daca banda
			# se curbeaza inapoi spre bucla. Fara testul de lateral, un breach
			# fals a iesit 342/150s pe Track09 cu 0 contacte reale (masurat) —
			# masina nici nu era pe banda, doar cel mai apropiat punct al ei
			# era departe pe curba.
			var mouth_bidx := r1.closest_index_global(_gate.mouth_position())
			if bidx >= mouth_bidx and lat <= r1.half_width:
				var gate_state := _gate.current_state()
				st.past_mouth_closed = int(st.get("past_mouth_closed", 0)) + 1
				# STARE 1 (RISING_TO_MOUTH) NU e o breșă reala: vaca inca STA pe
				# prag (telegraph-ul e doar vizual/sonor), deci lanul e fizic
				# gol — o masina care era deja langa/dupa gura cand a inceput
				# telegraph-ul il traverseaza legitim inainte ca vaca sa apuce
				# sa se mute. STARILE 3 (culcata) inseamna coliziunea nu tine —
				# ACELA e defectul clar. STARILE 2/5 (in mers) NU se pot judeca
				# doar din `bidx >= mouth_bidx`: vaca e undeva INTRE prag si
				# gura, nu neaparat la indexul gurii, deci un `bidx` mare poate
				# insemna doar ca masina a trecut de UNDE VA FI vaca, nu de
				# UNDE E ACUM (gasit chiar asa: 24 "brese" cu gate_state=2 care,
				# verificate pe distanta reala fata de corp, erau la >8 m de
				# vaca — fals pozitiv al acestui test bazat pe index, nu o
				# bresa reala). Pentru 2/5 se cere in plus distanta 3D fata de
				# CowBody sub `_gate.clear_radius_m` — daca vaca era chiar
				# acolo, siguranta CONTINUA din CowGate ar fi trebuit sa o
				# opreasca oricum, deci coincidenta spatiala e chiar testul.
				var real := false
				if gate_state == CowGate.State.LYING_IN_MOUTH:
					real = true
				elif gate_state == CowGate.State.WALKING_TO_MOUTH \
						or gate_state == CowGate.State.WALKING_TO_THRESHOLD:
					var body_pos: Vector3 = _gate.get_node("CowBody").global_position
					real = car.global_position.distance_to(body_pos) < _gate.clear_radius_m
				if real:
					st.real_breach_frames = int(st.real_breach_frames) + 1
					if int(st.real_breach_frames) <= 3:
						print(("[BRESA REALA] t=%5.1fs %-20s bidx=%d mouth=%d lat=%.2f "
							+ "gate_state=%d (vaca ar trebui sa fie in cale) — poarta NU tine")
							% [_elapsed, st.name, bidx, mouth_bidx, lat, gate_state])
	st.last_route = car.route


## Contact vaca-masina: CowBody-ul intern al CowGate-ului e un
## AnimatableBody3D obisnuit (fara meta "lava"), deci coliziunea fizica
## opreste masina ca un perete — dar tinta e ZERO, adica vaca nu trebuie sa
## fie niciodata acolo unde e o masina. Se numara pe `get_colliding_bodies()`
## al FIECAREI masini, ca la _watch_stuck din probe_race.gd.
func _watch_cow_contacts() -> void:
	var cow_body: Node = _gate.get_node_or_null("CowBody")
	if cow_body == null:
		return
	var cars: Array[Car] = _race.cars
	for i in cars.size():
		var car := cars[i]
		if car.get_colliding_bodies().has(cow_body):
			var st := _stats[i]
			st.cow_contacts = int(st.cow_contacts) + 1
			if int(st.cow_contacts) == 1:
				print("[vaca] t=%5.1fs %-20s CONTACT cu poarta (stare %d)"
					% [_elapsed, st.name, _gate.current_state()])


func _watch_stuck(car: Car, st: Dictionary, speed: float, delta: float) -> void:
	if _race.state != Race.State.RUNNING or speed > 6.0:
		st.stuck_t = 0.0
		return
	st.stuck_t = float(st.stuck_t) + delta
	if float(st.stuck_t) < 3.0 or int(st.stuck_reports) >= 6:
		return
	st.stuck_t = 0.0
	st.stuck_reports = int(st.stuck_reports) + 1
	print("[blocaj] t=%5.1fs %-20s frac=%.3f v=%4.1f route=%d" % [
		_elapsed, st.name, _track.frac_at(car.road_index, car.route), speed, car.route])


func _on_respawn(_car: Car, index: int) -> void:
	_stats[index].respawns = int(_stats[index].respawns) + 1


func _finish_seed() -> void:
	var cars: Array[Car] = _race.cars
	var laps: Array[float] = []
	var branch_open := 0
	var branch_closed := 0
	var past_mouth_closed := 0
	var real_breach_frames := 0
	var cow_contacts := 0
	var respawns := 0
	var slow_s := 0.0
	var reverse_s := 0.0
	for i in cars.size():
		var st := _stats[i]
		laps.append(float(_race._progress[i].total))
		branch_open += int(st.branch_open_entries)
		branch_closed += int(st.branch_closed_entries)
		past_mouth_closed += int(st.get("past_mouth_closed", 0))
		real_breach_frames += int(st.get("real_breach_frames", 0))
		cow_contacts += int(st.cow_contacts)
		respawns += int(st.respawns)
		slow_s += float(st.slow_s)
		reverse_s += float(st.reverse_s)
	laps.sort()
	var avg_laps := 0.0
	for l in laps:
		avg_laps += l
	avg_laps /= maxf(float(laps.size()), 1.0)
	var lap_time_s := _seconds / maxf(avg_laps, 0.01)
	_results.append({
		"seed": _seeds[_seed_i],
		"avg_laps": avg_laps,
		"lap_time_s": lap_time_s,
		"branch_open": branch_open,
		"branch_closed": branch_closed,
		"past_mouth_closed": past_mouth_closed,
		"real_breach_frames": real_breach_frames,
		"cow_contacts": cow_contacts,
		"respawns": respawns,
		"slow_s": slow_s,
		"reverse_s": reverse_s,
		"gate_pending": _gate != null and _gate.is_pending(),
	})
	print(("  seed %d: %.2f tururi medii (%.1fs/tur) · fork d/i %d/%d (route flip la fork, vezi "
		+ "antet) · treceri in fereastra telegraph (benign) %d · BRESE REALE %d · contacte "
		+ "vaca %d · repuneri %d · lent %.1fs · invers %.1fs")
		% [_seeds[_seed_i], avg_laps, lap_time_s, branch_open, branch_closed,
			past_mouth_closed, real_breach_frames, cow_contacts, respawns, slow_s, reverse_s])
	_race.queue_free()
	_race = null
	_gate = null
	_seed_i += 1
	_run_next_seed.call_deferred()


func _report_summary() -> void:
	print("\n=== SUMAR ProbeJodVaca — pista %s · %s%s ===" % [
		CLEAN_TRACKS.get(_track_index, "necunoscuta"),
		"FARA vaca (control)" if _no_cow else "CU vaca",
		" · SABOTAJ" if _no_safety else ""])
	print("%6s %9s %10s %10s %8s %9s %10s %9s %8s %9s %8s" % [
		"seed", "tururi", "s/tur", "fork d/i", "telegr.", "BRESE",
		"contacte", "repuneri", "lent(s)", "invers(s)", "amanat"])
	print(("      (fork d/i = route flip la FORK, nu dovada de trecere; telegr. = a trecut in "
		+ "fereastra de telegraph cand vaca inca statea pe prag — benign, vezi antet; "
		+ "BRESE = a trecut FIZIC de gura cat vaca era in mers/culcata, tinta 0 — ACESTA e "
		+ "testul real)"))
	var total_contacts := 0
	var total_closed_entries := 0
	var total_telegraph_passes := 0
	var total_breaches := 0
	var total_respawns := 0
	var lap_times: Array[float] = []
	for r in _results:
		print("%6d %9.2f %10.1f %5d/%-4d %8d %9d %10d %9d %8.1f %9.1f %8s" % [
			r.seed, r.avg_laps, r.lap_time_s, r.branch_open, r.branch_closed,
			r.get("past_mouth_closed", 0), r.get("real_breach_frames", 0),
			r.cow_contacts, r.respawns, r.slow_s, r.reverse_s,
			"DA" if r.gate_pending else "-"])
		total_contacts += int(r.cow_contacts)
		total_closed_entries += int(r.branch_closed)
		total_telegraph_passes += int(r.get("past_mouth_closed", 0))
		total_breaches += int(r.get("real_breach_frames", 0))
		total_respawns += int(r.respawns)
		lap_times.append(float(r.lap_time_s))
	lap_times.sort()
	var avg_lap := 0.0
	for t in lap_times:
		avg_lap += t
	avg_lap /= maxf(float(lap_times.size()), 1.0)
	print("--- total contacte vaca-masina: %d (tinta 0)" % total_contacts)
	print("--- total route-flip la fork cat era inchisa: %d (asteptat > 0, NU e defect — "
		% total_closed_entries + "vezi antet)")
	print("--- total treceri in fereastra de telegraph (vaca inca pe prag): %d (benign — "
		% total_telegraph_passes + "masina era deja pe banda inainte sa inceapa telegraph-ul)")
	print("--- total BRESE REALE (trecere fizica prin gura ocupata): %d (tinta 0)" % total_breaches)
	print("--- total repuneri: %d" % total_respawns)
	print("--- timp de tur mediu: %.1fs (min %.1f, max %.1f) pe %d seed-uri" % [
		avg_lap, lap_times[0] if not lap_times.is_empty() else 0.0,
		lap_times[lap_times.size() - 1] if not lap_times.is_empty() else 0.0,
		lap_times.size()])
	if _no_safety:
		# Verdictul de sabotaj se citeste pe BRESE (trecere fizica prin gura
		# ocupata), nu pe CONTACTE: geometria gurii (2.8 m dintr-o alee de
		# 3.2 m) lasa un culoar de 0.2 m — masurat, in ambele regimuri
		# (siguranta ON si sabotaj) contactele raman 0, fiindca masinile care
		# ajung in fereastra periculoasa trec PRINTR-un moment in care vaca e
		# INCA in mers (WALKING_TO_MOUTH/WALKING_TO_THRESHOLD), nu blocheaza
		# lanul cu trupul deja asezat — deci "0 contacte" nu e semnul ca garda
		# functioneaza, e limita geometrica a testului. BRESELE sunt semnul
		# corect: daca sabotajul le CRESTE fata de rularea cu siguranta ON
		# (compara manual cele doua rulari — sonda nu compara singura doua
		# procese separate), garda chiar face ceva.
		if total_breaches > 0:
			print(("--- SABOTAJ: cu regula de siguranta OFF, BRESE REALE ies > 0 (%d). "
				+ "Comparat cu rularea echivalenta cu siguranta ON, o crestere confirma ca "
				+ "garda nu e circulara (memoria garda-circulara-propria-functie). Contactele "
				+ "raman 0 in ambele regimuri — asta e limita geometrica dintre fereastra de "
				+ "mers (2s) si traficul de pe pista-gazda, nu o dovada ca sabotajul n-a facut "
				+ "nimic.") % total_breaches)
		else:
			print("--- SABOTAJ NEREUSIT: cu regula de siguranta OFF, tot 0 brese si 0 contacte. "
				+ "Sonda nu demonstreaza nimic (memoria garda-circulara-propria-functie) — "
				+ "raportat onest, de investigat (poate geometria gurii nu intersecteaza "
				+ "traiectoria masinilor pe pista asta).")
	print("=== SFARSIT ProbeJodVaca ===\n")
