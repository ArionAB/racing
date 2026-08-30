extends Node
## Sonda ELICEI din stanca goala (Cappadocia §2 POI G, §7.1b): pista trece
## peste ea insasi de DOUA ori, nu o data, si nu pe o dreapta ci pe un cerc.
##
## De ce nu ajunge ProbeOverpass: acolo tablierul traverseaza etajul de jos
## perpendicular, deci punctele stivuite sunt cateva. Pe elice cele doua ture
## sunt suprapuse pe TOATA lungimea, la 19 m una peste alta, iar diferenta de
## index intre ele e de ~59 de puncte coapte (~176 m de arc) — adica FIX
## dincolo de fereastra locala de cautare (-8..+24 puncte, ~72 m). Aici se
## vede daca mecanismul tine sau doar parea sa tina.
##
##  (0)   GEOMETRIA: panta medie si maxima a elicei, si separarea verticala
##        MINIMA masurata intre ture. Briefing-ul afirma ~11% si 19 m/tura —
##        se verifica pe punctele COAPTE, nu pe formula.
##  (iv)  ETAJELE: intrebat despre indexul spirei de JOS, un punct aflat pe
##        spira de SUS raspunde „nu sunt pe drumul asta". Testul care separa
##        cele doua ramuri ale lui Track.is_on_road (vezi --no-width).
##  (i)   TERENUL: sub tura de sus, terenul ramane la cota turei de jos (nu
##        urca dupa ea). A/B cu --no-fix, martorul fara custom_overpass_ranges.
##  (ii)  INDEXUL: o masina cazuta de pe tura de sus pe cea de jos, tinand
##        inca indexul de sus, si-l muta pe tura de jos in sub 1 s si NU isi
##        innoieste checkpoint-ul sus. Control: pe tura de sus ramane sus.
##  (iii) REPUNEREA: dupa cadere, repunerea vine pe tura pe care ai cazut.
##
## Ruleaza CA SCENA (masina cere autoload-urile):
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeHelix.tscn
##   ... -- [--no-fix] [--no-width]
##
## `--no-width` scoate `custom_width_segments`. NU e cosmetic: cu profil de
## latime declarat, Track.is_on_road ia ramura care compara doar LATERAL (2D)
## si sare peste `is_other_level` — vezi track.gd:9998. Cappadocia are latimi
## pe POI (6..9 m), deci pista reala VA avea profil; implicit sonda testeaza
## calea cu profil, iar `--no-width` e martorul care arata ca diferenta e din
## profil, nu din elice.
##
## Iese cu cod 1 la orice verdict picat.

const CAR_SCENE: String = "res://scenes/cars/Car.tscn"

# --- elicea din brief (§2 POI G) -------------------------------------------
## Raza rampei elicoidale sapate in peretele stancii goale.
const HELIX_RADIUS: float = 28.0
## Cate ture complete face rampa inainte de gura de sus.
const HELIX_TURNS: float = 2.0
const HELIX_Y0: float = 12.0
const HELIX_Y1: float = 50.0
## Puncte de control PE TURA. La 12 puncte pe tura coarda e de 14.5 m pe o
## raza de 28 — sub jumatatea razei, deci Catmull-Rom nu strange curba (vezi
## memoria "viraje stranse: puncte pe arc").
const PTS_PER_TURN: int = 12
## Latimea rampei din brief pentru POI G.
const HELIX_HALF_WIDTH: float = 3.0
## Latimea platoului de intoarcere (POI A, 9 m latime = 4.5 half).
const PLATEAU_HALF_WIDTH: float = 4.5
## Raza buclei de intoarcere. Aleasa ca sa nu se apropie de axa elicei sub
## 32 m — cilindrul stancii are 28, deci raman 4.5 m de garda.
const RETURN_RADIUS: float = 95.0

## De la ce diferenta de cota doua puncte apropiate in plan sunt ETAJE.
## Acelasi prag ca ProbeLayout.STACK_MIN_DY, si din acelasi motiv: peste
## TrackRoute.ROAD_ABOVE_TOLERANCE (12 m), cu marja.
const STACK_MIN_DY: float = 14.0
## Cat de aproape in plan (XZ) trebuie sa fie doua puncte ca sa fie "una peste
## alta". O tura de elice sta exact deasupra celeilalte, deci pragul e mic.
const STACK_MAX_XZ: float = 6.0
## Cate puncte coapte se sar cand se cauta cealalta tura (vecinii imediati
## sunt normal aproape). ~30 puncte = 90 m de arc, sub jumatatea unei ture.
const SELF_SKIP: int = 30
const SETTLE_SECONDS: float = 1.5

var _no_fix: bool = false
var _no_width: bool = false
var _track: TrackFromPath
## Indicii perechii stivuite cu separarea verticala cea mai MICA: cel mai greu
## caz pentru testul "pe sosea".
var _lo_i: int = -1
var _hi_i: int = -1
var _min_dy: float = INF
var _fails: int = 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_no_fix = "--no-fix" in args
	_no_width = "--no-width" in args
	_track = TrackFromPath.new()
	var path := Path3D.new()
	path.name = "Path"
	var curve := Curve3D.new()
	for p in _helix_points():
		curve.add_point(p)
	path.curve = curve
	_track.add_child(path)
	_track.custom_name = "ProbeHelix"
	_track.custom_theme = "desert"
	_track.custom_half_width = HELIX_HALF_WIDTH
	add_child(_track)
	await get_tree().process_frame
	if not _no_width:
		# Profilul real al Cappadociei, simplificat: rampa 6 m (POI G),
		# platoul 9 m (POI A'). Vezi antetul pentru ce schimba.
		_track.custom_width_segments = _width_segments()
		_track.rebuild()
		await get_tree().process_frame
	_find_stack()
	if not _no_fix:
		_track.custom_overpass_ranges = _deck_ranges()
		_track.rebuild()
		await get_tree().process_frame
		_find_stack()

	print("=== ELICEA DIN STANCA GOALA (%s%s) ==="
		% ["FARA fix, martor" if _no_fix else "cu pasaj",
		", fara profil de latime" if _no_width else ", cu profil de latime"])
	print("  pista %.1f m, %d puncte coapte, half_width %.1f"
		% [_track.curve.get_baked_length(), _track.baked.size(),
		_track.half_width])
	_check_geometry()
	_check_levels()
	_check_terrain()
	await _check_fall()
	await _check_stay()
	await _check_respawn()
	print("=== %s ===" % ("PICAT: %d verdicte" % _fails if _fails > 0 else "TOATE OK"))
	get_tree().quit(1 if _fails > 0 else 0)


# ------------------------------------------------------------------ traseul

## Traseul-test: elicea din brief, plus intoarcerea care o inchide in bucla.
##
## O elice singura nu e o pista: pista e o BUCLA inchisa, deci dupa ce urci
## 12 -> 50 trebuie sa cobori inapoi la 12. Intoarcerea e un cerc mare cu
## centrul mutat spre est, tangent la elice in punctul de iesire — asa
## coboara lin si NU reintra niciodata in cilindrul stancii (se verifica:
## nu se apropie de axa la mai putin de 32 m, cu cilindrul la 28). Daca
## intoarcerea ar trece pe deasupra ei insasi, ar adauga perechi stivuite
## care nu sunt ale elicei si masuratoarea (0) ar minti.
##
## Distantele intre puncte se tin EGALE (~14.6 m, coarda de 12 puncte pe tura
## la raza 28): Catmull-Rom strange curba cand punctele sunt inegal spatiate
## — vezi memoria „viraje stranse: puncte pe arc".
func _helix_points() -> Array[Vector3]:
	var pts: Array[Vector3] = []
	var n := int(HELIX_TURNS * float(PTS_PER_TURN))
	# Elicea. Punctul t = 1.0 NU se adauga: ar cadea peste primul punct al
	# intoarcerii si ar face o coarda de zero.
	for i in n:
		var t := float(i) / float(n)
		var a := TAU * HELIX_TURNS * t
		pts.append(Vector3(
			HELIX_RADIUS * cos(a),
			lerpf(HELIX_Y0, HELIX_Y1, t),
			HELIX_RADIUS * sin(a)))
	# Intoarcerea: cerc de raza RETURN_RADIUS cu centrul la est, care atinge
	# gura elicei (HELIX_RADIUS, *, 0). Se parcurge in sens invers acelor de
	# ceasornic in unghi (deci ORAR in plan), ca sa iasa din elice pe aceeasi
	# directie (+Z) si sa reintre tot pe ea.
	var cx := HELIX_RADIUS + RETURN_RADIUS
	var chord := 2.0 * HELIX_RADIUS * sin(PI / float(PTS_PER_TURN))
	var steps := int(round(TAU / (2.0 * asin(minf(1.0, chord / (2.0 * RETURN_RADIUS))))))
	for k in range(1, steps):
		var a := PI - float(k) * TAU / float(steps)
		pts.append(Vector3(
			cx + RETURN_RADIUS * cos(a),
			lerpf(HELIX_Y1, HELIX_Y0, float(k) / float(steps)),
			RETURN_RADIUS * sin(a)))
	return pts


## Sectoarele de latime: rampa ingusta pe elice, platou lat pe intoarcere.
## Fractiile se iau dupa lungimea de arc, deci se deriva din pista deja
## construita — nu se ghicesc.
func _width_segments() -> Array[Vector3]:
	var n := _track.baked.size()
	var last_helix := -1
	for i in n:
		if _is_helix_index(i):
			last_helix = i
	if last_helix < 0:
		return []
	var f_end := _track.frac_at(last_helix)
	return [
		Vector3(0.0, f_end, HELIX_HALF_WIDTH),
		Vector3(f_end, 1.0, PLATEAU_HALF_WIDTH),
	]


## E punctul COPT dat pe elice, sau pe bucla de intoarcere?
##
## Testul e pe LUNGIME DE ARC, nu pe raza. Raza minte la capete: bucla de
## intoarcere se racordeaza tangent la gura stancii, deci primele si ultimele
## ei puncte sunt la 32 m de axa — la 4 m in afara cilindrului de 28, dar cu
## totul in dreptul lui. Cu prag pe raza, punctul 199 (aflat la 365 m pe
## traseu, adica DUPA cele 354 m ale elicei) trecea drept „spira" si sonda
## raporta separarea buclei fata de elice pe post de separare intre ture.
## Arcul nu are ambiguitatea asta: elicea e exact prima portiune a traseului.
func _is_helix_index(i: int) -> bool:
	var n := _track.baked.size()
	if n == 0:
		return false
	return _track.frac_at(i) * _track.curve.get_baked_length() < _helix_arc()


## Lungimea 3D a elicei: doua ture de cerc de raza 28, plus urcarea.
func _helix_arc() -> float:
	var horiz := TAU * HELIX_RADIUS * HELIX_TURNS
	return sqrt(horiz * horiz + (HELIX_Y1 - HELIX_Y0) * (HELIX_Y1 - HELIX_Y0))


## Sunt cele doua puncte coapte una peste alta — si AMANDOUA pe elice?
##
## Restrictia la elice nu e cosmetica. Bucla de intoarcere a pistei-test se
## racordeaza la gura stancii, deci trece inevitabil pe langa spira de jos si
## produce perechi stivuite care NU sunt ale elicei. Daca ar intra in
## masuratoare, sonda ar raporta separarea dintre intoarcere si elice in loc
## de cea dintre ture — adica exact cifra pe care briefing-ul o afirma. Le
## numaram separat si le tiparim, ca sa nu dispara tacut.
func _stacked(i: int, j: int, helix_only: bool) -> bool:
	var n := _track.baked.size()
	var d := absi(j - i)
	if mini(d, n - d) < SELF_SKIP:
		return false
	var p: Vector3 = _track.baked[i]
	var q: Vector3 = _track.baked[j]
	if p.y - q.y < STACK_MIN_DY:
		return false
	if Vector2(p.x - q.x, p.z - q.z).length() >= STACK_MAX_XZ:
		return false
	if helix_only and (not _is_helix_index(i) or not _is_helix_index(j)):
		return false
	return true


## Intervalele de pasaj: punctele care au ALT DRUM sub ele.
##
## Pe un flyover drept intervalul e evident (tablierul). Pe elice nu: spira de
## sus e deasupra celei de jos pe TOATA lungimea ei, deci intervalul e „de la
## primul punct care are ceva sub el pana la ultimul". Se deriva din punctele
## COAPTE, ca in probe_overpass._deck_range() — cu deosebirea ca aici intra si
## racordul buclei de intoarcere, fiindca si el trece peste drum si terenul
## trebuie sa-l ignore la fel.
func _deck_ranges() -> Array[Vector2]:
	var n := _track.baked.size()
	var first := -1
	var last := -1
	var count := 0
	var over := PackedByteArray()
	over.resize(n)
	over.fill(0)
	for i in n:
		for j in n:
			if _stacked(i, j, false):
				over[i] = 1
				break
		if over[i] == 1:
			count += 1
			if first < 0:
				first = i
			last = i
	if first < 0:
		print("  pasaj: NICIUN punct nu trece peste altul (?!)")
		return []
	# Multimea „am drum sub mine" nu e neaparat UN interval: se tiparesc toate
	# rulajele ei, fiindca `custom_overpass_ranges` cere intervale, si daca
	# rulajele nu se leaga intr-unul singur, un interval unic mascheaza si
	# puncte care STAU pe pamant si trebuie sa traga terenul.
	print("  pasaj: rulaje de puncte cu drum sub ele: %s" % str(_runs(over)))
	var f0 := _track.frac_at(first)
	var f1 := _track.frac_at(last)
	print("  pasaj: indici %d..%d, fractii %.3f..%.3f (%d puncte cu drum sub ele)"
		% [first, last, f0, f1, count])
	return [Vector2(f0, f1)]


## Rulajele contigue de „true" dintr-o masca, ca text: [a..b, c..d].
func _runs(mask: PackedByteArray) -> Array:
	var out: Array = []
	var i := 0
	var n := mask.size()
	while i < n:
		if mask[i] == 0:
			i += 1
			continue
		var a := i
		while i < n and mask[i] == 1:
			i += 1
		out.append("%d..%d" % [a, i - 1])
	return out


## Perechea de SPIRE stivuite cu separarea verticala cea mai MICA: cazul cel
## mai greu pentru testul „pe sosea". Se numara si perechile de la racordul
## buclei de intoarcere, dar NU intra in verdict — vezi _stacked().
func _find_stack() -> void:
	var n := _track.baked.size()
	_min_dy = INF
	_lo_i = -1
	_hi_i = -1
	var off_helix := 0
	for i in n:
		for j in n:
			if _stacked(i, j, false) and not _stacked(i, j, true):
				off_helix += 1
			if not _stacked(i, j, true):
				continue
			var dy: float = _track.baked[i].y - _track.baked[j].y
			if dy < _min_dy:
				_min_dy = dy
				_hi_i = i
				_lo_i = j
	if off_helix > 0:
		print("  (%d perechi stivuite in afara elicei — racordul buclei de intoarcere, ignorate in (0))"
			% off_helix)


func _verdict(ok: bool, text: String) -> void:
	print("  [%s] %s" % ["OK" if ok else "PICAT", text])
	if not ok:
		_fails += 1


# ------------------------------------------------------------------ (0)

func _check_geometry() -> void:
	print("--- (0) geometria elicei (brief: ~11% panta, 19 m/tura, >= 12 m separare)")
	var n := _track.baked.size()
	# Panta pe punctele coapte, doar pe portiunea de elice.
	var sum_rise := 0.0
	var sum_run := 0.0
	var max_slope := 0.0
	var max_at := 0.0
	var helix_pts := 0
	for i in n:
		if not _is_helix_index(i) or not _is_helix_index((i + 1) % n):
			continue
		var a: Vector3 = _track.baked[i]
		var b: Vector3 = _track.baked[(i + 1) % n]
		helix_pts += 1
		var run := Vector2(b.x - a.x, b.z - a.z).length()
		var rise := b.y - a.y
		if run < 0.01:
			continue
		sum_rise += rise
		sum_run += run
		var s := absf(rise) / run
		if s > max_slope:
			max_slope = s
			max_at = _track.frac_at(i)
	var avg := (sum_rise / sum_run) if sum_run > 0.01 else 0.0
	var pitch := sum_rise / HELIX_TURNS
	print("    elice: %d segmente coapte, %.1f m parcurs orizontal, %.1f m urcare"
		% [helix_pts, sum_run, sum_rise])
	print("    pas pe tura     %.2f m  (brief: 19 m/tura)" % pitch)
	print("    panta MEDIE   %.1f %%   (brief: ~11%%)" % (avg * 100.0))
	# Panta maxima cade la inceputul elicei: acolo Catmull-Rom leaga ultimul
	# punct al buclei de intoarcere (care coboara) de primul al elicei (care
	# urca), si racordul e mai abrupt decat oricare dintre ele. E o cusatura a
	# pistei-test, nu a elicei — de aceea se tipareste si panta pe MIJLOCUL
	# elicei, departe de ambele capete.
	print("    panta MAXIMA  %.1f %% la frac %.2f   (ProbeLayout taie la 22%%)"
		% [max_slope * 100.0, max_at])
	var mid_max := 0.0
	for i in n:
		if not _is_helix_index(i) or not _is_helix_index((i + 1) % n):
			continue
		var f := _track.frac_at(i) * _track.curve.get_baked_length() / _helix_arc()
		if f < 0.15 or f > 0.85:
			continue
		var a2: Vector3 = _track.baked[i]
		var b2: Vector3 = _track.baked[(i + 1) % n]
		var run2 := Vector2(b2.x - a2.x, b2.z - a2.z).length()
		if run2 > 0.01:
			mid_max = maxf(mid_max, absf(b2.y - a2.y) / run2)
	print("    panta maxima pe MIJLOCUL elicei (15%%..85%%)  %.1f %%   (fara cusaturi)"
		% (mid_max * 100.0))
	# Separarea verticala minima intre ture, masurata pe puncte coapte.
	if _lo_i >= 0:
		var hi: Vector3 = _track.baked[_hi_i]
		var lo: Vector3 = _track.baked[_lo_i]
		print("    separare verticala MINIMA intre ture: %.2f m (sus [%d] y=%.2f, jos [%d] y=%.2f, dXZ=%.2f m)"
			% [_min_dy, _hi_i, hi.y, _lo_i, lo.y,
			Vector2(hi.x - lo.x, hi.z - lo.z).length()])
		print("    distanta de INDEX intre ture: %d puncte = %.0f m de arc (fereastra locala e -8..+24)"
			% [absi(_hi_i - _lo_i), absi(_hi_i - _lo_i) * _track.curve.bake_interval])
	_verdict(_lo_i >= 0, "elicea chiar trece peste ea insasi (s-a gasit o pereche stivuita)")
	_verdict(max_slope <= 0.22, "panta maxima sub pragul ProbeLayout (%.1f %% <= 22 %%)"
		% (max_slope * 100.0))
	_verdict(_min_dy >= TrackRoute.ROAD_ABOVE_TOLERANCE,
		"separarea minima trece de toleranta verticala pe sosea (%.2f m >= %.1f m)"
		% [_min_dy, TrackRoute.ROAD_ABOVE_TOLERANCE])


# ------------------------------------------------------------------ (iv)

## Un punct de pe spira de SUS, intrebat despre indexul spirei de JOS.
##
## Aici se desparte codul de el insusi. [method Track.is_on_road] are doua
## ramuri (track.gd:9998):
##   - fara profil de latime cheama [method TrackRoute.is_on_road], care e
##     lateral SI vertical (`is_other_level`);
##   - cu profil de latime compara doar `lateral_distance`, care e 2D prin
##     definitie — deci raspunde „da, esti pe drumul de jos" unei masini
##     aflate 17 m mai sus, pe spira urmatoare.
##
## Pe un pasaj drept nu se vedea: acolo etajul de sus e un tablier scurt si
## masina care il tine nu are motive sa fie intrebata despre etajul de jos.
## Pe elice cele doua spire stau una peste alta pe toata lungimea, iar
## checkpoint-ul (car.gd:530) se innoieste EXACT prin testul asta. Cappadocia
## are latimi pe POI (6..9 m), deci VA avea profil.
func _check_levels() -> void:
	print("--- (iv) etajele: un punct de pe spira de sus, intrebat despre indexul spirei de jos")
	var hi: Vector3 = _track.baked[_hi_i]
	var lo: Vector3 = _track.baked[_lo_i]
	var route: TrackRoute = _track.route_at(0)
	var d_lat := route.lateral_distance(_lo_i, hi)
	var other := route.is_other_level(_lo_i, hi)
	var via_route := route.is_on_road(_lo_i, hi)
	var via_track := _track.is_on_road(_lo_i, hi)
	print("    punct de sus %s, index de jos %d (y=%.2f), dy=%+.2f m, lateral=%.2f m"
		% [str(hi.round()), _lo_i, lo.y, hi.y - lo.y, d_lat])
	print("    TrackRoute.is_other_level = %s   TrackRoute.is_on_road = %s   Track.is_on_road = %s"
		% [str(other), str(via_route), str(via_track)])
	var w := _track.width_at_index(_lo_i)
	print("    profil de latime: %s, latimea la indexul de jos %.2f m (prag lateral %.2f m)"
		% ["NU (lista goala)" if _no_width else "DA", w, w + 0.5])
	# Cat de aproape a fost de a raspunde GRESIT: daca separarea laterala
	# scade sub pragul de latime, ramura 2D zice „da" indiferent de cei 17 m.
	print("    marja pana la raspunsul gresit: %.2f m lateral (dy nu conteaza pe ramura cu profil)"
		% (d_lat - (w + 0.5)))
	_verdict(other, "TrackRoute stie ca e alt etaj")
	_verdict(not via_route, "TrackRoute.is_on_road spune NU (lateral + vertical)")
	_verdict(not via_track,
		"Track.is_on_road spune NU — daca PICA, ramura cu profil de latime e 2D si sare peste is_other_level")

	# CAZUL CEL MAI RAU, si el nu e teoretic: cele doua spire au ACEEASI raza,
	# deci axa uneia trece exact pe deasupra axei celeilalte. Cei 5.81 m de mai
	# sus sunt doar defazajul de esantionare al punctelor coapte, nu o
	# departare reala. O masina care merge pe spira de sus fix deasupra unui
	# punct al spirei de jos are lateral ZERO — si atunci singurul lucru care
	# o mai poate scoate de pe „drumul de jos" e testul VERTICAL.
	var straight_up := lo + Vector3.UP * (hi.y - lo.y)
	var up_route := route.is_on_road(_lo_i, straight_up)
	var up_track := _track.is_on_road(_lo_i, straight_up)
	print("    fix deasupra punctului de jos (lateral 0.00 m, dy=%+.2f m):" % (hi.y - lo.y))
	print("      TrackRoute.is_on_road = %s   Track.is_on_road = %s"
		% [str(up_route), str(up_track)])
	_verdict(not up_route,
		"TrackRoute.is_on_road spune NU si cu lateral zero (testul vertical isi face treaba)")
	_verdict(not up_track,
		"Track.is_on_road spune NU si cu lateral zero — AICI se vede daca ramura cu profil de latime e oarba pe verticala")


# ------------------------------------------------------------------ (i)

func _check_terrain() -> void:
	print("--- (i) terenul sub tura de sus")
	var sampler: TrackSideSampler = _track.get("_sampler")
	var n := _track.baked.size()
	var buried := 0.0
	var lifted := 0.0
	for off in range(-6, 7):
		var i := posmod(_lo_i + off, n)
		var p: Vector3 = _track.baked[i]
		var g := sampler.ground_y(p.x, p.z)
		buried = maxf(buried, g - p.y)
		if off % 3 == 0:
			print("    tura de jos [%3d] drum %.2f teren %.2f  diff %+.2f"
				% [i, p.y, g, g - p.y])
	for off in range(-6, 7):
		var i := posmod(_hi_i + off, n)
		var p: Vector3 = _track.baked[i]
		var g := sampler.ground_y(p.x, p.z)
		lifted = maxf(lifted, g - _track.baked[_lo_i].y)
		if off % 3 == 0:
			print("    tura de sus [%3d] rampa %.2f teren %.2f  gol %.2f"
				% [i, p.y, g, p.y - g])
	# Terenul sta cu ~0.3 m sub buza asfaltului (GROUND_DROP); peste +0.15
	# inseamna asfalt ingropat.
	_verdict(buried <= 0.15, "tura de jos nu e ingropata (max teren-drum %+.2f m)" % buried)
	_verdict(lifted <= 1.0, "terenul de sub tura de sus ramane la cota turei de jos (max +%.2f m)" % lifted)


# ------------------------------------------------------------------ (ii)

func _spawn(at: Vector3, index: int) -> Car:
	var car := (load(CAR_SCENE) as PackedScene).instantiate() as Car
	add_child(car)
	car.apply_data(GameState.CAR_DATA[0])
	car.track = _track
	car.global_transform = Transform3D(Basis.IDENTITY, at)
	car.velocity = Vector3.ZERO
	car.route = 0
	car.road_index = index
	car.last_safe_index = index
	car.last_safe_route = 0
	car.race_active = true
	return car


func _settle() -> void:
	for _f in int(SETTLE_SECONDS * 60.0):
		await get_tree().physics_frame


func _check_fall() -> void:
	print("--- (ii) cadere de pe tura de sus pe cea de jos, cu indexul de sus")
	var lo: Vector3 = _track.baked[_lo_i]
	var car := _spawn(lo + Vector3(0, 1.5, 0), _hi_i)
	await _settle()
	var d := absi(car.road_index - _lo_i)
	var on_lo := _track.is_on_road(car.road_index, car.global_position)
	var safe_d := absi(car.last_safe_index - _lo_i)
	var safe_hi := absi(car.last_safe_index - _hi_i)
	print("    index %d (jos e %d, sus e %d), y=%.2f, pe sosea=%s, safe=%d"
		% [car.road_index, _lo_i, _hi_i, car.global_position.y, str(on_lo),
		car.last_safe_index])
	_verdict(d <= 6, "indexul s-a mutat pe tura de jos (|delta|=%d)" % d)
	_verdict(on_lo, "e „pe sosea” pe tura de jos")
	_verdict(safe_d <= 6 and safe_hi > 6,
		"checkpoint-ul e pe tura de jos, nu pe cea de sus (|delta jos|=%d, |delta sus|=%d)"
		% [safe_d, safe_hi])
	car.queue_free()
	await get_tree().process_frame


func _check_stay() -> void:
	print("--- (ii-b) control: pe tura de sus, cu indexul ei")
	var hi: Vector3 = _track.baked[_hi_i]
	var car := _spawn(hi + Vector3(0, 1.0, 0), _hi_i)
	await _settle()
	var d := absi(car.road_index - _hi_i)
	var on_hi := _track.is_on_road(car.road_index, car.global_position)
	print("    index %d (sus e %d), y=%.2f, pe sosea=%s"
		% [car.road_index, _hi_i, car.global_position.y, str(on_hi)])
	_verdict(d <= 6, "indexul a ramas pe tura de sus (|delta|=%d)" % d)
	_verdict(on_hi, "e „pe sosea” pe tura de sus")
	_verdict(car.global_position.y > hi.y - 1.0,
		"masina sta PE rampa, nu a cazut prin ea (y=%.2f)" % car.global_position.y)
	car.queue_free()
	await get_tree().process_frame


# ------------------------------------------------------------------ (iii)

func _check_respawn() -> void:
	print("--- (iii) repunere dupa cadere")
	var lo: Vector3 = _track.baked[_lo_i]
	var car := _spawn(lo + Vector3(0, 1.5, 0), _hi_i)
	await _settle()
	car.respawn()
	await get_tree().physics_frame
	var y := car.global_position.y
	print("    dupa repunere y=%.2f (jos %.2f, sus %.2f), index %d"
		% [y, lo.y, _track.baked[_hi_i].y, car.road_index])
	_verdict(absf(y - lo.y) < 3.0, "repus pe tura de jos, nu pe cea de sus")
	car.queue_free()
