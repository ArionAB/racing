extends Node
## ARE `inti_punku` BUIANDRUG PESTE DRUM, SAU SUNT DOAR DOI USCIORI?
##
## Capturile de la 0,2250 arata doua cutii de piatra de o parte si de alta a
## drumului si NIMIC intre ele. Doua explicatii posibile, cu consecinte diferite:
##  1. piesa chiar n-are traversa (atunci "poarta" e un nume, nu o forma);
##  2. are, dar e la 4,8-5,0 m, iar camera cu ochiul la 10 m trece PESTE ea si
##     o vede din spate/de sus, deci nu se citeste ca arcada.
##
## Se decide numarand vertecsii pe felii de inaltime si pe felii de latime:
## daca exista geometrie DEASUPRA golului (in banda centrala pe X, peste 4 m pe
## Y), buiandrugul exista.

func _ready() -> void:
	var ps := load("res://assets/models/machupicchu/structures/main_gate.glb") as PackedScene
	var root := ps.instantiate()
	add_child(root)
	var mi := _first_mesh(root)
	if mi == null:
		print("; nu gasesc mesh")
		get_tree().quit(1)
		return
	var mesh := mi.mesh
	var aabb := mesh.get_aabb()
	print("; AABB: pozitie (%.2f, %.2f, %.2f) dimensiune (%.2f, %.2f, %.2f)" % [
		aabb.position.x, aabb.position.y, aabb.position.z,
		aabb.size.x, aabb.size.y, aabb.size.z])
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	print("; %d vertecsi" % verts.size())
	# Felii pe Y: cati vertecsi si ce interval pe X ocupa fiecare felie.
	print("; felie Y        n    x_min    x_max   |x|<2 (banda centrala, peste gol)")
	var y0 := aabb.position.y
	var h := aabb.size.y
	for k in 10:
		var lo := y0 + h * float(k) / 10.0
		var hi := y0 + h * float(k + 1) / 10.0
		var n := 0
		var xmin := INF
		var xmax := -INF
		var centru := 0
		for v in verts:
			if v.y >= lo and v.y < hi:
				n += 1
				xmin = minf(xmin, v.x)
				xmax = maxf(xmax, v.x)
				if absf(v.x) < 2.0:
					centru += 1
		if n == 0:
			print("; %5.2f-%5.2f  %5d        -        -        -" % [lo, hi, n])
		else:
			print("; %5.2f-%5.2f  %5d  %7.2f  %7.2f  %5d" % [lo, hi, n, xmin, xmax, centru])
	get_tree().quit(0)

func _first_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node as MeshInstance3D
	for c in node.get_children():
		var r := _first_mesh(c)
		if r != null:
			return r
	return null
