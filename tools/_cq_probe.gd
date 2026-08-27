extends Node
func _ready() -> void:
	await get_tree().process_frame
	var t := (load("res://scenes/tracks/Track12.tscn") as PackedScene).instantiate() as Track
	add_child(t)
	for i in 8: await get_tree().process_frame
	await get_tree().physics_frame
	var r := t.routes[0]
	var n := r.count()
	for nm in ["PasajRotativ", "Macara", "Monorail", "CuloarCeata", "Telecabina3D"]:
		var h := t.get_node_or_null(nm) as Node3D
		if h == null: continue
		var p := h.global_position
		var best := -1; var bd := INF
		for i in n:
			var q: Vector3 = r.baked[i]
			var d := q.distance_to(p)
			if d < bd: bd = d; best = i
		var rp: Vector3 = r.baked[best]
		print("%-14s @(%.1f,%.1f,%.1f)  sosea %.1f m  frac %.4f  y_sosea %.1f  dy %+.1f" % [
			nm, p.x, p.y, p.z, bd, r.frac_at(best), rp.y, p.y - rp.y])
	get_tree().quit()
