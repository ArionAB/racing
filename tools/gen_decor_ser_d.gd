extends Node
## Generator de decor MANUAL pentru POI D — PADUREA DE CEATA (Track14,
## Serengeti, frac 0.196-0.339, urcarea 0 -> 45 m pe flancul craterului).
## Ca la Cappadocia (gen_decor_capp_a.gd): nu e sonda, e unealta care
## CALCULEAZA transformarile ce se lipesc in Track14.tscn sub
## `DecorManual/ZoneD_PadureaDeCeata`.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorSerD.tscn -- \
##       --out=C:/cale/zoneD.part [--survey]
##
## Cu `--survey` scrie doar profilul terenului (cote pe laterale, panta,
## directia umbrei) si nu genereaza nimic — compozitia se decide pe cifre.
##
## Ce decide compozitia (masurat cu --survey, runda 1, D_r1_survey.txt):
##
## 1. TERENUL E O RAMPA LINA, NU UN FLANC. Pe tot intervalul solul sta la
##    ±0.5 m de sosea pana la 15 m lateral si la cel mult ±6 m la 40 m;
##    partea care URCA alterneaza cu S-urile (la 0.24 urca stanga +5.2 m la
##    40 m, la 0.27 urca dreapta +3.8 m). Deci etajele NU ies din teren:
##    al doilea etaj e facut din smochini mai INALTI (14-17 m) in randul
##    al doilea, iar „versantul de granit" e o pereche de grupuri de
##    bolovani puse pe partea masurata ca urca la fiecare S (nu „dreapta").
##
## 2. PLAFONUL DE CADRU (10 + 0.093*d) decide cat de aproape stau smochinii
##    de 13 m: la 4 m de muchie centrul e la 6.5 + 4 + 0.6 = 11.1 m de ax,
##    deci camera vede pana la 11 m — coroana intra intreaga cu varful taiat
##    usor, exact ce trebuie: drumul intra SUB copaci (brief §2 D).
##
## 3. CAMERA NU ARE VOIE IN COROANE. Camera zboara pe axa la 10 m si taie
##    coltul in S-uri cu 2-3 m; coroana smochinului are raza 5.6 m, deci la
##    sub 4 m de muchie ar ajunge la mai putin de 5 m de ax si camera ar
##    intra in frunzis la fiecare ocolire pe umar. Randul apropiat sta la
##    4.0-6.5 m de muchie.
##
## 4. DENSITATEA E CE SE VEDE, NU CE SE NUMARA (memoria
##    driver-view-for-composition): un copac la 9 m pe fiecare parte, cu
##    coroane de 11 m, inseamna coroane care se ATING de-a lungul benzii; al
##    doilea rand la 11 m pas, al treilea la 16 m — primul plan plin,
##    fundalul se rareste in ceata, ca in referinta.
##
## 5. DEGAJAREA se masoara de la MUCHIA drumului la TRUNCHI (coliziunea e
##    `trunk` pe toti copacii — world_prop), nu la coroana: coroana are voie
##    peste umar, trunchiul nu.
##
## 6. SOARELE (survey): lumina merge spre (-0.58,-0.57,0.58), elevatie 35;
##    umbra pe XZ -> (-0.707, +0.707). Pe drepte (0.20-0.22, 0.27-0.28)
##    umbra cade spre STANGA (dot side/umbra = -1): copacii din dreapta
##    arunca umbre PESTE drum — de aia randul din dreapta e cel mai des.
##    Pe 0.24-0.25 si 0.30-0.31 soarele e in fata camerei (umbrele vin
##    spre ea).
##
## 7. Copacii uscati NU intra: referinta e o masa verde-inchis compacta, un
##    trunchi gol in ea ar fi un gol. Subarboretul e doar euphorbia.

const TRACK := "res://scenes/tracks/Track14.tscn"
const ZONE := "DecorManual/ZoneD_PadureaDeCeata"

## Inceputul/sfarsitul padurii pe traseu (brief-ul bucatii D).
const F_IN := 0.196
const F_OUT := 0.339
## Pana unde e DEASA (intrarea si iesirea se raresc).
const F_DENSE_IN := 0.214
const F_DENSE_OUT := 0.328

## id-urile ext_resource din Track14.tscn (handoff §1).
const RES := {
	"fig_tree": "s_fig_tree",
	"fever_tree": "s_fever_tree",
	"euphorbia": "s_euphorbia",
	"dead_tree": "s_dead_tree",
	"kopje_boulder_a": "s_kopje_boulder_a",
	"kopje_boulder_b": "s_kopje_boulder_b",
	"kopje_boulder_c": "s_kopje_boulder_c",
	"acacia_umbrella_a": "s_acacia_umbrella_a",
}

## Raza de DEGAJARE la sol (m): trunchiul la copaci (coliziunea e trunk),
## jumatatea laturii mari la bolovani (hull). Din AABB-urile masurate
## (0_r1_kit_probe.txt).
const BASE_R := {
	"fig_tree": 0.7, "fever_tree": 0.5, "euphorbia": 0.9, "dead_tree": 0.6,
	"kopje_boulder_a": 1.1, "kopje_boulder_b": 2.0, "kopje_boulder_c": 2.8,
	"acacia_umbrella_a": 0.5,
}
## Raza COROANEI (m), pentru testul camerei (nota 3) si pentru „se ating".
const CROWN_R := {
	"fig_tree": 5.6, "fever_tree": 4.4, "euphorbia": 0.9, "dead_tree": 2.4,
	"kopje_boulder_a": 1.1, "kopje_boulder_b": 2.0, "kopje_boulder_c": 2.8,
	"acacia_umbrella_a": 4.5,
}
## Inaltimea reala (m) — scara se cere in METRI, nu din burta.
const HEIGHT := {
	"fig_tree": 13.0, "fever_tree": 10.12, "euphorbia": 4.03, "dead_tree": 6.01,
	"kopje_boulder_a": 1.44, "kopje_boulder_b": 2.88, "kopje_boulder_c": 4.32,
	"acacia_umbrella_a": 7.04,
}

var _track: Track
var _sampler: TrackSideSampler
var _terrain_rid: RID = RID()
var _sus_y := 0.0
var _out: Array[String] = []
var _n := 0
var _warn := 0
var _rng := RandomNumberGenerator.new()
var _out_path := ""
var _survey_only := false
var _tri := 0
const TRI := {
	"fig_tree": 3494, "fever_tree": 1188, "euphorbia": 1558, "dead_tree": 404,
	"kopje_boulder_a": 158, "kopje_boulder_b": 178, "kopje_boulder_c": 178,
	"acacia_umbrella_a": 1176,
}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out_path = a.trim_prefix("--out=")
		elif a == "--survey":
			_survey_only = true
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	_sampler = _track._sampler
	var nd: int = _track.baked.size()
	if _track._dists.size() > nd:
		_total_len = float(_track._dists[nd])
	print("; lungime traseu %.1f m, %d puncte" % [_total_len, nd])
	var hi := -INF
	for bp in _track.baked:
		hi = maxf(hi, bp.y)
	_sus_y = hi + 120.0
	_rng.seed = 140401
	_survey()
	if not _survey_only:
		_understory()
		_near_row()
		_second_row()
		_far_row()
		_granite()
		_edges()
		_mist()
		_write()
	get_tree().quit(0)


# ------------------------------------------------------------------ masuratori

## Profilul terenului pe laterale + directia umbrei. Se citeste INAINTE de
## compozitie; cifrele din antet vin de aici.
func _survey() -> void:
	var sun := _find_sun(_track)
	if sun != null:
		var dir: Vector3 = -sun.global_transform.basis.z
		# Umbra cade in sensul in care merge lumina (dir), proiectat pe XZ.
		var sh := Vector3(dir.x, 0.0, dir.z).normalized()
		print("; soare: rot %s, lumina merge spre (%.2f, %.2f, %.2f), umbra pe XZ -> (%.3f, %.3f), elevatie %.1f deg" % [
			str(sun.rotation_degrees), dir.x, dir.y, dir.z, sh.x, sh.z,
			rad_to_deg(asin(-dir.y))])
	var n := _track.baked.size()
	print("; frac      ax(x,z)          y_drum  half  side(x,z)        sol la -40 -25 -15 -8 | +8 +15 +25 +40   dot(side,umbra)")
	var f := 0.19
	var shadow := Vector3.ZERO
	if sun != null:
		var d: Vector3 = -sun.global_transform.basis.z
		shadow = Vector3(d.x, 0.0, d.z).normalized()
	while f <= 0.35:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var half := _track.width_at_index(i)
		var cols: Array[String] = []
		for off: float in [-40.0, -25.0, -15.0, -8.0, 8.0, 15.0, 25.0, 40.0]:
			var q := p + s * off
			cols.append("%+6.1f" % (_sol_real(q.x, q.z) - p.y))
		print("; %.3f  (%7.1f,%7.1f)  %5.1f  %4.1f  (%+.2f,%+.2f)  %s  %+.2f" % [
			f, p.x, p.z, p.y, half, s.x, s.z, " ".join(cols), s.dot(shadow)])
		f += 0.01


func _find_sun(node: Node) -> DirectionalLight3D:
	if node is DirectionalLight3D:
		return node as DirectionalLight3D
	for c in node.get_children():
		var r := _find_sun(c)
		if r != null:
			return r
	return null


# ------------------------------------------------------------------ compozitia

## Cat de „in padure" e fractia: 0 la margini, 1 in interiorul dens. Randurile
## se raresc cu ea, ca padurea sa se INCHIDA peste drum in 20 m, nu sa apara
## dintr-un foc.
func _density(f: float) -> float:
	if f < F_IN or f > F_OUT:
		return 0.0
	var a := clampf((f - F_IN) / (F_DENSE_IN - F_IN), 0.0, 1.0)
	var b := clampf((F_OUT - f) / (F_OUT - F_DENSE_OUT), 0.0, 1.0)
	return minf(a, b)


## Pasul pe traseu in fractii pentru `meters` metri.
func _step(meters: float) -> float:
	return meters / _total_len


var _total_len := 2098.7


## SUBARBORETUL: euphorbia (4 m) si copaci uscati pe umar, la 0.8-2.5 m de
## muchie. E stratul de la inaltimea ochiului, cel care trece pe langa geam;
## fara el intre iarba si coroanele de la 8 m nu e nimic.
func _understory() -> void:
	var f := F_IN
	var k := 0
	while f < F_OUT:
		var dens := _density(f)
		var sgn := -1.0 if k % 2 == 0 else 1.0
		# Rar: referinta n-are candelabre, are numai masa verde a coroanelor.
		# Cateva pe umar dau scara la nivelul geamului, mai multe fac cactusi.
		if _rng.randf() < 0.15 + 0.35 * dens:
			_place("euphorbia", "euforbie", f, sgn,
				_rng.randf_range(1.5, 3.0), _rng.randf_range(0.0, TAU),
				_scale_for("euphorbia", _rng.randf_range(3.0, 4.2)), "trunk")
		f += _step(9.0)
		k += 1


## RANDUL APROPIAT: smochini (13 m) si acacii galbene (10 m) la 4.0-6.5 m de
## muchie, un copac la ~9 m pe fiecare parte. Coroanele de 11 m se ating
## de-a lungul benzii si trec peste umar; asta e „drumul intra sub copaci".
func _near_row() -> void:
	for sgn: float in [-1.0, 1.0]:
		var f := F_IN + (0.0 if sgn < 0.0 else _step(4.5))
		var k := 0
		while f < F_OUT:
			var dens := _density(f)
			# La margini randul se rareste si trece pe fever tree (mai mic, mai
			# deschis): tranzitia de biom din savana in padure.
			var mdl := "fig_tree"
			if k % 3 == 2 or dens < 0.5:
				mdl = "fever_tree"
			if _rng.randf() < 0.25 + 0.75 * dens:
				var h := _rng.randf_range(11.0, 13.5) if mdl == "fig_tree" \
					else _rng.randf_range(9.0, 11.0)
				_place(mdl, "smochin" if mdl == "fig_tree" else "febra", f, sgn,
					_rng.randf_range(4.0, 6.5), _rng.randf_range(0.0, TAU),
					_scale_for(mdl, h), "trunk")
			f += _step(7.0 + _rng.randf_range(-1.2, 1.2))
			k += 1


## AL DOILEA RAND: smochini mai MARI (14-17 m) la 9-16 m de muchie. Pe dreapta
## terenul urca, deci coroanele lor ies PESTE primul rand (al doilea etaj din
## referinta); pe stanga terenul coboara si se aduna in masa.
func _second_row() -> void:
	for sgn: float in [-1.0, 1.0]:
		var f := F_IN + _step(2.0 if sgn < 0.0 else 7.0)
		var k := 0
		while f < F_OUT:
			var dens := _density(f)
			if _rng.randf() < 0.15 + 0.85 * dens:
				var mdl := "fig_tree" if k % 4 != 1 else "fever_tree"
				var h := _rng.randf_range(14.0, 17.0) if mdl == "fig_tree" \
					else _rng.randf_range(10.0, 12.0)
				_place(mdl, "smochinSpate" if mdl == "fig_tree" else "febraSpate",
					f, sgn, _rng.randf_range(9.0, 16.0), _rng.randf_range(0.0, TAU),
					_scale_for(mdl, h), "trunk")
			f += _step(8.5 + _rng.randf_range(-1.5, 1.5))
			k += 1


## FUNDALUL: la 20-36 m de muchie, la ~10 m pas. Umple golurile dintre
## trunchiuri pe interiorul S-urilor, unde camera priveste PESTE primul rand;
## in ceata culoarului ies ca siluete verde-gri.
func _far_row() -> void:
	for sgn: float in [-1.0, 1.0]:
		var f := F_IN + _step(5.0 if sgn < 0.0 else 12.0)
		var k := 0
		while f < F_OUT:
			var dens := _density(f)
			if _rng.randf() < 0.2 + 0.8 * dens:
				var mdl := "fig_tree" if k % 4 != 3 else "fever_tree"
				var h := _rng.randf_range(13.0, 17.0) if mdl == "fig_tree" \
					else _rng.randf_range(10.0, 12.0)
				_place(mdl, "smochinFund" if mdl == "fig_tree" else "febraFund",
					f, sgn, _rng.randf_range(20.0, 36.0), _rng.randf_range(0.0, TAU),
					_scale_for(mdl, h), "trunk")
			f += _step(10.0 + _rng.randf_range(-2.0, 2.0))
			k += 1
	_backdrop()


## ZIDUL DE FUND: smochinii cei mai INALTI (16-19 m) la 38-60 m de muchie, la
## ~12 m pas. Masurat pe captura v1 (D_r1_a026.png, D_r1_a0.253.png): la
## iesirea din fiecare S camera priveste PESTE randurile de la 4-36 m si vede
## CERUL violet intre coroane — padurea „se termina" la 40 m. In referinta nu
## exista orizont in padure: fiecare gol dintre coroane e alta coroana, mai
## departe si mai in ceata. Inaltimea mare e ca sa se vada PESTE randurile
## din fata (plafonul 10 + 0.093*d la 50 m = 14.6 m, deci varful e taiat —
## bine: intra sub marginea de sus a cadrului ca frunzis, nu ca silueta).
func _backdrop() -> void:
	for sgn: float in [-1.0, 1.0]:
		var f := F_IN + _step(3.0 if sgn < 0.0 else 9.0)
		var k := 0
		while f < F_OUT + _step(20.0):
			var dens := _density(clampf(f, F_IN, F_OUT - 0.001))
			if _rng.randf() < 0.3 + 0.7 * dens:
				var h := _rng.randf_range(16.0, 19.0)
				_place("fig_tree", "smochinZid", f, sgn,
					_rng.randf_range(38.0, 60.0), _rng.randf_range(0.0, TAU),
					_scale_for("fig_tree", h), "trunk")
			f += _step(12.0 + _rng.randf_range(-2.0, 2.0))
			k += 1


## GRANITUL: grupuri de bolovani pe partea care URCA (masurata: solul la 25 m
## lateral mai sus decat pe cealalta parte; la egalitate, dreapta, ca in
## referinta), la 5-14 m de muchie, ca „versantul de granit" sa aiba piatra
## la vedere intre trunchiuri. Cate 3-4 bucati la ~45 m, cu marimi diferite
## (1.5-7 m), cel mare in spate, cei mici spre drum — gradientul de contact
## (patru-defecte-de-diorama, 3). Mai rar si mai in spate decat in v1:
## clasa `granite` iese ALBA sub soarele cald (D_r1_a026.png — bolovanii
## citeau ca marmura/sare la 3 m de drum), deci pana la o tenta mai gri a
## clasei (partajata, decizia lead-ului) piatra sta intre trunchiuri, nu pe
## umar.
func _granite() -> void:
	var f := F_IN + _step(20.0)
	var g := 0
	while f < F_OUT - _step(10.0):
		var dens := _density(f)
		if dens > 0.4:
			var sgn := _uphill_side(f)
			var cnt := 3 + (g % 2)
			for j in cnt:
				var mdl := "kopje_boulder_c" if j == 0 else (
					"kopje_boulder_b" if j % 2 == 1 else "kopje_boulder_a")
				var gap := 9.0 + _rng.randf_range(0.0, 5.0) if j == 0 \
					else _rng.randf_range(5.0, 11.0)
				var h := _rng.randf_range(5.0, 7.5) if j == 0 else (
					_rng.randf_range(2.5, 4.0) if j % 2 == 1
					else _rng.randf_range(1.4, 2.2))
				_place(mdl, "granit", f + _step(_rng.randf_range(-7.0, 7.0)),
					sgn, gap, _rng.randf_range(0.0, TAU), _scale_for(mdl, h),
					"hull")
		f += _step(45.0 + _rng.randf_range(-6.0, 6.0))
		g += 1


## Partea care urca la fractia data: solul la 25 m lateral, stanga fata de
## dreapta. Diferenta sub 1 m = egalitate = dreapta (+1).
func _uphill_side(frac: float) -> float:
	var n := _track.baked.size()
	var i := int(frac * float(n)) % n
	var p := _track.baked[i]
	var s := _track._side_at(i)
	var l := p + s * -25.0
	var r := p + s * 25.0
	var dl := _sol_real(l.x, l.z)
	var dr := _sol_real(r.x, r.z)
	if dl - dr > 1.0:
		return -1.0
	return 1.0


## MARGINILE: acacii-umbrela la intrarea si iesirea din padure, pe 30 m in
## afara intervalului, ca sa lege savana de padure (o acacie apoi doua, apoi
## smochini) in loc de un zid care incepe la o fractie.
func _edges() -> void:
	for j in 3:
		var f_in := F_IN - _step(12.0 + 14.0 * float(j))
		_place("acacia_umbrella_a", "acacieIntrare", f_in,
			-1.0 if j % 2 == 0 else 1.0, _rng.randf_range(3.0, 8.0),
			_rng.randf_range(0.0, TAU), 1.0, "trunk")
		var f_out := F_OUT + _step(8.0 + 14.0 * float(j))
		_place("fever_tree", "febraIesire", f_out,
			1.0 if j % 2 == 0 else -1.0, _rng.randf_range(3.0, 9.0),
			_rng.randf_range(0.0, TAU), _scale_for("fever_tree", 9.5), "trunk")


## CEATA JOASA (MistPatch, scenes/props/mist_patch.gd): petice de billboard-uri
## moi intre trunchiuri, la 9-16 m de ax pe partea DINSPRE care priveste
## camera la iesirea din fiecare S (interiorul virajului urmator), plus unul
## mai departe (22-30 m), mai rar, pentru adancime. Nu pe carosabil: un
## billboard de 8 m peste banda ar acoperi drumul de la 10 m. In captura
## fara masina e singura ceata care se vede — culoarul de ceata al
## Environment-ului lucreaza doar cu jucatorul inauntru.
func _mist() -> void:
	# Voalul sta INTRE TRUNCHIURI, nu peste carosabil. Masurat pe D_r1_hero_b:
	# panze de 11-20 m puse la 8-15 m de ax acopereau drumul pana in botul
	# masinii (banda are 6.5 m semi-latime, deci o panza de 20 m centrata la
	# 10 m ajunge la 0 m). Regula: `lateral - size_max/2 >= half + 3`, adica
	# panza incepe la cel putin 3 m in afara muchiei. De aici lateralele de
	# 18-26 m si 30-46 m cu panze de 12-18 m.
	#
	# Densitatea vine din SUPRAPUNERE la alpha mic (0.05-0.07): la 0.30 fiecare
	# panza citea ca un ghemotoc alb de vata (D_r1_hero.png), la 0.085 pe patru
	# benzi a inecat cadrul. Un singur strat trebuie sa fie aproape invizibil.
	var f := F_DENSE_IN - _step(10.0)
	while f < F_DENSE_OUT + _step(10.0):
		for sgn: float in [-1.0, 1.0]:
			_mist_at(f, sgn, _rng.randf_range(18.0, 26.0), 9,
				Vector2(11.0, 7.0), Vector2(12.0, 18.0), 0.065)
			if _rng.randf() < 0.6:
				_mist_at(f + _step(7.0), sgn, _rng.randf_range(30.0, 46.0), 7,
					Vector2(14.0, 9.0), Vector2(14.0, 22.0), 0.055)
		f += _step(16.0)


func _mist_at(frac: float, side_sign: float, lateral: float, cnt: int,
		foot: Vector2, sz: Vector2, alpha: float) -> void:
	var n := _track.baked.size()
	var i := int(frac * float(n)) % n
	var p := _track.baked[i]
	var s := _track._side_at(i) * side_sign
	var q := p + s * lateral
	var g := _sol_real(q.x, q.z)
	_n += 1
	_out.append('[node name="ceata%d" type="Node3D" parent="%s"]' % [_n, ZONE])
	_out.append("transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %f, %f, %f)"
		% [q.x, g, q.z])
	_out.append('script = ExtResource("mist")')
	_out.append("count = %d" % cnt)
	_out.append("footprint = Vector2(%.1f, %.1f)" % [foot.x, foot.y])
	_out.append("size = Vector2(%.1f, %.1f)" % [sz.x, sz.y])
	_out.append("tint = Color(0.87, 0.89, 0.88, %.3f)" % alpha)
	_out.append("height = Vector2(0.4, 2.2)")
	_out.append("seed = %d" % (1000 + _n))
	_out.append("")


# ------------------------------------------------------------------ asezarea

func _scale_for(model: String, meters: float) -> float:
	var h: float = HEIGHT.get(model, 1.0)
	return meters / h if h > 0.001 else 1.0


func _ceiling(d: float) -> float:
	return 10.0 + 0.093 * d


## Aseaza o piesa la `frac`, pe partea `side_sign`, la `gap` metri de MUCHIA
## drumului pana la TRUNCHI (raza de degajare). Cota vine din teren (raza).
func _place(model: String, base: String, frac: float, side_sign: float,
		gap: float, yaw: float, scl: float, mode: String = "hull") -> void:
	var n := _track.baked.size()
	var i := int(frac * float(n)) % n
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
	# Camera zboara pe axa, la 10 m: coroana n-are voie sub 4.0 m de ax.
	var cr: float = CROWN_R.get(model, 0.6) * scl
	if d - cr < 4.0:
		_warn += 1
		print("; ATENTIE coroana %s la frac %.4f ajunge la %.2f m de ax" % [
			model, frac, d - cr])
	if g - p.y > 6.0 or p.y - g > 12.0:
		print("; nota %s la frac %.4f: teren la %+.2f m fata de sosea (lateral %.1f)" % [
			model, frac, g - p.y, d])
	_raw(model, base, Vector3(q.x, g, q.z), yaw, scl, mode)


func _raw(model: String, base: String, pos: Vector3, yaw: float, scl: float,
		mode: String) -> void:
	_n += 1
	_tri += int(TRI.get(model, 0))
	var c := cos(yaw) * scl
	var s := sin(yaw) * scl
	_out.append('[node name="%s%d" parent="%s" instance=ExtResource("%s")]'
		% [base, _n, ZONE, RES[model]])
	# Randurile bazei (memoria tscn-transform-e-pe-randuri): yaw pur =
	# (bx.x, 0, bz.x, 0, 1, 0, bx.z, 0, bz.z), cu bx = (cos, 0, -sin),
	# bz = (sin, 0, cos), totul inmultit cu scara.
	_out.append("transform = Transform3D(%f, 0, %f, 0, %f, 0, %f, 0, %f, %f, %f, %f)"
		% [c, s, scl, -s, c, pos.x, pos.y, pos.z])
	if mode != "hull":
		_out.append('metadata/coliziune = "%s"' % mode)
	_out.append("")


func _write() -> void:
	print("; asezate %d piese, %d avertismente, ~%d triunghiuri" % [_n, _warn, _tri])
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


## Cota SOLULUI din coliziunea reala a panzei de teren (TerrainBody), nu din
## campul neted si nu din _terrain_mesh_y (memoria terrain-mesh-y-extrapoleaza).
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
