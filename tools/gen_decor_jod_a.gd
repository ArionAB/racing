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
##   trotuarului), trei in piata dinaintea turnului si doua intre turn si poarta. Varianta cu corp `Car` oprit (se
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
	"stall_canopy_a": "s_stall_canopy_a",
	"stall_canopy_b": "s_stall_canopy_b",
	"stall_canopy_c": "s_stall_canopy_c",
	"chai_stall": "s_chai_stall",
	"thela_cart": "s_thela_cart",
	"spice_sacks": "s_spice_sacks",
	"euphorbia": "s_euphorbia",
}
## Fata cu usi si ferestre a fiecarei case, MASURATA pe GLB (runda 2): aria
## golurilor `*_Glow` + a ramelor `*_Trim` la < 1 m de fiecare fata a lui
## `House_Wall*` (m2):
##   blue_house_a  +X 3,0  +Z 1,2           -> +X (usa; ca la H)
##   blue_house_b  +X 7,0  -Z 5,3           -> +X
##   blue_house_c  -Z 16,2 +X 14,0          -> -Z
##   blue_house_d  +X 6,7  -Z 6,5           -> +X (casa de colt)
##   blue_house_e  +X 0,8, restul 0         -> golurile sunt RETRASE in volum
##                 (Trim z -2,0..1,2 in peretele de +-3,1); media lor cade spre
##                 -Z (Glow z -0,77, Trim z -1,22) -> -Z, masuratoare slaba
##   haveli_facade -Z 12,0 +X 8,5; usa e un plan la z -2,28 -> -Z
## Nicio casa nu are fata pe +Z, cum presupunea runda 1 (yaw 0 spre drum).
const FACE := {
	"blue_house_a": "+X", "blue_house_b": "+X", "blue_house_c": "-Z",
	"blue_house_d": "+X", "blue_house_e": "-Z", "haveli_facade": "-Z",
}
## (latime pe X, adancime pe Z) din inventar.
const HOUSE_DIMS := {
	"blue_house_a": Vector2(7.15, 6.62), "blue_house_b": Vector2(6.82, 7.55),
	"blue_house_c": Vector2(7.50, 7.67), "blue_house_d": Vector2(7.50, 8.01),
	"blue_house_e": Vector2(7.40, 6.26), "haveli_facade": Vector2(10.92, 7.43),
}
const STALL_DEPTH := {
	"stall_canopy_a": 3.10, "stall_canopy_b": 3.10, "stall_canopy_c": 3.10,
	"chai_stall": 2.67, "thela_cart": 1.20,
}
## Fatada primului rand (m de la ax): trotuarul se termina la 9,7, fasia de
## tarabe sta intre 9,1 si 11,2.
const FACADE_LAT := 11.4
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
var _shop_lamps: Array[Vector3] = []
var _tuk_x: Array[float] = []


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
	_market()
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
	# Trei in piata dinaintea turnului (se vad din cadrul de start, langa
	# rangoli, si sunt joase: nu acopera turnul de pe H).
	var xs := [-35.2, -39.1, -43.0]
	for i in xs.size():
		var x: float = xs[i] + _rng.randf_range(-0.3, 0.3)
		var z := _rz(x) + 10.9 + _rng.randf_range(-0.15, 0.25)
		var yaw := -PI * 0.5 + _rng.randf_range(-0.12, 0.12)
		_raw("tuktuk", "aTuk", Vector3(x, _sol_real(x, z), z), yaw, 1.0, "hull")
		_tuk_x.append(x)


## Yaw-ul care intoarce FATA MASURATA a modelului spre directia (tx, tz).
## Fata = unde stau golurile `*_Glow` si ramele `*_Trim` (usi, ferestre),
## masurata pe GLB (runda 2; vezi FACE).
func _yaw_facing(model: String, tx: float, tz: float) -> float:
	match String(FACE.get(model, "+Z")):
		"+X":
			return atan2(-tz, tx)
		"-Z":
			return atan2(-tx, -tz)
		_:
			return atan2(tx, tz)


## Adancimea casei pe directia spre drum (dupa fata masurata).
func _depth_facing(model: String) -> float:
	var dims: Vector2 = HOUSE_DIMS[model]
	return dims.x if String(FACE.get(model, "+Z")) == "+X" else dims.y


func _houses() -> void:
	# Randul intai pe dreapta (nord): fatada la FACADE_LAT, cu usile si
	# ferestrele spre drum; coliziune implicita (hull).
	var x := -13.5
	var k := 0
	while x > -70.0:
		var m: String = HOUSES[k % HOUSES.size()]
		var dims: Vector2 = HOUSE_DIMS[m]
		var w: float = dims.y if String(FACE.get(m, "+Z")) == "+X" else dims.x
		var xx := x - w * 0.5
		if xx - w * 0.5 < -72.0:
			break
		var lat := FACADE_LAT + _depth_facing(m) * 0.5 + _rng.randf_range(0.0, 0.5)
		var z := _rz(xx) - lat
		var yaw := _yaw_facing(m, 0.0, 1.0) + _rng.randf_range(-0.05, 0.05)
		_raw(m, "aDr", Vector3(xx, _sol_real(xx, z), z), yaw, 1.0, "")
		if m != "haveli_facade" and _rng.randf() < 0.4:
			_meta_last("metadata/indigo = true")
		if k % 2 == 0:
			var gz := _rz(xx) - FACADE_LAT + 0.15
			_raw("marigold_garland", "aDrGhirlanda", Vector3(xx, _sol_real(xx, gz) + 3.1, gz), 0.0, 1.0, "")
		x -= w + _rng.randf_range(0.3, 1.2)
		k += 1
	# Randul doi pe dreapta (fundal, fara corp), tot cu fata spre drum.
	x = -17.0
	while x > -68.0:
		var xx := x + _rng.randf_range(-0.8, 0.8)
		var m: String = HOUSES[(k + 3) % HOUSES.size()]
		var z := _rz(xx) - 24.5 - _rng.randf_range(0.0, 1.5)
		_raw(m, "aDrB", Vector3(xx, _sol_real(xx, z), z), _yaw_facing(m, 0.0, 1.0), 1.0, "none")
		if m != "haveli_facade" and _rng.randf() < 0.4:
			_meta_last("metadata/indigo = true")
		x -= 8.3 + _rng.randf_range(-0.4, 0.6)
		k += 1
	# Fundalul pietei din stanga (24 m): de la x -8 pana la aripa portii; turnul
	# se decupeaza pe el de pe grila. Fata spre drum (-Z in lume).
	x = -8.0
	while x > -70.0:
		var xx := x + _rng.randf_range(-0.6, 0.6)
		if absf(xx - TOWER_X) < 5.0:
			x -= 8.2
			continue
		var z := _rz(xx) + 24.5 + _rng.randf_range(0.0, 1.5)
		var m: String = HOUSES[(k + 5) % HOUSES.size()]
		_raw(m, "aSt", Vector3(xx, _sol_real(xx, z), z), _yaw_facing(m, 0.0, -1.0), 1.0, "none")
		if m != "haveli_facade" and _rng.randf() < 0.4:
			_meta_last("metadata/indigo = true")
		x -= 8.2 + _rng.randf_range(-0.4, 0.6)
		k += 1


## Fasia de bazar dintre asfalt si case (tiparul lui H, runda 3): o taraba in
## fiecare golf dintre doi stalpi de felinar (golful are 7 m, taraba 3,5 m, deci
## nu atinge stalpul), o piesa mica (saci / cactus) la fiecare stalp: un
## obiect la ~3,5 m. Tarabele stau cu spatele la case si fata spre drum, cu
## felinarul de pravalie la gura (`StreetLights.extra_lamps`).
func _market() -> void:
	var stations := _stations_x()
	for side: float in [1.0, -1.0]: # +1 = stanga (+Z), -1 = dreapta
		for i in range(stations.size() - 1):
			var bay := (stations[i] + stations[i + 1]) * 0.5
			if _market_blocked(side, bay, 2.0):
				continue
			var r := _rng.randf()
			var m := "stall_canopy_a"
			if r < 0.22:
				m = "stall_canopy_a"
			elif r < 0.44:
				m = "stall_canopy_b"
			elif r < 0.66:
				m = "stall_canopy_c"
			elif r < 0.82:
				m = "chai_stall"
			else:
				m = "thela_cart"
			_stall(m, "aTaraba", bay + _rng.randf_range(-0.4, 0.4), side)
		for i in stations.size():
			var xs: float = stations[i]
			if _market_blocked(side, xs, 0.9):
				continue
			var c := _rng.randf()
			var z := _rz(xs) + side * (9.95 + _rng.randf_range(0.0, 0.15))
			if c < 0.55:
				for j in [-0.5, 0.5]:
					var sx: float = xs + j * 0.9
					_raw("spice_sacks", "aSaci", Vector3(sx, _sol_real(sx, z), z),
						_yaw_to_road(side) + _rng.randf_range(-0.4, 0.4), 1.0, "")
			elif c < 0.8:
				_raw("euphorbia", "aEufor", Vector3(xs, _sol_real(xs, z), z),
					_rng.randf_range(0.0, TAU), 1.0, "")
			else:
				_raw("spice_sacks", "aSaci", Vector3(xs, _sol_real(xs, z), z),
					_yaw_to_road(side), 1.0, "")
	_square()


## Piata din stanga, INAINTEA turnului (x -9..-44, 14-20 m): doua randuri de
## tarabe joase (2,6 m) cu culoar intre ele, saci si ghirlande. Nimic mai inalt
## de 2,6 m: de pe H turnul (13,5 m lateral) se vede peste ele.
func _square() -> void:
	for row in [[14.6, 1.0], [19.6, -1.0]]:
		var lat: float = row[0]
		var face: float = row[1] # +1 = fata spre drum
		var x := -9.5 + _rng.randf_range(-0.5, 0.5)
		while x > -44.0:
			var r := _rng.randf()
			var z := _rz(x) + lat + _rng.randf_range(-0.3, 0.3)
			var y := _sol_real(x, z)
			if r < 0.7:
				var ms := ["stall_canopy_a", "stall_canopy_b", "stall_canopy_c", "chai_stall"]
				var m: String = ms[_rng.randi() % ms.size()]
				var yaw := _yaw_to_road(1.0) if face > 0.0 else _yaw_to_road(1.0) + PI
				yaw += _rng.randf_range(-0.08, 0.08)
				_raw(m, "aPiata", Vector3(x, y, z), yaw, 1.0, "")
				_shop_lamp_for(m, Vector3(x, y, z), yaw)
				var gdir := Vector3(sin(yaw), 0.0, cos(yaw))
				var gp := Vector3(x, y + 2.55, z) + gdir * 1.6
				_raw("marigold_garland", "aPiataGhirlanda", gp, yaw, 1.0, "")
			else:
				for j in [-0.6, 0.6]:
					var sx: float = x + j
					_raw("spice_sacks", "aPiataSaci", Vector3(sx, _sol_real(sx, z), z),
						_rng.randf_range(0.0, TAU), 1.0, "")
			x -= 4.1 + _rng.randf_range(-0.3, 0.5)


func _stall(m: String, base: String, x: float, side: float) -> void:
	var depth: float = STALL_DEPTH[m]
	var lat := maxf(9.1, 11.2 - depth * 0.5)
	var z := _rz(x) + side * lat
	var y := _sol_real(x, z)
	var yaw := _yaw_to_road(side) + _rng.randf_range(-0.07, 0.07)
	_raw(m, base, Vector3(x, y, z), yaw, 1.0, "")
	_shop_lamp_for(m, Vector3(x, y, z), yaw)
	var fr := Vector3(sin(yaw), 0.0, cos(yaw))
	var rt := Vector3(cos(yaw), 0.0, -sin(yaw))
	# Ghirlanda de galbenele pe muchia din fata a copertinei.
	if m.begins_with("stall_canopy") or m == "chai_stall":
		_raw("marigold_garland", base + "Ghirlanda", Vector3(x, y + 2.55, z) + fr * (depth * 0.5),
			yaw, 1.0, "")
	# Candele in fata tarabei.
	for j in [-1.2, -0.4, 0.4, 1.2]:
		var p := Vector3(x, 0.0, z) + fr * (depth * 0.5 + 0.1) + rt * float(j)
		_diyas.append(Vector3(p.x, _sol_real(p.x, p.z), p.z))


## Felinarul atarna la gura pravaliei (inaltimi si adancimi de la H).
func _shop_lamp_for(m: String, pos: Vector3, yaw: float) -> void:
	var lamp_h := {"stall_canopy_a": 2.25, "stall_canopy_b": 2.25, "stall_canopy_c": 2.25,
		"chai_stall": 2.3, "thela_cart": 1.9}
	var lamp_dz := {"thela_cart": 0.75, "chai_stall": 1.45}
	if not lamp_h.has(m):
		return
	var f := Vector3(sin(yaw), 0.0, cos(yaw))
	_shop_lamps.append(pos + Vector3.UP * float(lamp_h[m]) + f * float(lamp_dz.get(m, 1.65)))


## +Z local spre drum (tarabe, saci): side +1 = stanga, drumul e spre -Z.
func _yaw_to_road(side: float) -> float:
	return PI if side > 0.0 else 0.0


## Unde NU intra fasia: turnul, tuk-tuk-urile parcate, aripa portii.
func _market_blocked(side: float, x: float, half: float) -> bool:
	if x + half > -9.0 or x - half < -73.0:
		return true
	if side > 0.0:
		if absf(x - TOWER_X) < 3.5 + half + 0.5:
			return true
		for tx in _tuk_x:
			if absf(x - tx) < 1.4 + half:
				return true
	return false


## x-ul statiilor de felinar (aceleasi ca StreetLights aFelinare).
func _stations_x() -> Array[float]:
	var out: Array[float] = []
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
			out.append(a.x)
		acc += Vector2(b.x - a.x, b.z - a.z).length()
	return out


func _rangoli() -> void:
	var items := [[-40.0, 11.0, 0], [-18.0, 3.0, 1], [-26.0, 3.0, 1]]
	for it in items:
		var x: float = it[0]
		var d: float = it[1]
		_n += 1
		_out.append('[node name="aRangoli%d" type="Decal" parent="%s"]' % [_n, ZONE])
		_out.append("transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %f, %f, %f)"
			% [x, _road_y(x), _rz(x)])
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
	var sl: Array[String] = []
	for v in _shop_lamps:
		sl.append("%.3f, %.3f, %.3f" % [v.x, v.y, v.z])
	_out.append("extra_lamps = PackedVector3Array(%s)" % ", ".join(sl))
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


## z-ul axei drumului la x (dreapta H urca spre z 188 la est de x -30; la
## vest de x -30 drumul e pe z 190). Interpolare pe punctele coapte.
func _rz(x: float) -> float:
	var pts := _track.baked
	for i in pts.size():
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[(i + 1) % pts.size()]
		if absf(a.z - ROAD_Z) > 8.0 or absf(b.z - ROAD_Z) > 8.0:
			continue
		if (a.x - x) * (b.x - x) <= 0.0 and absf(a.x - b.x) > 0.001:
			return lerpf(a.z, b.z, (x - a.x) / (b.x - a.x))
	return ROAD_Z


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
