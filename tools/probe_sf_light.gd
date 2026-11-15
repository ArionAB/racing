extends Node
## LUMINA PE TRASEUL REAL San Francisco (Track25, brief san_francisco.md §4 si §7 pasul 2b).
## Pasul 0 a masurat soarele pe strada SINTETICA (tools/probe_sf_loc.gd, casele din
## sf_loc_decor.gd). Pe B200 strada tramvaiului 1 s-a rotit: urcarea merge spre S, adica SPRE
## soare. Sonda asta pune pe traseul real RANDURI DE CASE-CUTIE cu gabaritul caselor de la pasul 0
## (fatada la 10,5 m de axa = trotuar de 3,5 m, 7 m latime, 12 m adancime, podeaua la cota
## trotuarului din capatul de SUS + 0,15, 10,5 m inaltime pana la cornisa / mijlocul frontonului,
## soclu pana la 3 m sub capatul de jos), cu o strada transversala de 14 m la fiecare 72 m (pe lant:
## in mijlocul intersectiilor plate), si masoara:
##   1. SOARE PE CAROSABIL: raze din grila de pe sosea (0,5 m x 1 m, +-6,75 m) spre soarele PISTEI
##      (`custom_sun_rotation_deg`), contra caselor si a terenului;
##   2. CONTRA-LUMINA: unghiul dintre directia de mers si azimutul soarelui pe fiecare strada
##      (sub ~60 de grade, camera de urmarire vede fatadele din umbra: soarele e in fata);
##   3. FATADELE de pe laturile strazii: N.L (pozitiv = la soare).
## Strazile vin din `metadata/sf_streets` (nume -> Vector2(frac start, frac end) pe INDEX), scrise de
## tools/gen_sf_route.py (si pe bucla veche, cu SF_LAYOUT=vechi SF_OUT=...).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeSfLight.tscn -- [--scene=res://...]
##       [--sun=EL,AZ]   (suprascrie soarele pistei, conventia temei; reglajul se cauta aici)
##
## Nu e verdict de arta: casele-cutie nu au bovindouri, fronton sau decalaj; e aceeasi aproximare
## ca la pasul 0, deci cifrele se compara intre ele (bucla veche / B200 / alt soare), nu cu ochiul.
##
##   ... -- --real   (pasul 8) FARA casele-cutie: masoara contra caselor REALE ale pistei, adica
##       instantele kitului de sub `DecorManual` cu metadata `sf_case` (scrise de gen_sf_route.py),
##       cu un corp trimesh din geometria lor randata (fronton, cornisa, turnulet, bovindou) — ca
##       `tools/sf_loc_decor.gd --glb` pe strada sintetica. Plus cutiile lor (`CaseCorpuri`). Pe
##       scena fara case (`SF_CASE=0`) da soarele pe carosabil contra terenului singur. Din pasul 8b
##       si randurile din spate (`CityFill` cu metadata `sf_spate`), cu aceeasi geometrie.

const ROAD_HALF_SAMPLE: float = 6.75
const FACADE_OFF: float = 10.5
const HOUSE_W: float = 7.0
const HOUSE_D: float = 12.0
const HOUSE_H: float = 10.5
const CROSS_EVERY: float = 72.0
const CROSS_W: float = 14.0

var _scene: String = "res://scenes/tracks/Track25.tscn"
var _sun_over := Vector3.ZERO
var _real := false
var _track: Track
var _houses: Node3D


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--scene="):
			_scene = a.trim_prefix("--scene=")
		elif a.begins_with("--sun="):
			var p := a.trim_prefix("--sun=").split(",")
			_sun_over = Vector3(-float(p[0]), float(p[1]), 0.0)
		elif a == "--real":
			_real = true
	_track = (load(_scene) as PackedScene).instantiate() as Track
	if _sun_over != Vector3.ZERO:
		_track.set("custom_sun_rotation_deg", _sun_over)
	add_child(_track)
	for _i in 4:
		await get_tree().process_frame
		await get_tree().physics_frame
	if not _track.has_meta("sf_streets"):
		push_error("ProbeSfLight: pista n-are metadata/sf_streets")
		get_tree().quit(1)
		return
	var sun_rot: Vector3 = _track._sun_rotation_deg()
	var b := Basis.from_euler(Vector3(deg_to_rad(sun_rot.x), deg_to_rad(sun_rot.y), deg_to_rad(sun_rot.z)))
	var to_sun := -(b * Vector3.FORWARD)
	var sun_h := Vector2(to_sun.x, to_sun.z).normalized()
	print("ProbeSfLight: %s, soare %s -> spre soare %s (elevatie %.1f grade, azimut busola %.0f)" % [
		_scene.get_file(), sun_rot, to_sun, rad_to_deg(asin(to_sun.y)),
		fposmod(rad_to_deg(atan2(to_sun.x, -to_sun.z)), 360.0)])
	_houses = Node3D.new()
	add_child(_houses)
	var streets: Dictionary = _track.get_meta("sf_streets")
	var r := _track.routes[0]
	var n := r.baked.size()
	var spans := {}
	for key: String in streets:
		var w: Vector2 = streets[key]
		var i0 := int(w.x * float(n))
		var i1 := int(w.y * float(n))
		var idx: Array[int] = []
		var i := i0
		while i != i1:
			idx.append(i)
			i = (i + 1) % n
		spans[key] = idx
		if not _real:
			_build_rows(r, idx)
	if _real:
		print("  --real: %d case reale (trimesh din geometria randata)" % _real_houses())
	for _i in 4:
		await get_tree().physics_frame
	var space := get_viewport().world_3d.direct_space_state
	var tot_all := 0
	var lit_all := 0
	for key: String in spans:
		var idx: Array[int] = spans[key]
		var lit := 0
		var tot := 0
		var by_house := 0
		var head_ang: Array[float] = []
		var nl_l: Array[float] = []
		var nl_r: Array[float] = []
		var acc := 0.0
		for k in idx.size() - 1:
			var p0: Vector3 = r.baked[idx[k]]
			var p1: Vector3 = r.baked[idx[k + 1]]
			acc += Vector2(p1.x - p0.x, p1.z - p0.z).length()
			if acc < 1.0:
				continue
			acc = 0.0
			var fwd := Vector2(p1.x - p0.x, p1.z - p0.z).normalized()
			var side := Vector3(-fwd.y, 0.0, fwd.x)     # dreapta mersului (x, z)
			head_ang.append(rad_to_deg(acos(clampf(fwd.dot(sun_h), -1.0, 1.0))))
			# fatada din DREAPTA are normala spre stanga (spre strada), cea din stanga spre dreapta
			nl_r.append(Vector3(-side.x, 0.0, -side.z).dot(to_sun))
			nl_l.append(side.dot(to_sun))
			var x := -ROAD_HALF_SAMPLE
			while x <= ROAD_HALF_SAMPLE + 0.01:
				var top := p0 + side * x + Vector3.UP * 6.0
				var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(top, top + Vector3.DOWN * 12.0))
				if not hit.is_empty():
					var q: Vector3 = hit["position"] + Vector3.UP * 0.05
					var h2 := space.intersect_ray(PhysicsRayQueryParameters3D.create(q, q + to_sun * 300.0))
					tot += 1
					if h2.is_empty():
						lit += 1
					elif (h2["collider"] as Node).is_in_group("sf_light_house"):
						by_house += 1
				x += 0.5
		tot_all += tot
		lit_all += lit
		head_ang.sort()
		var contra := 0
		for a in head_ang:
			if a < 60.0:
				contra += 1
		print("  %-14s soare pe carosabil %5.1f%% (%d puncte, umbra de case %.1f%%) | unghi mers-soare median %3.0f grade, contra-lumina (< 60) %3.0f%% | fatada stanga N.L %+.2f, dreapta %+.2f" % [
			key, 100.0 * float(lit) / maxf(float(tot), 1.0), tot,
			100.0 * float(by_house) / maxf(float(tot), 1.0),
			head_ang[head_ang.size() / 2] if not head_ang.is_empty() else -1.0,
			100.0 * float(contra) / maxf(float(head_ang.size()), 1.0), _mean(nl_l), _mean(nl_r)])
	print("  TOATE strazile masurate: %.1f%% la soare" % (100.0 * float(lit_all) / maxf(float(tot_all), 1.0)))
	get_tree().quit(0)


## Corpuri trimesh din geometria caselor reale (instantele cu `sf_case`), in grupul caselor.
func _real_houses() -> int:
	var dm := _track.get_node_or_null(^"DecorManual")
	var corp := _track.get_node_or_null(^"CaseCorpuri")
	if corp != null:
		corp.add_to_group("sf_light_house")
	if dm == null:
		return 0
	var n := 0
	var stack: Array[Node] = [dm]
	while not stack.is_empty():
		var nd: Node = stack.pop_back()
		for c in nd.get_children():
			stack.append(c)
		if not (nd is Node3D and nd.has_meta("sf_case")):
			continue
		n += 1
		var body := StaticBody3D.new()
		body.add_to_group("sf_light_house")
		for c in nd.find_children("*", "MeshInstance3D", true, false):
			var mi := c as MeshInstance3D
			if mi.mesh == null:
				continue
			var faces := mi.mesh.get_faces()
			var xf := mi.global_transform
			for i in faces.size():
				faces[i] = xf * faces[i]
			var shape := ConcavePolygonShape3D.new()
			shape.backface_collision = true
			shape.set_faces(faces)
			var cs := CollisionShape3D.new()
			cs.shape = shape
			body.add_child(cs)
		_houses.add_child(body)
	return n + _real_back_houses()


## Pasul 8b: si randurile din SPATE (`CityFill` cu metadata `sf_spate`, instante explicite scrise
## de gen_sf_route.py), cu aceeasi geometrie randata: modelul (sau perechea lui `_m`, pentru o
## instanta ceruta oglindit — exact ce deseneaza CityFill) sub transformarea instantei.
func _real_back_houses() -> int:
	var n := 0
	for fill_n in _track.find_children("*", "CityFill", true, false):
		var fill := fill_n as CityFill
		if not fill.has_meta("sf_spate"):
			continue
		var faces_of := {}      # scena -> fetele ei in spatiul modelului
		var f := fill.explicit_xforms
		var i := 0
		while i + 13 <= f.size():
			var mi := int(f[i])
			var b := Basis(Vector3(f[i + 1], f[i + 2], f[i + 3]), Vector3(f[i + 4], f[i + 5], f[i + 6]),
				Vector3(f[i + 7], f[i + 8], f[i + 9]))
			var xf := Transform3D(b, Vector3(f[i + 10], f[i + 11], f[i + 12]))
			i += 13
			var scene: PackedScene = fill.models[mi]
			if b.determinant() < 0.0 and mi < fill.mirror_models.size() and fill.mirror_models[mi] != null:
				scene = fill.mirror_models[mi]
				xf.basis.x = -xf.basis.x
			if not faces_of.has(scene):
				var inst := scene.instantiate() as Node3D
				var all := PackedVector3Array()
				for c in inst.find_children("*", "MeshInstance3D", true, false):
					var mi3 := c as MeshInstance3D
					if mi3.mesh == null:
						continue
					var local := Transform3D.IDENTITY
					var cur: Node = mi3
					while cur != null and cur != inst:
						local = (cur as Node3D).transform * local
						cur = cur.get_parent()
					for p in mi3.mesh.get_faces():
						all.append(local * p)
				inst.free()
				faces_of[scene] = all
			var src: PackedVector3Array = faces_of[scene]
			var faces := PackedVector3Array()
			faces.resize(src.size())
			for k in src.size():
				faces[k] = xf * src[k]
			var shape := ConcavePolygonShape3D.new()
			shape.backface_collision = true
			shape.set_faces(faces)
			var cs := CollisionShape3D.new()
			cs.shape = shape
			var body := StaticBody3D.new()
			body.add_to_group("sf_light_house")
			body.add_child(cs)
			_houses.add_child(body)
			n += 1
	if n > 0:
		print("  --real: din care %d din randurile din spate (CityFill)" % n)
	return n


static func _mean(a: Array[float]) -> float:
	if a.is_empty():
		return 0.0
	var s := 0.0
	for v in a:
		s += v
	return s / float(a.size())


## Randurile de case pe ambele laturi ale strazii date de indicii coapti `idx`.
func _build_rows(r: TrackRoute, idx: Array[int]) -> void:
	# lungimea cumulata si punctele
	var pts: Array[Vector3] = []
	var cum: Array[float] = [0.0]
	for i in idx:
		pts.append(r.baked[i])
	for k in range(1, pts.size()):
		cum.append(cum[k - 1] + Vector2(pts[k].x - pts[k - 1].x, pts[k].z - pts[k - 1].z).length())
	var total: float = cum[cum.size() - 1]
	var s := 0.0
	while s + HOUSE_W <= total:
		var mid := s + HOUSE_W * 0.5
		# strada transversala la fiecare CROSS_EVERY m (centrul ei la CROSS_EVERY - 12 de la capat)
		var ph := fposmod(mid + 12.0, CROSS_EVERY)
		if ph < CROSS_W * 0.5 + HOUSE_W * 0.5 or ph > CROSS_EVERY - CROSS_W * 0.5 - HOUSE_W * 0.5:
			s += HOUSE_W
			continue
		var a := _at(pts, cum, s)
		var c := _at(pts, cum, s + HOUSE_W)
		var m := _at(pts, cum, mid)
		var fwd := Vector2(c.x - a.x, c.z - a.z).normalized()
		var right := Vector3(-fwd.y, 0.0, fwd.x)
		var y_hi := maxf(a.y, c.y) + 0.15
		var y_lo := minf(a.y, c.y) - 3.0
		var y_top := y_hi + HOUSE_H
		for sd in [-1.0, 1.0]:
			var body := StaticBody3D.new()
			body.add_to_group("sf_light_house")
			var cs := CollisionShape3D.new()
			var bx := BoxShape3D.new()
			bx.size = Vector3(HOUSE_D, y_top - y_lo, HOUSE_W)   # X lateral, Z de-a lungul strazii
			cs.shape = bx
			body.add_child(cs)
			var center := Vector3(m.x, (y_top + y_lo) * 0.5, m.z) + right * float(sd) * (FACADE_OFF + HOUSE_D * 0.5)
			body.transform = Transform3D(Basis.looking_at(Vector3(fwd.x, 0.0, fwd.y), Vector3.UP), center)
			_houses.add_child(body)
		s += HOUSE_W


static func _at(pts: Array[Vector3], cum: Array[float], s: float) -> Vector3:
	for k in range(1, pts.size()):
		if cum[k] >= s:
			var t := (s - cum[k - 1]) / maxf(cum[k] - cum[k - 1], 1e-6)
			return pts[k - 1].lerp(pts[k], t)
	return pts[pts.size() - 1]
