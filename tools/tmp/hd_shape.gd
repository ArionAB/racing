extends SceneTree
## Cum e distribuita masa lui hongya_dong pe inaltime, si cat din suprafata e
## ORIZONTALA (acoperis) vs VERTICALA (fatada). Daca partea de sus e mai ales
## acoperis, o cladire privita de sus va fi mereu un camp de placi.
func _init() -> void:
	var ps := load("res://assets/models/chongqing/structures/hongya_dong.glb") as PackedScene
	var n := ps.instantiate()
	var bands := {}   # banda de 5 m -> [aria_oriz, aria_vert]
	var stack: Array = [n]
	while not stack.is_empty():
		var x = stack.pop_back()
		for c in x.get_children(): stack.append(c)
		var mi := x as MeshInstance3D
		if mi == null or mi.mesh == null: continue
		for si in mi.mesh.get_surface_count():
			var arr = mi.mesh.surface_get_arrays(si)
			var v = arr[Mesh.ARRAY_VERTEX]
			var idx = arr[Mesh.ARRAY_INDEX]
			if v == null: continue
			var count: int = idx.size() if idx != null else v.size()
			var i := 0
			while i < count - 2:
				var a: Vector3 = v[idx[i]] if idx != null else v[i]
				var b: Vector3 = v[idx[i+1]] if idx != null else v[i+1]
				var c2: Vector3 = v[idx[i+2]] if idx != null else v[i+2]
				var cr := (b - a).cross(c2 - a)
				var area := cr.length() * 0.5
				if area > 0.0:
					var nrm := cr.normalized()
					var band := int(((a.y + b.y + c2.y) / 3.0) / 5.0) * 5
					if not bands.has(band): bands[band] = [0.0, 0.0]
					if absf(nrm.y) > 0.6: bands[band][0] += area
					else: bands[band][1] += area
				i += 3
	var keys = bands.keys(); keys.sort()
	for k in keys:
		var h: float = bands[k][0]
		var vv: float = bands[k][1]
		print("y %3d-%3d m  oriz=%7.1f  vert=%7.1f  vert%%=%.0f" % [k, k+5, h, vv, 100.0*vv/maxf(h+vv,0.001)])
	quit()
