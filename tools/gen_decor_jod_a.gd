extends Node
## Generator de decor MANUAL pentru POI A — STARTUL SUB GHANTA GHAR (Track17,
## Jodhpur, frac 0.000-0.094; grila 8-16 m in spatele liniei, x -14..-22).
##
## Nu e sonda: CALCULEAZA transformarile care se lipesc in Track17.tscn sub
## `DecorManual/ZoneA_Start` (tiparul gen_decor_jod_e.gd).
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorJodA.tscn -- \
##       --out=C:/cale/zoneA.part
##
## ------------------------------------------------------------------------
## DECIZIILE (contractul A din jodhpur_poi_gauntlet.md + masuratoarea lui H)
##
## - TURNUL pe stanga, 13,5 m de ax, 20 m DUPA linie (x -50). Drumul continua
##   drept dupa grila, deci turnul nu poate sta pe ax; cu cat e mai la vest,
##   cu atat e mai „in capat" de pe H (tabelul lui H: 15 m dupa -> 47 % din
##   dreapta H il are intreg in cadru, 50 m dupa -> 65 %). 20 m e compromisul
##   cu cadrul de START: la 50 m dupa linie turnul ar sta la 58 m in fata
##   masinii de pe pole (mic, in ceata de start), la 20 m sta la 28 m, pe
##   stanga-fata, intreg de la baza pana la cadrane. Brief-ul („30-50 m in
##   spate-stanga") il punea pe H — acolo ar fi iesit din cadru exact cand
##   H ajunge la grila.
## - POARTA PIETEI peste drum, DUPA turn (x -80), la scara 1,06: golul masurat
##   18,39 m -> 19,49 m (usciorii la +-9,75, dincolo de trotuarul pavat care
##   se termina la 6,5 + 3,2 = 9,7 m si e DRUM pentru `is_on_road`); cheia
##   11,34 -> 12,02 m, peste camera de joc (10 m). Nu peste grila: aripile
##   portii (9,75..21,4 m lateral, 14 m inalte) ar sta exact pe linia de vedere
##   de pe H spre turn (13,5 m lateral) si l-ar ascunde pana la cadrane. Dupa
##   turn, poarta e FUNDALUL lui, ca in dioramă („arcada in spatele turnului").
## - Tuk-tuk-urile parcate: prop static `hull`, la 10,9 m (in afara
##   trotuarului), intre turn si poarta. Varianta cu corp `Car` oprit (se
##   impinge) e cod: `TrafficController` n-are mod „parcat".
## - Rangoli: `RangoliDecal` (decal, nu textura pe drum) — unul mare, 11 m,
##   imediat dupa linie (in fata grilei, x -40), si doua mici pe axul grilei,
##   intre masini (x -18, -26).
## - Luminile: al doilea `StreetLights` (0,99 -> 1,035) racordat la hFelinare
##   al lui H (0,915 -> 0,99), cu sfori de becuri pe muchiile turnului si pe
##   cornisa portii (`eave_points`), plus ghirlande de galbenele pe stalpi.

const TRACK := "res://scenes/tracks/Track17.tscn"
const ZONE := "DecorManual/ZoneA_Start"

const TOWER_X := -50.0
const TOWER_LAT := 13.5 # stanga (+Z)
const GATE_X := -80.0
const GATE_SCALE := 1.06
const ROAD_Z := 190.0

const RES := {
	"ghanta_ghar": "s_ghanta_ghar",
	"market_gate": "s_market_gate",
	"tuktuk": "s_tuktuk",
	"marigold_garland": "s_marigold_garland",
	"blue_house_a": "s_blue_house_a",
	"blue_house_b": "s_blue_house_b",
	"blue_house_c": "s_blue_house_c",
	"blue_house_d": "s_blue_house_d",
	"blue_house_e": "s_blue_house_e",
	"haveli_facade": "s_haveli_facade",
}
const HOUSES := ["blue_house_b", "blue_house_d", "blue_house_a", "haveli_facade",
	"blue_house_c", "blue_house_e", "blue_house_b", "blue_house_d"]

## StreetLights de pe A (aceiasi parametri ca hFelinare, ca sa se racordeze).
const L_FROM := 0.99
const L_TO := 1.035
const L_STEP := 7.0
const L_LAT := 8.3

var _track: Track
var _space: PhysicsDirectSpaceState3D
var _terrain_rid := RID()
var _out: Array[String] = []
var _n := 0
var _out_path := ""
var _rng := RandomNumberGenerator.new()
var _diyas: Array[Vector3] = []
var _eaves: Array[Vector3] = []


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out_path = a.trim_prefix("--out=")
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	_space = _track.get_world_3d().direct_space_state
	_rng.seed = 300926
	_tower()
	_gate()
	_tuks()
	_houses()
	_rangoli()
	_post_garlands()
	_diya_node()
	_lights_node()
	_write()
	get_tree().quit(0)


# ------------------------------------------------------------------ piese

func _tower() -> void:
	var z := ROAD_Z + TOWER_LAT
	var y := _sol_real(TOWER_X, z)
	_raw("ghanta_ghar", "aTurn", Vector3(TOWER_X, y - 0.1, z), 0.0, 1.0, "")
	# Ghirlande pe cele patru fete ale soclului (la 4,6 m, sub cornisa de 6,5).
	for k in 4:
		var yaw := float(k) * PI * 0.5
		var out := Vector3(sin(yaw), 0.0, cos(yaw))
		var p := Vector3(TOWER_X, y + 4.6, z) + out * 3.3
		_raw("marigold_garland", "aTurnGhirlanda", p, yaw, 1.0, "")
	# Candele pe soclu: patrat la 3,9 m de centru.
	var s := 3.9
	var t := -s
	while t <= s + 0.01:
		for q in [Vector2(t, -s), Vector2(t, s), Vector2(-s, t), Vector2(s, t)]:
			_diyas.append(Vector3(TOWER_X + q.x, y, z + q.y))
		t += 0.55
	# Sfori de becuri pe muchiile turnului: inelul cornisei de sus (17,5 m,
	# +-2,7), al cornisei de mijloc (14,5 m, +-3,3), al soclului (6,5 m,
	# +-3,27) si patru sfori din coltul cornisei de sus spre stalpii de pe
	# trotuar si spre casele din spate — „turnul imbracat in lumini" din bara.
	for ring in [Vector2(17.5, 2.75), Vector2(14.5, 3.35), Vector2(6.5, 3.32)]:
		var h: float = y + ring.x
		var r: float = ring.y
		var c := [Vector3(-r, 0, -r), Vector3(r, 0, -r), Vector3(r, 0, r), Vector3(-r, 0, r)]
		for i in 4:
			_eaves.append(Vector3(TOWER_X, h, z) + (c[i] as Vector3))
			_eaves.append(Vector3(TOWER_X, h, z) + (c[(i + 1) % 4] as Vector3))
	var top := y + 17.5
	var anchors := [
		Vector3(TOWER_X + 9.0, 0.0, ROAD_Z + L_LAT),
		Vector3(TOWER_X - 9.0, 0.0, ROAD_Z + L_LAT),
		Vector3(TOWER_X + 10.0, 0.0, ROAD_Z + 23.0),
		Vector3(TOWER_X - 10.0, 0.0, ROAD_Z + 23.0),
	]
	var corners := [Vector3(2.75, 0, -2.75), Vector3(-2.75, 0, -2.75),
		Vector3(2.75, 0, 2.75), Vector3(-2.75, 0, 2.75)]
	for i in 4:
		var an: Vector3 = anchors[i]
		an.y = _sol_real(an.x, an.z) + (4.3 if i < 2 else 6.5)
		_eaves.append(Vector3(TOWER_X, top, z) + (corners[i] as Vector3))
		_eaves.append(an)


func _gate() -> void:
	var y := _road_y(GATE_X)
	# yaw 90: lungimea modelului (X) trece pe Z, adica peste drum.
	_raw("market_gate", "PoartaStartPiata", Vector3(GATE_X, y, ROAD_Z), PI * 0.5, GATE_SCALE, "")
	_meta_last("metadata/camera_blocker = true")
	# Sfoara de becuri pe cornisa, pe ambele fete (13,5 m * 1,06, fata la
	# +-3,5 * 1,06), in deschideri de ~4,7 m.
	var h := y + 13.4 * GATE_SCALE
	for face in [1.0, -1.0]:
		var fx: float = GATE_X + face * 3.55 * GATE_SCALE
		var zz := -17.4 * GATE_SCALE
		while zz < 17.4 * GATE_SCALE - 0.1:
			var z2 := minf(zz + 4.7, 17.4 * GATE_SCALE)
			_eaves.append(Vector3(fx, h, ROAD_Z + zz))
			_eaves.append(Vector3(fx, h, ROAD_Z + z2))
			zz = z2
	# Ghirlande pe fata dinspre start a usciorilor.
	for side in [1.0, -1.0]:
		for dz in [10.6, 13.2]:
			var p := Vector3(GATE_X + 3.8 * GATE_SCALE, y + 8.0, ROAD_Z + side * dz)
			_raw("marigold_garland", "aPoartaGhirlanda", p, PI * 0.5, 1.0, "")


func _tuks() -> void:
	var xs := [-58.5, -62.4, -66.6, -70.4]
	for i in xs.size():
		var x: float = xs[i] + _rng.randf_range(-0.3, 0.3)
		var z := ROAD_Z + 10.9 + _rng.randf_range(-0.15, 0.25)
		var yaw := -PI * 0.5 + _rng.randf_range(-0.12, 0.12)
		_raw("tuktuk", "aTuk", Vector3(x, _sol_real(x, z), z), yaw, 1.0, "hull")


func _houses() -> void:
	# Randul intai pe dreapta (nord), lipit de trotuar: coliziune implicita.
	var x := -13.5
	var k := 0
	while x > -67.0:
		var xx := x + _rng.randf_range(-0.5, 0.5)
		var lat := 14.0 + _rng.randf_range(-0.6, 0.8)
		var m: String = HOUSES[k % HOUSES.size()]
		var yaw := 0.0 if _rng.randf() < 0.75 else (PI * 0.5 if _rng.randf() < 0.5 else -PI * 0.5)
		var z := ROAD_Z - lat
		_raw(m, "aDr", Vector3(xx, _sol_real(xx, z), z), yaw, 1.0, "")
		if _rng.randf() < 0.4:
			_meta_last("metadata/indigo = true")
		if k % 2 == 0:
			var gz := z + 3.7
			_raw("marigold_garland", "aDrGhirlanda", Vector3(xx, _sol_real(xx, gz) + 3.1, gz), 0.0, 1.0, "")
		# Candele pe pragul casei.
		var dx := -3.0
		while dx <= 3.0:
			var dz := z + 4.2
			_diyas.append(Vector3(xx + dx, _sol_real(xx + dx, dz), dz))
			dx += 0.75
		x -= 8.0 + _rng.randf_range(-0.4, 0.6)
		k += 1
	# Randul doi pe dreapta (fundal, fara corp).
	x = -17.0
	while x > -68.0:
		var xx := x + _rng.randf_range(-0.8, 0.8)
		var z := ROAD_Z - 24.5 - _rng.randf_range(0.0, 1.5)
		var m: String = HOUSES[(k + 3) % HOUSES.size()]
		_raw(m, "aDrB", Vector3(xx, _sol_real(xx, z), z), 0.0, 1.0, "none")
		if _rng.randf() < 0.4:
			_meta_last("metadata/indigo = true")
		x -= 8.3 + _rng.randf_range(-0.4, 0.6)
		k += 1
	# Fundalul din spatele turnului (stanga, 24 m): casele pe care turnul se
	# decupeaza de pe grila. Nu intre x -72 si -88 (aripa portii).
	x = -32.0
	while x > -70.0:
		var xx := x + _rng.randf_range(-0.6, 0.6)
		var z := ROAD_Z + 24.5 + _rng.randf_range(0.0, 1.5)
		var m: String = HOUSES[(k + 5) % HOUSES.size()]
		_raw(m, "aSt", Vector3(xx, _sol_real(xx, z), z), PI, 1.0, "none")
		if _rng.randf() < 0.4:
			_meta_last("metadata/indigo = true")
		x -= 8.2 + _rng.randf_range(-0.4, 0.6)
		k += 1
	# Candele pe bordura pietei (stanga, x -12..-45, in afara trotuarului).
	var px := -12.0
	while px > -45.5:
		var pz := ROAD_Z + 10.0
		_diyas.append(Vector3(px, _sol_real(px, pz), pz))
		px -= 0.8


func _rangoli() -> void:
	var items := [[-40.0, 11.0, 0], [-18.0, 3.0, 1], [-26.0, 3.0, 1]]
	for it in items:
		var x: float = it[0]
		var d: float = it[1]
		_n += 1
		_out.append('[node name="aRangoli%d" type="Decal" parent="%s"]' % [_n, ZONE])
		_out.append("transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %f, %f, %f)"
			% [x, _road_y(x), ROAD_Z])
		_out.append('script = ExtResource("a_rangoli")')
		_out.append("size = Vector3(%.2f, 1.2, %.2f)" % [d, d])
		_out.append("variant = %d" % int(it[2]))
		_out.append("")


## Ghirlande pe stalpii felinarelor de pe A (aceeasi statie ca StreetLights).
func _post_garlands() -> void:
	var route := _track.route_at(0)
	var pts := route.baked
	var n := pts.size()
	var i0 := int(L_FROM * float(n))
	var i1 := int(L_TO * float(n))
	var acc := L_STEP
	for i in range(i0, i1):
		var a: Vector3 = pts[route.wrap_index(i)]
		var b: Vector3 = pts[route.wrap_index(i + 1)]
		if acc >= L_STEP:
			acc = 0.0
			var side := route.side_at(route.wrap_index(i))
			side.y = 0.0
			side = side.normalized()
			for sgn in [1.0, -1.0]:
				var p: Vector3 = a + side * (L_LAT * float(sgn))
				# Langa poarta, stalpul e lipit de uscior: fara ghirlanda.
				if absf(p.x - GATE_X) < 5.0:
					continue
				p.y = _sol_real(p.x, p.z) + 4.25
				var yaw := atan2(side.x, side.z)
				_raw("marigold_garland", "aStalpGhirlanda", p, yaw, 1.0, "")
				# Atarna de stalpul felinarului (MultiMesh fara corp): baza
				# stalpului e ancora de sol, nu aerul de sub ghirlanda.
				_meta_last("metadata/ancora_sol = Vector3(0, -4.25, 0)")
		acc += Vector2(b.x - a.x, b.z - a.z).length()


func _diya_node() -> void:
	_out.append('[node name="aCandele" type="MultiMeshInstance3D" parent="%s"]' % ZONE)
	_out.append('script = ExtResource("flock")')
	_out.append('model = ExtResource("s_diya")')
	var ps: Array[String] = []
	var ys: Array[String] = []
	for i in _diyas.size():
		var v := _diyas[i]
		ps.append("%.3f, %.3f, %.3f" % [v.x, v.y + 0.02, v.z])
		ys.append("%.2f" % (float(i) * 1.7))
	_out.append("positions = PackedVector3Array(%s)" % ", ".join(ps))
	_out.append("yaws = PackedFloat32Array(%s)" % ", ".join(ys))
	_out.append("scale_min = 3.40")
	_out.append("scale_max = 3.60")
	_out.append("halo_enabled = true")
	_out.append("")
	print("; candele: %d" % _diyas.size())


func _lights_node() -> void:
	_out.append('[node name="aFelinare" type="Node3D" parent="%s"]' % ZONE)
	_out.append('script = ExtResource("h_lights")')
	_out.append("frac_from = %.3f" % L_FROM)
	_out.append("frac_to = %.3f" % L_TO)
	# Fara fatade: stanga toata (piata, turnul, tuk-tuk-urile), dreapta de la
	# poarta incolo.
	_out.append("facade_gaps = Array[Vector3]([Vector3(-1, 0.98, 1.04), Vector3(1, 1.02, 1.04)])")
	var ps: Array[String] = []
	for v in _eaves:
		ps.append("%.3f, %.3f, %.3f" % [v.x, v.y, v.z])
	_out.append("eave_points = PackedVector3Array(%s)" % ", ".join(ps))
	_out.append("")
	print("; sfori pe muchii: %d" % (_eaves.size() / 2))


# ------------------------------------------------------------------ iesire

func _raw(model: String, base: String, pos: Vector3, yaw: float, scl: float,
		mode: String) -> void:
	var b := Basis.from_euler(Vector3(0.0, yaw, 0.0)).scaled(Vector3(scl, scl, scl))
	_n += 1
	_out.append('[node name="%s%d" parent="%s" instance=ExtResource("%s")]'
		% [base, _n, ZONE, RES[model]])
	# RANDURILE bazei, nu coloanele (memoria tscn-transform-e-pe-randuri).
	_out.append("transform = Transform3D(%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)"
		% [b.x.x, b.y.x, b.z.x, b.x.y, b.y.y, b.z.y, b.x.z, b.y.z, b.z.z,
			pos.x, pos.y, pos.z])
	if mode != "":
		_out.append('metadata/coliziune = "%s"' % mode)
	_out.append("")


func _meta_last(line: String) -> void:
	_out.insert(_out.size() - 1, line)


func _write() -> void:
	print("; asezate %d piese" % _n)
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


func _road_y(x: float) -> float:
	var best := INF
	var y := 0.0
	for p in _track.baked:
		var d := absf(p.x - x) + absf(p.z - ROAD_Z)
		if d < best:
			best = d
			y = p.y
	return y


## Cota SOLULUI din coliziunea reala a panzei de teren (TerrainBody).
func _sol_real(x: float, z: float) -> float:
	if _terrain_rid == RID():
		for c in _track.get_children():
			if str(c.name) == "TerrainBody":
				_terrain_rid = (c as StaticBody3D).get_rid()
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(x, 200.0, z), Vector3(x, -200.0, z))
	q.collide_with_areas = false
	if _terrain_rid != RID():
		var hit: Dictionary = _space.intersect_ray(q)
		var guard := 0
		while not hit.is_empty() and hit["rid"] != _terrain_rid and guard < 24:
			q.exclude = q.exclude + [hit["rid"]]
			hit = _space.intersect_ray(q)
			guard += 1
		if not hit.is_empty() and hit["rid"] == _terrain_rid:
			return float(hit["position"].y)
	return _track._sampler.ground_y(x, z)
