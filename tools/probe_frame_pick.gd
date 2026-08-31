extends Node
## Alege CADRUL, nu lumea. Pentru fiecare frac: cate conuri intregi (baza SI varf)
## sunt in frustum, la ce distanta e cel mai apropiat obiect, si cat din latimea
## cadrului e ocupata de ceva. Un cadru bun are 3+ conuri intregi si nimic lipit
## de obiectiv.
func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 4: await get_tree().process_frame
	var r = t.routes[0]
	var n: int = r.baked.size()
	# aduna varfurile de con din DecorManual
	var props: Array[Node3D] = []
	var stack: Array[Node] = [t]
	while not stack.is_empty():
		var nd: Node = stack.pop_back()
		for c in nd.get_children():
			stack.append(c)
		if nd is Node3D and nd.name.to_lower().contains("horn"):
			props.append(nd as Node3D)
	print("prop-uri de tip horn gasite: %d" % props.size())
	var cam := Camera3D.new()
	cam.fov = 68.0
	cam.near = 0.05
	cam.far = 400.0
	add_child(cam)
	print("frac | conuri intregi in cadru | cel mai apropiat (m)")
	var f := 0.03
	while f < 0.20:
		var i := int(f * n)
		var p: Vector3 = r.baked[i]
		var a: Vector3 = r.baked[(i + 6) % n]
		var dir: Vector3 = (a - p).normalized()
		var eye: Vector3 = p - dir * 12.5 + Vector3.UP * 10.0
		cam.global_transform = Transform3D().looking_at(dir, Vector3.UP)
		cam.global_position = eye
		var whole := 0
		var nearest := 9999.0
		for pr in props:
			var b: Vector3 = pr.global_position
			var top: Vector3 = b + Vector3.UP * 14.0
			if cam.is_position_in_frustum(b) and cam.is_position_in_frustum(top):
				whole += 1
				nearest = minf(nearest, eye.distance_to(b))
		print("%.2f | %2d | %.1f" % [f, whole, nearest])
		f += 0.01
	get_tree().quit(0)
