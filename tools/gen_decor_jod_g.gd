extends Node
## Generator de decor MANUAL pentru POI G — COBORAREA PE STANCA (frac
## 0.699-0.861) si G2 — DEVKUND SI CENOTAFUL (0.861-0.910), Track17 Jodhpur.
##
## Nu e sonda: CALCULEAZA transformarile care se lipesc in Track17.tscn sub
## `DecorManual/ZoneG_Stanca` (tiparul gen_decor_jod_f.gd).
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorJodG.tscn -- \
##       --out=C:/cale/zoneG.part [--survey]
##
## `--survey` scrie profilul traseului (pozitie, semilatime, panta, solul pe
## ambele parti) si nu genereaza nimic.
##
## ------------------------------------------------------------------------
## CONTRACTUL (jodhpur_poi_gauntlet.md §G, §G2, premisele 11-12)
##
## - G: stanca de riolit (clasa de sol exista), bolovani `hull` pe margine,
##   euforbii, khejri, tufe uscate; orasul e pe DREAPTA (in afara cadrului),
##   lacul pe STANGA spre final.
## - G2: kickerul `KickerDevkund` taie drumul 0.880-0.888 (apa -4,32 in canal
##   si in lac, pe stanga). Cenotaful (`jaswant_thada`, `mesh`) pe STANGA,
##   dincolo de lac, intreg in cadru; candele plutitoare pe lac; malul de
##   riolit in blocuri.
## - SARITURA E GIMMICKUL: nimic cu coliziune pe coridorul de zbor (buza,
##   golul, aterizarea) — fereastra FLIGHT_F0..FLIGHT_F1 pe tot latul
##   drumului + marja. ProbeRace 16 seed-uri, ProbeLaneClear pe baza 31.
## - Luminile calde in siruri pe muchii din runda 1 (StreetLights fara
##   coliziune, FortLamps pe muchiile blocurilor de mal / soclul cenotafului).

const TRACK := "res://scenes/tracks/Track17.tscn"
const ZONE := "DecorManual/ZoneG_Stanca"

const G_IN := 0.699
const G_OUT := 0.906

const RES := {
	"rhyolite_boulder_a": "s_rhyolite_boulder_a",
	"rhyolite_boulder_b": "s_rhyolite_boulder_b",
	"rhyolite_boulder_c": "s_rhyolite_boulder_c",
	"rock_slab": "s_rock_slab",
	"euphorbia": "s_euphorbia",
	"neem_tree": "s_neem_tree",
	"khejri_tree": "s_khejri_tree",
	"jaswant_thada": "s_jaswant_thada",
	"marigold_garland": "s_marigold_garland",
	"blue_house_a": "s_blue_house_a", "blue_house_b": "s_blue_house_b",
	"blue_house_c": "s_blue_house_c", "blue_house_d": "s_blue_house_d",
	"blue_house_e": "s_blue_house_e", "haveli_facade": "s_haveli_facade",
}

var _track: Track
var _sampler: TrackSideSampler
var _terrain_rid: RID = RID()
var _sus_y := 0.0
var _out: Array[String] = []
var _n := 0
var _rng := RandomNumberGenerator.new()
var _out_path := ""
var _survey_only := false
var _mesh_only := false
var _space: PhysicsDirectSpaceState3D


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out_path = a.trim_prefix("--out=")
		elif a == "--survey":
			_survey_only = true
		elif a == "--mesh":
			_mesh_only = true
	await get_tree().process_frame
	if _mesh_only:
		_mesh_report()
		get_tree().quit(0)
		return
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	_space = _track.get_world_3d().direct_space_state
	_sampler = _track._sampler
	var hi := -INF
	for bp in _track.baked:
		hi = maxf(hi, bp.y)
	_sus_y = hi + 150.0
	_rng.seed = 300930
	if _survey_only:
		_survey()
	else:
		_build()
		_write()
	get_tree().quit(0)


# ------------------------------------------------------------------ geometrie

func _idx(frac: float) -> int:
	var n := _track.baked.size()
	return int(round(fposmod(frac, 1.0) * float(n))) % n


func _tangent(i: int) -> Vector3:
	var n := _track.baked.size()
	var d := _track.baked[(i + 2) % n] - _track.baked[(i - 2 + n) % n]
	d.y = 0.0
	return d.normalized()


## Stanga orizontala (tangenta x UP da dreapta, ca `Track._side_at`).
func _left(i: int) -> Vector3:
	var t := _tangent(i)
	return Vector3(t.z, 0.0, -t.x)


func _slope(i: int) -> float:
	var n := _track.baked.size()
	var a := _track.baked[(i - 2 + n) % n]
	var b := _track.baked[(i + 2) % n]
	return (b.y - a.y) / maxf(Vector2(b.x - a.x, b.z - a.z).length(), 0.01)


## Distanta in plan de la q la muchia celui mai apropiat asfalt (negativ = pe
## asfalt), ignorand tronsoanele cu cota departe de `y`.
func _edge_dist(q: Vector3, dy_max: float = 30.0) -> float:
	var best := INF
	for j in _track.baked.size():
		var b := _track.baked[j]
		if absf(b.y - q.y) > dy_max:
			continue
		best = minf(best, Vector2(q.x - b.x, q.z - b.z).length() - _track.width_at_index(j))
	return best


## Indexul celui mai apropiat punct copt (in plan).
func _nearest_i(q: Vector3) -> int:
	var best := INF
	var bi := 0
	for j in _track.baked.size():
		var b := _track.baked[j]
		var d := Vector2(q.x - b.x, q.z - b.z).length_squared()
		if d < best:
			best = d
			bi = j
	return bi


func _survey() -> void:
	print("; frac   i    x       z      y     semi panta%% | sol st 8/12/16/20/30/40/60 | sol dr 8/12/16/20/30/40/60")
	var f := 0.696
	while f <= 0.912 + 1e-6:
		var i := _idx(f)
		var p := _track.baked[i]
		var sl := ""
		var sr := ""
		for d: float in [8.0, 12.0, 16.0, 20.0, 30.0, 40.0, 60.0]:
			var ql := p + _left(i) * d
			var qr := p - _left(i) * d
			sl += "%+5.1f " % (_sol_real(ql.x, ql.z) - p.y)
			sr += "%+5.1f " % (_sol_real(qr.x, qr.z) - p.y)
		print("; %.3f %4d %7.1f %7.1f %6.2f %5.2f %5.1f | %s| %s  L=(%.2f,%.2f)" % [
			f, i, p.x, p.z, p.y, _track.width_at_index(i),
			100.0 * _slope(i), sl, sr, _left(i).x, _left(i).z])
		f += 0.004


# ------------------------------------------------------------------ piese

## Semi-diagonala AABB in plan (m, la scara 1) — amprenta reala la yaw
## arbitrar (memoria amprenta-hull-nu-raza-nominala), nu raza nominala.
const CORNER := {
	"rhyolite_boulder_a": 1.92, "rhyolite_boulder_b": 2.07,
	"rhyolite_boulder_c": 1.60, "rock_slab": 2.36,
	"euphorbia": 0.45, "khejri_tree": 0.5, "neem_tree": 0.5,
}
## Inaltimea la scara 1 (masurata pe GLB, jodhpur_masuratori.md).
const HEIGHT := {
	"rhyolite_boulder_a": 2.0, "rhyolite_boulder_b": 1.8,
	"rhyolite_boulder_c": 1.6, "rock_slab": 0.8,
}
const BOULDERS := ["rhyolite_boulder_a", "rhyolite_boulder_b", "rhyolite_boulder_c"]
const BIG := ["rhyolite_boulder_a", "rhyolite_boulder_b"]

## Coridorul sariturii: buza 0.880, golul 0.880-0.888, aterizarea 0.888.
## Nimic cu coliziune pe FLIGHT_F0..FLIGHT_F1 la mai putin de FLIGHT_GAP m de
## marginea asfaltului (masina iese stramb de pe trambulina, aterizeaza
## lateral); pe asfalt nimic deloc, nici fantome.
const FLIGHT_F0 := 0.862
const FLIGHT_F1 := 0.904
const FLIGHT_GAP := 12.0
## Elanul spre trambulina: runda 1 a incercat 8 m liberi pe 0.815-0.862
## (seed 12 avea o repunere noua la 0.891). N-a eliminat evenimentul, doar l-a
## mutat (ordinea contactelor Jolt, nu decorul) — decizia coordonatorului:
## pe elan contractul obisnuit (>= 2,2 m pe colt), 12 m doar pe fata
## kickerului si pe traiectoria de zbor (FLIGHT_F0..FLIGHT_F1).
## Cea mai mica distanta colt-margine pentru piesele cu corp. Bolovanii de
## margine (contract: „bolovani hull pe marginea dreapta") au EDGE_ROW_GAP.
const GAP_MIN := 4.0
const EDGE_ROW_GAP := 2.2
## Sub atat fata de drum, terenul e in rapa lacului / canal: piesele de
## acolo sunt fantome (o masina cazuta nu trebuie sa ramana pe un bolovan in
## loc sa fie repusa de RespawnZone).
const RAVINE_DY := 1.5
const WATER_Y := -4.32

## Felinarele (StreetLights, fara coliziune) pe ambele muchii; se opresc
## inaintea canalului (terenul coboara sub stalpi) si reiau dupa aterizare.
const LIGHT_A := Vector2(0.703, 0.8755)
const LIGHT_B := Vector2(0.8915, 0.9055)


var _obst: Array[Vector3] = [] # (x, z, raza)
var _lamp_sets := {} # nume nod -> {"p": PackedVector3Array, "r": PackedFloat32Array}
var _eaves := PackedVector3Array()
var _floats := PackedVector3Array()
var _float_yaw := PackedFloat32Array()
var _thada_c := Vector3.INF
var _thada_xf := Transform3D.IDENTITY
## In interiorul unui afloriment piesele se suprapun intentionat (silueta
## decupata); suprapunerea se verifica doar intre aflorimente.
var _ignore_overlap := false
var _bank := {} # model -> [[pozitie, yaw, scara], ...]


func _build() -> void:
	_g2_group()
	_rock_terraces()
	_houses_right()
	_lake()
	_kerb_diyas()
	_emit_nodes()
	print("; obstacole cu corp: %d" % _obst.size())


func _frac_of(i: int) -> float:
	return float(i) / float(_track.baked.size())


## Piesa cu corp: e voie aici? (coridorul de zbor, marginea, suprapunerea)
func _solid_ok(q: Vector3, r: float, gap: float, pad: float = 0.5) -> bool:
	var i := _nearest_i(q)
	var f := _frac_of(i)
	var ed := _edge_dist(q, 40.0) - r
	if ed < gap:
		return false
	if f >= FLIGHT_F0 and f <= FLIGHT_F1 and ed < FLIGHT_GAP:
		return false
	return not _overlaps(q, r, pad)


func _overlaps(q: Vector3, r: float, pad: float) -> bool:
	if _ignore_overlap:
		return false
	for o in _obst:
		if Vector2(q.x - o.x, q.z - o.y).length() < o.z + r + pad:
			return true
	return false


## In rapa (lac, canal): terenul e cu RAVINE_DY sub drumul cel mai apropiat.
func _in_ravine(q: Vector3) -> bool:
	var i := _nearest_i(q)
	return _sol_real(q.x, q.z) < _track.baked[i].y - RAVINE_DY


## Un bolovan asezat pe sol, cu talpa putin ingropata (fara gol sub el pe
## panta). Intoarce true daca l-a pus.
func _rock(model: String, base: String, q: Vector3, scl: float, gap: float,
		pad: float = 0.5) -> bool:
	var r: float = CORNER[model] * scl
	var ghost := _in_ravine(q)
	if ghost:
		if _edge_dist(q, 40.0) - r < 1.0:
			return false
		if _overlaps(q, r, -r * 0.4):
			return false
	elif not _solid_ok(q, r, gap, pad):
		return false
	var g := _ground_min(q, r * 0.6)
	var sink: float = 0.12 * float(HEIGHT.get(model, 1.0)) * scl
	if ghost:
		# fantomele din rapa merg in MultiMesh-ul malului (vezi `_lake`)
		if not _bank.has(model):
			_bank[model] = []
		(_bank[model] as Array).append([Vector3(q.x, g - sink, q.z), _rng.randf_range(-PI, PI), scl])
		_obst.append(Vector3(q.x, q.z, r * 0.6))
		return true
	_raw(model, base, Vector3(q.x, g - sink, q.z), _rng.randf_range(-PI, PI), scl,
		"none" if ghost else "")
	if not ghost:
		_obst.append(Vector3(q.x, q.z, r))
	else:
		_obst.append(Vector3(q.x, q.z, r * 0.6))
	return true


## Cota minima a solului sub un disc (centru + 4 puncte), ca talpa sa nu
## ramana in aer pe partea de jos a pantei.
func _ground_min(q: Vector3, r: float) -> float:
	var g := _sol_real(q.x, q.z)
	for d: Vector2 in [Vector2(r, 0), Vector2(-r, 0), Vector2(0, r), Vector2(0, -r)]:
		g = minf(g, _sol_real(q.x + d.x, q.z + d.y))
	return g


func _lamp(set_name: String, p: Vector3, r: float) -> void:
	if not _lamp_sets.has(set_name):
		_lamp_sets[set_name] = {"p": PackedVector3Array(), "r": PackedFloat32Array()}
	# Packed* sunt valori: append pe (x as Packed...) scrie intr-o copie
	# (memoria append-pe-copie-in-array-netipizat) — se scrie inapoi.
	var pp: PackedVector3Array = _lamp_sets[set_name]["p"]
	var rr: PackedFloat32Array = _lamp_sets[set_name]["r"]
	pp.append(p)
	rr.append(r)
	_lamp_sets[set_name]["p"] = pp
	_lamp_sets[set_name]["r"] = rr


# ---------------------------------------------------------------- G2: cenotaful


func _rect_lamps(xf: Transform3D, a: Vector2, b: Vector2, y: float, step: float,
		r: float) -> void:
	var corners := [Vector2(a.x, a.y), Vector2(b.x, a.y), Vector2(b.x, b.y), Vector2(a.x, b.y)]
	for k in 4:
		var p0: Vector2 = corners[k]
		var p1: Vector2 = corners[(k + 1) % 4]
		var n := maxi(int(p0.distance_to(p1) / step), 1)
		for j in n:
			var t := float(j) / float(n)
			var p := p0.lerp(p1, t)
			_lamp("gCandeleCenotaf", xf * Vector3(p.x, y, p.y), r)


func _festoon_rect(xf: Transform3D, a: Vector2, b: Vector2, y: float, span: float) -> void:
	var corners := [Vector2(a.x, a.y), Vector2(b.x, a.y), Vector2(b.x, b.y), Vector2(a.x, b.y)]
	for k in 4:
		var p0: Vector2 = corners[k]
		var p1: Vector2 = corners[(k + 1) % 4]
		var n := maxi(int(p0.distance_to(p1) / span), 1)
		for j in n:
			var q0 := p0.lerp(p1, float(j) / float(n))
			var q1 := p0.lerp(p1, float(j + 1) / float(n))
			_eaves.append(xf * Vector3(q0.x, y, q0.y))
			_eaves.append(xf * Vector3(q1.x, y, q1.y))


# ---------------------------------------------------------------- G: stanca






# ---------------------------------------------------------------- G2: lacul

## Candele plutitoare pe TOATA apa (interiorul, nu un tiv), mai dese spre
## cenotaf; blocuri de riolit pe mal (fantome, sunt in rapa); sir de candele
## pe linia apei.
func _lake() -> void:
	var lo := Vector2(INF, INF)
	var hi := -lo
	for f in range(_idx(0.855), _idx(0.912)):
		var p := _track.baked[f]
		lo = lo.min(Vector2(p.x, p.z))
		hi = hi.max(Vector2(p.x, p.z))
	lo -= Vector2(80, 80)
	hi += Vector2(80, 80)
	var cell := 1.7
	var nf := 0
	var bank: Array[Vector3] = []
	var shore: Array[Vector3] = []
	var x := lo.x
	while x < hi.x:
		var z := lo.y
		while z < hi.y:
			var g := _sol_real(x, z)
			var q := Vector3(x, 0.0, z)
			if g < WATER_Y - 0.25:
				var pr := 0.33
				if _thada_c != Vector3.INF:
					var dc := Vector2(x - _thada_c.x, z - _thada_c.z).length()
					pr += 0.5 * clampf(1.0 - (dc - 14.0) / 30.0, 0.0, 1.0)
				if _rng.randf() < pr and not _overlaps(Vector3(x, 0, z), 0.4, 0.0):
					var j := Vector3(_rng.randf_range(-0.7, 0.7), 0, _rng.randf_range(-0.7, 0.7)) * cell
					_floats.append(Vector3(x + j.x, WATER_Y, z + j.z))
					_float_yaw.append(_rng.randf_range(0.0, 360.0))
					nf += 1
			elif g < WATER_Y + 1.2:
				bank.append(Vector3(x, g, z))
			if g > WATER_Y - 0.05 and g < WATER_Y + 0.55:
				shore.append(Vector3(x, g, z))
			z += cell
		x += cell
	print("; candele plutitoare: %d, celule de mal %d, linia apei %d" % [nf, bank.size(), shore.size()])
	# blocuri pe mal: Poisson rar, marime descrescatoare de la apa in sus
	for a in range(bank.size() - 1, 0, -1):
		var b2 := _rng.randi_range(0, a)
		var t := bank[a]
		bank[a] = bank[b2]
		bank[b2] = t
	var nb := 0
	for b in bank:
		if _thada_c != Vector3.INF and Vector2(b.x - _thada_c.x, b.z - _thada_c.z).length() < 22.0:
			continue
		if _edge_dist(b, 40.0) < 2.0:
			continue
		# Malul e in rapa: fantome, si NU noduri de scena — `probe_manual`
		# judeca solul pe `ground_y` al samplerului, care nu stie de rapa
		# sapata (prima rulare: 14 blocuri „INGROPAT" cu 2-5 m, desi stateau
		# pe fundul real). Un MultiMesh (FlockProp) pe clasa `rhyolite` e
		# acelasi material, zero corpuri.
		var m: String = BOULDERS[_rng.randi() % 3]
		var sc := _rng.randf_range(1.2, 2.6)
		var r: float = CORNER[m] * sc
		if _edge_dist(b, 40.0) - r < 1.0 or _overlaps(b, r, -r * 0.4):
			continue
		var g := _ground_min(b, r * 0.6)
		var sink: float = 0.12 * float(HEIGHT[m]) * sc
		if not _bank.has(m):
			_bank[m] = []
		(_bank[m] as Array).append([Vector3(b.x, g - sink, b.z), _rng.randf_range(-PI, PI), sc])
		_obst.append(Vector3(b.x, b.z, r * 0.6))
		nb += 1
		if nb >= 90:
			break
	print("; blocuri de mal: %d" % nb)
	# linia apei: candele la ~1,6 m una de alta
	var taken: Array[Vector3] = []
	for s in shore:
		if _edge_dist(s, 40.0) < 1.5:
			continue
		var ok := true
		for t in taken:
			if Vector2(s.x - t.x, s.z - t.z).length() < 1.6:
				ok = false
				break
		if not ok:
			continue
		taken.append(s)
		_lamp("gCandeleMal", Vector3(s.x, s.y + 0.12, s.z), 0.12)
	print("; candele pe linia apei: %d" % taken.size())


## Candele pe bordura, ambele parti, la pas regulat (sir, nu praf).
func _kerb_diyas() -> void:
	var n := _track.baked.size()
	var i0 := _idx(0.703)
	var i1 := _idx(0.9055)
	var acc := 0.0
	for i in range(i0, i1):
		var a := _track.baked[i]
		var b := _track.baked[(i + 1) % n]
		var seg := Vector2(b.x - a.x, b.z - a.z).length()
		acc += seg
		if acc < 2.4:
			continue
		acc = 0.0
		var w := _track.width_at_index(i)
		for sgn: float in [-1.0, 1.0]:
			var q := a + _left(i) * sgn * (w + 1.25)
			var g := _sol_real(q.x, q.z)
			if absf(g - a.y) > 0.9:
				continue
			_lamp("gCandeleMargine", Vector3(q.x, g + 0.13, q.z), 0.13)


# ---------------------------------------------------------------- runda 2

## Casele kitului: dimensiunile AABB (X, Z) si yaw-ul fetei (grade), ca in
## `OrasFill.front_yaw_deg` (fata in lume = Basis(UP, yaw + front) * -Z).
const HOUSES := {
	"blue_house_a": [7.15, 6.62, -90.0], "blue_house_b": [6.82, 7.55, -90.0],
	"blue_house_c": [7.50, 7.67, 0.0], "blue_house_d": [7.50, 8.01, -90.0],
	"blue_house_e": [7.40, 6.26, 0.0], "haveli_facade": [10.92, 7.43, 0.0],
}
const HOUSE_W := {"blue_house_a": 0.14, "blue_house_b": 0.26, "blue_house_c": 0.2,
	"blue_house_d": 0.2, "blue_house_e": 0.14, "haveli_facade": 0.06}

var _chh_b := PackedVector3Array()
var _chh_s := PackedFloat32Array()
var _chh_y := PackedFloat32Array()
var _chh_n := PackedInt32Array()


## Cutie orientata (centru, yaw, semi-laturi X/Z): toate punctele de pe
## contur (colturi + mijloace) la >= gap de asfalt; pe fereastra de zbor
## >= FLIGHT_GAP. Amprenta reala, nu raza (memoria amprenta-hull).
func _box_clear(c: Vector3, yaw: float, hx: float, hz: float, gap: float) -> bool:
	var b := Basis(Vector3.UP, yaw)
	for u: float in [-1.0, 0.0, 1.0]:
		for v: float in [-1.0, 0.0, 1.0]:
			if u == 0.0 and v == 0.0:
				continue
			var q := c + b.x * (u * hx) + b.z * (v * hz)
			q.y = c.y
			var ed := _edge_dist(q, 40.0)
			if ed < gap:
				return false
			var f := _frac_of(_nearest_i(q))
			if f >= FLIGHT_F0 and f <= FLIGHT_F1 and ed < FLIGHT_GAP:
				return false
	return true


func _box_ground(c: Vector3, yaw: float, hx: float, hz: float) -> Vector2:
	var b := Basis(Vector3.UP, yaw)
	var lo := INF
	var hi := -INF
	for u: float in [-1.0, 0.0, 1.0]:
		for v: float in [-1.0, 0.0, 1.0]:
			var q := c + b.x * (u * hx) + b.z * (v * hz)
			var g := _sol_real(q.x, q.z)
			lo = minf(lo, g)
			hi = maxf(hi, g)
	return Vector2(lo, hi)


## Un bloc de riolit cu blat plat (rock_slab: 2,5 x 0,8 x 4, blatul la 0,8):
## cutie de semi-laturi hx (X local) si hz (Z local), varful la `top` (lume).
## Corp `hull` pe uscat, fantoma (MultiMesh-ul malului) in rapa.
func _block(base: String, c: Vector3, yaw: float, hx: float, hz: float, top: float,
		gap: float, check: bool = true) -> bool:
	if check and not _box_clear(c, yaw, hx, hz, gap):
		return false
	var gr := _box_ground(c, yaw, hx, hz)
	var y0 := gr.x - 0.3
	if top - y0 < 0.4:
		return false
	var sc := Vector3(hx / 1.25, (top - y0) / 0.8, hz / 2.0)
	var pos := Vector3(c.x, y0, c.z)
	# Blocurile de pe buza rapei au talpa in rapa: fantome (MultiMesh), altfel
	# `probe_manual` (solul samplerului, care nu stie de rapa) le da INGROPAT.
	if _in_ravine(c) or y0 < _sampler.ground_y(c.x, c.z) - 1.8:
		if not _bank.has("rock_slab"):
			_bank["rock_slab"] = []
		(_bank["rock_slab"] as Array).append([pos, yaw, sc])
	else:
		var bas := Basis(Vector3.UP, yaw) * Basis.from_scale(sc)
		_raw_basis("rock_slab", base, pos, bas, "")
	_obst.append(Vector3(c.x, c.z, maxf(hx, hz)))
	return true


## Sir de candele pe muchia din fata (X local * face) a unui bloc.
func _edge_row(set_name: String, c: Vector3, yaw: float, hx: float, hz: float,
		top: float, face: float, step: float) -> void:
	var b := Basis(Vector3.UP, yaw)
	var z := -hz * 0.85
	while z <= hz * 0.85:
		var p := c + b.x * (face * hx * 0.9) + b.z * z
		p.y = top + 0.12
		_lamp(set_name, p, 0.12)
		z += step


func _advance(i: int, i_end: int, step: float) -> int:
	var n := _track.baked.size()
	var acc := 0.0
	while acc < step and i < i_end:
		var a := _track.baked[i]
		var b := _track.baked[(i + 1) % n]
		acc += Vector2(b.x - a.x, b.z - a.z).length()
		i += 1
	return i


## G, partea STANCII (stanga, in afara buclei): riolit in TREPTE, CONTINUU,
## imediat dupa lantul de lumini — trei randuri de blocuri cu blat plat
## (jos langa drum, mediu, inalt in spate), lipite si suprapuse, cu euforbii
## in golurile randului din fata. Critic r1: „benzile de pe ambele parti sunt
## GOALE, 20-40 m de nisip plat intre lumini si decor". Inaltimile NU trec de
## 9 m (memoria capcana-parametrului-care-doar-aduna: lipsa era
## continuitatea langa drum, nu scara).
func _rock_terraces() -> void:
	var i := _idx(0.704)
	var i_end := _idx(0.859)
	var placed := 0
	while i < i_end:
		var road := _track.baked[i]
		var L := _left(i)
		var T := _tangent(i)
		var w := _track.width_at_index(i)
		var yaw := atan2(T.x, T.z) + _rng.randf_range(-0.22, 0.22) # Z local ~ tangenta
		var bx := Basis(Vector3.UP, yaw).x
		var face := -1.0 if bx.dot(L) > 0.0 else 1.0
		var hz0 := _rng.randf_range(1.5, 2.3)
		# randul 1 (jos): la 2,4-3,2 m de asfalt; uneori gol cu euforbii
		var d0 := _rng.randf_range(2.4, 3.2)
		var hx0 := _rng.randf_range(1.1, 1.7)
		var c0 := road + L * (w + d0 + hx0)
		var top0 := road.y + _rng.randf_range(0.9, 2.0)
		if _rng.randf() >= 0.28:
			if _block("gTreapta", c0, yaw, hx0, hz0, top0, EDGE_ROW_GAP):
				placed += 1
				_edge_row("gCandeleStanca", c0, yaw, hx0, hz0, top0, face, 0.8)
		else:
			for k in _rng.randi_range(2, 3):
				var e := c0 + T * _rng.randf_range(-1.6, 1.6) + L * _rng.randf_range(-0.8, 0.8)
				if _box_clear(e, 0.0, 0.45, 0.45, EDGE_ROW_GAP):
					_raw("euphorbia", "gEuforbie", Vector3(e.x, _sol_real(e.x, e.z) - 0.05, e.z),
						_rng.randf_range(-PI, PI), _rng.randf_range(0.8, 1.3), "")
		# randul 2 (mediu), suprapus 0,6 m peste randul 1
		var hx1 := _rng.randf_range(1.4, 2.2)
		var c1 := road + L * (w + d0 + 2.0 * hx0 + hx1 - 0.6) + T * _rng.randf_range(-1.0, 1.0)
		# Spre lac (> TAPER_F) stanca coboara: din cadrul-erou G2 (0.850)
		# randurile inalte acopereau grupul de chhatri (captura w4).
		var fr := _frac_of(i)
		var taper := clampf((fr - TAPER_F) / 0.014, 0.0, 1.0)
		var top1 := road.y + lerpf(_rng.randf_range(2.8, 4.6), _rng.randf_range(1.4, 2.2), taper)
		if _block("gTreapta", c1, yaw + _rng.randf_range(-0.15, 0.15), hx1,
				hz0 * _rng.randf_range(1.0, 1.3), top1, EDGE_ROW_GAP):
			placed += 1
			if _rng.randf() < 0.5:
				_edge_row("gCandeleStanca", c1, yaw, hx1, hz0, top1, face, 1.0)
		# randul 3 (inalt), nu la fiecare statie
		if _rng.randf() < 0.7 and taper < 0.5:
			var hx2 := _rng.randf_range(1.8, 2.8)
			var c2 := road + L * (w + d0 + 2.0 * hx0 + 2.0 * hx1 + hx2 - 1.2) + T * _rng.randf_range(-1.5, 1.5)
			var top2 := road.y + _rng.randf_range(5.5, 8.8)
			if _block("gTreapta", c2, yaw + _rng.randf_range(-0.3, 0.3), hx2,
					hz0 * _rng.randf_range(1.1, 1.5), top2, EDGE_ROW_GAP):
				placed += 1
		if _rng.randf() < 0.16:
			var q := road + L * (w + d0 + _rng.randf_range(10.0, 14.0))
			if _solid_ok(q, 0.5, 4.0, 0.2):
				_raw("khejri_tree" if _rng.randf() < 0.6 else "neem_tree", "gCopac",
					Vector3(q.x, _sol_real(q.x, q.z) - 0.1, q.z), _rng.randf_range(-PI, PI),
					_rng.randf_range(0.9, 1.2), "")
				_obst.append(Vector3(q.x, q.z, 0.5))
		# pasul: lungimea blocului, cu suprapunere mica -> sir continuu
		i = _advance(i, i_end, 2.0 * hz0 * _rng.randf_range(0.8, 0.95))
	print("; trepte de riolit (stanga): %d blocuri" % placed)


## G, partea ORASULUI (dreapta): case albastre din kit pana la bordura
## (primul rand la 2,6-3,6 m de asfalt, dincolo de felinare), al doilea rand
## in spate; in golurile dintre case bolovani, euforbii, copaci. Corp `hull`
## (casele kitului). Pe fereastra de zbor nimic.
func _houses_right() -> void:
	for row in 2:
		var i := _idx(0.706)
		var i_end := _idx(0.8595)
		var nh := 0
		while i < i_end:
			var road := _track.baked[i]
			var R := -_left(i)
			var T := _tangent(i)
			var w := _track.width_at_index(i)
			var m := _pick_house()
			var d: Array = HOUSES[m]
			var side_front := absf(float(d[2])) > 1.0
			var front := deg_to_rad(float(d[2]))
			var width: float = float(d[1]) if side_front else float(d[0])
			var depth: float = float(d[0]) if side_front else float(d[1])
			var gap_front := _rng.randf_range(2.6, 3.6)
			var lat := w + gap_front + depth * 0.5
			if row == 1:
				lat += depth + _rng.randf_range(1.0, 3.0)
			var to := -R
			var yaw := atan2(-to.x, -to.z) - front + _rng.randf_range(-0.08, 0.08)
			var c := road + R * lat + T * _rng.randf_range(-0.5, 0.5)
			var hx := float(d[0]) * 0.5
			var hz := float(d[1]) * 0.5
			var ok := _box_clear(c, yaw, hx, hz, EDGE_ROW_GAP) and not _overlaps(c, maxf(hx, hz) * 0.9, 0.0)
			var gr := _box_ground(c, yaw, hx, hz)
			if ok and gr.y - gr.x < 1.6 and absf(gr.x - road.y) < 1.5 and _rng.randf() > 0.12:
				_raw(m, "gCasa", Vector3(c.x, gr.x - 0.25, c.z), yaw, 1.0, "")
				if _rng.randf() < 0.4:
					_meta_last("metadata/indigo = true")
				_obst.append(Vector3(c.x, c.z, maxf(hx, hz) * 0.95))
				nh += 1
			elif row == 0:
				_gap_fill(road + R * (w + 3.0), R, T)
			var step := width + _rng.randf_range(0.3, 1.4)
			if row == 0 and _rng.randf() < 0.18:
				step += 4.0
				_gap_fill(road + R * (w + 3.0) + T * (width * 0.5 + 2.0), R, T)
			i = _advance(i, i_end, step)
		print("; case dreapta, randul %d: %d" % [row + 1, nh])


func _pick_house() -> String:
	var r := _rng.randf()
	var acc := 0.0
	for k in HOUSE_W.keys():
		acc += float(HOUSE_W[k])
		if r <= acc:
			return k
	return "blue_house_b"


## Golul dintre case: un bolovan de margine (contract: bolovani `hull` pe
## marginea dreapta), o euforbie, uneori un copac.
func _gap_fill(q: Vector3, R: Vector3, T: Vector3) -> void:
	var m: String = BOULDERS[_rng.randi() % 3]
	var s := _rng.randf_range(0.9, 1.4)
	var c := q + R * (float(CORNER[m]) * s)
	_rock(m, "gMargine", c, s, EDGE_ROW_GAP, 0.3)
	var e := c + R * _rng.randf_range(1.5, 3.0) + T * _rng.randf_range(-1.5, 1.5)
	if _solid_ok(e, 0.45, EDGE_ROW_GAP, 0.1):
		_raw("euphorbia", "gEuforbie", Vector3(e.x, _sol_real(e.x, e.z) - 0.05, e.z),
			_rng.randf_range(-PI, PI), _rng.randf_range(0.9, 1.3), "")
		_obst.append(Vector3(e.x, e.z, 0.45))
	if _rng.randf() < 0.45:
		var t := c + R * _rng.randf_range(4.0, 6.0)
		if _solid_ok(t, 0.5, 4.0, 0.3):
			_raw("neem_tree" if _rng.randf() < 0.5 else "khejri_tree", "gCopac",
				Vector3(t.x, _sol_real(t.x, t.z) - 0.1, t.z), _rng.randf_range(-PI, PI),
				_rng.randf_range(0.85, 1.1), "")
			_obst.append(Vector3(t.x, t.z, 0.5))


## G2: GRUPUL de chhatri in trepte pe stanca de riolit, chiar deasupra apei,
## cu `jaswant_thada` ca piesa centrala sus. Critic r1: „un singur pavilion
## mic, departe, pe un bloc jos izolat; in REF 4-6 chhatri albe in trepte pe
## stanca masiva, silueta verticala, ghirlande pe cornise".
## Terasele: T0 din apa (blat la ~1,3 m peste apa), T1 pe mal, T2, apoi
## soclul cenotafului — fiecare rand mai departe si mai sus.
const TAPER_F := 0.832
const G2_F0 := 0.864
const G2_F1 := 0.899
const G2_THADA := 0.884
const TIER_TOP := [-2.4, 1.6, 4.4, 7.2]


func _far_bank(i: int) -> float:
	var road := _track.baked[i]
	var L := _left(i)
	var in_water := false
	var lat := 10.0
	while lat < 90.0:
		var q := road + L * lat
		var g := _sol_real(q.x, q.z)
		if g < WATER_Y:
			in_water = true
		elif in_water and g > WATER_Y + 0.5:
			return lat
		lat += 0.5
	return 40.0


func _g2_group() -> void:
	var i := _idx(G2_F0)
	var i_end := _idx(G2_F1)
	var ti := _idx(G2_THADA)
	var fb_t := _far_bank(ti)
	var Lt := _left(ti)
	var yaw_t := atan2(Lt.x, Lt.z)
	# Cenotaful: fata (z local -10,3 = treptele) spre drum, pe soclul T3.
	var tc := _track.baked[ti] + Lt * (fb_t + 12.5 + 10.3)
	tc.y = float(TIER_TOP[3])
	var tb := Basis(Vector3.UP, yaw_t)
	_thada_c = tc
	_thada_xf = Transform3D(tb, tc)
	# soclul: un bloc larg sub cenotaf (1 m de blat in jurul lui)
	_block("gSoclu", tc - tb.z * 1.5, yaw_t, 15.8, 10.5, float(TIER_TOP[3]), 20.0, false)
	_raw_basis("jaswant_thada", "gCenotaf", tc, tb, "mesh")
	print("; cenotaf la %s, malul departat %.1f m" % [str(tc), fb_t])
	var tiers_pts: Array = [[], [], []]
	while i < i_end:
		var road := _track.baked[i]
		var L := _left(i)
		var T := _tangent(i)
		var fb := _far_bank(i)
		var yaw := atan2(L.x, L.z) + _rng.randf_range(-0.12, 0.12)
		var hx := _rng.randf_range(3.0, 4.0)
		# Z local = spre departe (L); X local = de-a lungul malului. Randul
		# -1: bolovani-treapta in apa, sub T0 (stanca intra in lac in trepte).
		var specs := [
			[fb - 5.0, _rng.randf_range(3.0, 3.8), float(TIER_TOP[0]) + _rng.randf_range(-0.3, 0.4)],
			[fb + 1.8, _rng.randf_range(3.2, 4.0), float(TIER_TOP[1]) + _rng.randf_range(-0.3, 0.5)],
			[fb + 8.6, _rng.randf_range(3.2, 4.0), float(TIER_TOP[2]) + _rng.randf_range(-0.4, 0.6)],
			[fb - 10.0, _rng.randf_range(1.6, 2.4), WATER_Y + _rng.randf_range(0.4, 1.0)],
		]
		for k in 4:
			var sp: Array = specs[k]
			var hzk := float(sp[1])
			var c := road + L * float(sp[0]) + T * _rng.randf_range(-0.8, 0.8)
			# sub cenotaf nu se pun trepte peste soclu
			var loc := _thada_xf.affine_inverse() * c
			if absf(loc.x) < 16.5 and loc.z > -13.0:
				continue
			if k == 3:
				_block("gTerasa", c, yaw + _rng.randf_range(-0.4, 0.4), hx * 0.7, hzk, float(sp[2]), 8.0)
				continue
			if _block("gTerasa", c, yaw, hx, hzk, float(sp[2]), 10.0):
				(tiers_pts[k] as Array).append([Vector3(c.x, float(sp[2]), c.z), yaw])
				# candele pe muchia dinspre apa (-Z local)
				var bb := Basis(Vector3.UP, yaw)
				var x := -hx * 0.85
				while x <= hx * 0.85:
					var p := c + bb.x * x - bb.z * (hzk * 0.9)
					p.y = float(sp[2]) + 0.12
					_lamp("gCandeleTerase", p, 0.13)
					x += 0.9
		i = _advance(i, i_end, 2.0 * hx * 0.75)
	# Chhatri: 2 pe T0 (langa apa), 2 pe T1, 2 pe T2, 2 pe colturile din
	# fata ale soclului — in trepte, cele mai mari sus.
	var picks := [[0, 2, 1.3], [1, 2, 1.5], [2, 2, 1.75]]
	for pk in picks:
		var arr: Array = tiers_pts[int(pk[0])]
		if arr.is_empty():
			continue
		var cnt := int(pk[1])
		for j in cnt:
			var idx := int(round(float(j + 1) * float(arr.size()) / float(cnt + 1))) - 1
			idx = clampi(idx + _rng.randi_range(-1, 1), 0, arr.size() - 1)
			var it: Array = arr[idx]
			var sc := float(pk[2]) * _rng.randf_range(0.9, 1.1)
			_chhatri(it[0], sc, float(it[1]), 4 if _rng.randf() < 0.6 else 8)
	for sgn: float in [-1.0, 1.0]:
		_chhatri(_thada_xf * Vector3(sgn * 13.5, 0.0, -11.5), 1.5, yaw_t, 8)
	print("; chhatri: %d, blocuri pe trepte T0/T1/T2: %d/%d/%d" % [_chh_b.size(),
		(tiers_pts[0] as Array).size(), (tiers_pts[1] as Array).size(),
		(tiers_pts[2] as Array).size()])
	# Candelele cenotafului + festoane (ca in runda 1).
	var xf := _thada_xf
	var x2 := -15.0
	while x2 <= 15.0:
		_lamp("gCandeleCenotaf", xf * Vector3(x2, 0.14, -11.2), 0.14)
		x2 += 0.9
	_rect_lamps(xf, Vector2(-7.8, -4.8), Vector2(7.8, 5.6), 1.6 + 0.12, 0.7, 0.12)
	_rect_lamps(xf, Vector2(-10.6, -8.2), Vector2(10.6, 7.0), 0.9 + 0.12, 0.8, 0.12)
	for k in 30:
		var a := TAU * float(k) / 30.0
		_lamp("gCandeleCenotaf", xf * Vector3(cos(a) * 4.2, 7.12, sin(a) * 4.2), 0.12)
	_festoon_rect(xf, Vector2(-10.6, -8.2), Vector2(10.6, 7.0), 1.9, 3.5)
	var ring: Array[Vector3] = []
	for k in 12:
		var a := TAU * float(k) / 12.0
		ring.append(xf * Vector3(cos(a) * 4.5, 8.6, sin(a) * 4.5))
	for k in 12:
		_eaves.append(ring[k])
		_eaves.append(ring[(k + 1) % 12])
	# ghirlande intre chhatri vecini (la streasina): lantul de lumini in trepte
	var inv := _thada_xf.affine_inverse()
	var order: Array = []
	for k in _chh_b.size():
		order.append(k)
	order.sort_custom(func(a: int, b: int) -> bool:
		return (inv * _chh_b[a]).x < (inv * _chh_b[b]).x)
	for k in range(order.size() - 1):
		var a: int = order[k]
		var b: int = order[k + 1]
		var pa := _chh_b[a] + Vector3.UP * 3.3 * _chh_s[a]
		var pb := _chh_b[b] + Vector3.UP * 3.3 * _chh_s[b]
		if pa.distance_to(pb) < 12.0:
			_eaves.append(pa)
			_eaves.append(pb)


func _chhatri(base: Vector3, s: float, yaw: float, sides: int) -> void:
	_chh_b.append(base)
	_chh_s.append(s)
	_chh_y.append(yaw)
	_chh_n.append(sides)
	# festoane pe conturul streasinii (chajja)
	var rc := 1.6 * s * (1.41 if sides == 4 else 1.0) * 1.3
	var ey := base.y + (0.5 + 2.3 + 0.52) * s
	var off := yaw + (PI / float(sides) if sides == 4 else 0.0)
	var pts: Array[Vector3] = []
	for k in sides:
		var a := off + TAU * float(k) / float(sides)
		pts.append(Vector3(base.x + cos(a) * rc, ey, base.z + sin(a) * rc))
	for k in sides:
		_eaves.append(pts[k])
		_eaves.append(pts[(k + 1) % sides])


# ---------------------------------------------------------------- noduri

func _emit_nodes() -> void:
	for pair in [LIGHT_A, LIGHT_B]:
		var v: Vector2 = pair
		_n += 1
		_out.append('[node name="gFelinare%d" type="Node3D" parent="%s"]' % [_n, ZONE])
		_out.append('script = ExtResource("h_lights")')
		_out.append("frac_from = %.4f" % v.x)
		_out.append("frac_to = %.4f" % v.y)
		_out.append("lateral_m = %.2f" % 8.1)
		_out.append("step_m = 8.0")
		_out.append("cross_every = 0")
		_out.append("facade_heights_m = PackedFloat32Array()")
		# (Runda 1: am incercat decalul de lumina calda al lui StreetLights pe
		# fata cenotafului — nu s-a vazut in captura la apus, deci scos; fata
		# spre drum e cea umbrita, soarele e la est.)
		_out.append("facade_wash = false")
		_out.append("base_drop_m = 1.6")
		# Runda 1, prima captura: felinarele lui H (glob 0,5 m, becuri 0,16)
		# citeau ca margele uriase pe marginea stancii; aici sunt mai mici.
		_out.append("lamp_radius_m = 0.3")
		_out.append("lamp_halo_core_m = 0.32")
		_out.append("lamp_halo_m = 1.3")
		_out.append("bulb_radius_m = 0.09")
		_out.append("bulb_halo_core_m = 0.11")
		_out.append("bulb_halo_m = 0.38")
		_out.append("bulb_step_m = 0.3")
		_out.append("post_radius_m = 0.1")
		_out.append("")
	# festoanele cenotafului: StreetLights fara stalpi (frac_from = frac_to)
	if not _eaves.is_empty():
		_out.append('[node name="gCenotafFestoane" type="Node3D" parent="%s"]' % ZONE)
		_out.append('script = ExtResource("h_lights")')
		_out.append("frac_from = 0.9")
		_out.append("frac_to = 0.9")
		_out.append("facade_heights_m = PackedFloat32Array()")
		_out.append("facade_wash = false")
		_out.append("cross_every = 0")
		var ps: Array[String] = []
		for v in _eaves:
			ps.append("%.3f, %.3f, %.3f" % [v.x, v.y, v.z])
		_out.append("eave_points = PackedVector3Array(%s)" % ", ".join(ps))
		_out.append("eave_sag_m = 0.35")
		_out.append("")
	for key in _lamp_sets.keys():
		var st: Dictionary = _lamp_sets[key]
		var pp: PackedVector3Array = st["p"]
		var rr: PackedFloat32Array = st["r"]
		_out.append('[node name="%s" type="Node3D" parent="%s"]' % [key, ZONE])
		_out.append('script = ExtResource("e_fort_lamps")')
		var ps: Array[String] = []
		for v in pp:
			ps.append("%.3f, %.3f, %.3f" % [v.x, v.y, v.z])
		_out.append("positions = PackedVector3Array(%s)" % ", ".join(ps))
		var rs: Array[String] = []
		var ss: Array[String] = []
		for v in rr:
			rs.append("%.2f" % v)
			ss.append("1.00")
		_out.append("radii = PackedFloat32Array(%s)" % ", ".join(rs))
		_out.append("stretch = PackedFloat32Array(%s)" % ", ".join(ss))
		_out.append("")
		print("; %s: %d lampi" % [key, pp.size()])
	if not _chh_b.is_empty():
		_out.append('[node name="gChhatri" type="Node3D" parent="%s"]' % ZONE)
		_out.append('script = ExtResource("g_chhatri")')
		var cb: Array[String] = []
		var cs: Array[String] = []
		var cy: Array[String] = []
		var cn: Array[String] = []
		for k in _chh_b.size():
			cb.append("%.3f, %.3f, %.3f" % [_chh_b[k].x, _chh_b[k].y, _chh_b[k].z])
			cs.append("%.3f" % _chh_s[k])
			cy.append("%.4f" % _chh_y[k])
			cn.append("%d" % _chh_n[k])
		_out.append("bases = PackedVector3Array(%s)" % ", ".join(cb))
		_out.append("scales = PackedFloat32Array(%s)" % ", ".join(cs))
		_out.append("yaws = PackedFloat32Array(%s)" % ", ".join(cy))
		_out.append("sides = PackedInt32Array(%s)" % ", ".join(cn))
		_out.append("")
	for m in _bank.keys():
		var items: Array = _bank[m]
		_out.append('[node name="gMal_%s" type="MultiMeshInstance3D" parent="%s"]' % [str(m).right(1), ZONE])
		_out.append('script = ExtResource("flock")')
		_out.append('model = ExtResource("%s")' % RES[m])
		var ps: Array[String] = []
		var ys: Array[String] = []
		var ss: Array[String] = []
		for it in items:
			var v: Vector3 = it[0]
			ps.append("%.3f, %.3f, %.3f" % [v.x, v.y, v.z])
			ys.append("%.3f" % float(it[1]))
			var sv: Vector3 = it[2] if it[2] is Vector3 else Vector3.ONE * float(it[2])
			ss.append("Vector3(%.3f, %.3f, %.3f)" % [sv.x, sv.y, sv.z])
		_out.append("positions = PackedVector3Array(%s)" % ", ".join(ps))
		_out.append("yaws = PackedFloat32Array(%s)" % ", ".join(ys))
		_out.append("scale3_list = Array[Vector3]([%s])" % ", ".join(ss))
		_out.append('tri_class = "rhyolite"')
		_out.append("")
	if not _floats.is_empty():
		_out.append('[node name="gCandeleLac" type="MultiMeshInstance3D" parent="%s"]' % ZONE)
		_out.append('script = ExtResource("flock")')
		_out.append('model = ExtResource("s_floating_diya")')
		var ps: Array[String] = []
		for v in _floats:
			ps.append("%.3f, %.3f, %.3f" % [v.x, v.y, v.z])
		_out.append("positions = PackedVector3Array(%s)" % ", ".join(ps))
		var ys: Array[String] = []
		for v in _float_yaw:
			ys.append("%.1f" % v)
		_out.append("yaws = PackedFloat32Array(%s)" % ", ".join(ys))
		_out.append("scale_min = 2.80")
		_out.append("scale_max = 3.00")
		_out.append("halo_enabled = true")
		_out.append("halo_reflect = 0.6")
		_out.append("halo_reflect_stretch = 5.0")
		_out.append("")


func _meta_last(line: String) -> void:
	_out.insert(_out.size() - 1, line)


# ------------------------------------------------------------------ iesire

func _raw(model: String, base: String, pos: Vector3, yaw: float, scl: float,
		mode: String) -> void:
	var b := Basis.from_euler(Vector3(0.0, yaw, 0.0)) * Basis.from_scale(Vector3(scl, scl, scl))
	_raw_basis(model, base, pos, b, mode)


func _raw_basis(model: String, base: String, pos: Vector3, b: Basis,
		mode: String) -> void:
	_n += 1
	_out.append('[node name="%s%d" parent="%s" instance=ExtResource("%s")]'
		% [base, _n, ZONE, RES[model]])
	# RANDURILE bazei, nu coloanele (memoria tscn-transform-e-pe-randuri).
	_out.append("transform = Transform3D(%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)"
		% [b.x.x, b.y.x, b.z.x, b.x.y, b.y.y, b.z.y, b.x.z, b.y.z, b.z.z,
			pos.x, pos.y, pos.z])
	if mode != "" and mode != "hull":
		_out.append('metadata/coliziune = "%s"' % mode)
	_out.append("")


func _write() -> void:
	print("; asezate %d piese" % _n)
	if _out_path.is_empty():
		for line in _out:
			print(line)
		return
	var fa := FileAccess.open(_out_path, FileAccess.WRITE)
	if fa == null:
		push_error("nu pot scrie %s" % _out_path)
		return
	for line in _out:
		fa.store_line(line)
	fa.close()
	print("; scris %s" % _out_path)


## Cota SOLULUI din coliziunea reala a panzei de teren (TerrainBody).
func _sol_real(x: float, z: float) -> float:
	if _terrain_rid == RID():
		for c in _track.get_children():
			if str(c.name) == "TerrainBody":
				_terrain_rid = (c as StaticBody3D).get_rid()
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(x, _sus_y, z), Vector3(x, _sus_y - 1200.0, z))
	q.collide_with_areas = false
	if _terrain_rid != RID():
		var hit: Dictionary = _space.intersect_ray(q)
		var guard := 0
		while not hit.is_empty() and hit["rid"] != _terrain_rid and guard < 24:
			q.exclude = q.exclude + [hit["rid"]]
			hit = _space.intersect_ray(q)
			guard += 1
		if not hit.is_empty() and hit["rid"] == _terrain_rid:
			return float(hit["position"].y)
	return _sampler.ground_y(x, z)


# ------------------------------------------------------------------ --mesh

## Harta de inaltimi (celule de 1 m, maximul y) a unui model din kit: de aici
## se iau muchiile teraselor cenotafului pentru sirurile de candele.
func _height_grid(path: String, cell: float) -> Dictionary:
	var root := (load("res://assets/models/jodhpur/%s.glb" % path) as PackedScene).instantiate()
	add_child(root)
	var grid := {}
	var lo := Vector3(INF, INF, INF)
	var hi := -lo
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var xf := _xf_to(m, root)
		for s in m.mesh.get_surface_count():
			var arr := m.mesh.surface_get_arrays(s)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			var tris := idx.size() / 3 if idx.size() > 0 else v.size() / 3
			for t in tris:
				var a := xf * v[idx[t * 3] if idx.size() > 0 else t * 3]
				var b := xf * v[idx[t * 3 + 1] if idx.size() > 0 else t * 3 + 1]
				var c := xf * v[idx[t * 3 + 2] if idx.size() > 0 else t * 3 + 2]
				# esantioneaza triunghiul (puncte baricentrice) ca sa umple celulele
				var n := maxi(int(maxf(a.distance_to(b), maxf(b.distance_to(c), c.distance_to(a))) / (cell * 0.5)), 1)
				for u in n + 1:
					for w in n + 1 - u:
						var p := a + (b - a) * (float(u) / n) + (c - a) * (float(w) / n)
						lo = lo.min(p)
						hi = hi.max(p)
						var k := Vector2i(int(floor(p.x / cell)), int(floor(p.z / cell)))
						grid[k] = maxf(grid.get(k, -INF), p.y)
	root.queue_free()
	return {"grid": grid, "lo": lo, "hi": hi}


func _mesh_report() -> void:
	for path in ["rocks/rock_slab", "rocks/rhyolite_boulder_a", "rocks/rhyolite_boulder_b"]:
		var rr := _height_grid(path, 0.25)
		var g: Dictionary = rr["grid"]
		print("; %s AABB %s .. %s" % [path, str(rr["lo"]), str(rr["hi"])])
		for z in range(int(floor(rr["lo"].z / 0.25)), int(ceil(rr["hi"].z / 0.25)), 2):
			var ln := "; "
			for x in range(int(floor(rr["lo"].x / 0.25)), int(ceil(rr["hi"].x / 0.25)), 2):
				var k := Vector2i(x, z)
				ln += ("%4.1f" % float(g[k])) if g.has(k) else "   ."
			print(ln)
	var r := _height_grid("structures/jaswant_thada", 1.0)
	var grid: Dictionary = r["grid"]
	var lo: Vector3 = r["lo"]
	var hi: Vector3 = r["hi"]
	print("; jaswant_thada AABB %s .. %s" % [str(lo), str(hi)])
	print("; harta de inaltimi, celula 1 m, x spre dreapta, z in jos (valori = y rotunjit)")
	for z in range(int(floor(lo.z)), int(ceil(hi.z))):
		var line := "; z%+3d " % z
		for x in range(int(floor(lo.x)), int(ceil(hi.x))):
			var k := Vector2i(x, z)
			if grid.has(k):
				line += "%5.1f" % float(grid[k])
			else:
				line += "    ."
		print(line)


func _xf_to(n: Node3D, root: Node) -> Transform3D:
	var xf := n.transform
	var p := n.get_parent()
	while p != null and p != root:
		if p is Node3D:
			xf = (p as Node3D).transform * xf
		p = p.get_parent()
	return xf
