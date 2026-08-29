extends SceneTree
func _init() -> void:
	var ps := load("res://scenes/tracks/Track12.tscn") as PackedScene
	var root := ps.instantiate()
	get_root().add_child(root)
	var tr := root
	# find curve
	var path := _findp(root)
	print("path=", path)
	var c: Curve3D = path.curve
	var L := c.get_baked_length()
	print("baked length=%.1f" % L)
	for f in [0.0, 0.003, 0.005, 0.008, 0.012, 0.016, 0.020, 0.025, 0.030, 0.04]:
		var p := c.sample_baked(f * L)
		var p2 := c.sample_baked(minf(f*L+2.0, L))
		var fwd := (p2 - p).normalized()
		var right := fwd.cross(Vector3.UP).normalized()
		print("frac %.3f pos=(%.1f,%.1f,%.1f) right=(%.2f,%.2f,%.2f)" % [f, p.x,p.y,p.z, right.x,right.y,right.z])
	quit()
func _findp(n: Node) -> Path3D:
	if n is Path3D: return n
	for ch in n.get_children():
		var r := _findp(ch)
		if r: return r
	return null
