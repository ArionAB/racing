extends Node
## Tuk-tuk-ul din kit (`tuktuk.glb`) montat pe `Car` prin `tuktuk.tres`:
## modelul e cel nou, rotile au fost gasite, botul priveste inainte si rotile
## ating solul dupa ce suspensia se aseaza. (Fizica nu depinde de mesh: raza
## de suspensie e clamp(raza_rotii, 0,22..0,42), iar vechiul ape_piaggio avea
## un singur nod `Ape_Wheels` la y=0 -> tot 0,22; de aceea ProbeJodTuk iese
## identic la bit — asta e verificarea VIZUALULUI.)
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeJodTukModel.tscn

func _ready() -> void:
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200, 1, 200)
	shape.shape = box
	ground.add_child(shape)
	add_child(ground)
	ground.global_position = Vector3(0, -0.5, 0)
	await get_tree().physics_frame
	var car := Car.new()
	add_child(car)
	car.global_position = Vector3(0, 0.6, 0)
	car.apply_data(load("res://scenes/cars/data/tuktuk.tres") as CarData)
	for i in 120:
		await get_tree().physics_frame
	var fail := false
	var model := car._visual.get_child(0) as Node3D
	print("model: %s" % model.scene_file_path)
	if not model.scene_file_path.ends_with("jodhpur/vehicles/tuktuk.glb"):
		print("  [FAIL] modelul nu e tuktuk.glb"); fail = true
	print("roti gasite: %d (fata %d), raza vizuala %.3f, raza suspensie %.3f" % [
		car._wheels_all.size(), car._wheels_front.size(), car._wheel_radius,
		car._susp_wheel_radius])
	if car._wheels_all.size() != 3 or car._wheels_front.size() != 1:
		print("  [FAIL] asteptat 3 roti, 1 in fata"); fail = true
	# Botul: roata din fata trebuie sa fie INAINTEA centrului, pe -Z-ul masinii.
	var fwd := -car.global_transform.basis.z
	var front := car._wheels_front[0].global_position - car.global_position
	print("roata din fata fata de centru, pe directia de mers: %+.2f m" % front.dot(fwd))
	if front.dot(fwd) <= 0.3:
		print("  [FAIL] roata din fata nu e in fata"); fail = true
	# Rotile pe sol: cel mai jos vertex al fiecarei roti, in lume.
	for w in car._wheels_all:
		var lo := INF
		for mi in _meshes(w):
			var xf := mi.global_transform
			var arr: Array = mi.mesh.surface_get_arrays(0)
			for v: Vector3 in arr[Mesh.ARRAY_VERTEX]:
				lo = minf(lo, (xf * v).y)
		print("  %-14s talpa la y = %+.3f m (solul e 0)" % [w.name, lo])
		if absf(lo) > 0.08:
			print("  [FAIL] roata nu atinge solul (toleranta 8 cm)"); fail = true
	print("caroserie in picioare: %s, viteza %.2f m/s" % [
		car.global_transform.basis.y.dot(Vector3.UP) > 0.95, car.linear_velocity.length()])
	print("REZULTAT: %s" % ("PICAT" if fail else "TRECUT"))
	get_tree().quit(1 if fail else 0)

func _meshes(n: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	var st: Array[Node] = [n]
	while not st.is_empty():
		var c: Node = st.pop_back()
		for k in c.get_children(): st.append(k)
		if c is MeshInstance3D and (c as MeshInstance3D).mesh != null:
			out.append(c as MeshInstance3D)
	return out
