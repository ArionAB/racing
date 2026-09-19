extends Node
## Cata faleza mai e la poarta, si unde e ULTIMUL punct cu perete real.
## Masoara pe AMBELE parti, la mai multe cote laterale, cu raycast filtrat.
func _ready() -> void:
	var ps := load("res://scenes/tracks/Track15.tscn") as PackedScene
	var t := ps.instantiate()
	add_child(t)
	await get_tree().process_frame
	var tr := t as Track
	var n := tr.baked.size()
	var space := get_viewport().world_3d.direct_space_state
	var rid := RID()
	for c in tr.get_children():
		if str(c.name) == "TerrainBody":
			rid = (c as StaticBody3D).get_rid()
	print("frac   half | perete(-X): +10  +18  +25  +35 | gol(+X): +10  +18  +25")
	var ff := 0.9200
	while ff <= 0.9860:
		var i := int(ff * float(n)) % n
		var p: Vector3 = tr.baked[i]
		var s: Vector3 = tr._side_at(i)
		var line := "%.4f %4.2f |" % [ff, tr.width_at_index(i)]
		for spec in [[-1.0, 10.0], [-1.0, 18.0], [-1.0, 25.0], [-1.0, 35.0],
				[1.0, 10.0], [1.0, 18.0], [1.0, 25.0]]:
			var q: Vector3 = p + s * (float(spec[0]) * float(spec[1]))
			var par := PhysicsRayQueryParameters3D.create(
				Vector3(q.x, p.y + 500.0, q.z), Vector3(q.x, p.y - 500.0, q.z))
			var hit := space.intersect_ray(par)
			var g := 8888.0
			var guard := 0
			while not hit.is_empty() and hit["rid"] != rid and guard < 24:
				par.exclude = par.exclude + [hit["rid"]]
				hit = space.intersect_ray(par)
				guard += 1
			if not hit.is_empty() and hit["rid"] == rid:
				g = hit.position.y - p.y
			line += " %5.1f" % g
			if spec[1] == 35.0:
				line += " |"
		print(line)
		ff += 0.0040
	get_tree().quit()
