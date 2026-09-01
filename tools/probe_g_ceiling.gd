extends Node
## Ce anume acopera cerul in cadrul de la 0.80 si 0.86 — pe NOD, nu pe cota.
##
## ProbeGSky spune CATE azimuturi sunt inchise. Nu spune CINE le inchide, si
## fara asta nu se stie ce se coboara. Sonda asta ia plafonul pe azimut si il
## atribuie nodului care il produce.
func _ready() -> void:
	var t := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	add_child(t)
	await get_tree().process_frame
	await get_tree().process_frame
	var axis := Vector2(-302.02, 6.0)
	var r := t.routes[0]
	var g := t.get_node_or_null("DecorManual/G) Stanca goala")
	for f: float in [0.80, 0.86, 0.92]:
		var i := int(f * float(r.baked.size())) % r.baked.size()
		var p: Vector3 = r.baked[i]
		var d := Vector2(p.x - axis.x, p.z - axis.y)
		var az0 := rad_to_deg(d.angle())
		# plafonul cadrului: camera vede in sus y + 10 + 0.093*dist
		print("")
		print("=== frac %.2f: masina y=%.1f, az=%.0f ===" % [f, p.y, az0])
		var best := {}
		var stack: Array = [g]
		while not stack.is_empty():
			var c: Node = stack.pop_back()
			for k in c.get_children():
				stack.append(k)
			var mi := c as MeshInstance3D
			if mi == null or mi.mesh == null or not mi.visible:
				continue
			var xf := mi.global_transform
			var owner_name := mi.name
			var pn := mi.get_parent()
			while pn != null and pn != g:
				owner_name = pn.name
				pn = pn.get_parent()
			for s2 in mi.mesh.get_surface_count():
				for v in mi.mesh.surface_get_arrays(s2)[Mesh.ARRAY_VERTEX] as PackedVector3Array:
					var w: Vector3 = xf * v
					var dd := Vector2(w.x - axis.x, w.z - axis.y)
					# doar felia din fata masinii (+-30 grade)
					var da := rad_to_deg(dd.angle()) - az0
					while da > 180.0: da -= 360.0
					while da < -180.0: da += 360.0
					if absf(da) > 30.0:
						continue
					var dist := (Vector2(w.x, w.z) - Vector2(p.x, p.z)).length()
					var ceiling := p.y + 10.0 + 0.093 * dist
					if w.y <= ceiling:
						continue
					# acest vertex e PESTE plafon: taie cerul
					if not best.has(owner_name):
						best[owner_name] = [0, -INF]
					best[owner_name][0] += 1
					best[owner_name][1] = maxf(best[owner_name][1], w.y - ceiling)
		var ks := best.keys()
		ks.sort()
		if ks.is_empty():
			print("    nimic peste plafon — cadrul are CER")
		for k in ks:
			print("    %-18s %5d vertecsi peste plafon, cel mai sus cu %+.1f m" % [
				k, best[k][0], best[k][1]])
	get_tree().quit()
