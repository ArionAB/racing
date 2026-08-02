extends SceneTree
## Tipareste cotele de coliziune ale prop-urilor mari (landmark-uri, poarta de
## start, dinozaur), ca sa se vada ce forma a iesit din AABB-ul modelului.
##
## De ce exista: cotele astea erau scrise de mana intr-un tabel si doua din ele
## erau deja gresite fata de geometrie — benzinaria declarata 6.0 pe Z cand
## modelul are 6.58, moara 9.0 cand turnul are 10.95. Nimic nu le verifica.
## Acum se citesc din AABB, iar sonda asta e cum arati ca s-a intamplat.
##
## De rulat dupa fiecare asset nou integrat: daca un GLB vine cu alte cote,
## coliziunea trebuie sa le urmeze singura. Daca nu le urmeaza, ai gasit inca un
## numar hardcodat.
##
##   godot --headless --path . --script res://tools/probe_dims.gd
##   godot --headless --path . --script res://tools/probe_dims.gd -- --track=2

var _paths: Array[String] = []
var _index: int = 0
var _track: Node = null
var _frames: int = 0


func _initialize() -> void:
	var only := -1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			only = int(arg.trim_prefix("--track="))
	for i in range(1, 10):
		var path := "res://scenes/tracks/Track%02d.tscn" % i
		if not ResourceLoader.exists(path):
			continue
		if only < 0 or only == i:
			_paths.append(path)
	if _paths.is_empty():
		push_error("probe_dims: nu am gasit nicio pista")
		quit(1)


func _process(_delta: float) -> bool:
	if _track == null:
		if _index >= _paths.size():
			return true
		_track = (load(_paths[_index]) as PackedScene).instantiate()
		root.add_child(_track)
		_frames = 0
		return false
	_frames += 1
	if _frames < 3:
		return false # lasam rebuild() sa termine
	print("=== ", _track.name, " — cote de coliziune ===")
	_dump(_track)
	root.remove_child(_track)
	_track.free()
	_track = null
	_index += 1
	return false


func _dump(track: Node) -> void:
	for node in _walk(track):
		var body := node as StaticBody3D
		if body == null:
			continue
		var tag := ""
		if body.is_in_group("landmarks"):
			tag = "landmark"
		elif body.is_in_group("start_arch"):
			tag = "poarta"
		elif body.is_in_group("dinos"):
			tag = "dino"
		if tag == "":
			continue
		var model_name := "?"
		for c in body.get_children():
			if c is Node3D and not (c is CollisionShape3D):
				model_name = String(c.name)
				break
		for c in body.get_children():
			var cs := c as CollisionShape3D
			if cs == null:
				continue
			var desc := "?"
			var box := cs.shape as BoxShape3D
			var cyl := cs.shape as CylinderShape3D
			if box != null:
				desc = "box %5.2f x %5.2f x %5.2f" % [box.size.x, box.size.y,
					box.size.z]
			elif cyl != null:
				desc = "cyl r=%.2f h=%5.2f" % [cyl.radius, cyl.height]
			print("  %-9s %-14s %-28s centru y=%5.2f" % [tag, model_name, desc,
				cs.position.y])


func _walk(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for c in node.get_children():
		out.append_array(_walk(c))
	return out
