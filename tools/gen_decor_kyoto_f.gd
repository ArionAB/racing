extends Node
## Generator de decor MANUAL pentru POI F — GRADINA CU IAZ (Track18, Kyoto,
## frac ~0.60-0.66): Pavilionul de Aur pe malul din SPATE al iazului, cu
## reflexia in apa, si daruma-otoshi pe malul de langa drum (hazardul exista,
## nu se muta).
##
## Nu e sonda: CALCULEAZA transformarile pe terenul real si scrie blocul de
## noduri in `tools/kyoto_decor/poi_f.part`, pe care `tools/gen_kyoto_route.py`
## il lipeste in Track18.tscn (blocul `=== DECOR MANUAL (POI-uri) ===`), deci decorul
## supravietuieste regenerarii pistei.
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorKyotoF.tscn
##   godot ... res://tools/GenDecorKyotoF.tscn -- --scan   (doar cotele, nu scrie)
##   python tools/gen_kyoto_route.py scenes/tracks/Track18.tscn
##
## Pista se incarca FARA blocul POI F (scena e citita si blocul vechi e scos
## inainte de masuratori): altfel corpurile pieselor de la rularea trecuta ar
## intra in raycast-urile de sol.
##
## ------------------------------------------------------------------------
## DECIZIILE (masurate pe pista reala, rularea --scan)
##
## - IAZUL real (rapa 3 cu apa la -1) e mult mai mare decat schita: ~100 x 100 m,
##   x 112..212, z 238..340. Punctul de garda al generatorului de traseu
##   (KINKAKU_XY = plan (150,-300) = Godot (150, 300)) cade IN MIJLOCUL apei.
##   Pavilionul sta pe MALUL DE VEST (malul din spate, privit de pe F, care
##   merge spre V), cu fatada pe apa si dealul gradinii (+24, Godot (60, 300))
##   direct in spatele lui: aurul pe verde si rosu, ca Kinkaku-ji pe muntele
##   Kinugasa. Distantele si azimuturile se tiparesc la rulare.
## - Reflexia: `PondReflection` (nod frate cu DecorManual, NU sub el), cu
##   shaderul care oglindeste si proiecteaza pe planul apei; +1 material.
## - Daruma: nimic in cercul de 13 m din jurul turnului (ciocanul si cadrul stau
##   in spatele lui, spre iaz) si nimic pe culoarul discului (de la turn, 22 m
##   spre interiorul curbei, ±(raza + marja)).
## - Malul iazului: pietre de gradina, movile de muschi, tufe karikomi si pini
##   niwaki pe linia apei gasita prin raze din centrul iazului; doua insulite cu
##   pin (Kyoko-chi are insule cu pini), departe de linia de vedere spre
##   pavilion, ca reflexia sa ramana curata.
## - Malul de langa drum (dreapta): gard shiba-gaki, felinare yukimi la apa.
## - Pasunea (stanga, interiorul curbei): calugari care matura frunze, gramezi
##   de frunze, tufe tunse, pietre de pas, felinare de piatra.

const TRACK_SCENE := "res://scenes/tracks/Track18.tscn"
const ZONE := "DecorManual/ZoneF_Gradina"
const PART := "res://tools/kyoto_decor/poi_f.part"
const WATER_Y := -1.0

const MODELS := {
	"kinkakuji": "structures", "yukimi_lantern": "props", "stone_lantern_a": "props",
	"stone_lantern_b": "props", "niwaki_pine": "plants", "karikomi_shrub_a": "plants",
	"karikomi_shrub_b": "plants", "garden_rock_a": "rocks", "garden_rock_b": "rocks",
	"garden_rock_c": "rocks", "stepping_stones": "rocks", "moss_mound": "rocks",
	"shiba_fence": "props", "leaf_pile": "props", "monk_sweeper": "props",
	"momiji_a": "plants", "momiji_b": "plants", "momiji_c": "plants", "ginkgo": "plants",
}

## Centrul aproximativ al iazului (Godot) si unde stau reperele.
const POND_C := Vector2(162.0, 290.0)
const PAVILION_Z := 288.0
## Punctul de pe drum spre care priveste fatada pavilionului (cadrul-erou).
const FACE_FRAC := 0.615
## Scara de jucarie a pavilionului (runda 2: la 1,0 avea ~40 px pe cadrul-erou).
const PAV_SCALE := 1.3
## Reflexia: cat din culoarea pavilionului trece in apa.
const REFLECT_STRENGTH := 0.8
## Insulitele (Godot x, z): la ~45-50 m de linia de vedere spre pavilion.
const ISLETS := [Vector2(150.0, 262.0), Vector2(186.0, 280.0)]

var _track: Track
var _space: PhysicsDirectSpaceState3D
var _terrain_rid := RID()
var _rng := RandomNumberGenerator.new()
var _nodes: Array[String] = []
var _used := {}
var _n := 0
var _scan := false
var _tower := Vector3.ZERO
var _outward := Vector3.ZERO
var _disc_len := 22.0
var _disc_half := 3.0
var _pav := Vector3.ZERO
var _pav_yaw := 0.0
var _placed: Array[Vector3] = [] # (x, z, raza) pentru suprapuneri


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--scan":
			_scan = true
	await get_tree().process_frame
	_track = _load_track_without_block()
	get_tree().root.add_child(_track)
	for k in 3:
		await get_tree().process_frame
	await get_tree().physics_frame
	_space = _track.get_world_3d().direct_space_state
	_rng.seed = 31026
	_daruma()
	_pavilion()
	_report_pavilion()
	if _scan:
		get_tree().quit(0)
		return
	_pavilion_garden()
	_islets()
	_back_trees()
	_shore()
	_near_bank()
	_east_bank()
	_pasture()
	_write()
	get_tree().quit(0)


## Scena pistei FARA blocul POI F (corpurile rularii trecute ar fi in raycast).
func _load_track_without_block() -> Track:
	var ps := load(TRACK_SCENE) as PackedScene
	var t := ps.instantiate() as Track
	var dm := t.get_node_or_null(ZONE)
	if dm != null:
		dm.get_parent().remove_child(dm)
		dm.free()
	var rf := t.get_node_or_null("ReflexiePavilion")
	if rf != null:
		t.remove_child(rf)
		rf.free()
	return t


# ------------------------------------------------------------------ repere

func _daruma() -> void:
	var hz: DarumaOtoshiHazard = _track.get_node("Hazarduri/DarumaOtoshi") as DarumaOtoshiHazard
	_outward = hz.outward()
	_tower = hz.global_position + _outward * absf(hz.tower_center_x())
	_disc_len = hz.slide_distance
	_disc_half = hz.disc_diameter * 0.5 + hz.hit_margin_along + 1.0
	print("; daruma: turn (%.1f, %.1f, %.1f), exterior (%.2f, %.2f), disc %.0f m spre interior" % [
		_tower.x, _tower.y, _tower.z, _outward.x, _outward.z, _disc_len])


## Interzis: cercul turnului (ciocan + cadru in spate) si culoarul discului.
func _forbidden(p: Vector3, r: float) -> bool:
	var d := Vector2(p.x - _tower.x, p.z - _tower.z)
	if d.length() < 13.0 + r:
		return true
	var o := Vector2(_outward.x, _outward.z)
	var along := Vector2(-o.y, o.x)
	var inward := -d.dot(o)          # metri de la turn spre interior
	var lat := absf(d.dot(along))
	if inward > -4.0 and inward < _disc_len + 6.0 and lat < _disc_half + r:
		return true
	return false


## Pe carosabil (cu marja) pe orice banda?
func _on_road(p: Vector3, margin: float) -> bool:
	var i := _track.closest_index_global(p)
	var rc := _track.road_coords(i, p)
	return absf(rc.y) < _track.width_at_index(i) + margin


func _overlaps(p: Vector3, r: float) -> bool:
	for q in _placed:
		if Vector2(p.x - q.x, p.z - q.y).length() < r + q.z:
			return true
	return false


func _pavilion() -> void:
	# Malul de vest la z = PAVILION_Z: mergi de la centrul iazului spre V pana
	# iese terenul din apa.
	var x := POND_C.x
	while x > 60.0 and _sol_real(x, PAVILION_Z) < WATER_Y + 0.05:
		x -= 0.5
	var shore_x := x
	var fi := int(FACE_FRAC * float(_track.baked.size()))
	var face_to: Vector3 = _track.baked[fi]
	# Centrul: fatada (adancimea 11,4 / 2) iese ~1 m peste apa.
	var dir := Vector2(face_to.x - shore_x, face_to.z - PAVILION_Z).normalized()
	var c := Vector2(shore_x, PAVILION_Z) - dir * (5.7 * PAV_SCALE - 1.2)
	var y := _sol_real(c.x, c.y)
	_pav = Vector3(c.x, maxf(y, WATER_Y + 0.1) - 0.05, c.y)
	# -Z local spre camera: (-sin, -cos) = dir.
	_pav_yaw = atan2(-dir.x, -dir.y)
	print("; pavilion: mal V la x %.1f, centru (%.1f, %.2f, %.1f), yaw %.1f grade" % [
		shore_x, _pav.x, _pav.y, _pav.z, rad_to_deg(_pav_yaw)])


## Cele patru axe (memoria reperul-se-vede-pe-patru-axe): distanta, verticala
## fata de plafonul camerei, azimut fata de directia drumului, si ocluzia (raza
## camera -> mijlocul pavilionului loveste terenul?).
func _report_pavilion() -> void:
	var n := _track.baked.size()
	var top := _pav.y + 13.7 * PAV_SCALE
	print("; frac   dist   azimut  plafon   varf   ocluzie")
	var f := 0.59
	while f <= 0.665:
		var i := int(f * n) % n
		var p: Vector3 = _track.baked[i]
		var t := (_track.point_at(i + 6) - p)
		t.y = 0.0
		t = t.normalized()
		var cam := p - t * 12.5 + Vector3.UP * 10.0
		var to := _pav - p
		to.y = 0.0
		var dist := to.length()
		var az := rad_to_deg(atan2(t.cross(to.normalized()).y, t.dot(to.normalized())))
		var ceil_y := p.y + 10.0 + 0.092 * dist
		var q := PhysicsRayQueryParameters3D.create(cam, _pav + Vector3.UP * 7.0)
		q.collide_with_areas = false
		var hit := _space.intersect_ray(q)
		var occ := "-" if hit.is_empty() else "%.0f m" % cam.distance_to(hit["position"])
		# Inaltimea pe ecran (1080 px verticali, fov 68), de la camera.
		var dcam := Vector2(_pav.x - cam.x, _pav.z - cam.z).length()
		var px := 1080.0 * 0.5 / tan(deg_to_rad(34.0)) * (13.7 * PAV_SCALE) / dcam
		print(";  %.3f  %5.1f  %+6.1f  %6.1f  %5.1f   %-6s %4.0f px" % [f, dist, -az, ceil_y, top, occ, px])
		f += 0.005


# ------------------------------------------------------------------ piese

func _pavilion_garden() -> void:
	_raw("kinkakuji", "fPavilion", _pav, _pav_yaw, PAV_SCALE, "")
	var fwd := Vector3(-sin(_pav_yaw), 0.0, -cos(_pav_yaw))
	var right := Vector3(fwd.z, 0.0, -fwd.x)
	# Doi pini mici la baza (brief kit 1.4: „nu fac parte din GLB").
	# Runda 3 (verdict: „pavilionul sa iasa din verde"): pini niwaki MARI (1,4-1,6)
	# pe flancuri si in spate, tufe karikomi pe mal; nimic in fata fatadei (fwd > 6)
	# si nimic intre flancuri pe fata, ca reflexia sa ramana curata.
	# (inainte, dreapta, scara); dreapta se oglindeste pe flancuri.
	for it in [[2.0, 11.5, 1.5], [-3.5, 13.5, 1.6], [5.0, 13.0, 1.4]]:
		for s in [-1.0, 1.0]:
			_pav_pine(_pav + fwd * float(it[0]) + right * (float(it[1]) * s), fwd, float(it[2]))
	for it in [[-11.0, -7.5, 1.5], [-12.5, 0.0, 1.6], [-11.0, 7.5, 1.5], [-17.5, -4.0, 1.45], [-17.5, 4.5, 1.55]]:
		_pav_pine(_pav + fwd * float(it[0]) + right * float(it[1]), fwd, float(it[2]))
	for it in [[4.5, 8.8, 1.4], [3.0, 16.0, 1.3], [-6.5, 10.5, 1.3], [-1.0, 17.0, 1.35]]:
		for s in [-1.0, 1.0]:
			var q: Vector3 = _pav + fwd * float(it[0]) + right * (float(it[1]) * s)
			if _sol_real(q.x, q.z) >= WATER_Y + 0.1:
				var m := "karikomi_shrub_a" if s > 0.0 else "karikomi_shrub_b"
				_ground_piece(m, "fPavTufa", q, _rng.randf() * TAU, float(it[2]))
	# Pietre de mal la piciorul fatadei si doua felinare yukimi pe capete.
	for k in 5:
		var o := -8.0 + 4.0 * k + _rng.randf_range(-0.8, 0.8)
		var p: Vector3 = _pav + fwd * (5.7 * PAV_SCALE + 1.6) + right * o
		_rock(p, 1.1 + _rng.randf() * 0.4, "fPavPiatra")
	for s in [-1.0, 1.0]:
		var p: Vector3 = _pav + fwd * 6.5 + right * (15.0 * s)
		_ground_piece("yukimi_lantern", "fPavYukimi", p, _pav_yaw, 1.15)
	_placed.append(Vector3(_pav.x, _pav.z, 8.5))
	# Reflexia: nod frate cu DecorManual, aceeasi transformare.
	_n += 1
	var b := Basis.from_euler(Vector3(0.0, _pav_yaw, 0.0)).scaled(Vector3.ONE * PAV_SCALE)
	_nodes.append('[node name="ReflexiePavilion" type="Node3D" parent="."]')
	_nodes.append("transform = %s" % _xf(b, _pav))
	_nodes.append('script = ExtResource("poif_pond_reflection")')
	_nodes.append('model = ExtResource("poif_kinkakuji")')
	_nodes.append("water_y = %.2f" % WATER_Y)
	_nodes.append("strength = %.2f" % REFLECT_STRENGTH)
	_nodes.append("")


func _islets() -> void:
	for c: Vector2 in ISLETS:
		var g := _sol_real(c.x, c.y)
		if g > WATER_Y - 0.3:
			print("; insulita (%.0f, %.0f) nu e in apa (sol %.2f), sarita" % [c.x, c.y, g])
			continue
		var p: Vector3 = Vector3(c.x, WATER_Y - 0.45, c.y)
		_raw("moss_mound", "fInsulaMovila", p, _rng.randf() * TAU, 1.7, "")
		_raw("garden_rock_a", "fInsulaPiatra", p + Vector3(2.2, 0.05, -1.0), _rng.randf() * TAU, 1.3, "")
		_raw("garden_rock_c", "fInsulaPiatra", p + Vector3(-2.0, 0.0, 1.4), _rng.randf() * TAU, 1.1, "")
		_raw("niwaki_pine", "fInsulaPin", p + Vector3(0.0, 0.5, 0.0), _rng.randf() * TAU, 0.8, "")
		_placed.append(Vector3(c.x, c.y, 5.0))


## Linia apei: raze din centrul iazului, primul punct de pe uscat.
func _shore_points() -> Array[Vector3]:
	var out: Array[Vector3] = []
	var a := 0.0
	while a < 360.0:
		var d := Vector2(cos(deg_to_rad(a)), sin(deg_to_rad(a)))
		var r := 4.0
		var found := false
		while r < 110.0:
			var x := POND_C.x + d.x * r
			var z := POND_C.y + d.y * r
			if _sol_real(x, z) >= WATER_Y + 0.05:
				found = true
				break
			r += 0.5
		if found:
			out.append(Vector3(POND_C.x + d.x * r, a, POND_C.y + d.y * r))
		a += 3.0
	return out


## Linia vederii spre pavilion: de pe cadrul-erou (frac 0,600-0,628, camera la
## 12,5 m in spate si 10 m sus) pana la pavilion. Ce e inalt nu sta pe ea.
func _blocks_view(p: Vector3, r: float) -> bool:
	var n := _track.baked.size()
	var f := 0.600
	while f <= 0.628:
		var i := int(f * float(n)) % n
		var a: Vector3 = _track.baked[i]
		var t := _track.point_at(i + 6) - a
		t.y = 0.0
		t = t.normalized()
		var cam := a - t * 12.5
		var q := Geometry2D.get_closest_point_to_segment(Vector2(p.x, p.z),
			Vector2(cam.x, cam.z), Vector2(_pav.x, _pav.z))
		# Doar INAINTEA pavilionului (in spatele lui, pinii il ancoreaza).
		if q.distance_to(Vector2(_pav.x, _pav.z)) > 9.0 and q.distance_to(Vector2(p.x, p.z)) < 9.0 + r:
			return true
		f += 0.004
	return false


## Malul iazului. Runda 2 (verdict: „pietris alb marunt"): STANCI de gradina in
## grupuri de 2-3 cu una mare (scara 1,6-2,5), muschi la baza, un grup la ~3
## puncte de mal; pe malul de vest si de nord (in jurul si in spatele
## pavilionului) pini niwaki DESI si tufe karikomi, ca pavilionul sa iasa din
## verde, dar nimic inalt pe linia de vedere.
func _shore() -> void:
	var pts := _shore_points()
	print("; linia apei: %d puncte" % pts.size())
	var k := 0
	for s in pts:
		k += 1
		var p: Vector3 = Vector3(s.x, 0.0, s.z)
		var out := Vector3(p.x - POND_C.x, 0.0, p.z - POND_C.y).normalized()
		var tang := Vector3(-out.z, 0.0, out.x)
		if _on_road(p, 1.5) or _forbidden(p, 2.0):
			continue
		var near_pav := Vector2(p.x - _pav.x, p.z - _pav.z).length() < 13.0
		if k % 3 == 0 and not near_pav:
			var c := p - out * 0.6
			_rock(c, 1.6 + _rng.randf() * 0.9, "fMalStanca")
			_rock(c + tang * (1.9 + _rng.randf() * 0.6) + out * 0.5, 1.1 + _rng.randf() * 0.4, "fMalStanca")
			if _rng.randf() < 0.6:
				_rock(c - tang * (1.7 + _rng.randf() * 0.5) + out * 0.3, 0.9 + _rng.randf() * 0.4, "fMalStanca")
			_ground_piece("moss_mound", "fMalMovila", c + out * 3.4 + tang * 1.2, _rng.randf() * TAU,
				1.0 + _rng.randf() * 0.4)
		var a: float = s.y
		var back := a > 140.0 and a < 335.0 # malul de vest si de nord
		if back:
			# Doua randuri: tufe la 3-4 m, pini la 6-9 m si la 11-14 m.
			var sh := p + out * (3.0 + _rng.randf())
			if not _forbidden(sh, 1.5) and not _on_road(sh, 2.0) and Vector2(sh.x - _pav.x, sh.z - _pav.z).length() > 9.0:
				var m := "karikomi_shrub_a" if k % 2 == 0 else "karikomi_shrub_b"
				_ground_piece(m, "fMalTufa", sh, _rng.randf() * TAU, 1.2 + _rng.randf() * 0.5)
			for d in [7.0, 12.5]:
				var pn: Vector3 = p + out * (float(d) + _rng.randf() * 2.0) + tang * _rng.randf_range(-1.5, 1.5)
				if not _on_road(pn, 4.0) and not _forbidden(pn, 3.0) and not _blocks_view(pn, 3.0):
					_tree("niwaki_pine", "fMalPin", pn, 0.95 + _rng.randf() * 0.35)
		else:
			var inland := p + out * (3.0 + _rng.randf() * 1.5)
			if k % 5 == 1 and not _on_road(inland, 2.0) and not _forbidden(inland, 1.5):
				var m2 := "karikomi_shrub_a" if _rng.randf() < 0.5 else "karikomi_shrub_b"
				_ground_piece(m2, "fMalTufa", inland, _rng.randf() * TAU, 1.0 + _rng.randf() * 0.4)
			var pine := p + out * (6.5 + _rng.randf() * 2.0)
			if k % 7 == 3 and not _on_road(pine, 4.0) and not _forbidden(pine, 3.0) and not _blocks_view(pine, 3.0):
				_tree("niwaki_pine", "fMalPin", pine, 0.9 + _rng.randf() * 0.25)


## Malul de langa drum (dreapta, intre asfalt si apa): gardul shiba-gaki si
## felinare; pe frac 0.612-0.656, fara cercul turnului.
func _near_bank() -> void:
	var n := _track.baked.size()
	var i := int(0.612 * float(n))
	var i1 := int(0.656 * float(n))
	var acc := 3.0
	while i < i1:
		var a: Vector3 = _track.baked[i]
		var b: Vector3 = _track.baked[i + 1]
		acc += Vector2(b.x - a.x, b.z - a.z).length()
		if acc >= 3.0:
			acc = 0.0
			var t := (b - a)
			t.y = 0.0
			t = t.normalized()
			var side := _track.routes[0].side_at(i)
			side.y = 0.0
			side = side.normalized()
			var hw := _track.width_at_index(i)
			var p: Vector3 = a + side * (hw + 1.4)
			var g := _sol_real(p.x, p.z)
			if g >= WATER_Y + 0.15 and not _forbidden(p, 2.0):
				_raw("shiba_fence", "fGard", Vector3(p.x, g - 0.05, p.z), atan2(t.x, t.z), 1.0, "")
		i += 1
	# Felinare de piatra pe malul de langa drum, la apa.
	for f in [0.618, 0.645, 0.653]:
		var p: Vector3 = _lat(f, 8.6)
		if not _forbidden(p, 1.5):
			_ground_piece("stone_lantern_a" if f > 0.64 else "stone_lantern_b", "fMalFelinar",
				p, _rng.randf_range(-0.3, 0.3) + _yaw_road(f), 1.0)


## Malul de est (dreapta, frac 0.612-0.630): fasia de iarba dintre drum si apa,
## pe care trece linia de vedere spre pavilion. Doar piese JOASE (tufe tunse,
## movile, felinare, pietre de pas spre apa); un singur pin, lateral.
func _east_bank() -> void:
	var f := 0.612
	var k := 0
	while f < 0.6305:
		var lat := 9.5
		while lat < 30.0:
			var p: Vector3 = _lat(f + _rng.randf_range(-0.0008, 0.0008), lat + _rng.randf_range(-1.0, 1.0))
			k += 1
			var g := _sol_real(p.x, p.z)
			if g >= WATER_Y + 0.2 and not _forbidden(p, 2.0) and not _on_road(p, 2.5):
				match k % 5:
					0, 2:
						var m := "karikomi_shrub_a" if k % 2 == 0 else "karikomi_shrub_b"
						_ground_piece(m, "fEstTufa", p, _rng.randf() * TAU, 1.2 + _rng.randf() * 0.5)
					1:
						_ground_piece("moss_mound", "fEstMovila", p, _rng.randf() * TAU, 1.2 + _rng.randf() * 0.4)
					3:
						_rock(p, 1.8 + _rng.randf() * 0.6, "fEstPiatra")
			lat += 5.5
		f += 0.0028
	for it in [[0.615, 15.0, "stone_lantern_b"], [0.626, 12.0, "yukimi_lantern"]]:
		var p: Vector3 = _lat(it[0], it[1])
		if not _forbidden(p, 1.5):
			_ground_piece(it[2], "fEstFelinar", p, _yaw_road(it[0]), 1.1)
	_tree("niwaki_pine", "fEstPin", _lat(0.6165, 13.5), 1.05)


## Pasunea din interiorul curbei (stanga).
func _pasture() -> void:
	# Tufe tunse in grupuri de cate trei, pe marginea drumului.
	for f in [0.600, 0.607, 0.614, 0.622, 0.643, 0.650, 0.657]:
		for j in 3:
			var p: Vector3 = _lat(f + j * 0.0012, -(8.2 + _rng.randf() * 1.2))
			var m := "karikomi_shrub_a" if (j + int(f * 1000.0)) % 2 == 0 else "karikomi_shrub_b"
			if not _forbidden(p, 1.2) and not _on_road(p, 1.5):
				_ground_piece(m, "fPasuneTufa", p, _rng.randf() * TAU, 1.1 + _rng.randf() * 0.4)
	# Doi calugari care matura frunzele spre gramezi.
	for it in [[0.647, -12.5], [0.618, -13.0]]:
		var p: Vector3 = _lat(it[0], it[1])
		if _forbidden(p, 2.0):
			continue
		_ground_piece("monk_sweeper", "fCalugar", p, _yaw_road(it[0]) + PI * 0.5 + 0.3, 1.0)
		for k in 3:
			var q: Vector3 = p + Vector3(_rng.randf_range(-3.5, 3.5), 0.0, _rng.randf_range(-3.5, 3.5))
			if q.distance_to(p) > 1.6 and not _forbidden(q, 1.2):
				_ground_piece("leaf_pile", "fFrunze", q, _rng.randf() * TAU, 1.0 + _rng.randf() * 0.5)
	# Carare de pietre de pas, perpendiculara pe drum.
	for k in 4:
		var p: Vector3 = _lat(0.640, -(8.0 + 2.9 * k))
		if not _forbidden(p, 1.5):
			_ground_piece("stepping_stones", "fPasPietre", p, _yaw_road(0.640) + PI * 0.5 + _rng.randf_range(-0.2, 0.2), 1.0)
	# Felinare de piatra si un grup de pietre cu movila.
	for it in [[0.642, -10.0, "stone_lantern_a"], [0.624, -9.6, "stone_lantern_b"],
			[0.606, -11.0, "stone_lantern_a"]]:
		var p: Vector3 = _lat(it[0], it[1])
		if not _forbidden(p, 1.5):
			_ground_piece(it[2], "fPasuneFelinar", p, _yaw_road(it[0]) + PI, 1.0)
	var g: Vector3 = _lat(0.611, -16.0)
	if not _forbidden(g, 4.0):
		_ground_piece("moss_mound", "fPasuneMovila", g, 0.4, 1.4)
		_rock(g + Vector3(2.4, 0.0, -0.8), 1.4, "fPasunePiatra")
		_rock(g + Vector3(-1.8, 0.0, 1.5), 1.0, "fPasunePiatra")


## Cativa artari si ginkgo pe malurile de N si E (fundal rosu-auriu dincolo de
## apa, vazut de pe drum).
func _back_trees() -> void:
	var pts := _shore_points()
	var k := 0
	for s in pts:
		var a := s.y
		# malul de nord (unghiuri 200..320 in conventia (cos, sin) pe (x, z)).
		if a < 200.0 or a > 330.0:
			continue
		k += 1
		if k % 3 != 0:
			continue
		var p: Vector3 = Vector3(s.x, 0.0, s.z)
		var out := Vector3(p.x - POND_C.x, 0.0, p.z - POND_C.y).normalized()
		var q: Vector3 = p + out * (9.0 + _rng.randf() * 5.0)
		if _on_road(q, 6.0) or _forbidden(q, 4.0) or _blocks_view(q, 4.0):
			continue
		var m: String = ["momiji_a", "momiji_b", "momiji_c", "ginkgo"][k / 3 % 4]
		_tree(m, "fMalArbore", q, 0.95 + _rng.randf() * 0.25)


# ------------------------------------------------------------------ ajutoare

func _lat(f: float, lat: float) -> Vector3:
	var n := _track.baked.size()
	var i := int(f * float(n)) % n
	var a: Vector3 = _track.baked[i]
	var side := _track.routes[0].side_at(i)
	side.y = 0.0
	side = side.normalized()
	return a + side * lat


func _yaw_road(f: float) -> float:
	var n := _track.baked.size()
	var i := int(f * float(n)) % n
	var t := _track.point_at(i + 1) - _track.point_at(i)
	return atan2(t.x, t.z)


func _rock(p: Vector3, scl: float, base: String) -> void:
	if _on_road(p, 2.3) or _forbidden(p, 1.0):
		return
	var m: String = ["garden_rock_a", "garden_rock_b", "garden_rock_c"][_rng.randi() % 3]
	_ground_piece(m, base, p, _rng.randf() * TAU, scl, 0.18 * scl, 0.45)


func _tree(m: String, base: String, p: Vector3, scl: float) -> bool:
	if _overlaps(p, 2.5):
		return false
	var g := _sol_real(p.x, p.z)
	if g < WATER_Y + 0.1:
		return false
	_raw(m, base, Vector3(p.x, g - 0.1, p.z), _rng.randf() * TAU, scl, "")
	_placed.append(Vector3(p.x, p.z, 2.5))
	return true


## Pin langa pavilion: daca locul cerut e in apa sau ocupat, se da inapoi (spre
## spatele pavilionului) cu cate 3 m, de cel mult 4 ori.
func _pav_pine(p: Vector3, fwd: Vector3, scl: float) -> void:
	for k in 5:
		if _tree("niwaki_pine", "fPavPin", p - fwd * (3.0 * k), scl):
			return


func _ground_piece(m: String, base: String, p: Vector3, yaw: float, scl: float, sink: float = 0.05, rf: float = 0.9) -> void:
	if _overlaps(p, rf * scl):
		return
	var g := _sol_real(p.x, p.z)
	# Doar pietrele si movilele pot sta in apa (mal, insulite); restul nu.
	if g < WATER_Y + 0.1 and not (m.begins_with("garden_rock") or m == "moss_mound"):
		return
	var y := g - sink
	# La apa: piesa sta pe fundul de mal, dar nu mai jos de 0,45 m sub apa.
	if g < WATER_Y:
		y = maxf(g, WATER_Y - 0.45) - sink
	_raw(m, base, Vector3(p.x, y, p.z), yaw, scl, "")
	_placed.append(Vector3(p.x, p.z, rf * scl))


func _xf(b: Basis, pos: Vector3) -> String:
	# RANDURILE bazei, nu coloanele (memoria tscn-transform-e-pe-randuri).
	return "Transform3D(%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)" % [
		b.x.x, b.y.x, b.z.x, b.x.y, b.y.y, b.z.y, b.x.z, b.y.z, b.z.z, pos.x, pos.y, pos.z]


func _raw(model: String, base: String, pos: Vector3, yaw: float, scl: float, mode: String) -> void:
	_used[model] = true
	var b := Basis.from_euler(Vector3(0.0, yaw, 0.0)).scaled(Vector3(scl, scl, scl))
	_n += 1
	_nodes.append('[node name="%s%d" parent="%s" instance=ExtResource("poif_%s")]' % [base, _n, ZONE, model])
	_nodes.append("transform = %s" % _xf(b, pos))
	if mode != "":
		_nodes.append('metadata/coliziune = "%s"' % mode)
	_nodes.append("")


func _write() -> void:
	var ext: Array[String] = []
	ext.append('[ext_resource type="Script" path="res://scenes/props/pond_reflection.gd" id="poif_pond_reflection"]')
	_used["kinkakuji"] = true
	var stems := _used.keys()
	stems.sort()
	for s in stems:
		ext.append('[ext_resource type="PackedScene" path="res://assets/models/kyoto/%s/%s.glb" id="poif_%s"]'
			% [MODELS[s], s, s])
	var lines: Array[String] = []
	lines.append("; POI F (gradina cu iaz) — generat de tools/gen_decor_kyoto_f.gd, NU edita de mana.")
	lines.append(";;EXT")
	lines.append_array(ext)
	lines.append(";;NODES")
	lines.append('[node name="ZoneF_Gradina" type="Node3D" parent="DecorManual"]')
	lines.append("")
	lines.append_array(_nodes)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tools/kyoto_decor"))
	var fa := FileAccess.open(PART, FileAccess.WRITE)
	for l in lines:
		fa.store_line(l)
	fa.close()
	print("; asezate %d piese, %d modele -> %s" % [_n, stems.size(), PART])


## Cota SOLULUI din coliziunea reala a panzei de teren (TerrainBody).
func _sol_real(x: float, z: float) -> float:
	if _terrain_rid == RID():
		for c in _track.get_children():
			if str(c.name) == "TerrainBody":
				_terrain_rid = (c as StaticBody3D).get_rid()
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, 200.0, z), Vector3(x, -200.0, z))
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
