extends Node
## Unde, IN LUME, cade dala r0 c3 din cadrul de sofer? Raycast pe mesh-ul
## Erciyes-ului apropiat (triunghiuri, nu coliziune — silueta n-are corp fizic).

const DIST := 7.5
const HEIGHT := 3.2
const FOV := 68.0
const LOOK_AHEAD := 14.0
const LOOK_HEIGHT := 1.2
const W := 1280.0
const H := 720.0

func _ready() -> void:
	var ti := GameState.resolve_track_index(13)
	var track := (load(GameState.TRACK_SCENES[ti]) as PackedScene).instantiate() as Track
	add_child(track)
	for i in range(6):
		await get_tree().process_frame

	var route := track.route_at(0)
	var pts := route.baked
	var n := pts.size()
	var idx := int(0.06 * float(n)) % n
	var focus: Vector3 = pts[idx]
	var ahead: Vector3 = pts[route.wrap_index(idx + 12)]
	var dir := (ahead - focus).normalized()
	var eye := focus - dir * DIST + Vector3.UP * HEIGHT
	var target := focus + dir * LOOK_AHEAD + Vector3.UP * LOOK_HEIGHT

	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = FOV
	cam.far = 400.0
	cam.global_position = eye
	cam.look_at(target, Vector3.UP)
	cam.current = true
	await get_tree().process_frame

	print("eye=%.2f,%.2f,%.2f" % [eye.x, eye.y, eye.z])

	# aduna triunghiurile Erciyes-ului apropiat (@Node3D@128)
	var tris := PackedVector3Array()
	_gather(track, tris)
	print("triunghiuri Erciyes apropiat: %d" % (tris.size() / 3))

	print("--- grila 5x5 in dala r0 c3, unde loveste ---")
	for gy in range(5):
		var row := ""
		for gx in range(5):
			var px := Vector2((3.0 + (gx + 0.5) / 5.0) * W / 5.0,
				((gy + 0.5) / 5.0) * H / 5.0)
			var ro := cam.project_ray_origin(px)
			var rd := cam.project_ray_normal(px)
			var best := 1e9
			var bp := Vector3.ZERO
			for t in range(0, tris.size(), 3):
				var hit = Geometry3D.ray_intersects_triangle(ro, rd,
					tris[t], tris[t + 1], tris[t + 2])
				if hit != null:
					var d := ro.distance_to(hit)
					if d < best:
						best = d
						bp = hit
			if best < 1e8:
				row += " %4.0fm(%.0f,%.0f,%.0f)" % [best, bp.x, bp.y, bp.z]
			else:
				row += "        cer      "
		print(row)
	get_tree().quit()

func _gather(node: Node, out: PackedVector3Array) -> void:
	for child in node.get_children():
		if child is MeshInstance3D and "Erciyes" in str(child.get_path()) \
				and "@128" in str(child.get_path()):
			var mi := child as MeshInstance3D
			var xf := mi.global_transform
			for s in range((mi.mesh as Mesh).get_surface_count()):
				var arr := (mi.mesh as Mesh).surface_get_arrays(s)
				var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
				if ix.is_empty():
					for i in range(vs.size()):
						out.append(xf * vs[i])
				else:
					for i in range(ix.size()):
						out.append(xf * vs[ix[i]])
		_gather(child, out)
