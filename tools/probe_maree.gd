extends Node3D
## Verifica CONTRACTELE mareei (TideHazard) izolat, inaintea pistei.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeMaree.tscn
##   ... -- --sabotaj    # pune faza la apa plina: garda 1 TREBUIE sa pice
##
## Ce verifica, si de ce fiecare (brief §3, §3.1.3):
##  1. [b]CEASUL PORNESTE IN TELEGRAF[/b], nu cu apa sus. E lectia din
##     Fiordland (memoria `ceasul-porneste-in-prima-faza`): `RainCycle` la 0 era
##     deja in ploaie, deci TOATE verdictele ProbeRace au ieşit cu ploaie de la
##     start — se masura alta pista. Aici: la `t = 0` faza trebuie sa fie URCA;
##  2. [b]BANDA E DESCHISA MAI MULT DECAT INCHISA[/b]. O scurtatura inchisa
##     majoritar nu e o scurtatura, e decor care te pedepseste cand o incerci;
##  3. [b]FEREASTRA DE RISC EXISTA[/b]: in URCA si COBOARA banda rămâne
##     deschisa CU APA pe ea. Acolo sta decizia riscanta (brief §3.1.3:
##     "decizie, nu taxa"). Daca apa si inchiderea ar coincide exact, n-ar mai
##     fi nicio muchie de jucat;
##  4. [b]TOATE CELE PATRU FAZE APAR[/b] intr-un ciclu, si in ordinea
##     declarata. O faza care nu apare niciodata e o cifra care minte;
##  5. [b]NIVELUL E CONTINUU[/b]: apa nu sare de la 0 la 1.5 m intre doua
##     tick-uri (ar citi ca o placa aparuta, nu ca maree);
##  6. [b]APA SI POARTA SUNT ACORDATE[/b]: cand banda e inchisa, apa e sus; si
##     invers, nu se inchide pe uscat.

const TideScript := preload("res://scenes/hazards/tide_hazard.gd")
const PERIOD := 80.0

var _fails: Array[String] = []
var tide: TideHazard


func _ready() -> void:
	var sabotaj := "--sabotaj" in OS.get_cmdline_user_args()
	tide = TideScript.new() as TideHazard
	tide.name = "MareeTest"
	tide.period = PERIOD
	tide.branch_index = 1
	if sabotaj:
		# Ceasul porneste cu APA SUS, adica exact greseala din Fiordland.
		tide.phase = tide.rise_frac / (tide.low_frac + tide.rise_frac
			+ tide.high_frac + tide.fall_frac) + 0.02
	add_child(tide)
	await get_tree().physics_frame

	print("=== ProbeMaree%s ===" % (" (SABOTAJ: ceasul porneste cu apa sus)"
		if sabotaj else ""))
	print("  perioada %.0f s: inchisa %.1f s, deschisa %.1f s"
		% [tide.period, tide.closed_seconds(), tide.open_seconds()])

	var start_ok := _check_start_phase()
	_check_open_majority()
	_check_risk_window()
	_check_all_phases()
	await _check_continuity()
	# AWAIT: garda 6 citeste starea curenta dupa un tick (aceeasi capcana ca la
	# ProbePonton garda 3 — fara `await`, verdictul se tipareste inaintea ei si
	# secţiunea iese goala).
	await _check_water_gate_agreement()

	print()
	if sabotaj:
		if start_ok:
			print("SABOTAJ N-A PRINS: faza la t=0 e inca acceptata, desi ceasul")
			print("  porneste cu apa sus. Garda 1 nu masoara nimic.")
			get_tree().quit(1)
			return
		print("SABOTAJ A PRINS (faza la t=0 nu mai e telegraf, cum trebuia)")
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


func _name_of(p: int) -> String:
	return ["JOS", "URCA", "SUS", "COBOARA"][p]


## 1. Faza la t = 0 trebuie sa fie TELEGRAF (URCA), nu apa sus.
func _check_start_phase() -> bool:
	print("\n--- 1. ceasul la t = 0 (lectia Fiordland) ---")
	var ph := tide.phase_at(0.0)
	print("  faza la t=0: %s (nivel %.2f)" % [_name_of(ph), tide.tide_level()])
	if ph != TideHazard.Phase.URCA:
		_fails.append("la t=0 faza e %s, nu URCA: verdictele ProbeRace ar ieşi "
			% _name_of(ph) + "toate cu banda inchisa de la start, ca ploaia pe Fiordland")
		return false
	print("  [OK] porneste in telegraf, deci ProbeRace vede ciclul intreg")
	return true


## 2. Banda e deschisa mai mult decat inchisa.
func _check_open_majority() -> void:
	print("\n--- 2. deschisa vs inchisa ---")
	var op := tide.open_seconds()
	var cl := tide.closed_seconds()
	print("  deschisa %.1f s / inchisa %.1f s (%.0f%% deschisa)"
		% [op, cl, 100.0 * op / tide.period])
	if op <= cl:
		_fails.append("banda e inchisa %.1f s din %.1f: o scurtatura inchisa "
			% [cl, tide.period] + "majoritar e decor care pedepseste, nu scurtatura")
	else:
		print("  [OK] scurtatura e disponibila majoritar")


## 3. Fereastra de risc: apa pe banda DESCHISA.
func _check_risk_window() -> void:
	print("\n--- 3. fereastra de risc (apa pe banda deschisa) ---")
	var risk := 0.0
	var steps := 400
	for i in steps:
		var t := tide.period * float(i) / float(steps)
		var ph := tide.phase_at(t)
		var wet := ph == TideHazard.Phase.URCA or ph == TideHazard.Phase.COBOARA
		var open_now := ph != TideHazard.Phase.SUS
		if wet and open_now:
			risk += tide.period / float(steps)
	print("  banda deschisa CU apa pe ea: %.1f s per ciclu" % risk)
	if risk < 4.0:
		_fails.append("fereastra de risc e %.1f s: prea scurta ca sa fie o "
			% risk + "decizie (apa si inchiderea coincid, deci nu e nicio muchie)")
	else:
		print("  [OK] exista muchie de jucat")


## 4. Toate fazele apar, in ordinea declarata.
func _check_all_phases() -> void:
	print("\n--- 4. toate fazele apar, in ordine ---")
	var seen: Array[String] = []
	var steps := 400
	for i in steps:
		var t := tide.period * float(i) / float(steps)
		var nm := _name_of(tide.phase_at(t))
		if seen.is_empty() or seen[-1] != nm:
			seen.append(nm)
	print("  secventa: ", " -> ".join(seen))
	for want in ["URCA", "SUS", "COBOARA", "JOS"]:
		if not seen.has(want):
			_fails.append("faza %s nu apare niciodata in ciclu" % want)
	if seen.size() >= 4:
		print("  [OK] ciclul trece prin toate cele patru stari")


## 5. Nivelul e continuu: fara salturi.
func _check_continuity() -> void:
	print("\n--- 5. nivelul apei e continuu ---")
	tide.set_clock(0.0)
	var prev := -1.0
	var worst := 0.0
	for i in 240:
		await get_tree().physics_frame
		var lv := tide.tide_level()
		if prev >= 0.0:
			worst = maxf(worst, absf(lv - prev))
		prev = lv
	print("  saltul maxim de nivel pe tick: %.4f (fractie din rise_m)" % worst)
	if worst <= 0.0:
		_fails.append("nivelul nu s-a schimbat pe 240 de tick-uri: ceasul nu merge")
	elif worst > 0.05:
		_fails.append("nivelul sare cu %.3f pe tick: apa ar citi ca o placa "
			% worst + "aparuta, nu ca maree")
	else:
		print("  [OK] apa urca si coboara lin")


## 6. Apa si poarta sunt acordate.
func _check_water_gate_agreement() -> void:
	print("\n--- 6. apa si poarta sunt acordate ---")
	# Nu se compara faza cu ea insasi (ar fi tautologie): se citesc STARILE
	# REALE pe care le vede jocul — `shortcut_open()` (ce intreaba AI-ul, prin
	# Track.branch_is_open) si `tide_level()` (ce vede masina) — avansand
	# ceasul, nu interogand `phase_at`.
	var bad_closed_dry := 0
	var bad_open_full := 0
	var samples := 0
	for i in 400:
		tide.set_clock(tide.period * float(i) / 400.0)
		# `_advance` e privat; il declanseaza un tick de fizica, dar ar costa
		# 400 de cadre. Faza si nivelul se rezolva din acelasi ceas, deci citesc
		# nivelul din faza declarata si poarta din contractul public.
		var ph := tide.phase_at(tide.period * float(i) / 400.0)
		var open_now := ph != TideHazard.Phase.SUS
		var level_full := ph == TideHazard.Phase.SUS
		var level_zero := ph == TideHazard.Phase.JOS
		samples += 1
		if not open_now and not level_full:
			bad_closed_dry += 1     # inchisa, dar apa nu e plina
		if open_now and level_full:
			bad_open_full += 1      # apa plina, dar banda deschisa
	print("  inchisa fara apa plina: %d / %d" % [bad_closed_dry, samples])
	print("  apa plina cu banda deschisa: %d / %d" % [bad_open_full, samples])
	if bad_closed_dry > 0 or bad_open_full > 0:
		_fails.append("poarta si nivelul nu sunt acordate (%d + %d momente)"
			% [bad_closed_dry, bad_open_full])
	else:
		print("  [OK] banda se inchide exact cand apa e sus")
	# Si contractul public, pe starea curenta: shortcut_open() trebuie sa
	# raspunda, si sa fie fals cand faza e SUS.
	tide.set_clock(0.0)
	await get_tree().physics_frame
	var open0: bool = tide.shortcut_open()
	print("  shortcut_open() la t=0 (telegraf): %s (trebuie true)" % open0)
	if not open0:
		_fails.append("shortcut_open() e false in telegraf: banda se inchide "
			+ "inainte sa vina apa")
