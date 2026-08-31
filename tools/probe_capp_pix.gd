extends Node
## CE OBIECT e la un pixel dat din cadrul de sofer.
##
## Exista fiindca reprosurile vin ca "lama palida in stanga jos", iar cautarea
## prin .tscn dupa nume ghiceste. Trage o raza prin pixelul cerut si spune pe
## ce nod a cazut, cu tot lantul de parinti — deci obiectul se identifica din
## CADRU, nu din lista.
##
##   godot --headless --path . res://tools/ProbeCappPix.tscn -- --track=6 --frac=0.06 --px=150 --py=420

const MEASURE_DIST := 7.5
const MEASURE_HEIGHT := 2.6
const MEASURE_FOV := 60.0
const MEASURE_LOOK_AHEAD := 14.0
const MEASURE_LOOK_HEIGHT := 1.4


func _ready() -> void:
	await get_tree().process_frame
	var idx := 6
	var frac := 0.06
	var max_dist := 40.0
	var pts_px: Array = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
		elif arg.begins_with("--frac="):
			frac = float(arg.trim_prefix("--frac="))
		elif arg.begins_with("--maxdist="):
			max_dist = float(arg.trim_prefix("--maxdist="))
		elif arg.begins_with("--at="):
			var xy := arg.trim_prefix("--at=").split(",")
			pts_px.append(Vector2(float(xy[0]), float(xy[1])))
	if pts_px.is_empty():
		pts_px = [Vector2(150, 420)]
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	for i in 6:
		await get_tree().process_frame

	var pts := track.baked
	var n := pts.size()
	var i0 := int(frac * float(n)) % n
	var focus: Vector3 = pts[i0]
	var ahead: Vector3 = pts[(i0 + 12) % n]
	var dir := (ahead - focus).normalized()
	var eye := focus - dir * MEASURE_DIST + Vector3.UP * MEASURE_HEIGHT
	var target := focus + dir * MEASURE_LOOK_AHEAD + Vector3.UP * MEASURE_LOOK_HEIGHT
	var cam := Camera3D.new()
	get_tree().root.add_child(cam)
	cam.fov = MEASURE_FOV
	cam.near = 0.05
	cam.far = 400.0
	cam.global_position = eye
	cam.look_at(target, Vector3.UP)
	await get_tree().process_frame

	# TRIUNGHI CU TRIUNGHI, nu pe AABB.
	#
	# Prima versiune lua cel mai apropiat mesh al carui AABB contine pixelul, si
	# a mintit imediat: AABB-ul unui horn de 14 m inconjoara tot coltul de cadru,
	# deci orice reprosi in zona aia primea numele hornului. Verificat prin
	# A/B — am stins moloz si usa pe hornul acuzat si lama a ramas neatinsa in
	# captura. Un test care raspunde acelasi lucru si dupa ce ai sters obiectul
	# acuzat nu identifica nimic; costa o runda de "reparat" pe geometria buna.
	# Se intersecteaza acum raza chiar cu triunghiurile.
	var mis: Array[MeshInstance3D] = []
	_meshes(track, mis)
	print("")
	print("=== ce e la pixel, frac %.3f ===" % frac)
	for px: Vector2 in pts_px:
		var best: MeshInstance3D = null
		var best_d := 1e9
		var ro := cam.project_ray_origin(px)
		var rd := cam.project_ray_normal(px)
		for mi in mis:
			if mi.mesh == null or not mi.visible:
				continue
			var ab := mi.global_transform * mi.mesh.get_aabb()
			# Filtru ieftin pe AABB inainte de triunghiuri, plus o raza de
			# interes: reprosurile de prim-plan sunt la sub 40 m, iar fara
			# limita sonda scaneaza toata pista (400k triunghiuri x pixel) si
			# nu se mai termina.
			if eye.distance_to(ab.get_center()) > max_dist:
				continue
			if not ab.intersects_ray(ro, rd):
				continue
			var xf := mi.global_transform
			for sf in mi.mesh.get_surface_count():
				var arr := mi.mesh.surface_get_arrays(sf)
				var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var ix := PackedInt32Array()
				if arr[Mesh.ARRAY_INDEX] != null:
					ix = arr[Mesh.ARRAY_INDEX]
				var cnt := ix.size() / 3 if ix.size() > 0 else vs.size() / 3
				for t in cnt:
					var a: Vector3
					var b: Vector3
					var c2: Vector3
					if ix.size() > 0:
						a = xf * vs[ix[t * 3]]
						b = xf * vs[ix[t * 3 + 1]]
						c2 = xf * vs[ix[t * 3 + 2]]
					else:
						a = xf * vs[t * 3]
						b = xf * vs[t * 3 + 1]
						c2 = xf * vs[t * 3 + 2]
					var hit = Geometry3D.ray_intersects_triangle(ro, rd, a, b, c2)
					if hit == null:
						continue
					var d := ro.distance_to(hit)
					if d < best_d:
						best_d = d
						best = mi
		if best == null:
			print("  (%4.0f,%4.0f)  nimic" % [px.x, px.y])
			continue
		var chain := ""
		var nd: Node = best
		while nd != null and nd != get_tree().root:
			chain = String(nd.name) + ("/" + chain if chain != "" else "")
			nd = nd.get_parent()
		print("  (%4.0f,%4.0f)  dist %5.1f m  %s" % [px.x, px.y, best_d, chain])
	get_tree().quit()


func _meshes(node: Node, out: Array[MeshInstance3D]) -> void:
	var mi := node as MeshInstance3D
	if mi != null:
		out.append(mi)
	for c in node.get_children():
		_meshes(c, out)
