extends Node
## Generator de decor pentru POI D — Castelul si poarta (Track20, Okinawa).
##   godot --headless --path . res://tools/GenDecorOkD.tscn -- --out=<fisier>
## Iesirea e un fragment (ext_resource `d_*` + noduri sub `DecorManual/ZonaD`),
## lipit in Track20.tscn de `tools/splice_ok_d.py`.
##
## Ziduri gusuku: LANTURI de module (drept 12 m, curb A R=20, curb B R=40),
## inlantuite pe capete (matematica din tools/blender/preview_okinawa.py
## wall_chain). Un cautator cu orizont de 3 module alege, la fiecare pas, modulul
## care tine lantul pe o curba-tinta sinuoasa la 8-15 m de marginea asfaltului,
## cu fata zidului la >= 6 m de asfalt (penalizat tare). Cadrul de calcul e Blender
## (X, Y = -z); yaw-ul Blender r = yaw-ul Godot. Wall_B are nodul deplasat +10 m
## pe X in GLB: originea instantei se corecteaza.

const SCENE := "res://scenes/tracks/Track20.tscn"
const ZONE := "DecorManual/ZonaD"
const LEN := 2058.3
const M_OK := "res://assets/models/okinawa/"
const RES := {
	"straight": M_OK + "structures/gusuku_wall_straight.glb",
	"curve": M_OK + "structures/gusuku_wall_curve.glb",
	"arch": M_OK + "structures/gusuku_arch_gate.glb",
	"palace": M_OK + "buildings/ryukyu_palace.glb",
	"pine": M_OK + "plants/ryukyu_pine.glb",
	"fukugi_a": M_OK + "plants/fukugi_tree_a.glb",
	"fukugi_b": M_OK + "plants/fukugi_tree_b.glb",
	"fukugi_c": M_OK + "plants/fukugi_tree_c.glb",
	"cycad": M_OK + "plants/cycad.glb",
	"bougainvillea": M_OK + "plants/bougainvillea.glb",
	"banyan": "res://assets/models/trees/banyan.glb",
	"hibiscus": "res://assets/models/plants/hibiscus_bush.glb",
	"shisa": "res://assets/models/props/shisa_statue.glb",
	"shisa_c": "res://assets/models/props/shisa_statue_closed.glb",
}
const R_A := 20.0
const R_B := 40.0
const GATE_U := 0.4298
const PAL_U := 0.4125
const PAL_V := -30.0
const MIN_CLEAR := 6.0      # fata zidului la >= 6 m de asfalt
const HALF_T := 1.45        # jumatate de grosime + marja
const SINK := 0.35
const SY := 0.85            # inaltime zid 6,8 m (contract 6-10)

var tr: Track
var n: int
var rng := RandomNumberGenerator.new()
var out := PackedStringArray()
var used_res := {}
var counts := {}
var report := PackedStringArray()
var mods: Array = []
var road_p := PackedVector2Array()   # (x, z) Godot, indici i0..i1
var road_hw := PackedFloat32Array()
var wall_pts: Array[Vector2] = []    # Godot (x,z): puncte de zid (pentru copaci)
var module_pts: Array = []           # {pts: Array[Vector2] godot, arch: bool, side}
var trunk_pts: Array[Vector2] = []
var noise := FastNoiseLite.new()
var pal_pos := Vector3.ZERO
var pal_yaw_v := 0.0
var module_mid: Array = []           # [Vector2 godot, side, clearance]
var min_clear_seen := 99.0
var tgt_p := PackedVector2Array()    # tinta curenta, cadru Blender
var tgt_h := PackedFloat32Array()
var tgt_u := PackedFloat32Array()


func _ready() -> void:
	tr = (load(SCENE) as PackedScene).instantiate() as Track
	add_child(tr)
	for k in 4:
		await get_tree().process_frame
	n = tr.baked.size()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_generate(a.substr(6))
	get_tree().quit(0)


# ---------------------------------------------------------------- drum

func _lerp_i(u: float) -> Array:
	var f := u * float(n)
	return [int(floor(f)) % n, f - floor(f)]


func _pos(u: float, v: float) -> Vector3:
	var li := _lerp_i(u)
	var i: int = li[0]
	var q: Vector3 = (tr.baked[i] as Vector3).lerp(tr.baked[(i + 1) % n], li[1])
	var s: Vector3 = tr._side_at(i)
	var hw: float = tr.width_at_index(i)
	var p := q + s * ((hw + v) if v >= 0.0 else (-hw + v))
	p.y = tr._terrain_mesh_y(p.x, p.z)
	return p


func _heading(u: float) -> Vector3:
	var i: int = _lerp_i(u)[0]
	var d: Vector3 = tr.baked[(i + 1) % n] - tr.baked[i]
	d.y = 0.0
	return d.normalized()


func _uv(p: Vector3) -> Vector2:
	var i: int = tr.closest_index_global(p)
	var q: Vector3 = tr.baked[i]
	var s: Vector3 = tr._side_at(i)
	var hw: float = tr.width_at_index(i)
	var lat := (p - q).dot(s)
	return Vector2(float(i) / float(n), signf(lat) * maxf(absf(lat) - hw, 0.0))


func _edge2(p: Vector2) -> float:
	var best := 1e9
	for k in road_p.size() - 1:
		var c := Geometry2D.get_closest_point_to_segment(p, road_p[k], road_p[k + 1])
		var d := p.distance_to(c) - road_hw[k]
		if d < best:
			best = d
	return best


func _gy(p: Vector2) -> float:
	return tr._terrain_mesh_y(p.x, p.y)


# ---------------------------------------------------------------- lant

func _rot(v: Vector2, r: float) -> Vector2:
	return Vector2(cos(r) * v.x - sin(r) * v.y, sin(r) * v.x + cos(r) * v.y)


func _b2g(w: Vector2) -> Vector2:
	return Vector2(w.x, -w.y)


func _mk_mods() -> void:
	var pa := asin(8.0 / R_A)
	var pb := asin(8.0 / R_B)
	mods = [
		{"k": "S", "res": "straight", "half": 6.0, "phi": 0.0, "rev": false, "root": "", "R": 0.0},
		{"k": "AL", "res": "curve", "half": 8.0, "phi": pa, "rev": false, "root": "A", "R": R_A},
		{"k": "AR", "res": "curve", "half": 8.0, "phi": pa, "rev": true, "root": "A", "R": R_A},
		{"k": "BL", "res": "curve", "half": 8.0, "phi": pb, "rev": false, "root": "B", "R": R_B},
		{"k": "BR", "res": "curve", "half": 8.0, "phi": pb, "rev": true, "root": "B", "R": R_B},
	]


func _step(E: Vector2, H: float, m: Dictionary) -> Dictionary:
	var half: float = m.half
	var phi: float = m.phi
	var r: float
	var t: Vector2
	var e2: Vector2
	var h2: float
	if not m.rev:
		r = H + phi
		t = E - _rot(Vector2(0, -half), r)
		e2 = _rot(Vector2(0, half), r) + t
		h2 = r + phi
	else:
		r = H - phi - PI
		t = E - _rot(Vector2(0, half), r)
		e2 = _rot(Vector2(0, -half), r) + t
		h2 = H - 2.0 * phi
	return {"r": r, "t": t, "E": e2, "H": h2}


## puncte locale ale modulului (cadru Blender local) pentru clearance
func _local_samples(m: Dictionary) -> Array[Vector2]:
	var res: Array[Vector2] = []
	var half: float = m.half
	res.append(Vector2(0, -half))
	res.append(Vector2(0, 0))
	res.append(Vector2(0, half))
	if float(m.phi) > 0.0:
		var R: float = m.R
		var phi: float = m.phi
		res.append(Vector2(-R * cos(phi) + R, 0.0))
		res.append(Vector2(-R * cos(phi) + R * cos(phi * 0.5), R * sin(phi * 0.5)))
		res.append(Vector2(-R * cos(phi) + R * cos(phi * 0.5), -R * sin(phi * 0.5)))
	return res


func _clear_of(m: Dictionary, st: Dictionary) -> float:
	var worst := 99.0
	for lp in _local_samples(m):
		var w: Vector2 = _rot(lp, st.r) + st.t
		var c := _edge2(_b2g(w)) - HALF_T
		if c < worst:
			worst = c
	return worst


func _angdiff(a: float, b: float) -> float:
	return absf(wrapf(a - b, -PI, PI))


func _tcost(E: Vector2, H: float) -> float:
	var best := 1e9
	var bk := 0
	for k in tgt_p.size():
		var d := E.distance_squared_to(tgt_p[k])
		if d < best:
			best = d
			bk = k
	var a := _angdiff(H, tgt_h[bk]) * 4.0
	return best + a * a


func _search(E: Vector2, H: float, depth: int) -> float:
	if depth == 0:
		return 0.0
	var best := 1e12
	for m in mods:
		var st := _step(E, H, m)
		var c := _tcost(st.E, st.H) + (4.0 if m.k == "S" else 0.0)
		var cl := _clear_of(m, st)
		if cl < MIN_CLEAR:
			c += 2000.0 * (MIN_CLEAR - cl) + 3000.0
		c += _search(st.E, st.H, depth - 1) * 0.8
		if c < best:
			best = c
	return best


func _progress_u(E: Vector2) -> float:
	var best := 1e9
	var bu := 0.0
	for k in tgt_p.size():
		var d := E.distance_squared_to(tgt_p[k])
		if d < best:
			best = d
			bu = tgt_u[k]
	return bu


func _vc(side: float, u: float, ph: float) -> float:
	var s := 0.5 + 0.5 * sin((u - ph) / 0.048 * TAU)
	var v := 9.8 + 4.6 * s
	# tronson drept si paralel in jurul portii si al arcului (u 0.402-0.440)
	var w := clampf((0.020 - absf(u - 0.421)) / 0.012, 0.0, 1.0)
	v = lerpf(v, 9.4, w)
	return side * v


func _set_targets(side: float, u0: float, u1: float, ph: float) -> void:
	tgt_p.clear()
	tgt_h.clear()
	tgt_u.clear()
	var u := u0 - 0.004
	while u <= u1 + 0.008:
		var p := _pos(u, _vc(side, u, ph))
		tgt_p.append(Vector2(p.x, -p.z))
		tgt_u.append(u)
		u += 1.5 / LEN
	for k in tgt_p.size():
		var a := tgt_p[maxi(k - 1, 0)]
		var b := tgt_p[mini(k + 1, tgt_p.size() - 1)]
		var d := b - a
		tgt_h.append(atan2(-d.x, d.y))


func _build_chain(cname: String, side: float, u0: float, u1: float, ph: float, gate_u: float) -> int:
	_set_targets(side, u0, u1, ph)
	var E := tgt_p[0]
	var H := tgt_h[0]
	var placed := 0
	var gate_done := false
	var safety := 0
	while safety < 60:
		safety += 1
		var u_cur := _progress_u(E)
		if u_cur >= u1:
			break
		var chosen: Dictionary = {}
		var st: Dictionary = {}
		if not gate_done and gate_u > 0.0 and u_cur >= gate_u:
			chosen = {"k": "G", "res": "arch", "half": 7.0, "phi": 0.0, "rev": false, "root": "", "R": 0.0}
			st = _step(E, H, chosen)
			gate_done = true
		else:
			var best := 1e12
			for m in mods:
				var s1 := _step(E, H, m)
				var c := _tcost(s1.E, s1.H) + (4.0 if m.k == "S" else 0.0)
				var cl := _clear_of(m, s1)
				if cl < MIN_CLEAR:
					c += 2000.0 * (MIN_CLEAR - cl) + 3000.0
				c += _search(s1.E, s1.H, 2) * 0.8
				if c < best:
					best = c
					chosen = m
					st = s1
		_emit_module(cname, placed, chosen, st, side)
		E = st.E
		H = st.H
		placed += 1
	return placed


func _emit_module(cname: String, idx: int, m: Dictionary, st: Dictionary, side: float) -> void:
	var r: float = st.r
	var t: Vector2 = st.t
	var inst := t
	if m.root == "B":
		inst = t - _rot(Vector2(10.0, 0.0), r)
	var gp := _b2g(inst)
	var miny := 1e9
	for lp in _local_samples(m):
		var g := _b2g(_rot(lp, r) + t)
		miny = minf(miny, _gy(g))
	var cpts: Array[Vector2] = []
	for k in 6:
		var f := float(k) / 5.0
		var lp: Vector2
		if float(m.phi) > 0.0:
			var th := lerpf(-float(m.phi), float(m.phi), f)
			var R: float = m.R
			lp = Vector2(-R * cos(float(m.phi)) + R * cos(th), R * sin(th))
		else:
			lp = Vector2(0, lerpf(-float(m.half), float(m.half), f))
		wall_pts.append(_b2g(_rot(lp, r) + t))
		cpts.append(_b2g(_rot(lp, r) + t))
	module_pts.append({"pts": cpts, "arch": m.res == "arch", "side": side})
	var cl := _clear_of(m, st)
	min_clear_seen = minf(min_clear_seen, cl)
	if cl < MIN_CLEAR:
		report.append("ATENTIE modul %s%d clearance %.2f la (%.0f, %.0f)" % [cname, idx, cl, gp.x, gp.y])
	var b := Basis(Vector3.UP, r) * Basis.from_scale(Vector3(1.0, SY, 1.0))
	var nname := "%s%02d" % [cname, idx]
	out.append('[node name="%s" parent="%s/Ziduri" instance=ExtResource("%s")]' % [nname, ZONE, _rid(m.res)])
	out.append("transform = " + var_to_str(Transform3D(b, Vector3(gp.x, miny - SINK, gp.y))))
	out.append("")
	if m.res == "curve":
		var hide := "Wall_B_Limestone" if m.root == "A" else "Wall_A_Limestone"
		var hidx := 1 if m.root == "A" else 0
		out.append('[node name="%s" parent="%s/Ziduri/%s" index="%d"]' % [hide, ZONE, nname, hidx])
		out.append("visible = false")
		out.append("")
	_cnt("modul_" + String(m.k))
	module_mid.append([_b2g(t), side, cl])


# ---------------------------------------------------------------- piese

func _rid(key: String) -> String:
	used_res[key] = true
	return "d_" + key


func _cnt(k: String, c := 1) -> void:
	counts[k] = int(counts.get(k, 0)) + c


func _group(g: String) -> void:
	out.append('[node name="%s" type="Node3D" parent="%s"]' % [g, ZONE])
	out.append("")


func _prop(group: String, nname: String, key: String, p: Vector3, yaw: float, sc := 1.0, sink := 0.0, extra := "") -> void:
	var b := Basis(Vector3.UP, yaw) * Basis.from_scale(Vector3.ONE * sc)
	out.append('[node name="%s" parent="%s/%s" instance=ExtResource("%s")]' % [nname, ZONE, group, _rid(key)])
	out.append("transform = " + var_to_str(Transform3D(b, Vector3(p.x, p.y - sink, p.z))))
	if extra != "":
		out.append(extra)
	out.append("")
	_cnt(key)


func _near_wall(p: Vector2, r: float) -> bool:
	for w in wall_pts:
		if w.distance_to(p) < r:
			return true
	return false


func _yaw_toward(from: Vector3, to: Vector3) -> float:
	var d := to - from
	return atan2(-d.x, -d.z)


func _on_ground(p: Vector3) -> Vector3:
	p.y = tr._terrain_mesh_y(p.x, p.z)
	return p


# ---------------------------------------------------------------- main

func _generate(path: String) -> void:
	rng.seed = 20261012
	_mk_mods()
	var i0 := int(0.325 * n)
	var i1 := int(0.485 * n)
	for i in range(i0, i1):
		var q: Vector3 = tr.baked[i]
		road_p.append(Vector2(q.x, q.z))
		road_hw.append(tr.width_at_index(i))

	_group("Ziduri")
	_group("Palat")
	_group("Arbori")
	_group("Flori")
	_group("Shisa")

	# palatul mutat din 26 m la 36 m de axa: fata lui, cu scara, nu intra in zidul
	# din fata (contractul zice "~")
	var pp := _pos(PAL_U, PAL_V)
	var road_pt := _pos(PAL_U, 0.0)
	var pal_yaw := _yaw_toward(pp, road_pt)
	pp.y -= 0.15
	_prop("Palat", "Palat", "palace", pp, pal_yaw, 1.0, 0.0)
	var pal2 := Vector2(pp.x, pp.z)
	report.append("palat la (%.1f, %.1f, %.1f) yaw %.2f rad, la %.1f m de axa" % [pp.x, pp.y, pp.z, pal_yaw, 6.0 - PAL_V])

	var nl := _build_chain("L", -1.0, 0.341, 0.4745, 0.34, PAL_U)
	var nr1 := _build_chain("R", 1.0, 0.347, 0.418, 0.352, 0.0)
	var nr2 := _build_chain("S", 1.0, 0.4375, 0.470, 0.352, 0.4555)
	report.append("lant stanga %d module, dreapta %d + %d" % [nl, nr1, nr2])
	report.append("clearance minim fata zid (centru - 1.45 m - asfalt): %.2f m" % min_clear_seen)

	# pereche shisa la poarta (kit vechi, ~1.5x), inainte de cadrul portii
	var us := GATE_U - 8.0 / LEN
	for sd in [-1.0, 1.0]:
		var sp := _pos(us, sd * 4.8)
		var axis := _pos(us, 0.0)
		var hd := _heading(us)
		var f := (axis - sp).normalized() * 0.6 - hd * 0.8
		var key := "shisa" if sd < 0.0 else "shisa_c"
		_prop("Shisa", "Shisa_%s" % ("S" if sd < 0.0 else "D"), key, sp, atan2(-f.x, -f.z), 1.5, 0.02)
		wall_pts.append(Vector2(sp.x, sp.z))

	# pini Ryukyu
	var pn := 0
	var cand: Array = []
	for k in 16:
		cand.append([rng.randf_range(0.352, 0.472), -rng.randf_range(17.0, 30.0)])
	for k in 10:
		cand.append([rng.randf_range(0.352, 0.468), rng.randf_range(17.0, 30.0)])
	for c in cand:
		if pn >= 14:
			break
		var u: float = c[0]
		var v: float = c[1]
		if v < 0.0 and absf(u - PAL_U) < 0.0125:
			continue
		var p := _pos(u, v)
		if _near_wall(Vector2(p.x, p.z), 3.5) or Vector2(p.x, p.z).distance_to(pal2) < 21.0:
			continue
		var pu := _uv(p)
		if absf(absf(pu.y) - absf(v)) > 2.5:
			continue
		_prop("Arbori", "Pin%02d" % pn, "pine", p, rng.randf() * TAU, rng.randf_range(0.85, 1.15), 0.2)
		wall_pts.append(Vector2(p.x, p.z))
		pn += 1

	pal_pos = pp
	pal_yaw_v = pal_yaw
	noise.seed = 20261013
	noise.frequency = 0.045
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_vegetation()

	var head := PackedStringArray()
	for k in used_res:
		head.append('[ext_resource type="PackedScene" path="%s" id="d_%s"]' % [RES[k], k])
	var fo := FileAccess.open(path, FileAccess.WRITE)
	fo.store_string("\n".join(head) + "\n###NODES###\n" + "\n".join(out))
	fo.close()
	print("--- raport generator ---")
	for r in report:
		print("  ", r)
	print("  piese: ", counts)


# ---------------------------------------------------------------- vegetatie

func _pal_local(q: Vector2) -> Vector2:
	var d := Vector3(q.x - pal_pos.x, 0.0, q.y - pal_pos.z)
	var l := Basis(Vector3.UP, pal_yaw_v).inverse() * d
	return Vector2(l.x, l.z)   # fata palatului = -z local


func _in_palace_view(q: Vector2) -> bool:
	var l := _pal_local(q)
	return absf(l.x) < 23.0 and l.y < 12.0


func _stream(step: float) -> Array:
	var res: Array = []
	for md in module_pts:
		var pts: Array = md["pts"]
		for k in pts.size() - 1:
			var a: Vector2 = pts[k]
			var b: Vector2 = pts[k + 1]
			var cnt := maxi(int(a.distance_to(b) / step), 1)
			var td := (b - a).normalized()
			for j in cnt:
				var p := a.lerp(b, float(j) / float(cnt))
				var nrm := Vector2(-td.y, td.x)
				var uv := _uv(Vector3(p.x, tr._terrain_mesh_y(p.x, p.y), p.y))
				var rp := _pos(uv.x, 0.0)
				if nrm.dot(p - Vector2(rp.x, rp.z)) < 0.0:
					nrm = -nrm
				res.append({"p": p, "away": nrm, "u": uv.x, "arch": md["arch"]})
	return res


func _trunk_free(q: Vector2, d: float) -> bool:
	for t in trunk_pts:
		if t.distance_to(q) < d:
			return false
	return true


var _ids := {}
func _nid(k: String) -> String:
	_ids[k] = int(_ids.get(k, 0)) + 1
	return "%s%03d" % [k, _ids[k]]


func _tree(group: String, key: String, q: Vector2, sc: float, sink := 0.2) -> void:
	var p := _on_ground(Vector3(q.x, 0, q.y))
	_prop(group, _nid(key), key, p, rng.randf() * TAU, sc, sink)
	trunk_pts.append(q)
	wall_pts.append(q)


func _vegetation() -> void:
	var variants := ["fukugi_a", "fukugi_b", "fukugi_c"]
	# --- 1+3: banda la baza zidurilor (partea dinspre drum) + paturi de fukugi
	var st := _stream(2.2)
	var active := 0
	var cool := 0.0
	var cov_n := 0
	for e in st:
		var p: Vector2 = e["p"]
		var away: Vector2 = e["away"]
		var u: float = e["u"]
		if noise.get_noise_2d(p.x, p.y) < -0.12:
			continue
		active += 1
		var tang := Vector2(-away.y, away.x)
		# tufe joase, fara coliziune pana la ~2.2 m de bordura
		if rng.randf() < 0.75:
			var q := p - away * rng.randf_range(1.8, 3.2) + tang * rng.randf_range(-1.0, 1.0)
			if _edge2(q) >= 2.2 and not _near_wall(q, 1.5):
				_prop("Flori", _nid("Hibiscus"), "hibiscus", _on_ground(Vector3(q.x, 0, q.y)), rng.randf() * TAU, rng.randf_range(1.3, 2.0), 0.05)
		if rng.randf() < 0.35:
			var q2 := p - away * rng.randf_range(2.0, 3.6) + tang * rng.randf_range(-1.0, 1.0)
			if _edge2(q2) >= 2.4 and not _near_wall(q2, 1.6):
				_prop("Flori", _nid("Cicada"), "cycad", _on_ground(Vector3(q2.x, 0, q2.y)), rng.randf() * TAU, rng.randf_range(1.1, 1.5), 0.1)
		if rng.randf() < 0.07:
			var q3 := p - away * 1.9
			if _edge2(q3) >= 2.4:
				var d3 := Vector3(-away.x, 0, -away.y)
				_prop("Flori", _nid("Bougainvillea"), "bougainvillea", _on_ground(Vector3(q3.x, 0, q3.y)), atan2(-d3.x, -d3.z), 1.2, 0.05, 'metadata/coliziune = "none"')
		# pat de fukugi suprapuse (3-5), nu in dreptul portii / arcului
		cool -= 2.2
		if cool <= 0.0 and not bool(e["arch"]) and absf(u - GATE_U) > 0.0085 and absf(u - PAL_U) > 0.005:
			cool = rng.randf_range(12.0, 26.0)
			var c := p - away * rng.randf_range(2.9, 4.4)
			var nn := rng.randi_range(3, 5)
			for k in nn:
				var q4 := c + Vector2(rng.randf_range(-2.8, 2.8), rng.randf_range(-2.8, 2.8))
				if _edge2(q4) < 3.3 or _near_wall(q4, 2.3) or not _trunk_free(q4, 1.1):
					continue
				_tree("Arbori", variants[rng.randi() % 3], q4, rng.randf_range(0.85, 1.25))
	report.append("fluxul de baza: %d puncte active din %d" % [active, st.size()])

	# --- 2: masa de coroane in spatele zidurilor (peste zid se vede o linie de coroane)
	var st2 := _stream(4.0)
	var pine_new := 0
	for e in st2:
		var p: Vector2 = e["p"]
		var away: Vector2 = e["away"]
		if bool(e["arch"]):
			continue
		var base := p + away * rng.randf_range(3.2, 7.5)
		if _in_palace_view(base) or base.distance_to(Vector2(pal_pos.x, pal_pos.z)) < 22.0:
			continue
		if rng.randf() < 0.28:
			if _near_wall(base, 3.4) or not _trunk_free(base, 3.0):
				continue
			_tree("Arbori", "pine", base, rng.randf_range(1.15, 1.5))
			pine_new += 1
		else:
			var nn := rng.randi_range(2, 3)
			for k in nn:
				var q := base + Vector2(rng.randf_range(-2.2, 2.2), rng.randf_range(-2.2, 2.2))
				if _near_wall(q, 2.4) or not _trunk_free(q, 1.3) or _in_palace_view(q):
					continue
				_tree("Arbori", variants[rng.randi() % 3], q, rng.randf_range(1.35, 1.8))
	report.append("pini noi pe coama: %d" % pine_new)

	# --- palatul: banian pe laturi + masa de tufe si pini pe terasa
	for sgn in [-1.0, 1.0]:
		var lq: Vector3 = Basis(Vector3.UP, pal_yaw_v) * Vector3(sgn * 27.5, 0.0, 3.0)
		var q := Vector2(pal_pos.x + lq.x, pal_pos.z + lq.z)
		_tree("Arbori", "banyan", q, 1.6, 0.25)
		for k in 3:
			var lq2: Vector3 = Basis(Vector3.UP, pal_yaw_v) * Vector3(sgn * rng.randf_range(20.0, 32.0), 0.0, rng.randf_range(-4.0, 14.0))
			var q2 := Vector2(pal_pos.x + lq2.x, pal_pos.z + lq2.z)
			if _near_wall(q2, 3.0) or not _trunk_free(q2, 2.2):
				continue
			if k == 0:
				_tree("Arbori", "pine", q2, rng.randf_range(1.2, 1.5))
			else:
				_tree("Arbori", variants[rng.randi() % 3], q2, rng.randf_range(1.3, 1.7))
		for k in 6:
			var lq3: Vector3 = Basis(Vector3.UP, pal_yaw_v) * Vector3(sgn * rng.randf_range(17.5, 24.0), 0.0, rng.randf_range(-8.0, 8.0))
			var q3 := Vector2(pal_pos.x + lq3.x, pal_pos.z + lq3.z)
			_prop("Flori", _nid("Hibiscus"), "hibiscus", _on_ground(Vector3(q3.x, 0, q3.y)), rng.randf() * TAU, rng.randf_range(1.3, 1.9), 0.05)
	# coroane in spatele palatului (nu se vad din fata; umplu cerul de pe laturi)
	for k in 5:
		var lq4: Vector3 = Basis(Vector3.UP, pal_yaw_v) * Vector3(rng.randf_range(-36.0, 36.0), 0.0, rng.randf_range(16.0, 24.0))
		var q4 := Vector2(pal_pos.x + lq4.x, pal_pos.z + lq4.z)
		if _trunk_free(q4, 3.0):
			_tree("Arbori", "pine" if k % 2 == 0 else variants[k % 3], q4, rng.randf_range(1.2, 1.6))
