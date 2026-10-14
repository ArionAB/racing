extends Node
## Generator de decor MANUAL pentru POI B — BARAJUL (Vidraru, cu Prometeu si hauul)
## (Track21 Transfagarasan, frac 0.064-0.1535, semi 7,0 / 6,0 pe coronament).
## Nu e sonda: MASOARA terenul real (raycast pe TerrainBody) si CALCULEAZA
## nodurile care se lipesc in `Track21.tscn` sub `DecorManual/ZonaB`.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorTfB.tscn -- --survey
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorTfB.tscn -- --emit    (tipareste)
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorTfB.tscn -- --write   (rescrie ZonaB)
##
## ----------------------------------------------------------------------------
## LISTA DE ELEMENTE (runda 1) — din decupajul `B.png`, cu cifrele fisei (`### B`)
## ----------------------------------------------------------------------------
## Ce arata decupajul (MATERIA, nu layoutul): zidul de beton cu parapet alb-rosu
## pe coronament, lacul verde-inchis in spate, turnul de priza si centrala (toate
## MONTATE, nu se ating); Prometeu bronz pe un PINTEN DE SIST gri-verzui in lame
## inclinate, cu iarba pe creasta si zapada veche in crapaturi; in jurul hauului
## DOUA PERETI de versant: padure de molid verde-negru in 2-3 randuri si 3 marimi
## (coloane inguste, in palcuri) cu fag rotund, verde cald, doar la poale; stanci
## de sist care ies prin padure; la picior stanci mari + zapada murdara.
##
## Realitatea pistei (masurata cu --survey): coronamentul 0.078-0.123 are PE
## DREAPTA hauul (la 5 m de margine terenul e la -16..-39 m), iar peretele opus e
## la 40-90 m (+8..+21 m peste drum) — acolo sta padurea si sistul din cadru.
## Stanga e lacul (apa la 4,5 m sub coronament). Dupa baraj (0.124-0.1535) dreapta
## e o pajiste plata de ~30 m cu Prometeu, apoi cade spre vale; stanga are un mal
## ingust de ~8-20 m deasupra apei. Inainte de baraj (0.064-0.078): rampa plata
## (padurea lui A intra deja pana la x ~ 62 si NU se dubleaza).
##
##  #  element                        cifra   piesa (GLB)                      cum
##  1  molizi, peretele opus al hauului ~100  trees/alpine_pines Pine_A..D       FlockProp (ace pe
##     (0.074-0.126, dreapta 40-90 m)         (+ Trunk_A..D, acelasi stol)       tf_jneapan, trunchi atlas)
##  2  molizi, pajiste dupa baraj       ~95   alpine_pines                       FlockProp, 3 randuri
##     (0.126-0.1535, dreapta 9-50 m)                                            (12-16 / 22-30 / 36-50 m)
##  3  molizi, malul stang dupa baraj   ~30   alpine_pines                       FlockProp, palcuri mici
##  4  fasie joasa langa drum           ~110  plants/jneapan_a/b + afin           FlockProp: jneapan culcat
##     (rampa 0.064-0.078 si dupa                                                  (ace tf_jneapan, scoarta
##     baraj, 3,5-9,5 m de margine)                                                tf_jneapan), afin, flori
##  5  pinten de sist la Prometeu       3+3   rocks/schist_outcrop_a/b/c          noduri `hull`, la >= 17 m
##     (0.126-0.137, dreapta)                                                      de axa, in spatele statuii
##  6  sist in peretele opus            ~34   schist_outcrop_b (Schist_Schist)    FlockProp tf_schist, lame
##                                                                                  inalte (scale3), fara coliziune
##  7  banci de zapada pe creasta opusa 10    structures/snow_wall (SnowWall_B_Snow) FlockProp `snow`, ingropate
##  8  grohotis la malul lacului        1     rocks/scree_cone                     nod, fara coliziune
##  9  fagi, accent la poale            9     plants/beech_tree_a/b                noduri `trunk` (3 palcuri)
## 10  petice de bujor + afin           4     plants/bujor_de_munte + afin         FlockProp (atint tf_bloom)
##
## Densitate spre drum: 0-3,5 m de margine nimic; 3,5-9,5 m fasie joasa; 10-30 m
## primul/al doilea rand de molid; 30-50 m al treilea rand; 40-90 m (peretele opus)
## padurea si sistul. INTERZIS: coronamentul (nimic), hauul 6-40 m dreapta
## 0.080-0.128 (fata din aval nu se ascunde), linia vizuala spre Prometeu,
## portalul de stanca (0.1315-0.148), lacul (cota < 8,2).
##
## 0 MATERIALE NOI: tf_jneapan, tf_schist, snow, atint:tf_bloom si atlasul sunt
## deja pe pista.

const SCENE_PATH := "res://scenes/tracks/Track21.tscn"
const TRACK := "res://scenes/tracks/Track21.tscn"
const ZONE := "DecorManual/ZonaB"
const F0 := 0.064
const F1 := 0.1535
const LAKE_Y := 7.5

const MODELS := {
	"b_flock": ["Script", "res://scenes/props/flock.gd"],
	"b_jneapan_a": ["PackedScene", "res://assets/models/transfagarasan/plants/jneapan_a.glb"],
	"b_jneapan_b": ["PackedScene", "res://assets/models/transfagarasan/plants/jneapan_b.glb"],
	"b_afin": ["PackedScene", "res://assets/models/transfagarasan/plants/afin.glb"],
	"b_bujor": ["PackedScene", "res://assets/models/transfagarasan/plants/bujor_de_munte.glb"],
	"b_outcrop_a": ["PackedScene", "res://assets/models/transfagarasan/rocks/schist_outcrop_a.glb"],
	"b_outcrop_b": ["PackedScene", "res://assets/models/transfagarasan/rocks/schist_outcrop_b.glb"],
	"b_outcrop_c": ["PackedScene", "res://assets/models/transfagarasan/rocks/schist_outcrop_c.glb"],
	"b_scree": ["PackedScene", "res://assets/models/transfagarasan/rocks/scree_cone.glb"],
	"b_snow_wall": ["PackedScene", "res://assets/models/transfagarasan/structures/snow_wall.glb"],
	"b_pines": ["PackedScene", "res://assets/models/trees/alpine_pines.glb"],
	"b_flower": ["PackedScene", "res://assets/models/flowers/flower_cluster.glb"],
	"b_beech_a": ["PackedScene", "res://assets/models/transfagarasan/plants/beech_tree_a.glb"],
	"b_beech_b": ["PackedScene", "res://assets/models/transfagarasan/plants/beech_tree_b.glb"],
}

var _track: Track
var _sampler: TrackSideSampler
var _terrain_rid: RID = RID()
var _sus_y := 0.0
var _rng := RandomNumberGenerator.new()
var _i_lo := 0
var _i_hi := 0
var _prom := Vector3(162.038, 11.98, 241.384)

var _nodes: Array[String] = []
var _flocks := {}
var _count := {}
var _rejected := 0
var _node_n := 0


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
	var n := _track.baked.size()
	_i_lo = int((F0 - 0.03) * float(n))
	_i_hi = int((F1 + 0.03) * float(n))
	_rng.seed = 64153
	var args := OS.get_cmdline_user_args()
	if "--survey" in args:
		_survey()
	else:
		_build()
		if "--write" in args:
			_write_scene()
		else:
			print("\n".join(_ext_lines()))
			print("\n".join(_nodes))
			print(_flock_text())
	get_tree().quit(0)


# ------------------------------------------------------------------ constructie

func _build() -> void:
	_strip()
	_molizi_perete_opus()
	_molizi_pajiste()
	_molizi_mal_stang()
	_pinten_prometeu()
	_sist_perete_opus()
	_zapada_creasta()
	_grohotis_mal()
	_fagi()
	_petice_bujor()
	var tot := 0
	for k in _count:
		tot += int(_count[k])
	print("; ZonaB: %d piese asezate, %d respinse de garzi" % [tot, _rejected])
	for k in _count:
		print(";   %s: %d" % [k, _count[k]])
	for k in _flocks:
		print(";   lot %s: %d instante" % [k, (_flocks[k]["pos"] as PackedVector3Array).size()])


## Un punct candidat: fractia, latura (+1 dreapta / -1 stanga) si offsetul de la
## MARGINEA asfaltului. Intoarce pozitia pe teren + ce trebuie garzilor.
func _cand(f: float, sg: float, off: float) -> Dictionary:
	var n := _track.baked.size()
	var i := int(f * float(n)) % n
	var p := _track.baked[i]
	var s := _track._side_at(i)
	var half := _track.width_at_index(i)
	var q: Vector3 = p + s * sg * (half + off)
	return _cand_at(q, f, p.y)


func _cand_at(q0: Vector3, f: float, road_y: float) -> Dictionary:
	var q := q0
	q.y = _sol_real(q.x, q.z)
	var near := _nearest_road(q)
	return {"pos": q, "f": f, "d": near["d"], "i": near["i"],
		"half_j": _track.width_at_index(near["i"]),
		"dy": q.y - road_y, "road_y": road_y}


## Garzile comune. `margin` = distanta libera de la MARGINEA asfaltului (m),
## `r` = raza piesei. Lacul, portalul de stanca, Prometeu si coronamentul raman libere.
func _ok(c: Dictionary, r: float, margin: float, solid: bool = false) -> bool:
	var q: Vector3 = c["pos"]
	if is_nan(q.y):
		return false
	if float(c["d"]) < float(c["half_j"]) + margin + r:
		return false
	# nodurile cu coliziune: cota din raycast si cea din sampler (pe care o citeste
	# `probe_manual`) trebuie sa se potriveasca, altfel sonda le numeste INGROPAT
	if solid and absf(_sampler.ground_y(q.x, q.z) - q.y) > 1.0:
		return false
	# lacul: stanga, sub cota apei + 0,8 m
	if q.y < LAKE_Y + 0.8 and _lake_side(q):
		return false
	# portalul de stanca: nimic solid la < 15 m de axa pe 0.1315-0.148, nimic nici
	# jos la < 11 m (zidurile lui ies din axa)
	var pd := _axis_dist(q, 0.1305, 0.1495)
	if pd < (15.0 if solid else 11.0) + r:
		return false
	# Prometeu: statuia si o insula in jurul ei
	if Vector2(q.x - _prom.x, q.z - _prom.z).length() < 5.0 + r:
		return false
	return true


## Pe stanga cota apei e +7,5 (rapa 0); o cota mica pe dreapta e hauul, nu lac.
func _lake_side(q: Vector3) -> bool:
	var near := _nearest_road(q)
	var i: int = near["i"]
	var s := _track._side_at(i)
	var p := _track.baked[i]
	var dot := (q.x - p.x) * s.x + (q.z - p.z) * s.z
	return dot < 0.0


func _axis_dist(q: Vector3, f0: float, f1: float) -> float:
	var best := 1e9
	var n := _track.baked.size()
	for i in range(int(f0 * float(n)), int(f1 * float(n))):
		var p := _track.baked[i]
		best = minf(best, Vector2(p.x - q.x, p.z - q.z).length())
	return best


func _put(kind: String, _c: Dictionary = {}) -> void:
	_count[kind] = int(_count.get(kind, 0)) + 1


func _slice_of(q: Vector3) -> int:
	if q.x < 85.0:
		return 0
	if q.x < 150.0:
		return 1
	return 2


func _flock_add(key: String, pos: Vector3, yaw: float, scl: Vector3) -> void:
	if not _flocks.has(key):
		_flocks[key] = {"pos": PackedVector3Array(), "yaw": PackedFloat32Array(), "scl": [] as Array[Vector3]}
	var d: Dictionary = _flocks[key]
	var pa: PackedVector3Array = d["pos"]
	pa.append(pos)
	d["pos"] = pa
	var ya: PackedFloat32Array = d["yaw"]
	ya.append(yaw)
	d["yaw"] = ya
	var sa: Array[Vector3] = []
	sa.assign(d["scl"])
	sa.append(scl)
	d["scl"] = sa


## Un molid in stolul potrivit (coroana + trunchi, aceleasi instante).
func _pine(pos: Vector3, sc: float) -> void:
	var r := _rng.randf()
	var v := "b" if r < 0.34 else ("c" if r < 0.68 else ("d" if r < 0.86 else "a"))
	var yaw := _rng.randf_range(-PI, PI)
	var s := _slice_of(pos)
	var p3 := pos
	p3.y -= 0.12
	var sv := Vector3(sc, sc * _rng.randf_range(0.95, 1.12), sc)
	_flock_add("pine_%s_s%d" % [v, s], p3, yaw, sv)
	_flock_add("trunk_%s_s%d" % [v, s], p3, yaw, sv)


# 4 ------------------------------------------------------------------ fasia joasa

## Jneapan culcat in palcuri de 3-5, afin si flori, la 3,5-9,5 m de margine: rampa
## dinaintea coronamentului (0.064-0.078, ambele parti; padurea lui A e mai la
## exterior) si pajistea de dupa baraj (0.1245-0.1535). Pe coronament NIMIC.
func _strip() -> void:
	var ranges := [
		[0.0645, 0.0735, 1.0], [0.0645, 0.0770, -1.0],
		[0.1245, 0.1535, 1.0], [0.1260, 0.1535, -1.0],
	]
	var clumps := 0
	for r: Array in ranges:
		var f: float = r[0]
		var sg: float = r[2]
		while f < float(r[1]):
			# 1-2 palcuri de jneapan pe statie (statii la ~0,0016 = 3 m)
			var kc := _rng.randi_range(1, 2)
			for _k in kc:
				var off := 3.5 + pow(_rng.randf(), 1.5) * 6.5
				var c := _cand(f + _rng.randf_range(-0.0007, 0.0007), sg, off)
				if not _ok(c, 1.8, 3.2) or float(c["dy"]) < -2.0:
					_rejected += 1
					continue
				var k := _rng.randi_range(3, 5)
				var placed := 0
				for m in k:
					var ang := _rng.randf() * TAU
					var rad := _rng.randf_range(0.0, 2.4) if m > 0 else 0.0
					var pc := _cand_at((c["pos"] as Vector3) + Vector3(cos(ang) * rad, 0.0, sin(ang) * rad), f, float(c["road_y"]))
					if not _ok(pc, 1.4, 3.2) or absf(float(pc["dy"]) - float(c["dy"])) > 1.2:
						continue
					var v := "a" if _rng.randf() < 0.55 else "b"
					var sc := _rng.randf_range(0.8, 1.3)
					var p3: Vector3 = pc["pos"]
					p3.y -= 0.05
					var s := _slice_of(p3)
					_flock_add("jn_%s_s%d" % [v, s], p3, _rng.randf_range(-PI, PI),
						Vector3(sc, sc * _rng.randf_range(0.9, 1.15), sc))
					_put("jneapan", pc)
					placed += 1
				if placed > 0:
					clumps += 1
			# afin: palc de 3-5 la baza lor
			if _rng.randf() < 0.55:
				var ca := _cand(f, sg, _rng.randf_range(4.0, 11.0))
				if _ok(ca, 1.2, 3.2) and float(ca["dy"]) > -2.0:
					for j in _rng.randi_range(3, 5):
						var q2: Vector3 = (ca["pos"] as Vector3) + Vector3(_rng.randf_range(-1.6, 1.6), 0.0, _rng.randf_range(-1.6, 1.6))
						var pc2 := _cand_at(q2, f, float(ca["road_y"]))
						if not _ok(pc2, 0.5, 3.2):
							continue
						var p4: Vector3 = pc2["pos"]
						p4.y -= 0.03
						var sc2 := _rng.randf_range(1.3, 1.9)
						_flock_add("afin_s%d" % _slice_of(p4), p4, _rng.randf_range(-PI, PI), Vector3(sc2, sc2, sc2))
						_put("afin", pc2)
			# flori de pajiste
			for _j in _rng.randi_range(1, 3):
				var cf := _cand(f + _rng.randf_range(-0.001, 0.001), sg, 3.4 + pow(_rng.randf(), 1.6) * 14.0)
				if not _ok(cf, 0.5, 2.8) or float(cf["dy"]) < -2.5:
					continue
				var pf: Vector3 = cf["pos"]
				pf.y -= 0.03
				var sf := _rng.randf_range(1.0, 1.8)
				_flock_add("flori_s%d" % _slice_of(pf), pf, _rng.randf_range(-PI, PI), Vector3(sf, sf, sf))
				_put("flori", cf)
			f += 0.0016
	_count["palcuri_jneapan"] = clumps


# 1 ------------------------------------------------------------------ molizi: peretele opus

## Padurea de pe peretele opus al hauului: dreapta, 40-90 m de margine, unde terenul
## urca +4..+22 m peste drum. Palcuri de 4-7, trei marimi, mai mari spre baza peretelui.
func _molizi_perete_opus() -> void:
	var clumps := 0
	var guard := 0
	while clumps < 80 and guard < 24000:
		guard += 1
		var f := _rng.randf_range(0.0725, 0.1275)
		var off := 36.0 + pow(_rng.randf(), 1.7) * 60.0
		var c := _cand(f, 1.0, off)
		if is_nan((c["pos"] as Vector3).y):
			continue
		var dy: float = c["dy"]
		if dy < -24.0 or dy > 30.0:
			continue
		if not _ok(c, 2.4, 20.0):
			_rejected += 1
			continue
		var k := _rng.randi_range(4, 7)
		var got := 0
		for m in k:
			var pc := c
			if m > 0:
				var ang := _rng.randf() * TAU
				var rad := _rng.randf_range(2.0, 6.5)
				pc = _cand_at((c["pos"] as Vector3) + Vector3(cos(ang) * rad, 0.0, sin(ang) * rad), f, float(c["road_y"]))
				if not _ok(pc, 1.8, 20.0) or float(pc["dy"]) < -26.0:
					continue
			# marimea: arborii de la baza peretelui (dy mic) mai mici, cei de sus mai mari
			var t := clampf((float(pc["dy"]) + 24.0) / 40.0, 0.0, 1.0)
			var sc := _rng.randf_range(0.7, 1.1) + 0.7 * t * _rng.randf_range(0.6, 1.0)
			_pine(pc["pos"], sc)
			_put("molizi_perete_opus", pc)
			got += 1
		if got > 0:
			clumps += 1


# 2 ------------------------------------------------------------------ molizi: pajistea de dupa baraj

func _molizi_pajiste() -> void:
	# [centru offset, +/-, nr pe palc, prob. palc, marime min, marime max]
	var rows := [
		[13.0, 3.0, 4, 0.75, 0.55, 1.0],
		[26.0, 4.0, 6, 0.85, 0.85, 1.35],
		[42.0, 6.0, 6, 0.80, 1.1, 1.7],
	]
	var clumps := 0
	for r: Array in rows:
		var f := 0.1265
		while f < F1 - 0.002:
			f += _rng.randf_range(0.0016, 0.0032)
			if f >= F1 - 0.002:
				break
			if _rng.randf() > float(r[3]):
				continue
			var off := float(r[0]) + _rng.randf_range(-float(r[1]), float(r[1]))
			# insula statuii: pe 0.119-0.1315, primul rand nu intra in linia vizuala spre ea
			if f < 0.1315 and off < 22.0:
				continue
			var c := _cand(f, 1.0, off)
			if not _ok(c, 2.4, 4.0):
				_rejected += 1
				continue
			var k: int = int(r[2]) + _rng.randi_range(-1, 2)
			var got := 0
			for m in k:
				var pc := c
				if m > 0:
					var ang := _rng.randf() * TAU
					var rad := _rng.randf_range(1.8, 5.5)
					pc = _cand_at((c["pos"] as Vector3) + Vector3(cos(ang) * rad, 0.0, sin(ang) * rad), f, float(c["road_y"]))
					if not _ok(pc, 1.8, 4.0):
						continue
				# primul rand rarit cu ~25 %: altfel citeste ca gard de brazi
				if float(r[0]) < 20.0 and _rng.randf() < 0.25:
					continue
				_pine(pc["pos"], _rng.randf_range(float(r[4]), float(r[5])))
				_put("molizi_pajiste", pc)
				got += 1
			if got > 0:
				clumps += 1
	_count["palcuri_pajiste"] = clumps


# 3 ------------------------------------------------------------------ molizi: malul stang

func _molizi_mal_stang() -> void:
	var clumps := 0
	var guard := 0
	while clumps < 8 and guard < 4000:
		guard += 1
		var f := _rng.randf_range(0.1325, F1 - 0.002)
		var c := _cand(f, -1.0, _rng.randf_range(7.0, 26.0))
		if not _ok(c, 2.2, 5.0) or float(c["dy"]) < -4.0:
			continue
		var k := _rng.randi_range(3, 5)
		var got := 0
		for m in k:
			var pc := c
			if m > 0:
				var ang := _rng.randf() * TAU
				var rad := _rng.randf_range(1.8, 4.5)
				pc = _cand_at((c["pos"] as Vector3) + Vector3(cos(ang) * rad, 0.0, sin(ang) * rad), f, float(c["road_y"]))
				if not _ok(pc, 1.8, 5.0) or float(pc["dy"]) < -4.0:
					continue
			_pine(pc["pos"], _rng.randf_range(0.6, 1.25))
			_put("molizi_mal_stang", pc)
			got += 1
		if got > 0:
			clumps += 1


# 5 ------------------------------------------------------------------ pintenul lui Prometeu

## 3 lame mari de sist in spatele statuii (nu o acopera din camera) + 3 mici la
## picior, cu coliziune `hull`, la >= 17 m de axa.
func _pinten_prometeu() -> void:
	# [model, frac, offset de la margine, scara, yaw]
	var specs := [
		["outcrop_b", 0.1300, 27.0, 1.5, 0.5], ["outcrop_a", 0.1272, 24.0, 1.4, 2.2],
		["outcrop_c", 0.1328, 22.0, 1.1, 4.1],
		["outcrop_b", 0.1310, 19.0, 1.0, 1.4], ["outcrop_c", 0.1262, 21.0, 0.85, 3.3],
		["outcrop_a", 0.1340, 31.0, 1.2, 5.6], ["outcrop_a", 0.1284, 23.0, 1.3, 1.1],
	]
	var n := 0
	for sp: Array in specs:
		var c := _cand(float(sp[1]), 1.0, float(sp[2]))
		if not _ok(c, 3.0 * float(sp[3]), 12.0, true):
			_rejected += 1
			continue
		var p3: Vector3 = c["pos"]
		n += 1
		_node("B_Pinten%02d" % n, "b_" + String(sp[0]), Vector3(p3.x, p3.y - 0.35 * float(sp[3]), p3.z),
			float(sp[4]), float(sp[3]), "")
		_put("aflorimente_pinten", c)
	# stanci in malul stang (sistul de pe lac din decupaj)
	for sp2: Array in [["outcrop_a", 0.1350, 10.0, 1.2, 2.8], ["outcrop_c", 0.1505, 10.5, 1.1, 0.9]]:
		var c2 := _cand(float(sp2[1]), -1.0, float(sp2[2]))
		if not _ok(c2, 3.5, 3.0, true) or float(c2["dy"]) < -5.0:
			_rejected += 1
			continue
		var q: Vector3 = c2["pos"]
		n += 1
		_node("B_PintenMal%02d" % n, "b_" + String(sp2[0]), Vector3(q.x, q.y - 0.35 * float(sp2[3]), q.z),
			float(sp2[4]), float(sp2[3]), "")
		_put("aflorimente_mal", c2)


# 6 ------------------------------------------------------------------ sist in peretele opus

## Lame inalte de sist (scara neuniforma, foliatie) care ies prin padure pe
## peretele opus; stol `tf_schist`, fara coliziune (sunt la 40+ m de drum).
func _sist_perete_opus() -> void:
	var n := 0
	var guard := 0
	while n < 46 and guard < 9000:
		guard += 1
		var f := _rng.randf_range(0.0715, 0.1275)
		var c := _cand(f, 1.0, 36.0 + pow(_rng.randf(), 1.5) * 46.0)
		if is_nan((c["pos"] as Vector3).y) or float(c["dy"]) < -20.0:
			continue
		if not _ok(c, 3.0, 20.0):
			continue
		# gruparea: 2-3 lame vecine
		var k := _rng.randi_range(1, 3)
		for m in k:
			var pc := c
			if m > 0:
				var ang := _rng.randf() * TAU
				var rad := _rng.randf_range(2.5, 6.0)
				pc = _cand_at((c["pos"] as Vector3) + Vector3(cos(ang) * rad, 0.0, sin(ang) * rad), f, float(c["road_y"]))
				if not _ok(pc, 2.0, 20.0) or float(pc["dy"]) < -22.0:
					continue
			var sx := _rng.randf_range(1.6, 3.2)
			var sy := _rng.randf_range(1.8, 3.8)
			var sz := _rng.randf_range(0.9, 1.6)
			var p3: Vector3 = pc["pos"]
			p3.y -= 0.45 * sy
			_flock_add("rock_s%d" % _slice_of(p3), p3, _rng.randf_range(-PI, PI), Vector3(sx, sy, sz))
			_put("sist_perete", pc)
			n += 1


# 7 ------------------------------------------------------------------ zapada pe creasta opusa

func _zapada_creasta() -> void:
	var n := 0
	var guard := 0
	while n < 10 and guard < 5000:
		guard += 1
		var f := _rng.randf_range(0.0725, 0.1235)
		var c := _cand(f, 1.0, _rng.randf_range(44.0, 78.0))
		if is_nan((c["pos"] as Vector3).y) or float(c["dy"]) < 8.0:
			continue
		if not _ok(c, 3.0, 20.0):
			continue
		var sx := _rng.randf_range(1.4, 2.4)
		var sy := _rng.randf_range(0.9, 1.5)
		var sz := _rng.randf_range(0.6, 1.0)
		var p3: Vector3 = c["pos"]
		p3.y -= 3.02 * sy * _rng.randf_range(0.35, 0.5)
		_flock_add("snow_s%d" % _slice_of(p3), p3, _rng.randf_range(-PI, PI), Vector3(sx, sy, sz))
		_put("zapada", c)
		n += 1


# 8 ------------------------------------------------------------------ grohotis la lac

func _grohotis_mal() -> void:
	for sp: Array in [[0.1418, 9.5], [0.1462, 9.0], [0.1388, 11.0]]:
		var c := _cand(float(sp[0]), -1.0, float(sp[1]))
		if not _ok(c, 6.0, 2.0) or float(c["dy"]) < -5.0:
			_rejected += 1
			continue
		var q: Vector3 = c["pos"]
		# latura plata spre drum: yaw pe directia centru -> drum
		var i: int = c["i"]
		var to_road: Vector3 = _track.baked[i] - q
		to_road.y = 0.0
		to_road = to_road.normalized()
		# latura plata e +Z local, deci o intoarcem spre STANCA (departe de drum)
		var to_rock := -to_road
		_node("B_Grohotis%02d" % int(_count.get("grohotis", 0) + 1), "b_scree",
			Vector3(q.x, q.y - 0.25, q.z), atan2(to_rock.x, to_rock.z), 1.0, "none")
		_put("grohotis", c)


# 9 ------------------------------------------------------------------ fagi

## Accente la poale (nu masa): 3 palcuri de 3, pe pajistea de dupa portal si pe malul stang.
func _fagi() -> void:
	var groups := [[0.1500, 1.0, 19.0], [0.1518, 1.0, 13.0], [0.1478, -1.0, 11.0]]
	var total := 0
	for g: Array in groups:
		for k in 3:
			var off: float = float(g[2]) + _rng.randf_range(-2.0, 2.0) + float(k) * 2.4
			var c := _cand(float(g[0]) + _rng.randf_range(-0.002, 0.002), float(g[1]), off)
			if not _ok(c, 3.4, 8.0, true) or float(c["dy"]) < -4.0:
				_rejected += 1
				continue
			var q: Vector3 = c["pos"]
			var m := "b_beech_a" if _rng.randf() < 0.5 else "b_beech_b"
			total += 1
			_node("B_Fag%02d" % total, m, Vector3(q.x, q.y - 0.1, q.z), _rng.randf_range(0.0, TAU),
				_rng.randf_range(0.8, 1.15), "")
			_put("fagi", c)


# 10 ----------------------------------------------------------------- bujor

func _petice_bujor() -> void:
	var spots := [[0.0668, 1.0, 9.5], [0.1272, -1.0, 6.5], [0.1442, 1.0, 14.0], [0.1523, 1.0, 11.0]]
	for sp: Array in spots:
		var c := _cand(float(sp[0]), float(sp[1]), float(sp[2]))
		if not _ok(c, 2.0, 4.0) or float(c["dy"]) < -3.0:
			_rejected += 1
			continue
		var cp: Vector3 = c["pos"]
		for j in 6:
			var a := _rng.randf_range(0.0, TAU)
			var r := sqrt(_rng.randf()) * 1.8
			var pc := _cand_at(cp + Vector3(cos(a) * r, 0.0, sin(a) * r), float(sp[0]), float(c["road_y"]))
			if is_nan((pc["pos"] as Vector3).y):
				continue
			var q: Vector3 = pc["pos"]
			q.y += 0.02
			var sc := _rng.randf_range(1.0, 1.4)
			_flock_add("bujor_s%d" % _slice_of(q), q, _rng.randf_range(-PI, PI), Vector3(sc, sc, sc))
			_put("bujor", pc)
		for j in 3:
			var a2 := _rng.randf_range(0.0, TAU)
			var r2 := 2.2 + _rng.randf() * 1.6
			var pc2 := _cand_at(cp + Vector3(cos(a2) * r2, 0.0, sin(a2) * r2), float(sp[0]), float(c["road_y"]))
			if is_nan((pc2["pos"] as Vector3).y):
				continue
			var q2: Vector3 = pc2["pos"]
			var sc2 := _rng.randf_range(1.4, 1.9)
			_flock_add("afin_s%d" % _slice_of(q2), q2, _rng.randf_range(-PI, PI), Vector3(sc2, sc2, sc2))
			_put("afin", pc2)


# ------------------------------------------------------------------ emitere

## Un nod instantiat din GLB. `mode` = `metadata/coliziune` ("" = implicit al piesei).
func _node(nm: String, res_id: String, pos: Vector3, yaw: float, sc: float, mode: String) -> void:
	var b := Basis(Vector3.UP, yaw).scaled(Vector3(sc, sc, sc))
	_nodes.append('[node name="%s" parent="%s" instance=ExtResource("%s")]' % [nm, ZONE, res_id])
	_nodes.append("transform = Transform3D(%.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.3f, %.3f, %.3f)"
		% [b.x.x, b.x.y, b.x.z, b.y.x, b.y.y, b.y.z, b.z.x, b.z.y, b.z.z, pos.x, pos.y, pos.z])
	if mode != "":
		_nodes.append('metadata/coliziune = "%s"' % mode)
	_nodes.append("")
	_node_n += 1


## Lotul -> (id model, mesh_name, clasa). Cheia lotului: prefix_variant_sN.
func _lot_spec(key: String) -> Dictionary:
	var parts := key.split("_")
	match parts[0]:
		"jn":
			return {"model": "b_jneapan_" + parts[1], "mesh": "Jneapan_Needles", "cls": "tf_jneapan", "nm": "B_JnAce_" + parts[1] + "_" + parts[2]}
		"afin":
			return {"model": "b_afin", "mesh": "Afin_Leaves", "cls": "", "nm": "B_Afin_" + parts[1]}
		"pine":
			return {"model": "b_pines", "mesh": "Pine_" + parts[1].to_upper(), "cls": "tf_jneapan", "nm": "B_Molid_" + parts[1] + "_" + parts[2]}
		"trunk":
			return {"model": "b_pines", "mesh": "Trunk_" + parts[1].to_upper(), "cls": "", "nm": "B_Trunchi_" + parts[1] + "_" + parts[2]}
		"rock":
			return {"model": "b_outcrop_b", "mesh": "Schist_Schist", "cls": "tf_schist", "nm": "B_Sist_" + parts[1]}
		"snow":
			return {"model": "b_snow_wall", "mesh": "SnowWall_B_Snow", "cls": "snow", "nm": "B_Banc_" + parts[1]}
		"flori":
			return {"model": "b_flower", "mesh": "", "cls": "", "nm": "B_Flori_" + parts[1]}
		"bujor":
			return {"model": "b_bujor", "mesh": "Bujor_Bloom", "cls": "atint:tf_bloom", "nm": "B_BujorFloare_" + parts[1]}
	return {}


func _flock_text() -> String:
	var out: Array[String] = []
	for key in _flocks:
		out.append_array(_flock_block(key))
	return "\n".join(out)


func _block(nm: String, spec_model: String, mesh: String, cls: String, d: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	lines.append('[node name="%s" type="MultiMeshInstance3D" parent="%s"]' % [nm, ZONE])
	lines.append('script = ExtResource("b_flock")')
	lines.append('model = ExtResource("%s")' % spec_model)
	if mesh != "":
		lines.append('mesh_name = "%s"' % mesh)
	if cls != "":
		lines.append('tri_class = "%s"' % cls)
	lines.append("positions = %s" % var_to_str(d["pos"]).replace("\n", ""))
	lines.append("yaws = %s" % var_to_str(d["yaw"]).replace("\n", ""))
	lines.append("scale3_list = %s" % var_to_str(d["scl"]).replace("\n", ""))
	lines.append("")
	return lines


func _flock_block(key: String) -> Array[String]:
	var lines: Array[String] = []
	var d: Dictionary = _flocks[key]
	var spec := _lot_spec(key)
	if (d["pos"] as PackedVector3Array).is_empty():
		return lines
	lines.append_array(_block(spec["nm"], spec["model"], spec["mesh"], spec["cls"], d))
	# scoarta jneapanului: pe `tf_jneapan` (atlasul o iese portocalie), aceleasi instante
	if key.begins_with("jn_"):
		lines.append_array(_block(String(spec["nm"]).replace("JnAce", "JnScoarta"), spec["model"],
			"Jneapan_Bark", "tf_jneapan", d))
	if key.begins_with("afin_"):
		lines.append_array(_block(String(spec["nm"]).replace("Afin_", "AfinBoabe_"), spec["model"],
			"Afin_Berry", "", d))
	if key.begins_with("bujor_"):
		lines.append_array(_block(String(spec["nm"]).replace("Floare", "Frunze"), spec["model"],
			"Bujor_Leaves", "", d))
	return lines


func _ext_lines() -> Array[String]:
	var out: Array[String] = []
	for id in MODELS:
		out.append('[ext_resource type="%s" path="%s" id="%s"]' % [MODELS[id][0], MODELS[id][1], id])
	return out


## Rescrie DOAR ZonaB si ext_resource-urile `b_*` din Track21.tscn. Restul ramane
## octet cu octet. (Un .tscn editat de mana nu se rescrie: citesc, tai, lipesc.)
func _write_scene() -> void:
	var path := ProjectSettings.globalize_path(SCENE_PATH)
	var txt := FileAccess.get_file_as_string(path)
	var lines := txt.split("\n")
	var kept: Array[String] = []
	var skipping := false
	for ln in lines:
		var l: String = ln
		if l.begins_with('[ext_resource') and ' id="b_' in l:
			continue
		if l.begins_with("["):
			skipping = ('parent="%s"' % ZONE) in l
		if skipping:
			continue
		kept.append(l)
	var out: Array[String] = []
	var last_ext := -1
	for k in kept.size():
		if kept[k].begins_with("[ext_resource"):
			last_ext = k
	var zona_end := -1
	for k in kept.size():
		if kept[k].begins_with('[node name="ZonaB" type="Node3D" parent="DecorManual"]'):
			var m := k + 1
			while m < kept.size() and kept[m] != "":
				m += 1
			zona_end = m
	for k in kept.size():
		out.append(kept[k])
		if k == last_ext:
			out.append_array(_ext_lines())
		if k == zona_end:
			out.append_array(_nodes)
			var ft := _flock_text()
			if ft != "":
				out.append(ft)
				out.append("")
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("\n".join(out))
	f.close()
	print("; scris %s (%d noduri de instanta, %d loturi MultiMesh)" % [path, _node_n, _flocks.size()])


# ------------------------------------------------------------------ survey

func _survey() -> void:
	var offs := [2, 5, 10, 15, 20, 30, 40, 60, 90]
	var f := F0
	while f < F1 + 0.003:
		var i := int(f * float(_track.baked.size())) % _track.baked.size()
		var p: Vector3 = _track.baked[i]
		var line := "f=%.4f x=%.0f z=%.0f y=%.1f half=%.1f | " % [f, p.x, p.z, p.y, _track.width_at_index(i)]
		for sgn in [1.0, -1.0]:
			line += ("R " if sgn > 0 else "L ")
			for o in offs:
				var c := _cand(f, sgn, float(o))
				var q: Vector3 = c["pos"]
				line += "%s " % ("nan" if is_nan(q.y) else "%+.0f" % (q.y - p.y))
			line += "| "
		print(line)
		f += 0.004


# ------------------------------------------------------------------ helpers

## Cea mai apropiata bucata de drum: {d (de la axa, xz), i (indexul)}.
func _nearest_road(q: Vector3) -> Dictionary:
	var best := 1e9
	var bi := _i_lo
	var n := _track.baked.size()
	for k in range(_i_lo, mini(_i_hi, n - 1)):
		var a := _track.baked[k]
		var b := _track.baked[k + 1]
		var abx := b.x - a.x
		var abz := b.z - a.z
		var l2 := abx * abx + abz * abz
		var t := 0.0
		if l2 > 0.0001:
			t = clampf(((q.x - a.x) * abx + (q.z - a.z) * abz) / l2, 0.0, 1.0)
		var dx := a.x + abx * t - q.x
		var dz := a.z + abz * t - q.z
		var d := dx * dx + dz * dz
		if d < best:
			best = d
			bi = k if t < 0.5 else k + 1
	return {"d": sqrt(best), "i": bi}


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
	return _sampler.ground_y(x, z)
