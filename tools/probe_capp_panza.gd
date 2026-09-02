extends Node
## CAT DE DEPARTE ajunge panza de teren, si cat de aproape trece drumul de
## marginea ei.
##
## Punctul 3 din raportul de la volan ("gol alb sub hornuri, faleza taiata")
## nu e o problema de faleza: la frac 0.33-0.37 raza laterala nu mai gaseste
## NICIUN mesh dincolo de ~70-90 m. Sonda verifica ipoteza structurala —
## `Track._world_extent` plafoneaza patratul de teren la TERRAIN_MAX_SIZE
## (1400 m), iar traseul Cappadociei e mai lat de atat plus marja.
##
##   godot --headless --path . res://tools/ProbeCappPanza.tscn -- --track=6

func _ready() -> void:
	await get_tree().process_frame
	var idx := 6
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	var t := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 6: await get_tree().process_frame

	var tb := t.get_node_or_null("TerrainBody")
	var aabb := AABB()
	var first := true
	if tb != null:
		for ch in tb.get_children():
			if ch is MeshInstance3D:
				var mi := ch as MeshInstance3D
				var a := mi.get_aabb()
				a.position += mi.global_position
				if first:
					aabb = a
					first = false
				else:
					aabb = aabb.merge(a)
	print("=== PANZA DE TEREN (mesh randat) ===")
	print("AABB x: %.1f .. %.1f  (latime %.1f)" % [aabb.position.x, aabb.end.x, aabb.size.x])
	print("AABB z: %.1f .. %.1f  (latime %.1f)" % [aabb.position.z, aabb.end.z, aabb.size.z])
	print("AABB y: %.1f .. %.1f" % [aabb.position.y, aabb.end.y])

	var lo := Vector3.INF
	var hi := -Vector3.INF
	for p in t.baked:
		lo = lo.min(p)
		hi = hi.max(p)
	print("--- traseu x: %.1f .. %.1f (span %.1f) | z: %.1f .. %.1f (span %.1f)"
		% [lo.x, hi.x, hi.x - lo.x, lo.z, hi.z, hi.z - lo.z])
	print("--- span maxim %.1f + marja 230.0 = %.1f | TERRAIN_MAX_SIZE %.1f"
		% [maxf(hi.x - lo.x, hi.z - lo.z), maxf(hi.x - lo.x, hi.z - lo.z) + 230.0,
		   Track.TERRAIN_MAX_SIZE])

	var cen := Vector3.ZERO
	for p in t.baked:
		cen += p
	cen /= float(t.baked.size())
	print("--- centroid (media punctelor) x=%.1f z=%.1f" % [cen.x, cen.z])
	print("--- centrul casetei                x=%.1f z=%.1f" % [(lo.x + hi.x) * 0.5, (lo.z + hi.z) * 0.5])
	print("--- DERIVA centroid - centru caseta: x %+.1f  z %+.1f"
		% [cen.x - (lo.x + hi.x) * 0.5, cen.z - (lo.z + hi.z) * 0.5])
	print("--- degajare teoretica pe x: stanga %.1f, dreapta %.1f"
		% [lo.x - aabb.position.x, aabb.end.x - hi.x])
	print("--- degajare teoretica pe z: jos    %.1f, sus     %.1f"
		% [lo.z - aabb.position.z, aabb.end.z - hi.z])
	print("=== DEGAJARE: cati metri de teren raman lateral fata de sosea ===")
	var n: int = t.baked.size()
	var worst := 1e9
	var worst_f := 0.0
	var f := 0.0
	while f < 1.0:
		var i := clampi(int(f * float(n)), 0, n - 1)
		var p: Vector3 = t.baked[i]
		var margin_x: float = minf(p.x - aabb.position.x, aabb.end.x - p.x)
		var margin_z: float = minf(p.z - aabb.position.z, aabb.end.z - p.z)
		var m: float = minf(margin_x, margin_z)
		if m < worst:
			worst = m
			worst_f = f
		if m < 120.0:
			print("  frac %.3f | pos (%7.1f,%7.1f) | teren ramas %6.1f m" % [f, p.x, p.z, m])
		f += 0.01
	print("VERDICT degajare minima %.1f m la frac %.3f" % [worst, worst_f])
	get_tree().quit(0)
