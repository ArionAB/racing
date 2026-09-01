extends Node
## Cate perechi de blocuri de grohotis se intrepatrund ADANC.
##
## Petele negre de pe poala sunt z-fighting: blocurile sunt acelasi mesh, iar
## cand doua ajung la scari apropiate si se suprapun, au fete COPLANARE care se
## bat pe adancime. Nota din generatorul vechi spunea 69 din 93; dupa marire si
## indesire trebuie remasurat, ca sa se stie daca reparatia e in scari sau in
## numar.

func _ready() -> void:
	await get_tree().process_frame
	var scene := load(GameState.TRACK_SCENES[6]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var groh := track.get_node_or_null(
		"DecorManual/D) Canionul rosu/Grohotis")
	var bs: Array = []
	for b in groh.get_children():
		var n3 := b as Node3D
		if n3 == null: continue
		var r := 0.0
		for mi in n3.find_children("*", "MeshInstance3D", true, false):
			var mm := (mi as MeshInstance3D).mesh
			if mm == null: continue
			var ab := mm.get_aabb()
			var sc := (mi as MeshInstance3D).global_transform.basis.get_scale()
			r = maxf(r, maxf(ab.size.x * sc.x, ab.size.z * sc.z) * 0.5)
		bs.append({"p": n3.global_transform.origin, "r": r})
	var deep := 0
	var close_scale := 0
	for i in bs.size():
		for j in range(i + 1, bs.size()):
			var a: Dictionary = bs[i]
			var b2: Dictionary = bs[j]
			var d: float = (a["p"] as Vector3).distance_to(b2["p"] as Vector3)
			var rr: float = float(a["r"]) + float(b2["r"])
			# suprapunere de peste 35% din suma razelor = intrepatrundere adanca
			if d < rr * 0.65:
				deep += 1
				var ra: float = float(a["r"])
				var rb: float = float(b2["r"])
				if absf(ra - rb) / maxf(0.01, maxf(ra, rb)) < 0.15:
					close_scale += 1
	print("blocuri=%d  perechi intrepatrunse adanc=%d  dintre ele cu scari apropiate=%d"
		% [bs.size(), deep, close_scale])
	get_tree().quit(0)
