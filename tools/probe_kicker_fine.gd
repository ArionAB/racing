extends SceneTree
## Grila fina (0,5 m) pe rampa kopje_kicker.glb: x -10..1, z -8..1.
const GLB := "res://assets/models/serengeti/rocks/kopje_kicker.glb"
func _init() -> void:
	var scene := (load(GLB) as PackedScene).instantiate()
	var tris: Array = []
	_collect(scene, Transform3D.IDENTITY, tris)
	var head := "   z|x  "
	var x := -10.0
	while x <= 1.01:
		head += "%5.1f" % x
		x += 0.5
	print(head)
	var z := -8.0
	while z <= 1.01:
		var row := "%5.1f  " % z
		x = -10.0
		while x <= 1.01:
			var h := _height_at(tris, x, z)
			row += "  ---" if h < -100.0 else "%5.2f" % h
			x += 0.5
		print(row)
		z += 0.5
	quit(0)
func _collect(node: Node, xf: Transform3D, out: Array) -> void:
	var t := xf
	if node is Node3D:
		t = xf * (node as Node3D).transform
	if node is MeshInstance3D:
		var mesh := (node as MeshInstance3D).mesh
		for s in mesh.get_surface_count():
			var arr := mesh.surface_get_arrays(s)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			for k in range(0, idx.size(), 3):
				out.append([t * v[idx[k]], t * v[idx[k + 1]], t * v[idx[k + 2]]])
	for c in node.get_children():
		_collect(c, t, out)
func _height_at(tris: Array, x: float, z: float) -> float:
	var best := -1000.0
	var p := Vector2(x, z)
	for tri in tris:
		var a: Vector3 = tri[0]; var b: Vector3 = tri[1]; var c: Vector3 = tri[2]
		var a2 := Vector2(a.x, a.z); var b2 := Vector2(b.x, b.z); var c2 := Vector2(c.x, c.z)
		var den := (b2.y - c2.y) * (a2.x - c2.x) + (c2.x - b2.x) * (a2.y - c2.y)
		if absf(den) < 1e-9:
			continue
		var l0 := ((b2.y - c2.y) * (p.x - c2.x) + (c2.x - b2.x) * (p.y - c2.y)) / den
		var l1 := ((c2.y - a2.y) * (p.x - c2.x) + (a2.x - c2.x) * (p.y - c2.y)) / den
		var l2 := 1.0 - l0 - l1
		if l0 < -1e-4 or l1 < -1e-4 or l2 < -1e-4:
			continue
		best = maxf(best, l0 * a.y + l1 * b.y + l2 * c.y)
	return best
