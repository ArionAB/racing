extends Node
## Ce se vede DIN CADRUL DE LIVRARE (frac 0.05, vederea soferului): pentru
## fiecare horn din frustum, distanta, inaltimea pe ecran, si daca are poala de
## grohotis. Sonda raspunde la intrebarea criticului "de ce nu vad taluz":
## poate ca nu e pus pe hornurile care se VAD, nu ca nu e pus deloc.
func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 6: await get_tree().process_frame
	var r = t.routes[0]
	var n: int = r.baked.size()
	var props: Array[Node3D] = []
	var stack: Array[Node] = [t]
	while not stack.is_empty():
		var nd: Node = stack.pop_back()
		for c in nd.get_children():
			stack.append(c)
		if nd is Node3D and (nd.name.to_lower().contains("horn") or nd.name.to_lower().contains("moloz")):
			props.append(nd as Node3D)
	var cam := Camera3D.new()
	cam.fov = 68.0
	cam.near = 0.05
	cam.far = 400.0
	add_child(cam)
	var i := int(0.05 * n)
	var p: Vector3 = r.baked[i]
	var a: Vector3 = r.baked[(i + 6) % n]
	var dir: Vector3 = (a - p).normalized()
	var eye: Vector3 = p - dir * 12.5 + Vector3.UP * 10.0
	cam.global_transform = Transform3D().looking_at(dir, Vector3.UP)
	cam.global_position = eye
	print("EYE ", eye, "  DIR ", dir)
	print("nume | dist | h_ecran_px | talus_spread | talus_rocks | strata_step")
	var cu := 0
	var fara := 0
	var lista: Array = []
	for pr in props:
		var b: Vector3 = pr.global_position
		if not cam.is_position_in_frustum(b):
			continue
		var d := eye.distance_to(b)
		if d > 160.0:
			continue
		# inaltimea in pixeli a unui obiect de 12 m la distanta d, ecran 720p
		var hpx := 12.0 / d * (720.0 / (2.0 * tan(deg_to_rad(34.0))))
		var ts: float = pr.get("talus_spread") if pr.get("talus_spread") != null else -1.0
		var tr = pr.get("talus_rocks")
		var ss = pr.get("strata_step")
		if ts > 0.0: cu += 1
		else: fara += 1
		lista.append([d, "%-18s | %6.1f | %6.0f | %5.2f | %s | %s" % [pr.name, d, hpx, ts, str(tr), str(ss)]])
	lista.sort_custom(func(x, y): return x[0] < y[0])
	for e in lista:
		print(e[1])
	print("--- in cadru la <160 m: %d cu poala, %d FARA" % [cu, fara])
	get_tree().quit(0)
