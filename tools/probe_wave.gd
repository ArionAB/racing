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
##   3. EFECTUL — masina de sub el chiar intra in aquaplanare (`slip_time > 0`)
##   4. MATURAREA — creasta trece peste axa drumului si iese in larg
##   5. COTA — cat e in larg, valul coboara spre nivelul marii in loc sa
##      pluteasca la cota soselei, peste un dig de 1.6 m
## ############################################################################

## Cate cadre urmarim per pista. Perioada valului e 9 s, deci 12 s la 60 fps
## prind un ciclu intreg cu marja, indiferent de defazaj.
const FRAMES: int = 720
## Cadre lasate pistei sa se construiasca, inainte sa asezam masina.
const WARMUP: int = 4

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
	if _frames == WARMUP:
		_place()
		return
	if _frames > WARMUP:
		_sample()
	if _frames < WARMUP + FRAMES:
		return
	_report()
	remove_child(_track)
	_track.free()
	_track = null
	_index += 1


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

	# 1. Ancora. Originea pistei e (0,0,0), deci un val care matura acolo cand
	#    sectorul lui e la sute de metri se vede ca ancora ~zero.
	_check(anchor.length() > 1.0, "valul e ancorat pe sector, nu pe originea pistei")
	# 2. Ceasul. Ambele capete conteaza: si „uda mereu", si „nu uda niciodata"
	#    sunt moduri de a nu avea gimmick.
	_check(wet_pct > 5.0 and wet_pct < 60.0,
		"apa e un CEAS (pornita intre 5% si 60% din ciclu)")
	# 3. Efectul. Aici cade orice sonda care doar numara instante.
	_check(slip_pct > 0.0, "masina de sub val chiar intra in aquaplanare")
	# 4. Maturarea trece peste axa drumului si iese binisor in larg.
	_check(_min_dist < 3.0 and _max_dist > 10.0, "valul traverseaza toata soseaua")
	# 5. Cota. Daca pista i-a dat linia apei, creasta coboara sub sosea cat e in
	#    larg; altfel ar pluti in aer peste dig.
	var water_y: float = _wave.get("water_y")
	if is_finite(water_y):
		_check(_min_y < road_y - 0.5, "in larg valul coboara spre nivelul marii")


func _check(ok: bool, label: String) -> void:
	print("  [%s] %s" % ["OK" if ok else "!!", label])
	if not ok:
		_failed = true
