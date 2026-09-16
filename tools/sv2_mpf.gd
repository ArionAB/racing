extends Node
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
	for bp in _track.baked: hi = maxf(hi, bp.y)
	_sus_y = hi + 150.0
	var n := _track.baked.size()
	# harta fina pe cornisa noua: x -260..-120, z -175..-105
	print("HARTA FINA (x -260..-120 pas 5)")
	var hdr := "zx    "
	var xx := -260.0
	while xx <= -120.0:
		hdr += "%6.0f" % xx
		xx += 5.0
	print(hdr)
	var zz := -175.0
	while zz <= -105.0:
		var row := "%6.0f" % zz
		var x2 := -260.0
		while x2 <= -120.0:
			row += "%6.1f" % _sol(x2, zz)
			x2 += 5.0
		print(row)
		zz += 5.0
	# profile transversale fine pe fractii de pe bratul de intors
	var fr: Array[float] = [0.690, 0.695, 0.700, 0.705, 0.710, 0.715, 0.720, 0.725, 0.730]
	for fk in fr:
		var i := int(fk * float(n)) % n
		var p := _track.baked[i]
		var s := _track._side_at(i)
		var line := ""
		var off := 0.0
		while off <= 60.0:
			var q := p + s * off
			line += "%.0f:%+.1f " % [off, _sol(q.x, q.z)]
			off += 2.5
		print("TRANS %.3f ax=(%.1f,%.1f) y=%.1f half=%.1f side=(%.2f,%.2f) | %s" % [fk, p.x, p.z, p.y, _track.width_at_index(i), s.x, s.z, line])
	get_tree().quit(0)

func _sol(x: float, z: float) -> float:
	if not _terrain_rid.is_valid():
		var tb := _track.find_child("TerrainBody", true, false)
		if tb is CollisionObject3D: _terrain_rid = (tb as CollisionObject3D).get_rid()
	var sp := _track.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, _sus_y, z), Vector3(x, -400.0, z))
	q.collide_with_areas = false
	if _terrain_rid.is_valid():
		q.collision_mask = 0xFFFFFFFF
	var r := sp.intersect_ray(q)
	if r.is_empty(): return -999.0
	return float((r["position"] as Vector3).y)
