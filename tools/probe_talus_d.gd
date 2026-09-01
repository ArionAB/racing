extends Node
## E conul de grohotis un CON, sau un brau?
##
## Verdictul spune ca poala citeste „ca un plint, nu ca o gramada" si cere ca
## ea sa INGROAPE imbinarea perete-sol. Doua lucruri se pot masura direct:
##   1. inaltimea grohotisului fata de teren, pe distanta de perete — un con
##      real e gros lipit de perete si se stinge afara;
##   2. daca talpa peretelui mai e DESCOPERITA: pentru felii in lungul
##      peretelui, exista bloc de grohotis in dreptul imbinarii?

func _ready() -> void:
	await get_tree().process_frame
	var scene := load(GameState.TRACK_SCENES[6]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var base := track.get_node_or_null("DecorManual/D) Canionul rosu")
	var groh := base.get_node_or_null("Grohotis")
	var faleza := base.get_node_or_null("Faleza")
	print("blocuri=", groh.get_child_count())
	# Vertecsii peretelui, pentru talpa.
	var wall: PackedVector3Array = PackedVector3Array()
	for mi in faleza.find_children("*", "MeshInstance3D", true, false):
		var mm := (mi as MeshInstance3D).mesh
		if mm == null: continue
		var xf := (mi as MeshInstance3D).global_transform
		for s in mm.get_surface_count():
			var arr := mm.surface_get_arrays(s)
			for v in (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				wall.append(xf * v)
	# Centrele si razele blocurilor.
	var blocks: Array = []
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
		blocks.append({"p": n3.global_transform.origin, "r": r})
	# Inaltimea peste teren, pe intervale de distanta fata de perete.
	var route := track.route_at(0)
	var pts := route.baked
	var n := pts.size()
	var buckets := {}
	for b in blocks:
		var p: Vector3 = b["p"]
		# distanta fata de cel mai apropiat vertex de perete, in plan
		var dmin := 1e9
		for wv in wall:
			var dx: float = p.x - wv.x
			var dz: float = p.z - wv.z
			var dd: float = dx * dx + dz * dz
			if dd < dmin:
				dmin = dd
		dmin = sqrt(dmin)
		var g: float = track._sampler.ground_y(p.x, p.z)
		var key: int = int(dmin / 3.0)
		if not buckets.has(key):
			buckets[key] = []
		buckets[key].append(p.y + b["r"] - g)
	var ks: Array = buckets.keys()
	ks.sort()
	print("--- inaltimea varfului peste teren, pe distanta de perete ---")
	for k in ks:
		var arr: Array = buckets[k]
		var s := 0.0
		for v in arr:
			s += v
		print("  %2d-%2d m de perete: n=%3d  varf mediu %+.2f m"
			% [int(k) * 3, int(k) * 3 + 3, arr.size(), s / float(arr.size())])
	# Talpa descoperita: pentru fiecare vertex de perete de la baza, exista
	# bloc in raza lui?
	var foot_open := 0
	var foot_cov := 0
	var i := 0
	for wv in wall:
		i += 1
		if i % 7 != 0:
			continue
		var g: float = track._sampler.ground_y(wv.x, wv.z)
		if absf(wv.y - g) > 1.2:
			continue
		var covered := false
		for b in blocks:
			var p: Vector3 = b["p"]
			var dx: float = p.x - wv.x
			var dz: float = p.z - wv.z
			if sqrt(dx * dx + dz * dz) < float(b["r"]) * 1.1:
				covered = true
				break
		if covered:
			foot_cov += 1
		else:
			foot_open += 1
	print("TALPA: acoperita=%d  descoperita=%d  (%.0f%% acoperita)"
		% [foot_cov, foot_open,
		100.0 * float(foot_cov) / maxf(1.0, float(foot_cov + foot_open))])
	get_tree().quit(0)
