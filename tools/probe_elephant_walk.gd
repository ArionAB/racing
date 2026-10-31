extends Node
## Sonda #613 (diagnostic + garda): elefantii hazard (G_Elefant1/2 pe Track14)
## chiar isi misca picioarele cat merg si le tin nemiscate cand stau.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeElephantWalk.tscn
##
## Masoara pe scheletul REAL din scena (Skeleton3D.get_bone_global_pose a
## oaselor LegFL/FR/RL/RR), nu doar ca exista un AnimationPlayer.
var _failed := false

func _ready() -> void:
	if "--clip" in OS.get_cmdline_user_args():
		await _clip_sheet()
		get_tree().quit(0)
		return
	var idx := GameState.resolve_track_index(7)
	var t := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	add_child(t)
	for i in 10:
		await get_tree().physics_frame
	var els: Array[SlidingHazard] = []
	_collect(t, els)
	var sabotage := "--sabotage" in OS.get_cmdline_user_args()
	print("")
	print("=== Elefantii merg (#613) === hazarduri: %d" % els.size())
	_check(els.size() >= 2, "doi elefanti hazard pe pista")
	for h in els:
		var drv: StrideDriver = h._stride
		_check(drv != null, "%s: are StrideDriver (rig cu oase de picior)" % h.name)
		if drv == null:
			continue
		if sabotage:
			drv.enabled = false # animatia oprita: picioarele raman incremenite
		var sk := h.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
		# CAUZA RADACINA a lui #613: ruperea accentelor (fildesi) copia varfurile
		# fara BONES/WEIGHTS, deci pielea nu urma niciodata scheletul. Fiecare
		# plasa a modelului trebuie sa fie skinned SI legata de schelet.
		var meshes := h.find_children("*", "MeshInstance3D", true, false)
		var skinned := 0
		for m in meshes:
			var mi := m as MeshInstance3D
			if mi.mesh == null:
				continue
			var fmt: int = mi.mesh.surface_get_format(0)
			var ok: bool = (fmt & Mesh.ARRAY_FORMAT_BONES) != 0 and (fmt & Mesh.ARRAY_FORMAT_WEIGHTS) != 0 				and mi.skin != null and mi.get_node_or_null(mi.skeleton) == sk
			_check(ok, "%s/%s: plasa skinned si legata de schelet" % [h.name, mi.name])
			skinned += 1 if ok else 0
		_check(skinned >= 2, "%s: corp + accent (fildesi) sunt amandoua skinned (%d)" % [h.name, skinned])
		await _measure(h, drv, sk)
	print("")
	print("REZULTAT: ", "PICAT" if _failed else "TRECUT")
	if sabotage:
		get_tree().quit(0 if _failed else 1) # sabotajul TREBUIE sa pice
		return
	if "--capture" in OS.get_cmdline_user_args():
		await _capture(els[0])
	get_tree().quit(1 if _failed else 0)

func _check(ok: bool, what: String) -> void:
	print("  [", "OK " if ok else "PICAT", "] ", what)
	if not ok:
		_failed = true

## Pozitia lumii a labei (piciorul `leg`): punctul din repaus de la sol, dus prin
## pozitia curenta a osului — fix ce face skinning-ul varfurilor labei.
func _foot(sk: Skeleton3D, leg: String) -> Vector3:
	var i := sk.find_bone(leg)
	var rest := sk.get_bone_global_rest(i)
	var p0 := Vector3(rest.origin.x, 0.0, rest.origin.z)
	return sk.global_transform * (sk.get_bone_global_pose(i) * rest.affine_inverse() * p0)

func _measure(h: SlidingHazard, drv: StrideDriver, sk: Skeleton3D) -> void:
	var legs := ["LegFL", "LegFR", "LegRL", "LegRR"]
	# 1. IN MISCARE: 6 s, un esantion pe cadru.
	var feet: Array = []  # [cadru][picior] -> pozitie lume
	var body: Array[Vector3] = []
	var stance_of: Array = []  # [cadru][picior] -> true cat laba e in faza de sprijin
	var angles := {}
	for l in legs:
		angles[l] = []
	for f in 360:
		await get_tree().physics_frame
		var row: Array[Vector3] = []
		for l in legs:
			row.append(_foot(sk, l))
			angles[l].append(sk.get_bone_pose_rotation(sk.find_bone(l)).get_euler().x)
		var st: Array[bool] = []
		for l in legs:
			var phi := fposmod(drv.phase + float(StrideDriver.LEGS[StringName(l)]), 1.0)
			st.append(phi < drv.stance and drv.amp > 0.95)
		stance_of.append(st)
		feet.append(row)
		body.append(h.global_position)
	var ymin := INF
	for row in feet:
		for p: Vector3 in row:
			ymin = minf(ymin, p.y)
	var skate := 0.0
	var stance_h := 0.0
	var stance_lo := 1e9
	var n := 0
	var travelled := 0.0
	for k in range(1, feet.size()):
		var db := Vector3(body[k].x - body[k - 1].x, 0.0, body[k].z - body[k - 1].z).length()
		travelled += db
		if db < 0.01:
			continue
		for j in 4:
			var p1: Vector3 = feet[k][j]
			var p0: Vector3 = feet[k - 1][j]
			if stance_of[k][j] and stance_of[k - 1][j]:
				stance_h = maxf(stance_h, p1.y - body[k].y)
				stance_lo = minf(stance_lo, p1.y - body[k].y)
				skate += Vector3(p1.x - p0.x, 0.0, p1.z - p0.z).length() / db
				n += 1
	var swing := 0.0
	for l in legs:
		var lo := 1e9
		var hi := -1e9
		for a: float in angles[l]:
			lo = minf(lo, a)
			hi = maxf(hi, a)
		swing = maxf(swing, rad_to_deg(hi - lo))
	var mean_skate := skate / maxf(n, 1)
	print("-- %s: %.1f m in 6 s, pas %.2f m, picioare-pe-sol %d esantioane" % [h.name, travelled, drv.stride_length(), n])
	print("   patinaj pe sol (mers laba / mers corp, 0 = nu patineaza): %.3f" % mean_skate)
	print("   laba in sprijin: %.3f .. %.3f m fata de baza hazardului" % [stance_lo, stance_h])
	print("   balans maxim picior: %.1f grade" % swing)
	_check(travelled > 5.0, "%s: elefantul chiar se deplaseaza (%.1f m)" % [h.name, travelled])
	_check(swing > 15.0, "%s: picioarele se misca in timp ce merge (%.1f grade)" % [h.name, swing])
	_check(n > 40 and mean_skate < 0.12, "%s: labele pe sol nu patineaza (%.3f < 0.12)" % [h.name, mean_skate])
	# 2. PARCAT: hazardul nemiscat, driverul primeste 0 m -> picioare drepte si fixe.
	h.set_physics_process(false)
	for f in 90:
		drv.advance(0.0, 1.0 / 60.0)
	var a0 := {}
	for l in legs:
		a0[l] = sk.get_bone_pose(sk.find_bone(l))
	for f in 30:
		drv.advance(0.0, 1.0 / 60.0)
	var drift := 0.0
	var off_rest := 0.0
	for l in legs:
		var i := sk.find_bone(l)
		drift = maxf(drift, (sk.get_bone_pose(i).origin - (a0[l] as Transform3D).origin).length())
		off_rest = maxf(off_rest, rad_to_deg((sk.get_bone_pose(i).basis.get_rotation_quaternion()
			* sk.get_bone_rest(i).basis.get_rotation_quaternion().inverse()).get_angle()))
	print("   parcat: deriva %.4f m, abatere de la repaus %.2f grade" % [drift, off_rest])
	_check(drift < 0.001 and off_rest < 0.5, "%s: parcat, picioarele stau drepte si nemiscate" % h.name)
	h.set_physics_process(true)

func _collect(n: Node, out: Array[SlidingHazard]) -> void:
	if n is SlidingHazard and n.model_scene != null and n.model_scene.resource_path.ends_with("elephant.glb"):
		out.append(n)
	for c in n.get_children():
		_collect(c, out)

## Cu fereastra: 4 cadre la 0,2 s, din lateral, camera tinuta pe elefant
## (snapshots/elefant_mers_N.png). Citeste-le cu Read.
func _capture(h: SlidingHazard) -> void:
	var cam := Camera3D.new()
	cam.fov = 40.0
	add_child(cam)
	cam.current = true
	DirAccess.make_dir_recursive_absolute("res://snapshots")
	var guard := 0
	while h._speed < 2.0 and guard < 2400:
		await get_tree().physics_frame
		guard += 1
	for k in 4:
		for f in 9:
			await get_tree().physics_frame
			var p := h.global_position
			var right := h.global_transform.basis.x
			cam.global_position = p + right * 11.0 + Vector3.UP * 1.6
			cam.look_at(p + Vector3.UP * 1.6)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://snapshots/elefant_mers_%d.png" % k)



## Elefantul GOL (fara pista): 4 faze ale ciclului Walk, din lateral, ortografic.
## snapshots/elefant_clip_N.png — arata doar ce face rig-ul, fara hazard.
func _clip_sheet() -> void:
	var inst := (load("res://assets/models/serengeti/animals/elephant.glb") as PackedScene).instantiate()
	add_child(inst)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.8, 0.85, 0.9)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.9, 0.9, 0.9)
	add_child(env)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 6.0
	add_child(cam)
	cam.global_position = Vector3(12, 1.8, 0)
	cam.look_at(Vector3(0, 1.8, 0))
	cam.current = true
	var ap := inst.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	DirAccess.make_dir_recursive_absolute("res://snapshots")
	ap.play("Walk")
	ap.pause()
	var clen := ap.get_animation("Walk").length
	for k in 4:
		ap.seek(clen * k / 4.0, true)
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://snapshots/elefant_clip_%d.png" % k)
