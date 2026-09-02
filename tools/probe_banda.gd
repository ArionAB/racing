extends Node
## CINE E BANDA DE RUGINA? Raycast prin pixelii benzii rosii de sub con, pe
## TOATE mesh-urile din scena, si raporteaza pe NUME cine e lovit.
##
## De ce. Criticul orb a spus: conul de orizont e blocat (GLB cu UV colapsate),
## dar banda rosie de sub el "nu e evident acelasi obiect" si trebuie ATRIBUITA
## inainte sa presupui ceva. Daca e teren sau un plan separat, se repara cu
## unelte de asezare; daca e tot conul, nu.

const DIST := 7.5
const HEIGHT := 3.2
const FOV := 68.0
const LOOK_AHEAD := 14.0
const LOOK_HEIGHT := 1.2
const W := 1280.0
const H := 720.0


func _ready() -> void:
	var ti := GameState.resolve_track_index(13)
	var track := (load(GameState.TRACK_SCENES[ti]) as PackedScene).instantiate() as Track
	add_child(track)
	for i in range(6):
		await get_tree().process_frame

	var route := track.route_at(0)
	var pts := route.baked
	var n := pts.size()
	var idx := int(0.06 * float(n)) % n
	var focus: Vector3 = pts[idx]
	var ahead: Vector3 = pts[route.wrap_index(idx + 12)]
	var dir := (ahead - focus).normalized()
	var eye := focus - dir * DIST + Vector3.UP * HEIGHT
	var target := focus + dir * LOOK_AHEAD + Vector3.UP * LOOK_HEIGHT

	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = FOV
	cam.far = 400.0
	cam.global_position = eye
	cam.look_at(target, Vector3.UP)
	cam.current = true
	await get_tree().process_frame

	# toate mesh-urile, cu numele lor
	var items: Array = []
	_gather(track, items)
	print("mesh-uri stranse: %d" % items.size())

	# banda de rugina: y 0.30..0.48, x 0.72..0.98 din cadru
	var tally := {}
	var dsum := {}
	for gy in range(9):
		for gx in range(9):
			var px := Vector2(
				(0.72 + (gx + 0.5) / 9.0 * 0.26) * W,
				(0.30 + (gy + 0.5) / 9.0 * 0.18) * H)
			var ro := cam.project_ray_origin(px)
			var rd := cam.project_ray_normal(px)
			var best := 1e9
			var who := "cer"
			for it in items:
				var tris: PackedVector3Array = it["tris"]
				for t in range(0, tris.size(), 3):
					var hit = Geometry3D.ray_intersects_triangle(ro, rd,
						tris[t], tris[t + 1], tris[t + 2])
					if hit != null:
						var d := ro.distance_to(hit)
						if d < best:
							best = d
							who = "%s @%.0fm" % [it["name"], d]
			var key := who.split(" @")[0]
			tally[key] = int(tally.get(key, 0)) + 1
			if best < 1e8:
				dsum[key] = float(dsum.get(key, 0.0)) + best
	print("--- cine ocupa banda de rugina (81 raze) ---")
	var keys := tally.keys()
	keys.sort_custom(func(a, b): return tally[a] > tally[b])
	for k in keys:
		var dm: float = float(dsum.get(k, 0.0)) / maxf(1.0, float(tally[k]))
		print("  %5.1f%%  %-22s distanta medie %.0f m" % [
			100.0 * float(tally[k]) / 81.0, k, dm])
	get_tree().quit()


func _gather(node: Node, out: Array) -> void:
	for child in node.get_children():
		if child is MeshInstance3D and (child as MeshInstance3D).mesh != null \
				and (child as MeshInstance3D).visible:
			var mi := child as MeshInstance3D
			var xf := mi.global_transform
			var tris := PackedVector3Array()
			for s in range((mi.mesh as Mesh).get_surface_count()):
				var arr := (mi.mesh as Mesh).surface_get_arrays(s)
				if arr.is_empty() or arr[Mesh.ARRAY_VERTEX] == null:
					continue
				var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var ixv = arr[Mesh.ARRAY_INDEX]
				var ix: PackedInt32Array = (ixv as PackedInt32Array) 					if ixv != null else PackedInt32Array()
				if ix.is_empty():
					for i in range(vs.size()):
						tris.append(xf * vs[i])
				else:
					for i in range(ix.size()):
						tris.append(xf * vs[ix[i]])
			if tris.size() >= 3:
				out.append({"name": String(mi.name), "tris": tris})
		_gather(child, out)
