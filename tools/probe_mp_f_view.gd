extends Node
## Unde se UITA soferul pe POI F, si ce cota are terenul acolo.
##
## Rostul: prima runda a asezat raul in bazinul masurat (z ~ -204) si el nu s-a
## vazut deloc in captura — fiindca „langa drum" si „in fata camerei" sunt doua
## locuri diferite (memoria `masoara-inainte-nu-langa`). Sonda asta trage raze
## din pozitia camerei de joc, pe directia de mers si la +/- 20 si 40 de grade,
## si spune UNDE cade fiecare si la ce cota — adica exact caseta in care un
## decor are voie sa spere ca se vede.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeMpFView.tscn

const TRACK := "res://scenes/tracks/Track15.tscn"

var _track: Track
var _terrain_rid: RID = RID()
var _sus_y := 0.0


func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	var hi := -INF
	for bp in _track.baked:
		hi = maxf(hi, bp.y)
	_sus_y = hi + 150.0
	var n := _track.baked.size()
	print("; frac  cam(x,z)        dir(x,z)     | unghi: pozitia la 40/70/110 m si cota fata de sosea")
	var f := 0.650
	while f <= 0.732:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var i2 := (i + 6) % n
		var fwd := (_track.baked[i2] - p)
		fwd.y = 0.0
		fwd = fwd.normalized()
		# Camera de joc sta in spate; pozitia de privire e in jurul masinii.
		for ang: float in [-40.0, -20.0, 0.0, 20.0, 40.0]:
			var d := fwd.rotated(Vector3.UP, deg_to_rad(ang))
			var cols: Array[String] = []
			for dist: float in [40.0, 70.0, 110.0]:
				var q := p + d * dist
				var g := _sol_real(q.x, q.z)
				cols.append("%3.0fm(%7.1f,%7.1f)y%+6.1f" % [dist, q.x, q.z, g - p.y])
			print("; %.3f (%7.1f,%7.1f) %+5.0f deg  %s" % [f, p.x, p.z, ang, " ".join(cols)])
		f += 0.005
	get_tree().quit(0)


func _sol_real(x: float, z: float) -> float:
	if _terrain_rid == RID():
		for c in _track.get_children():
			if str(c.name) == "TerrainBody":
				_terrain_rid = (c as StaticBody3D).get_rid()
	var space := _track.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(x, _sus_y, z), Vector3(x, _sus_y - 1200.0, z))
	q.collide_with_areas = false
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
	return _track._sampler.ground_y(x, z)
