extends Node
## Testul final de trecere: plimbam gabaritul masinii pe TOATA banda directa
## prin POI E, F si G, si raportam orice gol sub roti sau orice zid in fata.
## Nu pe axa modulului - pe axa TRASEULUI, adica pe unde chiar merge masina.
const CAR_HALF_W: float = 0.95
const CAR_LEN: float = 4.0
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
	var holes := 0
	var walls := 0
	var tested := 0
	var box := BoxShape3D.new()
	box.size = Vector3(CAR_HALF_W * 2.0, 1.0, CAR_LEN)
	var f := 0.44
	while f <= 0.97:
		var i := int(round(f * float(n))) % n
		var c: Vector3 = r.baked[i]
		var fw := (r.baked[(i + 2) % n] - r.baked[(i - 2 + n) % n]).normalized()
		var side := Vector3(fw.z, 0.0, -fw.x).normalized()
		for lat: float in [-3.0, -1.5, 0.0, 1.5, 3.0]:
			var p := c + side * lat
			tested += 1
			var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 3.0, p + Vector3.DOWN * 4.0)
			var h := space.intersect_ray(q)
			if h.is_empty():
				holes += 1
				if holes <= 8:
					print("  GOL la frac %.4f banda %+.1f" % [f, lat])
				continue
			# zid: cutia masinii ridicata pe podea
			var par := PhysicsShapeQueryParameters3D.new()
			par.shape = box
			par.transform = Transform3D(Basis(Vector3.UP, atan2(fw.x, fw.z)),
				h.position + Vector3.UP * 0.85)
			for hit in space.intersect_shape(par, 6):
				var col = hit.collider
				if col == null:
					continue
				var nm := str(col.name)
				# poarta imbranceste prin design; deck-ul e podeaua
				if nm in ["Gate", "Deck", "Span", "ServiceRamp", "TerrainBody", "Load", "Beam"]:
					continue
				walls += 1
				if walls <= 8:
					print("  ZID %s la frac %.4f banda %+.1f" % [nm, f, lat])
				break
		f += 0.001
	print("pozitii testate: %d | goluri: %d | ziduri: %d" % [tested, holes, walls])
	print("VERDICT: %s" % ("OK" if holes == 0 and walls == 0 else "PROBLEME"))
	get_tree().quit()
