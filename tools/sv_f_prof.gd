extends Node
## Profil lateral REAL (raycast) pe fractiile lui F, ca sa vedem UNDE e buza si
## cat de departe e albia fata de ea.
const TRACK := "res://scenes/tracks/Track15.tscn"
var _track: Track
var _sus := 0.0
var _rid: RID = RID()

func _ready() -> void:
	await get_tree().process_frame
	_track = (load(TRACK) as PackedScene).instantiate() as Track
	get_tree().root.add_child(_track)
	await get_tree().process_frame
	await get_tree().process_frame
	var hi := -INF
	for bp in _track.baked: hi = maxf(hi, bp.y)
	_sus = hi + 200.0
	for n in _track.find_children("*", "StaticBody3D", true, false):
		if n.name.begins_with("Terrain"): _rid = (n as StaticBody3D).get_rid()
	var cnt := _track.baked.size()
	for f in [0.66, 0.67, 0.68, 0.69, 0.70, 0.71, 0.72]:
		var i := int(f * float(cnt)) % cnt
		var p: Vector3 = _track.baked[i]
		var nx: Vector3 = _track.baked[(i + 4) % cnt]
		var fwd := (nx - p); fwd.y = 0.0; fwd = fwd.normalized()
		var side := Vector3(fwd.z, 0.0, -fwd.x)
		var line := "f=%.2f ax_y=%.1f | " % [f, p.y]
		for s in [-1.0, 1.0]:
			var seg := "%+d:" % int(s)
			for d in [8, 14, 20, 30, 45, 60, 80]:
				var q: Vector3 = p + side * (s * float(d))
				var y := _ray(q)
				seg += " %d:%.0f" % [d, y]
			line += seg + "  "
		print(line)
	get_tree().quit()

func _ray(q: Vector3) -> float:
	var st := _track.get_world_3d().direct_space_state
	var pr := PhysicsRayQueryParameters3D.create(Vector3(q.x, _sus, q.z), Vector3(q.x, _sus - 900.0, q.z))
	var r := st.intersect_ray(pr)
	if r.is_empty(): return -999.0
	return (r["position"] as Vector3).y
