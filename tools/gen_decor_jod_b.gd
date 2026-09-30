extends Node
## Generator de decor MANUAL pentru POI B — BAZARUL SARDAR (Track17, Jodhpur,
## frac ~0.03-0.129: dreapta spre vest, virajul 0.094 spre nord, apoi pana la
## pragul fantanii).
##
## Nu e sonda: CALCULEAZA transformarile care se lipesc in Track17.tscn sub
## `DecorManual/ZoneB_Bazar` (tiparul gen_decor_jod_a.gd).
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorJodB.tscn -- \
##       --out=C:/cale/zoneB.part
##
## ------------------------------------------------------------------------
## DECIZIILE (contractul B din jodhpur_poi_gauntlet.md + lectiile lui A)
##
## - Verdictele de pe A: „mese de picnic goale, rare" si „globuri prea mari".
##   Deci tarabele stau in SIRURI CONTINUE (grupuri de 4-8 lipite, goluri de
##   0,6-1,4 m intre grupuri), fiecare cu o COPERTINA DE PANZA SATURATA facuta
##   din cod (`BazaarKit`: galben, roz, verde, rosu, portocaliu, albastru) care
##   acopera acoperisul pal al GLB-ului si iese 1,1 m spre drum, cu gramezi de
##   condimente in fata si oameni pe trotuar. Luminile: becuri MICI (0,1 m) in
##   siruri pe muchia din fata a fiecarei copertine, felinare mici pe stalpi.
## - Tarabele sunt PERETI CU MASA (`hull`, implicitul kitului), cu fata la
##   FRONT_LAT de ax: dupa trotuarul pavat (asfaltul 6,5 + trotuarul 3,2 =
##   9,7 m, trotuarul e DRUM). Marfa si oamenii din fata stau pe muchia
##   trotuarului, fara corp (teatru; o masina pe trotuar trece prin ei ca prin
##   procesiunea din D).
## - Casele albastre DEASUPRA tarabelor: randul 1 cu fatada lipita de spatele
##   tarabelor (`hull`), randul 2 in spate (fara corp, ca pe A).
## - Fasiile de textile PESTE strada la 7-9 m, legate de fatadele randului 1
##   (nu de stalpi), la fiecare STRIP_STEP m pe portiunile drepte.
## - Traficul (tuk-tuk-urile) e cod; nimic nu se pune pe asfalt.

const TRACK := "res://scenes/tracks/Track17.tscn"
const ZONE := "DecorManual/ZoneB_Bazar"

## Portiunea (fractii pe index). Inceputul: dupa aripa portii pietei (A, x -80,
## aripile pana la x -83,7) si dupa ultimul stalp de felinar al lui A.
const F_FROM := 0.030
## Sfarsitul pe fiecare parte: dreapta (interiorul buclei, spre groapa
## fantanii) se opreste mai devreme; pe stanga bazarul tine pana la viraj.
const F_TO_RIGHT := 0.117
const F_TO_LEFT := 0.123

## Fata tarabelor (m de la ax) si adancimea lor.
const FRONT_LAT := 10.0
const RES := {
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
	"spice_sacks": "s_spice_sacks",
	"neem_tree": "s_neem_tree",
}
## Fata casei (masurata pe GLB, gen_decor_jod_a.gd FACE).
const FACE := {
	"blue_house_a": "+X", "blue_house_b": "+X", "blue_house_c": "-Z",
	"blue_house_d": "+X", "blue_house_e": "-Z", "haveli_facade": "-Z",
}
const HOUSE_DIMS := {
	"blue_house_a": Vector2(7.15, 6.62), "blue_house_b": Vector2(6.82, 7.55),
	"blue_house_c": Vector2(7.50, 7.67), "blue_house_d": Vector2(7.50, 8.01),
	"blue_house_e": Vector2(7.40, 6.26), "haveli_facade": Vector2(10.92, 7.43),
}
const HOUSES := ["blue_house_b", "blue_house_d", "blue_house_a", "blue_house_c",
	"haveli_facade", "blue_house_e", "blue_house_b", "blue_house_a", "blue_house_d",
	"blue_house_c", "blue_house_e"]
const STALL_DEPTH := {
	"stall_canopy_a": 3.10, "stall_canopy_b": 3.10, "stall_canopy_c": 3.10,
	"chai_stall": 2.67,
}
const STALL_W := {
	"stall_canopy_a": 3.50, "stall_canopy_b": 3.50, "stall_canopy_c": 3.50,
	"chai_stall": 2.11,
}
## Fatada randului 1: lipita de spatele tarabelor.
const FACADE_LAT := FRONT_LAT + 3.3
const ROW2_GAP := 1.0
## Copertina: spatele la cota AW_BACK_H peste sol, iese AW_OUT m in fata tarabei,
## coborand pe toata lungimea cu AW_DROP.
const AW_BACK_H := 3.15
const AW_OUT := 1.1
const AW_DROP := 0.6
const CLOTH_SLOTS := [16, 31, 21, 14, 30, 15]
## Condimentele: rosu, galben (turmeric), portocaliu, verde, roz, alb, maro.
const SPICE_SLOTS := [14, 16, 30, 21, 31, 22, 27, 30, 14, 16]
const CLOTHES := [14, 16, 31, 30, 15, 21, 22, 14, 31, 16]
## Sacii: iuta (nisip mediu), panza alba-crem, iarba uscata.
const SACK_SLOTS := [1, 19, 13, 1]
## Multimea: linia grupurilor si limitele (de la ax). Asfaltul se termina la
## 6,5, trotuarul la 9,7; marfa din fata tarabelor incepe la ~9,0.
const CROWD_LAT := 8.0
const CROWD_MIN_LAT := 7.1
const CROWD_MAX_LAT := 9.1
## Fasiile peste strada.
## Runda 1, prima captura: la pas 11 m si panze de 0,9-1,35 m fasiile acopereau
## jumatatea de sus a cadrului (un zid de panza in fata camerei). Mai rare, mai
## sus si mai scurte: panza intre ~8 si ~9,2 m, sub camera (10 m).
const STRIP_STEP := 17.0
const STRIP_H := 9.6
## StreetLights.
const L_LAT := 8.3
const L_STEP := 7.0

var _track: Track
var _route: TrackRoute
var _space: PhysicsDirectSpaceState3D
var _terrain_rid := RID()
var _out: Array[String] = []
var _n := 0
var _out_path := ""
var _rng := RandomNumberGenerator.new()
## Amprentele ocupate (cerc XZ): Vector3(x, z, r).
var _occ: Array[Vector3] = []
var _awn := PackedVector3Array()
var _awn_slots := PackedInt32Array()
var _goods := PackedVector3Array()
var _goods_s := PackedFloat32Array()
var _goods_sl := PackedInt32Array()
var _ppl := PackedVector3Array()
var _ppl_h := PackedFloat32Array()
var _ppl_sl := PackedInt32Array()
var _ppl_hs := PackedInt32Array()
var _ppl_yaw := PackedFloat32Array()
var _boxes := PackedVector3Array()
var _box_dims := PackedVector3Array()
var _box_yaws := PackedFloat32Array()
var _box_slots := PackedInt32Array()
var _box_tapers := PackedFloat32Array()
var _stands := PackedVector3Array()
var _stand_h := PackedFloat32Array()
var _lamps := PackedVector3Array()
var _lamp_r := PackedFloat32Array()
var _strips := PackedVector3Array()
var _eaves: Array[Vector3] = []
var _shop_lamps: Array[Vector3] = []
var _cloth_k := 0
var _cnt := {}


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
	_route = _track.route_at(0)
	_rng.seed = 300927
	for side: float in [1.0, -1.0]:
		_stalls(side)
	for side: float in [1.0, -1.0]:
		_houses(side, FACADE_LAT, "bDr" if side > 0.0 else "bSt", "")
	for side: float in [1.0, -1.0]:
		_houses(side, -1.0, "bDrB" if side > 0.0 else "bStB", "none")
	for side: float in [1.0, -1.0]:
		_crowd(side)
	_strips_across()
	_kit_node()
	_lamps_node()
	_lights_node()
	_write()
	get_tree().quit(0)


# ------------------------------------------------------------ geometria drumului

## Punctele axei pe portiune, cu dreapta orizontala si fractia.
func _axis(f0: float, f1: float) -> Array[Dictionary]:
	var pts := _route.baked
	var n := pts.size()
	var out: Array[Dictionary] = []
	for i in range(int(f0 * float(n)), int(f1 * float(n)) + 1):
		var s := _route.side_at(_route.wrap_index(i))
		s.y = 0.0
		out.append({"p": pts[_route.wrap_index(i)], "s": s.normalized(),
			"f": float(i) / float(n)})
	return out


## Linia paralela cu axa la `lat` (semn = partea), ca polilinie cu lungimi
## cumulate. Pe interiorul virajului se strange; pe exterior se lungeste.
func _offset_line(f0: float, f1: float, side: float, lat: float) -> Dictionary:
	var ax := _axis(f0, f1)
	var ps: Array[Vector3] = []
	var ss: Array[Vector3] = []
	var fs: Array[float] = []
	var cum: Array[float] = [0.0]
	for k in ax.size():
		var p: Vector3 = ax[k]["p"] + (ax[k]["s"] as Vector3) * (lat * side)
		ps.append(p)
		ss.append(ax[k]["s"])
		fs.append(ax[k]["f"])
		if k > 0:
			cum.append(cum[k - 1] + Vector2(p.x - ps[k - 1].x, p.z - ps[k - 1].z).length())
	return {"p": ps, "s": ss, "f": fs, "c": cum}


## Punctul pe linia paralela la distanta d: pozitia, dreapta axei, fractia.
func _on_line(line: Dictionary, d: float) -> Dictionary:
	var cum: Array[float] = line["c"]
	var ps: Array[Vector3] = line["p"]
	for k in range(1, cum.size()):
		if cum[k] >= d:
			var t := (d - cum[k - 1]) / maxf(cum[k] - cum[k - 1], 0.001)
			var s: Vector3 = (line["s"][k - 1] as Vector3).lerp(line["s"][k], t).normalized()
			return {"p": ps[k - 1].lerp(ps[k], t), "s": s,
				"f": lerpf(line["f"][k - 1], line["f"][k], t)}
	return {"p": ps[ps.size() - 1], "s": line["s"][ps.size() - 1], "f": line["f"][ps.size() - 1]}


## Distanta XZ minima de la un punct la axa buclei (tot turul).
func _axis_dist(p: Vector3) -> float:
	var best := INF
	for q in _route.baked:
		var d := Vector2(p.x - q.x, p.z - q.z).length()
		if d < best:
			best = d
	return best


func _free(x: float, z: float, r: float, tol: float = 0.0) -> bool:
	for o in _occ:
		if Vector2(x - o.x, z - o.y).length() < r + o.z - tol:
			return false
	return true


## Dreptunghiul (centru, fata spre drum f, latime w, adancime dp) e in afara
## drumului + trotuarului pe tot conturul?
func _rect_clear(c: Vector3, f: Vector3, w: float, dp: float, min_lat: float) -> bool:
	var t := Vector3.UP.cross(f).normalized()
	for a in [-0.5, 0.5]:
		for b in [-0.5, 0.5]:
			var q: Vector3 = c + t * (w * float(a)) + f * (dp * float(b))
			if _axis_dist(q) < min_lat:
				return false
	return true


# ------------------------------------------------------------------ tarabele

func _stalls(side: float) -> void:
	var f1 := F_TO_RIGHT if side > 0.0 else F_TO_LEFT
	var mid_lat := FRONT_LAT + 1.55
	var line := _offset_line(F_FROM, f1, side, mid_lat)
	var total: float = (line["c"] as Array)[(line["c"] as Array).size() - 1]
	var d := 1.0 + _rng.randf_range(0.0, 1.0)
	var base := "bTaraba" if side > 0.0 else "bTarabaS"
	while d < total - 2.0:
		var n := _rng.randi_range(4, 8)
		var placed_any := false
		for i in n:
			var m := _pick_booth()
			var w: float = STALL_W[m]
			if d + w > total:
				break
			var q := _on_line(line, d + w * 0.5)
			var s: Vector3 = q["s"]
			var fwd := -s * side # spre drum
			var dp: float = STALL_DEPTH[m]
			# Centrul: fata la FRONT_LAT (chai e mai putin adanc).
			var c: Vector3 = q["p"] + s * side * (dp * 0.5 - 1.55)
			if not _rect_clear(c, fwd, w, dp, FRONT_LAT - 0.1) or not _free(c.x, c.z, w * 0.45, 0.0):
				d += 0.5
				break
			var y := _sol_real(c.x, c.z)
			var yaw := atan2(fwd.x, fwd.z) + _rng.randf_range(-0.02, 0.02)
			_raw(m, base, Vector3(c.x, y, c.z), yaw, 1.0, "")
			_occ.append(Vector3(c.x, c.z, w * 0.5))
			_stall_dressing(m, c, y, fwd, w, dp)
			d += w + _rng.randf_range(0.0, 0.08)
			placed_any = true
		# Golul dintre grupuri: pasaj cu un sac si un FELINAR LA SOL (runda 2,
		# criticul: „felinare/lampi calde la sol intre tarabe").
		var gap := _rng.randf_range(0.8, 1.4)
		if placed_any:
			var q := _on_line(line, d + gap * 0.5)
			var s: Vector3 = q["s"]
			var fwd := -s * side
			var c: Vector3 = q["p"] + s * side * 0.3
			if _rng.randf() < 0.6:
				var sx := c + fwd * 0.6
				_raw("spice_sacks", base + "Saci", Vector3(sx.x, _sol_real(sx.x, sx.z), sx.z),
					atan2(fwd.x, fwd.z) + PI * 0.5 + _rng.randf_range(-0.2, 0.2), 1.0, "")
			var lp := c - fwd * 0.9
			var hh := _rng.randf_range(1.05, 1.35)
			var gy := _sol_real(lp.x, lp.z)
			_stands.append(Vector3(lp.x, gy, lp.z))
			_stand_h.append(hh)
			_lamps.append(Vector3(lp.x, gy + hh + 0.16, lp.z))
			_lamp_r.append(0.13)
		d += gap


func _pick_booth() -> String:
	var r := _rng.randf()
	if r < 0.3:
		return "stall_canopy_a"
	if r < 0.6:
		return "stall_canopy_b"
	if r < 0.9:
		return "stall_canopy_c"
	return "chai_stall"


## Copertina, marfa, becurile si oamenii unei tarabe.
func _stall_dressing(m: String, c: Vector3, y: float, fwd: Vector3, w: float,
		dp: float) -> void:
	var t := Vector3.UP.cross(fwd).normalized()
	var back := c - fwd * (dp * 0.5 + 0.05)
	var h := AW_BACK_H + (0.07 if _awn_slots.size() % 2 == 0 else 0.0)
	var bl := back - t * (w * 0.5 - 0.01) + Vector3.UP * 0.0
	var br := back + t * (w * 0.5 - 0.01)
	bl.y = y + h
	br.y = y + h
	var reach := dp + 0.05 + AW_OUT
	var out := fwd * reach + Vector3.DOWN * AW_DROP
	_awn.append(bl)
	_awn.append(br)
	_awn.append(out)
	# Culori care nu se repeta alaturat.
	_cloth_k = (_cloth_k + 1 + (_rng.randi() % 2)) % CLOTH_SLOTS.size()
	_awn_slots.append(CLOTH_SLOTS[_cloth_k])
	# Becurile pe muchia din fata a copertinei (sub falbala).
	var fl := bl + out + Vector3.DOWN * 0.2
	var fr := br + out + Vector3.DOWN * 0.2
	_eaves.append(fl)
	_eaves.append(fr)
	# O lampa mica sub copertina, deasupra tejghelei.
	_shop_lamps.append(Vector3(c.x, y + 2.25, c.z) + fwd * (dp * 0.5 + 0.2))
	# MARFA, runda 2 (criticul: „stive CONTINUE de marfa: cosuri, saci, textile
	# stivuite, care umplu tejgheaua"). Trei randuri lipite pe toata latimea:
	#   - pe tejghea (y + 0,85): stive de baloti de textile;
	#   - randul A, lipit de fata tarabei: saci plini (cu con de condiment) si
	#     stive de baloti de 0,4-0,9 m;
	#   - randul B, pe muchia trotuarului, sub marginea copertinei: cosuri joase
	#     cu gramezi (se vad de sub falbala din camera de joc).
	var yaw := atan2(fwd.x, fwd.z)
	var u := -w * 0.5 + 0.05
	while u < w * 0.5 - 0.25:
		var wid := _rng.randf_range(0.38, 0.52)
		var p := c + t * (u + wid * 0.5) + fwd * (dp * 0.5 + 0.28)
		_front_item(p, wid, yaw)
		u += wid + 0.02
	u = -w * 0.5 + 0.1
	while u < w * 0.5 - 0.3:
		var wid := _rng.randf_range(0.5, 0.62)
		var p := c + t * (u + wid * 0.5) + fwd * (dp * 0.5 + 0.8)
		_goods.append(Vector3(p.x, _sol_real(p.x, p.z), p.z))
		_goods_s.append(wid / 0.52)
		_goods_sl.append(SPICE_SLOTS[_rng.randi() % SPICE_SLOTS.size()])
		u += wid + 0.03
	# Un felinar jos, pe caldaram, in fata fiecarei tarabe.
	var lp := c + fwd * (dp * 0.5 + 0.8) + t * (w * 0.5 - 0.1)
	var ly := _sol_real(lp.x, lp.z)
	_stands.append(Vector3(lp.x, ly, lp.z))
	_stand_h.append(0.42)
	_lamps.append(Vector3(lp.x, ly + 0.58, lp.z))
	_lamp_r.append(0.1)
	if m != "chai_stall":
		u = -w * 0.5 + 0.12
		while u < w * 0.5 - 0.3:
			var wid := _rng.randf_range(0.42, 0.58)
			var p := c + t * (u + wid * 0.5) + fwd * (dp * 0.5 - 0.35)
			_stack(Vector3(p.x, y + 0.85, p.z), wid, yaw, _rng.randi_range(2, 5))
			u += wid + 0.02


## Un obiect din randul A: sac plin cu condiment sau stiva de baloti.
func _front_item(p: Vector3, wid: float, yaw: float) -> void:
	var gy := _sol_real(p.x, p.z)
	if _rng.randf() < 0.55:
		var h := _rng.randf_range(0.5, 0.7)
		_box(Vector3(p.x, gy, p.z), Vector3(wid * 0.5, h, 0.2), yaw + _rng.randf_range(-0.15, 0.15),
			SACK_SLOTS[_rng.randi() % SACK_SLOTS.size()], 0.8)
		_goods.append(Vector3(p.x, gy + h - 0.2, p.z))
		_goods_s.append(wid / 0.55)
		_goods_sl.append(SPICE_SLOTS[_rng.randi() % SPICE_SLOTS.size()])
	else:
		_stack(Vector3(p.x, gy, p.z), wid, yaw, _rng.randi_range(3, 6))


## Stiva de baloti de textile (0,12-0,16 m fiecare, culori saturate alternate).
func _stack(base: Vector3, wid: float, yaw: float, n: int) -> void:
	var y := base.y
	var k := _rng.randi() % CLOTHES.size()
	for i in n:
		var hh := _rng.randf_range(0.12, 0.16)
		_box(Vector3(base.x, y, base.z), Vector3(wid * 0.5 * _rng.randf_range(0.9, 1.0), hh, 0.22),
			yaw + _rng.randf_range(-0.12, 0.12), CLOTHES[k % CLOTHES.size()], 1.0)
		y += hh
		k += 1 + (_rng.randi() % 3)


func _box(p: Vector3, dims: Vector3, yaw: float, slot: int, taper: float) -> void:
	_boxes.append(p)
	_box_dims.append(dims)
	_box_yaws.append(yaw)
	_box_slots.append(slot)
	_box_tapers.append(taper)


## MULTIMEA pe caldaram, runda 2 (criticul: „figurine de oameni DESE, in
## picioare, grupuri, de-a lungul marginilor pavate, pe ambele parti, pana
## departe"): grupuri de 3-6 intorsi unul spre altul, cu trecatori razleti
## intre ele. Doar pe trotuarul pavat (7,1-9,1 m de ax), niciodata pe asfalt
## (6,5 m); fara corp: trotuarul e drum, o masina trece prin ei.
func _crowd(side: float) -> void:
	var f1 := F_TO_RIGHT if side > 0.0 else F_TO_LEFT
	var line := _offset_line(F_FROM + 0.002, f1, side, CROWD_LAT)
	var total: float = (line["c"] as Array)[(line["c"] as Array).size() - 1]
	var d := _rng.randf_range(0.5, 2.0)
	while d < total - 1.0:
		var q := _on_line(line, d)
		var s: Vector3 = q["s"]
		var t := Vector3.UP.cross(s).normalized()
		var gc: Vector3 = q["p"] + s * side * _rng.randf_range(-0.5, 0.5)
		var n := _rng.randi_range(3, 6)
		var r := 0.35 + 0.12 * float(n)
		var a0 := _rng.randf_range(0.0, TAU)
		for i in n:
			var a := a0 + TAU * float(i) / float(n) + _rng.randf_range(-0.3, 0.3)
			var pp := gc + (t * cos(a) + s * sin(a)) * r * _rng.randf_range(0.75, 1.0)
			var to_c := gc - pp
			_person(pp, atan2(to_c.x, to_c.z) + _rng.randf_range(-0.4, 0.4))
		# Trecatori intre grupuri, mergand in lungul strazii.
		for i in _rng.randi_range(0, 2):
			var pp := gc + t * _rng.randf_range(1.6, 2.6) + s * side * _rng.randf_range(-0.7, 0.7)
			var yw := atan2(t.x, t.z) + (PI if _rng.randf() < 0.5 else 0.0)
			_person(pp, yw + _rng.randf_range(-0.2, 0.2))
		d += _rng.randf_range(3.2, 4.6)


func _person(p: Vector3, yaw: float) -> void:
	var ad := _axis_dist(p)
	if ad < CROWD_MIN_LAT or ad > CROWD_MAX_LAT:
		return
	_ppl.append(Vector3(p.x, _sol_real(p.x, p.z) - 0.03, p.z))
	_ppl_h.append(_rng.randf_range(1.6, 1.85))
	_ppl_sl.append(CLOTHES[_rng.randi() % CLOTHES.size()])
	_ppl_yaw.append(yaw)
	var r := _rng.randf()
	_ppl_hs.append(-1 if r < 0.4 else CLOTHES[_rng.randi() % CLOTHES.size()])


# ------------------------------------------------------------------ casele

## Randul de case pe partea `side`, cu fatada la `face_lat` (sau, pentru
## randul 2, imediat in spatele randului 1: face_lat < 0).
func _houses(side: float, face_lat: float, base: String, mode: String) -> void:
	var f1 := F_TO_RIGHT if side > 0.0 else F_TO_LEFT
	var row2 := face_lat < 0.0
	var lat0 := FACADE_LAT + 8.0 + ROW2_GAP if row2 else face_lat
	var line := _offset_line(F_FROM + (0.004 if row2 else 0.0), f1 - (0.004 if row2 else 0.0),
		side, lat0 + 4.0)
	var total: float = (line["c"] as Array)[(line["c"] as Array).size() - 1]
	var d := _rng.randf_range(0.0, 2.0)
	var k := _rng.randi() % HOUSES.size() + (3 if row2 else 0)
	while d < total - 3.0:
		var m: String = HOUSES[k % HOUSES.size()]
		var dims: Vector2 = HOUSE_DIMS[m]
		var front_is_x := String(FACE[m]) == "+X"
		var wid: float = dims.y if front_is_x else dims.x
		var dep: float = dims.x if front_is_x else dims.y
		var q := _on_line(line, d + wid * 0.5)
		var s: Vector3 = q["s"]
		var fwd := -s * side
		var lat := lat0 + dep * 0.5 + _rng.randf_range(0.0, 0.4)
		var c: Vector3 = q["p"] + s * side * (lat - lat0 - 4.0)
		var r := maxf(wid, dep) * 0.5
		if not _rect_clear(c, fwd, wid, dep, lat0 - 0.2) or not _free(c.x, c.z, r * 0.8, 0.3):
			d += 1.5
			k += 1
			continue
		var yaw := _yaw_facing(m, fwd.x, fwd.z) + _rng.randf_range(-0.04, 0.04)
		_raw(m, base, Vector3(c.x, _sol_real(c.x, c.z) - 0.15, c.z), yaw, 1.0, mode)
		if m != "haveli_facade" and _rng.randf() < 0.4:
			_meta_last("metadata/indigo = true")
		_occ.append(Vector3(c.x, c.z, r * 0.8))
		d += wid + _rng.randf_range(0.1, 0.7)
		k += 1


func _yaw_facing(model: String, tx: float, tz: float) -> float:
	match String(FACE.get(model, "+Z")):
		"+X":
			return atan2(-tz, tx)
		"-Z":
			return atan2(-tx, -tz)
		_:
			return atan2(tx, tz)


# ------------------------------------------------------------ fasiile de textile

func _strips_across() -> void:
	var line := _offset_line(F_FROM + 0.003, F_TO_RIGHT - 0.002, 1.0, 0.0)
	var total: float = (line["c"] as Array)[(line["c"] as Array).size() - 1]
	var d := 5.0
	while d < total - 3.0:
		var q := _on_line(line, d)
		var p: Vector3 = q["p"]
		var s: Vector3 = q["s"]
		# Pe viraj fatadele nu sunt paralele: fasia doar pe portiunile drepte.
		var fr := float(q["f"])
		if fr > 0.086 and fr < 0.101:
			d += STRIP_STEP
			continue
		var a := p + s * (FACADE_LAT + 0.1)
		var b := p - s * (FACADE_LAT + 0.1)
		a.y = _sol_real(a.x, a.z) + STRIP_H + _rng.randf_range(-0.2, 0.2)
		b.y = _sol_real(b.x, b.z) + STRIP_H + _rng.randf_range(-0.2, 0.2)
		_strips.append(a)
		_strips.append(b)
		d += STRIP_STEP + _rng.randf_range(-1.5, 1.5)


# ------------------------------------------------------------------ noduri

func _pv3(arr: PackedVector3Array) -> String:
	var ps: Array[String] = []
	for v in arr:
		ps.append("%.3f, %.3f, %.3f" % [v.x, v.y, v.z])
	return "PackedVector3Array(%s)" % ", ".join(ps)


func _kit_node() -> void:
	_out.append('[node name="bBazar" type="Node3D" parent="%s"]' % ZONE)
	_out.append('script = ExtResource("b_bazaar_kit")')
	_out.append("awnings = " + _pv3(_awn))
	_out.append("awning_slots = PackedInt32Array(%s)" % ", ".join(Array(_awn_slots).map(func(v): return str(v))))
	_out.append("goods = " + _pv3(_goods))
	_out.append("goods_sizes = PackedFloat32Array(%s)" % ", ".join(Array(_goods_s).map(func(v): return "%.2f" % v)))
	_out.append("goods_slots = PackedInt32Array(%s)" % ", ".join(Array(_goods_sl).map(func(v): return str(v))))
	_out.append("people = " + _pv3(_ppl))
	_out.append("people_heights = PackedFloat32Array(%s)" % ", ".join(Array(_ppl_h).map(func(v): return "%.2f" % v)))
	_out.append("people_slots = PackedInt32Array(%s)" % ", ".join(Array(_ppl_sl).map(func(v): return str(v))))
	_out.append("people_head_slots = PackedInt32Array(%s)" % ", ".join(Array(_ppl_hs).map(func(v): return str(v))))
	_out.append("people_yaws = PackedFloat32Array(%s)" % ", ".join(Array(_ppl_yaw).map(func(v): return "%.2f" % v)))
	_out.append("boxes = " + _pv3(_boxes))
	_out.append("box_dims = " + _pv3(_box_dims))
	_out.append("box_yaws = PackedFloat32Array(%s)" % ", ".join(Array(_box_yaws).map(func(v): return "%.2f" % v)))
	_out.append("box_slots = PackedInt32Array(%s)" % ", ".join(Array(_box_slots).map(func(v): return str(v))))
	_out.append("box_tapers = PackedFloat32Array(%s)" % ", ".join(Array(_box_tapers).map(func(v): return "%.2f" % v)))
	_out.append("stands = " + _pv3(_stands))
	_out.append("stand_heights = PackedFloat32Array(%s)" % ", ".join(Array(_stand_h).map(func(v): return "%.2f" % v)))
	_out.append("strips = " + _pv3(_strips))
	_out.append("strip_sag_m = 0.45")
	_out.append("strip_cloth_h = Vector2(0.5, 0.75)")
	_out.append("strip_cloth_w = Vector2(0.55, 0.85)")
	_out.append("strip_gap = Vector2(0.18, 0.32)")
	_out.append("")
	print("; copertine %d, marfa %d, oameni %d, fasii %d" % [_awn_slots.size(), _goods.size(),
		_ppl.size(), _strips.size() / 2])


## Felinarele de la sol (lampile; stativele sunt in BazaarKit). Acelasi
## material si acelasi halou ca FortLamps din E/D si becurile din H.
func _lamps_node() -> void:
	_out.append('[node name="bLampiSol" type="Node3D" parent="%s"]' % ZONE)
	_out.append('script = ExtResource("e_fort_lamps")')
	_out.append("positions = " + _pv3(_lamps))
	_out.append("radii = PackedFloat32Array(%s)" % ", ".join(Array(_lamp_r).map(func(v): return "%.2f" % v)))
	var st: Array[String] = []
	for i in _lamps.size():
		st.append("1.40")
	_out.append("stretch = PackedFloat32Array(%s)" % ", ".join(st))
	_out.append("")
	print("; felinare la sol %d, stive %d" % [_lamps.size(), _boxes.size()])


func _lights_node() -> void:
	_out.append('[node name="bFelinare" type="Node3D" parent="%s"]' % ZONE)
	_out.append('script = ExtResource("h_lights")')
	_out.append("frac_from = %.3f" % (F_FROM + 0.004))
	_out.append("frac_to = %.3f" % F_TO_LEFT)
	_out.append("lateral_m = %.2f" % L_LAT)
	_out.append("step_m = %.1f" % L_STEP)
	_out.append("cross_every = 0")
	_out.append("facade_lateral_m = %.2f" % (FACADE_LAT + 0.15))
	_out.append("facade_heights_m = PackedFloat32Array(3.9, 6.3)")
	# Pe dreapta casele se opresc la F_TO_RIGHT (groapa fantanii): fara
	# festoane in aer dincolo de ele.
	_out.append("facade_gaps = Array[Vector3]([Vector3(1, %.3f, %.3f)])" % [F_TO_RIGHT - 0.004, F_TO_LEFT + 0.01])
	# Lectia A: globuri mici, becuri mici si dese.
	_out.append("lamp_radius_m = 0.2")
	_out.append("lamp_halo_core_m = 0.22")
	_out.append("lamp_halo_m = 0.9")
	_out.append("lamp_halo_intensity = 0.75")
	_out.append("extra_lamp_radius_m = 0.09")
	_out.append("bulb_radius_m = 0.09")
	_out.append("bulb_step_m = 0.3")
	_out.append("bulb_halo_core_m = 0.12")
	_out.append("bulb_halo_m = 0.4")
	_out.append("eave_sag_m = 0.08")
	var ps: Array[String] = []
	for v in _eaves:
		ps.append("%.3f, %.3f, %.3f" % [v.x, v.y, v.z])
	_out.append("eave_points = PackedVector3Array(%s)" % ", ".join(ps))
	var sl: Array[String] = []
	for v in _shop_lamps:
		sl.append("%.3f, %.3f, %.3f" % [v.x, v.y, v.z])
	_out.append("extra_lamps = PackedVector3Array(%s)" % ", ".join(sl))
	_out.append("")


# ------------------------------------------------------------------ iesire

func _raw(model: String, base: String, pos: Vector3, yaw: float, scl: float,
		mode: String) -> void:
	var b := Basis.from_euler(Vector3(0.0, yaw, 0.0)).scaled(Vector3(scl, scl, scl))
	_n += 1
	_cnt[model] = int(_cnt.get(model, 0)) + 1
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
	print("; asezate %d piese: %s" % [_n, _cnt])
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
