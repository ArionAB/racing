extends Node
## Cat DESPRIND roatele de asfalt masinile lungi la coborare, fara nici o
## trambulina in fata.
##
## Intrebarea la care raspunde: "autobuzul si pompierii par ca zboara la
## coborare" e o impresie sau un fapt masurabil? Si daca e fapt, e legat de
## LUNGIMEA caroseriei? `floor_snap_length` e o constanta (2.0) pentru toate
## masinile, dar corpurile difera mult: muscle 4.20 m, pompierii 4.87,
## autobuzul 5.46. Un corp lung se balanseaza peste o creasta mai mult decat
## unul scurt, deci are nevoie de mai mult snap ca sa ramana lipit.
##
## Ruleaza CA SCENA (masinile au nevoie de autoload-uri):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeSlopeHop.tscn
##   ... -- --track=2 --seconds=70
##
## Pentru fiecare masina din garaj tipareste: de cate ori a desprins roatele,
## cat timp total a stat in aer si care a fost cea mai lunga desprindere — toate
## masurate DOAR pe coborare, cu zonele de fly-off/rampa excluse.

const CAR_SCENE: String = "res://scenes/cars/Car.tscn"
## Cat conduce fiecare masina (secunde de simulare).
const DRIVE_SECONDS: float = 70.0
## Sub atat o desprindere e zgomot de coliziune, nu "zbor" (secunde).
const MIN_HOP: float = 0.05
## Cat de aproape de o rampa/creasta declarata ignoram desprinderile (fractii de
## tur). Acolo airtime-ul e INTENTIONAT — nu despre asta e sonda.
const KICKER_GUARD: float = 0.02

var _track_index: int = 2
var _seconds: float = DRIVE_SECONDS
var _track: Track


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			_track_index = int(arg.trim_prefix("--track="))
		elif arg.begins_with("--seconds="):
			_seconds = float(arg.trim_prefix("--seconds="))

	var track_scene := load(GameState.TRACK_SCENES[_track_index]) as PackedScene
	_track = track_scene.instantiate() as Track
	add_child(_track)
	await get_tree().physics_frame

	# Zonele unde airtime-ul e cerut de pista: le sarim la numaratoare.
	var kickers: Array[float] = []
	kickers.append_array(_track._flyoff_fracs())
	kickers.append_array(_track._ramp_fracs())

	print("")
	print("=== Desprinderi la coborare — ", GameState.TRACK_NAMES[_track_index],
		" (%.0f s per masina) ===" % _seconds)
	print("zone de airtime intentionat, excluse: ", kickers)
	print("")
	print("%-14s %6s %7s %8s %8s %9s"
		% ["masina", "lung.", "sarituri", "aer_tot", "cea_mai", "panta_max"])

	for i in GameState.CAR_DATA.size():
		var data := GameState.CAR_DATA[i] as CarData
		var r := await _drive(data, kickers)
		print("%-14s %5.2fm %7d %7.2fs %7.2fs %8.1f%%"
			% [data.display_name, data.body_length, int(r.hops),
				float(r.air), float(r.longest), float(r.slope) * 100.0])

	print("")
	print("aer_tot = timp cu toate roatile in aer, DOAR pe coborare, in afara")
	print("zonelor de mai sus. O masina lipita de asfalt are aproape 0.")
	get_tree().quit(0)


func _drive(data: CarData, kickers: Array[float]) -> Dictionary:
	var car := load(CAR_SCENE).instantiate() as Car
	car.track = _track
	add_child(car)
	var spawns := _track.spawn_transforms(1)
	car.global_transform = spawns[0]
	car.route = 0
	car.road_index = _track.closest_index_global(car.global_position)
	car.last_safe_index = car.road_index
	car.apply_data(data)
	var ai := AIController.new()
	car.set_controller(ai)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260813 # aceeasi linie pentru toate masinile
	ai.configure(_track, rng)
	ai.line_offset = 0.0
	car.race_active = true

	var hops := 0
	var air := 0.0
	var longest := 0.0
	var cur := 0.0
	var steepest := 0.0
	var was_air := false
	var prev_y := car.global_position.y
	var t := 0.0
	var step := 1.0 / 60.0
	while t < _seconds:
		await get_tree().physics_frame
		t += step
		var y := car.global_position.y
		var descending := y < prev_y - 0.001
		# Panta locala, ca sa stim pe ce fel de teren se intampla.
		var flat := Vector3(car.velocity.x, 0.0, car.velocity.z).length()
		if flat > 1.0:
			var slope := absf(y - prev_y) / (flat * step)
			if descending and slope < 1.0:
				steepest = maxf(steepest, slope)
		prev_y = y

		var frac := _track.frac_at(car.road_index, car.route)
		var near_kicker := false
		for k in kickers:
			var d: float = absf(frac - k)
			d = minf(d, 1.0 - d) # tur inchis
			if d < KICKER_GUARD:
				near_kicker = true
				break

		var in_air := not car.is_on_floor()
		if in_air and descending and not near_kicker:
			cur += step
			air += step
		elif was_air or not in_air:
			if cur >= MIN_HOP:
				hops += 1
				longest = maxf(longest, cur)
			cur = 0.0
		was_air = in_air
	if cur >= MIN_HOP:
		hops += 1
		longest = maxf(longest, cur)

	car.queue_free()
	await get_tree().physics_frame
	return {"hops": hops, "air": air, "longest": longest, "slope": steepest}
