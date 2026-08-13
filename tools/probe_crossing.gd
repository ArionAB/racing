extends Node
## Sonda traversarii cu sens ([SlidingHazard.Motion.TRAVERSARE], #241).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCrossing.tscn
##
## Ca SCENA, nu cu --script: hazardele au nevoie de autoload-uri ca sa compileze
## (acelasi motiv ca la probe_hazard_marker.gd).
##
## Ce masoara, si de ce fiecare verdict exista:
##
##   1. PARCAT IN AFARA DRUMULUI. La capatul cursei, tot corpul trebuie sa fie
##      dincolo de asfalt. Daca ar ramane pe banda, un vehicul care asteapta 5 s
##      ar fi un zid pe jumatate de drum — exact opusul evenimentului cerut, si
##      chiar capcana masurata in antetul clasei (obstacol lent = toata lumea
##      intra in el).
##   2. TRAVERSEAZA COMPLET. Ajunge si pe partea cealalta, tot in afara — altfel
##      face doar o incursiune si se intoarce, adica o pendulare cu pauze.
##   3. UN SINGUR SENS PE TRECERE. Intre doua parcari, deplasarea isi pastreaza
##      semnul. Asta e chiar diferenta fata de pendulare: daca s-ar intoarce din
##      mijlocul drumului, ar fi tot un pendul, doar mai lent.
##   4. VITEZA SUB PLAFON. Perioada dedusa tine traversarea sub `max_sweep_speed`
##      (formula difera de cea sinusoidala — vezi `_readable_period`). Fara
##      verdictul asta, o trecere ~27% mai iute decat plafonul ar fi trecut
##      neobservata pana la playtest.
##   5. PENDULAREA E NEATINSA. Acelasi obstacol pe modul implicit ramane in
##      sosea, ca inainte de #241.

const HALF_WIDTH: float = 7.0
const SWEEP_SPEED: float = 12.0
## Cat simulam: destul cat sa prindem doua treceri intregi, dus si intors.
const SIM_SECONDS: float = 26.0
const STEP: float = 1.0 / 60.0


func _ready() -> void:
	await get_tree().process_frame

	var cross := _sample(SlidingHazard.Motion.TRAVERSARE)
	var pend := _sample(SlidingHazard.Motion.PENDULARE)

	print("")
	print("=== Sonda traversare cu sens ===")
	print("semilatime sosea: %.1f m, plafon viteza: %.1f m/s"
			% [HALF_WIDTH, SWEEP_SPEED])

	var failed := false

	# 1 + 2: capetele cursei, dincolo de asfalt pe AMANDOUA partile.
	var half_body: float = cross["half_extent"]
	var need: float = HALF_WIDTH + half_body
	var lo: float = cross["min_offset"]
	var hi: float = cross["max_offset"]
	print("\ncapetele cursei (semicorp %.2f m, prag %.2f m):" % [half_body, need])
	for pair in [["stanga", lo], ["dreapta", hi]]:
		var name: String = pair[0]
		var val: float = absf(float(pair[1]))
		var good := val >= need
		if not good:
			failed = true
		print("  parcat %-8s -> %.2f m de axa  %s"
				% [name, val, "OK" if good else "PROBLEMA (ramane pe asfalt)"])

	# 3: un singur sens per trecere.
	var flips: int = cross["direction_flips"]
	# Doua treceri simulate = cel mult 2 schimbari de sens (una per capat).
	# Mai multe inseamna ca se rasuceste in mijlocul drumului.
	var flips_ok := flips <= 2
	if not flips_ok:
		failed = true
	print("\nsensuri: %d schimbari in %.0f s  %s"
			% [flips, SIM_SECONDS, "OK" if flips_ok else "PROBLEMA (penduleaza)"])

	# 4: viteza de traversare sub plafon.
	var vmax: float = cross["max_speed"]
	var speed_ok := vmax <= SWEEP_SPEED * 1.05 # 5% toleranta de esantionare
	if not speed_ok:
		failed = true
	print("viteza maxima: %.2f m/s (plafon %.1f)  %s"
			% [vmax, SWEEP_SPEED, "OK" if speed_ok else "PROBLEMA"])

	# Cat sta pe carosabil vs. parcat — nu e verdict, e cifra de tunare.
	print("pe carosabil: %.0f%% din ciclu" % (100.0 * float(cross["on_road"])))

	# 5: pendularea neatinsa.
	var pend_max: float = maxf(absf(float(pend["min_offset"])),
			absf(float(pend["max_offset"])))
	var pend_ok := pend_max <= HALF_WIDTH + 0.01
	if not pend_ok:
		failed = true
	print("\npendulare (neatinsa): capat la %.2f m, sub semilatime %.1f  %s"
			% [pend_max, HALF_WIDTH, "OK" if pend_ok else "PROBLEMA"])

	print("")
	print("VERDICT: ", "OK" if not failed else "PROBLEME")
	get_tree().quit(1 if failed else 0)


## Simuleaza un obstacol si intoarce ce a facut de-a lungul timpului.
##
## Pozitia se calculeaza din `_offset_now()` si `travel`, nu se citeste din
## `global_position`. Motivul e ca `SlidingHazard` are `sync_to_physics = true`:
## transformul il tine serverul de fizica, iar intr-o sonda care nu ruleaza pasi
## de fizica reali, pozitia scrisa de `_physics_process` nu se vede inapoi pe
## nod — prima varianta a sondei a masurat asa si a raportat 0.00 peste tot,
## adica „nu se misca nimic" pentru un obstacol perfect functional.
##
## Ce ne intereseaza oricum e LEGEA de miscare (offsetul pe axa) plus cursa
## taiata de `_clamp_travel()`, si pe amandoua le avem exact.
func _sample(motion: SlidingHazard.Motion) -> Dictionary:
	var hz := SlidingHazard.new()
	hz.motion = motion
	hz.road_half_width = HALF_WIDTH
	hz.max_sweep_speed = SWEEP_SPEED
	add_child(hz)
	hz.center = Vector3.ZERO
	# Cursa ceruta de pista, ca in `Track._build_hazard`: lateralul * 0.9.
	hz.travel = Vector3.RIGHT * HALF_WIDTH * 0.9
	hz.global_position = Vector3.ZERO

	var lo := INF
	var hi := -INF
	var vmax := 0.0
	var flips := 0
	var on_road := 0
	var steps := int(SIM_SECONDS / STEP)
	var prev_x := 0.0
	var prev_dir := 0
	for i in steps:
		hz._physics_process(STEP)
		var x: float = hz.travel.x * hz._offset_now()
		lo = minf(lo, x)
		hi = maxf(hi, x)
		if i > 0:
			var dx := x - prev_x
			vmax = maxf(vmax, absf(dx) / STEP)
			var dir := 0
			if absf(dx) > 0.0005: # ignoram statul pe loc si telegraful
				dir = 1 if dx > 0.0 else -1
			if dir != 0 and prev_dir != 0 and dir != prev_dir:
				flips += 1
			if dir != 0:
				prev_dir = dir
		# „Pe carosabil" = corpul atinge asfaltul.
		if absf(x) < HALF_WIDTH + hz._half_extent:
			on_road += 1
		prev_x = x

	var out := {
		"min_offset": lo,
		"max_offset": hi,
		"max_speed": vmax,
		"direction_flips": flips,
		"on_road": float(on_road) / float(steps),
		"half_extent": hz._half_extent,
	}
	hz.queue_free()
	return out
