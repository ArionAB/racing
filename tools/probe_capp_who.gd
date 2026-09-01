extends Node
## CINE e in cadru la frac 0.06: numele si coloana pe ecran a fiecarui obiect
## de decor, proiectate cu ACEEASI camera ca Snapshot.
##
## Motivul: sonda de silueta raporteaza conuri dupa coloana X, iar eu am reglat
## `chimney_shape` presupunand ca acele conuri SUNT hornuri. Daca in stanga-fata
## e de fapt alt asset (mesa, creasta, bolovan), atunci toate rundele care au
## tunat hornuri au masurat un obiect pe care nu-l atingeau.

func _ready() -> void:
	await get_tree().process_frame
	var scn: PackedScene = load("res://scenes/tracks/Track13.tscn")
	var track: Node = scn.instantiate()
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var cam := _find_cam(get_tree().root)
	if cam == null:
		print("fara camera")
		get_tree().quit()
		return
	var rows: Array = []
	_walk(track, cam, rows)
	rows.sort_custom(func(a, b): return a[1] < b[1])
	print("obiecte proiectate in cadru (x_ecran, nume, script):")
	for r in rows:
		print("  x=%4d  h=%4d px  %-26s %s" % [r[1], r[2], r[0], r[3]])
	get_tree().quit()


func _find_cam(n: Node) -> Camera3D:
	if n is Camera3D and (n as Camera3D).current:
		return n
	for c in n.get_children():
		var r := _find_cam(c)
		if r != null:
			return r
	return null


func _walk(n: Node, cam: Camera3D, out: Array) -> void:
	var mi := n as MeshInstance3D
	if mi != null and mi.mesh != null and mi.visible:
		var ab: AABB = mi.global_transform * mi.mesh.get_aabb()
		var ctr := ab.get_center()
		if not cam.is_position_behind(ctr):
			var p := cam.unproject_position(ctr)
			if p.x > -200.0 and p.x < 1480.0:
				var top := cam.unproject_position(
						Vector3(ctr.x, ab.position.y + ab.size.y, ctr.z))
				var bot := cam.unproject_position(
						Vector3(ctr.x, ab.position.y, ctr.z))
				var hpx := int(absf(bot.y - top.y))
				if hpx > 40:
					var owner_n := n
					while owner_n != null and owner_n.get_script() == null:
						owner_n = owner_n.get_parent()
					var scr := "-"
					var nm := mi.name
					if owner_n != null:
						scr = owner_n.get_script().resource_path.get_file()
						nm = owner_n.name
					out.append([nm, int(p.x), hpx, scr])
	for c in n.get_children():
		_walk(c, cam, out)
