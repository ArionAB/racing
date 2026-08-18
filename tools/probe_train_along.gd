extends Node
## Sonda TRENULUI PE SENS (TrainHazard.along_road, Baikal).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeTrainAlong.tscn [-- --track=3]
##
## Ce verifica:
##   1. SE CONSTRUIESTE: pista are un tren cu along_road, cu sina de peste 60 m
##      (adica portiunea a fost destul de dreapta).
##   2. VINE DIN FATA: in timpul trecerii, trenul se deplaseaza IMPOTRIVA
##      sensului de mers al pistei (semnul verificat pe pozitii, nu pe baze).
##   3. STA PE AXA: pe toata trecerea, corpul trenului ramane la sub 1.5 m de
##      axa soselei — altfel „drumul deschis pe margini" e o minciuna.
##   4. AI-UL STIE: lane_bias_at e > 0 pe sector (si putin inainte), 0 in rest.

func _ready() -> void:
	await get_tree().process_frame
	var idx := 3
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = int(arg.trim_prefix("--track="))
	var scene := load(GameState.TRACK_SCENES[idx]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var failed := false
	print("\n=== ProbeTrainAlong — %s ===" % track.track_name)

	var train: TrainHazard = null
	for child in track.get_children():
		if child is TrainHazard and (child as TrainHazard).along_road:
			train = child
			break
	var ok1 := train != null and train.half_rail > 60.0
	failed = failed or not ok1
	print("1. constructie: tren pe sens %s, sina %.0f m  %s" % [
		train != null, train.half_rail if train else 0.0, "OK" if ok1 else "PROBLEMA"])
	if train == null:
		get_tree().quit(1)
		return

	# Directia drumului la origine si indexul de acolo.
	var n: int = track.baked.size()
	var i0: int = track.closest_index_global(train.global_position)
	var dir: Vector3 = (track.baked[(i0 + 1) % n] - track.baked[i0]).normalized()
	var body := train.get_node_or_null("Train") as Node3D
	if body == null:
		for c in train.get_children():
			if c is AnimatableBody3D:
				body = c
				break
	# Asteapta trecerea (dupa WARN), apoi masoara doua pozitii la 0.5 s.
	var moved := Vector3.ZERO
	var max_lat := 0.0
	var seen := false
	var p_prev := Vector3.ZERO
	for k in int(train.period * 60.0):
		await get_tree().physics_frame
		if body == null or not body.visible:
			continue
		var pos: Vector3 = body.global_position
		if seen:
			moved += pos - p_prev
			# Doar cat originea (coada garniturii) e in sectorul de sina: la
			# capete coada iese din portiunea dreapta si asta e normal.
			if absf((pos - train.global_position).dot(dir)) <= train.half_rail:
				var j: int = track.closest_index_global(pos)
				var lat: float = track.routes[0].lateral_distance(j, pos)
				max_lat = maxf(max_lat, lat)
		seen = true
		p_prev = pos
	var ok2 := seen and moved.dot(dir) < -20.0
	failed = failed or not ok2
	print("2. vine din fata: deplasare pe sens %.0f m (negativ = spre masini)  %s" % [
		moved.dot(dir), "OK" if ok2 else "PROBLEMA"])
	var ok3 := seen and max_lat < 2.0
	failed = failed or not ok3
	print("3. pe axa: abatere laterala maxima %.2f m  %s" % [max_lat, "OK" if ok3 else "PROBLEMA"])

	var f_center: float = track.frac_at(i0)
	var i_before: int = ((i0 - int(20.0 / (track._dists[n] / float(n)))) % n + n) % n
	var i_far: int = (i0 + n / 2) % n
	var b_center := track.lane_bias_at(i0)
	var b_before := track.lane_bias_at(i_before)
	var b_far := track.lane_bias_at(i_far)
	var ok4 := b_center > 0.5 and b_before > 0.5 and b_far == 0.0
	failed = failed or not ok4
	print("4. AI: bias la %.3f = %.2f, cu 20 m inainte = %.2f, la jumatate de tur = %.2f  %s" % [
		f_center, b_center, b_before, b_far, "OK" if ok4 else "PROBLEMA"])

	print("VERDICT: ", "OK" if not failed else "PROBLEME")
	get_tree().quit(1 if failed else 0)
