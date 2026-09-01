extends Node
## Muntele, atribuit pixel cu pixel: cine e lovit, la ce distanta, pe ce SLOT
## de atlas, si cat din culoare mai ramane dupa ceata.
##
## De ce nu ajunge probe_banda: aia spune doar CINE. Aici intereseaza de ce un
## munte cu trei etaje (2/29/22) apare de o singura culoare pe ecran.

const DIST := 7.5
const HEIGHT := 3.2
const FOV := 68.0
const LOOK_AHEAD := 14.0
const LOOK_HEIGHT := 1.2
const W := 1280.0
const H := 720.0

const SLOT_NAMES := {0: "SAND_LIGHT", 1: "SAND_MID", 2: "SAND_SHADOW",
	3: "ROCK_LIGHT", 4: "ROCK_DARK", 19: "CORAL_SAND", 20: "VOLCANIC_BLACK",
	22: "FOAM_WHITE", 23: "TILE_TERRACOTTA", 27: "LARCH_RUST", 29: "MARBLE_GREY"}


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

	var items: Array = []
	_gather(track, items)
	print("mesh-uri: %d   ochi %.0f,%.0f,%.0f" % [items.size(), eye.x, eye.y, eye.z])

	var fog_begin := 140.0
	var fog_end := 300.0
	var tally := {}
	var slot_tally := {}
	var fogsum := {}
	var total := 0
	var hist := {}
	# TOT sfertul din dreapta-sus, unde sta muntele in cadrul de sofer
	for gy in range(24):
		for gx in range(24):
			var px := Vector2(
				(0.55 + (gx + 0.5) / 24.0 * 0.45) * W,
				(0.00 + (gy + 0.5) / 24.0 * 0.42) * H)
			var ro := cam.project_ray_origin(px)
			var rd := cam.project_ray_normal(px)
			var best := 1e9
			var who := "cer"
			var slot := -1
			for it in items:
				var tris: PackedVector3Array = it["tris"]
				var slots: PackedInt32Array = it["slots"]
				for t in range(0, tris.size(), 3):
					var hit = Geometry3D.ray_intersects_triangle(ro, rd,
						tris[t], tris[t + 1], tris[t + 2])
					if hit != null:
						var d := ro.distance_to(hit)
						if d < best:
							best = d
							who = String(it["name"])
							slot = slots[t / 3]
			total += 1
			tally[who] = int(tally.get(who, 0)) + 1
			if who != "cer":
				var f: float = clampf((best - fog_begin) / (fog_end - fog_begin), 0.0, 1.0)
				f = pow(f, 1.4)
				fogsum[who] = float(fogsum.get(who, 0.0)) + f
				if who == "Erciyes":
					var bk := int(best / 20.0)
					hist[bk] = int(hist.get(bk, 0)) + 1
				var sk := "%s / slot %d %s" % [who, slot,
					String(SLOT_NAMES.get(slot, "?"))]
				slot_tally[sk] = int(slot_tally.get(sk, 0)) + 1

	# Distanta REALA de la ochi la fiecare instanta Erciyes, si cat ramane din ea
	print("--- instantele Erciyes fata de OCHI (nu de origine) ---")
	for c in track.get_children():
		_erc_dist(c, eye)
	print("--- cine ocupa sfertul din dreapta-sus (%d raze) ---" % total)
	var keys := tally.keys()
	keys.sort_custom(func(a, b): return tally[a] > tally[b])
	for k in keys:
		var line := "  %5.1f%%  %-24s" % [100.0 * float(tally[k]) / float(total), k]
		if fogsum.has(k):
			line += "  CEATA medie %.0f%%" % [100.0 * float(fogsum[k]) / float(tally[k])]
		print(line)
	print("--- histograma de distanta pentru pixelii Erciyes ---")
	var hk := hist.keys()
	hk.sort()
	for k in hk:
		print("  %3d-%3d m : %d raze" % [int(k) * 20, int(k) * 20 + 20, hist[k]])
	print("--- pe sloturi ---")
	var sk2 := slot_tally.keys()
	sk2.sort_custom(func(a, b): return slot_tally[a] > slot_tally[b])
	for k in sk2:
		print("  %5.1f%%  %s" % [100.0 * float(slot_tally[k]) / float(total), k])
	get_tree().quit()


func _erc_dist(n: Node, eye: Vector3) -> void:
	if n is MeshInstance3D and String(n.name).begins_with("Erciyes"):
		var mi := n as MeshInstance3D
		var aabb := mi.get_aabb()
		var xf := mi.global_transform
		var d := eye.distance_to(xf * aabb.get_center())
		var f: float = clampf((d - 140.0) / 160.0, 0.0, 1.0)
		f = pow(f, 1.4)
		print("  %s: centru la %.0f m de ochi, scale %.2f -> ramane %.0f%% din culoare" % [
			mi.name, d, xf.basis.get_scale().y, 100.0 * (1.0 - f)])
	for c in n.get_children():
		_erc_dist(c, eye)


func _gather(node: Node, out: Array) -> void:
	for child in node.get_children():
		if child is MeshInstance3D and (child as MeshInstance3D).mesh != null \
				and (child as MeshInstance3D).visible:
			var mi := child as MeshInstance3D
			var xf := mi.global_transform
			var tris := PackedVector3Array()
			var slots := PackedInt32Array()
			for s in range((mi.mesh as Mesh).get_surface_count()):
				var arr := (mi.mesh as Mesh).surface_get_arrays(s)
				if arr.is_empty() or arr[Mesh.ARRAY_VERTEX] == null:
					continue
				var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var uvv = arr[Mesh.ARRAY_TEX_UV]
				var uv: PackedVector2Array = (uvv as PackedVector2Array) if uvv != null else PackedVector2Array()
				var ixv = arr[Mesh.ARRAY_INDEX]
				var ix: PackedInt32Array = (ixv as PackedInt32Array) if ixv != null else PackedInt32Array()
				if ix.is_empty():
					for i in range(vs.size()):
						tris.append(xf * vs[i])
					for i in range(vs.size() / 3):
						slots.append(_slot(uv, i * 3))
				else:
					for i in range(ix.size()):
						tris.append(xf * vs[ix[i]])
					for i in range(ix.size() / 3):
						slots.append(_slot_ix(uv, ix, i * 3))
			if tris.size() >= 3:
				out.append({"name": String(mi.name), "tris": tris, "slots": slots})
		_gather(child, out)


func _slot(uv: PackedVector2Array, i: int) -> int:
	if uv.is_empty() or i >= uv.size():
		return -1
	return int(uv[i].x * 32.0)


func _slot_ix(uv: PackedVector2Array, ix: PackedInt32Array, i: int) -> int:
	if uv.is_empty() or i >= ix.size() or ix[i] >= uv.size():
		return -1
	return int(uv[ix[i]].x * 32.0)
