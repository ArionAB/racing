extends Node
## Generator de decor MANUAL pentru POI H — SPARTURA LERAI (Track14, Serengeti,
## frac 0.853-0.887). Nu e sonda: CALCULEAZA transformarile care se lipesc in
## Track14.tscn sub `DecorManual/ZoneH_Spartura` (si un HazardMarker FLYOFF in
## `Hazarduri`). Tiparul e `gen_decor_capp_a.gd`.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorSerH.tscn
##
## Ce decide compozitia, si de ce cifrele sunt astea:
##
## 1. PERETELE NU E IN TEREN. Masurat (ProbeFrac + raycast): la 0.853 drumul e
##    la y~1 pe campie plata; craterul (rapa 0.358-0.486) e in alta parte a
##    turului. Deci „taietura in peretele de granit" e INTREAGA in
##    `crater_gap.glb` (doua fete de ~40 m, 12,4 m inalte). Fara el nu exista
##    POI, cu el trebuie sa para ca peretele continua: bolovanii kopje la
##    colturi si acaciile din spate ii dau grosime.
##
## 2. GOLUL E MAI INGUST DECAT DRUMUL. GLB-ul are 12 m liber; drumul aici are
##    `half_width` 7,0 (14 m carosabil) — brief-ul spunea „7 m" si era
##    semilatimea. Solutia: scara pe X local (perpendicular pe drum) astfel
##    incat intre fete sa ramana carosabilul + margine; cifra se DERIVA din
##    devierea reala a axului fata de o dreapta pe lungimea fetelor (drumul
##    coteste ~17 grade pe 0.84-0.87), nu se alege. Vezi `_fit_gap`.
##
## 3. ORIGINEA GLB-ULUI e `assembly`, pe axa drumului, la talpa fetelor. Cota se
##    ia din TEREN sub talpa fetelor (minimul pe ambele parti), nu din sosea:
##    o fata care pluteste 30 cm se vede de la 40 m, una ingropata 30 cm nu.
##
## 4. COMPOZITIA E DE SOFER (memoria `driver-view-for-composition`): cadrul erou
##    e la 0.84, cu masina la ~28 m de gura sparturii. Ce conteaza e ce e la
##    5-40 m in fata, pe ambele parti: coltul fetelor cu bolovani si euphorbii
##    la baza, acacii la 3-8 m de muchie inainte si dupa, coroane care intra
##    peste drum. Plafonul frustumului (10 + 0.093*d): fetele de 12,4 m intra
##    intregi de la 26 m incolo.
##
## 5. SOARELE (masurat din DirectionalLight3D, nu presupus): vine din fata-
##    stanga fata de sensul de mers (+x). Fata din stanga isi arunca umbra PE
##    drum, spre camera; fata din dreapta e luminata. Acaciile mari stau pe
##    stanga ca umbra coroanei sa cada pe laterit.

const TRACK := "res://scenes/tracks/Track14.tscn"
const ZONE := "DecorManual/ZoneH_Spartura"

## id-urile ext_resource asa cum sunt deja in Track14.tscn (handoff §1).
const RES := {
	"crater_gap": "s_crater_gap",
	"kopje_boulder_a": "s_kopje_boulder_a",
	"kopje_boulder_b": "s_kopje_boulder_b",
	"kopje_boulder_c": "s_kopje_boulder_c",
	"euphorbia": "s_euphorbia",
	"acacia_umbrella_a": "s_acacia_umbrella_a",
	"acacia_umbrella_b": "s_acacia_umbrella_b",
	"acacia_umbrella_c": "s_acacia_umbrella_c",
	"dead_tree": "s_dead_tree",
	"kopje_camp": "s_kopje_camp",
}

## Raza la sol a piesei (probe_serengeti_kit: jumatate din latura mare a AABB
## pentru bolovani; TRUNCHIUL pentru copaci — coroana are voie peste drum).
const BASE_R := {
	"kopje_boulder_a": 1.07, "kopje_boulder_b": 2.03, "kopje_boulder_c": 2.80,
	"euphorbia": 0.90, "acacia_umbrella_a": 0.6, "acacia_umbrella_b": 0.7,
	"acacia_umbrella_c": 0.8, "dead_tree": 0.5, "kopje_camp": 6.7,
}

## Spartura: din AABB-ul GLB-ului (pos -18.37..17.80 pe X, -21.64..22.16 pe Z).
const GAP_FREE_X: float = 12.0
const GAP_LEN_Z: float = 43.8
## Cat ramane liber intre muchia carosabilului si fata de granit, minim.
##
## Era 2.0 si dadea scara X 1.60, adica 19,2 m liber intre fete — de trei ori
## mai mult decat cei 12 m din brief. Doua pagube masurate pe cadrul de joc:
## taietura citea ca un CORIDOR larg, nu ca o strangere, iar scara pe X intinde
## fetele pe orizontala, deci coloanele granitului se rareau si se vedea cerul
## printre ele. Cifrele reale pe lungimea fetelor (survey, 0.863-0.884):
## `half_width` constant 7.0 si abatere laterala maxima 0.20 m — deci 14 m de
## carosabil. Cu marginea la 1.2 m iese 16,4 m liber (scara 1.40): masina trece
## fara sa atinga (ProbeRace 0 pereti pe felia 0.85-0.90), dar fata de granit e
## la 8,2 m de ax in loc de 9,6, adica intra in cadru ca perete, nu ca gard.
const GAP_MARGIN: float = 1.2
## Fractia din jurul careia se cauta centrul sparturii (brief: 0.853).
const GAP_FRAC_NOMINAL: float = 0.872
const GAP_FRAC_SEARCH: float = 0.003

var _track: Track
var _sampler: TrackSideSampler
var _terrain_rid: RID = RID()
var _sus_y := 0.0
var _out: Array[String] = []
var _haz: Array[String] = []
var _n := 0
var _rng := RandomNumberGenerator.new()
var _warn := 0
## Rezultatul potrivirii sparturii: centrul (index), directia, scara X.
var _gap_idx := 0
var _gap_dir := Vector3.FORWARD
var _gap_center := Vector3.ZERO
var _gap_sx := 1.0
var _m_per_frac := 2.0


func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	_sampler = _track._sampler
	var hi := -INF
	for bp in _track.baked:
		hi = maxf(hi, bp.y)
	_sus_y = hi + 120.0
	_rng.seed = 140853
	var n := _track.baked.size()
	_m_per_frac = _track._dists[_track._dists.size() - 1] / 1000.0
	_sun()
	_survey()
	_fit_gap()
	_gap()
	_corners()
	_trees()
	_kicker()
	print("")
	print(";;; ZONE")
	for line in _out:
		print(line)
	print(";;; HAZARDURI")
	for line in _haz:
		print(line)
	print(";;; END")
	print("; asezate %d piese, %d avertismente de degajare" % [_n, _warn])
	get_tree().quit(0)


## Directia LUMINII, citita din nod — brief §4 cere remasurare la fiecare
## redesenare a traseului.
func _sun() -> void:
	var light: DirectionalLight3D = null
	for c in _track.find_children("*", "DirectionalLight3D", true, false):
		light = c
		break
	if light == null:
		print("; ATENTIE: fara DirectionalLight3D in scena")
		return
	var d := -light.global_transform.basis.z
	var i := _idx(GAP_FRAC_NOMINAL)
	var s := _track._side_at(i)
	print("; soare: lumina merge spre (%.3f, %.3f, %.3f); dot(side, umbra_xz)=%.2f (>0: umbra cade spre +side)" % [
		d.x, d.y, d.z, Vector3(d.x, 0, d.z).normalized().dot(s)])


func _idx(frac: float) -> int:
	var n := _track.baked.size()
	return int(fposmod(frac, 1.0) * float(n)) % n


func _survey() -> void:
	print("; frac   ax(x,z)          y_drum  dir(x,z)      half  sol@-20 sol@-10 sol@+10 sol@+20")
	var f := 0.826
	while f < 0.932:
		var i := _idx(f)
		var p := _track.baked[i]
		var n := _track.baked.size()
		var d := (_track.baked[(i + 1) % n] - p).normalized()
		var s := _track._side_at(i)
		var half := _track.width_at_index(i)
		var row := "; %.3f (%7.2f,%7.2f) %6.2f (%5.2f,%5.2f) %4.1f" % [f, p.x, p.z, p.y, d.x, d.z, half]
		for off: float in [-20.0, -10.0, 10.0, 20.0]:
			var q := p + s * off
			row += " %7.2f" % _sol_real(q.x, q.z)
		print(row)
		f += 0.002


## Potrivirea sparturii pe drumul care coteste: pentru fiecare centru candidat
## se ia directia medie a axului pe +-GAP_LEN_Z/2 si se masoara cat se abate
## axul de la dreapta aia (lateral). Se alege centrul cu abaterea minima, si
## scara pe X iese din abatere + half_width + margine.
func _fit_gap() -> void:
	var n := _track.baked.size()
	var best_dev := INF
	var f := GAP_FRAC_NOMINAL - GAP_FRAC_SEARCH
	while f <= GAP_FRAC_NOMINAL + GAP_FRAC_SEARCH + 1e-6:
		var ci := _idx(f)
		var c := _track.baked[ci]
		# indexii pe +-jumatate din lungime, pe distanta reala
		var pts: Array[Vector3] = []
		var dsum := Vector3.ZERO
		for k in range(-80, 81):
			var j := ((ci + k) % n + n) % n
			var p := _track.baked[j]
			var along := (p - c).length()
			if along <= GAP_LEN_Z * 0.5:
				pts.append(p)
				dsum += (_track.baked[(j + 1) % n] - p).normalized()
		var dir := Vector3(dsum.x, 0, dsum.z).normalized()
		var side := dir.cross(Vector3.UP).normalized()
		var dev := 0.0
		var wmax := 0.0
		for p in pts:
			dev = maxf(dev, absf((p - c).dot(side)))
		for p in pts:
			wmax = maxf(wmax, _track.width_at_index(_nearest(p)))
		var need := dev + wmax + GAP_MARGIN
		print("; candidat %.4f: abatere laterala max %.2f m, half max %.1f -> liber necesar %.1f m (%d puncte)" % [
			f, dev, wmax, 2.0 * need, pts.size()])
		# Se alege SPATIUL minim necesar (abatere + banda + margine), nu abaterea:
		# pe 0.869-0.875 abaterea e sub 0,5 m peste tot, dar banda scade de la
		# 10 la 7 m — si banda decide scara.
		if need < best_dev:
			best_dev = need
			_gap_idx = ci
			_gap_dir = dir
			_gap_center = c
			_gap_sx = ceil(2.0 * need / GAP_FREE_X * 20.0) / 20.0
		f += 0.0005
	print("; SPARTURA la frac %.4f centru (%.2f, %.2f, %.2f) dir (%.3f, %.3f) scara X %.2f -> %.1f m liber" % [
		float(_gap_idx) / float(n), _gap_center.x, _gap_center.y, _gap_center.z,
		_gap_dir.x, _gap_dir.z, _gap_sx, GAP_FREE_X * _gap_sx])


func _nearest(p: Vector3) -> int:
	var n := _track.baked.size()
	var best := 0
	var bd := INF
	for k in range(-100, 101):
		var j := ((_gap_idx + k) % n + n) % n
		var d := (_track.baked[j] - p).length_squared()
		if d < bd:
			bd = d
			best = j
	return best


## Spartura propriu-zisa: pe axa, cu Z local pe directia drumului, cota din
## terenul de sub TALPA fetelor.
func _gap() -> void:
	var side := _gap_dir.cross(Vector3.UP).normalized()
	var inner := GAP_FREE_X * 0.5 * _gap_sx
	var lo := INF
	var hi := -INF
	for sgn: float in [-1.0, 1.0]:
		for lat: float in [inner + 0.5, inner + 4.0, inner + 9.0]:
			var along := -GAP_LEN_Z * 0.45
			while along <= GAP_LEN_Z * 0.45:
				var q := _gap_center + side * (sgn * lat) + _gap_dir * along
				var g := _sol_real(q.x, q.z)
				lo = minf(lo, g)
				hi = maxf(hi, g)
				along += 4.0
	print("; teren sub fete: %.2f .. %.2f (drum %.2f) -> spartura la y=%.2f" % [
		lo, hi, _gap_center.y, lo])
	var yaw := atan2(_gap_dir.x, _gap_dir.z)
	_raw("crater_gap", "spartura", Vector3(_gap_center.x, lo, _gap_center.z),
		yaw, Vector3(_gap_sx, 1.0, 1.0), "mesh")
	# Tufe si moloz LA BAZA fetelor, pe fasia dintre carosabil si granit
	# (memoria `patru-defecte-de-diorama` #3: stanca atinge solul prin moloz,
	# des si marunt la baza). Fara coliziune: fasia are 2 m si e langa banda.
	for sgn: float in [-1.0, 1.0]:
		var along := -GAP_LEN_Z * 0.42
		var k := 0
		while along <= GAP_LEN_Z * 0.42:
			# La talpa fetei (inner = 9,6 m), nu pe umar: probe_manual cere
			# >= banda + 2 m de ax, si banda e 7,0-7,3 pe lungimea fetelor.
			var lat := inner + 0.1 + _rng.randf_range(0.0, 0.6)
			var q := _gap_center + side * (sgn * lat) + _gap_dir * along
			var g := _sol_real(q.x, q.z)
			if k % 3 == 1:
				_raw("euphorbia", "euphorbiaBaza", Vector3(q.x, g, q.z),
					_rng.randf_range(0.0, TAU), Vector3.ONE * _rng.randf_range(0.4, 0.6), "none")
			else:
				_raw("kopje_boulder_a", "molozBaza", Vector3(q.x, g - 0.25, q.z),
					_rng.randf_range(0.0, TAU), Vector3.ONE * _rng.randf_range(0.6, 1.0), "none")
			along += _rng.randf_range(4.5, 7.0)
			k += 1


## COLTURILE fetelor: aici se citeste ca peretele e din bolovani ingramaditi,
## nu o placa. Bolovani b/c (2,9 / 4,3 m) lipiti de capetele fetelor, in
## AFARA carosabilului (marginea la >= 0,5 m de muchie), cu hull.
func _corners() -> void:
	var n := _track.baked.size()
	var f0 := float(_gap_idx) / float(n)
	var df := (GAP_LEN_Z * 0.5) / _m_per_frac / 1000.0
	var entry := f0 - df
	var exit := f0 + df
	print("; fete de la frac %.4f la %.4f (%.1f m/0.001)" % [entry, exit, _m_per_frac])
	# intrare: bolovanii mari pe colt, un pic inaintea fetei, plus euphorbii
	_place("kopje_boulder_c", "coltIntrare", entry - 0.0025, -1.0, 1.6, 0.7, 1.15, "hull")
	_place("kopje_boulder_b", "coltIntrare", entry - 0.0048, -1.0, 1.2, 2.1, 1.0, "hull")
	_place("kopje_boulder_b", "coltIntrare", entry - 0.0020, 1.0, 1.4, 3.9, 1.25, "hull")
	_place("kopje_boulder_c", "coltIntrare", entry - 0.0042, 1.0, 2.2, 1.3, 0.95, "hull")
	_place("kopje_boulder_a", "molozIntrare", entry - 0.0062, -1.0, 2.2, 0.4, 1.1, "none")
	_place("kopje_boulder_a", "molozIntrare", entry - 0.0070, 1.0, 2.1, 2.8, 0.9, "none")
	_place("euphorbia", "euphorbiaIntrare", entry - 0.0036, -1.0, 3.6, 0.0, 0.9, "trunk")
	_place("euphorbia", "euphorbiaIntrare", entry - 0.0058, 1.0, 2.6, 1.1, 1.0, "trunk")
	_place("euphorbia", "euphorbiaIntrare", entry - 0.0012, 1.0, 4.4, 2.0, 0.8, "trunk")
	# iesire
	_place("kopje_boulder_c", "coltIesire", exit + 0.0022, 1.0, 1.5, 5.1, 1.1, "hull")
	_place("kopje_boulder_b", "coltIesire", exit + 0.0046, 1.0, 1.0, 0.9, 1.05, "hull")
	_place("kopje_boulder_b", "coltIesire", exit + 0.0018, -1.0, 1.3, 2.4, 1.2, "hull")
	_place("kopje_boulder_c", "coltIesire", exit + 0.0044, -1.0, 2.4, 4.0, 0.9, "hull")
	_place("kopje_boulder_a", "molozIesire", exit + 0.0066, 1.0, 2.2, 1.7, 1.0, "none")
	_place("kopje_boulder_a", "molozIesire", exit + 0.0072, -1.0, 2.4, 0.2, 0.85, "none")
	_place("euphorbia", "euphorbiaIesire", exit + 0.0034, 1.0, 3.4, 0.5, 1.0, "trunk")
	_place("euphorbia", "euphorbiaIesire", exit + 0.0056, -1.0, 2.8, 3.3, 0.85, "trunk")
	# Bolovani MARI in spatele colturilor, ca peretele sa aiba grosime cand il
	# vezi oblic (la 8-14 m de muchie, dincolo de fata).
	_place("kopje_boulder_c", "spateColt", entry - 0.0010, -1.0, 8.0, 1.9, 1.6, "hull")
	_place("kopje_boulder_c", "spateColt", entry - 0.0030, 1.0, 9.0, 0.3, 1.5, "hull")
	_place("kopje_boulder_c", "spateColt", exit + 0.0030, 1.0, 8.5, 2.6, 1.5, "hull")
	_umerii_gurii()
	# CRESTA din care e taiata spartura. In cadrul erou fetele incepeau brusc
	# din campie plata: se citea ca doua placi asezate pe iarba, nu ca o
	# taietura intr-un perete (defectul „obiecte infipte in plan" din memoria
	# `patru-defecte-de-diorama`). Bolovanii de aici urca de la 12 la 24 m
	# lateral pe ultimii 45 m de apropiere si se SUPRAPUN intre ei, ca masa
	# de granit sa existe si inainte, si in spatele fetelor.
	# Coloana a 4-a e ACUM inaltimea tinta in metri, nu un factor de scara: din
	# ea se alege si piesa, si scara. Motiv masurat pe cadrul erou al rundei 1
	# (`H_r2_before.png`): ecartul siluetei pe toata latimea cadrului era 0.133
	# din inaltime — adica linia cerului e PLATA, un gard de tarusi la aceeasi
	# cota. Cauza nu era scara prea mica, ci faptul ca TOATA creasta era
	# `kopje_boulder_c` (4,32 m) intre 1.5 si 2.1: acelasi contur, aceeasi
	# inaltime, de 16 ori. Un bolovan marit ramane un bolovan.
	var ridge: Array = [
		[0.0150, -1.0, 13.0, 15.0], [0.0132, 1.0, 15.0, 7.5],
		[0.0118, -1.0, 19.0, 9.0], [0.0104, 1.0, 21.0, 17.0],
		[0.0092, -1.0, 11.5, 6.0], [0.0080, 1.0, 12.5, 8.5],
		[0.0068, -1.0, 16.0, 18.0], [0.0058, 1.0, 17.5, 6.5],
		[0.0046, -1.0, 10.0, 5.0], [0.0036, 1.0, 10.5, 11.0],
	]
	for e in ridge:
		_place_h("creasta", entry - float(e[0]), float(e[1]),
			float(e[2]) + _rng.randf_range(-1.5, 1.5), float(e[3]))
	# si dincolo de fete, ca peretele sa aiba adancime cand treci prin gura
	var back_h: Array = [16.0, 6.5, 12.0, 8.0, 19.0, 7.0]
	for j in 6:
		var side := -1.0 if j % 2 == 0 else 1.0
		_place_h("creastaSpate", entry + 0.0030 + 0.0038 * float(j), side,
			_rng.randf_range(13.0, 22.0), float(back_h[j]))


## Inaltimea reala a piesei la scara 1 (AABB din probe_serengeti_kit). Din ea
## se DERIVA scara pentru o inaltime ceruta, in loc sa fie ghicita.
const H1 := {
	"kopje_boulder_a": 1.44, "kopje_boulder_b": 2.88, "kopje_boulder_c": 4.32,
	"kopje_camp": 13.22,
}


## Aseaza masa de granit cea mai potrivita pentru inaltimea `h_m`, cu scara
## derivata. Regula piesei: sub 5 m boulder_c, 5-9 m boulder_c intins, peste
## 9 m `kopje_camp` — care e o alta forma (13,2 m, cu platou si trepte), nu
## acelasi bolovan umflat. Scara ramane in 0.55-1.6 pe kopje_camp si sub 2.2
## pe boulder_c, ca dala triplanara sa nu se intinda vizibil.
func _place_h(base: String, frac: float, side_sign: float, gap: float,
		h_m: float) -> void:
	# Inaltimea ceruta e fata de SOSEA, nu fata de solul de sub piesa. Unde
	# terenul urca lateral, o masa de 19 m pe un dambovic de 14 m are varful la
	# 33 m si citeste ca stanca atarnata in cer, desprinsa de peisaj — asa
	# arata `creastaSpate52` in `H_r2_hero.png`, coltul din dreapta sus. Deci
	# se scade cota terenului din inaltimea ceruta, si sub 3,5 m ramasi piesa
	# se sare: acolo dealul face treaba, nu bolovanul.
	var i := _idx(frac)
	var p := _track.baked[i]
	var s := _track._side_at(i) * side_sign
	var half := _track.width_at_index(i)
	var q := p + s * (half + gap)
	var ridicat: float = _sol_real(q.x, q.z) - p.y
	var h_ef: float = h_m - maxf(ridicat, 0.0)
	if h_ef < 3.5:
		print("; SARIT %s la frac %.4f: terenul urca %.1f m, ar ramane %.1f m de piesa" % [
			base, frac, ridicat, h_ef])
		return
	var model := "kopje_camp" if h_ef >= 9.0 else "kopje_boulder_c"
	var scl: float = h_ef / float(H1[model])
	_place(model, base, frac, side_sign, gap, _rng.randf_range(0.0, TAU), scl, "hull")


## UMERII GURII — cele doua mase care inchid spartura PE VERTICALA.
##
## Defectul numit de critic pe cadrul erou al rundei 1: blocurile de la buza
## taieturii se termina pe la o treime din inaltimea cadrului si lasa cer plus
## orizont vizibil intre ele, deci „spartura" citea ca un drum drept cu pietre
## pe margini. Cifrele de pe `H_r2_before.png`: cer 10.2 % in banda centrala,
## ecart de silueta 0.133 pe toata latimea (linie plata).
##
## De ce NU se rezolva marind bolovanii, cum ar veni la indemana: fetele
## `crater_gap` au 12,36 m si sunt deja cea mai inalta piesa de acolo, iar
## `kopje_boulder_c` are 4,32 m — ca sa ajunga la 18 m ii trebuie scara 4.2,
## adica dala triplanara se intinde de patru ori si iese o piatra de plastic.
## Piesa corecta exista deja in kit: `kopje_camp`, 13,22 m, cu platou si
## trepte — la scara 1.25-1.45 da 16,5-19 m fara sa intinda textura.
##
## Plasarea: perechea sta la intrarea in fete (unde e privita din fata la
## ~28 m in cadrul erou), retrasa lateral cat sa NU intre in carosabil dar
## destul de aproape cat sa acopere unghiul dintre coloane. Plafonul
## frustumului la 28 m e 10 + 0.093*28 = 12,6 m, deci varful unei mase de 18 m
## IESE din cadru sus — exact ce se cere: cerul dintre coloane dispare fiindca
## masa il taie, nu fiindca e vazuta intreaga.
func _umerii_gurii() -> void:
	var n := _track.baked.size()
	var f0 := float(_gap_idx) / float(n)
	var df := (GAP_LEN_Z * 0.5) / _m_per_frac / 1000.0
	var entry := f0 - df
	var exit := f0 + df
	# Perechea dominanta, imediat in fata fetelor, una pe fiecare parte.
	# Asimetrice ca inaltime (18 / 15,5 m): doua mase egale citesc ca poarta
	# de fabrica, referinta are o stanca vizibil mai mare decat cealalta.
	_place_h("umarGura", entry - 0.0006, -1.0, 6.5, 18.5)
	_place_h("umarGura", entry - 0.0014, 1.0, 4.5, 17.0)
	# A doua pereche, in spatele primei si mai departe lateral: masa continua
	# dincolo de gura, deci silueta nu cade brusc la iarba dupa umeri.
	_place_h("umarSpate", entry + 0.0022, -1.0, 12.0, 16.0)
	_place_h("umarSpate", entry + 0.0040, 1.0, 9.0, 15.0)
	# Umarul din DREAPTA cadrului erou: in `H_r2_hero.png` stanga era inchisa
	# de o masa care iese din cadru, iar dreapta ramasese cu cer si orizont
	# pana jos. Cauza: garda de traseu strain trage piesele din dreapta inapoi
	# spre ax (traseul se intoarce pe z=165 pe partea aia), deci ce era departe
	# lateral a fost sarit. Se compenseaza cu piese APROAPE, nu departe.
	_place_h("umarDreapta", entry - 0.0042, 1.0, 3.5, 14.0)
	_place_h("umarDreapta", entry - 0.0072, 1.0, 5.0, 11.0)
	# La IESIRE, ca taietura sa se inchida si in oglinda retrovizoare si in
	# cadrul de context de la 0.858 (unde privesti prin gura spre campie).
	_place_h("umarIesire", exit + 0.0014, 1.0, 7.0, 16.5)
	_place_h("umarIesire", exit + 0.0034, -1.0, 8.5, 13.0)


## ACACIILE: referinta are coroane la 3-8 m de drum, care se ating, si umbre
## pe laterit. Inainte de spartura pe ambele parti (cadrul erou le vede
## lateral), dupa spartura in campia aurie, cu inaltimile mari in fata
## (plafonul frustumului creste cu distanta).
func _trees() -> void:
	var n := _track.baked.size()
	var f0 := float(_gap_idx) / float(n)
	var df := (GAP_LEN_Z * 0.5) / _m_per_frac / 1000.0
	var entry := f0 - df
	var exit := f0 + df
	# intrarea (0.826-0.842): patru acacii, alternand, apropiate
	_place("acacia_umbrella_b", "acaciaIntrare", entry - 0.0085, 1.0, 3.5, 0.6, 1.0, "trunk")
	_place("acacia_umbrella_a", "acaciaIntrare", entry - 0.0125, -1.0, 4.5, 2.2, 1.05, "trunk")
	_place("acacia_umbrella_c", "acaciaIntrare", entry - 0.0180, 1.0, 6.0, 4.0, 1.0, "trunk")
	_place("acacia_umbrella_a", "acaciaIntrare", entry - 0.0235, -1.0, 3.0, 1.4, 0.95, "trunk")
	_place("acacia_umbrella_b", "acaciaIntrare", entry - 0.0290, 1.0, 5.0, 3.1, 1.1, "trunk")
	_place("dead_tree", "copacUscat", entry - 0.0150, -1.0, 9.0, 0.8, 1.1, "trunk")
	# STRATUL DE LA SOL PE APROPIERE (0.836-0.862). In cadrul erou de la 0.84
	# apropierea avea NUMAI copaci: intre asfalt si trunchiuri ramanea iarba
	# goala pe 20 m, iar referinta are tufe si pietre chiar pe muchie. Banda
	# de aici e generata cu jitter (lectia valurilor 1-2: pasul fix se
	# citeste ca „instante plasate"), cu densitate care CRESTE spre spartura,
	# si cu piese care se suprapun intre ele.
	_undergrowth(entry - 0.0330, entry - 0.0010)
	# O acacie DINCOLO de fata din stanga (fata scalata tine pana la 28,5 m de
	# ax; la 21 m copacul era IN stanca). Pe dreapta nu: linia de sosire trece
	# la z=165, la 40 m de axa noastra, si coroana ar fi cazut peste ea
	# (probe_manual: „IN DRUM" la 11,6 m de axa ei).
	_place("acacia_umbrella_c", "acaciaPeste", f0 - 0.004, -1.0, 30.0, 1.0, 1.15, "trunk")
	# iesirea si campia (0.865-0.895)
	_place("acacia_umbrella_a", "acaciaCampie", exit + 0.0080, 1.0, 3.0, 0.2, 1.0, "trunk")
	_place("acacia_umbrella_c", "acaciaCampie", exit + 0.0120, -1.0, 5.0, 2.9, 1.0, "trunk")
	_place("acacia_umbrella_b", "acaciaCampie", exit + 0.0175, 1.0, 4.0, 1.7, 0.95, "trunk")
	_place("acacia_umbrella_a", "acaciaCampie", exit + 0.0230, -1.0, 3.5, 3.6, 1.05, "trunk")
	_place("acacia_umbrella_c", "acaciaCampie", exit + 0.0290, 1.0, 7.0, 0.9, 1.1, "trunk")
	_place("acacia_umbrella_b", "acaciaCampie", exit + 0.0340, -1.0, 4.5, 2.3, 1.0, "trunk")
	# etajul de mijloc: 15-30 m de muchie, rar
	_place("acacia_umbrella_c", "acaciaMijloc", exit + 0.0100, 1.0, 18.0, 0.4, 1.1, "trunk")
	_place("acacia_umbrella_b", "acaciaMijloc", exit + 0.0200, -1.0, 22.0, 2.0, 1.05, "trunk")
	_place("acacia_umbrella_a", "acaciaMijloc", exit + 0.0300, 1.0, 26.0, 1.2, 1.0, "trunk")
	_place("dead_tree", "copacUscat", exit + 0.0150, 1.0, 12.0, 2.5, 1.0, "trunk")
	# euphorbii in iarba, la drum, si cateva pietre razlete (cazute din perete)
	for j in 8:
		var f := exit + 0.0060 + 0.0036 * float(j)
		var sgn := -1.0 if j % 2 == 0 else 1.0
		_place("euphorbia", "euphorbiaCampie", f, sgn, _rng.randf_range(1.2, 6.0),
			_rng.randf_range(0.0, TAU), _rng.randf_range(0.7, 1.0), "trunk")
	for j in 5:
		var f := exit + 0.0050 + 0.0050 * float(j)
		var sgn := 1.0 if j % 2 == 0 else -1.0
		_place("kopje_boulder_b" if j % 3 == 0 else "kopje_boulder_a", "piatraCazuta", f, sgn,
			_rng.randf_range(2.5, 9.0), _rng.randf_range(0.0, TAU), _rng.randf_range(0.7, 1.0),
			"hull" if j % 3 == 0 else "none")


## Tufe si pietre marunte LA MUCHIA drumului, pe intervalul dat. Nu e un tiv
## regulat: pasul are jitter de peste jumatate din el, distanta laterala e
## trasa din doua cozi (majoritatea la 0.3-3 m de muchie, cateva la 6-10 m),
## iar densitatea creste liniar spre capatul dinspre spartura. Piesele au voie
## sa se atinga — asta le face sa citeasca drept tufaris, nu drept obiecte.
func _undergrowth(f_from: float, f_to: float) -> void:
	var span := f_to - f_from
	var f := f_from
	var k := 0
	while f < f_to:
		# 0 la inceputul apropierii, 1 langa spartura
		var t: float = clampf((f - f_from) / maxf(span, 1e-6), 0.0, 1.0)
		for sgn: float in [-1.0, 1.0]:
			# doua-trei piese pe pas langa spartura, una la inceput
			var reps := 1 + int(_rng.randf() < 0.35 + 0.55 * t) + int(_rng.randf() < 0.15 + 0.45 * t)
			for r in reps:
				var near := _rng.randf() < 0.72
				# minimul e 0.7, nu 0.2: sub el marginea piesei intra in asfalt
				# (generatorul dadea 6 avertismente de degajare) — fara sa
				# blocheze (coliziune "none"), dar o tufa care creste din
				# carosabil se vede de la 30 m.
				var gap: float = _rng.randf_range(0.7, 3.2) if near else _rng.randf_range(5.0, 11.0)
				var jf := f + _rng.randf_range(-0.0009, 0.0009)
				# Amestecul e 0.30 euphorbia / 0.70 piatra, nu 0.58/0.42, si
				# euphorbia e mica (0.35-0.6, nu 0.5-0.95). Motiv masurat pe
				# cadrul erou al rundei: cu 55 de exemplare mari, euphorbia —
				# care e o planta COLUMNARA — umplea campul cu ce citeste ca
				# saguaro verde-deschis, adica desert american, nu savana. In
				# bara, stratul de la baza stancilor e din tufe mici si
				# rotunde, iar verdele mare vine DOAR din coroanele acaciilor.
				if _rng.randf() < 0.30:
					_place("euphorbia", "tufaApropiere", jf, sgn, gap,
						_rng.randf_range(0.0, TAU), _rng.randf_range(0.35, 0.6), "none")
				else:
					_place("kopje_boulder_a", "piatraApropiere", jf, sgn, gap,
						_rng.randf_range(0.0, TAU), _rng.randf_range(0.3, 0.75), "none")
		# pasul se strange spre spartura (0.0034 -> 0.0016 in fractii)
		f += _rng.randf_range(0.6, 1.4) * (0.0034 - 0.0018 * t)
		k += 1


## KICKERUL de la iesire: HazardMarker kind=6 (FLYOFF) — rampa de 12 m urca
## pana la 2,8 m si buza verticala te arunca pe lateritul din campie. Incepe
## chiar dupa capatul fetelor, ca sa zbori DIN spartura, nu inainte de ea.
func _kicker() -> void:
	var n := _track.baked.size()
	var f0 := float(_gap_idx) / float(n)
	var df := (GAP_LEN_Z * 0.5) / _m_per_frac / 1000.0
	# Rampa (12 m, track.gd FLYOFF_RISE_LEN) incepe cu 12 m inaintea CENTRULUI
	# sparturii, deci buza e la mijlocul taieturii. De ce nu la capat: gravitatia
	# jocului e 28 m/s2 (Car.gravity), deci la 30 m/s zborul e ~25 m si cu turbo
	# ~35 m; drumul coteste 16 grade pe 0.882-0.890, iar o aterizare dincolo de
	# 0.890 ar cadea cu 3-4 m in afara axei. Cu buza la 0.874 aterizezi la
	# 0.886-0.891: in gura sparturii, pe laterit, inca pe axa (abatere <3 m).
	var fk := f0 - 12.0 / _m_per_frac / 1000.0
	var p := _track.baked[_idx(fk)]
	print("; kicker FLYOFF la frac %.4f: rampa de la (%.2f, %.2f, %.2f), buza la ~%.4f" % [
		fk, p.x, p.y, p.z, fk + 12.0 / _m_per_frac / 1000.0])
	_haz.append('[node name="H_Kicker" type="Marker3D" parent="Hazarduri"]')
	_haz.append("transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.2f, %.2f, %.2f)" % [p.x, p.y, p.z])
	_haz.append("gizmo_extents = 3.0")
	_haz.append('script = ExtResource("hzm")')
	_haz.append("kind = 6")
	_haz.append("")


# ------------------------------------------------------------------ asezarea

## Distanta de la un punct pana la CEA MAI APROPIATA portiune de traseu, pe
## tot turul — nu doar pe felia noastra. Fara ea o piesa impinsa lateral din
## zona H aterizeaza pe alta bucata de sosea: aici traseul se intoarce pe
## z=165, la ~40 m de axa sparturii, si ProbeLaneClear a prins doua mase
## (`creasta45`, `creastaSpate57`) chiar pe banda de la frac 0.07-0.11.
func _dist_orice_drum(x: float, z: float) -> float:
	var best := INF
	var n := _track.baked.size()
	for j in n:
		var b := _track.baked[j]
		var d2 := (b.x - x) * (b.x - x) + (b.z - z) * (b.z - z)
		if d2 < best:
			best = d2
	return sqrt(best)


func _place(model: String, base: String, frac: float, side_sign: float,
		gap: float, yaw: float, scl: float, mode: String = "hull") -> void:
	var i := _idx(frac)
	var p := _track.baked[i]
	var s := _track._side_at(i) * side_sign
	var half := _track.width_at_index(i)
	var r: float = BASE_R.get(model, 0.6) * scl
	var d := half + gap + r
	var q := p + s * d
	var g := _sol_real(q.x, q.z)
	# Garda de traseu STRAIN: marginea piesei trebuie sa stea la >= 2 m de
	# ORICE carosabil, nu doar de al nostru. Piesele solide se muta inapoi
	# spre ax pana incap; daca nici lipite de banda noastra nu incap, se sar.
	if mode != "none":
		var tries := 0
		while _dist_orice_drum(q.x, q.z) < r + 9.0 and tries < 12:
			d -= 1.5
			if d - r < half + 0.5:
				print("; SARIT %s la frac %.4f: nu incape intre banda noastra si alt drum" % [
					model, frac])
				return
			q = p + s * d
			tries += 1
		g = _sol_real(q.x, q.z)
	if d - r < half + 0.5:
		_warn += 1
		print("; ATENTIE %s la frac %.4f: marginea la %.2f m de ax, banda %.2f" % [
			model, frac, d - r, half])
	if absf(p.y - g) > 1.2:
		print("; nota %s la frac %.4f: teren la %.2f m fata de sosea" % [model, frac, g - p.y])
	_raw(model, base, Vector3(q.x, g, q.z), yaw, Vector3.ONE * scl, mode)


func _raw(model: String, base: String, pos: Vector3, yaw: float, scl: Vector3,
		mode: String) -> void:
	_n += 1
	# Baza se construieste in cod si se scrie pe RANDURI (memoria
	# `tscn-transform-e-pe-randuri`); apoi se citeste inapoi si se compara.
	var b := Basis(Vector3.UP, yaw) * Basis.from_scale(scl)
	var s := "Transform3D(%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)" % [
		b.x.x, b.y.x, b.z.x, b.x.y, b.y.y, b.z.y, b.x.z, b.y.z, b.z.z,
		pos.x, pos.y, pos.z]
	var back: Transform3D = str_to_var(s)
	if (back.basis.z - b.z).length() > 1e-3 or (back.basis.x - b.x).length() > 1e-3:
		print("; EROARE de serializare pe %s: %s" % [base, s])
	_out.append('[node name="%s%d" parent="%s" instance=ExtResource("%s")]' % [
		base, _n, ZONE, RES[model]])
	_out.append("transform = " + s)
	if mode != "hull":
		_out.append('metadata/coliziune = "%s"' % mode)
	_out.append("")


## Cota SOLULUI din coliziunea reala a panzei de teren (portat din
## gen_decor_capp_a: `_terrain_mesh_y` extrapoleaza, campul e neted).
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
	print("; ATENTIE fara sol la (%.1f, %.1f): se cade pe camp" % [x, z])
	return _sampler.ground_y(x, z)
