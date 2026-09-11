extends Node
## Unde cad pe ECRAN punctele date, prin camera de joc la fractia ceruta.
## Serveste la asezarea benzii de crusta si a inelului de flamingi CHIAR in
## cadrul hero, nu langa el.

const OUT_W := 1280.0
const OUT_H := 720.0

func _ready() -> void:
	var frac := 0.40
	var pts: Array[Vector3] = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--frac="):
			frac = float(arg.trim_prefix("--frac="))
		elif arg.begins_with("--p="):
			var e := arg.trim_prefix("--p=").split(",")
			pts.append(Vector3(float(e[0]), float(e[1]), float(e[2])))
	await get_tree().process_frame
	var only := GameState.resolve_track_index(7)
	var scene := load(GameState.TRACK_SCENES[only]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var r: TrackRoute = track.routes[0]
	var n := r.baked.size()
	var i := int(frac * float(n)) % n
	var focus: Vector3 = r.baked[i]
	var ahead: Vector3 = r.baked[r.wrap_index(i + 12)]
	var dir := (ahead - focus).normalized()
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = ChaseCamera.BASE_FOV
	cam.far = 500.0
	cam.position = focus - dir * ChaseCamera.DEFAULT_DISTANCE + Vector3.UP * ChaseCamera.DEFAULT_HEIGHT
	cam.look_at(focus + dir * ChaseCamera.LOOK_AHEAD + Vector3.UP * ChaseCamera.LOOK_HEIGHT, Vector3.UP)
	cam.current = true
	await get_tree().process_frame
	get_viewport().size = Vector2i(int(OUT_W), int(OUT_H))
	await get_tree().process_frame
	print("CAM pos=(%.1f,%.1f,%.1f) fwd=(%.2f,%.2f,%.2f)" % [cam.global_position.x, cam.global_position.y, cam.global_position.z, -cam.global_basis.z.x, -cam.global_basis.z.y, -cam.global_basis.z.z])
	var space := track.get_world_3d().direct_space_state
	for p in pts:
		var behind := cam.is_position_behind(p)
		var s := cam.unproject_position(p)
		var vis := "in" if (not behind and s.x >= 0 and s.x <= OUT_W and s.y >= 0 and s.y <= OUT_H) else "AFARA"
		var q := PhysicsRayQueryParameters3D.create(cam.global_position, p)
		var hit := space.intersect_ray(q)
		var occ := "liber"
		if not hit.is_empty():
			var dh := cam.global_position.distance_to(hit.position)
			var dp := cam.global_position.distance_to(p)
			if dh < dp - 2.0:
				occ = "OCLUZAT la %.0f/%.0f m (%s)" % [dh, dp, str(hit.collider.name if hit.collider != null else "?")]
		print("  (%.0f,%.0f,%.0f) -> ecran (%.0f,%.0f) %s  %s" % [p.x, p.y, p.z, s.x, s.y, vis, occ])
	get_tree().quit(0)
