extends Node
## Generator de decor MANUAL pentru POI A (Valea Argesului, Track21).
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorTfA.tscn -- --scan|--map|--aabb|--build
##
## --build SCRIE direct in scenes/tracks/Track21.tscn, SUB `DecorManual/ZonaA` (tot ce e intre
## metadata nodului si `ZonaB` se inlocuieste; ext_resource-urile `a_*` din antet la fel).
## Idempotent: se poate rula iar dupa orice ajustare. Nu atinge nimic in afara de ZonaA.
##
## LISTA DE ELEMENTE (decupajul `A` + `A_poenari`), legata de piese (runda 1):
##  1. SATUL, 12-15 case cu acoperis de tabla (argintiu = arges_house_a, rosu = arges_house_b), fatada
##     spre drum, primul rand la 5-6 m de marginea asfaltului (gardul propriu al casei) si al doilea
##     rand pe plat, in spate. Valea reala are doar o fasie plata de ~18 m pe dreapta (conurile
##     ValeA_N/S1/S2 se ridica abrupt dincolo), deci casele se aleg dupa FLATUL amprentei, nu dupa
##     grila: planificator in `_plan_houses`.
##  2. GARDURI de lemn ~120 m: `wooden_fence` (Fence_A, MultiMesh: GLB-ul are doua variante si
##     `keep_variants` nu exista in main), pe linia gardurilor caselor si in jurul pasunii.
##  3. STOGURI/FAN: `hay_bale` la scara mare (stogurile), 1 `hay_cart`, 8 `wood_stack` linga case.
##  4. 4-5 VACI (`cow`) pe pajiste, statice, la >= 15 m de axa, intre case.
##  5. FAGI (`beech_tree_a/b`): primul rand cu coliziune `trunk` ca noduri (paclauri de 3-5, in
##     goluri intre case), masa pe flancurile conurilor ca MultiMesh feliat (coroana pe clasa
##     tf_beech, scoarta pe atlas), livada (fagi mici) printre case, fagi la poalele lui Poenari.
##  6. MOLIZI (`alpine_pines`, variantele B/C/A, MultiMesh pe mesh_name): paclauri inchise pe
##     flancuri, 8-10 izolati langa sat.
##  7. 5 AFLORIMENTE de sist (`schist_outcrop_a/b/c`) in jurul lui Poenari si la marginea padurii.
##  8. FLORI DE PAJISTE (`flower_cluster`, ~25, in petice) si DRUMUL DE PAMANT dintre case (placi
##     plate pe un slot de atlas, FlockProp `disc_slot`): zero materiale noi.
##  Densitate: 0-10 m de margine pajiste scurta + garduri, 10-30 m case/fagi in paclauri, 30-60 m
##  al doilea rand, livada, vaci, molizii in departare.

const TRACK := "res://scenes/tracks/Track21.tscn"

var _track: Track
var _sampler: TrackSideSampler
var _terrain_rid: RID = RID()
var _sus_y := 0.0


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
	if "--scan" in OS.get_cmdline_user_args():
		_scan()
	if "--map" in OS.get_cmdline_user_args():
		_map()
	if "--aabb" in OS.get_cmdline_user_args():
		_aabb()
	if "--build" in OS.get_cmdline_user_args():
		_build()
	get_tree().quit(0)


func _in_a(f: float) -> bool:
	return f >= 0.9786 or f <= 0.064


func _scan() -> void:
	var n := _track.baked.size()
	print("; n=%d" % n)
	var step := 4
	var offs := [-100.0, -80.0, -60.0, -40.0, -30.0, -20.0, -12.0, 12.0, 20.0, 30.0, 40.0, 60.0, 80.0, 100.0]
	var hdr := "; f      x       z      y   fwdx fwdz  w |"
	for o in offs:
		hdr += " %5.0f" % o
	print(hdr)
	var i := 0
	while i < n:
		var f := float(i) / float(n)
		if _in_a(f):
			var p := _track.baked[i]
			var q := _track.baked[(i + 1) % n]
			var fwd := (q - p).normalized()
			var left := Vector3.UP.cross(fwd).normalized()
			var w := _track.width_at_index(i)
			var line := "; %.4f %7.1f %6.1f %5.2f %5.2f %5.2f %.1f |" % [f, p.x, p.z, p.y, fwd.x, fwd.z, w]
			for o in offs:
				# offs negativ = stanga (conventia pistei: stanga = left)
				var c: Vector3 = p + left * (-o)
				var gy := _sol_real(c.x, c.z)
				line += " %5.1f" % (gy - p.y)
			print(line)
		i += step


func _sol_real(x: float, z: float) -> float:
	if _terrain_rid == RID():
		for c in _track.get_children():
			if str(c.name) == "TerrainBody":
				_terrain_rid = (c as StaticBody3D).get_rid()
	var space := _track.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(x, _sus_y, z), Vector3(x, _sus_y - 900.0, z))
	q.collide_with_areas = false
	if _terrain_rid != RID():
		q.collide_with_bodies = true
		q.exclude = []
		var hit: Dictionary = space.intersect_ray(q)
		var guard := 0
		while not hit.is_empty() and hit["rid"] != _terrain_rid and guard < 24:
			q.exclude = q.exclude + [hit["rid"]]
			hit = space.intersect_ray(q)
			guard += 1
		if not hit.is_empty() and hit["rid"] == _terrain_rid:
			return float(hit["position"].y)
	return _sampler.ground_y(x, z)


## Harta de inaltimi (PNG) in jurul zonei A: rosu = sosea, izolinii la 2 m, albastru = pante > 25 %.
func _map() -> void:
	var x0 := -175.0
	var z0 := 190.0
	var w := 220
	var h := 150
	var res := 1.0
	var sc := 6
	var img := Image.create(w * sc, h * sc, false, Image.FORMAT_RGB8)
	var hts := PackedFloat32Array()
	hts.resize(w * h)
	for j in h:
		for i in w:
			hts[j * w + i] = _sol_real(x0 + i * res, z0 + j * res)
	for j in h:
		for i in w:
			var y := hts[j * w + i]
			var gx := (hts[j * w + mini(i + 1, w - 1)] - hts[j * w + maxi(i - 1, 0)]) / (2.0 * res)
			var gz := (hts[mini(j + 1, h - 1) * w + i] - hts[maxi(j - 1, 0) * w + i]) / (2.0 * res)
			var sl := sqrt(gx * gx + gz * gz)
			var col := Color(0.25 + clampf(y / 40.0, 0.0, 1.0) * 0.6, 0.3 + clampf(y / 40.0, 0.0, 1.0) * 0.6, 0.25 + clampf(y / 40.0, 0.0, 1.0) * 0.5)
			if sl > 0.25:
				col = col.lerp(Color(0.2, 0.2, 0.9), clampf((sl - 0.25) * 2.0, 0.0, 0.7))
			if int(floor(y / 2.0)) != int(floor(hts[j * w + maxi(i - 1, 0)] / 2.0)) or int(floor(y / 2.0)) != int(floor(hts[maxi(j - 1, 0) * w + i] / 2.0)):
				col = col.darkened(0.45)
			for a in sc:
				for b in sc:
					img.set_pixel(i * sc + a, j * sc + b, col)
	var n := _track.baked.size()
	for k in n:
		var f := float(k) / float(n)
		var p := _track.baked[k]
		var wd := _track.width_at_index(k)
		var q := _track.baked[(k + 1) % n]
		var fw := Vector2(q.x - p.x, q.z - p.z).normalized()
		var lf := Vector2(fw.y, -fw.x)
		var t := -wd
		while t <= wd:
			var px := (p.x + lf.x * t - x0) / res * sc
			var py := (p.z + lf.y * t - z0) / res * sc
			if px >= 0 and py >= 0 and px < w * sc - 1 and py < h * sc - 1:
				var cc := Color(0.9, 0.1, 0.1) if _in_a(f) else Color(0.6, 0.3, 0.3)
				img.set_pixel(int(px), int(py), cc)
			t += 0.25
	# grila de 20 m
	for gx in range(-160, 41, 20):
		var px := int((gx - x0) / res * sc)
		for yy in h * sc:
			if px >= 0 and px < w * sc:
				img.set_pixel(px, yy, Color(1, 1, 0))
	for gz in range(200, 331, 20):
		var py := int((gz - z0) / res * sc)
		for xx in w * sc:
			if py >= 0 and py < h * sc:
				img.set_pixel(xx, py, Color(1, 1, 0))
	img.save_png("C:/Users/Arion/AppData/Local/Temp/claude/d--GameDev-ignition-spike/3f8c4ccf-462d-462b-aa5a-5294e51a1b5a/scratchpad/mapA.png")
	print("; harta scrisa (x0=%.0f z0=%.0f, %d m/px*%d)" % [x0, z0, int(res), sc])


const KIT := {
	"arges_house_a": "res://assets/models/transfagarasan/buildings/arges_house_a.glb",
	"arges_house_b": "res://assets/models/transfagarasan/buildings/arges_house_b.glb",
	"beech_tree_a": "res://assets/models/transfagarasan/plants/beech_tree_a.glb",
	"beech_tree_b": "res://assets/models/transfagarasan/plants/beech_tree_b.glb",
	"schist_outcrop_a": "res://assets/models/transfagarasan/rocks/schist_outcrop_a.glb",
	"schist_outcrop_b": "res://assets/models/transfagarasan/rocks/schist_outcrop_b.glb",
	"schist_outcrop_c": "res://assets/models/transfagarasan/rocks/schist_outcrop_c.glb",
	"poenari_ruin": "res://assets/models/transfagarasan/buildings/poenari_ruin.glb",
	"cow": "res://assets/models/props/cow.glb",
	"hay_cart": "res://assets/models/vehicles/hay_cart.glb",
	"hay_bale": "res://assets/models/props/hay_bale.glb",
	"wood_stack": "res://assets/models/props/wood_stack.glb",
	"wooden_fence": "res://assets/models/structures/wooden_fence.glb",
	"flower_cluster": "res://assets/models/flowers/flower_cluster.glb",
	"alpine_pines": "res://assets/models/trees/alpine_pines.glb",
}


func _aabb() -> void:
	for k in KIT:
		var scn := load(KIT[k]) as PackedScene
		var root := scn.instantiate()
		var stack: Array[Node] = [root]
		var lo := Vector3(INF, INF, INF)
		var hi := Vector3(-INF, -INF, -INF)
		var parts: Array[String] = []
		while not stack.is_empty():
			var nd: Node = stack.pop_back()
			for c in nd.get_children():
				stack.append(c)
			var mi := nd as MeshInstance3D
			if mi != null and mi.mesh != null:
				var xf := Transform3D.IDENTITY
				var cur: Node = mi
				while cur != null and cur != root:
					if cur is Node3D:
						xf = (cur as Node3D).transform * xf
					cur = cur.get_parent()
				var a := xf * mi.mesh.get_aabb()
				lo = lo.min(a.position)
				hi = hi.max(a.end)
				parts.append("%s[y %.1f..%.1f]" % [mi.name, a.position.y, a.end.y])
		print("; %-18s x %.2f..%.2f  y %.2f..%.2f  z %.2f..%.2f   %s" % [k, lo.x, hi.x, lo.y, hi.y, lo.z, hi.z, " ".join(parts)])
		root.free()


# ------------------------------------------------------------------ constructie

const SCENE_FILE := "res://scenes/tracks/Track21.tscn"
const PARENT := "DecorManual/ZonaA"
const RAD := {"arges_house_a": 7.9, "arges_house_b": 9.0}
## Amprenta casei in cadrul local: [x_min, x_max, z_min, z_max] (fata/prispa/gardul pe -Z).
const HOUSE_FP := {
	"arges_house_a": [-5.2, 5.2, -7.2, 4.2],
	"arges_house_b": [-3.7, 9.4, -7.6, 4.5],
}
const POENARI := Vector2(-125.0, 215.0)

var _rng := RandomNumberGenerator.new()
var _out: Array[String] = []
var _res: Dictionary = {}          # id -> linie ext_resource
var _res_ids: Dictionary = {}      # cheie -> id
var _solid: Array[Vector3] = []    # (x, z, r) corpuri solide plasate
var _n := 0
var _stat: Dictionary = {}
var _houses: Array[Dictionary] = []
var _a_idx: Array[int] = []        # indicii baked din zona A
var _near_idx: Array[int] = []     # toata soseaua din caseta zonei (A + capetele H si B)
const PATH_SLOT := 8               # DRY_VEGETATION: pamantul batut al drumului dintre case
const WANT_BEECH := 130
const WANT_PINE := 640
var _sun_dir := Vector3.ZERO


func _use(key: String, path: String, type: String = "PackedScene") -> String:
	if _res_ids.has(key):
		return _res_ids[key]
	var id := "a_" + key
	_res_ids[key] = id
	_res[id] = '[ext_resource type="%s" path="%s" id="%s"]' % [type, path, id]
	return id


func _count(k: String, v: int = 1) -> void:
	_stat[k] = int(_stat.get(k, 0)) + v


## Distanta de la un punct de lume la MARGINEA benzii cea mai apropiata (zona A).
func _edge_gap(q: Vector2) -> float:
	var best := INF
	for i in _near_idx:
		var p := _track.baked[i]
		var d := Vector2(p.x, p.z).distance_to(q) - _track.width_at_index(i)
		if d < best:
			best = d
	return best


func _yaw_to(from: Vector2, to: Vector2) -> float:
	var d := (to - from).normalized()
	return atan2(-d.x, -d.y)


func _fp_points(model: String, c: Vector2, yaw: float, step: float = 1.6, sc: float = 1.0) -> Array[Vector2]:
	var b := Basis(Vector3.UP, yaw)
	var r: Array = HOUSE_FP[model]
	var pts: Array[Vector2] = []
	var x: float = float(r[0]) * sc
	while x <= float(r[1]) * sc + 0.01:
		var z: float = float(r[2]) * sc
		while z <= float(r[3]) * sc + 0.01:
			var w := b * Vector3(x, 0, z)
			pts.append(Vector2(c.x + w.x, c.y + w.z))
			z += step
		x += step
	return pts


func _house_circle(model: String, c: Vector2, yaw: float, sc: float = 1.0) -> Vector3:
	var r: Array = HOUSE_FP[model]
	var cl := Vector3((float(r[0]) + float(r[1])) * 0.5, 0, (float(r[2]) + float(r[3])) * 0.5) * sc
	var w := Basis(Vector3.UP, yaw) * cl
	return Vector3(c.x + w.x, c.y + w.z, float(RAD[model]) * sc)


## Amprenta unei case: min/max/medie a terenului sub ea.
func _flat(model: String, c: Vector2, yaw: float, sc: float = 1.0) -> Dictionary:
	var lo := INF
	var hi := -INF
	var sum := 0.0
	var k := 0
	for q in _fp_points(model, c, yaw, 1.6, sc):
		var y := _sol_real(q.x, q.y)
		lo = minf(lo, y)
		hi = maxf(hi, y)
		sum += y
		k += 1
	return {"lo": lo, "hi": hi, "mean": sum / maxf(float(k), 1.0), "range": hi - lo}


func _free_skip(c: Vector2, r: float, pad: float, skip: Vector3) -> bool:
	for o in _solid:
		if o.is_equal_approx(skip):
			continue
		if Vector2(o.x, o.y).distance_to(c) < o.z + r + pad:
			return false
	return true


func _free(c: Vector2, r: float, pad: float = 0.0) -> bool:
	for o in _solid:
		if Vector2(o.x, o.y).distance_to(c) < o.z + r + pad:
			return false
	return true


func _tf(pos: Vector3, yaw: float, scl: float) -> String:
	var b := Basis(Vector3.UP, yaw).scaled(Vector3(scl, scl, scl))
	return var_to_str(Transform3D(b, pos))


func _node(base: String, key: String, path: String, pos: Vector3, yaw: float, scl: float, meta: Array = []) -> void:
	_n += 1
	var id := _use(key, path)
	_out.append('[node name="%s%d" parent="%s" instance=ExtResource("%s")]' % [base, _n, PARENT, id])
	_out.append("transform = %s" % _tf(pos, yaw, scl))
	for m in meta:
		_out.append(String(m))
	_out.append("")


func _plan_houses() -> void:
	# Ancore de-a lungul soselei la ~16-20 m: randul 1 (fatada la ~5-6 m de margine), randul 2 in
	# spate si cateva pe stanga acolo unde e plat. Fiecare ancora cauta in jur cea mai plata amprenta.
	# Pasul 2 (daca nu se ating 15 case): aceleasi ancore, case la scara 0,84 (fasia plata e ingusta).
	var anchors: Array[Dictionary] = []
	var n := _track.baked.size()
	var idx := int(0.9790 * float(n))
	var k := 0
	var guard := 0
	while guard < 600:
		guard += 1
		var ii := idx % n
		var fr := float(ii) / float(n)
		if fr > 0.0640 and fr < 0.9700:
			break
		anchors.append({"i": ii, "row": 1, "side": 1.0})
		anchors.append({"i": ii + 3, "row": 2, "side": 1.0})
		if k % 2 == 0:
			anchors.append({"i": ii + 5, "row": 1, "side": -1.0})
		idx += 8 + (k % 3)
		k += 1
	var want := 15
	for pass_i in 2:
		var hsc := 1.0 if pass_i == 0 else 0.84
		for a in anchors:
			if _houses.size() >= want:
				break
			var best := _try_house(a, hsc)
			if best.is_empty():
				continue
			_solid.append(_house_circle(best["model"], best["c"], best["yaw"], hsc))
			_houses.append(best)
	print("; case plasate: %d (tinta %d)" % [_houses.size(), want])
	for h in _houses:
		var fl: Dictionary = h["fl"]
		var cc: Vector2 = h["c"]
		print(";   %s r%d sc %.2f la (%.1f, %.1f) yaw %.0f grade, amprenta %.2f..%.2f (range %.2f)" % [
			h["model"], h["row"], h["sc"], cc.x, cc.y, rad_to_deg(float(h["yaw"])), fl["lo"], fl["hi"], fl["range"]])
		var y: float = float(fl["lo"]) + 0.10 * float(fl["range"]) - 0.05
		_node("Casa", h["model"], KIT[h["model"]], Vector3(cc.x, y, cc.y), h["yaw"], float(h["sc"]))
		_count(h["model"])


func _try_house(a: Dictionary, hsc: float) -> Dictionary:
	var n := _track.baked.size()
	var ii: int = int(a["i"]) % n
	var p := _track.baked[ii]
	var q := _track.baked[(ii + 1) % n]
	var fwd := Vector2(q.x - p.x, q.z - p.z).normalized()
	var right := Vector2(-fwd.y, fwd.x)
	var side: float = a["side"]
	var w := _track.width_at_index(ii)
	var row: int = a["row"]
	var best: Dictionary = {}
	var best_score := INF
	var model: String = "arges_house_a" if (_houses.size() % 2 == 1) else "arges_house_b"
	var base_gap := 12.5 if row == 1 else 30.0
	for dl in [-4.5, -1.5, 0.0, 1.5, 4.5]:
		for dg in [-1.5, 0.0, 2.0, 4.5, 8.0, -4.0]:
			var gap_c: float = base_gap + float(dg)
			if gap_c < 10.8 * hsc:
				continue
			var c2 := Vector2(p.x, p.z) + fwd * float(dl) + right * side * (w + gap_c)
			var tgt := Vector2(p.x, p.z) + fwd * float(dl)
			var yaw := _yaw_to(c2, tgt) + _rng.randf_range(-0.25, 0.25)
			var circ := _house_circle(model, c2, yaw, hsc)
			if not _free(Vector2(circ.x, circ.y), circ.z, 1.2):
				continue
			if POENARI.distance_to(Vector2(circ.x, circ.y)) < 40.0:
				continue
			var ok := true
			for fp in _fp_points(model, c2, yaw, 2.4, hsc):
				if _edge_gap(fp) < 3.7:
					ok = false
					break
			if not ok:
				continue
			var fl := _flat(model, c2, yaw, hsc)
			if float(fl["range"]) > 2.0:
				continue
			var score: float = float(fl["range"]) * 3.0 + absf(float(dg)) * 0.05 + absf(float(dl)) * 0.04
			if score < best_score:
				best_score = score
				best = {"model": model, "c": c2, "yaw": yaw, "fl": fl, "row": row, "side": side, "sc": hsc}
	return best


func _build() -> void:
	_rng.seed = 21001
	var n := _track.baked.size()
	for i in n:
		var f := float(i) / float(n)
		if _in_a(f):
			_a_idx.append(i)
	for i in n:
		var pp := _track.baked[i]
		if pp.x > -215.0 and pp.x < 70.0 and pp.z > 140.0 and pp.z < 345.0:
			_near_idx.append(i)
	_sun()
	_solid.append(Vector3(POENARI.x, POENARI.y, 22.0))
	_plan_houses()
	_extras()
	_forest()
	_fences()
	_flowers()
	_paths()
	_write()


func _sun() -> void:
	var stack: Array[Node] = [_track]
	while not stack.is_empty():
		var nd: Node = stack.pop_back()
		for c in nd.get_children():
			stack.append(c)
		var sun := nd as DirectionalLight3D
		if sun != null:
			var d := -sun.global_transform.basis.z
			_sun_dir = d
			var sh := Vector2(d.x, d.z).normalized()
			print("; soare: lumina merge catre (%.2f, %.2f, %.2f); umbra pe XZ catre (%.2f, %.2f)" % [d.x, d.y, d.z, sh.x, sh.y])
			return
	print("; ATENTIE: nu am gasit DirectionalLight3D")


func _write() -> void:
	var path := ProjectSettings.globalize_path(SCENE_FILE)
	var txt := FileAccess.get_file_as_string(path)
	var lines := txt.split("\n")
	var out: Array[String] = []
	var in_zone := false
	var last_res := -1
	var skip_body := false
	var cleaned: Array[String] = []
	for ln in lines:
		if ln.begins_with("[ext_resource") and ' id="a_' in ln:
			continue
		cleaned.append(ln)
	for i in cleaned.size():
		if cleaned[i].begins_with("[ext_resource"):
			last_res = i
	for i in cleaned.size():
		var ln: String = cleaned[i]
		if skip_body:
			if ln.begins_with('[node name="ZonaB"'):
				skip_body = false
			else:
				continue
		out.append(ln)
		if i == last_res:
			var ids: Array = _res.keys()
			ids.sort()
			for id in ids:
				out.append(String(_res[id]))
		if ln.begins_with('[node name="ZonaA" type="Node3D" parent="DecorManual"]'):
			in_zone = true
		elif in_zone and ln.begins_with("metadata/fractii"):
			out.append("")
			for o in _out:
				out.append(o)
			skip_body = true
			in_zone = false
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("\n".join(out))
	f.close()
	print("; scris %s: %d noduri, %d linii, %d ext_resource" % [path, _n, _out.size(), _res.size()])
	for k in _stat:
		print(";   %s: %d" % [k, _stat[k]])


# ------------------------------------------------------------------ restul compozitiei

## Punct plat si liber: (c, raza libera, interval de gap, range maxim pe un disc de 2 m).
func _spot_ok(c: Vector2, r: float, gap_lo: float, gap_hi: float, flat_max: float = 0.6, pad: float = 0.4) -> bool:
	var g := _edge_gap(c)
	if g < gap_lo or g > gap_hi:
		return false
	if not _free(c, r, pad):
		return false
	if flat_max < 90.0:
		var y0 := _sol_real(c.x, c.y)
		for k in 4:
			var a := float(k) * PI * 0.5
			var y1 := _sol_real(c.x + cos(a) * 1.8, c.y + sin(a) * 1.8)
			if absf(y1 - y0) > flat_max:
				return false
	return true


## Puncte din satul real: sosea aproape + partea dreapta/stanga, pe un interval de index.
func _road_anchor(i: int, side: float, gap: float) -> Vector2:
	var n := _track.baked.size()
	var p := _track.baked[i % n]
	var q := _track.baked[(i + 1) % n]
	var fwd := Vector2(q.x - p.x, q.z - p.z).normalized()
	var right := Vector2(-fwd.y, fwd.x)
	return Vector2(p.x, p.z) + right * side * (_track.width_at_index(i % n) + gap)


func _village_indices() -> Array[int]:
	var r: Array[int] = []
	for i in _a_idx:
		var p := _track.baked[i]
		if p.x > -165.0 and p.x < 12.0:
			r.append(i)
	return r


func _extras() -> void:
	var vi := _village_indices()
	var n := _track.baked.size()
	# --- vaci: 5, pe pajiste, intre case, la 14-30 m de margine, plat
	var cows := 0
	var tries := 0
	while cows < 5 and tries < 1500:
		tries += 1
		var i: int = vi[_rng.randi() % vi.size()]
		var c := _road_anchor(i, 1.0 if _rng.randf() < 0.75 else -1.0, _rng.randf_range(11.0, 38.0))
		if not _spot_ok(c, 2.2, 11.0, 40.0, 0.7, 2.5):
			continue
		var y := _sol_real(c.x, c.y)
		_node("Vaca", "cow", KIT["cow"], Vector3(c.x, y, c.y), _rng.randf_range(0.0, TAU), 1.0)
		_solid.append(Vector3(c.x, c.y, 2.2))
		cows += 1
		_count("cow")
	# --- stoguri: 6 hay_bale mari, la marginea caselor, 12-28 m
	var hay := 0
	tries = 0
	while hay < 4 and tries < 800:
		tries += 1
		var i2: int = vi[_rng.randi() % vi.size()]
		var c2 := _road_anchor(i2, 1.0 if _rng.randf() < 0.8 else -1.0, _rng.randf_range(11.0, 26.0))
		if not _spot_ok(c2, 2.0, 10.0, 30.0, 0.5, 2.0):
			continue
		var y2 := _sol_real(c2.x, c2.y)
		_node("Stog", "hay_bale", KIT["hay_bale"], Vector3(c2.x, y2, c2.y), _rng.randf_range(0.0, TAU), _rng.randf_range(1.8, 2.3))
		_solid.append(Vector3(c2.x, c2.y, 2.0))
		hay += 1
		_count("hay_bale")
	# --- caruta
	tries = 0
	while tries < 400:
		tries += 1
		var i3: int = vi[_rng.randi() % vi.size()]
		var c3 := _road_anchor(i3, 1.0, _rng.randf_range(9.0, 18.0))
		if not _spot_ok(c3, 2.4, 8.0, 22.0, 0.4, 2.0):
			continue
		_node("Caruta", "hay_cart", KIT["hay_cart"], Vector3(c3.x, _sol_real(c3.x, c3.y), c3.y), _rng.randf_range(0.0, TAU), 1.1)
		_solid.append(Vector3(c3.x, c3.y, 2.4))
		_count("hay_cart")
		break
	# --- stive de lemne langa case: 8
	var wood := 0
	for h in _houses:
		if wood >= 8:
			break
		var cc: Vector2 = h["c"]
		var yaw: float = h["yaw"]
		var b := Basis(Vector3.UP, yaw)
		var model: String = h["model"]
		var xr: Array = HOUSE_FP[model]
		for sgn in [1.0, -1.0]:
			var hsc2: float = float(h["sc"])
			var lx: float = ((float(xr[1]) + 1.6) if sgn > 0.0 else (float(xr[0]) - 1.6)) * hsc2
			var w3 := b * Vector3(lx, 0, _rng.randf_range(-3.0, 1.0))
			var c4 := Vector2(cc.x + w3.x, cc.y + w3.z)
			var skip := _house_circle(model, cc, yaw, hsc2)
			if not _free_skip(c4, 1.1, 0.3, skip) or _edge_gap(c4) < 5.0:
				continue
			var y4 := _sol_real(c4.x, c4.y)
			if absf(_sol_real(c4.x + 1.2, c4.y) - y4) > 0.6 or absf(_sol_real(c4.x, c4.y + 1.2) - y4) > 0.6:
				continue
			_node("Lemne", "wood_stack", KIT["wood_stack"], Vector3(c4.x, _sol_real(c4.x, c4.y), c4.y), yaw + _rng.randf_range(-0.3, 0.3) + (PI * 0.5), _rng.randf_range(1.0, 1.35))
			_solid.append(Vector3(c4.x, c4.y, 1.1))
			wood += 1
			_count("wood_stack")
			break
	# --- aflorimente: 3 la Poenari (la 22-30 m de nod), 2 la marginea padurii pe flancul nordic
	var oc_defs := [
		["schist_outcrop_b", 205.0, 25.0], ["schist_outcrop_a", 255.0, 27.0], ["schist_outcrop_c", 150.0, 25.0],
	]
	for od in oc_defs:
		var ang := deg_to_rad(float(od[1]))
		var c5 := POENARI + Vector2(cos(ang), sin(ang)) * float(od[2])
		if not _free(c5, 3.0, 0.3):
			continue
		_node("Aflorim", String(od[0]), KIT[String(od[0])], Vector3(c5.x, _sol_real(c5.x, c5.y), c5.y), _rng.randf_range(0.0, TAU), _rng.randf_range(1.0, 1.25))
		_solid.append(Vector3(c5.x, c5.y, 3.0))
		_count(String(od[0]))
	var placed2 := 0
	tries = 0
	while placed2 < 2 and tries < 400:
		tries += 1
		var i6: int = vi[_rng.randi() % vi.size()]
		var c6 := _road_anchor(i6, -1.0, _rng.randf_range(14.0, 26.0))
		if not _spot_ok(c6, 3.5, 12.0, 30.0, 1.2, 1.5):
			continue
		var key6 := "schist_outcrop_a" if placed2 == 0 else "schist_outcrop_c"
		_node("Aflorim", key6, KIT[key6], Vector3(c6.x, _sol_real(c6.x, c6.y) - 0.2, c6.y), _rng.randf_range(0.0, TAU), _rng.randf_range(1.0, 1.3))
		_solid.append(Vector3(c6.x, c6.y, 3.5))
		placed2 += 1
		_count(key6)
	# --- primul rand de fagi cu coliziune: 5 paclauri de 3
	var clusters := 0
	tries = 0
	while clusters < 5 and tries < 500:
		tries += 1
		var i7: int = vi[_rng.randi() % vi.size()]
		var side7 := 1.0 if _rng.randf() < 0.55 else -1.0
		var c7 := _road_anchor(i7, side7, _rng.randf_range(10.0, 22.0))
		if not _spot_ok(c7, 5.0, 9.0, 26.0, 99.0, 0.5):
			continue
		for k in 3:
			var a7 := _rng.randf_range(0.0, TAU)
			var q7 := c7 + Vector2(cos(a7), sin(a7)) * _rng.randf_range(1.5, 4.0)
			if _edge_gap(q7) < 8.0 or not _free(q7, 1.2, 0.0):
				continue
			var kk := "beech_tree_a" if _rng.randf() < 0.5 else "beech_tree_b"
			_node("Fag", kk, KIT[kk], Vector3(q7.x, _sol_real(q7.x, q7.y), q7.y), _rng.randf_range(0.0, TAU), _rng.randf_range(0.95, 1.3))
			_solid.append(Vector3(q7.x, q7.y, 1.2))
			_count(kk)
		clusters += 1


# ------------------------------------------------------------------ MultiMesh: paduri, garduri, flori, drum

## Un stol (FlockProp) ca noduri `MultiMeshInstance3D`.
func _flock(base: String, key: String, mesh_name: String, pos: PackedVector3Array,
		yaws: PackedFloat32Array, sc: Array, tri_class: String = "", view_m: float = 0.0) -> void:
	if pos.is_empty():
		return
	_n += 1
	var id := _use(key, KIT[key])
	var sid := _use("flock", "res://scenes/props/flock.gd", "Script")
	_out.append('[node name="%s%d" type="MultiMeshInstance3D" parent="%s"]' % [base, _n, PARENT])
	_out.append('script = ExtResource("%s")' % sid)
	_out.append('model = ExtResource("%s")' % id)
	if mesh_name != "":
		_out.append('mesh_name = "%s"' % mesh_name)
	if tri_class != "":
		_out.append('tri_class = "%s"' % tri_class)
	if view_m > 0.0:
		_out.append("view_m = %.1f" % view_m)
	_out.append("positions = %s" % var_to_str(pos))
	_out.append("yaws = %s" % var_to_str(yaws))
	_out.append("scale3_list = Array[Vector3](%s)" % var_to_str(sc))
	_out.append("")
	_count("flock:" + base, pos.size())


func _noise_at(nz: FastNoiseLite, p: Vector2) -> float:
	return nz.get_noise_2d(p.x, p.y) * 0.5 + 0.5


func _forest() -> void:
	var nz := FastNoiseLite.new()
	nz.seed = 4242
	nz.frequency = 0.05
	# Felii pe x (culling): 4 felii
	var cuts := [-200.0, -130.0, -75.0, -20.0, 40.0]
	var slices := cuts.size() - 1
	var pos := {}
	var yw := {}
	var scl := {}
	var grid := {}
	var want_beech := WANT_BEECH
	var want_pine := WANT_PINE
	var nb := 0
	var np := 0
	var tries := 0
	var forced: Array[Dictionary] = []
	# Poenari: inel de fagi la poale (24-34 m, pe toate partile), apoi padurea din jur: molizi si fagi
	# pe flancurile si in spatele ruinei (spre nord si vest, departe de sosea), ca in decupajul A_poenari.
	for k in 14:
		var a := deg_to_rad(float(k) * 25.7 + 12.0)
		var q := POENARI + Vector2(cos(a), sin(a)) * _rng.randf_range(24.0, 34.0)
		forced.append({"p": q, "kind": "beech"})
	for k in 12:
		var a3 := deg_to_rad(_rng.randf_range(170.0, 370.0))
		var q3b := POENARI + Vector2(cos(a3), sin(a3)) * _rng.randf_range(36.0, 58.0)
		forced.append({"p": q3b, "kind": "beech"})
	for k in 46:
		var a2 := deg_to_rad(_rng.randf_range(160.0, 380.0))
		var q2 := POENARI + Vector2(cos(a2), sin(a2)) * _rng.randf_range(27.0, 66.0)
		forced.append({"p": q2, "kind": "pine"})
	var vi := _village_indices()
	var all_idx: Array[int] = []
	for i in _near_idx:
		var pp := _track.baked[i]
		if pp.x > -190.0 and pp.x < 30.0 and pp.z > 215.0:
			all_idx.append(i)
	var cand: Array[Dictionary] = forced.duplicate()
	for t in 60000:
		var i: int = all_idx[_rng.randi() % all_idx.size()]
		var side := 1.0 if _rng.randf() < 0.5 else -1.0
		# distanta de la margine: mai multe aproape (sqrt inversat), pana la ~100 m
		var u := _rng.randf()
		var gap := 9.0 + pow(u, 1.35) * 112.0
		var along := _rng.randf_range(-4.0, 4.0)
		var q3 := _road_anchor(i, side, gap)
		var nn := _track.baked.size()
		var pn := _track.baked[(i + 1) % nn]
		var pc := _track.baked[i]
		var fw := Vector2(pn.x - pc.x, pn.z - pc.z).normalized()
		q3 += fw * along
		cand.append({"p": q3, "kind": ""})
	for cd in cand:
		if nb >= want_beech and np >= want_pine:
			break
		tries += 1
		var q4: Vector2 = cd["p"]
		var forced_t: bool = String(cd["kind"]) != ""
		if q4.x < -215.0 or q4.x > 32.0:
			continue
		if POENARI.distance_to(q4) < 21.0:
			continue
		var g := _edge_gap(q4)
		if g < 9.0:
			continue
		if not _free(q4, 2.2, 0.0):
			continue
		var kind: String = String(cd["kind"])
		var cell := Vector2i(int(floor(q4.x / 3.4)), int(floor(q4.y / 3.4)))
		var busy := false
		var rmin := 3.3
		for dx in [-1, 0, 1]:
			for dz in [-1, 0, 1]:
				var ck := Vector2i(cell.x + int(dx), cell.y + int(dz))
				if grid.has(ck):
					for o in grid[ck]:
						if (o as Vector2).distance_to(q4) < rmin:
							busy = true
		if busy:
			continue
		var gy := _sol_real(q4.x, q4.y)
		var rel := gy - _nearest_axis_y(q4)
		if kind == "":
			# plat si aproape de drum = satul/pajistea: doar paclauri rare; panta = padure densa
			var nv := _noise_at(nz, q4)
			var dens := 0.97
			if rel < 1.5:
				dens = 0.10 if g < 26.0 else (0.60 if nv > 0.45 else 0.08)
			elif rel < 4.0:
				dens = 0.85
			if _rng.randf() > dens:
				continue
			var pb := clampf(0.95 - rel / 9.0, 0.05, 0.85)
			kind = "beech" if _rng.randf() < pb else "pine"
			# fagul (coroana 10 m) nu sta in marginea soselei: umbra si ocluzia; molidul mai aproape
			if kind == "beech" and g < 19.0:
				kind = "pine"
			if kind == "pine" and g < 11.5:
				continue
			if kind == "beech" and nb >= want_beech:
				continue
			if kind == "pine" and np >= want_pine:
				continue
		if kind == "beech":
			var near_b := false
			for dx2 in [-1, 0, 1]:
				for dz2 in [-1, 0, 1]:
					var ck2 := Vector2i(cell.x + int(dx2), cell.y + int(dz2))
					if grid.has(ck2):
						for o2 in grid[ck2]:
							if (o2 as Vector2).distance_to(q4) < 5.2:
								near_b = true
			if near_b:
				continue
		if not grid.has(cell):
			grid[cell] = []
		(grid[cell] as Array).append(q4)
		var sl := 0
		for s in slices:
			if q4.x >= float(cuts[s]) and q4.x < float(cuts[s + 1]):
				sl = s
		var yaw := _rng.randf_range(0.0, TAU)
		if kind == "beech":
			var v := "a" if _rng.randf() < 0.5 else "b"
			var s0 := _rng.randf_range(0.85, 1.4)
			var u3 := _rng.randf_range(0.9, 1.15)
			for part in ["L", "B"]:
				var key := "beech_%s_%s_%d" % [v, part, sl]
				_push(pos, yw, scl, key, Vector3(q4.x, gy - 0.1, q4.y), yaw, Vector3(s0 * u3, s0, s0 * u3))
			nb += 1
		else:
			var r := _rng.randf()
			var v2 := "B" if r < 0.5 else ("C" if r < 0.85 else "A")
			var s1 := _rng.randf_range(0.8, 1.4)
			var u2 := _rng.randf_range(0.9, 1.1)
			for part2 in ["P", "T"]:
				var key2 := "pine_%s_%s_%d" % [v2, part2, sl]
				_push(pos, yw, scl, key2, Vector3(q4.x, gy - 0.1, q4.y), yaw, Vector3(s1 * u2, s1, s1 * u2))
			np += 1
	var keys: Array = pos.keys()
	keys.sort()
	for key3 in keys:
		var parts: PackedStringArray = String(key3).split("_")
		if parts[0] == "beech":
			var model := "beech_tree_" + parts[1]
			if parts[2] == "L":
				_flock("FagiCoroana", model, "Beech_Leaves", pos[key3], yw[key3], scl[key3], "tf_beech", 190.0)
			else:
				_flock("FagiScoarta", model, "Beech_Bark", pos[key3], yw[key3], scl[key3], "", 190.0)
		else:
			var mn := "Pine_" + parts[1] if parts[2] == "P" else "Trunk_" + parts[1]
			_flock("Molizi", "alpine_pines", mn, pos[key3], yw[key3], scl[key3], "tf_jneapan" if parts[2] == "P" else "", 230.0)
	print("; paduri: %d fagi, %d molizi (MultiMesh), %d candidati" % [nb, np, tries])
	_count("fagi_mm", nb)
	_count("molizi_mm", np)


## Adauga o instanta intr-un grup de stoluri (Dictionary de Packed*: se rescrie valoarea, nu se modifica o copie).
func _push(pos: Dictionary, yw: Dictionary, scl: Dictionary, key: String, p: Vector3, yaw: float, sc: Vector3) -> void:
	var pa: PackedVector3Array = pos.get(key, PackedVector3Array())
	pa.append(p)
	pos[key] = pa
	var ya: PackedFloat32Array = yw.get(key, PackedFloat32Array())
	ya.append(yaw)
	yw[key] = ya
	var sa: Array = scl.get(key, [])
	sa.append(sc)
	scl[key] = sa


func _nearest_axis_y(q: Vector2) -> float:
	var best := INF
	var by := 0.0
	for i in _near_idx:
		var p := _track.baked[i]
		var d := Vector2(p.x, p.z).distance_squared_to(q)
		if d < best:
			best = d
			by = p.y
	return by


## Garduri: linia din marginea satului (gap 3.6 m) in randuri de 14-30 m cu goluri, plus o
## ingradire in jurul vacilor. Segmentele sunt `Fence_A` (2,04 m), orientate pe tangenta.
func _fences() -> void:
	var pos := PackedVector3Array()
	var yws := PackedFloat32Array()
	var sc: Array = []
	var c1 := _fence_line(pos, yws, sc, 3.4, 1.0, 50, 10, 18)
	var c2 := _fence_line(pos, yws, sc, 13.5, 1.0, 36, 6, 12)
	var c3 := _fence_line(pos, yws, sc, 5.0, -1.0, 22, 6, 12)
	_flock("Garduri", "wooden_fence", "Fence_A", pos, yws, sc, "", 150.0)
	var count := c1 + c2 + c3
	print("; garduri: %d segmente de 2,04 m = %.0f m (margine %d, pasune %d, stanga %d)" % [count, count * 2.04, c1, c2, c3])
	_count("garduri_m", int(count * 2.04))


## O linie de gard la `gap` m de marginea soselei, pe `side`, in randuri de `rmin`..`rmax` segmente cu goluri.
## Un rand sub 4 segmente se arunca (sine singuratice pe iarba citesc ca resturi, nu ca gard).
func _fence_line(pos: PackedVector3Array, yws: PackedFloat32Array, sc: Array, gap: float,
		side: float, maxn: int, rmin: int, rmax: int) -> int:
	var vi := _village_indices()
	var run_left := 0
	var gap_left := 0
	var count := 0
	var prev := Vector2.ZERO
	var have_prev := false
	var buf_p := PackedVector3Array()
	var buf_y := PackedFloat32Array()
	for i in vi:
		if count + buf_p.size() >= maxn:
			break
		var o := _road_anchor(i, side, gap)
		if not have_prev:
			prev = o
			have_prev = true
			continue
		if o.distance_to(prev) < 2.04:
			continue
		var mid := (o + prev) * 0.5
		var t := (o - prev).normalized()
		prev = o
		var good := true
		if gap_left > 0:
			gap_left -= 1
			good = false
		else:
			if run_left <= 0:
				run_left = rmin + (_rng.randi() % (rmax - rmin + 1))
			run_left -= 1
			if run_left == 0:
				gap_left = 3 + (_rng.randi() % 3)
		if good:
			if not _free(mid, 0.3, 0.0) or _edge_gap(mid) < 2.8:
				good = false
		if good:
			for h in _houses:
				var circ := _house_circle(h["model"], h["c"], h["yaw"], float(h["sc"]))
				if Vector2(circ.x, circ.y).distance_to(mid) < circ.z + 1.5:
					good = false
					break
		var y0 := 0.0
		if good:
			y0 = _sol_real(mid.x, mid.y)
			if absf(_sol_real(mid.x + t.x * 1.0, mid.y + t.y * 1.0) - y0) > 0.9:
				good = false
		if good:
			buf_p.append(Vector3(mid.x, y0, mid.y))
			buf_y.append(atan2(-t.y, t.x))
		if (not good) or run_left == 0:
			count += _flush_run(buf_p, buf_y, pos, yws, sc)
			buf_p = PackedVector3Array()
			buf_y = PackedFloat32Array()
	count += _flush_run(buf_p, buf_y, pos, yws, sc)
	return count


func _flush_run(bp: PackedVector3Array, by: PackedFloat32Array, pos: PackedVector3Array,
		yws: PackedFloat32Array, sc: Array) -> int:
	if bp.size() < 4:
		return 0
	for k in bp.size():
		pos.append(bp[k])
		yws.append(by[k])
		sc.append(Vector3.ONE)
	return bp.size()


func _flowers() -> void:
	var vi := _village_indices()
	var pos := PackedVector3Array()
	var yws := PackedFloat32Array()
	var sc: Array = []
	var patches := 0
	var tries := 0
	while patches < 5 and tries < 300:
		tries += 1
		var i: int = vi[_rng.randi() % vi.size()]
		var c := _road_anchor(i, 1.0 if _rng.randf() < 0.7 else -1.0, _rng.randf_range(6.0, 22.0))
		if not _spot_ok(c, 1.5, 5.0, 26.0, 0.6, 0.2):
			continue
		for k in _rng.randi_range(4, 7):
			var a := _rng.randf_range(0.0, TAU)
			var q := c + Vector2(cos(a), sin(a)) * _rng.randf_range(0.4, 3.0)
			if _edge_gap(q) < 4.0 or not _free(q, 0.3, 0.0):
				continue
			pos.append(Vector3(q.x, _sol_real(q.x, q.y), q.y))
			yws.append(_rng.randf_range(0.0, TAU))
			var s := _rng.randf_range(1.0, 1.7)
			sc.append(Vector3(s, s, s))
		patches += 1
	_flock("Flori", "flower_cluster", "", pos, yws, sc, "", 120.0)
	print("; flori: %d buchete in %d petice" % [pos.size(), patches])


## Drumul de pamant: placi plate (FlockProp `disc_slot`) de la poarta fiecarei case la sosea.
func _paths() -> void:
	var pos := PackedVector3Array()
	var yws := PackedFloat32Array()
	var sc: Array = []
	for h in _houses:
		var cc: Vector2 = h["c"]
		var yaw: float = h["yaw"]
		var b := Basis(Vector3.UP, yaw)
		var g0 := b * Vector3(0.0, 0.0, -7.0)
		var a := cc + Vector2(g0.x, g0.z)
		# spre cel mai apropiat punct de pe margine
		var best := INF
		var tgt := a
		for i in _near_idx:
			var p := _track.baked[i]
			var d := Vector2(p.x, p.z).distance_to(a)
			if d < best:
				best = d
				tgt = Vector2(p.x, p.z)
		var dir := (tgt - a).normalized()
		var w := 7.0
		var dist := minf(best - w - 0.3, 3.5)
		var t := 0.0
		while t < dist:
			var q := a + dir * t
			pos.append(Vector3(q.x, _sol_real(q.x, q.y) + 0.07, q.y))
			yws.append(0.0)
			var s := _rng.randf_range(0.95, 1.25)
			sc.append(Vector3(s, 1.0, s))
			t += 1.3
	_n += 1
	var sid := _use("flock", "res://scenes/props/flock.gd", "Script")
	_out.append('[node name="Poteca%d" type="MultiMeshInstance3D" parent="%s"]' % [_n, PARENT])
	_out.append('script = ExtResource("%s")' % sid)
	_out.append("disc_slot = %d" % PATH_SLOT)
	_out.append("disc_radius = 1.1")
	_out.append("view_m = 140.0")
	_out.append("positions = %s" % var_to_str(pos))
	_out.append("yaws = %s" % var_to_str(yws))
	_out.append("scale3_list = Array[Vector3](%s)" % var_to_str(sc))
	_out.append("")
	print("; poteci: %d placi" % pos.size())
	_count("poteca_placi", pos.size())
