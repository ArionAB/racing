extends Node
## Umbrele in CADRUL DE LIVRARE, nu pe pista in general.
## Directia drumului la frac 0.05, azimutul soarelui, unghiul dintre umbra si
## directia de mers, si daca lumina chiar arunca (shadow enabled, cascada).
func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 6: await get_tree().process_frame
	var r = t.routes[0]
	var n: int = r.baked.size()
	var i := int(0.05 * n)
	var p: Vector3 = r.baked[i]
	var a: Vector3 = r.baked[(i + 6) % n]
	var dir: Vector3 = (a - p).normalized()
	var road_az := rad_to_deg(atan2(dir.x, -dir.z))
	if road_az < 0.0: road_az += 360.0
	# lumina
	var sun: DirectionalLight3D = null
	var stack: Array[Node] = [t]
	while not stack.is_empty():
		var nd: Node = stack.pop_back()
		for c in nd.get_children(): stack.append(c)
		if nd is DirectionalLight3D: sun = nd
	if sun == null:
		print("NU EXISTA DirectionalLight3D"); get_tree().quit(0); return
	var ld: Vector3 = -sun.global_transform.basis.z
	print("lumina: rot=%s  shadow=%s  mode=%d  bias=%.4f  norm_bias=%.3f" % [
		str(sun.rotation_degrees), str(sun.shadow_enabled),
		sun.directional_shadow_mode, sun.shadow_bias, sun.shadow_normal_bias])
	print("  max_distance=%.1f  blur=%.2f  pancake=%.2f  energy=%.2f" % [
		sun.directional_shadow_max_distance, sun.shadow_blur,
		sun.directional_shadow_pancake_size, sun.light_energy])
	# CINE arunca, in cadru
	var cam := Camera3D.new()
	cam.fov = 68.0; cam.near = 0.05; cam.far = 400.0
	add_child(cam)
	var eye: Vector3 = p - dir * 12.5 + Vector3.UP * 10.0
	cam.global_transform = Transform3D().looking_at(dir, Vector3.UP)
	cam.global_position = eye
	var on := 0; var off := 0; var innear := 0
	var st2: Array[Node] = [t]
	while not st2.is_empty():
		var nd: Node = st2.pop_back()
		for c in nd.get_children(): st2.append(c)
		var gi := nd as GeometryInstance3D
		if gi == null: continue
		var d := eye.distance_to(gi.global_position)
		if d > 90.0: continue
		if not cam.is_position_in_frustum(gi.global_position): continue
		innear += 1
		if gi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF: off += 1
		else: on += 1
	print("in frustum la <90 m (in cascada de 75): %d obiecte, %d arunca, %d NU" % [innear, on, off])
	# umbra cade in directia in care merge lumina, proiectata pe plan
	var sh := Vector2(ld.x, ld.z).normalized()
	var sh_az := rad_to_deg(atan2(sh.x, -sh.y))
	if sh_az < 0.0: sh_az += 360.0
	var elev := rad_to_deg(asin(-ld.y))
	print("drum azimut la frac 0.05: %.1f deg" % road_az)
	print("umbra bate spre azimut: %.1f deg   elevatie soare: %.1f deg" % [sh_az, elev])
	var rel: float = fmod(sh_az - road_az + 720.0, 360.0)
	if rel > 180.0: rel = 360.0 - rel
	print("unghi umbra-vs-directia de mers: %.1f deg  (0=in fata, 180=inapoi peste camera)" % rel)
	print("componenta TRANSVERSALA (sin): %.2f   lungime umbra / inaltime: %.2f" % [
		sin(deg_to_rad(rel)), 1.0 / maxf(tan(deg_to_rad(elev)), 0.01)])
	get_tree().quit(0)
