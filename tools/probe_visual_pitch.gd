extends Node
## Cat de mult MINTE caroseria fata de panta pe care sta masina.
##
## Intrebarea la care raspunde: de ce par autobuzul si pompierii ca "zboara" la
## coborare? Doua sonde excluseseră deja explicatiile usoare:
##   - tools/probe_slope_hop.gd: tocmai ele desprind roatele CEL MAI PUTIN
##     (0.90 s / 0.83 s de aer pe 70 s, fata de 1.47-2.17 la masinile scurte);
##   - tools/probe_ride_height.gd: toate modelele sunt asezate identic fata de
##     talpa colizerului (-0.10 m).
## Deci nu corpul fizic pleca de pe drum — mintea desenul.
##
## Cauza: `_update_visual_tilt` calcula pitch-ul din `-velocity.y`. Pe o
## coborare lunga viteza verticala sta negativa continuu, deci unghiul se lipea
## de plafonul +0.15 rad si masina cobora cu botul in sus. Cat de rau se vede
## depinde de LUNGIME (rotatia ridica capetele cu jumatate_lungime * sin), iar
## autobuzul (5.46 m) si pompierii (4.87 m) sunt cele mai lungi din garaj.
##
## Sonda conduce fiecare masina pe pista si compara, cadru cu cadru, unghiul
## caroseriei cu unghiul REAL al pantei de sub ea. Diferenta e minciuna.
##
## Ruleaza CA SCENA (are nevoie de autoload-uri):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeVisualPitch.tscn
##   ... -- --track=2 --seconds=60

const CAR_SCENE: String = "res://scenes/cars/Car.tscn"
const DRIVE_SECONDS: float = 60.0
## Cat are voie sa se abata caroseria de la panta, IN MEDIE, pe sol (radiani).
## 0.06 rad ~ 3.4 grade: destul cat sa incapa amortizarea, prea putin cat sa
## citeasca drept "decolare".
##
## Pragul e pe MEDIE, nu pe maxim, si asta e o alegere, nu o slabire: unghiul
## se aseaza cu lerp (5.0 * delta), deci la fiecare schimbare brusca de panta
## exista cateva cadre in care caroseria e in urma terenului. Aia e chiar
## amortizarea pe care o vrem — un maxim ar masura-o pe ea, nu regimul in care
## sta masina. Varfurile raman tiparite, ca sa se vada unde apar.
const PASS_RAD: float = 0.06
## Panta de la care incolo consideram ca masina chiar coboara (radiani).
const SLOPE_MIN: float = 0.05

var _track_index: int = 2
var _seconds: float = DRIVE_SECONDS
var _track: Track
var _failed: bool = false


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

	print("")
	print("=== Caroseria fata de panta — ", GameState.TRACK_NAMES[_track_index],
		" (%.0f s per masina) ===" % _seconds)
	print("se masoara DOAR pe coborari reale (panta > %.0f grade), cu rotile pe sol"
		% rad_to_deg(SLOPE_MIN))
	print("")
	print("%-14s %8s %11s %11s %10s"
		% ["masina", "lungime", "abatere_med", "abatere_max", "bot_ridicat"])

	for i in GameState.CAR_DATA.size():
		var data := GameState.CAR_DATA[i] as CarData
		var r := await _drive(data)
		var avg := float(r.avg)
		var mx := float(r.max)
		# Cat se ridica botul din abaterea medie, in metri — cifra pe care o
		# vede de fapt ochiul.
		var lift: float = data.body_length * 0.5 * sin(avg)
		var mark := "" if avg <= PASS_RAD else "   <-- MINTE"
		if avg > PASS_RAD:
			_failed = true
		print("%-14s %7.2fm %9.3frad %9.3frad %8.3fm%s"
			% [data.display_name, data.body_length, avg, mx, lift, mark])
		var at: Dictionary = r.at
		if not at.is_empty():
			print("               varful la frac=%.3f: panta %.3f rad, caroserie %.3f rad, v=%.1f"
				% [float(at.frac), float(at.slope), float(at.pitch), float(at.v)])

	print("")
	print("abaterea e unghiul dintre caroserie si panta reala de sub roti.")
	print("0 = masina sta paralela cu drumul (ce face una adevarata).")
	print("bot_ridicat = cati metri urca varful botului din abaterea medie;")
	print("raza unei roti e ~0.20-0.30 m, deci o cifra comparabila citeste")
	print("direct ca 'a decolat'.")
	print("")
	print("REZULTAT: ", "PICAT" if _failed else "TRECUT",
		" (prag %.3f rad pe abaterea MEDIE)" % PASS_RAD)
	get_tree().quit(1 if _failed else 0)


func _drive(data: CarData) -> Dictionary:
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
	await get_tree().physics_frame # ca `_visual` mort din apply_data sa dispara

	var visual := _find_visual(car)
	var total := 0.0
	var samples := 0
	var worst := 0.0
	var worst_at: Dictionary = {}
	var t := 0.0
	var step := 1.0 / 60.0
	# Cat ignoram dupa reatingerea solului: inclinarea se aseaza cu lerp
	# (5.0 * delta), deci imediat dupa o aterizare caroseria e inca la unghiul
	# din aer. Aia e amortizarea, nu minciuna pe panta — masuram regimul
	# stabilizat, cum masoara si sonda de saritura DOAR saritura.
	var settle := 0.0
	while t < _seconds:
		await get_tree().physics_frame
		t += step
		if visual == null or not car.is_on_floor():
			settle = 0.35
			continue
		settle = maxf(settle - step, 0.0)
		if settle > 0.0:
			continue
		var up := car.get_floor_normal()
		if up.length_squared() < 0.5:
			continue
		var fwd_h := -car.global_transform.basis.z
		fwd_h = Vector3(fwd_h.x, 0.0, fwd_h.z).normalized()
		# Unghiul pantei sub masina, cu acelasi semn ca pitch-ul caroseriei.
		var slope := asin(clampf(up.dot(fwd_h), -1.0, 1.0))
		if slope <= SLOPE_MIN: # doar coborari (bot in jos = panta pozitiva aici)
			continue
		var diff := absf(visual.rotation.x - slope)
		total += diff
		if diff > worst:
			worst = diff
			worst_at = {"frac": _track.frac_at(car.road_index, car.route),
				"slope": slope, "pitch": visual.rotation.x,
				"v": car.horizontal_speed()}
		samples += 1

	car.queue_free()
	await get_tree().physics_frame
	return {"avg": total / maxf(float(samples), 1.0), "max": worst,
		"at": worst_at}


## `_visual` e privat, dar e copil de tip Node3D EXACT (nu o subclasa):
## colizerul, umbra, particulele si audio-ul sunt toate subclase.
##
## Se ia ULTIMUL viu: `apply_data` face `queue_free()` pe vizualul vechi si
## construieste imediat unul nou, iar nodul eliberat pleaca din arbore abia la
## finalul cadrului.
func _find_visual(car: Car) -> Node3D:
	var found: Node3D = null
	for child in car.get_children():
		if child.get_class() == "Node3D" and not child.is_queued_for_deletion():
			found = child as Node3D
	return found
