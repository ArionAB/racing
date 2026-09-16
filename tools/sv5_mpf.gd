extends Node
const TRACK := "res://scenes/tracks/Track15.tscn"
var _track: Track
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
	# FIR: pe z fix, pas 2 m pe x
	for zk: float in [-114.0, -116.0, -118.0, -120.0]:
		var line := ""
		var xk := -212.0
		while xk <= -150.0:
			line += "%.0f:%+.1f " % [xk, _sol(xk, zk)]
			xk += 2.0
		print("FIR z=%.0f %s" % [zk, line])
	# transversale fine pe x, pas 1 m pe z
	for xk: float in [-204.0, -196.0, -188.0, -180.0, -172.0, -164.0, -158.0]:
		var line := ""
		var zk := -126.0
		while zk <= -106.0:
			line += "%.0f:%+.1f " % [zk, _sol(xk, zk)]
			zk += 1.0
		print("TRV x=%.0f %s" % [xk, line])
	get_tree().quit(0)
func _sol(x: float, z: float) -> float:
	var sp := _track.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, _sus_y, z), Vector3(x, -400.0, z))
	q.collide_with_areas = false
	var r := sp.intersect_ray(q)
	if r.is_empty(): return -999.0
	return float((r["position"] as Vector3).y)
