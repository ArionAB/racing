extends Node
## Generator de decor pentru POI C — Trestia si urcarea (Track20, Okinawa).
##   godot --headless --path . res://tools/GenDecorOkC.tscn -- --inspect
##   godot --headless --path . res://tools/GenDecorOkC.tscn -- --out=<fisier>
##
## Iesirea e un fragment .tscn (ext_resource cu id `c_*` + noduri sub
## `DecorManual/ZonaC`), lipit in Track20.tscn de `tools/splice_ok_c.py`.
##
## Fapte masurate (contract §Premise 1): drumul urca (5-8 %) pe CRESTA, terenul
## lateral e plat la cota drumului ±25 m, interiorul (DREAPTA) coboara incet
## (-1.5 m la 60 m); stanga e plat pana la mare (86-100 m). Deci trestia sta la
## cota drumului, pe teren, nu "pe deal".
##
## Trestia: `sugar_cane_clump` (kit vechi) ca FlockProp (MultiMesh), cate un
## stol per camp, in RANDURI (transversale pe drum), margini neregulate.
## Un clump are 1216 tri si 2,7 x 3,8 m.

const SCENE := "res://scenes/tracks/Track20.tscn"
const ZONE := "DecorManual/ZonaC"
const PALACE := Vector2(110.0, -285.0)
const GATE := Vector2(142.8, -249.9)

const M_OK := "res://assets/models/okinawa/"
const RES := {
	"cane": "res://assets/models/plants/sugar_cane_clump.glb",
	"hibiscus": "res://assets/models/plants/hibiscus_bush.glb",
	"pine": M_OK + "plants/ryukyu_pine.glb",
	"cycad": M_OK + "plants/cycad.glb",
	"fukugi_a": M_OK + "plants/fukugi_tree_a.glb",
	"fukugi_b": M_OK + "plants/fukugi_tree_b.glb",
	"fukugi_c": M_OK + "plants/fukugi_tree_c.glb",
	"house_a": M_OK + "buildings/concrete_house_a.glb",
	"house_b": M_OK + "buildings/concrete_house_b.glb",
	"wall": M_OK + "structures/coral_stone_wall.glb",
	"buffalo": M_OK + "animals/water_buffalo.glb",
	"egret": M_OK + "animals/egret.glb",
}
const FLOCK_SCRIPT := "res://scenes/props/flock.gd"

## [nume, u0, u1, v0, v1] ; v>0 dreapta (interior), v<0 stanga; v0 mai aproape de drum
const FIELDS := [
	["R1", 0.2285, 0.2615, 4.0, 44.0],
	["R2", 0.2675, 0.3025, 4.0, 48.0],
	["R3", 0.3075, 0.3345, 4.0, 36.0],
	["L1", 0.2255, 0.2575, -4.0, -32.0],
	["L2", 0.2725, 0.3025, -4.0, -36.0],
	["L3", 0.3075, 0.3345, -4.0, -30.0],
]
const ROW_X := 3.2   # intre randuri (de-a lungul drumului)
const PLANT_X := 2.5  # in rand (transversal)

var tr: Track
var n: int
var rng := RandomNumberGenerator.new()
var noise := FastNoiseLite.new()
var out := PackedStringArray()
var used_res := {}
var counts := {}
## discuri ocupate (x, z, raza): case, luminis, pini -- trestia nu intra in ele
var discs: Array[Vector3] = []
var cams: Array[Vector3] = []
var report := PackedStringArray()


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	tr = (load(SCENE) as PackedScene).instantiate() as Track
	add_child(tr)
	for k in 4:
		await get_tree().process_frame
	n = tr.baked.size()
	if "--inspect" in args:
		for p in [RES["cane"], RES["egret"], RES["buffalo"]]:
			_inspect(p)
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


## (u, v) al unui punct de lume, dupa cel mai apropiat punct de drum.
func _uv(p: Vector3) -> Vector2:
	var i: int = tr.closest_index_global(p)
	var q: Vector3 = tr.baked[i]
	var s: Vector3 = tr._side_at(i)
	var hw: float = tr.width_at_index(i)
	var lat := (p - q).dot(s)
	# pe asfalt v = 0 (nici dreapta, nici stanga): altfel jumatatea stanga a
	# drumului ar iesi cu v pozitiv si ar primi trestie in mijlocul soselei
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


## Piesa inalta in axa spre palat/poarta, vazuta din camera (10 m sus, 12,5 m in
## spate) pe oricare punct al ferestrei C: respinsa.
func _blocks_palace(p: Vector3, height: float) -> bool:
	# fizic: piesa acopera palatul doar daca varful ei sta mai sus decat linia
	# camera -> baza palatului (+30, platoul) si e in +-4 grade de azimut
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


## Cea mai apropiata fractie u (cautare +-0.03) unde o piesa de `height` m nu
## acopera palatul; -1 daca nu exista.
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


func _prop(group: String, nname: String, key: String, p: Vector3, yaw: float, sc := 1.0, sink := 0.0) -> void:
	var b := Basis(Vector3.UP, yaw) * Basis.from_scale(Vector3.ONE * sc)
	var xf := Transform3D(b, Vector3(p.x, p.y - sink, p.z))
	out.append('[node name="%s" parent="%s/%s" instance=ExtResource("%s")]' % [nname, ZONE, group, _res_id(key)])
	out.append("transform = " + var_to_str(xf))
	out.append("")
	_count(key)


## Poza nedorita a unui GLB cu doua poze ca noduri separate: ascunsa pe instanta.
func _hide_pose(inst: String, pose: String) -> void:
	out.append('[node name="%s" parent="%s/Fauna/%s"]' % [pose, ZONE, inst])
	out.append("visible = false")
	out.append("")


func _flock(nname: String, key: String, pos: PackedVector3Array, yaw: PackedFloat32Array, sc3: Array[Vector3]) -> void:
	used_res["flock"] = true
	out.append('[node name="%s" type="MultiMeshInstance3D" parent="%s/Trestia"]' % [nname, ZONE])
	out.append('script = ExtResource("c_flock")')
	out.append('model = ExtResource("%s")' % _res_id(key))
	out.append("positions = " + var_to_str(pos))
	out.append("yaws = " + var_to_str(yaw))
	out.append("scale3_list = " + var_to_str(sc3))
	out.append("")


# ---------------------------------------------------------------------------
# campurile

func _in_field(f: Array, uv: Vector2) -> bool:
	var u0: float = f[1]
	var u1: float = f[2]
	var v0: float = f[3]
	var v1: float = f[4]
	var sg := 1.0 if v1 > 0.0 else -1.0
	if sg * uv.y <= 0.0:
		return false
	var a := absf(uv.y)
	# margini neregulate: u se clatina cu v, v cu u (zgomot neted)
	var du := noise.get_noise_2d(uv.y * 3.1, 11.0) * 0.0035
	var dv := noise.get_noise_2d(uv.x * 900.0, 7.0) * 4.5
	var dv0 := noise.get_noise_2d(uv.x * 700.0, 29.0) * 1.2
	if uv.x < u0 + du or uv.x > u1 - du:
		return false
	return a > absf(v0) + 0.3 + dv0 and a < absf(v1) + dv


func _build_field(f: Array, clear: Array) -> void:
	var uc: float = (float(f[1]) + float(f[2])) * 0.5
	var vc: float = (float(f[3]) + float(f[4])) * 0.5
	var c := _pos(uc, vc)
	var d0 := _heading(uc)
	var s0 := Vector3(-d0.z, 0.0, d0.x) # dreapta
	var pos := PackedVector3Array()
	var yaw := PackedFloat32Array()
	var sc3: Array[Vector3] = []
	var span_u := (float(f[2]) - float(f[1])) * 2058.0 * 0.5 + 12.0
	var span_v := absf(float(f[4]) - float(f[3])) * 0.5 + 14.0
	var k_lim := int(span_u / ROW_X) + 3
	var m_lim := int(span_v / PLANT_X) + 3
	for k in range(-k_lim, k_lim + 1):
		var roww := noise.get_noise_2d(float(k) * 2.7, 91.0) * 0.18  # randul se abate usor
		for m in range(-m_lim, m_lim + 1):
			var jx := rng.randf_range(-0.22, 0.22)
			var jz := rng.randf_range(-0.35, 0.35)
			var base := c + d0 * (float(k) * ROW_X + roww + jx) + s0 * (float(m) * PLANT_X + jz)
			var uv := _uv(base)
			if not _in_field(f, uv):
				continue
			if _occupied(base, 2.0):
				continue
			var skip := false
			for cl: Vector3 in clear:
				if Vector2(base.x - cl.x, base.z - cl.y).length() < cl.z:
					skip = true
					break
			if skip:
				continue
			base.y = tr._terrain_mesh_y(base.x, base.z)
			if base.y < 0.8:
				continue
			pos.append(Vector3(base.x, base.y - 0.05, base.z))
			yaw.append(rng.randf() * TAU)
			var w := rng.randf_range(0.95, 1.22)
			sc3.append(Vector3(w, rng.randf_range(0.92, 1.12), w * rng.randf_range(0.9, 1.1)))
	_flock("Camp_" + String(f[0]), "cane", pos, yaw, sc3)
	_count("cane", pos.size())
	report.append("camp %s: %d clump-uri" % [f[0], pos.size()])


# ---------------------------------------------------------------------------

func _generate(path: String) -> void:
	rng.seed = 20261010
	noise.seed = 20261010
	noise.frequency = 0.5
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	# camerele ferestrei C (10 m sus, 12,5 m in spate)
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

	# --- case de beton (cu gradina): discuri ocupate inainte de trestie
	var houses := [["a", 0.2455, 50.0], ["b", 0.2935, 61.0], ["b", 0.3195, 21.0],
		["b", 0.2850, -36.0], ["a", 0.2400, -34.0], ["b", 0.2750, 76.0], ["a", 0.2330, 62.0]]
	var hn := 0
	for h in houses:
		if hn >= 3:
			break
		var hu := _free_u(float(h[1]), float(h[2]), 9.5)
		if hu < 0.0:
			report.append("casa la u=%.3f respinsa (axa palat)" % float(h[1]))
			continue
		var hp := _pos(hu, float(h[2]))
		var d := _pos(hu, -2.0) - hp
		d.y = 0.0
		d = d.normalized()
		# fata casei = -Z local; vrem -Z -> spre drum
		var yw := atan2(-d.x, -d.z) + rng.randf_range(-0.25, 0.25)
		_prop("Case", "Casa%d" % hn, "house_" + String(h[0]), hp, yw, 1.0, 0.25)
		discs.append(Vector3(hp.x, hp.z, 8.5))
		hn += 1

	# --- luminis (pasune) in campul R2 pentru bivol + 2 egrete
	var cl_c := _pos(0.2865, 36.0)
	var clear: Array = [Vector3(cl_c.x, cl_c.z, 8.0)]
	for f in FIELDS:
		_build_field(f, clear if f[0] == "R2" else [])

	# --- fauna
	var bd := _heading(0.2865)
	var bs := Vector3(-bd.z, 0, bd.x)
	_prop("Fauna", "Bivol", "buffalo", cl_c + bd * 0.6, atan2(bd.x, bd.z) + 2.2, 1.35)
	_hide_pose("Bivol", "Pose_Walk")
	var e1 := cl_c - bd * 3.4 + bs * 3.0
	var e2 := cl_c + bd * 2.8 - bs * 3.6
	e1.y = tr._terrain_mesh_y(e1.x, e1.z)
	e2.y = tr._terrain_mesh_y(e2.x, e2.z)
	_prop("Fauna", "Egreta0", "egret", e1, rng.randf() * TAU, 1.7)
	_prop("Fauna", "Egreta1", "egret", e2, rng.randf() * TAU, 1.7)
	_hide_pose("Egreta0", "Pose_Fly")
	_hide_pose("Egreta1", "Pose_Fly")

	# --- garduri de corali: despartituri TRANSVERSALE intre campuri + capatul
	#     lung (paralel cu drumul doar departe, v >= 56)
	var wn := 0
	wn += _wall_seg(wn, _pos(0.2645, 5.5), _pos(0.2645, 50.0))
	wn += _wall_seg(wn, _pos(0.3050, 5.5), _pos(0.3050, 52.0))
	wn += _wall_seg(wn, _pos(0.2650, -5.5), _pos(0.2650, -38.0))
	wn += _wall_seg(wn, _pos(0.3050, -5.5), _pos(0.3050, -38.0))
	wn += _wall_line_par(wn, 0.2675, 0.3025, 54.0)
	wn += _wall_line_par(wn, 0.2285, 0.2615, 50.0)

	# --- pini Ryukyu (8 in C): rari, la marginile campurilor, nu in axa palatului
	var pines := [
		[0.2270, 9.0], [0.2625, 12.0], [0.2660, 56.0], [0.3045, 10.0],
		[0.3110, 46.0], [0.2400, -14.0], [0.2800, -22.0], [0.3150, -12.0],
	]
	var pn := 0
	for pp in pines:
		var pu := _free_u(float(pp[0]), float(pp[1]), 9.5)
		if pu < 0.0:
			report.append("pin la u=%.3f respins (axa palat)" % float(pp[0]))
			continue
		var p := _pos(pu, float(pp[1]))
		p += Vector3(rng.randf_range(-1.5, 1.5), 0, rng.randf_range(-1.5, 1.5))
		p.y = tr._terrain_mesh_y(p.x, p.z)
		if _blocks_palace(p, 9.5):
			report.append("pin la u=%.3f respins (axa palat)" % float(pp[0]))
			continue
		_prop("Arbori", "Pin%02d" % pn, "pine", p, rng.randf() * TAU, rng.randf_range(0.85, 1.1), 0.2)
		discs.append(Vector3(p.x, p.z, 2.5))
		pn += 1
	# --- cativa fukugi la marginea de departe (fundal verde inchis)
	var fuk := [
		["a", 0.2330, 54.0], ["c", 0.2800, 78.0], ["b", 0.2560, 66.0], ["c", 0.3010, 80.0],
		["a", 0.2500, -30.0], ["c", 0.2950, -34.0],
	]
	var fnn := 0
	for ff in fuk:
		var fu := _free_u(float(ff[1]), float(ff[2]), 8.8)
		if fu < 0.0:
			report.append("fukugi la u=%.3f respins" % float(ff[1]))
			continue
		var p := _pos(fu, float(ff[2]))
		if _occupied(p, 2.0):
			report.append("fukugi la u=%.3f respins" % float(ff[1]))
			continue
		_prop("Arbori", "Fukugi%02d" % fnn, "fukugi_" + String(ff[0]), p, rng.randf() * TAU, rng.randf_range(0.9, 1.15), 0.2)
		discs.append(Vector3(p.x, p.z, 3.0))
		fnn += 1

	# --- cicade (~25): grupuri pe margini, langa case si ziduri
	var cyc := [
		[0.2290, 3.8, 3], [0.2630, 7.0, 4], [0.2680, 7.0, 3], [0.3035, 8.0, 4],
		[0.2470, 44.0, 3], [0.2950, 56.0, 3], [0.3210, 14.0, 2], [0.2420, -9.0, 3], [0.2870, -12.0, 3],
	]
	var cn := 0
	for cc in cyc:
		var cp := _pos(float(cc[0]), float(cc[1]))
		for k in int(cc[2]):
			var p := cp + Vector3(rng.randf_range(-2.4, 2.4), 0, rng.randf_range(-2.4, 2.4))
			p.y = tr._terrain_mesh_y(p.x, p.z)
			if _edge_dist(p) < 3.2 or _occupied(p, 0.5):
				continue
			_prop("Arbori", "Cicada%02d" % cn, "cycad", p, rng.randf() * TAU, rng.randf_range(0.95, 1.4), 0.1)
			cn += 1

	# --- hibiscus: 6 petice (accentul rosu), niciodata aliniate
	var hib := [
		[0.2635, 9.0, 4], [0.3040, 7.5, 5], [0.2475, 44.0, 4], [0.3185, 18.0, 4],
		[0.2400, -7.0, 4], [0.2860, -9.5, 5],
	]
	var hbn := 0
	for hh in hib:
		var hp := _pos(float(hh[0]), float(hh[1]))
		for k in int(hh[2]):
			var p := hp + Vector3(rng.randf_range(-2.0, 2.0), 0, rng.randf_range(-2.0, 2.0))
			p.y = tr._terrain_mesh_y(p.x, p.z)
			if _edge_dist(p) < 3.2 or _occupied(p, 0.5):
				continue
			_prop("Flori", "Hibiscus%02d" % hbn, "hibiscus", p, rng.randf() * TAU, rng.randf_range(1.2, 1.7), 0.05)
			hbn += 1

	# --- iesirea: ext_resource-urile intai
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


## Gard paralel cu drumul, doar departe (>= 50 m): capatul de jos al campului.
func _wall_line_par(wn: int, u0: float, u1: float, v: float) -> int:
	var made := 0
	var u := u0
	var prev := _pos(u, v)
	while u < u1:
		u += 0.0018
		var cur := _pos(u, v)
		made += _wall_seg(wn + made, prev, cur)
		prev = cur
	return made


## Gard de la a la b: segmente de ~4 m (scalate pe Z ca sa se prinda capetele).
func _wall_seg(wn: int, a: Vector3, b: Vector3) -> int:
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
		if _edge_dist(c) < 4.5 or _occupied(c, 0.0):
			continue
		var yaw := atan2(dir.x, dir.z) + rng.randf_range(-0.05, 0.05)
		var b2 := Basis(Vector3.UP, yaw) * Basis.from_scale(Vector3(1.0, 1.0, step / 4.0))
		out.append('[node name="Gard%03d" parent="%s/Garduri" instance=ExtResource("%s")]' % [wn + made, ZONE, _res_id("wall")])
		out.append("transform = " + var_to_str(Transform3D(b2, Vector3(c.x, c.y - 0.12, c.z))))
		out.append("")
		_count("wall")
		made += 1
	return made


# ---------------------------------------------------------------------------

func _inspect(path: String) -> void:
	var root := (load(path) as PackedScene).instantiate() as Node3D
	add_child(root)
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		print("%s | %s | visible %s | path %s" % [path.get_file(), m.name, m.visible, root.get_path_to(m)])
	root.queue_free()
