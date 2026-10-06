extends Node
## Sonda cailor animati (Track19, SlidingHazard cu horse_*.glb) -- lantul intreg.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeHorse.tscn
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeHorse.tscn -- --sabotaj
##
## Ca SCENA (autoload-uri). Verifica, pe fiecare cal care traverseaza:
##   1. SlidingHazard a GASIT AnimationPlayer-ul (_anim != null) -- ramane in
##      scena chiar daca `model_node = "Pose_Walk"` filtreaza copiii radacinii;
##   2. exista Walk + Idle, cu bucla pusa (importul le lasa one-shot);
##   3. starea urmeaza viteza REALA: parcat -> Idle, in traversare -> Walk,
##      cu ritmul = viteza / WALK_CYCLE_SPEED;
##   4. scheletul chiar DEFORMEAZA, picioarele se misca ALTERNATIV: pe un ciclu
##      Walk esantionat, fiecare dintre cele 4 oase Upper isi face turul
##      (amplitudine > 28 grade) iar momentul maximului e DIFERIT la toate patru
##      (mers in 4 timpi, nu galop/pas lateral cu picioare sincrone).
## Citeste starea AnimationPlayer-ului si pozitiile oaselor, nu doar existenta.
##
## `--sabotaj`: inlocuieste modelul fiecarui cal cu o copie FARA AnimationPlayer
## (GLB-ul de dinainte de rig) si ruleaza ACELEASI verificari prin
## `_build_model` real -- trebuie sa pice.

const LEG_BONES := ["F_L_Upper", "F_R_Upper", "H_L_Upper", "H_R_Upper"]

var _failed := false
var _sabotage := false


func _ready() -> void:
	_sabotage = "--sabotaj" in OS.get_cmdline_user_args()
	var idx := GameState.resolve_track_index(19)
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 3:
		await get_tree().physics_frame

	print("\n=== Sonda cailor animati, Track19%s ===" % (" (SABOTAJ)" if _sabotage else ""))
	var horses: Array[SlidingHazard] = []
	for n in track.find_children("*", "SlidingHazard", true, false):
		var hz := n as SlidingHazard
		if hz.model_scene != null and "horse_" in hz.model_scene.resource_path:
			horses.append(hz)
	_check(horses.size() == 4, "4 cai care traverseaza (CalC1, CalC2, CalG1, CalG2): %d" % horses.size())

	# Cele 3 GLB-uri (si black, care nu traverseaza pe Track19): Walk + Idle +
	# schelet + cele doua poze-noduri din contractul kitului.
	for coat in ["bay", "pinto", "black"]:
		var path := "res://assets/models/monumentvalley/animals/horse_%s.glb" % coat
		var inst := (load(path) as PackedScene).instantiate()
		var pl := inst.find_children("*", "AnimationPlayer", true, false)
		var sk := inst.find_children("*", "Skeleton3D", true, false)
		_check(not pl.is_empty() and (pl[0] as AnimationPlayer).has_animation(&"Walk")
			and (pl[0] as AnimationPlayer).has_animation(&"Idle"),
			"horse_%s.glb: AnimationPlayer cu Walk + Idle" % coat)
		_check(not sk.is_empty() and (sk[0] as Skeleton3D).get_bone_count() == 16,
			"horse_%s.glb: schelet cu 16 oase" % coat)
		_check(inst.has_node("Pose_Stand") and inst.has_node("Pose_Walk"),
			"horse_%s.glb: noduri Pose_Stand + Pose_Walk (contractul markerelor)" % coat)
		inst.free()

	for hz in horses:
		if _sabotage:
			_strip_animation(hz)
		await _probe_horse(hz)
	print("=== %s ===\n" % ("PROBLEME" if _failed else "TOATE OK"))
	get_tree().quit(1 if _failed else 0)


## Sabotaj: acelasi hazard, acelasi `_build_model`, dar GLB-ul fara player.
func _strip_animation(hz: SlidingHazard) -> void:
	var copy := hz.model_scene.instantiate()
	for p in copy.find_children("*", "AnimationPlayer", true, false):
		p.get_parent().remove_child(p)
		p.free()
	var packed := PackedScene.new()
	packed.pack(copy)
	copy.free()
	hz._anim = null
	hz._pivot.queue_free()
	for c in hz.get_children():
		if c is CollisionShape3D:
			c.queue_free()
	hz.model_scene = packed
	hz._build_model()


func _probe_horse(hz: SlidingHazard) -> void:
	var tag := "%s (%s)" % [hz.name, hz.model_scene.resource_path.get_file()]
	print("  -- ", tag)
	_check(hz._anim != null, "%s: _anim gasit (AnimationPlayer in model)" % tag)
	if hz._anim == null:
		return
	for want: StringName in [&"Walk", &"Idle"]:
		_check(hz._anim.has_animation(want), "%s: animatia %s exista" % [tag, want])
		if hz._anim.has_animation(want):
			_check(hz._anim.get_animation(want).loop_mode == Animation.LOOP_LINEAR,
				"%s: bucla pusa pe %s" % [tag, want])
	_check(hz._anim_rest == &"Idle", "%s: repaus = Idle (e '%s')" % [tag, hz._anim_rest])
	var skel := hz.find_children("*", "Skeleton3D", true, false)
	_check(not skel.is_empty() and (skel[0] as Skeleton3D).get_bone_count() >= 12,
		"%s: schelet cu >= 12 oase (skeleton-uri: %d, oase: %d)"
		% [tag, skel.size(), (skel[0] as Skeleton3D).get_bone_count() if not skel.is_empty() else 0])
	if skel.is_empty():
		return

	# Faze: parcat (viteza minima) si in plina traversare (maxima), pe legea reala.
	var t_rest := 0.0
	var t_cross := 0.0
	var v_min := 1e9
	var v_max := -1.0
	var saved := hz._time
	var horizon: float = maxf(hz.period, 1.0) + \
		(SlidingHazard.CROSS_WAIT + SlidingHazard.CROSS_TELEGRAPH) * 2.0
	var t := 0.0
	while t < horizon * 2.0:
		hz._time = t
		var a: float = hz._offset_now()
		hz._time = t + 0.05
		var v: float = absf(hz._offset_now() - a) / 0.05 * hz.travel.length()
		if v < v_min:
			v_min = v
			t_rest = t
		if v > v_max:
			v_max = v
			t_cross = t
		t += 0.05
	hz._time = saved
	print("     viteza pe ciclu: %.2f .. %.2f m/s" % [v_min, v_max])

	hz._time = t_rest
	for i in 6:
		await get_tree().physics_frame
	_check(hz._anim.current_animation == "Idle" and hz._anim.is_playing(),
		"%s: parcat -> Idle ruleaza (e '%s', playing=%s)"
		% [tag, hz._anim.current_animation, hz._anim.is_playing()])

	hz._time = t_cross
	for i in 6:
		await get_tree().physics_frame
		if OS.get_environment("PROBE_VERBOSE") != "":
			print("     [dbg] t=%.2f speed=%.3f rate=%.2f pos=%s last=%s" % [hz._time, hz._speed, hz._anim.speed_scale, hz.global_position, hz._last_pos])
	var want_rate := clampf(v_max / hz._walk_cycle_speed, 0.75, 2.2)
	_check(hz._anim.current_animation == "Walk" and hz._anim.is_playing(),
		"%s: in traversare -> Walk ruleaza (e '%s', playing=%s)"
		% [tag, hz._anim.current_animation, hz._anim.is_playing()])
	_check(absf(hz._anim.speed_scale - want_rate) < 0.2,
		"%s: ritm = viteza/viteza ciclului pe model (%.2f, asteptat %.2f)"
		% [tag, hz._anim.speed_scale, want_rate])

	# Pasii: esantionam ciclul Walk cu hazardul oprit, citim oasele Upper.
	hz.set_physics_process(false)
	hz._anim.play(&"Walk")
	var sk := skel[0] as Skeleton3D
	var length := hz._anim.get_animation(&"Walk").length
	var ids: Array[int] = []
	for b in LEG_BONES:
		ids.append(sk.find_bone(b))
		_check(ids[-1] >= 0, "%s: os %s exista" % [tag, b])
	if ids.has(-1):
		return
	var steps := 12
	var pitch: Array = [[], [], [], []]
	var sig: Array[Vector3] = []
	for s in steps:
		hz._anim.seek(length * float(s) / float(steps), true)
		for li in 4:
			pitch[li].append(sk.get_bone_pose_rotation(ids[li]).get_euler().x)
		var sum := Vector3.ZERO
		for bi in sk.get_bone_count():
			sum += sk.get_bone_global_pose(bi).origin
		sig.append(sum)
	var peaks: Array[int] = []
	for li in 4:
		var lo: float = pitch[li].min()
		var hi: float = pitch[li].max()
		var amp := rad_to_deg(hi - lo)
		var arg: int = pitch[li].find(hi)
		peaks.append(arg)
		_check(amp > 28.0, "%s: %s se misca (amplitudine %.0f grade, maxim la pasul %d/%d)"
			% [tag, LEG_BONES[li], amp, arg, steps])
	var uniq := {}
	for p in peaks:
		uniq[p] = true
	_check(uniq.size() == 4, "%s: cele 4 picioare isi ating maximul la momente DIFERITE (%s)"
		% [tag, str(peaks)])
	var spread := 0.0
	for s in range(1, steps):
		spread = maxf(spread, sig[0].distance_to(sig[s]))
	_check(spread > 0.05, "%s: scheletul deformeaza intre cadre (delta %.3f)" % [tag, spread])
	hz.set_physics_process(true)


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failed = true
	print("  %s %s" % ["OK      " if ok else "PROBLEMA", what])
