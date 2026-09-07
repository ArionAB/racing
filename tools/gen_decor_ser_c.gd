extends Node
## Generator de decor MANUAL pentru POI C — VADUL MARA (Track14, frac
## 0.121-0.173, vadul masurat la 0.144). Ca la Cappadocia: nu e sonda, e
## unealta care CALCULEAZA transformarile ce se lipesc in Track14.tscn sub
## `DecorManual/ZoneC_VadulMara`.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorSerC.tscn -- --track=7
##
## Ce decide compozitia, si de ce cifrele sunt astea.
##
## 1. GEOMETRIA REALA A VADULUI (ProbeSerCSurvey, nu brief-ul). Soseaua merge
##    pe z ~ 165 spre -X: la frac 0.110 e la x = 0, la 0.174 la x = -132.
##    `side` e (0, -1), deci lateral POZITIV inseamna z mai MIC (nord, spre
##    peretele craterului) si lateral NEGATIV inseamna z mai MARE (sud, spre
##    campie). Albia coboara de la 0.00 (x = 0) la -1.38 (x = -76) si urca
##    inapoi; apa sta la -1.05, deci vadul ud e x ~ -58 .. -95.
##
## 2. MALURILE SUNT PROP-URI, NU TEREN. Prima incercare a fost sa ridic doua
##    creste de `TerrainPeak` de o parte si de alta a albiei, ca apa sa curga
##    intre ele. Nu se poate, si motivul e in cod, nu in reglaj:
##    `TrackSideSampler._lift_peaks` stinge orice masiv pe banda de protectie a
##    asfaltului — `smoothstep(PEAK_ROAD_CLEAR 6, PEAK_ROAD_FULL 32,
##    dist - half_width)`. La 17 m de ax (half 8) masca iese 0.03, adica trei
##    procente dintr-un munte. Un mal de rau la 10-20 m de sosea e EXACT zona
##    pe care mecanismul asta o apara. Deci malul se face din bolovani si
##    movile de noroi asezate ca obiecte, si terenul ramane cum e.
##
## 3. FRUSTUMUL. Camera de cursa e la 10 m inaltime; un obiect de inaltime h la
##    distanta d intra intreg doar daca h < 10 + 0.093*d. Bolovanii de kopje
##    (3-6 m) incap oriunde; kopje-ul cu leu (13 m pe platou) cere d > 32 m de
##    ax, de aceea sta la 38 m pe latura nordica, unde oricum urca peretele.
##
## 4. DENSITATEA CRESTE SPRE VAD, NU E UNIFORMA (lectia valului 1: un scatter
##    pe grila citeste ca „instante plasate"). Bolovanii se ingramadesc pe
##    ultimii 20 m dinainte de apa si in apa, si se raresc spre capete. Toate
##    piesele primesc jitter de pozitie de cel putin 0.5 din pas si yaw complet
##    aleator, iar razele lor se SUPRAPUN deliberat: in referinta bolovanii se
##    ocluzioneaza intre ei, nu stau la distanta egala.
##
## 5. CROCODILII stau pe MAL, in apa mica, nu pe uscat curat: in referinta sunt
##    intinsi pe namolul de la linia apei, cu botul spre rau. Se aseaza la cota
##    solului, pe ambele maluri, la 12-20 m de ax — destul de aproape ca sa
##    intre in cadru la 5-40 m, destul de departe ca sa nu-i calce nimeni.
##
## 6. NIMIC SOLID PE BANDA. Degajarea minima fata de MUCHIA asfaltului (half,
##    nu ax) e 3 m pentru piese cu corp. Bolovanii din apa stau in albie, dar
##    in afara benzii de trecere: vadul se trece pe mijloc.

const TRACK := "res://scenes/tracks/Track14.tscn"
const ZONE := "DecorManual/ZoneC_VadulMara"

## Numele ext_resource-urilor pre-inregistrate in Track14.tscn (handoff §1).
const RES := {
	"kopje_boulder_a": "s_kopje_boulder_a",
	"kopje_boulder_b": "s_kopje_boulder_b",
	"kopje_boulder_c": "s_kopje_boulder_c",
	"kopje_camp": "s_kopje_camp",
	"kopje_kicker": "s_kopje_kicker",
	"lion_kopje": "s_lion_kopje",
	"crocodile": "s_crocodile",
	"acacia_umbrella_a": "s_acacia_umbrella_a",
	"acacia_umbrella_b": "s_acacia_umbrella_b",
	"acacia_umbrella_c": "s_acacia_umbrella_c",
	"fever_tree": "s_fever_tree",
	"fig_tree": "s_fig_tree",
	"dead_tree": "s_dead_tree",
	"euphorbia": "s_euphorbia",
	"termite_mound_a": "s_termite_mound_a",
	"termite_mound_b": "s_termite_mound_b",
	"carcass_vultures": "s_carcass_vultures",
}

var _track: Track
var _sampler: TrackSideSampler
var _out: Array[String] = []
var _n := 0
var _rng := RandomNumberGenerator.new()
var _terrain_rid := RID()
var _sus_y := 400.0
var _sea_y := 0.0


func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	_sampler = _track._sampler
	_sea_y = _sampler.mean_road_y() + _track.sea_level_offset
	_rng.seed = 140714
	print("; sea_y %.3f" % _sea_y)

	_banks()
	_boulders_in_water()
	_crocodiles()
	_kopje_with_lion()
	_trees()
	_kicker()

	print("")
	for line in _out:
		print(line)
	print("; asezate %d piese" % _n)
	get_tree().quit(0)


## Indexul punctului copt cel mai apropiat de o fractie.
func _idx(frac: float) -> int:
	var n := _track.baked.size()
	return int(frac * float(n)) % n


## MALURILE. Doua siruri de bolovani si movile care insotesc albia, cu
## densitate care creste spre apa. Nu e un tiv: sirul are DOUA randuri
## decalate, iar al doilea rand sta mai departe si mai rar, ca sa se vada
## adancime, nu un gard.
func _banks() -> void:
	var rocks := ["kopje_boulder_a", "kopje_boulder_b", "kopje_boulder_c"]
	var f := 0.124
	while f <= 0.168:
		var i := _idx(f)
		var p: Vector3 = _track.baked[i]
		var half: float = _track.width_at_index(i)
		# Cat de aproape suntem de mijlocul vadului (0.144): 1.0 chiar in vad.
		var near := clampf(1.0 - absf(f - 0.144) / 0.024, 0.0, 1.0)
		for sgn: float in [1.0, -1.0] as Array[float]:
			# Randul din fata: la 3-9 m de muchie, des langa apa.
			var count := 1 + int(round(near * 2.0))
			for k in count:
				var lat := sgn * (half + 3.0 + _rng.randf_range(0.0, 6.0))
				var along := _rng.randf_range(-7.0, 7.0)
				var scl := _rng.randf_range(0.5, 1.15) * (0.75 + 0.45 * near)
				_at(i, lat, along, rocks[_rng.randi() % 3], "Bolovan",
					_rng.randf_range(0.0, TAU), scl, "hull")
			# Randul din spate: mai rar, mai departe, mai mic — adancime.
			if _rng.randf() < 0.55 + 0.3 * near:
				var lat2 := sgn * (half + 11.0 + _rng.randf_range(0.0, 9.0))
				_at(i, lat2, _rng.randf_range(-8.0, 8.0),
					rocks[_rng.randi() % 3], "BolovanFund",
					_rng.randf_range(0.0, TAU), _rng.randf_range(0.4, 0.8),
					"hull")
			# Movile de termite ca accent de noroi uscat pe malul de sus.
			if _rng.randf() < 0.22:
				var m: String = "termite_mound_a" if _rng.randf() < 0.5 \
					else "termite_mound_b"
				_at(i, sgn * (half + 8.0 + _rng.randf_range(0.0, 12.0)),
					_rng.randf_range(-6.0, 6.0), m, "Musuroi",
					_rng.randf_range(0.0, TAU),
					_rng.randf_range(0.7, 1.1), "hull")
		f += 0.0035


## BOLOVANI IN APA. In referinta raul nu e o oglinda goala: sunt pietre care
## rup curentul chiar in albie, si tocmai ele spun ca apa e mica. Stau in afara
## culoarului de trecere (mijlocul benzii ramane liber), pe ultimii metri
## dinspre maluri.
func _boulders_in_water() -> void:
	var rocks := ["kopje_boulder_a", "kopje_boulder_b", "kopje_boulder_c"]
	var f := 0.134
	while f <= 0.156:
		var i := _idx(f)
		var half: float = _track.width_at_index(i)
		for sgn: float in [1.0, -1.0] as Array[float]:
			if _rng.randf() < 0.75:
				# Intre muchia benzii si mal: piatra in apa, nu pe drum.
				var lat := sgn * (half + 0.6 + _rng.randf_range(0.0, 2.2))
				_at(i, lat, _rng.randf_range(-5.0, 5.0),
					rocks[_rng.randi() % 3], "PiatraInApa",
					_rng.randf_range(0.0, TAU),
					_rng.randf_range(0.28, 0.55), "hull")
		f += 0.004


## CROCODILII. Pe namolul de la linia apei, botul spre rau. Trei pe malul
## dinspre camera la intrare (se vad de la 15-30 m) si doi pe malul opus.
func _crocodiles() -> void:
	var spots := [
		# frac, lateral (+ = nord), yaw fata de directia soselei
		[0.1330, 13.5, 0.55],
		[0.1365, -14.5, -0.75],
		[0.1500, 12.0, -0.35],
		[0.1545, -13.0, 0.85],
		[0.1405, -17.0, 0.15],
	]
	for s: Array in spots:
		var i := _idx(float(s[0]))
		_at(i, float(s[1]), _rng.randf_range(-2.0, 2.0), "crocodile",
			"Crocodil", float(s[2]), _rng.randf_range(0.95, 1.15), "hull")


## KOPJE-UL CU LEU. In referinta e masivul de granit din stanga, cu leul pe
## creasta, si de pe el sare masina galbena. Sta pe latura NORDICA (lateral
## pozitiv), unde terenul urca oricum spre peretele craterului, la 38 m de ax:
## la 13 m inaltime frustumul (10 + 0.093*d) il cuprinde de la 32 m in sus.
func _kopje_with_lion() -> void:
	var i := _idx(0.1285)
	_at(i, 38.0, 0.0, "kopje_camp", "KopjeLeu", 2.1, 1.25, "hull")
	# Leul pe platou: fantoma (fara corp), asezat pe kopje, nu pe teren.
	var p: Vector3 = _track.baked[i]
	var s := _track._side_at(i)
	var q := p + s * 38.0
	var g := _sol_real(q.x, q.z)
	_raw("lion_kopje", "Leu", Vector3(q.x, g + 12.4, q.z), 2.4, 1.0, "none")
	# Doi bolovani mari la poalele kopje-ului, ca masivul sa nu para lipit.
	_at(i, 27.0, -9.0, "kopje_boulder_a", "BolovanKopje", 0.9, 1.5, "hull")
	_at(i, 31.0, 8.0, "kopje_boulder_c", "BolovanKopje", 2.7, 1.2, "hull")


## ACACIILE. Pe ambele maluri, cu coroanele care se ating deasupra drumului
## la intrarea si la iesirea din vad — in referinta copacii nu stau in sir, sunt
## in pilcuri, unele foarte aproape de apa.
func _trees() -> void:
	var canopy := ["acacia_umbrella_a", "acacia_umbrella_b",
		"acacia_umbrella_c", "fever_tree", "fig_tree"]
	var spots := [
		[0.1245, 12.0], [0.1260, -13.5], [0.1290, -19.0],
		[0.1315, 15.5], [0.1350, -12.0], [0.1385, 19.0],
		[0.1580, -12.5], [0.1605, 14.0], [0.1630, -18.0],
		[0.1660, 13.0], [0.1690, -15.0], [0.1230, -22.0],
		[0.1560, 22.0], [0.1520, -24.0],
	]
	for s: Array in spots:
		var i := _idx(float(s[0]))
		var m: String = canopy[_rng.randi() % canopy.size()]
		_at(i, float(s[1]) + _rng.randf_range(-2.5, 2.5),
			_rng.randf_range(-4.0, 4.0), m, "Acacia",
			_rng.randf_range(0.0, TAU), _rng.randf_range(0.85, 1.25),
			"trunk")
	# Copaci morti si euphorbia ca variatie de silueta, mai departe.
	for s2: Array in [[0.1275, 30.0], [0.1470, -30.0], [0.1650, 28.0],
			[0.1330, -34.0]]:
		var i2 := _idx(float(s2[0]))
		var m2: String = "dead_tree" if _rng.randf() < 0.5 else "euphorbia"
		_at(i2, float(s2[1]), _rng.randf_range(-6.0, 6.0), m2, "CopacUscat",
			_rng.randf_range(0.0, TAU), _rng.randf_range(0.9, 1.3), "trunk")
	# O carcasa cu vulturi pe malul de sud, la iesire: povestea vadului.
	var i3 := _idx(0.1585)
	_at(i3, -20.0, 0.0, "carcass_vultures", "Carcasa", 1.1, 1.0, "none")


## KICKER-UL. Rampa de granit din cotul de dinainte de vad: scurtatura care te
## arunca peste rau (referinta: masina galbena in aer). Mesh-ul masurat
## (probe_kicker_shape): rampa urca de la ~0.3 la ~2.7 m pe axa locala -Z, deci
## se roteste ca -Z local sa fie directia de mers. Saltul propriu-zis il da un
## HazardMarker kind=6 pus separat in Track14.tscn.
func _kicker() -> void:
	var i := _idx(0.1225)
	# Pe latura sudica (lateral negativ). Degajarea NU e cea din brief:
	# AABB-ul masurat al piesei e 20 x 5.9 x 18 m (probe_kicker_shape), nu
	# 8 x 6 x 2.8 cum spunea brief-ul, iar originea nu e in centrul rampei —
	# corpul se intinde pana la x = -16 local. La 13.5 m de ax ProbeLaneClear
	# a raportat 19 probe blocate, toate pe KickerVad, unele chiar pe axa
	# (lat = 0.0). Cu 26 m coliziunea iese complet din banda si rampa ramane
	# o scurtatura pe care intri deliberat, nu un zid pe drum.
	_at(i, -26.0, 0.0, "kopje_kicker", "KickerVad", _yaw_along(i), 1.0,
		"mesh")


## Yaw-ul care aduce -Z local pe directia de mers a soselei.
func _yaw_along(i: int) -> float:
	var n := _track.baked.size()
	var d := (_track.baked[(i + 1) % n] - _track.baked[i]).normalized()
	return atan2(-d.x, -d.z)


func _at(idx: int, lateral: float, along: float, model: String, base: String,
		yaw: float, scl: float, mode: String) -> void:
	var n := _track.baked.size()
	var p: Vector3 = _track.baked[idx]
	var s := _track._side_at(idx)
	var dir := (_track.baked[(idx + 1) % n] - p).normalized()
	var q := p + s * lateral + dir * along
	var g := _sol_real(q.x, q.z)
	_raw(model, base, Vector3(q.x, g, q.z), yaw, scl, mode)


func _raw(model: String, base: String, pos: Vector3, yaw: float, scl: float,
		mode: String) -> void:
	_n += 1
	var c := cos(yaw) * scl
	var s := sin(yaw) * scl
	_out.append('[node name="%s%d" parent="%s" instance=ExtResource("%s")]'
		% [base, _n, ZONE, RES[model]])
	_out.append("transform = Transform3D(%f, 0, %f, 0, %f, 0, %f, 0, %f, %f, %f, %f)"
		% [c, -s, scl, s, c, pos.x, pos.y, pos.z])
	if mode != "hull":
		_out.append('metadata/coliziune = "%s"' % mode)
	_out.append("")


## Cota SOLULUI din coliziunea reala (memoria `terrain-mesh-y-extrapoleaza`:
## `_terrain_mesh_y` extrapoleaza in afara panzei, iar `ground_y` e campul
## neted, nu grila de care se lovesc rotile).
func _sol_real(x: float, z: float) -> float:
	if _terrain_rid == RID():
		for c in _track.get_children():
			if str(c.name) == "TerrainBody":
				_terrain_rid = (c as StaticBody3D).get_rid()
	var space := _track.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(x, _sus_y, z), Vector3(x, _sus_y - 900.0, z))
	q.collide_with_areas = false
	if _terrain_rid != RID():
		q.collide_with_bodies = true
		q.exclude = []
		var hit: Dictionary = space.intersect_ray(q)
		var guard := 0
		while not hit.is_empty() and hit["rid"] != _terrain_rid and guard < 24:
			q.exclude = q.exclude + [hit["rid"]]
			hit = space.intersect_ray(q)
			guard += 1
		if not hit.is_empty() and hit["rid"] == _terrain_rid:
			return float(hit["position"].y)
	print("; ATENTIE fara sol la (%.1f, %.1f)" % [x, z])
	return _sampler.ground_y(x, z)
