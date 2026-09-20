extends Node
## Sonda ad-hoc: afla fractia markerului AVALANCHE de pe Track09 (Alpii), ca
## sa poata fi comparat cu numarul de repuneri raportat de ProbeRace pe felia
## corespunzatoare.
const TRACK := "res://scenes/tracks/Track09.tscn"
var _t: Track


func _ready() -> void:
	await get_tree().process_frame
	_t = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_t)
	await get_tree().process_frame
	await get_tree().process_frame
	for node in _t.get_tree().get_nodes_in_group(&"_none_"):
		pass
	_scan(_t)
	get_tree().quit(0)


func _scan(node: Node) -> void:
	for child in node.get_children():
		if child.get_class() == "Marker3D" and child.get("kind") == 8:
			var p: Vector3 = _t.to_local(child.global_position)
			var idx := _t._closest_baked_index(p) if _t.has_method("_closest_baked_index") else -1
			print("AVALANCHE marker '%s' global=%s local=%s idx=%d frac=%.4f" % [
				child.name, child.global_position, p, idx,
				(_t.frac_at(idx) if idx >= 0 else -1.0)])
		_scan(child)
