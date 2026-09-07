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
	pass
