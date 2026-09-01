extends Node
## De ce e un voal translucid peste jumatatea stanga a cadrului la 0.72?
##
## Nu raycast: voalul poate fi geometrie FARA corp de coliziune. Reconstruiesc
## camera de masurare a Snapshot-ului si intreb fiecare MeshInstance3D din
## scena daca AABB-ul lui e in frustum SI daca materialul lui e transparent.
## Un perete opac in frustum e normal; unul transparent, la 5-30 m in fata
## camerei, e voalul.

const MEASURE_DIST: float = 7.5
const MEASURE_HEIGHT: float = 3.2
const MEASURE_FOV: float = 68.0
const MEASURE_LOOK_AHEAD: float = 14.0
const MEASURE_LOOK_HEIGHT: float = 1.2

func _ready() -> void:
	var frac := 0.72
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--frac="):
			frac = float(a.trim_prefix("--frac="))
	var track_scene: PackedScene = load("res://scenes/tracks/Track13.tscn")
	var track := track_scene.instantiate()
	add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var route = track.route_at(0)
	var pts = route.baked
	var n: int = pts.size()
	var idx: int = int(frac * float(n)) % n
	var focus: Vector3 = pts[idx]
	var ahead: Vector3 = pts[route.wrap_index(idx + 12)]
	var dir := (ahead - focus).normalized()
	var eye: Vector3 = focus - dir * MEASURE_DIST + Vector3.UP * MEASURE_HEIGHT
	var look: Vector3 = focus + dir * MEASURE_LOOK_AHEAD + Vector3.UP * MEASURE_LOOK_HEIGHT

	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = MEASURE_FOV
	cam.far = 400.0
	cam.global_position = eye
	cam.look_at(look, Vector3.UP)
	cam.current = true
	await get_tree().process_frame

	print("=== VOAL frac=%.2f  ochi %s ===" % [frac, eye])
	var found: Array = []
	_walk(track, cam, eye, found)
	found.sort_custom(func(a, b): return a["d"] < b["d"])
	print("--- mesh-uri TRANSPARENTE in frustum, dupa distanta ---")
	for f in found:
		print("  %6.1f m  %-46s  %s" % [f["d"], f["path"], f["why"]])
	if found.is_empty():
		print("  (niciunul)")
	get_tree().quit()

func _walk(node: Node, cam: Camera3D, eye: Vector3, out: Array) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.visible and mi.is_visible_in_tree() and mi.mesh != null:
			var aabb := mi.global_transform * mi.get_aabb()
			if cam.is_position_in_frustum(aabb.get_center()):
				var why := _why_transparent(mi)
				if why != "":
					out.append({
						"d": eye.distance_to(aabb.get_center()),
						"path": String(mi.get_path()).substr(0, 46),
						"why": why,
					})
	for c in node.get_children():
		_walk(c, cam, eye, out)

func _why_transparent(mi: MeshInstance3D) -> String:
	var mats: Array = []
	if mi.material_override != null:
		mats.append(mi.material_override)
	for i in range(mi.get_surface_override_material_count()):
		var m := mi.get_surface_override_material(i)
		if m != null:
			mats.append(m)
	var mesh := mi.mesh
	for i in range(mesh.get_surface_count()):
		var m := mesh.surface_get_material(i)
		if m != null:
			mats.append(m)
	for m in mats:
		if m is BaseMaterial3D:
			var b := m as BaseMaterial3D
			if b.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
				return "transparency=%d alpha=%.2f blend=%d" % [
					b.transparency, b.albedo_color.a, b.blend_mode]
			if b.albedo_color.a < 0.999:
				return "albedo.a=%.2f" % b.albedo_color.a
		elif m is ShaderMaterial:
			return "ShaderMaterial %s" % [
				(m as ShaderMaterial).shader.resource_path if (m as ShaderMaterial).shader else "?"]
	return ""
