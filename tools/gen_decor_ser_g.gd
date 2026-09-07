extends Node
## Generator de decor MANUAL pentru POI G — FUNDUL CRATERULUI (Track14,
## Serengeti, frac 0.715-0.853). Nu e sonda: CALCULEAZA transformarile care se
## lipesc in Track14.tscn sub `DecorManual/ZoneG_FundulCraterului`, cu cotele
## luate din coliziunea reala a terenului (raza pe `TerrainBody`), nu din
## `_terrain_mesh_y` (memoria `terrain-mesh-y-extrapoleaza`).
##
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorSerG.tscn -- --dump
##   godot --headless --fixed-fps 60 --path . res://tools/GenDecorSerG.tscn
##
## `--dump` tipareste geometria intervalului (punct pe ax, latura, semilatime,
## cota terenului si amestecul de laguna la cateva degajari, directia umbrei)
## — masuratoarea pe care s-a construit compozitia de mai jos. Fara `--dump`
## scrie nodurile.

const TRACK := "res://scenes/tracks/Track14.tscn"
const ZONE := "DecorManual/ZoneG_FundulCraterului"

var _track: Track
var _terrain_rid: RID = RID()
var _sus_y := 0.0
var _out: Array[String] = []
var _n := 0
var _warn := 0
var _rng := RandomNumberGenerator.new()
var _sea_y := -1e9


func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	var hi := -INF
	for bp in _track.baked:
		hi = maxf(hi, bp.y)
	_sus_y = hi + 120.0
	_sea_y = _track._sampler.mean_road_y() + _track.sea_level_offset
	_rng.seed = 140701
	if "--dump" in OS.get_cmdline_user_args():
		_dump()
	else:
		_compose()
		print("")
		for line in _out:
			print(line)
		print("; asezate %d piese, %d avertismente" % [_n, _warn])
	get_tree().quit(0)


# ------------------------------------------------------------------ masuratori

func _dump() -> void:
	var n := _track.baked.size()
	var sun: DirectionalLight3D = null
	for c in _track.get_children():
		if c is DirectionalLight3D:
			sun = c
	if sun != null:
		var d := -sun.global_transform.basis.z
		print("; soare: lumina merge spre (%.3f, %.3f, %.3f); umbra pe XZ spre (%.3f, %.3f)"
			% [d.x, d.y, d.z, d.x, d.z])
	print("; sea_y = %.2f (mean_road_y %.2f + offset %.2f)" % [_sea_y,
		_track._sampler.mean_road_y(), _track.sea_level_offset])
	print("; frac    idx      ax(x,y,z)           side(x,z)   hw    dist_lac_ax | teren la -side: 3 8 15 25 | +side: 3 8 15 25 | lag +side 8 15 25")
	var f := 0.700
	while f <= 0.870 + 1e-6:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var hw := _track.width_at_index(i)
		var lag_d := _lagoon_signed_dist(p.x, p.z)
		var cols := ""
		for sgn: float in [-1.0, 1.0]:
			for off: float in [3.0, 8.0, 15.0, 25.0]:
				var q: Vector3 = p + s * sgn * (hw + off)
				cols += " %6.2f" % (_sol_real(q.x, q.z) - p.y)
			cols += " |"
		for off: float in [8.0, 15.0, 25.0]:
			var q: Vector3 = p + s * (hw + off)
			cols += " %.2f" % _track._sampler._lagoon_mix(q.x, q.z)
		print("; %.3f %5d (%7.1f,%6.2f,%7.1f) (%5.2f,%5.2f) %4.1f %7.1f |%s" % [
			f, i, p.x, p.y, p.z, s.x, s.z, hw, lag_d, cols])
		f += 0.005
	# Punctele candidate din brief pentru elefanti + vartej: fractia lor reala.
	for c: Vector3 in [Vector3(-20, 0, -16), Vector3(35, 0, -30), Vector3(10, 0, -52),
			Vector3(-55, 2, 40)]:
		var i := _track._closest_baked_index(c)
		var p := _track.baked[i]
		print("; candidat (%.0f, %.0f): frac %.4f, ax la (%.1f, %.2f, %.1f), la %.1f m de ax, lag %.2f, sol %.2f"
			% [c.x, c.z, _track.frac_at(i), p.x, p.y, p.z,
			Vector2(c.x - p.x, c.z - p.z).length(),
			_track._sampler._lagoon_mix(c.x, c.z), _sol_real(c.x, c.z)])


## Distanta cu semn de la un punct la conturul lagunei (negativ = in lac).
func _lagoon_signed_dist(x: float, z: float) -> float:
	var poly: PackedVector2Array = _track._lagoon_poly()
	if poly.size() < 3:
		return 1e9
	var p := Vector2(x, z)
	var d_sq := INF
	for i in poly.size():
		var q := Geometry2D.get_closest_point_to_segment(p, poly[i], poly[(i + 1) % poly.size()])
		d_sq = minf(d_sq, p.distance_squared_to(q))
	var sd := sqrt(d_sq)
	if Geometry2D.is_point_in_polygon(p, poly):
		sd = -sd
	return sd


## Cota SOLULUI din coliziunea reala a panzei de teren (raza in jos, doar pe
## `TerrainBody`); cade pe camp doar daca nu exista panza acolo.
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
	print("; ATENTIE fara sol la (%.1f, %.1f): se cade pe camp" % [x, z])
	return _track._sampler.ground_y(x, z)


# ------------------------------------------------------------------ compozitia

func _compose() -> void:
	# Compozitia POI G. Fiecare piesa se aseaza fata de AXA soselei la o
	# fractie masurata (`_at`), la o distanta laterala de MARGINEA benzii si cu
	# semnul benzii: +1 = DREAPTA soferului (verificat: side_at ~ forward x UP
	# la 0.77), unde e lacul; -1 = STANGA, unde sta padurea Lerai.
	_out.append("[node name=\"ZoneG_FundulCraterului\" type=\"Node3D\" parent=\"DecorManual\"]")
	_approach()
	_lake_shore()
	_lerai()
	_balloon_camp()
	_to_gap()


## 0.715-0.752: intrarea pe crusta. Silueta se construieste din arbori de
## savana la 8-27 m pe STANGA (terenul urca acolo pana la +8 m la 0.735, deci
## coroanele se etajeaza) si musuroaie/euphorbia aproape de banda.
func _approach() -> void:
	var trees := [
		[0.716, -1.0, 13.0, "s_acacia_umbrella_a", 1.15],
		[0.719, -1.0, 24.0, "s_acacia_umbrella_c", 1.30],
		[0.723, -1.0, 10.0, "s_fever_tree", 1.00],
		[0.727, -1.0, 19.0, "s_acacia_umbrella_b", 1.20],
		[0.731, -1.0, 12.0, "s_acacia_umbrella_a", 0.95],
		[0.734, -1.0, 27.0, "s_baobab", 0.85],
		[0.738, -1.0, 9.0, "s_dead_tree", 1.10],
		[0.742, -1.0, 16.0, "s_acacia_umbrella_c", 1.05],
		[0.746, -1.0, 11.0, "s_fever_tree", 0.90],
		[0.750, -1.0, 21.0, "s_acacia_umbrella_a", 1.25],
		[0.7205, -1.0, 17.0, "s_acacia_umbrella_b", 1.10],
		[0.726, 1.0, 32.0, "s_acacia_umbrella_a", 1.20],
		[0.733, 1.0, 12.0, "s_dead_tree", 1.00],
		[0.741, 1.0, 18.0, "s_acacia_umbrella_c", 0.95],
	]
	for t: Array in trees:
		_put(t[3] as String, t[0] as float, t[1] as float, t[2] as float,
			t[4] as float, _rng.randf() * TAU)
	var small := [
		[0.717, 1.0, 7.0, "s_termite_mound_a"],
		[0.724, -1.0, 6.5, "s_euphorbia"],
		[0.728, 1.0, 8.0, "s_termite_mound_b"],
		[0.736, -1.0, 7.5, "s_termite_mound_a"],
		[0.744, 1.0, 6.0, "s_euphorbia"],
		[0.748, -1.0, 8.5, "s_termite_mound_b"],
	]
	for t: Array in small:
		_put(t[3] as String, t[0] as float, t[1] as float, t[2] as float,
			_rng.randf_range(0.9, 1.3), _rng.randf() * TAU)


## 0.752-0.785, DREAPTA: lacul de soda. Malul e la ~35 m de ax pe 0.760-0.775
## (masurat: amestecul de laguna la 25 m de margine urca la 0.21 la 0.770).
## Flamingii vin in TREI stoluri care isi cauta singure linia apei: unul
## aproape (se citesc individual), doua pe malul din departare, ca banda roz.
## Hoitul cu vulturi sta la 9 m de banda, ca in referinta.
func _lake_shore() -> void:
	_flock(0.762, 1.0, 24.0, 34.0, 150, 0.30)
	_flock(0.772, 1.0, 30.0, 40.0, 170, 0.22)
	_flock(0.752, 1.0, 26.0, 30.0, 110, 0.35)
	# Elefantii de pe crusta (referinta: trei siluete gri pe alb). DOI stau ca
	# decor, mergand spre lac; al treilea si al patrulea TRAVERSEAZA drumul
	# (HazardMarker G_Elefant1/2 in Track14.tscn). Trei hazarduri pe acelasi
	# tronson insemnau drum ocupat permanent (ProbeRace: 26% lent, doua
	# blocaje), asa ca doar doi sunt mobili.
	_put("s_elephant", 0.759, 1.0, 21.0, 1.05, 1.9)
	_put("s_elephant", 0.7635, 1.0, 27.0, 1.15, 2.0)
	_put("s_elephant", 0.7565, 1.0, 33.0, 0.95, 1.7)
	_put("s_carcass_vultures", 0.757, 1.0, 9.0, 1.15, 2.1)
	_put("s_carcass_vultures", 0.784, -1.0, 11.0, 1.0, 0.6)
	# Bolovani de granit izolati pe crusta, ca in referinta (petele gri intre
	# lac si drum): sparg albul continuu si primesc umbra lunga.
	var rocks := [
		[0.755, 1.0, 16.0, "s_kopje_boulder_a", 0.85],
		[0.766, 1.0, 13.0, "s_kopje_boulder_c", 0.70],
		[0.777, 1.0, 18.0, "s_kopje_boulder_b", 0.95],
		[0.760, -1.0, 14.0, "s_kopje_boulder_b", 0.80],
		[0.771, -1.0, 10.0, "s_kopje_boulder_a", 0.65],
	]
	for r: Array in rocks:
		_put(r[3] as String, r[0] as float, r[1] as float, r[2] as float,
			r[4] as float, _rng.randf() * TAU)


## 0.756-0.800, STANGA: padurea Lerai — fever_tree in banda deasa, coroanele
## se ating (referinta: perete verde-galben pe o latura). Trunchiul opreste,
## coroana nu (world_prop: "trunk"), deci se poate apropia la 7,5 m de
## margine fara sa intre in banda.
func _lerai() -> void:
	var f := 0.756
	var i := 0
	while f < 0.800:
		var near := 7.5 + _rng.randf_range(0.0, 2.5)
		_put("s_fever_tree", f, -1.0, near, _rng.randf_range(0.95, 1.20),
			_rng.randf() * TAU)
		_put("s_fever_tree", f + 0.0015, -1.0, near + _rng.randf_range(7.0, 10.0),
			_rng.randf_range(1.0, 1.3), _rng.randf() * TAU)
		if i % 2 == 0:
			_put("s_fig_tree", f + 0.003, -1.0, near + _rng.randf_range(15.0, 20.0),
				_rng.randf_range(0.9, 1.15), _rng.randf() * TAU)
		if i % 3 == 1:
			_put("s_euphorbia", f + 0.002, -1.0, 6.0 + _rng.randf_range(0.0, 1.5),
				_rng.randf_range(1.0, 1.4), _rng.randf() * TAU)
		f += 0.0045
		i += 1


## 0.789-0.812: tabara balonului. Vartejul e la 7,4 m de ax la 0.802, deci
## tabara sta mai departe (11-24 m) ca sa nu se acopere reciproc. Balonul e
## 16,6 x 9,1 m culcat: pata galben-verde exact ca in referinta.
func _balloon_camp() -> void:
	_put("s_safari_balloon_landed", 0.793, 1.0, 17.0, 1.0, 2.6)
	_put("s_safari_tent", 0.796, 1.0, 13.0, 1.0, 1.1)
	_put("s_safari_tent", 0.798, 1.0, 20.0, 0.95, 2.4)
	_put("s_land_rover", 0.791, 1.0, 11.0, 1.0, 1.9)
	_put("s_campfire", 0.7955, 1.0, 15.5, 1.0, 0.0)
	_put("s_acacia_umbrella_b", 0.789, 1.0, 24.0, 1.15, 0.9)
	_put("s_acacia_umbrella_a", 0.806, 1.0, 19.0, 1.05, 2.2)
	_put("s_termite_mound_a", 0.800, 1.0, 8.5, 1.2, 0.0)
	_put("s_termite_mound_b", 0.809, -1.0, 8.0, 1.1, 0.0)
	_put("s_dead_tree", 0.804, -1.0, 10.0, 1.15, 1.4)
	_put("s_acacia_umbrella_c", 0.811, -1.0, 15.0, 1.2, 0.4)


## 0.816-0.852: iesirea spre spartura. Terenul urca pe DREAPTA (masurat:
## +6,2 m la 25 m pe 0.820, +19,6 la 0.825), deci acolo merg bolovanii mari si
## coroanele inalte — se etajeaza natural. Pe stanga campia ramane plata.
func _to_gap() -> void:
	var items := [
		[0.816, 1.0, 14.0, "s_kopje_boulder_a", 1.30],
		[0.820, 1.0, 20.0, "s_kopje_boulder_b", 1.60],
		[0.824, 1.0, 16.0, "s_acacia_umbrella_a", 1.20],
		[0.828, 1.0, 22.0, "s_kopje_boulder_c", 1.40],
		[0.833, 1.0, 12.0, "s_acacia_umbrella_c", 1.05],
		[0.838, 1.0, 17.0, "s_baobab", 0.80],
		[0.844, 1.0, 11.0, "s_fever_tree", 1.00],
		[0.850, 1.0, 18.0, "s_acacia_umbrella_b", 1.15],
		[0.818, -1.0, 12.0, "s_acacia_umbrella_b", 1.10],
		[0.826, -1.0, 18.0, "s_acacia_umbrella_a", 1.25],
		[0.831, -1.0, 9.0, "s_dead_tree", 1.05],
		[0.836, -1.0, 15.0, "s_acacia_umbrella_c", 1.15],
		[0.842, -1.0, 11.0, "s_fever_tree", 0.95],
		[0.848, -1.0, 20.0, "s_acacia_umbrella_a", 1.20],
		[0.852, -1.0, 10.0, "s_euphorbia", 1.30],
	]
	for t: Array in items:
		_put(t[3] as String, t[0] as float, t[1] as float, t[2] as float,
			t[4] as float, _rng.randf() * TAU)
	var mounds := [
		[0.822, -1.0, 7.0, "s_termite_mound_a"],
		[0.834, 1.0, 8.0, "s_termite_mound_b"],
		[0.846, -1.0, 7.5, "s_termite_mound_a"],
	]
	for t: Array in mounds:
		_put(t[3] as String, t[0] as float, t[1] as float, t[2] as float,
			_rng.randf_range(1.0, 1.4), _rng.randf() * TAU)


# ------------------------------------------------------------------ ajutoare

## Punctul de lume la fractia `f`, `dist` metri lateral de MARGINEA benzii, pe
## partea `sgn` (+1 dreapta soferului). Cota vine din raza reala pe teren, nu
## din campul de inaltime (memoria `terrain-mesh-y-extrapoleaza`).
func _world_at(f: float, sgn: float, dist: float) -> Vector3:
	var n := _track.baked.size()
	var i := int(f * float(n)) % n
	var p := _track.baked[i]
	var s := _track._side_at(i)
	var hw := _track.width_at_index(i)
	var q: Vector3 = p + s * sgn * (hw + dist)
	q.y = _sol_real(q.x, q.z)
	return q


func _put(res_id: String, f: float, sgn: float, dist: float, scl: float,
		yaw: float) -> void:
	var q := _world_at(f, sgn, dist)
	if q.y < _sea_y - 0.05:
		print("; ATENTIE %s la frac %.3f (%.1f m, semn %.0f) e SUB apa (%.2f < %.2f) - sarit"
			% [res_id, f, dist, sgn, q.y, _sea_y])
		_warn += 1
		return
	_n += 1
	var b := Basis(Vector3.UP, yaw).scaled(Vector3.ONE * scl)
	var nm := "%s_%03d" % [res_id.trim_prefix("s_"), _n]
	_out.append("")
	_out.append("[node name=\"%s\" parent=\"%s\" instance=ExtResource(\"%s\")]"
		% [nm, ZONE, res_id])
	# Transform3D se scrie pe RANDURILE bazei (memoria tscn-transform-e-pe-randuri).
	_out.append("transform = Transform3D(%.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.3f, %.3f, %.3f)"
		% [b.x.x, b.x.y, b.x.z, b.y.x, b.y.y, b.y.z, b.z.x, b.z.y, b.z.z,
		q.x, q.y, q.z])


## Un nod FlamingoFlock: stolul isi cauta singur linia apei in raza data, deci
## daca se muta lacul se muta si pasarile.
func _flock(f: float, sgn: float, dist: float, radius: float, count: int,
		wings: float) -> void:
	var q := _world_at(f, sgn, dist)
	_n += 1
	_out.append("")
	_out.append("[node name=\"StolFlamingi_%03d\" type=\"Node3D\" parent=\"%s\"]" % [_n, ZONE])
	_out.append("transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.3f, %.3f, %.3f)"
		% [q.x, q.y, q.z])
	_out.append("script = ExtResource(\"flock\")")
	_out.append("count = %d" % count)
	_out.append("radius = %.1f" % radius)
	_out.append("wings_fraction = %.2f" % wings)
	_out.append("seed = %d" % (1400 + _n))
