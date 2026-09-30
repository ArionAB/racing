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

## Cenotaful: fractia de ancora pe drum, pe STANGA, dincolo de lac.
const THADA_FRAC := 0.898
## Soclul: rock_slab (2,5 x 0,8 x 4, blat plat pe interior +-1,0 / +-1,5).
const PLINTH_SX := 15.0
const PLINTH_SZ := 6.5
const PLINTH_ABOVE := 6.0

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
var _clusters: Array[Vector3] = []
var _thada_lat := 40.0
var _bank := {} # model -> [[pozitie, yaw, scara], ...]


func _build() -> void:
	_cenotaph()
	_left_massif()
	_right_edge()
	_trees()
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

func _cenotaph() -> void:
	var i := _idx(THADA_FRAC)
	var road := _track.baked[i]
	var L := _left(i)
	# Malul departat al lacului pe stanga: prima iesire din apa dupa ce ai
	# intrat in ea.
	var in_water := false
	var far := 40.0
	var lat := 10.0
	while lat < 90.0:
		var q := road + L * lat
		var g := _sol_real(q.x, q.z)
		if g < WATER_Y:
			in_water = true
		elif in_water and g > WATER_Y + 0.5:
			far = lat
			break
		lat += 0.5
	var front := far - 1.0
	var depth := 4.0 * PLINTH_SZ
	var yaw := atan2(L.x, L.z) # +Z local = departe de drum
	var basis := Basis.from_euler(Vector3(0.0, yaw, 0.0))
	var pc := road + L * (front + depth * 0.5)
	var ground_c := _sol_real(pc.x, pc.z)
	var top := maxf(ground_c, road.y) + PLINTH_ABOVE
	var lo := INF
	var X := basis.x
	for u: float in [-1.0, -0.5, 0.0, 0.5, 1.0]:
		for v: float in [-1.0, -0.5, 0.0, 0.5, 1.0]:
			var q := pc + X * (u * 1.25 * PLINTH_SX) + L * (v * 2.0 * PLINTH_SZ)
			lo = minf(lo, _sol_real(q.x, q.z))
	var base_y := lo - 0.3
	var sy := (top - base_y) / 0.8
	print("; cenotaf: malul departat la %.1f m, soclu %.1f..%.1f (sy %.2f), centru %s" % [
		far, base_y, top, sy, str(pc)])
	_raw_basis("rock_slab", "gSoclu", Vector3(pc.x, base_y, pc.z),
		basis * Basis.from_scale(Vector3(PLINTH_SX, sy, PLINTH_SZ)), "")
	_meta_last('metadata/scufundat = true')
	_obst.append(Vector3(pc.x, pc.z, 2.36 * PLINTH_SX * 0.95))
	# Treapta de jos spre apa (terasa la +2,5 peste apa), mai ingusta, in fata.
	var step_c := road + L * (front - 1.5)
	var step_top := WATER_Y + 2.8
	var step_lo := _ground_min(step_c, 6.0) - 0.3
	_raw_basis("rock_slab", "gSocluTreapta", Vector3(step_c.x, step_lo, step_c.z),
		basis * Basis.from_scale(Vector3(PLINTH_SX * 0.7, (step_top - step_lo) / 0.8, 1.6)), "none")
	_meta_last('metadata/scufundat = true')
	# Cenotaful: treptele (z local -10,3) la 3,5 m de fata soclului, pe blatul
	# plat.
	var tc := road + L * (front + 13.8)
	_thada_lat = front + 13.8 - 8.0
	tc.y = top
	_thada_c = tc
	_thada_xf = Transform3D(basis, tc)
	_raw_basis("jaswant_thada", "gCenotaf", tc, basis, "mesh")
	# Blocuri de riolit pe fata soclului si la picior, in apa (fantome: sunt
	# in rapa), mari si rare sus, marunte jos (gradient de moloz).
	for k in 14:
		var u := _rng.randf_range(-1.05, 1.05)
		var q := road + L * (front + _rng.randf_range(-2.5, 0.5)) + X * (u * 1.25 * PLINTH_SX)
		var m: String = BOULDERS[_rng.randi() % 3]
		var s := _rng.randf_range(1.6, 3.2) if k < 8 else _rng.randf_range(0.8, 1.5)
		_rock(m, "gSocluBloc", q, s, 1.0, -1.0)
	# Colturile soclului: doua blocuri inalte (silueta decupata, nu cutie).
	for sgn: float in [-1.0, 1.0]:
		var q := pc + X * (sgn * 1.25 * PLINTH_SX * 0.97) + L * _rng.randf_range(-6.0, 6.0)
		var g := _sol_real(q.x, q.z)
		var s := (top - g + 1.5) / 2.0
		_raw("rhyolite_boulder_a", "gSocluColt", Vector3(q.x, g - 0.5, q.z),
			_rng.randf_range(-PI, PI), clampf(s, 2.0, 5.0), "")
	# Candele: sir pe muchia din fata a blatului, inel pe tambur, sir pe
	# terasa a doua; festoane (StreetLights fara stalpi) pe platforma si
	# tambur.
	var xf := _thada_xf
	# muchia din fata a blatului plat (z local -10,5), de-a lungul lui
	var x := -0.97 * PLINTH_SX
	while x <= 0.97 * PLINTH_SX:
		_lamp("gCandeleCenotaf", xf * Vector3(x, 0.14, -10.5), 0.14)
		x += 0.9
	# terasa a doua (y 1,6): dreptunghi x +-7,8, z -4,8..5,6
	_rect_lamps(xf, Vector2(-7.8, -4.8), Vector2(7.8, 5.6), 1.6 + 0.12, 0.7, 0.12)
	# platforma de baza (y 0,9): x +-10,6, z -8,2..7,0
	_rect_lamps(xf, Vector2(-10.6, -8.2), Vector2(10.6, 7.0), 0.9 + 0.12, 0.8, 0.12)
	# tamburul (y 7,0), inel r 4,3
	for k in 30:
		var a := TAU * float(k) / 30.0
		_lamp("gCandeleCenotaf", xf * Vector3(cos(a) * 4.2, 7.0 + 0.12, sin(a) * 4.2), 0.12)
	# festoane: pe muchia platformei (prinse la +0,9 peste ea) si pe tambur
	_festoon_rect(xf, Vector2(-10.6, -8.2), Vector2(10.6, 7.0), 0.9 + 1.0, 3.5)
	var ring: Array[Vector3] = []
	for k in 12:
		var a := TAU * float(k) / 12.0
		ring.append(xf * Vector3(cos(a) * 4.5, 7.0 + 1.6, sin(a) * 4.5))
	for k in 12:
		_eaves.append(ring[k])
		_eaves.append(ring[(k + 1) % 12])
	# chhatri-urile din fata (x +-13, varf 4,2): festoane de la tambur la ele
	for sgn: float in [-1.0, 1.0]:
		_eaves.append(xf * Vector3(sgn * 4.5, 8.6, -1.0))
		_eaves.append(xf * Vector3(sgn * 12.8, 4.4, -3.5))
		_eaves.append(xf * Vector3(sgn * 4.5, 8.6, 1.0))
		_eaves.append(xf * Vector3(sgn * 10.0, 2.6, 6.8))


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

## Masivul de riolit pe STANGA coborarii (partea din afara buclei): aflorimente
## cu un miez inalt, lespezi cu blat luminat, bolovani medii si moloz marunt
## spre drum (densitatea creste spre drum, fara grila).
func _left_massif() -> void:
	var f := 0.707
	var count := 0
	while f < 0.858:
		var i := _idx(f)
		var road := _track.baked[i]
		var L := _left(i)
		var w := _track.width_at_index(i)
		var cs := _rng.randf_range(3.2, 5.2)
		var lat := w + 2.07 * cs + _rng.randf_range(GAP_MIN + 3.0, GAP_MIN + 16.0)
		var c := road + L * lat
		if _outcrop(c, i, cs, 1.0):
			count += 1
		f += _rng.randf_range(0.006, 0.010)
	print("; aflorimente stanga: %d" % count)


## Un afloriment: miez + lespezi + bolovani + moloz. `side` +1 = stanga.
func _outcrop(c: Vector3, i: int, core_s: float, side: float) -> bool:
	var core: String = BIG[_rng.randi() % 2]
	var cr0: float = CORNER[core] * core_s
	# tot aflorimentul (miez + moloz spre drum) e un singur obstacol
	for o in _clusters:
		if Vector2(c.x - o.x, c.z - o.y).length() < o.z + cr0 * 1.6:
			return false
	var road := _track.baked[i]
	var to_road := Vector3(road.x - c.x, 0.0, road.z - c.z).normalized()
	# Miezul: 2-4 STALPI de riolit (rock_slab intins pe verticala: blat plat,
	# fete fatetate) de inaltimi diferite, lipiti unul de altul — blocuri
	# mari cu silueta in trepte. Runda 1, prima captura: un bolovan scalat x4
	# citea piramida rosie, nu bloc.
	var k0 := core_s / 3.5
	var yaw0 := _rng.randf_range(-PI, PI)
	var h0 := core_s * 2.0
	if not _pillar(c, _rng.randf_range(1.3, 2.0) * k0, h0, _rng.randf_range(0.9, 1.3) * k0,
			yaw0, GAP_MIN + 3.0, to_road):
		return false
	_ignore_overlap = true
	for k in _rng.randi_range(1, 3):
		var a := _rng.randf_range(-PI, PI)
		var q := c + Vector3(cos(a), 0, sin(a)) * cr0 * _rng.randf_range(0.35, 0.7)
		_pillar(q, _rng.randf_range(1.0, 1.8) * k0, h0 * _rng.randf_range(0.45, 0.85),
			_rng.randf_range(0.8, 1.3) * k0, yaw0 + _rng.randf_range(-0.6, 0.6), GAP_MIN + 1.0, to_road)
	var T := Vector3(-to_road.z, 0.0, to_road.x)
	var cr: float = CORNER[core] * core_s
	# lespezi: blat plat la 1,8-3,2 m, lipite de miez spre drum / lateral
	for k in _rng.randi_range(1, 2):
		var off := to_road * cr * _rng.randf_range(0.5, 0.9) + T * cr * _rng.randf_range(-0.9, 0.9)
		var q := c + off
		var sx := _rng.randf_range(2.2, 3.4)
		var sz := _rng.randf_range(1.8, 2.8)
		var sy := _rng.randf_range(2.3, 4.0)
		var r := Vector2(1.25 * sx, 2.0 * sz).length()
		if not _solid_ok(q, r, GAP_MIN, -r * 0.5):
			continue
		var yaw := atan2(to_road.x, to_road.z) + _rng.randf_range(-0.5, 0.5)
		var bas := Basis.from_euler(Vector3(0.0, yaw, 0.0)) * Basis.from_scale(Vector3(sx, sy, sz))
		var g := _ground_min(q, r * 0.5)
		_raw_basis("rock_slab", "gLespede", Vector3(q.x, g - 0.2, q.z), bas, "")
		_obst.append(Vector3(q.x, q.z, r * 0.8))
		# sir de candele pe muchia blatului dinspre drum (z local -1,5 dupa
		# yaw: +Z local e spre drum)
		var top := g - 0.2 + 0.8 * sy
		var xf := Transform3D(Basis.from_euler(Vector3(0.0, yaw, 0.0)), Vector3(q.x, 0.0, q.z))
		var x := -1.0 * sx
		while x <= 1.0 * sx:
			var p := xf * Vector3(x, 0.0, 1.45 * sz)
			p.y = top + 0.12
			_lamp("gCandeleStanca", p, 0.12)
			x += 0.75
	# bolovani medii in jurul miezului
	for k in _rng.randi_range(2, 4):
		var a := _rng.randf_range(-PI, PI)
		var q := c + Vector3(cos(a), 0, sin(a)) * cr * _rng.randf_range(0.8, 1.3) + to_road * cr * 0.3
		_rock(BOULDERS[_rng.randi() % 3], "gBolovan", q, _rng.randf_range(1.2, 2.2), GAP_MIN, -0.3)
	# moloz marunt, spre drum (gradient)
	for k in _rng.randi_range(4, 8):
		var q := c + to_road * cr * _rng.randf_range(1.1, 2.4) + T * cr * _rng.randf_range(-1.4, 1.4)
		_rock(BOULDERS[_rng.randi() % 3], "gMoloz", q, _rng.randf_range(0.35, 0.8), GAP_MIN - 1.0, 0.1)
	# o euforbie la picior
	if _rng.randf() < 0.6:
		var q := c + to_road * cr * 1.2 + T * cr * _rng.randf_range(-1.0, 1.0)
		if _solid_ok(q, 0.45, GAP_MIN, 0.3):
			_raw("euphorbia", "gEuforbie", Vector3(q.x, _sol_real(q.x, q.z) - 0.05, q.z),
				_rng.randf_range(-PI, PI), _rng.randf_range(0.9, 1.3), "")
			_obst.append(Vector3(q.x, q.z, 0.45))
	_ignore_overlap = false
	_clusters.append(Vector3(c.x, c.z, cr0 * 1.6))
	return true


## Un stalp de riolit: rock_slab cu scara (sx, inaltime/0,8, sz), corp hull.
func _pillar(q: Vector3, sx: float, h: float, sz: float, yaw: float, gap: float,
		to_road: Vector3) -> bool:
	var r := Vector2(1.25 * sx, 2.0 * sz).length()
	if _in_ravine(q) or not _solid_ok(q, r, gap, 0.3):
		return false
	var g := _ground_min(q, r * 0.6) - 0.3
	var sy := (h + 0.3) / 0.8
	var bas := Basis.from_euler(Vector3(0.0, yaw, 0.0)) * Basis.from_scale(Vector3(sx, sy, sz))
	_raw_basis("rock_slab", "gStalp", Vector3(q.x, g, q.z), bas, "")
	_obst.append(Vector3(q.x, q.z, r * 0.8))
	return true


## Marginea DREAPTA (spre oras): sir de bolovani `hull` pe margine (contract),
## la pas neregulat, si aflorimente joase la 10-20 m (orasul trebuie sa se
## citeasca peste ele).
func _right_edge() -> void:
	var f := 0.706
	var n := 0
	while f < 0.852:
		var i := _idx(f)
		var road := _track.baked[i]
		var R := -_left(i)
		var w := _track.width_at_index(i)
		var m: String = BOULDERS[_rng.randi() % 3]
		var s := _rng.randf_range(0.9, 1.6)
		var lat: float = w + EDGE_ROW_GAP + float(CORNER[m]) * s + _rng.randf_range(0.0, 1.2)
		if _rock(m, "gMargine", road + R * lat, s, EDGE_ROW_GAP, 0.3):
			n += 1
			# uneori un al doilea, mai mic, lipit in spate
			if _rng.randf() < 0.45:
				_rock(BOULDERS[_rng.randi() % 3], "gMargine",
					road + R * (lat + _rng.randf_range(1.8, 3.0)) + _tangent(i) * _rng.randf_range(-1.5, 1.5),
					_rng.randf_range(0.5, 1.0), EDGE_ROW_GAP + 1.0, -0.3)
		f += _rng.randf_range(0.0035, 0.008)
	print("; bolovani de margine dreapta: %d" % n)
	var f2 := 0.712
	var k := 0
	while f2 < 0.852:
		var i := _idx(f2)
		var road := _track.baked[i]
		var R := -_left(i)
		var w := _track.width_at_index(i)
		var cs := _rng.randf_range(1.8, 2.8)
		var c := road + R * (w + 2.07 * cs + _rng.randf_range(GAP_MIN + 3.0, GAP_MIN + 10.0))
		# pe 0.70-0.73 terenul cade la 30 m pe dreapta: doar pe sol plat
		if absf(_sol_real(c.x, c.z) - road.y) < 1.2 and _outcrop(c, i, cs, -1.0):
			k += 1
		f2 += _rng.randf_range(0.016, 0.026)
	print("; aflorimente dreapta: %d" % k)


## Copaci (khejri, neem) pe ambele parti, la 4-12 m de margine: coroanele
## umbresc marginea asfaltului in prim-plan (memoria contrastul-e-umbra).
func _trees() -> void:
	var f := 0.708
	var n := 0
	while f < 0.905:
		var i := _idx(f)
		var road := _track.baked[i]
		var sgn := 1.0 if _rng.randf() < 0.5 else -1.0
		var w := _track.width_at_index(i)
		var q := road + _left(i) * sgn * (w + _rng.randf_range(4.5, 12.0))
		var model := "khejri_tree" if _rng.randf() < 0.55 else "neem_tree"
		if not _in_ravine(q) and _solid_ok(q, 0.5, 4.0, 1.5):
			_raw(model, "gCopac", Vector3(q.x, _sol_real(q.x, q.z) - 0.1, q.z),
				_rng.randf_range(-PI, PI), _rng.randf_range(0.85, 1.2), "")
			_obst.append(Vector3(q.x, q.z, 0.5))
			n += 1
			# tufa de euforbii langa trunchi
			for k in _rng.randi_range(1, 3):
				var e := q + Vector3(_rng.randf_range(-3, 3), 0, _rng.randf_range(-3, 3))
				if not _in_ravine(e) and _solid_ok(e, 0.45, 3.0, 0.2):
					_raw("euphorbia", "gEuforbie", Vector3(e.x, _sol_real(e.x, e.z) - 0.05, e.z),
						_rng.randf_range(-PI, PI), _rng.randf_range(0.7, 1.2), "")
					_obst.append(Vector3(e.x, e.z, 0.45))
		f += _rng.randf_range(0.0035, 0.007)
	print("; copaci: %d" % n)


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
				if _rng.randf() < pr:
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
			ss.append("Vector3(%.3f, %.3f, %.3f)" % [float(it[2]), float(it[2]), float(it[2])])
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
