extends Node
## Cat de LATA e gaura de sub tablier, si unde se termina.
## Survey-ul generatorului a aratat -40.30 sub mijlocul podului, dar -20.3 la
## +/-3..40 m lateral pe aceleasi fractii. Adica gaura e o FANTA in lungul
## podului, nu o gorja: se masoara marginile ei pe ambele axe.
const TRACK := "res://scenes/tracks/Track15.tscn"

var _t: Track
var _rid: RID = RID()
var _sus := 0.0


func _ready() -> void:
	await get_tree().process_frame
	_t = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_t)
	for i in 5:
		await get_tree().process_frame
	var hi := -INF
	for bp in _t.baked:
		hi = maxf(hi, bp.y)
	_sus = hi + 200.0
	for c in _t.get_children():
		if str(c.name) == "TerrainBody":
			_rid = (c as StaticBody3D).get_rid()
	print("; TerrainBody rid ok = %s" % str(_rid != RID()))
	# Podul e pe z = -155, de la x = -3 la x = 31 (mijloc x = 14).
	print("; A. profil pe Z (perpendicular pe pod), la x = 14 (mijlocul tablierului):")
	for z: float in [-215.0, -205.0, -195.0, -185.0, -178.0, -172.0, -168.0,
			-165.0, -162.0, -159.0, -157.0, -155.0, -153.0, -151.0, -148.0,
			-145.0, -142.0, -138.0, -132.0, -125.0, -115.0, -105.0, -95.0]:
		print(";   x=14  z=%7.1f  sol %+8.2f" % [z, _sol(14.0, z)])
	print("; B. profil pe X (in lungul podului), la z = -155:")
	var x := -60.0
	while x <= 60.5:
		print(";   z=-155 x=%7.1f  sol %+8.2f" % [x, _sol(x, -155.0)])
		x += 4.0
	print("; C. profil pe Z la x = 14, dar la +-10 m de axa podului (x=4 si x=24):")
	for xx: float in [4.0, 24.0]:
		var line := ";   x=%5.1f :" % xx
		for z: float in [-185.0, -175.0, -168.0, -162.0, -158.0, -155.0,
				-152.0, -148.0, -142.0, -135.0, -125.0]:
			line += " %.0f:%+.1f" % [z, _sol(xx, z)]
		print(line)
	get_tree().quit(0)


func _sol(x: float, z: float) -> float:
	var space := _t.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(x, _sus, z), Vector3(x, _sus - 1400.0, z))
	q.collide_with_areas = false
	q.exclude = []
	var hit: Dictionary = space.intersect_ray(q)
	var g := 0
	while not hit.is_empty() and hit["rid"] != _rid and g < 48:
		q.exclude = q.exclude + [hit["rid"]]
		hit = space.intersect_ray(q)
		g += 1
	if not hit.is_empty() and hit["rid"] == _rid:
		return float(hit["position"].y)
	return -999.0
