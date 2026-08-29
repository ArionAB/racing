extends Node
## Transformari pentru TURNURI sub piata: stau pe fundul rapei si urca pana
## aproape de cota soselei. Raportul fatada/acoperis al lui tower_silhouette
## e 3.7-4.3, fata de 0.42 la liziba_block: de la o camera care priveste in
## jos, turnul arata fatada, blocul arata acoperis.
func _ready() -> void:
	await get_tree().process_frame
	var track := (load(GameState.TRACK_SCENES[GameState.resolve_track_index(12)])
		as PackedScene).instantiate() as Track
	add_child(track)
	for _i in 12:
		await get_tree().process_frame
	var space := get_viewport().world_3d.direct_space_state
	var c: Curve3D = (track.get_node("Path") as Path3D).curve
	var L := c.get_baked_length()
	# model, inaltime nescalata, fractie, lateral, scara
	var plan := [
		{"m": "c", "h": 31.1, "f": 0.0025, "d": 26.0, "s": 0.95},
		{"m": "a", "h": 38.1, "f": 0.0055, "d": 40.0, "s": 1.00},
		{"m": "b", "h": 48.1, "f": 0.0085, "d": 30.0, "s": 0.85},
		{"m": "c", "h": 31.1, "f": 0.0115, "d": 52.0, "s": 1.05},
		{"m": "a", "h": 38.1, "f": 0.0145, "d": 34.0, "s": 0.95},
		{"m": "b", "h": 48.1, "f": 0.0180, "d": 62.0, "s": 0.90},
		{"m": "c", "h": 31.1, "f": 0.0210, "d": 38.0, "s": 1.00},
		{"m": "a", "h": 38.1, "f": 0.0245, "d": 74.0, "s": 1.00},
		{"m": "b", "h": 48.1, "f": 0.0280, "d": 44.0, "s": 0.90},
		{"m": "c", "h": 31.1, "f": 0.0320, "d": 88.0, "s": 1.05},
	]
	var i := 0
	for e: Dictionary in plan:
		i += 1
		var f: float = e["f"]
		var d: float = e["d"]
		var sc: float = e["s"]
		var mh: float = e["h"]
		var s: float = f * L
		var p := c.sample_baked(s)
		var p2 := c.sample_baked(minf(s + 3.0, L))
		var fwd := (p2 - p).normalized()
		var right := fwd.cross(Vector3.UP).normalized()
		var o: Vector3 = p + right * d + Vector3.UP * 60.0
		var q := PhysicsRayQueryParameters3D.create(o, o + Vector3.DOWN * 220.0)
		var h := space.intersect_ray(q)
		var ground: float = h.position.y if not h.is_empty() else 23.0
		var pos: Vector3 = p + right * d
		pos.y = ground
		# Varful ramane SUB cota soselei: asa privesti in JOS peste ele si
		# citesti caderea. Un turn care trece de sosea sta LANGA drum, nu sub el.
		var top_cap: float = p.y - 4.0
		if ground + mh * sc > top_cap:
			pos.y = top_cap - mh * sc
		# fata spre drum: rotim turnul cu +X spre inainte, Z spre -right
		var bx := fwd * sc
		var by := Vector3.UP * sc
		var bz := -right * sc
		if bx.cross(by).dot(bz) < 0.0:
			bx = -bx
		var b := Basis(bx, by, bz)
		print("turn%d model=%s frac=%.4f d=%.0f teren=%.1f varf=%.1f (sosea %.1f)"
			% [i, e["m"], f, d, ground, ground + mh * sc, p.y])
		print("transform = Transform3D(%.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.6f, %.3f, %.3f, %.3f)"
			% [b.x.x, b.x.y, b.x.z, b.y.x, b.y.y, b.y.z, b.z.x, b.z.y, b.z.z, pos.x, pos.y, pos.z])
	get_tree().quit()
