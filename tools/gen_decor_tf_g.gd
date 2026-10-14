extends Node
## Generator de decor MANUAL pentru POI G — BALEA CASCADA Transfagarasan
## (Track21, frac 0.6268-0.7036, semi 7,0). Nu e sonda: MASOARA terenul real
## (raycast pe TerrainBody) si CALCULEAZA nodurile care se lipesc in
## Track21.tscn sub `DecorManual/ZonaG`.
##
##   godot --headless --path . res://tools/GenDecorTfG.tscn -- --survey
##   godot --headless --path . res://tools/GenDecorTfG.tscn -- --emit    (tipareste)
##   godot --headless --path . res://tools/GenDecorTfG.tscn -- --write   (rescrie ZonaG)
##
## ---------------------------------------------------------------------------
## LISTA DE ELEMENTE (runda 1; runda 2: 3 tonuri de molid 65 inchis/35 atlas + palcuri de fag 17%, molizi mici 0,4-0,7 in primii 25 m, gramezi de 3-4 aflorimente x3 pe felie, umplere dreapta 0.688-0.7036) — din decupajul `G.png`, cu cifrele fisei
## (`### G` din transfagarasan_poi_gauntlet.md), fiecare legat de o piesa.
##
## Ce arata decupajul (MATERIA, nu layoutul): MASA de molid verde-negru, in
## coloane inguste si ascutite, in 2-3 randuri si 3 marimi, pe ambele maluri,
## cu goluri; intre drum si copaci o FASIE joasa (iarba scurta cu jneapan culcat,
## afin, lame mici de sist); cascada in trepte pe un perete de sist gri-verzui in
## LAME inclinate (aflorimente de-o parte si de alta a perdelei, grohotis la
## picior); cabana de lemn imbatranit cu acoperis ruginiu pe stanga, langa drum;
## bujor de munte magenta intr-un singur petic mic, nealiniat; fagi doar ca
## accent (nu aici: G e deasupra liniei fagului, deci 0).
##
##  #  element                      cifra   piesa (GLB)                        cum
##  1  molizi, masa                 ~600    trees/alpine_pines Pine_A..D       MultiMesh feliat (4 felii),
##     (5 randuri/parte, 3 marimi)          (+ Trunk_A..D)                     ace pe tri_class tf_jneapan,
##                                                                              trunchi pe atlas
##  2  cabana Balea Cascada         1       buildings/cabana_balea_cascada     nod, hull, fata spre drum,
##                                                                              stanga la ~14 m de margine
##  3  aflorimente de sist          ~22     rocks/schist_outcrop_a/b/c         noduri, hull: 8 flancand
##                                                                              cascada, restul la 25-50 m
##  4  conuri de grohotis           2       rocks/scree_cone                   noduri, fara coliziune
##  5  fasie joasa 3,5-9 m          ~450    plants/jneapan_a/b + afin +        MultiMesh, fara coliziune
##     (jneapan, afin, sist mic)            rocks/schist_outcrop_b (mic) +
##                                          rocks/scree_cone (mic)
##  6  petice de bujor de munte     5       plants/bujor_de_munte (x5-6/petic) MultiMesh, atint:tf_bloom
##  7  telecabina, cascada (apa), canalul: NU sunt ale mele (fundatie/integrare)
##  8  corbi (raven): nu — ar aduce un material nou (0 materiale noi in val 1)
##  9  cable_car_station (jos): nu — cabana ESTE statia in decupaj; statia e a integrarii
##
## Densitate spre drum: 0-10 m de MARGINE = fasia joasa (nimic cu coliziune);
## 10-30 m = randurile 1-2 de molizi (cele mai dese), cabana pe stanga; 30-60 m =
## randurile 3-4, mai inalte, si peretele cu cascada. Culoarul sariturii
## (0.665-0.690, canalul ParaulBalea): NIMIC (nici MultiMesh) la < 24 m de axa.

const TRACK := "res://scenes/tracks/Track21.tscn"
const SCENE_PATH := "res://scenes/tracks/Track21.tscn"
const ZONE := "DecorManual/ZonaG"
const F0 := 0.6268
const F1 := 0.7036
const CASCADA := Vector2(-72.0, -302.5)

const MODELS := {
	"g_flock": ["Script", "res://scenes/props/flock.gd"],
	"g_pines": ["PackedScene", "res://assets/models/trees/alpine_pines.glb"],
	"g_beech_a": ["PackedScene", "res://assets/models/transfagarasan/plants/beech_tree_a.glb"],
	"g_beech_b": ["PackedScene", "res://assets/models/transfagarasan/plants/beech_tree_b.glb"],
	"g_jneapan_a": ["PackedScene", "res://assets/models/transfagarasan/plants/jneapan_a.glb"],
	"g_jneapan_b": ["PackedScene", "res://assets/models/transfagarasan/plants/jneapan_b.glb"],
	"g_afin": ["PackedScene", "res://assets/models/transfagarasan/plants/afin.glb"],
	"g_bujor": ["PackedScene", "res://assets/models/transfagarasan/plants/bujor_de_munte.glb"],
	"g_outcrop_a": ["PackedScene", "res://assets/models/transfagarasan/rocks/schist_outcrop_a.glb"],
	"g_outcrop_b": ["PackedScene", "res://assets/models/transfagarasan/rocks/schist_outcrop_b.glb"],
	"g_outcrop_c": ["PackedScene", "res://assets/models/transfagarasan/rocks/schist_outcrop_c.glb"],
	"g_scree": ["PackedScene", "res://assets/models/transfagarasan/rocks/scree_cone.glb"],
	"g_cabana": ["PackedScene", "res://assets/models/transfagarasan/buildings/cabana_balea_cascada.glb"],
}

var _track: Track
var _sampler: TrackSideSampler
var _terrain_rid: RID = RID()
var _sus_y := 0.0
var _rng := RandomNumberGenerator.new()
var _i_lo := 0
var _i_hi := 0

var _nodes: Array[String] = []
var _flocks := {}
var _count := {}
var _rejected := 0
var _cabana_pos := Vector3.ZERO
var _rocks: Array[Vector3] = []


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
	_rng.seed = 627036
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
	_cabana()
	_roci_cascada()
	_roci_padure()
	_grohotis()
	_molizi()
	_fasie()
	_bujor()
	var tot := 0
	for k in _count:
		tot += int(_count[k])
	print("; ZonaG: %d piese asezate, %d respinse de garzi" % [tot, _rejected])
	for k in _count:
		print(";   %s: %d" % [k, _count[k]])
	for k in _flocks:
		print(";   lot %s: %d instante" % [k, (_flocks[k]["pos"] as PackedVector3Array).size()])


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
	d["dy_road"] = q.y - _track.baked[near["i"]].y
	d["slope"] = slope
	d["nrm"] = nrm
	return d


## Garzile comune. `margin` = cat de departe de MARGINEA asfaltului (m), `r` =
## raza piesei. Culoarul sariturii (canalul) ramane gol; la fel cascada si cabana.
func _ok(c: Dictionary, r: float, margin: float) -> bool:
	var q: Vector3 = c["pos"]
	if is_nan(q.y):
		return false
	if float(c["d"]) < float(c["half_j"]) + margin + r:
		return false
	var fj: float = float(c["j"]) / float(_track.baked.size())
	# culoarul sariturii: nimic la < 24 m de axa pe 0.668-0.690
	if fj > 0.668 and fj < 0.690 and float(c["d"]) < 24.0 + r:
		return false
	# perdeaua cascadei si bazinul de sub ea: liber de copaci/plante (cutie pe plan)
	if q.x > -86.0 and q.x < -58.0 and q.z > -313.0 and q.z < -296.0:
		return false
	if _cabana_pos != Vector3.ZERO and Vector2(q.x - _cabana_pos.x, q.z - _cabana_pos.z).length() < 11.5 + r:
		return false
	return true


## Cota unui NOD de decor, in banda de toleranta a garzii (probe_manual judeca fata
## de `sampler.ground_y`: plutit > 3 m, ingropat > 2 m). Pe peretele cascadei meshul
## urca cu 5-8 m peste sampler (nisa cascadei), deci piesa mare se infige in perete.
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


## Felia (0..3) dupa fractie: culling pe felii.
func _slice_of(f: float) -> int:
	return clampi(int((f - F0) / (F1 - F0) * 4.0), 0, 3)


# 2 ------------------------------------------------------------------ cabana

func _cabana() -> void:
	# stanga, pe platoul plat (0.645-0.665), la ~21 m de margine: prispa (2,5 m)
	# ajunge la ~14 m de margine. Fata bogata = -Z local; yaw o intoarce spre drum.
	var c := _cand(0.656, -1.0, 21.0)
	var pos: Vector3 = c["pos"]
	var rd: Vector3 = _track.baked[int(c["j"])]
	var d := Vector2(rd.x - pos.x, rd.z - pos.z).normalized()
	var yaw := atan2(-d.x, -d.y)
	pos.y -= 0.15
	_cabana_pos = pos
	_node("G_Cabana", "g_cabana", pos, yaw, 1.0)
	_count["cabana"] = 1
	print("; cabana la (%.1f, %.1f, %.1f) yaw %.2f, d axa %.1f m" % [pos.x, pos.y, pos.z, yaw, float(c["d"])])


# 3 ------------------------------------------------------------------ roci

## Aflorimente care flancheaza perdeaua cascadei, pe baza peretelui: lame mari
## de-o parte si de alta, mai mici la picior, ca in decupaj.
func _roci_cascada() -> void:
	# [x, z, scara, model] — z peste -304 (>= 24 m de axa), pe peretele care se ridica
	var specs := [
		[-81.0, -300.5, 1.55, "a"], [-85.5, -299.0, 1.35, "c"], [-90.0, -299.5, 1.1, "b"],
		[-63.5, -300.5, 1.5, "b"], [-59.0, -299.0, 1.3, "a"], [-55.0, -300.0, 1.0, "c"],
		[-78.5, -297.0, 1.9, "c"], [-66.0, -297.0, 1.8, "a"],
	]
	var k := 0
	for s: Array in specs:
		var pos := Vector3(float(s[0]), 0.0, float(s[1]))
		var c := _cand_at(pos, {"f": 0.68, "sg": -1.0})
		var q: Vector3 = c["pos"]
		if is_nan(q.y):
			continue
		var sc: float = float(s[2])
		var p3 := q
		p3.y = _y_garda(p3.x, p3.z, p3.y - 0.4 * sc)
		k += 1
		_node("G_AflorCascada%02d" % k, "g_outcrop_" + String(s[3]), p3, _rng.randf_range(-PI, PI), sc, c["nrm"], 0.55)
		_rocks.append(q)
		_count["aflorimente"] = int(_count.get("aflorimente", 0)) + 1


## Gramezi de 3-4 aflorimente fatetate (a/b, scara mixta) care ies din padure:
## 3 pe fiecare din cele 4 felii, la 14-45 m de margine, ambele parti.
func _roci_padure() -> void:
	var centers: Array[Vector3] = []
	var total := 0
	var groups := 0
	for sl in 4:
		var got := 0
		var guard := 0
		while got < 3 and guard < 3000:
			guard += 1
			var f := F0 + (F1 - F0) * (float(sl) + _rng.randf()) / 4.0
			var sg := 1.0 if _rng.randf() < 0.5 else -1.0
			var c := _cand(f, sg, _rng.randf_range(14.0, 45.0))
			if not _ok(c, 4.0, 12.0) or float(c["slope"]) > 0.9:
				continue
			var pp: Vector3 = c["pos"]
			var near := false
			for q in centers:
				if q.distance_to(pp) < 22.0:
					near = true
					break
			if near:
				continue
			centers.append(pp)
			got += 1
			groups += 1
			var k := _rng.randi_range(3, 4)
			for m in k:
				var ang := _rng.randf() * TAU
				var rad := _rng.randf_range(0.0, 3.2) if m > 0 else 0.0
				var pc := _cand_at(pp + Vector3(cos(ang) * rad, 0.0, sin(ang) * rad), c)
				var sc := _rng.randf_range(1.0, 1.6) if m == 0 else _rng.randf_range(0.55, 1.2)
				if not _ok(pc, 3.0 * sc, 12.0):
					continue
				var nm := "outcrop_a" if _rng.randf() < 0.55 else "outcrop_b"
				var p3: Vector3 = pc["pos"]
				p3.y = _y_garda(p3.x, p3.z, p3.y - 0.35 * sc)
				total += 1
				_node("G_Aflor%02d" % total, "g_" + nm, p3, _rng.randf_range(-PI, PI), sc, pc["nrm"], 0.3)
				_rocks.append(pc["pos"])
				_count["aflorimente"] = int(_count.get("aflorimente", 0)) + 1
	_count["gramezi_roci"] = groups


func _grohotis() -> void:
	# la piciorul flancurilor cascadei, cu latura plata spre stanca
	var specs := [[-93.0, -302.0], [-53.0, -302.5]]
	var k := 0
	for s: Array in specs:
		var pos := Vector3(float(s[0]), 0.0, float(s[1]))
		var c := _cand_at(pos, {"f": 0.68, "sg": -1.0})
		var q: Vector3 = c["pos"]
		if is_nan(q.y):
			continue
		var to_rock := Vector2(CASCADA.x - q.x, -296.0 - q.z).normalized()
		k += 1
		var p3 := q
		p3.y = _y_garda(p3.x, p3.z, p3.y - 0.4)
		_node("G_Grohotis%02d" % k, "g_scree", p3, atan2(to_rock.x, to_rock.y), _rng.randf_range(0.8, 1.0), c["nrm"], 0.7)
		_count["grohotis"] = int(_count.get("grohotis", 0)) + 1


# 1 ------------------------------------------------------------------ molizi

## Randuri de molizi in palcuri neregulate (3-6 arbori), 3 marimi, cu goluri;
## densitate care creste spre drum (randurile apropiate au mai putine goluri).
func _molizi() -> void:
	# [offset centru de la margine, prob. palc, decalaj frac, clasa marime]
	var rows := [
		[9.5, 0.6, 0.0, 0], [15.0, 0.92, 0.0012, 0], [22.0, 0.92, 0.0024, 0],
		[31.0, 0.92, 0.0006, 1], [42.0, 0.92, 0.0018, 2], [55.0, 0.9, 0.0030, 2],
		[70.0, 0.88, 0.0010, 2], [88.0, 0.85, 0.0022, 2],
	]
	var trees := 0
	var clumps := 0
	for sg: float in [1.0, -1.0]:
		for r: Array in rows:
			var f: float = F0 + float(r[2]) - 0.006
			while f < F1 + 0.006:
				f += _rng.randf_range(0.0024, 0.0038)
				if _rng.randf() > float(r[1]):
					continue
				var off: float = float(r[0]) + _rng.randf_range(-3.5, 3.5)
				var c := _cand(f, sg, maxf(off, 7.5))
				if float(c["slope"]) > 1.0:
					_rejected += 1
					continue
				var k := _rng.randi_range(3, 6) if int(r[3]) == 0 else _rng.randi_range(3, 7)
				# ~14% dintre palcuri sunt fagi (verde-lime), 3-5 la rand, doar in primele 45 m
				var beech := float(r[0]) <= 45.0 and _rng.randf() < 0.17
				if beech:
					k = _rng.randi_range(3, 5)
				var got := 0
				for m in k:
					var pc := c
					if m > 0:
						var ang := _rng.randf() * TAU
						var rad := _rng.randf_range(1.8, 5.2)
						pc = _cand_at((c["pos"] as Vector3) + Vector3(cos(ang) * rad, 0.0, sin(ang) * rad), c)
					if not _ok(pc, 2.0, 5.5) or float(pc["slope"]) > 1.1:
						_rejected += 1
						continue
					# poiana cabanei: molizii mari nu o ascund de pe drum
					var qp: Vector3 = pc["pos"]
					if _cabana_pos != Vector3.ZERO and int(r[3]) > 0 							and Vector2(qp.x - _cabana_pos.x, qp.z - _cabana_pos.z).length() < 19.0:
						_rejected += 1
						continue
					got += 1
					trees += 1
					_pine(pc, int(r[3]), beech)
				if got > 0:
					clumps += 1
	# pajistea dreapta 0.688-0.7036: randuri suplimentare (cerinta r2)
	for r2: Array in [[12.0, 0], [20.0, 0], [32.0, 1], [46.0, 2], [62.0, 2], [80.0, 2]]:
		var f2 := 0.686
		while f2 < F1 + 0.004:
			f2 += _rng.randf_range(0.0018, 0.0030)
			var c2 := _cand(f2, 1.0, float(r2[0]) + _rng.randf_range(-3.0, 3.0))
			var k2 := _rng.randi_range(3, 6)
			for m in k2:
				var pc2 := c2
				if m > 0:
					var ang2 := _rng.randf() * TAU
					var rad2 := _rng.randf_range(1.8, 5.0)
					pc2 = _cand_at((c2["pos"] as Vector3) + Vector3(cos(ang2) * rad2, 0.0, sin(ang2) * rad2), c2)
				if not _ok(pc2, 2.0, 5.5) or float(pc2["slope"]) > 1.1:
					continue
				trees += 1
				_pine(pc2, int(r2[1]), false)
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
		var bs := _rng.randf_range(0.55, 1.0)
		var b3 := Vector3(bs * _rng.randf_range(0.9, 1.1), bs * _rng.randf_range(0.9, 1.1), bs * _rng.randf_range(0.9, 1.1))
		_flock_add("fag_%s_s%d" % [bv, sl], p3, yaw, b3)
		return
	var rr := _rng.randf()
	var v := "A" if rr < 0.25 else ("B" if rr < 0.6 else ("C" if rr < 0.85 else "D"))
	var sc := 1.0
	var pick := _rng.randf()
	match size_class:
		0:
			# primii ~25 m: molizi mici (0,4-0,7), rar unul mai mare
			sc = _rng.randf_range(0.4, 0.7) if pick < 0.88 else _rng.randf_range(0.7, 0.9)
		1:
			sc = _rng.randf_range(0.75, 1.15) if pick < 0.75 else _rng.randf_range(0.5, 0.75)
		_:
			sc = _rng.randf_range(1.2, 1.75) if pick < 0.7 else _rng.randf_range(0.9, 1.2)
	# ton: ~65% inchis (tf_jneapan), ~35% atlas (oliv-verde); amestecat in palcuri
	var tone := "pine" if _rng.randf() < 0.65 else "pinem"
	# inclinare simulata prin scara neuniforma (FlockProp nu are inclinare per instanta)
	var s3 := Vector3(sc * _rng.randf_range(0.85, 1.15), sc * _rng.randf_range(0.9, 1.15), sc * _rng.randf_range(0.85, 1.15))
	_flock_add("%s_%s_s%d" % [tone, v, sl], p3, yaw, s3)
	_flock_add("trunk_%s_s%d" % [v, sl], p3, yaw, s3)


# 5 ------------------------------------------------------------------ fasie

## Fasia joasa de la 3,5 la ~9 m de margine, pe ambele parti, pe toata zona:
## jneapan culcat, afin, lame mici de sist, grohotis mic. Fara coliziune.
func _fasie() -> void:
	var n := 0
	var f := F0 + 0.002
	while f < F1:
		for sg: float in [1.0, -1.0]:
			# nimic in canalul de sarituri (0.671-0.688), banca lui e carvata
			if f > 0.671 and f < 0.688:
				continue
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
			if _rng.randf() < 0.1:
				var c5 := _cand(f, sg, _rng.randf_range(6.0, 9.0))
				if _ok(c5, 1.2, 3.2):
					var p5: Vector3 = c5["pos"]
					p5.y -= 0.1
					var sc5 := _rng.randf_range(0.28, 0.4)
					_flock_add("grohm_s%d" % _slice_of(f), p5, _rng.randf_range(-PI, PI), Vector3(sc5, sc5, sc5))
					n += 1
		f += 0.0014
	_count["fasie_piese"] = n


# 6 ------------------------------------------------------------------ bujor

func _bujor() -> void:
	# 5 petice mici, nealiniate: [frac, latura, offset]
	var specs := [[0.6335, 1.0, 9.0], [0.6485, -1.0, 11.0], [0.6590, -1.0, 8.0],
		[0.6965, 1.0, 10.0], [0.7010, -1.0, 9.5]]
	var patches := 0
	for s: Array in specs:
		var c := _cand(float(s[0]), float(s[1]), float(s[2]))
		if not _ok(c, 2.0, 3.0):
			_rejected += 1
			continue
		var k := _rng.randi_range(5, 6)
		for m in k:
			var ang := _rng.randf() * TAU
			var rad := sqrt(_rng.randf()) * 1.8
			var pc := _cand_at((c["pos"] as Vector3) + Vector3(cos(ang) * rad, 0.0, sin(ang) * rad), c)
			if not _ok(pc, 0.8, 3.0):
				continue
			var sc := _rng.randf_range(1.5, 2.2)
			var p3: Vector3 = pc["pos"]
			p3.y -= 0.03
			_flock_add("bujor_s0", p3, _rng.randf_range(-PI, PI), Vector3(sc, sc, sc))
		for m in 3:
			var ang2 := _rng.randf() * TAU
			var rad2 := 2.2 + _rng.randf() * 1.6
			var pc2 := _cand_at((c["pos"] as Vector3) + Vector3(cos(ang2) * rad2, 0.0, sin(ang2) * rad2), c)
			if _ok(pc2, 0.5, 3.0):
				var sc2 := _rng.randf_range(1.3, 1.8)
				_flock_add("afin_s%d" % _slice_of(float(s[0])), pc2["pos"], _rng.randf_range(-PI, PI), Vector3(sc2, sc2, sc2))
		patches += 1
	_count["petice_bujor"] = patches


# ------------------------------------------------------------------ emitere

func _node(nm: String, res_id: String, pos: Vector3, yaw: float, sc: float,
		nrm: Vector3 = Vector3.UP, tilt: float = 0.0) -> void:
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
	_nodes.append("")


## Lotul -> lista de {model, mesh, cls, nm} (un lot poate da 2 stoluri: ace + scoarta).
func _lot_specs(key: String) -> Array:
	var parts := key.split("_")
	match parts[0]:
		"pine":
			return [{"model": "g_pines", "mesh": "Pine_" + parts[1], "cls": "tf_jneapan", "nm": "G_Molid_%s_%s" % [parts[1], parts[2]]}]
		"pinem":
			return [{"model": "g_pines", "mesh": "Pine_" + parts[1], "cls": "", "nm": "G_MolidM_%s_%s" % [parts[1], parts[2]]}]
		"fag":
			return [
				{"model": "g_beech_" + parts[1], "mesh": "Beech_Bark", "cls": "", "nm": "G_FagScoarta_%s_%s" % [parts[1], parts[2]]},
				{"model": "g_beech_" + parts[1], "mesh": "Beech_Leaves", "cls": "tf_beech", "nm": "G_FagCoroana_%s_%s" % [parts[1], parts[2]]},
			]
		"trunk":
			return [{"model": "g_pines", "mesh": "Trunk_" + parts[1], "cls": "", "nm": "G_Trunchi_%s_%s" % [parts[1], parts[2]]}]
		"jn":
			return [
				{"model": "g_jneapan_" + parts[1], "mesh": "Jneapan_Needles", "cls": "tf_jneapan", "nm": "G_JnAce_%s_%s" % [parts[1], parts[2]]},
				{"model": "g_jneapan_" + parts[1], "mesh": "Jneapan_Bark", "cls": "tf_jneapan", "nm": "G_JnScoarta_%s_%s" % [parts[1], parts[2]]},
			]
		"afin":
			return [
				{"model": "g_afin", "mesh": "Afin_Leaves", "cls": "", "nm": "G_AfinFrunze_" + parts[1]},
				{"model": "g_afin", "mesh": "Afin_Berry", "cls": "", "nm": "G_AfinBoabe_" + parts[1]},
			]
		"roca":
			return [{"model": "g_outcrop_b", "mesh": "Schist_Schist", "cls": "tf_schist", "nm": "G_RocaMica_" + parts[1]}]
		"grohm":
			return [{"model": "g_scree", "mesh": "Scree_Schist", "cls": "tf_schist", "nm": "G_GrohotisMic_" + parts[1]}]
		"bujor":
			return [
				{"model": "g_bujor", "mesh": "Bujor_Bloom", "cls": "atint:tf_bloom", "nm": "G_BujorFloare_" + parts[1]},
				{"model": "g_bujor", "mesh": "Bujor_Leaves", "cls": "", "nm": "G_BujorFrunze_" + parts[1]},
			]
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
		lines.append('script = ExtResource("g_flock")')
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


## Rescrie DOAR ZonaG si ext_resource-urile `g_*` din Track21.tscn; restul ramane
## octet cu octet (memoria `tscn-editat-de-mana-nu-se-rescrie`).
func _write_scene() -> void:
	var path := ProjectSettings.globalize_path(SCENE_PATH)
	var txt := FileAccess.get_file_as_string(path)
	var lines := txt.split("\n")
	var kept: Array[String] = []
	var skipping := false
	for ln in lines:
		var l: String = ln
		if l.begins_with('[ext_resource') and ' id="g_' in l:
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
		if kept[k].begins_with('[node name="ZonaG" type="Node3D" parent="DecorManual"]'):
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
	print("; grid cascada: mesh / sampler (x -100..-48 pas 4; z de sus in jos)")
	var z := -290.0
	while z >= -312.0:
		var l2 := "z%6.0f:" % z
		var x := -100.0
		while x <= -48.0:
			l2 += " %5.1f/%5.1f" % [_track._terrain_mesh_y(x, z), _sampler.ground_y(x, z)]
			x += 4.0
		print(l2)
		z -= 2.0


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


## Cota SUPRAFETEI vizibile a terenului (grila meshului), nu a coliziunii: pe
## peretele cascadei cele doua difera cu 5-6 m, iar garda (probe_manual) si ochiul
## cer meshul (memoria `terrain-mesh-y-extrapoleaza`: doar in interiorul grilei).
func _sol_real(x: float, z: float) -> float:
	return _track._terrain_mesh_y(x, z)
