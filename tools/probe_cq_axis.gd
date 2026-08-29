extends Node
## Cat de aproape trece SOSEAUA (oricare portiune, tot turul) de un punct dat
## langa piata. Daca bucla revine pe langa piata, o piesa "departe lateral" de
## fractia 0.02 poate fi de fapt langa axa la alta fractie.
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 8:
		await get_tree().process_frame
	var c: Curve3D = (track.get_node("Path") as Path3D).curve
	var L := c.get_baked_length()
	print("lungime tur = %.1f m" % L)
	# pentru cateva fractii din piata, la ce alte fractii revine drumul aproape
	for f in [0.002, 0.010, 0.020, 0.030]:
		var p := c.sample_baked(f * L)
		var line := "frac=%.3f poz=(%.0f,%.0f) revine: " % [f, p.x, p.z]
		var k := 0
		while k < 2000:
			var g: float = float(k) / 2000.0
			var pp := c.sample_baked(g * L)
			var d2 := Vector2(pp.x - p.x, pp.z - p.z).length()
			var df: float = absf(g - f)
			df = minf(df, 1.0 - df)
			if d2 < 60.0 and df > 0.05:
				line += "[f=%.3f d=%.0f dy=%.0f] " % [g, d2, pp.y - p.y]
				k += 60
			k += 1
		print(line)
	get_tree().quit()
