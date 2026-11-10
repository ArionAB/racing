extends Node
## ECARTUL DINTRE NIVELURILE AI (issue #682): Bronz / Argint / Aur fata de
## referinta (AI-ul cu toate butoanele la maximum), pe pista reala.
##
## O rulare = o cursa: 6 masini, TOATE conduse de AI la acelasi nivel (si masina
## jucatorului, ca la ProbeRace), pana cand fiecare a facut primul tur si inca
## `--laps` tururi lansate. Tiparita o linie `AISKILL_RESULT` si, cu `--out=`,
## adaugata intr-un fisier. Raportul (`--report=`) citeste fisierul si da
## verdictul. Driverul care le leaga si le ruleaza in paralel e
## `tools/ai_skill_gap.sh` — de acolo se porneste, nu de mana.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeAiSkill.tscn -- \
##       --track=12 --seed=3 --skill=bronz [--laps=2] [--out=fisier] [--sabotaj=...]
##   godot --headless --path . res://tools/ProbeAiSkill.tscn -- --report=fisier
##
## `--skill=`: implicit | referinta | bronz | argint | aur. Nivelurile de joc
## trec pe drumul jocului (`GameState.race_ai_level` -> `Race._spawn_cars` ->
## `AiSkill.for_race()` -> fiecare `AIController.skill`), iar sonda verifica
## firul inainte de cursa. `implicit` nu atinge nicio clasa noua, deci aceeasi
## sonda ruleaza si pe main — asa se compara distributiile main / ramura.
##
## De ce pe pista reala si nu pe o bucla sintetica: pe pistele cu hazarde
## coada de AI se formeaza din hazard (usa, semafor, bratul excavatorului), iar
## un harnas sintetic isi face regimul lui (memoria
## `harnas-sintetic-comportament-emergent`).
##
## Seed-ul fixeaza zarurile (linia fiecarui pilot, scurtatura, `speed_scale`,
## rocket start-ul) — ACELEASI la orice nivel, fiindca greselile au zar propriu
## (`AIController._mistake_rng`). Fizica Jolt NU e determinista (memoria
## `proberace-nedeterminism`), deci verdictul se da pe distributii pe seed-uri.
##
## CONTRACTE (raportul):
##   ORDINE   pe fiecare pista, mediana ecartului Bronz > Argint > Aur, si in
##            fiecare pereche de seed-uri ordinea tine in majoritate.
##   VITEZA   niciun nivel nu depaseste viteza maxima a masinii lui: parametrii
##            de fizica (max_speed, acceleratie, grip, speed_scale, bonusul de
##            turbo) sunt EXACT ai masinii, la start si la final, iar viteza
##            orizontala nu trece de plafonul ei (max_speed * speed_scale +
##            turbo + aspiratie) mai mult decat marja de panta.
##   REPUNERI Bronz nu se repune mai des decat profilul implicit, peste marja:
##            un AI „prost" care iese mereu de pe drum e un bug, nu un nivel.
##
## Sabotaje (`--sabotaj=`), fiecare trebuie sa pice contractul lui:
##   viteza   +10% `max_speed` pe toate masinile dupa GO (un nivel „trisat")
##   ordine   Bronz primeste profilul de Aur
##   repuneri Bronz nu mai vede virajele (nu franeaza, tinteste exteriorul)

const RACE_SCENE: String = "res://scenes/race/Race.tscn"
const SKILL_SCRIPT: String = "res://scenes/cars/ai_skill/ai_skill.gd"
const SKILL_DIR: String = "res://scenes/cars/ai_skill/"
## Nivelurile de joc, in ordinea indexului din `AiSkill.LEVEL_PATHS`.
const LEVELS: Array[String] = ["bronz", "argint", "aur"]

## Marja de panta peste plafonul masinii: la vale gravitatia poate impinge peste
## plafonul motorului (plafonul taie forta de tractiune, nu viteza). Calibrata pe
## profilul implicit — vezi raportul de sondaj din PR.
const SPEED_SLACK: float = 1.06
## Cat din timp (fractie din esantioane) are voie o masina sa stea peste plafon
## * SPEED_SLACK (coborari lungi, aterizari). Masurat pe 240 de curse (3 piste x
## 16 seed-uri x 5 profiluri, nov 2026): maximum 1,1% (referinta, Monument
## Valley seed 12; implicitul pana la 0,7%), cu fizica masinii neatinsa. Sabotajul
## de +10% pe `max_speed` da 4,3%, deci pragul de 2% il prinde cu marja; garda
## principala ramane oricum egalitatea exacta a parametrilor masinii.
const SPEED_OVER_MAX: float = 0.02
## Repuneri: Bronz are voie la atatea ori repunerile implicitului pe aceeasi
## pista, plus o repunere pe seed (zgomotul de pe pistele cu caderi).
const RESPAWN_FACTOR: float = 1.5
const RESPAWN_SLACK_PER_SEED: float = 1.0

var _track_index: int = 12
var _seed: int = 1
var _skill_name: String = "implicit"
var _laps: int = 2
var _timeout_s: float = 900.0
var _sabotage: String = ""
var _out_path: String = ""
var _report_path: String = ""
var _overrides: Dictionary = {}
var _tag: String = ""

var _race: Node
var _elapsed: float = 0.0
var _done: bool = false
var _go_seen: bool = false
var _t_wall0: int = 0
## Per masina: momentele (s de la GO) la care a terminat un tur.
var _lap_marks: Array = []
var _last_laps: Array[int] = []
var _respawns: Array[int] = []
## Unde s-au repus masinile (fractie de traseu, ruta), pentru diagnostic.
var _resp_at: Array[String] = []
var _speed_samples: Array[int] = []
var _speed_over: Array[int] = []
var _speed_peak_ratio: Array[float] = []
var _params0: Array = []
var _params_ok: bool = true
var _params_note: String = ""


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			_track_index = int(arg.trim_prefix("--track="))
		elif arg.begins_with("--seed="):
			_seed = int(arg.trim_prefix("--seed="))
		elif arg.begins_with("--skill="):
			_skill_name = arg.trim_prefix("--skill=")
		elif arg.begins_with("--laps="):
			_laps = maxi(1, int(arg.trim_prefix("--laps=")))
		elif arg.begins_with("--timeout="):
			_timeout_s = float(arg.trim_prefix("--timeout="))
		elif arg.begins_with("--sabotaj="):
			_sabotage = arg.trim_prefix("--sabotaj=")
		elif arg.begins_with("--out="):
			_out_path = arg.trim_prefix("--out=")
		elif arg.begins_with("--set="):
			# Unealta de reglaj: `--set=camp=valoare,camp=valoare` peste nivelul
			# ales (pe o copie). Cu `--tag=NUME`, rezultatul iese sub alt nume.
			for pair in arg.trim_prefix("--set=").split(","):
				var kv := pair.split("=")
				if kv.size() == 2:
					_overrides[kv[0]] = float(kv[1])
		elif arg.begins_with("--tag="):
			_tag = arg.trim_prefix("--tag=")
		elif arg.begins_with("--report="):
			_report_path = arg.trim_prefix("--report=")
	if not _report_path.is_empty():
		var ok := _report(_report_path)
		get_tree().quit(0 if ok else 1)
		return
	_start()


# ---------------------------------------------------------------- o cursa

func _start() -> void:
	_t_wall0 = Time.get_ticks_msec()
	# Masina jucatorului se FIXEAZA (vezi ProbeRace): altfel ar mosteni ce a
	# ales dezvoltatorul ultima data in garaj.
	GameState.selected_car = 0
	var resolved := GameState.resolve_track_index(_track_index)
	if resolved < 0:
		push_error("probe_ai_skill: --track=%d nu e in lista" % _track_index)
		get_tree().quit(1)
		return
	_track_index = resolved
	GameState.selected_track = _track_index
	GameState.champ_active = false
	GameState.total_laps = 99 # cursa nu se termina singura
	GameState.traffic_override = -1
	GameState.ai_cars_override = []
	# Recordul de tur al pistei pus la 1 ms, IN MEMORIE: masina jucatorului e
	# condusa de AI si un tur „record" ar scrie in user://records.cfg — salvarea
	# reala a dezvoltatorului. Cu recordul imbatabil, `try_record` nu salveaza.
	GameState.records[GameState.TRACK_NAMES[_track_index]] = 1
	var level := LEVELS.find(_skill_name)
	if _skill_name != "implicit" and _skill_name != "referinta" and level < 0:
		push_error("probe_ai_skill: --skill=%s necunoscut" % _skill_name)
		get_tree().quit(1)
		return
	if level >= 0:
		GameState.set("race_ai_level", level)
	print("probe_ai_skill: pista %s · seed %d · nivel %s%s" % [
		GameState.track_label(_track_index), _seed, _skill_name,
		(" · SABOTAJ " + _sabotage) if not _sabotage.is_empty() else ""])

	_race = (load(RACE_SCENE) as PackedScene).instantiate()
	add_child(_race)
	(_race._rng as RandomNumberGenerator).seed = _seed
	# Nivelul aplicat de race.gd nu mai e nevoie sa ramana setat.
	if level >= 0:
		GameState.set("race_ai_level", -1)

	var cars: Array[Car] = _race.cars
	if _race.track.has_method("jump_takeoff_indices"):
		var fr: Array[String] = []
		for k: int in _race.track.call("jump_takeoff_indices"):
			fr.append("%.3f" % _race.track.frac_at(k))
		print("sarituri (buza de decolare, frac): %s" % (", ".join(PackedStringArray(fr)) if not fr.is_empty() else "niciuna"))
	var skill: Resource = _skill_for_run(level, cars)
	if skill == null and _skill_name != "implicit":
		return # firul e rupt, deja raportat
	# Jucatorul primeste tot un creier AI, la acelasi nivel.
	var player: Car = _race.player
	var old: CarController = player.controller
	player.remove_child(old)
	old.free()
	player.set_controller(AIController.new())
	# Zarurile cursei, aceleasi la orice nivel pe acelasi seed: linia,
	# scurtatura si `speed_scale` din rng-ul sondei.
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	for i in cars.size():
		var car := cars[i]
		var ai := car.controller as AIController
		if skill != null:
			ai.set("skill", skill)
		ai.configure(_race.track, rng, _race._ai_visible)
		car.speed_scale = rng.randf_range(0.88, 0.97)
		_lap_marks.append([])
		_last_laps.append(0)
		_respawns.append(0)
		_speed_samples.append(0)
		_speed_over.append(0)
		_speed_peak_ratio.append(0.0)
		_params0.append(_params_of(car))
		car.respawned.connect(func(c: Car) -> void:
			_respawns[i] += 1
			_resp_at.append("%.2f" % _race.track.frac_at(c.road_index, c.route)
				+ ("" if c.route == 0 else "r%d" % c.route)))
	_check_params_match_data(cars)


## Resursa de nivel pentru rulare, verificand ca jocul a pus-o singur pe fiecare
## AI (nivelurile de joc). Null pe `implicit` (nu se atinge nimic).
func _skill_for_run(level: int, cars: Array[Car]) -> Resource:
	if _skill_name == "implicit" and _overrides.is_empty():
		# Pe ramura: profilul implicit e AiSkill.new(); pe main nu exista deloc.
		return null
	if not ResourceLoader.exists(SKILL_SCRIPT):
		push_error("probe_ai_skill: AiSkill lipseste (ruleaza doar --skill=implicit aici)")
		get_tree().quit(1)
		return null
	var skill: Resource
	if _skill_name == "implicit":
		skill = (load(SKILL_SCRIPT) as Script).new()
	elif _skill_name == "referinta":
		skill = load(SKILL_DIR + "referinta.tres")
	else:
		skill = load(SKILL_DIR + _skill_name + ".tres")
		# Firul GameState -> Race -> AIController: fiecare adversar l-a primit.
		var wired := 0
		for car in cars:
			if car == _race.player:
				continue
			var s: Resource = (car.controller as AIController).get("skill")
			if s != null and s.resource_path == skill.resource_path:
				wired += 1
		if wired != cars.size() - 1:
			print("VERDICT: PROBLEMA — firul nivelului e rupt: %d din %d adversari au %s"
				% [wired, cars.size() - 1, skill.resource_path])
			get_tree().quit(1)
			return null
		print("fir: %d/%d adversari pe %s (din GameState.race_ai_level)" % [
			wired, cars.size() - 1, skill.resource_path.get_file()])
	if not _overrides.is_empty():
		skill = skill.duplicate()
		for k: String in _overrides:
			skill.set(k, _overrides[k])
		print("reglaj: %s" % str(_overrides))
	if _sabotage == "ordine" and _skill_name == "bronz":
		skill = load(SKILL_DIR + "aur.tres")
	elif _sabotage == "repuneri" and _skill_name == "bronz":
		# Un pilot STRICAT, nu unul prudent: nu vede virajele (nu franeaza
		# deloc), tinteste exteriorul si greseste la fiecare al doilea viraj.
		# Prima varianta (doar podeaua 0.8) nu misca repunerile — Bronz isi
		# tine oricum viteza jos pe drept; asta da 20 de repuneri pe o cursa
		# pe Kyoto si 8 pe Monument Valley (implicit: 3).
		skill = skill.duplicate()
		skill.set("corner_speed_floor", 1.0)
		skill.set("corner_soft", 1.0)
		skill.set("inside_bias", -0.8)
		skill.set("straight_speed", 1.0)
		skill.set("mistake_chance", 0.6)
	return skill


func _params_of(car: Car) -> Array:
	return [car.max_speed, car.acceleration, car.grip, car.speed_scale,
		car.turbo_speed_bonus, car.slip_speed_bonus]


## Parametrii de fizica ai fiecarei masini sunt ai CarData-ului ei: nivelul nu
## are voie sa atinga masina.
func _check_params_match_data(cars: Array[Car]) -> void:
	for i in cars.size():
		var car := cars[i]
		var data := GameState.CAR_DATA[_car_data_index(i)] as CarData
		if car.max_speed != data.max_speed or car.acceleration != data.acceleration \
				or car.grip != data.grip:
			_params_ok = false
			_params_note = "%s: fizica difera de CarData la start" % car.pilot_name


func _car_data_index(slot: int) -> int:
	if slot == 0:
		return GameState.selected_car
	var lineup: Array[int] = Race.AI_CARS
	return lineup[(slot - 1) % lineup.size()]


func _physics_process(delta: float) -> void:
	if _done or _race == null or _report_path != "":
		return
	if _race.state != Race.State.RUNNING:
		return
	var cars: Array[Car] = _race.cars
	if not _go_seen:
		_go_seen = true
		if _sabotage == "viteza":
			for car in cars:
				car.max_speed *= 1.10
	_elapsed += delta
	var all_done := true
	for i in cars.size():
		var car := cars[i]
		var laps_now := int(_race._progress[i].laps)
		if laps_now > _last_laps[i]:
			(_lap_marks[i] as Array).append(_elapsed)
		_last_laps[i] = laps_now
		if (_lap_marks[i] as Array).size() < _laps + 1:
			all_done = false
		# Plafonul REAL al masinii in clipa asta, din parametrii ei de START
		# (sabotajul de viteza nu-si muta singur rigla).
		var p0: Array = _params0[i]
		var cap := float(p0[0]) * float(p0[3]) + float(p0[5])
		if car.is_boosting:
			cap += float(p0[4])
		var v := car.horizontal_speed()
		_speed_samples[i] += 1
		if v > cap * SPEED_SLACK:
			_speed_over[i] += 1
		_speed_peak_ratio[i] = maxf(_speed_peak_ratio[i], v / maxf(cap, 0.001))
	if all_done or _elapsed >= _timeout_s:
		_finish(cars, all_done)


func _finish(cars: Array[Car], all_done: bool) -> void:
	_done = true
	for i in cars.size():
		if _params_of(cars[i]) != _params0[i]:
			_params_ok = false
			_params_note = "%s: fizica schimbata in cursa (%s -> %s)" % [
				cars[i].pilot_name, str(_params0[i]), str(_params_of(cars[i]))]
	var all_laps: Array[float] = []
	var per_car: Array[String] = []
	var over := 0
	var samples := 0
	var peak := 0.0
	var resp := 0
	var late := 0
	var wide := 0
	for i in cars.size():
		var marks: Array = _lap_marks[i]
		var car_laps: Array[float] = []
		for k in range(1, marks.size()):
			car_laps.append(float(marks[k]) - float(marks[k - 1]))
		all_laps.append_array(car_laps)
		per_car.append("%s:%s" % [cars[i].car_name.replace(" ", "_"),
			",".join(PackedStringArray(car_laps.map(func(x: float) -> String: return "%.2f" % x)))])
		over += _speed_over[i]
		samples += _speed_samples[i]
		peak = maxf(peak, _speed_peak_ratio[i])
		resp += _respawns[i]
		var ai := cars[i].controller as AIController
		var md: Variant = ai.get("mistakes_done")
		if md != null:
			late += int(md[0])
			wide += int(md[1])
	var over_frac := float(over) / maxf(float(samples), 1.0)
	var wall_s := float(Time.get_ticks_msec() - _t_wall0) / 1000.0
	var line := ("AISKILL_RESULT track=%d label=%s seed=%d skill=%s sabotaj=%s "
		+ "lap_mean=%.3f lap_med=%.3f laps=%d complete=%d respawns=%d speed_over=%.5f "
		+ "speed_peak=%.3f params_ok=%d mistakes=%d,%d sim_s=%.1f wall_s=%.1f resp_at=%s per_car=%s") % [
		_track_index, GameState.track_label(_track_index).replace(" ", "_"), _seed,
		_tag if not _tag.is_empty() else _skill_name,
		_sabotage if not _sabotage.is_empty() else "-",
		_mean(all_laps), _median(all_laps), all_laps.size(), 1 if all_done else 0, resp, over_frac,
		peak, 1 if _params_ok else 0, late, wide, _elapsed, wall_s,
		",".join(PackedStringArray(_resp_at)) if not _resp_at.is_empty() else "-",
		";".join(per_car)]
	print(line)
	if not _params_ok:
		print("parametri: " + _params_note)
	if not _out_path.is_empty():
		var f := FileAccess.open(_out_path, FileAccess.READ_WRITE) \
			if FileAccess.file_exists(_out_path) else FileAccess.open(_out_path, FileAccess.WRITE)
		if f != null:
			f.seek_end()
			f.store_line(line)
			f.close()
	get_tree().quit(0)


## Media tururilor lansate ale tuturor masinilor. Media, nu mediana: pe pistele
## cu hazarde pe ceas (carul Gion, discul daruma din Kyoto) timpii pe tur sunt
## BIMODALI — cine prinde fereastra trece, cine nu asteapta un ciclu — iar
## mediana sare intre cele doua moduri de la o rulare la alta. Media le cantareste
## cum le simte jucatorul: in timpul total al cursei.
static func _mean(xs: Array[float]) -> float:
	if xs.is_empty():
		return -1.0
	var t := 0.0
	for x in xs:
		t += x
	return t / float(xs.size())


static func _median(xs: Array[float]) -> float:
	if xs.is_empty():
		return -1.0
	var s := xs.duplicate()
	s.sort()
	var n := s.size()
	return s[n / 2] if n % 2 == 1 else 0.5 * (s[n / 2 - 1] + s[n / 2])


# ---------------------------------------------------------------- raportul

## Citeste toate liniile `AISKILL_RESULT` si judeca cele trei contracte.
## Ecartul se calculeaza PE PERECHI (acelasi seed, acelasi traseu, acelasi
## zar), fata de referinta, apoi se ia mediana pe seed-uri.
func _report(path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		print("VERDICT: PROBLEMA — nu pot citi %s" % path)
		return false
	# rows[track][skill][seed] = {lap, resp, ...}
	var rows: Dictionary = {}
	var labels: Dictionary = {}
	var problems: Array[String] = []
	var wall_total := 0.0
	var runs := 0
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if not line.begins_with("AISKILL_RESULT"):
			continue
		var kv := {}
		for tok in line.split(" "):
			var eq := tok.find("=")
			if eq > 0:
				kv[tok.substr(0, eq)] = tok.substr(eq + 1)
		var t := int(kv.track)
		labels[t] = String(kv.label).replace("_", " ")
		var sk := String(kv.skill)
		if not rows.has(t):
			rows[t] = {}
		if not rows[t].has(sk):
			rows[t][sk] = {}
		rows[t][sk][int(kv.seed)] = {
			"lap": float(kv.get("lap_mean", kv.lap_med)), "resp": int(kv.respawns),
			"complete": int(kv.complete), "over": float(kv.speed_over),
			"peak": float(kv.speed_peak), "params": int(kv.params_ok),
			"sab": String(kv.get("sabotaj", "-")),
		}
		wall_total += float(kv.wall_s)
		runs += 1
	print("probe_ai_skill: %d rulari, %.0f s de ceas in total (%.0f s/rulare)" % [
		runs, wall_total, wall_total / maxf(float(runs), 1.0)])
	print("\n%-22s %-10s %6s %10s %16s %8s %7s %9s" % [
		"pista", "nivel", "seeds", "tur s", "ecart% med[q1,q3]", "ord.ok", "repun.", "v_peak"])
	var tracks := rows.keys()
	tracks.sort()
	for t in tracks:
		var by: Dictionary = rows[t]
		if not by.has("referinta"):
			problems.append("%s: lipseste referinta" % labels[t])
			continue
		var ref: Dictionary = by.referinta
		var gaps: Dictionary = {}
		for sk in ["referinta", "aur", "argint", "implicit", "bronz"]:
			if not by.has(sk):
				continue
			var d: Dictionary = by[sk]
			var g: Array[float] = []
			var laps: Array[float] = []
			var resp := 0
			var peak := 0.0
			for seed in d:
				var r: Dictionary = d[seed]
				resp += int(r.resp)
				peak = maxf(peak, float(r.peak))
				if int(r.params) != 1:
					problems.append("VITEZA %s %s seed %d: parametrii de fizica ai masinii schimbati"
						% [labels[t], sk, seed])
				if float(r.over) > SPEED_OVER_MAX:
					problems.append("VITEZA %s %s seed %d: %.1f%% din timp peste plafonul masinii x%.2f"
						% [labels[t], sk, seed, float(r.over) * 100.0, SPEED_SLACK])
				if float(r.lap) <= 0.0 or int(r.complete) != 1:
					problems.append("%s %s seed %d: cursa nu s-a incheiat (tururi lipsa)"
						% [labels[t], sk, seed])
					continue
				laps.append(float(r.lap))
				if ref.has(seed) and float(ref[seed].lap) > 0.0:
					g.append((float(r.lap) / float(ref[seed].lap) - 1.0) * 100.0)
			gaps[sk] = g
			var q := _quartiles(g)
			print("%-22s %-10s %6d %10.2f %7.1f [%5.1f,%5.1f] %8s %7d %9.3f" % [
				labels[t], sk, d.size(), _median(laps), q.y, q.x, q.z, "", resp, peak])
		# ORDINE: mediane Bronz > Argint > Aur, plus perechi pe seed.
		var order := ["aur", "argint", "bronz"]
		for k in range(order.size() - 1):
			var lo: String = order[k]
			var hi: String = order[k + 1]
			if not (gaps.has(lo) and gaps.has(hi)):
				continue
			var m_lo := _median(gaps[lo])
			var m_hi := _median(gaps[hi])
			var wins := 0
			var pairs := 0
			for seed in by[lo]:
				if by[hi].has(seed) and float(by[lo][seed].lap) > 0.0 \
						and float(by[hi][seed].lap) > 0.0:
					pairs += 1
					if float(by[hi][seed].lap) > float(by[lo][seed].lap):
						wins += 1
			var ok := m_hi > m_lo and wins * 2 > pairs
			print("    ordine %s < %s: mediane %.1f%% < %.1f%%, perechi %d/%d %s" % [
				lo, hi, m_lo, m_hi, wins, pairs, "ok" if ok else "PICA"])
			if not ok:
				problems.append("ORDINE %s: %s (%.1f%%) nu e mai lent decat %s (%.1f%%), perechi %d/%d"
					% [labels[t], hi, m_hi, lo, m_lo, wins, pairs])
		# REPUNERI: Bronz fata de implicit, pe aceleasi seed-uri.
		if by.has("bronz") and by.has("implicit"):
			var rb := 0
			var ri := 0
			var n := 0
			for seed in by.bronz:
				if by.implicit.has(seed):
					rb += int(by.bronz[seed].resp)
					ri += int(by.implicit[seed].resp)
					n += 1
			var cap := float(ri) * RESPAWN_FACTOR + RESPAWN_SLACK_PER_SEED * float(n)
			var ok_r := float(rb) <= cap
			print("    repuneri bronz %d vs implicit %d pe %d seed-uri (plafon %.0f) %s" % [
				rb, ri, n, cap, "ok" if ok_r else "PICA"])
			if not ok_r:
				problems.append("REPUNERI %s: bronz %d fata de implicit %d (plafon %.0f)"
					% [labels[t], rb, ri, cap])
	print("")
	if problems.is_empty():
		print("VERDICT: OK — ordinea, plafonul de viteza si repunerile tin pe %d piste" % tracks.size())
		return true
	for p in problems:
		print("  - " + p)
	print("VERDICT: PROBLEMA — %d incalcari" % problems.size())
	return false


## (q1, mediana, q3) ale unei liste; zero pe lista goala.
static func _quartiles(xs: Array[float]) -> Vector3:
	if xs.is_empty():
		return Vector3.ZERO
	var s := xs.duplicate()
	s.sort()
	var n := s.size()
	return Vector3(s[int(floor((n - 1) * 0.25))], _median(xs), s[int(ceil((n - 1) * 0.75))])
