extends Node
## Unde e hero-ul in CADRU, la fiecare fractie de captura. Raspunde la
## intrebarea pe care capturile o pun dar nu o masoara: „la 0.30 hero-ul e in
## fata sau in spate?".
const TRACK := "res://scenes/tracks/Track12.tscn"

func _ready() -> void:
	await get_tree().process_frame
	var track := (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	for i in 6:
		await get_tree().physics_frame
	var dm := track.get_node_or_null(NodePath("DecorManual"))
	var targets := {}
	var stack: Array = [dm]
	while not stack.is_empty():
		var x = stack.pop_back()
		for c in x.get_children(): stack.append(c)
		var n3 := x as Node3D
		if n3 != null and (n3.name.begins_with("hongya_hero")
				or n3.name.begins_with("bloc_sub_piata")
				or n3.name.begins_with("bloc_contrafort")):
			targets[String(n3.name)] = n3.global_position
	var baked: PackedVector3Array = track.baked
	var n := baked.size()
	print("frac | obiect | dist | unghi_fata_de_directie_deg (0=drept in fata) | dy_fata_de_drum")
	for f: float in [0.005, 0.010, 0.020, 0.030, 0.26, 0.27, 0.28, 0.30, 0.32, 0.36, 0.40]:
		var idx := int(f * float(n)) % n
		var here: Vector3 = baked[idx]
		var fw: Vector3 = baked[(idx + 4) % n] - baked[(idx - 4 + n) % n]
		fw.y = 0.0
		fw = fw.normalized()
		for k: String in targets:
			var t: Vector3 = targets[k]
			var d := t - here
			var flat := Vector3(d.x, 0.0, d.z)
			if flat.length() > 320.0: continue
			var ang := rad_to_deg(acos(clampf(fw.dot(flat.normalized()), -1.0, 1.0)))
			var sgn := signf(fw.cross(flat).y)
			print("%.3f | %-22s | %6.1f m | %+7.1f | dy=%+6.1f"
				% [f, k, flat.length(), ang * sgn, d.y])
	get_tree().quit(0)
