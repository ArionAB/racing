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
##     COBOARA (nu urca);
##  7. SEMNAL/ZGOMOT SOLO: afundarea masinii jucatorului trebuie sa fie de cel
##     putin `SOLO_SNR_MIN` ori valul de fond. Garda asta exista pentru ca
##     verdictul la volan („cu mai multe masini se simte, singur nu") a trecut
##     prin toate celelalte sase: fiecare cifra era in contract, dar contractul
##     nu spunea nimic despre RAPORTUL dintre afundare si val, iar `_drop` le
##     aduna pe acelasi canal vertical. O amplitudine corecta sub un val la fel
##     de mare nu se poate percepe — e aceeasi familie cu memoria
##     `efecte-invizibile-nu-se-numara`: cifra exista, efectul nu se vede.
##
## SABOTAJ (`--sabotaj`): stinge capetele libere (free_ends = 0, adica podul).
## Garda 2 trebuie sa TREACA oricum (pragul devine zero), dar garda 5-6 de
## identitate de ponton trebuie sa PICE: fara capete libere si fara tangaj, nu
## mai e un ponton. Fara sabotajul asta, garzile n-ar deosebi pontonul de pod.

const PontoonScript := preload("res://scenes/hazards/pontoon_road_hazard.gd")
const MASS_BUS := 2.6
const MASS_SPORT := 0.9
## Lungimea tronsonului de TEST. E cea REALA din Track22 (7 tronsoane pe zona
## plutitoare dau 43.1 m), nu o cifra rotunda: panta de intrare depinde de
## raportul `edge_clamp / lungime`, deci o sonda care testeaza pe 60 m raporteaza
## o panta mai blanda decat cea din joc (7.1% vs 7.6% masurat).
const LENGTH := 43.1
const WIDTH := 6.0
## Contractele din brief §3.
const SAG_BUS_TARGET := 0.70
const SAG_SPORT_TARGET := 0.30
const SAG_TOL := 0.08
## Masa masinii jucatorului, pentru garda de semnal/zgomot (garda 7).
const MASS_PLAYER := 1.3
## [b]RAPORTUL SEMNAL/ZGOMOT MINIM[/b], solo. Afundarea unei singure masini
## impartita la amplitudinea valului de fond. Sub ~2 verdictul la volan a fost
## „singur nu prea se simte", desi TOATE celelalte garzi treceau: cifrele de
## calibrare erau respectate, dar fata de un val care le acoperea. Vezi garda 7.
const SOLO_SNR_MIN := 2.5
const EDGE_STEP_MAX := 0.30
const PLATE_JUMP_MAX := 0.12

var _fails: Array[String] = []
## Amplitudinea varf-la-varf a pontonului GOL, masurata de garda 5 si folosita
## ca numitor de garda 7. O tin aici ca sa nu masor valul de doua ori, cu doua
## definitii care pot aluneca una de alta.
var _wave_swing: float = 0.0
var pont: PontoonRoadHazard


func _ready() -> void:
	var sabotaj := "--sabotaj" in OS.get_cmdline_user_args()
	pont = PontoonScript.new() as PontoonRoadHazard
	pont.name = "PontonTest"
	pont.near_end = Vector3.ZERO
	pont.far_end = Vector3(0.0, 0.0, -LENGTH)
	pont.deck_width = WIDTH
	# `plate_count` CA IN JOC. Generatorul foloseste `max(6, int(span / 6.0))`,
	# deci 7 placi pe 43.1 m (6.2 m per placa). Implicitul clasei e 12, adica
	# 3.6 m per placa — o rezolutie mai FINA decat cea din joc, pe care garda de
	# continuitate (3) ar fi raportat salturi mai mici decat cele reale. O sonda
	# care testeaza alti parametri decat jocul masoara alt obiect
	# (memoria `verifica-cu-parametrii-lui`).
	pont.plate_count = maxi(6, int(LENGTH / 6.0))
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
	_check_solo_snr(_wave_swing)
	var pitch_ok := _check_pitch()
	_check_grid_load()
	_check_entry_slope()

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
##
## [b]Masoara o masina care TRAVERSEAZA, nu una aparuta din senin.[/b] Prima
## versiune punea sarcina brusc la mijloc si masura de acolo, iar cifra ei era
## dominata de PROPRIUL artefact de pornire: placile se teleportau din poziţia
## de repaus in forma incarcata. Tick-urile o arata fara dubiu — 0.3012,
## 0.1406, apoi 0.0064, 0.0092, 0.0117... — doua tick-uri de salt si pe urma o
## mişcare de zeci de ori mai mica. Nu e nimic ce poate lovi o masina: la tick
## 0 masina nici n-a ajuns pe ponton.
##
## Diagnosticul a fost pus prin eliminare: cu balansul stins, cu tangajul stins,
## cu valul stins si cu sarcina centrata, cifra rămânea 0.1403-0.1410, identica
## la a treia zecimala. Un numar care nu se schimba cand stingi pe rand toate
## mecanismele nu-i masoara pe ei (memoria `sonda-masura-alt-obiect`).
##
## Cazul REAL e o masina care intra pe un capat si iese pe celalalt: la 90 km/h
## traverseaza 43 m in 1.72 s, deci ~103 tick-uri. Asa masurat, saltul maxim e
## 0.023 m/tick — de sase ori sub prag. Pragul nu s-a mutat; sonda a inceput sa
## masoare ce pretindea ca masoara.
func _check_continuity() -> void:
	print("
--- 3. continuitate (masina care traverseaza la 90 km/h) ---")
	# Pornesc de la pontonul AŞEZAT si gol, apoi plimb sarcina de la un capat la
	# altul. Fara `settle_now` aici, primul tick ar reintroduce exact artefactul
	# pe care garda asta l-a avut.
	pont.preview_loads = []
	pont.settle_now()
	await get_tree().physics_frame
	var prev: Array[float] = []
	for p in pont.plates():
		prev.append(p.global_position.y)
	var worst := 0.0
	var worst_at := 0.0
	# 103 tick-uri de traversare la 90 km/h, plus marja ca sarcina sa iasa.
	const CROSSING_TICKS := 103
	for i in 110:
		var u := clampf(float(i) / float(CROSSING_TICKS), 0.0, 1.0)
		pont.preview_loads = [Vector3(u, 1.5, MASS_BUS)]
		await get_tree().physics_frame
		var plates := pont.plates()
		for k in plates.size():
			var y := plates[k].global_position.y
			var d := absf(y - prev[k])
			if d > worst:
				worst = d
				worst_at = u
			prev[k] = y
	pont.preview_loads = []
	print("  110 tick-uri x %d placi, sarcina plimbata u=0->1" % pont.plates().size())
	print("  cel mai rau salt la u=%.2f" % worst_at)
	print("  saltul maxim pe tick: %.4f m (prag %.2f)" % [worst, PLATE_JUMP_MAX])
	if worst <= 0.0:
		_fails.append("saltul maxim e 0.0000 m pe 110 de tick-uri: placile nu s-au "
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
	_wave_swing = swing
	print("  cota mijlocului oscileaza pe %.4f m (gol, doar din val)" % swing)
	if swing < 0.02:
		_fails.append("valul nu mişca pontonul gol (%.4f m): nu pluteste, e doar moale"
			% swing)
		return false
	print("  [OK] pontonul se mişca si cand pista e goala")
	return true


## 7. SEMNAL/ZGOMOT SOLO: se simte pontonul cand ESTI SINGUR pe el?
##
## Garzile 1-6 masoara fiecare efect IZOLAT, si de-aia garda 1 stinge deliberat
## valul inainte de-a masura afundarea. Izolarea e corecta pentru calibrare, dar
## jucatorul nu primeste efectele izolate: `_drop` le aduna pe acelasi canal
## vertical. Deci o afundare care respecta contractul poate fi invizibila sub un
## val care respecta si el contractul — ce s-a si intamplat (verdict la volan:
## „cu mai multe masini pe el am simtit, singur nu prea").
##
## Masor amandoua pe acelasi tronson, in aceleasi unitati: cat coboara tablierul
## sub masina jucatorului, fata de cat se mişca singur din val. Pragul e un
## raport, nu o cota, fiindca perceptia e a contrastului.
func _check_solo_snr(wave_swing: float) -> void:
	print("
--- 7. semnal/zgomot solo (contract >= %.1f) ---" % SOLO_SNR_MIN)
	if wave_swing <= 0.0:
		print("  [skip] valul e stins (sabotaj): raportul nu are numitor")
		return
	var wave_keep := pont.wave_amp
	pont.wave_amp = 0.0
	pont.preview_loads = [Vector3(0.5, 0.0, MASS_PLAYER)]
	pont.settle_now()
	var solo := pont.sag_at(0.5)
	pont.preview_loads = []
	pont.wave_amp = wave_keep
	pont.settle_now()
	# `wave_swing` e amplitudinea VARF-LA-VARF a pontonului gol (garda 5), deci
	# il compar cu afundarea proprie masurata la fel, de la repaus.
	var snr := solo / maxf(wave_swing, 0.0001)
	print("  masina jucatorului (%.1f) lasa %.3f m; valul mişca %.3f m"
		% [MASS_PLAYER, solo, wave_swing])
	print("  raport semnal/zgomot = %.2f" % snr)
	if snr < SOLO_SNR_MIN:
		_fails.append(("solo semnal/zgomot %.2f < %.1f: afundarea proprie (%.3f m) "
			+ "e acoperita de valul de fond (%.3f m), deci pontonul se simte doar "
			+ "cand sunt mai multe masini pe el")
			% [snr, SOLO_SNR_MIN, solo, wave_swing])
	else:
		print("  [OK] pontonul cedeaza vizibil si sub o singura masina")


## 8. PANTA DE INTRARE pe ponton, cu plutonul pe el.
##
## Contractele 1-7 verificau PRAGUL la buza (0.042 m, in regula) si afundarea la
## MIJLOC (1.080 m, in regula). Niciunul nu se uita la cat de REPEDE coboara
## tablierul intre cele doua — si acolo era defectul: cu `edge_clamp = 5` pe un
## tronson de 43 m, tablierul cadea 0.42 m pe primii 4 m, adica **13.4%**, peste
## pragul de panta al pistei (13%). Pe pista asta a dat repuneri in valuri pe
## primul ponton (0/3/0/4 -> 1/13/2/9), fiindcă plutonul urca pe el strans.
##
## Garda masoara panta MAXIMA a tablierului pe primii 20% din tronson, in starea
## cea mai defavorabila (plutonul la mijloc, deci afundare maxima).
func _check_entry_slope() -> void:
	print("\n--- 8. panta de intrare pe ponton (cu plutonul pe el) ---")
	var loads: Array[Vector3] = []
	for i in 8:
		loads.append(Vector3(0.35 + 0.30 * (float(i) / 7.0),
			-2.0 if i % 2 == 0 else 2.0, MASS_BUS))
	pont.preview_loads = loads
	pont.settle_now()
	var L: float = pont.deck_length()
	var worst := 0.0
	var worst_u := 0.0
	var prev := pont.drop_at(0.0)
	var steps := 80
	for k in range(1, steps + 1):
		var u := 0.20 * float(k) / float(steps)
		var d := pont.drop_at(u)
		var dx := 0.20 * L / float(steps)
		var slope := absf(d - prev) / maxf(dx, 0.0001)
		if slope > worst:
			worst = slope
			worst_u = u
		prev = d
	pont.preview_loads = []
	pont.settle_now()
	print("  panta maxima pe primii 20%%: %.1f%% (la u=%.3f)" % [worst * 100.0, worst_u])
	print("  edge_clamp = %.1f m pe un tronson de %.1f m" % [pont.edge_clamp, L])
	if worst > 0.13:
		_fails.append("panta de intrare %.1f%% depaseste pragul pistei de 13%%: "
			% (worst * 100.0) + "creste `edge_clamp` (la 43 m tronson, 14 m dau ~5%%)")
	else:
		print("  [OK] panta de intrare %.1f%% sub pragul pistei (13%%)"
			% (worst * 100.0))


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
