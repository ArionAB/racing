extends Node
## Completarea LIVE a lui ProbeDirtRanges: o cursa intreaga (Race.tscn, jucator +
## AI) pe Dunele, in care intervalul de pamant e declarat pe pista, si se
## esantioneaza in fiecare cadru fizic toate masinile. Verifica bucla reala de
## efecte (Car._update_effects -> _update_dust), nu doar functiile apelate de mana:
##
##   - pe SOSEA, in interval, la viteza: praful porneste (>= 95% din esantioane);
##   - pe SOSEA, in afara intervalului (asfalt): praful NU porneste (< 1%);
##   - SABOTAJ: aceeasi cursa cu intervalul GOL — in portiunea in care ar fi fost
##     pamant, praful trebuie sa lipseasca (< 5%). Fara asta, un praf care
##     porneste "din alte motive" ar trece drept dovada.
##
## Intervalul se declara DUPA constructia pistei (cursa isi incarca pista din
## GameState): conteaza doar interogarile masinii; geometria o acopera
## ProbeDirtRanges. Ruleaza CA SCENA:
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeDirtRace.tscn
## Cod de iesire 1 la orice verdict picat sau la prea putine esantioane.

const RACE_SCENE: String = "res://scenes/race/Race.tscn"
const RANGE: Vector2 = Vector2(0.01, 0.30)
## Marginea fata de capetele intervalului, ca tranzitia (masina ia un cadru sa
## treaca) sa nu intre in statistica.
const MARGIN: float = 0.015
const SECONDS: float = 36.0
const MIN_SPEED: float = 8.0
const MIN_SAMPLES: int = 150

var _fails: int = 0


func _ready() -> void:
	await get_tree().process_frame
	print("=== ProbeDirtRace: Dunele, interval %s, %.0f s de cursa ===" % [RANGE, SECONDS])
	var real := await _run(true)
	var sab := await _run(false)

	var real_dirt_rate := _rate(real["dirt_dust"], real["dirt"])
	var real_asph_rate := _rate(real["asph_dust"], real["asph"])
	var sab_dirt_rate := _rate(sab["dirt_dust"], sab["dirt"])
	print("CU interval : pe sosea in interval %d esantioane, praf %.1f%% | pe asfalt %d esantioane, praf %.1f%% | drift pe pamant %d (fum colorat %d), drift pe asfalt %d (fum gri %d)" % [
		real["dirt"], real_dirt_rate * 100.0, real["asph"], real_asph_rate * 100.0,
		real["drift_dirt"], real["drift_dirt_tint"], real["drift_asph"], real["drift_asph_grey"]])
	print("SABOTAJ gol : pe sosea in portiunea (fara interval) %d esantioane, praf %.1f%%" % [
		sab["dirt"], sab_dirt_rate * 100.0])

	_expect("destule esantioane in interval (%d >= %d)" % [real["dirt"], MIN_SAMPLES],
		int(real["dirt"]) >= MIN_SAMPLES)
	_expect("destule esantioane pe asfalt (%d >= %d)" % [real["asph"], MIN_SAMPLES],
		int(real["asph"]) >= MIN_SAMPLES)
	_expect("pe sosea in interval praful porneste (%.1f%% >= 95%%)" % (real_dirt_rate * 100.0),
		real_dirt_rate >= 0.95)
	_expect("pe asfalt, in afara intervalului, praful NU porneste (%.1f%% < 1%%)" % (real_asph_rate * 100.0),
		real_asph_rate < 0.01)
	_expect("SABOTAJ: destule esantioane (%d >= %d)" % [sab["dirt"], MIN_SAMPLES],
		int(sab["dirt"]) >= MIN_SAMPLES)
	_expect("SABOTAJ: fara interval, in aceeasi portiune praful NU porneste (%.1f%% < 5%%)" % (sab_dirt_rate * 100.0),
		sab_dirt_rate < 0.05)
	# Fumul de drift: informativ daca nimeni n-a derapat (AI-ul deriveaza rar),
	# dar daca exista esantioane, pe pamant trebuie sa fie colorat, pe asfalt gri.
	if int(real["drift_dirt"]) > 0:
		_expect("fumul de drift pe pamant e colorat (%d/%d)" % [real["drift_dirt_tint"], real["drift_dirt"]],
			int(real["drift_dirt_tint"]) == int(real["drift_dirt"]))
	if int(real["drift_asph"]) > 0:
		_expect("fumul de drift pe asfalt e gri (%d/%d)" % [real["drift_asph_grey"], real["drift_asph"]],
			int(real["drift_asph_grey"]) == int(real["drift_asph"]))
	print("=== %s ===" % ("VERDICT: OK" if _fails == 0 else "VERDICT: PICAT"))
	get_tree().quit(1 if _fails > 0 else 0)


func _rate(a: int, b: int) -> float:
	return float(a) / float(maxi(b, 1))


## O cursa de SECONDS secunde; intoarce contoarele. `declare` pune intervalul pe
## pista; fara el, aceleasi esantioane se clasifica dupa intervalul VIRTUAL.
func _run(declare: bool) -> Dictionary:
	GameState.selected_track = 0
	GameState.selected_car = 0
	GameState.champ_active = false
	GameState.total_laps = 99
	var race := (load(RACE_SCENE) as PackedScene).instantiate()
	add_child(race)
	await get_tree().process_frame
	await get_tree().process_frame
	var track := race.get("track") as Track
	if declare:
		var ranges: Array[Vector2] = [RANGE]
		track.custom_dirt_ranges = ranges

	var s := {"dirt": 0, "dirt_dust": 0, "asph": 0, "asph_dust": 0,
		"drift_dirt": 0, "drift_dirt_tint": 0, "drift_asph": 0, "drift_asph_grey": 0}
	var frames := int(SECONDS * 60.0)
	for _f in frames:
		await get_tree().physics_frame
		for c: Car in (race.get("cars") as Array):
			if c.route != 0 or c.wheels_on_ground <= 0 or c._dust_particles == null:
				continue
			if not track.is_on_road(c.road_index, c.global_position):
				continue
			var f := track.frac_at(c.road_index)
			var in_range := f > RANGE.x + MARGIN and f < RANGE.y - MARGIN
			var past := f > RANGE.y + MARGIN
			var fast := c.horizontal_speed() > MIN_SPEED
			var dust := c._dust_particles.emitting
			if in_range and fast:
				s["dirt"] += 1
				if dust:
					s["dirt_dust"] += 1
			elif past and fast:
				s["asph"] += 1
				if dust:
					s["asph_dust"] += 1
			if c.is_drifting and c._drift_particles.emitting and (in_range or past):
				var grey := (c._drift_particles.color as Color).is_equal_approx(Car.DRIFT_SMOKE_COLOR)
				if in_range:
					s["drift_dirt"] += 1
					if not grey:
						s["drift_dirt_tint"] += 1
				else:
					s["drift_asph"] += 1
					if grey:
						s["drift_asph_grey"] += 1
	race.queue_free()
	await get_tree().process_frame
	return s


func _expect(name: String, ok: bool) -> void:
	print("%s %s" % ["OK   " if ok else "ESEC ", name])
	if not ok:
		_fails += 1
