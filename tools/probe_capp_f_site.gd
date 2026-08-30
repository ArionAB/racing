extends Node
## Cotele exacte pe fractiile POI F, cu directie si lateral, ca sa se aseze
## salile pe drumul care EXISTA. Tipareste si tabelul de care are nevoie
## generatorul, in loc sa-l ghiceasca din brief.
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(13)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 10:
		await get_tree().process_frame
	var r := track.routes[0]
	var n := r.count()
	print("frac      x         z        y     hw    yaw")
	for f: float in [0.650, 0.655, 0.660, 0.665, 0.670, 0.675, 0.680, 0.685,
			0.690, 0.695, 0.700, 0.705, 0.710, 0.715, 0.720, 0.725, 0.730,
			0.735, 0.740, 0.745, 0.750, 0.755, 0.760]:
		var i := int(round(f * float(n))) % n
		var c: Vector3 = r.baked[i]
		var fw := (r.baked[(i + 1) % n] - r.baked[(i - 1 + n) % n]).normalized()
		print("%.3f %9.2f %9.2f %7.2f %5.2f %7.1f" % [
			f, c.x, c.z, c.y, track.width_at(f), rad_to_deg(atan2(fw.x, fw.z))])
	get_tree().quit()
