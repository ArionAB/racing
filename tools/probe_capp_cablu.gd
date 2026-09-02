extends Node
## Cablul balonului ancorat iese pe DEASUPRA panzei?
##
## In cadrul de la 21.7 s se vede o linie rosie subtire care porneste din
## VARFUL panzei si urca in cer. Daca tubul de cablu e mai lung decat cursa
## cosului, capatul lui de sus ramane afara prin panza — exact simptomul.
##
## Sonda compara, pe fiecare balon: cat de sus ajunge tubul de cablu fata de
## cat de sus ajunge panza, in cele doua capete ale ciclului (jos si sus).
##
##   godot --headless --path . res://tools/ProbeCappCablu.tscn -- --track=6

func _ready() -> void:
	await get_tree().process_frame
	var idx := 6
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--track="):
			idx = GameState.resolve_track_index(int(arg.trim_prefix("--track=")))
	var t := (load(GameState.TRACK_SCENES[idx]) as PackedScene).instantiate() as Track
	get_tree().root.add_child(t)
	for i in 6: await get_tree().process_frame

	var balloons: Array[Node] = []
	_collect(t, balloons)
	print("=== CABLUL FATA DE PANZA ===")
	for b in balloons:
		var teth := b.get_node_or_null("Tether") as MeshInstance3D
		var basket := b.get_node_or_null("Basket") as Node3D
		var env := b.get_node_or_null("Basket/Envelope") as Node3D
		if teth == null:
			continue
		var ta := teth.get_aabb()
		var top_cablu: float = (teth.global_transform * (ta.position + ta.size)).y
		var jos_cablu: float = (teth.global_transform * ta.position).y
		var top_panza := -1e9
		if env != null:
			for m in _meshes(env):
				var ma := m.get_aabb()
				top_panza = maxf(top_panza,
					(m.global_transform * (ma.position + ma.size)).y)
		var cos_y := 0.0
		if basket != null:
			cos_y = basket.global_position.y
		print("  %-22s | cablu %.1f .. %.1f (lung %.1f) | cos y=%.1f | varf panza %.1f | cablu peste panza: %+.1f m"
			% [b.name, jos_cablu, top_cablu, top_cablu - jos_cablu, cos_y,
			   top_panza, top_cablu - top_panza])
	get_tree().quit(0)


func _meshes(node: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	var st: Array[Node] = [node]
	while not st.is_empty():
		var n: Node = st.pop_back()
		if n is MeshInstance3D and (n as MeshInstance3D).is_visible_in_tree():
			out.append(n as MeshInstance3D)
		for c in n.get_children(): st.append(c)
	return out


func _collect(node: Node, out: Array[Node]) -> void:
	if node.get_script() != null and node.has_node("Tether"):
		out.append(node)
	for c in node.get_children():
		_collect(c, out)
