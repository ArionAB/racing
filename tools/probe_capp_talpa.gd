extends Node
## ATRIBUIRE pentru gaura de la punctul 3: cat de sus ramane TALPA panzei de
## faleza fata de terenul de sub ea?
##
## `CliffFace._column` citeste fundul vaii cu raze, dar apoi il PLAFONEAZA:
##   floor_y = maxf(floor_y, lip_y - depth_m * DEPTH_SLACK)
## Deci panza nu poate cobori mai mult de depth_m * 1.8 sub buza. Daca valea e
## mai adanca de atat, talpa se opreste IN AER si prin fanta se vede cerul —
## exact "golul alb" din cadrul de la 28 s.
##
## Sonda reface acelasi calcul cu aceleasi cifre, coloana cu coloana, si
## raporteaza FANTA = (cota talpii plafonate) - (cota terenului sub talpa).
## Fanta > 0 inseamna gaura.
##
##   godot --headless --path . res://tools/ProbeCappTalpa.tscn -- --track=6

func _ready() -> void:
	await get_tree().process_frame
	var idx := 6
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	var t := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 6: await get_tree().process_frame

	var faces: Array[CliffFace] = []
	_collect(t, faces)
	var space := t.get_world_3d().direct_space_state
	var r = t.routes[0]
	var n: int = r.baked.size()
	print("=== FANTA SUB TALPA PANZEI (pozitiv = gaura) ===")
	var worst_all := -1e9
	for face in faces:
		if face.far_wall or face.cut_wall or face.brow:
			continue
		print("--- %s  frac %.3f..%.3f  side %+.0f  depth_m %.1f (raza max %.1f m)"
			% [face.name, face.frac_start, face.frac_end, face.side,
			   face.depth_m, face.depth_m * 1.8])
		var worst := -1e9
		var worst_f := 0.0
		var count := 0
		var f := face.frac_start
		while f <= face.frac_end + 1e-6:
			var i := clampi(int(round(f * float(n))) % n, 0, n - 1)
			var p: Vector3 = r.baked[i]
			var a: Vector3 = r.baked[(i + 4) % n]
			var sd: Vector3 = (a - p).normalized().cross(Vector3.UP).normalized() * signf(face.side)
			var lip_y: float = p.y
			# minimul terenului pe fereastra, ca in _column
			# Fereastra se opreste la ULTIMA raza care chiar gaseste teren.
			# Cautarea oarba pana la 140 m raporta -400 (fallback-ul) acolo unde
			# panza pur si simplu se termina, si scotea "fante" de 346 m care nu
			# sunt un defect de faleza, ci marginea lumii. Ce se afla dincolo de
			# panza nu e treaba talpii.
			var floor_y := lip_y - face.depth_m
			var d := 6.0
			while d < 140.0:
				var q: Vector3 = p + sd * d
				var gy := _gy(space, q, lip_y)
				if gy <= lip_y - 399.0:
					break
				floor_y = minf(floor_y, gy)
				d += 4.0
			var real_floor := floor_y
			var clamped := maxf(floor_y, lip_y - face.depth_m * 1.8)
			var gap := clamped - real_floor
			if gap > worst:
				worst = gap
				worst_f = f
			if gap > 0.5:
				count += 1
				print("      frac %.3f | buza %+6.1f | fund real %+7.1f (cadere %5.1f) | talpa %+7.1f | FANTA %+5.1f"
					% [f, lip_y, real_floor, lip_y - real_floor, clamped, gap])
			f += 0.004
		print("    fanta maxima %+.1f m la frac %.3f | coloane cu fanta > 0.5 m: %d"
			% [worst, worst_f, count])
		worst_all = maxf(worst_all, worst)
	print("VERDICT fanta maxima pe pista: %+.1f m" % worst_all)
	get_tree().quit(0)


## Cota terenului CARE SE VEDE.
##
## Prima versiune a sondei lua prima raza care lovea orice, si a raportat
## caderi de 106 m la frac 0.328. Atribuirea a rasturnat cifra: la 90-130 m
## lateral raza lovea `@StaticBody3D@2037`, un corp FARA NICIUN MESH (plansa de
## resetare a lumii, la y = -69.6). Adica sonda masura o podea invizibila si
## cerea o panza cu 40 m mai lunga decat are pe ce sta.
##
## Deci: se sare peste orice collider care nu are mesh vizibil in familie.
func _gy(space: PhysicsDirectSpaceState3D, q: Vector3, from_y: float) -> float:
	var exclude: Array[RID] = []
	for step in 8:
		var ray := PhysicsRayQueryParameters3D.create(
			Vector3(q.x, from_y + 120.0, q.z), Vector3(q.x, from_y - 400.0, q.z))
		ray.exclude = exclude
		var hit := space.intersect_ray(ray)
		if hit.is_empty():
			return from_y - 400.0
		if _visible_mesh_count(hit["collider"] as Node) > 0:
			return float(hit["position"].y)
		exclude.append(hit["rid"] as RID)
	return from_y - 400.0


func _visible_mesh_count(node: Node) -> int:
	if node == null: return 0
	var stack: Array[Node] = [node]
	var seen := 0
	while not stack.is_empty():
		var nd: Node = stack.pop_back()
		if nd is MeshInstance3D and (nd as MeshInstance3D).is_visible_in_tree():
			seen += 1
		for c in nd.get_children(): stack.append(c)
	return seen


func _collect(node: Node, out: Array[CliffFace]) -> void:
	if node is CliffFace:
		out.append(node as CliffFace)
	for c in node.get_children():
		_collect(c, out)
