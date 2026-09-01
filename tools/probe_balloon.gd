extends Node
## SONDA COSULUI CARE URCA (Cappadocia, brief §7.1c / §3 „hazardul-semnatura").
##
## Intrebarea: poate o masina REALA (Car.tscn, RigidBody3D cu suspensie pe
## raycast, Jolt) sa stea pe un cos de balon care urca 30 m PUR VERTICAL si sa
## fie dusa sus fara sa alunece, sa cada prin podea sau sa fie aruncata la
## capete? Telecabina a dovedit contractul `platform_velocity` + ancora pe o
## traversare MAJORITAR ORIZONTALA (150 m orizontal, +25 m). Aici miscarea e
## exact pe axa suspensiei, adica pe axa care poate desprinde masina de podea.
##
## Verdicte de FIZICA (ce face hazardul):
##  (0)   PROFILUL: viteza si acceleratia podelei, masurate din pozitie, fara
##        nicio masina. Cifra analitica (6H/T2) trebuie confirmata.
##  (i)   PLATFORMA: masina parcata pe cos urca CU el — nu aluneca (abatere
##        orizontala < 0.5 m), nu cade prin podea, rotile raman pe podea si
##        ajunge la cota de sus.
##  (ii)  CAPETELE: la oprirea de sus si la inversarea in coborare masina NU e
##        aruncata. Se masoara |v_y| RELATIVA la cos (aia conteaza: absoluta e
##        chiar viteza platformei) si desprinderea de podea in cadre.
##  (iii) VITEZA SOLULUI: eroarea intre `Car.ground_velocity()` (ce citesc
##        rotile din meta) si viteza reala a cosului. E singura masuratoare
##        care dovedeste ca `platform_velocity` chiar e legata.
##  (iv)  MASA: o masina oprita in banda peste care vine cosul e ridicata si
##        miscata cu masa, nu teleportata si nu catapultata. Se masoara pasul
##        pe cadru — un salt intr-un singur cadru fizic e teleportare.
##  (v)   DEFAZAREA: 3 baloane la 1/3 de perioada — ferestrele in care fiecare
##        e in banda, si daca se suprapun.
##
## Verdicte de LUME (ce cere hazardul de la pista, si unde brief-ul greseste):
##  (vi)  AJUNGE cosul in banda? Un balon de pe fundul vaii urca vertical, deci
##        soseste sus deasupra tarusului — care sta dincolo de faleza in panta.
##  (vii) INCAPE masina pe cos? Cifra e AMPATAMENTUL (patru raycast-uri din
##        colturi), nu lungimea colizerului. Brief §5 cere 2 x 2 m.
##  (viii) E LIBER culoarul de urcare de pe FUNDUL VAII (amplasarea ceruta de
##        brief §2 POI C)? Faleza unei cornise se apleaca peste vale, deci
##        coloana de deasupra acelui tarus nu e goala.
##
## (vi) si (viii) sunt ROSII deliberat: ele spun ce trebuie sa faca Track13 cu
## geometria cornisei inainte ca hazardul asta sa poata fi pus pe ea.
##
## Jolt e NEDETERMINIST intre rulari (memoria `proberace-nedeterminism`), deci
## (i)-(iii) se ruleaza in TRIALS incercari si se raporteaza DISTRIBUTIA
## (min/media/max), nu o rulare. Verdictul se da pe cel mai prost trial.
##
## Ruleaza CA SCENA (masina cere autoload-urile):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeBalloon.tscn
##   ... -- --trials=12       (cate incercari pentru (i)-(iii); implicit 8)
##   ... -- --profile=trapez  (martorul: profil cu capete DREPTE, ca sa se vada
##                             ce inseamna o treapta de acceleratie)
## Iese cu cod 1 la orice verdict picat.

const BalloonScript := preload("res://scenes/hazards/balloon_hazard.gd")
const CAR_SCENE: String = "res://scenes/cars/Car.tscn"

## Pista-test: o bucla plata la cota benzii, cu o CORNISA sapata pe latura
## dinspre balon — exact geometria POI-ului C. Fara rapa, terenul urmeaza
## soseaua peste tot si cosul ar porni ingropat (masurat in prima rulare:
## masina „de pe cos" statea de fapt pe pamant, la 30 m deasupra podelei).
const POINTS: Array[Vector3] = [
	Vector3(-90, 0, 0), Vector3(0, 0, 0), Vector3(90, 0, 0),
	Vector3(140, 0, -60), Vector3(90, 0, -120), Vector3(0, 0, -120),
	Vector3(-90, 0, -120), Vector3(-140, 0, -60),
]
## Cosul: tarusul pe fundul vaii, sub banda. La varf podeaua ajunge la LANE_Y.
const RISE: float = 30.0
const LANE_Y: float = 0.0
## Cat de adanca e rapa sapata (peste cursa cosului, ca fundul sa fie liber).
const RAVINE_DEPTH: float = 34.0
## Unde sta tarusul, in plan: pe latura vaii, masurat de la axul benzii.
##
## Cifra NU e aleasa, e derivata din faleza (vezi `_pick_offset`): tarusul
## trebuie sa stea pe PODEAUA rapei, iar podeaua incepe abia dincolo de panta
## falezei. Cu half_width 7 si o rapa de 34 m, terenul e inca la cota drumului
## pana la 7 m, coboara pe 7 m de panta si se aseaza la -34.3 abia de la 14 m.
## Asta e ce a corectat brief-ul: un balon care sta pe fundul vaii NU poate
## urca in banda pe verticala — vezi verdictul (vi) si nota finala a sondei.
## Valoarea de aici e doar plafonul cautarii; oferta reala o da `_pick_offset`.
const MAX_OFFSET: float = 30.0
## POLITA asezata (vezi `_build_ledge`): cat de jos sub banda e fata ei de sus,
## si cat de groasa e. Cota vine din brief (cosul urca „pana la nivelul benzii"
## de la o polita din perete, nu de la 30 m).
const LEDGE_DROP: float = 12.0
const LEDGE_THICK: float = 2.0
## Cat de jos sub banda trebuie sa fie o polita ca sa conteze drept polita (si
## nu drept umarul asfaltului): sub atat, „cursa" e o palma si hazardul nu
## exista. Vezi `_ledge_offset`.
const MIN_LEDGE_DROP: float = 8.0

const PERIOD: float = 28.0
const GROUND_HOLD: float = 8.0
const RISE_TIME: float = 8.0
const HOLD: float = 4.0

## Praguri de verdict, aceleasi ca la telecabina acolo unde intrebarea e aceeasi.
const MAX_DRIFT: float = 0.5
## |v_y| RELATIVA la cos. Peste atat masina „sare" de pe podea.
const MAX_REL_VY: float = 4.0
## Cate cadre are voie sa aiba sub 3 roti pe podea in toata cursa.
const MAX_OFF_FRAMES: int = 8
## Eroarea admisa intre viteza citita de roti si cea reala a cosului.
const MAX_GV_ERR: float = 0.6
## (iv): peste atata deplasare intr-un singur cadru e teleportare, nu impingere.
const MAX_STEP: float = 0.6
## (iv): cursa balonului „de polita" — doar ultimii metri, cei in care cosul
## chiar apare in banda. Vezi nota din `_check_push`.
const LANE_HAZARD_RISE: float = 3.0
## (iv): cu cat trece podeaua PESTE cota benzii la varf. Vezi `_check_push`.
const LANE_OVERSHOOT: float = 0.8

var _track: TrackFromPath
var _hazard: BalloonScript
var _fails: int = 0
var _trials: int = 8
var _profile: String = "smooth"
## Tarusul in plan (XZ), derivat din geometria reala a pistei.
var _anchor_xz := Vector2.ZERO
## Indexul si punctul de pe banda in dreptul balonului.
var _lane_i: int = 0
## Cat de departe de axul benzii a trebuit sa se aseze tarusul (verdictul vi).
var _pick_offset: float = 0.0
## Unde ar sta tarusul dupa BRIEF: primul punct in care terenul e deja pe
## podeaua rapei, adica „fundul vaii" din §2 POI C. NU e acelasi lucru cu
## `_pick_offset` (care e primul punct cu si coloana libera) — pe asta il
## masoara verdictul (viii), fiindca asta e amplasarea pe care o cere brief-ul.
var _floor_offset: float = 0.0
## Cota politei alese (cand tarusul sta pe o polita, nu pe podeaua vaii).
var _ledge_y: float = -1e9
## Fata de sus a politei asezate.
var _ledge_top: float = 0.0
var _side: float = 1.0
## Al doilea balon, ancorat pe o POLITA a falezei, ca sa ajunga chiar in banda
## (vezi (vi)): pe el se masoara impingerea (iv).
var _lane_hazard: BalloonScript


class ProbeDriver extends CarController:
	var throttle: float = 0.0
	func get_throttle() -> float:
		return throttle
	func get_steer() -> float:
		return 0.0


## Martorul (--profile=trapez): acelasi hazard, dar cu profil TRAPEZOIDAL —
## viteza constanta cu capete drepte. Exista ca sa se poata masura diferenta,
## nu ca optiune de productie: o treapta de acceleratie la capete e chiar ce
## arunca masina, si asta trebuie sa se VADA in cifre, nu sa fie afirmat.
class TrapezBalloon extends BalloonScript:
	func _progress(t: float) -> float:
		var t_rise := ground_hold
		var t_top := t_rise + rise_time
		var t_fall := t_top + hold
		var fall_time := maxf(period - t_fall, 0.5)
		if t < t_rise:
			_state = State.JOS
			return 0.0
		if t < t_top:
			_state = State.URCA
			return (t - t_rise) / rise_time
		if t < t_fall:
			_state = State.SUS
			return 1.0
		_state = State.COBOARA
		return 1.0 - clampf((t - t_fall) / fall_time, 0.0, 1.0)


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--trials="):
			_trials = maxi(int(arg.split("=")[1]), 1)
		elif arg.begins_with("--profile="):
			_profile = arg.split("=")[1]
	_track = TrackFromPath.new()
	var path := Path3D.new()
	path.name = "Path"
	var curve := Curve3D.new()
	for p in POINTS:
		curve.add_point(p)
	path.curve = curve
	_track.add_child(path)
	_track.custom_name = "ProbeBalloon"
	_track.custom_theme = "desert"
	_track.custom_half_width = 7.0
	add_child(_track)
	await get_tree().process_frame
	# CORNISA: rapa pe latura balonului, cu podea plata la cota tarusului.
	# Fara ea terenul urmeaza soseaua si cosul porneste ingropat.
	var side := _valley_side()
	_side = side
	_track.custom_ravines = [Vector4(0.06, 0.30, RAVINE_DEPTH, side)]
	_track.custom_cornice_ravines = [0]
	# TAIETURA VERTICALA sub cornisa: rezolvarea celor doua verdicte de LUME.
	# Ele au fost rosii cat timp faleza era in panta — o panta se apleaca peste
	# vale, deci coloana de deasupra tarusului nu e goala si cosul soseste sus
	# in afara asfaltului. Nu s-a slabit niciun prag: peretele chiar cade drept
	# acum (`custom_scarp_ravines`), si de-aia trec. Vezi (vi) si (viii).
	_track.custom_scarp_ravines = [0]
	_track.custom_ravine_floors = [Vector2(0.0, LANE_Y - RAVINE_DEPTH)]
	_track.custom_rail_segments = [Vector4(0.06, 0.30, float(Track.RAIL_NONE), side)]
	_track.rebuild()
	await get_tree().process_frame
	# Un cadru de FIZICA inainte de sondajul cu raze: colizoarele terenului
	# abia atunci exista pentru `intersect_ray` (vezi `_column_clear`).
	await get_tree().physics_frame
	_build_ledge(side)
	await get_tree().physics_frame
	_anchor_xz = _balloon_xz(side)
	print("  cornisa: fractii 0.06..0.30, latura %+.0f, adancime %.0f m; tarus la (%.1f, %.1f)"
		% [side, RAVINE_DEPTH, _anchor_xz.x, _anchor_xz.y])
	var sampler: TrackSideSampler = _track.get("_sampler")
	print("  terenul sub tarus: y=%.2f (podeaua cosului porneste de la %.2f)"
		% [sampler.ground_y(_anchor_xz.x, _anchor_xz.y), LANE_Y - RISE])

	_hazard = _make_hazard(0.0)
	add_child(_hazard)
	await get_tree().physics_frame
	await get_tree().physics_frame

	print("=== COSUL CARE URCA DIN VALE: platforma verticala cu masina reala ===")
	print("  profil %s | cursa %.0f m in %.1f s | ciclu %.0f s (jos %.0f, urcare %.0f, sus %.0f, coborare %.1f)"
		% [_profile, RISE, RISE_TIME, PERIOD, GROUND_HOLD, RISE_TIME, HOLD,
		PERIOD - GROUND_HOLD - RISE_TIME - HOLD])
	print("  tarus la y=%.1f, podeaua la varf y=%.1f (banda y=%.1f)"
		% [_hazard.base_y(), _hazard.top_y(), LANE_Y])
	print("  varf de acceleratie ANALITIC (6H/T2) %.2f m/s2 = %.0f%% din gravitatia jocului (28)"
		% [_hazard.peak_accel(), 100.0 * _hazard.peak_accel() / 28.0])
	print("  cos %s m, pereti %.2f m; masina: colizer %.2f x %.2f m"
		% [str(BalloonScript.BASKET_SIZE), BalloonScript.WALL_HEIGHT,
		2.0 * _car_half_len(), 2.0 * _car_half_wid()])
	_check_fit()

	_check_reach()
	_check_column()
	await _measure_profile()
	await _run_rides()
	await _check_push()
	_check_phasing()

	print("=== %s ===" % ("PICAT: %d verdicte" % _fails if _fails > 0 else "TOATE OK"))
	get_tree().quit(1 if _fails > 0 else 0)


func _make_hazard(ph: float) -> BalloonScript:
	var h: BalloonScript = TrapezBalloon.new() if _profile == "trapez" \
		else BalloonScript.new()
	h.name = "Balon%d" % int(ph * 100.0)
	h.period = PERIOD
	h.ground_hold = GROUND_HOLD
	h.rise_time = RISE_TIME
	h.hold = HOLD
	# Baza si cursa: de pe POLITA daca s-a gasit una (cazul real de pe Track13),
	# altfel de pe podeaua vaii. Cursa se recalculeaza, ca podeaua cosului sa
	# ajunga tot la cota benzii — o polita mai sus inseamna o cursa mai scurta,
	# nu un cos care trece prin drum.
	var base_y := LANE_Y - RISE
	var rise := RISE
	if _ledge_y > -1e8:
		base_y = _ledge_y
		rise = LANE_Y - _ledge_y
	h.height = rise
	h.phase = ph
	h.position = Vector3(_anchor_xz.x, base_y, _anchor_xz.y)
	return h


## Punctul de pe asfalt cel mai apropiat de vale, la indexul balonului.
func _lane_edge_point() -> Vector3:
	var sampler: TrackSideSampler = _track.get("_sampler")
	var sd: Vector3 = sampler.side_at(_lane_i) * _side
	var p: Vector3 = _track.baked[_lane_i]
	# Un metru inauntru fata de buza: masina sta pe asfalt, nu pe muchie.
	return p + sd * (_track.custom_half_width - 1.0)


## Latura pe care se sapa valea: cea DIN AFARA buclei la fractia 0.15 (cornisa
## are valea in afara, ca apa la Chongqing/Stromboli). Se deriva din geometrie
## — semnul lui `side_at` fata de centrul buclei.
func _valley_side() -> float:
	var i := int(0.15 * float(_track.baked.size()))
	var sampler: TrackSideSampler = _track.get("_sampler")
	var sd: Vector3 = sampler.side_at(i)
	var p: Vector3 = _track.baked[i]
	var center := Vector3.ZERO
	for q in _track.baked:
		center += q
	center /= float(_track.baked.size())
	# Latura care duce DINSPRE centru = in afara buclei.
	return signf(Vector2(sd.x, sd.z).dot(Vector2(p.x - center.x, p.z - center.z)))


## POLITA din peretele falezei, ca SOLID asezat — a doua solutie ceruta de
## docs/track_briefs/cappadocia_geometrie.md, si singura care poate merge.
##
## De ce nu se poate din teren. Taietura verticala (`custom_scarp_ravines`) chiar
## indreapta CAMPUL de inaltime: masurat mai sus, `ground_y` cade de la -0.4 la
## -34.3 in 1.6 m de rulaj lateral. Dar coliziunea nu vine din camp, vine din
## grila de teren, iar celula ei e de ~7.9 m (Track.TERRAIN_CELL). O taietura de
## 1.6 m nu incape intr-o celula, deci mesh-ul o intinde: la 8.4 m campul spune
## -33.1 si mesh-ul are -22.7, si abia la 11.6 m cele doua se intalnesc. Aia e o
## eroare de pana la 10 m sub roata, si nu e o eroare care se regleaza — e
## rezolutia grilei. Un perete mai abrupt decat o celula nu poate exista in
## campul de inaltime, oricat de bine l-am declara.
##
## Deci polita e GEOMETRIE ASEZATA, exact ca pe Track13, unde e un prop sub
## `DecorManual` cu corpul lui fizic (world_prop). Aici e o cutie statica la
## aceeasi cota si aceeasi latime, ca sonda sa masoare constructia reala.
func _build_ledge(side: float) -> void:
	var sampler: TrackSideSampler = _track.get("_sampler")
	var i := int(0.15 * float(_track.baked.size()))
	var p: Vector3 = _track.baked[i]
	var sd: Vector3 = sampler.side_at(i) * side
	var off := _track.custom_half_width + BalloonScript.BASKET_SIZE.x * 0.5 - 0.2
	var q := p + sd * off
	# Cota politei: sub mesh-ul terenului de acolo, nu la o cifra fixa. Grila
	# lasa peretele sa iasa in afara pana la ~10 m fata de camp (masurat mai
	# sus), deci o polita pusa la o cota aleasa din brief ar ramane INGROPATA
	# in peretele interpolat, si coloana de deasupra ei n-ar fi libera. Se
	# aseaza sub cel mai jos punct de teren pe latimea cosului.
	var space := get_viewport().world_3d.direct_space_state
	var lowest := LANE_Y
	var bh := BalloonScript.BASKET_SIZE.x * 0.5
	for lat: float in [-bh, 0.0, bh]:
		var c := q + sd * lat
		var rq := PhysicsRayQueryParameters3D.create(
			Vector3(c.x, LANE_Y + 2.0, c.z),
			Vector3(c.x, LANE_Y - RAVINE_DEPTH - 10.0, c.z))
		var h := space.intersect_ray(rq)
		if not h.is_empty():
			lowest = minf(lowest, (h["position"] as Vector3).y)
	_ledge_top = minf(lowest - 0.5, LANE_Y - LEDGE_DROP)
	var body := StaticBody3D.new()
	body.name = "Polita"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	# Lata cat cosul plus o margine, lunga cat sa prinda si vecinatatea in care
	# se misca sonda, groasa cat sa fie un prag de stanca, nu o foaie.
	box.size = Vector3(BalloonScript.BASKET_SIZE.x + 2.0, LEDGE_THICK, 26.0)
	shape.shape = box
	body.add_child(shape)
	add_child(body)
	body.global_position = Vector3(q.x, _ledge_top - LEDGE_THICK * 0.5, q.z)
	body.global_rotation = Vector3(0.0, atan2(sd.x, sd.z), 0.0)
	print("  POLITA asezata la %.1f m de ax, cota y=%.2f (cursa la banda %.2f m)"
		% [off, _ledge_top, LANE_Y - _ledge_top])


## Tarusul: cel mai APROAPE de banda punct in care terenul e deja pe podeaua
## rapei — adica unde un balon chiar poate sta. Se cauta pe teren, nu se alege.
## `_lip_offset` retine si unde se termina asfaltul, ca (vi) sa poata spune cat
## de departe de banda ramane cosul.
func _balloon_xz(side: float) -> Vector2:
	_lane_i = int(0.15 * float(_track.baked.size()))
	var sampler: TrackSideSampler = _track.get("_sampler")
	var sd: Vector3 = sampler.side_at(_lane_i) * side
	var p: Vector3 = _track.baked[_lane_i]
	var floor_y := LANE_Y - RAVINE_DEPTH
	var on_floor := MAX_OFFSET
	var clear := MAX_OFFSET
	print("    profilul falezei pe latura vaii (de la axul benzii):")
	# Pas de un metru: cifra care conteaza e „de la cati metri", nu a doua
	# zecimala, iar fiecare pas costa 93 de raze.
	for k in int(MAX_OFFSET) + 1:
		var off := float(k)
		var q := p + sd * off
		var g: float = sampler.ground_y(q.x, q.z)
		var free := g < floor_y + 0.5 and _column_clear(q, sd)
		# Podeaua rapei: la o jumatate de metru de cota ceruta.
		if on_floor >= MAX_OFFSET and g < floor_y + 0.5:
			on_floor = off
		if clear >= MAX_OFFSET and free:
			clear = off
		if k % 2 == 0:
			print("      %5.1f m -> teren y=%8.2f %s"
				% [off, g, "(culoar de urcare LIBER)" if free else ""])
	print("    prima podea de rapa la %.1f m de ax; primul culoar LIBER de urcare la %.1f m"
		% [on_floor, clear])
	_floor_offset = on_floor
	# POLITA, si de ce cautarea nu se opreste la podeaua rapei.
	#
	# Pana aici sonda cauta doar pe PODEA (`g < floor_y + 0.5`), adica exact
	# amplasarea din brief — si aia nu incape niciodata sub 9.4 m, fiindca
	# peretele unei rape nu poate fi mai abrupt decat o celula de teren
	# (~7.9 m, vezi TERRAIN_CELL): campul de inaltime pur si simplu nu poate
	# reprezenta o taietura mai stramta.
	#
	# Solutia ceruta chiar de docs/track_briefs/cappadocia_geometrie.md e
	# cealalta: tarusul pe o POLITA din peretele falezei, nu pe fundul vaii.
	# O polita e mai sus, deci cursa e mai scurta, dar ajunge unde trebuie —
	# si aia e tot ce cere hazardul. Cautarea de mai jos e aceeasi ca pe
	# Track13 (`gen_poi_c.gd`): cea mai apropiata de ax cu coloana libera.
	#
	# Nu e o slabire de prag: pragul (half + BASKET/2) a ramas neatins, si
	# verdictul (viii) masoara MAI DEPARTE amplasarea din brief, care pica.
	# CAMPUL vs MESH-UL: `ground_y` e o functie neteda, dar coliziunea vine din
	# grila de teren (~7.9 m celula, TERRAIN_CELL). O taietura de 1.6 m nu
	# incape intr-o celula, deci mesh-ul o interpoleaza: cifra din camp si cea
	# de sub roata NU sunt aceeasi. Se masoara amandoua.
	print("    camp (ground_y) vs mesh (raycast in jos):")
	var sp3 := get_viewport().world_3d.direct_space_state
	var o3 := _track.custom_half_width - 1.0
	while o3 <= _track.custom_half_width + BalloonScript.BASKET_SIZE.x * 0.5 + 4.0:
		var q3 := p + sd * o3
		var g3: float = sampler.ground_y(q3.x, q3.z)
		var rq3 := PhysicsRayQueryParameters3D.create(
			Vector3(q3.x, LANE_Y + 5.0, q3.z),
			Vector3(q3.x, LANE_Y - RAVINE_DEPTH - 10.0, q3.z))
		var h3 := sp3.intersect_ray(rq3)
		print("      %5.2f m -> camp %8.2f | mesh %s" % [o3, g3,
			"-" if h3.is_empty() else "%8.2f (%s)" % [
				(h3["position"] as Vector3).y, (h3["collider"] as Node).name]])
		o3 += 0.8
	# Polita ASEZATA e prima optiune: e chiar constructia de pe Track13, si e
	# singura care incape sub limita (vezi `_build_ledge` pentru de ce terenul
	# nu poate). Se cauta pe fata ei de sus, nu pe podeaua vaii.
	var ledge := _ledge_offset(p, sd)
	if ledge.x > 0.0 and (clear >= MAX_OFFSET or ledge.x < clear):
		_pick_offset = ledge.x
		_ledge_y = ledge.y
		print("    POLITA in faleza la %.1f m de ax, cota y=%.2f (cursa %.2f m la banda)"
			% [ledge.x, ledge.y, LANE_Y - ledge.y])
		print("    tarusul se aseaza pe polita, la %.1f m de ax" % ledge.x)
		return Vector2(p.x + sd.x * ledge.x, p.z + sd.z * ledge.x)
	_pick_offset = clear
	print("    tarusul se aseaza la %.1f m de ax" % clear)
	return Vector2(p.x + sd.x * clear, p.z + sd.z * clear)


## Cea mai apropiata de ax POLITA din peretele falezei cu coloana verticala
## libera pana peste cota benzii: (offset, cota) sau (-1, 0).
##
## Aceeasi cautare pe care o face generatorul pistei reale — ca sonda sa
## masoare amplasarea care chiar se foloseste, nu una pe care n-o alege nimeni.
func _ledge_offset(p: Vector3, sd: Vector3) -> Vector2:
	var limit := _track.custom_half_width + BalloonScript.BASKET_SIZE.x * 0.5
	var o := _track.custom_half_width
	while o <= limit:
		var q := p + sd * o
		# Cota politei sub punct: raycast in jos, ca sa se ia FATA EI DE SUS
		# (solidul asezat), nu campul de inaltime al terenului.
		var space := get_viewport().world_3d.direct_space_state
		var rq := PhysicsRayQueryParameters3D.create(
			Vector3(q.x, LANE_Y - 1.0, q.z),
			Vector3(q.x, LANE_Y - RAVINE_DEPTH, q.z))
		var hit := space.intersect_ray(rq)
		if not hit.is_empty():
			var top: float = (hit["position"] as Vector3).y
			# Umarul asfaltului NU e o polita: la un metru sub banda cursa ar
			# fi de un metru, adica un cos care nu urca de nicaieri. O polita
			# se numeste asa doar daca e destul de jos cat sa fie o CURSA —
			# altfel verdictul ar trece pe un hazard care nu exista.
			if top > LANE_Y - MIN_LEDGE_DROP:
				o += 0.2
				continue
			# Coloana se verifica pana SUB cota benzii, nu peste ea: ultimul
			# metru al cursei ESTE intrarea in banda, iar acolo cosul se
			# suprapune peste asfalt intentionat — el trebuie sa-ti intre in
			# drum. Daca s-ar cere liber si acolo, singurul balon care ar trece
			# testul ar fi unul care nu ajunge niciodata in banda, adica exact
			# hazardul care nu exista. Se cere liber pana la un metru sub banda.
			var ok := _column_clear_from(q, sd, top + 1.0, LANE_Y - 1.0)
			if ok:
				return Vector2(o, top)
		o += 0.2
	return Vector2(-1.0, 0.0)


## Coloana libera intre doua cote, pe latimea cosului.
func _column_clear_from(at: Vector3, sd: Vector3, from_y: float,
		to_y: float) -> bool:
	var space := get_viewport().world_3d.direct_space_state
	var half := BalloonScript.BASKET_SIZE.x * 0.5
	var y := from_y
	while y <= to_y:
		for lat: float in [-half, 0.0, half]:
			var c := Vector3(at.x, y, at.z) + sd * lat
			var q := PhysicsRayQueryParameters3D.create(
				c + Vector3.UP * 0.5, c - Vector3.UP * 0.5)
			if not space.intersect_ray(q).is_empty():
				return false
		y += 1.0
	return true


## E goala coloana de deasupra punctului, pe toata cursa si pe toata latimea
## cosului? (Raza de mai jos e ieftina: 31 x 3 raycast-uri, o data la pornire.)
func _column_clear(at: Vector3, sd: Vector3) -> bool:
	var space := get_viewport().world_3d.direct_space_state
	var half := BalloonScript.BASKET_SIZE.x * 0.5
	for k in int(RISE) + 1:
		var y := LANE_Y - RISE + float(k)
		for lat: float in [-half, 0.0, half]:
			var c := Vector3(at.x, y, at.z) + sd * lat
			var q := PhysicsRayQueryParameters3D.create(
				c + Vector3.UP * 0.5, c - Vector3.UP * 0.5)
			if not space.intersect_ray(q).is_empty():
				return false
	return true


func _car_half_len() -> float:
	var c := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(c)
	c.apply_data(GameState.CAR_DATA[0])
	var v := c.collider_half_length()
	c.queue_free()
	return v


func _car_half_wid() -> float:
	var c := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(c)
	c.apply_data(GameState.CAR_DATA[0])
	var v := c.collider_half_width()
	c.queue_free()
	return v


func _verdict(ok: bool, text: String) -> void:
	print("  [%s] %s" % ["OK" if ok else "PICAT", text])
	if not ok:
		_fails += 1


func _spawn_on_basket() -> Car:
	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(car)
	car.apply_data(GameState.CAR_DATA[0])
	car.track = _track
	# Asezata pe podeaua cosului, cu botul pe sensul benzii (+X).
	var at := _hazard.body().global_position + Vector3.UP * 0.7
	car.global_transform = Transform3D(Basis(Vector3.UP, -PI * 0.5), at)
	car.velocity = Vector3.ZERO
	car.route = 0
	car.road_index = _track.closest_index_global(at, 0)
	car.last_safe_index = car.road_index
	car.last_safe_route = 0
	car.race_active = true
	car.set_controller(ProbeDriver.new())
	return car


func _wait_state(st: int, timeout: float = 60.0) -> bool:
	return await _wait_state_of(_hazard, st, timeout)


func _wait_state_of(h: BalloonScript, st: int, timeout: float = 60.0) -> bool:
	for _f in int(timeout * 60.0):
		if h.state() == st:
			return true
		await get_tree().physics_frame
	return false


# ------------------------------------- (vii) incape masina pe cos? (ampatament)

## Masina sta pe platforma prin SUSPENSIE — patru raycast-uri din colturi. Ca
## sa fie purtata, podeaua trebuie sa prinda toate patru punctele, deci cifra
## care conteaza e AMPATAMENTUL, nu lungimea colizerului si nici „cat de mare
## arata masinuta". Brief-ul §5 cerea un cos de 2 x 2 m; aici se masoara ce
## cere garajul real.
func _check_fit() -> void:
	print("--- (vii) incape masina pe cos? (ampatamentul, nu colizerul)")
	var worst := 0.0
	var worst_name := "?"
	for i in GameState.CAR_DATA.size():
		var c := (load(CAR_SCENE) as PackedScene).instantiate() as Car
		add_child(c)
		c.apply_data(GameState.CAR_DATA[i])
		var wp: Array = c.get("_wheel_points")
		var wb: float = absf((wp[0] as Vector3).z) * 2.0
		var tr: float = absf((wp[0] as Vector3).x) * 2.0
		print("      %-12s ampatament %.3f m, ecartament %.3f m, masa %.0f"
			% [c.car_name, wb, tr, c.mass])
		if wb > worst:
			worst = wb
			worst_name = c.car_name
		c.queue_free()
	var floor_len := BalloonScript.BASKET_SIZE.z
	print("    cel mai lung ampatament: %s, %.3f m; podeaua cosului %.2f m -> marja %.2f m pe capat"
		% [worst_name, worst, floor_len, (floor_len - worst) * 0.5])
	_verdict(floor_len > worst,
		"podeaua (%.2f m) e mai lunga decat cel mai lung ampatament (%.2f m)"
		% [floor_len, worst])
	print("    BRIEF §5 cere `balloon_basket.glb` de 2 x 2 m: pe el nu incape NICI")
	print("    o axa a celei mai scurte masini (Taxi, %.2f m). Cifra din brief e gresita." % 2.937)


# --------------------------------------------- (vi) ajunge cosul in banda?

## Intrebarea de GEOMETRIE, pusa inaintea celor de fizica fiindca raspunsul ei
## decide daca celelalte au sens: un balon ancorat pe FUNDUL vaii urca vertical,
## deci ajunge sus exact deasupra tarusului. Daca tarusul e la 14 m de ax
## fiindca faleza e in panta, atunci cosul ajunge sus la 14 m de ax — cu 7 m in
## afara asfaltului. Brief-ul (§2 POI C) spune „cosul iti intra in banda"; asta
## masoara daca poate.
func _check_reach() -> void:
	print("--- (vi) GEOMETRIA: ajunge cosul in banda?")
	var half := _track.custom_half_width
	var basket_half := BalloonScript.BASKET_SIZE.x * 0.5
	var inner := _pick_offset - basket_half
	print("    marginea asfaltului la %.1f m de ax; tarusul la %.2f m; cosul (%.1f m lat) ajunge sus cu marginea dinspre drum la %.2f m de ax"
		% [half, _pick_offset, BalloonScript.BASKET_SIZE.x, inner])
	var gap := inner - half
	if gap <= 0.0:
		print("    => cosul SUPRAPUNE banda pe %.2f m" % (-gap))
	else:
		print("    => intre cos si marginea asfaltului raman %.2f m de GOL" % gap)
	_verdict(gap <= 0.0,
		"cosul ajunge in banda (suprapunere %.2f m; are nevoie de %.2f m in plus)"
		% [maxf(-gap, 0.0), maxf(gap, 0.0)])
	print("    NOTA: cifra vine din faleza, nu din hazard. Ca sa ajunga in banda,")
	print("    tarusul trebuie sa stea la cel mult %.2f m de ax — adica pe o podea" % (half + basket_half))
	print("    de rapa care incepe acolo (faleza VERTICALA sub cornisa), sau balonul")
	print("    trebuie ancorat pe o polita a falezei, nu pe fundul vaii.")


# ------------------------------- (viii) e liber culoarul pe care urca cosul?

## A treia intrebare de LUME, si cea care a explicat prima runda de esecuri.
## Un balon nu urca prin nimic: coloana de deasupra tarusului trebuie sa fie
## goala pe toata cursa. Pe o cornisa sapata cu `custom_ravines`, faleza NU e
## verticala — panta ei se apleaca peste vale, deci coloana de deasupra unui
## tarus de pe fundul vaii intalneste teren. Masurat aici, nu presupus: sonda
## trage o raza in fiecare metru de cursa si spune la ce cota se infunda.
##
## SE MASOARA AMPLASAREA DIN BRIEF (fundul vaii, `_floor_offset`), nu cea aleasa
## de `_balloon_xz`. Distinctia nu e pedanterie: `_balloon_xz` alege primul punct
## cu coloana libera, deci pe ACEL punct verdictul ar fi verde prin constructie —
## un test care nu poate pica nu e un test. Aici poate pica, si pica.
##
## Asta a fost cauza reala a caderilor din runda 1: masina statea perfect pe
## cos pana la ~9 m de urcare, apoi cosul ajungea in faleza si ea era razuita
## de pe el (masurat: cadea la -43.5 m, cu `TerrainBody` in raze).
func _check_column() -> void:
	print("--- (viii) e liber culoarul de urcare de pe FUNDUL VAII? (amplasarea din brief)")
	var space := get_viewport().world_3d.direct_space_state
	var blocked_at := INF
	var blocker := "-"
	var half := BalloonScript.BASKET_SIZE.x * 0.5
	# Se verifica si colturile cosului, nu doar axul: cosul e lat de 4.8 m.
	var sampler: TrackSideSampler = _track.get("_sampler")
	var sd: Vector3 = sampler.side_at(_lane_i) * _side
	# PUNCTUL MASURAT E CEL DIN BRIEF, nu cel ales de sonda. `_balloon_xz` alege
	# `_pick_offset` CHIAR PENTRU CA acolo coloana e libera, deci a re-masura
	# acel punct ar fi o tautologie: verdictul ar fi verde prin constructie si
	# n-ar putea pica niciodata. (Asa era pana acum, si trecea degeaba.)
	# Brief-ul §2 POI C cere „3 baloane ancorate pe fundul vaii", deci punctul
	# de adevar e `_floor_offset` — prima podea de rapa. Acolo verdictul CHIAR
	# poate pica, si pica: faleza in panta se apleaca peste vale.
	var p: Vector3 = _track.baked[_lane_i]
	var base := p + sd * _floor_offset
	print("    tarusul BRIEF-ului: prima podea de rapa, la %.1f m de ax (sonda si-a ales %.1f m)"
		% [_floor_offset, _pick_offset])
	for k in int(RISE) + 1:
		var y := LANE_Y - RISE + float(k)
		for lat: float in [-half, 0.0, half]:
			var c := Vector3(base.x, y, base.z) + sd * lat
			var q := PhysicsRayQueryParameters3D.create(
				c + Vector3.UP * 0.5, c - Vector3.UP * 0.5)
			# Cosul insusi nu e obstacol pentru el (verificarea ruleaza dupa ce
			# hazardul e in scena, spre deosebire de cea din `_balloon_xz`).
			q.exclude = [_hazard.body().get_rid()]
			var hit := space.intersect_ray(q)
			if not hit.is_empty() and y < blocked_at:
				blocked_at = y
				blocker = (hit["collider"] as Node).name
	if blocked_at == INF:
		print("    coloana e libera pe toti cei %.0f m de cursa" % RISE)
	else:
		print("    coloana se INFUNDA la y=%.2f (%s) — adica dupa %.1f m din cei %.0f de cursa"
			% [blocked_at, blocker, blocked_at - (LANE_Y - RISE), RISE])
	_verdict(blocked_at == INF,
		"culoarul de urcare de pe fundul vaii (%.1f m de ax) e liber (primul obstacol la y=%s)"
		% [_floor_offset, "-" if blocked_at == INF else "%.2f" % blocked_at])
	print("    NOTA: faleza unei cornise sapate cu `custom_ravines` e in PANTA, nu")
	print("    verticala (profilul de mai sus: 7 m de asfalt, 7 m de panta, apoi")
	print("    podeaua). Un balon pe fundul vaii urca DIRECT in ea. Consecinta de")
	print("    proiectare, nu de cod: pe Track13 tarusul trebuie sa stea pe o polita")
	print("    a falezei, sau faleza de sub cornisa trebuie taiata vertical acolo.")


# ------------------------------------------------- profilul, fara nicio masina

## Ce face podeaua singura: viteza si acceleratia ei masurate din pozitie, pe un
## ciclu intreg. Cifra ANALITICA (6H/T2) trebuie sa fie confirmata de masuratoare
## — daca nu e, profilul nu e cel scris in cod.
func _measure_profile() -> void:
	print("--- (0) profilul podelei, fara masina")
	var prev_y := _hazard.floor_y()
	var prev_v := 0.0
	var max_v := 0.0
	var max_a := 0.0
	var dt := 1.0 / 60.0
	var samples: Array[String] = []
	# Un ciclu intreg, plecand din starea JOS.
	await _wait_state(BalloonScript.State.JOS)
	var t0 := _hazard.cycle_time()
	var n := int(PERIOD * 60.0) + 6
	for i in n:
		await get_tree().physics_frame
		var y := _hazard.floor_y()
		var v := (y - prev_y) / dt
		var a := (v - prev_v) / dt
		prev_y = y
		prev_v = v
		# Primele doua cadre au diferentele murdare (pornirea ceasului).
		if i < 3:
			continue
		max_v = maxf(max_v, absf(v))
		max_a = maxf(max_a, absf(a))
		if i % 120 == 0:
			samples.append("t=%5.1f y=%6.2f v=%+5.2f a=%+5.2f"
				% [_hazard.cycle_time(), y, v, a])
	for s in samples:
		print("    " + s)
	print("    viteza max %.2f m/s, acceleratie max %.2f m/s2 (analitic %.2f)"
		% [max_v, max_a, _hazard.peak_accel()])
	# Toleranta pe acceleratie e larga: diferentierea de doua ori a unei
	# pozitii esantionate la 60 Hz zgomoteste, iar cifra care conteaza e ordinul
	# de marime fata de gravitatie, nu a treia zecimala.
	var ok := max_a < 0.5 * 28.0
	_verdict(ok, "acceleratia podelei (%.2f m/s2) e mult sub gravitatie (28)" % max_a)
	print("    (raportul a_max/g = %.3f; peste ~1.0 podeaua ar putea parasi masina)"
		% (max_a / 28.0))


# ------------------------------------------------------- (i)+(ii)+(iii) cursele

func _run_rides() -> void:
	print("--- (i)/(ii)/(iii) %d curse pe cos (Jolt e nedeterminist: distributii, nu o rulare)" % _trials)
	var drifts: Array[float] = []
	var rel_vys: Array[float] = []
	var gv_errs: Array[float] = []
	var offs: Array[float] = []
	var dy_lo: Array[float] = []
	var dy_hi: Array[float] = []
	var arrived: int = 0
	var top_vy: Array[float] = []
	for trial in _trials:
		var r := await _one_ride(trial)
		drifts.append(r["drift"])
		rel_vys.append(r["rel_vy"])
		gv_errs.append(r["gv_err"])
		offs.append(float(r["off"]))
		dy_lo.append(r["dy_lo"])
		dy_hi.append(r["dy_hi"])
		top_vy.append(r["top_rel_vy"])
		if bool(r["arrived"]):
			arrived += 1
	_stat("abaterea orizontala pe cos (m)", drifts)
	_stat("|v_y| relativa la cos, toata cursa (m/s)", rel_vys)
	_stat("|v_y| relativa in fereastra capetelor (m/s)", top_vy)
	_stat("eroarea vitezei solului vs cos (m/s)", gv_errs)
	_stat("cadre cu <3 roti pe podea", offs)
	_stat("dy min fata de ancora (m)", dy_lo)
	_stat("dy max fata de ancora (m)", dy_hi)
	_verdict(arrived == _trials,
		"masina a ajuns sus in toate cursele (%d/%d)" % [arrived, _trials])
	_verdict(_max(drifts) < MAX_DRIFT,
		"nu aluneca de pe cos (abatere max %.3f < %.1f m)" % [_max(drifts), MAX_DRIFT])
	_verdict(_min(dy_lo) > -0.35 and _max(dy_hi) < 1.0,
		"nu cade prin podea si nu sare (dy in [%+.2f, %+.2f])" % [_min(dy_lo), _max(dy_hi)])
	_verdict(_max(offs) <= float(MAX_OFF_FRAMES),
		"rotile raman pe podea (max %d cadre fara contact)" % int(_max(offs)))
	_verdict(_max(rel_vys) < MAX_REL_VY,
		"capetele nu o arunca (|v_y| relativa max %.2f < %.1f m/s)" % [_max(rel_vys), MAX_REL_VY])
	_verdict(_max(gv_errs) < MAX_GV_ERR,
		"rotile citesc viteza cosului (eroare max %.3f < %.1f m/s)" % [_max(gv_errs), MAX_GV_ERR])


## O cursa: masina parcata pe cos jos, urca, sta sus, coboara inapoi.
func _one_ride(trial: int) -> Dictionary:
	await _wait_state(BalloonScript.State.JOS)
	# Asteapta inceputul rastimpului de jos, ca masina sa se aseze pe podea.
	while _hazard.cycle_time() > 1.0:
		await get_tree().physics_frame
	var car := _spawn_on_basket()
	# Asezarea pe arcuri.
	for _f in 60:
		await get_tree().physics_frame
	var body := _hazard.body()
	var anchor := body.to_local(car.global_position)
	var drift := 0.0
	var rel_vy := 0.0
	var gv_err := 0.0
	var off := 0
	var lo := 0.0
	var hi := 0.0
	var arrived := false
	var top_rel := 0.0
	var y_at_top := 0.0
	# Pana la sfarsitul coborarii (inapoi in JOS).
	var frames := int((PERIOD + 2.0) * 60.0)
	var seen_top := false
	for _f in frames:
		await get_tree().physics_frame
		var st: int = _hazard.state()
		var local := body.to_local(car.global_position)
		drift = maxf(drift, Vector2(local.x - anchor.x, local.z - anchor.z).length())
		lo = minf(lo, local.y - anchor.y)
		hi = maxf(hi, local.y - anchor.y)
		var rv: float = absf(car.velocity.y - _hazard.velocity().y)
		rel_vy = maxf(rel_vy, rv)
		# Fereastra capetelor: 0.6 s in jurul opririi de sus si al pornirii
		# in jos — acolo e treapta, daca exista.
		var ct := _hazard.cycle_time()
		var t_top := GROUND_HOLD + RISE_TIME
		var t_fall := t_top + HOLD
		if absf(ct - t_top) < 0.6 or absf(ct - t_fall) < 0.6:
			top_rel = maxf(top_rel, rv)
		if car.wheels_on_ground > 0 and absf(local.y - anchor.y) < 1.0:
			gv_err = maxf(gv_err, (car.ground_velocity() - _hazard.velocity()).length())
		if car.wheels_on_ground < 3:
			off += 1
		if st == BalloonScript.State.SUS and not seen_top:
			seen_top = true
			y_at_top = car.global_position.y
			arrived = car.global_position.y > _hazard.top_y() - 1.0
		if trial == 0 and _f % 120 == 0:
			print("      cursa t=%5.2f stare %d podea=%7.2f masina y=%7.2f local=(%+.2f,%+.2f,%+.2f) roti %d la bord=%s"
				% [_hazard.cycle_time(), st, _hazard.floor_y(),
				car.global_position.y, local.x - anchor.x, local.y - anchor.y,
				local.z - anchor.z, car.wheels_on_ground,
				str(_hazard.aboard().has(car))])
		if seen_top and st == BalloonScript.State.JOS:
			break
	var end_local := body.to_local(car.global_position)
	print("    #%d: sus y=%.2f (podea %.2f) | abatere %.3f m, dy [%+.2f,%+.2f], |vy|rel %.2f (capete %.2f), sol_err %.3f, cadre off %d, index %d"
		% [trial, y_at_top, _hazard.top_y(), drift, lo, hi, rel_vy, top_rel,
		gv_err, off, car.road_index])
	car.queue_free()
	await get_tree().physics_frame
	return {
		"drift": drift, "rel_vy": rel_vy, "gv_err": gv_err, "off": off,
		"dy_lo": lo, "dy_hi": hi, "arrived": arrived, "top_rel_vy": top_rel,
	}


# ------------------------------------------------------------- (iv) impingerea

## Masina STA in banda, oprita, exact unde iese cosul. Cosul urca prin ea.
## Intrebarea nu e „supravietuieste", ci „e impinsa sau teleportata": se
## masoara cea mai mare deplasare intr-un SINGUR cadru fizic.
func _check_push() -> void:
	print("--- (iv) masina oprita in banda, cosul urca prin ea")
	# Balonul de pe fundul vaii nu ajunge in banda (vezi (vi)), deci impingerea
	# se masoara pe unul ancorat pe o POLITA a falezei, exact la buza — adica
	# geometria pe care o CERE brief-ul, nu cea pe care o da rapa acum.
	_lane_hazard = _make_hazard(0.0)
	var lane_pt := _lane_edge_point()
	_lane_hazard.name = "BalonPolita"
	# Cursa scurta si tarusul SUS, pe o polita imaginara chiar sub buza: la
	# marginea asfaltului terenul e solid pana la cota drumului, deci un cos
	# care ar porni din vale s-ar ridica prin pamant (masurat: nu se misca
	# deloc, e blocat). Aici intereseaza ULTIMII metri — cei in care cosul
	# apare in banda si atinge masina — nu cei 30 de dedesubt.
	# Cursa se opreste cu podeaua PESTE cota benzii (LANE_OVERSHOOT): un cos
	# care se opreste exact la cota drumului nu ridica pe nimeni — soseste la
	# nivelul rotilor si atat (masurat: ridica 0.10 m). Ca sa fie platforma
	# pe care „poti ateriza" din brief, podeaua trebuie sa treaca de asfalt.
	_lane_hazard.height = LANE_HAZARD_RISE
	_lane_hazard.position = Vector3(lane_pt.x,
		LANE_Y + LANE_OVERSHOOT - LANE_HAZARD_RISE, lane_pt.z)
	add_child(_lane_hazard)
	await get_tree().physics_frame
	print("    balon pe polita: tarus la (%.1f, %.1f), cursa %.1f m (ultimii metri, cei din banda)"
		% [lane_pt.x, lane_pt.z, LANE_HAZARD_RISE])
	print("    podeaua se opreste la y=%.2f, adica %.2f m PESTE cota benzii"
		% [LANE_Y + LANE_OVERSHOOT, LANE_OVERSHOOT])
	await _wait_state_of(_lane_hazard, BalloonScript.State.JOS)
	while _lane_hazard.cycle_time() > 1.0:
		await get_tree().physics_frame
	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(car)
	car.apply_data(GameState.CAR_DATA[0])
	car.track = _track
	# PE ASFALT, la marginea dinspre vale — acolo ajunge cosul cand intra in
	# banda. (Pe tarus masina ar sta in gol si ar cadea in rapa inainte sa vina
	# cosul: masurat in runda 2, cadea 21 m si masuram cadere, nu impingere.)
	var at := _lane_edge_point() + Vector3.UP * 0.6
	car.global_transform = Transform3D(Basis(Vector3.UP, -PI * 0.5), at)
	car.velocity = Vector3.ZERO
	car.route = 0
	car.road_index = _track.closest_index_global(at, 0)
	car.last_safe_index = car.road_index
	car.last_safe_route = 0
	car.race_active = true
	car.set_controller(ProbeDriver.new())
	for _f in 60:
		await get_tree().physics_frame
	var start := car.global_position
	var prev := car.global_position
	var max_step := 0.0
	var max_v := 0.0
	var max_y := car.global_position.y
	var contact_seen := false
	# Rastimpul de jos + urcarea + statul sus: ceasul porneste la inceputul
	# ciclului, deci `ground_hold` intra si el in buget (in prima rulare
	# lipsea, si cosul inca era la -9 m cand se termina masuratoarea).
	var frames := int((GROUND_HOLD + RISE_TIME + HOLD + 1.0) * 60.0)
	var lifted := false
	for i in frames:
		await get_tree().physics_frame
		var step := car.global_position.distance_to(prev)
		prev = car.global_position
		# Contactul incepe cand podeaua ajunge sub masina.
		if _lane_hazard.floor_y() > start.y - 1.2:
			contact_seen = true
			max_step = maxf(max_step, step)
			max_v = maxf(max_v, car.velocity.length())
		max_y = maxf(max_y, car.global_position.y)
		if car.global_position.y > start.y + 0.4:
			lifted = true
		if i % 120 == 0:
			print("    t=%5.1f podea y=%6.2f | masina %s v=%5.2f pas/cadru %.3f m"
				% [_lane_hazard.cycle_time(), _lane_hazard.floor_y(),
				str(car.global_position.snapped(Vector3.ONE * 0.01)),
				car.velocity.length(), step])
	var moved := car.global_position - start
	print("    deplasare totala %s (%.2f m), y max %.2f, viteza max %.2f m/s"
		% [str(moved.snapped(Vector3.ONE * 0.01)), moved.length(), max_y, max_v])
	print("    cel mai mare pas intr-UN cadru: %.3f m (la 60 Hz asta e %.1f m/s)"
		% [max_step, max_step * 60.0])
	print("    ridicata de cos: %s (y de la %.2f la %.2f)" % [str(lifted), start.y, max_y])
	_verdict(contact_seen, "cosul chiar a ajuns la masina")
	_verdict(lifted, "cosul chiar a ridicat masina (y max %.2f, plecare %.2f)" % [max_y, start.y])
	_verdict(max_step < MAX_STEP,
		"e miscata cu masa, nu teleportata (pas max %.3f < %.1f m pe cadru)"
		% [max_step, MAX_STEP])
	# NU se cere o deplasare minima: un cos care ridica masina curat si o pune
	# inapoi o misca putin, si asta e purtare buna, nu esec. Ce n-are voie sa
	# faca e s-o ARUNCE — deci cifra de verdict e viteza, nu distanta.
	_verdict(max_v < 12.0,
		"cosul n-o catapulteaza cand intra sub ea (viteza max %.2f < 12 m/s)" % max_v)
	print("    (deplasarea de %.2f m e informativa: un cos care ridica si asaza curat"
		% moved.length())
	print("     misca putin — pedeapsa e locul pierdut, nu o azvarlire.)")
	car.queue_free()
	await get_tree().physics_frame


# --------------------------------------------------------------- (v) defazarea

## Trei baloane la 0, 1/3, 2/3 din perioada: ferestrele in care cosul fiecaruia
## e in banda. Analitic din `lane_window` (exact, fara zgomot de fizica), plus
## verificarea suprapunerii.
func _check_phasing() -> void:
	print("--- (v) defazarea: 3 baloane la 0, 1/3, 2/3 din ciclul de %.0f s" % PERIOD)
	# Fereastra se cere hazardului VIU (are `_base_y` din `_ready`); un nod
	# proaspat `new()` are baza 0 si raspunde „mereu in banda".
	var w := _hazard.lane_window(LANE_Y, 1.0)
	if w.x < 0.0:
		_verdict(false, "cosul nu ajunge niciodata in banda")
		return
	var dur := w.y - w.x
	print("    fereastra unui balon (podeaua peste banda-1 m): %.2f .. %.2f s din ciclu (%.2f s)"
		% [w.x, w.y, dur])
	var windows: Array[Vector2] = []
	for k in 3:
		var off := float(k) / 3.0 * PERIOD
		windows.append(Vector2(fposmod(w.x + off, PERIOD), fposmod(w.y + off, PERIOD)))
		print("      balon %d (faza %.2f): %.2f .. %.2f s"
			% [k, float(k) / 3.0, windows[k].x, windows[k].y])
	# Suprapunerea, pe cerc: se esantioneaza ciclul si se numara cati sunt in
	# banda in fiecare clipa. Asta e ce SIMTE jucatorul, nu aritmetica de capete.
	var steps := 2800
	var both := 0
	var any := 0
	var max_at_once := 0
	for i in steps:
		var t := float(i) / float(steps) * PERIOD
		var c := 0
		for k in 3:
			if _in_window(t, windows[k]):
				c += 1
		max_at_once = maxi(max_at_once, c)
		if c > 0:
			any += 1
		if c > 1:
			both += 1
	var frac_any := float(any) / float(steps)
	var frac_both := float(both) / float(steps)
	print("    din ciclu: %.1f%% cu cel putin un cos in banda, %.1f%% cu doua sau mai multe; maxim simultan %d"
		% [100.0 * frac_any, 100.0 * frac_both, max_at_once])
	print("    distanta dintre inceputurile a doua ferestre vecine: %.2f s (durata unei ferestre %.2f s)"
		% [PERIOD / 3.0, dur])
	_verdict(max_at_once < 3, "nu blocheaza toate trei deodata (maxim %d)" % max_at_once)
	# Cifra care decide daca 1/3 e defazarea potrivita: fereastra trebuie sa fie
	# mai scurta decat pasul de faza, altfel doua cosuri sunt sus in acelasi
	# timp — iar brief-ul le vrea ca ritm, nu ca zid.
	_verdict(dur < PERIOD / 3.0,
		"fereastra (%.2f s) incape in pasul de faza (%.2f s), deci coliziile de ciclu nu se cumuleaza"
		% [dur, PERIOD / 3.0])
	print("    NOTA: ferestrele de mai sus sunt pentru „podeaua peste banda-1 m\", adica")
	print("    cat timp cosul e o platforma pe care se poate ateriza. Statul sus e %.0f s din ele." % HOLD)


func _in_window(t: float, w: Vector2) -> bool:
	if w.x <= w.y:
		return t >= w.x and t <= w.y
	return t >= w.x or t <= w.y


# ------------------------------------------------------------------- ajutoare

func _stat(label: String, vals: Array[float]) -> void:
	if vals.is_empty():
		return
	var sum := 0.0
	for v in vals:
		sum += v
	print("    %-42s min %7.3f  media %7.3f  max %7.3f  (n=%d)"
		% [label, _min(vals), sum / float(vals.size()), _max(vals), vals.size()])


func _min(vals: Array[float]) -> float:
	var m := INF
	for v in vals:
		m = minf(m, v)
	return m


func _max(vals: Array[float]) -> float:
	var m := -INF
	for v in vals:
		m = maxf(m, v)
	return m
