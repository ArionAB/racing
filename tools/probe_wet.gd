extends Node
## Sonda portiunilor ude de pe traseul principal (#246).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeWet.tscn
##
## Ce verifica:
##
##   1. INTERVALUL RASPUNDE. `is_wet_at` e adevarat inauntru si fals in afara,
##      inclusiv pentru un interval care trece peste linia de start.
##   2. SE VEDE. Asfaltul din interval e mai INCHIS decat cel din afara. Fara
##      verdictul asta, o portiune care taie grip-ul ar fi invizibila — adica
##      necinstita fata de jucator, si exact clasa de bug in care „efectul
##      exista" dar pe ecran nu e nimic.
##   3. MARGINEA E ESTOMPATA. Intunecarea creste treptat, nu dintr-un vertex in
##      altul: o trecere brusca ar desena o dunga transversala trasa cu rigla.
##   4. GRIP-UL SCADE CU ADEVARAT. Se masoara pe MASINA, prin cate cadre de
##      alunecare primeste — nu pe constante din cod.
##   5. NEREGRESIE: fara intervale declarate, asfaltul ramane bit-identic.

const HALF_WIDTH: float = 7.0


func _ready() -> void:
	await get_tree().process_frame

	print("")
	print("=== Sonda sosea uda ===")
	var failed := false

	# --- 1. intervalul raspunde
	var t := TrackFromPath.new()
	t.custom_name = "SondaUd"
	t.custom_wet_ranges = [Vector2(0.30, 0.40), Vector2(0.95, 0.05)]
	get_tree().root.add_child(t)
	await get_tree().process_frame
	await get_tree().process_frame

	print("\nintervalul (0.30-0.40 si 0.95-0.05, peste linia de start):")
	for probe in [[0.35, true], [0.20, false], [0.45, false],
			[0.97, true], [0.02, true], [0.50, false]]:
		var f: float = probe[0]
		var want: bool = probe[1]
		var got: bool = t.is_wet_at(f)
		var ok := got == want
		if not ok:
			failed = true
		print("  frac %.2f -> %s (asteptat %s)  %s"
				% [f, got, want, "OK" if ok else "PROBLEMA"])

	# --- 2 + 3. se vede, cu margine estompata
	var inside: float = t._wet_shade(0.35).r
	var outside: float = t._wet_shade(0.20).r
	var edge: float = t._wet_shade(0.302).r # foarte aproape de capat
	var darker := inside < outside - 0.15
	if not darker:
		failed = true
	print("\nsemnalul vizual (factor de intunecare, 1.0 = neatins):")
	print("  in interval  -> %.2f" % inside)
	print("  in afara     -> %.2f" % outside)
	print("  %s" % ["OK (se vede)" if darker else "PROBLEMA (nu se distinge)"])
	var faded := edge > inside + 0.05 and edge < outside
	if not faded:
		failed = true
	print("  langa margine-> %.2f  %s"
			% [edge, "OK (estompat)" if faded else "PROBLEMA (dunga brusca)"])

	# --- 5. neregresie
	var dry := TrackFromPath.new()
	dry.custom_name = "SondaUd"
	get_tree().root.add_child(dry)
	await get_tree().process_frame
	var dry_shade: float = dry._wet_shade(0.35).r
	var clean := is_equal_approx(dry_shade, 1.0)
	if not clean:
		failed = true
	print("\nfara intervale (neregresie):")
	print("  factor -> %.2f  %s"
			% [dry_shade, "OK (asfalt neatins)" if clean else "PROBLEMA"])
	dry.queue_free()

	# --- 4. grip-ul, masurat pe masina
	var slip := await _slip_frames(t)
	print("\ngrip-ul, masurat pe masina:")
	var wet_frames: int = slip["wet"]
	var dry_frames: int = slip["dry"]
	var slips := wet_frames > 0 and dry_frames == 0
	if not slips:
		failed = true
	print("  cadre de alunecare -> in ud %d, pe uscat %d  %s"
			% [wet_frames, dry_frames, "OK" if slips else "PROBLEMA"])
	var grip: float = slip["grip"]
	var grip_ok := grip < 8.0
	if not grip_ok:
		failed = true
	print("  grip lateral in ud -> %.1f (uscat 8.0)  %s"
			% [grip, "OK" if grip_ok else "PROBLEMA"])

	t.queue_free()
	print("")
	print("VERDICT: ", "OK" if not failed else "PROBLEME")
	get_tree().quit(1 if failed else 0)


## Pune o masina pe pista, o plimba prin ud si prin uscat, si numara cadrele in
## care chiar a primit alunecare.
func _slip_frames(track: Track) -> Dictionary:
	var car_scene: PackedScene = load("res://scenes/cars/Car.tscn")
	var car: Car = car_scene.instantiate()
	track.add_child(car)
	car.track = track
	await get_tree().process_frame

	var wet_hits := 0
	var dry_hits := 0
	var grip := 0.0
	for pair in [[0.35, true], [0.20, false]]:
		var frac: float = pair[0]
		var is_wet: bool = pair[1]
		var n: int = track.baked.size()
		var idx: int = int(frac * float(n)) % n
		car.global_position = track.baked[idx] + Vector3.UP * 0.5
		car.route = 0
		car.road_index = idx
		car.slip_time = 0.0
		# Cateva cadre de fizica: udul se reinnoieste in fiecare cadru cat stai
		# pe el, deci daca mecanismul merge, `slip_time` ramane pozitiv.
		for i in 8:
			await get_tree().physics_frame
		if car.slip_time > 0.0:
			if is_wet:
				wet_hits += 1
				grip = car.slip_grip
			else:
				dry_hits += 1

	var out := {"wet": wet_hits, "dry": dry_hits, "grip": grip}
	car.queue_free()
	return out
