extends Node
const TRACK := "res://scenes/tracks/Track15.tscn"
var _track: Track
var _sus_y := 0.0
var _baked: PackedVector3Array

func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	var hi := -INF
	for bp in _track.baked: hi = maxf(hi, bp.y)
	_sus_y = hi + 150.0
	_baked = _track.baked
	# profil N-S fin (pas 1.5 m) pe coloane x, in gorja: z -132..-104
	for xk: float in [-240.0, -230.0, -220.0, -210.0, -200.0, -190.0, -180.0, -170.0, -160.0, -150.0]:
		var line := ""
		var zk := -134.0
		while zk <= -102.0:
			line += "%.0f:%+.1f " % [zk, _sol(xk, zk)]
			zk += 2.0
		print("GORJA x=%.0f %s" % [xk, line])
	# distanta la drum pentru un set de puncte din gorja
	print("== DIST LA AX DRUM ==")
	for xk: float in [-230.0, -210.0, -190.0, -170.0, -155.0]:
		for zk: float in [-124.0, -120.0, -116.0, -112.0]:
			print("  (%.0f,%.0f) sol=%+.1f dist_ax=%.1f" % [xk, zk, _sol(xk, zk), _dist_ax(xk, zk)])
	get_tree().quit(0)

func _dist_ax(x: float, z: float) -> float:
	var best := 1e9
	for p in _baked:
		var d := Vector2(p.x - x, p.z - z).length()
		if d < best: best = d
	return best

func _sol(x: float, z: float) -> float:
	var sp := _track.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, _sus_y, z), Vector3(x, -400.0, z))
	q.collide_with_areas = false
	var r := sp.intersect_ray(q)
	if r.is_empty(): return -999.0
	return float((r["position"] as Vector3).y)
