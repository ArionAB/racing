extends Node
## CARE indice de traseu a produs peretele de umeri de la (-276.6, 19..22, 18.1)?
## Se reface calculul din _build_shoulders pentru fiecare i si se cauta cel al
## carui patrulater de umar contine punctul, in XZ.
const TARGET := Vector2(-276.6, 18.1)


func _ready() -> void:
	await get_tree().process_frame
	var idx := GameState.resolve_track_index(6)
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene) \
		.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	var r: TrackRoute = track.routes[0]
	var n := r.baked.size()
	print("indicii al caror umar acopera punctul, in XZ:")
	for i in n:
		var p: Vector3 = r.baked[i]
		if Vector2(p.x, p.z).distance_to(TARGET) > 12.0:
			continue
		var f := r.frac_at(i)
		var over := track._overpass_mix(i) > 0.5
		var wl: float = track._shoulder_width(i, -1.0)
		var wr: float = track._shoulder_width(i, 1.0)
		print("  i=%4d f=%.4f  y=%6.2f  dXZ=%5.2f  over=%s  wl=%.2f wr=%.2f"
			% [i, f, p.y, Vector2(p.x, p.z).distance_to(TARGET),
			"DA" if over else "nu", wl, wr])
	get_tree().quit(0)
