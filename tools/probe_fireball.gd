extends Node
## SONDA — gheizerele de foc din craterul Stromboli ([FireballGeyser]).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeFireball.tscn
##
## Doua intrebari, amandoua masurate, nu presupuse:
##
## 1. TINE INVARIANTUL? La orice moment, in fiecare pereche trebuie sa existe
##    cel putin un culoar liber. E ce vinde hazardul (vezi antetul clasei), si
##    depinde de o relatie intre `up_fraction`, caderea si numarul de guri —
##    genul de lucru care se rupe tacut la prima retusare de tuning. Sonda l-a
##    si prins o data, la 0.38: ~0.3 s pe ciclu cu ambele coloane ridicate.
##
## 2. SE SIMTE LOVITURA? O masina impinsa in coloana ridicata trebuie sa iasa
##    ARSA (burn_time), incetinita (crush_factor), fara turbo si zvarlita
##    LATERAL. Numaratoarea de atingeri nu ajunge: un hazard care emite
##    semnalul dar nu schimba nimic in starea masinii trece o sonda care doar
##    numara (vezi memoria „efectele nu se verifica numarand").

const CAR_SCENE: String = "res://scenes/cars/Car.tscn"

var _track: Track
var _fails: Array[String] = []


func _ready() -> void:
	await get_tree().process_frame
	_track = (load("res://scenes/tracks/Track11.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame

	var grup := _track.get_node_or_null("GheizereCrater")
	if grup == null:
		print("PICAT: nodul GheizereCrater lipseste din Track11")
		get_tree().quit(1)
		return

	await _test_invariant(grup)
	await _test_impact(grup)

	print("")
	if _fails.is_empty():
		print("=== VERDICT: OK ===")
	else:
		print("=== VERDICT: PICAT ===")
		for f in _fails:
			print("  - ", f)
	get_tree().quit(0 if _fails.is_empty() else 1)


## 1. Invariantul: niciodata toate coloanele unei perechi ridicate deodata.
func _test_invariant(grup: Node) -> void:
	print("")
	print("=== 1. INVARIANT: mereu un culoar liber ===")
	var perechi := grup.get_children()
	var incalcari := {}
	var blocate := {}
	var esantioane := 0
	for p in perechi:
		incalcari[p.name] = 0
		blocate[p.name] = 0
	# ~3 perioade complete la 60 Hz.
	for _i in 840:
		await get_tree().physics_frame
		esantioane += 1
		for p in perechi:
			var sus := 0
			for g in p.get_children():
				var body := g.get_node_or_null("Bila") as Node3D
				if body != null and body.visible:
					sus += 1
			if sus >= p.get_child_count():
				incalcari[p.name] += 1
			if sus > 0:
				blocate[p.name] += 1
	for p in perechi:
		var pct := 100.0 * float(blocate[p.name]) / float(esantioane)
		print("  %-10s  ambele_in_aer=%d   gura activa %.0f%% din timp"
			% [p.name, incalcari[p.name], pct])
		if incalcari[p.name] > 0:
			_fails.append("%s: %d cadre cu toate bilele in aer simultan"
				% [p.name, incalcari[p.name]])
	print("  esantioane: %d (~%.1f s)" % [esantioane, esantioane / 60.0])


## 2. Lovitura: ce se schimba efectiv in starea masinii.
func _test_impact(grup: Node) -> void:
	print("")
	print("=== 2. LOVITURA: starea masinii inainte/dupa ===")
	var pereche := grup.get_child(0) as FireballGeyser
	var gheizer := pereche.get_child(0) as Node3D

	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	car.track = _track
	get_tree().root.add_child(car)
	car.apply_data(GameState.CAR_DATA[0] as CarData)
	# Bara plina inainte: golirea ei e jumatate din pedeapsa, deci trebuie sa
	# existe ce goli.
	car.turbo_charge = 1.0
	await get_tree().physics_frame

	var v0 := 24.0
	var lovit := false
	var burn := 0.0
	var factor := 1.0
	var turbo_dupa := 1.0
	var viteza_dupa := Vector3.ZERO
	var lateral := 0.0

	# Asteptam sa se ridice coloana, apoi punem masina in ea cu viteza.
	for _i in 900:
		await get_tree().physics_frame
		var body := gheizer.get_node_or_null("Bila") as Node3D
		if body == null or not body.visible:
			continue
		# Bila e periculoasa doar cand e JOS, la cota masinii: pe restul
		# arcului trece pe deasupra. Asteptam fereastra aia — altfel sonda ar
		# raporta „nu m-a lovit" pentru ceva ce zboara la 9 m.
		if body.position.y > 1.2:
			continue
		if lovit:
			continue
		# Asezata in coloana DECENTRAT, cum intra o masina reala: cu botul
		# peste marginea jetului, nu fix pe gura. Centrul exact e cazul
		# degenerat (directia radiala are lungime zero) si nu se intampla in
		# joc — prima versiune a sondei il folosea si raporta, corect, ca nu
		# exista zvarlire laterala.
		# Sub BILA, nu deasupra gurii: obiectul periculos se misca acum.
		var gp := body.global_position
		var fwd := -pereche.global_transform.basis.z
		var right := pereche.global_transform.basis.x
		car.global_position = gp + right * 0.8
		car.velocity = fwd * v0
		car.turbo_charge = 1.0
		car.burn_time = 0.0
		car.crush_factor = 1.0
		await get_tree().physics_frame
		await get_tree().physics_frame
		lovit = car.burn_time > 0.0
		burn = car.burn_time
		factor = car.crush_factor
		turbo_dupa = car.turbo_charge
		viteza_dupa = car.velocity
		lateral = absf(viteza_dupa.dot(right))
		break

	print("  a fost lovita:       %s" % lovit)
	print("  burn_time:           %.2f s" % burn)
	print("  crush_factor:        %.2f  (plafon taiat cu %.0f%%)"
		% [factor, (1.0 - factor) * 100.0])
	print("  turbo dupa lovitura: %.2f  (era 1.00)" % turbo_dupa)
	print("  viteza verticala:    %+.2f m/s  (zvarlita in sus)" % viteza_dupa.y)
	print("  viteza laterala:     %.2f m/s  (scoasa de pe linie)" % lateral)

	if not lovit:
		_fails.append("masina pusa IN bila (jos pe arc) nu a fost aprinsa")
		return
	if factor >= 1.0:
		_fails.append("plafonul de viteza nu a fost taiat (crush_factor=1)")
	if turbo_dupa > 0.01:
		_fails.append("bara de turbo nu s-a golit (%.2f)" % turbo_dupa)
	if viteza_dupa.y <= 0.5:
		_fails.append("nu a fost aruncata in sus (vy=%.2f)" % viteza_dupa.y)
	if lateral < 1.0:
		_fails.append("nu a fost scoasa lateral de pe linie (%.2f m/s)" % lateral)

	# Bara nu are voie sa se reincarce cat arde: altfel pedeapsa e doar pe hartie.
	var turbo_inainte := car.turbo_charge
	for _i in 30:
		await get_tree().physics_frame
	print("  turbo dupa inca 0.5 s de ardere: %.3f (era %.3f)"
		% [car.turbo_charge, turbo_inainte])
	if car.turbo_charge > turbo_inainte + 0.001:
		_fails.append("bara se reincarca in timp ce masina arde")

	# Si se stinge singura, fara sa curete nimeni dupa ea.
	for _i in 260:
		await get_tree().physics_frame
	print("  burn_time dupa ~4.3 s: %.2f (trebuie 0)" % car.burn_time)
	if car.burn_time > 0.0:
		_fails.append("focul nu s-a stins singur")
