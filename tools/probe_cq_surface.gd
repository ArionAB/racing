extends Node
## Cota SUPRAFETEI pe care se conduce, pe axa traseului, in jurul lui 0.655.
## Centrul curbei nu e carosabilul: pe viaduct suprafata e deasupra.
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 10:
		await get_tree().process_frame
	var space := get_viewport().world_3d.direct_space_state
	var span := track.find_child("PasajRotativ", false, false)
	# stingem modulul ca sa masuram SOSEAUA, nu placa lui
	span.visible = false
	for c in span.get_children():
		if c is CollisionObject3D:
			(c as CollisionObject3D).process_mode = Node.PROCESS_MODE_DISABLED
	var r := track.routes[0]
	var n := r.count()
	print("frac  | centru curbei y | suprafata lovita | delta | ce e")
	for f: float in [0.630, 0.635, 0.640, 0.645, 0.650, 0.655, 0.660, 0.665, 0.670, 0.675, 0.680]:
		var i := int(round(f * float(n))) % n
		var c: Vector3 = r.baked[i]
		var q := PhysicsRayQueryParameters3D.create(c + Vector3.UP * 30.0, c + Vector3.DOWN * 40.0)
		var h := space.intersect_ray(q)
		if h.is_empty():
			print("%.3f | %8.2f |      ---" % [f, c.y])
		else:
			print("%.3f | %8.2f | %8.2f | %+6.2f | %s" % [
				f, c.y, h.position.y, h.position.y - c.y, h.collider.name])
	get_tree().quit()
