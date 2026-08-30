extends Node
## Cati pixeli din cadrul soferului sunt MALUL OPUS — numarati pe imagine, nu
## pe geometrie.
##
## Lectia pe care pista asta o tot repeta: o sonda de geometrie trece si cand pe
## ecran nu e nimic. AABB-ul malului spune ca masa se intinde pe 370 m; asta nu
## inseamna ca soferul o vede. Aici se randeaza chiar cadrul judecat si se
## numara pixelii care cad pe mesh-ul de mal, prin culoare de identificare.
const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"


func _ready() -> void:
	var t := (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(t)
	await get_tree().process_frame
	await get_tree().physics_frame
	var s: TrackSideSampler = t.get("_sampler")
	var n := s.point_count()
	# marcheaza malul cu un material plat, inconfundabil
	var mis: Array[Node] = []
	_walk(t, mis)
	for m in mis:
		var mi := m as MeshInstance3D
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1, 0, 1)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mi.material_override = mat
	var vp := SubViewport.new()
	vp.size = Vector2i(640, 360)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var cam := Camera3D.new()
	vp.add_child(cam)
	cam.current = true
	for f: float in [0.22, 0.28, 0.34]:
		var i := int(f * float(n)) % n
		var p := s.baked_point(i)
		var ahead := s.baked_point((i + 12) % n)
		var dir := (ahead - p).normalized()
		var eye := p - dir * ChaseCamera.DEFAULT_DISTANCE \
			+ Vector3.UP * ChaseCamera.DEFAULT_HEIGHT
		cam.global_transform = Transform3D().looking_at(dir, Vector3.UP)
		cam.global_position = eye
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img := vp.get_texture().get_image()
		var hit := 0
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.r > 0.6 and c.g < 0.4 and c.b > 0.6:
					hit += 1
		var pct := 100.0 * float(hit) / float(img.get_width() * img.get_height())
		print("frac %.2f — malul opus ocupa %5.2f%% din cadru" % [f, pct])
	get_tree().quit()


func _walk(n: Node, out: Array[Node]) -> void:
	if n is MeshInstance3D and (n.name as String).contains("pinten"):
		out.append(n)
	for c in n.get_children():
		_walk(c, out)
