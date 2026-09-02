extends Node
## Treptele "in aer": care dintre ele NU are perete imediat in spatele ei.
##
## Pe captura ramane o placa pe cer. O treapta e legitima doar daca se INFIGE
## in roca: cutia intra 1.4 m in perete, deci in spatele fetei ei trebuie sa
## existe vertecsi de perete la mai putin de ~2 m. Daca nu exista, treapta a
## fost ancorata pe o felie unde peretele e in alta parte si pluteste.

func _ready() -> void:
	await get_tree().process_frame
	var scene := load(GameState.TRACK_SCENES[6]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var base := track.get_node_or_null("DecorManual/D) Canionul rosu")
	var strate := base.get_node_or_null("Strate")
	var faleza := base.get_node_or_null("Faleza")
	var verts: PackedVector3Array = PackedVector3Array()
	for mi in faleza.find_children("*", "MeshInstance3D", true, false):
		var mm := (mi as MeshInstance3D).mesh
		if mm == null: continue
		var xf := (mi as MeshInstance3D).global_transform
		for s in mm.get_surface_count():
			var arr := mm.surface_get_arrays(s)
			for v in (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				verts.append(xf * v)
	var air := 0
	var ok := 0
	for t in strate.get_children():
		var mi := t as MeshInstance3D
		if mi == null: continue
		# Se masoara din SPATELE cutiei, nu din centru. Cutia are acum 2.2+outw
		# adancime (consola s-a scalat la perete), deci centrul ei sta legitim
		# la 2+ m in fata rocii; un prag pe centru ar raporta „in aer" trepte
		# perfect infipte. Spatele trebuie sa fie IN roca.
		var xf3 := mi.global_transform
		var ctr: Vector3 = xf3.origin - xf3.basis.z.normalized() 			* (xf3.basis.z.length() * 0.35)
		# cel mai apropiat vertex de perete, in orice directie
		var best := 1e9
		for v in verts:
			var dd: float = ctr.distance_squared_to(v)
			if dd < best:
				best = dd
		best = sqrt(best)
		if best > 3.0:
			air += 1
			print("IN AER %s la %.1f m de roca  (y=%.1f)" % [mi.name, best, ctr.y])
		else:
			ok += 1
	print("TOTAL=%d  infipte=%d  in_aer=%d" % [air + ok, ok, air])
	get_tree().quit(0)
