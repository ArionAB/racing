extends Node
## Generator de decor MANUAL pentru POI E — IESIREA DIN TUNEL SI LACUL BALEA Transfagarasan
## (Track21, frac 0.3171-0.372, semi 6,0 in tunel / 7,0). Nu e sonda: MASOARA terenul real
## (meshul terenului) si CALCULEAZA nodurile care se lipesc in Track21.tscn sub
## `DecorManual/ZonaE`.
##
##   godot --headless --path . res://tools/GenDecorTfE.tscn -- --survey
##   godot --headless --path . res://tools/GenDecorTfE.tscn -- --emit    (tipareste)
##   godot --headless --path . res://tools/GenDecorTfE.tscn -- --write   (rescrie ZonaE)
##
## ---------------------------------------------------------------------------
## LISTA DE ELEMENTE (runda 1) — din decupajul `E.png` (+ CREASTA/ORIZONT pentru dezvaluire),
## cu cifrele fisei (`### E` din transfagarasan_poi_gauntlet.md), fiecare legat de o piesa.
##
## Ce arata decupajul (MATERIA, nu layoutul): o cabana de piatra si lemn cu acoperis abrupt
## de tabla gri, pe o terasa de pamant batut la marginea unui lac verde-albastrui rece; o
## ROANDA de 5-6 masini colorate (albastru/rosu/alb) parcate in fata ei, o tarabe de lemn cu
## acoperis lateral langa cabana; molizi verde-negru in coloane ascutite, in grupuri de 2-4,
## in 3 marimi; peste drum, pe versantul de jos, petice mari de BUJOR MAGENTA pe iarba scurta cu
## zapada la margini; versantul de sus gri-verzui in lame inclinate, cu zapada veche in
## straturi; aflorimente mici de piatra pe malul lacului.
##
##  #  element                      cifra   piesa (GLB)                        cum
##  1  cabana Balea Lac             1       buildings/cabana_balea_lac         nod, hull, fata spre drum (-Z)
##  2  masini parcate               6       vehicles/parked_car_a (albastra)   noduri, hull, in rand pe terasa
##                                          vehicles/parked_car_b (rosie)      (nas spre cabana, unghi variat)
##  3  motociclete                  3       vehicles/motorbike                 noduri, hull, langa rand
##  4  tarabe                       4       props/souvenir_stall               noduri, hull, fata spre drum
##  5  aflorimente de sist          ~8      rocks/schist_outcrop_a/b/c         noduri, hull: versantul stang
##                                                                              + buza lacului
##  6  conuri de grohotis           2       rocks/scree_cone                   noduri, fara coliziune
##  7  molizi, masa (3 tonuri)      ~350    trees/alpine_pines Pine_A..D       MultiMesh feliat, ace pe
##     (rand 1-3, 3 marimi)                 (+ Trunk_A..D)                     tf_jneapan 55% / atlas 30% /
##                                          + plants/beech_tree_a/b (15%)      fagi 15% (tf_beech), in palcuri
##  8  fasie joasa 3,5-9 m          ~250    plants/jneapan_a/b, afin,          MultiMesh, fara coliziune
##     (jneapan ~10 palcuri, afin,          schist_outcrop_b mic, scree mic
##      sist mic)
##  9  petice de bujor magenta      6       plants/bujor_de_munte (x6-8/petic) MultiMesh, atint:tf_bloom
## 10  zapada veche pe versant      12 pet. structures/snow_wall (SnowWall_B)  MultiMesh, pe ATLAS (tri_class ""),
##                                                                              ingropata 35-50%
## 11  telecabina, lac, apa, tunel, portaluri: NU sunt ale mele (fundatie/integrare)
## 12  corbi (raven), cable_car_station: nu — material nou / piesa de integrare
##
## Densitate spre drum: 0-10 m de MARGINE = fasia joasa (nimic cu coliziune); 10-30 m =
## cabana, masinile, tarabele, randurile 1-2 de molizi pe VERSANTUL STANG, bujori; 30-60 m =
## versantul cu zapada, aflorimente, randurile 3-4. DEZVALUIREA (f 0.358-0.372): pe DREAPTA
## drumului nimic peste ~1,5 m (nici molizi, nici cabana in axa spre F); copacii stau pe stanga.

const TRACK := "res://scenes/tracks/Track21.tscn"
const SCENE_PATH := "res://scenes/tracks/Track21.tscn"
const ZONE := "DecorManual/ZonaE"
const F0 := 0.3171
const F1 := 0.372
## Tunelul (portalul N la 0.3499): nimic decorat inauntru. Vegetatia incepe la portal.
const F_TUNEL_END := 0.3499
## De la ce fractie dreapta drumului ramane joasa (dezvaluirea serpentinelor F).
const F_REVEAL := 0.357
## Cabana: fractia si offsetul de la marginea asfaltului (dreapta).
const CABANA_F := 0.3625
const CABANA_OFF := 14.0

const MODELS := {
	"e_flock": ["Script", "res://scenes/props/flock.gd"],
	"e_pines": ["PackedScene", "res://assets/models/trees/alpine_pines.glb"],
	"e_beech_a": ["PackedScene", "res://assets/models/transfagarasan/plants/beech_tree_a.glb"],
	"e_beech_b": ["PackedScene", "res://assets/models/transfagarasan/plants/beech_tree_b.glb"],
	"e_jneapan_a": ["PackedScene", "res://assets/models/transfagarasan/plants/jneapan_a.glb"],
	"e_jneapan_b": ["PackedScene", "res://assets/models/transfagarasan/plants/jneapan_b.glb"],
	"e_afin": ["PackedScene", "res://assets/models/transfagarasan/plants/afin.glb"],
	"e_bujor": ["PackedScene", "res://assets/models/transfagarasan/plants/bujor_de_munte.glb"],
	"e_outcrop_a": ["PackedScene", "res://assets/models/transfagarasan/rocks/schist_outcrop_a.glb"],
	"e_outcrop_b": ["PackedScene", "res://assets/models/transfagarasan/rocks/schist_outcrop_b.glb"],
	"e_outcrop_c": ["PackedScene", "res://assets/models/transfagarasan/rocks/schist_outcrop_c.glb"],
	"e_scree": ["PackedScene", "res://assets/models/transfagarasan/rocks/scree_cone.glb"],
	"e_cabana": ["PackedScene", "res://assets/models/transfagarasan/buildings/cabana_balea_lac.glb"],
	"e_car_a": ["PackedScene", "res://assets/models/transfagarasan/vehicles/parked_car_a.glb"],
	"e_car_b": ["PackedScene", "res://assets/models/transfagarasan/vehicles/parked_car_b.glb"],
	"e_moto": ["PackedScene", "res://assets/models/transfagarasan/vehicles/motorbike.glb"],
	"e_stall": ["PackedScene", "res://assets/models/transfagarasan/props/souvenir_stall.glb"],
	"e_snow_wall": ["PackedScene", "res://assets/models/transfagarasan/structures/snow_wall.glb"],
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
## obstacole cu coliziune puse de mine (x, z, raza) + piesele montate din vecinatate
var _solid: Array[Vector3] = []
var _montate: Array[Vector3] = []
var _cabana_pos := Vector3.ZERO
var _terasa: Array[Vector3] = []


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
	_rng.seed = 317372
	_collect_montate()
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


## Piesele montate de fundatie la < 60 m de zona (Jalon, Portal_N, ZidC): le evit.
func _collect_montate() -> void:
	var dm := _track.get_node_or_null("DecorManual")
	if dm == null:
		return
	for zn in dm.get_children():
		if zn.name == &"ZonaE" or zn.name.begins_with("Zona") and String(zn.name).length() == 5:
			continue
		for c in zn.get_children():
			if c is Node3D:
				_montate.append(Vector3((c as Node3D).global_position.x, 0.0, (c as Node3D).global_position.z))
		if zn is Node3D:
			_montate.append(Vector3((zn as Node3D).global_position.x, 0.0, (zn as Node3D).global_position.z))


# ------------------------------------------------------------------ constructie

func _build() -> void:
	_cabana_si_terasa()
	_roci()
	_grohotis()
	_molizi()
	_fasie()
	_bujor()
	_zapada()
	var tot := 0
	for k in _count:
		tot += int(_count[k])
	print("; ZonaE: %d piese asezate, %d respinse de garzi" % [tot, _rejected])
	for k in _count:
		print(";   %s: %d" % [k, _count[k]])
	for k in _flocks:
		print(";   lot %s: %d instante" % [k, (_flocks[k]["pos"] as PackedVector3Array).size()])


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
	d["dy_road"] = q.y - _track.baked[near["i"]].y
	d["slope"] = slope
	d["nrm"] = nrm
	d["rp"] = near["p"]
	# lateralul semnat fata de drum: >0 dreapta
	var s2 := _track._side_at(int(near["i"]))
	d["lat"] = (q.x - (near["p"] as Vector3).x) * s2.x + (q.z - (near["p"] as Vector3).z) * s2.z
	return d


## Garzile comune. `margin` = cat de departe de MARGINEA asfaltului (m), `r` = raza piesei.
func _ok(c: Dictionary, r: float, margin: float) -> bool:
	var q: Vector3 = c["pos"]
	if is_nan(q.y):
		return false
	if float(c["d"]) < float(c["half_j"]) + margin + r:
		return false
	for m in _montate:
		if Vector2(q.x - m.x, q.z - m.z).length() < 3.0 + r:
			return false
	for s in _solid:
		if Vector2(q.x - s.x, q.z - s.z).length() < s.y + r:
			return false
	return true


func _y_garda(x: float, z: float, y: float) -> float:
	var g: float = _sampler.ground_y(x, z)
	return clampf(y, g - 1.8, g + 2.8)


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


func _slice_of(f: float) -> int:
	return clampi(int((f - F0) / (F1 - F0) * 3.0), 0, 2)


func _put(key: String, n: int = 1) -> void:
	_count[key] = int(_count.get(key, 0)) + n


func _face(from: Vector3, to: Vector3) -> float:
	var d := Vector2(to.x - from.x, to.z - from.z).normalized()
	return atan2(-d.x, -d.y)


# 1-4 ------------------------------------------------------------------ cabana + terasa

## Terasa (lasata de relief) e o banda plata pe dreapta drumului, f 0.357-0.372, ~(185-204, -179..-200).
## Cabana sta pe marginea dinspre lac; masinile in rand intre ea si drum; tarabele spre amonte.
func _cabana_si_terasa() -> void:
	var cc := _cand(CABANA_F, 1.0, CABANA_OFF)
	var cp: Vector3 = cc["pos"]
	var rc := _nearest_road(cp)
	var road_pt: Vector3 = rc["p"]
	var yaw := _face(cp, road_pt)
	var pos := Vector3(cp.x, _sol_real(cp.x, cp.z) - 0.15, cp.z)
	pos.y = _y_garda(pos.x, pos.z, pos.y)
	_cabana_pos = pos
	_node("E_Cabana", "e_cabana", pos, yaw, 1.0)
	_solid.append(Vector3(pos.x, 8.0, 0.0))
	_put("cabana")
	print("; cabana la (%.1f, %.1f, %.1f) yaw %.2f, d axa %.1f m slope %.2f" % [pos.x, pos.y, pos.z, yaw, float(rc["d"]), float(cc["slope"])])
	var fd := Vector3(road_pt.x - pos.x, 0.0, road_pt.z - pos.z).normalized()
	var sd := Vector3(-fd.z, 0.0, fd.x)
	# masini: in rand pe marginea drumului (nas-in oblic), pe fractie, ocolind capatul scarii cabanei
	var k := 0
	var fs := [0.3566, 0.3586, 0.3606, 0.3628, 0.3650, 0.3672]
	for j in fs.size():
		var c := _cand(float(fs[j]), 1.0, 4.5 + _rng.randf_range(0.0, 0.5))
		var q: Vector3 = c["pos"]
		if is_nan(q.y) or float(c["d"]) < float(c["half_j"]) + 3.0 + 1.1 or float(c["slope"]) > 0.6:
			print("; masina j%d respinsa: d=%.1f margine %.1f sl %.2f" % [j, float(c["d"]), float(c["d"]) - float(c["half_j"]), float(c["slope"])])
			_rejected += 1
			continue
		k += 1
		# paralel cu drumul (tangenta) cu un unghi oblic variat
		var i := int(c["j"])
		var tg := (_track.baked[mini(i + 1, _track.baked.size() - 1)] - _track.baked[maxi(i - 1, 0)])
		var base_yaw := atan2(-tg.x, -tg.z)
		var y := base_yaw + (0.38 if j % 2 == 0 else -0.30) + _rng.randf_range(-0.1, 0.1)
		var p3 := q
		p3.y = _y_garda(q.x, q.z, q.y - 0.02)
		_node("E_Masina%d" % k, "e_car_" + ("a" if j % 2 == 0 else "b"), p3, y, 1.0, c["nrm"], 0.9)
		_solid.append(Vector3(q.x, 2.4, 0.0))
		_put("masini")
		print(";   masina %d la (%.1f, %.1f) margine %.1f dy %.2f sl %.2f" % [k, q.x, q.z, float(c["d"]) - float(c["half_j"]), float(c["dy_road"]), float(c["slope"])])
	# motociclete: 3, la capetele randului
	var mf := [[0.3552, 4.2, 0.5], [0.3556, 6.6, -0.4], [0.3693, 4.4, 0.9]]
	k = 0
	for mt: Array in mf:
		var c := _cand(float(mt[0]), 1.0, float(mt[1]))
		var q: Vector3 = c["pos"]
		if is_nan(q.y) or float(c["d"]) < float(c["half_j"]) + 3.0 + 0.8 or not _ok(c, 1.0, 3.0):
			print("; moto respinsa la (%.1f, %.1f)" % [q.x, q.z])
			_rejected += 1
			continue
		k += 1
		var p3 := q
		p3.y = _y_garda(q.x, q.z, q.y - 0.02)
		var i2 := int(c["j"])
		var tg2 := (_track.baked[mini(i2 + 1, _track.baked.size() - 1)] - _track.baked[maxi(i2 - 1, 0)])
		_node("E_Moto%d" % k, "e_moto", p3, atan2(-tg2.x, -tg2.z) + float(mt[2]), 1.0, c["nrm"], 0.9)
		_solid.append(Vector3(q.x, 1.4, 0.0))
		_put("motociclete")
	# tarabe: 4, in sir pe flancul cabanei dinspre amonte, fata spre drum
	var stalls := [[-11.0, 2.5], [-11.4, -1.6], [-10.8, -5.6], [11.5, 1.0]]
	k = 0
	for st: Array in stalls:
		var p := pos + sd * float(st[0]) + fd * float(st[1])
		var c := _cand_at(p, {"f": 0.36, "sg": 1.0})
		var q: Vector3 = c["pos"]
		if is_nan(q.y) or float(c["d"]) < float(c["half_j"]) + 3.0 + 2.0 or float(c["slope"]) > 0.5 or not _ok(c, 2.0, 3.0):
			print("; taraba respinsa la (%.1f, %.1f) d=%.1f sl=%.2f" % [q.x, q.z, float(c["d"]), float(c["slope"])])
			_rejected += 1
			continue
		k += 1
		var p3 := q
		p3.y = _y_garda(q.x, q.z, q.y - 0.02)
		_node("E_Taraba%d" % k, "e_stall", p3, _face(q, road_pt) + _rng.randf_range(-0.12, 0.12), 1.0, c["nrm"], 0.9)
		_solid.append(Vector3(q.x, 2.4, 0.0))
		_put("tarabe")
		print(";   taraba %d la (%.1f, %.1f) d axa %.1f" % [k, q.x, q.z, float(c["d"])])
	_terasa.append(pos)


# 5 ------------------------------------------------------------------ roci

## Aflorimente: pe versantul STANG la 3,5-12 m de margine (primul rand cu coliziune), grupuri de 2-3,
## si pe buza lacului. Lame inclinate (tilt pe normala).
func _roci() -> void:
	var total := 0
	# [frac, latura, offset, scara, model]
	var specs := [
		[0.3515, -1.0, 4.5, 1.35, "a"], [0.3535, -1.0, 7.5, 1.0, "c"], [0.3562, -1.0, 4.0, 1.1, "b"],
		[0.3592, -1.0, 6.0, 0.95, "a"], [0.3622, -1.0, 4.5, 1.15, "c"], [0.3655, -1.0, 4.8, 1.0, "b"],
		[0.3510, 1.0, 6.5, 1.1, "b"], [0.3552, 1.0, 5.0, 0.9, "a"],
	]
	for s: Array in specs:
		var c := _cand(float(s[0]), float(s[1]), float(s[2]))
		var sc: float = float(s[3])
		if not _ok(c, 2.8 * sc, 3.2):
			_rejected += 1
			continue
		var p3: Vector3 = c["pos"]
		p3.y = _y_garda(p3.x, p3.z, p3.y - 0.4 * sc)
		total += 1
		_node("E_Aflor%02d" % total, "e_outcrop_" + String(s[4]), p3, _rng.randf_range(-PI, PI), sc, c["nrm"], 0.55)
		_solid.append(Vector3(p3.x, 2.2 * sc, 0.0))
		_put("aflorimente")
	# buza lacului (est de terasa): 3 lame mici, cu coliziune
	var lip := [[207.5, -186.0, 1.1, "b"], [208.5, -192.0, 1.4, "a"], [206.0, -197.5, 1.0, "c"]]
	for s: Array in lip:
		var c := _cand_at(Vector3(float(s[0]), 0.0, float(s[1])), {"f": 0.362, "sg": 1.0})
		var sc: float = float(s[2])
		if not _ok(c, 2.5 * sc, 3.0):
			_rejected += 1
			continue
		var p3: Vector3 = c["pos"]
		p3.y = _y_garda(p3.x, p3.z, p3.y - 0.45 * sc)
		total += 1
		_node("E_Aflor%02d" % total, "e_outcrop_" + String(s[3]), p3, _rng.randf_range(-PI, PI), sc, c["nrm"], 0.45)
		_solid.append(Vector3(p3.x, 2.2 * sc, 0.0))
		_put("aflorimente")


func _grohotis() -> void:
	# un con la piciorul versantului stang, langa portal, unul pe buza lacului
	var specs := [[0.3535, -1.0, 15.0], [0.3615, 1.0, 26.0]]
	var k := 0
	for s: Array in specs:
		var c := _cand(float(s[0]), float(s[1]), float(s[2]))
		if not _ok(c, 3.5, 3.5):
			_rejected += 1
			continue
		var q: Vector3 = c["pos"]
		var rp: Vector3 = c["rp"]
		k += 1
		var p3 := q
		p3.y = _y_garda(p3.x, p3.z, p3.y - 0.4)
		# latura plata spre stanca: invers fata de drum
		_node("E_Grohotis%02d" % k, "e_scree", p3, _face(q, rp) + PI, _rng.randf_range(0.9, 1.15), c["nrm"], 0.7, "none")
		_put("grohotis")


# 7 ------------------------------------------------------------------ molizi

## Palcuri neregulate de 3-6 molizi, 3 marimi. Versantul STANG (-1) pe toata zona de dupa
## portal; DREAPTA (+1) doar inainte de dezvaluire (f < F_REVEAL) si in spatele terasei/cabanei,
## departe (> 30 m), ca sa nu acopere serpentinele.
func _molizi() -> void:
	# [offset centru de la margine, prob. palc, decalaj frac, clasa marime]
	var rows := [
		[9.0, 0.6, 0.0, 0], [14.0, 0.9, 0.0010, 0], [21.0, 0.92, 0.0020, 0],
		[30.0, 0.92, 0.0005, 1], [41.0, 0.92, 0.0015, 2], [54.0, 0.9, 0.0028, 2],
		[70.0, 0.88, 0.0008, 2],
	]
	var trees := 0
	var clumps := 0
	for sg: float in [-1.0, 1.0]:
		for r: Array in rows:
			var f: float = F_TUNEL_END - 0.004 + float(r[2])
			while f < F1 + 0.004:
				f += _rng.randf_range(0.0017, 0.0028)
				if _rng.randf() > float(r[1]):
					continue
				# dreapta: doar inainte de dezvaluire (f < F_REVEAL), sau departe de drum (> 36 m) in spatele cabanei
				if sg > 0.0 and f > F_REVEAL and float(r[0]) < 36.0:
					continue
				var off: float = float(r[0]) + _rng.randf_range(-3.0, 3.0)
				var c := _cand(f, sg, maxf(off, 7.0))
				if float(c["slope"]) > 1.2:
					_rejected += 1
					continue
				var k := _rng.randi_range(3, 6)
				var beech := float(r[0]) <= 45.0 and _rng.randf() < 0.15
				if beech:
					k = _rng.randi_range(3, 4)
				var got := 0
				for m in k:
					var pc := c
					if m > 0:
						var ang := _rng.randf() * TAU
						var rad := _rng.randf_range(1.8, 5.0)
						pc = _cand_at((c["pos"] as Vector3) + Vector3(cos(ang) * rad, 0.0, sin(ang) * rad), c)
					if not _ok(pc, 2.0, 5.5) or float(pc["slope"]) > 1.3:
						_rejected += 1
						continue
					# nimic peste terasa / aproape de cabana (nu-i acoperi fata)
					var qp: Vector3 = pc["pos"]
					if _cabana_pos != Vector3.ZERO and Vector2(qp.x - _cabana_pos.x, qp.z - _cabana_pos.z).length() < 13.0 + 3.0 * float(r[3]):
						_rejected += 1
						continue
					got += 1
					trees += 1
					_pine(pc, int(r[3]), beech)
				if got > 0:
					clumps += 1
	_count["molizi"] = trees
	_count["palcuri_molizi"] = clumps


func _pine(pc: Dictionary, size_class: int, beech: bool = false) -> void:
	var f: float = pc["f"]
	var sl := _slice_of(f)
	var yaw := _rng.randf_range(-PI, PI)
	var p3: Vector3 = pc["pos"]
	p3.y -= 0.15
	if beech:
		var bv := "a" if _rng.randf() < 0.5 else "b"
		var bs := _rng.randf_range(0.5, 0.9)
		var b3 := Vector3(bs * _rng.randf_range(0.9, 1.1), bs * _rng.randf_range(0.9, 1.1), bs * _rng.randf_range(0.9, 1.1))
		_flock_add("fag_%s_s%d" % [bv, sl], p3, yaw, b3)
		return
	var rr := _rng.randf()
	var v := "A" if rr < 0.25 else ("B" if rr < 0.6 else ("C" if rr < 0.85 else "D"))
	var sc := 1.0
	var pick := _rng.randf()
	match size_class:
		0:
			sc = _rng.randf_range(0.4, 0.7) if pick < 0.88 else _rng.randf_range(0.7, 0.9)
		1:
			sc = _rng.randf_range(0.75, 1.15) if pick < 0.75 else _rng.randf_range(0.5, 0.75)
		_:
			sc = _rng.randf_range(1.2, 1.75) if pick < 0.7 else _rng.randf_range(0.9, 1.2)
	# ton: ~65% inchis (tf_jneapan) / ~35% atlas pe molizi (restul de 15% din total sunt fagii)
	var tone := "pine" if _rng.randf() < 0.65 else "pinem"
	var s3 := Vector3(sc * _rng.randf_range(0.85, 1.15), sc * _rng.randf_range(0.9, 1.15), sc * _rng.randf_range(0.85, 1.15))
	_flock_add("%s_%s_s%d" % [tone, v, sl], p3, yaw, s3)
	_flock_add("trunk_%s_s%d" % [v, sl], p3, yaw, s3)


# 8 ------------------------------------------------------------------ fasie

## Fasia joasa de la 3,5 la ~9 m de margine, ambele parti, de la portal pana la capat: jneapan
## culcat in palcuri (~10), afin, lame mici de sist. Fara coliziune; pe dreapta ramane joasa.
func _fasie() -> void:
	var n := 0
	var f := F_TUNEL_END
	while f < F1:
		for sg: float in [1.0, -1.0]:
			for k in _rng.randi_range(1, 2):
				var c := _cand(f + _rng.randf_range(-0.0014, 0.0014), sg, _rng.randf_range(3.5, 9.0))
				if not _ok(c, 1.0, 3.2) or float(c["slope"]) > 1.2:
					continue
				var v := "a" if _rng.randf() < 0.5 else "b"
				var sc := _rng.randf_range(0.7, 1.1)
				var p3: Vector3 = c["pos"]
				p3.y -= 0.05
				_flock_add("jn_%s_s%d" % [v, _slice_of(f)], p3, _rng.randf_range(-PI, PI), Vector3(sc, sc * 0.9, sc))
				n += 1
			if _rng.randf() < 0.75:
				var c2 := _cand(f, sg, _rng.randf_range(4.0, 9.0))
				if _ok(c2, 0.6, 3.2):
					for j in _rng.randi_range(2, 3):
						var pos2: Vector3 = (c2["pos"] as Vector3) + Vector3(_rng.randf_range(-1.6, 1.6), 0.0, _rng.randf_range(-1.6, 1.6))
						var c3 := _cand_at(pos2, c2)
						if _ok(c3, 0.5, 3.2):
							var sc2 := _rng.randf_range(1.3, 1.8)
							_flock_add("afin_s%d" % _slice_of(f), c3["pos"], _rng.randf_range(-PI, PI), Vector3(sc2, sc2, sc2))
							n += 1
			if _rng.randf() < 0.5:
				var c4 := _cand(f, sg, _rng.randf_range(4.5, 9.0))
				if _ok(c4, 0.8, 3.2):
					var p4: Vector3 = c4["pos"]
					p4.y -= 0.12
					var sc4 := _rng.randf_range(0.28, 0.5)
					_flock_add("roca_s%d" % _slice_of(f), p4, _rng.randf_range(-PI, PI), Vector3(sc4, sc4, sc4))
					n += 1
		f += 0.0014
	# ~10 palcuri de jneapan mai deschisi, 10-26 m, pe terasa si versant (accent de pajiste)
	var pal := 0
	var guard := 0
	while pal < 10 and guard < 4000:
		guard += 1
		var ff := _rng.randf_range(F_TUNEL_END, F1)
		var sg2 := 1.0 if _rng.randf() < 0.5 else -1.0
		var c := _cand(ff, sg2, _rng.randf_range(10.0, 26.0))
		if not _ok(c, 3.0, 5.0) or float(c["slope"]) > 1.0:
			continue
		for m in _rng.randi_range(6, 10):
			var ang := _rng.randf() * TAU
			var rad := sqrt(_rng.randf()) * 3.4
			var pc := _cand_at((c["pos"] as Vector3) + Vector3(cos(ang) * rad, 0.0, sin(ang) * rad), c)
			if not _ok(pc, 0.8, 4.0):
				continue
			var v2 := "a" if _rng.randf() < 0.5 else "b"
			var sc3 := _rng.randf_range(0.8, 1.35)
			var p5: Vector3 = pc["pos"]
			p5.y -= 0.05
			_flock_add("jn_%s_s%d" % [v2, _slice_of(ff)], p5, _rng.randf_range(-PI, PI), Vector3(sc3, sc3 * 0.9, sc3))
			n += 1
		pal += 1
	_count["fasie_piese"] = n
	_count["palcuri_jneapan"] = pal


# 9 ------------------------------------------------------------------ bujor

func _bujor() -> void:
	# 6 petice (frac, latura, offset) — accentul magenta, doua mari spre terasa/versantul de jos
	var specs := [[0.3512, 1.0, 8.5], [0.3535, -1.0, 9.0], [0.3575, 1.0, 11.0],
		[0.3600, 1.0, 8.0], [0.3640, 1.0, 9.5], [0.3665, 1.0, 7.0]]
	var patches := 0
	for s: Array in specs:
		var c := _cand(float(s[0]), float(s[1]), float(s[2]))
		if not _ok(c, 2.0, 3.0):
			_rejected += 1
			continue
		var k := _rng.randi_range(6, 9)
		for m in k:
			var ang := _rng.randf() * TAU
			var rad := sqrt(_rng.randf()) * 2.2
			var pc := _cand_at((c["pos"] as Vector3) + Vector3(cos(ang) * rad, 0.0, sin(ang) * rad), c)
			if not _ok(pc, 0.8, 3.0):
				continue
			var sc := _rng.randf_range(1.5, 2.2)
			var p3: Vector3 = pc["pos"]
			p3.y -= 0.03
			_flock_add("bujor_s%d" % _slice_of(float(s[0])), p3, _rng.randf_range(-PI, PI), Vector3(sc, sc, sc))
		for m in 3:
			var ang2 := _rng.randf() * TAU
			var rad2 := 2.4 + _rng.randf() * 1.6
			var pc2 := _cand_at((c["pos"] as Vector3) + Vector3(cos(ang2) * rad2, 0.0, sin(ang2) * rad2), c)
			if _ok(pc2, 0.5, 3.0):
				var sc2 := _rng.randf_range(1.3, 1.8)
				_flock_add("afin_s%d" % _slice_of(float(s[0])), pc2["pos"], _rng.randf_range(-PI, PI), Vector3(sc2, sc2, sc2))
		patches += 1
	_count["petice_bujor"] = patches


# 10 ----------------------------------------------------------------- zapada

## Zapada veche pe versant: SnowWall_B_Snow pe ATLAS, ingropata 35-50% (calota cu trepte), lungimea pe
## curba de nivel. 12 petice de 3 banci: 8 pe versantul stang (sus) + 4 pe buza de nord a caldarii (dreapta).
func _snow_lump(pc: Dictionary, big: bool) -> void:
	var nrm: Vector3 = pc["nrm"]
	var cx := -nrm.z
	var cz := nrm.x
	var yaw := _rng.randf_range(-PI, PI)
	if Vector2(cx, cz).length() > 0.05:
		yaw = atan2(cx, cz) + _rng.randf_range(-0.4, 0.4)
	var sy := _rng.randf_range(1.3, 2.1) if big else _rng.randf_range(0.8, 1.3)
	var sx := _rng.randf_range(1.6, 2.6) if big else _rng.randf_range(1.0, 1.8)
	var sz := _rng.randf_range(0.9, 1.5) if big else _rng.randf_range(0.5, 0.9)
	var p3: Vector3 = pc["pos"]
	p3.y -= 3.02 * sy * _rng.randf_range(0.35, 0.5)
	_flock_add("snow_s%d" % _slice_of(float(pc["f"])), p3, yaw, Vector3(sx, sy, sz))
	_put("banci_zapada")


func _zapada() -> void:
	var groups := 0
	var guard := 0
	while groups < 12 and guard < 12000:
		guard += 1
		var f := _rng.randf_range(F_TUNEL_END, F1 - 0.004)
		var sg := -1.0 if groups < 8 else 1.0
		# sus pe versant: la 14-40 m de margine, panta mai mare
		var c := _cand(f, sg, _rng.randf_range(14.0, 40.0) if sg < 0.0 else _rng.randf_range(24.0, 44.0))
		if not _ok(c, 3.0, 8.0) or float(c["slope"]) < 0.25 or float(c["slope"]) > 1.4:
			continue
		if sg > 0.0 and f > F_REVEAL and float(c["d"]) < 36.0:
			continue
		var cp: Vector3 = c["pos"]
		for m in 3:
			var ang := _rng.randf() * TAU
			var rad := _rng.randf_range(0.0, 3.8) if m > 0 else 0.0
			var pc := _cand_at(cp + Vector3(cos(ang) * rad, 0.0, sin(ang) * rad), c)
			if not _ok(pc, 1.8, 6.0):
				continue
			_snow_lump(pc, m == 0)
		groups += 1
	_count["petice_zapada"] = groups


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
	_nodes.append('[node name="%s" parent="%s" instance=ExtResource("%s")]' % [nm, ZONE, res_id])
	_nodes.append("transform = Transform3D(%.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.3f, %.3f, %.3f)"
		% [b.x.x, b.x.y, b.x.z, b.y.x, b.y.y, b.y.z, b.z.x, b.z.y, b.z.z, pos.x, pos.y, pos.z])
	if mode != "":
		_nodes.append('metadata/coliziune = "%s"' % mode)
	_nodes.append("")


func _lot_specs(key: String) -> Array:
	var parts := key.split("_")
	match parts[0]:
		"pine":
			return [{"model": "e_pines", "mesh": "Pine_" + parts[1], "cls": "tf_jneapan", "nm": "E_Molid_%s_%s" % [parts[1], parts[2]]}]
		"pinem":
			return [{"model": "e_pines", "mesh": "Pine_" + parts[1], "cls": "", "nm": "E_MolidM_%s_%s" % [parts[1], parts[2]]}]
		"fag":
			return [
				{"model": "e_beech_" + parts[1], "mesh": "Beech_Bark", "cls": "", "nm": "E_FagScoarta_%s_%s" % [parts[1], parts[2]]},
				{"model": "e_beech_" + parts[1], "mesh": "Beech_Leaves", "cls": "tf_beech", "nm": "E_FagCoroana_%s_%s" % [parts[1], parts[2]]},
			]
		"trunk":
			return [{"model": "e_pines", "mesh": "Trunk_" + parts[1], "cls": "", "nm": "E_Trunchi_%s_%s" % [parts[1], parts[2]]}]
		"jn":
			return [
				{"model": "e_jneapan_" + parts[1], "mesh": "Jneapan_Needles", "cls": "tf_jneapan", "nm": "E_JnAce_%s_%s" % [parts[1], parts[2]]},
				{"model": "e_jneapan_" + parts[1], "mesh": "Jneapan_Bark", "cls": "tf_jneapan", "nm": "E_JnScoarta_%s_%s" % [parts[1], parts[2]]},
			]
		"afin":
			return [
				{"model": "e_afin", "mesh": "Afin_Leaves", "cls": "", "nm": "E_AfinFrunze_" + parts[1]},
				{"model": "e_afin", "mesh": "Afin_Berry", "cls": "", "nm": "E_AfinBoabe_" + parts[1]},
			]
		"roca":
			return [{"model": "e_outcrop_b", "mesh": "Schist_Schist", "cls": "tf_schist", "nm": "E_RocaMica_" + parts[1]}]
		"bujor":
			return [
				{"model": "e_bujor", "mesh": "Bujor_Bloom", "cls": "atint:tf_bloom", "nm": "E_BujorFloare_" + parts[1]},
				{"model": "e_bujor", "mesh": "Bujor_Leaves", "cls": "", "nm": "E_BujorFrunze_" + parts[1]},
			]
		"snow":
			return [{"model": "e_snow_wall", "mesh": "SnowWall_B_Snow", "cls": "", "nm": "E_Banc_" + parts[1]}]
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
		lines.append('script = ExtResource("e_flock")')
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


## Rescrie DOAR ZonaE si ext_resource-urile `e_*` din Track21.tscn; restul ramane octet cu octet.
func _write_scene() -> void:
	var path := ProjectSettings.globalize_path(SCENE_PATH)
	var txt := FileAccess.get_file_as_string(path)
	var lines := txt.split("\n")
	var kept: Array[String] = []
	var skipping := false
	for ln in lines:
		var l: String = ln
		if l.begins_with('[ext_resource') and ' id="e_' in l:
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
		if kept[k].begins_with('[node name="ZonaE" type="Node3D" parent="DecorManual"]'):
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
	print("; scris %s (%d noduri de instanta, %d loturi MultiMesh)" % [path, _nodes.size() / 3, _flocks.size()])


# ------------------------------------------------------------------ survey

func _survey() -> void:
	var n := _track.baked.size()
	print("; montate in apropiere: %d" % _montate.size())
	for f in [0.3499, 0.355, 0.36, 0.365, 0.3686, 0.372]:
		var i := int(f * n)
		var p := _track.baked[i]
		print("f %.4f (%.1f, %.1f, %.1f) half %.1f" % [f, p.x, p.y, p.z, _track.width_at_index(i)])


# ------------------------------------------------------------------ helpers

func _nearest_road(q: Vector3) -> Dictionary:
	var best := 1e9
	var bi := _i_lo
	var n := _track.baked.size()
	var bp := Vector3.ZERO
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
			bp = Vector3(a.x + abx * t, a.y, a.z + abz * t)
	return {"d": sqrt(best), "i": bi, "p": bp}


func _sol_real(x: float, z: float) -> float:
	return _track._terrain_mesh_y(x, z)
