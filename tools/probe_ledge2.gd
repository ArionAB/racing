extends Node
## Iese treapta din perete SAU e ingropata? Masurat corect de data asta.
##
## Prima ProbeLedge compara treapta cu AABB-ul celui mai apropiat MODUL, care
## putea fi la 15 m si avea 20 m lungime — adica raspundea la alta intrebare.
## Aici se trage o RAZA din fata treptei spre inauntru: daca primul lucru lovit
## e perete la mai putin de `depth`, treapta chiar iese din el.
##
## Se numara si cate trepte au fata liberă (nimic in fata lor pe 1.5 m), fiindca
## o treapta perfect asezata dar acoperita de un modul mai avansat e tot
## invizibila.

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
	# Toti vertecsii peretelui.
	var verts: PackedVector3Array = PackedVector3Array()
	for mi in faleza.find_children("*", "MeshInstance3D", true, false):
		var mm := (mi as MeshInstance3D).mesh
		if mm == null: continue
		var xf := (mi as MeshInstance3D).global_transform
		for s in mm.get_surface_count():
			var arr := mm.surface_get_arrays(s)
			for v in (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				verts.append(xf * v)
	var free_cnt := 0
	var buried := 0
	var n := 0
	for t in strate.get_children():
		var mi := t as MeshInstance3D
		if mi == null: continue
		n += 1
		var xf := mi.global_transform
		var nrm := xf.basis.z.normalized()
		var ctr := xf.origin
		var half: float = xf.basis.z.length() * 0.5
		# Punctul de pe fata exterioara a treptei.
		var face_p: Vector3 = ctr - nrm * half
		# Exista vertecsi de perete IN FATA fetei treptei (mai aproape de
		# sosea cu peste 0.15 m), in cilindrul din jurul ei?
		var blocked := false
		var nearest_front := 1e9
		for v in verts:
			var rel: Vector3 = v - face_p
			var fwd: float = -rel.dot(nrm)
			if fwd < 0.15:
				continue
			# in raza de 3 m lateral/vertical fata de axa razei
			var perp: Vector3 = rel + nrm * fwd
			if perp.length() > 3.0:
				continue
			nearest_front = minf(nearest_front, fwd)
			blocked = true
		if blocked:
			buried += 1
		else:
			free_cnt += 1
		if n <= 10:
			print("%s  fata_libera=%s  perete_in_fata=%.2f m"
				% [mi.name, str(not blocked),
				(nearest_front if blocked else -1.0)])
	print("TOTAL trepte=%d  cu fata LIBERA=%d  acoperite=%d" % [n, free_cnt, buried])
	get_tree().quit(0)
