extends Node3D
## Ce raporteaza panzele ACUM: procent de normale-sus si inaltime. Criticul
## rundei 3 spune ca panza inca citeste plat; inainte sa schimb parametri,
## masor ce da configuratia din .tscn (up_pct tinta ~47%, ca la semicilindru).


func _ready() -> void:
	await get_tree().process_frame
	var track := (load("res://scenes/tracks/Track13.tscn") as PackedScene).instantiate() as Track
	add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	print("")
	print("nod              latime pas arcade  up%%  inaltime  tris")
	for node in _all(track):
		var fd := node as FabricDrape
		if fd == null:
			continue
		var r: Dictionary = fd.report()
		print("%-16s %5.1f %4.1f %5d  %5.1f  %6.2f  %5d"
			% [fd.name, fd.width_m, fd.pitch_m, fd.arches,
			   r["up_pct"], r["height_m"], r["tris"]])
	get_tree().quit()


func _all(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	var st: Array[Node] = [root]
	while not st.is_empty():
		var c: Node = st.pop_back()
		out.append(c)
		for k in c.get_children():
			st.push_back(k)
	return out
