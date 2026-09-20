extends Node
## Verifica daca "PLUTESTE" de pe F e real: compara cota raportata de
## `probe_manual` (campul neted `_sampler.ground_y`) cu un RAYCAST pe
## TerrainBody, in acelasi punct. Memoria `terrain-mesh-y-extrapoleaza`.
const TRACK := "res://scenes/tracks/Track15.tscn"
var _track: Track
var _rid: RID = RID()
var _sus := 0.0

func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	var hi := -INF
	for bp in _track.baked:
		hi = maxf(hi, bp.y)
	_sus = hi + 150.0
	for c in _track.get_children():
		if str(c.name) == "TerrainBody":
			_rid = (c as StaticBody3D).get_rid()
	var zone := _track.get_node_or_null("DecorManual/ZoneF_MalulRaului")
	print("%-28s %9s %9s %9s %8s" % ["nod", "y_obiect", "neted", "raycast", "delta_ray"])
	for ch in zone.get_children():
		var nm := str(ch.name)
		if not (nm.begins_with("FCort") or nm.begins_with("FVers")
				or nm.begins_with("FRucsac")):
			continue
		var n3 := ch as Node3D
		if n3 == null:
			continue
		var p := n3.global_position
		var neted: float = _track._sampler.ground_y(p.x, p.z)
		var ray := _ray(p.x, p.z)
		if absf(p.y - ray) < 1.0:
			continue
		# panta locala pe 8 directii la 1.2 m (raza de esantionare din _place)
		var lo := INF
		var hi2 := -INF
		for k in 8:
			var a := TAU * float(k) / 8.0
			var g := _ray(p.x + cos(a) * 1.2, p.z + sin(a) * 1.2)
			lo = minf(lo, g)
			hi2 = maxf(hi2, g)
		print("%-28s obiect %7.2f  ray_centru %7.2f  delta %6.2f  amprenta %7.2f..%7.2f (=%.2f m)" % [nm, p.y, ray, p.y - ray, lo, hi2, hi2 - lo])
	get_tree().quit(0)

func _ray(x: float, z: float) -> float:
	var space := _track.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(x, _sus, z), Vector3(x, _sus - 1200.0, z))
	q.collide_with_areas = false
	q.exclude = []
	var hit: Dictionary = space.intersect_ray(q)
	var guard := 0
	while not hit.is_empty() and hit["rid"] != _rid and guard < 24:
		q.exclude = q.exclude + [hit["rid"]]
		hit = space.intersect_ray(q)
		guard += 1
	if not hit.is_empty() and hit["rid"] == _rid:
		return float(hit["position"].y)
	return NAN
