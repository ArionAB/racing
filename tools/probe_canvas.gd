extends SceneTree
## Ce e, geometric, „panza aterizata": cate triunghiuri, ce gabarit, si mai ales
## cat de PLATA e — inaltimea fata de amprenta la sol.
##
## Critica oarba: „citeste ca un patrat plat cu un inel pe el". Aici se verifica
## daca asa e si in geometrie, inainte sa se atinga ceva.
func _initialize() -> void:
	var scn := load("res://assets/models/cappadocia/props/balloon_landed.glb") as PackedScene
	var n := scn.instantiate()
	var mis: Array[Node] = []
	_walk(n, mis)
	for m in mis:
		var mi := m as MeshInstance3D
		var ab := mi.mesh.get_aabb()
		var tris := 0
		for si in mi.mesh.get_surface_count():
			var arr := mi.mesh.surface_get_arrays(si)
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			tris += (idx.size() / 3) if idx.size() > 0 \
				else ((arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3)
		var foot := maxf(ab.size.x, ab.size.z)
		print("%-28s  %4d tris  gabarit %.2f x %.2f x %.2f  inaltime/amprenta %.2f"
			% [mi.name, tris, ab.size.x, ab.size.y, ab.size.z,
			ab.size.y / maxf(foot, 0.001)])
		print("   suprafete: %d  materiale: %d"
			% [mi.mesh.get_surface_count(), mi.mesh.get_surface_count()])
	quit()


func _walk(n: Node, out: Array[Node]) -> void:
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		_walk(c, out)
