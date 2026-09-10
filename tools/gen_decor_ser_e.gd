extends Node
## Generator de decor MANUAL pentru POI E — BUZA CRATERULUI (Track14 Serengeti,
## frac 0.362-0.482). Nu e sonda: CALCULEAZA transformarile care se lipesc in
## Track14.tscn sub `DecorManual/ZoneE_Buza`, pe teren real (raycast pe
## TerrainBody, nu `_terrain_mesh_y` — memoria `terrain-mesh-y-extrapoleaza`).
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorSerE.tscn -- \
##       --out=<fisier> [--measure]
##
## Ce decide compozitia, si de ce cifrele sunt astea (runda 1):
##
## 1. CREASTA ARE DOUA LUMI. Pe +side (dreapta, +z) e craterul: rapa
##    `custom_ravines (0.358, 0.486, 45, 1)` cu cornisa taiata vertical, podea
##    la y=2, lata 175 m; pe -side (stanga, -z) campia la cota drumului (45 m).
##    Masurat cu `--measure`: umarul din dreapta (teren la cota drumului) tine
##    doar cativa metri dincolo de muchie, apoi cade 43 m. Deci pe dreapta se
##    pun DOAR piese mici (bolovani de 2-4 m, euphorbia) la 0,5-1,5 m de
##    muchie, si numai unde raza gaseste sol la cel mult 1,5 m sub drum;
##    tot ce e inalt (acacii-umbrela, boma) sta pe stanga.
##
## 2. ACACIILE SUNT PLAFONUL FRUSTUMULUI (brief §2.0): la 3 m de muchie
##    centrul unei acacia_c (10 m) e la 7 + 3 + 5,9 = 15,9 m de ax, plafonul
##    e 10 + 0,093 * 15,9 = 11,5 m — coroana intra intreaga. Referinta are
##    coroane care se ating si umbre pe drum, deci pasul intre copaci e
##    10-14 m, cu bolovani si euphorbia intre ei.
##
## 3. BOMA la 0.454 pe stanga (campie), la 3 m de muchie: 16 x 17 m, deci
##    centrul la 7 + 3 + 8,5 = 18,5 m de ax. Cireada Ankole (5 HazardMarker
##    SLIDING/TRAVERSARE cu cow.glb + coarne) imediat dupa boma, la
##    0.460-0.465, defazate cu 0,3 s ca sa treaca IN SIR, nu in front.
##
## 4. FUNDUL CRATERULUI e la 43 m sub banda si 60-120 m lateral: flamingii
##    (MultiMesh, ~160) pe bordura lagunei `custom_lagoon`, padurea Lerai
##    (fever_tree) intre piciorul peretelui si lac, 3 elefanti statici pe mal.
##    Peretele opus (crater_far_wall) la ~190 m, ca silueta in ceata.

const TRACK := "res://scenes/tracks/Track14.tscn"
const ZONE := "DecorManual/ZoneE_Buza"
const FRAC_A := 0.362
const FRAC_B := 0.482

## id-urile ext_resource din Track14.tscn (pre-inregistrate de fundatie).
const RES := {
	"acacia_a": "s_acacia_umbrella_a", "acacia_b": "s_acacia_umbrella_b",
	"acacia_c": "s_acacia_umbrella_c", "euphorbia": "s_euphorbia",
	"fever": "s_fever_tree", "dead": "s_dead_tree",
	"boulder_a": "s_kopje_boulder_a", "boulder_b": "s_kopje_boulder_b",
	"boulder_c": "s_kopje_boulder_c", "boma": "s_maasai_boma",
	"elephant": "s_elephant", "far_wall": "s_crater_far_wall",
	"termite_a": "s_termite_mound_a", "termite_b": "s_termite_mound_b",
	"horns": "s_ankole_horns", "fig": "s_fig_tree", "baobab": "s_baobab",
}
## Raza la baza (jumatate din latura mare a AABB-ului, probe_serengeti_kit).
const BASE_R := {
	"acacia_a": 4.45, "acacia_b": 5.55, "acacia_c": 6.24, "euphorbia": 0.92,
	"fever": 4.36, "dead": 2.36, "boulder_a": 1.07, "boulder_b": 2.03,
	"boulder_c": 2.80, "boma": 8.5, "elephant": 3.21, "far_wall": 104.0,
	"termite_a": 0.6, "termite_b": 1.1,
	"horns": 0.9, "fig": 5.2, "baobab": 5.0,
}
## Modul de coliziune care difera de implicitul din world_prop (doar unde e
## cazul; copacii sunt deja `trunk`, orizontul `none`).
const COLL := {}

var _track: Track
var _sampler: TrackSideSampler
var _terrain_rid: RID = RID()
var _sus_y := 0.0
var _out: Array[String] = []
var _n := 0
var _warn := 0
var _rng := RandomNumberGenerator.new()
var _measure := false
var _skipped_road := 0
var _out_path := ""
var _flam_pos: PackedVector3Array = []
var _flam_yaw: PackedFloat32Array = []
var _wing_pos: PackedVector3Array = []
var _wing_yaw: PackedFloat32Array = []
## Creasta de granit a flancului (POI E, runda 3): MultiMesh, nu WorldProp.
## Runda 2 punea 2.800+ bolovani ca instante de scena individuale -- corect
## vizual (masurat separat), dar fiecare instanta e un desen propriu, si
## garda de desene ("aranjamentul bate numarul") a picat: 3126 desene pe toata
## pista, fata de 2426 pe scena integrata FARA creasta. Doua loturi (boulder_b,
## boulder_c), cate un desen fiecare -- acelasi numar de bolovani, ~2 desene.
var _coama_b_pos: Array[Vector3] = []
var _coama_b_yaw: Array[float] = []
var _coama_b_scale: Array[Vector3] = []
var _coama_c_pos: Array[Vector3] = []
var _coama_c_yaw: Array[float] = []
var _coama_c_scale: Array[Vector3] = []


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out_path = a.trim_prefix("--out=")
		elif a == "--measure":
			_measure = true
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().physics_frame
	_sampler = _track._sampler
	var hi := -INF
	for bp in _track.baked:
		hi = maxf(hi, bp.y)
	_sus_y = hi + 120.0
	_rng.seed = 140501
	_print_sun()
	_print_profile()
	await _print_cow()
	if not _measure:
		_left_bank()
		_right_shoulder()
		_boma_and_herd()
		_crater_floor()
		_far_wall()
		_flamingos()
		_emit_flock()
		_emit_coame()
		if _out_path != "":
			var f := FileAccess.open(_out_path, FileAccess.WRITE)
			for line in _out:
				f.store_line(line)
			f.close()
			print("; scris %s" % _out_path)
		print("; asezate %d piese, %d avertismente, %d sarite langa sosea" % [_n, _warn, _skipped_road])
	get_tree().quit(0)


# ------------------------------------------------------------------ masuratori

## Directia umbrei, din lumina REALA a scenei (nu din euler presupus).
func _print_sun() -> void:
	for c in _track.get_children():
		if c is DirectionalLight3D:
			var l := c as DirectionalLight3D
			var d := -l.global_transform.basis.z # incotro merge lumina
			print("; soare: lumina merge spre (%.3f, %.3f, %.3f); umbra pe XZ spre (%.3f, %.3f); elevatie %.1f grade"
				% [d.x, d.y, d.z, d.x, d.z, rad_to_deg(asin(-d.y))])
			var n := _track.baked.size()
			for f in [0.38, 0.40, 0.42, 0.45]:
				var i := int(f * float(n)) % n
				var s := _track._side_at(i)
				print(";   frac %.2f: dot(side, umbra) = %.2f (pozitiv = umbra cade spre +side/crater)"
					% [f, s.x * d.x + s.z * d.z])
			return
	print("; soare: NICIO DirectionalLight3D gasita")


func _print_profile() -> void:
	var n := _track.baked.size()
	print("; profil teren (y - y_drum) pe lateral, de la ax; + = spre crater")
	var lats := [-40.0, -25.0, -15.0, -10.0, -8.0, -7.0, -8.5, 9.0, 9.5, 10.0, 11.0, 12.0, 14.0, 18.0, 25.0, 40.0, 60.0, 90.0, 120.0]
	var f := FRAC_A
	while f <= FRAC_B + 0.0001:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var row := "; %.3f hw=%.1f y=%.1f |" % [f, _track.width_at_index(i), p.y]
		for l in lats:
			var q := p + s * float(l)
			var g := _sol_real(q.x, q.z, true)
			row += " %+.0f:%+.1f" % [float(l), g - p.y]
		print(row)
		f += 0.01


func _print_cow() -> void:
	var cow := (load("res://assets/models/props/cow.glb") as PackedScene).instantiate() as Node3D
	get_tree().root.add_child(cow)
	await get_tree().process_frame
	var aabb := Track.model_aabb(cow)
	print("; cow.glb: aabb pos(%.2f,%.2f,%.2f) size(%.2f,%.2f,%.2f)" % [
		aabb.position.x, aabb.position.y, aabb.position.z,
		aabb.size.x, aabb.size.y, aabb.size.z])
	for sk in cow.find_children("*", "Skeleton3D", true, false):
		var s := sk as Skeleton3D
		print("; cow skeleton la %s, scala globala %s" % [cow.get_path_to(s), s.global_transform.basis.get_scale()])
		var hb := s.find_bone("Head")
		if hb >= 0:
			var gp := s.global_transform * s.get_bone_global_pose(hb)
			print("; cow Head: pozitie globala (%.3f, %.3f, %.3f), scala os %s" % [
				gp.origin.x, gp.origin.y, gp.origin.z, gp.basis.get_scale()])
			print("; cow Head: axe x=%s y=%s z=%s" % [gp.basis.x, gp.basis.y, gp.basis.z])
	var horns := (load("res://assets/models/serengeti/props/ankole_horns.glb") as PackedScene).instantiate() as Node3D
	get_tree().root.add_child(horns)
	await get_tree().process_frame
	var ha := Track.model_aabb(horns)
	print("; ankole_horns: aabb pos(%.2f,%.2f,%.2f) size(%.2f,%.2f,%.2f)" % [
		ha.position.x, ha.position.y, ha.position.z, ha.size.x, ha.size.y, ha.size.z])
	horns.queue_free()
	cow.queue_free()


# ------------------------------------------------------------------ compozitia

## STANGA (campia aurie): acacii-umbrela in PALCURI, nu la pas fix. Referinta
## are copaci care se ating si se ocluzioneaza, bolovani mari de granit lipiti
## de banda, tufe intre ei — deci grupam 2-4 piese in jurul unei ancore, cu
## jitter de peste jumatate de pas, si lasam coroanele sa se suprapuna.
func _left_bank() -> void:
	var anchors: Array[float] = []
	var f := FRAC_A + 0.001
	while f < FRAC_B:
		anchors.append(f + _rng.randf_range(-0.0022, 0.0022))
		f += 0.0132
	var k := 0
	for af in anchors:
		# Copacul mare al palcului, la 1,5-5 m de muchie (referinta: coroana
		# atarna PESTE banda).
		var big: String = "acacia_c" if k % 2 == 0 else "acacia_b"
		_place(big, "Acacia", af, -1.0, _rng.randf_range(4.5, 9.0),
			_rng.randf_range(0.0, TAU), _rng.randf_range(0.9, 1.15))
		# Insotitorii palcului: 1-3 piese in jurul lui, la 3-8 m mai departe,
		# defazate longitudinal cu +-6 m; se suprapun cu el si intre ele.
		var mates: int = _rng.randi_range(1, 2)
		for m in mates:
			var pick: String = ["acacia_a", "acacia_a", "acacia_b", "euphorbia"][_rng.randi_range(0, 3)]
			_place(pick, "AcaciaPalc", af + _rng.randf_range(-0.0028, 0.0028), -1.0,
				_rng.randf_range(7.0, 16.0), _rng.randf_range(0.0, TAU),
				_rng.randf_range(0.8, 1.1))
		# Bolovanii de granit: in referinta sunt LANGA banda si mari in cadru.
		# Piesele JOASE umplu golul lasat de pasul mai mare intre copaci: ele
		# dau densitate la 0,4-6 m de banda fara sa arunce umbre lungi (un
		# bolovan de 2 m arunca 2,9 m la 35 grade, o coroana de 10 m arunca
		# 14). Referinta: bolovani lipiti de banda pe TOATA lungimea.
		var nb: int = _rng.randi_range(3, 5)
		for j in nb:
			var bn: String = ["boulder_a", "boulder_b", "boulder_c", "boulder_c"][_rng.randi_range(0, 3)]
			_place(bn, "Bolovan", af + _rng.randf_range(-0.0055, 0.0055), -1.0,
				_rng.randf_range(0.4, 6.0), _rng.randf_range(0.0, TAU),
				_rng.randf_range(0.85, 1.5))
		if k % 2 == 0:
			_place("euphorbia", "Euphorbia", af + _rng.randf_range(-0.002, 0.002), -1.0,
				_rng.randf_range(0.8, 3.0), _rng.randf_range(0.0, TAU),
				_rng.randf_range(0.8, 1.2))
		k += 1
	# Al doilea plan, la 18-40 m in campie: siluete rare care dau adancime
	# (scara de adancime — memoria `scara-de-adancime-are-gol`).
	var g := FRAC_A
	var q := 0
	while g < FRAC_B:
		var far: String = ["acacia_b", "acacia_a", "dead", "baobab"][_rng.randi_range(0, 3)]
		_place(far, "CampieFund", g + _rng.randf_range(-0.003, 0.003), -1.0,
			_rng.randf_range(16.0, 46.0), _rng.randf_range(0.0, TAU),
			_rng.randf_range(0.9, 1.2), "", "", 0.0, 12.0)
		g += 0.0125
		q += 1
	_place("dead", "CopacUscat", 0.392, -1.0, 6.0, 0.8, 1.15)
	_place("dead", "CopacUscat", 0.437, -1.0, 11.0, 2.3, 1.0)
	_place("termite_b", "Termitiera", 0.372, -1.0, 4.5, 0.3, 1.0)
	_place("termite_a", "Termitiera", 0.415, -1.0, 2.2, 1.7, 1.0)
	_place("termite_b", "Termitiera", 0.468, -1.0, 7.5, 2.9, 1.1)
	_place("termite_a", "Termitiera", 0.386, -1.0, 3.1, 2.2, 1.1)
	_place("termite_b", "Termitiera", 0.402, -1.0, 5.8, 1.1, 0.95)
	_place("termite_a", "Termitiera", 0.444, -1.0, 2.6, 0.5, 1.05)
	_place("termite_b", "Termitiera", 0.477, -1.0, 4.2, 2.0, 1.0)


## DREAPTA (buza craterului si flancul de sub ea). Referinta NU are un tiv de
## bolovani pe muchie si apoi gol: are coasta populata pe TOATA caderea —
## coame de granit gri iesind din iarba, tufe si copaci verzi tot mai desi spre
## fund. Deci punem trei benzi: muchia (piese joase, ca sa nu ascunda lacul),
## flancul de sus (bolovani mari care ies din panta) si flancul de jos (verde).
func _right_shoulder() -> void:
	# a) muchia propriu-zisa: nimic peste ~2,5 m, altfel taluzul ascunde lacul.
	var f := FRAC_A + 0.002
	var k := 0
	while f < FRAC_B:
		var bn: String = "boulder_b" if k % 3 == 0 else "boulder_a"
		_place(bn, "BolovanBuza", f + _rng.randf_range(-0.002, 0.002), 1.0,
			_rng.randf_range(-0.6, 0.6), _rng.randf_range(0.0, TAU),
			_rng.randf_range(0.9, 1.6), "hull", "", 1.2, 7.0)
		if k % 2 == 1:
			_place("euphorbia", "EuphorbiaBuza", f + _rng.randf_range(-0.002, 0.002), 1.0,
				_rng.randf_range(-0.4, 0.8), _rng.randf_range(0.0, TAU),
				_rng.randf_range(0.7, 1.1), "trunk", "", 0.8, 7.0)
		f += 0.0055
		k += 1
	# b) flancul: raze aruncate LATERAL peste buza; unde solul e la 3-30 m sub
	#    drum, e coasta. Bolovanii de granit ies din panta (coamele gri din
	#    referinta), copacii verzi se indesesc spre fund.
	_flank()


## Coasta de sub buza, esantionata pe teren real. Piesele se aseaza in
## coordonate de lume (nu prin `_place`, care lucreaza pe distanta laterala
## constanta si ar rata caderea).
##
## RUNDA 2 -- diagnosticul vechi (verde prea des) era corect ca simptom dar
## gresit ca leac: dupa ce runda 1 a rarit verdele la 22,7 %, roca a ramas la
## 1,9 % fata de tinta 20+ %. Masurat pe captura: bolovanii `kopje_boulder_*`
## sunt ROTUNZI (6 m la scara 1) si stateau IZOLATI, la 4-9 m unul de altul,
## pe un flanc de 90 m -- la 60-150 m de camera, cateva puncte gri pe o
## panta verde nu ajung niciodata la 20 % din caseta. Referinta nu are
## bolovani presarati, are FATA DE STANCA: benzi aproape verticale de gri
## care se ating si se suprapun pe toata caderea.
##
## Leacul: roca devine UMPLUTURA de fond, nu accent. Compunem "coame" --
## grupuri de 3-6 bolovani suprapusi, intinsi pe verticala si turtiti pe o
## axa orizontala (scale3 neuniform, cere `_raw` cu parametru nou), asezate
## dese (pas 3-5 m) pe toata latimea coastei. Verdele ramane, dar doar ca
## pete RARE agatate intre coame (candelabre/copaci mici), nu ca panza.
func _flank() -> void:
	var n := _track.baked.size()
	var placed := 0
	var ridges := 0
	var f := FRAC_A
	while f < FRAC_B:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var half := _track.width_at_index(i)
		var lat := half + 3.0
		while lat < 95.0:
			var step := _rng.randf_range(3.0, 5.0)
			var jl := lat + _rng.randf_range(-1.2, 1.2)
			var jf := f + _rng.randf_range(-0.003, 0.003)
			var ii := int(jf * float(n)) % n
			var pp := _track.baked[ii]
			var ss := _track._side_at(ii)
			var qq := pp + ss * jl
			var g := _sol_real(qq.x, qq.z, true)
			var drop := p.y - g
			if drop < 2.0 or drop > 44.0:
				lat += step
				continue
			# Sub cota apei nu punem nimic (lacul si crusta sunt ale POI G).
			if g < _sea_y() + 0.6:
				lat += step
				continue
			var t: float = clampf(drop / 40.0, 0.0, 1.0) # 0 sus pe buza, 1 jos
			var eye_d := sqrt(jl * jl + pow(p.y + 10.0 - g, 2.0))
			var in_view_window: bool = eye_d < 60.0 or _in_lake_window(Vector3(qq.x, g, qq.z))
			# COASTA E O FATA DE STANCA, NU O PANTA DE IARBA. O "coama" e un
			# grup de bolovani suprapusi la aceeasi ancora lateral+longitudinal,
			# intinsi pe verticala (scale3.y mare) si turtiti pe orizontala
			# (scale3.x/z mici) ca sa citeasca drept CRESTE care urmeaza
			# caderea, nu bulgari rotunzi. Referinta: benzile se ating.
			var mates: int = _rng.randi_range(3, 6)
			for m in mates:
				var use_c: bool = _rng.randf() < 0.66 # 2/3 boulder_c, 1/3 boulder_b
				var dl := _rng.randf_range(-2.4, 2.4)
				var df := _rng.randf_range(-0.0015, 0.0015)
				var fi := int((jf + df) * float(n)) % n
				var fp := _track.baked[fi]
				var fs := _track._side_at(fi)
				var rq := fp + fs * (jl + dl)
				var rg := _sol_real(rq.x, rq.z, true)
				if rg < _sea_y() + 0.3:
					continue
				var stretch_v := _rng.randf_range(1.7, 2.9) # verticala: creasta inalta
				var flat_h := _rng.randf_range(0.55, 0.85)  # orizontala: turtita
				var sc3 := Vector3(flat_h, stretch_v, flat_h) * _rng.randf_range(0.9, 1.5)
				var rp := Vector3(rq.x, rg - 0.6, rq.z)
				var ry := _rng.randf_range(0.0, TAU)
				var eff_r: float = BASE_R.get("boulder_c" if use_c else "boulder_b", 0.6) \
					* maxf(sc3.x, maxf(sc3.y, sc3.z))
				if _too_close_to_road(rp, eff_r):
					continue
				if use_c:
					_coama_c_pos.append(rp)
					_coama_c_yaw.append(ry)
					_coama_c_scale.append(sc3)
				else:
					_coama_b_pos.append(rp)
					_coama_b_yaw.append(ry)
					_coama_b_scale.append(sc3)
				placed += 1
			ridges += 1
			# Verde: doar pete RARE agatate intre coamele de piatra, niciodata
			# in fereastra ochi/lac. 8 % pe buza -> 16 % pe fund, mult sub
			# pragul 6-14 % masurat pe toata caseta (buza + flanc + campie).
			var green_p: float = 0.08 + 0.08 * t
			if not in_view_window and _rng.randf() < green_p:
				var model := "fever" if (t > 0.55 and _rng.randf() < 0.6) else "acacia_a"
				var scl: float = _rng.randf_range(0.30, 0.45) + 0.30 * t
				_raw(model, "FlancVerde", Vector3(qq.x, g, qq.z), _rng.randf_range(0.0, TAU),
					scl, "trunk")
				placed += 1
			lat += step
		f += 0.0035
	print("; flanc: %d piese pe coasta (%d coame)" % [placed, ridges])


## BOMA la 0.454 pe campie + cireada Ankole care traverseaza dupa ea.
func _boma_and_herd() -> void:
	_place("boma", "BomaMaasai", 0.454, -1.0, 3.0, 0.0, 1.0, "hull", "toward")
	# Cireada: 5 markere SLIDING/TRAVERSARE la 2,6 m una de alta pe lungul
	# drumului (0.0012 din tur ≈ 2,5 m), defazate cu 0,3 s. Ciclul unei
	# treceri (leg) = 5 + 1,2 + period/2; cu amp ≈ 9,3 m si 12 m/s period ≈
	# 3,1 s, deci leg ≈ 7,75 s si ciclul dus-intors ≈ 15,5 s; 0,3 s = 0,019.
	var n := _track.baked.size()
	# Cinci vaci care traverseaza IN SIR, nu in front. `SlidingHazard` isi ia
	# defazajul din fractie (`fposmod(frac * 3.7, 1.0)` in track.gd), deci
	# markerele lipite unul de altul ar porni la unison si ar face un ZID
	# mobil pe o buza fara parapet: ProbeRace a dat 2 repuneri exact aici
	# (frac 0.454-0.457) cand erau la 2 m distanta. Pasul de 0.0068 din tur
	# (~14 m) le da defazaje de 0.025 intre ele si le intinde pe 57 m, deci
	# masina prinde mereu o fereastra intre doua vaci.
	for c in 5:
		var fr := 0.4535 + 0.0068 * float(c)
		var i := int(fr * float(n)) % n
		var p := _track.baked[i]
		_n += 1
		_out.append('[node name="E_Ankole%d" type="Marker3D" parent="%s"]' % [c + 1, ZONE])
		_out.append("transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.3f, %.3f, %.3f)" % [p.x, p.y, p.z])
		_out.append('script = ExtResource("hzm")')
		_out.append('model = ExtResource("s_cow")')
		_out.append("model_scale = %.3f" % COW_SCALE)
		_out.append("face_travel = true")
		_out.append("motion = 1")
		_out.append("")
		print("; Ankole%d la frac %.4f (%.1f, %.1f, %.1f), defazaj %.3f"
			% [c + 1, fr, p.x, p.y, p.z, fposmod(fr * 3.7, 1.0)])
	# Coarnele Ankole nu se pot parenta pe un hazard care isi construieste
	# singur modelul (HazardMarker n-are `attach_*`), deci raman ca trofeu pe
	# gardul bomei — exact unde le pune si referinta (stalpul cu shuka rosie).
	_place("horns", "CoarneAnkole", 0.4512, -1.0, 1.2, 0.6, 1.4, "none")


## Scara vacii (cow.glb e deja la marime reala, masurat cu `--measure`).
const COW_SCALE := 1.0


## FUNDUL CRATERULUI: padurea Lerai (fever_tree) pe podeaua dintre piciorul
## coastei si crusta lacului, plus elefantii ca puncte gri pe mal. Coordonate
## de LUME: lacul are centrul (0, -68) si raza ~52 m, drumul e la z ~ -165.
func _crater_floor() -> void:
	var sea := _sea_y()
	var kept := 0
	var tries := 0
	# Padurea: inel intre raza 56 si raza 105 fata de centrul lacului, DAR
	# numai pe jumatatea dinspre drum (z < -55), ca sa nu punem copaci in
	# jumatatea pe care camera n-o vede niciodata din bucata asta.
	while kept < 70 and tries < 4000:
		tries += 1
		var ang := _rng.randf_range(0.0, TAU)
		var rad := _rng.randf_range(54.0, 108.0)
		var px := cos(ang) * rad
		var pz := -68.0 + sin(ang) * rad
		if pz < -140.0 or pz > -20.0:
			continue
		var g := _sol_real(px, pz, true)
		if g < sea + 0.5 or g > sea + 9.0:
			continue # in apa, pe crusta uda, sau deja pe coasta
		# Densitatea creste spre lac (referinta: verde des la baza coastei).
		var t: float = clampf((108.0 - rad) / 54.0, 0.0, 1.0)
		# Rarita in runda 2: padurea Lerai e in referinta un pluton de
		# copaci inchisi la culoare pe fundul craterului, nu o panza verde.
		# 150 de copaci + 324 de piese de flanc dadeau 23 % verde in sfertul
		# in care referinta are 2,8 %.
		if _rng.randf() > 0.18 + 0.30 * t:
			continue
		if _in_lake_window(Vector3(px, g, pz)):
			continue # padurea nu are voie sa acopere lacul din cadrul erou
		var model: String = "fever" if _rng.randf() < 0.7 else "acacia_a"
		_raw(model, "Lerai", Vector3(px, g, pz), _rng.randf_range(0.0, TAU),
			_rng.randf_range(0.8, 1.2), "trunk")
		kept += 1
	print("; padurea Lerai: %d copaci din %d incercari" % [kept, tries])
	# Elefantii pe crusta, langa apa, in doua grupuri (referinta: sirag, nu
	# obiecte izolate).
	# Elefantii stau pe ARCUL DINSPRE DRUM al crustei (z sub centrul lacului),
	# fiindca doar el intra in cadrul de la 0.40; grupurile de la z = -104..
	# -124 din runda 1 erau pe malul opus, adica in afara frustumului. La
	# 90-120 m un elefant la scara 1 are ~9 px inaltime: il ducem la 1.6-1.9,
	# ca in referinta, unde elefantii sunt siluete clare pe crusta alba.
	var groups := [[-30.0, -104.0], [8.0, -110.0], [40.0, -96.0], [-58.0, -88.0]]
	for gr in groups:
		var m: int = _rng.randi_range(2, 4)
		for e in m:
			var px := float(gr[0]) + _rng.randf_range(-11.0, 11.0)
			var pz := float(gr[1]) + _rng.randf_range(-8.0, 8.0)
			var g := _sol_real(px, pz, true)
			if g < sea - 0.3 or g > sea + 4.0:
				continue
			_raw("elephant", "Elefant", Vector3(px, maxf(g, sea), pz),
				_rng.randf_range(0.0, TAU), _rng.randf_range(1.6, 1.9), "none")


## Peretele opus al craterului, ca silueta in ceata la ~190 m de banda.
func _far_wall() -> void:
	var wx := 0.0
	var wz := 20.0
	var g := _sol_real(wx, wz)
	_raw("far_wall", "PereteOpus", Vector3(wx, g, wz), FAR_WALL_YAW, 1.0, "none")
	print("; perete opus la (%.1f, %.1f, %.1f)" % [wx, g, wz])

const FAR_WALL_YAW := 0.0


## Flamingii: bordura roz a lacului Magadi. Doua lectii aplicate:
##  - NU un tiv pe contur (lectia bucatii G): banda are latime, deci pasarile
##    stau si IN apa mica, in trei inele concentrice, cu densitatea cea mai
##    mare pe muchia apei;
##  - pe JUMATATEA DINSPRE DRUM. Prima incercare le-a asezat uniform pe tot
##    conturul, iar jumatatea dinspre camera (z < -68) primise doar cateva:
##    in captura de la 0.4 nu se vedea niciun flamingo, desi sonda numarase
##    170 (memoria `efecte-invizibile-nu-se-numara`).
func _flamingos() -> void:
	var poly := _track._lagoon_poly()
	if poly.is_empty():
		print("; ATENTIE: fara laguna")
		return
	var cx := 0.0
	var cz := 0.0
	for p in poly:
		cx += p.x
		cz += p.y
	cx /= float(poly.size())
	cz /= float(poly.size())
	var sea := _sea_y()
	# ARCUL VIZIBIL. Lacul e la 83-135 m de ochi, iar camera de joc are 68 gr
	# vertical = ~97 gr orizontal, deci +-48 gr. Masurat (tools/_pE.gd): la
	# frac 0.40 malul dinspre drum e la azimut +31 gr (in cadru), centrul la
	# +47 (pe muchie) si malul opus la +75 (AFARA). La 0.42-0.47 tot lacul e
	# la +83..+137 gr, adica in spatele umarului drept. Deci exista UN singur
	# cadru care poate arata gimmickul, cel de la 0.40, si in el se vede doar
	# arcul dinspre sosea. Tot ce se aseaza pe restul conturului e munca
	# nevazuta (memoria `decor-nevazut-se-numara-pe-obiect`): aici il numim
	# explicit si il taiem la un tiv rar.
	# Arcul dinspre drum = z < cz (drumul e la z ~ -166, lacul la z ~ -68).
	_crust(poly, cx, cz, sea)
	var tries := 0
	var kept := 0
	var kept_w := 0
	# Tinta masurata pe referinta: rozul e 8,35 % din sfertul din dreapta-jos,
	# la noi era 0,73 %. Inelul nu se ingroasa cu ce nu se vede, deci crestem
	# NUMARUL pe arcul vizibil si SCARA (la 85 m un flamingo de 1,2 m are ~7
	# px; masa il face banda, nu individul).
	while kept + kept_w < 900 and tries < 40000:
		tries += 1
		var e := _rng.randi_range(0, poly.size() - 1)
		var a := poly[e]
		var b := poly[(e + 1) % poly.size()]
		var q := a.lerp(b, _rng.randf())
		var out_dir := (q - Vector2(cx, cz)).normalized()
		# Banda LATA: 9 m in apa mica, 9 m pe crusta. In referinta inelul roz
		# are grosime, nu e un contur.
		q += out_dir * _rng.randf_range(-9.0, 9.0)
		# Arcul dinspre drum ia 9 din 10 pasari; restul conturului ramane
		# populat rar, ca lacul sa nu para chel daca alt POI il priveste.
		if q.y > cz and _rng.randf() > 0.10:
			continue
		var g := _sol_real(q.x, q.y, true)
		if g < sea - 1.2 or g > sea + 1.6:
			continue
		var y := maxf(g, sea)
		var yaw := _rng.randf_range(0.0, TAU)
		if _rng.randf() < 0.14:
			_wing_pos.append(Vector3(q.x, y, q.y))
			_wing_yaw.append(yaw)
			kept_w += 1
		else:
			_flam_pos.append(Vector3(q.x, y, q.y))
			_flam_yaw.append(yaw)
			kept += 1
	var near := 0
	for fp in _flam_pos:
		if fp.z < cz:
			near += 1
	print("; flamingi: %d in picioare (%d pe arcul dinspre drum) + %d cu aripi, din %d incercari"
		% [kept, near, kept_w, tries])


## CRUSTA DE SARE: placi plate albe (slot 22 FOAM_WHITE) pe bordura lacului.
##
## De ce e livrabilul cel mai mare al rundei: masurat pe sfertul din
## dreapta-jos al cadrului, referinta are 20,8 % crusta alba, 13,9 % apa si
## 8,4 % roz; noi aveam 0,2 % crusta, 24,7 % apa si 0,7 % roz — adica un
## bazin turcoaz care atinge direct verdele. Crusta e ce da inelului roz un
## fundal pe care sa se citeasca, si e cea mai luminoasa suprafata din cadru.
func _crust(poly: PackedVector2Array, cx: float, cz: float, sea: float) -> void:
	var pos: PackedVector3Array = []
	var yaw: PackedFloat32Array = []
	var tries := 0
	while pos.size() < 420 and tries < 20000:
		tries += 1
		var e := _rng.randi_range(0, poly.size() - 1)
		var a := poly[e]
		var b := poly[(e + 1) % poly.size()]
		var q := a.lerp(b, _rng.randf())
		var out_dir := (q - Vector2(cx, cz)).normalized()
		# De la 4 m in apa (crusta se vede prin apa mica) pana la 26 m pe mal.
		q += out_dir * _rng.randf_range(-4.0, 26.0)
		if q.y > cz and _rng.randf() > 0.12:
			continue
		var g := _sol_real(q.x, q.y, true)
		# Crusta urca pana la 3 m peste apa; mai sus incepe coasta verde.
		if g < sea - 1.5 or g > sea + 3.0:
			continue
		# INALTIMEA E CE A OMORAT PRIMA VERSIUNE. O placa PLATA de 14 m
		# diametru asezata la +0,12 m pe un mal in panta intra cu totul in
		# teren: A/B-ul crusta on/off a dat 0,04 % din cadru, adica invizibila,
		# desi 193 din 420 de placi se proiectau in cadru. Ridicarea se ia din
		# panta REALA sub placa: cat coboara terenul pe raza ei, atat trebuie
		# sa pluteasca marginea ca sa nu se ingroape.
		var rr := 7.0 * 1.1
		var lo := g
		for da in [0.0, TAU / 3.0, TAU * 2.0 / 3.0]:
			lo = minf(lo, _sol_real(q.x + cos(da) * rr, q.y + sin(da) * rr, true))
		var lift: float = clampf(g - lo, 0.0, 2.5) + 0.15
		pos.append(Vector3(q.x, maxf(g, sea - 0.35) + lift, q.y))
		yaw.append(_rng.randf_range(0.0, TAU))
	if pos.is_empty():
		print("; ATENTIE: crusta goala")
		return
	_out.append('[node name="E_CrustaSare" type="MultiMeshInstance3D" parent="%s"]' % ZONE)
	_out.append('script = ExtResource("flock")')
	_out.append("disc_slot = 22")
	_out.append("disc_radius = 7.0")
	_out.append("scale_min = 0.75")
	_out.append("scale_max = 1.5")
	_out.append("positions = %s" % var_to_str(pos).replace("
", ""))
	_out.append("yaws = %s" % var_to_str(yaw).replace("
", ""))
	_out.append("")
	_n += 1
	print("; crusta de sare: %d placi din %d incercari" % [pos.size(), tries])


func _sea_y() -> float:
	var sea := _track.get_node_or_null("Sea") as Node3D
	if sea != null:
		return sea.global_position.y
	return _sampler.mean_road_y() + _track.sea_level_offset


func _emit_flock() -> void:
	if _flam_pos.is_empty():
		return
	for spec in [["E_Flamingi", "s_flamingo", _flam_pos, _flam_yaw],
			["E_FlamingiAripi", "s_flamingo_wings", _wing_pos, _wing_yaw]]:
		var pos: PackedVector3Array = spec[2]
		if pos.is_empty():
			continue
		_out.append('[node name="%s" type="MultiMeshInstance3D" parent="%s"]' % [spec[0], ZONE])
		_out.append('script = ExtResource("flock")')
		_out.append('model = ExtResource("%s")' % spec[1])
		_out.append("scale_min = 1.5")
		_out.append("scale_max = 2.1")
		_out.append("positions = %s" % var_to_str(pos).replace("\n", ""))
		_out.append("yaws = %s" % var_to_str(spec[3]).replace("\n", ""))
		_out.append("")
		_n += 1


## Creasta de granit ca MultiMesh -- doua loturi (boulder_b, boulder_c), un
## desen fiecare, scalare NEUNIFORMA per instanta prin `scale3_list`
## (FlockProp, runda 3). ~2.800 de bolovani coborau garda de desene de la
## 2.426 (scena integrata fara creasta) la 3.126; ca MultiMesh acelasi numar
## de bolovani adauga doar 2 desene.
func _emit_coame() -> void:
	for spec in [["E_CoameB", "s_kopje_boulder_b", _coama_b_pos, _coama_b_yaw, _coama_b_scale],
			["E_CoameC", "s_kopje_boulder_c", _coama_c_pos, _coama_c_yaw, _coama_c_scale]]:
		var pos: Array[Vector3] = spec[2]
		if pos.is_empty():
			continue
		var pv := PackedVector3Array(pos)
		var yv := PackedFloat32Array(spec[3])
		_out.append('[node name="%s" type="MultiMeshInstance3D" parent="%s"]' % [spec[0], ZONE])
		_out.append('script = ExtResource("flock")')
		_out.append('model = ExtResource("%s")' % spec[1])
		_out.append('tri_class = "granite"')
		_out.append("positions = %s" % var_to_str(pv).replace("\n", ""))
		_out.append("yaws = %s" % var_to_str(yv).replace("\n", ""))
		_out.append("scale3_list = %s" % var_to_str(spec[4]).replace("\n", ""))
		_out.append("")
		_n += 1
	print("; creasta: %d boulder_b + %d boulder_c ca MultiMesh (2 desene)"
		% [_coama_b_pos.size(), _coama_c_pos.size()])


# ------------------------------------------------------------------ asezarea

## Aseaza o piesa la `frac`, pe partea `side_sign`, la `gap` metri de MUCHIA
## drumului. Cota din teren (raycast). `max_drop`: daca solul e cu mai mult
## de atat sub drum, piesa NU se pune (a cazut in crater).
func _place(model: String, base: String, frac: float, side_sign: float,
		gap: float, yaw: float, scl: float, mode: String = "",
		face: String = "", lift: float = 0.0, max_drop: float = 6.0) -> void:
	var n := _track.baked.size()
	var i := int(frac * float(n)) % n
	var p := _track.baked[i]
	var s := _track._side_at(i) * side_sign
	var half := _track.width_at_index(i)
	var r: float = BASE_R.get(model, 0.6) * scl
	var d := half + gap + r
	var q := p + s * d
	var g := _sol_real(q.x, q.z)
	if p.y - g > max_drop:
		print("; sarit %s la frac %.4f: solul cu %.1f m sub drum (perete)" % [model, frac, p.y - g])
		return
	if d - r < half + 0.6:
		# Piesa ar intra in banda: o impingem exact pe limita, nu o lasam si nu
		# o aruncam. ProbeLaneClear vede corpurile, nu intentiile.
		d = half + 0.6 + r
		q = p + s * d
		g = _sol_real(q.x, q.z)
		if p.y - g > max_drop:
			print("; sarit %s la frac %.4f dupa impingere: sol cu %.1f m sub drum" % [model, frac, p.y - g])
			return
	var a := yaw
	if face == "toward":
		a = atan2(-(-s.x), -(-s.z)) # -Z al piesei spre drum (spre -s)
	elif face == "along":
		var dir := (_track.baked[(i + 1) % n] - p).normalized()
		a = atan2(-dir.x, -dir.z)
	_raw(model, base, Vector3(q.x, g + lift, q.z), a, scl, mode)


func _raw(model: String, base: String, pos: Vector3, yaw: float, scl: float,
		mode: String, scale3: Vector3 = Vector3.ZERO) -> void:
	# scale3 != ZERO: scalare NEUNIFORMA (coame de granit intinse pe verticala
	# si turtite pe o axa orizontala) — raza de coliziune/road-clear foloseste
	# tot componenta cea mai mare, ca sa nu subestimeze gabaritul.
	var eff_scl := scl if scale3 == Vector3.ZERO else maxf(scale3.x, maxf(scale3.y, scale3.z))
	if _too_close_to_road(pos, BASE_R.get(model, 0.6) * eff_scl):
		_skipped_road += 1
		return
	_n += 1
	var sc := Vector3.ONE * scl if scale3 == Vector3.ZERO else scale3
	var t := Transform3D(Basis(Vector3.UP, yaw) * Basis.from_scale(sc), pos)
	_out.append('[node name="E_%s%d" parent="%s" instance=ExtResource("%s")]'
		% [base, _n, ZONE, RES[model]])
	_out.append("transform = %s" % var_to_str(t))
	if mode != "" and mode != "hull":
		_out.append('metadata/coliziune = "%s"' % mode)
	_out.append("")


## FEREASTRA LACULUI, in COORDONATE DE ECRAN. Trei runde au incercat sa taie
## verdele din coltul dreapta-jos cu praguri pe distanta (34 m, apoi 52, apoi
## 60) si de fiecare data a ramas o panza: piesele care umplu coltul sunt la
## 59-118 m, adica DINCOLO de orice prag rezonabil, dar jos in cadru fiindca
## stau pe coasta, sub linia de vedere. Distanta nu spune unde cade un obiect
## pe ecran; proiectia spune.
##
## Aici proiectam pozitia prin exact camera de joc de la `frac` (10 m sus,
## 12,5 m in spate, FOV 68, 16:9) si spunem daca pica in dreptunghiul pe care
## referinta il tine pentru lac: x > 0,72 si y > 0,34 din cadru.
func _in_lake_window(pos: Vector3) -> bool:
	var n := _track.baked.size()
	var i := int(HERO_FRAC * float(n)) % n
	var p := _track.baked[i]
	var fwd := (_track.baked[(i + 8) % n] - p).normalized()
	var eye := p - fwd * 12.5 + Vector3(0, 10, 0)
	var right := Vector3(-fwd.z, 0.0, fwd.x)
	var target := p + fwd * 14.0 + Vector3(0, 1.2, 0)
	var look := (target - eye).normalized()
	var cam_r := look.cross(Vector3.UP).normalized()
	var cam_u := cam_r.cross(look).normalized()
	var d := pos - eye
	var z := d.dot(look)
	if z <= 0.5:
		return false
	var ty := tan(deg_to_rad(68.0) * 0.5)
	var tx := ty * (16.0 / 9.0)
	var sx := (d.dot(cam_r) / z) / tx # -1..1, + = dreapta
	var sy := (d.dot(cam_u) / z) / ty # -1..1, + = sus
	var fx := 0.5 + 0.5 * sx
	var fy := 0.5 - 0.5 * sy
	return fx > 0.72 and fy > 0.34


const HERO_FRAC := 0.40


## Adevarat daca piesa ar sta peste ORICE felie de sosea (nu doar cea din care
## a plecat). Pe buza craterului traseul se intoarce la 26 m de el insusi:
## piese aruncate 90 m in coasta cadeau pe carosabilul de la frac 0.55-0.58 si
## blocau 24 de probe ProbeLaneClear.
func _too_close_to_road(pos: Vector3, r: float) -> bool:
	var n := _track.baked.size()
	for i in n:
		var p := _track.baked[i]
		if absf(p.y - pos.y) > 12.0:
			continue
		var dx := p.x - pos.x
		var dz := p.z - pos.z
		if dx * dx + dz * dz < pow(_track.width_at_index(i) + 1.2 + r, 2.0):
			return true
	return false


## Cota SOLULUI din coliziunea reala a panzei de teren (portat din
## gen_decor_capp_a.gd). `quiet` = fara avertisment cand nu e sol (profil).
func _sol_real(x: float, z: float, quiet: bool = false) -> float:
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
	if not quiet:
		print("; ATENTIE fara sol la (%.1f, %.1f): se cade pe camp" % [x, z])
	return _sampler.ground_y(x, z)
