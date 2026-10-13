extends Node
## Generator pentru montarea kitului Transfagarasan in Track21 (etapa M-scena).
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenMontScena.tscn -- --aabb
##   godot --headless --fixed-fps 60 --path . res://tools/GenMontScena.tscn -- --at --f=0.5
##   godot --headless --fixed-fps 60 --path . res://tools/GenMontScena.tscn -- --nodes
##   godot --headless --fixed-fps 60 --path . res://tools/GenMontScena.tscn -- --out=C:/cale/mont.part
##
## Emite blocuri `[node ...]` pentru `DecorManual` (pozitii si orientari luate din
## traseul COPT al pistei si din raze pe teren, nu din ochi) plus ext_resource-urile
## cu id `m_*`. tools/splice_mont_scena.py le lipeste in Track21.tscn.
##
## Conventii (masurate pe GLB, `--aabb`): fata pieselor e pe -Z local; +X local =
## dreapta fata de sensul de mers; yaw = atan2(-d.x, -d.z) duce -Z pe directia d.

const TRACK := "res://scenes/tracks/Track21.tscn"
const KIT := "res://assets/models/transfagarasan/"

const PATHS := {
	"portal_balea": KIT + "structures/tunnel_portal_balea.glb",
	"dam": KIT + "structures/vidraru_dam.glb",
	"rock_portal": KIT + "structures/rock_tunnel_portal.glb",
	"wall_straight": KIT + "structures/retaining_wall_straight.glb",
	"wall_curve": KIT + "structures/retaining_wall_curve.glb",
	"snow_wall": KIT + "structures/snow_wall.glb",
	"snow_pole": KIT + "props/snow_pole.glb",
	"road_works": KIT + "props/road_works.glb",
	"level_crossing": KIT + "props/level_crossing.glb",
	"bear_sign": KIT + "props/bear_warning_sign.glb",
	"prometheus": KIT + "props/prometheus_statue.glb",
	"poenari": KIT + "buildings/poenari_ruin.glb",
	"bear": KIT + "animals/brown_bear.glb",
	"sheepdog": KIT + "animals/sheepdog.glb",
	"train": KIT + "vehicles/ro_train.glb",
}

var _track: Track
var _space: PhysicsDirectSpaceState3D
var _terrain_rid := RID()
var _pts: PackedVector3Array
var _cum: PackedFloat32Array
var _len := 0.0
var _out: Array[String] = []
var _used := {}
var _counts := {}
var _out_path := ""
var _args: PackedStringArray


func _ready() -> void:
	_args = OS.get_cmdline_user_args()
	for a in _args:
		if a.begins_with("--out="):
			_out_path = a.trim_prefix("--out=")
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	_space = _track.get_world_3d().direct_space_state
	_index_path()
	if "--aabb" in _args:
		_print_aabb()
	elif "--nodes" in _args:
		_print_nodes()
	elif "--at" in _args:
		for a in _args:
			if a.begins_with("--f="):
				_print_at(float(a.trim_prefix("--f=")))
	else:
		_build()
		_write()
	get_tree().quit(0)


func _index_path() -> void:
	_pts = PackedVector3Array(_track.baked)
	_cum = PackedFloat32Array()
	var acc := 0.0
	for i in _pts.size():
		_cum.append(acc)
		acc += _pts[i].distance_to(_pts[(i + 1) % _pts.size()])
	_len = acc
	print("; traseu: %d puncte, %.1f m" % [_pts.size(), _len])


## Arclength la fractia de INDEX `f` (aceeasi conventie ca track.gd: i / n).
func _s_of(f: float) -> float:
	var fi := fposmod(f, 1.0) * _pts.size()
	var i := int(floor(fi))
	var t := fi - i
	return _cum[i] + t * _pts[i].distance_to(_pts[(i + 1) % _pts.size()])


## Punct pe axa la arclength s: pozitia `p`, directia xz `d`, normala DREAPTA
## `r` = (-d.y, d.x), yaw-ul care duce -Z pe `d`, indexul segmentului `i`.
func _at(s: float) -> Dictionary:
	s = fposmod(s, _len)
	var lo := 0
	var hi := _cum.size() - 1
	while lo < hi:
		var mid := (lo + hi + 1) / 2
		if _cum[mid] <= s:
			lo = mid
		else:
			hi = mid - 1
	var a := _pts[lo]
	var b := _pts[(lo + 1) % _pts.size()]
	var seg := maxf(a.distance_to(b), 0.001)
	var p := a.lerp(b, (s - _cum[lo]) / seg)
	var d := Vector2(b.x - a.x, b.z - a.z).normalized()
	return {"p": p, "d": d, "r": Vector2(-d.y, d.x), "yaw": atan2(-d.x, -d.y),
		"i": lo}


func _frac_of_s(s: float) -> float:
	var q := _at(s)
	return float(int(q["i"])) / float(_pts.size())


## Semilatimea soselei la s (din track.width_at, nu presupusa).
func _semi_at(s: float) -> float:
	return _track.width_at(_frac_of_s(s))


## Punctul de pe marginea soselei: axa + side * semilatime * dreapta.
func _rim(s: float, side: float) -> Vector3:
	var q := _at(s)
	var p: Vector3 = q["p"]
	var r: Vector2 = q["r"]
	var w := _semi_at(s)
	return Vector3(p.x + r.x * w * side, p.y, p.z + r.y * w * side)


## Punct la `lat` metri lateral (+ = dreapta) de axa, la s; y = cota axei.
func _lat(s: float, lat: float) -> Vector3:
	var q := _at(s)
	var p: Vector3 = q["p"]
	var r: Vector2 = q["r"]
	return Vector3(p.x + r.x * lat, p.y, p.z + r.y * lat)


func _xf(pos: Vector3, yaw: float, scl: float = 1.0) -> String:
	var b := Basis(Vector3.UP, yaw).scaled(Vector3(scl, scl, scl))
	return var_to_str(Transform3D(b, pos))


## yaw care duce axa locala +X pe directia `d` (piese lungi pe X: recuzita).
func _yaw_x_along(d: Vector2) -> float:
	return atan2(-d.y, d.x)


func _sol(x: float, z: float) -> float:
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


func _print_aabb() -> void:
	for k in PATHS:
		var ps := load(PATHS[k]) as PackedScene
		if ps == null:
			print("%s: LIPSA" % k)
			continue
		var m := ps.instantiate() as Node3D
		add_child(m)
		var bb := Track.model_aabb(m)
		print("%s: pos=%s size=%s" % [k, bb.position, bb.size])
		for c in m.get_children():
			if c is Node3D:
				var cb := Track.model_aabb(c as Node3D)
				print("    %s: pos=%s size=%s" % [c.name, cb.position, cb.size])
		m.queue_free()


func _print_nodes() -> void:
	for c in _track.get_node("DecorManual").get_children():
		var g := (c as Node3D).global_position
		var bi := 0
		var bd := 1e9
		for i in _pts.size():
			var dd := Vector2(g.x - _pts[i].x, g.z - _pts[i].z).length()
			if dd < bd:
				bd = dd
				bi = i
		var q := _at(_cum[bi])
		var qp: Vector3 = q["p"]
		var qr: Vector2 = q["r"]
		var lat: float = (g.x - qp.x) * qr.x + (g.z - qp.z) * qr.y
		print("N %s f=%.4f lat=%.1f y=%.2f road_y=%.2f" % [c.name,
			float(bi) / _pts.size(), lat, g.y, qp.y])


func _print_at(f: float) -> void:
	var s := _s_of(f)
	var q := _at(s)
	var p: Vector3 = q["p"]
	var d: Vector2 = q["d"]
	var line := "f=%.4f s=%.1f p=(%.1f, %.2f, %.1f) d=(%.3f, %.3f) semi=%.2f" % [
		f, s, p.x, p.y, p.z, d.x, d.y, _semi_at(s)]
	for lat in [-30.0, -15.0, -10.0, 10.0, 15.0, 30.0]:
		var e := _lat(s, lat)
		line += "  g(%+.0f)=%.1f" % [lat, _sol(e.x, e.z)]
	print(line)


# ---------------------------------------------------------------- emitere ---

func _res(model: String) -> String:
	_used[model] = true
	return 'ExtResource("m_%s")' % model


func _zone(zname: String) -> void:
	_out.append('[node name="%s" type="Node3D" parent="DecorManual"]\n' % zname)


## Emite o instanta. `keep` = copiii-varianta pastrati (GLB multi-varianta);
## `variants` = toti copiii-radacina ai GLB-ului: ceilalti primesc
## `visible = false` ca plasa de siguranta pana aterizeaza
## WorldProp._prune_variants (commit 25538d2a, inca nemerged).
func _put(zone: String, model: String, nm: String, pos: Vector3, yaw: float,
		scl: float = 1.0, keep: Array = [], variants: Array = []) -> void:
	var lines := '[node name="%s" parent="DecorManual/%s" instance=%s]\ntransform = %s\n' % [
		nm, zone, _res(model), _xf(pos, yaw, scl)]
	if not keep.is_empty():
		var qs: Array[String] = []
		for k in keep:
			qs.append('"%s"' % k)
		lines += 'metadata/keep_variants = PackedStringArray(%s)\n' % ", ".join(qs)
	_out.append(lines)
	for v in variants:
		if not keep.has(v):
			_out.append('[node name="%s" parent="DecorManual/%s/%s"]\nvisible = false\n' % [
				v, zone, nm])
	_counts[model] = int(_counts.get(model, 0)) + 1


func _write() -> void:
	print("; asezate: %s" % [_counts])
	var hdr: Array[String] = []
	for m in _used:
		hdr.append('[ext_resource type="PackedScene" path="%s" id="m_%s"]' % [PATHS[m], m])
	var text := "\n".join(hdr) + "\n\n=====NODES=====\n" + "\n".join(_out) + "\n"
	if _out_path.is_empty():
		print(text)
		return
	var fa := FileAccess.open(_out_path, FileAccess.WRITE)
	fa.store_string(text)
	fa.close()
	print("; scris %s" % _out_path)


# ---------------------------------------------------------------- piesele ---

func _build() -> void:
	_zone("ZonaTunel")
	_portals()
	_zone("ZonaBaraj")
	_dam()
	_zone("ZonaZiduri")
	_walls()
	_zone("ZonaZapada")
	_snow()
	_zone("ZonaRepere")
	_landmarks()


## Portalurile tunelului Capra-Balea, pe axa soselei, fata spre exterior.
func _portals() -> void:
	var s_a := _s_of(0.317)
	var s_b := _s_of(0.350)
	var qa := _at(s_a)
	var qb := _at(s_b)
	var pa: Vector3 = qa["p"]
	var pb: Vector3 = qb["p"]
	# S: masinile intra mergand pe d; fata (-Z local) priveste inapoi spre ele.
	_put("ZonaTunel", "portal_balea", "Portal_S", pa, float(qa["yaw"]) + PI)
	_put("ZonaTunel", "portal_balea", "Portal_N", pb, float(qb["yaw"]))
	# Recuzita santierului: in tunel, pe dreapta, la ~14 m de gura de sud.
	var qw := _at(s_a + 14.0)
	var dw: Vector2 = qw["d"]
	var pw := _lat(s_a + 14.0, 4.3)
	_put("ZonaTunel", "road_works", "Santier_tunel", pw, _yaw_x_along(dw))


## 6 module de baraj pe coronament (0,078-0,123), turnul si centrala pe modulele
## de langa care stau.
func _dam() -> void:
	var s0 := _s_of(0.078)
	var s1 := _s_of(0.123)
	print("; coronament: %.1f m (s %.1f..%.1f)" % [s1 - s0, s0, s1])
	var first := (s0 + s1) * 0.5 - 48.0
	var variants := ["Dam_Module", "Dam_Tower", "Dam_PowerHouse"]
	for k in 6:
		var q := _at(first + 8.0 + 16.0 * k)
		var p: Vector3 = q["p"]
		var yaw: float = q["yaw"]
		_put("ZonaBaraj", "dam", "Dam_%02d" % (k + 1), p, yaw, 1.0,
			["Dam_Module"], variants)
		if k == 2:
			_put("ZonaBaraj", "dam", "Dam_Turn", p, yaw, 1.0, ["Dam_Tower"], variants)
		if k == 3:
			_put("ZonaBaraj", "dam", "Dam_Centrala", p, yaw, 1.0,
				["Dam_PowerHouse"], variants)


## Pasul pe axa care da o coarda de `chord` metri (pe axa) de la s.
func _next_module(s: float, chord: float) -> float:
	var pa: Vector3 = _at(s)["p"]
	var t := s + chord * 0.6
	while t < s + chord * 2.0:
		var pb: Vector3 = _at(t)["p"]
		if Vector2(pb.x - pa.x, pb.z - pa.z).length() >= chord:
			return t
		t += 0.25
	return s + chord


## Pasul care da o coarda de `chord` metri pe MARGINEA `side` (nu pe axa): pe un
## ac de par cu R axa 16 / R exterior 23, 8 m pe margine sunt doar ~5,6 m pe axa.
func _next_rim(s: float, side: float, chord: float) -> float:
	var ea := _rim(s, side)
	var t := s + chord * 0.4
	while t < s + chord * 2.5:
		var eb := _rim(t, side)
		if Vector2(eb.x - ea.x, eb.z - ea.z).length() >= chord:
			return t
		t += 0.1
	return s + chord


## Ziduri de sprijin pe marginea de vale a acelor de par (0,372-0,625).
func _walls() -> void:
	var s := _s_of(0.372)
	var s_end := _s_of(0.625)
	var n := 0
	var curves := 0
	var straights := 0
	while s < s_end:
		var qa := _at(s)
		var look := _at(_next_module(s, 6.0))
		var da: Vector2 = qa["d"]
		var db: Vector2 = look["d"]
		var rr: Vector2 = qa["r"]
		var curved := absf(da.angle_to(db)) > 0.17
		var side := 1.0
		if curved:
			var to_right := (db - da).dot(rr) > 0.0
			side = -1.0 if to_right else 1.0  # partea exterioara virajului
		else:
			# vale = partea cu terenul mai jos cu >= 2 m, la 3 m dincolo de rim
			var best := 0.0
			var drop_best := 2.0
			for sd in [-1.0, 1.0]:
				var e := _rim(s, sd)
				var g := _sol(e.x + rr.x * sd * 3.0, e.z + rr.y * sd * 3.0)
				if e.y - g > drop_best:
					drop_best = e.y - g
					best = sd
			if best == 0.0:
				s = _next_module(s, 8.0)
				continue
			side = best
		var s2 := _next_rim(s, side, 8.0)
		var ea := _rim(s, side)
		var eb := _rim(s2, side)
		var mid := (ea + eb) * 0.5
		var cd := Vector2(eb.x - ea.x, eb.z - ea.z).normalized()
		var yaw := atan2(-cd.x, -cd.y)
		if side < 0.0:
			yaw += PI  # +X local trebuie sa arate spre vale
		var nrm := Vector2(-cd.y, cd.x) * side  # spre exterior (vale)
		n += 1
		if curved:
			curves += 1
			# apexul arcului e cu sageata (~0,35 m) mai spre exterior decat coarda
			_put("ZonaZiduri", "wall_curve", "ZidC%02d" % n,
				mid + Vector3(nrm.x, 0.0, nrm.y) * 0.35, yaw)
		else:
			straights += 1
			_put("ZonaZiduri", "wall_straight", "ZidD%02d" % n, mid, yaw)
		s = s2
	print("; ziduri: %d curbe, %d drepte" % [curves, straights])


## Pereti de zapada pe urcarea D (fata taiata spre sosea) + jaloane pe portiunea
## inalta.
func _snow() -> void:
	var s0 := _s_of(0.268)
	var s1 := _s_of(0.313)
	var s := s0
	var k := 0
	var variants := ["SnowWall_A", "SnowWall_B"]
	var s_util := _closest_s((_track.get_node("DecorManual/Utilaj_parcat") as Node3D).global_position)
	while s + 8.0 <= s1:
		var qc := _at(s + 4.0)
		var yaw: float = qc["yaw"]
		var p: Vector3 = qc["p"]
		var w := _semi_at(s + 4.0)
		for side in [-1.0, 1.0]:
			# stanga (versantul) continuu; dreapta cu goluri (fiecare al 3-lea)
			if side > 0.0 and (k % 3 == 2 or absf(s + 4.0 - s_util) < 8.0):
				continue
			var pos := _lat(s + 4.0, (w + 1.7) * side)
			var g := _sol(pos.x, pos.z)
			if p.y - g > 3.0:
				continue  # deasupra unei prapastii: fara banca plutitoare
			pos.y = minf(p.y, g) - 0.15
			# fata taiata e pe -X local: pe stanga rotim cu PI, ca -X sa arate spre sosea
			var yw := yaw + (PI if side < 0.0 else 0.0)
			var which := "SnowWall_A" if (k + (0 if side < 0.0 else 1)) % 2 == 0 else "SnowWall_B"
			_put("ZonaZapada", "snow_wall",
				"Zapada_%s%02d" % ["S" if side < 0.0 else "D", k], pos, yw, 1.0,
				[which], variants)
		s += 8.0
		k += 1
	var wall_end := s0 + 8.0 * k
	var sp := _s_of(0.250)
	var sp_end := _s_of(0.400)
	var j := 0
	while sp < sp_end:
		var in_snow := sp > s0 - 3.0 and sp < wall_end + 3.0
		if not in_snow:
			var w := _semi_at(sp)
			var sd := 1.0 if j % 2 == 0 else -1.0
			var pos := _lat(sp, (w + 0.9) * sd)
			var g := _sol(pos.x, pos.z)
			if absf(pos.y - g) < 3.0:
				pos.y = g - 0.05
				_put("ZonaZapada", "snow_pole", "Jalon%02d" % j, pos, float(j) * 1.7)
		sp += 20.0
		j += 1


## Reperele: portalul de stanca, urs + semn, Prometeu, Poenari, trecerea la nivel.
func _landmarks() -> void:
	# --- Prometeu: pe pintenul de la capatul de est al barajului (dreapta) ----
	var sp := _s_of(0.129)
	var qp := _at(sp)
	var pp := _lat(sp, 13.0)
	pp.y = _ground_under(pp, 3.2, 12.0) - 0.15
	# fata (-Z) spre masinile care vin de pe baraj: invers decat sensul de mers
	_put("ZonaRepere", "prometheus", "Prometeu", pp, float(qp["yaw"]) + PI)

	# --- portalul de stanca de pe malul Vidraru (C) -----------------------
	var sr := _s_of(0.138)
	var qr := _at(sr)
	var pr: Vector3 = qr["p"]
	pr.y -= 1.0  # coborat 1 m: flancul din stanga atarna peste panta spre lac
	_put("ZonaRepere", "rock_portal", "Portal_Stanca", pr, float(qr["yaw"]) + PI)

	_res("bear")  # modelul de pe Hazarduri/Urs (ext_resource m_bear)
	# --- ursul: semnul "nu hraniti ursii" cu ~45 m inaintea lui, pe dreapta ---
	var bear: Node3D = _track.get_node("Hazarduri/Urs")
	var bi := _closest_s(bear.global_position)
	var ss := bi - 45.0
	var qs := _at(ss)
	var ps := _lat(ss, _semi_at(ss) + 2.2)
	ps.y = _sol(ps.x, ps.z) - 0.05
	_put("ZonaRepere", "bear_sign", "Semn_urs", ps, float(qs["yaw"]) + PI)

	# --- Poenari: stanga-fata pe ultima dreapta, fata spre camera de la ~190 m ---
	var pc := Vector3(-125.0, 0.0, 215.0)
	pc.y = _sol(pc.x, pc.z) - 1.5
	var cam := _at(_s_of(0.90))["p"] as Vector3
	var vx := cam.x - pc.x
	var vz := cam.z - pc.z
	_put("ZonaRepere", "poenari", "Poenari", pc, atan2(-vx, -vz))

	# --- trecerea la nivel: langa stalpii din TrainHazard._build_gates ----------
	var tren: Node3D = _track.get_node("Hazarduri/Tren")
	var st := _closest_s(tren.global_position)
	var qt := _at(st)
	print("; Tren: s=%.1f f=%.4f" % [st, _frac_of_s(st)])
	# cate un ansamblu pe fiecare parte a sinei (stalpii hazardului stau la +-9,6 m
	# de centrul trecerii, deci la 2,6 m de ai nostri); fata spre cine se apropie
	_put("ZonaRepere", "level_crossing", "Trecere_nivel_A", _lat(st - 7.0, 0.0),
		float(qt["yaw"]) + PI)
	_put("ZonaRepere", "level_crossing", "Trecere_nivel_B", _lat(st + 7.0, 0.0),
		float(qt["yaw"]))
	_crossing_report(tren, st)


func _closest_s(pos: Vector3) -> float:
	var bi := 0
	var bd := 1e18
	for i in _pts.size():
		var dd := Vector2(pos.x - _pts[i].x, pos.z - _pts[i].z).length_squared()
		if dd < bd:
			bd = dd
			bi = i
	return _cum[bi]


## Cota terenului sub un obiect cu amprenta de raza `r`: minimul pe 5 puncte,
## ca soclul sa nu pluteasca pe pinten (memoria `terrain-mesh-y-extrapoleaza`).
func _ground_under(pos: Vector3, r: float, cap_above: float) -> float:
	var lo := 1e9
	for off in [Vector2.ZERO, Vector2(r, 0), Vector2(-r, 0), Vector2(0, r), Vector2(0, -r)]:
		lo = minf(lo, _sol(pos.x + off.x, pos.z + off.y))
	return lo


func _crossing_report(tren: Node3D, st: float) -> void:
	var q := _at(st)
	var p: Vector3 = q["p"]
	var r: Vector2 = q["r"]
	var d: Vector2 = q["d"]
	for side in [-1.0, 1.0]:
		var wp := tren.to_global(Vector3(side * 3.4, 0.0, (7.0 + 2.2) * side))
		var rel := Vector2(wp.x - p.x, wp.z - p.z)
		print("; stalp hazard (%+.1f,%+.1f) -> lat=%+.1f along=%+.1f" % [
			side * 3.4, (7.0 + 2.2) * side, rel.dot(r), rel.dot(d)])