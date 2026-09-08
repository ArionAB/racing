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
}

## Raza la sol a piesei (probe_serengeti_kit: jumatate din latura mare a AABB
## pentru bolovani; TRUNCHIUL pentru copaci — coroana are voie peste drum).
const BASE_R := {
	"kopje_boulder_a": 1.07, "kopje_boulder_b": 2.03, "kopje_boulder_c": 2.80,
	"euphorbia": 0.90, "acacia_umbrella_a": 0.6, "acacia_umbrella_b": 0.7,
	"acacia_umbrella_c": 0.8, "dead_tree": 0.5,
}

## Spartura: din AABB-ul GLB-ului (pos -18.37..17.80 pe X, -21.64..22.16 pe Z).
const GAP_FREE_X: float = 12.0
const GAP_LEN_Z: float = 43.8
## Cat ramane liber intre muchia carosabilului si fata de granit, minim.
const GAP_MARGIN: float = 2.0
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
					_rng.randf_range(0.0, TAU), Vector3.ONE * _rng.randf_range(0.55, 0.85), "none")
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
