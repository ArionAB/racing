extends Node
## Sonda ad-hoc: de ce se opreste masina la frac ~0.85-0.87 pe Track16
## (kickerul Bowen), lovind static body #156? Dump baked road Y si raycast
## din sus in jos pe axa, la rezolutie fina, in jurul zonei.
const TRACK := "res://scenes/tracks/Track16.tscn"
var _t: Track

func _ready() -> void:
	await get_tree().process_frame
	_t = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_t)
	await get_tree().process_frame
	await get_tree().process_frame
	var n := _t.baked.size()
	print("baked road n=%d" % n)
	print("frac    idx   bakedY   width")
	var f := 0.82
	while f < 0.90:
		var i := int(round(f * float(n))) % n
		var bp: Vector3 = _t.baked[i]
		var w := _t.width_at_index(i)
		print("%.4f  %4d  %7.3f  %5.2f  pos=(%.1f,%.2f,%.1f)" % [f, i, bp.y, w, bp.x, bp.y, bp.z])
		f += 0.002
	# Raycast fizic din sus in jos la fiecare punct baked in interval.
	print("\n--- raycast fizic (de sus in jos) ---")
	var space := get_tree().root.get_world_3d().direct_space_state
	f = 0.82
	while f < 0.90:
		var i := int(round(f * float(n))) % n
		var bp: Vector3 = _t.baked[i]
		var from := bp + Vector3(0, 50, 0)
		var to := bp + Vector3(0, -50, 0)
		var q := PhysicsRayQueryParameters3D.create(from, to)
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			print("%.4f  NICIUN HIT  bakedY=%.2f" % [f, bp.y])
		else:
			var hy: float = hit.position.y
			var delta := hy - bp.y
			var flag := "  <-- DIFERA" if absf(delta) > 0.3 else ""
			print("%.4f  hitY=%7.3f  bakedY=%7.3f  delta=%+.3f  collider=%s%s" % [
				f, hy, bp.y, delta, str(hit.get("collider")), flag])
		f += 0.004
	print("\n--- noduri StaticBody3D/CollisionShape3D langa (-13, -0.4, 229), raza 40 m ---")
	var target := Vector3(-13, -0.4, 229)
	_dump_tree(_t, 0, target, 40.0)

	print("\n--- gasire TerrainBody si bounding-ul lui ---")
	_find_terrain(_t, 0)

	print("\n--- intersect_point la (-13, 0.6, 229) ---")
	var pshape := PhysicsPointQueryParameters3D.new()
	pshape.position = Vector3(-13, 0.6, 229)
	pshape.collide_with_areas = false
	pshape.collide_with_bodies = true
	var hits := space.intersect_point(pshape, 8)
	for h in hits:
		print("  hit: ", h)

	print("\n--- raycast pe X (lateral) la y=0.6, z=229, x de la -60 la 40 ---")
	var x := -60.0
	while x < 40.0:
		var from2 := Vector3(x, 60.0, 229.0)
		var to2 := Vector3(x, -60.0, 229.0)
		var q2 := PhysicsRayQueryParameters3D.create(from2, to2)
		var hit2 := space.intersect_ray(q2)
		if not hit2.is_empty():
			print("  x=%.1f hitY=%.2f collider=%s" % [x, hit2.position.y, str(hit2.get("collider"))])
		x += 2.0
	print("\n--- TOATE StaticBody3D din scena (nume + global_position) ---")
	_dump_all(_t, 0)

	print("\n--- ground_y direct din sampler ---")
	print("ground_y(-13, 229) = ", _t._sampler.ground_y(-13.0, 229.0))
	print("ground_y(-13, 200) = ", _t._sampler.ground_y(-13.0, 200.0))
	print("ground_y(-13, 260) = ", _t._sampler.ground_y(-13.0, 260.0))
	print("ground_y(0, 229) = ", _t._sampler.ground_y(0.0, 229.0))
	print("ground_y(-60, 229) = ", _t._sampler.ground_y(-60.0, 229.0))
	print("ground_y(60, 229) = ", _t._sampler.ground_y(60.0, 229.0))

	get_tree().quit(0)

func _dump_tree(n: Node, depth: int, target: Vector3, radius: float) -> void:
	if n is StaticBody3D:
		var gp := (n as Node3D).global_position
		if gp.distance_to(target) < radius:
			print("%s%s (%s) at %s  path=%s" % ["  ".repeat(depth), n.name,
				n.get_class(), gp, (n as Node).get_path()])
	for c in n.get_children():
		_dump_tree(c, depth + 1, target, radius)

func _dump_all(n: Node, depth: int) -> void:
	if n is StaticBody3D:
		var gp := (n as Node3D).global_position
		print("%s%s  global=%s  path=%s" % ["  ".repeat(depth), n.name, gp, (n as Node).get_path()])
	for c in n.get_children():
		_dump_all(c, depth + 1)

func _find_terrain(n: Node, depth: int) -> void:
	if n.name == "TerrainBody":
		print("gasit TerrainBody: ", (n as Node).get_path(), " global_pos=",
			(n as Node3D).global_position if n is Node3D else "?")
		for c in n.get_children():
			print("  copil: ", c.name, " (", c.get_class(), ")")
	for c in n.get_children():
		_find_terrain(c, depth + 1)
