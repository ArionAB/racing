extends Node
## Garda mini-typhoon-ului: incadrarea in ecran, asezarea pe pista si dovada ca
## masina prinsa chiar ATERIZEAZA PE SOSEA.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeTyphoon.tscn -- --track=4
##   ... -- --track=4 --scan          cauta fractii bune, nu verifica nimic
##
## ATENTIE la numarul pistei: e INDEXUL din `GameState.TRACK_SCENES`, nu numarul
## din numele fisierului. 3 = Track07 (Okinawa v2), 4 = Track08 (Okinawa manual).
## `tools/probe_decor.gd` numara invers — acolo `--track=8` chiar inseamna
## Track08 — fiindca isi construieste singur calea din numar. Sonda asta
## foloseste GameState fiindca are nevoie si de `CAR_DATA` pentru proba de zbor.
##
## Ruleaza CA SCENA, nu cu --script: masina si pista au nevoie de autoload-uri.
##
## ############################################################################
## CE VERIFICA, si de ce fiecare cifra e o consecinta si nu o setare
##
## 1. CADRUL. Inaltimea palniei nu se alege, se deriva din camera. Sonda
##    reconstruieste tabelul din constantele lui `ChaseCamera` (nu din literale
##    copiate aici — daca cineva tuneaza camera, tabelul se schimba singur) si
##    spune de la ce distanta incape tromba intreaga in ecran. Fara asta,
##    „inaltimea potrivita" ar fi o parere.
##
## 2. ASEZAREA. Unde ajunge tromba la capetele maturarii si ce e acolo (apa sau
##    uscat), cat de dreapta e soseaua in punctul ala, si cat de departe e de
##    celelalte hazarde. Un hazard cu ceas asezat langa altul nu produce doua
##    decizii, produce o loterie.
##
## 3. ARUNCAREA — singura care chiar conduce. Masina intra in tromba la viteza
##    ceruta si sonda urmareste tot zborul: cat de sus a ajuns, cat a stat in
##    aer, cati metri a facut si — cifra care conteaza — cat de departe de axa
##    soselei a atins pamantul. Restul se pot citi si dintr-un desen; asta nu.
##
## De ce ATERIZAREA e proba si nu inaltimea: cerinta a fost „ridica si arunca
## masina, insa tot pe sosea". Prima jumatate e usoara si se vede cu ochiul.
## A doua e o afirmatie despre 2 secunde de zbor peste un drum care se
## curbeaza, si singurul mod de a sti daca e adevarata e sa zbori.
## ############################################################################

const CAR_SCENE: String = "res://scenes/cars/Car.tscn"

## Cati metri inainte de tromba porneste masina in proba de zbor.
const RUN_UP: float = 90.0
## Cat urmarim, dupa ce a pornit.
const WATCH_SECONDS: float = 14.0
## Cate treceri se incearca, si la ce distanta de axa soselei sta TROMBA in
## fiecare. Masina merge de fiecare data pe mijloc.
##
## Decalajul e al trombei, nu al masinii, si asta a fost o corectie. Prima
## versiune il cerea AI-ului prin `line_offset` — dar AI-ul isi limiteaza singur
## linia la ce incape pe asfalt, deci 3.5 si 6.2 au dat amandoua aceeasi trecere,
## la 5.3 m de axa. Doua treceri identice tiparite ca doua rezultate diferite e
## mai rau decat o singura trecere: arata ca o acoperire pe care n-o ai.
##
## Ultima valoare e dincolo de CATCH_RADIUS: acolo NU trebuie sa se intample
## nimic, si o sonda care nu verifica si negativul nu stie decat ca ceva se
## declanseaza, nu ca se declanseaza cand trebuie.
const OFFSETS: Array[float] = [0.0, 4.0, 6.5, 8.5]

## Sub raza asta soseaua e prea stramta pentru un hazard care cere anticipare.
##
## 400 m, masurat cu RADIUS_SPAN_M — adica in aceeasi unitate cu cifrele din
## track07.gd (rampa la 1900 m, creasta la 6400 m). Nu e „drept", e „destul de
## drept cat s-o vezi venind": la 400 m de raza, pe cei 68 m ai intervalului de
## decizie soseaua se abate lateral cu ~1.4 m.
const SCAN_MIN_RADIUS: float = 400.0
## Cat de departe trebuie sa stea de orice alt hazard cu ceas, in fractii de tur.
const SCAN_MIN_GAP: float = 0.055

var _track_index: int = 4 # Track08 — Okinawa manual
var _scan: bool = false
var _track: Track
var _typhoons: Array = []

# --- proba de zbor ---
var _car: Car
var _typhoon: TyphoonHazard
var _pass: int = -1
var _time: float = 0.0
var _airborne: bool = false
var _apex: float = 0.0
var _lift_from: float = 0.0
var _air_time: float = 0.0
var _launch_at: Vector3 = Vector3.ZERO
## Cat de aproape de axa trombei a trecut masina in trecerea curenta.
var _closest: float = 1e9
## Cel mai adanc a ajuns talpa palniei sub terenul de sub ea, pe toata proba.
var _foot_gap: float = 1e9
var _rows: Array[Dictionary] = []
var _fail: int = 0


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			_track_index = int(arg.trim_prefix("--track="))
		elif arg == "--scan":
			_scan = true
	_track = (load(GameState.TRACK_SCENES[_track_index]) as PackedScene) \
		.instantiate() as Track
	add_child(_track)
	for child in _track.get_children():
		if child is TyphoonHazard:
			_typhoons.append(child)

	_report_frame()
	if _scan:
		_report_scan()
		get_tree().quit(0)
		return
	if _typhoons.is_empty():
		print("\nprobe_typhoon: pista %s n-are nicio tromba (--scan cauta unde ar incapea)"
			% _track.track_name)
		get_tree().quit(1)
		return
	_report_placement()
	_report_throw_math()
	_setup_flight()


# ############################################################################
# 1. CADRUL
# ############################################################################

## De la ce distanta incape in ecran un obiect de inaltimea data.
##
## Geometria: camera sta la `distance` in spate si `height` deasupra masinii si
## priveste in jos cu unghiul `atan(_pitch_tan)`. Raza de SUS a frustumului urca
## deci doar `fov/2 - pitch` peste orizontala — la o camera inclinata in jos,
## foarte putin. La `D` metri de camera intra in cadru tot ce e sub
## `height + D * tan(fov/2 - pitch)`.
##
## Constantele se citesc din ChaseCamera, NU se copiaza aici. Daca cineva
## tuneaza camera, tabelul asta se muta odata cu ea si tromba pica singura —
## adica exact ce vrem de la o garda.
func _frame_ceiling(ahead: float, fov: float) -> float:
	var d := ChaseCamera.DEFAULT_DISTANCE
	var h := ChaseCamera.DEFAULT_HEIGHT
	var pitch := atan((h - ChaseCamera.LOOK_HEIGHT) / (d + ChaseCamera.LOOK_AHEAD))
	return h + (ahead + d) * tan(deg_to_rad(fov * 0.5) - pitch)


## Cat de departe in fata trebuie sa fie un obiect de `tall` metri ca sa incapa.
func _frame_distance(tall: float, fov: float) -> float:
	var d := ChaseCamera.DEFAULT_DISTANCE
	var h := ChaseCamera.DEFAULT_HEIGHT
	var pitch := atan((h - ChaseCamera.LOOK_HEIGHT) / (d + ChaseCamera.LOOK_AHEAD))
	var slope := tan(deg_to_rad(fov * 0.5) - pitch)
	if slope <= 0.0:
		return INF # camera nu vede deloc peste orizontala: nimic nu incape
	return (tall - h) / slope - d


func _report_frame() -> void:
	var base := ChaseCamera.BASE_FOV
	var top := base + ChaseCamera.FOV_SPEED_KICK
	var mid := (base + top) * 0.5
	var d := ChaseCamera.DEFAULT_DISTANCE
	var pitch := rad_to_deg(atan(
		(ChaseCamera.DEFAULT_HEIGHT - ChaseCamera.LOOK_HEIGHT)
		/ (d + ChaseCamera.LOOK_AHEAD)))
	print("=== 1. CADRU (din constantele lui ChaseCamera) ===")
	print("  camera: %.1f m in spate, %.1f m sus, panta %.2f° in jos"
		% [d, ChaseCamera.DEFAULT_HEIGHT, pitch])
	print("  raza de sus a frustumului, peste orizontala:")
	for fov: float in [base, mid, top]:
		print("    FOV %4.1f° -> %+5.2f°" % [fov, fov * 0.5 - pitch])
	print("  inaltimea maxima care incape intreaga in ecran:")
	print("    %-10s %10s %10s %10s" % ["m in fata", "repaus", "50% vit", "max"])
	for ahead: float in [20.0, 40.0, 60.0, 80.0, 100.0, 150.0]:
		print("    %-10.0f %10.1f %10.1f %10.1f" % [ahead,
			_frame_ceiling(ahead, base), _frame_ceiling(ahead, mid),
			_frame_ceiling(ahead, top)])
	var tall := TyphoonHazard.FUNNEL_HEIGHT
	var near_max := _frame_distance(tall, top)
	var near_rest := _frame_distance(tall, base)
	print("  palnia are %.1f m -> incape intreaga de la %.0f m in fata la viteza"
		% [tall, near_max])
	print("     de varf, si de la %.0f m in cea mai stramta stare a camerei."
		% near_rest)
	# Pragul se citeste INVERS decat pare la prima vedere, si prima versiune a
	# sondei l-a citit gresit.
	#
	# `near_max` NU e „de cat timp mai dispui", e distanta sub care tromba INCEPE
	# sa iasa din cadru. Peste ea, o vezi intreaga oricat de departe ar fi (la 100
	# m plafonul e 28 m, la 150 m e 36 — creste mereu). Deci cifra buna e una MICA:
	# cu cat e mai mica, cu atat te apropii mai mult inainte sa-i piarda varful.
	#
	# Cerinta reala e ca la momentul DECIZIEI — cam doua secunde inainte de
	# contact, cat iti ia sa alegi intre a forta si a ridica piciorul — tromba sa
	# fie inca intreaga in ecran. Adica `near_max` sub distanta parcursa in doua
	# secunde.
	var speed := 34.0
	var decision := speed * 2.0
	if near_max > decision:
		print("  PROBLEMA: incepe sa iasa din cadru de la %.0f m, adica INAINTE de"
			% near_max)
		print("  momentul deciziei (%.0f m = 2 s la %.0f m/s). E prea inalta."
			% [decision, speed])
		_fail += 1
	else:
		print("  OK: intreaga in cadru pana la %.0f m, adica pe tot intervalul de"
			% near_max)
		print("  decizie (%.0f m); varful incepe sa iasa abia in ultima %.1f s."
			% [decision, near_max / speed])


# ############################################################################
# 2. ASEZAREA
# ############################################################################

## Cota terenului sub un punct, prin raza — aceeasi masca folosita de tromba.
func _ground_at(at: Vector3) -> float:
	# Lumea se cere PISTEI: sonda e un `Node` simplu, nu un `Node3D`, deci n-are
	# `get_world_3d()`. (Prima versiune il chema pe self si scriptul nu compila —
	# iar o scena cu script picat ruleaza mai departe cu bucla goala, adica pare
	# ca se blocheaza in loc sa crape.)
	var space := _track.get_world_3d().direct_space_state
	var from := at + Vector3.UP * 90.0
	var q := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 200.0)
	q.collision_mask = Track.CAMERA_BLOCKER_LAYER
	var hit := space.intersect_ray(q)
	return INF if hit.is_empty() else float((hit.position as Vector3).y)


## Raza cercului prin trei puncte — copiata ca formula, nu ca cod, din
## probe_layout: acolo e metoda privata a altei sonde.
func _circumradius(a: Vector3, b: Vector3, c: Vector3) -> float:
	var ab := a.distance_to(b)
	var bc := b.distance_to(c)
	var ca := c.distance_to(a)
	var area := 0.5 * absf((b.x - a.x) * (c.z - a.z) - (c.x - a.x) * (b.z - a.z))
	if area < 1e-4:
		return INF
	return ab * bc * ca / (4.0 * area)


## Raza minima a soselei intr-o fereastra in jurul unui punct copt.
##
## Cele trei puncte stau la ~12 m unul de altul, ca in probe_layout, iar minimul
## se ia pe o fereastra de +/-`window_m`. Distanta dintre puncte e ce se masoara
## de fapt, si nu e o alegere libera: prima versiune ii dadea 40 m si intorcea
## raze de 50-170 m pe TOATA pista, inclusiv pe bucatile pe care track07.gd le
## descrie ca fiind drepte (1900 m la rampa, 6400 m la creasta). Nu era o
## contrazicere — la 40 m intre puncte netezesti curbura locala si masori bucla
## insulei (1800 m de tur inseamna ~286 m raza daca ar fi cerc), nu drumul.
## Cifra cu care se compara trebuie sa fie masurata la fel ca cifrele existente.
const RADIUS_SPAN_M: float = 12.0


func _radius_near(idx: int, window_m: float) -> float:
	var n := _track.baked.size()
	var interval := maxf(_track.curve.bake_interval, 0.5)
	var span := maxi(int(RADIUS_SPAN_M / interval), 1)
	var reach := maxi(int(window_m / interval), 1)
	var worst := INF
	for k in range(-reach, reach + 1):
		var a := _track.baked[posmod(idx + k - span, n)]
		var b := _track.baked[posmod(idx + k, n)]
		var c := _track.baked[posmod(idx + k + span, n)]
		worst = minf(worst, _circumradius(a, b, c))
	return worst


## Cota marii pe pista curenta.
##
## Se cere prin `get`/`call` fiindca samplerul si media cotelor sunt interne
## pistei si n-au de ce sa devina API public pentru o sonda. Alternativa —
## construi o tromba doar ca sa citesc `water_y` de pe ea — n-ar merge in modul
## --scan, care se pune tocmai cand inca nu exista niciuna.
func _sea_level() -> float:
	var sampler: Object = _track.get("_sampler")
	if sampler == null or not sampler.has_method("mean_road_y"):
		return -1e9
	return float(sampler.call("mean_road_y")) + _track.sea_level_offset


func _report_placement() -> void:
	print("\n=== 2. ASEZARE pe %s ===" % _track.track_name)
	var n := _track.baked.size()
	for t: TyphoonHazard in _typhoons:
		# Ancora, nu `position`: tromba se plimba, deci pozitia ei e o functie de
		# ceas. Ancora e punctul in jurul caruia matura si singurul care descrie
		# ASEZAREA.
		var here: Vector3 = t.get("_anchor")
		var idx := _track.closest_index_global(here)
		var frac := float(idx) / float(n)
		var side := t.travel_dir
		var radius := _radius_near(idx, 40.0)
		print("  frac %.3f  raza %s  latime %.1f m  maturare +/-%.1f m"
			% [frac, ("%.0f m" % radius) if radius < 1e5 else "dreapta",
				t.road_half_width * 2.0, t.sweep])
		for s: float in [-1.0, 1.0]:
			var at := here + side * (t.sweep * s)
			var g := _ground_at(at)
			var what := "APA" if g <= t.water_y + 0.35 else "uscat"
			print("      capat %+.0f m: %s (teren %.1f, apa la %.1f)"
				% [t.sweep * s, what, g, t.water_y])
		# Unde e malul in fiecare parte: de aici se alege daca maturarea merita
		# largita ca sa ajunga pe apa (si sa porneasca stropii).
		for s: float in [-1.0, 1.0]:
			var shore := _shore_distance(here, side * s, t.water_y)
			print("      malul la %+.0f: %s"
				% [s, ("%.0f m de axa" % shore) if shore > 0.0
					else "peste 60 m (nu se vede apa)"])
		_check_visible(t, idx)


# ############################################################################
# 3. ARUNCAREA — cifrele, si apoi zborul
# ############################################################################

## La cati metri de axa soselei intra terenul sub linia apei. 0 daca nicaieri.
func _shore_distance(from: Vector3, dir: Vector3, water: float) -> float:
	for m in range(6, 62, 2):
		if _ground_at(from + dir * float(m)) <= water + 0.35:
			return float(m)
	return 0.0


## Se vede tromba din masina, la momentul deciziei?
##
## ############################################################################
## ASTA A INLOCUIT UN PRAG DE RAZA DE VIRAJ, si merita spus de ce.
##
## Prima versiune cerea soselei o raza minima in punctul de asezare, pe ideea ca
## pe un viraj strans n-ai cum sa vezi obstacolul venind. Regula e buna — si
## chiar exista in `probe_layout` — dar e regula pentru obstacole JOASE: o
## bariera de un metru chiar dispare dupa un deal sau dupa curbura drumului.
##
## Tromba are 18 m si 12 m latime. Ea nu se ascunde dupa un viraj de 155 m raza,
## se vede PESTE el. Pragul de raza respingea deci o asezare buna pentru un motiv
## care nu i se aplica — si, mai rau, era de nesatisfacut: pe Okinawa nicio
## fereastra libera n-are raza peste ~220 m, deci pragul ar fi respins orice
## asezare posibila, la infinit, fara sa spuna ca problema e in el.
##
## Testul corect e cel direct: cu masina pe sosea, la distanta de decizie,
## palnia cade in campul vizual al camerei? FOV-ul ORIZONTAL e cel care conteaza
## aici (~100° la 16:9 cu 68° vertical), si e foarte larg — de-aia un viraj de
## 155 m nici nu-l zgarie.
## ############################################################################
func _check_visible(t: TyphoonHazard, idx: int) -> void:
	var n := _track.baked.size()
	var decision := 68.0 # 2 s la 34 m/s
	var back := posmod(idx - int(decision / maxf(_track.curve.bake_interval, 0.5)), n)
	var eye := _track.baked[back]
	var fwd := (_track.baked[posmod(back + 1, n)] - eye).normalized()
	# FOV orizontal din cel vertical, la 16:9 — Godot pastreaza INALTIMEA
	# (`keep_aspect` implicit), deci `fov` e cel vertical si latimea iese din raport.
	var v_half := deg_to_rad(ChaseCamera.BASE_FOV * 0.5)
	var h_half := atan(tan(v_half) * 16.0 / 9.0)
	var to_it := t.get("_anchor") as Vector3 - eye
	to_it.y = 0.0
	var angle := absf(fwd.signed_angle_to(to_it.normalized(), Vector3.UP))
	# Cel mai rau caz nu e centrul palniei, ci capatul maturarii dinspre exterior:
	# acolo ajunge cand traverseaza, si tot atunci trebuie s-o vezi.
	var worst := angle + atan(t.sweep / maxf(to_it.length(), 1.0))
	print("      vizibila la %.0f m: axa la %.0f° fata de directia de mers,"
		% [decision, rad_to_deg(angle)])
	print("      capatul maturarii la %.0f°, marginea cadrului la %.0f°"
		% [rad_to_deg(worst), rad_to_deg(h_half)])
	if worst > h_half:
		print("      PROBLEMA: la momentul deciziei tromba e in afara cadrului.")
		_fail += 1


func _report_throw_math() -> void:
	print("\n=== 3. ARUNCARE (cifre derivate) ===")
	var g := 28.0 # Car.gravity, implicit
	print("  %-8s %8s %8s %10s" % ["ridica", "v sus", "in aer", "la 34 m/s"])
	for lift: float in [TyphoonHazard.LIFT_MIN, TyphoonHazard.LIFT_MAX]:
		var v := sqrt(2.0 * g * lift)
		var air := 2.0 * v / g
		print("  %6.1f m %6.1f m/s %6.2f s %8.0f m"
			% [lift, v, air, air * 34.0 * TyphoonHazard.SPEED_KEEP])
	print("  (ultima coloana e drumul facut in aer cu viteza pastrata —")
	print("   distanta pe care curentul de aterizare trebuie s-o tina pe asfalt)")


func _setup_flight() -> void:
	_typhoon = _typhoons[0]
	print("\n=== 4. ZBOR: masina prin tromba ===")
	print("  intrare 34 m/s, %d treceri; masina pe mijloc, TROMBA decalata"
		% OFFSETS.size())
	print("  %-8s %7s %7s %7s %9s %s"
		% ["decalaj", "apex", "in aer", "metri", "|lateral|", "verdict"])
	_next_pass()


## Ceasul la care tromba sta la `d` metri de axa soselei.
func _clock_for(d: float) -> float:
	var x := asin(clampf(d / maxf(_typhoon.sweep, 0.01), -1.0, 1.0))
	return (x / TAU - _typhoon.phase) * TyphoonHazard.PERIOD


func _next_pass() -> void:
	_pass += 1
	if _pass >= OFFSETS.size():
		_finish()
		return
	if _car != null:
		_car.queue_free()
	var lateral: float = OFFSETS[_pass]
	# Punctul de start: RUN_UP metri inaintea trombei. Se pleaca de la ANCORA, nu
	# de la pozitia curenta — aia se plimba.
	var idx := _track.closest_index_global(_typhoon.get("_anchor"))
	var n := _track.baked.size()
	var back := posmod(idx - int(RUN_UP / maxf(_track.curve.bake_interval, 0.5)), n)
	var dir := (_track.baked[posmod(back + 1, n)] - _track.baked[back]).normalized()
	var start := _track.baked[back] + Vector3.UP * 0.6

	_car = (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(_car)
	_car.apply_data(GameState.CAR_DATA[0])
	_car.track = _track
	_car.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP), start)
	_car.velocity = dir * 34.0
	_car.road_index = _track.closest_index_global(start)
	_car.last_safe_index = _car.road_index
	_car.race_active = true
	# Creier de AI, nu volan blocat — si nu din pedanterie: fara controller masina
	# nu accelereaza deloc, incetineste de la primul metru si prima rulare a
	# sondei a raportat de trei ori „NEPRINSA" pentru ca masina nici nu ajungea la
	# tromba. Decalajul lateral se cere AI-ului prin `line_offset`, in loc sa fie
	# o pozitie de start: asa masina chiar TINE linia aia pana la contact, in loc
	# s-o corecteze in primii 20 m.
	var ai := AIController.new()
	_car.set_controller(ai)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260806
	ai.configure(_track, rng)
	ai.line_offset = 0.0 # masina pe mijloc; decalajul e al trombei

	_closest = 1e9
	_time = 0.0
	_airborne = false
	_apex = 0.0
	_air_time = 0.0


func _physics_process(delta: float) -> void:
	if _scan or _car == null:
		return
	_time += delta
	# CEASUL TROMBEI, INGHETAT PE AXA SOSELEI cat tine proba de zbor.
	#
	# Prima versiune calcula o faza de start ca tromba sa ajunga pe axa fix cand
	# ajunge masina, si esua din prea multe motive deodata: acceleratia AI-ului
	# nu e uniforma, drumul nu e o dreapta, iar tromba se misca si ea. Nu-mi
	# trebuie insa un test de sincronizare — perioada si defazajul sunt aritmetica
	# simpla si nu se pot strica in tacere. Ce se poate strica, si de-aia exista
	# sonda, e ce se intampla DUPA contact. Deci contactul se garanteaza.
	#
	# `_offset()` e `sweep * sin(TAU * (t/PERIOD + phase))`, deci ceasul care da
	# un decalaj `d` iese prin inversare: `t = (asin(d/sweep)/TAU - phase) * PERIOD`.
	_typhoon.set("_time", _clock_for(OFFSETS[_pass]))
	_closest = minf(_closest, Vector2(
		_car.global_position.x - _typhoon.global_position.x,
		_car.global_position.z - _typhoon.global_position.z).length())
	# Talpa palniei fata de terenul de sub ea, in fiecare cadru.
	#
	# Verificarea asta a fost adaugata dupa ce tromba n-a aparut pe pista: cauza
	# principala era ca depozitul nu fusese tras, dar dedesubt statea un defect
	# real — o raza ratata muta talpa pe cota MARII in loc s-o lase pe loc, adica
	# ingropa 18 m de palnie cu cinci metri sub asfalt. Un raport de asezare din
	# `_ready` nu l-ar fi prins niciodata: acolo pozitia e inca ancora, iar
	# defectul apare abia la primul cadru de fizica.
	var ground := _ground_at(_typhoon.global_position)
	if ground < 1e5:
		_foot_gap = minf(_foot_gap, _typhoon.global_position.y - ground)
	var y := _car.global_position.y
	if not _airborne and not _car.is_on_floor() and _car.velocity.y > 4.0:
		_airborne = true
		_lift_from = y
		_launch_at = _car.global_position
		_apex = y
		_air_time = 0.0
	elif _airborne:
		_air_time += delta
		_apex = maxf(_apex, y)
		if _car.is_on_floor() and _air_time > 0.2:
			_land()
			return
	if _time > WATCH_SECONDS:
		if _airborne:
			_land()
		else:
			# Dincolo de raza de prindere, „neprinsa" e raspunsul CORECT — asta e
			# tot rostul ultimei treceri. Inauntru, e un defect. Cea mai apropiata
			# trecere pe langa axa distinge intre cele doua fara sa mai ghicesc.
			var expected := _closest > TyphoonHazard.CATCH_RADIUS
			print("  %+6.1f m       —       —       —        — NEPRINSA%s (a trecut la %.1f m de axa)"
				% [OFFSETS[_pass], "" if expected else " — DEFECT", _closest])
			if not expected:
				print("           era in raza de prindere (%.1f m): zona nu detecteaza."
					% TyphoonHazard.CATCH_RADIUS)
				_fail += 1
			_next_pass()


func _land() -> void:
	var pos := _car.global_position
	var idx := _track.closest_index_global(pos, _car.route)
	var lateral := _track.lateral_distance(idx, pos, _car.route)
	# Pragul e jumatatea de latime, nu o cifra rotunda: „pe sosea" inseamna pe
	# asfalt, iar asfaltul are exact latimea pe care o are pista acolo.
	var on_road := lateral <= _track.half_width
	var verdict := "PE SOSEA" if on_road else "IN AFARA"
	if not on_road:
		_fail += 1
	_rows.append({"ok": on_road})
	print("  %+6.1f m %6.1f m %6.2f s %6.0f m %8.1f m %s (a trecut la %.1f m de axa)" % [
		OFFSETS[_pass], _apex - _lift_from, _air_time,
		Vector2(pos.x - _launch_at.x, pos.z - _launch_at.z).length(),
		lateral, verdict, _closest])
	_next_pass()


func _finish() -> void:
	# Un prag, nu zero: terenul are triunghiuri mari, deci raza si talpa nu cad
	# exact pe acelasi punct pe o panta. O jumatate de metru e sub orice se vede;
	# defectul pe care il cauta era de peste cinci.
	print("\n  talpa palniei fata de teren: cel mai adanc %.2f m %s"
		% [_foot_gap, "OK" if _foot_gap > -0.5 else "— PROBLEMA, e ingropata"])
	if _foot_gap <= -0.5:
		_fail += 1
	print("\n%s (%d treceri, %d probleme)"
		% ["TOTUL E BINE" if _fail == 0 else "SUNT PROBLEME",
			_rows.size(), _fail])
	get_tree().quit(1 if _fail > 0 else 0)


# ############################################################################
# --scan: unde ar incapea o tromba
# ############################################################################

## Fractiile deja ocupate de altceva cu ceas sau cu geometrie proprie.
##
## Se cer PISTEI, nu se scriu aici: o lista copiata ar fi ramas in urma la prima
## mutare de rampa, si sonda ar fi recomandat linistita o fractie ocupata.
func _busy_fracs() -> Array[float]:
	var out: Array[float] = []
	for key in ["_hazard_fracs", "_ramp_fracs", "_flyoff_fracs", "_hose_fracs",
			"_wave_fracs", "_rockfall_fracs", "_train_fracs", "_carousel_fracs",
			"_deflector_fracs"]:
		if _track.has_method(key):
			for f: float in _track.call(key):
				out.append(f)
	if _track.has_method("_channel_specs"):
		for ch: Dictionary in _track.call("_channel_specs"):
			out.append(float(ch.get("frac", 0.0)))
	# RAPILE NU SUNT AICI, desi prima versiune le trecea. Doua motive:
	#   - o rapa nu e un hazard cu ceas, e teren. Nu concureaza cu tromba pentru
	#     atentia jucatorului, deci n-are de ce sa tina distanta fata de ea;
	#   - ce chiar deranjeaza — talpa palniei care dispare intr-o groapa la capat
	#     de maturare — se masoara oricum mai jos, cu raze, si se masoara ACOLO
	#     UNDE ajunge tromba, nu pe fractia pe care sta.
	# Trecute si aici, cele trei rapi ale Okinawei plus marja de 0.055 acopereau
	# jumatate de tur si scanarea nu intorcea nicio fractie — o interdictie
	# derivata din contorizarea de doua ori a aceleiasi constrangeri.
	return out


func _gap_to_busy(frac: float, busy: Array[float]) -> float:
	var best := 1.0
	for b in busy:
		var d := absf(frac - b)
		best = minf(best, minf(d, 1.0 - d))
	return best


## Cauta fractii si le CLASEAZA, in loc sa le filtreze.
##
## Prima versiune era un sir de filtre si intorcea „nicio fractie nu trece" —
## adevarat, si complet inutil: nu spunea care cerinta a picat, nici cat de
## putin. Un scor plus tabelul complet raspunde la ce intrebi de fapt, care e
## „unde e cel mai bine", nu „exista un loc perfect".
func _report_scan() -> void:
	print("\n=== SCAN: unde ar sta cel mai bine o tromba pe %s ===" % _track.track_name)
	print("  se cauta: sosea dreapta (raza mare), departe de alte hazarde,")
	print("  panta mica, si un capat de maturare pe APA — o tromba vine dinspre")
	print("  larg, iar contrastul apa/uscat e ce face traversarea lizibila.")
	var busy := _busy_fracs()
	var n := _track.baked.size()
	var sweep := _track.half_width * 3.2
	var sea := _sea_level()
	var rows: Array[Dictionary] = []
	for i in range(0, n, maxi(n / 200, 1)):
		var frac := float(i) / float(n)
		var here := _track.baked[i]
		var ahead := _track.baked[posmod(i + 6, n)]
		var dir := (ahead - here).normalized()
		var side := dir.cross(Vector3.UP).normalized()
		var slope := absf(ahead.y - here.y) / maxf(here.distance_to(ahead), 0.01)
		var radius := _radius_near(i, 40.0)
		var gap := _gap_to_busy(frac, busy)
		var wet := 0
		var pit := false
		var ends := PackedStringArray()
		for s: float in [-1.0, 1.0]:
			var g := _ground_at(here + side * sweep * s)
			# „Apa" NU inseamna ca raza n-a lovit nimic. Terenul pistei continua
			# SUB mare (fundul e sapat, nu lipseste), deci raza gaseste mereu ceva;
			# ce hotaraste e daca punctul ala e sub linia apei. Prima versiune
			# cauta o raza ratata si de aceea n-a gasit apa nicaieri pe o insula
			# inconjurata de ea.
			if g <= sea + 0.35:
				wet += 1
				ends.append("apa")
			else:
				# O groapa sub maturare inseamna ca tromba dispare intr-o rapa
				# tocmai la capat de cursa, adica exact acolo unde ar trebui s-o
				# vezi departandu-se.
				if g < here.y - 18.0:
					pit = true
				ends.append("%.0f" % g)
		var score := minf(radius, 8000.0) / 8000.0 * 2.0 \
			+ minf(gap, 0.12) / 0.12 * 2.0 \
			+ (1.0 - minf(slope, 0.20) / 0.20) \
			+ (1.5 if wet == 1 else 0.0) \
			- (3.0 if pit else 0.0)
		rows.append({"frac": frac, "radius": radius, "gap": gap, "slope": slope,
			"ends": " / ".join(ends), "y": here.y, "score": score})
	var header := "  %-7s %9s %8s %7s %6s   %s" \
		% ["frac", "raza", "distanta", "panta", "scor", "capete de maturare"]
	var line := func(r: Dictionary) -> void:
		print("  %-7.3f %7.0f m %8.3f %6.1f%% %6.2f   %s (sosea %.0f)"
			% [r.frac, minf(r.radius, 99999.0), r.gap, float(r.slope) * 100.0,
				r.score, r.ends, r.y])
	rows.sort_custom(func(a, b): return float(a.score) > float(b.score))
	print("\n  --- cele mai bune 10 dupa scor ---")
	print(header)
	for k in mini(rows.size(), 10):
		line.call(rows[k])
	# Si tabloul complet, in ordinea turului. Clasamentul spune care e cel mai
	# bun punct; harta spune daca exista o FEREASTRA — adica o bucata continua in
	# care hazardul incape — si asta e intrebarea reala pe o pista deja plina.
	rows.sort_custom(func(a, b): return float(a.frac) < float(b.frac))
	print("\n  --- tot turul, doar ce e la >= %.3f de alt hazard ---" % SCAN_MIN_GAP)
	print(header)
	for r: Dictionary in rows:
		if float(r.gap) >= SCAN_MIN_GAP:
			line.call(r)
