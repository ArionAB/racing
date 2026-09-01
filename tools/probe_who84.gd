extends Node
## Cine e `@StaticBody3D@84`: parintii lui, si ce forma are.
const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"

func _ready() -> void:
	var t := (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(t)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	var bodies: Array[Node] = []
	_walk(t, bodies)
	for b in bodies:
		var sb := b as StaticBody3D
		if not String(sb.name).begins_with("@StaticBody3D@"):
			continue
		var chain := ""
		var cur: Node = sb
		while cur != null and cur != t:
			chain = String(cur.name) + "/" + chain
			cur = cur.get_parent()
		var sh := ""
		for c in sb.get_children():
			if c is CollisionShape3D:
				var s := (c as CollisionShape3D).shape
				sh += "%s " % s.get_class()
				if s is ConcavePolygonShape3D:
					sh += "(%d fete) " % ((s as ConcavePolygonShape3D).get_faces().size() / 3)
				if s is BoxShape3D:
					sh += "%v " % (s as BoxShape3D).size
		var g := sb.global_position
		print("  %s\n     pozitie=(%.1f,%.1f,%.1f)  layer=%d  forme: %s"
			% [chain, g.x, g.y, g.z, sb.collision_layer, sh])
	t.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)

func _walk(n: Node, out: Array[Node]) -> void:
	for c in n.get_children():
		if c is StaticBody3D:
			out.append(c)
		_walk(c, out)
