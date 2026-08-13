extends Node
## Cate masini trecute peste un canal cu `jump: true`, fiecare cu alta viteza de
## intrare, ca sa se vada DE LA CE VITEZA se trece golul.
##
## Intrebarea la care raspunde: "turbo-only" e o intentie sau un fapt? Un gol
## declarat de 26 m nu inseamna nimic pana nu stii ca masina de referinta il
## rateaza la 30 m/s si il trece la 40 — altfel ori e o formalitate pe care o
## sare toata lumea, ori o capcana pe care n-o sare nimeni.
##
## Ruleaza CA SCENA: masina are nevoie de autoload-urile GameState/AudioManager.
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeJump.tscn
##   ... -- --track=2 --speeds=24,30,36,42,48
##
## Pentru fiecare viteza tipareste: a trecut sau a cazut, cat airtime a avut si
## cat de departe a ajuns fata de buza de aterizare.

const CAR_SCENE: String = "res://scenes/cars/Car.tscn"
## De cati metri inainte de trambulina porneste masina.
##
## SCURT, si asta e esential: cu 55-90 m de run-up, AI-ul accelereaza pana la
## plafonul LUI si toate rularile ajungeau la buza cu 37 m/s indiferent de
## viteza ceruta — sonda masura plafonul masinii, nu pragul sariturii. La 18 m
## masina nu apuca sa schimbe mult viteza pusa in `velocity`, deci coloana
## „intrare" chiar inseamna ceva. Se poate schimba cu --runup=.
var _run_up: float = 18.0
const WATCH_SECONDS: float = 8.0

var _track_index: int = 2
var _speeds: Array[float] = [24.0, 30.0, 36.0, 42.0, 48.0]
var _trace: bool = false
var _track: Track
var _ch: Dictionary = {}
var _near_lip: Vector3
var _far_lip: Vector3
var _across: Vector3


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			_track_index = int(arg.trim_prefix("--track="))
		elif arg.begins_with("--runup="):
			_run_up = float(arg.trim_prefix("--runup="))
		elif arg == "--trace":
			_trace = true
		elif arg.begins_with("--speeds="):
			_speeds.clear()
			for s in arg.trim_prefix("--speeds=").split(","):
				_speeds.append(float(s))
	await get_tree().process_frame
	_track = (load(GameState.TRACK_SCENES[_track_index]) as PackedScene) \
		.instantiate() as Track
	add_child(_track)
	await get_tree().process_frame

	var channels: Array = _track.get("_channels")
	var jumper := {}
	for ch: Dictionary in channels:
		if bool(ch.get("jump", false)):
			jumper = ch
			break
	if jumper.is_empty():
		print("probe_jump: pista nu are canal cu `jump: true`")
		get_tree().quit(1)
		return
	_ch = jumper
	_near_lip = _ch["near_point"]
	_far_lip = _ch["far_point"]
	_across = _ch["across"]

	print("")
	print("=== SARITURA PESTE CANAL — %s / %s ===" % [
		_track.track_name, String(_ch.get("label", "canal"))])
	print("gol cerut %.1f m, gol OBTINUT %.2f m (asta conteaza)" % [
		float(_ch["gap_requested"]), float(_ch["gap"])])
	print("buza de plecare %s -> buza de aterizare %s" % [
		str(_near_lip), str(_far_lip)])
	print("adancime %.1f m, apa cu %.1f m sub sosea" % [
		float(_ch["depth"]), float(_ch.get("water_y_drop", 0.0))])
	print("")
	print(" intrare   rezultat        airtime  y_min   marja fata de buza")
	for sp in _speeds:
		await _run_one(sp)
	print("")
	print("marja > 0 = a aterizat DUPA buza (a trecut). < 0 = a cazut in gol.")
	get_tree().quit()


func _run_one(entry_speed: float) -> void:
	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(car)
	car.apply_data(GameState.CAR_DATA[0])
	car.track = _track
	# Pornirea se ia DE PE CURBA COAPTA, mergand inapoi din buza de plecare pana
	# la `_run_up` metri. Prima versiune mergea in linie dreapta pe axa
	# canalului si punea masina langa drum si sub cota
	# lui: acolo soseaua vine dintr-un viraj, deci axa golului si axa soselei
	# nu sunt aceeasi directie. Masura iesea "a lovit malul" la orice viteza,
	# adica sonda masura o masina cazuta de pe drum inainte de trambulina.
	var n := _track.baked.size()
	var near_i: int = _ch["near"]
	var back := near_i
	var walked := 0.0
	while walked < _run_up:
		var prev := ((back - 1) % n + n) % n
		walked += _track.baked[prev].distance_to(_track.baked[back])
		back = prev
	var start := _track.baked[back]
	var dir := (_track.baked[(back + 1) % n] - start).normalized()
	car.global_transform = Transform3D(
		Basis.looking_at(dir, Vector3.UP), start + Vector3.UP * 0.6)
	car.velocity = dir * entry_speed
	car.road_index = back
	car.last_safe_index = back
	if _trace:
		print("    [trace] start p=%s idx=%d (near=%d) gap_axis=%.1f"
			% [str(start), back, int(_ch["near"]), _along_gap(start)])
	# Cu AI la volan, ca sonda podului: pe ultimii 55 m soseaua coteste, si un
	# volan blocat ar iesi de pe asfalt inainte sa ajunga la trambulina. AI-ul
	# tine linia; viteza de intrare ramane cea impusa, fiindca o punem direct
	# in `velocity` si distanta e prea scurta ca sa o schimbe mult.
	var ai := AIController.new()
	car.set_controller(ai)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260812
	ai.configure(_track, rng)
	ai.line_offset = 0.0
	car.race_active = true
	var respawned := false
	car.respawned.connect(func(_c: Car) -> void: respawned = true)

	var t := 0.0
	var airtime := 0.0
	var y_min := 1e9
	var was_air := false
	var landed_at := -1e9
	# Masuram DOAR saritura, nu si hopurile de pe run-up. Prima versiune latea
	# `landed_at` la prima aterizare de oriunde, iar pe coborarea din vale
	# masina desprinde roatile de cateva ori inainte de trambulina — deci sonda
	# raporta ca "a aterizat" cu 73 m inainte de gol si declara esec o saritura
	# care de fapt reusea (traceul arata gap_axis=+12.6 la final).
	var armed := false
	while t < WATCH_SECONDS:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		var p := car.global_position
		var s := _along_gap(p)
		# Armare la buza de plecare: de aici incolo orice desprindere e saritura.
		if not armed and s > -float(_ch["gap"]) - 3.0:
			armed = true
		if armed:
			y_min = minf(y_min, p.y)
		var on_floor := car.is_on_floor()
		if armed and not on_floor:
			if not was_air and _trace:
				print("    [trace] desprindere la gap_axis=%.1f v_oriz=%.1f "
					% [s, Vector2(car.velocity.x, car.velocity.z).length()]
					+ "v_y=%.1f y=%.1f" % [car.velocity.y, p.y])
			airtime += 1.0 / 60.0
			was_air = true
		elif armed and was_air and landed_at < -1e8:
			# Prima atingere de sol DUPA ce a zburat: aici a aterizat. Masurat
			# pe ORIZONTALA, pe axa golului: componenta verticala a lui
			# `_across` ar amesteca in marja si diferenta de cota dintre buze.
			landed_at = s
		if respawned:
			break
		# Trecut bine dincolo de buza si pe roti: gata.
		if landed_at > -1e8 and s > 12.0:
			break
		# Cazut in albie: nu mai are rost sa asteptam cele 8 secunde. Pragul e
		# sub cota apei, deci sub orice aterizare reusita.
		if armed and p.y < _water_y() - 1.0:
			break

	if _trace:
		print("    [trace] final p=%s v=%.1f gap_axis=%.1f on_floor=%s"
			% [str(car.global_position), car.velocity.length(),
				_along_gap(car.global_position), str(car.is_on_floor())])
	var verdict := "A CAZUT"
	var margin := landed_at
	if respawned:
		verdict = "A CAZUT (repus)"
		margin = -absf(float(_ch["gap"])) * 0.5
	elif landed_at > 0.0:
		verdict = "A TRECUT"
	elif landed_at > -1e8:
		verdict = "A LOVIT MALUL"
	print("  %4.0f m/s  %-15s %5.2f s  %6.1f  %+7.2f m" % [
		entry_speed, verdict, airtime, y_min, margin])
	car.queue_free()
	await get_tree().process_frame


## Cota apei din albie: originea canalului minus caderea declarata.
func _water_y() -> float:
	return float((_ch["origin"] as Vector3).y) - float(_ch.get("water_y_drop", 0.0))


## Cat de departe e punctul dincolo de buza de aterizare, pe orizontala.
## Negativ = inca peste gol (sau inainte de el), pozitiv = a trecut.
func _along_gap(p: Vector3) -> float:
	var axis := Vector2(_across.x, _across.z).normalized()
	return Vector2(p.x - _far_lip.x, p.z - _far_lip.z).dot(axis)
