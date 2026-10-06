extends Node
## Patinarea picioarelor animalelor care traverseaza (SlidingHazard cu schelet).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeFootSlide.tscn \
##       -- [--tracks=19,14] [--cal=horse_bay=1.5,elephant=2.1]
##
## Pentru fiecare hazard cu AnimationPlayer: viteza REALA de traversare v, apoi,
## pentru 3 variante de ritm, viteza in LUME a oaselor-talpa cat sunt pe sol
## (medie pe ciclu; 0 = nu patineaza):
##   (a) main: viteza masurata dubla (bug-ul `_last_pos = global_position`)
##   (b) viteza corecta, WALK_CYCLE_SPEED global
##   (c) viteza corecta, viteza ciclului calibrata pe model (S_nat, citita din
##       clip: viteza cu care sta talpa inapoi in stance la ritm 1)
## Talpile = cele 4 oase cu cota minima pe ciclu; stance = cadrele in care osul
## e la <= 4% din inaltimea scheletului peste minimul lui.
## Citeste pozitiile oaselor din animatia REALA (seek), nu estimeaza.

const WALK_CYCLE := 1.5
const N := 96


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var only: Array[int] = []
	var cal := {}
	for a in args:
		if a.begins_with("--tracks="):
			for p in a.trim_prefix("--tracks=").split(","):
				only.append(int(p))
		elif a.begins_with("--cal="):
			for kv in a.trim_prefix("--cal=").split(","):
				var p := kv.split("=")
				cal[p[0]] = float(p[1])
	print("\n=== Patinare talpi (m/s in lume, medie pe stance) ===")
	for path in GameState.TRACK_SCENES:
		var num := int(path.get_file().trim_prefix("Track").trim_suffix(".tscn"))
		if not only.is_empty() and not only.has(num):
			continue
		var track := (load(path) as PackedScene).instantiate() as Track
		add_child(track)
		for _i in 3:
			await get_tree().physics_frame
		for n in track.find_children("*", "SlidingHazard", true, false):
			var hz := n as SlidingHazard
			if hz._anim != null:
				await _measure(num, hz, cal)
		track.queue_free()
		await get_tree().process_frame
	get_tree().quit()


func _measure(num: int, hz: SlidingHazard, cal: Dictionary) -> void:
	var stem := hz.model_scene.resource_path.get_file().get_basename()
	# viteza reala de traversare, pe legea de miscare (maximul)
	var v := 0.0
	var tm := 0.0
	var t := 0.0
	while t < hz.period * 3.0 + 40.0:
		var a: float = hz._offset_at(t)
		var d: float = absf(hz._offset_at(t + 0.05) - a) / 0.05 * hz.travel.length()
		if d > v:
			v = d
			tm = t
		t += 0.05
	hz._time = tm
	for _i in 4:
		await get_tree().physics_frame
	hz.set_physics_process(false)
	var sk := hz.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var anim_name := &"Walk"
	var an := hz._anim.get_animation(anim_name)
	var L := an.length
	hz._anim.play(anim_name, 0.0)
	# directia REALA de miscare la momentul masurat (nu presupunem ca modelul
	# priveste inainte): semnul derivatei offsetului x axa de traversare
	var dsign := signf(hz._offset_at(tm + 0.05) - hz._offset_at(tm))
	var fwd := hz.travel.normalized() * dsign
	fwd.y = 0.0
	fwd = fwd.normalized()
	var face := -hz.global_basis.z
	face.y = 0.0
	# TALPA = osul-picior + decalajul pana la sol din poza de repaus (picioarele
	# elefantului sunt oase de sold: originea lor nu atinge niciodata solul).
	var feet: Array[int] = []
	for bi in sk.get_bone_count():
		var nm := sk.get_bone_name(bi)
		if nm.ends_with("_Hoof") or nm.begins_with("Leg") or nm in ["FF.L", "FF.R", "FFB.L", "FFB.R"]:
			feet.append(bi)
	var ground := hz.global_position.y
	var offs: Array[Vector3] = []
	var rest_inv: Array[Basis] = []
	for bi in feet:
		var rest := sk.global_transform * sk.get_bone_global_rest(bi)
		offs.append(Vector3(0.0, -(rest.origin.y - ground), 0.0))
		rest_inv.append(rest.basis.inverse())
	var height := maxf(Track.model_aabb(sk.get_parent() as Node3D).size.y, 1.0)
	var clips := {}
	for cn: StringName in [&"Walk", &"Gallop"]:
		if hz._anim.has_animation(cn):
			clips[cn] = _clip(hz, sk, cn, feet, offs, rest_inv, height, fwd)
	var s_nat: float = clips[&"Walk"]["s_nat"]
	var cnt: int = clips[&"Walk"]["cnt"]
	var stance_walk: Array = clips[&"Walk"]["stance"]
	var has_gallop := hz._anim.has_animation(&"Gallop")
	var out := "T%d %s %s: v=%.2f m/s, %d talpi, stance %d/%d esantioane, S_nat=%.2f m/s, ciclu %.2f s, privire.miscare=%.2f, max_sweep=%.1f%s" % [
		num, hz.name, stem, v, feet.size(),
		cnt, feet.size() * N, s_nat, L, fwd.dot(face.normalized()), hz.max_sweep_speed, " (are Gallop)" if has_gallop else ""]
	print(out, "  [motion=", hz.motion, " model_scale=", hz.model_scale, "]")
	# ritmul OPTIM (minim de patinare) pe clip, cautat pe grila, si viteza ciclului
	# care il da la viteza asta: S* = v / r*  (valoarea de pus in tabel)
	var best_r := 1.0
	var best_s := 1e9
	for ri in range(20, 400):
		var r := float(ri) * 0.01
		var acc := 0.0
		for f in stance_walk:
			acc += absf(v + f * r)
		var sl := acc / maxf(stance_walk.size(), 1)
		if sl < best_s:
			best_s = sl
			best_r = r
	var s_opt := v / best_r
	print("    optim Walk: rate*=%.2f -> patinare %.2f m/s, viteza ciclului S*=%.2f m/s" % [best_r, best_s, s_opt])
	# S* al clipului Walk la o viteza de plimbare de referinta (1,5 m/s), ca sa
	# existe valoare de tabel si pentru modele care traverseaza doar in galop
	var wr := 1.0
	var ws := 1e9
	for ri in range(20, 400):
		var r := float(ri) * 0.01
		var acc := 0.0
		for f in stance_walk:
			acc += absf(1.5 + f * r)
		var sl := acc / maxf(stance_walk.size(), 1)
		if sl < ws:
			ws = sl
			wr = r
	print("    Walk la v=1.5 m/s: rate*=%.2f, patinare %.2f, S*=%.2f m/s" % [wr, ws, 1.5 / wr])
	if clips.has(&"Gallop"):
		var g: Array = clips[&"Gallop"]["stance"]
		var gr := 1.0
		var gs := 1e9
		for ri in range(20, 400):
			var r := float(ri) * 0.01
			var acc := 0.0
			for f in g:
				acc += absf(v + f * r)
			var sl := acc / maxf(g.size(), 1)
			if sl < gs:
				gs = sl
				gr = r
		print("    optim Gallop: rate*=%.2f -> patinare %.2f m/s, viteza ciclului S*=%.2f m/s" % [gr, gs, v / gr])
	var calv: float = hz._walk_cycle_speed
	var variants := {
		"a main (v dubla, 1.5)": [2.0 * v, WALK_CYCLE],
		"b fix (v, 1.5)": [v, WALK_CYCLE],
		"c fix+tabel (livrat)": [v, calv],
	}
	for k in variants:
		var vm: float = variants[k][0]
		var cyc: float = variants[k][1]
		var which := "Walk"
		var rate := clampf(vm / cyc, 0.75, 2.2)
		if vm > SlidingHazard.RUN_SPEED and has_gallop:
			which = "Gallop"
			rate = clampf(vm / (SlidingHazard.RUN_CYCLE_SPEED if not k.begins_with("c") else hz._run_cycle_speed), 0.7, 3.0)
		# viteza in lume = v + f*rate (f negativ in stance)
		var clip: Dictionary = clips[&"Gallop"] if which == "Gallop" else clips[&"Walk"]
		var stance: Array = clip["stance"]
		var acc := 0.0
		for f in stance:
			acc += absf(v + f * rate)
		var slide := acc / maxf(stance.size(), 1)
		print("    %-24s anim=%-6s rate=%.2f  patinare=%.2f m/s  (%.0f%% din v)" % [
			k, which, rate, slide, 100.0 * slide / maxf(v, 0.001)])


## Esantioneaza un clip: -> {stance: Array[float] (viteza fwd a talpii in
## anim-timp, cadrele de sprijin), s_nat: viteza medie inapoi in stance}.
func _clip(hz: SlidingHazard, sk: Skeleton3D, cn: StringName, feet: Array[int],
		offs: Array[Vector3], rest_inv: Array[Basis], height: float, fwd: Vector3) -> Dictionary:
	var L := hz._anim.get_animation(cn).length
	hz._anim.play(cn, 0.0)
	var P: Array = []   # [esantion][talpa] -> pozitie in lume
	for i in N:
		hz._anim.seek(L * float(i) / N, true)
		var row: Array[Vector3] = []
		for k in feet.size():
			var cur := sk.global_transform * sk.get_bone_global_pose(feet[k])
			row.append(cur.origin + cur.basis * rest_inv[k] * offs[k])
		P.append(row)
	var tol := 0.02 * height
	if OS.get_environment("PROBE_VERBOSE") != "":
		for i in range(0, N, 8):
			print("   [dbg] %s i=%d foot0=%s bonepose=%s" % [cn, i, P[i][0], sk.get_bone_pose_rotation(feet[0])])
	var dt_anim := L / N
	var sum_back := 0.0
	var cnt := 0
	var stance: Array = []
	for k in feet.size():
		# SPRIJIN = talpa se misca INAPOI fata de corp (in swing merge inainte).
		# Pe elefant (picioare-pendul, fara ridicare) un criteriu de inaltime
		# n-ar selecta nimic.
		for i in N:
			var j := (i + 1) % N
			var f: float = (P[j][k] - P[i][k]).dot(fwd) / dt_anim
			if f < 0.0:
				sum_back += -f
				cnt += 1
				stance.append(f)
	return {"stance": stance, "s_nat": sum_back / maxf(cnt, 1), "cnt": cnt, "len": L}
