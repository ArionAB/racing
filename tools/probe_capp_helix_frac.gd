extends Node
## La ce FRAC copt incepe efectiv elicea (raza fata de axa stancii scade sub
## 34 m si drumul incepe sa urce)? Masca de pasaj trebuie sa inceapa inainte.
const CX: float = -302.0
const CZ: float = 6.0


func _ready() -> void:
	await get_tree().process_frame
	var idx := GameState.resolve_track_index(6)
	var track := (load(GameState.TRACK_SCENES[idx]) as PackedScene) \
		.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	var r: TrackRoute = track.routes[0]
	var n := r.baked.size()
	print("frac    r_axa   y      half")
	for i in n:
		var f := r.frac_at(i)
		if f < 0.72 or f > 0.98:
			continue
		var p: Vector3 = r.baked[i]
		var rad := Vector2(p.x - CX, p.z - CZ).length()
		print("%.4f  %6.2f  %6.2f  %.2f" % [f, rad, p.y,
			track.width_at_index(i)])
	get_tree().quit(0)
