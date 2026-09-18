extends SceneTree
# Unde exista UMAR langa 0,33: cota solului la 3/5/8 m dincolo de muchie,
# pe ambele parti, pe toata vecinatatea. Cauta un loc pentru casa paznicului.
func _init() -> void:
	var tr = (load("res://scenes/tracks/Track15.tscn") as PackedScene).instantiate()
	get_root().add_child(tr)
	await process_frame
	await process_frame
	var n: int = tr.baked.size()
	var space := (tr as Node3D).get_world_3d().direct_space_state
	print("frac  | parte | sub sosea la 3m / 5m / 8m dincolo de muchie")
	var f := 0.290
	while f <= 0.370:
		var i := int(f * float(n)) % n
		var p: Vector3 = tr.baked[i]
		var s: Vector3 = tr._side_at(i)
		var half: float = tr.width_at_index(i)
		for sg in [-1.0, 1.0]:
			var vals := []
			for off in [3.0, 5.0, 8.0]:
				var q: Vector3 = p + s * sg * (half + off)
				var pr := PhysicsRayQueryParameters3D.create(
					q + Vector3(0, 400, 0), q - Vector3(0, 400, 0))
				var hit := space.intersect_ray(pr)
				vals.append("%7.2f" % ((hit["position"] as Vector3).y - p.y) if not hit.is_empty() else "     --")
			print("%.4f | %+.0f  | %s" % [f, sg, " ".join(vals)])
		f += 0.005
	quit(0)
