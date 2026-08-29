extends SceneTree
func _init() -> void:
	var ps := load("res://assets/models/chongqing/buildings/liziba_block.glb") as PackedScene
	var mi: MeshInstance3D = _find(ps.instantiate())
	var arr := mi.mesh.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var roof := 0.0; var wall := 0.0
	for i in range(0, idx.size(), 3):
		var a := v[idx[i]]; var b := v[idx[i+1]]; var c := v[idx[i+2]]
		var nn := (b-a).cross(c-a); var ar := nn.length()*0.5
		if ar <= 0.0: continue
		nn = nn.normalized()
		if absf(nn.y) > 0.7: roof += ar
		else: wall += ar
	print("liziba: orizontal=%.1f vertical=%.1f raport=%.2f" % [roof, wall, wall/roof])
	quit()
func _find(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D: return n
	for c in n.get_children():
		var r := _find(c)
		if r: return r
	return null
