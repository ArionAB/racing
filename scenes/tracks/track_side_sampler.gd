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
## Pe cati metri dincolo de marginea asfaltului terenul e legat de cota LOCALA a
## drumului, in loc de media ponderata.
##
## Media Shepard descrie CORIDORUL, nu marginea: pe o creasta ea sta sub asfalt,
## intr-o vale peste el. Masurat pe Dunele, treapta de la buza soselei la nisip
## iesea intre 0.12 m si 1.32 m in loc de GROUND_DROP — adica un prag pe care
## masina nu-l mai urca la loc dupa ce iese de pe drum (16 profile masurate, 8
## peste 0.15 m). Langa drum raspunsul corect e cota drumului de ACOLO; media
## conteaza abia cand terenul se desprinde de el.
##
## 15 m si nu mai mult: pe pistele care se auto-intersecteaza (Dunele trece la
## ~40 m de ea insasi) cele doua ramuri raman fiecare peste 15 m distanta una de
## alta, deci nu exista punct in care "cea mai apropiata" sa sara de pe una pe
## alta si sa lase o muchie. Vezi ground_y pentru de ce media exista.
const GROUND_LOCK_LEN: float = 15.0

# --- tarmul insulei (doar cand _far_drop > 0) ---
## Cat de departe INAUNTRUL poligonului de control se intinde plaja. Banda e
## asimetrica intentionat: partea uscata e scurta, ca interiorul buclei sa
## ramana ferm uscat (anti-atol, vezi ground_y), iar cea dinspre larg e lunga,
## ca panta pana la -26 m sa citeasca a recif, nu a zid scufundat.
const SHORE_BAND_IN: float = 30.0
## Cat de departe in larg se termina coborarea spre fundul marii.
const SHORE_BAND_OUT: float = 60.0

## Banda efectiva, pe care tema o poate strange (cheile `shore_band_in/out`).
##
## Constantele de mai sus descriu un ATOL: recif care se intinde lenes spre
## larg, potrivit pe Okinawa. O insula vulcanica tanara are tarmul ABRUPT —
## conul intra direct in apa. Cu 30+60 m, plaja de pe Stromboli iesea la
## ~90 m de sosea, deci pedeapsa "intri in mare" nu se putea intampla.
##
## Se seteaza dupa constructie, din Track.rebuild; pistele care nu declara
## nimic raman exact pe valorile vechi.
var shore_in: float = SHORE_BAND_IN
var shore_out: float = SHORE_BAND_OUT

# --- laguna dinauntrul buclei (doar cand _lagoon_depth > 0) ---
## Banda de tarm a lagunei, oglinda lui SHORE_BAND_*: IN = spre apa, OUT = spre
## uscat. Mai stramta decat a tarmului exterior fiindca panta e mai scurta —
## laguna e mica si putin adanca, deci trecerea plaja -> apa se face pe zeci de
## metri, nu pe o suta.
const LAGOON_BAND_IN: float = 25.0
const LAGOON_BAND_OUT: float = 45.0

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

## Rapa de CORNISA: aceeasi taietura, dar cu buza lipita de asfalt.
##
## Implicitul (4 + 16) descrie o VALE de sub o creasta de fly-off: acolo golul
## trebuie sa fie sub traiectorie, la 20 m lateral, iar buza lina e o calitate —
## cine rateaza saritura aluneca in ea, nu se opreste intr-un perete.
##
## Pe un drum de munte descrie insa exact lucrul gresit. Masurat pe traversarea
## Alpilor, taind profilul terenului perpendicular pe sosea: primii 10 m de
## langa asfalt coborau 1.1-1.4 m, adica o pajiste in panta, si abia pe la 20 m
## incepea caderea. Din masina, „prapastia" citea ca un accident de teren —
## puteai iesi cu doua roti pe iarba fara consecinte, ceea ce anuleaza tot ce ar
## trebui sa comunice lipsa parapetului. Cu cornisa, acelasi profil da -5 m pe
## buza si -17 m la cinci metri lateral.
##
## Cu buza la 0.5 m de asfalt si racord pe 6 m, marginea drumului chiar e
## marginea lumii. Nu se schimba implicitul, fiindca rapele de fly-off de pe
## celelalte piste sunt bine asa: se cere per rapa, cu `cornice`.
const RAVINE_CORNICE_INNER: float = 0.5
const RAVINE_CORNICE_RIM: float = 6.0
## Viaduct: cat de departe DINCOLO de axa ajunge buza interioara (metri peste
## jumatatea latimii) si cat de scurt e racordul pana la fund. Cu 1.5 + 2.5,
## chiar sub axa sapatura e la ~85% din adancime; sub tablier nu se vede.
const RAVINE_VIADUCT_OVERHANG: float = 1.5
const RAVINE_VIADUCT_RIM: float = 2.5

# --- masivele declarate (ruda pe PLUS a rapelor) ---
## Banda de protectie a asfaltului: sub PEAK_ROAD_CLEAR de la marginea soselei
## muntele e stins complet, la PEAK_ROAD_FULL e la putere plina. NU e cosmetica:
## fara ea conul ar trece PESTE asfaltul care il traverseaza. Efectul secundar e
## chiar cel dorit: intre doua diagonale de serpentina la ~45 m una de alta
## ramane un val de teren la jumatatea distantei — citirea de drum taiat in
## coasta muntelui.
const PEAK_ROAD_CLEAR: float = 6.0
const PEAK_ROAD_FULL: float = 32.0
## Netezimea racordului munte-teren, aceeasi familie cu SMOOTH_* (issue #97).
const SMOOTH_PEAK_K: float = 4.0

var _baked: PackedVector3Array
var _dists: PackedFloat32Array
var _loop_poly: PackedVector2Array
## Latimea de referinta a soselei — media, cand exista un profil pe sectoare.
##
## Ramane pentru raspunsurile care NU au un loc anume in vedere (vezi
## [method half_width]); tot ce stie UNDE se afla trece prin [member _widths].
var _half_width: float
## Jumatatea latimii la fiecare punct copt, sau goala cand pista are latime
## constanta.
##
## Goala inseamna „intreaba `_half_width`", nu „latime zero": pe pistele fara
## profil declarat nu se aloca nimic si nu se schimba niciun raspuns.
var _widths: PackedFloat32Array
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
## Indicii rapelor care sunt CORNISE (buza lipita de asfalt). Vezi
## RAVINE_CORNICE_INNER.
var _cornices: Array[int] = []
## Care rape sunt VIADUCTE: terenul coboara si SUB sosea, nu doar langa ea.
## Vezi _carve_ravines.
var _viaducts: Array[int] = []
## Cat de adanc cade campul DEPARTAT sub media soselei. 0 = uscat (desert,
## padure); > 0 = fund de mare (insula). Vezi ground_y.
var _far_drop: float = 0.0
## Puncte de pe benzile SECUNDARE (scurtaturi). Terenul le urmeaza cota ca pe a
## soselei, iar decorul le ocoleste — altfel scurtatura ar pluti peste fundul de
## mare si i-ar rasari palmieri prin mijloc.
var _extra: PackedVector3Array = PackedVector3Array()
## Conturul lagunei din INTERIORUL buclei, in plan XZ. Gol = pista n-are laguna.
var _lagoon_poly: PackedVector2Array = PackedVector2Array()
## Cat de adanc sapa laguna sub media soselei. Vezi ground_y.
var _lagoon_depth: float = 0.0
## Canalele navigabile care TAIE soseaua. Rezolvate de Track — vezi
## [method Track._resolve_channels] pentru forma dictionarului.
var _channels: Array[Dictionary] = []
## Masivele declarate: (x, z, raza, cota varfului IN LUME). Terenul urmareste
## soseaua peste tot, deci interiorul unei bucle care URCA ramane o campie —
## muntele pe care pista pretinde ca se catara nu exista pana nu e declarat.
var _peaks: Array[Vector4] = []


func _init(baked: PackedVector3Array, dists: PackedFloat32Array,
		control_points: Array[Vector3], half_width: float,
		dune_phase: float = 0.0, ravines: Array[Vector4] = [],
		far_drop: float = 0.0,
		extra_corridors: PackedVector3Array = PackedVector3Array(),
		lagoon_poly: PackedVector2Array = PackedVector2Array(),
		lagoon_depth: float = 0.0,
		channels: Array[Dictionary] = [],
		peaks: Array[Vector4] = [],
		cornices: Array[int] = [],
		widths: PackedFloat32Array = PackedFloat32Array(),
		carve_corridors: PackedVector3Array = PackedVector3Array(),
		viaducts: Array[int] = []) -> void:
	_baked = baked
	_dists = dists
	_half_width = half_width
	_widths = widths
	_dune_phase = dune_phase
	_ravines = ravines
	_far_drop = far_drop
	_extra = extra_corridors
	_carve = carve_corridors
	_lagoon_poly = lagoon_poly
	_lagoon_depth = lagoon_depth
	_channels = channels
	_peaks = peaks
	_cornices = cornices
	_viaducts = viaducts
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
##
## Cand pista are latime variabila, asta e MEDIA. Cine stie langa ce bucata de
## drum se afla trebuie sa cheme [method half_width_at], nu functia asta:
## raspunsul de aici e bun pentru bugete si praguri globale, nu pentru asezat
## ceva pe marginea drumului.
func half_width() -> float:
	return _half_width


## Jumatatea de latime la un index din punctele coapte.
##
## Pe o pista fara profil declarat, [member _widths] e goala si raspunsul e
## acelasi peste tot — deci nicio pista existenta nu se schimba.
func half_width_at(i: int) -> float:
	var n := _widths.size()
	if n == 0:
		return _half_width
	return _widths[((i % n) + n) % n]


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
	# Langa asfalt, cota LOCALA a drumului bate media (vezi GROUND_LOCK_LEN).
	# Distanta e cea perpendiculara pe axa, nu cea pana la punctul copt: pasul de
	# esantionare e ~6 m, deci pe mijlocul drumului "cel mai apropiat punct" poate
	# fi la 3 m si lacatul s-ar slabi chiar acolo unde trebuie sa fie ferm.
	var local := _local_road(wx, wz, near_i)
	var lock := 1.0 - smoothstep(0.0, GROUND_LOCK_LEN,
		maxf(local.x - half_width_at(near_i), 0.0))
	if lock > 0.0:
		road_level = lerpf(road_level, local.y, lock)
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
	if _far_drop > 0.0:
		# Insula: dincolo de coridorul pistei, terenul devine FUND DE MARE.
		#
		# Fara asta o pista de insula e imposibila, si nu dintr-un motiv estetic:
		# campul departat se ancoreaza la media cotelor soselei, deci nu coboara
		# niciodata sub ea. Un plan de apa peste el e ori complet ingropat (cota
		# mica), ori inunda si soseaua (cota mare) — nu exista pozitie din care
		# sa iasa o insula.
		#
		# Trecerea uscat -> fund de mare a fost booleana (is_point_in_polygon):
		# 26 m de treapta verticala, instant, de-a lungul COARDELOR dintre
		# punctele de control — un prag poligonal drept prin nisip, vizibil in
		# orice captura de sus (issue #98). Acum e o plaja: distanta semnata
		# fata de poligon, netezita pe o banda asimetrica — SHORE_BAND_IN spre
		# uscat (interiorul ramane uscat, anti-atol), SHORE_BAND_OUT spre larg.
		#
		# Relieful de fund pastreaza doar un sfert din amplitudinea dunelor. Nu e
		# cosmetica: adancimea trebuie sa treaca DECIS de pragul dincolo de care
		# apa nu-si mai schimba culoarea (Track.SEA_NEAR_DEPTH). Cu dune la
		# amplitudine plina, adancimea oscila peste si sub prag, iar grila fina de
		# tarm se emitea pe toata suprafata marii — masurat: 12 800 de triunghiuri
		# in loc de ~2 000.
		var shore := _shore_mix(wx, wz)
		if shore > 0.0:
			var seabed := _mean_y - _far_drop \
				+ _smax(_dunes(wx, wz), -1.0, SMOOTH_FLOOR_K) * 0.25
			far_level = lerpf(far_level, seabed, shore)
	var y := lerpf(road_level, far_level, t * t)
	# Detaliul foloseste ACEEASI masca de coridor ca amestecul mare: zero pe
	# banda plata a soselei, plin dincolo de blend. Inainte de _lift_branches,
	# ca bancurile scurtaturilor sa ramana netede.
	y += _detail_dunes(wx, wz) * (t * t)
	# Masivele INAINTE de benzi si de taieturi: poteca unei scurtaturi isi
	# re-aseaza terenul peste flancul muntelui, iar rapele taie si prin el.
	y = _lift_peaks(y, wx, wz, dist, near_i)
	y = _lift_branches(y, wx, wz, road_level, dist, near_i)
	y = _carve_branches(y, wx, wz, dist, near_i)
	y = _carve_lagoon(y, dist, wx, wz, near_i)
	y = _carve_ravines(y, road_level, dist, near_i, wx, wz) - GROUND_DROP
	# ULTIMA taietura, si singura care nu ocoleste asfaltul. Vezi _carve_channel.
	return _carve_channel(y, wx, wz)


## Distanta perpendiculara pana la axa soselei si cota drumului acolo, ca
## Vector2(distanta, y).
##
## Se uita la SEGMENTELE din jurul punctului copt cel mai apropiat, nu la punctul
## in sine: cu pasul de esantionare (~6 m) si cota lui, terenul de langa drum ar
## iesi in trepte de latimea unui segment — pe o panta de 12% asta inseamna
## praguri de 0.7 m exact acolo unde vrem racord.
func _local_road(wx: float, wz: float, near_i: int) -> Vector2:
	var n := _baked.size()
	var p := Vector2(wx, wz)
	var best_d := INF
	var best_y := _baked[near_i].y
	# Cele doua segmente care ating punctul: [near-stride, near] si [near, near+stride].
	# near_i vine din bucla cu pasul GROUND_STRIDE, deci e mereu un capat de segment.
	for k: int in [-GROUND_STRIDE, 0]:
		var i0 := ((near_i + k) % n + n) % n
		var i1 := (i0 + GROUND_STRIDE) % n
		var a := _baked[i0]
		var b := _baked[i1]
		var a2 := Vector2(a.x, a.z)
		var ab := Vector2(b.x, b.z) - a2
		var len_sq := ab.length_squared()
		var t := 0.0 if len_sq <= 0.0 else clampf((p - a2).dot(ab) / len_sq, 0.0, 1.0)
		var d := p.distance_to(a2 + ab * t)
		if d < best_d:
			best_d = d
			best_y = lerpf(a.y, b.y, t)
	return Vector2(best_d, best_y)


## Ridica terenul spre masivele declarate — vezi [member _peaks].
##
## Fiecare masiv e un dom: cota varfului inmultita cu un profil neted care
## moare la raza declarata. Se combina cu terenul existent prin max NETED
## (aceeasi lectie #97 ca la podeaua vailor: min/max dur = muchie de rigla),
## apoi TOT rezultatul e mascat de banda de protectie a asfaltului, ca muntele
## sa nu treaca peste drumul care il traverseaza. Peste profil se adauga
## acelasi zgomot de dune ca in campul departat, altfel flancul iese un con
## de strung.
func _lift_peaks(y: float, wx: float, wz: float, dist: float,
		near_i: int) -> float:
	if _peaks.is_empty():
		return y
	var mask := smoothstep(PEAK_ROAD_CLEAR, PEAK_ROAD_FULL,
		dist - half_width_at(near_i))
	if mask <= 0.0:
		return y
	var peak := -INF
	for v in _peaks:
		var d := Vector2(wx - v.x, wz - v.y).length()
		if d >= v.z:
			continue
		var f := 1.0 - smoothstep(0.0, 1.0, d / v.z)
		peak = maxf(peak, v.w * f)
	if peak == -INF:
		return y
	peak += _dunes(wx, wz) * 0.5
	return lerpf(y, _smax(y, peak, SMOOTH_PEAK_K), mask)


## Cat de departe de axa unei benzi secundare terenul mai sta la cota ei.
##
## MULT mai stramt decat pentru sosea (45 m + 70 m blend), si asta e chiar
## ideea. Prima versiune baga punctele scurtaturii in acelasi camp Shepard ca
## soseaua: bancul de nisip ridica atunci o limba de teren lata de 230 m, care
## umplea golful pe care tocmai il taia. Ceea ce trebuia sa fie o fasie de nisip
## in apa iesea un istm, iar scurtatura nu se mai citea ca alegere.
const BRANCH_FLAT_RADIUS: float = 11.0
const BRANCH_BLEND_LEN: float = 16.0


## Cat de departe de marginea soselei principale poate ridicatura unei benzi
## secundare sa treaca PESTE cota drumului. Sub atat, e plafonata la ea.
##
## Nu e o cifra de stil, e o reparatie. Pe Okinawa v2 scurtatura se desprinde
## chiar din varful crestei, deci pe primii ~30 m banda si soseaua sunt vecine
## SI la cote diferite (banda ramane pe creasta, soseaua incepe sa coboare).
## Ridicatura benzii lua atunci si asfaltul principal cu ea: o pana de nisip
## crestea din mijlocul drumului chiar la despicatura, si sonda de cursa gasea
## AI intepenit acolo la fiecare tur, atingand TerrainBody. Cat timp toate
## scurtaturile au fost sub cota soselei (bancul de nisip din Okinawa, la
## nivelul marii), bug-ul n-avea cum sa apara.
const BRANCH_LIFT_CLEAR: float = 12.0


## Ridica terenul la cota benzilor secundare, dar doar chiar langa ele.
func _lift_branches(y: float, wx: float, wz: float,
		road_level: float, road_dist: float, near_i: int) -> float:
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
	var lifted := _smax(y, lerpf(level, y, t * t), SMOOTH_BRANCH_K)
	# ...dar niciodata peste soseaua principala cand suntem chiar pe ea. Vezi
	# BRANCH_LIFT_CLEAR: plafonul se ridica de la cota drumului la ridicatura
	# libera pe primii metri de dincolo de asfalt, deci nu apare nicio treapta
	# la marginea lui.
	var room := clampf((road_dist - half_width_at(near_i)) / BRANCH_LIFT_CLEAR,
		0.0, 1.0)
	return minf(lifted, lerpf(road_level, lifted, room))


## Punctele coapte ale benzilor care se conduc PE teren (drum de tara, pietris)
## — pentru ele terenul se si SAPA pana la cota benzii, nu doar se ridica.
## Vezi _carve_branches. Bancul de nisip din Okinawa nu e aici.
var _carve: PackedVector3Array = PackedVector3Array()


## Coboara terenul la cota benzilor de pe uscat, chiar langa ele.
##
## `_lift_branches` doar RIDICA (max neted), si asta e corect pentru un banc de
## nisip: e sub apa prin definitie, iar uscatul din jurul racordurilor trebuie
## sa ramana uscat. Dar un drum de tara desenat printr-un deal ramanea sub deal:
## masurat pe scurtatura din cod a Alpilor, 58 din 90 de puncte coapte erau sub
## teren, cu pana la 4.9 m — banda exista in fizica si era invizibila (sonda:
## tools/probe_branch.gd). Un drum de pe uscat e o suprafata pe care terenul o
## INTALNESTE din ambele parti, deci aici se si sapa.
##
## Aceeasi raza plata si acelasi racord ca la ridicare, ca banda sa aiba o
## singura forma de coridor. Langa soseaua principala nu se sapa (BRANCH_LIFT_CLEAR,
## din acelasi motiv ca la ridicare, cu semn schimbat: nu se scoate pamantul de
## sub marginea asfaltului).
func _carve_branches(y: float, wx: float, wz: float, road_dist: float,
		near_i: int) -> float:
	var m := _carve.size()
	if m == 0:
		return y
	var reach := BRANCH_FLAT_RADIUS + BRANCH_BLEND_LEN
	var reach_sq := reach * reach
	var near_sq := INF
	var level := 0.0
	var k := 0
	while k < m:
		var q := _carve[k]
		var dx := q.x - wx
		var dz := q.z - wz
		var d_sq := dx * dx + dz * dz
		if d_sq < near_sq:
			near_sq = d_sq
			level = q.y
		k += GROUND_STRIDE
	# Terenul sta putin SUB banda (BRANCH_DROP), ca sub sosea (GROUND_DROP):
	# grila de teren e la ~8 m si intre noduri planul ei se abate de la curba
	# benzii — fara marja, colturi de pajiste rasareau prin drum (vazut pe
	# captura: o pana verde peste banda). Marginea benzii coboara pana sub
	# nivelul asta si se ingroapa in teren, deci linia vizibila a drumului e
	# INTERSECTIA celor doua suprafete, nu o muchie de mesh — vezi
	# Track._build_branch_dirt.
	level -= BRANCH_DROP
	if near_sq > reach_sq or level >= y:
		return y
	var d := sqrt(near_sq)
	var t := smoothstep(0.0, 1.0,
		clampf((d - BRANCH_FLAT_RADIUS) / BRANCH_BLEND_LEN, 0.0, 1.0))
	var carved := lerpf(level, y, t)
	var room := clampf((road_dist - half_width_at(near_i)) / BRANCH_CARVE_CLEAR,
		0.0, 1.0)
	return lerpf(y, carved, room)


## Pe cati metri dincolo de marginea asfaltului se aprinde saparea benzii.
## Mai STRANS decat BRANCH_LIFT_CLEAR (12 m), si nu din neatentie: ridicarea
## trebuia tinuta departe de drum ca sa nu creasca o pana de nisip prin asfalt;
## saparea are grija doar sa nu scoata pamantul de sub buza asfaltului, iar
## pentru asta ajung cativa metri. Cu 12 m, o banda care coboara abrupt de pe
## sosea (scurtatura Alpilor: -4 m in primii 18 m) ramanea sub teren pe tot
## racordul — masina iesea de pe asfalt direct intr-un mal.
const BRANCH_CARVE_CLEAR: float = 4.0
## Cat sta terenul sub planul unei benzi de pe uscat. Vezi _carve_branches.
const BRANCH_DROP: float = 0.25


## De la cati metri dincolo de marginea asfaltului incepe malul lagunei, si pe
## cati metri coboara pana la fund. Aceleasi doua roluri ca RAVINE_INNER /
## RAVINE_RIM, si nu din simetrie: laguna TREBUIE sa poata veni pana langa drum.
##
## Prima versiune o aplica pe campul departat, adica in spatele coridorului
## soselei (45 m plat + 70 m de racord). Sigur, dar inutil: coridorul manca
## 115 m din fiecare margine a unui interior de ~350x300 m, deci din laguna
## ramanea o balta in mijloc, iar insula citea ca o plaja uriasa cu o baltoaca.
## Ca RAPA, apa urca pana la 15 m de axa drumului si insula redevine un inel.
const LAGOON_INNER: float = 8.0
const LAGOON_RIM: float = 30.0


## Sapa laguna din interiorul buclei.
##
## Regula anti-atol din ground_y exista fiindca o insula careia ii apare mare in
## mijloc din GRESEALA e imposibil de vazut din masina. Dar o insula INELARA in
## jurul unei lagune e o lume in sine, si atunci golul din mijloc e chiar
## subiectul pistei. Diferenta e ca aici e cerut explicit, cu un contur.
##
## `lerpf` simplu, nu `_smin`: tinta e prin constructie sub y, iar amestecul e
## produsul a doua smoothstep-uri, deci racordul e deja C1. Un _smin ar mai fi
## scazut k/4 = 0.75 m uniform pe toata suprafata lagunei, degeaba.
func _carve_lagoon(y: float, road_dist: float, wx: float, wz: float,
		near_i: int) -> float:
	if _lagoon_depth <= 0.0 or _lagoon_poly.size() < 3:
		return y
	var lat := smoothstep(0.0, 1.0,
		clampf((road_dist - half_width_at(near_i) - LAGOON_INNER) / LAGOON_RIM,
			0.0, 1.0))
	if lat <= 0.0:
		return y
	var lag := _lagoon_mix(wx, wz)
	if lag <= 0.0:
		return y
	# Un sfert din amplitudinea dunelor, ca la fundul de mare: adancimea trebuie
	# sa ramana DECIS sub Track.SEA_NEAR_DEPTH ca laguna sa fie turcoaz de mic
	# adanc pe toata suprafata, nu albastru de larg pe petice.
	var bed := _mean_y - _lagoon_depth \
		+ _smax(_dunes(wx, wz), -1.0, SMOOTH_FLOOR_K) * 0.25
	return lerpf(y, bed, lag * lat)


## Sapa canalele navigabile care taie soseaua.
##
## E SINGURA taietura de teren care nu ocoleste asfaltul, si asta e chiar rostul
## ei. Rapa (`_carve_ravines`) incepe la RAVINE_INNER metri dincolo de marginea
## drumului, laguna la LAGOON_INNER — amandoua ca sa nu apara o groapa sub roti.
## Un canal insa TREBUIE sa treaca pe dedesubt: soseaua il sare pe un pod, iar
## golul de sub pod e continutul gimmick-ului, nu un accident.
##
## Consecinta pe care o plateste apelantul: portiunea de sosea de deasupra apei
## nu mai are teren sub ea. Cine cere un canal cere si structura care sustine
## drumul acolo — vezi [method Track._build_lift_bridge].
##
## Fundul e PLAT (cota drumului minus `depth`), nu ondulat ca fundul de mare:
## un senal navigabil e dragat. In plus, un fund plat garanteaza acelasi pescaj
## pe toata lungimea, deci vaporul nu iese din apa la un capat.
func _carve_channel(y: float, wx: float, wz: float) -> float:
	for ch in _channels:
		var o: Vector3 = ch["origin"]
		# Groapa circulara (vezi TrackChannel.pit): acelasi profil de mal, dar
		# radial fata de taietura, nu in lungul unei axe. Adancimea se masoara
		# tot de la cota DRUMULUI de acolo (o.y), ca la albie.
		if bool(ch.get("pit", false)):
			var rr := Vector2(wx - o.x, wz - o.z).length()
			var mix := 1.0 - smoothstep(float(ch["water_half"]),
				float(ch["water_half"]) + float(ch["bank"]), rr)
			if mix > 0.0:
				y = _smin(y, o.y - float(ch["depth"]) * mix, SMOOTH_RAVINE_K)
			continue
		var along: Vector2 = ch["along2"]
		var across: Vector2 = ch["across2"]
		var d := Vector2(wx - o.x, wz - o.z)
		# `t` = cat de departe pe canal, `s` = cat de departe de axa lui (adica
		# masurat IN LUNGUL soselei, fiindca cele doua sunt perpendiculare).
		var t := absf(d.dot(along))
		var reach: float = ch["reach"]
		if t > reach:
			continue
		var s := absf(d.dot(across))
		var water_half: float = ch["water_half"]
		var lat := 1.0 - smoothstep(water_half, water_half + float(ch["bank"]), s)
		if lat <= 0.0:
			continue
		# Capetele se sting in terenul din jur. Fara stingere, canalul s-ar
		# termina cu un perete drept in mijlocul marii — se vede din elicopter si
		# deloc din masina, exact clasa de artefact pe care o descrie ground_y
		# despre atolii aparuti din greseala.
		var run := 1.0 - smoothstep(reach - float(ch["fade"]), reach, t)
		if run <= 0.0:
			continue
		y = _smin(y, o.y - float(ch["depth"]) * lat * run, SMOOTH_RAVINE_K)
	return y


## Cat de „in canal" e un punct, in 0..1. Peste ~0.3 nu se mai planteaza nimic:
## un palmier semanat de benzile statistice ale lui [TrackDecor] ar rasari din
## apa, fiindca imprastierea nu stie nimic despre taieturile de teren.
func channel_mix(wx: float, wz: float) -> float:
	var best := 0.0
	for ch in _channels:
		var o: Vector3 = ch["origin"]
		if bool(ch.get("pit", false)):
			var rr := Vector2(wx - o.x, wz - o.z).length()
			best = maxf(best, 1.0 - smoothstep(float(ch["water_half"]),
				float(ch["water_half"]) + float(ch["bank"]), rr))
			continue
		var d := Vector2(wx - o.x, wz - o.z)
		var t := absf(d.dot(ch["along2"] as Vector2))
		var reach: float = ch["reach"]
		if t > reach:
			continue
		var s := absf(d.dot(ch["across2"] as Vector2))
		var water_half: float = ch["water_half"]
		var lat := 1.0 - smoothstep(water_half, water_half + float(ch["bank"]), s)
		var run := 1.0 - smoothstep(reach - float(ch["fade"]), reach, t)
		best = maxf(best, lat * run)
	return best


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
##
## Include si laguna, desi nu e o rapa: consumatorul (podeaua de coliziune din
## _build_environment) intreaba de fapt "cat de jos poate cobori terenul sub
## sosea", iar o laguna sapata sub media soselei e exact asta. Fara ea, podeaua
## ar putea taia prin fundul lagunei.
func max_ravine_depth() -> float:
	var d := _lagoon_depth
	for r in _ravines:
		d = maxf(d, r.z)
	# Canalul se masoara de la cota DRUMULUI de acolo, nu de la media pistei, iar
	# consumatorul vrea „cat de jos poate cobori terenul sub sosea". Pe o portiune
	# de drum care sta peste medie, diferenta chiar conteaza.
	for ch in _channels:
		var o: Vector3 = ch["origin"]
		d = maxf(d, float(ch["depth"]) + (o.y - _mean_y))
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
	for ri in _ravines.size():
		var r: Vector4 = _ravines[ri]
		if not is_zero_approx(r.w) and signf(r.w) != _side_sign_at(near_i, wx, wz):
			continue
		var along := _ring_window(f, r.x, r.y, RAVINE_FADE_FRAC)
		if along <= 0.0:
			continue
		var cornice := _cornices.has(ri)
		var inner := RAVINE_CORNICE_INNER if cornice else RAVINE_INNER
		var rim := RAVINE_CORNICE_RIM if cornice else RAVINE_RIM
		if _viaducts.has(ri):
			# VIADUCT: golul e si sub asfalt. O rapa obisnuita lasa terenul de
			# sub sosea la cota ei (lacatul de langa drum), deci o cornisa pe
			# ambele parti iesea o CREASTA de stanca de 13 m cu drumul pe
			# muchie — de pe gheata se vedea un zid, nu arcade. Aici buza
			# interioara trece dincolo de axa (inner negativ), cu racordul
			# scurt: sub tablier terenul e la fund, iar pilele din kit
			# (DecorManual) au unde sa stea. Tablierul soselei isi are fusta si
			# coliziunea lui (ROAD_THICKNESS), deci nu ramane nimic in aer.
			inner = -(half_width_at(near_i) + RAVINE_VIADUCT_OVERHANG)
			rim = RAVINE_VIADUCT_RIM
		var lat := smoothstep(0.0, 1.0,
			clampf((dist - half_width_at(near_i) - inner) / rim, 0.0, 1.0))
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


## 0 = uscat, 1 = fund de mare, cu smoothstep pe banda [-IN, +OUT] in jurul
## poligonului de control. Distanta semnata: minimul pe cele 24 de segmente,
## semnul din is_point_in_polygon (negativ inauntru). ~24 segmente x zeci de
## mii de apeluri la generare = neglijabil, si numai pe pistele cu apa.
func _shore_mix(wx: float, wz: float) -> float:
	if _loop_poly.size() < 3:
		return 1.0
	var p := Vector2(wx, wz)
	var d_sq := INF
	var n := _loop_poly.size()
	for i in n:
		var q := Geometry2D.get_closest_point_to_segment(
			p, _loop_poly[i], _loop_poly[(i + 1) % n])
		d_sq = minf(d_sq, p.distance_squared_to(q))
	var sd := sqrt(d_sq)
	if Geometry2D.is_point_in_polygon(p, _loop_poly):
		sd = -sd
	return smoothstep(-shore_in, shore_out, sd)


## 0 = uscat, 1 = fundul lagunei. Oglinda lui _shore_mix, cu semnul invers:
## acolo "inauntrul buclei" inseamna uscat, aici "inauntrul conturului" inseamna
## apa. Poligonul are ~16 laturi, deci costul e de acelasi ordin, si numai pe
## pistele care chiar declara o laguna.
func _lagoon_mix(wx: float, wz: float) -> float:
	var p := Vector2(wx, wz)
	var d_sq := INF
	var n := _lagoon_poly.size()
	for i in n:
		var q := Geometry2D.get_closest_point_to_segment(
			p, _lagoon_poly[i], _lagoon_poly[(i + 1) % n])
		d_sq = minf(d_sq, p.distance_squared_to(q))
	var sd := sqrt(d_sq)
	if not Geometry2D.is_point_in_polygon(p, _lagoon_poly):
		sd = -sd
	return smoothstep(-LAGOON_BAND_OUT, LAGOON_BAND_IN, sd)


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


## Dune MICI: zgomot de detaliu la ~11 m lungime de unda, ±0.35 m amplitudine.
##
## _dunes() da forma mare (sute de metri); asta da textura de relief pe care o
## vezi din masina — la pasul de teren de ~8 m, valurile astea devin FORME cu
## lumina si umbra proprie, nu doar nuante. Frecvente necomensurabile, ca sa nu
## apara tipar de grila; faza pistei intra in ambele, ca terenul sa difere
## intre piste.
##
## Traieste in SAMPLER, nu in _build_terrain: tot ce citeste ground_y (teren,
## coliziune, faleze, decor, landmark-uri) vede acelasi relief — nimic nu
## pluteste peste valuri si nimic nu se ingroapa in ele.
## Amplitudinea (±0.35 m) e departe de pragul de ±3.5 m/50 m din style_bible
## §11.3, deci masinile care ies de pe drum nu sar.
func _detail_dunes(wx: float, wz: float) -> float:
	return sin(wx * 0.57 + _dune_phase * 3.0) \
		* cos(wz * 0.61 - _dune_phase) * 0.22 \
		+ sin((wx + wz) * 0.43 + _dune_phase * 5.0) * 0.13


## Punctele benzilor secundare, pentru consumatorii care isi fac propria
## evitare spatiala (iarba densa isi construieste un cos de cautare din ele —
## clearance_at ar fi O(n) per smoc, si smocurile sunt mii).
func extra_points() -> PackedVector3Array:
	return _extra


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
		var b0 := _baked[i] + side_at(i) * half_width_at(i) * side_sign
		var b1 := _baked[j] + side_at(j) * half_width_at(j) * side_sign
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
	var hw := half_width_at(idx)
	var pos := base + side * (hw + offset)
	# PUNCTUL UNIC prin care trec toate falezele si tot decorul. Era `base.y`,
	# adica exact cota drumului — de aici plutea tot ce se aseza langa o portiune
	# inaltata. Vezi ground_y() pentru diagnosticul complet.
	pos.y = ground_y(pos.x, pos.z)

	# Respins daca ar cadea peste alta bucla a pistei. Marja de 1m: vrem sa
	# permitem slotul propriu (care e la exact half_width + offset), dar nu unul
	# care s-a apropiat de o sosea vecina.
	if clearance_at(pos) < hw + offset - 1.0:
		return null
	# ...si daca ar cadea in canal. Slotul isi ia cota din ground_y, deci un
	# palmier de acolo n-ar pluti: ar creste de pe fundul senalului, cu coroana
	# sub linia apei.
	if channel_mix(pos.x, pos.z) > 0.3:
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
