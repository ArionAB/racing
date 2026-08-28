extends Node
## Cine intra in culoarul de mers? Pentru fiecare fractie a rutei, plimba
## gabaritul masinii pe toata latimea soselei plus o marja si raporteaza orice
## colizor de decor pe care il atinge. Un felinar la 8 m lateral nu e o
## problema de estetica: sonda de cursa a masurat masina intepenita in el.
const MARGIN: float = 2.5   ## cati metri dincolo de asfalt mai cerem liberi
const CAR_HALF_W: float = 1.10
const CAR_HALF_L: float = 1.90
const CAR_H: float = 1.00

func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 12:
		await get_tree().process_frame
	var space := get_viewport().world_3d.direct_space_state
	var shape := BoxShape3D.new()
	shape.size = Vector3(CAR_HALF_W * 2.0, CAR_H * 2.0, CAR_HALF_L * 2.0)
	var r := track.routes[0]
	var n := r.count()
	var hits := {}
	var steps := 1200
	for s in steps:
		var f := float(s) / float(steps)
		var i := int(round(f * float(n))) % n
		var c: Vector3 = r.baked[i]
		var fw := (r.baked[(i + 1) % n] - r.baked[(i - 1 + n) % n]).normalized()
		var side := Vector3(fw.z, 0.0, -fw.x).normalized()
		var hw: float = track.width_at_index(i) + MARGIN
		var lat := -hw
		while lat <= hw:
			var p := c + side * lat + Vector3.UP * (CAR_H + 0.15)
			var params := PhysicsShapeQueryParameters3D.new()
			params.shape = shape
			var basis := Basis(side, Vector3.UP, -fw)
			params.transform = Transform3D(basis, p)
			for res: Dictionary in space.intersect_shape(params, 16):
				var col: Object = res.get("collider")
				if col == null:
					continue
				var node := col as Node
				# ne intereseaza doar decorul manual, nu soseaua/terenul/hazardurile
				var path := str(node.get_path())
				if not path.contains("DecorManual"):
					continue
				var key := str(node.name)
				if not hits.has(key):
					hits[key] = {"frac": f, "lat": lat, "pos": (node as Node3D).global_position}
			lat += 0.8
	print("=== decor in culoarul de mers (asfalt + %.1f m marja) ===" % MARGIN)
	if hits.is_empty():
		print("niciunul")
	else:
		var keys := hits.keys()
		keys.sort_custom(func(a, b): return hits[a]["frac"] < hits[b]["frac"])
		for k: String in keys:
			var d: Dictionary = hits[k]
			print("  frac=%.3f lat=%+5.1f  %s  poz=(%.0f,%.0f,%.0f)" % [
				d["frac"], d["lat"], k, d["pos"].x, d["pos"].y, d["pos"].z])
	print("VERDICT: %s (%d piese)" % ["OK" if hits.is_empty() else "PICAT", hits.size()])
	get_tree().quit()
