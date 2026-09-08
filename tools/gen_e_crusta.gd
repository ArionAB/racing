extends Node
## Genereaza banda de crusta si tivul de flamingi pe ARCUL VIZIBIL al lacului
## din cadrul hero (POI E, frac 0.40).
##
## De ce arcul, si nu tot lacul: proiectat prin camera de joc (ProbeEProj),
## din malul lacului intra in cadru doar sectorul de azimut 205-290 grade fata
## de centrul lagunei (0, -68); restul e in afara cadrului sau ocluzat de buza.
## Un inel intreg costa instante care nu se vad niciodata (memoria
## `decor-nevazut-se-numara-pe-obiect`).
##
## Cotele NU se ghicesc: linia apei si podeaua se iau din raycast, ca la
## `terrain-mesh-y-extrapoleaza`.

func _ready() -> void:
	await get_tree().process_frame
	var idx := GameState.resolve_track_index(7)
	var scene := load(GameState.TRACK_SCENES[idx]) as PackedScene
	var track := scene.instantiate() as Track
	get_tree().root.add_child(track)
	await get_tree().process_frame
	await get_tree().process_frame
	var space := track.get_world_3d().direct_space_state
	var c := Vector2(0.0, -68.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260908

	var crust: Array[Vector3] = []
	var flam: Array[Vector3] = []
	var flam_yaw: Array[float] = []
	var wings: Array[Vector3] = []
	var wings_yaw: Array[float] = []

	# Linia apei pe fiecare azimut al arcului vizibil.
	print("START")
	var shore := {}
	for adeg in range(200, 296, 2):
		var a := deg_to_rad(float(adeg))
		var dirv := Vector2(cos(a), sin(a))
		var prev_below := true
		for step in range(12, 90):
			var o := c + dirv * float(step)
			var q := PhysicsRayQueryParameters3D.create(Vector3(o.x, 120, o.y), Vector3(o.x, -60, o.y))
			var hit := space.intersect_ray(q)
			if hit.is_empty():
				continue
			var below := float(hit.position.y) < 0.0
			if prev_below and not below:
				shore[adeg] = float(step)
				break
			prev_below = below

	print("SHORE %d" % shore.size())
	var az_keys: Array = shore.keys()
	az_keys.sort()
	for adeg in az_keys:
		var a := deg_to_rad(float(adeg))
		var dirv := Vector2(cos(a), sin(a))
		var d0: float = shore[adeg]
		# CRUSTA: din apa mica (-5 m fata de linie) pana la 32 m in uscat.
		# Placile se suprapun deliberat (12 laturi x raza 7) — o suprafata, nu
		# discuri razlete.
		for k in range(-1, 5):
			var d := d0 + float(k) * 7.0 + rng.randf_range(-2.0, 2.0)
			var o := c + dirv * d
			var jitter := Vector2(rng.randf_range(-3.0, 3.0), rng.randf_range(-3.0, 3.0))
			o += jitter
			var y: Variant = _ground(space, o)
			if y == null:
				continue
			# Crusta sta pe uscat sau abia sub linia apei; nu pe taluz.
			if float(y) > 4.0:
				continue
			crust.append(Vector3(o.x, maxf(float(y), 0.05) + 0.10, o.y))
		# FLAMINGI: tiv LAT peste linia apei (de la -4 m in apa la +9 m in
		# uscat), doua randuri dese — pe referinta banda roz e 6.4% din cadru,
		# la noi era 0.5%.
		# TIVUL: STRANS pe linia apei (+/- 3 m), nu imprastiat pe crusta. Pe
		# referinta banda roz e un inel continuu lipit de apa; imprastiati pe
		# toata crusta, aceiasi 337 de flamingi citeau ca puncte razlete
		# (0.32% din cadru fata de 6.40% pe referinta).
		for k in 34:
			var d := d0 + rng.randf_range(-4.0, 7.0)
			var o := c + dirv * d + Vector2(rng.randf_range(-1.4, 1.4), rng.randf_range(-1.4, 1.4))
			var y2: Variant = _ground(space, o)
			if y2 == null:
				continue
			if float(y2) > 3.0:
				continue
			var py := maxf(float(y2), 0.0)
			var yw := rng.randf_range(0.0, TAU)
			if rng.randf() < 0.12:
				wings.append(Vector3(o.x, py, o.y))
				wings_yaw.append(yw)
			else:
				flam.append(Vector3(o.x, py, o.y))
				flam_yaw.append(yw)

	print("CRUSTA %d" % crust.size())
	print(_vec3_line(crust))
	print("FLAMINGI %d" % flam.size())
	print(_vec3_line(flam))
	print(_float_line(flam_yaw))
	print("ARIPI %d" % wings.size())
	print(_vec3_line(wings))
	print(_float_line(wings_yaw))
	get_tree().quit(0)


func _ground(space: PhysicsDirectSpaceState3D, o: Vector2):
	var q := PhysicsRayQueryParameters3D.create(Vector3(o.x, 120, o.y), Vector3(o.x, -60, o.y))
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return null
	return float(hit.position.y)


func _vec3_line(a: Array[Vector3]) -> String:
	var parts: PackedStringArray = []
	for v in a:
		parts.append("%.3f, %.3f, %.3f" % [v.x, v.y, v.z])
	return "PackedVector3Array(" + ", ".join(parts) + ")"


func _float_line(a: Array[float]) -> String:
	var parts: PackedStringArray = []
	for v in a:
		parts.append("%.4f" % v)
	return "PackedFloat32Array(" + ", ".join(parts) + ")"
