extends Node
## Generator de decor MANUAL pentru POI F — SERPENTINELE SENETO (Track14,
## frac 0.500-0.715, coborarea in crater). Nu e sonda, e unealta care
## MASOARA terenul real (raycast pe TerrainBody, nu campul) si CALCULEAZA
## transformarile care se lipesc in Track14.tscn sub
## `DecorManual/ZoneF_Serpentine`.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorSerF.tscn -- --survey
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorSerF.tscn -- --emit
##
## `--survey` tipareste relieful (grila de cote + profil lateral per fractie +
## directia soarelui); `--emit` tipareste nodurile .tscn.
##
## Ce decide compozitia (cifrele sunt masurate cu --survey, runda 1):
##
## 1. GEOMETRIA SERPENTINEI. Patru drepte pe z = -116 / -86 / -56 / -26
##    (x intre ~80 si ~174), legate de ace de par la x~172 (dreapta) si x~80
##    (stanga); cota coboara 41 -> 7 m, adica ~11.3 m intre doua drepte
##    vecine aflate la 30 m una de alta. Panta terenului dintre drepte e
##    deci ~37% (20 grade): un VERSANT, nu un perete. Referinta are perete
##    de granit fatetat intre drepte. Peretele se CONSTRUIESTE (CliffFace
##    `cut_wall`, memoria cliff_face.gd: campul de teren are celula de 7.9 m
##    si nu poate tine o faleza), pe latura din AMONTE a fiecarei drepte.
##
## 2. AMONTE ALTERNEAZA. Drumul coboara spre +z; pe dreapta care merge spre
##    -x amontele (-z) e in DREAPTA sensului de mers, pe cea spre +x e in
##    STANGA. Brief-ul spune „peretele pe stanga, golul pe dreapta" — e
##    adevarat doar pe jumatate din drepte; aici se urmeaza terenul.
##
## 3. BOLOVANII. kopje_boulder_a/b/c (2/4/6 m) se aseaza pe versantul din
##    amonte, la 1.5-9 m de muchie, ca moloz cazut din perete, cu cei mari
##    mai departe (plafonul de cadru 10 + 0.093*d). Pe aval, la buza, cativa
##    mici (a) — ce s-a rostogolit si s-a oprit pe umar.
##
## 4. CHEVRON-URILE stau pe EXTERIORUL fiecarui ac (partea spre care te
##    duce inertia), pe arc, la 1.0 m de muchie, cu fata spre drum.

const TRACK := "res://scenes/tracks/Track14.tscn"
const ZONE := "DecorManual/ZoneF_Serpentine"

## Intervalul POI-ului (masurat cu ProbeFrac pe traseul real).
const F0 := 0.500
const F1 := 0.715

const RES := {
	"kopje_boulder_a": "s_kopje_boulder_a",
	"kopje_boulder_b": "s_kopje_boulder_b",
	"kopje_boulder_c": "s_kopje_boulder_c",
	"chevron_post": "s_chevron_post",
	"euphorbia": "s_euphorbia",
	"dead_tree": "s_dead_tree",
	"acacia_umbrella_a": "s_acacia_umbrella_a",
	"acacia_umbrella_c": "s_acacia_umbrella_c",
	"fever_tree": "s_fever_tree",
	"termite_mound_a": "s_termite_mound_a",
}

## Raza la baza (jumatate din latura mare a AABB-ului, probe_serengeti_kit).
const BASE_R := {
	"kopje_boulder_a": 1.08, "kopje_boulder_b": 2.03, "kopje_boulder_c": 2.80,
	"chevron_post": 0.3, "euphorbia": 0.92, "dead_tree": 2.36,
	"acacia_umbrella_a": 4.45, "acacia_umbrella_c": 6.24, "fever_tree": 4.36,
	"termite_mound_a": 0.8,
}

var _track: Track
var _sampler: TrackSideSampler
var _terrain_rid: RID = RID()
var _sus_y := 0.0
var _out: Array[String] = []
var _n := 0
var _warn := 0
var _rng := RandomNumberGenerator.new()


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
	_rng.seed = 140601
	var args := OS.get_cmdline_user_args()
	if "--survey" in args:
		_survey()
	else:
		_emit()
	get_tree().quit(0)


# ------------------------------------------------------------------ survey

func _survey() -> void:
	# Soarele: din nodul real, nu din euler-ul temei.
	for c in _track.get_children():
		if c is DirectionalLight3D:
			var d := -(c as DirectionalLight3D).global_transform.basis.z
			print("; soare: lumina merge spre (%.3f, %.3f, %.3f); umbra pe XZ spre (%.3f, %.3f)"
				% [d.x, d.y, d.z, d.x, d.z])
	print("; profil per fractie: frac  x z y  dir  side  half | amonte(+2,+6,+12,+20 m de muchie) | aval(+2,+6,+12,+20)")
	var n := _track.baked.size()
	var f := F0 - 0.01
	while f <= F1 + 0.01:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var dir := (_track.baked[(i + 1) % n] - p).normalized()
		var half := _track.width_at_index(i)
		# amonte = latura pe care terenul URCA. Se decide masurand la +6 m.
		var gr := _sol_real(p.x + s.x * (half + 6.0), p.z + s.z * (half + 6.0))
		var gl := _sol_real(p.x - s.x * (half + 6.0), p.z - s.z * (half + 6.0))
		var up_sign := 1.0 if gr > gl else -1.0
		var line := "%.3f  %7.1f %7.1f %5.1f  dir(%5.2f,%5.2f) side(%5.2f,%5.2f) half %.1f amonte=%s |" % [
			f, p.x, p.z, p.y, dir.x, dir.z, s.x, s.z, half, "R" if up_sign > 0 else "L"]
		for off: float in [2.0, 6.0, 12.0, 20.0]:
			var q: Vector3 = p + s * up_sign * (half + off)
			line += " %+6.1f" % (_sol_real(q.x, q.z) - p.y)
		line += " |"
		for off: float in [2.0, 6.0, 12.0, 20.0]:
			var q: Vector3 = p - s * up_sign * (half + off)
			line += " %+6.1f" % (_sol_real(q.x, q.z) - p.y)
		print(line)
		f += 0.005
	print("; grila de cote (y), x pe coloane 40..220 pas 10, z pe randuri -170..30 pas 10")
	var hdr := ";     z\\x"
	var x := 40.0
	while x <= 220.0:
		hdr += "%6.0f" % x
		x += 10.0
	print(hdr)
	var z := -170.0
	while z <= 30.0:
		var row := "; %6.0f" % z
		x = 40.0
		while x <= 220.0:
			row += "%6.1f" % _sol_real(x, z)
			x += 10.0
		print(row)
		z += 10.0


# ------------------------------------------------------------------ emit

func _emit() -> void:
	# Peretii de granit se pun ca noduri CliffFace in .tscn (scrise de mana in
	# blocul Faleze), nu de aici: ele isi masoara singure creasta la Regenerate.
	# Aici se emit doar prop-urile ASEZATE, cu cota din raycast real.
	#
	# Straturile de la baza peretelui, in ordinea din referinta:
	#  1. moloz DES la piciorul taieturii (bolovanii care s-au desprins),
	#  2. bolovani mari mai departe, pe versant, ca sa dea etaj,
	#  3. vegetatie rara AGATATA de perete (euforbii, acacii pipernicite),
	#  4. cativa bolovani mici pe umarul dinspre gol,
	#  5. chevron-uri pe exteriorul acelor de par.
	for seg in STRAIGHTS:
		_populate_straight(seg["f0"], seg["f1"], seg["up"])
	for h in HAIRPINS:
		_hairpin(h["f"], h["up"])
	for line in _out:
		print(line)
	print("; asezate %d piese, %d avertismente" % [_n, _warn])


## Cele patru drepte, cu latura din AMONTE masurata cu --survey (coloana
## `amonte`): +1 = dreapta sensului de mers, -1 = stanga.
## `up` e semnul care inmulteste `_side_at` ca sa dea AMONTELE. Atentie:
## `Track._side_at` arata spre STANGA sensului de mers (verificat cu produsul
## vectorial pe dir/side tiparite de --survey si confirmat in captura
## F_r1_hero2: cu semnul dedus din coloana `amonte` peretele a iesit pe partea
## golului, fix in fata camerei). Coloana `amonte` a survey-ului e deci
## etichetata pe dos; semnele de aici sunt cele CORECTATE.
const STRAIGHTS := [
	{"f0": 0.519, "f1": 0.557, "up": -1.0},
	{"f0": 0.565, "f1": 0.611, "up": 1.0},
	{"f0": 0.623, "f1": 0.664, "up": -1.0},
	{"f0": 0.674, "f1": 0.701, "up": 1.0},
]
## Acele de par: fractia varfului si latura din amonte acolo.
const HAIRPINS := [
	{"f": 0.5135, "up": -1.0},
	{"f": 0.5605, "up": -1.0},
	{"f": 0.6175, "up": 1.0},
	{"f": 0.6675, "up": 1.0},
]


## Un tronson drept: moloz la piciorul peretelui + bolovani pe versant +
## vegetatie agatata + cativa bolovani pe umarul dinspre gol.
func _populate_straight(f0: float, f1: float, up: float) -> void:
	var n := _track.baked.size()
	# Pasul: ~7 m pe traseu, cu jitter de peste jumatate din pas (lectia
	# valurilor 1-2: un scatter pe grila se citeste ca instante plasate).
	var span := f1 - f0
	var steps := maxi(int(round(span * 2098.7 / 7.0)), 3)
	for k in steps:
		var t := (float(k) + 0.5) / float(steps)
		var f: float = f0 + span * t
		var i := int(f * float(n)) % n
		var p: Vector3 = _track.baked[i]
		var s: Vector3 = _track._side_at(i) * up
		var half: float = _track.width_at_index(i)
		# Stingere la capete: molozul nu incepe brusc.
		var edge: float = minf(t, 1.0 - t) / 0.14
		var dens: float = clampf(edge, 0.35, 1.0)
		# --- 1. moloz la picior: 1-2 bolovani mici, lipiti de perete, care se
		# SUPRAFATA unul pe altul (referinta: gramada, nu sirag).
		var cnt := 1 + (1 if _rng.randf() < 0.55 * dens else 0)
		for _c in cnt:
			var off: float = half + 1.6 + _rng.randf_range(0.0, 2.6)
			var along: float = _rng.randf_range(-3.4, 3.4)
			_place("kopje_boulder_a", p, s, off, along, i,
				_rng.randf_range(0.55, 1.05))
		# --- 2. bolovan mare pe versant, mai departe (etajul al doilea).
		if _rng.randf() < 0.55 * dens:
			var nm := "kopje_boulder_b" if _rng.randf() < 0.6 else "kopje_boulder_c"
			_place(nm, p, s, half + _rng.randf_range(5.0, 11.0),
				_rng.randf_range(-3.0, 3.0), i, _rng.randf_range(0.8, 1.25))
		# --- 3. vegetatie AGATATA de perete. Referinta (ref_F.png) are peretele
		# ACOPERIT de coroane late verzi care se ating; euforbia-candelabru e
		# accentul RAR dintre ele. Runda 2 avea raportul invers (20 euforbii /
		# 6 acacii, numarate in .tscn) si acacii impinse la 8-14 m si micsorate
		# la 0.55-0.8 — de aceea criticul a citit banda ca pe un desert de
		# saguaro: singura silueta care ajungea langa drum era cea columnara.
		# Aici acacia devine specia DOMINANTA (0.46 fata de 0.10), se aseaza la
		# 2.5-9 m de asfalt si la scara 0.85-1.25. Verificarea de frustum:
		# acacia_c are 10 m (inventar), deci la 8 m distanta plafonul e
		# 10 + 0.093*8 = 10.7 m — coroana intra intreaga in cadru.
		var r := _rng.randf()
		# Scara si distanta merg IMPREUNA: coroana lui acacia_c are raza 6.24 m,
		# deci la 3 m de asfalt si scara 1.25 ea umple un sfert de cadru si
		# ascunde chiar peretele pe care trebuia sa-l imbrace (masurat pe
		# F_r3_hero, prima varianta). Exemplarele MARI (c, scara 0.85-1.10) se
		# duc la 7-13 m, unde coroana se citeste intreaga peste versant; langa
		# drum ramane doar `a`, cel mic (7 m inaltime), la scara 0.55-0.75.
		if r < 0.46 * dens:
			if _rng.randf() < 0.55:
				_place("acacia_umbrella_c", p, s, half + _rng.randf_range(7.0, 13.0),
					_rng.randf_range(-4.0, 4.0), i, _rng.randf_range(0.85, 1.10))
			else:
				_place("acacia_umbrella_a", p, s, half + _rng.randf_range(2.5, 6.0),
					_rng.randf_range(-4.0, 4.0), i, _rng.randf_range(0.55, 0.75))
		elif r < 0.56 * dens:
			_place("euphorbia", p, s, half + _rng.randf_range(2.2, 7.5),
				_rng.randf_range(-3.0, 3.0), i, _rng.randf_range(0.8, 1.4))
		elif r < 0.62 * dens:
			_place("dead_tree", p, s, half + _rng.randf_range(3.0, 8.0),
				_rng.randf_range(-3.0, 3.0), i, _rng.randf_range(0.6, 0.95))
		# --- 4. umarul dinspre GOL: pietre mici si un tufis, ca muchia sa nu fie
		# o taietura curata de asfalt in nisip.
		if _rng.randf() < 0.5 * dens:
			_place("kopje_boulder_a", p, -s, half + _rng.randf_range(0.8, 2.4),
				_rng.randf_range(-3.0, 3.0), i, _rng.randf_range(0.35, 0.7))
		# Umarul dinspre gol primeste tot acacie mica, nu euforbie: sirul de
		# candelabre de pe partea golului era exact banda pe care criticul a
		# numit-o „cactusi saguaro pe toata banda dreapta".
		if _rng.randf() < 0.22 * dens:
			_place("acacia_umbrella_a", p, -s, half + _rng.randf_range(1.5, 4.0),
				_rng.randf_range(-3.0, 3.0), i, _rng.randf_range(0.40, 0.60))


## Un ac de par: chevron-uri pe EXTERIOR (partea spre care te duce inertia,
## adica opusul amontelui) plus bolovani mari pe nasul virajului.
func _hairpin(fc: float, up: float) -> void:
	var n := _track.baked.size()
	var outn := -up
	# 7 tarusi pe arc, la ~0.9 m de marginea asfaltului.
	for k in 7:
		var f: float = fc + (float(k) - 3.0) * 0.0042
		var i := int(f * float(n)) % n
		var p: Vector3 = _track.baked[i]
		var s: Vector3 = _track._side_at(i) * outn
		var half: float = _track.width_at_index(i)
		_place("chevron_post", p, s, half + 0.9, 0.0, i, 1.0, true)
	# Nasul virajului, pe exterior: doi-trei bolovani mari care inchid cadrul.
	for k in 3:
		var f: float = fc + (float(k) - 1.0) * 0.006
		var i := int(f * float(n)) % n
		var p: Vector3 = _track.baked[i]
		var s: Vector3 = _track._side_at(i) * outn
		var half: float = _track.width_at_index(i)
		_place("kopje_boulder_b", p, s, half + _rng.randf_range(3.5, 7.0),
			_rng.randf_range(-2.0, 2.0), i, _rng.randf_range(0.7, 1.1))


## Asaza o piesa: cota din raycast real, yaw variat, verificare de gabarit fata
## de carosabil (nimic solid pe banda).
func _place(nm: String, p: Vector3, s: Vector3, off: float, along: float,
		i: int, sc: float, face_road: bool = false) -> void:
	var n := _track.baked.size()
	var dir: Vector3 = (_track.baked[(i + 1) % n] - _track.baked[i]).normalized()
	var pos: Vector3 = p + s * off + dir * along
	var y := _sol_real(pos.x, pos.z)
	var r: float = BASE_R.get(nm, 1.0) * sc
	# Garda de banda: marginea piesei nu are voie sa intre in asfalt.
	# Latimea se ia la indexul UNDE AJUNGE piesa dupa deplasarea `along`, nu la
	# `i`: pe ace de par carosabilul se largeste si se curbeaza spre piesa, iar
	# un bolovan mare mutat cu 4 m pe traseu ajunge in fata unei benzi mai late
	# decat cea masurata la `i`. Runda 3 a prins asa o regresie reala
	# (FKop128_col, kopje_boulder_c la frac 0.710, +2.0 m in banda), aparuta
	# doar fiindca schimbarea mixului de vegetatie a decalat sirul RNG.
	# Marja urca la 0.6 m: BASE_R e jumatate din latura AABB-ului, deci
	# subestimeaza un bolovan rotit neuniform.
	var j := i
	if absf(along) > 0.01:
		var seg: float = _track.baked[(i + 1) % n].distance_to(_track.baked[i])
		if seg > 0.01:
			j = posmod(i + int(round(along / seg)), n)
	var w_here: float = maxf(_track.width_at_index(i), _track.width_at_index(j))
	# Piesa care nu incape NU se arunca: se IMPINGE spre exterior pana incape.
	# Aruncarea era o pierdere dubla — cu marja stransa la 0.6 m si acacii mari
	# se pierdeau 23 de piese din 176, adica exact densitatea de coroane pe care
	# o cere referinta. Se renunta la piesa doar daca nici la +6 m nu incape
	# (atunci chiar nu e loc intre asfalt si buza).
	var need: float = w_here + 0.6 + r
	if off < need:
		if need - off <= 6.0:
			off = need
			pos = p + s * off + dir * along
			y = _sol_real(pos.x, pos.z)
		else:
			_warn += 1
			return
	# Cota se REVERIFICA pe gabaritul piesei, nu doar in centrul ei. Raycast-ul
	# din centru nimereste uneori peretele unei scobituri (`Scobituri`, terasele
	# rundei 2): solul e la cota buzei in centru si cu 3 m mai jos la o jumatate
	# de raza distanta, iar piesa ramane atarnata peste gol. Runda 3 a avut un
	# singur caz (FAca44, +3.40 m raportat de probe_manual), dar unul e destul —
	# copacul plutea la 10 m de axa, adica exact in cadrul soferului.
	# MINIMUL pe tot conturul e prea agresiv: pe versantul de ~20 de grade un
	# copac ar fi tras la cota muchiei lui din vale si ar iesi INGROPAT cu 2-5 m
	# (masurat: 3 cazuri). Piesa sta pe TRUNCHI, deci cota de referinta ramane
	# cea din centru; conturul serveste doar ca sa prinda golul de sub ea.
	# Se coboara doar cand centrul e mult peste conturul cel mai jos — atunci
	# raycast-ul din centru a nimerit buza unei scobituri — si doar pana la
	# MEDIA conturului, ca panta normala sa nu ingroape nimic.
	if r > 0.6:
		var acc := 0.0
		var lo := y
		for a in 4:
			var an: float = TAU * float(a) / 4.0
			var gy := _sol_real(pos.x + cos(an) * r * 0.7, pos.z + sin(an) * r * 0.7)
			acc += gy
			lo = minf(lo, gy)
		var avg: float = acc / 4.0
		if y - lo > 1.5:
			y = minf(y, avg)
	var yaw: float = _rng.randf_range(-PI, PI)
	if face_road:
		# Chevron-ul se uita SPRE drum: -Z al piesei pe -s.
		yaw = atan2(-s.x, -s.z)
	# Bolovanii primesc si o inclinare mica, ca sa nu para asezati cu macaraua.
	var b := Basis(Vector3.UP, yaw)
	if nm.begins_with("kopje_boulder"):
		b = b * Basis(Vector3.RIGHT, _rng.randf_range(-0.18, 0.18))
		b = b * Basis(Vector3.FORWARD, _rng.randf_range(-0.18, 0.18))
	b = b.scaled(Vector3(sc, sc, sc))
	# Piesele de roca se ingroapa putin, ca sa nu para puse pe masa.
	if nm.begins_with("kopje_boulder"):
		y -= r * 0.18
	_n += 1
	_out.append("[node name=\"F%s%d\" parent=\"DecorManual/ZoneF_Serpentine\" instance=ExtResource(\"%s\")]"
		% [nm.substr(0, 3).capitalize(), _n, RES[nm]])
	_out.append("transform = Transform3D(%.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.3f, %.3f, %.3f)"
		% [b.x.x, b.x.y, b.x.z, b.y.x, b.y.y, b.y.z, b.z.x, b.z.y, b.z.z,
			pos.x, y, pos.z])


# ------------------------------------------------------------------ helpers

## Cota SOLULUI din coliziunea reala a panzei de teren (TerrainBody), nu din
## camp si nu din `_terrain_mesh_y` (memoria `terrain-mesh-y-extrapoleaza`).
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
