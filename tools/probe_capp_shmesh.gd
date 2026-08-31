extends Node
## Unde e de fapt geometria corpului `Shoulders` in zona elicei? Se citesc
## VERTECSII mesh-ului de umeri si se raporteaza cei din cilindrul stancii
## (r < 40 m fata de axa) — pe intervale de inaltime.
const CX: float = -302.0
const CZ: float = 6.0


func _ready() -> void:
	await get_tree().process_frame
	var idx := GameState.resolve_track_index(6)
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene) \
		.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame

	for child in track.get_children():
		if not (child is StaticBody3D) or String(child.name) != "Shoulders":
			continue
		var cs := (child as StaticBody3D).get_child(0) as CollisionShape3D
		var tri := cs.shape as ConcavePolygonShape3D
		var pts := tri.get_faces()
		var buckets := {}
		var total := 0
		for p in pts:
			var rad := Vector2(p.x - CX, p.z - CZ).length()
			if rad > 40.0:
				continue
			total += 1
			var b := int(floor(p.y / 5.0)) * 5
			buckets[b] = int(buckets.get(b, 0)) + 1
		print("=== corp Shoulders: %d vertecsi in cilindrul stancii (r<40) ==="
			% total)
		var keys := buckets.keys()
		keys.sort()
		for k in keys:
			print("   y %3d..%3d : %d" % [k, k + 5, buckets[k]])
	get_tree().quit(0)
