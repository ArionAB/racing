extends SceneTree

func _initialize() -> void:
	var inst := (load("res://assets/models/chongqing/structures/tower_crane.glb") as PackedScene).instantiate() as Node3D
	var mi := inst.find_child("Jib", true, false) as MeshInstance3D
	var faces := mi.mesh.get_faces()
	var bands := {}
	for v in faces:
		var b := int(floor(v.z / 2.0)) * 2
		if not bands.has(b):
			bands[b] = [INF, -INF, INF, -INF]
		bands[b][0] = minf(bands[b][0], v.y)
		bands[b][1] = maxf(bands[b][1], v.y)
		bands[b][2] = minf(bands[b][2], v.x)
		bands[b][3] = maxf(bands[b][3], v.x)
	var keys := bands.keys()
	keys.sort()
	for k in keys:
		var e: Array = bands[k]
		print("  z %+5d..%+5d  y %+6.2f..%+6.2f  x %+5.2f..%+5.2f" % [k, k + 2, e[0], e[1], e[2], e[3]])
	inst.free()
	quit(0)
