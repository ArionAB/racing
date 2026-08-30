extends Node
## Politele exista ca CORPURI, nu doar ca desen? Si sunt la <= 9.4 m de ax, cu
## coloana libera deasupra? Astea sunt cele doua cifre din
## cappadocia_geometrie.md care decid daca hazardul-semnatura e posibil.
const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"

func _ready() -> void:
	var t := (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(t)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	var s: TrackSideSampler = t.get("_sampler")
	var n: int = s.point_count()
	var bodies: Array[Node] = []
	_walk(t, bodies)
	print("polite (corpuri fizice) gasite: ", bodies.size())
	var space := get_viewport().world_3d.direct_space_state
	# Baloanele nu-si blocheaza propria coloana: se scot din raze, altfel
	# masuram cosul care tocmai urca pe ea.
	var excl: Array[RID] = []
	_collect_hazard_rids(t, excl)
	for b in bodies:
		var sb := b as StaticBody3D
		var pos := sb.global_position
		# cel mai apropiat punct de ax
		var best := 0
		var bd := INF
		for i in n:
			var d: float = s.baked_point(i).distance_squared_to(pos)
			if d < bd:
				bd = d
				best = i
		var p := s.baked_point(best)
		var off := Vector2(pos.x - p.x, pos.z - p.z).length()
		var lane_y := p.y
		print("  %s: la %.2f m de ax (prag 9.40), cota %.2f, banda %.2f  =>  cursa %.1f m"
			% [sb.name, off, pos.y, lane_y, lane_y - pos.y])
		# coloana libera deasupra politei, pe colturile cosului de 4.8 m
		var sd := s.side_at(best)
		var blocked := INF
		for lat: float in [-2.4, 0.0, 2.4]:
			var c := pos + sd * lat
			for k in int(lane_y - pos.y) + 2:
				var y := pos.y + 1.2 + float(k)
				var q := PhysicsRayQueryParameters3D.create(
					Vector3(c.x, y + 0.5, c.z), Vector3(c.x, y - 0.5, c.z))
				var ex := excl.duplicate()
				ex.append(sb.get_rid())
				q.exclude = ex
				var hit := space.intersect_ray(q)
				if not hit.is_empty() and y < blocked:
					blocked = y
					print("       obstacol la y=%.2f lat=%.1f: %s" % [y, lat, (hit["collider"] as Node).name])
		if blocked == INF:
			print("     coloana LIBERA pe toata cursa  [OK]")
		else:
			print("     coloana se infunda la y=%.2f  [PICAT]" % blocked)
	t.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)

func _collect_hazard_rids(n: Node, out: Array[RID]) -> void:
	for c in n.get_children():
		if c is PhysicsBody3D and not String(c.name).begins_with("Polita"):
			var nm := String(c.name)
			if nm != "TerrainBody":
				out.append((c as PhysicsBody3D).get_rid())
		_collect_hazard_rids(c, out)


func _walk(n: Node, out: Array[Node]) -> void:
	for c in n.get_children():
		if c is StaticBody3D and String(c.name).begins_with("Polita"):
			out.append(c)
		_walk(c, out)
