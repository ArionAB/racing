extends Node
## CINE arunca umbra pe un punct: raza spre soare, si se raporteaza CE se
## loveste. Alternativa la ghicitul numelor de mesh — casterul poate fi in
## afara cadrului, deci nu apare in nicio masca.
##
## Foloseste coliziunea, deci vede doar corpuri fizice; pentru mesh-urile fara
## corp se face si un test analitic pe triunghiuri, pe cele mai mari mesh-uri.

func _ready() -> void:
	var frac := 0.27
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--frac="):
			frac = float(a.trim_prefix("--frac="))
	var idx := GameState.resolve_track_index(13)
	var track: Track = (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	add_child(track)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

	var sun: DirectionalLight3D = null
	var stk: Array[Node] = [get_tree().root]
	while not stk.is_empty():
		var nn: Node = stk.pop_back()
		if nn is DirectionalLight3D:
			sun = nn as DirectionalLight3D
		for c in nn.get_children():
			stk.append(c)
	var sdir := -sun.global_transform.basis.z.normalized()
	print("soare dir ", sdir)

	# Puncte DE PE PERETE: se ia mesh-ul si se esantioneaza vertecsii.
	var mi := _find(track, "Faleza pinten TaieturaSerpentinei")
	var arr := mi.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var xf := mi.global_transform

	# Toate mesh-urile mari, pentru testul analitic.
	var all: Array[MeshInstance3D] = []
	_collect(track, all)

	var blocked := 0
	var free := 0
	var by := {}
	var step := maxi(verts.size() / 120, 1)
	for vi in range(0, verts.size(), step):
		var wp: Vector3 = xf * verts[vi] + Vector3.UP * 0.05
		var who := _who_blocks(wp, -sdir, all, mi)
		if who == "":
			free += 1
		else:
			blocked += 1
			by[who] = int(by.get(who, 0)) + 1
	print("puncte testate %d: %d in umbra, %d in soare" % [blocked + free, blocked, free])
	var ks: Array = by.keys()
	ks.sort_custom(func(x, y): return int(by[x]) > int(by[y]))
	for k in ks:
		print("   %5d puncte umbrite de: %s" % [by[k], k])
	# AZIMUT fata de DIRECTIA DE MERS pe portiunea POI-ului C, si fata de
	# directia spre vale. Memoria `azimutul-soarelui-fata-de-drum`: se
	# remasoara la fiecare redesenare de traseu.
	var pts := track.route_at(0).baked
	var n := pts.size()
	var i := int(frac * float(n)) % n
	var fwd := (pts[(i + 12) % n] - pts[i]).normalized()
	var sun_from := -sdir
	var horiz_sun := Vector3(sun_from.x, 0.0, sun_from.z).normalized()
	var horiz_fwd := Vector3(fwd.x, 0.0, fwd.z).normalized()
	var ang := rad_to_deg(acos(clampf(horiz_sun.dot(horiz_fwd), -1.0, 1.0)))
	print("unghi soare fata de directia de MERS: %.0f grade (0 = din fata, 180 = din spate)" % ang)
	var elev := rad_to_deg(asin(clampf(sun_from.y, -1.0, 1.0)))
	print("elevatie soare: %.1f grade" % elev)
	get_tree().quit()


## Cine intersecteaza raza (p -> spre soare), analitic pe triunghiuri.
func _who_blocks(p: Vector3, dir: Vector3, all: Array[MeshInstance3D],
		self_mi: MeshInstance3D) -> String:
	var best := INF
	var who := ""
	for mi in all:
		var aabb := mi.global_transform * mi.mesh.get_aabb()
		if not _ray_aabb(p, dir, aabb):
			continue
		var arr := mi.mesh.surface_get_arrays(0)
		if arr.is_empty():
			continue
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var ind := PackedInt32Array()
		if arr[Mesh.ARRAY_INDEX] != null:
			ind = arr[Mesh.ARRAY_INDEX]
		var xf := mi.global_transform
		var tri := (ind.size() / 3) if ind.size() > 0 else (verts.size() / 3)
		for t in tri:
			var ia: int = ind[t * 3] if ind.size() > 0 else t * 3
			var ib: int = ind[t * 3 + 1] if ind.size() > 0 else t * 3 + 1
			var ic: int = ind[t * 3 + 2] if ind.size() > 0 else t * 3 + 2
			var r = Geometry3D.ray_intersects_triangle(p, dir,
				xf * verts[ia], xf * verts[ib], xf * verts[ic])
			if r == null:
				continue
			var d: float = p.distance_to(r)
			if d < 0.3 or d > 400.0:
				continue
			if d < best:
				best = d
				who = "%s (la %.0f m)" % [mi.name, d]
	if who == "":
		return ""
	# numele fara distanta, ca sa se grupeze
	return who.get_slice(" (la", 0)


func _ray_aabb(p: Vector3, d: Vector3, b: AABB) -> bool:
	var tmin := -INF
	var tmax := INF
	for a in 3:
		if absf(d[a]) < 1e-9:
			if p[a] < b.position[a] or p[a] > b.end[a]:
				return false
			continue
		var t1 := (b.position[a] - p[a]) / d[a]
		var t2 := (b.end[a] - p[a]) / d[a]
		tmin = maxf(tmin, minf(t1, t2))
		tmax = minf(tmax, maxf(t1, t2))
	return tmax >= maxf(tmin, 0.0)


func _collect(node: Node, out: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D and (node as MeshInstance3D).visible \
			and (node as MeshInstance3D).mesh != null \
			and (node as MeshInstance3D).cast_shadow != \
				GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
		out.append(node as MeshInstance3D)
	for c in node.get_children():
		_collect(c, out)


func _find(node: Node, want: String) -> MeshInstance3D:
	if node is MeshInstance3D and node.name == want:
		return node as MeshInstance3D
	for c in node.get_children():
		var r := _find(c, want)
		if r != null:
			return r
	return null
