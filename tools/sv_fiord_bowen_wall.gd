extends Node
## Sonda ad-hoc: care PARTE a rapei 2 (KickerBowen, custom_ravines index 2 =
## Vector4(0.84, 0.902, 6, -1)) e PERETELE de stanca (cota mare pe lateral,
## urca) vs bazinul de cadere (cota joasa, apa). Raycast fizic din sus in jos
## la +/-lateral fata de axa (nu `_terrain_mesh_y`, care extrapoleaza —
## memoria terrain-mesh-y-extrapoleaza), folosind `route.side_at(i)` ca
## directie laterala CANONICA (acelasi vector pe care il foloseste
## sv_fiord_kicker.gd cu `off` pozitiv) — nu ghicesc semnul (memoria
## rotatii-in-builder-semnul / tscn-transform-e-pe-randuri).
##
##   godot --headless --path . --script res://tools/sv_fiord_bowen_wall.gd -- --scene=16

const TRACK := "res://scenes/tracks/Track16.tscn"
var _t: Track

func _ready() -> void:
	await get_tree().process_frame
	_t = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_t)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var route := _t.routes[0]
	var n := _t.baked.size()
	print("baked n=%d" % n)

	if _t.has_node("Hazarduri/KickerBowen"):
		var kb := _t.get_node("Hazarduri/KickerBowen") as Node3D
		var idxk := _t.closest_index_global(kb.global_position)
		print("KickerBowen global_position=%s closest_idx=%d frac=%.4f baked=%s"
			% [kb.global_position, idxk, _t.frac_at(idxk), _t.baked[idxk]])

	var space := get_tree().root.get_world_3d().direct_space_state
	var fracs := [0.835, 0.845, 0.858, 0.87, 0.885, 0.90]
	for f in fracs:
		var i := int(round(float(f) * float(n))) % n
		var bp: Vector3 = _t.baked[i]
		var i0 := route.wrap_index(i - 4)
		var i1 := route.wrap_index(i + 4)
		var fwd: Vector3 = (_t.baked[i1] - _t.baked[i0]).normalized()
		var side: Vector3 = route.side_at(i)
		var hw: float = _t.width_at_index(i)
		print("\nfrac=%.4f idx=%d road=(%.1f,%.2f,%.1f) fwd=(%.2f,_,%.2f) side(+off)=(%.2f,_,%.2f) hw=%.2f"
			% [f, i, bp.x, bp.y, bp.z, fwd.x, fwd.z, side.x, side.z, hw])
		for lat in [4.0, 8.0, 12.0, 20.0, 30.0, 45.0, 60.0]:
			for sgn in [1.0, -1.0]:
				var wp: Vector3 = bp + side * (lat * sgn)
				var from := wp + Vector3(0, 100, 0)
				var to := wp + Vector3(0, -100, 0)
				var q := PhysicsRayQueryParameters3D.create(from, to)
				var hit := space.intersect_ray(q)
				if hit.is_empty():
					print("  off=%+6.1f (sgn=%+.0f) world=(%.1f,%.1f)  NICIUN HIT" % [lat * sgn, sgn, wp.x, wp.z])
				else:
					var hy: float = hit.position.y
					print("  off=%+6.1f (sgn=%+.0f) world=(%.1f,%.1f)  hitY=%7.2f  dy_vs_road=%+7.2f"
						% [lat * sgn, sgn, wp.x, wp.z, hy, hy - bp.y])
	get_tree().quit(0)
