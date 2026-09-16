extends Node
## Cat din FATA zidului e descoperita de teren: pentru fiecare stiva de creasta,
## cota terenului chiar la fata exterioara (0,1 m dincolo) fata de baza piesei.
## Daca terenul e PESTE baza, piesa e ingropata si se vede doar o felie.
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
	for bp in _track.baked: hi = maxf(hi, bp.y)
	_sus = hi + 150.0
	var zone := _track.get_node_or_null("DecorManual/ZoneG_Serpentine")
	var n := _track.baked.size()
	var expus: Array[float] = []
	for c in zone.get_children():
		var nm := str(c.name)
		if not nm.begins_with("zidSprijin") or nm.ends_with("_col"): continue
		var t: Node3D = c as Node3D
		var p: Vector3 = t.global_position
		var bi := _nearest(p)
		var s := _track._side_at(bi)
		var lat := Vector3(p.x - _track.baked[bi].x, 0.0, p.z - _track.baked[bi].z).dot(s)
		var outw := s * signf(lat)
		# cota terenului la 0,1 / 0,5 / 1,0 m dincolo de fata
		var q := p + outw * (0.43 + 0.1)
		var g := _sol(q)
		var baza := p.y            # originea piesei = talpa
		var varf := p.y + 2.487
		# cat din inaltimea piesei e DEASUPRA terenului de langa ea
		var e: float = clampf(varf - maxf(g, baza), 0.0, 2.487)
		expus.append(e)
	expus.sort()
	var s_ := 0.0
	for e in expus: s_ += e
	print("; stive masurate: %d" % expus.size())
	print("; fata EXPUSA (m din 2,487): median %.2f, p25 %.2f, p75 %.2f, min %.2f, max %.2f" % [
		expus[expus.size()/2], expus[expus.size()/4], expus[3*expus.size()/4],
		expus[0], expus[expus.size()-1]])
	print("; medie %.2f" % (s_ / float(expus.size())))
	var sub := 0
	for e in expus: if e < 1.0: sub += 1
	print("; piese cu sub 1,0 m de fata vizibila: %d din %d" % [sub, expus.size()])
	get_tree().quit(0)
func _nearest(p: Vector3) -> int:
	var best := 0; var bd := INF
	for i in _track.baked.size():
		var b: Vector3 = _track.baked[i]
		var d := (b.x-p.x)*(b.x-p.x)+(b.z-p.z)*(b.z-p.z)
		if d < bd: bd = d; best = i
	return best
func _sol(q: Vector3) -> float:
	if _rid == RID():
		for c in _track.get_children():
			if str(c.name) == "TerrainBody": _rid = (c as StaticBody3D).get_rid()
	var sp := _track.get_world_3d().direct_space_state
	var pr := PhysicsRayQueryParameters3D.create(Vector3(q.x,_sus,q.z), Vector3(q.x,_sus-1200.0,q.z))
	pr.collide_with_areas = false
	var hit: Dictionary = sp.intersect_ray(pr)
	var g := 0
	while not hit.is_empty() and hit["rid"] != _rid and g < 24:
		pr.exclude = pr.exclude + [hit["rid"]]; hit = sp.intersect_ray(pr); g += 1
	return float(hit["position"].y) if not hit.is_empty() else -999.0
