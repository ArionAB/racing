extends Node
## POARTA DE HORNURI GEMENE: unde e fata de banda, si cat lasa liber.
##
## De ce exista. ProbeLaneClear spune CE atinge masina, nu CU CAT rateaza.
## Poarta e continut cerut de brief (doua hornuri aplecate deasupra drumului),
## deci raspunsul nu e "sterge-o", ci "cu cat trebuie mutata/subtiata". Sonda
## masoara, in sistemul BENZII (lateral fata de ax, frac de-a lungul), unde cad
## corpurile de coliziune si cat spatiu liber ramane la cotele caroseriei.
##
## Contractul cerut de lead: 12 m deschidere pe o lungime de 8 m.

const NAMES := ["poarta_hornuri_gemene43", "hornEst6"]


func _ready() -> void:
	await get_tree().process_frame
	var scene := load(GameState.TRACK_SCENES[
		GameState.resolve_track_index(6)]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var r: TrackRoute = track.routes[0]
	var n := r.baked.size()
	for nm in NAMES:
		var node := _find(track, nm)
		if node == null:
			print("%s: NEGASIT" % nm)
			continue
		var ab := _world_aabb(node)
		print("\n=== %s ===" % nm)
		print("  AABB coliziune: centru (%.1f, %.1f, %.1f)  marime %.2f x %.2f x %.2f" % [
			ab.get_center().x, ab.get_center().y, ab.get_center().z,
			ab.size.x, ab.size.y, ab.size.z])
		var lat_min := INF
		var lat_max := -INF
		var f_min := INF
		var f_max := -INF
		var y_min := INF
		for k in 8:
			var p := ab.get_endpoint(k)
			var i := r.closest_index_global(p)
			var side := r.side_at(i)
			var lat: float = (p - r.baked[i]).dot(side)
			lat_min = minf(lat_min, lat)
			lat_max = maxf(lat_max, lat)
			var fr := r.frac_at(i)
			f_min = minf(f_min, fr)
			f_max = maxf(f_max, fr)
			y_min = minf(y_min, p.y - r.baked[i].y)
		print("  lateral fata de ax: %+.2f .. %+.2f m" % [lat_min, lat_max])
		print("  frac acoperit:      %.4f .. %.4f" % [f_min, f_max])
		print("  baza fata de asfalt: %+.2f m" % y_min)

	print("\n=== DESCHIDERE LIBERA (raze laterale de pe ax, la h peste asfalt) ===")
	var space := track.get_world_3d().direct_space_state
	var f := 0.140
	while f <= 0.196:
		var i := int(f * float(n)) % n
		var p: Vector3 = r.baked[i]
		var fwd: Vector3 = (r.baked[(i + 1) % n] - p).normalized()
		var side := fwd.cross(Vector3.UP).normalized()
		var hw: float = track.width_at_index(i)
		var line := "  frac %.3f  hw=%.1f " % [f, hw]
		for h in [0.4, 1.0, 1.6, 3.0]:
			var o: Vector3 = p + Vector3.UP * h
			var l := _ray(space, o, -side, 20.0)
			var rr := _ray(space, o, side, 20.0)
			line += " h%.1f[%s|%s]" % [h, _fmt(l), _fmt(rr)]
		print(line)
		f += 0.005
	get_tree().quit()


func _fmt(d: float) -> String:
	return "lib" if d >= 20.0 else "%.1f" % d


func _ray(space: PhysicsDirectSpaceState3D, o: Vector3,
		d: Vector3, maxd: float) -> float:
	var q := PhysicsRayQueryParameters3D.create(o, o + d * maxd)
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return maxd
	return o.distance_to(hit["position"] as Vector3)


func _world_aabb(node: Node) -> AABB:
	var ab := AABB()
	var first := true
	var st: Array[Node] = [node]
	while not st.is_empty():
		var x: Node = st.pop_back()
		for c in x.get_children():
			st.append(c)
		# AABB din MESH, nu din shape.get_debug_mesh(): pe un trimesh cu zeci de
		# mii de fete debug_mesh construieste o geometrie noua si sonda atarna.
		var co := x as MeshInstance3D
		if co == null or co.mesh == null:
			continue
		var sa: AABB = co.mesh.get_aabb()
		var g := co.global_transform
		var w := AABB(g * sa.position, Vector3.ZERO)
		for k in 8:
			w = w.expand(g * sa.get_endpoint(k))
		if first:
			ab = w
			first = false
		else:
			ab = ab.merge(w)
	return ab


func _find(node: Node, nm: String) -> Node:
	if String(node.name) == nm:
		return node
	for c in node.get_children():
		var r := _find(c, nm)
		if r != null:
			return r
	return null
