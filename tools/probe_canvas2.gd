extends SceneTree
## Gabaritele celorlalte piese de balon, ca panza aterizata sa fie inlocuita cu
## ceva de scara corecta si din acelasi kit (zero materiale noi).
func _initialize() -> void:
	for path in [
			"res://assets/models/cappadocia/props/balloon_envelope_a.glb",
			"res://assets/models/cappadocia/props/balloon_envelope_b.glb",
			"res://assets/models/cappadocia/props/balloon_envelope_c.glb",
			"res://assets/models/cappadocia/props/balloon_landed.glb",
			"res://assets/models/cappadocia/props/balloon_basket.glb"]:
		var scn := load(path) as PackedScene
		if scn == null:
			continue
		var n := scn.instantiate()
		var mis: Array[Node] = []
		_walk(n, mis)
		for m in mis:
			var mi := m as MeshInstance3D
			var ab := mi.mesh.get_aabb()
			print("%-26s %-22s gabarit %6.2f x %6.2f x %6.2f"
				% [path.get_file(), mi.name, ab.size.x, ab.size.y, ab.size.z])
	quit()


func _walk(n: Node, out: Array[Node]) -> void:
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		_walk(c, out)
