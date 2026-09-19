extends Node
## Camp neted vs raycast real pe fata golului lui H.
## Cine are dreptate acolo unde probe_manual striga PLUTESTE.
const TRACK := "res://scenes/tracks/Track15.tscn"
var _track: Track
var _sus := 0.0
var _rid: RID = RID()

func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	var hi := -INF
	for bp in _track.baked:
		hi = maxf(hi, bp.y)
	_sus = hi + 150.0
	# Pozitiile exacte ale celor semnalate, citite din .tscn.
	var probe: Array = [
		["stancaGol300", Vector3(-126.9, 0, 46.8)],
	]
	var n := _track.baked.size()
	print("; lat | camp neted | raycast TerrainBody | diferenta")
	for f: float in [0.9350, 0.9450, 0.9550]:
		var i := int(f * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i) * _gap_side(i)
		for lat: float in [7.0, 9.0, 10.5, 12.0, 14.0, 16.0]:
			var q := p + s * lat
			var neted := _track._sampler.ground_y(q.x, q.z)
			var real := _sol(q.x, q.z)
			print("; f=%.4f lat=%4.1f  neted %+7.2f  raycast %+7.2f  dif %+6.2f" % [
				f, lat, neted - p.y, real - p.y, neted - real])
	get_tree().quit(0)

func _gap_side(i: int) -> float:
	var p: Vector3 = _track.baked[i]
	var s := _track._side_at(i)
	var dl := 0.0
	var dr := 0.0
	for off: float in [15.0, 25.0]:
		dl += _sol((p + s * -off).x, (p + s * -off).z) - p.y
		dr += _sol((p + s * off).x, (p + s * off).z) - p.y
	return -1.0 if dl < dr else 1.0

func _sol(x: float, z: float) -> float:
	if _rid == RID():
		for c in _track.get_children():
			if str(c.name) == "TerrainBody":
				_rid = (c as StaticBody3D).get_rid()
	var space := _track.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, _sus, z), Vector3(x, _sus - 1200.0, z))
	q.collide_with_areas = false
	var hit := space.intersect_ray(q)
	var guard := 0
	while not hit.is_empty() and hit["rid"] != _rid and guard < 24:
		q.exclude = q.exclude + [hit["rid"]]
		hit = space.intersect_ray(q)
		guard += 1
	if not hit.is_empty() and hit["rid"] == _rid:
		return float(hit["position"].y)
	return NAN
