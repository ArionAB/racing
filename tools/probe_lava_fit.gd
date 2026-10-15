extends Node
## Cat de LIPITA de teren e limba de lava (#512).
##
## Pentru fiecare stadiu al fiecarui `LavaFlowHazard`, ia vertecsii mesh-ului
## vizibil, ii duce in spatiul lumii si trage o raza IN JOS din fiecare, pana
## la teren. Raporteaza distributia distantelor (minim / mediana / p90 / max)
## si cat la suta din talpa pluteste peste un prag.
##
## Masoara TALPA, nu tot mesh-ul: un vertex de pe creasta limbii e normal sa
## fie sus. Talpa = vertecsii din treimea de jos a fiecarei coloane (x,z) —
## altfel grosimea limbii se amesteca cu plutirea si cifra nu mai inseamna nimic.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeLavaFit.tscn -- --track=4
##   ... --stage=N   doar stadiul N (implicit: toate trei)

const RAY_UP := 2.0
const RAY_DOWN := 400.0
var _only_stage := -1


func _ready() -> void:
	await get_tree().process_frame
	var idx := 4
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
		elif arg.begins_with("--stage="):
			_only_stage = int(arg.trim_prefix("--stage="))
	print("[lava] pista: %s" % GameState.track_label(idx))
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	for i in 8:
		await get_tree().physics_frame
	var space := track.get_world_3d().direct_space_state
	var hazards: Array[Node] = []
	_collect_hazards(track, hazards)
	print("[lava] %d limbi de lava gasite" % hazards.size())
	var worst := 0.0
	for h in hazards:
		for si in 3:
			if _only_stage >= 0 and si != _only_stage:
				continue
			var m := _find(h, "Lava_Stage%d" % (si + 1)) as MeshInstance3D
			if m == null:
				print("  %s stadiu %d: nod lipsa" % [h.name, si + 1])
				continue
			var g := _gaps(m, space, h)
			if g.is_empty():
				print("  %s stadiu %d: 0 puncte de talpa" % [h.name, si + 1])
				continue
			g.sort()
			var n := g.size()
			var over := 0
			for v in g:
				if v > 0.5:
					over += 1
			var p90: float = g[int(n * 0.9)] if n > 1 else g[0]
			worst = maxf(worst, p90)
			print("  %-10s stadiu %d: %4d pct talpa | min %6.2f  median %6.2f  p90 %6.2f  max %6.2f m | %5.1f%% peste 0.5 m"
				% [h.name, si + 1, n, g[0], g[n / 2], p90, g[n - 1],
					100.0 * float(over) / float(n)])
	print("")
	if worst > 0.5:
		print("VERDICT: PROBLEMA — talpa pluteste (cel mai prost p90 = %.2f m)" % worst)
	else:
		print("VERDICT: OK — talpa lipita de teren (cel mai prost p90 = %.2f m)" % worst)
	get_tree().quit(0)


## Distantele de la talpa mesh-ului pana la teren, pe verticala.
func _gaps(m: MeshInstance3D, space: PhysicsDirectSpaceState3D, haz: Node) -> Array[float]:
	var out: Array[float] = []
	if m.mesh == null:
		return out
	var arr := m.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var xf := m.global_transform
	# Coloane pe o grila de 2 m: tin doar vertecsii din treimea de jos a
	# fiecarei coloane — aia e talpa, restul e grosimea limbii.
	var cols := {}
	for v in verts:
		var w := xf * v
		var key := Vector2i(int(floor(w.x * 0.5)), int(floor(w.z * 0.5)))
		if not cols.has(key):
			cols[key] = []
		(cols[key] as Array).append(w)
	for key in cols:
		var col: Array = cols[key]
		var lo := INF
		var hi := -INF
		for w: Vector3 in col:
			lo = minf(lo, w.y)
			hi = maxf(hi, w.y)
		# Talpa = vertexul CEL MAI DE JOS al coloanei. Regula veche ("treimea
		# de jos") mergea pe o placa plana, dar dupa asezarea pe relief
		# coloana urmeaza panta si treimea prinde si crusta de sus.
		for w: Vector3 in col:
			if w.y > lo + 0.05:
				continue
			var q := PhysicsRayQueryParameters3D.create(
				w + Vector3.UP * RAY_UP, w + Vector3.DOWN * RAY_DOWN)
			var hit := space.intersect_ray(q)
			if hit.is_empty():
				continue
			# Nu masura fata de propria lava (sau de alt stadiu): doar teren.
			var col_node := hit.collider as Node
			if col_node != null and haz.is_ancestor_of(col_node):
				continue
			out.append(w.y - (hit.position as Vector3).y)
	return out


func _collect_hazards(node: Node, out: Array[Node]) -> void:
	if node is LavaFlowHazard:
		out.append(node)
	for c in node.get_children():
		_collect_hazards(c, out)


func _find(node: Node, want: String) -> Node3D:
	for c in node.get_children():
		if c.name == want and c is Node3D:
			return c as Node3D
		var d := _find(c, want)
		if d != null:
			return d
	return null
