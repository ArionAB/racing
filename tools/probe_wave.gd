extends Node
## Garda hazardului de APA: unde e asezat, cand uda si daca CHIAR uda.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeWave.tscn
##   ... res://tools/ProbeWave.tscn -- --track=8
##
## Numarul pistei e cel din NUMELE FISIERULUI (8 = Track08, „Okinawa manual"),
## ca la `tools/probe_decor.gd` si spre deosebire de `probe_typhoon.gd`, care
## numara indexul din GameState. Fara argument, trece prin toate pistele.
##
## Ruleaza CA SCENA, nu cu --script: masina de proba are nevoie de autoload-uri
## (car.gd cheama AudioManager), iar cu --script scriptul ei nici nu compileaza.
##
## ############################################################################
## DE CE EXISTA
##
## Valul nu se poate verifica numarand instante. Un `WaveSurge` prezent in
## arbore trece testul si cand matura la ORIGINEA pistei in loc de sectorul lui
## (bug real, trait pe Track05 pana cand tromba l-a copiat si l-a documentat), si
## cand uda NON-STOP, si cand nu uda NICIODATA. Toate trei arata identic intr-o
## numaratoare de noduri. Deci sonda parcheaza o masina pe drum, sub val, si
## citeste ce se intampla cu ea.
##
## Ce verifica, pe fiecare pista cu val:
##   1. ANCORA — hazardul matura in jurul sectorului cerut, nu al originii
##   2. CEASUL — de-a lungul unui ciclu apa e si pornita, si oprita (un hazard
##      care uda mereu nu e o decizie, e o taxa; unul care nu uda niciodata e
##      decor)
##   3. EFECTUL — masina de sub el chiar patteste ceva: intra in aquaplanare
##      (`slip_time > 0`) SI e imbrancita din loc. Aquaplanarea singura nu era
##      destul, si a fost o observatie de playtest, nu de sonda: pe o dreapta de
##      200 m nu ceri aderenta laterala, deci n-ai ce pierde — valul „nu se
##      simtea" desi trecea peste masina. De-aia se masoara acum si CAT DE MULT
##      te muta.
##   4. MATURAREA — creasta trece peste axa drumului si iese in larg
##   5. COTA — cat e in larg, valul coboara spre nivelul marii in loc sa
##      pluteasca la cota soselei, peste un dig de 1.6 m
##   6. TRECEREA — o masina care intra in sector la viteza de cursa, o data cu
##      valul peste ea si o data fara. DIFERENTA dintre cele doua rulari e, prin
##      constructie, exact ce face valul: cati metri te scoate de pe linie si
##      cate km/h iti ia. Fizica e determinista la `--fixed-fps 60`, deci
##      diferenta nu are de unde sa vina din altceva.
## ############################################################################

## Cate cadre urmarim per pista. Perioada valului e 9 s, deci 12 s la 60 fps
## prind un ciclu intreg cu marja, indiferent de defazaj.
const FRAMES: int = 720
## Cadre lasate pistei sa se construiasca, inainte sa asezam masina.
const WARMUP: int = 4

## --- proba de trecere ---
## De cati metri inainte de val porneste masina.
const RUN_UP: float = 40.0
## Cu ce viteza intra. 26 m/s ~ 94 km/h, adica viteza de croaziera pe digul de
## start (masurata in joc: 62 km/h iesind din viraj, peste 100 pe dreapta).
const ENTRY_SPEED: float = 26.0
## Cat urmarim trecerea. 3 s: intrarea, valul, si iesirea din sector. Mai mult
## inseamna ca masina ajunge in poarta de start si masuram poarta.
const DRIVE_FRAMES: int = 180

var _paths: Array[String] = []
var _index: int = 0
var _track: Node = null
var _car: Node3D = null
var _wave: Node3D = null
var _hoses: int = 0
var _frames: int = 0
var _wet_frames: int = 0
var _slip_frames: int = 0
var _min_dist: float = 1e9
var _max_dist: float = 0.0
var _min_y: float = 1e9
## Cat de departe a fost imbrancita masina de unde am parcat-o, si ce viteza a
## capatat. Amandoua pornesc de la zero: masina n-are controller si nu se misca
## singura, deci orice metru si orice m/s vin de la val.
var _car_drift: float = 0.0
var _car_speed: float = 0.0
var _car_home: Vector3 = Vector3.ZERO
## Proba de trecere: unde a ajuns masina si cu ce viteza, in fiecare rulare.
var _pass_hit: Vector2 = Vector2.ZERO
var _pass_miss: Vector2 = Vector2.ZERO
var _pass_hit_pos: Vector3 = Vector3.ZERO
var _pass_miss_pos: Vector3 = Vector3.ZERO
var _drive_hit: bool = true
var _drive_car: Car = null
var _drive_frames: int = 0
var _drive_dev: float = 0.0
var _drive_slow: float = 1e9
## Din rularea FARA val: in ce cadru trece masina pe dreptul valului si cat de
## lateral e atunci. Cu ele se potriveste ceasul in rularea CU val.
var _cross_frame: int = -1
var _cross_lateral: float = 0.0
var _cross_best: float = 1e9
var _phase: int = 0 # 0 = val singur, 1 = trecere cu val, 2 = trecere fara
var _failed: bool = false


func _ready() -> void:
	var only := -1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			only = int(arg.trim_prefix("--track="))
	for i in range(1, 10):
		var path := "res://scenes/tracks/Track%02d.tscn" % i
		if not ResourceLoader.exists(path):
			continue
		if only < 0 or only == i:
			_paths.append(path)
	if _paths.is_empty():
		push_error("probe_wave: nu am gasit nicio pista")
		get_tree().quit(1)


func _physics_process(_delta: float) -> void:
	if _track == null:
		if _index >= _paths.size():
			print("\n", "PICAT" if _failed else "TRECUT")
			get_tree().quit(1 if _failed else 0)
			return
		_track = (load(_paths[_index]) as PackedScene).instantiate()
		add_child(_track)
		_reset()
		return
	_frames += 1
	if _phase == 0:
		if _frames == WARMUP:
			_place()
			return
		if _frames > WARMUP:
			_sample()
		if _frames < WARMUP + FRAMES:
			return
		_report()
		if _wave == null:
			_next_track()
			return
		_phase = 1
		_start_pass(false)
		return
	# Proba de trecere, de doua ori: cu valul peste masina si fara el.
	_drive_frames += 1
	_watch_pass()
	if _drive_frames < DRIVE_FRAMES:
		return
	if _phase == 1:
		_pass_miss = Vector2(_drive_dev, _drive_slow)
		_pass_miss_pos = _drive_car.global_position
		_phase = 2
		_start_pass(true)
		return
	_pass_hit = Vector2(_drive_dev, _drive_slow)
	_pass_hit_pos = _drive_car.global_position
	_report_pass()
	_next_track()


func _next_track() -> void:
	remove_child(_track)
	_track.free()
	_track = null
	_track = null
	_index += 1
	_phase = 0


func _reset() -> void:
	_frames = 0
	_wet_frames = 0
	_slip_frames = 0
	_min_dist = 1e9
	_max_dist = 0.0
	_min_y = 1e9
	_car = null
	_wave = null
	_hoses = 0
	_car_drift = 0.0
	_car_speed = 0.0


## Gaseste hazardele de apa si parcheaza o masina exact sub val.
func _place() -> void:
	for node in _track.get_children():
		if node is WaveSurge:
			_wave = node
		elif node is WaterHose:
			_hoses += 1
	if _wave == null:
		return
	# Masina sta pe ancora — adica pe axa soselei, in mijlocul sectorului maturat.
	# Fara controller si fara `track`, ramane pe loc si isi vede doar de fizica:
	# tot ce ne intereseaza de la ea e `slip_time`.
	_car = (load("res://scenes/cars/Car.tscn") as PackedScene).instantiate() as Node3D
	_track.add_child(_car)
	var anchor: Vector3 = _wave.get("_anchor")
	_car.global_position = _track.to_global(anchor) + Vector3.UP * 0.6
	_car_home = _car.global_position


func _sample() -> void:
	if _wave == null:
		return
	var wet: bool = _wave.get("_wet")
	if wet:
		_wet_frames += 1
	if _car != null:
		var slip: float = _car.get("slip_time")
		if slip > 0.0:
			_slip_frames += 1
		var off := _car.global_position - _car_home
		_car_drift = maxf(_car_drift, Vector2(off.x, off.z).length())
		var v: Vector3 = _car.get("velocity")
		_car_speed = maxf(_car_speed, Vector2(v.x, v.z).length())
	# Distanta pana la ancora, pe orizontala: cat de departe matura valul.
	var anchor: Vector3 = _wave.get("_anchor")
	var d := Vector2(_wave.position.x - anchor.x, _wave.position.z - anchor.z).length()
	_min_dist = minf(_min_dist, d)
	_max_dist = maxf(_max_dist, d)
	_min_y = minf(_min_y, _wave.position.y)


func _report() -> void:
	var track_name: String = _track.get("track_name")
	print("\n=== ", track_name, " (", _paths[_index], ") ===")
	print("  conducte (WaterHose): %d" % _hoses)
	if _wave == null:
		print("  val (WaveSurge): niciunul")
		return
	var anchor: Vector3 = _wave.get("_anchor")
	var road_y := anchor.y
	var wet_pct := 100.0 * float(_wet_frames) / float(FRAMES)
	var slip_pct := 100.0 * float(_slip_frames) / float(FRAMES)
	print("  ancora: (%.1f, %.1f, %.1f)" % [anchor.x, anchor.y, anchor.z])
	print("  maturare fata de ancora: %.1f .. %.1f m" % [_min_dist, _max_dist])
	print("  cota: sosea %.2f m, cel mai jos varf de val %.2f m" % [road_y, _min_y])
	print("  apa pornita %.0f%% din timp; masina in aquaplanare %.0f%%"
		% [wet_pct, slip_pct])
	print("  masina imbrancita: %.1f m, viteza capatata %.1f m/s"
		% [_car_drift, _car_speed])

	# 1. Ancora. Originea pistei e (0,0,0), deci un val care matura acolo cand
	#    sectorul lui e la sute de metri se vede ca ancora ~zero.
	_check(anchor.length() > 1.0, "valul e ancorat pe sector, nu pe originea pistei")
	# 2. Ceasul. Ambele capete conteaza: si „uda mereu", si „nu uda niciodata"
	#    sunt moduri de a nu avea gimmick.
	_check(wet_pct > 5.0 and wet_pct < 60.0,
		"apa e un CEAS (pornita intre 5% si 60% din ciclu)")
	# 3. Efectul, si e in doua bucati fiindca una singura minte. Aquaplanarea
	#    arata ca zona prinde masina; imbrancitura arata ca se si INTAMPLA ceva
	#    ce simti mergand drept.
	_check(slip_pct > 0.0, "masina de sub val chiar intra in aquaplanare")
	_check(_car_drift > 1.5, "masina e imbrancita din loc (peste 1.5 m)")
	# 4. Maturarea trece peste axa drumului si iese binisor in larg.
	_check(_min_dist < 3.0 and _max_dist > 10.0, "valul traverseaza toata soseaua")
	# 5. Cota. Daca pista i-a dat linia apei, creasta coboara sub sosea cat e in
	#    larg; altfel ar pluti in aer peste dig.
	var water_y: float = _wave.get("water_y")
	if is_finite(water_y):
		_check(_min_y < road_y - 0.5, "in larg valul coboara spre nivelul marii")


## Porneste o trecere: masina la `RUN_UP` metri inainte de val, pe axa soselei,
## in sensul cursei, cu AI la volan.
##
## `hit` potriveste CEASUL valului ca sa fie fix peste sosea cand ajunge masina;
## fara el, valul e trimis in larg. Restul — pista, linia AI-ului, viteza de
## intrare — sunt identice, deci diferenta dintre rulari e numai valul.
func _start_pass(hit: bool) -> void:
	_drive_hit = hit
	_drive_frames = 0
	_drive_dev = 0.0
	_drive_slow = 1e9
	if not hit:
		_cross_frame = -1
		_cross_best = 1e9
	if _drive_car != null and is_instance_valid(_drive_car):
		_drive_car.queue_free()
	if _car != null and is_instance_valid(_car):
		_car.queue_free()
		_car = null
	var track := _track as Track
	var wave_idx: int = track.closest_index_global(_wave.get("_anchor"))
	var baked: Array = track.get("baked")
	var n := baked.size()
	# Cu cati indici inapoi cade RUN_UP: punctele coapte sunt echidistante.
	var step: float = (baked[1] as Vector3).distance_to(baked[0])
	var back := int(RUN_UP / maxf(step, 0.01))
	var start_idx := (wave_idx - back + n) % n
	var here: Vector3 = baked[start_idx]
	var dir: Vector3 = ((baked[(start_idx + 1) % n] as Vector3) - here).normalized()
	_drive_car = (load("res://scenes/cars/Car.tscn") as PackedScene).instantiate() as Car
	_drive_car.track = track
	track.add_child(_drive_car)
	_drive_car.global_position = here + Vector3.UP * 0.6
	_drive_car.look_at(here + dir, Vector3.UP)
	_drive_car.velocity = dir * ENTRY_SPEED
	_drive_car.road_index = start_idx
	# FARA controller, si e o alegere de masurare, nu o scurtatura. Cu AI la
	# volan, prima rulare a sonzei a masurat AI-ul: masina se ducea singura la
	# 5 m de axa si intra intr-un parapet inainte sa ajunga la val, identic in
	# ambele rulari. O masina lansata si lasata sa ruleze n-are pareri — orice
	# metru lateral si orice km/h in minus vin de la ce a intalnit pe drum, adica
	# exact ce vrem sa citim.
	_drive_car.race_active = false
	# Ceasul valului. In rularea „fara" il trimitem in larg; in cea „cu" il
	# potrivim pe MOMENTUL SI LOCUL in care a trecut masina in rularea dinainte,
	# nu pe o estimare `RUN_UP / ENTRY_SPEED`.
	#
	# Estimarea a fost prima incercare si a picat pe Track05: acolo drumul se
	# curbeaza inainte de causeway, deci masina lansata nu ajunge unde ar trebui
	# la secunda calculata, iar valul trecea pe langa ea. O sonda care rateaza
	# tinta raporteaza „hazardul nu se simte" — exact concluzia gresita.
	var period: float = WaveSurge.PERIOD
	var span: float = WaveSurge.ON_ROAD_FRAC + WaveSurge.LEAD_TIME / period
	var phase: float = _wave.get("phase")
	if not hit:
		_wave.set("_time", period * (span + 0.2 - phase))
		return
	# Fractia din traversare la care creasta e chiar peste masina.
	var sweep: float = _wave.get("sweep")
	var at := clampf((_cross_lateral + sweep) / (2.0 * sweep), 0.0, 1.0)
	var t_cross := span * at
	_wave.set("_time", period * (t_cross - phase) - float(_cross_frame) / 60.0)


func _watch_pass() -> void:
	if _drive_car == null or not is_instance_valid(_drive_car):
		return
	var track := _track as Track
	var idx: int = track.closest_index_global(_drive_car.global_position)
	var axis: Vector3 = track.point_at(idx)
	var off := _drive_car.global_position - axis
	_drive_dev = maxf(_drive_dev, Vector2(off.x, off.z).length())
	# Viteza se citeste la CAPATUL cursei, nu ca minim: o masina lansata pierde
	# oricum din viteza, in amandoua rularile la fel, si ce ne intereseaza e cat
	# a mai ramas dupa sector.
	_drive_slow = _drive_car.horizontal_speed()
	if _drive_hit:
		return
	# Rularea de referinta: retinem cadrul in care masina e cel mai aproape de
	# linia pe care matura valul, si cat de lateral e atunci.
	var anchor: Vector3 = _wave.get("_anchor")
	var here := (_track as Node3D).to_global(anchor)
	var to_car: Vector3 = _drive_car.global_position - here
	var travel: Vector3 = _wave.get("travel_dir")
	var along := absf(to_car.dot(travel.cross(Vector3.UP).normalized()))
	if along < _cross_best:
		_cross_best = along
		_cross_frame = _drive_frames
		_cross_lateral = to_car.dot(travel)


func _report_pass() -> void:
	# Diferenta dintre cele doua masini, DESFACUTA pe axele soselei. E singura
	# masura care nu minte: „deviatia fata de axa" creste si fara val, fiindca o
	# masina lansata merge drept si soseaua nu (prima versiune a sondei masura
	# chiar asta si iesea NEGATIVA), iar distanta bruta dintre ele amesteca
	# imbrancitura cu franarea — cine incetineste ramane si in urma.
	var track := _track as Track
	var idx: int = track.closest_index_global(_wave.get("_anchor"))
	var baked: Array = track.get("baked")
	var n := baked.size()
	var fwd: Vector3 = ((baked[(idx + 1) % n] as Vector3) - baked[idx]).normalized()
	var side := fwd.cross(Vector3.UP).normalized()
	var diff := _pass_hit_pos - _pass_miss_pos
	var lateral := absf(diff.dot(side))
	var behind := -diff.dot(fwd)
	var d_spd := _pass_miss.y - _pass_hit.y
	print("  trecere CU val:   viteza la iesire %.1f m/s" % _pass_hit.y)
	print("  trecere FARA val: viteza la iesire %.1f m/s" % _pass_miss.y)
	print("  => valul te muta %.1f m lateral, te lasa %.1f m in urma"
		% [lateral, behind])
	print("     si iti ia %.1f m/s din viteza" % d_spd)
	# Pragul de jos e „se simte", cel de sus e „nu te arunca de pe dig". Al doilea
	# e la fel de important: un hazard care te scoate de pe drum de fiecare data
	# nu e o decizie, e o taxa cu alt nume. 5 m pe o sosea cu jumatatea de 7
	# inseamna „ajungi pe cealalta banda", nu „in mare".
	#
	# „Se simte" se CERE doar acolo unde valul e singura sursa de apa. Pe Track05
	# el imparte fractia cu o conducta care uda drumul permanent, deci masina e
	# uda si in rularea de referinta si diferenta dintre rulari nu mai apartine
	# valului. Cifrele se tiparesc oricum — doar pragul nu se aplica.
	if _hoses == 0:
		_check(lateral > 0.8 or d_spd > 1.5, "trecerea prin val CHIAR se simte")
	else:
		print("  (prag sarit: sectorul are si conducta, deci apa e permanenta)")
	_check(lateral < 5.0, "valul nu te matura de pe dig")


func _check(ok: bool, label: String) -> void:
	print("  [%s] %s" % ["OK" if ok else "!!", label])
	if not ok:
		_failed = true
