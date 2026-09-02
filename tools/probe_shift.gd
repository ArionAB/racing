extends Node
## Calculeaza POZITIILE noi pentru baloanele ancorate: acelasi punct de traseu,
## dar la rulajul cerut. Scrie linii gata de pus in .tscn.
##
## Se face cu sampler-ul, nu cu aritmetica pe coloanele lui Transform3D:
## semnul si coloana laterala depind de conventia de rotatie, si o presupunere
## gresita acolo muta baloanele in lungul drumului fara sa schimbe rulajul —
## exact ce s-a intamplat la prima incercare.
const TRACK_SCENE: String = "res://scenes/tracks/Track13.tscn"
const WANT_OFFSET: float = 19.0

func _ready() -> void:
	var t := (load(TRACK_SCENE) as PackedScene).instantiate() as Track
	add_child(t)
	await get_tree().process_frame
	await get_tree().physics_frame
	var s: TrackSideSampler = t.get("_sampler")
	var n := s.point_count()
	var nodes: Array[Node] = []
	_walk(t, nodes)
	for nd in nodes:
		var n3 := nd as Node3D
		var g := n3.global_position
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
		var want := p + sd * WANT_OFFSET
		print("%s|%.3f|%.3f|%.3f" % [n3.name, want.x, g.y, want.z])
	t.queue_free()
	await get_tree().process_frame
	get_tree().quit(0)

func _walk(n: Node, out: Array[Node]) -> void:
	for c in n.get_children():
		if String(c.name).begins_with("Balon") or String(c.name).begins_with("Tarus"):
			out.append(c)
		_walk(c, out)
