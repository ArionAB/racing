extends Node
## Sonda vacii animate (props/cow.glb, Quaternius) pe pista reala (Alpii).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCow.tscn
##   godot --fixed-fps 60 --path . res://tools/ProbeCow.tscn   (+ capturi PNG)
##
## Ca SCENA, nu cu --script (autoload-uri; vezi probe_hazard_marker.gd).
##
## Ce verifica — lantul intreg, nu doar existenta fisierului:
##   1. GLB-ul are AnimationPlayer cu cele 4 animatii si SlidingHazard l-a
##      GASIT (_anim != null). Fara verdictul asta, o vaca redenumita in
##      Blender ar iesi teapana si sonda de hazard ar trece nestingherita.
##   2. Buclele sunt puse (LOOP_LINEAR) — importul implicit le lasa one-shot.
##   3. Starea urmeaza viteza: parcata -> Eating; in traversare -> Walk/Gallop.
##      Fazele se cauta cu _offset_now(), nu se ghicesc din constante.
##   4. Scheletul chiar DEFORMEAZA: doua cadre de Walk difera intre ele la
##      pozitiile oaselor. O animatie "redata" pe un skin rupt nu misca nimic
##      si doar capul asta o prinde headless (memoria: efectele nu se
##      verifica numarand).
##
## Cu fereastra, salveaza si capturi in snapshots/: vaca parcata (paste) si
## vaca pe drum (merge), din unghiul soferului.

const TRACK_SCENE := "res://scenes/tracks/Track09.tscn"
const WANTED := [&"Idle", &"Eating", &"Walk", &"Gallop"]

var _failed := false


func _ready() -> void:
	var track := (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(track)
	await get_tree().process_frame
	await get_tree().physics_frame

	print("\n=== Sonda vacii animate ===")
	var cows: Array[SlidingHazard] = []
	_collect_cows(track, cows)
	_check(not cows.is_empty(), "hazard cu model animat gasit (%d)" % cows.size())
	if cows.is_empty():
		_finish()
		return
	var cow := cows[0]

	var anims := cow._anim.get_animation_list()
	for want: StringName in WANTED:
		_check(cow._anim.has_animation(want), "animatia %s exista" % want)
	print("  animatii in GLB: ", ", ".join(anims))
	for want: StringName in [&"Walk", &"Gallop", &"Eating"]:
		_check(cow._anim.get_animation(want).loop_mode == Animation.LOOP_LINEAR,
			"bucla pusa pe %s" % want)

	# Fazele, cautate pe legea reala de miscare: momentul cu deplasarea cea mai
	# mica intre doi pasi vecini = parcat; cea mai mare = in plina traversare.
	var t_rest := 0.0
	var t_cross := 0.0
	var v_min := 1e9
	var v_max := -1.0
	var saved := cow._time
	var horizon: float = maxf(cow.period, 1.0) + \
		(SlidingHazard.CROSS_WAIT + SlidingHazard.CROSS_TELEGRAPH) * 2.0
	var t := 0.0
	while t < horizon * 2.0:
		cow._time = t
		var a: float = cow._offset_now()
		cow._time = t + 0.05
		var v: float = absf(cow._offset_now() - a) / 0.05 * cow.travel.length()
		if v < v_min:
			v_min = v
			t_rest = t
		if v > v_max:
			v_max = v
			t_cross = t
		t += 0.05
	cow._time = saved
	print("  viteza pe ciclu: %.2f .. %.2f m/s" % [v_min, v_max])

	var cam := _make_camera(cow)

	cow._time = t_rest
	for i in 4:
		await get_tree().physics_frame
	_check(cow._anim.current_animation == "Eating",
		"parcata -> Eating (e '%s')" % cow._anim.current_animation)
	await _shoot(cam, cow, "vaca_paste")

	cow._time = t_cross
	var pose_a := _bone_signature(cow)
	for i in 4:
		await get_tree().physics_frame
	var moving := cow._anim.current_animation
	_check(moving == "Walk" or moving == "Gallop",
		"in traversare -> Walk/Gallop (e '%s', speed_scale %.2f)"
		% [moving, cow._anim.speed_scale])
	var pose_b := _bone_signature(cow)
	_check(pose_a.distance_to(pose_b) > 0.001,
		"scheletul deformeaza (delta poza %.4f)" % pose_a.distance_to(pose_b))
	await _shoot(cam, cow, "vaca_traverseaza")

	_finish()


func _collect_cows(node: Node, out: Array[SlidingHazard]) -> void:
	var hz := node as SlidingHazard
	if hz != null and hz._anim != null:
		out.append(hz)
	for child in node.get_children():
		_collect_cows(child, out)


## Suma pozitiilor globale ale oaselor — amprenta ieftina a pozei scheletului.
func _bone_signature(cow: SlidingHazard) -> Vector3:
	var skels := cow.find_children("*", "Skeleton3D", true, false)
	if skels.is_empty():
		return Vector3.ZERO
	var skel := skels[0] as Skeleton3D
	var sum := Vector3.ZERO
	for i in skel.get_bone_count():
		sum += skel.get_bone_global_pose(i).origin
	return sum


func _make_camera(cow: SlidingHazard) -> Camera3D:
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = 55.0
	cam.current = true
	return cam


func _shoot(cam: Camera3D, cow: SlidingHazard, tag: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	# Din fata-lateral, de la inaltimea capotei — unghiul din care o vede
	# jucatorul cand francheaza sa n-o loveasca.
	var side := cow.travel.normalized() if cow.travel.length() > 0.1 \
		else Vector3.RIGHT
	var along := side.cross(Vector3.UP).normalized()
	cam.global_position = cow.global_position + side * 4.0 + along * 5.0 \
		+ Vector3.UP * 1.6
	cam.look_at(cow.global_position + Vector3.UP * 0.8, Vector3.UP)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var dir := ProjectSettings.globalize_path("res://snapshots")
	DirAccess.make_dir_recursive_absolute(dir)
	var out := "%s/%s.png" % [dir, tag]
	get_viewport().get_texture().get_image().save_png(out)
	print("  captura: ", out)


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failed = true
	print("  %s %s" % ["OK      " if ok else "PROBLEMA", what])


func _finish() -> void:
	print("=== %s ===\n" % ("PROBLEME" if _failed else "TOATE OK"))
	get_tree().quit(1 if _failed else 0)
