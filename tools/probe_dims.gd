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


## Grupurile care poarta un model GLB si o coliziune derivata din el.
const TAGS := {
	"landmarks": "landmark", "start_arch": "poarta", "dinos": "dino",
	"markers": "stalp", "hazards": "hazard", "hoses": "furtun",
}


func _dump(track: Node) -> void:
	# Agregam: sunt pana la 110 popice identice pe o pista, nu vrem 110 linii.
	var seen: Dictionary = {}
	var order: Array[String] = []
	for node in _walk(track):
		var body := node as PhysicsBody3D
		if body == null:
			continue
		var tag := ""
		for g: String in TAGS:
			if body.is_in_group(g):
				tag = TAGS[g]
				break
		if tag == "":
			# Nu tot ce poarta un model e intr-un grup — SlidingHazard, de
			# exemplu, nu se inregistreaza nicaieri. Cadem pe numele clasei ca
			# sa nu scape nimic din raport doar fiindca cineva a uitat un grup.
			tag = _class_tag(body)
		if tag == "":
			continue
		var model_name := _model_name(body)
		for c in body.get_children():
			var cs := c as CollisionShape3D
			if cs == null:
				continue
			var key := "%s|%s|%s|%.2f" % [tag, model_name, _describe(cs.shape),
				cs.position.y]
			if seen.has(key):
				seen[key] += 1
			else:
				seen[key] = 1
				order.append(key)
	for key in order:
		var parts := key.split("|")
		var count: int = seen[key]
		var mult := "" if count == 1 else "  x%d" % count
		print("  %-9s %-14s %-28s centru y=%5.2f%s" % [parts[0], parts[1],
			parts[2], float(parts[3]), mult])


## Numele clasei din script, taiat la latimea coloanei. Doar pentru corpurile
## care chiar poarta un model — un StaticBody procedural n-are ce cauta aici.
func _class_tag(body: Node) -> String:
	var script := body.get_script() as Script
	if script == null:
		return ""
	var name := script.get_global_name()
	if name == "":
		return ""
	if _model_name(body) == "?":
		return ""
	return String(name).to_lower().substr(0, 9)


func _model_name(body: Node) -> String:
	for c in body.get_children():
		if c is Node3D and not (c is CollisionShape3D):
			# Radacina GLB-ului poate fi invelita intr-un pivot (mingea).
			if c.get_child_count() == 1 and c.get_child(0) is Node3D \
					and not (c.get_child(0) is MeshInstance3D):
				return String(c.get_child(0).name)
			return String(c.name)
	return "?"


func _describe(shape: Shape3D) -> String:
	var box := shape as BoxShape3D
	var cyl := shape as CylinderShape3D
	var sph := shape as SphereShape3D
	if box != null:
		return "box %5.2f x %5.2f x %5.2f" % [box.size.x, box.size.y, box.size.z]
	if cyl != null:
		return "cyl r=%.2f h=%5.2f" % [cyl.radius, cyl.height]
	if sph != null:
		return "sfera r=%.2f" % sph.radius
	return str(shape)


func _walk(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for c in node.get_children():
		out.append_array(_walk(c))
	return out
