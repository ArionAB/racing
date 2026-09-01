extends Node
## Petele negre de pe TREPTE: se suprapun cutiile intre ele?
## Aceeasi cauza ca la grohotis (fete coplanare din acelasi mesh), dar aici e
## intre trepte vecine puse pe aceeasi felie de perete.
func _ready() -> void:
	await get_tree().process_frame
	var scene := load(GameState.TRACK_SCENES[6]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var st := track.get_node_or_null("DecorManual/D) Canionul rosu/Strate")
	var bs: Array = []
	for c in st.get_children():
		var mi := c as MeshInstance3D
		if mi == null: continue
		bs.append(mi.global_transform)
	var pairs := 0
	for i in bs.size():
		for j in range(i + 1, bs.size()):
			var a: Transform3D = bs[i]
			var b: Transform3D = bs[j]
			var d: float = a.origin.distance_to(b.origin)
			var ra: float = a.basis.x.length() * 0.5
			var rb: float = b.basis.x.length() * 0.5
			if d < (ra + rb) * 0.55:
				pairs += 1
	print("trepte=%d  perechi suprapuse=%d" % [bs.size(), pairs])
	get_tree().quit(0)
