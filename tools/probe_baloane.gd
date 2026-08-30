extends Node
## Baloanele ancorate fata de DRUM: rulajul lateral si daca intra in banda.
##
## Criticul orb: „un balon care intersecteaza drumul la scara 4x, cu corzile
## iesind din cadru". Aici se masoara, pentru fiecare balon ancorat, la ce rulaj
## sta fata de axul benzii si cat de mare e anvelopa — ca sa se stie daca e
## asezat gresit, prea mare, sau amandoua.
const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"

func _ready() -> void:
	var t := (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(t)
	await get_tree().process_frame
	await get_tree().physics_frame
	var s: TrackSideSampler = t.get("_sampler")
	var n := s.point_count()
	var nodes: Array[Node] = []
	_walk(t, nodes)
	print("=== baloane ancorate fata de banda ===")
	for nd in nodes:
		var n3 := nd as Node3D
		var g := n3.global_position
		# cel mai apropiat punct de traseu
		var bi := 0
		var bd := INF
		for i in n:
			var p := s.baked_point(i)
			var d := Vector2(p.x - g.x, p.z - g.z).length_squared()
			if d < bd:
				bd = d
				bi = i
		var p := s.baked_point(bi)
		var sd := s.side_at(bi)
		var off := (g - p).dot(sd)
		var hw := s.half_width_at(bi)
		var frac := float(bi) / float(n)
		var scale_v: float = n3.get("model_scale") if n3.get("model_scale") != null else 1.0
		# anvelopa GLB e ~4.8 m in diametru la scara 1
		var diam := 4.8 * scale_v
		var verdict := "ok"
		if absf(off) - diam * 0.5 < hw:
			verdict = "INTRA IN BANDA (rulaj %.1f, semilatime %.1f, raza %.1f)" % [off, hw, diam * 0.5]
		print("  %-28s frac %.3f  rulaj %+6.1f m  scara %.2f  diametru ~%.1f m  %s"
			% [n3.name, frac, off, scale_v, diam, verdict])
	t.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)

func _walk(n: Node, out: Array[Node]) -> void:
	for c in n.get_children():
		if String(c.name).begins_with("Balon") or String(c.name).begins_with("Balonul"):
			out.append(c)
		_walk(c, out)
