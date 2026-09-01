extends Node
## Unde e panza falezei, in metri, fata de camera si fata de banda.
const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"

func _ready() -> void:
	var t := (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(t)
	await get_tree().process_frame
	await get_tree().physics_frame
	var mis: Array[Node] = []
	_walk(t, mis)
	print("=== MeshInstance care par faleza ===")
	for m in mis:
		var mi := m as MeshInstance3D
		var ab := mi.get_aabb()
		var g := mi.global_transform * ab.get_center()
		print("  %s  centru=(%.1f,%.1f,%.1f) marime=(%.1f,%.1f,%.1f) vizibil=%s"
			% [mi.name, g.x, g.y, g.z, ab.size.x, ab.size.y, ab.size.z, mi.visible])
	var s: TrackSideSampler = t.get("_sampler")
	var n := s.point_count()
	for f: float in [0.20, 0.28, 0.36]:
		var i := int(f * float(n)) % n
		var p := s.baked_point(i)
		var sd := s.side_at(i)
		print("banda frac %.2f: (%.1f,%.1f,%.1f) lateral=(%.2f,%.2f,%.2f)"
			% [f, p.x, p.y, p.z, sd.x, sd.y, sd.z])
	t.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)

func _walk(n: Node, out: Array[Node]) -> void:
	for c in n.get_children():
		if c is MeshInstance3D and (String(c.name).begins_with("Faleza")):
			out.append(c)
		_walk(c, out)
