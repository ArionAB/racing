class_name TrackSideSampler
extends RefCounted
## Singura sursa de adevar pentru "unde e loc langa drum".
##
## Toti generatorii de decor (faleze, prop-uri, garduri) cer sloturi de aici in
## loc sa-si refaca propria matematica peste [code]baked[/code]. Doua motive:
##   - regulile de siguranta (apex, franare, distanta fata de alta bucla a
##     pistei) se scriu O DATA si se aplica peste tot;
##   - esantionarea se face in ARC-LENGTH, nu pe indici. Punctele coapte sunt
##     la ~3m distanta pe drept, dar in viraje stranse se inghesuie; a numara
##     indici ar da prop-uri dese in viraje si rare pe drepte, exact invers
##     decat vrem.
##
## Nimeni nu modifica starea de aici — samplerul e read-only dupa constructie.

## Peste pragul asta de curbura normalizata, slotul e "apex": nimic inalt, si
## falezele se retrag ca sa ramana loc de depasire.
##
## Calibrat pe Dunele, nu ales din burta: curbura acolo e p50=0.04, p90=0.11,
## p99=0.29, max=0.43. Prima valoare incercata (0.55) era peste maximul pistei,
## deci NICIUN slot nu se marca vreodata ca apex — regula exista in cod dar nu
## se aplica nicaieri. La 0.18 prinde ultimele ~5% dintre puncte, adica exact
## virajele stranse.
const APEX_CURVATURE: float = 0.18
## Cat de departe in fata se cauta un viraj ca sa marchezi zona de franare.
const BRAKING_LOOKAHEAD_M: float = 25.0
## Cat de dese sunt punctele testate cand se cauta cea mai apropiata bucla de
## pista. Stride 1 = exact ca vechea bucla din track.gd; costa O(n) per apel,
## dar apelurile sunt cateva sute la generare, o singura data.
const CLEARANCE_STRIDE: int = 1

var _baked: PackedVector3Array
var _dists: PackedFloat32Array
var _loop_poly: PackedVector2Array
var _half_width: float
var _total_len: float
## Curbura precalculata per index — se cere de multe ori, se calculeaza o data.
var _curvature: PackedFloat32Array


func _init(baked: PackedVector3Array, dists: PackedFloat32Array,
		control_points: Array[Vector3], half_width: float) -> void:
	_baked = baked
	_dists = dists
	_half_width = half_width
	_total_len = dists[baked.size()] if dists.size() > baked.size() else 0.0
	_loop_poly = PackedVector2Array()
	for p in control_points:
		_loop_poly.append(Vector2(p.x, p.z))
	_bake_curvature()


## Numarul de puncte coapte — util consumatorilor care itereaza direct.
func point_count() -> int:
	return _baked.size()


## Lungimea totala a turului, in metri.
func total_length() -> float:
	return _total_len


## Jumatatea de latime a soselei — offseturile se dau fata de MARGINE, dar
## unii consumatori au nevoie si de distanta pana la axa.
func half_width() -> float:
	return _half_width


## Un punct copt al axei pistei (pentru limite, iteratii proprii).
func baked_point(i: int) -> Vector3:
	var n := _baked.size()
	return _baked[((i % n) + n) % n]


## Versorul lateral (spre dreapta sensului de mers) la un index dat.
func side_at(i: int) -> Vector3:
	var n := _baked.size()
	var dir := (_baked[(i + 1) % n] - _baked[i]).normalized()
	return dir.cross(Vector3.UP).normalized()


## Curbura locala normalizata in [0..1]: 0 = drept, 1 = ac de par.
func curvature_at(index: int) -> float:
	var n := _curvature.size()
	if n == 0:
		return 0.0
	return _curvature[((index % n) + n) % n]


## Distanta laterala minima fata de ORICE punct al pistei.
##
## Nu e acelasi lucru cu offsetul slotului: Dunele se auto-intersecteaza (in
## sud-vest curba trece la ~40m de ea insasi), deci o banda de decor de 26m de
## pe o bucla poate ateriza fix pe soseaua celeilalte. Verificarea asta e
## singura care prinde cazul.
func clearance_at(pos: Vector3) -> float:
	var nearest_sq := INF
	var n := _baked.size()
	var i := 0
	while i < n:
		var dx := _baked[i].x - pos.x
		var dz := _baked[i].z - pos.z
		nearest_sq = minf(nearest_sq, dx * dx + dz * dz)
		i += CLEARANCE_STRIDE
	return sqrt(nearest_sq)


## Sloturi pe o BANDA laterala, la pas constant in arc-length, cu offset
## aleator in intervalul dat. Pentru decor imprastiat (pietre, cactusi, tufe).
##
## `rng` e consumat determinist: acelasi seed -> acelasi peisaj.
func sample_band(spacing_m: float, offset_min: float, offset_max: float,
		rng: RandomNumberGenerator) -> Array[TrackDecorSpec]:
	var out: Array[TrackDecorSpec] = []
	if _total_len <= 0.0 or spacing_m <= 0.0:
		return out
	var d := 0.0
	while d < _total_len:
		for side_sign: float in [-1.0, 1.0]:
			var off := rng.randf_range(offset_min, offset_max)
			var spec := _make_spec(d, side_sign, off)
			if spec != null:
				out.append(spec)
		# jitter longitudinal: altfel iese un gard de prop-uri echidistante
		d += spacing_m * rng.randf_range(0.75, 1.25)
	return out


## Sloturi pe MARGINEA drumului, la pas fix si offset fix — fara niciun jitter.
## Pentru faleze: sectiunile trebuie sa se atinga cap la cap, iar o variatie
## de pas ar lasa fisuri (vizibile, si — mai rau — capcane de coliziune).
func sample_edge(spacing_m: float, offset: float) -> Array[TrackDecorSpec]:
	var out: Array[TrackDecorSpec] = []
	if _total_len <= 0.0 or spacing_m <= 0.0:
		return out
	var d := 0.0
	while d < _total_len:
		for side_sign: float in [-1.0, 1.0]:
			var spec := _make_spec(d, side_sign, offset)
			if spec != null:
				out.append(spec)
		d += spacing_m
	return out


## Intervalele (start_m, end_m) in care marginea e "inchisa", adica unde vechea
## regula de perete cerea gard: pe exteriorul circuitului mereu, pe interior
## doar unde soseaua e inaltata. Falezele se aseaza exact aici, iar popicele
## marcheaza restul — ambele citesc aceeasi sursa, deci nu se pot contrazice.
func wall_segments(side_sign: float) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var n := _baked.size()
	if n == 0:
		return out
	var run_start := -1.0
	for i in n:
		var j := (i + 1) % n
		var b0 := _baked[i] + side_at(i) * _half_width * side_sign
		var b1 := _baked[j] + side_at(j) * _half_width * side_sign
		var mid := (b0 + b1) * 0.5
		var closed := (not Geometry2D.is_point_in_polygon(
			Vector2(mid.x, mid.z), _loop_poly)) or mid.y > 1.0
		if closed and run_start < 0.0:
			run_start = _dists[i]
		elif not closed and run_start >= 0.0:
			out.append(Vector2(run_start, _dists[i]))
			run_start = -1.0
	if run_start >= 0.0:
		out.append(Vector2(run_start, _total_len))
	return out


## Distanta `d` (in metri, pe traseu) cade intr-unul din intervale?
static func in_segments(d: float, segments: Array[Vector2]) -> bool:
	for seg in segments:
		if d >= seg.x and d <= seg.y:
			return true
	return false


# ------------------------------------------------------------------ intern

## Construieste un slot la distanta `d` pe traseu. Intoarce null daca locul e
## respins (prea aproape de alta bucla a pistei).
func _make_spec(d: float, side_sign: float, offset: float) -> TrackDecorSpec:
	var idx := _index_at_distance(d)
	var n := _baked.size()
	var base := _baked[idx]
	var along := (_baked[(idx + 1) % n] - base).normalized()
	var side := along.cross(Vector3.UP).normalized() * side_sign
	var pos := base + side * (_half_width + offset)
	pos.y = base.y

	# Respins daca ar cadea peste alta bucla a pistei. Marja de 1m: vrem sa
	# permitem slotul propriu (care e la exact half_width + offset), dar nu unul
	# care s-a apropiat de o sosea vecina.
	if clearance_at(pos) < _half_width + offset - 1.0:
		return null

	var spec := TrackDecorSpec.new()
	spec.position = pos
	spec.normal_out = side
	spec.along = along
	spec.index = idx
	spec.frac = d / _total_len if _total_len > 0.0 else 0.0
	spec.side_sign = side_sign
	spec.offset = offset
	spec.is_exterior = not Geometry2D.is_point_in_polygon(
		Vector2(pos.x, pos.z), _loop_poly)
	spec.is_elevated = base.y > 1.0
	spec.is_apex = curvature_at(idx) > APEX_CURVATURE
	spec.is_braking = _braking_ahead(d)
	return spec


## Indexul punctului copt de la distanta `d` pe traseu. Cauta binar in _dists,
## care e monoton crescator.
func _index_at_distance(d: float) -> int:
	var n := _baked.size()
	if n == 0:
		return 0
	var lo := 0
	var hi := n - 1
	while lo < hi:
		var mid := (lo + hi + 1) / 2
		if _dists[mid] <= d:
			lo = mid
		else:
			hi = mid - 1
	return lo


## Exista un viraj stramt in urmatorii BRAKING_LOOKAHEAD_M metri?
func _braking_ahead(d: float) -> bool:
	var step := 4.0
	var scanned := 0.0
	while scanned < BRAKING_LOOKAHEAD_M:
		scanned += step
		var probe := fmod(d + scanned, _total_len) if _total_len > 0.0 else d
		if curvature_at(_index_at_distance(probe)) > APEX_CURVATURE:
			return true
	return false


## Curbura per index, o singura data la constructie.
##
## Se masoara unghiul dintre directia dinainte si cea de dupa, peste o baza de
## ~9m (3 puncte coapte) — destul de larg cat sa nu tresara la zgomotul de
## bake, destul de strans cat sa prinda un ac de par. Normalizat astfel incat
## un viraj de 90° pe baza aia sa dea ~1.0.
func _bake_curvature() -> void:
	var n := _baked.size()
	_curvature = PackedFloat32Array()
	_curvature.resize(n)
	if n < 7:
		return
	for i in n:
		var before := (_baked[i] - _baked[(i - 3 + n) % n]).normalized()
		var after := (_baked[(i + 3) % n] - _baked[i]).normalized()
		_curvature[i] = clampf(before.angle_to(after) / (PI * 0.5), 0.0, 1.0)
