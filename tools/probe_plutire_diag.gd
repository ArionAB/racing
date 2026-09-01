extends Node
## DIAGNOSTIC (temporar, runda 29): pentru fiecare prop care pluteste, compara
## cota din `ground_y` (sursa folosita de generator la asezare) cu cota gasita de
## o raza in jos. Daca cele doua difera, vinovatul e campul de teren, nu instanta.

const ZBURATOARE := ["Pigeon", "Balloon", "Balon", "Cabina", "Porumbel"]

func _ready() -> void:
	call_deferred("_go")

func _go() -> void:
	var only := 13
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--track="):
			only = int(a.trim_prefix("--track="))
	var t := (load(GameState.TRACK_SCENES[only]) as PackedScene).instantiate()
	get_tree().root.add_child(t)
	for i in 12:
		await get_tree().process_frame
	var sampler: Variant = t._sampler
	print("sampler: %s" % ("null" if sampler == null else str(sampler)))
	var space: PhysicsDirectSpaceState3D = t.get_world_3d().direct_space_state
	var stack: Array[Node] = [t]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if not (n is MeshInstance3D):
			continue
		var mi := n as MeshInstance3D
		if not mi.visible or mi.mesh == null:
			continue
		var up: Node = n
		var inside := false
		while up != null:
			if str(up.name).begins_with("DecorManual"):
				inside = true
				break
			up = up.get_parent()
		if not inside:
			continue
		var nm := str(n.name)
		var skip := false
		for z in ZBURATOARE:
			if nm.contains(z):
				skip = true
		if skip:
			continue
		var aabb := mi.get_aabb()
		var base: Vector3 = mi.global_transform * (aabb.position + Vector3(
			aabb.size.x * 0.5, 0.0, aabb.size.z * 0.5))
		var q := PhysicsRayQueryParameters3D.create(
			base + Vector3.UP * 1.0, base + Vector3.DOWN * 400.0)
		var hit: Dictionary = space.intersect_ray(q)
		var sol := 9999.0
		if not hit.is_empty():
			sol = float(hit["position"].y)
		var gy := 9999.0
		if sampler != null:
			gy = float(sampler.call("ground_y", base.x, base.z))
		var gol := base.y - sol
		if gol > 4.0 or hit.is_empty():
			print("%s | baza=%.2f raza_sol=%.2f ground_y=%.2f | gol_raza=%.2f gol_gy=%.2f | xz=(%.1f,%.1f)" % [
				nm, base.y, sol, gy, gol, base.y - gy, base.x, base.z])
	get_tree().quit(0)
