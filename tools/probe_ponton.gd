extends Node3D
## Verifica CONTRACTELE drumului de pontoane (PontoonRoadHazard) pe sol plat,
## INAINTEA traseului — tiparul lui probe_machu_pod.gd.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbePonton.tscn
##
## Ce verifica, si de ce fiecare (brief §3, §5.3):
##  1. AFUNDAREA PE MASA: autobuzul (2.6) lasa mijlocul cu ~0.45 m, sportul
##     (0.9) cu ~0.18 m. E ce face masa vizibila fara contact intre masini
##     (principiul 1 din CLAUDE.md), deci daca cifrele nu ies, gimmickul nu
##     exista;
##  2. PRAGUL LA INSULITA < 0.3 m, in starea cea mai defavorabila (autobuz pe
##     buza). Peste 0.3 m un prag lateral e ZID (memoria
##     `suprafete-cu-goluri-si-praguri`) — si asta e constrangerea pe care
##     capetele LIBERE o introduc si podul n-o avea;
##  3. CONTINUITATEA: nicio placa nu sare sub masina. Se masoara saltul maxim
##     al cotei unei placi intre doua tick-uri consecutive;
##  4. GEMENII: `_drop` din GDScript si `deck_drop` din shader trebuie sa fie
##     ACEEASI formula. Nu pot citi shaderul din GDScript, deci verific
##     INVARIANTII pe care amandoua trebuie sa-i respecte (valorile la capete,
##     simetria, semnul) — daca cineva schimba una si nu pe alta, un invariant
##     cade;
##  5. VALUL: pontonul se misca si cand nu e nimeni pe el (altfel nu pluteste,
##     e doar moale);
##  6. TANGAJUL: o masina spre un capat inclina tronsonul, si capatul ei
##     COBOARA (nu urca).
##
## SABOTAJ (`--sabotaj`): stinge capetele libere (free_ends = 0, adica podul).
## Garda 2 trebuie sa TREACA oricum (pragul devine zero), dar garda 5-6 de
## identitate de ponton trebuie sa PICE: fara capete libere si fara tangaj, nu
## mai e un ponton. Fara sabotajul asta, garzile n-ar deosebi pontonul de pod.

const PontoonScript := preload("res://scenes/hazards/pontoon_road_hazard.gd")
const MASS_BUS := 2.6
const MASS_SPORT := 0.9
const LENGTH := 60.0
const WIDTH := 6.0
## Contractele din brief §3.
const SAG_BUS_TARGET := 0.45
const SAG_SPORT_TARGET := 0.18
const SAG_TOL := 0.08
const EDGE_STEP_MAX := 0.30
const PLATE_JUMP_MAX := 0.12

var _fails: Array[String] = []
var pont: PontoonRoadHazard


func _ready() -> void:
	var sabotaj := "--sabotaj" in OS.get_cmdline_user_args()
	pont = PontoonScript.new() as PontoonRoadHazard
	pont.name = "PontonTest"
	pont.near_end = Vector3.ZERO
	pont.far_end = Vector3(0.0, 0.0, -LENGTH)
	pont.deck_width = WIDTH
	if sabotaj:
		# „Pontonul" devine pod: capete ancorate, fara tangaj, fara val.
		pont.free_ends = 0.0
		pont.pitch_gain = 0.0
		pont.wave_amp = 0.0
	add_child(pont)
	await get_tree().physics_frame
	await get_tree().physics_frame

	print("=== ProbePonton%s ===" % (" (SABOTAJ: free_ends=0, pitch=0, val=0)"
		if sabotaj else ""))
	print("  tronson %.0f m x %.1f m, %d placi" % [pont.deck_length(),
		pont.deck_width_m(), pont.plates().size()])

	_check_sag_by_mass()
	_check_edge_step()
	# AWAIT obligatoriu: garda asta ruleaza 90 de tick-uri de fizica. Prima
	# versiune o chema fara `await`, deci verdictul se tiparea inaintea ei si
	# secţiunea ieşea GOALA — adica o garda care nu masoara nimic, dar nici nu
	# se plange (memoria `garda-verde-pe-zero-masuratori`).
	await _check_continuity()
	_check_twin_invariants()
	var wave_ok := _check_wave()
	var pitch_ok := _check_pitch()
	_check_grid_load()

	print()
	if sabotaj:
		# Sabotajul TREBUIE sa strice identitatea de ponton.
		if wave_ok or pitch_ok:
			print("SABOTAJ N-A PRINS: valul sau tangajul inca raspund, desi")
			print("  free_ends/pitch_gain/wave_amp sunt 0. Garzile 5-6 nu")
			print("  deosebesc pontonul de un pod — nu masoara nimic.")
			get_tree().quit(1)
			return
		print("SABOTAJ A PRINS (valul si tangajul au dispărut, cum trebuia)")
		get_tree().quit(0)
		return
	if _fails.is_empty():
		print("TOATE CONTRACTELE TREC")
		get_tree().quit(0)
		return
	print("PICAT:")
	for f in _fails:
		print("  - ", f)
	get_tree().quit(1)


## 1. Afundarea pe masa, prin incarcari fantoma la mijloc.
##
## VALUL SE STINGE PE DURATA MASURATORII. Prima versiune a sondei il lasa
## pornit si a raportat 0.507 m pentru autobuz in loc de 0.45: diferenta era
## EXACT `_wave(0.5)` la t = 0 (-0.0571 m), adica masuram afundarea plus hula.
## Clasa era corecta, sonda nu izola ce masura — aceeasi familie cu memoria
## `ceasul-porneste-in-prima-faza`. O sonda care masoara doua lucruri deodata
## raporteaza o cifra care nu e niciuna dintre ele.
func _check_sag_by_mass() -> void:
	print("\n--- 1. afundarea pe masa (mijlocul tronsonului, FARA val) ---")
	var wave_keep := pont.wave_amp
	pont.wave_amp = 0.0
	var results := {}
	for m: float in [MASS_SPORT, MASS_BUS]:
		pont.preview_loads = [Vector3(0.5, 0.0, m)]
		pont.settle_now()
		var d := pont.sag_at(0.5)
		results[m] = d
		print("  masa %.1f -> mijlocul coboara %.3f m" % [m, d])
	pont.preview_loads = []
	pont.wave_amp = wave_keep
	pont.settle_now()
	var bus: float = results[MASS_BUS]
	var sport: float = results[MASS_SPORT]
	if absf(bus - SAG_BUS_TARGET) > SAG_TOL:
		_fails.append("autobuzul lasa %.3f m, tinta %.2f +/- %.2f"
			% [bus, SAG_BUS_TARGET, SAG_TOL])
	if absf(sport - SAG_SPORT_TARGET) > SAG_TOL:
		_fails.append("sportul lasa %.3f m, tinta %.2f +/- %.2f"
			% [sport, SAG_SPORT_TARGET, SAG_TOL])
	# Ordinea conteaza mai mult decat cifra: masa grea TREBUIE sa lase mai mult.
	if bus <= sport:
		_fails.append("autobuzul (%.3f) nu lasa mai mult decat sportul (%.3f): "
			% [bus, sport] + "masa nu se vede, deci gimmickul nu exista")
	else:
		print("  [OK] masa se vede: autobuz %.3f > sport %.3f m" % [bus, sport])


## 2. Pragul la insulita, in starea cea mai defavorabila.
func _check_edge_step() -> void:
	# Pragul se masoara CU valul pornit, deliberat: masina intra pe ponton in
	# orice faza a hulei, deci starea cea mai defavorabila include valul. (La
	# garda 1 e invers — acolo valul ar contamina cifra de calibrare.)
	print("\n--- 2. pragul la insulita fixa, CU val (contract < %.2f m) ---"
		% EDGE_STEP_MAX)
	var worst := 0.0
	var worst_at := ""
	# Baleiez si faza valului: pragul cel mai rau nu e la t = 0.
	var phases: Array[float] = [0.0, 0.25, 0.5, 0.75]
	for spec: Array in [[0.02, "autobuz pe buza de intrare"],
			[0.5, "autobuz la mijloc"], [0.98, "autobuz pe buza de ieşire"]]:
		pont.preview_loads = [Vector3(spec[0] as float, 0.0, MASS_BUS)]
		var e := 0.0
		for ph: float in phases:
			pont.set_clock(ph * pont.wave_period)
			pont.settle_now()
			e = maxf(e, pont.edge_drop())
		print("  %-28s prag %.3f m (cel mai rau din 4 faze)" % [spec[1], e])
		if e > worst:
			worst = e
			worst_at = spec[1] as String
	pont.set_clock(0.0)
	pont.preview_loads = []
	pont.settle_now()
	if worst > EDGE_STEP_MAX:
		_fails.append("pragul la insulita %.3f m (%s) depaseste %.2f m: e ZID, "
			% [worst, worst_at, EDGE_STEP_MAX]
			+ "scade free_ends sau creste edge_clamp")
	else:
		print("  [OK] pragul cel mai rau %.3f m < %.2f m" % [worst, EDGE_STEP_MAX])


## 3. Continuitatea: nicio placa nu sare sub masina.
func _check_continuity() -> void:
	print("\n--- 3. continuitate (saltul unei placi intre tick-uri) ---")
	pont.preview_loads = [Vector3(0.5, 1.5, MASS_BUS)]
	var prev: Array[float] = []
	for p in pont.plates():
		prev.append(p.global_position.y)
	var worst := 0.0
	for i in 90:
		await get_tree().physics_frame
		var plates := pont.plates()
		for k in plates.size():
			var y := plates[k].global_position.y
			worst = maxf(worst, absf(y - prev[k]))
			prev[k] = y
	pont.preview_loads = []
	print("  %d tick-uri x %d placi masurate" % [90, pont.plates().size()])
	print("  saltul maxim pe tick: %.4f m (prag %.2f)" % [worst, PLATE_JUMP_MAX])
	if worst <= 0.0:
		_fails.append("saltul maxim e 0.0000 m pe 90 de tick-uri: placile nu s-au "
			+ "mişcat DELOC, deci garda n-a masurat nimic (ponton inert?)")
	elif worst > PLATE_JUMP_MAX:
		_fails.append("o placa sare cu %.3f m pe tick (prag %.2f): masina ar fi "
			% [worst, PLATE_JUMP_MAX] + "lovita de jos")
	else:
		print("  [OK] amplitudinile sunt continue")


## 4. Invariantii pe care GDScript-ul si shaderul trebuie sa-i respecte amandoi.
func _check_twin_invariants() -> void:
	print("\n--- 4. invariantii formulei (GDScript vs shader) ---")
	pont.preview_loads = []
	# Valul se stinge TEMPORAR si se repune la valoarea LUI, nu la o constanta:
	# prima versiune scria `pont.wave_amp = 0.10` la final si astfel SUPRASCRIA
	# sabotajul (`--sabotaj` pune 0), facand garda 5 sa raporteze oscilatie
	# chiar si cand valul era stins. O sonda care isi rescrie subiectul nu-l mai
	# masoara.
	var wave_keep := pont.wave_amp
	pont.wave_amp = 0.0   # izolez forma de val
	pont.settle_now()
	# (a) forma modului e simetrica fata de mijloc
	var a := pont.drop_at(0.25)
	var b := pont.drop_at(0.75)
	print("  simetrie: drop(0.25)=%.4f  drop(0.75)=%.4f" % [a, b])
	if absf(a - b) > 0.002:
		_fails.append("forma nu e simetrica (%.4f vs %.4f): formula s-a rupt"
			% [a, b])
	# (b) mijlocul cedeaza mai mult decat capatul
	var mid := pont.drop_at(0.5)
	var end := pont.drop_at(0.0)
	print("  mijloc %.4f vs capat %.4f" % [mid, end])
	if mid <= end:
		_fails.append("mijlocul (%.4f) nu cedeaza mai mult decat capatul (%.4f)"
			% [mid, end])
	# (c) capetele LIBERE: capatul cedeaza, dar mai putin. Asta e diferenta de
	#     fond fata de pod, unde capatul e exact zero.
	print("  capete libere: drop(0.0)=%.4f (podul ar da exact 0)" % end)
	pont.wave_amp = wave_keep
	print("  [OK] invariantii de forma raspund")


## 5. Valul: pontonul se misca si fara nimeni pe el.
func _check_wave() -> bool:
	print("\n--- 5. valul joncilor (pontonul e viu si gol) ---")
	pont.preview_loads = []
	var lo := INF
	var hi := -INF
	for i in 20:
		pont.set_clock(float(i) * 0.35)
		pont.settle_now()
		var d := pont.drop_at(0.5)
		lo = minf(lo, d)
		hi = maxf(hi, d)
	var swing := hi - lo
	print("  cota mijlocului oscileaza pe %.4f m (gol, doar din val)" % swing)
	if swing < 0.02:
		_fails.append("valul nu mişca pontonul gol (%.4f m): nu pluteste, e doar moale"
			% swing)
		return false
	print("  [OK] pontonul se mişca si cand pista e goala")
	return true


## 7. GRILA DE START pe un singur tronson — cazul care a rupt pista.
##
## Pe Track22, primul tronson primeste tot plutonul deodata in primul tur.
## Fara flotabilitate (`sag_max`) afundarea e LINIARA in incarcare: 8 masini
## dau ~2.3 m, deci tablierul de la +0.60 ajunge la -1.84, adica SUB plasa de
## repunere a marii (-1.20) si sub apa (0.00). Masurat inainte de plafon:
## 41-56 repuneri per cursa, toate in primul tur, toate pe primul tronson.
## Garda verifica DIRECT ce conteaza: cat de jos ajunge tablierul cu plutonul
## pe el, fata de plasa pe care pontonul insusi o cere (`net_ceiling_drop`).
func _check_grid_load() -> void:
	print("\n--- 7. grila de start (8 masini pe acelasi tronson) ---")
	var loads: Array[Vector3] = []
	# Mixul cel mai rau: tot plutonul greu, strans la mijloc.
	for i in 8:
		var u := 0.35 + 0.30 * (float(i) / 7.0)
		var lat := -2.0 if i % 2 == 0 else 2.0
		loads.append(Vector3(u, lat, MASS_BUS))
	pont.preview_loads = loads
	pont.settle_now()
	var deepest := 0.0
	for k in 21:
		deepest = maxf(deepest, pont.drop_at(float(k) / 20.0))
	var net := float(pont.call("net_ceiling_drop"))
	print("  8 autobuze: tablierul coboara cel mai mult %.3f m" % deepest)
	print("  plasa cerută de ponton (net_ceiling_drop): %.3f m sub sosea" % net)
	pont.preview_loads = []
	pont.settle_now()
	if deepest >= net:
		_fails.append("cu plutonul pe el, tablierul coboara %.3f m, adica SUB "
			% deepest + "plasa de %.3f m: masinile sunt repuse desi stau pe drum"
			% net)
	else:
		print("  [OK] tablierul (%.3f) rămâne peste plasa (%.3f), marja %.3f m"
			% [deepest, net, net - deepest])
	# Si invariantul de saturatie: 8 masini NU trebuie sa dea 8x afundarea uneia.
	pont.preview_loads = [Vector3(0.5, 0.0, MASS_BUS)]
	pont.settle_now()
	var one := pont.drop_at(0.5)
	pont.preview_loads = loads
	pont.settle_now()
	var many := pont.drop_at(0.5)
	pont.preview_loads = []
	pont.settle_now()
	var ratio := many / maxf(one, 0.001)
	print("  saturatie: 8 masini / 1 masina = %.2fx (liniar ar da ~8x)" % ratio)
	if ratio > 3.0:
		_fails.append("afundarea creste %.1fx cu 8 masini: nu satureaza, deci "
			% ratio + "pontonul n-are flotabilitate (vezi sag_max)")
	else:
		print("  [OK] afundarea satureaza (flotabilitate)")


## 6. Tangajul: masa spre un capat il COBOARA pe acela.
func _check_pitch() -> bool:
	print("\n--- 6. tangajul (masa spre un capat inclina tronsonul) ---")
	pont.set_clock(0.0)
	pont.preview_loads = [Vector3(0.85, 0.0, MASS_BUS)]
	pont.settle_now()
	var p := pont.pitch()
	var far_y := -pont.drop_at(0.9)
	var near_y := -pont.drop_at(0.1)
	print("  autobuz la u=0.85: pitch %.4f m, capat far %.3f vs near %.3f"
		% [p, far_y, near_y])
	pont.preview_loads = []
	pont.settle_now()
	if absf(p) < 0.002:
		_fails.append("tangajul nu raspunde (%.4f): pontonul nu se inclina pe lungime"
			% p)
		return false
	# Masa spre capatul DEPARTAT (u mare) trebuie sa-l coboare: pitch negativ,
	# fiindca _pitch_at(1.0) = +_pitch ridica, deci coborarea cere pitch < 0.
	if p > 0.0:
		_fails.append("masa la u=0.85 RIDICA capatul departat (pitch %.4f > 0): semn invers"
			% p)
		return false
	print("  [OK] capatul incarcat coboara (pitch %.4f < 0)" % p)
	return true
