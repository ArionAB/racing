extends Node
## Ce e pe BANDA DIRECTA in dreptul modulului de pe chei? Scanam pe latimea
## soselei reale si raportam ce colizor e sub fiecare punct: daca ocolul de
## serviciu se suprapune peste linia de curse, masinile intra in el.
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 10:
		await get_tree().process_frame
	var space := get_viewport().world_3d.direct_space_state
	var r := track.routes[0]
	var n := r.count()
	print("frac  | hw  | ce e sub banda, de la -hw la +hw (pas 2 m)")
	var f := 0.440
	while f <= 0.530:
		var i := int(round(f * float(n))) % n
		var c: Vector3 = r.baked[i]
		var fw := (r.baked[(i + 1) % n] - r.baked[(i - 1 + n) % n]).normalized()
		var side := Vector3(fw.z, 0.0, -fw.x).normalized()
		var hw: float = track.width_at_index(i)
		var row := ""
		var lat := -11.0
		while lat <= 11.0:
			var p := c + side * lat
			var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 2.0, p + Vector3.DOWN * 8.0)
			var h := space.intersect_ray(q)
			if h.is_empty():
				row += "."
			else:
				var nm := str(h.collider.name)
				if nm == "ServiceRamp": row += "S"
				elif nm == "Deck": row += "D"
				elif nm == "Span": row += "P"
				elif nm == "Gate": row += "G"
				elif nm == "TerrainBody": row += "t"
				else: row += "?"
			lat += 1.0
		print("%.3f | %4.1f | %s" % [f, hw, row])
		f += 0.003
	print("legenda: . gol  t teren/sosea  D deck  P tronson  S ocol  G poarta")
	get_tree().quit()
