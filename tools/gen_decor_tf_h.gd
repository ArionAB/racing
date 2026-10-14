extends Node
## Generator de decor MANUAL pentru POI H — DEFILEUL OLTULUI Transfagarasan
## (Track21, frac 0.7036-0.9786, ~588 m, semi 7,0). Nu e sonda: MASOARA terenul
## real (`_terrain_mesh_y`) si CALCULEAZA nodurile care se lipesc in
## `Track21.tscn` sub `DecorManual/ZonaH`.
##
##   godot --headless --path . res://tools/GenDecorTfH.tscn -- --survey
##   godot --headless --path . res://tools/GenDecorTfH.tscn -- --emit    (tipareste)
##   godot --headless --path . res://tools/GenDecorTfH.tscn -- --write   (rescrie ZonaH)
##
## ---------------------------------------------------------------------------
## LISTA DE ELEMENTE (runda 1) — din decupajele `H.png` si `A_poenari.png`, cu
## cifrele fisei (`### H` din transfagarasan_poi_gauntlet.md), fiecare legat de o
## piesa. Cifrele sunt TINTE; cele reale se tipasesc la `--emit` si merg in raport.
##
## Ce arata decupajul (MATERIA, nu layoutul): rau lat verde-cenusiu, cu MALURI DE
## STANCA gri-verzuie in lame inclinate (lespezi suprapuse, spuma alba la picior) pe
## ambele maluri; pereti de PADURE de molid verde-negru, in coloane inguste, 3
## marimi, in palcuri neregulate, cu FAG rotund verde-cald amestecat (mai mult spre
## capatul dinspre Argeș); intre drum si copaci o fasie de iarba scurta cu tufe;
## calea ferata cu trenul peste trecerea la nivel (MONTATE: nu le ating); la capat
## ruina Poenari pe o stanca, cu padure deasa in jur si lespezi de sist la picior.
##
##  #  element                        tinta   piesa (GLB)                       cum
##  1  molizi, masa (8 randuri pe     ~2300   trees/alpine_pines Pine_A..D       FlockProp feliat (6 felii),
##     stanga, 4 pe malul opus,               (+ Trunk_A..D)                     ace tf_jneapan 55% / atlas
##     3 marimi, palcuri de 3-6)                                                 30%; trunchi pe atlas
##  2  fagi in palcuri (tonul 3)     ~15%    plants/beech_tree_a/b             FlockProp, Beech_Leaves tf_beech,
##     crescand spre A (5% -> 30%)          (Beech_Bark pe atlas)              Beech_Bark atlas
##  3  lespezi de sist in peretele    ~280    rocks/schist_outcrop_a/b/c        FlockProp tf_schist, scale3
##     din stanga (0.765-0.865)             (Schist_Schist)                    (lame inalte), fara coliziune
##  4  aflorimente erou la piciorul   ~9      rocks/schist_outcrop_a/b/c        noduri `hull`, la >= 10 m de
##     peretelui (primul rand)                                                  margine (mod implicit)
##  5  stanci de mal la linia apei    ~160    rocks/schist_outcrop_b (mic)      FlockProp tf_schist, pe ambele
##     (apa Oltului, malul drept)                                                 maluri, in sirag cu goluri
##  6  tufe de fag / salcie la apa    ~70     plants/beech_tree_a (0,3-0,5)     FlockProp, pe malul apei
##  7  fasie joasa 3,5-9 m (afin,     ~700    plants/afin + beech mic +         FlockProp, fara coliziune;
##     tufe, sist mic, grohotis mic)          rocks/schist_outcrop_b (mic)       NU jneapan (contract: "jneapan nu")
##  8  conuri de grohotis             2       rocks/scree_cone                  noduri fara coliziune, la piciorul
##                                                                              peretelui
##  9  piciorul Poenari: lespezi      6       rocks/schist_outcrop_a/b/c        noduri fara coliziune, inel la
##     de sist in jurul ruinei                                                    10-15 m de centrul ruinei
##
## NU sunt ale mele: trenul, sina, trecerea la nivel (hazard/montare), Oltul (rape),
## Poenari (montat), orizontul. Culoar de sina: nimic la < 6 m de linia sinei pe
## +-72 m si nimic la < 9 m de bratele barierei.
##
## Densitate spre drum: 0-3,5 m nimic; 3,5-9 m fasia joasa; 9,5-30 m randurile 1-3 de
## molid mici/medii (cele mai dese, dar cu goluri), 30-60 m randurile 4-6 (mari),
## 60-110 m randul de dincolo de rau; ritm: perete (0.765-0.865) / deschidere spre
## rau / perete, nu uniform. 0 MATERIALE NOI: tf_jneapan, tf_schist, tf_beech si
## atlasul sunt deja pe pista.

const TRACK := "res://scenes/tracks/Track21.tscn"
const SCENE_PATH := "res://scenes/tracks/Track21.tscn"
const ZONE := "DecorManual/ZonaH"
const F0 := 0.7036
const F1 := 0.9786
const NSLICE := 6
const POENARI := Vector2(-125.0, 215.0)
## Sina: centrul nodului `Tren` si directia lui (x local al nodului, in planul xz).
const RAIL_C := Vector2(-199.674, -131.918)
const RAIL_U := Vector2(0.80327, 0.59562)
const CROSSINGS := [Vector2(-198.88, -138.90), Vector2(-200.27, -124.98)]

const MODELS := {
	"h_flock": ["Script", "res://scenes/props/flock.gd"],
	"h_pines": ["PackedScene", "res://assets/models/trees/alpine_pines.glb"],
	"h_beech_a": ["PackedScene", "res://assets/models/transfagarasan/plants/beech_tree_a.glb"],
	"h_beech_b": ["PackedScene", "res://assets/models/transfagarasan/plants/beech_tree_b.glb"],
	"h_afin": ["PackedScene", "res://assets/models/transfagarasan/plants/afin.glb"],
	"h_outcrop_a": ["PackedScene", "res://assets/models/transfagarasan/rocks/schist_outcrop_a.glb"],
	"h_outcrop_b": ["PackedScene", "res://assets/models/transfagarasan/rocks/schist_outcrop_b.glb"],
	"h_outcrop_c": ["PackedScene", "res://assets/models/transfagarasan/rocks/schist_outcrop_c.glb"],
	"h_scree": ["PackedScene", "res://assets/models/transfagarasan/rocks/scree_cone.glb"],
}

var _track: Track
var _sampler: TrackSideSampler
var _rng := RandomNumberGenerator.new()
var _i_lo := 0
var _i_hi := 0

var _nodes: Array[String] = []
var _flocks := {}
var _count := {}
var _rejected := 0
var _node_n := 0
var _shore_cache := {}


func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	_sampler = _track._sampler
	var n := _track.baked.size()
	_i_lo = int((F0 - 0.03) * float(n))
	_i_hi = int((F1 + 0.03) * float(n))
	_rng.seed = 703697
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
	_pietre_perete()
	_eroi_perete()
	_grohotis()
	_poenari_picior()
	_pietre_mal()
	_molizi()
	_umplutura()
	_fasie()
	var tot := 0
	for k in _count:
		tot += int(_count[k])
	print("; ZonaH: %d piese asezate, %d respinse de garzi" % [tot, _rejected])
	for k in _count:
		print(";   %s: %d" % [k, _count[k]])
	var mm := 0
	for k in _flocks:
		var c := (_flocks[k]["pos"] as PackedVector3Array).size()
		mm += c
		print(";   lot %s: %d instante" % [k, c])
	print(";   TOTAL instante MultiMesh: %d, noduri: %d" % [mm, _node_n])


## Un punct candidat: fractia, latura (+1 dreapta / -1 stanga fata de `_side_at`)
## si offsetul de la MARGINEA asfaltului.
func _cand(f: float, sg: float, off: float) -> Dictionary:
	var n := _track.baked.size()
	var i := int(f * float(n)) % n
	var p := _track.baked[i]
	var s := _track._side_at(i)
	var half := _track.width_at_index(i)
	var q: Vector3 = p + s * sg * (half + off)
	return _cand_at(q, {"f": f, "i": i, "sg": sg})


func _cand_at(pos: Vector3, base: Dictionary) -> Dictionary:
	var q := pos
	q.y = _sol_real(q.x, q.z)
	var near := _nearest_road(q)
	var y1 := _sol_real(q.x + 2.0, q.z)
	var y2 := _sol_real(q.x - 2.0, q.z)
	var y3 := _sol_real(q.x, q.z + 2.0)
	var y4 := _sol_real(q.x, q.z - 2.0)
	var slope := maxf(absf(y1 - y2), absf(y3 - y4)) / 4.0
	var nrm := Vector3(y2 - y1, 4.0, y4 - y3).normalized()
	var d := base.duplicate()
	d["pos"] = q
	d["d"] = near["d"]
	d["j"] = near["i"]
	d["half_j"] = _track.width_at_index(near["i"])
	d["dy"] = q.y - _track.baked[near["i"]].y
	d["slope"] = slope
	d["nrm"] = nrm
	return d


## Garzile comune. `margin` = cat de departe de MARGINEA asfaltului (m), `r` =
## raza piesei. Culoarul sinei, bratele barierei si ruina Poenari raman libere.
func _ok(c: Dictionary, r: float, margin: float) -> bool:
	var q: Vector3 = c["pos"]
	if is_nan(q.y):
		return false
	if float(c["d"]) < float(c["half_j"]) + margin + r:
		return false
	var p2 := Vector2(q.x, q.z)
	# culoarul sinei: +-72 m de-a lungul ei, 6 m + raza de o parte si de alta
	var rel := p2 - RAIL_C
	var t := rel.dot(RAIL_U)
	var perp := absf(rel.x * RAIL_U.y - rel.y * RAIL_U.x)
	if absf(t) < 72.0 and perp < 6.0 + r:
		return false
	for cr: Vector2 in CROSSINGS:
		if p2.distance_to(cr) < 9.0 + r:
			return false
	if p2.distance_to(POENARI) < 15.0 + r:
		return false
	return true


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


func _bump(k: String, n: int = 1) -> void:
	_count[k] = int(_count.get(k, 0)) + n


## Felia (0..NSLICE-1) dupa fractie: culling pe felii.
func _slice_of(f: float) -> int:
	return clampi(int((f - F0) / (F1 - F0) * float(NSLICE)), 0, NSLICE - 1)


func _smooth(a: float, b: float, x: float) -> float:
	var t := clampf((x - a) / (b - a), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


## Cota apei Oltului (absoluta) la fractia data: rapa 4 (0.705-0.775) la +3,4,
## rapa 6 (0.766-0.856) la +0,4, rapa 5 (0.845-0.975) la -2,5.
func _water_y(f: float) -> float:
	if f < 0.7655:
		return 3.4
	if f < 0.8555:
		return 0.4
	return -2.5


## Offsetul (de la marginea asfaltului, malul DREPT) la care terenul coboara sub apa;
## -1 daca pe 45 m nu ajunge la apa (gol, sau rapa nu e aici).
func _shore_off(f: float) -> float:
	var key := int(f * 4000.0)
	if _shore_cache.has(key):
		return float(_shore_cache[key])
	var n := _track.baked.size()
	var i := int(f * float(n)) % n
	var p := _track.baked[i]
	var s := _track._side_at(i)
	var half := _track.width_at_index(i)
	var w := _water_y(f)
	var res := -1.0
	var off := 1.0
	while off < 45.0:
		var q: Vector3 = p + s * (half + off)
		var y := _sol_real(q.x, q.z)
		if y < w + 0.25:
			res = off
			break
		off += 0.5
	_shore_cache[key] = res
	return res


# 3 ------------------------------------------------------------------ lespezi in perete

## Peretele din stanga (0.765-0.865, +5..+68 m peste drum la 20-90 m): masa de
## lespezi de sist suprapuse, inalte si inguste (scale3), pe jitter de grila, ca sa
## citeasca treptele din decupaj. FlockProp tf_schist, fara coliziune.
func _pietre_perete() -> void:
	var n := 0
	var f := 0.7655
	var guard := 0
	while f < 0.8665:
		var off := 11.0 + _rng.randf_range(0.0, 3.0)
		while off < 84.0:
			guard += 1
			var o := off + _rng.randf_range(-2.5, 2.5)
			off += _rng.randf_range(5.5, 9.0)
			# ritm: spatii intre grupuri de lespezi (vegetatia ia restul peretelui)
			var rhythm := 0.5 + 0.5 * sin((f - 0.7655) * 160.0 + off * 0.045)
			if _rng.randf() > 0.28 + 0.36 * rhythm:
				continue
			var c := _cand(f + _rng.randf_range(-0.0009, 0.0009), -1.0, o)
			var dy: float = c["dy"]
			if is_nan((c["pos"] as Vector3).y) or dy < 1.2 or float(c["slope"]) < 0.22:
				continue
			if not _ok(c, 2.5, 8.0):
				continue
			var p3: Vector3 = c["pos"]
			var sx := _rng.randf_range(1.5, 3.0)
			var sc3 := Vector3(sx, sx * _rng.randf_range(0.5, 0.95), sx * _rng.randf_range(0.8, 1.25))
			p3.y -= 0.35 * sc3.y
			var pick := _rng.randf()
			var key := "perete_b" if pick < 0.5 else ("perete_a" if pick < 0.8 else "perete_c")
			_flock_add("%s_s%d" % [key, _slice_of(f)], p3, _rng.randf_range(-PI, PI), sc3)
			n += 1
		f += 0.0017
	_bump("lespezi_perete", n)


# 4 ------------------------------------------------------------------ eroi

## Aflorimente cu coliziune (`hull`) la piciorul peretelui, 11-20 m de margine,
## in gramezi de 2: primul rand pe care il vede camera.
func _eroi_perete() -> void:
	var centers: Array[Vector3] = []
	var total := 0
	var guard := 0
	while total < 9 and guard < 6000:
		guard += 1
		var f := _rng.randf_range(0.770, 0.862)
		var c := _cand(f, -1.0, _rng.randf_range(11.0, 20.0))
		if not _ok(c, 4.0, 9.0) or float(c["slope"]) > 0.7 or float(c["dy"]) < -0.5:
			continue
		var pp: Vector3 = c["pos"]
		var near := false
		for q in centers:
			if q.distance_to(pp) < 24.0:
				near = true
				break
		if near:
			continue
		centers.append(pp)
		for m in 2:
			var pc := c
			if m > 0:
				var ang := _rng.randf() * TAU
				pc = _cand_at(pp + Vector3(cos(ang) * 2.6, 0.0, sin(ang) * 2.6), c)
				if not _ok(pc, 3.0, 9.0):
					continue
			var sc := _rng.randf_range(1.2, 1.9) if m == 0 else _rng.randf_range(0.7, 1.2)
			var nm: String = ["a", "b", "c"][_rng.randi_range(0, 2)]
			var p3: Vector3 = pc["pos"]
			total += 1
			_node("H_Aflor%02d" % total, "h_outcrop_" + nm, Vector3(p3.x, p3.y - 0.4 * sc, p3.z),
				_rng.randf_range(-PI, PI), sc, pc["nrm"], 0.45)
	_bump("aflorimente_eroi", total)


func _grohotis() -> void:
	var k := 0
	var guard := 0
	while k < 2 and guard < 4000:
		guard += 1
		var f := _rng.randf_range(0.775, 0.86)
		var c := _cand(f, -1.0, _rng.randf_range(12.0, 22.0))
		if not _ok(c, 5.0, 9.0) or float(c["slope"]) > 0.8 or float(c["dy"]) < 0.0:
			continue
		var p3: Vector3 = c["pos"]
		var i: int = c["j"]
		var to_road := _track.baked[i] - p3
		k += 1
		# latura plata a conului spre stanca (inapoi de drum)
		var yaw := atan2(-to_road.x, -to_road.z)
		_node("H_Grohotis%02d" % k, "h_scree", Vector3(p3.x, p3.y - 0.35, p3.z), yaw,
			_rng.randf_range(0.85, 1.1), c["nrm"], 0.7, "none")
	_bump("grohotis", k)


# 9 ------------------------------------------------------------------ Poenari

## Lespezi de sist in jurul ruinei (sprijinul stancii din decupaj): inel la 10-15 m
## de centru, fara coliziune (Poenari are propria baza), cu fata spre drum mai deasa.
func _poenari_picior() -> void:
	var n := 0
	for k in 7:
		var ang := float(k) / 7.0 * TAU + _rng.randf_range(-0.25, 0.25)
		var rad := _rng.randf_range(10.5, 14.5)
		var pos := Vector3(POENARI.x + cos(ang) * rad, 0.0, POENARI.y + sin(ang) * rad)
		var c := _cand_at(pos, {"f": 0.96, "sg": -1.0})
		var q: Vector3 = c["pos"]
		if is_nan(q.y) or float(c["d"]) < 9.0:
			continue
		var sc := _rng.randf_range(1.5, 2.5)
		n += 1
		var nm: String = ["a", "b", "c"][_rng.randi_range(0, 2)]
		_node("H_PoenariPiatra%02d" % n, "h_outcrop_" + nm, Vector3(q.x, q.y - 0.45 * sc, q.z),
			_rng.randf_range(-PI, PI), sc, Vector3.UP, 0.0, "none")
	_bump("poenari_picior", n)


# 5 + 6 -------------------------------------------------------------- mal de apa

## Siragul de stanci la linia apei (malul drept, la 10-14 m de margine), cu goluri,
## plus tufe rotunde (fag/salcie mici) si afin; si pe malul opus (apa vazuta de
## departe). Oltul in sine e al fundatiei.
func _pietre_mal() -> void:
	var n_rock := 0
	var n_tufa := 0
	var f := 0.7075
	while f < F1 - 0.002:
		f += _rng.randf_range(0.0013, 0.0024)
		var so := _shore_off(f)
		if so < 0.0:
			continue
		# ritm: sirag pe tronsoane, cu pauze (plaja deschisa)
		var rhythm := 0.5 + 0.5 * sin(f * 210.0)
		if _rng.randf() > 0.55 + 0.4 * rhythm:
			continue
		# trepte: 3-4 lespezi stivuite pe taluz, de la apa spre drum (fiecare pe cota terenului)
		var along_i := mini(int(_track.baked.size()) - 2, int(f * float(_track.baked.size())))
		var tan := _track.baked[along_i + 1] - _track.baked[along_i]
		var yaw_t := atan2(-tan.z, tan.x)
		var k := _rng.randi_range(3, 4)
		for m in k:
			var oo := so + float(m) * _rng.randf_range(1.1, 1.8) - 1.0
			var pc := _cand(f + _rng.randf_range(-0.0004, 0.0004), 1.0, oo)
			var q: Vector3 = pc["pos"]
			if is_nan(q.y) or not _ok(pc, 1.4, 3.0):
				_rejected += 1
				continue
			var sx := _rng.randf_range(0.55, 1.0) * (1.0 - 0.12 * float(m))
			var sc3 := Vector3(sx * _rng.randf_range(1.0, 1.5), sx * _rng.randf_range(0.45, 0.75), sx)
			var p3 := q
			p3.y -= 0.2 * sc3.y
			_flock_add("mal_s%d" % _slice_of(f), p3, yaw_t + _rng.randf_range(-0.35, 0.35), sc3)
			n_rock += 1
		# tufa de salcie / fag mic la apa
		if _rng.randf() < 0.08:
			var tc := _cand(f + _rng.randf_range(-0.001, 0.001), 1.0, so + _rng.randf_range(-3.5, -0.6))
			if _ok(tc, 1.0, 2.5) and float(tc["slope"]) < 1.3 and float(tc["dy"]) > -9.0:
				var ts := _rng.randf_range(0.17, 0.3)
				var tp: Vector3 = tc["pos"]
				tp.y -= 0.05
				var tv := _slice_of(f)
				_flock_add("fag_a_s%d" % tv, tp, _rng.randf_range(-PI, PI), Vector3(ts, ts * 0.85, ts))
				_flock_add("fagb_a_s%d" % tv, tp, _rng.randf_range(-PI, PI), Vector3(ts, ts * 0.85, ts))
				n_tufa += 1
	_bump("pietre_mal", n_rock)
	_bump("tufe_mal", n_tufa)


# 1 + 2 ------------------------------------------------------------------ molizi

## Randuri de palcuri neregulate (3-6 arbori), 3 marimi, cu goluri; densitate care
## creste spre drum (randurile apropiate au mai putine goluri). Stanga: de la marginea
## drumului pana la 90 m (urca pe perete). Dreapta: doar unde terenul nu cade in
## albia Oltului (maluri plate), plus malul opus (dincolo de apa, la 62-110 m).
func _molizi() -> void:
	# [offset centru, prob. palc, decalaj frac, clasa marime, pas min, pas max]
	var rows_l := [
		[9.5, 0.8, 0.0, 0, 0.0024, 0.0038], [15.0, 0.92, 0.0012, 0, 0.0024, 0.0036],
		[22.0, 0.94, 0.0024, 0, 0.0024, 0.0036], [31.0, 0.94, 0.0006, 1, 0.0026, 0.0040],
		[42.0, 0.92, 0.0018, 2, 0.0028, 0.0044], [55.0, 0.88, 0.0030, 2, 0.0032, 0.0050],
		[70.0, 0.78, 0.0010, 2, 0.0036, 0.0056], [88.0, 0.66, 0.0022, 2, 0.0040, 0.0062],
	]
	var rows_r := [
		[9.5, 0.7, 0.0006, 0, 0.0030, 0.0046], [16.0, 0.8, 0.0018, 0, 0.0028, 0.0044],
		[26.0, 0.82, 0.0004, 1, 0.0030, 0.0048], [40.0, 0.8, 0.0026, 2, 0.0034, 0.0052],
		[64.0, 0.82, 0.0010, 2, 0.0034, 0.0052], [78.0, 0.76, 0.0020, 2, 0.0036, 0.0056],
		[94.0, 0.64, 0.0030, 2, 0.0042, 0.0064], [110.0, 0.5, 0.0014, 2, 0.0048, 0.0072],
	]
	var trees := 0
	var clumps := 0
	var beech_clumps := 0
	for sg: float in [-1.0, 1.0]:
		var rows := rows_l if sg < 0.0 else rows_r
		for r: Array in rows:
			var f: float = F0 + float(r[2]) - 0.004
			while f < F1 + 0.004:
				f += _rng.randf_range(float(r[4]), float(r[5]))
				if _rng.randf() > float(r[1]) * _densitate(f, sg, float(r[0])) * (0.45 if float(r[0]) > 55.0 else (0.7 if float(r[0]) > 38.0 else 1.0)):
					continue
				var off: float = float(r[0]) + _rng.randf_range(-3.5, 3.5)
				var c := _cand(f, sg, maxf(off, 8.0))
				if float(c["slope"]) > 1.1:
					_rejected += 1
					continue
				# dreapta: nu in albia raului (cota sub drum) si nu pe panta malului
				if sg > 0.0 and not _right_ok(c):
					_rejected += 1
					continue
				var sc_cls := int(r[3])
				# Poenari se vede de pe drum (ferestra 0.90-0.9786, stanga): in banda 20-45 m
				# nimic mare si 60% din palcuri cad; ruina de 28 m trebuie sa treaca peste ele
				if sg < 0.0 and f > 0.90 and float(r[0]) >= 20.0 and float(r[0]) <= 48.0:
					if _rng.randf() < 0.6:
						continue
					sc_cls = 0
				var pb := 0.04 + 0.23 * _smooth(0.74, 0.975, f)
				var is_beech := float(r[0]) >= 28.0 and _rng.randf() < pb * 0.55
				var tone_dark := _rng.randf() < 0.65
				var k := _rng.randi_range(5, 8) if float(r[0]) <= 31.0 else _rng.randi_range(4, 7)
				if is_beech:
					k = _rng.randi_range(3, 4)
				var got := 0
				for m in k:
					var pc := c
					if m > 0:
						var ang := _rng.randf() * TAU
						var rad := _rng.randf_range(1.8, 5.2)
						pc = _cand_at((c["pos"] as Vector3) + Vector3(cos(ang) * rad, 0.0, sin(ang) * rad), c)
					if not _ok(pc, 2.0, 5.5) or float(pc["slope"]) > 1.2:
						_rejected += 1
						continue
					if sg > 0.0 and not _right_ok(pc):
						continue
					got += 1
					trees += 1
					_pine(pc, sc_cls, is_beech, tone_dark)
				if got > 0:
					clumps += 1
					if is_beech:
						beech_clumps += 1
	_bump("molizi_si_fagi", trees)
	_bump("palcuri", clumps)
	_bump("palcuri_fag", beech_clumps)


## Modulatia de densitate: perete/deschidere/perete pe stanga, goluri de poiana, iar
## randurile departate (> 55 m) se rarefiaza (ceata taie oricum). 1.0 = plin.
func _densitate(f: float, sg: float, off: float) -> float:
	var m := 1.0
	if sg < 0.0:
		# doua poieni deschise spre rau/cer, cu randurile apropiate rarefiate
		if off < 40.0:
			m *= 1.0 - 0.5 * _bump_at(f, 0.7235, 0.012) - 0.45 * _bump_at(f, 0.9120, 0.014)
		if f > 0.775 and f < 0.865:
			m *= 1.1
	else:
		if off < 30.0:
			m *= 1.0 - 0.5 * _bump_at(f, 0.7300, 0.015) - 0.5 * _bump_at(f, 0.9300, 0.02)
	if off > 55.0:
		m *= 0.8
	return clampf(m, 0.0, 1.0)


## Malul drept: pe fasia de la drum pana la apa (offset < 13 m) panta coboara pana la
## -3,4 m fata de drum si e buna de planta; mai departe (albia) doar unde terenul
## urca din nou (dy > -1,2: malul opus).
func _right_ok(c: Dictionary) -> bool:
	var off: float = float(c["d"]) - float(c["half_j"])
	var dy: float = c["dy"]
	if off < 13.0:
		return dy > -3.4 and float(c["slope"]) < 0.95
	return dy > -1.2


func _bump_at(f: float, center: float, width: float) -> float:
	var x := (f - center) / width
	return exp(-x * x)


func _pine(pc: Dictionary, size_class: int, beech: bool, tone_dark: bool) -> void:
	var f: float = pc["f"]
	var sl := _slice_of(f)
	var yaw := _rng.randf_range(-PI, PI)
	var p3: Vector3 = pc["pos"]
	p3.y -= 0.15
	if beech:
		var bv := "a" if _rng.randf() < 0.5 else "b"
		var bs := _rng.randf_range(0.32, 0.55) if size_class == 0 else (_rng.randf_range(0.5, 0.8) if size_class == 1 else _rng.randf_range(0.8, 1.1))
		var b3 := Vector3(bs * _rng.randf_range(0.9, 1.1), bs * _rng.randf_range(0.9, 1.1), bs * _rng.randf_range(0.9, 1.1))
		_flock_add("fag_%s_s%d" % [bv, sl], p3, yaw, b3)
		_flock_add("fagb_%s_s%d" % [bv, sl], p3, yaw, b3)
		return
	var rr := _rng.randf()
	var v := "A" if rr < 0.3 else ("B" if rr < 0.5 else ("C" if rr < 0.7 else "D"))
	var sc := 1.0
	var pick := _rng.randf()
	match size_class:
		0:
			sc = _rng.randf_range(0.4, 0.7) if pick < 0.88 else _rng.randf_range(0.7, 0.9)
		1:
			sc = _rng.randf_range(0.75, 1.15) if pick < 0.75 else _rng.randf_range(0.5, 0.75)
		_:
			sc = _rng.randf_range(1.2, 1.75) if pick < 0.7 else _rng.randf_range(0.9, 1.2)
	# ton: palcul are tonul lui (inchis 65% / atlas 35%), cu ~25% abateri in palc
	var dark := tone_dark
	if _rng.randf() < 0.25:
		dark = not dark
	var tone := "pine" if dark else "pinem"
	var s3 := Vector3(sc * _rng.randf_range(0.85, 1.15), sc * _rng.randf_range(0.9, 1.15), sc * _rng.randf_range(0.85, 1.15))
	_flock_add("%s_%s_s%d" % [tone, v, sl], p3, yaw, s3)
	_flock_add("trunk_%s_s%d" % [v, sl], p3, yaw, s3)


# 1b ------------------------------------------------------------------ umplutura

## Stratul de umplutura (verdictul r1): molizi mici (0,3-0,6) la fiecare ~2,6 m, de la
## 4 m de margine pana la ~25 m pe stanga (si pe fasia de langa apa pe dreapta), cu
## cele 3 tonuri amestecate pe palcuri si cate o lespede mica la baza. ~230 tri/molid.
func _umplutura() -> void:
	var n := 0
	for sg: float in [-1.0, 1.0]:
		var f := F0
		while f < F1:
			f += 0.0012
			var off := 4.0
			var cl_dark := _rng.randf() < 0.62
			while off < (25.0 if sg < 0.0 else 12.0):
				var o := off + _rng.randf_range(-0.9, 0.9)
				off += _rng.randf_range(2.2, 3.2)
				if _rng.randf() < 0.24:
					continue
				var c := _cand(f + _rng.randf_range(-0.0005, 0.0005), sg, maxf(o, 3.6))
				if not _ok(c, 1.0, 3.0) or float(c["slope"]) > 1.35:
					continue
				if sg > 0.0 and not _right_ok(c):
					continue
				var dens := _densitate(f, sg, 22.0)
				if _rng.randf() > 0.35 + 0.65 * dens:
					continue
				var sc := _rng.randf_range(0.3, 0.6)
				if sg > 0.0:
					sc *= 0.85
				var p3: Vector3 = c["pos"]
				p3.y -= 0.1
				var dark := cl_dark
				if _rng.randf() < 0.3:
					dark = not dark
				var rr := _rng.randf()
				var v := "A" if rr < 0.25 else ("B" if rr < 0.6 else ("C" if rr < 0.85 else "D"))
				var sl := _slice_of(f)
				var s3 := Vector3(sc * _rng.randf_range(0.85, 1.15), sc * _rng.randf_range(0.9, 1.2), sc * _rng.randf_range(0.85, 1.15))
				var yaw := _rng.randf_range(-PI, PI)
				_flock_add("%s_%s_s%d" % ["pine" if dark else "pinem", v, sl], p3, yaw, s3)
				_flock_add("trunk_%s_s%d" % [v, sl], p3, yaw, s3)
				n += 1
				if _rng.randf() < 0.1:
					var rp := p3 + Vector3(_rng.randf_range(-1.2, 1.2), 0.0, _rng.randf_range(-1.2, 1.2))
					rp.y = _sol_real(rp.x, rp.z) - 0.1
					var rs := _rng.randf_range(0.3, 0.55)
					_flock_add("roca_s%d" % sl, rp, _rng.randf_range(-PI, PI), Vector3(rs, rs * 0.7, rs))
	_bump("umplutura_molizi_mici", n)


# 7 ------------------------------------------------------------------ fasie

## Fasia joasa de la 3,5 la ~9 m de margine, pe ambele parti: afin in pete, tufe
## rotunde mici, lame mici de sist, grohotis mic. Fara coliziune. NU jneapan.
func _fasie() -> void:
	var n := 0
	var f := F0 + 0.002
	while f < F1:
		for sg: float in [1.0, -1.0]:
			# rhythm: pete, nu covor
			if _rng.randf() < 0.78:
				continue
			for k in _rng.randi_range(1, 2):
				var c := _cand(f + _rng.randf_range(-0.0012, 0.0012), sg, _rng.randf_range(3.6, 6.0))
				if not _ok(c, 0.9, 3.2) or float(c["slope"]) > 1.0:
					continue
				if sg > 0.0 and not _right_ok(c):
					continue
				for j in _rng.randi_range(1, 3):
					var pos2: Vector3 = (c["pos"] as Vector3) + Vector3(_rng.randf_range(-1.8, 1.8), 0.0, _rng.randf_range(-1.8, 1.8))
					var c3 := _cand_at(pos2, c)
					if _ok(c3, 0.5, 3.2) and not (sg > 0.0 and not _right_ok(c3)):
						var sc2 := _rng.randf_range(1.3, 1.9)
						var pa: Vector3 = c3["pos"]
						_flock_add("afin_s%d" % _slice_of(f), pa, _rng.randf_range(-PI, PI), Vector3(sc2, sc2, sc2))
						n += 1
			if _rng.randf() < 0.45:
				var c4 := _cand(f, sg, _rng.randf_range(4.5, 9.0))
				if _ok(c4, 0.8, 3.2) and not (sg > 0.0 and not _right_ok(c4)):
					var p4: Vector3 = c4["pos"]
					p4.y -= 0.1
					var sc4 := _rng.randf_range(0.28, 0.55)
					_flock_add("roca_s%d" % _slice_of(f), p4, _rng.randf_range(-PI, PI), Vector3(sc4, sc4, sc4))
					n += 1
			if _rng.randf() < 0.0:
				var c5 := _cand(f, sg, _rng.randf_range(5.0, 9.0))
				if _ok(c5, 0.8, 3.2) and not (sg > 0.0 and not _right_ok(c5)):
					var p5: Vector3 = c5["pos"]
					p5.y -= 0.05
					var s5 := _rng.randf_range(0.25, 0.42)
					var tv := _slice_of(f)
					_flock_add("fag_a_s%d" % tv, p5, _rng.randf_range(-PI, PI), Vector3(s5, s5 * 0.85, s5))
					_flock_add("fagb_a_s%d" % tv, p5, _rng.randf_range(-PI, PI), Vector3(s5, s5 * 0.85, s5))
					n += 1
			if _rng.randf() < 0.08:
				var c6 := _cand(f, sg, _rng.randf_range(6.0, 9.0))
				if _ok(c6, 1.2, 3.2) and not (sg > 0.0 and not _right_ok(c6)):
					var p6: Vector3 = c6["pos"]
					p6.y -= 0.1
					var s6 := _rng.randf_range(0.28, 0.4)
					_flock_add("grohm_s%d" % _slice_of(f), p6, _rng.randf_range(-PI, PI), Vector3(s6, s6, s6))
					n += 1
		f += 0.0013
	_bump("fasie_piese", n)


# ------------------------------------------------------------------ emitere

func _node(nm: String, res_id: String, pos: Vector3, yaw: float, sc: float,
		nrm: Vector3 = Vector3.UP, tilt: float = 0.0, mode: String = "") -> void:
	var b := Basis(Vector3.UP, yaw)
	if tilt > 0.0 and nrm.y < 0.999:
		var axis := Vector3.UP.cross(nrm)
		if axis.length() > 0.001:
			var ang := Vector3.UP.angle_to(nrm) * tilt
			b = Basis(axis.normalized(), ang) * b
	b = b.scaled(Vector3(sc, sc, sc))
	_node_n += 1
	_nodes.append('[node name="%s" parent="%s" instance=ExtResource("%s")]' % [nm, ZONE, res_id])
	_nodes.append("transform = Transform3D(%.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.3f, %.3f, %.3f)"
		% [b.x.x, b.x.y, b.x.z, b.y.x, b.y.y, b.y.z, b.z.x, b.z.y, b.z.z, pos.x, pos.y, pos.z])
	if mode != "":
		_nodes.append('metadata/coliziune = "%s"' % mode)
	_nodes.append("")


## Lotul -> lista de {model, mesh, cls, nm} (un lot poate da 2 stoluri: ace + scoarta).
func _lot_specs(key: String) -> Array:
	var parts := key.split("_")
	match parts[0]:
		"pine":
			return [{"model": "h_pines", "mesh": "Pine_" + parts[1], "cls": "tf_jneapan", "nm": "H_Molid_%s_%s" % [parts[1], parts[2]]}]
		"pinem":
			return [{"model": "h_pines", "mesh": "Pine_" + parts[1], "cls": "", "nm": "H_MolidM_%s_%s" % [parts[1], parts[2]]}]
		"trunk":
			return [{"model": "h_pines", "mesh": "Trunk_" + parts[1], "cls": "", "nm": "H_Trunchi_%s_%s" % [parts[1], parts[2]]}]
		"fag":
			return [{"model": "h_beech_" + parts[1], "mesh": "Beech_Leaves", "cls": "tf_beech", "nm": "H_FagCoroana_%s_%s" % [parts[1], parts[2]]}]
		"fagb":
			return [{"model": "h_beech_" + parts[1], "mesh": "Beech_Bark", "cls": "", "nm": "H_FagScoarta_%s_%s" % [parts[1], parts[2]]}]
		"afin":
			return [
				{"model": "h_afin", "mesh": "Afin_Leaves", "cls": "", "nm": "H_AfinFrunze_" + parts[1]},
				{"model": "h_afin", "mesh": "Afin_Berry", "cls": "", "nm": "H_AfinBoabe_" + parts[1]},
			]
		"roca":
			return [{"model": "h_outcrop_b", "mesh": "Schist_Schist", "cls": "tf_schist", "nm": "H_RocaMica_" + parts[1]}]
		"mal":
			return [{"model": "h_outcrop_b", "mesh": "Schist_Schist", "cls": "tf_schist", "nm": "H_PiatraMal_" + parts[1]}]
		"grohm":
			return [{"model": "h_scree", "mesh": "Scree_Schist", "cls": "tf_schist", "nm": "H_GrohotisMic_" + parts[1]}]
		"perete":
			return [{"model": "h_outcrop_" + parts[1], "mesh": "Schist_Schist", "cls": "tf_schist", "nm": "H_Lespede_%s_%s" % [parts[1].to_upper(), parts[2]]}]
	return []


func _flock_text() -> String:
	var out: Array[String] = []
	for key in _flocks:
		out.append_array(_flock_block(key))
	return "\n".join(out)


func _flock_block(key: String) -> Array[String]:
	var lines: Array[String] = []
	var d: Dictionary = _flocks[key]
	var pos: PackedVector3Array = d["pos"]
	if pos.is_empty():
		return lines
	var scl: Array[Vector3] = []
	scl.assign(d["scl"])
	for spec: Dictionary in _lot_specs(key):
		lines.append('[node name="%s" type="MultiMeshInstance3D" parent="%s"]' % [spec["nm"], ZONE])
		lines.append('script = ExtResource("h_flock")')
		lines.append('model = ExtResource("%s")' % spec["model"])
		if String(spec["mesh"]) != "":
			lines.append('mesh_name = "%s"' % spec["mesh"])
		if String(spec["cls"]) != "":
			lines.append('tri_class = "%s"' % spec["cls"])
		lines.append("positions = %s" % var_to_str(pos).replace("\n", ""))
		lines.append("yaws = %s" % var_to_str(d["yaw"]).replace("\n", ""))
		lines.append("scale3_list = %s" % var_to_str(scl).replace("\n", ""))
		lines.append("")
	return lines


func _ext_lines() -> Array[String]:
	var out: Array[String] = []
	for id in MODELS:
		out.append('[ext_resource type="%s" path="%s" id="%s"]' % [MODELS[id][0], MODELS[id][1], id])
	return out


## Rescrie DOAR ZonaH si ext_resource-urile `h_*` din Track21.tscn; restul ramane
## octet cu octet (memoria `tscn-editat-de-mana-nu-se-rescrie`).
func _write_scene() -> void:
	var path := ProjectSettings.globalize_path(SCENE_PATH)
	var txt := FileAccess.get_file_as_string(path)
	var lines := txt.split("\n")
	var kept: Array[String] = []
	var skipping := false
	for ln in lines:
		var l: String = ln
		if l.begins_with('[ext_resource') and ' id="h_' in l:
			continue
		if l.begins_with("["):
			skipping = ('parent="%s"' % ZONE) in l
		if skipping:
			continue
		kept.append(l)
	var last_ext := -1
	for k in kept.size():
		if kept[k].begins_with("[ext_resource"):
			last_ext = k
	var zona_end := -1
	for k in kept.size():
		if kept[k].begins_with('[node name="ZonaH" type="Node3D" parent="DecorManual"]'):
			var m := k + 1
			while m < kept.size() and kept[m] != "":
				m += 1
			zona_end = m
	var out: Array[String] = []
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
	print("; mal drept: offsetul liniei apei (m de la marginea asfaltului)")
	var f := 0.705
	while f < 0.976:
		print("; f=%.3f  apa la %.1f  (cota apei %.1f)" % [f, _shore_off(f), _water_y(f)])
		f += 0.01


# ------------------------------------------------------------------ helpers

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


## Cota SUPRAFETEI vizibile a terenului (grila meshului), nu a coliziunii
## (memoria `terrain-mesh-y-extrapoleaza`: doar in interiorul grilei).
func _sol_real(x: float, z: float) -> float:
	return _track._terrain_mesh_y(x, z)
