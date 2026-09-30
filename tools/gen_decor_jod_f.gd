extends Node
## Generator de decor MANUAL pentru POI F — BASTIONUL SI FATADA PALATULUI
## (Track17, Jodhpur, frac 0.588-0.699: fatada Moti Mahal pe dreapta spre est,
## coltul 0.622, bratul de intrare spre SV cu orasul in fata, varful 0.666,
## bratul de iesire spre est, coborarea de la 0.691).
##
## Nu e sonda: CALCULEAZA transformarile care se lipesc in Track17.tscn sub
## `DecorManual/ZoneF_Bastion` (tiparul gen_decor_jod_e.gd).
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorJodF.tscn -- \
##       --out=C:/cale/zoneF.part [--survey] [--mesh]
##
## `--survey` scrie profilul traseului pe F (raza, panta, semilatime, profilul
## transversal al terenului pe ambele parti, partea spre oras) si nu genereaza
## nimic. `--mesh` scrie cotele pieselor (fata cu ferestre, varful merloanelor).
##
## ------------------------------------------------------------------------
## CONTRACTUL (jodhpur_poi_gauntlet.md, sectiunea F + premisele 8-10)
##
## - Granita cu E: E detine tot ce e sub +38 m pana la 0.588 (zidurile de pe
##   fata stancii, portile, LampiFort). F detine platoul, bastionul, fatadele
##   si meterezele de peste +38 m, de la 0.588 incolo. Nimic aici inainte de
##   F_IN si nicio baza de zid care sa dubleze zidurile lui E.
## - Fatada palatului pe DREAPTA fatadei (0.588-0.622), la 10-18 m, cu fata
##   (ferestrele *_Glow) spre drum.
## - Meterezele cu tunuri pe DREAPTA bratului de intrare (0.622-0.666), partea
##   spre oras, cu gura spre oras; tunurile `hull`, in afara benzii.
## - Bastionul rotund sub varful acului (0.666), pe partea dinspre oras,
##   coroana SUB cota drumului: FARA parapet pe varf (premisa 10).
## - Diyas pe coama meterezelor, in sir regulat (FortLamps, tiparul lui E).

const TRACK := "res://scenes/tracks/Track17.tscn"
const ZONE := "DecorManual/ZoneF_Bastion"

const F_IN := 0.588
const F_OUT := 0.699

const RES := {
	"fort_wall_segment": "s_fort_wall_segment",
	"fort_wall_turret": "s_fort_wall_turret",
	"fort_bastion": "s_fort_bastion",
	"palace_facade_a": "s_palace_facade_a",
	"palace_facade_b": "s_palace_facade_b",
	"rampart_cannon": "s_rampart_cannon",
	"peacock_closed": "s_peacock_closed",
	"peacock_fanned": "s_peacock_fanned",
	"marigold_garland": "s_marigold_garland",
	"rhyolite_boulder_a": "s_rhyolite_boulder_a",
	"rhyolite_boulder_b": "s_rhyolite_boulder_b",
	"rhyolite_boulder_c": "s_rhyolite_boulder_c",
}

var _track: Track
var _sampler: TrackSideSampler
var _terrain_rid: RID = RID()
var _sus_y := 0.0
var _out: Array[String] = []
var _lamp_pos := PackedVector3Array()
var _lamp_r := PackedFloat32Array()
var _lamp_s := PackedFloat32Array()
var _n := 0
var _skipped := 0
var _rng := RandomNumberGenerator.new()
var _out_path := ""
var _survey_only := false
var _mesh_only := false
var _total_len := 1.0
var _city := Vector3.ZERO
var _space: PhysicsDirectSpaceState3D


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out_path = a.trim_prefix("--out=")
		elif a == "--survey":
			_survey_only = true
		elif a == "--mesh":
			_mesh_only = true
	await get_tree().process_frame
	if _mesh_only:
		_mesh_report()
		get_tree().quit(0)
		return
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	_space = _track.get_world_3d().direct_space_state
	_sampler = _track._sampler
	var nd: int = _track.baked.size()
	if _track._dists.size() > nd:
		_total_len = float(_track._dists[nd])
	print("; lungime traseu %.1f m, %d puncte" % [_total_len, nd])
	var hi := -INF
	for bp in _track.baked:
		hi = maxf(hi, bp.y)
		_city += bp
	_city /= float(nd)
	_city.y = 0.0
	_sus_y = hi + 150.0
	_rng.seed = 300926
	_survey()
	if not _survey_only:
		_build()
		_lamps_node()
		_write()
	get_tree().quit(0)


# ------------------------------------------------------------------ geometrie

func _idx(frac: float) -> int:
	var n := _track.baked.size()
	return int(round(fposmod(frac, 1.0) * float(n))) % n


func _tangent(i: int) -> Vector3:
	var n := _track.baked.size()
	var d := _track.baked[(i + 2) % n] - _track.baked[(i - 2 + n) % n]
	d.y = 0.0
	return d.normalized()


## Stanga orizontala (tangenta x UP da dreapta, ca `Track._side_at`).
func _left(i: int) -> Vector3:
	var t := _tangent(i)
	return Vector3(t.z, 0.0, -t.x)


func _radius(i: int) -> float:
	var n := _track.baked.size()
	var a := _track.baked[(i - 4 + n) % n]
	var b := _track.baked[i]
	var c := _track.baked[(i + 4) % n]
	var A := Vector2(a.x, a.z)
	var B := Vector2(b.x, b.z)
	var C := Vector2(c.x, c.z)
	var cross := absf((B - A).cross(C - A))
	if cross < 1e-4:
		return 9999.0
	return (B - A).length() * (C - B).length() * (A - C).length() / (2.0 * cross)


func _slope(i: int) -> float:
	var n := _track.baked.size()
	var a := _track.baked[(i - 2 + n) % n]
	var b := _track.baked[(i + 2) % n]
	return (b.y - a.y) / maxf(Vector2(b.x - a.x, b.z - a.z).length(), 0.01)


func _s(i: int) -> float:
	return float(_track._dists[i])


## Distanta in plan de la q la muchia celui mai apropiat asfalt (negativ = pe
## asfalt), ignorand tronsoanele cu cota departe de `y`.
func _edge_dist(q: Vector3, dy_max: float = 30.0) -> float:
	var best := INF
	for j in _track.baked.size():
		var b := _track.baked[j]
		if absf(b.y - q.y) > dy_max:
			continue
		best = minf(best, Vector2(q.x - b.x, q.z - b.z).length() - _track.width_at_index(j))
	return best


func _survey() -> void:
	print("; oras (centroidul buclei) %s" % str(_city))
	print("; frac   i    x       z      y     semi  raza  panta%%  oras  | sol st 8/12/16/20/30/40 | sol dr 8/12/16/20/30/40")
	var f := 0.584
	while f <= 0.705 + 1e-6:
		var i := _idx(f)
		var p := _track.baked[i]
		var to_city := (_city - Vector3(p.x, 0, p.z)).normalized()
		var side := "st" if _left(i).dot(to_city) > 0.0 else "dr"
		var az := rad_to_deg(atan2(_tangent(i).cross(to_city).y, _tangent(i).dot(to_city)))
		var sl := ""
		var sr := ""
		for d: float in [8.0, 12.0, 16.0, 20.0, 30.0, 40.0]:
			var ql := p + _left(i) * d
			var qr := p - _left(i) * d
			sl += "%+5.1f " % (_sol_real(ql.x, ql.z) - p.y)
			sr += "%+5.1f " % (_sol_real(qr.x, qr.z) - p.y)
		print("; %.3f %4d %7.1f %7.1f %6.2f %5.2f %6.1f %5.1f %s%+4.0f | %s| %s" % [
			f, i, p.x, p.z, p.y, _track.width_at_index(i), _radius(i),
			100.0 * _slope(i), side, az, sl, sr])
		f += 0.002


# ------------------------------------------------------------------ piese

const WALL_H := 13.98
const WALL_LEN := 12.0
const WALL_HALF_T := 1.8
const WALL_MIN_LEN := 4.0
const SAG_MAX := 0.35
## Varfurile merloanelor lui `fort_wall_segment` (masurate de E pe GLB): z =
## -4,8 .. 4,8, varful la y 13,98, pe x 0,8..1,5 — merloanele sunt pe +X.
const MERLON_Z := [-4.8, -2.4, 0.0, 2.4, 4.8]
const MERLON_TIP_Y := 13.98
const MERLON_X := 1.15
const DIYA_R := 0.13
const NICHE_Z := [-3.6, 3.6]
const NICHE_Y := 7.5
const NICHE_R := 0.2
const NICHE_STRETCH := 1.4

## Zidul inalt de pe STANGA fatadei (nordul platoului): continua `zid82` al
## lui E (capatul lui din fata, masurat din transform: centru (102,63,
## -332,58) + axa Z (0,9686, -0,2486) x 6). Varful la +9 peste drum, ca la E.
const LEFT_START := Vector3(108.45, 0.0, -334.07)
const LEFT_TO := 0.611
const LEFT_TOP := 9.0
const LEFT_GAP := 2.0

## Fatada A pe DREAPTA fatadei, fata (+X, ferestrele Palace_Glow) spre drum.
## Fata la FACADE_FRONT m de ax (contract: 10-18 m), 40 m de la FACADE_A_FROM.
const FACADE_A_FROM := 0.5905
const FACADE_FRONT := 14.0
const FACADE_HALF_D := 4.2
## Fatada B: capatul vizual al dreptei fatadei, dincolo de coltul 0.622, pe
## partea din afara, cu fata spre masina care vine (directia drumului la
## FACADE_B_LOOK_FROM). Fata la FACADE_B_EDGE m de muchia asfaltului.
const FACADE_B_LOOK_FROM := 0.600
const FACADE_B_EDGE := 9.0

## Meterezele: parapet crenelat (varful merloanelor la PARAPET_TOP peste
## drum, ca parapetul lui E) pe DREAPTA bratului de intrare si a bratului de
## iesire, partea dinspre oras. Varful acului (PARAPET_A_TO..PARAPET_B_FROM)
## ramane DESCHIS: fara parapet pe varful bastionului (premisa 10, contract).
## Runda 1, prima incercare: un zid cu merloanele la cota drumului pe tot
## varful citea din camera ca un sir de conuri portocalii (captura w_0650).
const PARAPET_A_FROM := 0.634
const PARAPET_A_TO := 0.6555
const PARAPET_B_FROM := 0.6715
const PARAPET_B_TO := 0.690
const PARAPET_TOP := 2.4
## Parapetul bratului de iesire e mai jos: din cadrul-erou (0.650) el sta
## chiar in fata orasului, iar la +2,4 merloanele lui acopereau banda de jos
## a caselor (captura w2_0.650).
const PARAPET_B_TOP := 1.2
## Runda 2: scara uniforma a parapetilor de langa drum (merlon 1,2 x 0,8 m in
## loc de 1,2 x 1,2 cu calota de 1,5): varful ramane la PARAPET_TOP.
const PARAPET_SCALE := 0.65
## Coronamentul lui `fort_wall_segment` (masurat pe GLB, runda 2): drumul de
## straja la y 11,5 (x -1,1..0,8), buza interioara la 12,5 (x -1,5..-1,1),
## crenelurile la 12,8 (x 0,8..1,5), merloanele pana la 14,0.
const WALK_Y := 11.5
const LIP_X := -1.3
const LIP_Y := 12.5
const CRENEL_Y := 12.8
const CRENEL_Z := [-6.0, -3.6, -1.2, 1.2, 3.6, 6.0]
const ROW_R := 0.09
const ROW_STEP := 0.5
## Tunurile de pe zidul exterior (dreapta bratului de intrare, in cadrul-erou
## 0.650, plus unul pe bratul de iesire), scara si pozitia pe X fata de axa
## zidului (gura trece de fata exterioara cu ~0,9 m).
const WALL_CANNON_FRACS := [0.6435, 0.6485, 0.6535, 0.684]
const WALL_CANNON_SCALE := 1.1
const WALL_CANNON_X := 0.1
const PEACOCK_FRACS := [0.639, 0.678]
## Curtea dintre brate (interiorul acului): in capturile w3 era o pata de
## sol gol care domina jumatatea stanga a cadrului-erou. Parapet (+2,4) pe
## muchia interioara a fiecarui brat, oprit la ~20 m de varf. La +1,2 (w4)
## zidul era ingropat si ramaneau doar merloanele, un sir de „oua" pe sol.
const PARAPET_IN_A_FROM := 0.628
const PARAPET_IN_A_TO := 0.650
const PARAPET_IN_B_FROM := 0.680
const PARAPET_IN_B_TO := 0.692
const RIM_GAP := 2.5
## Bastionul: varful merloanelor la RIM_DROP SUB cota drumului.
const RIM_DROP := 0.1
## Bastionul rotund sub varful acului, pe partea din afara (spre oras).
const TIP_FRAC := 0.664
const BASTION_R := 9.39
const BASTION_TIP_Y := 13.79
const BASTION_FLOOR_Y := 12.45
const BASTION_MERLONS := 22
const BASTION_MERLON_R := 7.5
## Tunurile: 5, pe podeaua bastionului, evantai pe jumatatea dinspre oras,
## gura (+X) spre exterior.
const CANNONS := 5
const CANNON_R := 4.4
const CANNON_FAN_DEG := 110.0


func _build() -> void:
	_left_wall()
	_facade_a()
	_facade_b()
	_rim_and_bastion()


## Punctele liniei paralele cu axa pe partea `sgn` (+1 stanga), la `off` m
## peste semilatime, intre doua fractii.
func _offset_line(f0: float, f1: float, sgn: float, off: float) -> Array:
	var pts: Array[Vector3] = []
	var idx: Array[int] = []
	for i in range(_idx(f0), _idx(f1) + 1):
		pts.append(_track.baked[i] + _left(i) * sgn * (_track.width_at_index(i) + off))
		idx.append(i)
	return [pts, idx]


## Lant de ziduri pe coarda (tiparul E). `top_of(i)` = cota varfului
## merloanelor pentru indexul de traseu i; `outward` = +1 daca merloanele
## (+X) stau spre exterior (departe de drum).
func _wall_chain(pts: Array[Vector3], idx: Array[int], start: Array, sgn: float,
		kind: String) -> void:
	var cur := start
	var guard := 0
	# Parapetii de langa drum: zidul intreg la scara uniforma PARAPET_SCALE
	# (merloane mai mici, sa citeasca crenelaj, nu butoaie — critic runda 1).
	var sc := 1.0 if kind == "sus" else PARAPET_SCALE
	var nf := float(_track.baked.size())
	while int(cur[1]) < pts.size() - 1 and guard < 200:
		guard += 1
		var len := WALL_LEN * sc
		var nxt := _chord_next(pts, cur, len)
		while len > WALL_MIN_LEN * sc and _sag(pts, cur, nxt) > SAG_MAX:
			len *= 0.85
			nxt = _chord_next(pts, cur, len)
		var p0: Vector3 = cur[0]
		var p1: Vector3 = nxt[0]
		var ci: int = idx[clampi(int(round(float(int(cur[1]) + int(nxt[1])) * 0.5)), 0, idx.size() - 1)]
		cur = nxt
		var c := (p0 + p1) * 0.5
		var road := _track.baked[ci]
		c.y = road.y
		var dir := Vector3(p1.x - p0.x, 0.0, p1.z - p0.z).normalized()
		var toward_road := Vector3(road.x - c.x, 0.0, road.z - c.z).normalized()
		# +X (merloanele) spre exterior: departe de drum.
		var x := Vector3.UP.cross(dir).normalized()
		if x.dot(toward_road) > 0.0:
			x = -x
		var z := x.cross(Vector3.UP).normalized()
		if _in_bastion(c, len * 0.5):
			continue
		if not _footprint_clear(c, z, len * 0.5, WALL_HALF_T * sc, 1.5):
			_skipped += 1
			continue
		var top: float = road.y + float({"sus": LEFT_TOP, "parapet": PARAPET_TOP,
			"parapet_jos": PARAPET_B_TOP}[kind])
		var base_y := top - WALL_H * sc
		var wb := Basis(x * sc, Vector3.UP * sc, z * (len / WALL_LEN))
		var wpos := Vector3(c.x, base_y, c.z)
		_raw_basis("fort_wall_segment", "fzid", wpos, wb, "")
		if _sol_real(c.x, c.z) - base_y > 2.0:
			_meta_last("metadata/scufundat = true")
		for lz: float in MERLON_Z:
			_lamp(wpos + wb * Vector3(MERLON_X, MERLON_TIP_Y + DIYA_R * 0.8, lz), DIYA_R, 1.0)
		if kind == "sus" and len > 8.0:
			for nz: float in NICHE_Z:
				_lamp(wpos + wb * Vector3(-(WALL_HALF_T + 0.12), NICHE_Y, nz), NICHE_R, NICHE_STRETCH)
		if kind == "sus":
			continue
		var pf := float(ci) / nf
		# Runda 2 (critic): sir des de diya pe coronament, INTRE merloane:
		# cate una in fiecare crenel (coama la y 12,8, x 0,8..1,5) si un sir
		# continuu la ~0,5 m pe buza interioara (x -1,5..-1,1, y 12,5), fata
		# dinspre drum — acolo se vede din masina.
		for gz: float in CRENEL_Z:
			_lamp(wpos + wb * Vector3(MERLON_X, CRENEL_Y + ROW_R / sc, gz), ROW_R, 1.0)
		var step := ROW_STEP * WALL_LEN / len
		var lz := -6.0 + step * 0.5
		while lz < 6.0:
			_lamp(wpos + wb * Vector3(LIP_X, LIP_Y + ROW_R / sc, lz), ROW_R, 1.0)
			lz += step
		# Tunurile de pe metereze (runda 2): in crenelul de la z +1,2, pe
		# drumul de straja (y 11,5), gura (+X) prin crenel spre vale.
		for cf: float in WALL_CANNON_FRACS:
			if absf(pf - cf) < 0.5 * len / _total_len and not _cannon_done.has(cf):
				_cannon_done[cf] = true
				var cx := x.normalized()
				var cb := Basis(cx, Vector3.UP, cx.cross(Vector3.UP).normalized()).scaled(
					Vector3.ONE * WALL_CANNON_SCALE)
				var mz := 1.2 * len / WALL_LEN
				var cpos := wpos + z * mz + cx * WALL_CANNON_X + Vector3.UP * (WALK_Y * sc)
				_raw_basis("rampart_cannon", "tunZid", cpos, cb, "")
				print("; tun pe zid la frac %.4f, %.1f m de ax" % [pf,
					Vector2(cpos.x - road.x, cpos.z - road.z).length()])
		# Paunii: pe drumul de straja (y 11,5), inchisi (evantaiul verde citea
		# ca un disc plutitor — critic runda 1; si era la 12,75, nu pe piatra).
		for pk: float in PEACOCK_FRACS:
			if absf(pf - pk) < 0.5 * len / _total_len and not _cannon_done.has(-pk):
				_cannon_done[-pk] = true
				var pp := wpos + wb * Vector3(-0.2, WALK_Y, -3.6)
				_raw("peacock_closed", "paun", pp, atan2(z.x, z.z) + _rng.randf_range(-0.4, 0.4),
					1.0, "none")


func _left_wall() -> void:
	var ol := _offset_line(F_IN, LEFT_TO, 1.0, LEFT_GAP + WALL_HALF_T)
	var pts: Array[Vector3] = ol[0]
	var idx: Array[int] = ol[1]
	# Porneste din capatul lui zid82 (proiectat pe polilinie): fara suprapunere.
	var best := 0
	var bd := INF
	for k in pts.size():
		var d := Vector2(pts[k].x - LEFT_START.x, pts[k].z - LEFT_START.z).length()
		if d < bd:
			bd = d
			best = k
	print("; zid stanga: capatul lui E la %.2f m de linia F (punct %d)" % [bd, best])
	var start_pt := LEFT_START
	start_pt.y = pts[best].y
	_wall_chain(pts, idx, [start_pt, best], 1.0, "sus")


## Fatada pe coarda liniei paralele de pe dreapta.
func _facade_a() -> void:
	var ol := _offset_line(FACADE_A_FROM, FACADE_A_FROM + 0.04, -1.0,
		FACADE_FRONT + FACADE_HALF_D - 6.0)
	var pts: Array[Vector3] = ol[0]
	var idx: Array[int] = ol[1]
	var p0 := pts[0]
	var nxt := _chord_next(pts, [p0, 0], 40.0)
	var p1: Vector3 = nxt[0]
	var c := (p0 + p1) * 0.5
	var ci: int = idx[clampi(int(nxt[1]) / 2, 0, idx.size() - 1)]
	_place_facade("palace_facade_a", "fatadaA", c, ci, 40.0)


func _facade_b() -> void:
	var i0 := _idx(FACADE_B_LOOK_FROM)
	var look := _tangent(i0)
	# Linia fetei: perpendiculara pe `look`, cat mai aproape de colt, dar la
	# FACADE_B_EDGE de orice asfalt pe toata lungimea (44,7 m).
	var apex := _track.baked[_idx(0.622)]
	var perp := Vector3(-look.z, 0.0, look.x)
	var along := 0.0
	var ok := false
	var c := Vector3.ZERO
	while along < 80.0:
		c = apex + look * along
		# Centrul pe latime: impins spre stanga (in afara coltului) pana nu
		# mai prinde drumul.
		var clear := true
		for u: float in [-1.0, -0.5, 0.0, 0.5, 1.0]:
			var q := c + perp * (u * 22.35)
			q.y = apex.y
			if _edge_dist(q) < FACADE_B_EDGE:
				clear = false
				break
		if clear:
			ok = true
			break
		along += 0.5
	if not ok:
		print("; fatada B: nu incape")
		return
	# Fata e linia gasita; centrul piesei e cu FACADE_HALF_D in spate.
	var center := c + look * FACADE_HALF_D
	center.y = apex.y
	var x := -look
	var z := x.cross(Vector3.UP).normalized()
	var base := apex.y - 0.3
	var pos := Vector3(center.x, base, center.z)
	_raw_basis("palace_facade_b", "fatadaB", pos, Basis(x, Vector3.UP, z), "")
	_meta_last("metadata/ancora_sol = Vector3(%.2f, 0, 0)" % FACADE_HALF_D)
	print("; fatada B: fata la %.1f m dincolo de colt, centru %s" % [along, str(pos)])


func _place_facade(model: String, base: String, c: Vector3, ci: int, length: float) -> void:
	var road := _track.baked[ci]
	var toward := Vector3(road.x - c.x, 0.0, road.z - c.z).normalized()
	# Axa lunga (Z) pe coarda, +X spre drum.
	var x := toward
	var z := x.cross(Vector3.UP).normalized()
	var pos := Vector3(c.x, road.y - 0.3, c.z)
	var front := c + x * FACADE_HALF_D
	front.y = road.y
	var dmin := INF
	for u: float in [-1.0, -0.5, 0.0, 0.5, 1.0]:
		dmin = minf(dmin, _edge_dist(front + z * (u * length * 0.5)))
	_raw_basis(model, base, pos, Basis(x, Vector3.UP, z), "")
	# Fatada sta cu spatele in stanca (terenul urca spre dreapta): baza
	# vizibila e muchia de jos a FETEI (+X), acolo se judeca plutit/ingropat.
	_meta_last("metadata/ancora_sol = Vector3(%.2f, 0, 0)" % FACADE_HALF_D)
	print("; %s: centru %s, fata la min %.1f m de muchia asfaltului" % [model, str(pos), dmin])


var _bastion_c := Vector3.INF
var _cannon_done := {}


func _in_bastion(c: Vector3, half_len: float) -> bool:
	if _bastion_c == Vector3.INF:
		return false
	return Vector2(c.x - _bastion_c.x, c.z - _bastion_c.z).length() < BASTION_R + half_len * 0.6


func _rim_and_bastion() -> void:
	var n := _track.baked.size()
	var ti := _idx(TIP_FRAC)
	var p := _track.baked[ti]
	var a := _track.baked[(ti - 6 + n) % n]
	var b := _track.baked[(ti + 6) % n]
	var mid := (a + b) * 0.5
	var out := Vector3(p.x - mid.x, 0.0, p.z - mid.z).normalized()
	var dist := _track.width_at_index(ti) + RIM_GAP + BASTION_R
	var c := p + out * dist
	c.y = p.y
	_bastion_c = c
	var top := p.y - RIM_DROP
	var base_y := top - BASTION_TIP_Y
	var yaw := atan2(out.x, out.z)
	var bb := Basis.from_euler(Vector3(0.0, yaw, 0.0))
	var bpos := Vector3(c.x, base_y, c.z)
	# `mesh`: podeaua dintre merloane e fata reala, pe ea stau tunurile (cu
	# hull-ul convex, podeaua ar fi inauntrul corpului).
	_raw_basis("fort_bastion", "bastion", bpos, bb, "mesh")
	if _sol_real(c.x, c.z) - base_y > 2.0:
		_meta_last("metadata/scufundat = true")
	print("; bastion: centru %s, iesire %s, sol la centru %+.1f fata de drum, marginea la %.1f m de asfalt" % [
		str(bpos), str(out), _sol_real(c.x, c.z) - p.y, _edge_dist(c) - BASTION_R])
	for k in BASTION_MERLONS:
		var ang := TAU * float(k) / float(BASTION_MERLONS)
		_lamp(bpos + Vector3(cos(ang) * BASTION_MERLON_R, BASTION_TIP_Y + DIYA_R * 0.8,
			sin(ang) * BASTION_MERLON_R), DIYA_R, 1.0)
	# Tunurile: evantai pe jumatatea dinspre exterior, gura spre exterior.
	var floor_y := base_y + BASTION_FLOOR_Y
	for k in CANNONS:
		var t := (float(k) / float(CANNONS - 1) - 0.5) * deg_to_rad(CANNON_FAN_DEG)
		var dir := out.rotated(Vector3.UP, t)
		var cp := c + dir * CANNON_R
		var cx := dir
		var cz := cx.cross(Vector3.UP).normalized()
		_raw_basis("rampart_cannon", "tun", Vector3(cp.x, floor_y, cp.z),
			Basis(cx, Vector3.UP, cz), "")
	# Parapetii de pe cele doua brate, varful ramane deschis.
	# [de la, pana la, fel, parte (+1 stanga)]. Parapetii interiori (stanga
	# ambelor brate, spre curtea dintre ele) sunt joasi si se opresc departe de
	# ac (PARAPET_IN_*), unde AI-ul taie interiorul: fara capete de zid acolo.
	for run: Array in [[PARAPET_A_FROM, PARAPET_A_TO, "parapet", -1.0],
			[PARAPET_B_FROM, PARAPET_B_TO, "parapet_jos", -1.0],
			[PARAPET_IN_A_FROM, PARAPET_IN_A_TO, "parapet", 1.0],
			[PARAPET_IN_B_FROM, PARAPET_IN_B_TO, "parapet", 1.0]]:
		var sg: float = run[3]
		var ol := _offset_line(float(run[0]), float(run[1]), sg,
			RIM_GAP + WALL_HALF_T * PARAPET_SCALE)
		var pts: Array[Vector3] = ol[0]
		var idx: Array[int] = ol[1]
		_wall_chain(pts, idx, [pts[0], 0], sg, str(run[2]))


## Cat se departeaza polilinia de coarda cur..nxt (m, in plan).
func _sag(pts: Array[Vector3], cur: Array, nxt: Array) -> float:
	var p0: Vector3 = cur[0]
	var p1: Vector3 = nxt[0]
	var a := Vector2(p0.x, p0.z)
	var d := Vector2(p1.x, p1.z) - a
	var l := d.length()
	if l < 1e-3:
		return 0.0
	d /= l
	var worst := 0.0
	for k in range(int(cur[1]) + 1, mini(int(nxt[1]) + 1, pts.size())):
		var q := Vector2(pts[k].x, pts[k].z) - a
		worst = maxf(worst, absf(q.x * d.y - q.y * d.x))
	return worst


func _chord_next(pts: Array[Vector3], cur: Array, len: float) -> Array:
	var p0: Vector3 = cur[0]
	var k: int = maxi(int(cur[1]), 0)
	while k + 1 < pts.size():
		var q := pts[k + 1]
		if Vector2(q.x - p0.x, q.z - p0.z).length() >= len:
			var lo := pts[k]
			var hi := q
			for _i in 30:
				var m := (lo + hi) * 0.5
				if Vector2(m.x - p0.x, m.z - p0.z).length() >= len:
					hi = m
				else:
					lo = m
			return [hi, k]
		k += 1
	var last := pts[pts.size() - 1]
	var d := last - pts[pts.size() - 2]
	d.y = 0.0
	d = d.normalized()
	var w := Vector2(last.x - p0.x, last.z - p0.z)
	var dv := Vector2(d.x, d.z)
	var bq := w.dot(dv)
	var cq := w.length_squared() - len * len
	var t := -bq + sqrt(maxf(bq * bq - cq, 0.0))
	return [last + d * t, pts.size() - 1]


## Dreptunghiul (centru c, axa lunga z, semi-lungime hl, semi-latime hw) sta la
## cel putin `keep` m de muchia ORICARUI tronson de asfalt (in plan)?
func _footprint_clear(c: Vector3, z: Vector3, hl: float, hw: float,
		keep: float) -> bool:
	var x := Vector3.UP.cross(z).normalized()
	for u: float in [-1.0, -0.5, 0.0, 0.5, 1.0]:
		for v: float in [-1.0, 0.0, 1.0]:
			var q := c + z * (u * hl) + x * (v * hw)
			q.y = c.y
			if _edge_dist(q) < keep:
				return false
	return true


# ------------------------------------------------------------------ iesire

func _raw(model: String, base: String, pos: Vector3, yaw: float, scl: float,
		mode: String) -> void:
	var b := Basis.from_euler(Vector3(0.0, yaw, 0.0)).scaled(Vector3(scl, scl, scl))
	_raw_basis(model, base, pos, b, mode)


func _raw_basis(model: String, base: String, pos: Vector3, b: Basis,
		mode: String) -> void:
	_n += 1
	_out.append('[node name="%s%d" parent="%s" instance=ExtResource("%s")]'
		% [base, _n, ZONE, RES[model]])
	# RANDURILE bazei, nu coloanele (memoria tscn-transform-e-pe-randuri).
	_out.append("transform = Transform3D(%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)"
		% [b.x.x, b.y.x, b.z.x, b.x.y, b.y.y, b.z.y, b.x.z, b.y.z, b.z.z,
			pos.x, pos.y, pos.z])
	if mode != "" and mode != "hull":
		_out.append('metadata/coliziune = "%s"' % mode)
	_out.append("")


func _lamp(p: Vector3, r: float, st: float) -> void:
	_lamp_pos.append(p)
	_lamp_r.append(r)
	_lamp_s.append(st)


func _lamps_node() -> void:
	if _lamp_pos.is_empty():
		return
	_out.append('[node name="LampiBastion" type="Node3D" parent="%s"]' % ZONE)
	_out.append('script = ExtResource("e_fort_lamps")')
	var ps: Array[String] = []
	for v in _lamp_pos:
		ps.append("%.3f, %.3f, %.3f" % [v.x, v.y, v.z])
	_out.append("positions = PackedVector3Array(%s)" % ", ".join(ps))
	var rs: Array[String] = []
	for v in _lamp_r:
		rs.append("%.2f" % v)
	_out.append("radii = PackedFloat32Array(%s)" % ", ".join(rs))
	var ss: Array[String] = []
	for v in _lamp_s:
		ss.append("%.2f" % v)
	_out.append("stretch = PackedFloat32Array(%s)" % ", ".join(ss))
	_out.append("")
	print("; lampi: %d" % _lamp_pos.size())


func _meta_last(line: String) -> void:
	_out.insert(_out.size() - 1, line)


func _write() -> void:
	print("; asezate %d piese, %d sarite" % [_n, _skipped])
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
		Vector3(x, _sus_y, z), Vector3(x, _sus_y - 1200.0, z))
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
	return _sampler.ground_y(x, z)


# ------------------------------------------------------------------ --mesh

func _mesh_report() -> void:
	for path in ["structures/palace_facade_a", "structures/palace_facade_b",
			"structures/fort_bastion", "props/rampart_cannon",
			"structures/fort_wall_segment", "animals/peacock_closed",
			"props/zipline_rider", "animals/black_kite_bird"]:
		var root := (load("res://assets/models/jodhpur/%s.glb" % path) as PackedScene).instantiate()
		add_child(root)
		print("; ===== %s" % path)
		for mi in root.find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			var xf := _xf_to(m, root)
			var lo := Vector3(INF, INF, INF)
			var hi := -lo
			var cnt := 0
			var ctr := Vector3.ZERO
			for s in m.mesh.get_surface_count():
				var arr := m.mesh.surface_get_arrays(s)
				var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				for w in v:
					var pw := xf * w
					lo = lo.min(pw)
					hi = hi.max(pw)
					ctr += pw
					cnt += 1
			print(";   %s (%d v) AABB %s .. %s, centru %s" % [m.name, cnt, str(lo),
				str(hi), str(ctr / maxf(cnt, 1))])
		root.queue_free()


func _xf_to(n: Node3D, root: Node) -> Transform3D:
	var xf := n.transform
	var p := n.get_parent()
	while p != null and p != root:
		if p is Node3D:
			xf = (p as Node3D).transform * xf
		p = p.get_parent()
	return xf
