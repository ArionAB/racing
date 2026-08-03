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

# --- campul de inaltime al terenului ---
## Cat de departe de sosea terenul mai sta exact la cota drumului.
const GROUND_FLAT_RADIUS: float = 45.0
## Peste cati metri se trece de la cota drumului la dunele libere.
const GROUND_BLEND_LEN: float = 70.0
## Raza in care o bucata de sosea mai conteaza pentru inaltimea terenului.
## Trebuie sa acopere TOATA zona de blend (45+70=115), altfel raman puncte fara
## nicio pondere si ar trebui inventata o cota pentru ele.
const GROUND_ROAD_RADIUS: float = 130.0
## Latimea "varfului" ponderii. Sub ea domina punctul cel mai apropiat; peste,
## intra si vecinii. Tinuta >= pasul de esantionare (~6 m), altfel terenul
## capata margele: un cocoas mic in dreptul fiecarui punct copt.
const GROUND_WEIGHT_SOFT: float = 7.0
## Din 2 in 2 puncte coapte = ~6 m.
const GROUND_STRIDE: int = 2
## Cat sta nisipul sub cota asfaltului (buza umarului).
const GROUND_DROP: float = 0.30

# --- racorduri netede intre campuri de inaltime ---
## Min/max-urile dure dintre campuri (rapa vs. teren, banda secundara vs. fund
## de mare, dune vs. podeaua vailor) lasau cute C0: discontinuitati de panta
## care, la un pas de grila de ~8 m, se citesc ca muchii drepte trase cu rigla
## (issue #97). k = latimea racordului, in metri.
const SMOOTH_RAVINE_K: float = 3.0
const SMOOTH_BRANCH_K: float = 2.0
const SMOOTH_FLOOR_K: float = 0.8

## Rapa: de la cati metri dincolo de marginea asfaltului incepe saparea.
const RAVINE_INNER: float = 4.0
## Peste cati metri se coboara pana la fundul rapei.
const RAVINE_RIM: float = 16.0
## Margini line pe traseu, in fractii de tur.
const RAVINE_FADE_FRAC: float = 0.02

var _baked: PackedVector3Array
var _dists: PackedFloat32Array
var _loop_poly: PackedVector2Array
var _half_width: float
var _total_len: float
## Curbura precalculata per index — se cere de multe ori, se calculeaza o data.
var _curvature: PackedFloat32Array
## Faza zgomotului de dune, ca terenul sa difere de la o pista la alta.
var _dune_phase: float = 0.0
## Campul de dune: FBM de simplex, instantiat O DATA — ground_y se apeleaza de
## zeci de mii de ori la generare si nu are voie sa construiasca obiecte.
var _noise: FastNoiseLite
## Cota medie a drumului — ancora campului DEPARTAT (vezi ground_y).
var _mean_y: float = 0.0
## Rapele declarate: (frac_start, frac_end, adancime, latura).
var _ravines: Array[Vector4] = []
## Cat de adanc cade campul DEPARTAT sub media soselei. 0 = uscat (desert,
## padure); > 0 = fund de mare (insula). Vezi ground_y.
var _far_drop: float = 0.0
## Puncte de pe benzile SECUNDARE (scurtaturi). Terenul le urmeaza cota ca pe a
## soselei, iar decorul le ocoleste — altfel scurtatura ar pluti peste fundul de
## mare si i-ar rasari palmieri prin mijloc.
var _extra: PackedVector3Array = PackedVector3Array()


func _init(baked: PackedVector3Array, dists: PackedFloat32Array,
		control_points: Array[Vector3], half_width: float,
		dune_phase: float = 0.0, ravines: Array[Vector4] = [],
		far_drop: float = 0.0,
		extra_corridors: PackedVector3Array = PackedVector3Array()) -> void:
	_baked = baked
	_dists = dists
	_half_width = half_width
	_dune_phase = dune_phase
	_ravines = ravines
	_far_drop = far_drop
	_extra = extra_corridors
	_total_len = dists[baked.size()] if dists.size() > baked.size() else 0.0
	_loop_poly = PackedVector2Array()
	for p in control_points:
		_loop_poly.append(Vector2(p.x, p.z))
	var sum_y := 0.0
	for p in baked:
		sum_y += p.y
	_mean_y = sum_y / float(maxi(baked.size(), 1))
	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	# Octava de baza ~200 m (dealuri), inca doua pana la ~50 m (ondulatii).
	# Sub 50 m nu coboram: grila de teren e la 7.9 m si ar aparea aliasing.
	_noise.frequency = 0.005
	_noise.fractal_octaves = 3
	# Seed derivat din faza veche: pistele raman diferite intre ele, iar 0
	# ramane 0 (Dunele isi pastreaza samanta implicita).
	_noise.seed = int(roundf(dune_phase * 1000.0))
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


## Cota terenului la o pozitie din lume. SURSA UNICA pentru tot ce se aseaza pe sol.
##
## Inainte, terenul era aplatizat la o cota CONSTANTA IN LUME (-0.3) in timp ce
## tot restul se aseza la cota drumului. Pe Dunele, unde 71% din traseu e peste
## 3 m si varful e la 19 m, asta insemna ca benzinaria, turnul si moara pluteau
## in aer — iar sub asfalt erau 16 m de gol la creasta, ascunsi doar partial de
## fusta de 3 m. Nu plutea decorul, plutea lumea.
##
## Acum terenul URMAREste drumul: exact la cota lui in primii 45 m, apoi se
## pierde in dune peste urmatorii 70.
##
## Ponderare cu SUPORT COMPACT, nu Shepard clasic:
##   - (1 - d/R)^4 taie orice munca peste 130 m;
##   - 1/(d^2 + soft^2) face ca ramura CEA MAI APROPIATA sa domine in loc sa fie
##     mediata cu una departata.
## Conteaza pe pistele care se auto-intersecteaza: pe Dunele, punctul (-82,11,-92)
## are la ~31 m lateral ramura de intoarcere, cu 8.6 m mai jos. Cu ponderile astea
## ramura departata trage in jos ~0.5 m (sub umar, invizibil); cu "cel mai apropiat
## punct" simplu ar fi iesit o muchie de cutit de 8.6 m.
func ground_y(wx: float, wz: float) -> float:
	var num := 0.0
	var den := 0.0
	var near_sq := INF
	var near_i := 0
	var r_sq := GROUND_ROAD_RADIUS * GROUND_ROAD_RADIUS
	var soft_sq := GROUND_WEIGHT_SOFT * GROUND_WEIGHT_SOFT
	var n := _baked.size()
	if n == 0:
		return -GROUND_DROP
	var i := 0
	while i < n:
		var p := _baked[i]
		var dx := p.x - wx
		var dz := p.z - wz
		var d_sq := dx * dx + dz * dz
		if d_sq < near_sq:
			near_sq = d_sq
			near_i = i
		if d_sq < r_sq:
			var u := 1.0 - sqrt(d_sq) / GROUND_ROAD_RADIUS
			var w := (u * u) * (u * u) / (d_sq + soft_sq)
			num += w * p.y
			den += w
		i += GROUND_STRIDE
	var road_level := (num / den) if den > 0.0 else _mean_y
	var dist := sqrt(near_sq)
	var t := clampf((dist - GROUND_FLAT_RADIUS) / GROUND_BLEND_LEN, 0.0, 1.0)
	# Campul departat se ancoreaza la media cotelor drumului, NU la zero: altfel
	# toata pista ar sta pe un platou cu o faleza de 19 m la 115 m distanta. Cu
	# media, desertul ondulează IMPREUNA cu traseul — creasta citeste ca mesa,
	# portiunile joase ca vai.
	# Clamp NETED la podeaua vailor: cel dur lasa lacuri perfect plate cu
	# margine de rigla acolo unde dunele coboara sub -1 m (issue #97).
	var far_level := _mean_y + _smax(_dunes(wx, wz), -1.0, SMOOTH_FLOOR_K)
	# INTERIORUL buclei ramane uscat, oricat de departe de sosea ar fi.
	#
	# Fara conditia asta, o insula iesea ca o panglica de nisip lata de 230 m
	# care urmareste drumul, cu mare in mijlocul circuitului — la propriu, un
	# atol. Se vede imediat dintr-o captura de sus si deloc din masina, motiv
	# pentru care merita spus: singurul lucru care o prinde e sa te uiti.
	#
	# Poligonul e cel al punctelor de control, deja folosit de _build_walls ca sa
	# decida ce margine e exterioara. O singura definitie pentru "inauntru".
	var inside := _loop_poly.size() >= 3 \
		and Geometry2D.is_point_in_polygon(Vector2(wx, wz), _loop_poly)
	if _far_drop > 0.0 and not inside:
		# Insula: dincolo de coridorul pistei, terenul devine FUND DE MARE.
		#
		# Fara asta o pista de insula e imposibila, si nu dintr-un motiv estetic:
		# campul departat se ancoreaza la media cotelor soselei, deci nu coboara
		# niciodata sub ea. Un plan de apa peste el e ori complet ingropat (cota
		# mica), ori inunda si soseaua (cota mare) — nu exista pozitie din care
		# sa iasa o insula.
		#
		# Relieful de fund pastreaza doar un sfert din amplitudinea dunelor. Nu e
		# cosmetica: adancimea trebuie sa treaca DECIS de pragul dincolo de care
		# apa nu-si mai schimba culoarea (Track.SEA_NEAR_DEPTH). Cu dune la
		# amplitudine plina, adancimea oscila peste si sub prag, iar grila fina de
		# tarm se emitea pe toata suprafata marii — masurat: 12 800 de triunghiuri
		# in loc de ~2 000.
		far_level = _mean_y - _far_drop \
			+ _smax(_dunes(wx, wz), -1.0, SMOOTH_FLOOR_K) * 0.25
	var y := lerpf(road_level, far_level, t * t)
	y = _lift_branches(y, wx, wz)
	return _carve_ravines(y, road_level, dist, near_i, wx, wz) - GROUND_DROP


## Cat de departe de axa unei benzi secundare terenul mai sta la cota ei.
##
## MULT mai stramt decat pentru sosea (45 m + 70 m blend), si asta e chiar
## ideea. Prima versiune baga punctele scurtaturii in acelasi camp Shepard ca
## soseaua: bancul de nisip ridica atunci o limba de teren lata de 230 m, care
## umplea golful pe care tocmai il taia. Ceea ce trebuia sa fie o fasie de nisip
## in apa iesea un istm, iar scurtatura nu se mai citea ca alegere.
const BRANCH_FLAT_RADIUS: float = 11.0
const BRANCH_BLEND_LEN: float = 16.0


## Ridica terenul la cota benzilor secundare, dar doar chiar langa ele.
func _lift_branches(y: float, wx: float, wz: float) -> float:
	var m := _extra.size()
	if m == 0:
		return y
	var reach := BRANCH_FLAT_RADIUS + BRANCH_BLEND_LEN
	var reach_sq := reach * reach
	var near_sq := INF
	var level := 0.0
	var k := 0
	while k < m:
		var q := _extra[k]
		var dx := q.x - wx
		var dz := q.z - wz
		var d_sq := dx * dx + dz * dz
		if d_sq < near_sq:
			near_sq = d_sq
			level = q.y
		k += GROUND_STRIDE
	if near_sq > reach_sq:
		return y
	var d := sqrt(near_sq)
	var t := clampf((d - BRANCH_FLAT_RADIUS) / BRANCH_BLEND_LEN, 0.0, 1.0)
	# max, nu lerp pur: banda nu SAPA niciodata terenul, doar il ridica. Acolo
	# unde trece peste uscat mai inalt (racordurile cu soseaua), ramane uscatul.
	# Neted, ca racordul banc-de-nisip -> fund de mare sa nu aiba muchie.
	return _smax(y, lerpf(level, y, t * t), SMOOTH_BRANCH_K)


## Suntem intr-o rapa declarata la fractia si latura date?
##
## Publica pentru ca sonda de anti-blocaj trebuie sa sara sloturile de rapa —
## altfel ar testa "cad intr-o groapa" in loc de "ma prinde o imbinare de faleza".
func ravine_at(frac: float, side_sign: float) -> bool:
	for r in _ravines:
		if not is_zero_approx(r.w) and signf(r.w) != signf(side_sign):
			continue
		if _ring_window(frac, r.x, r.y, RAVINE_FADE_FRAC) > 0.0:
			return true
	return false


## Cota medie a drumului — reper pentru nuantarea terenului dupa inaltimea
## RELATIVA. Cea absoluta functiona doar cat timp terenul statea in jurul lui zero.
func mean_road_y() -> float:
	return _mean_y


## Adancimea maxima declarata, ca podeaua lumii sa fie pusa sub ea.
func max_ravine_depth() -> float:
	var d := 0.0
	for r in _ravines:
		d = maxf(d, r.z)
	return d


## Sapa rapele declarate in campul de inaltime.
##
## Fara ele, terenul care urmareste soseaua umple exact golul in care era gandita
## drama fly-off-ului: zbori de pe creasta si aterizezi linistit pe nisip.
func _carve_ravines(y: float, road_level: float, dist: float, near_i: int,
		wx: float, wz: float) -> float:
	if _ravines.is_empty():
		return y
	var f := _dists[near_i] / _total_len if _total_len > 0.0 else 0.0
	for r in _ravines:
		if not is_zero_approx(r.w) and signf(r.w) != _side_sign_at(near_i, wx, wz):
			continue
		var along := _ring_window(f, r.x, r.y, RAVINE_FADE_FRAC)
		if along <= 0.0:
			continue
		var lat := smoothstep(0.0, 1.0,
			clampf((dist - _half_width - RAVINE_INNER) / RAVINE_RIM, 0.0, 1.0))
		# min: rapa SAPA, nu ridica. Altfel o rapa pe o portiune joasa ar
		# construi un dig in loc de o groapa. Neted: buza rapei era o cusatura
		# C0 trasa cu rigla peste RAVINE_RIM (16 m ~ doua celule de grila).
		y = _smin(y, road_level - r.z * along * lat, SMOOTH_RAVINE_K)
	return y


## Pe ce parte a drumului cade un punct, fata de indexul dat.
func _side_sign_at(idx: int, wx: float, wz: float) -> float:
	var s := side_at(idx)
	var p := _baked[idx]
	return signf(Vector2(s.x, s.z).dot(Vector2(wx - p.x, wz - p.z)))


## Minim neted polinomial: coincide cu minf departe de intersectie, rotunjeste
## muchia pe o banda de ~k metri. Rezultatul e <= minf(a, b), deci "sapa, nu
## ridica" ramane adevarat oriunde se foloseste in loc de minf.
static func _smin(a: float, b: float, k: float) -> float:
	var h := clampf(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
	return lerpf(b, a, h) - k * h * (1.0 - h)


## Maxim neted — oglinda lui _smin; rezultatul e >= maxf(a, b).
static func _smax(a: float, b: float, k: float) -> float:
	return -_smin(-a, -b, k)


## Fereastra circulara [f0,f1] cu margini line. f1 < f0 = trece peste linia de start.
static func _ring_window(f: float, f0: float, f1: float, fade: float) -> float:
	var span := fposmod(f1 - f0, 1.0)
	var into := fposmod(f - f0, 1.0)
	if into > span:
		return 0.0
	return clampf(minf(into, span - into) / maxf(fade, 0.0001), 0.0, 1.0)


## Dunele campului departat.
##
## A fost suma a trei sinusoide (2.2/2.0/1.3, lungimi de unda 200-520 m) —
## un cofraj de oua cu perioada vizibila, care citea procedural indiferent
## cat de fin era esantionat (issue #96). FBM-ul de simplex da forme
## neregulate, ca relieful modelat de mana.
##
## Amplitudinea 7.0 e calibrata prin masurare (tools/probe_noise_amp.gd, grile
## de 200x200 pe 3 seed-uri): fractalul are varfuri la ~±0.8 si rms ~0.27.
## La 7.0 varfurile ies ~5.5 m — anvelopa vechilor sinusoide — iar rms-ul
## ~1.9 m fata de 2.3 m inainte; vaile adanci le reteaza oricum clamp-ul
## de -1 m din ground_y.
func _dunes(wx: float, wz: float) -> float:
	return _noise.get_noise_2d(wx, wz) * 7.0


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
	# Si benzile secundare: un palmier plantat in mijlocul scurtaturii ar fi un
	# zid invizibil pe singura linie alternativa din pista.
	var m := _extra.size()
	var k := 0
	while k < m:
		var ex := _extra[k].x - pos.x
		var ez := _extra[k].z - pos.z
		nearest_sq = minf(nearest_sq, ex * ex + ez * ez)
		k += CLEARANCE_STRIDE
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
	# PUNCTUL UNIC prin care trec toate falezele si tot decorul. Era `base.y`,
	# adica exact cota drumului — de aici plutea tot ce se aseza langa o portiune
	# inaltata. Vezi ground_y() pentru diagnosticul complet.
	pos.y = ground_y(pos.x, pos.z)

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
	spec.is_ravine = ravine_at(spec.frac, side_sign)
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
