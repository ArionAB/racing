extends Node
## PUNCTUL 2 din raportul de la volan: "o LINIE ROSIE pe teren, fara scop".
##
## Ipoteza dezvoltatorului era o vizualizare de depanare lasata pornita. Am
## cautat: in tot `scenes/` si `scripts/` nu exista niciun `draw_line`, nicio
## `ImmediateMesh`, niciun `debug_draw` — deci ipoteza cade si trebuie aflat CE
## e obiectul.
##
## Sonda cauta candidatul dupa FORMA, nu dupa nume: orice mesh vizibil al carui
## AABB e lung pe o axa si subtire pe celelalte doua (raport > 20), sortat dupa
## lungime. O "linie" e exact asta si nimic altceva nu e.
##
##   godot --headless --path . res://tools/ProbeCappLinieRosie.tscn -- --track=6

const RAPORT_MIN: float = 20.0
const SUBTIRE_MAX: float = 1.2

func _ready() -> void:
	await get_tree().process_frame
	var idx := 6
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	var t := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 6: await get_tree().process_frame

	var found: Array = []
	_scan(t, t, found)
	found.sort_custom(func(a, b): return float(a["len"]) > float(b["len"]))
	print("=== GEOMETRIE LUNGA SI SUBTIRE (candidati de 'linie') ===")
	print("%d candidati" % found.size())
	for k in mini(found.size(), 25):
		var d: Dictionary = found[k]
		print("  %7.1f m lung x %.2f x %.2f | %s | centru (%.0f, %.0f, %.0f)"
			% [d["len"], d["a"], d["b"], d["path"],
			   d["c"].x, d["c"].y, d["c"].z])
	get_tree().quit(0)


func _scan(node: Node, root: Node, out: Array) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.is_visible_in_tree() and mi.mesh != null:
			var a := mi.get_aabb()
			var sc := mi.global_transform.basis.get_scale()
			var s := Vector3(a.size.x * absf(sc.x), a.size.y * absf(sc.y),
				a.size.z * absf(sc.z))
			var arr := [s.x, s.y, s.z]
			arr.sort()
			var lung: float = float(arr[2])
			var mij: float = float(arr[1])
			var mic: float = float(arr[0])
			if mij <= SUBTIRE_MAX and lung / maxf(mij, 0.001) >= RAPORT_MIN:
				out.append({
					"len": lung, "a": mij, "b": mic,
					"path": String(root.get_path_to(mi)),
					"c": mi.global_transform * a.get_center(),
				})
	for c in node.get_children():
		_scan(c, root, out)
