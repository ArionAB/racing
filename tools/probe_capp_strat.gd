extends Node
## La ce cota trebuie sa stea stratul rosu ca sa se vada SUB drum, peste o rapa.
##
## Criticul cere a doua nuanta la ADANCIME, ca masa de teren separata vazuta
## peste un gol — nu ca banda pictata pe conuri (aia s-a incercat si s-a scos).
## Deci nu se alege o cota din ochi: se masoara ce cote EXISTA in teren sub
## nivelul soselei, si cat teren e in fiecare felie. Un strat pus sub tot
## terenul nu se vede; unul pus prea sus urca pe conuri.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCappStrat.tscn -- --track=6


func _ready() -> void:
	await get_tree().process_frame
	var idx := 6
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame

	var pts: PackedVector3Array = track.baked
	var road_min := 1e9
	var road_max := -1e9
	var road_sum := 0.0
	for p in pts:
		road_min = minf(road_min, p.y)
		road_max = maxf(road_max, p.y)
		road_sum += p.y
	var road_mean := road_sum / float(pts.size())
	print("")
	print("=== cotele pistei si ale terenului ===")
	print("  sosea: min %.1f  medie %.1f  max %.1f" % [road_min, road_mean, road_max])

	# Histograma cotelor de teren din mesh-ul construit.
	var terr: MeshInstance3D = null
	var stack: Array[Node] = [track]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if n is MeshInstance3D and str(n.name).to_lower().contains("terrain"):
			terr = n as MeshInstance3D
	if terr == null:
		print("  (nu am gasit mesh-ul de teren dupa nume; caut cel mai mare)")
		var best := 0
		stack = [track]
		while not stack.is_empty():
			var n2: Node = stack.pop_back()
			for c in n2.get_children():
				stack.append(c)
			if n2 is MeshInstance3D:
				var mi := n2 as MeshInstance3D
				if mi.mesh != null:
					var vc: int = mi.mesh.get_faces().size()
					if vc > best:
						best = vc
						terr = mi
	if terr == null:
		print("VERDICT: fara teren")
		get_tree().quit(1)
		return
	print("  mesh de teren: %s" % terr.name)
	var faces := terr.mesh.get_faces()
	var buckets := {}
	var ymin := 1e9
	var ymax := -1e9
	for v in faces:
		var y: float = v.y + terr.global_position.y
		ymin = minf(ymin, y)
		ymax = maxf(ymax, y)
		var b := int(floor(y / 5.0)) * 5
		buckets[b] = int(buckets.get(b, 0)) + 1
	print("  teren: min %.1f  max %.1f" % [ymin, ymax])
	print("")
	print("  cota    vertecsi   %din teren   fata de soseaua medie")
	var keys := buckets.keys()
	keys.sort()
	var total := faces.size()
	for k in keys:
		var cnt: int = buckets[k]
		var pct := 100.0 * float(cnt) / float(total)
		var rel: float = float(k) - road_mean
		print("  %5d %9d %9.1f%%   %+7.1f m" % [k, cnt, pct, rel])
	# Chiar AJUNGE tenta pe vertecsi? Se citesc culorile din mesh, nu se
	# presupune din chei. (MEMORY: efectele nu se verifica numarand.)
	var arrs: Array = terr.mesh.surface_get_arrays(0)
	var cols: PackedColorArray = arrs[Mesh.ARRAY_COLOR]
	var verts: PackedVector3Array = arrs[Mesh.ARRAY_VERTEX]
	var reddish := 0
	var low := 0
	var low_red := 0
	for i in range(verts.size()):
		var y: float = verts[i].y + terr.global_position.y
		var c: Color = cols[i]
		var is_red: bool = c.r > c.b * 1.35
		if is_red: reddish += 1
		if y < 26.0:
			low += 1
			if is_red: low_red += 1
	print("")
	print("=== ajunge tenta pe vertecsi? ===")
	print("  vertecsi teren: %d" % verts.size())
	print("  sub cota 26: %d   dintre ei rosietici: %d (%.1f%%)" % [
		low, low_red, 100.0 * float(low_red) / maxf(1.0, float(low))])
	print("  rosietici in tot terenul: %d" % reddish)
	get_tree().quit(0)
