extends Node
## Amprenta unei piste GENERATE: dovada ca o optimizare de incarcare n-a mutat
## nimic. Ruleaza pista (rebuild complet in _ready) si scrie cate un hash pe
## fiecare copil direct al pistei — geometria fiecarui mesh, transformarile,
## bufferele MultiMesh si formele de coliziune — plus unul total.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeTrackHash.tscn -- --track=16
##   ... -- --track=16 --no-grid      # ground_y pe scanarea completa (referinta)
##   ... -- --track=16 --out=user://h16.txt
##
## Se compara doua rulari (inainte/dupa, sau cu/fara --no-grid) cu `diff`.
## Hash-ul se ia IMEDIAT dupa add_child, inainte de primul cadru: dupa aceea
## hazardele si animatiile misca noduri, iar amprenta n-ar mai fi stabila.
##
## Pe langa amprenta, compara `ground_y` cu grila si fara ea, la bit, pe
## puncte langa sosea si pe toata cutia pistei (+300 m). Raspunsul asteptat:
## 0 diferente. Vezi TrackSideSampler.use_ground_grid.

var _mesh_hash_cache: Dictionary = {}

func _ready() -> void:
	var track_arg := 0
	var out_path := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			track_arg = int(arg.trim_prefix("--track="))
		elif arg == "--no-grid":
			TrackSideSampler.use_ground_grid = false
		elif arg.begins_with("--out="):
			out_path = arg.trim_prefix("--out=")
	var idx := GameState.resolve_track_index(track_arg)
	if idx < 0:
		push_error("ProbeTrackHash: --track invalid")
		get_tree().quit(2)
		return
	var path: String = GameState.TRACK_SCENES[idx]
	var track := (load(path) as PackedScene).instantiate() as Track
	add_child(track)
	var lines: PackedStringArray = []
	lines.append("pista %s grila=%s" % [path.get_file().get_basename(),
		str(TrackSideSampler.use_ground_grid)])
	var total := HashingContext.new()
	total.start(HashingContext.HASH_MD5)
	for child in track.get_children():
		var ctx := HashingContext.new()
		ctx.start(HashingContext.HASH_MD5)
		var count := _hash_subtree(child, track, ctx)
		var h := ctx.finish().hex_encode()
		total.update(h.to_utf8_buffer())
		lines.append("  %-40s noduri=%6d  %s" % [String(child.name).left(40), count, h])
	lines.append("TOTAL %s" % total.finish().hex_encode())
	lines.append_array(_compare_ground(track))
	var text := "\n".join(lines)
	print(text)
	if out_path != "":
		var f := FileAccess.open(out_path, FileAccess.WRITE)
		f.store_string(text + "\n")
	get_tree().quit(0)


func _hash_subtree(n: Node, root: Node, ctx: HashingContext) -> int:
	var count := 1
	ctx.update(str(root.get_path_to(n)).to_utf8_buffer())
	ctx.update(n.get_class().to_utf8_buffer())
	var n3 := n as Node3D
	if n3 != null:
		ctx.update(var_to_bytes([n3.transform, n3.visible]))
	if n is MeshInstance3D:
		ctx.update(_mesh_hash((n as MeshInstance3D).mesh).to_utf8_buffer())
	elif n is MultiMeshInstance3D:
		var mm := (n as MultiMeshInstance3D).multimesh
		if mm != null:
			ctx.update(var_to_bytes([mm.instance_count, mm.visible_instance_count,
				mm.buffer]))
			ctx.update(_mesh_hash(mm.mesh).to_utf8_buffer())
	elif n is CollisionShape3D:
		ctx.update(_shape_bytes((n as CollisionShape3D).shape))
	for c in n.get_children():
		count += _hash_subtree(c, root, ctx)
	return count


func _mesh_hash(mesh: Mesh) -> String:
	if mesh == null:
		return "null"
	var key := mesh.get_rid()
	if _mesh_hash_cache.has(key):
		return _mesh_hash_cache[key]
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_MD5)
	ctx.update(mesh.get_class().to_utf8_buffer())
	for si in mesh.get_surface_count():
		ctx.update(var_to_bytes(mesh.surface_get_arrays(si)))
	var h := ctx.finish().hex_encode()
	_mesh_hash_cache[key] = h
	return h


func _shape_bytes(shape: Shape3D) -> PackedByteArray:
	if shape == null:
		return "null".to_utf8_buffer()
	if shape is ConcavePolygonShape3D:
		return var_to_bytes((shape as ConcavePolygonShape3D).get_faces())
	if shape is ConvexPolygonShape3D:
		return var_to_bytes((shape as ConvexPolygonShape3D).points)
	if shape is HeightMapShape3D:
		var hm := shape as HeightMapShape3D
		return var_to_bytes([hm.map_width, hm.map_depth, hm.map_data])
	# Primitivele (cutie, cilindru, capsula, sfera): proprietatile lor.
	var props := []
	for p in shape.get_property_list():
		if int(p["usage"]) & PROPERTY_USAGE_STORAGE:
			props.append(shape.get(p["name"]))
	return var_to_bytes([shape.get_class(), props])


## ground_y cu grila fata de scanarea completa, pe ACELASI sampler.
func _compare_ground(track: Track) -> PackedStringArray:
	var s: TrackSideSampler = track._sampler
	var out: PackedStringArray = []
	if s == null:
		out.append("ground_y: fara sampler")
		return out
	var pts := PackedVector2Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in s._baked:
		lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.z))
		hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.z))
		# Langa sosea: unde se aseaza decorul, umerii, discurile.
		for k in 3:
			pts.append(Vector2(p.x, p.z) + Vector2(rng.randf_range(-60.0, 60.0),
				rng.randf_range(-60.0, 60.0)))
	lo -= Vector2(300, 300)
	hi += Vector2(300, 300)
	for k in 6000:
		pts.append(Vector2(rng.randf_range(lo.x, hi.x), rng.randf_range(lo.y, hi.y)))
	# Pe muchiile de celula, unde rotunjirea ar musca prima.
	for k in 2000:
		var c := TrackSideSampler.GROUND_GRID_CELL
		pts.append(Vector2(floorf(rng.randf_range(lo.x, hi.x) / c) * c,
			rng.randf_range(lo.y, hi.y)))
	var saved := TrackSideSampler.use_ground_grid
	var diff := 0
	var worst := 0.0
	var t_grid := 0
	var t_full := 0
	for p in pts:
		TrackSideSampler.use_ground_grid = true
		var t0 := Time.get_ticks_usec()
		var a := s.ground_y(p.x, p.y)
		var t1 := Time.get_ticks_usec()
		TrackSideSampler.use_ground_grid = false
		var b := s.ground_y(p.x, p.y)
		var t2 := Time.get_ticks_usec()
		t_grid += t1 - t0
		t_full += t2 - t1
		if a != b and not (is_nan(a) and is_nan(b)):
			diff += 1
			worst = maxf(worst, absf(a - b))
	TrackSideSampler.use_ground_grid = saved
	out.append("ground_y: %d puncte, %d diferente (max %.9f m); grila %.1f us/apel, completa %.1f us/apel"
		% [pts.size(), diff, worst, t_grid / float(pts.size()), t_full / float(pts.size())])
	return out
