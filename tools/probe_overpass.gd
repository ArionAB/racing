extends Node
## Sonda „pistei peste pista": o pista-test in care soseaua trece la ~15 m
## peste un tronson anterior al ei, si trei intrebari tiparite cu cifre.
##
##  (i)   TERENUL: sub tablier, etajul de jos ramane pe pamant (nu e ingropat)
##        si tablierul ramane in aer (terenul nu urca dupa el).
##  (ii)  CADEREA: o masina care aterizeaza pe etajul de jos tinand inca
##        indexul etajului de sus isi muta indexul pe etajul de jos in sub 1 s
##        si NU isi innoieste checkpoint-ul pe etajul de sus. Si controlul:
##        o masina pe tablier, cu indexul tablierului, ramane acolo.
##  (iii) REPUNEREA: dupa cadere, repunerea vine pe etajul pe care ai cazut.
##
## Ruleaza CA SCENA (masina cere autoload-urile):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeOverpass.tscn
##   ... -- [--no-fix]
##
## `--no-fix` construieste pista FARA intervalul de pasaj (terenul vechi, care
## face media etajelor) — martorul A/B pentru (i). Iese cu cod 1 la orice
## verdict picat, ca sa poata fi garda.

const CAR_SCENE: String = "res://scenes/cars/Car.tscn"
## Bucla: drept pe z=0 (etajul de jos), urcare pe la est, intoarcere pe
## x=40 la 15 m PESTE dreapta de jos, coborare pe la vest.
const POINTS: Array[Vector3] = [
	Vector3(0, 0, 0), Vector3(80, 0, 0), Vector3(140, 0, -30),
	Vector3(150, 4, -100), Vector3(100, 10, -150), Vector3(40, 15, -100),
	Vector3(40, 15, 0), Vector3(40, 15, 60), Vector3(0, 10, 100),
	Vector3(-60, 5, 70), Vector3(-70, 0, 10), Vector3(-40, 0, 0),
]
const CROSS_X: float = 40.0
## De la ce cota (peste etajul de jos) un punct copt e „pe tablier".
const DECK_MIN_LIFT: float = 6.0
const SETTLE_SECONDS: float = 1.5

var _no_fix: bool = false
var _track: TrackFromPath
var _lo_i: int = -1
var _hi_i: int = -1
var _fails: int = 0


func _ready() -> void:
	_no_fix = "--no-fix" in OS.get_cmdline_user_args()
	_track = TrackFromPath.new()
	var path := Path3D.new()
	path.name = "Path"
	var curve := Curve3D.new()
	for p in POINTS:
		curve.add_point(p)
	path.curve = curve
	_track.add_child(path)
	_track.custom_name = "ProbeOverpass"
	_track.custom_theme = "desert"
	_track.custom_half_width = 6.0
	add_child(_track)
	await get_tree().process_frame
	_find_crossing()
	if not _no_fix:
		_track.custom_overpass_ranges = [_deck_range()]
		_track.rebuild()
		await get_tree().process_frame
		_find_crossing()
	print("=== PISTA PESTE PISTA (%s) ===" % ("FARA fix, martor" if _no_fix else "cu pasaj"))
	print("  jos: [%d] %s   sus: [%d] %s" % [_lo_i, str(_track.baked[_lo_i]),
		_hi_i, str(_track.baked[_hi_i])])
	_check_terrain()
	await _check_fall()
	await _check_stay()
	await _check_respawn()
	print("=== %s ===" % ("PICAT: %d verdicte" % _fails if _fails > 0 else "TOATE OK"))
	get_tree().quit(1 if _fails > 0 else 0)


## Indexul de jos si cel de sus la incrucisare (x=40, z=0).
func _find_crossing() -> void:
	var best_lo := INF
	var best_hi := INF
	for i in _track.baked.size():
		var p: Vector3 = _track.baked[i]
		var d := Vector2(p.x - CROSS_X, p.z).length()
		if p.y < DECK_MIN_LIFT and d < best_lo:
			best_lo = d
			_lo_i = i
		elif p.y >= DECK_MIN_LIFT and d < best_hi:
			best_hi = d
			_hi_i = i


## Intervalul de fractii al tablierului: tot ce sta peste DECK_MIN_LIFT.
func _deck_range() -> Vector2:
	var n := _track.baked.size()
	var first := -1
	var last := -1
	for i in n:
		if _track.baked[i].y >= DECK_MIN_LIFT:
			if first < 0:
				first = i
			last = i
	var f0 := _track.frac_at(first)
	var f1 := _track.frac_at(last)
	print("  tablier: indici %d..%d, fractii %.3f..%.3f" % [first, last, f0, f1])
	return Vector2(f0, f1)


func _verdict(ok: bool, text: String) -> void:
	print("  [%s] %s" % ["OK" if ok else "PICAT", text])
	if not ok:
		_fails += 1


# ------------------------------------------------------------------ (i)

func _check_terrain() -> void:
	print("--- (i) terenul la incrucisare")
	var sampler: TrackSideSampler = _track.get("_sampler")
	var buried := 0.0
	var lifted := 0.0
	for off in range(-6, 7):
		var i := posmod(_lo_i + off, _track.baked.size())
		var p: Vector3 = _track.baked[i]
		var g := sampler.ground_y(p.x, p.z)
		buried = maxf(buried, g - p.y)
		if off % 3 == 0:
			print("    jos [%3d] drum %.2f teren %.2f  diff %+.2f" % [i, p.y, g, g - p.y])
	for off in range(-6, 7):
		var i := posmod(_hi_i + off, _track.baked.size())
		var p: Vector3 = _track.baked[i]
		var g := sampler.ground_y(p.x, p.z)
		lifted = maxf(lifted, g - (_track.baked[_lo_i].y))
		if off % 3 == 0:
			print("    sus [%3d] tablier %.2f teren %.2f  gol %.2f" % [i, p.y, g, p.y - g])
	# Terenul sta cu ~0.3 m sub buza asfaltului (GROUND_DROP); tot ce e peste
	# +0.15 inseamna asfalt ingropat, ca in probe_branch.
	_verdict(buried <= 0.15, "etajul de jos nu e ingropat (max teren-drum %+.2f m)" % buried)
	_verdict(lifted <= 1.0, "terenul de sub tablier ramane la etajul de jos (max +%.2f m)" % lifted)


# ------------------------------------------------------------------ (ii)

func _spawn(at: Vector3, index: int) -> Car:
	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(car)
	car.apply_data(GameState.CAR_DATA[0])
	car.track = _track
	car.global_transform = Transform3D(Basis.IDENTITY, at)
	car.velocity = Vector3.ZERO
	car.route = 0
	car.road_index = index
	car.last_safe_index = index
	car.last_safe_route = 0
	car.race_active = true
	return car


func _settle() -> void:
	var frames := int(SETTLE_SECONDS * 60.0)
	for _f in frames:
		await get_tree().physics_frame


func _check_fall() -> void:
	print("--- (ii) aterizare pe etajul de jos cu indexul etajului de sus")
	var lo: Vector3 = _track.baked[_lo_i]
	var car := _spawn(lo + Vector3(0, 1.5, 0), _hi_i)
	await _settle()
	var d := absi(car.road_index - _lo_i)
	var on_lo := _track.is_on_road(car.road_index, car.global_position)
	var safe_d := absi(car.last_safe_index - _lo_i)
	print("    index %d (jos e %d, sus e %d), y=%.2f, pe sosea=%s, safe=%d"
		% [car.road_index, _lo_i, _hi_i, car.global_position.y, str(on_lo),
		car.last_safe_index])
	_verdict(d <= 6, "indexul s-a mutat pe etajul de jos (|delta|=%d)" % d)
	_verdict(on_lo, "e „pe sosea” pe etajul de jos")
	_verdict(safe_d <= 6, "checkpoint-ul e pe etajul de jos, nu pe cel de sus (|delta|=%d)" % safe_d)
	car.queue_free()
	await get_tree().process_frame


func _check_stay() -> void:
	print("--- (ii-b) control: pe tablier, cu indexul tablierului")
	var hi: Vector3 = _track.baked[_hi_i]
	var car := _spawn(hi + Vector3(0, 1.0, 0), _hi_i)
	await _settle()
	var d := absi(car.road_index - _hi_i)
	var on_hi := _track.is_on_road(car.road_index, car.global_position)
	print("    index %d (sus e %d), y=%.2f, pe sosea=%s" % [car.road_index, _hi_i,
		car.global_position.y, str(on_hi)])
	_verdict(d <= 6, "indexul a ramas pe tablier (|delta|=%d)" % d)
	_verdict(on_hi, "e „pe sosea” pe tablier")
	_verdict(car.global_position.y > hi.y - 1.0, "masina sta PE tablier, nu a cazut prin el (y=%.2f)" % car.global_position.y)
	car.queue_free()
	await get_tree().process_frame


# ------------------------------------------------------------------ (iii)

func _check_respawn() -> void:
	print("--- (iii) repunere dupa cadere")
	var lo: Vector3 = _track.baked[_lo_i]
	var car := _spawn(lo + Vector3(0, 1.5, 0), _hi_i)
	await _settle()
	car.respawn()
	await get_tree().physics_frame
	var y := car.global_position.y
	print("    dupa repunere y=%.2f (jos %.2f, sus %.2f), index %d" % [y, lo.y,
		_track.baked[_hi_i].y, car.road_index])
	_verdict(absf(y - lo.y) < 3.0, "repus pe etajul de jos")
	car.queue_free()
