extends Node
## Cine sunt mesh-urile anonime din cadrul hero (POI E, frac 0.40)?
## ProbeMasca le raporteaza ca @MeshInstance3D@NNN — asta scrie CALEA lor in
## scena, AABB-ul si materialul, ca sa stim ce parghie le atinge.

func _ready() -> void:
	await get_tree().process_frame
	var only := GameState.resolve_track_index(7)
	var scene := load(GameState.TRACK_SCENES[only]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var all: Array[MeshInstance3D] = []
	_collect(track, all)
	var rows: Array = []
	for mi in all:
		var ab := mi.get_aabb()
		var g := mi.global_transform * ab.get_center()
		var sz := ab.size * mi.global_transform.basis.get_scale()
		rows.append({"n": mi.name, "p": str(track.get_path_to(mi)), "c": g, "s": sz,
			"a": sz.x * sz.z})
	rows.sort_custom(func(x, y): return float(x["a"]) > float(y["a"]))
	print("--- cele mai mari 14 mesh-uri (arie XZ) ---")
	for rr in rows.slice(0, 14):
		print("  %8.0f m2  centru(%.0f,%.1f,%.0f) dim(%.0fx%.0fx%.0f)  %s"
			% [rr["a"], rr["c"].x, rr["c"].y, rr["c"].z,
			rr["s"].x, rr["s"].y, rr["s"].z, rr["p"]])
	get_tree().quit(0)

func _collect(node: Node, out: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D and (node as MeshInstance3D).visible \
			and (node as MeshInstance3D).mesh != null:
		out.append(node as MeshInstance3D)
	for c in node.get_children():
		if c is Node3D and not (c as Node3D).visible:
			continue
		_collect(c, out)
