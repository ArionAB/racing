extends Node
## Generator de decor pentru POI C — Trestia si urcarea (Track20, Okinawa).
##   godot --headless --path . res://tools/GenDecorOkC.tscn -- --inspect
##   godot --headless --path . res://tools/GenDecorOkC.tscn -- --out=<fisier>
##
## Iesirea e un fragment .tscn (ext_resource cu id `c_*` + noduri sub
## `DecorManual/ZonaC`), lipit in Track20.tscn de `tools/splice_ok_c.py`.
##
## Fapte masurate (contract §Premise 1): drumul urca (5-8 %) pe CRESTA, terenul
## lateral e plat la cota drumului ±25 m, interiorul (DREAPTA) coboara incet;
## stanga e plat pana la mare. Deci trestia sta la cota drumului, nu "pe deal".
##
## RUNDA 2 (verdict orb: "petice izolate cu sol gol intre ele, vrem masa
## continua"): cate un camp CONTINUU pe fiecare parte, de la ~2 m de bordura la
## 36-42 m adancime, in RANDURI PARALELE cu drumul (coordonate (u, v) ale
## drumului, deci randul urmeaza curba). Varianta de clump e `Cane_Clump_B`
## (824 tri, cea mai ieftina), stolul e feliat in celule de ~26 m cu
## `view_m` (nu se randeaza peste 180 m). Bordura dinspre drum: hibiscus,
## cicade, bougainvillea, pini, garduri de corali intrerupte.

const SCENE := "res://scenes/tracks/Track20.tscn"
const ZONE := "DecorManual/ZonaC"
const PALACE := Vector2(110.0, -285.0)
const GATE := Vector2(142.8, -249.9)
const LEN := 2058.3

const M_OK := "res://assets/models/okinawa/"
const RES := {
	"cane": "res://assets/models/plants/sugar_cane_clump.glb",
	"hibiscus": "res://assets/models/plants/hibiscus_bush.glb",
	"pine": M_OK + "plants/ryukyu_pine.glb",
	"cycad": M_OK + "plants/cycad.glb",
	"bougainvillea": M_OK + "plants/bougainvillea.glb",
	"fukugi_a": M_OK + "plants/fukugi_tree_a.glb",
	"fukugi_b": M_OK + "plants/fukugi_tree_b.glb",
	"fukugi_c": M_OK + "plants/fukugi_tree_c.glb",
	"house_a": M_OK + "buildings/concrete_house_a.glb",
	"house_b": M_OK + "buildings/concrete_house_b.glb",
	"ryukyu_c": M_OK + "buildings/ryukyu_house_c.glb",
	"wall": M_OK + "structures/coral_stone_wall.glb",
	"buffalo": M_OK + "animals/water_buffalo.glb",
	"egret": M_OK + "animals/egret.glb",
}
const FLOCK_SCRIPT := "res://scenes/props/flock.gd"

const U0 := 0.2090      # dupa colt (0.2047); punctele cu (u,v) nepotrivit se sar
const U1 := 0.3375
const CELL := 0.0125    # ~26 m per stol
const V0 := 2.2         # primul rand: de la marginea asfaltului
const ROW := 2.5
const STEP := 2.4
const WALL_V := 2.7

var tr: Track
var n: int
var rng := RandomNumberGenerator.new()
var noise := FastNoiseLite.new()
var out := PackedStringArray()
var used_res := {}
var counts := {}
## discuri ocupate (x, z, raza): case, luminis, pini, ziduri -- trestia nu intra
var discs: Array[Vector3] = []
var cams: Array[Vector3] = []
var report := PackedStringArray()
var cane_tris := 824


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


## Piesa inalta in axa spre palat/poarta (vazuta din camera ferestrei C) care
## depaseste linia camera -> baza palatului (+33): respinsa.
func _blocks_palace(p: Vector3, height: float) -> bool:
	var top := p.y + height
	for c in cams:
		for tgt: Vector2 in [PALACE, GATE]:
			var a1 := Vector2(tgt.x - c.x, tgt.y - c.z)
			var a2 := Vector2(p.x - c.x, p.z - c.z)
			if a2.length() > a1.length():
				continue
			if absf(rad_to_deg(a1.angle_to(a2))) > 4.0:
				continue
			var line_y := c.y + (33.0 - c.y) * (a2.length() / a1.length())
			if top > line_y:
				return true
	return false


func _free_u(u: float, v: float, height: float) -> float:
	for off in [0.0, 0.006, -0.006, 0.012, -0.012, 0.02, -0.02, 0.03, -0.03]:
		var p := _pos(u + off, v)
		if not _blocks_palace(p, height):
			return u + off
	return -1.0


# ---------------------------------------------------------------------------
# emitere

func _res_id(key: String) -> String:
	used_res[key] = true
	return "c_" + key


func _count(k: String, c := 1) -> void:
	counts[k] = int(counts.get(k, 0)) + c


func _group(gname: String) -> void:
	out.append('[node name="%s" type="Node3D" parent="%s"]' % [gname, ZONE])
	out.append("")


func _prop(group: String, nname: String, key: String, p: Vector3, yaw: float, sc := 1.0, sink := 0.0, extra := "") -> void:
	var b := Basis(Vector3.UP, yaw) * Basis.from_scale(Vector3.ONE * sc)
	var xf := Transform3D(b, Vector3(p.x, p.y - sink, p.z))
	out.append('[node name="%s" parent="%s/%s" instance=ExtResource("%s")]' % [nname, ZONE, group, _res_id(key)])
	out.append("transform = " + var_to_str(xf))
	if extra != "":
		out.append(extra)
	out.append("")
	_count(key)


func _hide_pose(inst: String, pose: String) -> void:
	out.append('[node name="%s" parent="%s/Fauna/%s"]' % [pose, ZONE, inst])
	out.append("visible = false")
	out.append("")


func _flock(nname: String, key: String, pos: PackedVector3Array, yaw: PackedFloat32Array, sc3: Array[Vector3]) -> void:
	used_res["flock"] = true
	out.append('[node name="%s" type="MultiMeshInstance3D" parent="%s/Trestia"]' % [nname, ZONE])
	out.append('script = ExtResource("c_flock")')
	out.append('model = ExtResource("%s")' % _res_id(key))
	out.append('mesh_name = "Cane_Clump_B"')
	out.append("view_m = 180.0")
	out.append("positions = " + var_to_str(pos))
	out.append("yaws = " + var_to_str(yaw))
	out.append("scale3_list = " + var_to_str(sc3))
	out.append("")


# ---------------------------------------------------------------------------
# trestia: camp continuu, randuri paralele cu drumul

func _build_cane(side: float, cell: int) -> void:
	var pos := PackedVector3Array()
	var yaw := PackedFloat32Array()
	var sc3: Array[Vector3] = []
	var ua := U0 + float(cell) * CELL
	var ub := ua + CELL
	if ua >= U1:
		return
	var k := 0
	while true:
		var v := V0 + float(k) * ROW
		# adancimea: neregulata doar spre interior (zgomot pe u)
		var vmax := 36.0 + noise.get_noise_2d(ua * 700.0, side * 5.0 + 3.0) * 7.0
		if v > vmax:
			break
		var m := 0
		var off := (STEP * 0.5) if k % 2 == 1 else 0.0
		while true:
			var du := (float(m) * STEP + off) / LEN
			var u := ua + du
			if u >= ub:
				break
			m += 1
			# departe de drum randul se rareste (fiecare al doilea) ca sa
			# nu se plateasca tris acolo unde nu conteaza
			if v > 22.0 and (m + k) % 2 == 1:
				continue
			var jv := rng.randf_range(-0.3, 0.3)
			var ju := rng.randf_range(-0.35, 0.35) / LEN
			var p := _pos(u + ju, side * (v + jv))
			var uv := _uv(p)
			if absf(absf(uv.y) - (v + jv)) > 1.6 or absf(uv.x - u) > 0.005:
				continue
			if _occupied(p, 0.0):
				continue
			if p.y < 0.8:
				continue
			pos.append(Vector3(p.x, p.y - 0.05, p.z))
			yaw.append(rng.randf() * TAU)
			var w := rng.randf_range(1.05, 1.35)
			sc3.append(Vector3(w, rng.randf_range(0.95, 1.2), w * rng.randf_range(0.9, 1.1)))
		k += 1
	_flock("Camp_%s%02d" % ["R" if side > 0.0 else "L", cell], "cane", pos, yaw, sc3)
	_count("cane", pos.size())


# ---------------------------------------------------------------------------

func _generate(path: String) -> void:
	rng.seed = 20261011
	noise.seed = 20261011
	noise.frequency = 0.5
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	var u := 0.20
	while u <= 0.335:
		var li := _lerp_i(u)
		var q: Vector3 = (tr.baked[li[0]] as Vector3).lerp(tr.baked[(li[0] + 1) % n], li[1])
		cams.append(q - _heading(u) * 12.5 + Vector3.UP * 10.0)
		u += 0.01

	_group("Trestia")
	_group("Case")
	_group("Garduri")
	_group("Arbori")
	_group("Fauna")
	_group("Flori")

	# --- case joase la 15-25 m de drum (prima reusita din lista; max 3)
	var houses := [
		["ryukyu_c", 0.2490, 19.0], ["house_a", 0.2860, -19.0], ["house_b", 0.3170, 17.0],
		["ryukyu_c", 0.2420, -20.0], ["house_b", 0.2730, 22.0], ["house_a", 0.3050, -17.0],
		["ryukyu_c", 0.2300, 20.0], ["house_b", 0.3290, -18.0],
	]
	var hn := 0
	var hseen := {}
	for h in houses:
		if hn >= 3:
			break
		var hp0 := _pos(float(h[1]), float(h[2]))
		var ht := 9.5 if String(h[0]) != "ryukyu_c" else 5.5
		var hu := _free_u(float(h[1]), float(h[2]), ht)
		if hu < 0.0:
			report.append("casa %s la u=%.3f respinsa (axa palat)" % [h[0], float(h[1])])
			continue
		var hp := _pos(hu, float(h[2]))
		var d := _pos(hu, signf(float(h[2])) * 2.0) - hp
		d.y = 0.0
		d = d.normalized()
		var yw := atan2(-d.x, -d.z) + rng.randf_range(-0.2, 0.2)
		_prop("Case", "Casa%d" % hn, String(h[0]), hp, yw, 1.0, 0.25)
		discs.append(Vector3(hp.x, hp.z, 8.5))
		hseen[hn] = hp0
		hn += 1

	# --- luminis (pasune) pentru bivol + 2 egrete, in campul din dreapta
	var cl_c := _pos(0.2865, 24.0)
	discs.append(Vector3(cl_c.x, cl_c.z, 7.0))

	# --- garduri de corali: borduri de camp la ~2.7 m de asfalt, INTRERUPTE
	var wn := 0
	for side: float in [1.0, -1.0]:
		var uu := U0 + (0.002 if side > 0.0 else 0.009)
		while uu < U1 - 0.01:
			var run_len := rng.randf_range(12.0, 24.0) / LEN
			var ue := minf(uu + run_len, U1 - 0.005)
			wn += _wall_line(wn, uu, ue, side * WALL_V, 2.4)
			uu = ue + rng.randf_range(7.0, 16.0) / LEN
	# despartituri transversale mai adanc in camp (v 12-36)
	for dd in [[0.2400, 1.0], [0.2750, 1.0], [0.3100, 1.0], [0.2300, -1.0], [0.2600, -1.0], [0.2950, -1.0], [0.3250, -1.0]]:
		wn += _wall_seg(wn, _pos(float(dd[0]), float(dd[1]) * 12.0), _pos(float(dd[0]), float(dd[1]) * 34.0), 4.5)

	# --- bordura de camp: pini, hibiscus, cicade, bougainvillea in palcuri
	var pn := 0
	var cn := 0
	var hbn := 0
	var bn := 0
	for side: float in [1.0, -1.0]:
		var uu := U0 + rng.randf_range(0.0, 0.006)
		var cluster := 0
		while uu < U1:
			var cu := uu
			var v := side * rng.randf_range(1.9, 3.2)
			var cp := _pos(cu, v)
			# 2-3 hibiscus + 1-2 cicade, in palc
			for k in rng.randi_range(2, 3):
				var p := cp + Vector3(rng.randf_range(-2.0, 2.0), 0, rng.randf_range(-1.2, 1.2))
				p.y = tr._terrain_mesh_y(p.x, p.z)
				if _edge_dist(p) < 1.3:
					continue
				_prop("Flori", "Hibiscus%02d" % hbn, "hibiscus", p, rng.randf() * TAU, rng.randf_range(1.2, 1.7), 0.05)
				hbn += 1
			for k in rng.randi_range(1, 2):
				var p := cp + Vector3(rng.randf_range(-2.4, 2.4), 0, rng.randf_range(-1.5, 1.5))
				p.y = tr._terrain_mesh_y(p.x, p.z)
				if _edge_dist(p) < 1.6:
					continue
				_prop("Arbori", "Cicada%02d" % cn, "cycad", p, rng.randf() * TAU, rng.randf_range(0.95, 1.35), 0.1)
				cn += 1
			if cluster % 5 == 2 and bn < 2:
				var bp := _pos(cu + 4.0 / LEN, side * 3.0)
				var bd := _pos(cu + 4.0 / LEN, side * 0.0) - bp
				bd.y = 0.0
				bd = bd.normalized()
				_prop("Flori", "Bougainvillea%d" % bn, "bougainvillea", bp, atan2(-bd.x, -bd.z), 1.1, 0.05, 'metadata/coliziune = "none"')
				bn += 1
			# pin la cateva palcuri, la 3.4-5 m (trunchi cu coliziune)
			if cluster % 3 == 1:
				var pu := _free_u(cu + 6.0 / LEN, side * 4.2, 9.5)
				if pu >= 0.0:
					var pp := _pos(pu, side * rng.randf_range(3.6, 5.0))
					_prop("Arbori", "Pin%02d" % pn, "pine", pp, rng.randf() * TAU, rng.randf_range(0.85, 1.1), 0.2)
					discs.append(Vector3(pp.x, pp.z, 1.8))
					pn += 1
			cluster += 1
			uu += rng.randf_range(16.0, 38.0) / LEN
	# --- cativa fukugi pe marginea interioara a campului (fundal verde inchis)
	var fuk := [
		["a", 0.2330, 44.0], ["c", 0.2800, 47.0], ["b", 0.2560, 46.0], ["c", 0.3010, 45.0],
		["a", 0.2500, -42.0], ["c", 0.2950, -44.0], ["b", 0.3220, 44.0],
	]
	var fnn := 0
	for ff in fuk:
		var fu := _free_u(float(ff[1]), float(ff[2]), 8.8)
		if fu < 0.0:
			continue
		var p := _pos(fu, float(ff[2]))
		if _occupied(p, 2.0):
			continue
		_prop("Arbori", "Fukugi%02d" % fnn, "fukugi_" + String(ff[0]), p, rng.randf() * TAU, rng.randf_range(0.9, 1.15), 0.2)
		fnn += 1

	# --- fauna in luminis
	var bd2 := _heading(0.2865)
	var bs := Vector3(-bd2.z, 0, bd2.x)
	var bp2 := cl_c + bd2 * 0.6
	bp2.y = tr._terrain_mesh_y(bp2.x, bp2.z)
	_prop("Fauna", "Bivol", "buffalo", bp2, atan2(bd2.x, bd2.z) + 2.2, 1.35)
	_hide_pose("Bivol", "Pose_Walk")
	var e1 := cl_c - bd2 * 3.4 + bs * 3.0
	var e2 := cl_c + bd2 * 2.8 - bs * 3.6
	e1.y = tr._terrain_mesh_y(e1.x, e1.z)
	e2.y = tr._terrain_mesh_y(e2.x, e2.z)
	_prop("Fauna", "Egreta0", "egret", e1, rng.randf() * TAU, 1.7)
	_prop("Fauna", "Egreta1", "egret", e2, rng.randf() * TAU, 1.7)
	_hide_pose("Egreta0", "Pose_Fly")
	_hide_pose("Egreta1", "Pose_Fly")

	# --- trestia (dupa ce toate discurile sunt cunoscute)
	var ncell := int(ceil((U1 - U0) / CELL))
	for cell in ncell:
		_build_cane(1.0, cell)
		_build_cane(-1.0, cell)
	report.append("clump-uri trestie: %d x %d tri (Cane_Clump_B) = %d tri" % [int(counts.get("cane", 0)), cane_tris, int(counts.get("cane", 0)) * cane_tris])

	var head := PackedStringArray()
	for k in used_res:
		if k == "flock":
			head.append('[ext_resource type="Script" path="%s" id="c_flock"]' % FLOCK_SCRIPT)
		else:
			head.append('[ext_resource type="PackedScene" path="%s" id="c_%s"]' % [RES[k], k])
	var fo := FileAccess.open(path, FileAccess.WRITE)
	fo.store_string("\n".join(head) + "\n###NODES###\n" + "\n".join(out))
	fo.close()
	print("--- raport generator ---")
	for r in report:
		print("  ", r)
	print("  piese: ", counts)


## Gard de la u0 la u1 la v fix (paralel cu drumul), segmente de ~4 m.
func _wall_line(wn: int, u0: float, u1: float, v: float, min_edge: float) -> int:
	var made := 0
	var uu := u0
	var prev := _pos(uu, v)
	while uu < u1:
		uu = minf(uu + 4.0 / LEN, u1)
		var cur := _pos(uu, v)
		made += _wall_seg(wn + made, prev, cur, min_edge)
		prev = cur
	return made


func _wall_seg(wn: int, a: Vector3, b: Vector3, min_edge: float) -> int:
	var d := b - a
	d.y = 0.0
	var length := d.length()
	if length < 1.0:
		return 0
	var dir := d / length
	var cnt := maxi(int(round(length / 3.9)), 1)
	var step := length / float(cnt)
	var made := 0
	for k in cnt:
		var c := a + dir * (step * (float(k) + 0.5))
		c.y = tr._terrain_mesh_y(c.x, c.z)
		if _edge_dist(c) < min_edge:
			continue
		var yaw := atan2(dir.x, dir.z) + rng.randf_range(-0.05, 0.05)
		var b2 := Basis(Vector3.UP, yaw) * Basis.from_scale(Vector3(1.0, 1.0, step / 4.0))
		out.append('[node name="Gard%03d" parent="%s/Garduri" instance=ExtResource("%s")]' % [wn + made, ZONE, _res_id("wall")])
		out.append("transform = " + var_to_str(Transform3D(b2, Vector3(c.x, c.y - 0.12, c.z))))
		out.append("")
		discs.append(Vector3(c.x, c.z, 1.5))
		_count("wall")
		made += 1
	return made
