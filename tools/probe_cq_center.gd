extends Node
## Unde e CENTRUL asfaltului fata de nodul modulului? Scanam lateral in jurul
## nodului si gasim mijlocul portiunii de deck; diferenta fata de 0 e cat
## trebuie mutat nodul.
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 10:
		await get_tree().process_frame
	var space := get_viewport().world_3d.direct_space_state
	var span := track.find_child("PasajRotativ", false, false)
	var r := track.routes[0]
	var n := r.count()
	# 1. centrul deck-ului construit de modul, in spatiul modulului
	print("z_local | marginile DECK-ului modulului (x local)")
	for z: float in [-16.0, 16.0]:
		var lo := NAN
		var hi := NAN
		var x := -14.0
		while x <= 14.0:
			var wp: Vector3 = span.global_transform * Vector3(x, 0.0, z)
			var q := PhysicsRayQueryParameters3D.create(wp + Vector3.UP * 3.0, wp + Vector3.DOWN * 6.0)
			var h := space.intersect_ray(q)
			if not h.is_empty() and str(h.collider.name) in ["Deck", "Span"]:
				if is_nan(lo):
					lo = x
				hi = x
			x += 2.0
		if is_nan(lo):
			print("  %+6.1f | (nimic)" % z)
		else:
			print("  %+6.1f | de la %+6.2f la %+6.2f  -> centru %+6.2f" % [z, lo, hi, (lo + hi) * 0.5])
	# 2. unde e axa traseului fata de nodul modulului
	print()
	print("axa traseului fata de nod (x local pe cateva fractii):")
	var inv := span.global_transform.affine_inverse()
	for f: float in [0.470, 0.480, 0.4905, 0.500, 0.510]:
		var i := int(round(f * float(n))) % n
		var l: Vector3 = inv * r.baked[i]
		print("  frac %.4f -> local (x %+6.2f, y %+6.2f, z %+7.2f)" % [f, l.x, l.y, l.z])
	get_tree().quit()
