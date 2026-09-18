extends SceneTree
## Ce forma are, de fapt, `inti_punku`: are BUIANDRUG peste gol sau sunt doua
## blocuri separate?
##
## Motivul: captura C_r2_decor_f0225_poarta.png arata doua cutii de piatra cu
## capacul deschis, de o parte si de alta a drumului, fara nimic deasupra —
## adica nu se citeste ca poarta. Masuratorile din brief dau "gol liber 13.98 m
## pe fereastra y 0.15-4.80", ceea ce e compatibil SI cu o poarta cu buiandrug
## la 4.8 m, SI cu doua blocuri fara nimic intre ele.
##
## Se taie mesh-ul pe felii de y si se raporteaza, pe fiecare felie, intervalele
## de x ACOPERITE — daca sus exista o felie continua peste gol, e buiandrug.
##
##   godot --headless --path . --script res://tools/probe_mp_c_punku.gd

const GLB := "res://assets/models/machupicchu/structures/inti_punku.glb"


func _initialize() -> void:
	var ps := load(GLB) as PackedScene
	var root_node := ps.instantiate()
	var mi := _find_mesh(root_node)
	if mi == null:
		print("nu gasesc mesh")
		quit(1)
		return
	var mesh := mi.mesh
	var verts := PackedVector3Array()
	for si in mesh.get_surface_count():
		var arr: Array = mesh.surface_get_arrays(si)
		verts.append_array(arr[Mesh.ARRAY_VERTEX] as PackedVector3Array)
	var lo := Vector3(INF, INF, INF)
	var hi := Vector3(-INF, -INF, -INF)
	for v in verts:
		lo = lo.min(v)
		hi = hi.max(v)
	print("nod: %s" % mi.name)
	print("AABB: x %.2f..%.2f (%.2f m), y %.2f..%.2f, z %.2f..%.2f" % [
		lo.x, hi.x, hi.x - lo.x, lo.y, hi.y, lo.z, hi.z])
	print("")
	print("Pe fiecare felie de y: cate celule de 0,5 m pe X sunt ATINSE de vertecsi,")
	print("si daca banda centrala (|x| < 5 m) e acoperita.")
	print(" y_jos  y_sus | celule pe x | centru acoperit?")
	var nx := int(ceil((hi.x - lo.x) / 0.5)) + 1
	var y := lo.y
	while y < hi.y:
		var occ := {}
		for v in verts:
			if v.y >= y and v.y < y + 0.5:
				occ[int((v.x - lo.x) / 0.5)] = true
		var centru := false
		for k: int in occ.keys():
			var xc := lo.x + (float(k) + 0.5) * 0.5
			if absf(xc) < 5.0:
				centru = true
		print("%6.2f %6.2f | %3d / %3d   | %s" % [
			y, y + 0.5, occ.size(), nx, "DA" if centru else "nu"])
		y += 0.5
	quit(0)


func _find_mesh(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D:
		return n as MeshInstance3D
	for c in n.get_children():
		var r := _find_mesh(c)
		if r != null:
			return r
	return null
