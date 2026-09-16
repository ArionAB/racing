extends Node
## Unde stau CU ADEVARAT piesele de zid fata de drum si fata de gol.
##
## Pentru fiecare `zidSprijin*` din ZoneG: fractia celui mai apropiat punct de
## traseu, distanta laterala de la AX, semnul lateralei, cota varfului fata de
## sosea, si CAT DE ADANC e golul chiar sub fata exterioara a zidului (la 1 m
## dincolo de el). Ultima cifra e cea care spune daca zidul "tine" ceva.
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
	var zone := _track.get_node_or_null("DecorManual/ZoneG_Serpentine")
	if zone == null:
		print("; fara zona")
		get_tree().quit(1)
		return
	var n := _track.baked.size()
	print("; nume | frac | lat(m de ax) | semn | half | varf-sosea | gol la +1m | gol la +3m")
	var n_fata := 0
	var n_tot := 0
	var sum_lat := 0.0
	for c in zone.get_children():
		if not str(c.name).begins_with("zidSprijin"):
			continue
		var p3: Vector3 = (c as Node3D).global_position
		var bi := _nearest(p3)
		var bp: Vector3 = _track.baked[bi]
		var s := _track._side_at(bi)
		var d := Vector3(p3.x - bp.x, 0.0, p3.z - bp.z)
		var lat := d.dot(s)
		var half := _track.width_at_index(bi)
		# varful piesei: originea + 2.487 * scara (scara e 1 in generator)
		var top: float = p3.y + 2.487
		var outw := Vector3(s.x, 0.0, s.z) * signf(lat)
		var g1 := _sol(p3 + outw * 1.0)
		var g3 := _sol(p3 + outw * 3.0)
		n_tot += 1
		sum_lat += absf(lat)
		if top - bp.y > -0.2:
			n_fata += 1
		var f := float(bi) / float(n)
		print("; %-14s %.4f  %+6.2f  %+d  %4.1f  %+6.2f  %+7.2f  %+7.2f" % [
			c.name, f, lat, int(signf(lat)), half, top - bp.y,
			g1 - bp.y, g3 - bp.y])
	print("; TOTAL %d piese, lat mediu %.2f m, %d cu varful la/peste cota soselei"
		% [n_tot, sum_lat / maxf(1.0, float(n_tot)), n_fata])
	get_tree().quit(0)

func _nearest(p: Vector3) -> int:
	var best := 0
	var bd := INF
	for i in _track.baked.size():
		var b: Vector3 = _track.baked[i]
		var dx := b.x - p.x
		var dz := b.z - p.z
		var d := dx * dx + dz * dz
		if d < bd:
			bd = d
			best = i
	return best

func _sol(q: Vector3) -> float:
	if _rid == RID():
		for c in _track.get_children():
			if str(c.name) == "TerrainBody":
				_rid = (c as StaticBody3D).get_rid()
	var sp := _track.get_world_3d().direct_space_state
	var pr := PhysicsRayQueryParameters3D.create(
		Vector3(q.x, _sus, q.z), Vector3(q.x, _sus - 1200.0, q.z))
	pr.collide_with_areas = false
	var hit: Dictionary = sp.intersect_ray(pr)
	var g := 0
	while not hit.is_empty() and hit["rid"] != _rid and g < 24:
		pr.exclude = pr.exclude + [hit["rid"]]
		hit = sp.intersect_ray(pr)
		g += 1
	return float(hit["position"].y) if not hit.is_empty() else -999.0
