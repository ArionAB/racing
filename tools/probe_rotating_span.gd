extends Node
## Sonda pasajului rotativ (Chongqing, brief §2 POI F si §3): tine ciclul,
## telegraph-ul si contractul de pedeapsa, cu masina REALA (Car.tscn) pe o
## pista-test?
##
## Pista-test: o bucla-stadion din TrackFromPath, cu dreapta de est pe x = 0,
## de la z = +140 la z = -140 (sensul de mers e -Z, deci nodul hazardului sta
## cu yaw 0). Soseaua e LATA (semilatime 16 m) dinadins: rampa de serviciu a
## hazardului iese 13 m lateral, si vrem ca ea sa cada tot pe carosabil —
## altfel decorul temei ar fi avut coliziune fix pe ocol, iar sonda ar fi
## masurat copaci, nu hazard. Pasajul insusi e ridicat cu 3 m (`deck_rise`),
## fiindca golul trebuie sa fie GOL: pe pista adevarata rampa nodului
## Huangjuewan e oricum pe piloni.
##
##  (0)   ciclul: intre doua inceputuri de rotatie trec exact `period` secunde.
##  (i)   telegraph: galbenul se aprinde cu `telegraph_lead` (3 s) inainte de
##        fiecare rotatie, si abia dupa el pleaca tronsonul.
##  (ii)  DESCHIS: masina trece pe tronson de la z=+70 la z=-70, nu cade
##        (y >= cota pasajului), nu e strivita, ramane in cursa, isi pastreaza
##        indexul si iese pe sosea. La TREI viteze de intrare (16/24/30 m/s).
##  (iii) INCHIS + ocol: aceleasi traversari pe rampa de serviciu, la aceleasi
##        trei viteze — aceleasi conditii de integritate. Trei fiindca un ocol
##        care merge la 24 m/s poate foarte bine sa fie de netrecut la 30
##        (ratezi cotul) sau un fund de sac la 16 (nu mai iesi din palnie).
##  (iv)  contractul de pedeapsa: (iii) - (ii) e o intarziere REALA, in
##        fereastra ancorata in brief (+3 s) — vezi PENALTY_MIN/PENALTY_MAX.
##  (v)   INCHIS + drept in poarta: golul nu e capcana mortala. Masina NU cade
##        in gol, NU e distrusa, si NU ramane intepenita — dupa ce se opreste
##        in bariere, acelasi sofer o duce pe ocol si termina traversarea.
##  (vi)  poarta nu se inchide peste o masina: cu o masina in dreptul portii
##        exact la comutare, colizorul asteapta (`gate_hold` > 0) si masina
##        nu e strivita.
##
## Ruleaza CA SCENA (masina cere autoload-urile):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeRotatingSpan.tscn
## Iese cu cod 1 la orice verdict picat.

const SpanScript := preload("res://scenes/hazards/rotating_span_hazard.gd")
const WaypointDriver := preload("res://tools/probe_waypoint_driver.gd")
const CAR_SCENE: String = "res://scenes/cars/Car.tscn"

const POINTS: Array[Vector3] = [
	Vector3(0, 0, 140), Vector3(0, 0, 60), Vector3(0, 0, -60), Vector3(0, 0, -140),
	Vector3(-40, 0, -190), Vector3(-100, 0, -190),
	Vector3(-140, 0, -140), Vector3(-140, 0, -60),
	Vector3(-140, 0, 60), Vector3(-140, 0, 140),
	Vector3(-100, 0, 190), Vector3(-40, 0, 190),
]
## Semilatimea soselei-test si capetele traversarii NU mai sunt cifre fixe:
## se deriva din gabaritul hazardului (vezi `_fit_track()`). Astea sunt doar
## minimele de la care se pleaca — pista-test nu are voie sa fie mai stramta
## decat lumea in care traieste hazardul, si o cifra scrisa de mana ramane in
## urma la prima marire a rampei de serviciu. Prima incercare de a mari ocolul
## in sesiunea asta a iesit cu rampa in decorul temei, exact din motivul asta.
const HALF_WIDTH_MIN: float = 16.0
const DECK_RISE: float = 3.0
const START_MIN: float = 70.0
## Cat teren liber ramane intre marginea rampei de serviciu si buza soselei.
const TRACK_MARGIN: float = 2.5
## Cati metri de sosea plana se lasa inainte de rampa de urcare a modulului.
const APPROACH: float = 8.0

var HALF_WIDTH: float = HALF_WIDTH_MIN
var START_Z: float = START_MIN
var FINISH_Z: float = -START_MIN
const ENTRY_SPEED: float = 24.0
## Vitezele de intrare la care se verifica traversarea (m/s). Contractul de
## pedeapsa se citeste la `ENTRY_SPEED`; celelalte doua sunt capetele plajei
## cu care se poate ajunge pe rampa nodului si raspund la o intrebare separata
## de cost: ramane ocolul TRECABIL, fara blocaje, si cand intri in el prea
## incet sau prea repede?
const ENTRY_SPEEDS: Array[float] = [16.0, ENTRY_SPEED, 30.0]
## Viteza cu care se intra in bariere la testul (v). Cea mai mare: la 30 m/s
## masina inainteaza 0.5 m intre doua cadre de fizica, deci acolo se vede si
## tunelarea prin peretele portii, si cea mai urata intrare in palnie.
const GATE_SPEED: float = 30.0
## Cat de mult sub cota pasajului inseamna „a cazut in gol".
const FALL_MARGIN: float = 1.2
## Semilatimea carosabilului hazardului (implicitul lui `road_half_width`).
const HW_HAZ: float = 3.4
## Fereastra contractului de pedeapsa (s). [b]Cifra vine din brief §3
## („inchis -> rampa de serviciu (+3 s)") si §2 randul F, nu din ce s-a
## masurat[/b] — de aceea e stransa in jurul lui 3.0 si nesimetrica doar cat
## sa incapa zgomotul dintre rulari (fizica pe mai multe fire nu da de doua
## ori acelasi zecime — memoria `proberace-nedeterminism`).
##
## [b]Nu se mai muta.[/b] Runda 2 a avut-o la [1.0, 6.0] si asa a trecut o
## deviere de +1.90 s, adica 63% din contract: cu pragul de jos la 1.0 sonda
## ar fi spus „OK" si la +1.1 s, adica si atunci cand gimmickul si-ar fi
## pierdut motivul de a exista (daca ocolul e gratis, semaforul e decor).
## Un prag pus in jurul masuratorii nu masoara nimic — e precedentul
## plafonului de triunghiuri din CLAUDE.md, ridicat de cinci ori pana cand a
## incetat sa mai fie o limita. Daca masuratoarea iese din fereastra, se
## schimba GEOMETRIA rampei de serviciu (`service_offset`, `service_lead`),
## nu cifrele de aici.
const PENALTY_MIN: float = 2.5
const PENALTY_MAX: float = 4.0
## Cat are voie sa coste ATINGEREA barierelor, fata de trecerea deschisa (s).
##
## Verdictul care lipsea in runda 1. Contractul din brief e „+3 s, nu
## distrugere", si el se refera la ocol — dar cine ignora si semaforul, si
## barierele, plateste tot un pret, si acela trebuie sa fie tot o pedeapsa de
## cursa, nu sfarsitul ei. Criticul a masurat +18.7 s la prima versiune (masina
## in noua cicluri de marsarier in poarta): intr-o cursa de 2-3 minute aia nu e
## o pedeapsa, e abandon. Plafonul e un ordin de marime sub el.
const BARRIER_COST_MAX: float = 10.0
## Cat sta sonda sa se uite la masina oprita in bariere inainte sa incerce
## iesirea (s). Scurt dinadins: fiecare secunda in plus intra in cost si l-ar
## umfla artificial. Verdictele de „nu cade / nu trece / nu e distrusa" se
## decid oricum in prima secunda dupa impact.
##
## Se numara de la IMPACT, nu de la pornire. Cat timp era numarat de la
## pornire, cifra depindea de unde sta poarta — iar poarta se muta odata cu
## rampa de serviciu (`_gate_z()` o aduce in fereastra de desprindere). Cu
## rampa lungita, o fereastra fixa de 2.5 s de la pornire s-ar fi inchis
## inainte ca masina sa ajunga in bariere, si sonda ar fi dat „nu cade, nu e
## strivita" despre o masina care inca gonea pe pasaj.
const STUCK_WATCH: float = 1.0
## Plafon de siguranta pentru asteptarea impactului (s).
const GATE_APPROACH_MAX: float = 12.0

var _track: TrackFromPath
var _hazard: SpanScript
var _fails: int = 0
## Aderenta laterala cu care soferul de sonda citeste curbele ocolului
## (m/s^2). Masina reala trage ~2 g pe asfalt (masurat aici: 19 m/s prin
## curbe de 14.7 m => 24 m/s^2), deci 16 e sub limita ei: soferul ridica
## piciorul din timp si trece curat. Sonda trebuie sa masoare cat te costa
## DRUMUL, nu cat te costa un sofer care nu franeaza.
const CORNER_GRIP: float = 16.0
## Sub viteza asta, o traversare nu mai e „incetinita de drum", ci „oprita de
## ceva" (m/s). Un ocol care te aduce la pas nu e o pedeapsa de +3 s, e un
## accident care se intampla sa dureze cat una — si daca sonda nu face
## distinctia, orice geometrie care ciocneste bine trece drept geometrie care
## costa bine. Cifra e cam jumatate din viteza de croaziera prin cotul cel mai
## stramt.
const CRAWL_SPEED: float = 6.0

var _grip: float = CORNER_GRIP
## Cat de departe in fata isi ia soferul de sonda punctul urmator (m).
##
## Nu e o rotita de reglaj, e rezolutia instrumentului. Cu 7 m — implicitul
## soferului — masina taie orice curba mai stransa de ~20 m si se freaca de
## parapeti; sonda masoara atunci CIOCNIRI, nu geometrie, si cifra sare
## nemonoton (masurat in sesiunea asta: ocol de 18 m -> +3.12 s, ocol de 20 m,
## mai mare, -> +2.28 s, fiindca la al doilea masina n-a atins zidul).
## Un ocol se conduce urmarind banda, nu tintind in departare.
var _reach: float = 4.5


## Cat de lata trebuie sa fie soseaua-test si de unde pana unde se conduce,
## ca rampa de serviciu sa cada tot pe carosabil si modulul sa incapa intreg
## intre start si sosire. Se calculeaza DUPA ce hazardul stie ce geometrie
## are, si inainte ca pista sa fie construita.
func _fit_track() -> void:
	var reach: float = _hazard.road_half_width * 0.45 + _hazard.service_offset 		+ _hazard.service_width * 0.5
	HALF_WIDTH = maxf(HALF_WIDTH_MIN, reach + TRACK_MARGIN)
	var module: float = _hazard.span_length * 0.5 + _hazard.deck_run 		+ _hazard.ramp_run
	START_Z = maxf(START_MIN, module + APPROACH)
	FINISH_Z = -START_Z


func _ready() -> void:
	_hazard = SpanScript.new()
	_hazard.name = "RotatingSpan"
	_hazard.deck_rise = DECK_RISE
	_hazard.service_side = -1 # spre interiorul buclei
	# Override-uri de GEOMETRIE pentru cautarea formei. Sunt aici fiindca forma
	# care plateste contractul de +3 s nu se gaseste pe hartie: modelul de
	# „viteza limitata de raza" a prezis in sesiunea asta ca arcele bat sinusul,
	# iar masuratoarea a spus invers (1.53 vs 1.90). Ce NU se poate da din linia
	# de comanda e fereastra contractului — aia sta in cod, in PENALTY_MIN/MAX.
	for a in OS.get_cmdline_user_args():
		if a == "--no-deck-parapet":
			_hazard.deck_parapet = 0.0
		elif a == "--no-service-parapet":
			_hazard.service_parapet = 0.0
		elif a.begins_with("--offset="):
			_hazard.service_offset = float(a.substr(9))
		elif a.begins_with("--lead="):
			_hazard.service_lead = float(a.substr(7))
		elif a.begins_with("--width="):
			_hazard.service_width = float(a.substr(8))
		elif a.begins_with("--reach="):
			_reach = float(a.substr(8))
		elif a.begins_with("--grip="):
			_grip = float(a.substr(7))
		elif a.begins_with("--skew="):
			_hazard.gate_skew_deg = float(a.substr(7))
		elif a.begins_with("--push="):
			_hazard.gate_push = float(a.substr(7))
		elif a.begins_with("--ratio="):
			_hazard.service_entry_ratio = float(a.substr(8))
	_hazard.deck_run = maxf(_hazard.deck_run, _hazard.service_lead + 4.0)
	_fit_track()

	_track = TrackFromPath.new()
	var path := Path3D.new()
	path.name = "Path"
	var curve := Curve3D.new()
	for p in POINTS:
		curve.add_point(p)
	path.curve = curve
	_track.add_child(path)
	_track.custom_name = "ProbeRotatingSpan"
	_track.custom_theme = "forest"
	_track.custom_half_width = HALF_WIDTH
	add_child(_track)
	await get_tree().process_frame
	add_child(_hazard)
	await get_tree().physics_frame
	await get_tree().physics_frame

	print("=== PASAJUL ROTATIV: ciclu, telegraph, contract de pedeapsa ===")
	print("  period %.1f s (asteptare %.2f + rotatie %.1f, de doua ori), telegraph %.1f s"
		% [_hazard.period, _hazard.hold_time(), _hazard.turn_time, _hazard.telegraph_lead])
	print("  gol %.2f m, pasaj +/-%.1f m, rampa %.1f m, cota pasajului %.1f m"
		% [_hazard.span_length, _hazard.deck_run, _hazard.ramp_run, DECK_RISE])
	print("  sosea-test: semilatime %.1f m, traversare z %+.0f -> %+.0f"
		% [HALF_WIDTH, START_Z, FINISH_Z])
	var sw := _hazard.service_waypoints()
	print("  ocol: %d puncte, de la %s la %s, iesire laterala max %.1f m"
		% [sw.size(), str(sw[0].round()), str(sw[sw.size() - 1].round()),
		_lateral_max(sw)])
	print("  ocol: intrare R=%.1f m, mijloc R=%.1f m, abatere max %.0f°, pe %.1f m de drum -> ~%.1f m/s prin mijloc"
		% [_hazard.entry_radius(), _hazard.service_radius(),
		rad_to_deg(_hazard.service_turn()),
		_hazard.span_length + 2.0 * _hazard.service_lead,
		_hazard.service_speed(CORNER_GRIP)])
	print("  fereastra de desprindere |z| %s, poarta la z=%.2f (dorit %.2f)"
		% [str(_hazard.merge_window()), _hazard.gate_z(),
		_hazard.span_length * 0.5 + _hazard.gate_lead])
	var ext := _hazard.gate_extent()
	print("  poarta: perete x %.2f..%.2f (drumul e %.1f..%.1f); ocolul la poarta: axa %.2f, margine interioara %.2f"
		% [ext[0], ext[1], -HW_HAZ, HW_HAZ,
		_hazard.service_center_mag(_hazard.gate_z()),
		_hazard.service_inner_mag(_hazard.gate_z())])
	await _run()
	print("=== %s ===" % ("PICAT: %d verdicte" % _fails if _fails > 0 else "TOATE OK"))
	get_tree().quit(1 if _fails > 0 else 0)


## Masina e deasupra modulului inaltat (pasaj plan + gol + ocol), acolo unde
## „sub cota pasajului" chiar inseamna cazuta?
func _over_module(car: Car) -> bool:
	var z := car.global_position.z
	return absf(z) < _hazard.span_length * 0.5 + _hazard.deck_run


## Ce atinge masina: raze scurte pe opt directii din centrul caroseriei.
## Un verdict „blocata" fara asta e o cifra fara vinovat — si vinovatul (poarta?
## parapetul ocolului? parapetul pasajului?) decide ce se repara.
func _around(car: Car) -> String:
	var space := car.get_world_3d().direct_space_state
	var from := car.global_position + Vector3.UP * 0.5
	var out := ""
	for i in 8:
		var ang := TAU * float(i) / 8.0
		var dir := Vector3(sin(ang), 0.0, -cos(ang))
		var q := PhysicsRayQueryParameters3D.create(from, from + dir * 3.0)
		q.exclude = [car.get_rid()]
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			continue
		var col: Node = hit["collider"]
		out += "%s@%.1fm(%s) " % [_dir_name(i),
			from.distance_to(hit["position"]), col.name]
	return out if out != "" else "liber"


func _dir_name(i: int) -> String:
	return ["fata", "fata-dr", "dr", "spate-dr", "spate", "spate-st", "st",
		"fata-st"][i]


func _lateral_max(pts: Array[Vector3]) -> float:
	var m := 0.0
	for p in pts:
		m = maxf(m, absf(p.x))
	return m


func _verdict(ok: bool, text: String) -> void:
	print("  [%s] %s" % ["OK" if ok else "PICAT", text])
	if not ok:
		_fails += 1


func _spawn(at: Vector3, speed: float) -> Car:
	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(car)
	car.apply_data(GameState.CAR_DATA[0])
	car.track = _track
	# Botul spre -Z: sensul de mers pe dreapta de est a buclei-test.
	car.global_transform = Transform3D(Basis.IDENTITY, at)
	car.velocity = Vector3(0, 0, -speed)
	car.route = 0
	car.road_index = _track.closest_index_global(at, 0)
	car.last_safe_index = car.road_index
	car.last_safe_route = 0
	car.race_active = true
	return car


## Asteapta pana la inceputul starii cerute (t din ciclu aproape de granita).
func _wait_state(want: int, timeout: float = 60.0) -> bool:
	var was := _hazard.state()
	for _f in int(timeout * 60.0):
		await get_tree().physics_frame
		if _hazard.state() == want and was != want:
			return true
		was = _hazard.state()
	return false


# ------------------------------------------------------- (0) + (i) ceasuri

func _measure_cycle() -> void:
	print("--- (0)+(i) ceasul si telegraph-ul")
	var samples: Array[float] = []
	var lead_first := -1.0
	var lead_second := -1.0
	var t_prev_turn := -1.0
	var t := 0.0
	var yellow_since := -1.0
	var was := _hazard.state()
	for _f in int(_hazard.period * 2.6 * 60.0):
		await get_tree().physics_frame
		t += 1.0 / 60.0
		var lamp := _hazard.lamp()
		if lamp == 1 and yellow_since < 0.0:
			yellow_since = t
		var now := _hazard.state()
		var turning := now == SpanScript.State.TURNING_SHUT \
			or now == SpanScript.State.TURNING_OPEN
		var was_turning := was == SpanScript.State.TURNING_SHUT \
			or was == SpanScript.State.TURNING_OPEN
		if turning and not was_turning:
			if t_prev_turn > 0.0:
				samples.append(t - t_prev_turn)
			if yellow_since > 0.0:
				var lead := t - yellow_since
				if lead_first < 0.0:
					lead_first = lead
				elif lead_second < 0.0:
					lead_second = lead
			t_prev_turn = t
			yellow_since = -1.0
		was = now
	# Intre doua inceputuri de rotatie e o JUMATATE de ciclu (inchidere si
	# deschidere), deci perioada e suma a doua intervale consecutive.
	var half_a := samples[0] if samples.size() > 0 else 0.0
	var half_b := samples[1] if samples.size() > 1 else 0.0
	print("    rotatii masurate: %s; jumatatile %.2f + %.2f = %.2f s (cerut %.1f)"
		% [str(samples), half_a, half_b, half_a + half_b, _hazard.period])
	print("    galbenul apare cu %.2f / %.2f s inainte de rotatie (cerut %.1f)"
		% [lead_first, lead_second, _hazard.telegraph_lead])
	_verdict(absf(half_a + half_b - _hazard.period) < 0.2,
		"ciclul complet e %.2f s (cerut %.1f)" % [half_a + half_b, _hazard.period])
	_verdict(absf(lead_first - _hazard.telegraph_lead) < 0.25
			and absf(lead_second - _hazard.telegraph_lead) < 0.25,
		"telegraph-ul precede fiecare rotatie cu %.1f s" % _hazard.telegraph_lead)


# ------------------------------------------------------------ traversarile

## Conduce o masina de la START_Z la FINISH_Z pe punctele date. Intoarce
## secundele (INF daca n-a ajuns) si tipareste ce s-a intamplat.
func _drive(label: String, points: Array[Vector3], timeout: float = 22.0,
		car_out: Array = [], entry: float = ENTRY_SPEED) -> float:
	var car := _spawn(Vector3(0.0, 0.7, START_Z), entry)
	car_out.append(car)
	var driver := WaypointDriver.new()
	driver.waypoints = points
	driver.reach = _reach
	driver.corner_grip = _grip
	driver.target_speed = 30.0
	car.set_controller(driver)
	var t := 0.0
	var min_y := INF
	var max_crush := 0.0
	var idx_start := car.road_index
	var frames := 0
	# Cea mai mica viteza de peste modul. Cifra asta separa cele doua feluri de
	# a pierde timp: un ocol care te tine la 13 m/s fiindca ASA e desenat, si
	# unul care te opreste fiindca ai intrat in parapet. Prima e pedeapsa din
	# brief, a doua e un accident — si arata la fel in cronometru.
	var min_speed := INF
	while t < timeout:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		frames += 1
		if _over_module(car):
			min_speed = minf(min_speed, car.horizontal_speed())
		# Cota se masoara DOAR peste modul (pasaj + gol + ocol). Prima versiune
		# lua minimul pe tot drumul si pica de fiecare data pe soseaua-test de
		# la y = 0, adica raporta „a cazut in gol" pentru o masina care nici nu
		# urcase inca pe pasaj.
		if _over_module(car):
			min_y = minf(min_y, car.global_position.y)
		max_crush = maxf(max_crush, car.crush_time)
		if frames % 60 == 0:
			print("    %s t=%5.2f pos %s v=%5.1f roti %d index %d (frac %.3f)"
				% [label, t, str(car.global_position.round()),
				car.horizontal_speed(), car.wheels_on_ground, car.road_index,
				_track.frac_at(car.road_index)])
		if car.global_position.z <= FINISH_Z:
			break
	var arrived := car.global_position.z <= FINISH_Z
	print("--- %s: %s in %.2f s; y min %.2f (pasaj la %.1f), viteza min %.2f, strivire max %.2f s, activa %s, index %d -> %d"
		% [label, "ajunsa" if arrived else "NEAJUNSA", t, min_y, DECK_RISE,
		min_speed, max_crush, str(car.race_active), idx_start, car.road_index])
	_verdict(min_speed > CRAWL_SPEED,
		"%s: nu se tarie prin modul (viteza minima %.2f > %.1f m/s)"
		% [label, min_speed, CRAWL_SPEED])
	_verdict(min_y > DECK_RISE - FALL_MARGIN,
		"%s: nu cade in gol (y min %.2f > %.2f)" % [label, min_y, DECK_RISE - FALL_MARGIN])
	_verdict(max_crush <= 0.01, "%s: nu e strivita (crush %.2f s)" % [label, max_crush])
	_verdict(car.race_active, "%s: ramane in cursa" % label)
	return t if arrived else INF


## Traseul benzii directe: axa pasajului, apoi iesirea pe sosea.
func _direct_route() -> Array[Vector3]:
	var route: Array[Vector3] = _hazard.direct_waypoints()
	route.append(Vector3(0.0, 0.0, FINISH_Z - 20.0))
	return route


## Traseul ocolului: cateva puncte pe axa, INAINTEA desprinderii, apoi axa
## rampei de serviciu, apoi iesirea.
##
## Punctele de racord se calculeaza din capetele reale ale rampei, nu se scriu
## de mana: rampa s-a lungit (14 -> 28 m de lead) ca sa-si plateasca cele 3 s,
## iar cele doua puncte fixe de dinainte (z = 45 si 28) ar fi ajuns AMANDOUA
## in spatele primului punct al ocolului. Soferul ar fi intors dupa ele, si
## sonda ar fi masurat o manevra inventata de ea.
func _service_route() -> Array[Vector3]:
	var sw := _hazard.service_waypoints()
	var z_first := sw[0].z
	var z_last := sw[sw.size() - 1].z
	var route: Array[Vector3] = [
		Vector3(0.0, DECK_RISE, z_first + 26.0),
		Vector3(0.0, DECK_RISE, z_first + 10.0)]
	route.append_array(sw)
	route.append(Vector3(0.0, DECK_RISE, z_last - 10.0))
	route.append(Vector3(0.0, 0.0, FINISH_Z - 20.0))
	return route


## Cautarea formei: doar traversarea directa si ocolul, la o singura viteza.
## Nu inlocuieste sonda — nu spune nimic despre ceas, telegraph, poarta sau
## blocaje — dar da cifra care conteaza cand cauti geometria, in a zecea parte
## din timp.
func _run_quick() -> void:
	var cars: Array = []
	await _wait_state(SpanScript.State.OPEN)
	_hazard.clock_running = false
	var t_direct := await _drive("DESCHIS", _direct_route(), 26.0, cars, ENTRY_SPEED)
	_hazard.clock_running = true
	cars[0].queue_free()
	await get_tree().physics_frame
	await _wait_state(SpanScript.State.SHUT)
	_hazard.clock_running = false
	var t_service := await _drive("OCOL", _service_route(), 34.0, cars, ENTRY_SPEED)
	_hazard.clock_running = true
	cars[1].queue_free()
	await get_tree().physics_frame
	print("### QUICK offset=%.1f lead=%.1f ratio=%.2f R1=%.1f R2=%.1f : direct %.2f, ocol %.2f, pedeapsa %+.2f s"
		% [_hazard.service_offset, _hazard.service_lead,
		_hazard.service_entry_ratio, _hazard.entry_radius(), _hazard.service_radius(),
		t_direct, t_service, t_service - t_direct])


## (v) Cine ignora si semaforul, si barierele: nu cade, nu moare, nu ramane
## intepenit. `ref` e traversarea directa la aceeasi viteza de intrare.
func _run_barrier(ref: float) -> void:
	# ------------------------------------- (v) drept in poarta: nu e capcana
	print("--- (v) INCHIS, drept in poarta la %.0f m/s: nu cade, nu moare, nu ramane blocata"
		% GATE_SPEED)
	var ok_shut2 := await _wait_state(SpanScript.State.SHUT)
	_verdict(ok_shut2, "pasajul s-a inchis din nou")
	# Ceasul hazardului se OPRESTE cat tine testul asta. Intrebarea aici e
	# despre configuratia inchisa („se descurca cineva care a intrat in
	# bariere?"), nu despre ciclu — iar cu ceasul pornit intrebarea nu apuca sa
	# fie pusa: masina a stat 8 s in bariere, intre timp pasajul s-a redeschis,
	# si sonda masura o plimbare printr-un nod fara niciun obstacol. Perioada
	# si telegraph-ul si-au primit oricum verdictele lor la (0) si (i).
	# Doar CEASUL, nu tot nodul: `_physics_process` stins ar fi stins si
	# ghiontul portii, adica exact mecanismul care trebuie testat aici.
	_hazard.clock_running = false
	print("    ceasul hazardului oprit pe INCHIS (tronson la %.2f, poarta solida: %s, ghiont %.1f m/s)"
		% [_hazard.turn_fraction(), str(_hazard.gate_solid()), _hazard.gate_push])
	var car := _spawn(Vector3(0.0, 0.7, START_Z), GATE_SPEED)
	var driver := WaypointDriver.new()
	driver.waypoints = _hazard.direct_waypoints()
	driver.target_speed = 30.0
	car.set_controller(driver)
	var min_y := INF
	var max_crush := 0.0
	var hit_t := -1.0
	var passed := false
	var t_total := 0.0
	for _f in int(GATE_APPROACH_MAX * 60.0):
		await get_tree().physics_frame
		t_total += 1.0 / 60.0
		if _over_module(car):
			min_y = minf(min_y, car.global_position.y)
		max_crush = maxf(max_crush, car.crush_time)
		if hit_t < 0.0 and car.global_position.z < _hazard.gate_z() + 2.0 				and car.horizontal_speed() < 6.0:
			hit_t = t_total
		# Trecuta DINCOLO de gol pe banda directa, cu pasajul inchis: poarta
		# n-a oprit-o. Prima rulare a picat exact aici, prin tunelare printr-un
		# colizor de 0.5 m la 0.5 m pe cadru.
		if car.global_position.z < -_hazard.span_length * 0.5 - 1.0:
			passed = true
			break
		if _f % 15 == 0:
			print("      lansata t=%5.2f pos %s v=%5.1f | %s"
				% [t_total, str(car.global_position.round()),
				car.horizontal_speed(), _around(car)])
		if hit_t >= 0.0 and t_total - hit_t >= STUCK_WATCH:
			break
	print("    impact la %.2f s, apoi %.1f s de privit: pozitie %s, viteza %.2f, y min %.2f, strivire max %.2f, activa %s, sus %.2f"
		% [hit_t, STUCK_WATCH, str(car.global_position.round()),
		car.horizontal_speed(), min_y, max_crush, str(car.race_active),
		car.global_transform.basis.y.y])
	_verdict(min_y > DECK_RISE - FALL_MARGIN,
		"nu a cazut in gol (y min %.2f)" % min_y)
	_verdict(not passed, "poarta a oprit-o inainte de gol (trecuta: %s)" % str(passed))
	_verdict(max_crush <= 0.01, "nu e distrusa (crush %.2f s)" % max_crush)
	_verdict(car.race_active, "ramane in cursa")
	_verdict(car.global_transform.basis.y.y > 0.3,
		"nu a ramas rasturnata (up.y %.2f)" % car.global_transform.basis.y.y)
	# Iesirea din blocaj: acelasi sofer, pe ocol — dar numai pe punctele din
	# FATA masinii. Prima versiune ii dadea lista intreaga a ocolului, care
	# incepe cu 15 m in spatele locului unde poarta o oprise: soferul intorcea
	# ca sa atinga un punct depasit, si sonda masura o manevra inventata de ea,
	# nu iesirea din blocaj.
	var out: Array[Vector3] = []
	for p in _hazard.service_waypoints():
		if p.z < car.global_position.z - 2.0:
			out.append(p)
	out.append(Vector3(0.0, DECK_RISE, -28.0))
	out.append(Vector3(0.0, 0.0, FINISH_Z - 20.0))
	print("    reluare: %d puncte in fata, primul %s (masina la %s)"
		% [out.size(), str(out[0].round()), str(car.global_position.round())])
	driver.waypoints = out
	driver.index = 0
	# Din loc, cu ocolul la cativa metri in stanga: punctele apropiate sunt
	# chiar cele utile, deci raza de „atins" scade. Cu 7 m soferul le sarea pe
	# primele si tragea de volan spre unul de dincolo de gol.
	driver.reach = 4.0
	# ACELASI sofer ca la traversari. Reluarea a rulat o vreme cu soferul orb,
	# si aia masura alta intrebare: masina iesea din bariere, lua ocolul cu 18
	# m/s (peste ce ingaduie arcele lui), derapa la reintrare si ramanea de-a
	# curmezisul pasajului, cu 32 s pierdute. Daca ocolul e trecabil cu un sofer
	# care ridica piciorul, atunci si iesirea din bariere trebuie judecata cu
	# acelasi sofer — altfel sonda compara doua lumi.
	driver.corner_grip = CORNER_GRIP
	driver.target_speed = 18.0
	var escaped := false
	var t_out := 0.0
	var min_out := INF
	var t_freed := -1.0
	for f in int(32.0 * 60.0):
		await get_tree().physics_frame
		t_out += 1.0 / 60.0
		t_total += 1.0 / 60.0
		# „Desprinsa" = a rulat iar, nu doar s-a zbatut in bariere.
		if t_freed < 0.0 and car.horizontal_speed() > 8.0:
			t_freed = t_out
		if _over_module(car):
			min_out = minf(min_out, car.global_position.y)
		if f % 30 == 0:
			print("      t=%5.2f pos %s v=%5.1f dir %s | %s" % [t_out,
				str(car.global_position.round()), car.horizontal_speed(),
				str((-car.global_transform.basis.z).snapped(Vector3.ONE * 0.1)),
				_around(car)])
		if car.global_position.z <= FINISH_Z:
			escaped = true
			break
	print("    reluare pe ocol: %s in %.2f s, desprinsa la %.2f s, pozitie %s"
		% ["iesita" if escaped else "BLOCATA", t_out, t_freed,
		str(car.global_position.round())])
	_verdict(t_freed >= 0.0 and t_freed < 20.0,
		"se desprinde din bariere (a rulat iar dupa %.2f s)" % t_freed)
	_verdict(escaped, "masina nu ramane intepenita (a terminat ocolul in %.2f s)" % t_out)
	_verdict(min_out > DECK_RISE - FALL_MARGIN,
		"la reluare nu cade de pe pasaj (y min %.2f)" % min_out)
	# Costul REAL al atingerii barierelor, masurat de la pornire pana la
	# iesirea din nod — nu „cat a stat in ele", care depindea de cate secunde
	# se uita sonda.
	# Referinta e traversarea directa la ACEEASI viteza de intrare, nu cea de
	# la 24: altfel cifra ar amesteca pretul barierelor cu diferenta dintre
	# doua viteze de intrare.
	var barrier_cost: float = t_total - float(ref)
	# ATENTIE la ce e cifra asta, fiindca a fost citita gresit o data: e pretul
	# platit de cine INTRA IN BARIERE, nu pedeapsa ocolului din brief. Cele doua
	# se masoara pe drumuri diferite si au plafoane diferite (PENALTY_MIN/MAX =
	# 2.5-4.0 s pentru ocol, BARRIER_COST_MAX = 10 s pentru bariere), fiindca
	# sunt doua contracte diferite: „ocolul costa ~3 s" si „cine ignora
	# semaforul plateste o pedeapsa de cursa, nu un abandon".
	#
	# Pedeapsa ocolului pe geometria REALA a Track12 (offset 24, lead 30,
	# width 6) e +3.27 s, masurata cu `--quick` — adica exact contractul din
	# brief §3. Sonda asta ruleaza pe o sosea-test cu modulul RIDICAT
	# (`deck_rise` = 3 m) si cu latimea ei implicita, deci cifra ei nu e
	# pedeapsa de pe pista si nu are voie sa fie comparata cu cei „+3 s".
	print("--- cost total cu barierele (NU pedeapsa ocolului): %.2f - %.2f = %+.2f s (plafon %+.2f)"
		% [t_total, ref, barrier_cost, BARRIER_COST_MAX])
	print("    (pedeapsa ocolului pe geometria Track12: +3.27 s, vezi --quick)")
	_verdict(escaped and barrier_cost <= BARRIER_COST_MAX,
		"barierele costa %+.2f s, nu cursa" % barrier_cost)
	_hazard.clock_running = true
	car.queue_free()
	await get_tree().physics_frame


func _run() -> void:
	if OS.get_cmdline_user_args().has("--quick-gate"):
		await _wait_state(SpanScript.State.OPEN)
		_hazard.clock_running = false
		var cars: Array = []
		var ref := await _drive("DESCHIS", _direct_route(), 26.0, cars, GATE_SPEED)
		_hazard.clock_running = true
		cars[0].queue_free()
		await get_tree().physics_frame
		await _run_barrier(ref)
		return
	if OS.get_cmdline_user_args().has("--quick"):
		await _run_quick()
		return
	await _measure_cycle()

	# ---------------------------------------------- (ii) traversarea directa
	print("--- (ii) DESCHIS: traversare pe tronson, la %s m/s" % str(ENTRY_SPEEDS))
	var ok_open := await _wait_state(SpanScript.State.OPEN)
	_verdict(ok_open, "pasajul s-a deschis")
	# Ceasul se opreste cat tin cele trei traversari, si nu e o indulgire:
	# starea DESCHIS tine `hold_time()` = 8.5 s, iar o traversare dureaza 5-9 s.
	# Cu ceasul pornit, a doua si a treia ar fi masurat un pasaj care se inchide
	# sub masina — adica alt test decat cel scris aici, si o cifra de referinta
	# facuta din altceva pentru fiecare viteza. Ciclul si telegraph-ul si-au
	# primit verdictele lor la (0) si (i), pe ceasul pornit.
	_hazard.clock_running = false
	var t_direct: Dictionary = {}
	var frac_open: Dictionary = {}
	for v: float in ENTRY_SPEEDS:
		var cars: Array = []
		var t := await _drive("DESCHIS %2.0f" % v, _direct_route(), 22.0, cars, v)
		t_direct[v] = t
		var car_open: Car = cars[0]
		_verdict(t < INF, "DESCHIS %.0f m/s: traversare terminata (%.2f s)" % [v, t])
		await get_tree().physics_frame
		_verdict(_track.is_on_road(car_open.road_index, car_open.global_position, 0),
			"DESCHIS %.0f m/s: iese pe sosea (index %d, frac %.3f)"
			% [v, car_open.road_index, _track.frac_at(car_open.road_index)])
		frac_open[v] = _track.frac_at(car_open.road_index)
		car_open.queue_free()
		await get_tree().physics_frame
	_hazard.clock_running = true

	# ------------------------------------------------- (iii) ocolul, inchis
	print("--- (iii) INCHIS: traversare pe rampa de serviciu, la %s m/s"
		% str(ENTRY_SPEEDS))
	var ok_shut := await _wait_state(SpanScript.State.SHUT)
	_verdict(ok_shut, "pasajul s-a inchis")
	_verdict(_hazard.gate_solid(), "poarta de bariere e solida cat e inchis")
	# Acelasi inghet, si aici e chiar mai necesar: starea INCHIS tine tot 8.5 s,
	# iar ocolul dureaza mai mult decat ea. Cu ceasul pornit, masina ar fi prins
	# redeschiderea la jumatatea rampei de serviciu — si sonda ar fi masurat un
	# ocol facut degeaba, nu pretul lui.
	_hazard.clock_running = false
	var t_service: Dictionary = {}
	for v: float in ENTRY_SPEEDS:
		var cars: Array = []
		var t := await _drive("OCOL    %2.0f" % v, _service_route(), 30.0, cars, v)
		t_service[v] = t
		var car_shut: Car = cars[0]
		_verdict(t < INF, "OCOL %.0f m/s: ocolul terminat, fara blocaj (%.2f s)"
			% [v, t])
		await get_tree().physics_frame
		_verdict(_track.is_on_road(car_shut.road_index, car_shut.global_position, 0),
			"OCOL %.0f m/s: iese pe sosea (index %d, frac %.3f)"
			% [v, car_shut.road_index, _track.frac_at(car_shut.road_index)])
		print("    fractia de tur la iesire: direct %.3f, ocol %.3f"
			% [frac_open[v], _track.frac_at(car_shut.road_index)])
		car_shut.queue_free()
		await get_tree().physics_frame
	_hazard.clock_running = true

	# --------------------------------------------- (iv) contractul de pedeapsa
	print("--- (iv) contractul de pedeapsa (brief §3: +3 s, fereastra %.1f..%.1f)"
		% [PENALTY_MIN, PENALTY_MAX])
	# Verdict pe FIECARE viteza, nu doar pe cea de referinta. Brieful nu spune
	# „+3 s daca intri cu 24", spune „+3 s" — iar o fereastra care atinge curba
	# intr-un singur punct lasa sa treaca o geometrie care costa +5.5 s la
	# intrare inceata si +3.3 la cea de referinta. Aceeasi lectie ca la
	# fereastra pusa in jurul masuratorii, cu o treapta mai sus.
	for v: float in ENTRY_SPEEDS:
		var pen: float = t_service[v] - t_direct[v]
		_verdict(pen >= PENALTY_MIN and pen <= PENALTY_MAX,
			"ocolul costa %+.2f s la %.0f m/s (contract +3 s, fereastra %.1f..%.1f)"
			% [pen, v, PENALTY_MIN, PENALTY_MAX])

	await _run_barrier(t_direct[GATE_SPEED])

	# ------------------------------- (vi) poarta nu se inchide peste o masina
	print("--- (vi) poarta cu senzor: nu se inchide peste o masina")
	var ok_open2 := await _wait_state(SpanScript.State.OPEN)
	_verdict(ok_open2, "pasajul s-a deschis pentru testul portii")
	# Masina, oprita, fix in dreptul portii; asteptam comutarea.
	var gate_z := _hazard.gate_z()
	var parked := _spawn(Vector3(0.0, DECK_RISE + 0.7, gate_z), 0.0)
	var park_driver := WaypointDriver.new()
	park_driver.waypoints = []
	park_driver.throttle_when_done = 0.0
	parked.set_controller(park_driver)
	var hold_max := 0.0
	var solid_while_inside := false
	var crush_max := 0.0
	for _f in int((_hazard.hold_time() + _hazard.turn_time + 2.0) * 60.0):
		await get_tree().physics_frame
		hold_max = maxf(hold_max, _hazard.gate_hold())
		crush_max = maxf(crush_max, parked.crush_time)
		var inside := absf(parked.global_position.z - gate_z) < 2.5
		if inside and _hazard.gate_solid():
			solid_while_inside = true
	print("    masina la z=%.1f (poarta la %.1f): asteptare max %.2f s (plafon %.2f), strivire %.2f, solid peste ea: %s"
		% [parked.global_position.z, gate_z, hold_max, _hazard.gate_hold_max,
		crush_max, str(solid_while_inside)])
	_verdict(hold_max > 0.0, "poarta a asteptat masina (%.2f s)" % hold_max)
	_verdict(crush_max <= 0.01, "masina din poarta nu e strivita")
	parked.queue_free()
	await get_tree().physics_frame
