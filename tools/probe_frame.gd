extends Node
## Sonda de CADRU: cate triunghiuri si cate draw call-uri ajung efectiv la GPU
## dintr-o pozitie de joc, nu cate exista pe pista.
##
##   godot --path . res://tools/ProbeFrame.tscn -- --track=1
##
## Ruleaza CU FEREASTRA: RenderingServer nu contorizeaza nimic in --headless.
## Camera e cea reala (constantele lui ChaseCamera), inclusiv far-ul ei.
##
## ############################################################################
## DE CE DOUA COLOANE DE TRIUNGHIURI, si de ce a doua nu e redundanta.
##
## `RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME` a fost singura sursa pana cand
## decorul a intrat in MultiMesh (TrackDecorBatch). Masurat atunci: cu decorul
## grupat intr-o SINGURA celula pe toata pista — deci cu tot decorul trimis in
## fiecare cadru, fara nicio taiere — contorul a raportat MAI PUTINE triunghiuri
## decat inainte de grupare. Imposibil fizic; explicatia e ca nu socoteste
## geometria unui MultiMesh o data per INSTANTA.
##
## Concluzia practica e neplacuta: dupa coacere, coloana aia nu mai poate fi
## comparata cu masuratorile de dinainte, si tocmai marimea celulei — singurul
## reglaj al taierii — se alege dupa ea.
##
## De aceea `tri (frustum)` se calculeaza AICI: se testeaza cutia fiecarui vizual
## fata de frustumul camerei si se aduna triunghiurile lui, inmultite cu numarul
## de instante. E o supra-estimare (culling-ul real al Godot mai taie prin
## ocluzie si prin cascadele de umbra), dar e o supra-estimare CONSECVENTA
## inainte si dupa coacere — deci se poate compara, si asta e tot ce i se cere.
## ############################################################################

const SAMPLES: int = 20

func _ready() -> void:
	var track_index := 0
	var no_shadows := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			track_index = int(arg.trim_prefix("--track="))
		elif arg == "--no-shadows":
			no_shadows = true
	track_index = clampi(track_index, 0, GameState.TRACK_SCENES.size() - 1)
	var track := (load(GameState.TRACK_SCENES[track_index]) as PackedScene) \
		.instantiate() as Track
	add_child(track)
	if no_shadows:
		track.theme_shadows = false
		track.rebuild()
	await get_tree().process_frame
	await get_tree().process_frame

	var cam := Camera3D.new()
	add_child(cam)
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = ChaseCamera.BASE_FOV
	cam.far = ChaseCamera.FAR_PLANE
	cam.current = true

	var n := track.baked.size()
	var rows: Array[Dictionary] = []
	for s in SAMPLES:
		var frac := float(s) / float(SAMPLES)
		var idx := int(frac * float(n)) % n
		var focus: Vector3 = track.baked[idx]
		var ahead: Vector3 = track.baked[(idx + 12) % n]
		var dir := (ahead - focus).normalized()
		cam.position = focus - dir * ChaseCamera.DEFAULT_DISTANCE \
			+ Vector3.UP * ChaseCamera.DEFAULT_HEIGHT
		cam.look_at(focus + dir * ChaseCamera.LOOK_AHEAD
			+ Vector3.UP * ChaseCamera.LOOK_HEIGHT, Vector3.UP)
		# Doua cadre ca sa se aseze culling-ul, apoi citim al treilea.
		for k in 3:
			await RenderingServer.frame_post_draw
		rows.append({
			"frac": frac,
			"prim": RenderingServer.get_rendering_info(
				RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
			"draw": RenderingServer.get_rendering_info(
				RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
			"frustum": _tris_in_frustum(track, cam),
		})

	print("")
	print("=== CADRU: %s (camera de joc, far %.0f m, umbre %s) ==="
		% [track.track_name, ChaseCamera.FAR_PLANE,
			"NU" if no_shadows else "da"])
	print("  frac   contor Godot   tri (frustum)   draw calls")
	var max_p := 0
	var sum_p := 0
	var max_f := 0
	var sum_f := 0
	var max_d := 0
	for r in rows:
		print("  %.2f   %12d   %13d   %10d"
			% [r["frac"], r["prim"], r["frustum"], r["draw"]])
		max_p = maxi(max_p, int(r["prim"]))
		max_d = maxi(max_d, int(r["draw"]))
		max_f = maxi(max_f, int(r["frustum"]))
		sum_p += int(r["prim"])
		sum_f += int(r["frustum"])
	print("  --- contor Godot: varf %d, medie %d" % [max_p, sum_p / rows.size()])
	print("  --- frustum:      varf %d, medie %d" % [max_f, sum_f / rows.size()])
	print("  --- draw calls:   varf %d" % max_d)
	get_tree().quit()


## Triunghiurile ale caror cutii intersecteaza frustumul camerei — numarate de
## noi, instanta cu instanta. Vezi nota din capul fisierului.
func _tris_in_frustum(track: Node, cam: Camera3D) -> int:
	var planes := cam.get_frustum()
	var cache := {}
	var total := 0
	for node in _walk(track):
		if node is MeshInstance3D:
			var mi := node as MeshInstance3D
			if mi.mesh == null or not mi.is_visible_in_tree():
				continue
			if _visible(mi.global_transform * mi.get_aabb(), planes):
				total += _tris_of(mi.mesh, cache)
		elif node is MultiMeshInstance3D:
			var mmi := node as MultiMeshInstance3D
			var mm := mmi.multimesh
			if mm == null or mm.mesh == null or not mmi.is_visible_in_tree():
				continue
			# Per INSTANTA, nu per buffer: altfel am reproduce exact eroarea
			# contorului pe care coloana asta exista ca s-o ocoleasca.
			var per := _tris_of(mm.mesh, cache)
			var local := mm.mesh.get_aabb()
			var base := mmi.global_transform
			for i in mm.instance_count:
				if _visible(base * mm.get_instance_transform(i) * local, planes):
					total += per
	return total


## Testul standard cutie-vs-plane, cu o capcana de semn care merita scrisa.
##
## `Camera3D.get_frustum()` intoarce plane cu normalele spre EXTERIOR. Prima
## versiune a presupus invers (documentatia se citeste usor pe dos) si rezultatul
## a fost o sonda care raporta 18.000 de triunghiuri vizibile acolo unde Godot
## desena 130.000 — adica pastra exact ce e AFARA si arunca ce e in cadru.
## Cifra nu parea absurda, si asta e partea periculoasa: singurul lucru care a
## dat-o de gol a fost ca nu se misca deloc cand schimbai marimea celulei.
##
## Deci: cutia e in afara daca varful ei cel mai avansat pe directia normalei e
## in FATA planului.
func _visible(box: AABB, planes: Array[Plane]) -> bool:
	for p in planes:
		var support := Vector3(
			box.position.x + (box.size.x if p.normal.x > 0.0 else 0.0),
			box.position.y + (box.size.y if p.normal.y > 0.0 else 0.0),
			box.position.z + (box.size.z if p.normal.z > 0.0 else 0.0))
		if p.distance_to(support) > 0.0:
			return false
	return true


func _tris_of(mesh: Mesh, cache: Dictionary) -> int:
	var key := mesh.get_instance_id()
	if not cache.has(key):
		cache[key] = mesh.get_faces().size() / 3
	return cache[key]


func _walk(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for c in node.get_children():
		out.append_array(_walk(c))
	return out
