extends Node
## CINE face pestritul de pe sol: se randeaza acelasi cadru de mai multe ori,
## stingand pe rand cate un strat, si se masoara contrastul aproape vs departe.
##
## Sonda asta exista fiindca doua presupuneri au picat una dupa alta (masca de
## detaliu din paleta, apoi filtrul de mipmap al soselei) si de fiecare data
## cifra a ramas neschimbata. Cand nu stii CINE deseneaza, nu ghicesti al
## treilea: stingi si masori.
const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"


func _ready() -> void:
	for mode in ["intreg", "fara detail (UV2)", "fara albedo_texture", "culoare plata"]:
		var t := (load(TRACK_SCENE) as PackedScene).instantiate() as Track
		add_child(t)
		await get_tree().process_frame
		await get_tree().physics_frame
		var touched := 0
		var mats: Array[Material] = []
		_collect(t, mats)
		for m in mats:
			var sm := m as StandardMaterial3D
			if sm == null:
				continue
			match mode:
				"fara detail (UV2)":
					sm.detail_enabled = false
				"fara albedo_texture":
					sm.detail_enabled = false
					sm.albedo_texture = null
				"culoare plata":
					sm.detail_enabled = false
					sm.albedo_texture = null
					sm.vertex_color_use_as_albedo = false
			touched += 1
		var s: TrackSideSampler = t.get("_sampler")
		var res := await _shoot(t, s)
		print("%-22s  aproape %5.2f · departe %5.2f  (%d materiale)"
			% [mode, res.x, res.y, touched])
		t.queue_free()
		await get_tree().process_frame
	get_tree().quit()


func _collect(n: Node, out: Array[Material]) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.material_override != null and not out.has(mi.material_override):
			out.append(mi.material_override)
		for si in mi.get_surface_override_material_count():
			var sm := mi.get_surface_override_material(si)
			if sm != null and not out.has(sm):
				out.append(sm)
	for c in n.get_children():
		_collect(c, out)


func _shoot(t: Track, s: TrackSideSampler) -> Vector2:
	var vp := SubViewport.new()
	vp.size = Vector2i(1280, 720)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var cam := Camera3D.new()
	vp.add_child(cam)
	cam.current = true
	var n := s.point_count()
	var i := int(0.22 * float(n)) % n
	var p := s.baked_point(i)
	var ahead := s.baked_point((i + 12) % n)
	var dir := (ahead - p).normalized()
	cam.global_transform = Transform3D().looking_at(dir, Vector3.UP)
	cam.global_position = p - dir * ChaseCamera.DEFAULT_DISTANCE \
		+ Vector3.UP * ChaseCamera.DEFAULT_HEIGHT
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	var near := _dev(img, 560, 700, 384, 794)
	var far := _dev(img, 374, 403, 486, 691)
	vp.queue_free()
	return Vector2(near, far)


func _dev(img: Image, y0: int, y1: int, x0: int, x1: int) -> float:
	var vals: Array[float] = []
	for y in range(y0, y1, 2):
		for x in range(x0, x1, 2):
			vals.append(img.get_pixel(x, y).get_luminance() * 255.0)
	var m := 0.0
	for v in vals:
		m += v
	m /= float(vals.size())
	var q := 0.0
	for v in vals:
		q += (v - m) * (v - m)
	return sqrt(q / float(vals.size()))
