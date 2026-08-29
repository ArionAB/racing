extends SceneTree
func _init() -> void:
	for name in ["liziba_block", "tower_silhouette_a", "tower_silhouette_b", "tower_silhouette_c"]:
		var ps := load("res://assets/models/chongqing/buildings/%s.glb" % name) as PackedScene
		var root := ps.instantiate()
		print("=== ", name)
		_walk(root, Transform3D.IDENTITY)
	quit()

func _walk(n: Node, xf: Transform3D) -> void:
	var t := xf
	if n is Node3D: t = xf * (n as Node3D).transform
	if n is MeshInstance3D:
		_report(n as MeshInstance3D, t)
	for c in n.get_children(): _walk(c, t)

func _report(mi: MeshInstance3D, xf: Transform3D) -> void:
	var aabb := mi.mesh.get_aabb()
	print("  mesh %s aabb pos=%v size=%v surf=%d" % [mi.name, aabb.position, aabb.size, mi.mesh.get_surface_count()])
	# per direction: area, and UV-slot spread (proxy for detail)
	var dirs := {"+X": Vector3.RIGHT, "-X": Vector3.LEFT, "+Y": Vector3.UP, "-Y": Vector3.DOWN, "+Z": Vector3.BACK, "-Z": Vector3.FORWARD}
	for s in mi.mesh.get_surface_count():
		var arr := mi.mesh.surface_get_arrays(s)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV] if arr[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		var area := {}
		var slots := {}
		var tri := {}
		for d in dirs: area[d] = 0.0; slots[d] = {}; tri[d] = 0
		for i in range(0, idx.size(), 3):
			var a := v[idx[i]]; var b := v[idx[i+1]]; var c := v[idx[i+2]]
			var n := (b-a).cross(c-a)
			var ar := n.length() * 0.5
			if ar <= 0.0: continue
			n = n.normalized()
			var best := ""; var bd := -2.0
			for d in dirs:
				var dv: float = n.dot(dirs[d])
				if dv > bd: bd = dv; best = d
			area[best] += ar
			tri[best] += 1
			if uv.size() > 0:
				var u := (uv[idx[i]] + uv[idx[i+1]] + uv[idx[i+2]]) / 3.0
				slots[best][Vector2i(int(u.x*64), int(u.y*64))] = true
		for d in ["+X","-X","+Y","-Y","+Z","-Z"]:
			print("    surf%d %s area=%.1f tris=%d uvcells=%d" % [s, d, area[d], tri[d], slots[d].size()])
