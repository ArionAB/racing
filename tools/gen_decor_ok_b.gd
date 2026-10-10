extends Node
## Generator de decor pentru POI B -- Aleea de fukugi (Track20, Okinawa).
##   godot --headless --path . res://tools/GenDecorOkB.tscn -- --out=<fisier>
##
## Iesirea e un fragment .tscn (ext_resource cu id `b_*` + noduri sub
## `DecorManual/ZonaB`), lipit in Track20.tscn de `tools/splice_ok_b.py`.
##
## Contract (okinawa_poi_gauntlet.md §B): aleea de nisip (semi 5,5) intre doua
## ziduri joase de corali (v = 2,8 m de la marginea asfaltului), apoi RANDURI
## DESE de fukugi la pas ~3,1 m: randul 1 (trunchi cu coliziune) la v ~4,0,
## randul 2 la ~6,9 (decalat, fara coliziune), randul 3 la ~9,8 (jumatate din
## densitate). Coroanele de 2,8-3,0 m se ating -> perete verde continuu.
## Case Ryukyu in 4 goluri ale randurilor (curti peste zid), bougainvillea
## revarsata peste zid (coliziune none), hibiscus si cicade in petice.
## Coordonate (u, v): u = fractie pe index, v = metri de la marginea asfaltului.

const SCENE := "res://scenes/tracks/Track20.tscn"
const ZONE := "DecorManual/ZonaB"
const LEN := 2058.3

const M_OK := "res://assets/models/okinawa/"
const RES := {
	"hibiscus": "res://assets/models/plants/hibiscus_bush.glb",
	"cycad": M_OK + "plants/cycad.glb",
	"bougainvillea": M_OK + "plants/bougainvillea.glb",
	"fukugi_a": M_OK + "plants/fukugi_tree_a.glb",
	"fukugi_b": M_OK + "plants/fukugi_tree_b.glb",
	"fukugi_c": M_OK + "plants/fukugi_tree_c.glb",
	"ryukyu_a": M_OK + "buildings/ryukyu_house_a.glb",
	"ryukyu_b": M_OK + "buildings/ryukyu_house_b.glb",
	"ryukyu_c": M_OK + "buildings/ryukyu_house_c.glb",
	"wall": M_OK + "structures/coral_stone_wall.glb",
	"mirror": M_OK + "props/convex_mirror.glb",
	"fan_palm": M_OK + "plants/fan_palm.glb",
}

const U0 := 0.1032
const U1 := 0.2040
const WALL_V := 2.8
const PITCH := 3.1
## [v, faza (0.5 = decalat cu jumatate de pas), fiecare al k-lea, coliziune]
const ROWS := [[4.0, 0.0, 1, true], [6.9, 0.5, 1, false], [9.8, 0.0, 2, false]]
## goluri in randurile de fukugi pentru curti: [u, parte (+1 dreapta/-1 stanga), tip casa, v centru]
const GAPS := [
	[0.1130, 1.0, "ryukyu_c", 12.0], [0.1330, 1.0, "ryukyu_a", 12.5],
	[0.1560, 1.0, "ryukyu_b", 13.0], [0.1750, 1.0, "ryukyu_c", 12.0],
	[0.1220, -1.0, "ryukyu_a", 12.5], [0.1450, -1.0, "ryukyu_b", 13.0],
	[0.1660, -1.0, "ryukyu_c", 12.0], [0.1930, -1.0, "ryukyu_a", 12.5],
]
const GAP_HALF := 8.2   # m, jumatate din golul din randuri

var tr: Track
var n: int
var rng := RandomNumberGenerator.new()
var out := PackedStringArray()
var used_res := {}
var counts := {}
var discs: Array[Vector3] = []
var report := PackedStringArray()
var gap_pts: Array = []   # [Vector2 (x,z), parte]


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	tr = (load(SCENE) as PackedScene).instantiate() as Track
	add_child(tr)
	for k in 4:
		await get_tree().process_frame
	n = tr.baked.size()
	for a in args:
		if a.begins_with("--out="):
			_generate(a.substr(6))
	get_tree().quit(0)


# ---------------------------------------------------------------------------
# geometrie de drum

func _lerp_i(u: float) -> Array:
	var f := u * float(n)
	var i := int(floor(f)) % n
	return [i, f - floor(f)]


## Punct la (u, v): v = metri de la MARGINEA asfaltului, + dreapta (interior), - stanga.
func _pos(u: float, v: float) -> Vector3:
	var li := _lerp_i(u)
	var i: int = li[0]
	var t: float = li[1]
	var q: Vector3 = (tr.baked[i] as Vector3).lerp(tr.baked[(i + 1) % n], t)
	var s: Vector3 = tr._side_at(i)
	var hw: float = tr.width_at_index(i)
	var p := q + s * ((hw + v) if v >= 0.0 else (-hw + v))
	p.y = tr._terrain_mesh_y(p.x, p.z)
	return p


func _heading(u: float) -> Vector3:
	var i: int = _lerp_i(u)[0]
	var d: Vector3 = (tr.baked[(i + 1) % n] - tr.baked[i])
	d.y = 0.0
	return d.normalized()


## (u, v) al unui punct de lume; pe asfalt v = 0.
func _uv(p: Vector3) -> Vector2:
	var i: int = tr.closest_index_global(p)
	var q: Vector3 = tr.baked[i]
	var s: Vector3 = tr._side_at(i)
	var hw: float = tr.width_at_index(i)
	var lat := (p - q).dot(s)
	var v := signf(lat) * maxf(absf(lat) - hw, 0.0)
	return Vector2(float(i) / float(n), v)


func _edge_dist(p: Vector3) -> float:
	var i: int = tr.closest_index_global(p)
	var q: Vector3 = tr.baked[i]
	return Vector2(p.x - q.x, p.z - q.z).length() - tr.width_at_index(i)


func _occupied(p: Vector3, extra := 0.0) -> bool:
	for d in discs:
		if Vector2(p.x - d.x, p.z - d.y).length() < d.z + extra:
			return true
	return false


func _in_gap(p: Vector3, side: float) -> bool:
	for g in gap_pts:
		if float(g[1]) == side and Vector2(p.x - g[0].x, p.z - g[0].z).length() < GAP_HALF:
			return true
	return false


# ---------------------------------------------------------------------------
# emitere

func _res_id(key: String) -> String:
	used_res[key] = true
	return "b_" + key


func _count(k: String, c := 1) -> void:
	counts[k] = int(counts.get(k, 0)) + c


func _group(gname: String) -> void:
	out.append('[node name="%s" type="Node3D" parent="%s"]' % [gname, ZONE])
	out.append("")


func _prop(group: String, nname: String, key: String, p: Vector3, yaw: float, sc := Vector3.ONE, sink := 0.0, extra := "") -> void:
	var b := Basis(Vector3.UP, yaw) * Basis.from_scale(sc)
	var xf := Transform3D(b, Vector3(p.x, p.y - sink, p.z))
	out.append('[node name="%s" parent="%s/%s" instance=ExtResource("%s")]' % [nname, ZONE, group, _res_id(key)])
	out.append("transform = " + var_to_str(xf))
	if extra != "":
		out.append(extra)
	out.append("")
	_count(key)


## Rand de fukugi pe o parte: mers pe lungimea reala a randului (nu pe u), ca
## pasul sa ramana ~PITCH si pe curbe.
func _fukugi_row(ri: int, side: float, fn: int) -> int:
	var row: Array = ROWS[ri]
	var v: float = row[0]
	var every: int = row[2]
	var coll: bool = row[3]
	var grp := "Fukugi%d" % (ri + 1)
	var last := Vector3(INF, 0, INF)
	if float(row[1]) > 0.0:
		# decalaj de faza: "ultima" piesa fictiva la 1 - faza pasi inapoi
		last = _pos(U0, side * v)
		last -= _heading(U0) * ((1.0 - float(row[1])) * PITCH * every)
	var u := U0
	var made := 0
	while u < U1:
		var p := _pos(u, side * v)
		if Vector2(p.x - last.x, p.z - last.z).length() >= PITCH * every:
			last = p
			var jv := rng.randf_range(-0.3, 0.3)
			var jl := rng.randf_range(-0.3, 0.3)
			var pp := _pos(u + jl / LEN, side * (v + jv))
			var uv := _uv(pp)
			var ok := absf(absf(uv.y) - (v + jv)) <= 1.6 and absf(uv.x - u) <= 0.005
			if ok and not _in_gap(pp, side) and not _occupied(pp, 0.0):
				var variant: String = ["a", "b", "c", "c"][rng.randi() % 4]
				var h := rng.randf_range(1.0, 1.15)
				var w := rng.randf_range(1.12, 1.28)
				if variant == "c":
					h = rng.randf_range(0.95, 1.08)
					w = rng.randf_range(1.35, 1.55)
				_prop(grp, "bFukugi%03d" % (fn + made), "fukugi_" + variant, pp,
					rng.randf() * TAU, Vector3(w, h, w), 0.15,
					"" if coll else 'metadata/coliziune = "none"')
				made += 1
		u += 0.35 / LEN
	return made


## Zid de corali la v fix, segmente de ~3,9 m.
func _wall_line(wn: int, u0: float, u1: float, v: float) -> int:
	var made := 0
	var uu := u0
	var prev := _pos(uu, v)
	while uu < u1:
		uu = minf(uu + 3.9 / LEN, u1)
		var cur := _pos(uu, v)
		made += _wall_seg(wn + made, prev, cur)
		prev = cur
	return made


func _wall_seg(wn: int, a: Vector3, b: Vector3) -> int:
	var d := b - a
	d.y = 0.0
	var length := d.length()
	if length < 1.0:
		return 0
	var dir := d / length
	var c := (a + b) * 0.5
	c.y = tr._terrain_mesh_y(c.x, c.z)
	if _edge_dist(c) < 2.5:
		return 0
	var yaw := atan2(dir.x, dir.z)
	var b2 := Basis(Vector3.UP, yaw) * Basis.from_scale(Vector3(1.0, 1.0, length / 4.0 * 1.03))
	out.append('[node name="bZid%03d" parent="%s/Ziduri" instance=ExtResource("%s")]' % [wn, ZONE, _res_id("wall")])
	out.append("transform = " + var_to_str(Transform3D(b2, Vector3(c.x, c.y - 0.12, c.z))))
	out.append("")
	_count("wall")
	return 1


func _generate(path: String) -> void:
	rng.seed = 20261012
	for g in GAPS:
		var gp := _pos(float(g[0]), float(g[1]) * 6.0)
		gap_pts.append([Vector3(gp.x, 0.0, gp.z), float(g[1])])

	_group("Ziduri")
	_group("Fukugi1")
	_group("Fukugi2")
	_group("Fukugi3")
	_group("Case")
	_group("Flori")

	# --- ziduri de corali pe ambele laturi (continue)
	var wn := 0
	for side: float in [1.0, -1.0]:
		wn += _wall_line(wn, U0, U1, side * WALL_V)

	# --- case in goluri (curti): fata spre drum
	var hn := 0
	for g in GAPS:
		var gu := float(g[0])
		var gs := float(g[1])
		var hp := _pos(gu, gs * float(g[3]))
		var d := _pos(gu, gs * 2.0) - hp
		d.y = 0.0
		d = d.normalized()
		var yw := atan2(-d.x, -d.z) + rng.randf_range(-0.08, 0.08)
		_prop("Case", "bCasa%d" % hn, String(g[2]), hp, yw, Vector3.ONE, 0.25)
		discs.append(Vector3(hp.x, hp.z, 7.5))
		# cicade si hibiscus in curte, spre zid
		for k in 3:
			var cp := _pos(gu + rng.randf_range(-7.0, 7.0) / LEN, gs * rng.randf_range(5.5, 8.5))
			var s := rng.randf_range(1.0, 1.4)
			_prop("Flori", "bCicada_g%d_%d" % [hn, k], "cycad", cp, rng.randf() * TAU, Vector3(s, s, s), 0.1, 'metadata/coliziune = "none"')
		for k in 2:
			var hpz := _pos(gu + rng.randf_range(-8.0, 8.0) / LEN, gs * rng.randf_range(4.0, 6.0))
			var s2 := rng.randf_range(1.2, 1.6)
			_prop("Flori", "bHibiscus_g%d_%d" % [hn, k], "hibiscus", hpz, rng.randf() * TAU, Vector3(s2, s2, s2), 0.05)
		# 1-2 palmieri-evantai langa casa, spre drum
		for k in rng.randi_range(1, 2):
			var pp := _pos(gu + (rng.randf_range(-6.5, 6.5)) / LEN, gs * rng.randf_range(5.0, 6.5))
			if _edge_dist(pp) < 4.0:
				continue
			var ps := rng.randf_range(1.1, 1.4)
			_prop("Flori", "bPalmier_g%d_%d" % [hn, k], "fan_palm", pp, rng.randf() * TAU, Vector3(ps, ps, ps), 0.1, 'metadata/coliziune = "none"')
		hn += 1

	# --- fukugi: 3 randuri pe fiecare parte
	var fn := 0
	for ri in ROWS.size():
		for side: float in [1.0, -1.0]:
			fn += _fukugi_row(ri, side, fn)

	# --- banda 11-26 m: pâlcuri de fukugi (3-4) + tufe, ca solul dintre randuri
	# si decorul de fundal sa nu ramana gol (lectia valului 1)
	var gn := 0
	var un := 0
	for side: float in [1.0, -1.0]:
		var uu := U0 + rng.randf_range(0.0, 0.004)
		var k_cl := 0
		while uu < U1:
			var cv := side * rng.randf_range(12.0, 22.0)
			var cp := _pos(uu, cv)
			var uv0 := _uv(cp)
			if absf(absf(uv0.y) - absf(cv)) <= 1.6 and not _in_gap(cp, side) and not _occupied(cp, 0.0):
				if k_cl % 2 == 0:
					for t in rng.randi_range(3, 4):
						var tp := cp + Vector3(rng.randf_range(-3.2, 3.2), 0, rng.randf_range(-3.2, 3.2))
						tp.y = tr._terrain_mesh_y(tp.x, tp.z)
						if _in_gap(tp, side) or _edge_dist(tp) < 9.0:
							continue
						var vr: String = ["a", "b", "c"][rng.randi() % 3]
						var w2 := rng.randf_range(1.1, 1.3)
						_prop("Fukugi3", "bFukugiG%03d" % gn, "fukugi_" + vr, tp, rng.randf() * TAU, Vector3(w2, rng.randf_range(0.95, 1.15), w2), 0.15, 'metadata/coliziune = "none"')
						gn += 1
				for t in rng.randi_range(2, 4):
					var tp2 := cp + Vector3(rng.randf_range(-4.0, 4.0), 0, rng.randf_range(-4.0, 4.0))
					tp2.y = tr._terrain_mesh_y(tp2.x, tp2.z)
					if _in_gap(tp2, side) or _edge_dist(tp2) < 9.0:
						continue
					var kk := rng.randi() % 3
					var sc := rng.randf_range(1.0, 1.5)
					var key := "cycad" if kk == 0 else ("hibiscus" if kk == 1 else "bougainvillea")
					_prop("Flori", "bTufa%03d" % un, key, tp2, rng.randf() * TAU, Vector3(sc, sc, sc), 0.08, 'metadata/coliziune = "none"')
					un += 1
			k_cl += 1
			uu += rng.randf_range(9.0, 14.0) / LEN

	# --- bougainvillea revarsata peste zid (coliziune none), petice neregulate
	var bn := 0
	for side: float in [1.0, -1.0]:
		var uu := U0 + rng.randf_range(0.0, 0.004)
		while uu < U1:
			var cnt := rng.randi_range(1, 2)
			for k in cnt:
				var bu := uu + float(k) * rng.randf_range(2.2, 3.2) / LEN
				var bp := _pos(bu, side * rng.randf_range(3.1, 3.5))
				if _edge_dist(bp) < 2.9:
					continue
				var bd := _pos(bu, 0.0) - bp
				bd.y = 0.0
				bd = bd.normalized()
				var bs := rng.randf_range(1.15, 1.45)
				_prop("Flori", "bBougainvillea%02d" % bn, "bougainvillea", bp, atan2(-bd.x, -bd.z), Vector3(bs, bs, bs), 0.05, 'metadata/coliziune = "none"')
				bn += 1
			uu += rng.randf_range(11.0, 19.0) / LEN
	# --- banda inflorita intre bordura si zid (v 0.9-2.4): palcuri dese de
	# 5-10 piese pe ~50 % din lungime, coliziune none
	var fb := 0
	for side: float in [1.0, -1.0]:
		var uu := U0 + rng.randf_range(0.0, 0.003)
		while uu < U1:
			var len_m := rng.randf_range(7.0, 11.0)
			var npc := rng.randi_range(5, 10)
			for k in npc:
				var fu := uu + rng.randf_range(0.0, len_m) / LEN
				var kk := rng.randi() % 5
				var fv := side * rng.randf_range(1.5, 2.3)
				if kk == 2:
					fv = side * rng.randf_range(2.3, 2.6)
				elif kk >= 3:
					fv = side * rng.randf_range(2.0, 2.4)
				var p := _pos(fu, fv)
				if absf(absf(_uv(p).y) - absf(fv)) > 1.0 or _edge_dist(p) < 1.4:
					continue
				var key := "hibiscus"
				if kk >= 3:
					key = "bougainvillea"
				elif kk == 2:
					key = "cycad"
				var sc := rng.randf_range(0.9, 1.15)
				var yaw := rng.randf() * TAU
				if key == "bougainvillea":
					var bd := _pos(fu, 0.0) - p
					bd.y = 0.0
					bd = bd.normalized()
					yaw = atan2(-bd.x, -bd.z)
				_prop("Flori", "bBanda%03d" % fb, key, p, yaw, Vector3(sc, sc, sc), 0.05, 'metadata/coliziune = "none"')
				fb += 1
			uu += (len_m + rng.randf_range(6.0, 12.0)) / LEN
	# --- hibiscus in petice la baza zidului, spre asfalt (v 1.7-2.3), coliziune none
	var hb := 0
	for side: float in [1.0, -1.0]:
		var uu := U0 + rng.randf_range(0.002, 0.01)
		while uu < U1:
			for k in rng.randi_range(2, 3):
				var p := _pos(uu + rng.randf_range(-2.0, 2.0) / LEN, side * rng.randf_range(1.7, 2.3))
				if _edge_dist(p) < 1.5:
					continue
				var s := rng.randf_range(1.1, 1.5)
				_prop("Flori", "bHibiscus%02d" % hb, "hibiscus", p, rng.randf() * TAU, Vector3(s, s, s), 0.05, 'metadata/coliziune = "none"')
				hb += 1
			uu += rng.randf_range(24.0, 44.0) / LEN
	# --- oglinda convexa la sicana (0.1803), pe exteriorul curbei
	var h0 := _heading(0.1803 - 0.01)
	var h1 := _heading(0.1803 + 0.01)
	var s_of: Vector3 = tr._side_at(_lerp_i(0.1803)[0])
	# viraj spre latura `s` daca h1 are componenta pe s; exteriorul = opusul
	var toward := signf((h1 - h0).dot(s_of))
	var outer := -toward
	var mp := _pos(0.1803, outer * 3.2)
	var md := _pos(0.1803, 0.0) - mp
	md.y = 0.0
	md = md.normalized()
	_prop("Flori", "bOglinda", "mirror", mp, atan2(-md.x, -md.z), Vector3.ONE, 0.03)
	report.append("sicana: viraj spre v%+.0f, oglinda pe v=%.1f" % [toward, outer * 3.2])

	var head := PackedStringArray()
	for k in used_res:
		head.append('[ext_resource type="PackedScene" path="%s" id="b_%s"]' % [RES[k], k])
	var fo := FileAccess.open(path, FileAccess.WRITE)
	fo.store_string("\n".join(head) + "\n###NODES###\n" + "\n".join(out))
	fo.close()
	print("--- raport generator ---")
	for r in report:
		print("  ", r)
	print("  piese: ", counts)
