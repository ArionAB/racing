extends Node
## Cat timp tine camera "in poarta". Briefull cere ca un tavan scurt sa nu
## clipuiasca peste 1 s (§2.0: un clip de sub 1 s e tolerabil).
##
## Nu se numara metri de piatra, se simuleaza `ChaseCamera._unclip`: pentru
## fiecare pozitie de pe banda se trage raza de la masina la pozitia ideala a
## camerei si se vede daca poarta o taie. Apoi se imparte la viteza reala.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCappClip.tscn -- --track=6

## Viteza cu care se trece pe acolo. POI B e o portiune tehnica in S-uri, deci
## nu se ia viteza maxima: 22 m/s (~80 km/h) e ce arata ProbeRace pe sectoare
## strambe. Cifra conteaza doar ca impartitor, si e cea PESIMISTA (mai incet =
## clip mai lung).
const SPEED: float = 22.0
const STEP: float = 0.5


func _ready() -> void:
	await get_tree().process_frame
	var idx := 6
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var space := track.get_world_3d().direct_space_state

	# Intai: chiar A PRIMIT poarta layerul de blocare? Un clip de 0 s poate
	# insemna si "camera trece pe langa arc", si "arcul e invizibil pentru
	# raycast" — sunt lucruri diferite si numai unul e in regula.
	var stack: Array[Node] = [track]
	while not stack.is_empty():
		var nn: Node = stack.pop_back()
		for c in nn.get_children():
			stack.append(c)
		if nn is StaticBody3D:
			var b := nn as StaticBody3D
			if String(b.name).find("poarta") >= 0 or String(b.name).find("horn") >= 0:
				print("; corp %s layer=%d camera=%s mod=%s forme=%d la %.1f m" % [
					b.name, b.collision_layer,
					str((b.collision_layer & Track.CAMERA_BLOCKER_LAYER) != 0),
					str(b.get_meta("mod_coliziune", "?")),
					b.get_child_count(),
					b.global_position.distance_to(Vector3(57.16, 46.29, 53.07))])

	# Se merge pe banda prin dreptul portii si se intreaba, la fiecare pas, daca
	# raza masina -> camera atinge ceva pe CAMERA_BLOCKER_LAYER.
	var n := track.baked.size()
	var clipped := 0.0
	var total := 0.0
	var first := -1.0
	var last := -1.0
	var d := 0.0
	var span := 60.0
	var f0 := 0.152 - 0.016
	while d < span:
		var f: float = f0 + (d / span) * 0.032
		var i := int(f * float(n)) % n
		var j := (i + 1) % n
		var p := track.baked[i]
		var fwd := (track.baked[j] - p).normalized()
		# Pozitia masinii si tinta camerei, cu parametrii reali ai ChaseCamera.
		var car := p + Vector3.UP * 0.6
		var from := car + Vector3.UP * ChaseCamera.LOOK_HEIGHT
		var want := car - fwd * 12.5 + Vector3.UP * 10.0
		var q := PhysicsRayQueryParameters3D.create(from, want,
			Track.CAMERA_BLOCKER_LAYER)
		var hit := space.intersect_ray(q)
		total += STEP
		if not hit.is_empty():
			clipped += STEP
			if first < 0.0:
				first = d
			last = d
		d += STEP
	# Cat de sus e arcul deasupra benzii, chiar pe ax. Se trage o raza in JOS
	# de la 30 m: prima piatra atinsa e intradosul.
	var gi := int(0.152 * float(n)) % n
	var gp := track.baked[gi]
	var down := PhysicsRayQueryParameters3D.create(
		gp + Vector3.UP * 30.0, gp + Vector3.UP * 1.0,
		Track.CAMERA_BLOCKER_LAYER)
	var dh := space.intersect_ray(down)
	if dh.is_empty():
		print("; NIMIC deasupra axei — poarta nu acopera banda")
	else:
		print("; intradosul arcului la %.2f m peste sosea (camera zboara la 10.0)" % [
			float(dh["position"].y) - gp.y])
	print("")
	print("=== camera prin poarta de hornuri gemene ===")
	print("  parcurs testat            %.1f m in jurul fractiei 0.152" % span)
	print("  lungime cu camera taiata  %.1f m (de la %.1f la %.1f)" % [
		clipped, first, last])
	print("  la %.0f m/s asta inseamna %.2f s" % [SPEED, clipped / SPEED])
	print("")
	var ok := clipped / SPEED < 1.0
	print("VERDICT: %s" % ("OK — clip sub 1 s" if ok else "PROBLEMA — clip peste 1 s"))
	get_tree().quit(0 if ok else 1)
