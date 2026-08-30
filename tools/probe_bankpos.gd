extends Node
## UNDE sta, in metri, mesh-ul malului opus — si cat de departe de sosea.
##
## Capturile arata un perete tan LIPIT de buza, desi cererea era o masa dincolo
## de vale. O sonda care spune „mesh construit" ar trece si asa. Aici se citesc
## AABB-urile reale ale nodurilor de faleza si se compara cu axul soselei.
const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"


func _ready() -> void:
	var t := (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(t)
	await get_tree().process_frame
	await get_tree().physics_frame
	var mis: Array[Node] = []
	_walk(t, mis)
	var s: TrackSideSampler = t.get("_sampler")
	for m in mis:
		var mi := m as MeshInstance3D
		var ab := mi.get_aabb()
		var c: Vector3 = mi.global_transform * ab.get_center()
		# rulajul fata de cel mai apropiat punct de sosea
		var best := 1e9
		var bi := 0
		for i in s.point_count():
			var d := Vector2(c.x, c.z).distance_to(
				Vector2(s.baked_point(i).x, s.baked_point(i).z))
			if d < best:
				best = d
				bi = i
		# ATENTIE: „cel mai apropiat punct de sosea" MINTE pe o serpentina —
		# drumul se intoarce, deci o masa la 105 m de piciorul de dus e la
		# noua metri de piciorul de intors. De aceea se tipareste si AABB-ul
		# in lume: acolo se vede daca masa e langa banda sau peste vale.
		print("%-34s  centru (%.0f, %.0f, %.0f)  y=%6.1f  cel mai apropiat drum %6.1f m  inaltime %5.1f m  AABB x[%.0f..%.0f] z[%.0f..%.0f]"
			% [mi.name, c.x, c.y, c.z, c.y, best, ab.size.y,
			(mi.global_transform * ab.position).x,
			(mi.global_transform * (ab.position + ab.size)).x,
			(mi.global_transform * ab.position).z,
			(mi.global_transform * (ab.position + ab.size)).z])
	get_tree().quit()


func _walk(n: Node, out: Array[Node]) -> void:
	if n is MeshInstance3D and (n.name as String).begins_with("Faleza"):
		out.append(n)
	for c in n.get_children():
		_walk(c, out)
