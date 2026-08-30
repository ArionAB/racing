extends Node
## Poarta chiar e PESTE banda? Captura de la 0.14 o arata alaturi de drum, nu
## deasupra lui. Se plimba gabaritul masinii pe axa benzii prin dreptul portii
## si se intreaba fizica ce atinge, exact ca probe_solid — plus se masoara
## distanta de la fiecare picior la ax.
##
##   godot --headless --fixed-fps 60 --path . res://tools/ProbeCappPoarta.tscn -- --track=6

const GATE_NAME := "poarta_hornuri_gemene"


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

	var gate: Node3D = null
	var stack: Array[Node] = [track]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if String(n.name).begins_with(GATE_NAME):
			gate = n as Node3D
	if gate == null:
		print("VERDICT: poarta nu e in scena")
		get_tree().quit(1)
		return

	var gp := gate.global_position
	print("")
	print("=== poarta vs. banda ===")
	print("  poarta la (%.2f, %.2f, %.2f)" % [gp.x, gp.y, gp.z])

	# Cel mai apropiat punct de sosea, si offsetul lateral al portii fata de ax.
	var best := INF
	var bi := 0
	for i in track.baked.size():
		var d: float = Vector2(track.baked[i].x - gp.x, track.baked[i].z - gp.z).length_squared()
		if d < best:
			best = d
			bi = i
	var p := track.baked[bi]
	var s := track._side_at(bi)
	var rel := gp - p
	var lat := rel.x * s.x + rel.z * s.z
	print("  cel mai apropiat punct de ax: i=%d frac=%.4f  (%.2f, %.2f)" % [
		bi, float(bi) / float(track.baked.size()), p.x, p.z])
	print("  offset LATERAL fata de ax:    %+.2f m   (half_width %.2f)" % [
		lat, track.width_at_index(bi)])
	print("  offset vertical:              %+.2f m" % (gp.y - p.y))

	# Unde sunt picioarele, in coordonate de banda: se citesc vertecsii de sub
	# 6 m si se proiecteaza pe laterala.
	var lo := INF
	var hi := -INF
	for c in _all(gate):
		if c is MeshInstance3D and (c as MeshInstance3D).mesh != null:
			var mi := c as MeshInstance3D
			var t := mi.global_transform
			for su in mi.mesh.get_surface_count():
				var arr := mi.mesh.surface_get_arrays(su)
				for v: Vector3 in (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array):
					var w := t * v
					if w.y - gp.y > 6.0:
						continue
					var r := w - p
					var l := r.x * s.x + r.z * s.z
					lo = minf(lo, l)
					hi = maxf(hi, l)
	print("  picioarele ocupa lateral      %.2f .. %.2f m fata de ax" % [lo, hi])
	print("  banda libera ceruta           -%.2f .. +%.2f" % [
		track.width_at_index(bi), track.width_at_index(bi)])
	var ok := lo < -track.width_at_index(bi) and hi > track.width_at_index(bi)
	print("")
	print("VERDICT: %s" % ("OK — banda trece INTRE picioare" if ok
		else "PROBLEMA — un picior cade in carosabil sau poarta e alaturi"))
	get_tree().quit(0 if ok else 1)


func _all(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for c in node.get_children():
		out.append_array(_all(c))
	return out
