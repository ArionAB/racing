extends Node
## Sonda PLACII DE GHEATA LIBERE (IceSlabHazard, Baikal).
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeIceSlab.tscn [-- --track=3]
##
## Ce verifica:
##   1. SE CONSTRUIESTE: pista are placi (din `custom_ice_slab_fracs` sau din
##      noduri HazardMarker cu kind ICE_SLAB) si fiecare are corpul + zona.
##   2. SEMNUL BASCULARII: o masina parcata pe capatul din FATA (in sensul de
##      mers) coboara capatul ala — unghi pozitiv, iar coltul din fata al placii
##      chiar ajunge mai jos decat cel din spate. Semnele de rotatie se
##      verifica pe geometrie, nu se ghicesc.
##   3. REVINE: masina luata, placa se aseaza inapoi la orizontala in < 2 s.
##   4. SE TRECE: o masina lansata la 30 m/s peste placa iese pe partea
##      cealalta cu viteza (nu se infige in muchie, nu ramane pe ea).

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
	print("\n=== ProbeIceSlab — %s ===" % track.track_name)

	var slabs: Array[IceSlabHazard] = []
	for child in track.get_children():
		if child is IceSlabHazard:
			slabs.append(child)
	var ok1 := not slabs.is_empty()
	for s in slabs:
		ok1 = ok1 and s.get_node_or_null("Plate") != null \
			and s.get_node_or_null("Load") != null
	failed = failed or not ok1
	print("1. constructie: %d placi, corp+zona pe fiecare  %s" % [
		slabs.size(), "OK" if ok1 else "PROBLEMA"])
	if slabs.is_empty():
		get_tree().quit(1)
		return

	var slab := slabs[0]
	var car_scene: PackedScene = load("res://scenes/cars/Car.tscn")
	var car: Car = car_scene.instantiate()
	track.add_child(car)
	car.track = track
	await get_tree().process_frame

	# 2. parcata pe capatul din fata: -Z local, la 5 m de mijloc
	var front := slab.to_global(Vector3(0.0, 0.8, -5.0))
	car.global_transform = Transform3D(slab.global_transform.basis, front)
	car.velocity = Vector3.ZERO
	car.freeze = true
	for k in 90:
		await get_tree().physics_frame
	var tilt := slab.tilt_deg()
	var plate := slab.get_node("Plate") as Node3D
	var y_front := plate.to_global(Vector3(0, 0, -IceSlabHazard.LENGTH * 0.5)).y
	var y_back := plate.to_global(Vector3(0, 0, IceSlabHazard.LENGTH * 0.5)).y
	var ok2 := tilt > 2.0 and y_front < y_back - 0.2
	failed = failed or not ok2
	print("2. incarcata in fata: unghi %.1f grade, colt fata y %.2f, colt spate y %.2f  %s" % [
		tilt, y_front, y_back, "OK" if ok2 else "PROBLEMA"])

	# 3. luata de pe placa
	car.global_position = slab.to_global(Vector3(0.0, 0.8, 60.0))
	for k in 120:
		await get_tree().physics_frame
	var rest := absf(slab.tilt_deg())
	var ok3 := rest < 0.3
	failed = failed or not ok3
	print("3. descarcata dupa 2 s: |unghi| %.2f grade  %s" % [rest, "OK" if ok3 else "PROBLEMA"])

	# 4. traversare la 30 m/s
	car.freeze = false
	var dir: Vector3 = -slab.global_transform.basis.z
	var start := slab.to_global(Vector3(0.0, 0.6, 30.0))
	car.global_transform = Transform3D(slab.global_transform.basis, start)
	car.velocity = dir * 30.0
	car.angular_velocity = Vector3.ZERO
	car.race_active = true
	car.controller = _Straight.new()
	var min_speed := INF
	var max_tilt := 0.0
	for k in int(2.2 * 60.0):
		await get_tree().physics_frame
		min_speed = minf(min_speed, car.velocity.length())
		max_tilt = maxf(max_tilt, absf(slab.tilt_deg()))
	var passed := slab.to_local(car.global_position).z < -IceSlabHazard.LENGTH
	var ok4 := passed and min_speed > 18.0 and max_tilt > 1.0
	failed = failed or not ok4
	print("4. traversare: a trecut=%s, viteza minima %.1f m/s, inclinare maxima %.1f grade  %s" % [
		passed, min_speed, max_tilt, "OK" if ok4 else "PROBLEMA"])

	print("VERDICT: ", "OK" if not failed else "PROBLEME")
	get_tree().quit(1 if failed else 0)


class _Straight extends CarController:
	func get_steer() -> float:
		return 0.0
	func get_throttle() -> float:
		return 1.0
